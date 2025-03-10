CREATE OR REPLACE PACKAGE BODY APPS.XXCMM002A10C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2022. All rights reserved.
 *
 * Package Name     : XXCMM002A10C (body)
 * Description      : Ðõf[^IFo_EBSRJg
 * MD.050           : T_MD050_CMM_002_A10_Ðõf[^IFo_EBSRJg
 * Version          : 1.22
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  nvl_for_hdl            HDLpNVL
 *  init                   ú(A-1)
 *  output_worker          ]ÆõîñÌoEt@CoÍ(A-2)
 *  output_user            [U[îñÌoEt@CoÍ(A-3)
 *  output_worker2         ]Æõîñiã·EVKÌpÞEÒjÌoEt@CoÍ(A-4)
 *  output_emp_bank_acct   ]ÆõoïûÀîñÌoEt@CoÍ(A-5)
 *  output_emp_info        Ðõ·ªîñÌoEt@CoÍiPaaSpj(A-6)
 *  update_mng_tbl         Çe[uo^EXV(A-7)
 *  submain                CvV[W
 *  main                   RJgÀst@Co^vV[W
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2023-01-12    1.0   Y.Ooyama         VKì¬
 *  2023-01-16    1.1   Y.Ooyama         E054
 *  2023-01-23    1.2   Y.Ooyama         E055, E056
 *  2023-01-29    1.3   Y.Ooyama         OeXgsïÎiNo.0010j
 *  2023-01-30    1.4   F.Hasebe         OeXgsïÎiNo.0012j
 *  2023-01-31    1.5   Y.Ooyama         OeXgsïÎiNo.0013j
 *  2023-01-31    1.6   Y.Ooyama         OeXgsïÎiNo.0014j
 *  2023-02-16    1.7   Y.Ooyama         J­cÛèNo.12iOeXgsïNo.0006j
 *  2023-02-27    1.8   Y.Ooyama         ViIeXgsïNo.0035
 *  2023-03-02    1.9   Y.Ooyama         ViIeXgsïNo.0053
 *  2023-03-03    1.10  Y.Ooyama         ViIeXgsïNo.0057
 *  2023-03-06    1.11  Y.Ooyama         ViIeXgsïNo.0028
 *  2023-03-15    1.12  Y.Ooyama         ViIeXgsïNo.0085
 *  2023-03-22    1.13  Y.Ooyama         ViIeXgsïNo.0093
 *  2023-04-18    1.14  T.Mizutani       PTeXgsïNo.0009
 *  2023-05-22    1.15  F.Hasebe         VXeeXgNo.5C³Î
 *  2023-06-05    1.16  F.Hasebe         àToDoNo.50C³Î
 *  2023-07-11    1.17  F.Hasebe         E_{Ò­_19324Î
 *  2023-07-06    1.18  F.Hasebe         E_{Ò­_19314Î
 *  2023-09-21    1.19  Y.Koh            E_{Ò®_19311y}X^zERPâsûÀ Î
 *  2023-12-22    1.20  K.Sudo           E_{Ò­_19379y}X^zVK]Æõ»ÊtOÌú»Î
 *  2024-01-30    1.21  K.Sudo           E_{Ò®_19791y}X^zoïûÀRÃ¯iERP)
 *  2024-06-25    1.22  K.Sudo           E_{Ò®_20083y}X^z]Æõdüæ}X^ûÀAgáQÎ
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
  -- [U[è`áO
  -- ===============================
  -- bNG[áO
  global_lock_expt          EXCEPTION;
  PRAGMA EXCEPTION_INIT(global_lock_expt, -54);
  -- t@CoÍáO
  global_fileout_expt       EXCEPTION;
  PRAGMA EXCEPTION_INIT(global_fileout_expt, -20010);
--
  -- ===============================
  -- [U[è`O[oè
  -- ===============================
  cv_pkg_name      CONSTANT VARCHAR2(100) := 'XXCMM002A10C'; -- pbP[W¼
--
  -- AvP[VZk¼
  cv_appl_xxcmm             CONSTANT VARCHAR2(5)   := 'XXCMM';              -- AhIF}X^E}X^Ìæ
  cv_appl_xxccp             CONSTANT VARCHAR2(5)   := 'XXCCP';              -- AhIF¤ÊEIFÌæ
  cv_appl_xxcoi             CONSTANT VARCHAR2(5)   := 'XXCOI';              -- AhIFÝÉÌæ
--
  -- út®
  cv_datetime_fmt           CONSTANT VARCHAR2(21)  := 'YYYY/MM/DD HH24:MI:SS';
  cv_date_fmt               CONSTANT VARCHAR2(10)  := 'YYYY/MM/DD';
--
  -- Åè¶
  cv_slash                  CONSTANT VARCHAR2(1)   := '/';
  cv_comma                  CONSTANT VARCHAR2(1)   := ',';
  cv_pipe                   CONSTANT VARCHAR2(1)   := '|';
  cv_space                  CONSTANT VARCHAR2(1)   := ' ';
  cv_hyphen                 CONSTANT VARCHAR2(1)   := '-';
--
  cv_open_mode_w            CONSTANT VARCHAR2(1)   := 'W';                  -- «Ý[h
  cn_max_linesize           CONSTANT BINARY_INTEGER := 32767;               -- t@CTCY
--
  cv_emp_kbn_internal       CONSTANT VARCHAR2(1)   := '1';                  -- ]ÆõæªF1(à)
  cv_emp_kbn_external       CONSTANT VARCHAR2(1)   := '2';                  -- ]ÆõæªF2(O)
  cv_emp_kbn_dummy          CONSTANT VARCHAR2(1)   := '4';                  -- ]ÆõæªF4(_~[)
  cv_vd_type_employee       CONSTANT VARCHAR2(8)   := 'EMPLOYEE';
  cv_wk_terms_suffix        CONSTANT VARCHAR2(2)   := 'WT';
  cv_wt                     CONSTANT VARCHAR2(2)   := 'WT';
  cv_itoen_email_suffix     CONSTANT VARCHAR2(3)   := 'ing';
  cv_itoen_email_domain     CONSTANT VARCHAR2(12)  := '@itoen.co.jp';
  cv_y                      CONSTANT VARCHAR2(1)   := 'Y';
  cv_n                      CONSTANT VARCHAR2(1)   := 'N';
  cv_act_cd_termination     CONSTANT VARCHAR2(11)  := 'TERMINATION';
  cv_act_cd_hire            CONSTANT VARCHAR2(4)   := 'HIRE';
  cv_act_cd_rehire          CONSTANT VARCHAR2(6)   := 'REHIRE';
  cv_act_cd_mng_chg         CONSTANT VARCHAR2(14)  := 'MANAGER_CHANGE';
  cv_meta_merge             CONSTANT VARCHAR2(5)   := 'MERGE';
  cv_meta_delete            CONSTANT VARCHAR2(6)   := 'DELETE';
  cv_ebs                    CONSTANT VARCHAR2(3)   := 'EBS';
  cv_jp                     CONSTANT VARCHAR2(2)   := 'JP';
  cv_global                 CONSTANT VARCHAR2(6)   := 'GLOBAL';
  cv_w1                     CONSTANT VARCHAR2(2)   := 'W1';
  cv_sales_le               CONSTANT VARCHAR2(8)   := 'SALES-LE';
  cv_sales_bu               CONSTANT VARCHAR2(8)   := 'SALES-BU';
  cv_wk_type_e              CONSTANT VARCHAR2(1)   := 'E';
  cv_sys_per_type_emp       CONSTANT VARCHAR2(3)   := 'EMP';
  cv_ass_type_et            CONSTANT VARCHAR2(2)   := 'ET';
  cv_per_type_employee      CONSTANT VARCHAR2(8)   := 'Employee';
  cv_seq_1                  CONSTANT VARCHAR2(1)   := '1';
  cv_ass_status_act         CONSTANT VARCHAR2(14)  := 'ACTIVE_PROCESS';
  cv_sup_type_line_manager  CONSTANT VARCHAR2(12)  := 'LINE_MANAGER';
  cv_proc_type_dept         CONSTANT VARCHAR2(1)   := '2';                  -- æªF2(å)
  cv_acct_type_sup          CONSTANT VARCHAR2(8)   := 'SUPPLIER';
-- Ver1.1 Add Start
  cv_yen                    CONSTANT VARCHAR2(3)  := 'JPY';
-- Ver1.1 Add End
--
  cv_cls_worker             CONSTANT VARCHAR2(6)   := 'Worker';
  cv_cls_per_name           CONSTANT VARCHAR2(10)  := 'PersonName';
  cv_cls_per_legi           CONSTANT VARCHAR2(21)  := 'PersonLegislativeData';
  cv_cls_per_email          CONSTANT VARCHAR2(11)  := 'PersonEmail';
  cv_cls_wk_rel             CONSTANT VARCHAR2(16)  := 'WorkRelationship';
  cv_cls_per_user           CONSTANT VARCHAR2(21)  := 'PersonUserInformation';
  cv_cls_wk_terms           CONSTANT VARCHAR2(9)   := 'WorkTerms';
  cv_cls_user               CONSTANT VARCHAR2(4)   := 'User';
  cv_cls_assignment         CONSTANT VARCHAR2(10)  := 'Assignment';
  cv_cls_ass_super          CONSTANT VARCHAR2(20)  := 'AssignmentSupervisor';
  cv_per_persons_dff        CONSTANT VARCHAR2(20)  := 'ITO_SALES_USE_ITEM';
  cv_per_asg_df             CONSTANT VARCHAR2(20)  := 'ITO_SALES_USE_ITEM';
--
  -- oÎÛO]ÆõÔ
  cv_not_get_emp1           CONSTANT VARCHAR2(10)  := '99983';
  cv_not_get_emp2           CONSTANT VARCHAR2(10)  := '99984';
  cv_not_get_emp3           CONSTANT VARCHAR2(10)  := '99985';
  cv_not_get_emp4           CONSTANT VARCHAR2(10)  := '99989';
  cv_not_get_emp5           CONSTANT VARCHAR2(10)  := '99997';
  cv_not_get_emp6           CONSTANT VARCHAR2(10)  := '99998';
  cv_not_get_emp7           CONSTANT VARCHAR2(10)  := '99999';
  cv_not_get_emp8           CONSTANT VARCHAR2(10)  := 'XXSCV_2';
--
  -- f[^^CvÊNVLÏ·l
  cv_nvl_v                  CONSTANT VARCHAR2(5)   := '#NULL';
  cv_nvl_d                  CONSTANT VARCHAR2(10)  := '4712/01/01';
  cv_nvl_n                  CONSTANT VARCHAR2(10)  := '-999999991';
--
  -- vt@C
  -- XXCMM:OICAgf[^t@Ci[fBNg¼
  cv_prf_out_file_dir       CONSTANT VARCHAR2(30)  := 'XXCMM1_OIC_OUT_FILE_DIR';
  -- XXCMM:]ÆõîñAgf[^t@C¼iOICAgj
  cv_prf_wrk_out_file       CONSTANT VARCHAR2(30)  := 'XXCMM1_002A10_W_OUT_FILE_FIL';
  -- XXCMM:]Æõîñiã·EVKÌpÞEÒjAgf[^t@C¼iOICAgj
  cv_prf_wrk2_out_file      CONSTANT VARCHAR2(30)  := 'XXCMM1_002A10_W2_OUT_FILE_FIL';
  -- XXCMM:[U[îñAgf[^t@C¼iOICAgj
  cv_prf_usr_out_file       CONSTANT VARCHAR2(30)  := 'XXCMM1_002A10_U_OUT_FILE_FIL';
-- Ver1.2(E055) Add Start
  -- XXCMM:[U[îñiíjAgf[^t@C¼iOICAgj
  cv_prf_usr2_out_file      CONSTANT VARCHAR2(30)  := 'XXCMM1_002A10_U2_OUT_FILE_FIL';
-- Ver1.2(E055) Add End
  -- XXCMM:PaaSpÌVK[U[îñt@C¼iOICAgj
  cv_prf_new_usr_out_file   CONSTANT VARCHAR2(30)  := 'XXCMM1_002A10_NU_OUT_FILE_FIL';
  -- XXCMM:PaaSpÌ]ÆõoïûÀîñt@C¼iOICAgj
  cv_prf_emp_bnk_out_file   CONSTANT VARCHAR2(30)  := 'XXCMM1_002A10_EBA_OUT_FILE_FIL';
  -- XXCMM:PaaSpÌÐõ·ªîñt@C¼iOICAgj
  cv_prf_emp_inf_out_file   CONSTANT VARCHAR2(30)  := 'XXCMM1_002A10_EDI_OUT_FILE_FIL';
  -- XXCMM:Ðõf[^IFñõîúiOICAgj
  cv_prf_1st_srch_date      CONSTANT VARCHAR2(30)  := 'XXCMM1_002A10_1ST_SC_DATE';
-- Ver1.15 Del Start
--  -- XXCMM:ERP_CloudúpX[hiOICAgj
--  cv_prf_password           CONSTANT VARCHAR2(30)  := 'XXCMM1_002A10_PASSWORD';
-- Ver1.15 Del End
  -- XXCMM:ftHgïp¨èÌ¨èÈÚiOICAgj
  cv_prf_def_account_cd     CONSTANT VARCHAR2(30)  := 'XXCMM1_002A10_DEF_ACCOUNT_CD';
  -- XXCMM:ftHgïp¨èÌâÈÚiOICAgj
  cv_prf_def_sub_acct_cd    CONSTANT VARCHAR2(30)  := 'XXCMM1_002A10_DEF_SUB_ACCT_CD';
-- Ver1.17 Add Start
  -- XXCMM:PaaSpÌVüÐõîñt@C¼iOICAgj
  cv_prf_new_emp_out_file   CONSTANT VARCHAR2(30)  := 'XXCMM1_002A10_NE_OUT_FILE_FIL';
-- Ver1.17 Add End
--
  -- bZ[W¼
  cv_input_param_msg        CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-60001';       -- p[^oÍbZ[W
  cv_prof_get_err_msg       CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00002';       -- vt@Cæ¾G[bZ[W
  cv_dir_path_get_err_msg   CONSTANT VARCHAR2(16)  := 'APP-XXCOI1-00029';       -- fBNgtpXæ¾G[bZ[W
  cv_to_date_err_msg        CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-60029';       -- út^Ï·G[bZ[W
  cv_if_file_name_msg       CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-60003';       -- IFt@C¼oÍbZ[W
  cv_file_exist_err_msg     CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-60004';       -- ¯êt@C¶ÝG[bZ[W
  cv_lock_err_msg           CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00008';       -- bNG[bZ[W
  cv_proc_date_get_err_msg  CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00018';       -- Æ±útæ¾G[bZ[W
  cv_process_date_msg       CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-60005';       -- úoÍbZ[W
  cv_search_trgt_cnt_msg    CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-60006';       -- õÎÛEbZ[W
  cv_file_open_err_msg      CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00487';       -- t@CI[vG[bZ[W
  cv_file_write_err_msg     CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00488';       -- t@C«ÝG[bZ[W
  cv_file_trgt_cnt_msg      CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-60007';       -- t@CoÍÎÛEbZ[W
  cv_insert_err_msg         CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00054';       -- }üG[bZ[W
  cv_update_err_msg         CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00055';       -- XVG[bZ[W
  cv_proc_date_msg          CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-60050';       -- Æ±útoÍbZ[W
  cv_if_date_msg            CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-60051';       -- AgútoÍbZ[W
--
  -- bZ[W¼(g[N)
  cv_rec_proc_date_msg      CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-60030';       -- Æ±útiJopj
  cv_oic_proc_mng_tbl_msg   CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-60008';       -- OICAgÇe[u
  cv_oic_emp_info_tbl_msg   CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-60031';       -- OICÐõ·ªîñe[u
  cv_oic_emp_inf_bk_tbl_msg CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-60032';       -- OICÐõ·ªîñobNAbve[u
  cv_oic_wk_hiera_dept_msg  CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-60047';       -- åKw[N
  cv_worker_msg             CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-60033';       -- AÆÒ
  cv_per_name_msg           CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-60044';       -- Âl¼
  cv_per_legi_msg           CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-60045';       -- ÂlÊdlf[^
  cv_per_email_msg          CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-60046';       -- ÂlE[
  cv_work_relation_msg      CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-60034';       -- ÙpÖWiÞEÒj
  cv_new_user_info_msg      CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-60035';       -- [U[îñiVKj
  cv_new_user_info_paas_msg CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-60049';       -- [U[îñiVKjPaaSp
  cv_work_term_msg          CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-60036';       -- Ùpð
  cv_assignment_msg         CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-60037';       -- ATCgîñ
  cv_user_info_msg          CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-60038';       -- [U[îñ
-- Ver1.2(E055) Add Start
  cv_user2_info_msg         CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-60052';       -- [U[îñiíj
-- Ver1.2(E055) Add End
  cv_sup_assignment_msg     CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-60039';       -- ATCgîñiã·j
  cv_work_relation_2_msg    CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-60040';       -- ÙpÖWiVKÌpÞEÒj
  cv_emp_bank_acct_msg      CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-60041';       -- ]ÆõoïûÀîñ
  cv_emp_info_msg           CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-60042';       -- Ðõ·ªîñ
--
  -- g[N¼
  cv_tkn_param_name         CONSTANT VARCHAR2(30)  := 'PARAM_NAME';             -- g[N¼(PARAM_NAME)
  cv_tkn_param_val          CONSTANT VARCHAR2(30)  := 'PARAM_VAL';              -- g[N¼(PARAM_VAL)
  cv_tkn_ng_profile         CONSTANT VARCHAR2(30)  := 'NG_PROFILE';             -- g[N¼(NG_PROFILE)
  cv_tkn_dir_tok            CONSTANT VARCHAR2(30)  := 'DIR_TOK';                -- g[N¼(DIR_TOK)
  cv_tkn_item               CONSTANT VARCHAR2(30)  := 'ITEM';                   -- g[N¼(ITEM)
  cv_tkn_value              CONSTANT VARCHAR2(30)  := 'VALUE';                  -- g[N¼(VALUE)
  cv_tkn_format             CONSTANT VARCHAR2(30)  := 'FORMAT';                 -- g[N¼(FORMAT)
  cv_tkn_file_name          CONSTANT VARCHAR2(30)  := 'FILE_NAME';              -- g[N¼(FILE_NAME)
  cv_tkn_ng_table           CONSTANT VARCHAR2(30)  := 'NG_TABLE';               -- g[N¼(NG_TABLE)
  cv_tkn_date1              CONSTANT VARCHAR2(30)  := 'DATE1';                  -- g[N¼(DATE1)
  cv_tkn_date2              CONSTANT VARCHAR2(30)  := 'DATE2';                  -- g[N¼(DATE2)
  cv_tkn_date               CONSTANT VARCHAR2(30)  := 'DATE';                   -- g[N¼(DATE)
  cv_tkn_target             CONSTANT VARCHAR2(30)  := 'TARGET';                 -- g[N¼(TARGET)
  cv_tkn_count              CONSTANT VARCHAR2(30)  := 'COUNT';                  -- g[N¼(COUNT)
  cv_tkn_table              CONSTANT VARCHAR2(30)  := 'TABLE';                  -- g[N¼(TABLE)
  cv_tkn_err_msg            CONSTANT VARCHAR2(30)  := 'ERR_MSG';                -- g[N¼(ERR_MSG)
  cv_tkn_sqlerrm            CONSTANT VARCHAR2(30)  := 'SQLERRM';                -- g[N¼(SQLERRM)
-- Ver1.2(E056) Add Start
  cv_site_code_comp         CONSTANT VARCHAR2(10)  := 'ïÐ';
-- Ver1.2(E056) Add End
--
  -- ===============================
  -- [U[è`O[o^
  -- ===============================
--
  -- ===============================
  -- [U[è`O[oÏ
  -- ===============================
  -- vt@Cl
  -- XXCMM:OICAgf[^t@Ci[fBNg¼
  gt_prf_val_out_file_dir       fnd_profile_option_values.profile_option_value%TYPE;
  -- XXCMM:]ÆõîñAgf[^t@C¼iOICAgj
  gt_prf_val_wrk_out_file       fnd_profile_option_values.profile_option_value%TYPE;
  -- XXCMM:]Æõîñiã·EVKÌpÞEÒjAgf[^t@C¼iOICAgj
  gt_prf_val_wrk2_out_file      fnd_profile_option_values.profile_option_value%TYPE;
  -- XXCMM:[U[îñAgf[^t@C¼iOICAgj
  gt_prf_val_usr_out_file       fnd_profile_option_values.profile_option_value%TYPE;
-- Ver1.2(E055) Add Start
  -- XXCMM:[U[îñiíjAgf[^t@C¼iOICAgj
  gt_prf_val_usr2_out_file      fnd_profile_option_values.profile_option_value%TYPE;
-- Ver1.2(E055) Add End
  -- XXCMM:PaaSpÌVK[U[îñt@C¼iOICAgj
  gt_prf_val_new_usr_out_file   fnd_profile_option_values.profile_option_value%TYPE;
  -- XXCMM:PaaSpÌ]ÆõoïûÀîñt@C¼iOICAgj
  gt_prf_val_emp_bnk_out_file   fnd_profile_option_values.profile_option_value%TYPE;
  -- XXCMM:PaaSpÌÐõ·ªîñt@C¼iOICAgj
  gt_prf_val_emp_inf_out_file   fnd_profile_option_values.profile_option_value%TYPE;
  -- XXCMM:Ðõf[^IFñõîúiOICAgj
  gt_prf_val_1st_srch_date      fnd_profile_option_values.profile_option_value%TYPE;
-- Ver1.15 Del Start
--  -- XXCMM:ERP_CloudúpX[hiOICAgj
--  gt_prf_val_password           fnd_profile_option_values.profile_option_value%TYPE;
-- Ver1.15 Del End
  -- XXCMM:ftHgïp¨èÌ¨èÈÚiOICAgj
  gt_prf_val_def_account_cd     fnd_profile_option_values.profile_option_value%TYPE;
  -- XXCMM:ftHgïp¨èÌâÈÚiOICAgj
  gt_prf_val_def_sub_acct_cd    fnd_profile_option_values.profile_option_value%TYPE;
-- Ver1.17 Add Start
  -- XXCMM:PaaSpÌVüÐõîñt@C¼iOICAgj
  gt_prf_val_new_emp_out_file   fnd_profile_option_values.profile_option_value%TYPE;
-- Ver1.17 Add End
--
  -- OICAgÇe[uÌo^EXVf[^
  gt_conc_program_name          fnd_concurrent_programs.concurrent_program_name%TYPE;    -- RJgvO¼
  gt_pre_process_date           xxccp_oic_if_process_mng.pre_process_date%TYPE;          -- Oñú
  gv_first_proc_flag            VARCHAR2(1);                                             -- ñtO(Y/N)
  gt_cur_process_date           xxccp_oic_if_process_mng.pre_process_date%TYPE;          -- ¡ñú
--
  gt_if_dest_date               DATE;                                                    -- Agút
  gv_str_pre_process_date       VARCHAR2(19);                                            -- Oñúi¶ñj
-- Ver1.18 Add Start
  gv_str_cur_process_date       VARCHAR2(19);                                            -- ¡ñúi¶ñj
-- Ver1.18 Add End
--
  -- t@Cnh
  gf_wrk_file_handle            UTL_FILE.FILE_TYPE;         -- ]ÆõîñAgf[^t@C
  gf_wrk2_file_handle           UTL_FILE.FILE_TYPE;         -- ]Æõîñiã·EVKÌpÞEÒjAgf[^t@C
  gf_usr_file_handle            UTL_FILE.FILE_TYPE;         -- [U[îñAgf[^t@C
-- Ver1.2(E055) Add Start
  gf_usr2_file_handle           UTL_FILE.FILE_TYPE;         -- [U[îñiíjAgf[^t@C
-- Ver1.2(E055) Add End
  gf_new_usr_file_handle        UTL_FILE.FILE_TYPE;         -- PaaSpÌVK[U[îñt@C
  gf_emp_bnk_file_handle        UTL_FILE.FILE_TYPE;         -- PaaSpÌ]ÆõoïûÀîñt@C
  gf_emp_inf_file_handle        UTL_FILE.FILE_TYPE;         -- PaaSpÌÐõ·ªîñt@C
-- Ver1.17 Add Start
  gf_new_emp_file_handle        UTL_FILE.FILE_TYPE;         -- PaaSpÌVüÐõîñt@C
-- Ver1.17 Add End
--
  -- ÂÊ
  -- o
  gn_get_wk_cnt                 NUMBER;                     -- AÆÒo
  gn_get_per_name_cnt           NUMBER;                     -- Âl¼o
  gn_get_per_legi_cnt           NUMBER;                     -- ÂlÊdlf[^o
  gn_get_per_email_cnt          NUMBER;                     -- ÂlE[o
  gn_get_wk_rel_cnt             NUMBER;                     -- ÙpÖWiÞEÒjo
  gn_get_new_user_cnt           NUMBER;                     -- [U[îñiVKjo
  gn_get_new_user_paas_cnt      NUMBER;                     -- [U[îñiVKjPaaSpo
  gn_get_wk_terms_cnt           NUMBER;                     -- Ùpðo
  gn_get_ass_cnt                NUMBER;                     -- ATCgîño
  gn_get_user_cnt               NUMBER;                     -- [U[îño
-- Ver1.2(E055) Add Start
  gn_get_user2_cnt              NUMBER;                     -- [U[îñiíjo
-- Ver1.2(E055) Add End
  gn_get_ass_sup_cnt            NUMBER;                     -- ATCgîñiã·jo
  gn_get_wk_rel2_cnt            NUMBER;                     -- ÙpÖWiVKÌpÞEÒjo
  gn_get_bank_acc_cnt           NUMBER;                     -- ]ÆõoïûÀîño
  gn_get_emp_info_cnt           NUMBER;                     -- Ðõ·ªîño
  -- oÍ
  gn_out_wk_cnt                 NUMBER;                     -- ]ÆõîñAgf[^t@CoÍ
  gn_out_p_new_user_cnt         NUMBER;                     -- PaaSpÌVK[U[îñt@CoÍ
  gn_out_user_cnt               NUMBER;                     -- [U[îñAgf[^t@CoÍ
-- Ver1.2(E055) Add Start
  gn_out_user2_cnt              NUMBER;                     -- [U[îñiíjAgf[^t@CoÍ
-- Ver1.2(E055) Add End
  gn_out_wk2_cnt                NUMBER;                     -- ]Æõîñiã·EVKÌpÞEÒjAgf[^t@CoÍ
  gn_out_p_bank_acct_cnt        NUMBER;                     -- PaaSpÌ]ÆõoïûÀîñt@CoÍ
  gn_out_p_emp_info_cnt         NUMBER;                     -- PaaSpÌÐõ·ªîñt@CoÍ
-- Ver1.17 Add Start
  gn_out_p_new_emp_cnt          NUMBER;                     -- PaaSpÌVüÐõîñt@CoÍ
-- Ver1.17 Add End
--  
  -- ===============================
  -- [U[è`O[oJ[\
  -- ===============================
--
--
  /**********************************************************************************
   * Function Name    : nvl_for_hdl
   * Description      : HDLpNVL
   ***********************************************************************************/
  FUNCTION nvl_for_hdl(
              iv_string          IN VARCHAR2,     -- ÎÛ¶ñ
              iv_new_reg_flag    IN VARCHAR2,     -- VKo^tO
              iv_nvl_string      IN VARCHAR2      -- NVLÏ·l
           )
    RETURN VARCHAR2
  IS
  --
    -- *** [Jè ***
    cv_prg_name         CONSTANT VARCHAR2(100) := 'nvl_for_hdl';
--
    -- *** [JÏ ***
  --
  BEGIN
--
    IF ( iv_new_reg_flag = cv_n ) THEN
      -- VKo^ÅÈ¢iXVjÌê
      IF ( iv_string IS NULL) THEN
        -- ÎÛ¶ñªNULLÌêANVLÏ·lðÔp
        RETURN iv_nvl_string;
      END IF;
    END IF;
--
    RETURN iv_string;
--
  EXCEPTION
--
--###############################  ÅèáO START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  Åè END   #########################################
--
  END nvl_for_hdl;
--
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ú(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    iv_proc_date_for_recovery  IN  VARCHAR2,     --   Æ±útiJopj
    ov_errbuf                  OUT VARCHAR2,     --   G[EbZ[W           --# Åè #
    ov_retcode                 OUT VARCHAR2,     --   ^[ER[h             --# Åè #
    ov_errmsg                  OUT VARCHAR2)     --   [U[EG[EbZ[W --# Åè #
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
    lv_msg               VARCHAR2(3000);
    lt_dir_path          all_directories.directory_path%TYPE;    -- fBNgpX
    ld_1st_srch_date     DATE;                                   -- Ðõf[^IFñõîú
    lb_fexists           BOOLEAN;                                -- t@Cª¶Ý·é©Ç¤©
    ln_file_length       NUMBER;                                 -- t@C·
    ln_block_size        NUMBER;                                 -- ubNTCY
    ld_process_date      DATE;                                   -- Æ±útiDBj
    ln_prf_idx           NUMBER;                                 -- vt@CpCfbNX
    ln_file_name_idx     NUMBER;                                 -- t@C¼pCfbNX
--
    -- *** [JEJ[\ ***
--
    -- *** [JER[h ***
    -- vt@CpR[h
    TYPE l_prf_rtype IS RECORD
    (
      prf_name           VARCHAR2(30)
    , prf_value          fnd_profile_option_values.profile_option_value%TYPE
    );
    -- vt@Cpe[u
    TYPE l_prf_ttype IS TABLE OF l_prf_rtype INDEX BY BINARY_INTEGER;
    l_prf_tab    l_prf_ttype;
--
    -- t@C¼pe[u
    TYPE l_file_name_ttype IS TABLE OF fnd_profile_option_values.profile_option_value%TYPE INDEX BY BINARY_INTEGER;
    l_file_name_tab      l_file_name_ttype;
--
  BEGIN
--
--##################  ÅèXe[^Xú» START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  Åè END   ############################
--
    -- ==============================================================
    -- 1.üÍp[^ÌoÍ
    -- ==============================================================
    -- üÍp[^¼FÆ±útiJopj
    lv_msg := xxccp_common_pkg.get_msg(
                iv_application  => cv_appl_xxcmm             -- AvP[VZk¼FXXCMM
              , iv_name         => cv_input_param_msg        -- bZ[W¼Fp[^oÍbZ[W
              , iv_token_name1  => cv_tkn_param_name         -- g[N¼1FPARAM_NAME
              , iv_token_value1 => cv_rec_proc_date_msg      -- g[Nl1FÆ±útiJopj
              , iv_token_name2  => cv_tkn_param_val          -- g[N¼2FPARAM_VAL
              , iv_token_value2 => iv_proc_date_for_recovery -- g[Nl2Fp[^l
              );
    --
    FND_FILE.PUT_LINE(
      which  => FND_FILE.OUTPUT
    , buff   => lv_msg
    );
    -- ós}ü
    FND_FILE.PUT_LINE(
      which  => FND_FILE.OUTPUT
    , buff   => ''
    );
    --
    -- p[^oÍbZ[WðO(LOG)ÉàoÍ
    FND_FILE.PUT_LINE(
      which  => FND_FILE.LOG
    , buff   => lv_msg
    );
    -- ós}ü
    FND_FILE.PUT_LINE(
      which  => FND_FILE.LOG
    , buff   => ''
    );
    --
    -- ==============================================================
    -- 2.vt@ClÌæ¾
    -- ==============================================================
    ln_prf_idx := 0;
    --
    -- 1.XXCMM:OICAgf[^t@Ci[fBNg¼
    gt_prf_val_out_file_dir := FND_PROFILE.VALUE( cv_prf_out_file_dir );
    -- vt@Cpe[uÉÝè
    ln_prf_idx := ln_prf_idx + 1;
    l_prf_tab(ln_prf_idx).prf_name  := cv_prf_out_file_dir;
    l_prf_tab(ln_prf_idx).prf_value := gt_prf_val_out_file_dir;
    --
    -- 2.XXCMM:]ÆõîñAgf[^t@C¼iOICAgj
    gt_prf_val_wrk_out_file := FND_PROFILE.VALUE( cv_prf_wrk_out_file );
    -- vt@Cpe[uÉÝè
    ln_prf_idx := ln_prf_idx + 1;
    l_prf_tab(ln_prf_idx).prf_name  := cv_prf_wrk_out_file;
    l_prf_tab(ln_prf_idx).prf_value := gt_prf_val_wrk_out_file;
    --
    -- 3.XXCMM:]Æõîñiã·EVKÌpÞEÒjAgf[^t@C¼iOICAgj
    gt_prf_val_wrk2_out_file := FND_PROFILE.VALUE( cv_prf_wrk2_out_file );
    -- vt@Cpe[uÉÝè
    ln_prf_idx := ln_prf_idx + 1;
    l_prf_tab(ln_prf_idx).prf_name  := cv_prf_wrk2_out_file;
    l_prf_tab(ln_prf_idx).prf_value := gt_prf_val_wrk2_out_file;
    --
    -- 4.XXCMM:[U[îñAgf[^t@C¼iOICAgj
    gt_prf_val_usr_out_file := FND_PROFILE.VALUE( cv_prf_usr_out_file );
    -- vt@Cpe[uÉÝè
    ln_prf_idx := ln_prf_idx + 1;
    l_prf_tab(ln_prf_idx).prf_name  := cv_prf_usr_out_file;
    l_prf_tab(ln_prf_idx).prf_value := gt_prf_val_usr_out_file;
-- Ver1.2(E055) Add Start
    --
    -- 5.XXCMM:[U[îñiíjAgf[^t@C¼iOICAgj
    gt_prf_val_usr2_out_file := FND_PROFILE.VALUE( cv_prf_usr2_out_file );
    -- vt@Cpe[uÉÝè
    ln_prf_idx := ln_prf_idx + 1;
    l_prf_tab(ln_prf_idx).prf_name  := cv_prf_usr2_out_file;
    l_prf_tab(ln_prf_idx).prf_value := gt_prf_val_usr2_out_file;
-- Ver1.2(E055) Add End
    --
    -- 6.XXCMM:PaaSpÌVK[U[îñt@C¼iOICAgj
    gt_prf_val_new_usr_out_file := FND_PROFILE.VALUE( cv_prf_new_usr_out_file );
    -- vt@Cpe[uÉÝè
    ln_prf_idx := ln_prf_idx + 1;
    l_prf_tab(ln_prf_idx).prf_name  := cv_prf_new_usr_out_file;
    l_prf_tab(ln_prf_idx).prf_value := gt_prf_val_new_usr_out_file;
    --
    -- 7.XXCMM:PaaSpÌ]ÆõoïûÀîñt@C¼iOICAgj
    gt_prf_val_emp_bnk_out_file := FND_PROFILE.VALUE( cv_prf_emp_bnk_out_file );
    -- vt@Cpe[uÉÝè
    ln_prf_idx := ln_prf_idx + 1;
    l_prf_tab(ln_prf_idx).prf_name  := cv_prf_emp_bnk_out_file;
    l_prf_tab(ln_prf_idx).prf_value := gt_prf_val_emp_bnk_out_file;
    --
    -- 8.XXCMM:PaaSpÌÐõ·ªîñt@C¼iOICAgj
    gt_prf_val_emp_inf_out_file := FND_PROFILE.VALUE( cv_prf_emp_inf_out_file );
    -- vt@Cpe[uÉÝè
    ln_prf_idx := ln_prf_idx + 1;
    l_prf_tab(ln_prf_idx).prf_name  := cv_prf_emp_inf_out_file;
    l_prf_tab(ln_prf_idx).prf_value := gt_prf_val_emp_inf_out_file;
    --
    -- 9.XXCMM:Ðõf[^IFñõîúiOICAgj
    gt_prf_val_1st_srch_date := FND_PROFILE.VALUE( cv_prf_1st_srch_date );
    -- vt@Cpe[uÉÝè
    ln_prf_idx := ln_prf_idx + 1;
    l_prf_tab(ln_prf_idx).prf_name  := cv_prf_1st_srch_date;
    l_prf_tab(ln_prf_idx).prf_value := gt_prf_val_1st_srch_date;
    --
-- Ver1.15 Del Start
--    -- 10.XXCMM:ERP_CloudúpX[hiOICAgj
--    gt_prf_val_password := FND_PROFILE.VALUE( cv_prf_password );
--    -- vt@Cpe[uÉÝè
--    ln_prf_idx := ln_prf_idx + 1;
--    l_prf_tab(ln_prf_idx).prf_name  := cv_prf_password;
--    l_prf_tab(ln_prf_idx).prf_value := gt_prf_val_password;
--    --
-- Ver1.15 Del End
    -- 11.XXCMM:ftHgïp¨èÌ¨èÈÚiOICAgj
    gt_prf_val_def_account_cd := FND_PROFILE.VALUE( cv_prf_def_account_cd );
    -- vt@Cpe[uÉÝè
    ln_prf_idx := ln_prf_idx + 1;
    l_prf_tab(ln_prf_idx).prf_name  := cv_prf_def_account_cd;
    l_prf_tab(ln_prf_idx).prf_value := gt_prf_val_def_account_cd;
    --
    -- 12.XXCMM:ftHgïp¨èÌâÈÚiOICAgj
    gt_prf_val_def_sub_acct_cd := FND_PROFILE.VALUE( cv_prf_def_sub_acct_cd );
    -- vt@Cpe[uÉÝè
    ln_prf_idx := ln_prf_idx + 1;
    l_prf_tab(ln_prf_idx).prf_name  := cv_prf_def_sub_acct_cd;
    l_prf_tab(ln_prf_idx).prf_value := gt_prf_val_def_sub_acct_cd;
    --
-- Ver1.17 Add Start
    -- 13.XXCMM:PaaSpÌVüÐõîñt@C¼iOICAgj
    gt_prf_val_new_emp_out_file := FND_PROFILE.VALUE( cv_prf_new_emp_out_file );
    -- vt@Cpe[uÉÝè
    ln_prf_idx := ln_prf_idx + 1;
    l_prf_tab(ln_prf_idx).prf_name  := cv_prf_new_emp_out_file;
    l_prf_tab(ln_prf_idx).prf_value := gt_prf_val_new_emp_out_file;
    --
-- Ver1.17 Add End
    -- vt@Cl`FbN
    <<prf_chk_loop>>
    FOR i IN 1..l_prf_tab.COUNT LOOP
      -- vt@ClªNULLÌê
      IF ( l_prf_tab(i).prf_value IS NULL ) THEN
        lv_errmsg :=  xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_xxcmm              -- AvP[VZk¼FXXCMM
                      , iv_name         => cv_prof_get_err_msg        -- bZ[W¼Fvt@Cæ¾G[bZ[W
                      , iv_token_name1  => cv_tkn_ng_profile          -- g[N¼1FNG_PROFILE
                      , iv_token_value1 => l_prf_tab(i).prf_name      -- g[Nl1Fvt@C
                      );
        lv_errbuf :=  lv_errmsg;
        RAISE global_process_expt;
      END IF;
    END LOOP prf_chk_loop;
--
    -- ==============================================================
    -- 3.fBNgpXæ¾
    -- ==============================================================
    BEGIN
      SELECT
          RTRIM( ad.directory_path , cv_slash )   AS  directory_path        -- fBNgpX
      INTO
          lt_dir_path
      FROM
          all_directories  ad     -- fBNgîñ
      WHERE
          ad.directory_name = gt_prf_val_out_file_dir
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_errbuf :=  xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_xxcoi             -- AvP[VZk¼FXXCOI
                      , iv_name         => cv_dir_path_get_err_msg   -- bZ[W¼FfBNgtpXæ¾G[bZ[W
                      , iv_token_name1  => cv_tkn_dir_tok            -- g[N¼1FDIR_TOK
                      , iv_token_value1 => gt_prf_val_out_file_dir   -- g[Nl1FfBNg¼
                      );
        --
        lv_errmsg :=  lv_errbuf;
        RAISE  global_process_expt;
    END;
--
    -- ==============================================================
    -- 4.vt@CluÐõf[^IFñõîúvÌút^Ï·
    -- ==============================================================
    BEGIN
      ld_1st_srch_date := TO_DATE( gt_prf_val_1st_srch_date , cv_datetime_fmt );
    EXCEPTION
      WHEN OTHERS THEN
        lv_errbuf :=  xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_xxcmm             -- AvP[VZk¼FXXCMM
                      , iv_name         => cv_to_date_err_msg        -- bZ[W¼Fút^Ï·G[bZ[W
                      , iv_token_name1  => cv_tkn_item               -- g[N¼1FITEM
                      , iv_token_value1 => cv_prf_1st_srch_date      -- g[Nl1Fvt@C¼
                      , iv_token_name2  => cv_tkn_value              -- g[N¼2FVALUE
                      , iv_token_value2 => gt_prf_val_1st_srch_date  -- g[Nl2Fvt@Cl
                      , iv_token_name3  => cv_tkn_format             -- g[N¼3FFORMAT
                      , iv_token_value3 => cv_datetime_fmt           -- g[Nl3FÏ·®
                      );
        --
        lv_errmsg :=  lv_errbuf;
        RAISE  global_process_expt;
    END;
--
    -- ==============================================================
    -- 5.IFt@C¼ÌoÍ
    -- ==============================================================
    ln_file_name_idx := 0;
    --
    -- ]ÆõîñAgf[^t@C¼
    ln_file_name_idx := ln_file_name_idx + 1;
    l_file_name_tab(ln_file_name_idx) := gt_prf_val_wrk_out_file;
    --
    -- ]Æõîñiã·EVKÌpÞEÒjAgf[^t@C¼
    ln_file_name_idx := ln_file_name_idx + 1;
    l_file_name_tab(ln_file_name_idx) := gt_prf_val_wrk2_out_file;
    --
    -- [U[îñAgf[^t@C¼
    ln_file_name_idx := ln_file_name_idx + 1;
    l_file_name_tab(ln_file_name_idx) := gt_prf_val_usr_out_file;
-- Ver1.2(E055) Add Start
    --
    -- [U[îñiíjAgf[^t@C¼
    ln_file_name_idx := ln_file_name_idx + 1;
    l_file_name_tab(ln_file_name_idx) := gt_prf_val_usr2_out_file;
-- Ver1.2(E055) Add End
    --
    -- PaaSpÌVK[U[îñt@C¼
    ln_file_name_idx := ln_file_name_idx + 1;
    l_file_name_tab(ln_file_name_idx) := gt_prf_val_new_usr_out_file;
    --
    -- PaaSpÌ]ÆõoïûÀîñt@C¼
    ln_file_name_idx := ln_file_name_idx + 1;
    l_file_name_tab(ln_file_name_idx) := gt_prf_val_emp_bnk_out_file;
    --
    -- PaaSpÌÐõ·ªîñt@C¼
    ln_file_name_idx := ln_file_name_idx + 1;
    l_file_name_tab(ln_file_name_idx) := gt_prf_val_emp_inf_out_file;
    --
-- Ver1.17 Add Start
    -- PaaSpÌVüÐõîñt@C¼
    ln_file_name_idx := ln_file_name_idx + 1;
    l_file_name_tab(ln_file_name_idx) := gt_prf_val_new_emp_out_file;
    --
-- Ver1.17 Add End
    <<file_name_out_loop>>
    FOR i IN 1..l_file_name_tab.COUNT LOOP
      --
      lv_msg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_appl_xxcmm             -- AvP[VZk¼FXXCMM
                , iv_name         => cv_if_file_name_msg       -- bZ[W¼FIFt@C¼oÍbZ[W
                , iv_token_name1  => cv_tkn_file_name          -- g[N¼1FFILE_NAME
                , iv_token_value1 => lt_dir_path
                                       || cv_slash
                                       || l_file_name_tab(i)   -- g[Nl1FfBNgpX{t@C¼
                );
      --
      FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => lv_msg
      );
    END LOOP file_name_out_loop;
    --
    -- ós}ü
    FND_FILE.PUT_LINE(
      which  => FND_FILE.OUTPUT
    , buff   => ''
    );
--
    -- ==============================================================
    -- 6.t@C¶Ý`FbN
    -- ==============================================================
    <<file_exist_chk_loop>>
    FOR i IN 1..l_file_name_tab.COUNT LOOP
      --
      UTL_FILE.FGETATTR(
        location     => gt_prf_val_out_file_dir
      , filename     => l_file_name_tab(i)
      , fexists      => lb_fexists
      , file_length  => ln_file_length
      , block_size   => ln_block_size
      );
      --
      IF ( lb_fexists = TRUE ) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application => cv_appl_xxcmm             -- AvP[VZk¼
                     , iv_name        => cv_file_exist_err_msg     -- bZ[WR[h
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
      END IF;
    END LOOP file_exist_chk_loop;
--
    -- ==============================================================
    -- 7.RJgvO¼A¨æÑOñúÌæ¾
    -- ==============================================================
    SELECT
        fcp.concurrent_program_name                    AS conc_program_name        -- RJgvO¼
      , NVL(xoipm.pre_process_date, ld_1st_srch_date)  AS pre_process_date         -- Oñú
      , (CASE
           WHEN xoipm.pre_process_date IS NOT NULL THEN
             cv_n
           ELSE
             cv_y
         END)                                          AS first_proc_flag          -- ñtO
    INTO
        gt_conc_program_name
      , gt_pre_process_date
      , gv_first_proc_flag
    FROM
        fnd_concurrent_programs    fcp       -- RJgvO
      , xxccp_oic_if_process_mng   xoipm     -- OICAgÇe[u
    WHERE
        fcp.concurrent_program_id   = cn_program_id
    AND fcp.concurrent_program_name = xoipm.program_name(+)
    FOR UPDATE OF xoipm.pre_process_date NOWAIT
    ;
--
    -- ==============================================================
    -- 8.¡ñúÌæ¾
    -- ==============================================================
    gt_cur_process_date := SYSDATE;
--
    -- ==============================================================
    -- 9.OñE¡ñúÌoÍ
    -- ==============================================================
    lv_msg := xxccp_common_pkg.get_msg(
                iv_application  => cv_appl_xxcmm             -- AvP[VZk¼FXXCMM
              , iv_name         => cv_process_date_msg       -- bZ[W¼FúoÍbZ[W
              , iv_token_name1  => cv_tkn_date1              -- g[N¼1FDATE1
              , iv_token_value1 => TO_CHAR(
                                     gt_pre_process_date
                                   , cv_datetime_fmt
                                   )                         -- g[Nl1FOñú
              , iv_token_name2  => cv_tkn_date2              -- g[N¼2FDATE2
              , iv_token_value2 => TO_CHAR(
                                     gt_cur_process_date
                                   , cv_datetime_fmt
                                   )                         -- g[Nl2F¡ñú
              );
    --
    FND_FILE.PUT_LINE(
      which  => FND_FILE.OUTPUT
    , buff   => lv_msg
    );
    -- ós}ü
    FND_FILE.PUT_LINE(
      which  => FND_FILE.OUTPUT
    , buff   => ''
    );
--
    -- ==============================================================
    -- 10.Æ±útÌæ¾
    -- ==============================================================
    ld_process_date := xxccp_common_pkg2.get_process_date;
--
    IF ( ld_process_date IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_xxcmm             -- AvP[VZk¼FXXCMM
                   , iv_name         => cv_proc_date_get_err_msg  -- bZ[W¼FÆ±útæ¾G[bZ[W
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    --
    lv_msg := xxccp_common_pkg.get_msg(
                iv_application  => cv_appl_xxcmm             -- AvP[VZk¼FXXCMM
              , iv_name         => cv_proc_date_msg          -- bZ[W¼FÆ±útoÍbZ[W
              , iv_token_name1  => cv_tkn_date               -- g[N¼1FDATE
              , iv_token_value1 => TO_CHAR(
                                     ld_process_date
                                   , cv_date_fmt
                                   )                         -- g[Nl1FÆ±útie[uj
              );
    --
    FND_FILE.PUT_LINE(
      which  => FND_FILE.OUTPUT
    , buff   => lv_msg
    );
    -- ós}ü
    FND_FILE.PUT_LINE(
      which  => FND_FILE.OUTPUT
    , buff   => ''
    );
--
    -- ==============================================================
    -- 11.AgútÌÝè
    -- ==============================================================
    IF ( iv_proc_date_for_recovery IS NOT NULL ) THEN
      gt_if_dest_date := TO_DATE( iv_proc_date_for_recovery , cv_datetime_fmt ) + 1;
    ELSE
      gt_if_dest_date := ld_process_date + 1;
    END IF;
    --
    lv_msg := xxccp_common_pkg.get_msg(
                iv_application  => cv_appl_xxcmm             -- AvP[VZk¼FXXCMM
              , iv_name         => cv_if_date_msg            -- bZ[W¼FAgútoÍbZ[W
              , iv_token_name1  => cv_tkn_date               -- g[N¼1FDATE
              , iv_token_value1 => TO_CHAR(
                                     gt_if_dest_date
                                   , cv_date_fmt
                                   )                         -- g[Nl1FAgút
              );
    --
    FND_FILE.PUT_LINE(
      which  => FND_FILE.OUTPUT
    , buff   => lv_msg
    );
    -- ós}ü
    FND_FILE.PUT_LINE(
      which  => FND_FILE.OUTPUT
    , buff   => ''
    );
--
    -- ==============================================================
    -- 12.Oñúi¶ñjÌÝè
    -- i]Æõ}X^AATCg}X^ÌDFFõpj
    -- ==============================================================
    gv_str_pre_process_date := TO_CHAR( gt_pre_process_date , cv_datetime_fmt );
--
    -- ==============================================================
    -- 13.t@CI[v
    -- ==============================================================
    BEGIN
      -- ]ÆõîñAgf[^t@C
      gf_wrk_file_handle      := UTL_FILE.FOPEN(
                                   location     => gt_prf_val_out_file_dir
                                 , filename     => gt_prf_val_wrk_out_file
                                 , open_mode    => cv_open_mode_w
                                 , max_linesize => cn_max_linesize
                                 );
      --
      -- ]Æõîñiã·EVKÌpÞEÒjAgf[^t@C
      gf_wrk2_file_handle     := UTL_FILE.FOPEN(
                                   location     => gt_prf_val_out_file_dir
                                 , filename     => gt_prf_val_wrk2_out_file
                                 , open_mode    => cv_open_mode_w
                                 , max_linesize => cn_max_linesize
                                 );
      --
      -- [U[îñAgf[^t@C
      gf_usr_file_handle      := UTL_FILE.FOPEN(
                                   location     => gt_prf_val_out_file_dir
                                 , filename     => gt_prf_val_usr_out_file
                                 , open_mode    => cv_open_mode_w
                                 , max_linesize => cn_max_linesize
                                 );
-- Ver1.2(E055) Add Start
      --
      -- [U[îñiíjAgf[^t@C
      gf_usr2_file_handle     := UTL_FILE.FOPEN(
                                   location     => gt_prf_val_out_file_dir
                                 , filename     => gt_prf_val_usr2_out_file
                                 , open_mode    => cv_open_mode_w
                                 , max_linesize => cn_max_linesize
                                 );
-- Ver1.2(E055) Add End
      --
      -- PaaSpÌVK[U[îñt@C
      gf_new_usr_file_handle  := UTL_FILE.FOPEN(
                                   location     => gt_prf_val_out_file_dir
                                 , filename     => gt_prf_val_new_usr_out_file
                                 , open_mode    => cv_open_mode_w
                                 , max_linesize => cn_max_linesize
                                 );
      --
      -- PaaSpÌ]ÆõoïûÀîñt@C
      gf_emp_bnk_file_handle  := UTL_FILE.FOPEN(
                                   location     => gt_prf_val_out_file_dir
                                 , filename     => gt_prf_val_emp_bnk_out_file
                                 , open_mode    => cv_open_mode_w
                                 , max_linesize => cn_max_linesize
                                 );
      --
      -- PaaSpÌÐõ·ªîñt@C
      gf_emp_inf_file_handle  := UTL_FILE.FOPEN(
                                   location     => gt_prf_val_out_file_dir
                                 , filename     => gt_prf_val_emp_inf_out_file
                                 , open_mode    => cv_open_mode_w
                                 , max_linesize => cn_max_linesize
                                 );
-- Ver1.17 Add Start
      --
      -- PaaSpÌVüÐõîñt@C
      gf_new_emp_file_handle  := UTL_FILE.FOPEN(
                                   location     => gt_prf_val_out_file_dir
                                 , filename     => gt_prf_val_new_emp_out_file
                                 , open_mode    => cv_open_mode_w
                                 , max_linesize => cn_max_linesize
                                 );
-- Ver1.17 Add End
  EXCEPTION
    WHEN OTHERS THEN
      lv_errmsg := SUBSTRB(
                     xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_xxcmm             -- AvP[VZk¼FXXCMM
                     , iv_name         => cv_file_open_err_msg      -- bZ[W¼Ft@CI[vG[bZ[W
                     , iv_token_name1  => cv_tkn_sqlerrm            -- g[N¼1FSQLERRM
                     , iv_token_value1 => SQLERRM                   -- g[Nl1FSQLERRM
                     )
                   , 1
                   , 5000
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END;
--
-- Ver1.18 Add Start
    -- ==============================================================
    -- 14.¡ñúi¶ñjÌÝè
    -- i]Æõ}X^AATCg}X^ÌDFFõpj
    -- ==============================================================
    gv_str_cur_process_date := TO_CHAR( gt_cur_process_date , cv_datetime_fmt );
--
-- Ver1.18 Add Start
  EXCEPTION
    -- *** bNG[áOnh ***
    WHEN global_lock_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_xxcmm             -- AvP[VZk¼FXXCMM
                   , iv_name         => cv_lock_err_msg           -- bZ[W¼FbNG[bZ[W
                   , iv_token_name1  => cv_tkn_ng_table           -- g[N¼1FNG_TABLE
                   , iv_token_value1 => cv_oic_proc_mng_tbl_msg   -- g[Nl1FOICAgÇe[u
                   );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  ÅèáO START   ####################################
--
    -- *** ¤ÊáOnh ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
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
  END init;
--
--
  /**********************************************************************************
   * Procedure Name   : output_worker
   * Description      : ]ÆõîñÌoEt@CoÍ(A-2)
   ***********************************************************************************/
  PROCEDURE output_worker(
    ov_errbuf     OUT VARCHAR2,     --   G[EbZ[W           --# Åè #
    ov_retcode    OUT VARCHAR2,     --   ^[ER[h             --# Åè #
    ov_errmsg     OUT VARCHAR2)     --   [U[EG[EbZ[W --# Åè #
  IS
    -- ===============================
    -- Åè[Jè
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'output_worker';       -- vO¼
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
    lv_wt_header_wrk     VARCHAR2(1);
    lv_wt_header_wrk2    VARCHAR2(1);
    lv_ass_header_wrk    VARCHAR2(1);
    lv_ass_header_wrk2   VARCHAR2(1);
--
    ------------------------------------
    --wb_[s(Worker)
    ------------------------------------
    cv_worker_header     CONSTANT VARCHAR2(10000) :=
                    'METADATA'                                                     --  1 : METADATA
      || cv_pipe || 'Worker'                                                       --  2 : Worker
      || cv_pipe || 'FLEX:PER_PERSONS_DFF'                                         --  3 : FLEX:PER_PERSONS_DFFiReLXgj
      || cv_pipe || 'PersonNumber'                                                 --  4 : PersonNumberiÂlÔj
      || cv_pipe || 'EffectiveStartDate'                                           --  5 : EffectiveStartDateiLøJnúj
      || cv_pipe || 'ActionCode'                                                   --  6 : ActionCodeiR[hj
      || cv_pipe || 'StartDate'                                                    --  7 : StartDateiJnúj
                                                                                   --      («PER_PERSONS_DFF=ITO_SALES_USE_ITEM)
      || cv_pipe || 'point(PER_PERSONS_DFF=ITO_SALES_USE_ITEM)'                    --  8 : pointi|Cg)
      || cv_pipe || 'qualificationCode(PER_PERSONS_DFF=ITO_SALES_USE_ITEM)'        --  9 : qualificationCodeiiR[h)
      || cv_pipe || 'employeeClass(PER_PERSONS_DFF=ITO_SALES_USE_ITEM)'            -- 10 : employeeClassi]Æõæª)
      || cv_pipe || 'vendorCode(PER_PERSONS_DFF=ITO_SALES_USE_ITEM)'               -- 11 : vendorCodeidüæR[h)
      || cv_pipe || 'representativeCarrier(PER_PERSONS_DFF=ITO_SALES_USE_ITEM)'    -- 12 : representativeCarrieri^ÆÒ)
      || cv_pipe || 'vendorsSiteCode(PER_PERSONS_DFF=ITO_SALES_USE_ITEM)'          -- 13 : vendorsSiteCodeidüæTCgR[h)
      || cv_pipe || 'qualificationCodeNew(PER_PERSONS_DFF=ITO_SALES_USE_ITEM)'     -- 14 : qualificationCodeNewiiR[hiVj)
      || cv_pipe || 'qualificationNameNew(PER_PERSONS_DFF=ITO_SALES_USE_ITEM)'     -- 15 : qualificationNameNewii¼iVj)
      || cv_pipe || 'qualificationCodeOld(PER_PERSONS_DFF=ITO_SALES_USE_ITEM)'     -- 16 : qualificationCodeOldiiR[hij)
      || cv_pipe || 'qualificationNameOld(PER_PERSONS_DFF=ITO_SALES_USE_ITEM)'     -- 17 : qualificationNameOldii¼ij)
      || cv_pipe || 'positionCodeNew(PER_PERSONS_DFF=ITO_SALES_USE_ITEM)'          -- 18 : positionCodeNewiEÊR[hiVj)
      || cv_pipe || 'positionNameNew(PER_PERSONS_DFF=ITO_SALES_USE_ITEM)'          -- 19 : positionNameNewiEÊ¼iVj)
      || cv_pipe || 'positionCodeOld(PER_PERSONS_DFF=ITO_SALES_USE_ITEM)'          -- 20 : positionCodeOldiEÊR[hij)
      || cv_pipe || 'positionNameOld(PER_PERSONS_DFF=ITO_SALES_USE_ITEM)'          -- 21 : positionNameOldiEÊ¼ij)
      || cv_pipe || 'jobCodeNew(PER_PERSONS_DFF=ITO_SALES_USE_ITEM)'               -- 22 : jobCodeNewiE±R[hiVj)
      || cv_pipe || 'jobNameNew(PER_PERSONS_DFF=ITO_SALES_USE_ITEM)'               -- 23 : jobNameNewiE±¼iVj)
      || cv_pipe || 'jobCodeOld(PER_PERSONS_DFF=ITO_SALES_USE_ITEM)'               -- 24 : jobCodeOldiE±R[hij)
      || cv_pipe || 'jobNameOld(PER_PERSONS_DFF=ITO_SALES_USE_ITEM)'               -- 25 : jobNameOldiE±¼ij)
      || cv_pipe || 'occupationalCodeNew(PER_PERSONS_DFF=ITO_SALES_USE_ITEM)'      -- 26 : occupationalCodeNewiEíR[hiVj)
      || cv_pipe || 'occupationalNameNew(PER_PERSONS_DFF=ITO_SALES_USE_ITEM)'      -- 27 : occupationalNameNewiEí¼iVj)
      || cv_pipe || 'occupationalCodeOld(PER_PERSONS_DFF=ITO_SALES_USE_ITEM)'      -- 28 : occupationalCodeOldiEíR[hij)
      || cv_pipe || 'occupationalNameOld(PER_PERSONS_DFF=ITO_SALES_USE_ITEM)'      -- 29 : occupationalNameOldiEí¼ij)
      || cv_pipe || 'DepartmentChild(PER_PERSONS_DFF=ITO_SALES_USE_ITEM)'          -- 30 : DepartmentChildi®å)
      || cv_pipe || 'referrenceDepartment(PER_PERSONS_DFF=ITO_SALES_USE_ITEM)'     -- 31 : referrenceDepartmentiÆïÍÍ)
      || cv_pipe || 'approvalDepartment(PER_PERSONS_DFF=ITO_SALES_USE_ITEM)'       -- 32 : approvalDepartmenti³FÒÍÍ)
      || cv_pipe || 'paymentMethod(PER_PERSONS_DFF=ITO_SALES_USE_ITEM)'            -- 33 : paymentMethodix¥û@)
      || cv_pipe || 'inquiryBaseCodeP(PER_PERSONS_DFF=ITO_SALES_USE_ITEM)'         -- 34 : inquiryBaseCodePiâ¹S_R[h)
                                                                                   --      (ªPER_PERSONS_DFF=ITO_SALES_USE_ITEM)
      || cv_pipe || 'SourceSystemOwner'                                            -- 35 : SourceSystemOwneri\[XEVXeLÒj
      || cv_pipe || 'SourceSystemId'                                               -- 36 : SourceSystemIdi\[XEVXeIDj
    ;
    --
    ------------------------------------
    --wb_[s(PersonName)
    ------------------------------------
    cv_per_name_header   CONSTANT VARCHAR2(3000) :=
                    'METADATA'                         --  1 : METADATA
      || cv_pipe || 'PersonName'                       --  2 : PersonName
      || cv_pipe || 'PersonNumber'                     --  3 : PersonNumberiÂlÔj
      || cv_pipe || 'NameType'                         --  4 : NameTypei¼O^Cvj
      || cv_pipe || 'EffectiveStartDate'               --  5 : EffectiveStartDateiLøJnúj
      || cv_pipe || 'LegislationCode'                  --  6 : LegislationCodeiÊdlR[hj
      || cv_pipe || 'FirstName'                        --  7 : FirstNamei¼j
      || cv_pipe || 'LastName'                         --  8 : LastNamei©j
      || cv_pipe || 'NameInformation1'                 --  9 : NameInformation1i¼Oîñ1j
      || cv_pipe || 'NameInformation2'                 -- 10 : NameInformation2i¼Oîñ2j
      || cv_pipe || 'SourceSystemOwner'                -- 11 : SourceSystemOwneri\[XEVXeLÒj
      || cv_pipe || 'SourceSystemId'                   -- 12 : SourceSystemIdi\[XEVXeIDj
    ;
    --
    ------------------------------------
    --wb_[s(PersonLegislativeData)
    ------------------------------------
    cv_per_legi_header   CONSTANT VARCHAR2(3000) :=
                    'METADATA'                         -- 1 : METADATA
      || cv_pipe || 'PersonLegislativeData'            -- 2 : PersonLegislativeData
      || cv_pipe || 'PersonNumber'                     -- 3 : PersonNumberiÂlÔj
      || cv_pipe || 'LegislationCode'                  -- 4 : LegislationCodeiÊdlR[hj
      || cv_pipe || 'EffectiveStartDate'               -- 5 : EffectiveStartDateiLøJnúj
      || cv_pipe || 'Sex'                              -- 6 : Sexi«Êj
      || cv_pipe || 'SourceSystemOwner'                -- 7 : SourceSystemOwneri\[XEVXeLÒj
      || cv_pipe || 'SourceSystemId'                   -- 8 : SourceSystemIdi\[XEVXeIDj
    ;
    --
    ------------------------------------
    --wb_[s(PersonEmail)
    ------------------------------------
    cv_per_email_header   CONSTANT VARCHAR2(3000) :=
                    'METADATA'                         -- 1 : METADATA
      || cv_pipe || 'PersonEmail'                      -- 2 : PersonEmail
      || cv_pipe || 'EmailAddress'                     -- 3 : EmailAddressiE[EAhXj
      || cv_pipe || 'EmailType'                        -- 4 : EmailTypeiE[E^Cvj
      || cv_pipe || 'PersonNumber'                     -- 5 : PersonNumberiÂlÔj
      || cv_pipe || 'DateFrom'                         -- 6 : DateFromiút: ©j
      || cv_pipe || 'SourceSystemOwner'                -- 7 : SourceSystemOwneri\[XEVXeLÒj
      || cv_pipe || 'SourceSystemId'                   -- 8 : SourceSystemIdi\[XEVXeIDj
    ;
    --
    ------------------------------------
    --wb_[s(WorkRelationship)
    ------------------------------------
    cv_wk_rel_header      CONSTANT VARCHAR2(3000) :=
                    'METADATA'                         --  1 : METADATA
      || cv_pipe || 'WorkRelationship'                 --  2 : WorkRelationship
      || cv_pipe || 'PersonNumber'                     --  3 : PersonNumberiÂlÔj
      || cv_pipe || 'WorkerType'                       --  4 : WorkerTypeiAÆÒ^Cvj
      || cv_pipe || 'DateStart'                        --  5 : DateStartiJnúj
      || cv_pipe || 'LegalEmployerName'                --  6 : LegalEmployerNameiÙpåj
      || cv_pipe || 'PrimaryFlag'                      --  7 : PrimaryFlagivC}Ùpj
      || cv_pipe || 'ActualTerminationDate'            --  8 : ActualTerminationDateiÀÑÞEúj
      || cv_pipe || 'TerminateWorkRelationshipFlag'    --  9 : TerminateWorkRelationshipFlagiÙpÖWÌI¹j
      || cv_pipe || 'ReverseTerminationFlag'           -- 10 : ReverseTerminationFlagiÞEÌæÁj
      || cv_pipe || 'ActionCode'                       -- 11 : ActionCodeiR[hj
      || cv_pipe || 'SourceSystemOwner'                -- 12 : SourceSystemOwneri\[XEVXeLÒj
      || cv_pipe || 'SourceSystemId'                   -- 13 : SourceSystemIdi\[XEVXeIDj
    ;
    --
    ------------------------------------
    --wb_[s(PersonUserInformation)
    ------------------------------------
    cv_per_user_header   CONSTANT VARCHAR2(3000) :=
                    'METADATA'                         -- 1 : METADATA
      || cv_pipe || 'PersonUserInformation'            -- 2 : PersonUserInformation
      || cv_pipe || 'UserName'                         -- 3 : UserNamei[U[¼j
      || cv_pipe || 'PersonNumber'                     -- 4 : PersonNumberiÂlÔj
      || cv_pipe || 'StartDate'                        -- 5 : StartDateiJnúj
      || cv_pipe || 'GeneratedUserAccountFlag'         -- 6 : GeneratedUserAccountFlagi¶¬Ï[U[EAJEgj
      || cv_pipe || 'SendCredentialsEmailFlag'         -- 7 : SendCredentialsEmailFlagiiØ¾E[ÌMj
    ;
    --
    ------------------------------------
    --wb_[s(WorkTerms)
    ------------------------------------
    cv_wk_terms_header   CONSTANT VARCHAR2(3000) :=
                    'METADATA'                         --  1 : METADATA
      || cv_pipe || 'WorkTerms'                        --  2 : WorkTerms
      || cv_pipe || 'AssignmentNumber'                 --  3 : AssignmentNumberiATCgÔj
      || cv_pipe || 'PersonNumber'                     --  4 : PersonNumberiÂlÔj
      || cv_pipe || 'WorkerType'                       --  5 : WorkerTypeiAÆÒ^Cvj
      || cv_pipe || 'DateStart'                        --  6 : DateStartiJnúj
      || cv_pipe || 'LegalEmployerName'                --  7 : LegalEmployerNameiÙpå¼j
      || cv_pipe || 'EffectiveLatestChange'            --  8 : EffectiveLatestChangeiLøÅIÏXj
      || cv_pipe || 'EffectiveStartDate'               --  9 : EffectiveStartDateiLøJnúj
      || cv_pipe || 'EffectiveSequence'                -- 10 : EffectiveSequenceiLøj
      || cv_pipe || 'AssignmentStatusTypeCode'         -- 11 : AssignmentStatusTypeCodeiATCgEXe[^XE^Cvj
      || cv_pipe || 'AssignmentType'                   -- 12 : AssignmentTypeiATCgE^Cvj
      || cv_pipe || 'AssignmentName'                   -- 13 : AssignmentNameiATCg¼j
      || cv_pipe || 'SystemPersonType'                 -- 14 : SystemPersonTypeiVXePerson^Cvj
      || cv_pipe || 'BusinessUnitShortCode'            -- 15 : BusinessUnitShortCodeirWlXEjbgj
      || cv_pipe || 'ActionCode'                       -- 16 : ActionCodeiR[hj
      || cv_pipe || 'PrimaryWorkTermsFlag'             -- 17 : PrimaryWorkTermsFlagiÙpÖWÌvC}Ùpðj
      || cv_pipe || 'SourceSystemOwner'                -- 18 : SourceSystemOwneri\[XEVXeLÒj
      || cv_pipe || 'SourceSystemId'                   -- 19 : SourceSystemIdi\[XEVXeIDj
    ;
    --
    ------------------------------------
    --wb_[s(Assignment)
    ------------------------------------
    cv_ass_header        CONSTANT VARCHAR2(10000) :=
                    'METADATA'                                                --  1 : METADATA
      || cv_pipe || 'Assignment'                                              --  2 : Assignment
      || cv_pipe || 'FLEX:PER_ASG_DF'                                         --  3 : FLEX:PER_ASG_DFiReLXgj
      || cv_pipe || 'AssignmentNumber'                                        --  4 : AssignmentNumberiATCgÔj
      || cv_pipe || 'WorkTermsNumber'                                         --  5 : WorkTermsNumberiÎ±ðÔj
      || cv_pipe || 'EffectiveLatestChange'                                   --  6 : EffectiveLatestChangeiLøÅIÏXj
      || cv_pipe || 'EffectiveStartDate'                                      --  7 : EffectiveStartDateiLøJnúj
      || cv_pipe || 'EffectiveSequence'                                       --  8 : EffectiveSequenceiLøj
      || cv_pipe || 'PersonTypeCode'                                          --  9 : PersonTypeCodeiPerson^Cvj
      || cv_pipe || 'AssignmentStatusTypeCode'                                -- 10 : AssignmentStatusTypeCodeiATCgEXe[^XE^Cvj
      || cv_pipe || 'AssignmentType'                                          -- 11 : AssignmentTypeiATCgE^Cvj
      || cv_pipe || 'SystemPersonType'                                        -- 12 : SystemPersonTypeiVXePerson^Cvj
      || cv_pipe || 'AssignmentName'                                          -- 13 : AssignmentNameiATCg¼j
      || cv_pipe || 'JobCode'                                                 -- 14 : JobCodeiWuER[hj
      || cv_pipe || 'DefaultExpenseAccount'                                   -- 15 : DefaultExpenseAccountiftHgïp¨èj
      || cv_pipe || 'BusinessUnitShortCode'                                   -- 16 : BusinessUnitShortCodeirWlXEjbgj
      || cv_pipe || 'ManagerFlag'                                             -- 17 : ManagerFlagi}l[Wj
      || cv_pipe || 'LocationCode'                                            -- 18 : LocationCodeiÆR[hj
      || cv_pipe || 'PersonNumber'                                            -- 19 : PersonNumberiÂlÔj
      || cv_pipe || 'ActionCode'                                              -- 20 : ActionCodeiR[hj
      || cv_pipe || 'WorkerType'                                              -- 21 : WorkerTypeiAÆÒ^Cvj
      || cv_pipe || 'DepartmentName'                                          -- 22 : DepartmentNameiåj
      || cv_pipe || 'DateStart'                                               -- 23 : DateStartiJnúj
      || cv_pipe || 'LegalEmployerName'                                       -- 24 : LegalEmployerNameiÙpå¼j
      || cv_pipe || 'PrimaryAssignmentFlag'                                   -- 25 : PrimaryAssignmentFlagiÙpÖWÌvC}EATCgj
                                                                              --      («PER_ASG_DF=ITO_SALES_USE_ITEM)
      || cv_pipe || 'transferReasonCode(PER_ASG_DF=ITO_SALES_USE_ITEM)'       -- 26 : transferReasonCodeiÙ®RR[h)
      || cv_pipe || 'announceDate(PER_ASG_DF=ITO_SALES_USE_ITEM)'             -- 27 : announceDatei­ßú)
      || cv_pipe || 'workLocDepartmentNew(PER_ASG_DF=ITO_SALES_USE_ITEM)'     -- 28 : workLocDepartmentNewiÎ±n_R[hiVj)
      || cv_pipe || 'workLocDepartmentOld(PER_ASG_DF=ITO_SALES_USE_ITEM)'     -- 29 : workLocDepartmentOldiÎ±n_R[hij)
      || cv_pipe || 'departmentNew(PER_ASG_DF=ITO_SALES_USE_ITEM)'            -- 30 : departmentNewi_R[hiVjj
      || cv_pipe || 'departmentOld(PER_ASG_DF=ITO_SALES_USE_ITEM)'            -- 31 : departmentOldi_R[hij)
      || cv_pipe || 'appWorkTimeCodeNew(PER_ASG_DF=ITO_SALES_USE_ITEM)'       -- 32 : appWorkTimeCodeNewiKpJ­Ô§R[hiVj)
      || cv_pipe || 'appWorkTimeNameNew(PER_ASG_DF=ITO_SALES_USE_ITEM)'       -- 33 : appWorkTimeNameNewiKpJ­¼iVj)
      || cv_pipe || 'appWorkTimeCodeOld(PER_ASG_DF=ITO_SALES_USE_ITEM)'       -- 34 : appWorkTimeCodeOldiKpJ­Ô§R[hij)
      || cv_pipe || 'appWorkTimeNameOld(PER_ASG_DF=ITO_SALES_USE_ITEM)'       -- 35 : appWorkTimeNameOldiKpJ­¼ij)
      || cv_pipe || 'positionSortCodeNew(PER_ASG_DF=ITO_SALES_USE_ITEM)'      -- 36 : positionSortCodeNewiEÊÀR[hiVj)
      || cv_pipe || 'positionSortCodeOld(PER_ASG_DF=ITO_SALES_USE_ITEM)'      -- 37 : positionSortCodeOldiEÊÀR[hij)
      || cv_pipe || 'approvalClassNew(PER_ASG_DF=ITO_SALES_USE_ITEM)'         -- 38 : approvalClassNewi³FæªiVj)
      || cv_pipe || 'approvalClassOld(PER_ASG_DF=ITO_SALES_USE_ITEM)'         -- 39 : approvalClassOldi³Fæªijj
      || cv_pipe || 'alternateClassNew(PER_ASG_DF=ITO_SALES_USE_ITEM)'        -- 40 : alternateClassNewiãsæªiVj)
      || cv_pipe || 'alternateClassOld(PER_ASG_DF=ITO_SALES_USE_ITEM)'        -- 41 : alternateClassOldiãsæªij)
      || cv_pipe || 'transferDateVend(PER_ASG_DF=ITO_SALES_USE_ITEM)'         -- 42 : transferDateVendi·ªAgpúti©Ì@j)
      || cv_pipe || 'transferDateRep(PER_ASG_DF=ITO_SALES_USE_ITEM)'          -- 43 : transferDateRepi·ªAgpúti [j)
                                                                              --      (ªPER_ASG_DF=ITO_SALES_USE_ITEM)
      || cv_pipe || 'SourceSystemOwner'                                       -- 44 : SourceSystemOwneri\[XEVXeLÒj
      || cv_pipe || 'SourceSystemId'                                          -- 45 : SourceSystemIdi\[XEVXeIDj
    ;
--
    -- *** [JÏ ***
    lv_file_data         VARCHAR2(30000) DEFAULT NULL;       -- oÍàe
--
    -- *** [JEJ[\ ***
    --------------------------------------
    -- AÆÒÌoJ[\
    --------------------------------------
    CURSOR worker_cur
    IS
      SELECT
          papf.employee_number                              AS employee_number            -- ]ÆõÔ
        , (SELECT
               TO_CHAR(MIN(papf3.effective_start_date), cv_date_fmt)
           FROM
               per_all_people_f     papf3  -- ]Æõ}X^
           WHERE
               papf3.person_id = papf.person_id
          )                                                 AS effective_start_date       -- LøJnú
-- Ver1.8 Mod Start
--        , TO_CHAR(papf.start_date, cv_date_fmt)             AS start_date                 -- Jnú
        , (SELECT
               TO_CHAR(MIN(papf4.effective_start_date), cv_date_fmt)
           FROM
               per_all_people_f     papf4  -- ]Æõ}X^
           WHERE
               papf4.person_id = papf.person_id
          )                                                 AS start_date                 -- Jnú
-- Ver1.8 Mod Start
        , papf.attribute1                                   AS attribute1                 -- |Cg
        , papf.attribute2                                   AS attribute2                 -- iR[h
        , papf.attribute3                                   AS attribute3                 -- ]Æõæª
        , papf.attribute4                                   AS attribute4                 -- düæR[h
        , papf.attribute5                                   AS attribute5                 -- ^ÆÒ
        , papf.attribute6                                   AS attribute6                 -- düæTCgR[h
        , papf.attribute7                                   AS attribute7                 -- iR[hiVj
        , papf.attribute8                                   AS attribute8                 -- i¼iVj
        , papf.attribute9                                   AS attribute9                 -- iR[hij
        , papf.attribute10                                  AS attribute10                -- i¼ij
        , papf.attribute11                                  AS attribute11                -- EÊR[hiVj
        , papf.attribute12                                  AS attribute12                -- EÊ¼iVj
        , papf.attribute13                                  AS attribute13                -- EÊR[hij
        , papf.attribute14                                  AS attribute14                -- EÊ¼ij
        , papf.attribute15                                  AS attribute15                -- E±R[hiVj
        , papf.attribute16                                  AS attribute16                -- E±¼iVj
        , papf.attribute17                                  AS attribute17                -- E±R[hij
        , papf.attribute18                                  AS attribute18                -- E±¼ij
        , papf.attribute19                                  AS attribute19                -- EíR[hiVj
        , papf.attribute20                                  AS attribute20                -- Eí¼iVj
        , papf.attribute21                                  AS attribute21                -- EíR[hij
        , papf.attribute22                                  AS attribute22                -- Eí¼ij
        , papf.attribute28                                  AS attribute28                -- ®å
        , papf.attribute29                                  AS attribute29                -- ÆïÍÍ
        , papf.attribute30                                  AS attribute30                -- ³FÒÍÍ
        , pvsa.pay_group_lookup_code                        AS pay_group_lookup_code      -- x¥O[v
        , pvsa.attribute5                                   AS inquiry_base_code_p        -- â¹S_R[h
        , papf.person_id                                    AS person_id                  -- ÂlID
        , (CASE
             WHEN papf.creation_date >= gt_pre_process_date THEN
               cv_y
             ELSE
               cv_n
           END)                                             AS new_reg_flag               -- VKo^tO
      FROM
          per_all_people_f     papf  -- ]Æõ}X^
        , po_vendors           pv    -- düæ}X^
        , po_vendor_sites_all  pvsa  -- düæTCg}X^
      WHERE
          papf.attribute3 IN (cv_emp_kbn_internal, cv_emp_kbn_external , cv_emp_kbn_dummy)  -- ]Æõæªi1:àA2:OA4:_~[j
      AND papf.attribute4 IS NULL    -- düæR[h
      AND papf.attribute5 IS NULL    -- ^ÆÒ
      AND papf.employee_number NOT IN (cv_not_get_emp1, cv_not_get_emp2, cv_not_get_emp3, cv_not_get_emp4, 
                                       cv_not_get_emp5, cv_not_get_emp6, cv_not_get_emp7, cv_not_get_emp8)  -- ]ÆõÔ
      AND papf.effective_start_date = 
              (SELECT
                   MAX(papf2.effective_start_date)
               FROM
                   per_all_people_f  papf2 -- ]Æõ}X^
               WHERE
                   papf2.person_id = papf.person_id
              )
      AND papf.person_id                = pv.employee_id(+)
      AND pv.vendor_type_lookup_code(+) = cv_vd_type_employee
      AND pv.vendor_id                  = pvsa.vendor_id(+)
-- Ver1.2(E056) Add Start
      AND pvsa.vendor_site_code(+)      = cv_site_code_comp
-- Ver1.2(E056) Add End
-- Ver1.18 Mod Start
--      AND (   papf.last_update_date >= gt_pre_process_date
---- Ver1.13 Mod Start
----           OR papf.attribute23      >= gv_str_pre_process_date)
--           OR papf.attribute23      >= gv_str_pre_process_date
--           OR pvsa.last_update_date >= gt_pre_process_date
--          )
---- Ver1.13 Mod End
      AND (   
              (     papf.last_update_date >= gt_pre_process_date
                AND papf.last_update_date <  gt_cur_process_date
              )
           OR (
                    papf.attribute23      >= gv_str_pre_process_date
                AND papf.attribute23      <  gv_str_cur_process_date
              )
           OR (
                    pvsa.last_update_date >= gt_pre_process_date
                AND pvsa.last_update_date <  gt_cur_process_date
              )
          )
-- Ver1.18 Mod End
      ORDER BY
          papf.employee_number ASC
    ;
--
    --------------------------------------
    -- Âl¼ÌoJ[\
    --------------------------------------
    CURSOR per_name_cur
    IS
      SELECT
          papf.employee_number                              AS employee_number            -- ]ÆõÔ
        , (SELECT
               TO_CHAR(MIN(papf3.effective_start_date), cv_date_fmt)
           FROM
               per_all_people_f  papf3  -- ]Æõ}X^
           WHERE
               papf3.person_id = papf.person_id
          )                                                 AS effective_start_date       -- LøJnú
        , papf.person_id                                    AS person_id                  -- ÂlID
        , papf.first_name                                   AS first_name                 -- ¼
        , papf.last_name                                    AS last_name                  -- ©
        , papf.per_information18                            AS per_information18          -- ¿©
        , papf.per_information19                            AS per_information19          -- ¿¼
        , (CASE
             WHEN papf.creation_date >= gt_pre_process_date THEN
               cv_y
             ELSE
               cv_n
           END)                                             AS new_reg_flag               -- VKo^tO
      FROM
          per_all_people_f       papf   -- ]Æõ}X^
        , po_vendors             pv     -- düæ}X^
      WHERE
          papf.attribute3 IN (cv_emp_kbn_internal, cv_emp_kbn_external , cv_emp_kbn_dummy)  -- ]Æõæªi1:àA2:OA4:_~[j
      AND papf.attribute4 IS NULL    -- düæR[h
      AND papf.attribute5 IS NULL    -- ^ÆÒ
      AND papf.employee_number NOT IN (cv_not_get_emp1, cv_not_get_emp2, cv_not_get_emp3, cv_not_get_emp4, 
                                       cv_not_get_emp5, cv_not_get_emp6, cv_not_get_emp7, cv_not_get_emp8)  -- ]ÆõÔ
      AND papf.effective_start_date = 
              (SELECT
                   MAX(papf2.effective_start_date)
               FROM
                   per_all_people_f  papf2 -- ]Æõ}X^
               WHERE
                   papf2.person_id = papf.person_id
              )
      AND papf.person_id                = pv.employee_id(+)
      AND pv.vendor_type_lookup_code(+) = cv_vd_type_employee
-- Ver1.18 Mod Start
--      AND (   papf.last_update_date >= gt_pre_process_date
--           OR papf.attribute23      >= gv_str_pre_process_date)
      AND (   
              (     papf.last_update_date >= gt_pre_process_date
                AND papf.last_update_date <  gt_cur_process_date
              )
           OR (
                    papf.attribute23      >= gv_str_pre_process_date
                AND papf.attribute23      <  gv_str_cur_process_date
              )
          )
-- Ver1.18 Mod End
      ORDER BY
          papf.employee_number ASC
    ;
--
    --------------------------------------
    -- ÂlÊdlf[^ÌoJ[\
    --------------------------------------
    CURSOR per_legi_cur
    IS
      SELECT
          papf.employee_number                              AS employee_number            -- ]ÆõÔ
        , (SELECT
               TO_CHAR(MIN(papf3.effective_start_date), cv_date_fmt)
           FROM
               per_all_people_f  papf3  -- ]Æõ}X^
           WHERE
               papf3.person_id = papf.person_id
          )                                                 AS effective_start_date       -- LøJnú
        , papf.person_id                                    AS person_id                  -- ÂlID
        , papf.sex                                          AS sex                        -- «Ê
        , (CASE
             WHEN papf.creation_date >= gt_pre_process_date THEN
               cv_y
             ELSE
               cv_n
           END)                                             AS new_reg_flag               -- VKo^tO
      FROM
          per_all_people_f       papf   -- ]Æõ}X^
        , po_vendors             pv     -- düæ}X^
      WHERE
          papf.attribute3 IN (cv_emp_kbn_internal, cv_emp_kbn_external , cv_emp_kbn_dummy)  -- ]Æõæªi1:àA2:OA4:_~[j
      AND papf.attribute4 IS NULL    -- düæR[h
      AND papf.attribute5 IS NULL    -- ^ÆÒ
      AND papf.employee_number NOT IN (cv_not_get_emp1, cv_not_get_emp2, cv_not_get_emp3, cv_not_get_emp4, 
                                       cv_not_get_emp5, cv_not_get_emp6, cv_not_get_emp7, cv_not_get_emp8)  -- ]ÆõÔ
      AND papf.effective_start_date = 
              (SELECT
                   MAX(papf2.effective_start_date)
               FROM
                   per_all_people_f  papf2  -- ]Æõ}X^
               WHERE
                   papf2.person_id = papf.person_id
              )
      AND papf.person_id                = pv.employee_id(+)
      AND pv.vendor_type_lookup_code(+) = cv_vd_type_employee
-- Ver1.18 Mod Start
--      AND (   papf.last_update_date >= gt_pre_process_date
--           OR papf.attribute23      >= gv_str_pre_process_date)
      AND (   
              (     papf.last_update_date >= gt_pre_process_date
                AND papf.last_update_date <  gt_cur_process_date
              )
           OR (
                    papf.attribute23      >= gv_str_pre_process_date
                AND papf.attribute23      <  gv_str_cur_process_date
              )
          )
-- Ver1.18 Mod End
      ORDER BY
          papf.employee_number ASC
    ;
--
    --------------------------------------
    -- ÂlE[ÌoJ[\
    --------------------------------------
    CURSOR per_email_cur
    IS
      SELECT
          papf.employee_number                              AS employee_number            -- ]ÆõÔ
        , (SELECT
               TO_CHAR(MIN(papf3.effective_start_date), cv_date_fmt)
           FROM
               per_all_people_f  papf3  -- ]Æõ}X^
           WHERE
               papf3.person_id = papf.person_id
           )                                                AS effective_start_date       -- LøJnú
        , papf.person_id                                    AS person_id                  -- ÂlID
        , (cv_itoen_email_suffix ||
           papf.employee_number  ||
           cv_itoen_email_domain)                           AS email_address              -- E[EAhX
      FROM
          per_all_people_f       papf   -- ]Æõ}X^
        , po_vendors             pv     -- düæ}X^
      WHERE
-- Ver1.10 Mod Start
--          papf.attribute3 IN (cv_emp_kbn_internal, cv_emp_kbn_external)  -- ]Æõæªi1:àA2:Oj
          papf.attribute3 IN (cv_emp_kbn_internal, cv_emp_kbn_external , cv_emp_kbn_dummy)  -- ]Æõæªi1:àA2:OA4:_~[j
-- Ver1.10 Mod End
      AND papf.attribute4 IS NULL    -- düæR[h
      AND papf.attribute5 IS NULL    -- ^ÆÒ
      AND papf.employee_number NOT IN (cv_not_get_emp1, cv_not_get_emp2, cv_not_get_emp3, cv_not_get_emp4, 
                                       cv_not_get_emp5, cv_not_get_emp6, cv_not_get_emp7, cv_not_get_emp8)  -- ]ÆõÔ
      AND papf.effective_start_date = 
              (SELECT
                   MAX(papf2.effective_start_date)
               FROM
                   per_all_people_f  papf2 -- ]Æõ}X^
               WHERE
                   papf2.person_id = papf.person_id
               )
      AND papf.person_id                = pv.employee_id(+)
      AND pv.vendor_type_lookup_code(+) = cv_vd_type_employee
-- Ver1.18 Mod Start
---- Ver1.10 Mod Start
----      AND (   papf.last_update_date >= gt_pre_process_date
----           OR papf.attribute23      >= gv_str_pre_process_date)
--      AND papf.creation_date >= gt_pre_process_date
---- Ver1.10 Mod End
      AND (
                papf.creation_date >= gt_pre_process_date
            AND papf.creation_date <  gt_cur_process_date
          )
-- Ver1.18 Mod End
      ORDER BY
          papf.employee_number ASC
    ;
--
    --------------------------------------
    -- ÙpÖWiÞEÒjÌoJ[\
    --------------------------------------
    CURSOR wk_rel_cur
    IS
      SELECT
          papf.employee_number                              AS employee_number            -- ]ÆõÔ
        , TO_CHAR(ppos.date_start, cv_date_fmt)             AS date_start                 -- Jnú
        , (CASE 
             WHEN xoedi.person_id IS NOT NULL THEN
               TO_CHAR(ppos.actual_termination_date, cv_date_fmt)
             ELSE 
               NULL
           END)                                             AS actual_termination_date    -- ÀÑÞEú
        , (CASE 
             WHEN (xoedi.person_id IS NOT NULL
                   AND  ppos.actual_termination_date IS NOT NULL) THEN
               cv_y
             ELSE 
               NULL
           END)                                             AS terminate_work_rel_flag    -- ÙpÖWÌI¹
        , (CASE 
             WHEN (xoedi.actual_termination_date IS NOT NULL
                   AND  ppos.actual_termination_date IS NULL) THEN
               cv_y
             ELSE 
               NULL
           END)                                             AS reverse_termination_flag   -- ÞEÌæÁ
        , (CASE 
             WHEN (xoedi.person_id IS NOT NULL
                   AND  ppos.actual_termination_date IS NOT NULL) THEN
               cv_act_cd_termination
-- Ver1.4 Add Start
             WHEN  xoedi_new.person_id IS NOT NULL THEN
               cv_act_cd_rehire
-- Ver1.4 Add End
             ELSE
               cv_act_cd_hire
           END)                                             AS action_code                -- R[h
        , ppos.period_of_service_id                         AS period_of_service_id       -- AÆîñID
        , (CASE
             WHEN ppos.creation_date >= gt_pre_process_date THEN
               cv_y
             ELSE
               cv_n
           END)                                             AS new_reg_flag               -- VKo^tO
      FROM
           per_all_people_f              papf      -- ]Æõ}X^
         , per_all_assignments_f         paaf      -- ATCg}X^
         , per_periods_of_service        ppos      -- AÆîñ
         , xxcmm_oic_emp_diff_info       xoedi     -- OICÐõ·ªîñe[u
-- Ver1.4 Add Start
         , xxcmm_oic_emp_diff_info       xoedi_new -- OICÐõ·ªîñe[uyVKz
-- Ver1.4 Add End
      WHERE
          papf.attribute3 IN (cv_emp_kbn_internal, cv_emp_kbn_external , cv_emp_kbn_dummy)  -- ]Æõæªi1:àA2:OA4:_~[j
      AND papf.attribute4 IS NULL    -- düæR[h
      AND papf.attribute5 IS NULL    -- ^ÆÒ
      AND papf.employee_number NOT IN (cv_not_get_emp1, cv_not_get_emp2, cv_not_get_emp3, cv_not_get_emp4, 
                                       cv_not_get_emp5, cv_not_get_emp6, cv_not_get_emp7, cv_not_get_emp8)  -- ]ÆõÔ
      AND papf.effective_start_date = 
              (SELECT
                   MAX(papf2.effective_start_date)
               FROM
                   per_all_people_f  papf2 -- ]Æõ}X^
               WHERE
                   papf2.person_id = papf.person_id
              )
      AND papf.person_id            = paaf.person_id
      AND paaf.period_of_service_id = ppos.period_of_service_id
      AND ppos.person_id            = xoedi.person_id(+)
      AND ppos.date_start           = xoedi.date_start(+)
-- Ver1.4 Add Start
      AND ppos.person_id            = xoedi_new.person_id(+)
-- Ver1.4 Add End
-- Ver1.18 Mod Start
--      AND ppos.last_update_date     >= gt_pre_process_date      
      AND (
                ppos.last_update_date >= gt_pre_process_date
            AND ppos.last_update_date <  gt_cur_process_date
          )
-- Ver1.18 Mod End
      ORDER BY
          papf.employee_number ASC
        , ppos.date_start ASC
    ;
--
    --------------------------------------
    -- [U[îñiVKjÌoJ[\
    --------------------------------------
    CURSOR new_user_cur
    IS
      -- [U[}X^ª¶Ý·éê
      SELECT
          fu.user_name                                      AS user_name                    -- [U[¼
        , papf.employee_number                              AS employee_number              -- ]ÆõÔ
        , TO_CHAR(fu.start_date, cv_date_fmt)               AS start_date                   -- Jnú
        , cv_y                                              AS generated_user_account_flag  -- ¶¬Ï[U[EAJEg
      FROM
          per_all_people_f     papf  -- ]Æõ}X^
        , fnd_user             fu    -- [U[}X^
      WHERE
          papf.attribute3 IN (cv_emp_kbn_internal, cv_emp_kbn_external , cv_emp_kbn_dummy)  -- ]Æõæªi1:àA2:OA4:_~[j
      AND papf.attribute4 IS NULL    -- düæR[h
      AND papf.attribute5 IS NULL    -- ^ÆÒ
      AND papf.employee_number NOT IN (cv_not_get_emp1, cv_not_get_emp2, cv_not_get_emp3, cv_not_get_emp4, 
                                       cv_not_get_emp5, cv_not_get_emp6, cv_not_get_emp7, cv_not_get_emp8)  -- ]ÆõÔ
      AND papf.effective_start_date = 
              (SELECT
                   MAX(papf2.effective_start_date)
               FROM
                   per_all_people_f  papf2 -- ]Æõ}X^
               WHERE
                   papf2.person_id = papf.person_id
              )
      AND papf.person_id     = fu.employee_id
-- Ver1.18 Mod Start
--      AND papf.creation_date >= gt_pre_process_date
--      AND fu.creation_date   >= gt_pre_process_date
      AND (
                papf.creation_date >= gt_pre_process_date
            AND papf.creation_date <  gt_cur_process_date
          )
      AND (
                fu.creation_date   >= gt_pre_process_date
            AND fu.creation_date   <  gt_cur_process_date
          )
-- Ver1.18 Mod End
      --
      UNION ALL
      -- [U[}X^ª¶ÝµÈ¢ê
      SELECT
          papf.employee_number                              AS user_name                    -- [U[¼
        , papf.employee_number                              AS employee_number              -- ]ÆõÔ
        , TO_CHAR(gt_if_dest_date, cv_date_fmt)             AS start_date                   -- Jnú
        , cv_n                                              AS generated_user_account_flag  -- ¶¬Ï[U[EAJEg
      FROM
          per_all_people_f     papf  -- ]Æõ}X^
      WHERE
          papf.attribute3 IN (cv_emp_kbn_internal, cv_emp_kbn_external , cv_emp_kbn_dummy)  -- ]Æõæªi1:àA2:OA4:_~[j
      AND papf.attribute4 IS NULL    -- düæR[h
      AND papf.attribute5 IS NULL    -- ^ÆÒ
      AND papf.employee_number NOT IN (cv_not_get_emp1, cv_not_get_emp2, cv_not_get_emp3, cv_not_get_emp4, 
                                       cv_not_get_emp5, cv_not_get_emp6, cv_not_get_emp7, cv_not_get_emp8)  -- ]ÆõÔ
      AND papf.effective_start_date = 
              (SELECT
                   MAX(papf2.effective_start_date)
               FROM
                   per_all_people_f  papf2 -- ]Æõ}X^
               WHERE
                   papf2.person_id = papf.person_id
              )
      AND NOT EXISTS (
              SELECT
                  1 AS flag
              FROM
                  fnd_user  fu    -- [U[}X^
              WHERE
                  fu.employee_id = papf.person_id
          )
-- Ver 1.2(E055) Mod Start
--      AND (papf.last_update_date >= gt_pre_process_date
--           OR
--           papf.attribute23 >= gv_str_pre_process_date
--           OR
--           EXISTS (
--               SELECT
--                   1 AS flag
--               FROM 
--                   per_all_assignments_f   paaf  -- ATCg}X^
--               WHERE
--                   paaf.person_id = papf.person_id
--               AND (paaf.last_update_date >= gt_pre_process_date
--                    OR
--                    paaf.ass_attribute19  >= gv_str_pre_process_date))
--          )
-- Ver1.18 Mod Start
--      AND papf.creation_date >= gt_pre_process_date
      AND (
                papf.creation_date >= gt_pre_process_date
            AND papf.creation_date <  gt_cur_process_date
          )
-- Ver1.18 Mod Start
-- Ver 1.2(E055) Mod End
      --
      ORDER BY
          employee_number ASC
    ;
--
    --------------------------------------
    -- ÙpðÌoJ[\
    --------------------------------------
    CURSOR wk_terms_cur
    IS
      SELECT
          (paaf.assignment_number || cv_wk_terms_suffix)    AS assignment_number          -- ATCgÔ
        , papf.employee_number                              AS employee_number            -- ]ÆõÔ
-- Ver1.4 Mod Start
--        , TO_CHAR(papf.start_date, cv_date_fmt)             AS start_date                 -- Jnú
        , TO_CHAR(ppos.date_start, cv_date_fmt)             AS start_date                 -- Jnú
-- Ver1.4 Mod End
        , (CASE
             WHEN xoedi.person_id IS NULL THEN
               TO_CHAR(paaf.effective_start_date, cv_date_fmt)
             ELSE
               TO_CHAR(gt_if_dest_date, cv_date_fmt)  -- Agút
           END)                                             AS effective_start_date       -- LøJnú
        , paaf.assignment_number                            AS assignment_name            -- ATCg¼
        , (cv_wt || paaf.assignment_id)                     AS source_system_id           -- \[XEVXeID
        , (CASE
             WHEN xoedi_new.person_id IS NULL THEN
               cv_act_cd_hire
             WHEN xoedi.person_id IS NULL THEN
               cv_act_cd_rehire
             ELSE
               cv_act_cd_mng_chg
           END)                                             AS action_code                -- R[h
        , (CASE
             WHEN xoedi.person_id IS NULL THEN
               cv_n
             WHEN NVL(xoedi.sup_assignment_number, '@') <> NVL(paaf_sup.assignment_number, '@') THEN
               cv_y
             ELSE
               cv_n
           END)                                             AS sup_chg_flag               -- ã·ÏXtO
      FROM
          per_all_people_f            papf      -- ]Æõ}X^
        , per_all_assignments_f       paaf      -- ATCg}X^
        , per_periods_of_service      ppos      -- AÆîñ
        , xxcmm_oic_emp_diff_info     xoedi_new -- OICÐõ·ªîñe[uyVKz
        , xxcmm_oic_emp_diff_info     xoedi     -- OICÐõ·ªîñe[u
        , (SELECT
               paaf_s.person_id           AS person_id           -- ÂlID
             , paaf_s.assignment_number   AS assignment_number   -- ATCgÔ
           FROM
               per_all_assignments_f    paaf_s  -- ATCg}X^(ã·)
             , per_periods_of_service   ppos_s  -- AÆîñ(ã·)
           WHERE
               paaf_s.period_of_service_id = ppos_s.period_of_service_id
           AND ppos_s.actual_termination_date IS NULL
          )                           paaf_sup  -- ATCg}X^(ã·)
      WHERE
          papf.attribute3 IN (cv_emp_kbn_internal, cv_emp_kbn_external , cv_emp_kbn_dummy)  -- ]Æõæªi1:àA2:OA4:_~[j
      AND papf.attribute4 IS NULL    -- düæR[h
      AND papf.attribute5 IS NULL    -- ^ÆÒ
      AND papf.employee_number NOT IN (cv_not_get_emp1, cv_not_get_emp2, cv_not_get_emp3, cv_not_get_emp4, 
                                       cv_not_get_emp5, cv_not_get_emp6, cv_not_get_emp7, cv_not_get_emp8)  -- ]ÆõÔ
      AND papf.effective_start_date = 
              (SELECT
                   MAX(papf2.effective_start_date)
               FROM
                   per_all_people_f  papf2 -- ]Æõ}X^
               WHERE
                   papf2.person_id = papf.person_id
              )
      AND papf.person_id = paaf.person_id
      AND paaf.effective_start_date = 
              (SELECT
                   MAX(paaf2.effective_start_date)
               FROM
                   per_all_assignments_f   paaf2  -- ATCg}X^
               WHERE
                   paaf2.person_id = paaf.person_id
              )
      AND paaf.period_of_service_id = ppos.period_of_service_id
      AND ppos.person_id            = xoedi_new.person_id(+)
      AND ppos.person_id            = xoedi.person_id(+)
      AND ppos.date_start           = xoedi.date_start(+)
      AND paaf.supervisor_id        = paaf_sup.person_id(+)
      AND (   ppos.actual_termination_date IS NULL
           OR xoedi.person_id IS NULL)
-- Ver1.18 Mod Start
--      AND (   paaf.last_update_date >= gt_pre_process_date
--           OR paaf.ass_attribute19  >= gv_str_pre_process_date)
      AND (   
              (     paaf.last_update_date >= gt_pre_process_date
                AND paaf.last_update_date <  gt_cur_process_date
              )
           OR (
                    paaf.ass_attribute19  >= gv_str_pre_process_date
                AND paaf.ass_attribute19  <  gv_str_cur_process_date
              )
          )
-- Ver1.18 Mod End
      ORDER BY
          papf.employee_number ASC
    ;
--
    --------------------------------------
    -- ATCgÌoJ[\
    --------------------------------------
    CURSOR ass_cur
    IS
      SELECT
          paaf.assignment_number                            AS assignment_number          -- ATCgÔ
        , (paaf.assignment_number || cv_wk_terms_suffix)    AS work_terms_number          -- Î±ðÔ
        , (CASE
             WHEN xoedi.person_id IS NULL THEN
               TO_CHAR(paaf.effective_start_date, cv_date_fmt)
             ELSE
               TO_CHAR(gt_if_dest_date, cv_date_fmt)  -- Agút
           END)                                             AS effective_start_date       -- LøJnú
        , paaf.assignment_type                              AS assignment_type            -- ATCgE^Cv
        , pjd.segment3                                      AS job_code                   -- ðER[h
        , (CASE
             WHEN gcc.code_combination_id IS NOT NULL THEN
               (gcc.segment1               || cv_hyphen ||
                gcc.segment2               || cv_hyphen ||
                gt_prf_val_def_account_cd  || cv_hyphen ||
                gt_prf_val_def_sub_acct_cd || cv_hyphen ||
                gcc.segment5               || cv_hyphen ||
                gcc.segment6               || cv_hyphen ||
                gcc.segment7               || cv_hyphen ||
                gcc.segment8
               )
             ELSE
               NULL
           END)                                             AS default_expense_account    -- ftHgïp¨è
        , (CASE
             WHEN
               (SELECT
                    COUNT(1)  AS cnt
                FROM 
                    per_all_assignments_f   paaf_staff  -- ATCg}X^(º)
                  , per_periods_of_service  ppos_staff  -- AÆîñ(º)
                WHERE 
                    paaf_staff.supervisor_id        = paaf.person_id
                AND paaf_staff.period_of_service_id = ppos_staff.period_of_service_id
                AND ppos_staff.actual_termination_date IS NULL
               ) > 0 THEN 
               cv_y
             ELSE
               NULL
           END)                                             AS manager_flag               -- }l[W
        , hla.location_code                                 AS location_code              -- ÆR[h
        , papf.employee_number                              AS employee_number            -- ]ÆõÔ
-- Ver1.4 Mod Start
--        , TO_CHAR(papf.start_date, cv_date_fmt)             AS start_date                 -- Jnú
        , TO_CHAR(ppos.date_start, cv_date_fmt)             AS start_date                 -- Jnú
-- Ver1.4 Mod End
        , paaf.primary_flag                                 AS primary_flag               -- vC}EtO
        , paaf.ass_attribute1                               AS ass_attribute1             -- Ù®RR[h
        , paaf.ass_attribute2                               AS ass_attribute2             -- ­ßú
        , paaf.ass_attribute3                               AS ass_attribute3             -- Î±n_R[h(V)
        , paaf.ass_attribute4                               AS ass_attribute4             -- Î±n_R[h()
        , paaf.ass_attribute5                               AS ass_attribute5             -- _R[h(V)
        , paaf.ass_attribute6                               AS ass_attribute6             -- _R[h()
        , paaf.ass_attribute7                               AS ass_attribute7             -- KpJ­Ô§R[h(V)
        , paaf.ass_attribute8                               AS ass_attribute8             -- KpJ­¼(V)
        , paaf.ass_attribute9                               AS ass_attribute9             -- KpJ­Ô§R[h()
        , paaf.ass_attribute10                              AS ass_attribute10            -- KpJ­¼()
        , paaf.ass_attribute11                              AS ass_attribute11            -- EÊÀR[h(V)
        , paaf.ass_attribute12                              AS ass_attribute12            -- EÊÀR[h()
        , paaf.ass_attribute13                              AS ass_attribute13            -- ³Fæª(V)
        , paaf.ass_attribute14                              AS ass_attribute14            -- ³Fæª()
        , paaf.ass_attribute15                              AS ass_attribute15            -- ãsæª(V)
        , paaf.ass_attribute16                              AS ass_attribute16            -- ãsæª()
        , paaf.ass_attribute17                              AS ass_attribute17            -- ·ªAgpút(©Ì@)
        , paaf.ass_attribute18                              AS ass_attribute18            -- ·ªAgpút( [)
        , paaf.assignment_id                                AS source_system_id           -- \[XEVXeID
        , (CASE
             WHEN paaf.creation_date >= gt_pre_process_date THEN
               cv_y
             ELSE
               cv_n
           END)                                             AS new_reg_flag               -- VKo^tO
        , (CASE
             WHEN xoedi_new.person_id IS NULL THEN
               cv_act_cd_hire
             WHEN xoedi.person_id IS NULL THEN
               cv_act_cd_rehire
             ELSE
               cv_act_cd_mng_chg
           END)                                             AS action_code                -- R[h
        , (CASE
             WHEN xoedi.person_id IS NULL THEN
               cv_n
             WHEN NVL(xoedi.sup_assignment_number, '@') <> NVL(paaf_sup.assignment_number, '@') THEN
               cv_y
             ELSE
               cv_n
           END)                                             AS sup_chg_flag               -- ã·ÏXtO
      FROM
          per_all_people_f            papf      -- ]Æõ}X^
        , per_all_assignments_f       paaf      -- ATCg}X^
        , per_jobs                    pj        -- ðE}X^
        , per_job_definitions         pjd       -- ðEè`}X^
        , hr_locations_all            hla       -- Æ}X^
        , gl_code_combinations        gcc       -- ¨èÈÚg¹
        , per_periods_of_service      ppos      -- AÆîñ
        , xxcmm_oic_emp_diff_info     xoedi_new -- OICÐõ·ªîñe[uyVKz
        , xxcmm_oic_emp_diff_info     xoedi     -- OICÐõ·ªîñe[u
        , (SELECT
               paaf_s.person_id           AS person_id           -- ÂlID
             , paaf_s.assignment_number   AS assignment_number   -- ATCgÔ
           FROM
               per_all_assignments_f    paaf_s  -- ATCg}X^(ã·)
             , per_periods_of_service   ppos_s  -- AÆîñ(ã·)
           WHERE
               paaf_s.period_of_service_id = ppos_s.period_of_service_id
           AND ppos_s.actual_termination_date IS NULL
          )                           paaf_sup  -- ATCg}X^(ã·)
      WHERE
          papf.attribute3 IN (cv_emp_kbn_internal, cv_emp_kbn_external , cv_emp_kbn_dummy)  -- ]Æõæªi1:àA2:OA4:_~[j
      AND papf.attribute4 IS NULL    -- düæR[h
      AND papf.attribute5 IS NULL    -- ^ÆÒ
      AND papf.employee_number NOT IN (cv_not_get_emp1, cv_not_get_emp2, cv_not_get_emp3, cv_not_get_emp4, 
                                       cv_not_get_emp5, cv_not_get_emp6, cv_not_get_emp7, cv_not_get_emp8)  -- ]ÆõÔ
      AND papf.effective_start_date = 
             (SELECT
                  MAX(papf2.effective_start_date)
              FROM
                  per_all_people_f  papf2 -- ]Æõ}X^
              WHERE
                  papf2.person_id = papf.person_id
             )
      AND papf.person_id = paaf.person_id
      AND paaf.effective_start_date = 
             (SELECT
                  MAX(paaf2.effective_start_date)
              FROM
                  per_all_assignments_f  paaf2  -- ATCg}X^
              WHERE
                  paaf2.person_id = paaf.person_id
             )
      AND paaf.job_id               = pj.job_id(+)
      AND pj.job_definition_id      = pjd.job_definition_id(+)
      AND paaf.default_code_comb_id = gcc.code_combination_id(+)
      AND paaf.location_id          = hla.location_id(+)
      AND paaf.period_of_service_id = ppos.period_of_service_id
      AND ppos.person_id            = xoedi_new.person_id(+)
      AND ppos.person_id            = xoedi.person_id(+)
      AND ppos.date_start           = xoedi.date_start(+)
      AND paaf.supervisor_id        = paaf_sup.person_id(+)
      AND (   ppos.actual_termination_date IS NULL
           OR xoedi.person_id IS NULL)
-- Ver1.18 Mod Start
--      AND (   paaf.last_update_date >= gt_pre_process_date
--           OR paaf.ass_attribute19  >= gv_str_pre_process_date)
           
      AND (   
              (     paaf.last_update_date >= gt_pre_process_date
                AND paaf.last_update_date <  gt_cur_process_date
              )
           OR (
                    paaf.ass_attribute19  >= gv_str_pre_process_date
                AND paaf.ass_attribute19  <  gv_str_cur_process_date
              )
          )
-- Ver1.18 Mod End
      ORDER BY
          paaf.assignment_number ASC
    ;
--
    -- *** [JER[h ***
    l_worker_rec       worker_cur%ROWTYPE;        -- AÆÒÌoJ[\R[h
    l_per_name_rec     per_name_cur%ROWTYPE;      -- Âl¼ÌoJ[\R[h
    l_per_legi_rec     per_legi_cur%ROWTYPE;      -- ÂlÊdlf[^ÌoJ[\R[h
    l_per_email_rec    per_email_cur%ROWTYPE;     -- ÂlE[ÌoJ[\R[h
    l_wk_rel_rec       wk_rel_cur%ROWTYPE;        -- ÙpÖWiÞEÒjÌoJ[\R[h
    l_new_user_rec     new_user_cur%ROWTYPE;      -- [U[îñiVKjÌoJ[\R[h
    l_wk_terms_rec     wk_terms_cur%ROWTYPE;      -- ÙpðÌoJ[\R[h
    l_ass_rec          ass_cur%ROWTYPE;           -- ATCgÌoJ[\R[h
--
  BEGIN
--
--##################  ÅèXe[^Xú» START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  Åè END   ############################
--
    -- [JÏÌú»
    lv_wt_header_wrk   := cv_n;
    lv_wt_header_wrk2  := cv_n;
    lv_ass_header_wrk  := cv_n;
    lv_ass_header_wrk2 := cv_n;
--
    -- ==============================================================
    -- AÆÒÌo(A-2-1)
    -- ==============================================================
    -- J[\I[v
    OPEN worker_cur;
    <<output_worker_loop>>
    LOOP
      --
      FETCH worker_cur INTO l_worker_rec;
      EXIT WHEN worker_cur%NOTFOUND;
      --
      -- oJEgAbv
      gn_get_wk_cnt := gn_get_wk_cnt + 1;
      --
      -- ==============================================================
      -- AÆÒÌt@CoÍ(A-2-2)
      -- ==============================================================
      -- wb_[sÌì¬iñÌÝj
      IF ( gn_get_wk_cnt = 1 ) THEN
        --
        BEGIN
          -- wb_[sÌt@CoÍ
          UTL_FILE.PUT_LINE( gf_wrk_file_handle  -- ]ÆõîñAgf[^t@C
                           , cv_worker_header
                           );
        EXCEPTION
          WHEN OTHERS THEN
            RAISE global_fileout_expt;
        END;
      END IF;
      --
      -- f[^sÌì¬
      lv_file_data := cv_meta_merge;                                                 --  1 : METADATA
      lv_file_data := lv_file_data || cv_pipe || cv_cls_worker;                      --  2 : Worker
      lv_file_data := lv_file_data || cv_pipe || cv_per_persons_dff;                 --  3 : FLEX:PER_PERSONS_DFFiReLXgj
      lv_file_data := lv_file_data || cv_pipe || l_worker_rec.employee_number;       --  4 : PersonNumberiÂlÔj
      lv_file_data := lv_file_data || cv_pipe || l_worker_rec.effective_start_date;  --  5 : EffectiveStartDateiLøJnúj
      lv_file_data := lv_file_data || cv_pipe || cv_act_cd_hire;                     --  6 : ActionCodeiR[hj
      lv_file_data := lv_file_data || cv_pipe || l_worker_rec.start_date;            --  7 : StartDateiJnúj
                                                                                     --      («PER_PERSONS_DFF=ITO_SALES_USE_ITEM)
      lv_file_data := lv_file_data || cv_pipe || 
                      nvl_for_hdl( l_worker_rec.attribute1
                                 , l_worker_rec.new_reg_flag
-- Ver1.3 Mod Start
--                                 , cv_nvl_n
                                 , cv_nvl_v
-- Ver1.3 Mod End
                                 );                                                  --  8 : pointi|Cg)
      lv_file_data := lv_file_data || cv_pipe || 
                      nvl_for_hdl( l_worker_rec.attribute2
                                 , l_worker_rec.new_reg_flag
                                 , cv_nvl_v
                                 );                                                  --  9 : qualificationCodeiiR[h)

      lv_file_data := lv_file_data || cv_pipe || l_worker_rec.attribute3;            -- 10 : employeeClassi]Æõæª)
      lv_file_data := lv_file_data || cv_pipe || 
                      nvl_for_hdl( l_worker_rec.attribute4
                                 , l_worker_rec.new_reg_flag
                                 , cv_nvl_v
                                 );                                                  -- 11 : vendorCodeidüæR[h)
      lv_file_data := lv_file_data || cv_pipe || 
                      nvl_for_hdl( l_worker_rec.attribute5
                                 , l_worker_rec.new_reg_flag
                                 , cv_nvl_v
                                 );                                                  -- 12 : representativeCarrieri^ÆÒ)
      lv_file_data := lv_file_data || cv_pipe || 
                      nvl_for_hdl( l_worker_rec.attribute6
                                 , l_worker_rec.new_reg_flag
                                 , cv_nvl_v
                                 );                                                  -- 13 : vendorsSiteCodeidüæTCgR[h)
      lv_file_data := lv_file_data || cv_pipe || 
                      nvl_for_hdl( l_worker_rec.attribute7
                                 , l_worker_rec.new_reg_flag
                                 , cv_nvl_v
                                 );                                                  -- 14 : qualificationCodeNewiiR[hiVj)
      lv_file_data := lv_file_data || cv_pipe || 
                      nvl_for_hdl( l_worker_rec.attribute8
                                 , l_worker_rec.new_reg_flag
                                 , cv_nvl_v
                                 );                                                  -- 15 : qualificationNameNewii¼iVj)
      lv_file_data := lv_file_data || cv_pipe || 
                      nvl_for_hdl( l_worker_rec.attribute9
                                 , l_worker_rec.new_reg_flag
                                 , cv_nvl_v
                                 );                                                  -- 16 : qualificationCodeOldiiR[hij)
      lv_file_data := lv_file_data || cv_pipe || 
                      nvl_for_hdl( l_worker_rec.attribute10
                                 , l_worker_rec.new_reg_flag
                                 , cv_nvl_v
                                 );                                                  -- 17 : qualificationNameOldii¼ij)
      lv_file_data := lv_file_data || cv_pipe || 
                      nvl_for_hdl( l_worker_rec.attribute11
                                 , l_worker_rec.new_reg_flag
                                 , cv_nvl_v
                                 );                                                  -- 18 : positionCodeNewiEÊR[hiVj)
      lv_file_data := lv_file_data || cv_pipe || 
                      nvl_for_hdl( l_worker_rec.attribute12
                                 , l_worker_rec.new_reg_flag
                                 , cv_nvl_v
                                 );                                                  -- 19 : positionNameNewiEÊ¼iVj)
      lv_file_data := lv_file_data || cv_pipe || 
                      nvl_for_hdl( l_worker_rec.attribute13
                                 , l_worker_rec.new_reg_flag
                                 , cv_nvl_v
                                 );                                                  -- 20 : positionCodeOldiEÊR[hij)
      lv_file_data := lv_file_data || cv_pipe || 
                      nvl_for_hdl( l_worker_rec.attribute14
                                 , l_worker_rec.new_reg_flag
                                 , cv_nvl_v
                                 );                                                  -- 21 : positionNameOldiEÊ¼ij)
      lv_file_data := lv_file_data || cv_pipe || 
                      nvl_for_hdl( l_worker_rec.attribute15
                                 , l_worker_rec.new_reg_flag
                                 , cv_nvl_v
                                 );                                                  -- 22 : jobCodeNewiE±R[hiVj)
      lv_file_data := lv_file_data || cv_pipe || 
                      nvl_for_hdl( l_worker_rec.attribute16
                                 , l_worker_rec.new_reg_flag
                                 , cv_nvl_v
                                 );                                                  -- 23 : jobNameNewiE±¼iVj)
      lv_file_data := lv_file_data || cv_pipe || 
                      nvl_for_hdl( l_worker_rec.attribute17
                                 , l_worker_rec.new_reg_flag
                                 , cv_nvl_v
                                 );                                                  -- 24 : jobCodeOldiE±R[hij)
      lv_file_data := lv_file_data || cv_pipe || 
                      nvl_for_hdl( l_worker_rec.attribute18
                                 , l_worker_rec.new_reg_flag
                                 , cv_nvl_v
                                 );                                                  -- 25 : jobNameOldiE±¼ij)
      lv_file_data := lv_file_data || cv_pipe || 
                      nvl_for_hdl( l_worker_rec.attribute19
                                 , l_worker_rec.new_reg_flag
                                 , cv_nvl_v
                                 );                                                  -- 26 : occupationalCodeNewiEíR[hiVj)
      lv_file_data := lv_file_data || cv_pipe || 
                      nvl_for_hdl( l_worker_rec.attribute20
                                 , l_worker_rec.new_reg_flag
                                 , cv_nvl_v
                                 );                                                  -- 27 : occupationalNameNewiEí¼iVj)
      lv_file_data := lv_file_data || cv_pipe || 
                      nvl_for_hdl( l_worker_rec.attribute21
                                 , l_worker_rec.new_reg_flag
                                 , cv_nvl_v
                                 );                                                  -- 28 : occupationalCodeOldiEíR[hij)
      lv_file_data := lv_file_data || cv_pipe || 
                      nvl_for_hdl( l_worker_rec.attribute22
                                 , l_worker_rec.new_reg_flag
                                 , cv_nvl_v
                                 );                                                  -- 29 : occupationalNameOldiEí¼ij)
      lv_file_data := lv_file_data || cv_pipe || 
                      nvl_for_hdl( l_worker_rec.attribute28
                                 , l_worker_rec.new_reg_flag
                                 , cv_nvl_v
                                 );                                                  -- 30 : DepartmentChildi®å)
      lv_file_data := lv_file_data || cv_pipe || 
                      nvl_for_hdl( l_worker_rec.attribute29
                                 , l_worker_rec.new_reg_flag
                                 , cv_nvl_v
                                 );                                                  -- 31 : referrenceDepartmentiÆïÍÍ)
      lv_file_data := lv_file_data || cv_pipe || 
                      nvl_for_hdl( l_worker_rec.attribute30
                                 , l_worker_rec.new_reg_flag
                                 , cv_nvl_v
                                 );                                                  -- 32 : approvalDepartmenti³FÒÍÍ)
      lv_file_data := lv_file_data || cv_pipe || 
                      nvl_for_hdl( l_worker_rec.pay_group_lookup_code
                                 , l_worker_rec.new_reg_flag
                                 , cv_nvl_v
                                 );                                                  -- 33 : paymentMethodix¥û@)
      lv_file_data := lv_file_data || cv_pipe || 
                      nvl_for_hdl( l_worker_rec.inquiry_base_code_p
                                 , l_worker_rec.new_reg_flag
                                 , cv_nvl_v
                                 );                                                  -- 34 : inquiryBaseCodePiâ¹S_R[h)
                                                                                     --      (ªPER_PERSONS_DFF=ITO_SALES_USE_ITEM)
      lv_file_data := lv_file_data || cv_pipe || cv_ebs;                             -- 35 : SourceSystemOwneri\[XEVXeLÒj
      lv_file_data := lv_file_data || cv_pipe || l_worker_rec.person_id;             -- 36 : SourceSystemIdi\[XEVXeIDj
      --
      BEGIN
        -- f[^sÌt@CoÍ
        UTL_FILE.PUT_LINE( gf_wrk_file_handle  -- ]ÆõîñAgf[^t@C
                         , lv_file_data
                         );
        -- oÍJEgAbv
        gn_out_wk_cnt := gn_out_wk_cnt + 1;
      EXCEPTION
        WHEN OTHERS THEN
          RAISE global_fileout_expt;
      END;
    --
    END LOOP output_worker_loop;
--
    -- oª1Èã éê
    IF ( gn_get_wk_cnt > 0 ) THEN
      BEGIN
        -- ósðt@CoÍ
        UTL_FILE.PUT_LINE( gf_wrk_file_handle  -- ]ÆõîñAgf[^t@C
                         , ''
                         );
      EXCEPTION
        WHEN OTHERS THEN
          RAISE global_fileout_expt;
      END;
    END IF;
--
    -- J[\N[Y
    CLOSE worker_cur;
--
--
    -- ==============================================================
    -- Âl¼Ìo(A-2-3)
    -- ==============================================================
    -- J[\I[v
    OPEN per_name_cur;
    <<output_per_name_loop>>
    LOOP
      --
      FETCH per_name_cur INTO l_per_name_rec;
      EXIT WHEN per_name_cur%NOTFOUND;
      --
      -- oJEgAbv
      gn_get_per_name_cnt := gn_get_per_name_cnt + 1;
      --
      -- ==============================================================
      -- Âl¼Ìt@CoÍ(A-2-4)
      -- ==============================================================
      -- wb_[sÌì¬iñÌÝj
      IF ( gn_get_per_name_cnt = 1 ) THEN
        --
        BEGIN
          -- wb_[sÌt@CoÍ
          UTL_FILE.PUT_LINE( gf_wrk_file_handle  -- ]ÆõîñAgf[^t@C
                           , cv_per_name_header
                           );
        EXCEPTION
          WHEN OTHERS THEN
            RAISE global_fileout_expt;
        END;
      END IF;
      --
      -- f[^sÌì¬
      lv_file_data := cv_meta_merge;                                                      --  1 : METADATA
      lv_file_data := lv_file_data || cv_pipe || cv_cls_per_name;                         --  2 : PersonName
      lv_file_data := lv_file_data || cv_pipe || l_per_name_rec.employee_number;          --  3 : PersonNumberiÂlÔj
      lv_file_data := lv_file_data || cv_pipe || cv_global;                               --  4 : NameTypei¼O^Cvj
      lv_file_data := lv_file_data || cv_pipe || l_per_name_rec.effective_start_date;     --  5 : EffectiveStartDateiLøJnúj
      lv_file_data := lv_file_data || cv_pipe || cv_jp;                                   --  6 : LegislationCodeiÊdlR[hj
      lv_file_data := lv_file_data || cv_pipe || 
                      nvl_for_hdl( l_per_name_rec.first_name
                                 , l_per_name_rec.new_reg_flag
                                 , cv_nvl_v
                                 );                                                       --  7 : FirstNamei¼j
      lv_file_data := lv_file_data || cv_pipe || l_per_name_rec.last_name;                --  8 : LastNamei©j
      lv_file_data := lv_file_data || cv_pipe || l_per_name_rec.per_information18;        --  9 : NameInformation1i¼Oîñ1j
      lv_file_data := lv_file_data || cv_pipe || 
                      nvl_for_hdl( l_per_name_rec.per_information19
                                 , l_per_name_rec.new_reg_flag
                                 , cv_nvl_v
                                 );                                                       -- 10 : NameInformation2i¼Oîñ2j
      lv_file_data := lv_file_data || cv_pipe || cv_ebs;                                  -- 11 : SourceSystemOwneri\[XEVXeLÒj
      lv_file_data := lv_file_data || cv_pipe || l_per_name_rec.person_id;                -- 12 : SourceSystemIdi\[XEVXeIDj
      --
      BEGIN
        -- f[^sÌt@CoÍ
        UTL_FILE.PUT_LINE( gf_wrk_file_handle  -- ]ÆõîñAgf[^t@C
                         , lv_file_data
                         );
        -- oÍJEgAbv
        gn_out_wk_cnt := gn_out_wk_cnt + 1;
      EXCEPTION
        WHEN OTHERS THEN
          RAISE global_fileout_expt;
      END;
    --
    END LOOP output_per_name_loop;
    --
    -- oª1Èã éê
    IF ( gn_get_per_name_cnt > 0 ) THEN
      BEGIN
        -- ós}ü
        UTL_FILE.PUT_LINE( gf_wrk_file_handle  -- ]ÆõîñAgf[^t@C
                         , ''
                         );
      EXCEPTION
        WHEN OTHERS THEN
          RAISE global_fileout_expt;
      END;
    END IF;
--
    -- J[\N[Y
    CLOSE per_name_cur;
--
--
    -- ==============================================================
    -- ÂlÊdlf[^Ìo(A-2-5)
    -- ==============================================================
    -- J[\I[v
    OPEN per_legi_cur;
    <<output_per_legi_loop>>
    LOOP
      --
      FETCH per_legi_cur INTO l_per_legi_rec;
      EXIT WHEN per_legi_cur%NOTFOUND;
      --
      -- oJEgAbv
      gn_get_per_legi_cnt := gn_get_per_legi_cnt + 1;
      --
      -- ==============================================================
      -- ÂlÊdlf[^Ìt@CoÍ(A-2-6)
      -- ==============================================================
      -- wb_[sÌì¬iñÌÝj
      IF ( gn_get_per_legi_cnt = 1 ) THEN
        --
        BEGIN
          -- wb_[sÌt@CoÍ
          UTL_FILE.PUT_LINE( gf_wrk_file_handle  -- ]ÆõîñAgf[^t@C
                           , cv_per_legi_header
                           );
        EXCEPTION
          WHEN OTHERS THEN
            RAISE global_fileout_expt;
        END;
      END IF;
      --
      -- f[^sÌì¬
      lv_file_data := cv_meta_merge;                                                      -- 1 : METADATA
      lv_file_data := lv_file_data || cv_pipe || cv_cls_per_legi;                         -- 2 : PersonLegislativeData
      lv_file_data := lv_file_data || cv_pipe || l_per_legi_rec.employee_number;          -- 3 : PersonNumberiÂlÔj
      lv_file_data := lv_file_data || cv_pipe || cv_jp;                                   -- 4 : LegislationCodeiÊdlR[hj
      lv_file_data := lv_file_data || cv_pipe || l_per_legi_rec.effective_start_date;     -- 5 : EffectiveStartDateiLøJnúj
      lv_file_data := lv_file_data || cv_pipe || 
                      nvl_for_hdl( l_per_legi_rec.sex
                                 , l_per_legi_rec.new_reg_flag
                                 , cv_nvl_v
                                 );                                                       -- 6 : Sexi«Êj
      lv_file_data := lv_file_data || cv_pipe || cv_ebs;                                  -- 7 : SourceSystemOwneri\[XEVXeLÒj
      lv_file_data := lv_file_data || cv_pipe || l_per_legi_rec.person_id;                -- 8 : SourceSystemIdi\[XEVXeIDj
      --
      BEGIN
        -- f[^sÌt@CoÍ
        UTL_FILE.PUT_LINE( gf_wrk_file_handle  -- ]ÆõîñAgf[^t@C
                         , lv_file_data
                         );
        -- oÍJEgAbv
        gn_out_wk_cnt := gn_out_wk_cnt + 1;
      EXCEPTION
        WHEN OTHERS THEN
          RAISE global_fileout_expt;
      END;
    --
    END LOOP output_per_legi_loop;
--
    -- oª1Èã éê
    IF ( gn_get_per_legi_cnt > 0 ) THEN
      BEGIN
        -- ósðt@CoÍ
        UTL_FILE.PUT_LINE( gf_wrk_file_handle  -- ]ÆõîñAgf[^t@C
                         , ''
                         );
      EXCEPTION
        WHEN OTHERS THEN
          RAISE global_fileout_expt;
      END;
    END IF;
--
    -- J[\N[Y
    CLOSE per_legi_cur;
--
--
    -- ==============================================================
    -- ÂlE[Ìo(A-2-7)
    -- ==============================================================
    -- J[\I[v
    OPEN per_email_cur;
    <<output_per_email_loop>>
    LOOP
      --
      FETCH per_email_cur INTO l_per_email_rec;
      EXIT WHEN per_email_cur%NOTFOUND;
      --
      -- oJEgAbv
      gn_get_per_email_cnt := gn_get_per_email_cnt + 1;
      --
      -- ==============================================================
      -- ÂlE[Ìt@CoÍ(A-2-8)
      -- ==============================================================
      -- wb_[sÌì¬iñÌÝj
      IF ( gn_get_per_email_cnt = 1 ) THEN
        --
        BEGIN
          -- wb_[sÌt@CoÍ
          UTL_FILE.PUT_LINE( gf_wrk_file_handle  -- ]ÆõîñAgf[^t@C
                           , cv_per_email_header
                           );
        EXCEPTION
          WHEN OTHERS THEN
            RAISE global_fileout_expt;
        END;
      END IF;
      --
      -- f[^sÌì¬
      lv_file_data := cv_meta_merge;                                                      -- 1 : METADATA
      lv_file_data := lv_file_data || cv_pipe || cv_cls_per_email;                        -- 2 : PersonEmail
      lv_file_data := lv_file_data || cv_pipe || l_per_email_rec.email_address;           -- 3 : EmailAddressiE[EAhXj
      lv_file_data := lv_file_data || cv_pipe || cv_w1;                                   -- 4 : EmailTypeiE[E^Cvj
      lv_file_data := lv_file_data || cv_pipe || l_per_email_rec.employee_number;         -- 5 : PersonNumberiÂlÔj
      lv_file_data := lv_file_data || cv_pipe || l_per_email_rec.effective_start_date;    -- 6 : DateFromiút: ©j
      lv_file_data := lv_file_data || cv_pipe || cv_ebs;                                  -- 7 : SourceSystemOwneri\[XEVXeLÒj
      lv_file_data := lv_file_data || cv_pipe || l_per_email_rec.person_id;               -- 8 : SourceSystemIdi\[XEVXeIDj
      --
      BEGIN
        -- f[^sÌt@CoÍ
        UTL_FILE.PUT_LINE( gf_wrk_file_handle  -- ]ÆõîñAgf[^t@C
                         , lv_file_data
                         );
        -- oÍJEgAbv
        gn_out_wk_cnt := gn_out_wk_cnt + 1;
      EXCEPTION
        WHEN OTHERS THEN
          RAISE global_fileout_expt;
      END;
    --
    END LOOP output_per_email_loop;
--
    -- oª1Èã éê
    IF ( gn_get_per_email_cnt > 0 ) THEN
      BEGIN
        -- ósðt@CoÍ
        UTL_FILE.PUT_LINE( gf_wrk_file_handle  -- ]ÆõîñAgf[^t@C
                         , ''
                         );
      EXCEPTION
        WHEN OTHERS THEN
          RAISE global_fileout_expt;
      END;
    END IF;
--
    -- J[\N[Y
    CLOSE per_email_cur;
--
--
    -- ==============================================================
    -- ÙpÖWiÞEÒjÌo(A-2-9)
    -- ==============================================================
    -- J[\I[v
    OPEN wk_rel_cur;
    <<output_wk_rel_loop>>
    LOOP
      --
      FETCH wk_rel_cur INTO l_wk_rel_rec;
      EXIT WHEN wk_rel_cur%NOTFOUND;
      --
      -- oJEgAbv
      gn_get_wk_rel_cnt := gn_get_wk_rel_cnt + 1;
      --
      -- ==============================================================
      -- ÙpÖWiÞEÒjÌt@CoÍ(A-2-10)
      -- ==============================================================
      -- wb_[sÌì¬iñÌÝj
      IF ( gn_get_wk_rel_cnt = 1 ) THEN
        --
        BEGIN
          -- wb_[sÌt@CoÍ
          UTL_FILE.PUT_LINE( gf_wrk_file_handle  -- ]ÆõîñAgf[^t@C
                           , cv_wk_rel_header
                           );
        EXCEPTION
          WHEN OTHERS THEN
            RAISE global_fileout_expt;
        END;
      END IF;
      --
      -- f[^sÌì¬
      lv_file_data := cv_meta_merge;                                                      --  1 : METADATA
      lv_file_data := lv_file_data || cv_pipe || cv_cls_wk_rel;                           --  2 : WorkRelationship
      lv_file_data := lv_file_data || cv_pipe || l_wk_rel_rec.employee_number;            --  3 : PersonNumberiÂlÔj
      lv_file_data := lv_file_data || cv_pipe || cv_wk_type_e;                            --  4 : WorkerTypeiAÆÒ^Cvj
      lv_file_data := lv_file_data || cv_pipe || l_wk_rel_rec.date_start;                 --  5 : DateStartiJnúj
      lv_file_data := lv_file_data || cv_pipe || cv_sales_le;                             --  6 : LegalEmployerNameiÙpåj
      lv_file_data := lv_file_data || cv_pipe || cv_y;                                    --  7 : PrimaryFlagivC}Ùpj
      lv_file_data := lv_file_data || cv_pipe || 
                      nvl_for_hdl( l_wk_rel_rec.actual_termination_date
                                 , l_wk_rel_rec.new_reg_flag
                                 , cv_nvl_d
                                 );                                                       --  8 : ActualTerminationDateiÀÑÞEúj
      lv_file_data := lv_file_data || cv_pipe || 
                      nvl_for_hdl( l_wk_rel_rec.terminate_work_rel_flag
                                 , l_wk_rel_rec.new_reg_flag
                                 , cv_nvl_v
                                 );                                                       --  9 : TerminateWorkRelationshipFlagiÙpÖWÌI¹j
      lv_file_data := lv_file_data || cv_pipe || 
                      nvl_for_hdl( l_wk_rel_rec.reverse_termination_flag
                                 , l_wk_rel_rec.new_reg_flag
                                 , cv_nvl_v
                                 );                                                       -- 10 : ReverseTerminationFlagiÞEÌæÁj
      lv_file_data := lv_file_data || cv_pipe || l_wk_rel_rec.action_code;                -- 11 : ActionCodeiR[hj
      lv_file_data := lv_file_data || cv_pipe || cv_ebs;                                  -- 12 : SourceSystemOwneri\[XEVXeLÒj
      lv_file_data := lv_file_data || cv_pipe || l_wk_rel_rec.period_of_service_id;       -- 13 : SourceSystemIdi\[XEVXeIDj
      --
      BEGIN
        -- f[^sÌt@CoÍ
        UTL_FILE.PUT_LINE( gf_wrk_file_handle  -- ]ÆõîñAgf[^t@C
                         , lv_file_data
                         );
        -- oÍJEgAbv
        gn_out_wk_cnt := gn_out_wk_cnt + 1;
      EXCEPTION
        WHEN OTHERS THEN
          RAISE global_fileout_expt;
      END;
    --
    END LOOP output_wk_rel_loop;
--
    -- oª1Èã éê
    IF ( gn_get_wk_rel_cnt > 0 ) THEN
      BEGIN
        -- ósðt@CoÍ
        UTL_FILE.PUT_LINE( gf_wrk_file_handle  -- ]ÆõîñAgf[^t@C
                         , ''
                         );
      EXCEPTION
        WHEN OTHERS THEN
          RAISE global_fileout_expt;
      END;
    END IF;
--
    -- J[\N[Y
    CLOSE wk_rel_cur;
--
--
    -- ==============================================================
    -- [U[îñiVKjÌo(A-2-11)
    -- ==============================================================
    -- J[\I[v
    OPEN new_user_cur;
    <<output_new_user_loop>>
    LOOP
      --
      FETCH new_user_cur INTO l_new_user_rec;
      EXIT WHEN new_user_cur%NOTFOUND;
      --
      -- oJEgAbv
      gn_get_new_user_cnt      := gn_get_new_user_cnt + 1;
-- Ver1.15 Del Start
--      gn_get_new_user_paas_cnt := gn_get_new_user_paas_cnt + 1;
-- Ver1.15 Del End
      --
      -- ==============================================================
      -- [U[îñiVKjÌt@CoÍ(A-2-12)
      -- ==============================================================
      -- wb_[sÌì¬iñÌÝj
      IF ( gn_get_new_user_cnt = 1 ) THEN
        --
        BEGIN
          -- wb_[sÌt@CoÍ
          UTL_FILE.PUT_LINE( gf_wrk_file_handle  -- ]ÆõîñAgf[^t@C
                           , cv_per_user_header
                           );
        EXCEPTION
          WHEN OTHERS THEN
            RAISE global_fileout_expt;
        END;
      END IF;
      --
      -- f[^sÌì¬
      lv_file_data := cv_meta_merge;                                                          -- 1 : METADATA
      lv_file_data := lv_file_data || cv_pipe || cv_cls_per_user;                             -- 2 : PersonUserInformation
      lv_file_data := lv_file_data || cv_pipe || l_new_user_rec.user_name;                    -- 3 : UserNamei[U[¼j
      lv_file_data := lv_file_data || cv_pipe || l_new_user_rec.employee_number;              -- 4 : PersonNumberiÂlÔj
      lv_file_data := lv_file_data || cv_pipe || l_new_user_rec.start_date;                   -- 5 : StartDateiJnúj
      lv_file_data := lv_file_data || cv_pipe || l_new_user_rec.generated_user_account_flag;  -- 6 : GeneratedUserAccountFlagi¶¬Ï[U[EAJEgj
      lv_file_data := lv_file_data || cv_pipe || cv_n;                                        -- 7 : SendCredentialsEmailFlagiiØ¾E[ÌMj
      --
      BEGIN
        -- f[^sÌt@CoÍ
        UTL_FILE.PUT_LINE( gf_wrk_file_handle  -- ]ÆõîñAgf[^t@C
                         , lv_file_data
                         );
        -- oÍJEgAbv
        gn_out_wk_cnt := gn_out_wk_cnt + 1;
      EXCEPTION
        WHEN OTHERS THEN
          RAISE global_fileout_expt;
      END;
      --
-- Ver1.15 Del Start
--      -- ==============================================================
--      -- PaaSpÌVK[U[îñÌt@CoÍ(A-2-13)
--      -- ==============================================================
--      IF (l_new_user_rec.generated_user_account_flag = cv_y) THEN
--        -- ¶¬Ï[U[EAJEgªYÌêi[U[}X^ª¶Ý·éêj
--        -- f[^sÌì¬
--        lv_file_data := xxccp_oiccommon_pkg.to_csv_string( l_new_user_rec.user_name , cv_space );  -- 1 : [U[¼
--        lv_file_data := lv_file_data || cv_comma ||
--                        xxccp_oiccommon_pkg.to_csv_string( gt_prf_val_password      , cv_space );  -- 2 : úpX[h
--        --
--        BEGIN
--          -- f[^sÌt@CoÍ
--          UTL_FILE.PUT_LINE( gf_new_usr_file_handle  -- PaaSpÌVK[U[îñt@C
--                           , lv_file_data
--                           );
--          -- oÍJEgAbv
--          gn_out_p_new_user_cnt := gn_out_p_new_user_cnt + 1;
--        EXCEPTION
--          WHEN OTHERS THEN
--            RAISE global_fileout_expt;
--        END;
--      ELSE
--        -- ¶¬Ï[U[EAJEgªNÌêi[U[}X^ª¶ÝµÈ¢êj
--        -- XLbvðJEgAbv
--        gn_warn_cnt := gn_warn_cnt + 1;
--      END IF;
-- Ver1.15 Del End
    --
    END LOOP output_new_user_loop;
--
    -- oª1Èã éê
    IF ( gn_get_new_user_cnt > 0 ) THEN
      BEGIN
        -- ósðt@CoÍ
        UTL_FILE.PUT_LINE( gf_wrk_file_handle  -- ]ÆõîñAgf[^t@C
                         , ''
                         );
      EXCEPTION
        WHEN OTHERS THEN
          RAISE global_fileout_expt;
      END;
    END IF;
--
    -- J[\N[Y
    CLOSE new_user_cur;
--
--
    -- ==============================================================
    -- ÙpðÌo(A-2-14)
    -- ==============================================================
    -- J[\I[v
    OPEN wk_terms_cur;
    <<output_wk_terms_loop>>
    LOOP
      --
      FETCH wk_terms_cur INTO l_wk_terms_rec;
      EXIT WHEN wk_terms_cur%NOTFOUND;
      --
      -- oJEgAbv
      gn_get_wk_terms_cnt := gn_get_wk_terms_cnt + 1;
      --
      -- ==============================================================
      -- ÙpðÌt@CoÍ(A-2-15)
      -- ==============================================================
      -- wb_[sÌì¬
      BEGIN
        IF ( l_wk_terms_rec.sup_chg_flag = cv_n AND lv_wt_header_wrk = cv_n ) THEN
          -- ã·ÏXÈµA©Âwb_[sª¢ì¬Ìê
          -- wb_[sÌt@CoÍ
          UTL_FILE.PUT_LINE( gf_wrk_file_handle  -- ]ÆõîñAgf[^t@C
                           , cv_wk_terms_header
                           );
          --
          -- wb_[sì¬Ï
          lv_wt_header_wrk := cv_y;
        ELSIF ( l_wk_terms_rec.sup_chg_flag = cv_y AND lv_wt_header_wrk2 = cv_n ) THEN
          -- ã·ÏX èA©Âwb_[sª¢ì¬Ìê
          -- wb_[sÌt@CoÍ
          UTL_FILE.PUT_LINE( gf_wrk2_file_handle  -- ]Æõîñiã·EVKÌpÞEÒjAgf[^t@C
                           , cv_wk_terms_header
                           );
          --
          -- wb_[sì¬Ï
          lv_wt_header_wrk2 := cv_y;
        END IF;
      EXCEPTION
        WHEN OTHERS THEN
          RAISE global_fileout_expt;
      END;
      --
      -- f[^sÌì¬
      lv_file_data := cv_meta_merge;                                                      --  1 : METADATA
      lv_file_data := lv_file_data || cv_pipe || cv_cls_wk_terms;                         --  2 : WorkTerms
      lv_file_data := lv_file_data || cv_pipe || l_wk_terms_rec.assignment_number;        --  3 : AssignmentNumberiATCgÔj
      lv_file_data := lv_file_data || cv_pipe || l_wk_terms_rec.employee_number;          --  4 : PersonNumberiÂlÔj
      lv_file_data := lv_file_data || cv_pipe || cv_wk_type_e;                            --  5 : WorkerTypeiAÆÒ^Cvj
      lv_file_data := lv_file_data || cv_pipe || l_wk_terms_rec.start_date;               --  6 : DateStartiJnúj
      lv_file_data := lv_file_data || cv_pipe || cv_sales_le;                             --  7 : LegalEmployerNameiÙpå¼j
      lv_file_data := lv_file_data || cv_pipe || cv_y;                                    --  8 : EffectiveLatestChangeiLøÅIÏXj
      lv_file_data := lv_file_data || cv_pipe || l_wk_terms_rec.effective_start_date;     --  9 : EffectiveStartDateiLøJnúj
      lv_file_data := lv_file_data || cv_pipe || cv_seq_1;                                -- 10 : EffectiveSequenceiLøj
      lv_file_data := lv_file_data || cv_pipe || cv_ass_status_act;                       -- 11 : AssignmentStatusTypeCodeiATCgEXe[^XE^Cvj
      lv_file_data := lv_file_data || cv_pipe || cv_ass_type_et;                          -- 12 : AssignmentTypeiATCgE^Cvj
      lv_file_data := lv_file_data || cv_pipe || l_wk_terms_rec.assignment_name;          -- 13 : AssignmentNameiATCg¼j
      lv_file_data := lv_file_data || cv_pipe || cv_sys_per_type_emp;                     -- 14 : SystemPersonTypeiVXePerson^Cvj
      lv_file_data := lv_file_data || cv_pipe || cv_sales_bu;                             -- 15 : BusinessUnitShortCodeirWlXEjbgj
      lv_file_data := lv_file_data || cv_pipe || l_wk_terms_rec.action_code;              -- 16 : ActionCodeiR[hj
      lv_file_data := lv_file_data || cv_pipe || cv_y;                                    -- 17 : PrimaryWorkTermsFlagiÙpÖWÌvC}Ùpðj
      lv_file_data := lv_file_data || cv_pipe || cv_ebs;                                  -- 18 : SourceSystemOwneri\[XEVXeLÒj
      lv_file_data := lv_file_data || cv_pipe || l_wk_terms_rec.source_system_id;         -- 19 : SourceSystemIdi\[XEVXeIDj
      --
      BEGIN
        IF ( l_wk_terms_rec.sup_chg_flag = cv_n ) THEN
          -- ã·ÏXÈµ
          -- f[^sÌt@CoÍ
          UTL_FILE.PUT_LINE( gf_wrk_file_handle  -- ]ÆõîñAgf[^t@C
                           , lv_file_data
                           );
          -- oÍJEgAbv
          gn_out_wk_cnt := gn_out_wk_cnt + 1;
        ELSE
          -- ã·ÏX è
          -- f[^sÌt@CoÍ
          UTL_FILE.PUT_LINE( gf_wrk2_file_handle  -- ]Æõîñiã·EVKÌpÞEÒjAgf[^t@C
                           , lv_file_data
                           );
          -- oÍJEgAbv
          gn_out_wk2_cnt := gn_out_wk2_cnt + 1;
        END IF;
      EXCEPTION
        WHEN OTHERS THEN
          RAISE global_fileout_expt;
      END;
    --
    END LOOP output_wk_terms_loop;
--
    BEGIN
      -- wb_[sðoÍµÄ¢éê
      IF ( lv_wt_header_wrk = cv_y ) THEN
        -- ósðt@CoÍ
        UTL_FILE.PUT_LINE( gf_wrk_file_handle  -- ]ÆõîñAgf[^t@C
                         , ''
                         );
      END IF;
      --
      IF ( lv_wt_header_wrk2 = cv_y ) THEN
        -- ósðt@CoÍ
        UTL_FILE.PUT_LINE( gf_wrk2_file_handle  -- ]Æõîñiã·EVKÌpÞEÒjAgf[^t@C
                         , ''
                         );
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        RAISE global_fileout_expt;
    END;
--
    -- J[\N[Y
    CLOSE wk_terms_cur;
--
--
    -- ==============================================================
    -- ATCgîñÌo(A-2-16)
    -- ==============================================================
    -- J[\I[v
    OPEN ass_cur;
    <<output_ass_loop>>
    LOOP
      --
      FETCH ass_cur INTO l_ass_rec;
      EXIT WHEN ass_cur%NOTFOUND;
      --
      -- oJEgAbv
      gn_get_ass_cnt := gn_get_ass_cnt + 1;
      --
      -- ==============================================================
      -- ATCgîñÌt@CoÍ(A-2-17)
      -- ==============================================================
      -- wb_[sÌì¬
      BEGIN
        IF ( l_ass_rec.sup_chg_flag = cv_n AND lv_ass_header_wrk = cv_n ) THEN
          -- ã·ÏXÈµA©Âwb_[sª¢ì¬Ìê
          -- wb_[sÌt@CoÍ
          UTL_FILE.PUT_LINE( gf_wrk_file_handle  -- ]ÆõîñAgf[^t@C
                           , cv_ass_header
                           );
          --
          -- wb_[sì¬Ï
          lv_ass_header_wrk := cv_y;
        ELSIF ( l_ass_rec.sup_chg_flag = cv_y AND lv_ass_header_wrk2 = cv_n ) THEN
          -- ã·ÏX èA©Âwb_[sª¢ì¬Ìê
          -- wb_[sÌt@CoÍ
          UTL_FILE.PUT_LINE( gf_wrk2_file_handle  -- ]Æõîñiã·EVKÌpÞEÒjAgf[^t@C
                           , cv_ass_header
                           );
          --
          -- wb_[sì¬Ï
          lv_ass_header_wrk2 := cv_y;
        END IF;
      EXCEPTION
        WHEN OTHERS THEN
          RAISE global_fileout_expt;
      END;
      --
      -- f[^sÌì¬
      lv_file_data :=                            cv_meta_merge;                           --  1 : METADATA
      lv_file_data := lv_file_data || cv_pipe || cv_cls_assignment;                       --  2 : Assignment
      lv_file_data := lv_file_data || cv_pipe || cv_per_asg_df;                           --  3 : FLEX:PER_ASG_DFiReLXgj
      lv_file_data := lv_file_data || cv_pipe || l_ass_rec.assignment_number;             --  4 : AssignmentNumberiATCgÔj
      lv_file_data := lv_file_data || cv_pipe || l_ass_rec.work_terms_number;             --  5 : WorkTermsNumberiÎ±ðÔj
      lv_file_data := lv_file_data || cv_pipe || cv_y;                                    --  6 : EffectiveLatestChangeiLøÅIÏXj
      lv_file_data := lv_file_data || cv_pipe || l_ass_rec.effective_start_date;          --  7 : EffectiveStartDateiLøJnúj
      lv_file_data := lv_file_data || cv_pipe || cv_seq_1;                                --  8 : EffectiveSequenceiLøj
      lv_file_data := lv_file_data || cv_pipe || cv_per_type_employee;                    --  9 : PersonTypeCodeiPerson^Cvj
      lv_file_data := lv_file_data || cv_pipe || cv_ass_status_act;                       -- 10 : AssignmentStatusTypeCodeiATCgEXe[^XE^Cvj
      lv_file_data := lv_file_data || cv_pipe || l_ass_rec.assignment_type;               -- 11 : AssignmentTypeiATCgE^Cvj
      lv_file_data := lv_file_data || cv_pipe || cv_sys_per_type_emp;                     -- 12 : SystemPersonTypeiVXePerson^Cvj
      lv_file_data := lv_file_data || cv_pipe || l_ass_rec.assignment_number;             -- 13 : AssignmentNameiATCg¼j
      lv_file_data := lv_file_data || cv_pipe || 
                      nvl_for_hdl( l_ass_rec.job_code
                                 , l_ass_rec.new_reg_flag
                                 , cv_nvl_v
                                 );                                                       -- 14 : JobCodeiWuER[hj
      lv_file_data := lv_file_data || cv_pipe || 
                      nvl_for_hdl( l_ass_rec.default_expense_account
                                 , l_ass_rec.new_reg_flag
                                 , cv_nvl_v
                                 );                                                       -- 15 : DefaultExpenseAccountiftHgïp¨èj
      lv_file_data := lv_file_data || cv_pipe || cv_sales_bu;                             -- 16 : BusinessUnitShortCodeirWlXEjbgj
      lv_file_data := lv_file_data || cv_pipe || 
                      nvl_for_hdl( l_ass_rec.manager_flag
                                 , l_ass_rec.new_reg_flag
                                 , cv_nvl_v
                                 );                                                       -- 17 : ManagerFlagi}l[Wj
      lv_file_data := lv_file_data || cv_pipe || 
                      nvl_for_hdl( l_ass_rec.location_code
                                 , l_ass_rec.new_reg_flag
                                 , cv_nvl_v
                                 );                                                       -- 18 : LocationCodeiÆR[hj
      lv_file_data := lv_file_data || cv_pipe || l_ass_rec.employee_number;               -- 19 : PersonNumberiÂlÔj
      lv_file_data := lv_file_data || cv_pipe || l_ass_rec.action_code;                   -- 20 : ActionCodeiR[hj
      lv_file_data := lv_file_data || cv_pipe || cv_wk_type_e;                            -- 21 : WorkerTypeiAÆÒ^Cvj
      lv_file_data := lv_file_data || cv_pipe || NULL;                                    -- 22 : DepartmentNameiåj
      lv_file_data := lv_file_data || cv_pipe || l_ass_rec.start_date;                    -- 23 : DateStartiJnúj
      lv_file_data := lv_file_data || cv_pipe || cv_sales_le;                             -- 24 : LegalEmployerNameiÙpå¼j
      lv_file_data := lv_file_data || cv_pipe || l_ass_rec.primary_flag;                  -- 25 : PrimaryAssignmentFlagiÙpÖWÌvC}EATCgj
                                                                                          --      («PER_ASG_DF=ITO_SALES_USE_ITEM)
      lv_file_data := lv_file_data || cv_pipe || 
                      nvl_for_hdl( l_ass_rec.ass_attribute1
                                 , l_ass_rec.new_reg_flag
                                 , cv_nvl_v
                                 );                                                       -- 26 : transferReasonCodeiÙ®RR[h)
      lv_file_data := lv_file_data || cv_pipe || 
                      nvl_for_hdl( l_ass_rec.ass_attribute2
                                 , l_ass_rec.new_reg_flag
                                 , cv_nvl_v
                                 );                                                       -- 27 : announceDatei­ßú)
      lv_file_data := lv_file_data || cv_pipe || 
                      nvl_for_hdl( l_ass_rec.ass_attribute3
                                 , l_ass_rec.new_reg_flag
                                 , cv_nvl_v
                                 );                                                       -- 28 : workLocDepartmentNewiÎ±n_R[hiVj)
      lv_file_data := lv_file_data || cv_pipe || 
                      nvl_for_hdl( l_ass_rec.ass_attribute4
                                 , l_ass_rec.new_reg_flag
                                 , cv_nvl_v
                                 );                                                       -- 29 : workLocDepartmentOldiÎ±n_R[hij)
      lv_file_data := lv_file_data || cv_pipe || 
                      nvl_for_hdl( l_ass_rec.ass_attribute5
                                 , l_ass_rec.new_reg_flag
                                 , cv_nvl_v
                                 );                                                       -- 30 : departmentNewi_R[hiVjj
      lv_file_data := lv_file_data || cv_pipe || 
                      nvl_for_hdl( l_ass_rec.ass_attribute6
                                 , l_ass_rec.new_reg_flag
                                 , cv_nvl_v
                                 );                                                       -- 31 : departmentOldi_R[hij)
      lv_file_data := lv_file_data || cv_pipe || 
                      nvl_for_hdl( l_ass_rec.ass_attribute7
                                 , l_ass_rec.new_reg_flag
                                 , cv_nvl_v
                                 );                                                       -- 32 : appWorkTimeCodeNewiKpJ­Ô§R[hiVj)
      lv_file_data := lv_file_data || cv_pipe || 
                      nvl_for_hdl( l_ass_rec.ass_attribute8
                                 , l_ass_rec.new_reg_flag
                                 , cv_nvl_v
                                 );                                                       -- 33 : appWorkTimeNameNewiKpJ­¼iVj)
      lv_file_data := lv_file_data || cv_pipe || 
                      nvl_for_hdl( l_ass_rec.ass_attribute9
                                 , l_ass_rec.new_reg_flag
                                 , cv_nvl_v
                                 );                                                       -- 34 : appWorkTimeCodeOldiKpJ­Ô§R[hij)
      lv_file_data := lv_file_data || cv_pipe || 
                      nvl_for_hdl( l_ass_rec.ass_attribute10
                                 , l_ass_rec.new_reg_flag
                                 , cv_nvl_v
                                 );                                                       -- 35 : appWorkTimeNameOldiKpJ­¼ij)
      lv_file_data := lv_file_data || cv_pipe || 
                      nvl_for_hdl( l_ass_rec.ass_attribute11
                                 , l_ass_rec.new_reg_flag
                                 , cv_nvl_v
                                 );                                                       -- 36 : positionSortCodeNewiEÊÀR[hiVj)
      lv_file_data := lv_file_data || cv_pipe || 
                      nvl_for_hdl( l_ass_rec.ass_attribute12
                                 , l_ass_rec.new_reg_flag
                                 , cv_nvl_v
                                 );                                                       -- 37 : positionSortCodeOldiEÊÀR[hij)
      lv_file_data := lv_file_data || cv_pipe || 
                      nvl_for_hdl( l_ass_rec.ass_attribute13
                                 , l_ass_rec.new_reg_flag
                                 , cv_nvl_v
                                 );                                                       -- 38 : approvalClassNewi³FæªiVj)
      lv_file_data := lv_file_data || cv_pipe || 
                      nvl_for_hdl( l_ass_rec.ass_attribute14
                                 , l_ass_rec.new_reg_flag
                                 , cv_nvl_v
                                 );                                                       -- 39 : approvalClassOldi³Fæªijj
      lv_file_data := lv_file_data || cv_pipe || 
                      nvl_for_hdl( l_ass_rec.ass_attribute15
                                 , l_ass_rec.new_reg_flag
                                 , cv_nvl_v
                                 );                                                       -- 40 : alternateClassNewiãsæªiVj)
      lv_file_data := lv_file_data || cv_pipe || 
                      nvl_for_hdl( l_ass_rec.ass_attribute16
                                 , l_ass_rec.new_reg_flag
                                 , cv_nvl_v
                                 );                                                       -- 41 : alternateClassOldiãsæªij)
      lv_file_data := lv_file_data || cv_pipe || 
                      nvl_for_hdl( l_ass_rec.ass_attribute17
                                 , l_ass_rec.new_reg_flag
                                 , cv_nvl_v
                                 );                                                       -- 42 : transferDateVendi·ªAgpúti©Ì@j)
      lv_file_data := lv_file_data || cv_pipe || 
                      nvl_for_hdl( l_ass_rec.ass_attribute18
                                 , l_ass_rec.new_reg_flag
                                 , cv_nvl_v
                                 );                                                       -- 43 : transferDateRepi·ªAgpúti [j)
                                                                                          --      (ªPER_ASG_DF=ITO_SALES_USE_ITEM)
      lv_file_data := lv_file_data || cv_pipe || cv_ebs;                                  -- 44 : SourceSystemOwneri\[XEVXeLÒj
      lv_file_data := lv_file_data || cv_pipe || l_ass_rec.source_system_id;              -- 45 : SourceSystemIdi\[XEVXeIDj
      --
      BEGIN
        IF ( l_ass_rec.sup_chg_flag = cv_n ) THEN
          -- ã·ÏXÈµ
          -- f[^sÌt@CoÍ
          UTL_FILE.PUT_LINE( gf_wrk_file_handle  -- ]ÆõîñAgf[^t@C
                           , lv_file_data
                           );
          -- oÍJEgAbv
          gn_out_wk_cnt := gn_out_wk_cnt + 1;
        ELSE
          -- ã·ÏX è
          -- f[^sÌt@CoÍ
          UTL_FILE.PUT_LINE( gf_wrk2_file_handle  -- ]Æõîñiã·EVKÌpÞEÒjAgf[^t@C
                           , lv_file_data
                           );
          -- oÍJEgAbv
          gn_out_wk2_cnt := gn_out_wk2_cnt + 1;
        END IF;
      EXCEPTION
        WHEN OTHERS THEN
          RAISE global_fileout_expt;
      END;
    --
    END LOOP output_ass_loop;
--
    BEGIN
      -- wb_[sðoÍµÄ¢éê
      IF ( lv_ass_header_wrk2 = cv_y ) THEN
        -- ósðt@CoÍ
        UTL_FILE.PUT_LINE( gf_wrk2_file_handle  -- ]Æõîñiã·EVKÌpÞEÒjAgf[^t@C
                         , ''
                         );
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        RAISE global_fileout_expt;
    END;
--
    -- J[\N[Y
    CLOSE ass_cur;
--
--
  EXCEPTION
    -- *** t@CoÍáOnh ***
    WHEN global_fileout_expt THEN
      -- J[\N[Y
      IF ( worker_cur%ISOPEN )    THEN CLOSE worker_cur;    END IF;
      IF ( per_name_cur%ISOPEN )  THEN CLOSE per_name_cur;  END IF;
      IF ( per_legi_cur%ISOPEN )  THEN CLOSE per_legi_cur;  END IF;
      IF ( per_email_cur%ISOPEN ) THEN CLOSE per_email_cur; END IF;
      IF ( wk_rel_cur%ISOPEN )    THEN CLOSE wk_rel_cur;    END IF;
      IF ( new_user_cur%ISOPEN )  THEN CLOSE new_user_cur;  END IF;
      IF ( wk_terms_cur%ISOPEN )  THEN CLOSE wk_terms_cur;  END IF;
      IF ( ass_cur%ISOPEN )       THEN CLOSE ass_cur;       END IF;
      --
      lv_errmsg := SUBSTRB(
                     xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_xxcmm             -- AvP[VZk¼FXXCMM
                     , iv_name         => cv_file_write_err_msg     -- bZ[W¼Ft@C«ÝG[bZ[W
                     , iv_token_name1  => cv_tkn_sqlerrm            -- g[N¼1FSQLERRM
                     , iv_token_value1 => SQLERRM                   -- g[Nl1FSQLERRM
                     )
                   , 1
                   , 5000
                   );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  ÅèáO START   ####################################
--
    -- *** ¤ÊáOnh ***
    WHEN global_process_expt THEN
      -- J[\N[Y
      IF ( worker_cur%ISOPEN )    THEN CLOSE worker_cur;    END IF;
      IF ( per_name_cur%ISOPEN )  THEN CLOSE per_name_cur;  END IF;
      IF ( per_legi_cur%ISOPEN )  THEN CLOSE per_legi_cur;  END IF;
      IF ( per_email_cur%ISOPEN ) THEN CLOSE per_email_cur; END IF;
      IF ( wk_rel_cur%ISOPEN )    THEN CLOSE wk_rel_cur;    END IF;
      IF ( new_user_cur%ISOPEN )  THEN CLOSE new_user_cur;  END IF;
      IF ( wk_terms_cur%ISOPEN )  THEN CLOSE wk_terms_cur;  END IF;
      IF ( ass_cur%ISOPEN )       THEN CLOSE ass_cur;       END IF;
      --
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ¤ÊÖáOnh ***
    WHEN global_api_expt THEN
      -- J[\N[Y
      IF ( worker_cur%ISOPEN )    THEN CLOSE worker_cur;    END IF;
      IF ( per_name_cur%ISOPEN )  THEN CLOSE per_name_cur;  END IF;
      IF ( per_legi_cur%ISOPEN )  THEN CLOSE per_legi_cur;  END IF;
      IF ( per_email_cur%ISOPEN ) THEN CLOSE per_email_cur; END IF;
      IF ( wk_rel_cur%ISOPEN )    THEN CLOSE wk_rel_cur;    END IF;
      IF ( new_user_cur%ISOPEN )  THEN CLOSE new_user_cur;  END IF;
      IF ( wk_terms_cur%ISOPEN )  THEN CLOSE wk_terms_cur;  END IF;
      IF ( ass_cur%ISOPEN )       THEN CLOSE ass_cur;       END IF;
      --
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ¤ÊÖOTHERSáOnh ***
    WHEN global_api_others_expt THEN
      -- J[\N[Y
      IF ( worker_cur%ISOPEN )    THEN CLOSE worker_cur;    END IF;
      IF ( per_name_cur%ISOPEN )  THEN CLOSE per_name_cur;  END IF;
      IF ( per_legi_cur%ISOPEN )  THEN CLOSE per_legi_cur;  END IF;
      IF ( per_email_cur%ISOPEN ) THEN CLOSE per_email_cur; END IF;
      IF ( wk_rel_cur%ISOPEN )    THEN CLOSE wk_rel_cur;    END IF;
      IF ( new_user_cur%ISOPEN )  THEN CLOSE new_user_cur;  END IF;
      IF ( wk_terms_cur%ISOPEN )  THEN CLOSE wk_terms_cur;  END IF;
      IF ( ass_cur%ISOPEN )       THEN CLOSE ass_cur;       END IF;
      --
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERSáOnh ***
    WHEN OTHERS THEN
      -- J[\N[Y
      IF ( worker_cur%ISOPEN )    THEN CLOSE worker_cur;    END IF;
      IF ( per_name_cur%ISOPEN )  THEN CLOSE per_name_cur;  END IF;
      IF ( per_legi_cur%ISOPEN )  THEN CLOSE per_legi_cur;  END IF;
      IF ( per_email_cur%ISOPEN ) THEN CLOSE per_email_cur; END IF;
      IF ( wk_rel_cur%ISOPEN )    THEN CLOSE wk_rel_cur;    END IF;
      IF ( new_user_cur%ISOPEN )  THEN CLOSE new_user_cur;  END IF;
      IF ( wk_terms_cur%ISOPEN )  THEN CLOSE wk_terms_cur;  END IF;
      IF ( ass_cur%ISOPEN )       THEN CLOSE ass_cur;       END IF;
      --
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  Åè END   ##########################################
--
  END output_worker;
--
--
  /**********************************************************************************
   * Procedure Name   : output_user
   * Description      : [U[îñÌoEt@CoÍ(A-3)
   ***********************************************************************************/
  PROCEDURE output_user(
    ov_errbuf     OUT VARCHAR2,     --   G[EbZ[W           --# Åè #
    ov_retcode    OUT VARCHAR2,     --   ^[ER[h             --# Åè #
    ov_errmsg     OUT VARCHAR2)     --   [U[EG[EbZ[W --# Åè #
  IS
    -- ===============================
    -- Åè[Jè
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'output_user';       -- vO¼
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
    ------------------------------------
    --wb_[s(User)
    ------------------------------------
    cv_user_header   CONSTANT VARCHAR2(3000) :=
                    'METADATA'          -- 1 : METADATA
      || cv_pipe || 'User'              -- 2 : User
      || cv_pipe || 'PersonNumber'      -- 3 : PersonNumberiÂlÔj
      || cv_pipe || 'Username'          -- 4 : Usernamei[U[¼j
      || cv_pipe || 'Suspended'         -- 5 : Suspendediâ~j
    ;
-- Ver1.2(E055) Add Start
    --
    ------------------------------------
    --wb_[s(User2)
    ------------------------------------
    cv_user2_header  CONSTANT VARCHAR2(3000) :=
                    'METADATA'               -- 1 : METADATA
      || cv_pipe || 'User'                   -- 2 : User
      || cv_pipe || 'PersonNumber'           -- 3 : PersonNumberiÂlÔj
      || cv_pipe || 'CredentialsEmailSent'   -- 4 : CredentialsEmailSentiiØ¾E[MÏj
    ;
-- Ver1.2(E055) Add End
--
    -- *** [JÏ ***
    lv_file_data         VARCHAR2(30000) DEFAULT NULL;       -- oÍàe
-- Ver1.17 Add Start
    lv_new_emp_flag      VARCHAR2(1);                        -- VüÐõtO
-- Ver1.17 Add End
--
    -- *** [JEJ[\ ***
    --------------------------------------
    -- [U[ÌoJ[\
    --------------------------------------
    CURSOR user_cur
    IS
      SELECT
          papf.employee_number          AS employee_number      -- ]ÆõÔ
        , fu.user_name                  AS user_name            -- [U[¼
        , (CASE
             WHEN fu.end_date <= gt_if_dest_date THEN
               cv_y
             ELSE
               cv_n
           END)                         AS suspended            -- â~
-- Ver1.17 Add Start
        , papf.person_id                AS person_id            -- ÂlID
-- Ver1.17 Add End
      FROM
          per_all_people_f  papf  -- ]Æõ}X^
        , fnd_user          fu    -- [U[}X^
      WHERE
          papf.attribute3 IN (cv_emp_kbn_internal, cv_emp_kbn_external , cv_emp_kbn_dummy)  -- ]Æõæªi1:àA2:OA4:_~[j
      AND papf.attribute4 IS NULL    -- düæR[h
      AND papf.attribute5 IS NULL    -- ^ÆÒ
      AND papf.employee_number NOT IN (cv_not_get_emp1, cv_not_get_emp2, cv_not_get_emp3, cv_not_get_emp4, 
                                       cv_not_get_emp5, cv_not_get_emp6, cv_not_get_emp7, cv_not_get_emp8)  -- ]ÆõÔ
      AND papf.effective_start_date = 
              (SELECT
                   MAX(papf2.effective_start_date)
               FROM
                   per_all_people_f  papf2 -- ]Æõ}X^
               WHERE
                   papf2.person_id = papf.person_id
              )
      AND papf.person_id       = fu.employee_id
      AND NOT EXISTS
              (SELECT
                   1  AS flag
               FROM
                   xxcmm_oic_emp_diff_info   xoedi -- OICÐõ·ªîñe[u
               WHERE
                   xoedi.person_id  = papf.person_id
               AND xoedi.user_name IS NULL
              )
-- Ver1.18 Mod Start
--      AND (   fu.last_update_date >= gt_pre_process_date
--           OR fu.end_date         = gt_if_dest_date)
      AND (   
            (     fu.last_update_date >= gt_pre_process_date
              AND fu.last_update_date <  gt_cur_process_date
            )
           OR     fu.end_date         = gt_if_dest_date
          )
-- Ver1.18 Mod End
      ORDER BY
          papf.employee_number ASC
    ;
-- Ver1.2(E055) Add Start
    --
    --------------------------------------
    -- [U[iíjÌoJ[\
    --------------------------------------
    CURSOR user2_cur
    IS
      SELECT
          papf.employee_number          AS employee_number      -- ]ÆõÔ
      FROM
          per_all_people_f         papf  -- ]Æõ}X^
-- Ver1.13 Add Start
        , po_vendors               pv    -- düæ}X^
        , po_vendor_sites_all      pvsa  -- düæTCg}X^
-- Ver1.13 Add End
        , per_all_assignments_f    paaf  -- ATCg}X^
        , per_periods_of_service   ppos  -- AÆîñ
      WHERE
          papf.attribute3 IN (cv_emp_kbn_internal, cv_emp_kbn_external , cv_emp_kbn_dummy)  -- ]Æõæªi1:àA2:OA4:_~[j
      AND papf.attribute4 IS NULL    -- düæR[h
      AND papf.attribute5 IS NULL    -- ^ÆÒ
      AND papf.employee_number NOT IN (cv_not_get_emp1, cv_not_get_emp2, cv_not_get_emp3, cv_not_get_emp4, 
                                       cv_not_get_emp5, cv_not_get_emp6, cv_not_get_emp7, cv_not_get_emp8)  -- ]ÆõÔ
      AND papf.effective_start_date = 
              (SELECT
                   MAX(papf2.effective_start_date)
               FROM
                   per_all_people_f  papf2 -- ]Æõ}X^
               WHERE
                   papf2.person_id = papf.person_id
              )
-- Ver1.13 Add Start
      AND papf.person_id                = pv.employee_id(+)
      AND pv.vendor_type_lookup_code(+) = cv_vd_type_employee
      AND pv.vendor_id                  = pvsa.vendor_id(+)
      AND pvsa.vendor_site_code(+)      = cv_site_code_comp
-- Ver1.13 Add End
      AND papf.person_id            = paaf.person_id
      AND paaf.effective_start_date =
              (SELECT
                   MAX(paaf2.effective_start_date)
               FROM
                   per_all_assignments_f  paaf2  -- ATCg}X^
               WHERE
                   paaf2.person_id = paaf.person_id
              )
      AND paaf.period_of_service_id = ppos.period_of_service_id
      AND NOT EXISTS (
              SELECT
                  1 AS flag
              FROM
                  fnd_user  fu    -- [U[}X^
              WHERE
                  fu.employee_id = papf.person_id
          )
-- Ver1.5 Mod Start
--      AND papf.creation_date < gt_pre_process_date
--      AND (   papf.last_update_date >= gt_pre_process_date
--           OR papf.attribute23      >= gv_str_pre_process_date
--           OR paaf.last_update_date >= gt_pre_process_date
--           OR paaf.ass_attribute19  >= gv_str_pre_process_date
--           OR ppos.last_update_date >= gt_pre_process_date
--          )
      AND (
            (    papf.creation_date >= gt_pre_process_date
             AND (   paaf.supervisor_id IS NOT NULL
                  OR actual_termination_date IS NOT NULL
                 )
            ) OR (
                 papf.creation_date < gt_pre_process_date
             AND (   papf.last_update_date >= gt_pre_process_date
                  OR papf.attribute23      >= gv_str_pre_process_date
-- Ver1.13 Add Start
                  OR pvsa.last_update_date >= gt_pre_process_date
-- Ver1.13 Add End
                  OR paaf.last_update_date >= gt_pre_process_date
                  OR paaf.ass_attribute19  >= gv_str_pre_process_date
                  OR ppos.last_update_date >= gt_pre_process_date
                 )
            )
          )
-- Ver1.5 Mod End
      ORDER BY
          papf.employee_number ASC
    ;
-- Ver1.2(E055) Add End
-- Ver1.17 Add Start
--
    --------------------------------------
    -- VüÐõîñÌoJ[\
    --------------------------------------
    CURSOR new_emp_cur (
             in_person_id IN NUMBER
    )
    IS
      SELECT
          fu.user_name                                      AS user_name                    -- [U[¼
        , papf.employee_number                              AS employee_number              -- ]ÆõÔ
        , TO_CHAR(fu.start_date, cv_date_fmt)               AS start_date                   -- Jnú
        , cv_y                                              AS generated_user_account_flag  -- ¶¬Ï[U[EAJEg
        , papf.person_id                                    AS person_id                    -- ÂlID
      FROM
          per_all_people_f     papf  -- ]Æõ}X^
        , fnd_user             fu    -- [U[}X^
      WHERE
          papf.attribute3 IN (cv_emp_kbn_internal, cv_emp_kbn_external , cv_emp_kbn_dummy)  -- ]Æõæªi1:àA2:OA4:_~[j
      AND papf.attribute4 IS NULL    -- düæR[h
      AND papf.attribute5 IS NULL    -- ^ÆÒ
      AND papf.employee_number NOT IN (cv_not_get_emp1, cv_not_get_emp2, cv_not_get_emp3, cv_not_get_emp4, 
                                       cv_not_get_emp5, cv_not_get_emp6, cv_not_get_emp7, cv_not_get_emp8)  -- ]ÆõÔ
      AND papf.effective_start_date = 
              (SELECT
                   MAX(papf2.effective_start_date)
               FROM
                   per_all_people_f  papf2 -- ]Æõ}X^
               WHERE
                   papf2.person_id = papf.person_id
              )
      AND papf.person_id     = fu.employee_id
-- Ver1.18 Mod Start
--      AND papf.creation_date >= gt_pre_process_date
--      AND fu.creation_date   >= gt_pre_process_date
      AND (
                papf.creation_date >= gt_pre_process_date
            AND papf.creation_date <  gt_cur_process_date
           )
      AND ( 
                fu.creation_date   >= gt_pre_process_date
            AND fu.creation_date   <  gt_cur_process_date
          )
-- Ver1.18 Mod End
      AND papf.person_id = in_person_id
      ORDER BY
          employee_number ASC
    ;
-- Ver1.17 Add End
--
    -- *** [JER[h ***
    l_user_rec     user_cur%ROWTYPE;    -- [U[ÌoJ[\R[h
-- Ver1.2(E055) Add Start
    l_user2_rec    user2_cur%ROWTYPE;   -- [U[iíjÌoJ[\R[h
-- Ver1.2(E055) Add End
-- Ver1.17 Add Start
    l_new_emp_rec  new_emp_cur%ROWTYPE; -- VüÐõîñÌoJ[\R[h
-- Ver1.17 Add End
--
  BEGIN
--
--##################  ÅèXe[^Xú» START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  Åè END   ############################
--
    -- ==============================================================
    -- [U[îñÌo(A-3-1)
    -- ==============================================================
    -- J[\I[v
    OPEN user_cur;
    <<output_user_loop>>
    LOOP
      --
      FETCH user_cur INTO l_user_rec;
      EXIT WHEN user_cur%NOTFOUND;
      --
      -- oJEgAbv
      gn_get_user_cnt := gn_get_user_cnt + 1;
      --
-- Ver1.17 Del Start
--      -- ==============================================================
--      -- [U[îñÌt@CoÍ(A-3-2)
--      -- ==============================================================
      -- wb_[sÌì¬iñÌÝj
--      IF ( gn_get_user_cnt = 1 ) THEN
--        --
--        BEGIN
--          -- wb_[sÌt@CoÍ
--          UTL_FILE.PUT_LINE( gf_usr_file_handle  -- [U[îñAgf[^t@C
--                           , cv_user_header
--                           );
--        EXCEPTION
--          WHEN OTHERS THEN
--            RAISE global_fileout_expt;
--        END;
--      END IF;
-- Ver1.17 Del End
      --
      -- f[^sÌì¬
      lv_file_data := cv_meta_merge;                                                      -- 1 : METADATA
      lv_file_data := lv_file_data || cv_pipe || cv_cls_user;                             -- 2 : User
      lv_file_data := lv_file_data || cv_pipe || l_user_rec.employee_number;              -- 3 : PersonNumberiÂlÔj
      lv_file_data := lv_file_data || cv_pipe || l_user_rec.user_name;                    -- 4 : Usernamei[U[¼j
      lv_file_data := lv_file_data || cv_pipe || l_user_rec.suspended;                    -- 5 : Suspendediâ~j
      --
-- Ver1.17 Mod Start
--      BEGIN
--        -- f[^sÌt@CoÍ
--        UTL_FILE.PUT_LINE( gf_usr_file_handle  -- [U[îñAgf[^t@C
--                         , lv_file_data
--                         );
--        -- oÍJEgAbv
--        gn_out_user_cnt := gn_out_user_cnt + 1;
      -- ==============================================================
      -- VüÐõîñÌo(A-3-2)
      -- ==============================================================
-- Ver1.20 Add Start
      lv_new_emp_flag := cv_n;
-- Ver1.20 Add End

      -- J[\I[v
      OPEN new_emp_cur (
             l_user_rec.person_id
           );
      <<output_new_emp_loop>>
      LOOP
        --
        FETCH new_emp_cur INTO l_new_emp_rec;
        EXIT WHEN new_emp_cur%NOTFOUND;
        --
          lv_new_emp_flag := cv_y;
          -- êv·éêYtOð½Äé
      END LOOP output_new_emp_loop;
--
      -- J[\N[Y
      CLOSE new_emp_cur;
--
      -- ==============================================================
      -- [U[îñÌt@CoÍ(A-3-3)
      -- ==============================================================
      BEGIN
        IF ( lv_new_emp_flag = cv_y ) THEN
          -- f[^sÌt@CoÍµÈ¢
          gn_get_user_cnt := gn_get_user_cnt - 1;
        ELSE
          -- wb_[sÌì¬i2ñÚÈ~ÍoÍµÈ¢j
          IF ( gn_get_user_cnt = 1 ) THEN
            --
            BEGIN
              -- wb_[sÌt@CoÍ
              UTL_FILE.PUT_LINE( gf_usr_file_handle  -- [U[îñAgf[^t@C
                               , cv_user_header
                               );
            EXCEPTION
              WHEN OTHERS THEN
                RAISE global_fileout_expt;
            END;
          END IF;         
          -- f[^sÌt@CoÍ·é
          UTL_FILE.PUT_LINE( gf_usr_file_handle  -- [U[îñAgf[^t@C
                           , lv_file_data
                           );
          -- oÍJEgAbv
          gn_out_user_cnt := gn_out_user_cnt + 1;
        END IF;
-- Ver1.17 Mod End
      EXCEPTION
        WHEN OTHERS THEN
          RAISE global_fileout_expt;
      END;
    --
    END LOOP output_user_loop;
--
    -- J[\N[Y
    CLOSE user_cur;
--
-- Ver1.14 Del Start
---- Ver1.2(E055) Add Start
--    -- ==============================================================
--    -- [U[îñiíjÌo(A-3-3)
--    -- ==============================================================
--    -- J[\I[v
--    OPEN user2_cur;
--    <<output_user2_loop>>
--    LOOP
--      --
--      FETCH user2_cur INTO l_user2_rec;
--      EXIT WHEN user2_cur%NOTFOUND;
--      --
--      -- oJEgAbv
--      gn_get_user2_cnt := gn_get_user2_cnt + 1;
--      --
--      -- ==============================================================
--      -- [U[îñiíjÌt@CoÍ(A-3-4)
--      -- ==============================================================
--      -- wb_[sÌì¬iñÌÝj
--      IF ( gn_get_user2_cnt = 1 ) THEN
--        --
--        BEGIN
--          -- wb_[sÌt@CoÍ
--          UTL_FILE.PUT_LINE( gf_usr2_file_handle  -- [U[îñiíjAgf[^t@C
--                           , cv_user2_header
--                           );
--        EXCEPTION
--          WHEN OTHERS THEN
--            RAISE global_fileout_expt;
--        END;
--      END IF;
--      --
--      -- f[^sÌì¬
--      lv_file_data := cv_meta_delete;                                                     -- 1 : METADATA
--      lv_file_data := lv_file_data || cv_pipe || cv_cls_user;                             -- 2 : User
--      lv_file_data := lv_file_data || cv_pipe || l_user2_rec.employee_number;             -- 3 : PersonNumberiÂlÔj
--      lv_file_data := lv_file_data || cv_pipe || cv_y;                                    -- 4 : CredentialsEmailSentiiØ¾E[MÏj
--      --
--      BEGIN
--        -- f[^sÌt@CoÍ
--        UTL_FILE.PUT_LINE( gf_usr2_file_handle  -- [U[îñiíjAgf[^t@C
--                         , lv_file_data
--                         );
--        -- oÍJEgAbv
--        gn_out_user2_cnt := gn_out_user2_cnt + 1;
--      EXCEPTION
--        WHEN OTHERS THEN
--          RAISE global_fileout_expt;
--      END;
--    --
--    END LOOP output_user2_loop;
----
--    -- J[\N[Y
--    CLOSE user2_cur;
---- Ver1.2(E055) Add End
-- Ver1.14 Del End
--
  EXCEPTION
    -- *** t@CoÍáOnh ***
    WHEN global_fileout_expt THEN
      -- J[\N[Y
      IF ( user_cur%ISOPEN ) THEN
        CLOSE user_cur;
      END IF;
-- Ver1.2(E055) Add Start
      -- J[\N[Y
      IF ( user2_cur%ISOPEN ) THEN
        CLOSE user2_cur;
      END IF;
-- Ver1.2(E055) Add End
-- Ver1.17 Add Start
      -- J[\N[Y
      IF ( new_emp_cur%ISOPEN ) THEN
        CLOSE new_emp_cur;
      END IF;
-- Ver1.17 Add End
      --
      lv_errmsg := SUBSTRB(
                     xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_xxcmm             -- AvP[VZk¼FXXCMM
                     , iv_name         => cv_file_write_err_msg     -- bZ[W¼Ft@C«ÝG[bZ[W
                     , iv_token_name1  => cv_tkn_sqlerrm            -- g[N¼1FSQLERRM
                     , iv_token_value1 => SQLERRM                   -- g[Nl1FSQLERRM
                     )
                   , 1
                   , 5000
                   );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  ÅèáO START   ####################################
--
    -- *** ¤ÊáOnh ***
    WHEN global_process_expt THEN
      -- J[\N[Y
      IF ( user_cur%ISOPEN ) THEN
        CLOSE user_cur;
      END IF;
-- Ver1.2(E055) Add Start
      -- J[\N[Y
      IF ( user2_cur%ISOPEN ) THEN
        CLOSE user2_cur;
      END IF;
-- Ver1.2(E055) Add End
-- Ver1.17 Add Start
      -- J[\N[Y
      IF ( new_emp_cur%ISOPEN ) THEN
        CLOSE new_emp_cur;
      END IF;
-- Ver1.17 Add End
      --
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ¤ÊÖáOnh ***
    WHEN global_api_expt THEN
      -- J[\N[Y
      IF ( user_cur%ISOPEN ) THEN
        CLOSE user_cur;
      END IF;
-- Ver1.2(E055) Add Start
      -- J[\N[Y
      IF ( user2_cur%ISOPEN ) THEN
        CLOSE user2_cur;
     END IF;
-- Ver1.2(E055) Add End
-- Ver1.17 Add Start
      -- J[\N[Y
      IF ( new_emp_cur%ISOPEN ) THEN
        CLOSE new_emp_cur;
      END IF;
-- Ver1.17 Add End
      --
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ¤ÊÖOTHERSáOnh ***
    WHEN global_api_others_expt THEN
      -- J[\N[Y
      IF ( user_cur%ISOPEN ) THEN
        CLOSE user_cur;
      END IF;
-- Ver1.2(E055) Add Start
      -- J[\N[Y
      IF ( user2_cur%ISOPEN ) THEN
        CLOSE user2_cur;
      END IF;
-- Ver1.2(E055) Add End
-- Ver1.17 Add Start
      -- J[\N[Y
      IF ( new_emp_cur%ISOPEN ) THEN
        CLOSE new_emp_cur;
      END IF;
-- Ver1.17 Add End
      --
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERSáOnh ***
    WHEN OTHERS THEN
      -- J[\N[Y
      IF ( user_cur%ISOPEN ) THEN
        CLOSE user_cur;
      END IF;
-- Ver1.2(E055) Add Start
      -- J[\N[Y
      IF ( user2_cur%ISOPEN ) THEN
        CLOSE user2_cur;
      END IF;
-- Ver1.2(E055) Add End
-- Ver1.17 Add Start
      -- J[\N[Y
      IF ( new_emp_cur%ISOPEN ) THEN
        CLOSE new_emp_cur;
      END IF;
-- Ver1.17 Add End
      --
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  Åè END   ##########################################
--
  END output_user;
--
--
  /**********************************************************************************
   * Procedure Name   : output_worker2
   * Description      : ]Æõîñiã·EVKÌpÞEÒjÌoEt@CoÍ(A-4)
   ***********************************************************************************/
  PROCEDURE output_worker2(
    ov_errbuf     OUT VARCHAR2,     --   G[EbZ[W           --# Åè #
    ov_retcode    OUT VARCHAR2,     --   ^[ER[h             --# Åè #
    ov_errmsg     OUT VARCHAR2)     --   [U[EG[EbZ[W --# Åè #
  IS
    -- ===============================
    -- Åè[Jè
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'output_worker2';       -- vO¼
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
    ------------------------------------
    --wb_[s(AssignmentSupervisor)
    ------------------------------------
    cv_ass_sup_header   CONSTANT VARCHAR2(3000) :=
                    'METADATA'                         --  1 : METADATA
      || cv_pipe || 'AssignmentSupervisor'             --  2 : AssignmentSupervisor
      || cv_pipe || 'AssignmentNumber'                 --  3 : AssignmentNumberiATCgÔj
      || cv_pipe || 'ManagerType'                      --  4 : ManagerTypei^Cvj
      || cv_pipe || 'ManagerAssignmentNumber'          --  5 : ManagerAssignmentNumberiã·ATCgÔj
      || cv_pipe || 'EffectiveStartDate'               --  6 : EffectiveStartDateiLøJnúj
      || cv_pipe || 'PrimaryFlag'                      --  7 : PrimaryFlagivC}j
      || cv_pipe || 'NewManagerType'                   --  8 : NewManagerTypeiVKã·^Cvj
      || cv_pipe || 'NewManagerAssignmentNumber'       --  9 : NewManagerAssignmentNumberiVKã·ATCgÔj
    ;
    --
    ------------------------------------
    --wb_[s(WorkRelationship)
    ------------------------------------
    cv_wk_rel_header   CONSTANT VARCHAR2(3000) :=
                    'METADATA'                         --  1 : METADATA
      || cv_pipe || 'WorkRelationship'                 --  2 : WorkRelationship
      || cv_pipe || 'PersonNumber'                     --  3 : PersonNumberiÂlÔj
      || cv_pipe || 'WorkerType'                       --  4 : WorkerTypeiAÆÒ^Cvj
      || cv_pipe || 'DateStart'                        --  5 : DateStartiJnúj
      || cv_pipe || 'LegalEmployerName'                --  6 : LegalEmployerNameiÙpåj
      || cv_pipe || 'PrimaryFlag'                      --  7 : PrimaryFlagivC}Ùpj
      || cv_pipe || 'ActualTerminationDate'            --  8 : ActualTerminationDateiÀÑÞEúj
      || cv_pipe || 'TerminateWorkRelationshipFlag'    --  9 : TerminateWorkRelationshipFlagiÙpÖWÌI¹j
      || cv_pipe || 'ReverseTerminationFlag'           -- 10 : ReverseTerminationFlagiÞEÌæÁj
      || cv_pipe || 'ActionCode'                       -- 11 : ActionCodeiR[hj
      || cv_pipe || 'SourceSystemOwner'                -- 12 : SourceSystemOwneri\[XEVXeLÒj
      || cv_pipe || 'SourceSystemId'                   -- 13 : SourceSystemIdi\[XEVXeIDj
    ;
--
    -- *** [JÏ ***
    lv_file_data         VARCHAR2(30000) DEFAULT NULL;       -- oÍàe
--
    -- *** [JEJ[\ ***
    --------------------------------------
    -- ATCgã·ÌoJ[\
    --------------------------------------
    CURSOR ass_sup_cur
    IS
      SELECT
          (CASE
             WHEN (xoedi.sup_assignment_number IS NOT NULL
                   AND paaf_sup.assignment_number IS NULL) THEN
               cv_meta_delete
             ELSE
               cv_meta_merge
           END)                                             AS metadata                   -- METADATA
        , paaf.assignment_number                            AS assignment_number          -- ATCgÔ
        , (CASE
-- Ver1.6 Mod Start
--             WHEN (xoedi.sup_assignment_number IS NOT NULL
--                   AND paaf_sup.assignment_number IS NULL) THEN
             WHEN xoedi.sup_assignment_number IS NOT NULL THEN
-- Ver1.6 Mod End
               xoedi.sup_assignment_number
             ELSE 
               paaf_sup.assignment_number
           END)                                             AS sup_ass_number             -- ã·ATCgÔ
        , (CASE
             WHEN xoedi.person_id IS NULL THEN
               TO_CHAR(paaf.effective_start_date, cv_date_fmt)
             ELSE
               TO_CHAR(gt_if_dest_date, cv_date_fmt)  -- Agút
           END)                                             AS effective_start_date       -- LøJnú

        , (CASE
             WHEN (xoedi.sup_assignment_number IS NOT NULL
                   AND paaf_sup.assignment_number IS NOT NULL) THEN
               cv_sup_type_line_manager
             ELSE 
               NULL
           END)                                             AS new_sup_type               -- VKã·^Cv
        , (CASE
             WHEN (xoedi.sup_assignment_number IS NOT NULL
                   AND paaf_sup.assignment_number IS NOT NULL) THEN
               paaf_sup.assignment_number
             ELSE 
               NULL
           END)                                             AS new_sup_ass_number         -- VKã·ATCgÔ
      FROM
          per_all_people_f            papf  -- ]Æõ}X^
        , per_all_assignments_f       paaf  -- ATCg}X^
        , per_periods_of_service      ppos  -- AÆîñ
        , xxcmm_oic_emp_diff_info     xoedi -- OICÐõ·ªîñe[u
        , (SELECT
               paaf_s.person_id           AS person_id           -- ÂlID
             , paaf_s.assignment_number   AS assignment_number   -- ATCgÔ
           FROM
               per_all_assignments_f    paaf_s  -- ATCg}X^(ã·)
             , per_periods_of_service   ppos_s  -- AÆîñ(ã·)
           WHERE
               paaf_s.period_of_service_id = ppos_s.period_of_service_id
           AND ppos_s.actual_termination_date IS NULL
          )                           paaf_sup  -- ATCg}X^(ã·)
      WHERE
          papf.attribute3 IN (cv_emp_kbn_internal, cv_emp_kbn_external , cv_emp_kbn_dummy)  -- ]Æõæªi1:àA2:OA4:_~[j
      AND papf.attribute4 IS NULL    -- düæR[h
      AND papf.attribute5 IS NULL    -- ^ÆÒ
      AND papf.employee_number NOT IN (cv_not_get_emp1, cv_not_get_emp2, cv_not_get_emp3, cv_not_get_emp4, 
                                       cv_not_get_emp5, cv_not_get_emp6, cv_not_get_emp7, cv_not_get_emp8)  -- ]ÆõÔ
      AND papf.effective_start_date = 
              (SELECT
                   MAX(papf2.effective_start_date)
               FROM
                   per_all_people_f  papf2 -- ]Æõ}X^
               WHERE
                   papf2.person_id = papf.person_id
              )
      AND papf.person_id = paaf.person_id
      AND paaf.effective_start_date = 
              (SELECT
                   MAX(paaf2.effective_start_date)
               FROM
                   per_all_assignments_f  paaf2  -- ATCg}X^
               WHERE
                   paaf2.person_id = paaf.person_id
              )
      AND paaf.period_of_service_id = ppos.period_of_service_id
      AND ppos.person_id            = xoedi.person_id(+)
      AND ppos.date_start           = xoedi.date_start(+)
      AND paaf.supervisor_id        = paaf_sup.person_id(+)
      AND (   xoedi.sup_assignment_number IS NOT NULL
           OR paaf.supervisor_id IS NOT NULL)
-- Ver1.12 Add Start
      AND (   ppos.actual_termination_date IS NULL
           OR xoedi.person_id IS NULL)
-- Ver1.12 Add End
-- Ver1.18 Mod Start
--      AND (   paaf.last_update_date >= gt_pre_process_date
--           OR paaf.ass_attribute19  >= gv_str_pre_process_date)
           
      AND (
              (     paaf.last_update_date >= gt_pre_process_date
                AND paaf.last_update_date <  gt_cur_process_date
              )
           OR (
                    paaf.ass_attribute19  >= gv_str_pre_process_date
                AND paaf.ass_attribute19  <  gv_str_cur_process_date
              )
          )
-- Ver1.18 Mod End
      ORDER BY
        paaf.assignment_number ASC
    ;
--
    --------------------------------------
    -- ÙpÖWiVKÌpÞEÒjÌoJ[\
    --------------------------------------
    CURSOR wk_rel2_cur
    IS
      SELECT
          papf.employee_number                              AS employee_number            -- ]ÆõÔ
        , TO_CHAR(ppos.date_start, cv_date_fmt)             AS date_start                 -- Jnú
        , TO_CHAR(ppos.actual_termination_date
                  , cv_date_fmt)                            AS actual_termination_date    -- ÀÑÞEú
        , ppos.period_of_service_id                         AS period_of_service_id       -- AÆîñID
      FROM
          per_all_people_f              papf  -- ]Æõ}X^
        , per_all_assignments_f         paaf  -- ATCg}X^
        , per_periods_of_service        ppos  -- AÆîñ
      WHERE
          papf.attribute3 IN (cv_emp_kbn_internal, cv_emp_kbn_external , cv_emp_kbn_dummy)  -- ]Æõæªi1:àA2:OA4:_~[j
      AND papf.attribute4 IS NULL    -- düæR[h
      AND papf.attribute5 IS NULL    -- ^ÆÒ
      AND papf.employee_number NOT IN (cv_not_get_emp1, cv_not_get_emp2, cv_not_get_emp3, cv_not_get_emp4, 
                                       cv_not_get_emp5, cv_not_get_emp6, cv_not_get_emp7, cv_not_get_emp8)  -- ]ÆõÔ
      AND papf.effective_start_date = 
              (SELECT
                   MAX(papf2.effective_start_date)
               FROM
                   per_all_people_f        papf2 -- ]Æõ}X^
               WHERE
                   papf2.person_id = papf.person_id
              )
      AND papf.person_id = paaf.person_id
      AND paaf.effective_start_date = 
              (SELECT
                   MAX(paaf2.effective_start_date)
               FROM
                   per_all_assignments_f   paaf2  -- ATCg}X^
               WHERE
                   paaf2.person_id = paaf.person_id
              )
      AND paaf.period_of_service_id = ppos.period_of_service_id
      AND ppos.actual_termination_date IS NOT NULL
      AND NOT EXISTS
              (SELECT
                   1  AS flag
               FROM
                   xxcmm_oic_emp_diff_info   xoedi -- OICÐõ·ªîñe[u
               WHERE
                   xoedi.person_id  = ppos.person_id
               AND xoedi.date_start = ppos.date_start
              )
-- Ver1.18 Mod Start
--      AND ppos.last_update_date >= gt_pre_process_date
      AND (
                ppos.last_update_date >= gt_pre_process_date
            AND ppos.last_update_date <  gt_cur_process_date
          )
-- Ver1.18 Mod End
      ORDER BY
          papf.employee_number ASC
    ;
--
    -- *** [JER[h ***
    l_ass_sup_rec      ass_sup_cur%ROWTYPE;    -- ATCgã·ÌoJ[\R[h
    l_wk_rel2_rec      wk_rel2_cur%ROWTYPE;    -- ÙpÖWiVKÌpÞEÒjÌoJ[\R[h
--
  BEGIN
--
--##################  ÅèXe[^Xú» START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  Åè END   ############################
--
    -- ==============================================================
    -- ATCgîñiã·jÌo(A-4-1)
    -- ==============================================================
    -- J[\I[v
    OPEN ass_sup_cur;
    <<output_ass_sup_loop>>
    LOOP
      --
      FETCH ass_sup_cur INTO l_ass_sup_rec;
      EXIT WHEN ass_sup_cur%NOTFOUND;
      --
      -- oJEgAbv
      gn_get_ass_sup_cnt := gn_get_ass_sup_cnt + 1;
      --
      -- ==============================================================
      -- ATCgîñiã·jÌt@CoÍ(A-4-2)
      -- ==============================================================
      -- wb_[sÌì¬iñÌÝj
      IF ( gn_get_ass_sup_cnt = 1 ) THEN
        --
        BEGIN
          -- wb_[sÌt@CoÍ
          UTL_FILE.PUT_LINE( gf_wrk2_file_handle  -- ]Æõîñiã·EVKÌpÞEÒjAgf[^t@C
                           , cv_ass_sup_header
                           );
        EXCEPTION
          WHEN OTHERS THEN
            RAISE global_fileout_expt;
        END;
      END IF;
      --
      -- f[^sÌì¬
      lv_file_data := l_ass_sup_rec.metadata;                                             -- 1 : METADATA
      lv_file_data := lv_file_data || cv_pipe || cv_cls_ass_super;                        -- 2 : AssignmentSupervisor
      lv_file_data := lv_file_data || cv_pipe || l_ass_sup_rec.assignment_number;         -- 3 : AssignmentNumberiATCgÔj
      lv_file_data := lv_file_data || cv_pipe || cv_sup_type_line_manager;                -- 4 : ManagerTypei^Cvj
      lv_file_data := lv_file_data || cv_pipe || l_ass_sup_rec.sup_ass_number;            -- 5 : ManagerAssignmentNumberiã·ATCgÔj
      lv_file_data := lv_file_data || cv_pipe || l_ass_sup_rec.effective_start_date;      -- 6 : EffectiveStartDateiLøJnúj
      lv_file_data := lv_file_data || cv_pipe || cv_y;                                    -- 7 : PrimaryFlagivC}j
      lv_file_data := lv_file_data || cv_pipe || l_ass_sup_rec.new_sup_type;              -- 8 : NewManagerTypeiVKã·^Cvj
      lv_file_data := lv_file_data || cv_pipe || l_ass_sup_rec.new_sup_ass_number;        -- 9 : NewManagerAssignmentNumberiVKã·ATCgÔj
      --
      BEGIN
        -- f[^sÌt@CoÍ
        UTL_FILE.PUT_LINE( gf_wrk2_file_handle  -- ]Æõîñiã·EVKÌpÞEÒjAgf[^t@C
                         , lv_file_data
                         );
        -- oÍJEgAbv
        gn_out_wk2_cnt := gn_out_wk2_cnt + 1;
      EXCEPTION
        WHEN OTHERS THEN
          RAISE global_fileout_expt;
      END;
    --
    END LOOP output_ass_sup_loop;
--
    -- oª1Èã éê
    IF ( gn_get_ass_sup_cnt > 0 ) THEN
      BEGIN
        -- ósðt@CoÍ
        UTL_FILE.PUT_LINE( gf_wrk2_file_handle  -- ]Æõîñiã·EVKÌpÞEÒjAgf[^t@C
                         , ''
                         );
      EXCEPTION
        WHEN OTHERS THEN
          RAISE global_fileout_expt;
      END;
    END IF;
--
    -- J[\N[Y
    CLOSE ass_sup_cur;
--
--
    -- ==============================================================
    -- ÙpÖWiVKÌpÞEÒjÌo(A-4-3)
    -- ==============================================================
    -- J[\I[v
    OPEN wk_rel2_cur;
    <<output_wk_rel2_loop>>
    LOOP
      --
      FETCH wk_rel2_cur INTO l_wk_rel2_rec;
      EXIT WHEN wk_rel2_cur%NOTFOUND;
      --
      -- oJEgAbv
      gn_get_wk_rel2_cnt := gn_get_wk_rel2_cnt + 1;
      --
      -- ==============================================================
      -- ÙpÖWiVKÌpÞEÒjÌt@CoÍ(A-4-4)
      -- ==============================================================
      -- wb_[sÌì¬iñÌÝj
      IF ( gn_get_wk_rel2_cnt = 1 ) THEN
        --
        BEGIN
          -- wb_[sÌt@CoÍ
          UTL_FILE.PUT_LINE( gf_wrk2_file_handle  -- ]Æõîñiã·EVKÌpÞEÒjAgf[^t@C
                           , cv_wk_rel_header
                           );
        EXCEPTION
          WHEN OTHERS THEN
            RAISE global_fileout_expt;
        END;
      END IF;
      --
      -- f[^sÌì¬
      lv_file_data := cv_meta_merge;                                                      --  1 : METADATA
      lv_file_data := lv_file_data || cv_pipe || cv_cls_wk_rel;                           --  2 : WorkRelationship
      lv_file_data := lv_file_data || cv_pipe || l_wk_rel2_rec.employee_number;           --  3 : PersonNumberiÂlÔj
      lv_file_data := lv_file_data || cv_pipe || cv_wk_type_e;                            --  4 : WorkerTypeiAÆÒ^Cvj
      lv_file_data := lv_file_data || cv_pipe || l_wk_rel2_rec.date_start;                --  5 : DateStartiJnúj
      lv_file_data := lv_file_data || cv_pipe || cv_sales_le;                             --  6 : LegalEmployerNameiÙpåj
      lv_file_data := lv_file_data || cv_pipe || cv_y;                                    --  7 : PrimaryFlagivC}Ùpj
      lv_file_data := lv_file_data || cv_pipe || l_wk_rel2_rec.actual_termination_date;   --  8 : ActualTerminationDateiÀÑÞEúj
      lv_file_data := lv_file_data || cv_pipe || cv_y;                                    --  9 : TerminateWorkRelationshipFlagiÙpÖWÌI¹j
      lv_file_data := lv_file_data || cv_pipe || NULL;                                    -- 10 : ReverseTerminationFlagiÞEÌæÁj
      lv_file_data := lv_file_data || cv_pipe || cv_act_cd_termination;                   -- 11 : ActionCodeiR[hj
      lv_file_data := lv_file_data || cv_pipe || cv_ebs;                                  -- 12 : SourceSystemOwneri\[XEVXeLÒj
      lv_file_data := lv_file_data || cv_pipe || l_wk_rel2_rec.period_of_service_id;      -- 13 : SourceSystemIdi\[XEVXeIDj
      --
      BEGIN
        -- f[^sÌt@CoÍ
        UTL_FILE.PUT_LINE( gf_wrk2_file_handle  -- ]Æõîñiã·EVKÌpÞEÒjAgf[^t@C
                         , lv_file_data
                         );
        -- oÍJEgAbv
        gn_out_wk2_cnt := gn_out_wk2_cnt + 1;
      EXCEPTION
        WHEN OTHERS THEN
          RAISE global_fileout_expt;
      END;
    --
    END LOOP output_wk_rel2_loop;
--
    -- J[\N[Y
    CLOSE wk_rel2_cur;
--
  EXCEPTION
    -- *** t@CoÍáOnh ***
    WHEN global_fileout_expt THEN
      -- J[\N[Y
      IF ( ass_sup_cur%ISOPEN ) THEN
        CLOSE ass_sup_cur;
      END IF;
      --
      IF ( wk_rel2_cur%ISOPEN ) THEN
        CLOSE wk_rel2_cur;
      END IF;
      --
      lv_errmsg := SUBSTRB(
                     xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_xxcmm             -- AvP[VZk¼FXXCMM
                     , iv_name         => cv_file_write_err_msg     -- bZ[W¼Ft@C«ÝG[bZ[W
                     , iv_token_name1  => cv_tkn_sqlerrm            -- g[N¼1FSQLERRM
                     , iv_token_value1 => SQLERRM                   -- g[Nl1FSQLERRM
                     )
                   , 1
                   , 5000
                   );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  ÅèáO START   ####################################
--
    -- *** ¤ÊáOnh ***
    WHEN global_process_expt THEN
      -- J[\N[Y
      IF ( ass_sup_cur%ISOPEN ) THEN
        CLOSE ass_sup_cur;
      END IF;
      --
      IF ( wk_rel2_cur%ISOPEN ) THEN
        CLOSE wk_rel2_cur;
      END IF;
      --
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ¤ÊÖáOnh ***
    WHEN global_api_expt THEN
      -- J[\N[Y
      IF ( ass_sup_cur%ISOPEN ) THEN
        CLOSE ass_sup_cur;
      END IF;
      --
      IF ( wk_rel2_cur%ISOPEN ) THEN
        CLOSE wk_rel2_cur;
      END IF;
      --
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ¤ÊÖOTHERSáOnh ***
    WHEN global_api_others_expt THEN
      -- J[\N[Y
      IF ( ass_sup_cur%ISOPEN ) THEN
        CLOSE ass_sup_cur;
      END IF;
      --
      IF ( wk_rel2_cur%ISOPEN ) THEN
        CLOSE wk_rel2_cur;
      END IF;
      --
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERSáOnh ***
    WHEN OTHERS THEN
      -- J[\N[Y
      IF ( ass_sup_cur%ISOPEN ) THEN
        CLOSE ass_sup_cur;
      END IF;
      --
      IF ( wk_rel2_cur%ISOPEN ) THEN
        CLOSE wk_rel2_cur;
      END IF;
      --
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  Åè END   ##########################################
--
  END output_worker2;
--
--
  /**********************************************************************************
   * Procedure Name   : output_emp_bank_acct
   * Description      : ]ÆõoïûÀîñÌoEt@CoÍ(A-5)
   ***********************************************************************************/
  PROCEDURE output_emp_bank_acct(
    ov_errbuf     OUT VARCHAR2,     --   G[EbZ[W           --# Åè #
    ov_retcode    OUT VARCHAR2,     --   ^[ER[h             --# Åè #
    ov_errmsg     OUT VARCHAR2)     --   [U[EG[EbZ[W --# Åè #
  IS
    -- ===============================
    -- Åè[Jè
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'output_emp_bank_acct';       -- vO¼
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
    lv_file_data         VARCHAR2(30000) DEFAULT NULL;       -- oÍàe
--
    -- *** [JEJ[\ ***
    --------------------------------------
    -- ]ÆõoïûÀîñÌoJ[\
    --------------------------------------
    CURSOR bank_acc_cur
    IS
-- Ver1.21 Mod Start
--      SELECT
--          papf.employee_number          AS employee_number         -- ]ÆõÔ
--        , abb.bank_number               AS bank_number             -- âsÔ
--        , abb.bank_num                  AS bank_num                -- âsxXÔ
--        , abb.bank_name                 AS bank_name               -- âs¼
--        , abb.bank_branch_name          AS bank_branch_name        -- âsxX¼
--        , abaa.bank_account_type        AS bank_account_type       -- ûÀíÊ
--        , abaa.bank_account_num         AS bank_account_num        -- ûÀÔ
---- Ver1.1 Mod Start
----        , abb.country                   AS country                 -- 
----        , abaa.currency_code            AS currency_code           -- ÊÝR[h
--        , NVL(abb.country, cv_jp)       AS country                 -- 
---- Ver1.7 Mod Start
----        , NVL(abaa.currency_code, cv_yen) AS currency_code         -- ÊÝR[h
--        , cv_nvl_v                      AS currency_code           -- ÊÝR[h
---- Ver1.7 Mod End
---- Ver1.1 Mod End
--        , abaa.account_holder_name      AS account_holder_name     -- ûÀ¼`l
--        , abaa.account_holder_name_alt  AS account_holder_name_alt -- ûÀ¼`lJi
--        , (CASE
--             WHEN abaa.inactive_date <= gt_if_dest_date THEN
--               cv_y
--             ELSE
---- Ver1.9 Mod Start
----               NULL
--               cv_n
---- Ver1.9 Mod End
--           END)                         AS inactive_flag           -- ñANeBu
--        , (CASE
--             WHEN ROW_NUMBER() OVER(
--                    PARTITION BY abb.bank_number
--                               , abb.bank_num
---- Ver1.11 Add Start
--                               , abb.bank_name
--                               , abb.bank_branch_name
---- Ver1.11 Add End
--                               , abaa.bank_account_type
--                               , abaa.bank_account_num
---- Ver1.1 Mod Start
----                               , abaa.currency_code
----                               , abb.country
--                               , NVL(abaa.currency_code, cv_yen)
--                               , NVL(abb.country, cv_jp)
---- Ver1.1 Mod End
--                    ORDER BY  abb.bank_number
--                            , abb.bank_num
---- Ver1.11 Add Start
--                            , abb.bank_name
--                            , abb.bank_branch_name
---- Ver1.11 Add End
--                            , abaa.bank_account_type
--                            , abaa.bank_account_num
---- Ver1.1 Mod Start
----                            , abaa.currency_code
----                            , abb.country
--                            , NVL(abaa.currency_code, cv_yen)
--                            , NVL(abb.country, cv_jp)
---- Ver1.1 Mod End
--                            , abaua.bank_account_uses_id
--                  ) = 1 THEN
--               cv_y
--             ELSE
--               cv_n
--           END)                         AS primary_flag             -- vC}tO
--        , abaua.primary_flag            AS expense_primary_flag     -- oïvC}tO
--      FROM
--          per_all_people_f           papf  -- ]Æõ}X^
--        , po_vendors                 pv    -- düæ}X^
--        , po_vendor_sites_all        pvsa  -- düæTCg}X^
--        , ap_bank_accounts_all       abaa  -- âsûÀ}X^
--        , ap_bank_branches           abb   -- âsxX}X^
--        , ap_bank_account_uses_all   abaua -- âsûÀgp}X^ 
--      WHERE
--          papf.attribute3 IN (cv_emp_kbn_internal, cv_emp_kbn_dummy)  -- ]Æõæªi1:àA4:_~[j
---- Ver1.9 Add Start
--      AND papf.attribute4 IS NULL    -- düæR[h
--      AND papf.attribute5 IS NULL    -- ^ÆÒ
---- Ver1.9 Add End
--      AND papf.employee_number NOT IN (cv_not_get_emp1, cv_not_get_emp2, cv_not_get_emp3, cv_not_get_emp4, 
--                                       cv_not_get_emp5, cv_not_get_emp6, cv_not_get_emp7, cv_not_get_emp8)  -- ]ÆõÔ
--      AND papf.effective_start_date = 
--              (SELECT
--                   MAX(papf2.effective_start_date)
--               FROM
--                   per_all_people_f  papf2 -- ]Æõ}X^
--               WHERE
--                   papf2.person_id = papf.person_id
--              )
--      AND papf.person_id                 = pv.employee_id
--      AND pv.vendor_type_lookup_code     = cv_vd_type_employee
--      AND pv.vendor_id                   = pvsa.vendor_id
---- Ver1.2(E056) Add Start
--      AND pvsa.vendor_site_code          = cv_site_code_comp
---- Ver1.2(E056) Add End
--      AND pvsa.vendor_id                 = abaua.vendor_id
--      AND pvsa.vendor_site_id            = abaua.vendor_site_id
--      AND abaua.external_bank_account_id = abaa.bank_account_id
--      AND abaa.account_type              = cv_acct_type_sup
--      AND abaa.bank_branch_id            = abb.bank_branch_id
---- Ver1.18 Mod Start
----      AND (   abaua.creation_date   >= gt_pre_process_date
----           OR abaa.last_update_date >= gt_pre_process_date
----           OR abaa.inactive_date    =  gt_if_dest_date)
--      AND (
--               (      abaua.creation_date   >= gt_pre_process_date
--                  AND abaua.creation_date   <  gt_cur_process_date
--               )
--           OR  (
--                      abaa.last_update_date >= gt_pre_process_date
--                  AND abaa.last_update_date <  gt_cur_process_date
--               )
---- Ver1.19 Add Start
--           OR  (
--                      abb.last_update_date  >= gt_pre_process_date
--                  AND abb.last_update_date  <  gt_cur_process_date
--               )
---- Ver1.19 Add End
--           OR         abaa.inactive_date    =  gt_if_dest_date
--          )
---- Ver1.18 Mod End
--      ORDER BY
--          abb.bank_number
--        , abb.bank_num
---- Ver1.11 Add Start
--        , abb.bank_name
--        , abb.bank_branch_name
---- Ver1.11 Add End
--        , abaa.bank_account_type
--        , abaa.bank_account_num
---- Ver1.1 Mod Start
----        , abaa.currency_code
----        , abb.country
--        , NVL(abaa.currency_code, cv_yen)
--        , NVL(abb.country, cv_jp)
---- Ver1.1 Mod End
--        , abaua.bank_account_uses_id

      SELECT
          abset.employee_number          AS employee_number         -- 1.]ÆõÔ
        , abset.bank_number              AS bank_number             -- 2.âsÔ
        , abset.bank_num                 AS bank_num                -- 3.âsxXÔ
        , abset.bank_name                AS bank_name               -- 4.âs¼
        , abset.bank_branch_name         AS bank_branch_name        -- 5.âsxX¼
        , abset.bank_account_type        AS bank_account_type       -- 6.ûÀíÊ
        , abset.bank_account_num         AS bank_account_num        -- 7.ûÀÔ
        , abset.country                  AS country                 -- 8.R[h
        , abset.currency_code            AS currency_code           -- 9.ÊÝR[h
        , abset.account_holder_name      AS account_holder_name     -- 10.ûÀ¼`l
        , abset.account_holder_name_alt  AS account_holder_name_alt -- 11.ûÀ¼`lJi
        , abset.inactive_flag            AS inactive_flag           -- 12.ñANeBu
        , abset.primary_flag             AS primary_flag            -- 13.vC}tO
        , abset.expense_primary_flag     AS expense_primary_flag    -- 14.oïvC}tO
      FROM
          (
            SELECT
                papf.employee_number          AS employee_number         -- 1.]ÆõÔ
              , abb.bank_number               AS bank_number             -- 2.âsÔ
              , abb.bank_num                  AS bank_num                -- 3.âsxXÔ
              , abb.bank_name                 AS bank_name               -- 4.âs¼
              , abb.bank_branch_name          AS bank_branch_name        -- 5.âsxX¼
              , abaa.bank_account_type        AS bank_account_type       -- 6.ûÀíÊ
              , abaa.bank_account_num         AS bank_account_num        -- 7.ûÀÔ
              , NVL(abb.country, cv_jp)       AS country                 -- 8.R[h
              , cv_nvl_v                      AS currency_code           -- 9.ÊÝR[h
              , abaa.account_holder_name      AS account_holder_name     -- 10.ûÀ¼`l
              , abaa.account_holder_name_alt  AS account_holder_name_alt -- 11.ûÀ¼`lJi
              , (CASE
                   WHEN abaa.inactive_date <= gt_if_dest_date THEN
                     cv_y
                   ELSE
                     cv_n
                 END)                         AS inactive_flag           -- 12.ñANeBu
              , (CASE
                   WHEN ROW_NUMBER() OVER(
                          PARTITION BY abb.bank_number
                                     , abb.bank_num
                                     , abb.bank_name
                                     , abb.bank_branch_name
                                     , abaa.bank_account_type
                                     , abaa.bank_account_num
                                     , NVL(abaa.currency_code, cv_yen)
                                     , NVL(abb.country, cv_jp)
                          ORDER BY  abb.bank_number
                                  , abb.bank_num
                                  , abb.bank_name
                                  , abb.bank_branch_name
                                  , abaa.bank_account_type
                                  , abaa.bank_account_num
                                  , NVL(abaa.currency_code, cv_yen)
                                  , NVL(abb.country, cv_jp)
                                  , abaua.bank_account_uses_id
                        ) = 1 THEN
                     cv_y
                   ELSE
                     cv_n
                 END)                         AS primary_flag             -- 13.vC}tO
              , abaua.primary_flag            AS expense_primary_flag     -- 14.oïvC}tO
              , abaua.bank_account_uses_id    AS bank_account_uses_id     -- 15.ûÀ[U[ID
              , abaua.creation_date           AS abaua_creation_date      -- 16.âsûÀgp}X^Ìì¬út
              , abaa.last_update_date         AS abaa_last_update_date    -- 17.âsûÀ}X^ÌÅIXVú
              , abb.last_update_date          AS abb_last_update_date     -- 18.âsxX}X^ÌÅIXVú
              , abaa.inactive_date            AS abaa_inactive_date       -- 19.âsûÀ}X^Ì³øú
-- Ver1.22 Add Start
              , abaua.last_update_date        AS abaua_last_update_date   -- 20.âsûÀgp}X^ÌÅIXVú
-- Ver1.22 Add End
            FROM
                per_all_people_f           papf  -- ]Æõ}X^
              , po_vendors                 pv    -- düæ}X^
              , po_vendor_sites_all        pvsa  -- düæTCg}X^
              , ap_bank_accounts_all       abaa  -- âsûÀ}X^
              , ap_bank_branches           abb   -- âsxX}X^
              , ap_bank_account_uses_all   abaua -- âsûÀgp}X^ 
            WHERE
                papf.attribute3 IN (cv_emp_kbn_internal, cv_emp_kbn_dummy)  -- ]Æõæªi1:àA4:_~[j
            AND papf.attribute4 IS NULL    -- düæR[h
            AND papf.attribute5 IS NULL    -- ^ÆÒ
            AND papf.employee_number NOT IN (cv_not_get_emp1, cv_not_get_emp2, cv_not_get_emp3, cv_not_get_emp4, 
                                             cv_not_get_emp5, cv_not_get_emp6, cv_not_get_emp7, cv_not_get_emp8)  -- ]ÆõÔ
            AND papf.effective_start_date = 
                    (SELECT
                         MAX(papf2.effective_start_date)
                     FROM
                         per_all_people_f  papf2  -- ]Æõ}X^
                     WHERE
                         papf2.person_id = papf.person_id
                    )
            AND papf.person_id                 = pv.employee_id
            AND pv.vendor_type_lookup_code     = cv_vd_type_employee
            AND pv.vendor_id                   = pvsa.vendor_id
            AND pvsa.vendor_site_code          = cv_site_code_comp
            AND pvsa.vendor_id                 = abaua.vendor_id
            AND pvsa.vendor_site_id            = abaua.vendor_site_id
            AND abaua.external_bank_account_id = abaa.bank_account_id
            AND abaa.account_type              = cv_acct_type_sup
            AND abaa.bank_branch_id            = abb.bank_branch_id
          )  abset  -- âsûÀÖAe[u
      WHERE
          (
               (      abset.abaua_creation_date   >= gt_pre_process_date
                  AND abset.abaua_creation_date   <  gt_cur_process_date
               )
-- Ver1.22 Add Start
           OR  (
                      abset.abaua_last_update_date >= gt_pre_process_date
                  AND abset.abaua_last_update_date <  gt_cur_process_date
                  AND abset.abaua_creation_date    <  gt_pre_process_date
               )
-- Ver1.22 Add End
           OR  (
                      abset.abaa_last_update_date >= gt_pre_process_date
                  AND abset.abaa_last_update_date <  gt_cur_process_date
               )
           OR  (
                      abset.abb_last_update_date  >= gt_pre_process_date
                  AND abset.abb_last_update_date  <  gt_cur_process_date
               )
           OR         abset.abaa_inactive_date    =  gt_if_dest_date
          )
      ORDER BY
          abset.bank_number
        , abset.bank_num
        , abset.bank_name
        , abset.bank_branch_name
        , abset.bank_account_type
        , abset.bank_account_num
        , abset.currency_code
        , abset.country
        , abset.bank_account_uses_id
-- Ver1.21 Mod End
    ;
--
    -- *** [JER[h ***
    l_bank_acc_rec      bank_acc_cur%ROWTYPE;    -- ]ÆõoïûÀîñÌoJ[\R[h
--
  BEGIN
--
--##################  ÅèXe[^Xú» START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  Åè END   ############################
--
    -- ==============================================================
    -- ]ÆõoïûÀîñÌo(A-5-1)
    -- ==============================================================
    -- J[\I[v
    OPEN bank_acc_cur;
    <<output_bank_acc_loop>>
    LOOP
      --
      FETCH bank_acc_cur INTO l_bank_acc_rec;
      EXIT WHEN bank_acc_cur%NOTFOUND;
      --
      -- oJEgAbv
      gn_get_bank_acc_cnt := gn_get_bank_acc_cnt + 1;
      --
      -- ==============================================================
      -- ]ÆõoïûÀîñÌt@CoÍ(A-5-2)
      -- ==============================================================
      -- f[^sÌì¬
      lv_file_data := xxccp_oiccommon_pkg.to_csv_string( l_bank_acc_rec.employee_number         , cv_space );  --  1 : ]ÆõÔ
      lv_file_data := lv_file_data || cv_comma ||
                      xxccp_oiccommon_pkg.to_csv_string( l_bank_acc_rec.bank_number             , cv_space );  --  2 : âsÔ
      lv_file_data := lv_file_data || cv_comma ||
                      xxccp_oiccommon_pkg.to_csv_string( l_bank_acc_rec.bank_num                , cv_space );  --  3 : âsxXÔ
      lv_file_data := lv_file_data || cv_comma ||
                      xxccp_oiccommon_pkg.to_csv_string( l_bank_acc_rec.bank_name               , cv_space );  --  4 : âs¼
      lv_file_data := lv_file_data || cv_comma ||
                      xxccp_oiccommon_pkg.to_csv_string( l_bank_acc_rec.bank_branch_name        , cv_space );  --  5 : âsxX¼
      lv_file_data := lv_file_data || cv_comma ||
                      xxccp_oiccommon_pkg.to_csv_string( l_bank_acc_rec.bank_account_type       , cv_space );  --  6 : ûÀíÊ
      lv_file_data := lv_file_data || cv_comma ||
                      xxccp_oiccommon_pkg.to_csv_string( l_bank_acc_rec.bank_account_num        , cv_space );  --  7 : ûÀÔ
      lv_file_data := lv_file_data || cv_comma ||
                      xxccp_oiccommon_pkg.to_csv_string( l_bank_acc_rec.country                 , cv_space );  --  8 : R[h
      lv_file_data := lv_file_data || cv_comma ||
                      xxccp_oiccommon_pkg.to_csv_string( l_bank_acc_rec.currency_code           , cv_space );  --  9 : ÊÝR[h
      lv_file_data := lv_file_data || cv_comma ||
                      xxccp_oiccommon_pkg.to_csv_string( l_bank_acc_rec.account_holder_name     , cv_space );  -- 10 : ûÀ¼`l
      lv_file_data := lv_file_data || cv_comma ||
                      xxccp_oiccommon_pkg.to_csv_string( l_bank_acc_rec.account_holder_name_alt , cv_space );  -- 11 : JiûÀ¼`
      lv_file_data := lv_file_data || cv_comma ||
                      xxccp_oiccommon_pkg.to_csv_string( l_bank_acc_rec.inactive_flag           , cv_space );  -- 12 : ñANeBu
      lv_file_data := lv_file_data || cv_comma ||
                      xxccp_oiccommon_pkg.to_csv_string( l_bank_acc_rec.primary_flag            , cv_space );  -- 13 : vC}tO
      lv_file_data := lv_file_data || cv_comma ||
                      xxccp_oiccommon_pkg.to_csv_string( l_bank_acc_rec.expense_primary_flag    , cv_space );  -- 14 : oïvC}tO
      --
      BEGIN
        -- f[^sÌt@CoÍ
        UTL_FILE.PUT_LINE( gf_emp_bnk_file_handle  -- PaaSpÌ]ÆõoïûÀîñt@C
                         , lv_file_data
                         );
        -- oÍJEgAbv
        gn_out_p_bank_acct_cnt := gn_out_p_bank_acct_cnt + 1;
      EXCEPTION
        WHEN OTHERS THEN
          RAISE global_fileout_expt;
      END;
    --
    END LOOP output_bank_acc_loop;
--
    -- J[\N[Y
    CLOSE bank_acc_cur;
--
  EXCEPTION
    -- *** t@CoÍáOnh ***
    WHEN global_fileout_expt THEN
      -- J[\N[Y
      IF ( bank_acc_cur%ISOPEN ) THEN
        CLOSE bank_acc_cur;
      END IF;
      --
      lv_errmsg := SUBSTRB(
                     xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_xxcmm             -- AvP[VZk¼FXXCMM
                     , iv_name         => cv_file_write_err_msg     -- bZ[W¼Ft@C«ÝG[bZ[W
                     , iv_token_name1  => cv_tkn_sqlerrm            -- g[N¼1FSQLERRM
                     , iv_token_value1 => SQLERRM                   -- g[Nl1FSQLERRM
                     )
                   , 1
                   , 5000
                   );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  ÅèáO START   ####################################
--
    -- *** ¤ÊáOnh ***
    WHEN global_process_expt THEN
      -- J[\N[Y
      IF ( bank_acc_cur%ISOPEN ) THEN
        CLOSE bank_acc_cur;
      END IF;
      --
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ¤ÊÖáOnh ***
    WHEN global_api_expt THEN
      -- J[\N[Y
      IF ( bank_acc_cur%ISOPEN ) THEN
        CLOSE bank_acc_cur;
      END IF;
      --
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ¤ÊÖOTHERSáOnh ***
    WHEN global_api_others_expt THEN
      -- J[\N[Y
      IF ( bank_acc_cur%ISOPEN ) THEN
        CLOSE bank_acc_cur;
      END IF;
      --
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERSáOnh ***
    WHEN OTHERS THEN
      -- J[\N[Y
      IF ( bank_acc_cur%ISOPEN ) THEN
        CLOSE bank_acc_cur;
      END IF;
      --
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  Åè END   ##########################################
--
  END output_emp_bank_acct;
--
--
  /**********************************************************************************
   * Procedure Name   : output_emp_info
   * Description      : Ðõ·ªîñÌoEt@CoÍiPaaSpj(A-6)
   ***********************************************************************************/
  PROCEDURE output_emp_info(
    ov_errbuf     OUT VARCHAR2,     --   G[EbZ[W           --# Åè #
    ov_retcode    OUT VARCHAR2,     --   ^[ER[h             --# Åè #
    ov_errmsg     OUT VARCHAR2)     --   [U[EG[EbZ[W --# Åè #
  IS
    -- ===============================
    -- Åè[Jè
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'output_emp_info';       -- vO¼
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
    lv_file_data         VARCHAR2(30000) DEFAULT NULL;       -- oÍàe
-- Ver1.17 Add Start
    lv_new_emp_flag      VARCHAR2(1);                        -- VüÐõtO
-- Ver1.17 Add End
--
    -- *** [JEJ[\ ***
    --------------------------------------
    -- Ðõ·ªîñÌoJ[\
    --------------------------------------
    CURSOR emp_info_cur
    IS
      SELECT
          fu.user_name                      AS user_name                    -- [U[¼
        , papf.employee_number              AS employee_number              -- ]ÆõÔ
        , papf.person_id                    AS person_id                    -- ÂlID
        , papf.last_name                    AS last_name                    -- Ji©
        , papf.first_name                   AS first_name                   -- Ji¼
        , papf.attribute28                  AS location_code                -- _R[h
        , papf.attribute7                   AS license_code                 -- iR[h(V)
        , papf.attribute11                  AS job_post                     -- EÊR[h(V)
        , papf.attribute15                  AS job_duty                     -- E±R[h(V)
        , papf.attribute19                  AS job_type                     -- EíR[h(V)
        , xwhd.dpt1_cd                      AS dpt1_cd                      -- 1KwÚåR[h
        , xwhd.dpt2_cd                      AS dpt2_cd                      -- 2KwÚåR[h
        , xwhd.dpt3_cd                      AS dpt3_cd                      -- 3KwÚåR[h
        , xwhd.dpt4_cd                      AS dpt4_cd                      -- 4KwÚåR[h
        , xwhd.dpt5_cd                      AS dpt5_cd                      -- 5KwÚåR[h
        , xwhd.dpt6_cd                      AS dpt6_cd                      -- 6KwÚåR[h
        , paaf_sup.assignment_number        AS sup_assignment_number        -- ã·ATCgÔ
        , ppos.date_start                   AS date_start                   -- Jnú
        , ppos.actual_termination_date      AS actual_termination_date      -- ÞEú
        , (CASE
             WHEN (fu.user_id IS NULL OR
                   (xoedi.person_id IS NOT NULL AND xoedi.user_name IS NULL)) THEN
               cv_n
             WHEN xoedi.person_id IS NULL THEN
               cv_y
             ELSE
               (CASE
                  WHEN (   papf.last_name             <> xoedi.last_name
                        OR NVL(papf.first_name , '@') <> NVL(xoedi.first_name,    '@')
                        OR NVL(papf.attribute28, '@') <> NVL(xoedi.location_code, '@')
                        OR NVL(papf.attribute7,  '@') <> NVL(xoedi.license_code,  '@')
                        OR NVL(papf.attribute11, '@') <> NVL(xoedi.job_post,      '@')
                        OR NVL(papf.attribute15, '@') <> NVL(xoedi.job_duty,      '@')
                        OR NVL(papf.attribute19, '@') <> NVL(xoedi.job_type,      '@')
-- Ver1.16 Add Start
                        OR ppos.date_start            <> xoedi.date_start
-- Ver1.16 Add End
                       ) THEN
                    cv_y
                  ELSE
                    cv_n
                END)
           END)                             AS roll_change_flag             -- [ÏXtO
        , (CASE
             WHEN xoedi.person_id IS NULL THEN
               cv_y
             ELSE
               (CASE
                  WHEN (   NVL(xwhd.dpt1_cd, '@')                 <> NVL(xoedi.dpt1_cd,   '@')
                        OR NVL(xwhd.dpt2_cd, '@')                 <> NVL(xoedi.dpt2_cd,   '@')
                        OR NVL(xwhd.dpt3_cd, '@')                 <> NVL(xoedi.dpt3_cd,   '@')
                        OR NVL(xwhd.dpt4_cd, '@')                 <> NVL(xoedi.dpt4_cd,   '@')
                        OR NVL(xwhd.dpt5_cd, '@')                 <> NVL(xoedi.dpt5_cd,   '@')
                        OR NVL(xwhd.dpt6_cd, '@')                 <> NVL(xoedi.dpt6_cd,   '@')
                        OR NVL(paaf_sup.assignment_number,   '@') <> NVL(xoedi.sup_assignment_number,   '@')
                        OR ppos.date_start                        <> xoedi.date_start
                        OR NVL(ppos.actual_termination_date, gt_cur_process_date) <> NVL(xoedi.actual_termination_date, gt_cur_process_date)
                       ) THEN
                    cv_y 
                  ELSE
                    cv_n
                END)
           END)                             AS other_change_flag            -- »Ì¼ÏXtO
        , xoedi.person_id                   AS xoedi_person_id              -- ÂlIDiÐõ·ªîñj
        , xoedi.last_name                   AS pre_last_name                -- OñJi©
        , xoedi.first_name                  AS pre_first_name               -- OñJi¼
        , xoedi.location_code               AS pre_location_code            -- Oñ_R[h
        , xoedi.license_code                AS pre_license_code             -- OñiR[h
        , xoedi.job_post                    AS pre_job_post                 -- OñEÊR[h
        , xoedi.job_duty                    AS pre_job_duty                 -- OñE±R[h
        , xoedi.job_type                    AS pre_job_type                 -- OñEíR[h
        , xoedi.dpt1_cd                     AS pre_dpt1_cd                  -- Oñ1KwÚåR[h
        , xoedi.dpt2_cd                     AS pre_dpt2_cd                  -- Oñ2KwÚåR[h
        , xoedi.dpt3_cd                     AS pre_dpt3_cd                  -- Oñ3KwÚåR[h
        , xoedi.dpt4_cd                     AS pre_dpt4_cd                  -- Oñ4KwÚåR[h
        , xoedi.dpt5_cd                     AS pre_dpt5_cd                  -- Oñ5KwÚåR[h
        , xoedi.dpt6_cd                     AS pre_dpt6_cd                  -- Oñ6KwÚåR[h
        , xoedi.sup_assignment_number       AS pre_sup_assignment_number    -- Oñã·ATCgÔ
        , xoedi.date_start                  AS pre_date_start               -- OñJnú
        , xoedi.actual_termination_date     AS pre_actual_termination_date  -- OñÞEú
      FROM
          xxcmm_oic_emp_diff_info  xoedi     -- OICÐõ·ªîñe[u
        , fnd_user                 fu        -- [U[}X^
        , per_all_people_f         papf      -- ]Æõ}X^
        , (SELECT
               xwhd_sub.cur_dpt_cd          AS cur_dpt_cd               -- ÅºwåR[h
             , xwhd_sub.dpt1_cd             AS dpt1_cd                  -- PKwÚåR[h
             , xwhd_sub.dpt2_cd             AS dpt2_cd                  -- QKwÚåR[h
             , xwhd_sub.dpt3_cd             AS dpt3_cd                  -- RKwÚåR[h
             , xwhd_sub.dpt4_cd             AS dpt4_cd                  -- SKwÚåR[h
             , xwhd_sub.dpt5_cd             AS dpt5_cd                  -- TKwÚåR[h
             , xwhd_sub.dpt6_cd             AS dpt6_cd                  -- UKwÚåR[h
             , ROW_NUMBER() OVER(
                 PARTITION BY xwhd_sub.cur_dpt_cd
                 ORDER BY xwhd_sub.cur_dpt_cd
               )                            AS row_num                  -- sÔiÅºwåR[hPÊj
           FROM
               xxcmm_wk_hiera_dept xwhd_sub  -- åKw[N
           WHERE
               xwhd_sub.process_kbn = cv_proc_type_dept
          )                        xwhd      -- åKw[N
        , per_all_assignments_f    paaf      -- ATCg}X^
        , (SELECT
               paaf_s.person_id             AS person_id                -- ÂlID
              ,paaf_s.assignment_number     AS assignment_number        -- ATCgÔ
           FROM
               per_all_assignments_f    paaf_s  -- ATCg}X^(ã·)
              ,per_periods_of_service   ppos_s  -- AÆîñ(ã·)
           WHERE
               paaf_s.period_of_service_id = ppos_s.period_of_service_id
           AND ppos_s.actual_termination_date IS NULL
          )                           paaf_sup  -- ATCg}X^(ã·)
        , per_periods_of_service      ppos      -- AÆîñ
      WHERE
          papf.attribute3 IN (cv_emp_kbn_internal, cv_emp_kbn_external , cv_emp_kbn_dummy)  -- ]Æõæªi1:àA2:OA4:_~[j
      AND papf.attribute4 IS NULL    -- düæR[h
      AND papf.attribute5 IS NULL    -- ^ÆÒ
      AND papf.employee_number NOT IN (cv_not_get_emp1, cv_not_get_emp2, cv_not_get_emp3, cv_not_get_emp4, 
                                       cv_not_get_emp5, cv_not_get_emp6, cv_not_get_emp7, cv_not_get_emp8)  -- ]ÆõÔ
      AND papf.person_id = fu.employee_id(+)
      AND papf.effective_start_date = 
              (SELECT
                   MAX(papf2.effective_start_date)
               FROM
                   per_all_people_f       papf2  -- ]Æõ}X^
               WHERE
                   papf2.person_id = papf.person_id
              )
      AND papf.attribute28          = xwhd.cur_dpt_cd(+)
      AND xwhd.row_num(+)           = 1
      AND papf.person_id            = paaf.person_id
      AND paaf.effective_start_date =
              (SELECT
                   MAX(paaf2.effective_start_date)
               FROM
                   per_all_assignments_f  paaf2  -- ATCg}X^
               WHERE
                   paaf2.person_id = paaf.person_id
              )
      AND paaf.period_of_service_id = ppos.period_of_service_id
      AND paaf.supervisor_id        = paaf_sup.person_id(+)
      AND papf.employee_number      = xoedi.employee_number(+)
-- Ver1.18 Mod Start
--      AND (   papf.last_update_date >= gt_pre_process_date
--           OR papf.attribute23      >= gv_str_pre_process_date
--           OR paaf.last_update_date >= gt_pre_process_date
--           OR paaf.ass_attribute19  >= gv_str_pre_process_date
--           OR ppos.last_update_date >= gt_pre_process_date
--          )
      AND (   
              (     papf.last_update_date >= gt_pre_process_date
                AND papf.last_update_date <  gt_cur_process_date
            )
           OR (
                    papf.attribute23 >= gv_str_pre_process_date
                AND papf.attribute23 <  gv_str_cur_process_date
              )
           OR (
                    paaf.last_update_date >= gt_pre_process_date
                AND paaf.last_update_date <  gt_cur_process_date
              )
           OR (
                    paaf.ass_attribute19 >= gv_str_pre_process_date
                AND paaf.ass_attribute19 <  gv_str_cur_process_date
              )
           OR (
                    ppos.last_update_date >= gt_pre_process_date
                AND ppos.last_update_date <  gt_cur_process_date
              )
          )
-- Ver1.18 Mod End
      ORDER BY
          papf.employee_number ASC
      FOR UPDATE OF xoedi.person_id NOWAIT
    ;
--
-- Ver1.17 Add Start
    --------------------------------------
    -- VüÐõîñÌoJ[\
    --------------------------------------
    CURSOR new_emp_cur (
             in_person_id IN NUMBER
    )
    IS
      SELECT
          fu.user_name                                      AS user_name                    -- [U[¼
        , papf.employee_number                              AS employee_number              -- ]ÆõÔ
        , TO_CHAR(fu.start_date, cv_date_fmt)               AS start_date                   -- Jnú
        , cv_y                                              AS generated_user_account_flag  -- ¶¬Ï[U[EAJEg
        , papf.person_id                                    AS person_id                    -- ÂlID
      FROM
          per_all_people_f     papf  -- ]Æõ}X^
        , fnd_user             fu    -- [U[}X^
      WHERE
          papf.attribute3 IN (cv_emp_kbn_internal, cv_emp_kbn_external , cv_emp_kbn_dummy)  -- ]Æõæªi1:àA2:OA4:_~[j
      AND papf.attribute4 IS NULL    -- düæR[h
      AND papf.attribute5 IS NULL    -- ^ÆÒ
      AND papf.employee_number NOT IN (cv_not_get_emp1, cv_not_get_emp2, cv_not_get_emp3, cv_not_get_emp4, 
                                       cv_not_get_emp5, cv_not_get_emp6, cv_not_get_emp7, cv_not_get_emp8)  -- ]ÆõÔ
      AND papf.effective_start_date = 
              (SELECT
                   MAX(papf2.effective_start_date)
               FROM
                   per_all_people_f  papf2 -- ]Æõ}X^
               WHERE
                   papf2.person_id = papf.person_id
              )
      AND papf.person_id     = fu.employee_id
-- Ver1.18 Mod Start
--      AND papf.creation_date >= gt_pre_process_date
--      AND fu.creation_date   >= gt_pre_process_date
      AND (
                papf.creation_date >= gt_pre_process_date
            AND papf.creation_date <  gt_cur_process_date
          )
      AND (
                fu.creation_date   >= gt_pre_process_date
            AND fu.creation_date   <  gt_cur_process_date
          )
-- Ver1.18 Mod End
      AND papf.person_id = in_person_id
      ORDER BY
          employee_number ASC
    ;
--
-- Ver1.7 Add End
    -- *** [JER[h ***
    l_emp_info_rec      emp_info_cur%ROWTYPE;    -- Ðõ·ªîñÌoJ[\R[h
-- Ver1.17 Add Start
    l_new_emp_rec       new_emp_cur%ROWTYPE;     -- VüÐõîñÌoJ[\R[h
-- Ver1.17 Add End
--
  BEGIN
--
--##################  ÅèXe[^Xú» START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  Åè END   ############################
--
    -- ==============================================================
    -- åKw[Niê\jÌo^(A-6-1)
    -- ==============================================================
    BEGIN
      --
      INSERT INTO xxcmm_wk_hiera_dept (
          cur_dpt_cd                              -- ÅºwåR[h
        , dpt1_cd                                 -- PKwÚåR[h
        , dpt2_cd                                 -- QKwÚåR[h
        , dpt3_cd                                 -- RKwÚåR[h
        , dpt4_cd                                 -- SKwÚåR[h
        , dpt5_cd                                 -- TKwÚåR[h
        , dpt6_cd                                 -- UKwÚåR[h
        , process_kbn                             -- æª
      )
      SELECT
          xhdv.cur_dpt_cd     AS cur_dpt_cd       -- ÅºwåR[h
        , xhdv.dpt1_cd        AS dpt1_cd          -- PKwÚåR[h
        , xhdv.dpt2_cd        AS dpt2_cd          -- QKwÚåR[h
        , xhdv.dpt3_cd        AS dpt3_cd          -- RKwÚåR[h
        , xhdv.dpt4_cd        AS dpt4_cd          -- SKwÚåR[h
        , xhdv.dpt5_cd        AS dpt5_cd          -- TKwÚåR[h
        , xhdv.dpt6_cd        AS dpt6_cd          -- UKwÚåR[h
        , cv_proc_type_dept   AS process_kbn      -- æª
      FROM
          xxcmm_hierarchy_dept_v  xhdv  -- åKwr[
      ;
    EXCEPTION
      WHEN OTHERS THEN
        -- o^É¸sµ½ê
        lv_errmsg := SUBSTRB(
                       xxccp_common_pkg.get_msg(
                         iv_application  => cv_appl_xxcmm             -- AvP[VZk¼FXXCMM
                       , iv_name         => cv_insert_err_msg         -- bZ[W¼F}üG[bZ[W
                       , iv_token_name1  => cv_tkn_table              -- g[N¼1FTABLE
                       , iv_token_value1 => cv_oic_wk_hiera_dept_msg  -- g[Nl1FåKw[N
                       , iv_token_name2  => cv_tkn_err_msg            -- g[N¼2FERR_MSG
                       , iv_token_value2 => SQLERRM                   -- g[Nl2FSQLERRM
                       )
                     , 1
                     , 5000
                     );
        lv_errbuf  := lv_errmsg;
        RAISE global_process_expt;
    END;
--
    -- ==============================================================
    -- Ðõ·ªîñÌo(A-6-2)
    -- ==============================================================
    -- J[\I[v
    OPEN emp_info_cur;
    <<output_emp_info_loop>>
    LOOP
      --
      FETCH emp_info_cur INTO l_emp_info_rec;
      EXIT WHEN emp_info_cur%NOTFOUND;
      --
      -- oJEgAbv
      gn_get_emp_info_cnt := gn_get_emp_info_cnt + 1;
      --
      IF ( l_emp_info_rec.roll_change_flag = cv_y ) THEN
        -- [ÏXtOªYÌê
        --
-- Ver1.17 Del Start
        -- ==============================================================
        -- Ðõ·ªîñÌt@CoÍ(A-6-3)
        -- ==============================================================
-- Ver1.17 Del End
        -- f[^sÌì¬
        lv_file_data := xxccp_oiccommon_pkg.to_csv_string( l_emp_info_rec.user_name       , cv_space );  --  1 : [U[¼
        lv_file_data := lv_file_data || cv_comma ||
                        xxccp_oiccommon_pkg.to_csv_string( l_emp_info_rec.employee_number , cv_space );  --  2 : ]ÆõÔ
        lv_file_data := lv_file_data || cv_comma ||
                        xxccp_oiccommon_pkg.to_csv_string( l_emp_info_rec.last_name       , cv_space );  --  3 : Ji©
        lv_file_data := lv_file_data || cv_comma ||
                        xxccp_oiccommon_pkg.to_csv_string( l_emp_info_rec.first_name      , cv_space );  --  4 : Ji¼
        lv_file_data := lv_file_data || cv_comma ||
                        xxccp_oiccommon_pkg.to_csv_string( l_emp_info_rec.location_code   , cv_space );  --  5 : _R[h
        lv_file_data := lv_file_data || cv_comma ||
                        xxccp_oiccommon_pkg.to_csv_string( l_emp_info_rec.license_code    , cv_space );  --  6 : iR[h
        lv_file_data := lv_file_data || cv_comma ||
                        xxccp_oiccommon_pkg.to_csv_string( l_emp_info_rec.job_post        , cv_space );  --  7 : EÊR[h
        lv_file_data := lv_file_data || cv_comma ||
                        xxccp_oiccommon_pkg.to_csv_string( l_emp_info_rec.job_duty        , cv_space );  --  8 : E±R[h
        lv_file_data := lv_file_data || cv_comma ||
                        xxccp_oiccommon_pkg.to_csv_string( l_emp_info_rec.job_type        , cv_space );  --  9 : EíR[h
        lv_file_data := lv_file_data || cv_comma ||
                        xxccp_oiccommon_pkg.to_csv_string( l_emp_info_rec.dpt1_cd         , cv_space );  -- 10 : PKwÚåR[h
        lv_file_data := lv_file_data || cv_comma ||
                        xxccp_oiccommon_pkg.to_csv_string( l_emp_info_rec.dpt2_cd         , cv_space );  -- 11 : QKwÚåR[h
        lv_file_data := lv_file_data || cv_comma ||
                        xxccp_oiccommon_pkg.to_csv_string( l_emp_info_rec.dpt3_cd         , cv_space );  -- 12 : RKwÚåR[h
        lv_file_data := lv_file_data || cv_comma ||
                        xxccp_oiccommon_pkg.to_csv_string( l_emp_info_rec.dpt4_cd         , cv_space );  -- 13 : SKwÚåR[h
        lv_file_data := lv_file_data || cv_comma ||
                        xxccp_oiccommon_pkg.to_csv_string( l_emp_info_rec.dpt5_cd         , cv_space );  -- 14 : TKwÚåR[h
        lv_file_data := lv_file_data || cv_comma ||
                        xxccp_oiccommon_pkg.to_csv_string( l_emp_info_rec.dpt6_cd         , cv_space );  -- 15 : UKwÚåR[h
        --
-- Ver1.17 Mod Start
--        BEGIN
--         -- f[^sÌt@CoÍ
--          UTL_FILE.PUT_LINE( gf_emp_inf_file_handle  -- PaaSpÌÐõ·ªîñt@C
--                           , lv_file_data
--                           );
--          -- oÍJEgAbv
--          gn_out_p_emp_info_cnt := gn_out_p_emp_info_cnt + 1;
    -- ==============================================================
    -- VüÐõîñÌo(A-6-3)
    -- ==============================================================
-- Ver1.20 Add Start
      lv_new_emp_flag := cv_n;
-- Ver1.20 Add End

      -- J[\I[v
      OPEN new_emp_cur (
             l_emp_info_rec.person_id
           );
      <<output_new_emp_loop>>
      LOOP
        --
        FETCH new_emp_cur INTO l_new_emp_rec;
        EXIT WHEN new_emp_cur%NOTFOUND;
        --
        -- emp_info_curÆnew_emp_curðär
--        IF ( l_emp_info_rec.person_id = l_new_emp_rec.person_id ) THEN
          lv_new_emp_flag := cv_y;
          -- êv·éêYtOð½Äé
--        END IF;
      END LOOP output_new_emp_loop;
--
      -- J[\N[Y
      CLOSE new_emp_cur;
        -- ==============================================================
        -- Ðõ·ªîñÌt@CoÍ(A-6-4)
        -- ==============================================================
        BEGIN
          IF ( lv_new_emp_flag = cv_y ) THEN
            -- f[^sÌt@CoÍ
            UTL_FILE.PUT_LINE( gf_new_emp_file_handle  -- PaaSpÌVüÐõîñt@C
                             , lv_file_data
                             );
            -- oÍJEgAbv
            gn_out_p_new_emp_cnt := gn_out_p_new_emp_cnt + 1;
          ELSE
            UTL_FILE.PUT_LINE( gf_emp_inf_file_handle  -- PaaSpÌÐõ·ªîñt@C
                             , lv_file_data
                             );
            -- oÍJEgAbv
            gn_out_p_emp_info_cnt := gn_out_p_emp_info_cnt + 1;
          END IF;
          --
-- Ver1.17 Mod End
        EXCEPTION
          WHEN OTHERS THEN
            RAISE global_fileout_expt;
        END;
      --
      ELSE
        -- [ÏXtOªNÌê
        -- XLbvðJEgAbv
        gn_warn_cnt := gn_warn_cnt + 1;
      END IF;
      --
      --
-- Ver1.17 Mod Start
--      -- ==============================================================
--      -- OICÐõ·ªîñe[uÌo^EXV(A-6-4)
--      -- ==============================================================
      -- ==============================================================
      -- OICÐõ·ªîñe[uÌo^EXV(A-6-5)
      -- ==============================================================
-- Ver1.17 Mod End
      IF (    l_emp_info_rec.roll_change_flag  = cv_y
           OR l_emp_info_rec.other_change_flag = cv_y ) THEN
        -- [ÏXtOªYAÜ½ÍA»Ì¼ÏXtOªYÌê
        --
        IF ( l_emp_info_rec.xoedi_person_id IS NULL ) THEN
          -- ÂlIDiÐõ·ªîñjªNULLÌê
          --
          BEGIN
            -- OICÐõ·ªîñe[uÌo^
            INSERT INTO xxcmm_oic_emp_diff_info (
                person_id                                     -- ÂlID
              , employee_number                               -- ]ÆõÔ
              , user_name                                     -- [U[¼
              , last_name                                     -- Ji©
              , first_name                                    -- Ji¼
              , location_code                                 -- _R[h
              , license_code                                  -- iR[h
              , job_post                                      -- EÊR[h
              , job_duty                                      -- E±R[h
              , job_type                                      -- EíR[h
              , dpt1_cd                                       -- PKwÚåR[h
              , dpt2_cd                                       -- QKwÚåR[h
              , dpt3_cd                                       -- RKwÚåR[h
              , dpt4_cd                                       -- SKwÚåR[h
              , dpt5_cd                                       -- TKwÚåR[h
              , dpt6_cd                                       -- UKwÚåR[h
              , sup_assignment_number                         -- ã·ATCgÔ
              , date_start                                    -- Jnú
              , actual_termination_date                       -- ÞEú
              , created_by                                    -- ì¬Ò
              , creation_date                                 -- ì¬ú
              , last_updated_by                               -- ÅIXVÒ
              , last_update_date                              -- ÅIXVú
              , last_update_login                             -- ÅIXVOC
              , request_id                                    -- vID
              , program_application_id                        -- RJgEvOEAvP[VID
              , program_id                                    -- RJgEvOID
              , program_update_date                           -- vOXVú
            ) VALUES (
                l_emp_info_rec.person_id                      -- ÂlID
              , l_emp_info_rec.employee_number                -- ]ÆõÔ
              , l_emp_info_rec.user_name                      -- [U[¼
              , l_emp_info_rec.last_name                      -- Ji©
              , l_emp_info_rec.first_name                     -- Ji¼
              , l_emp_info_rec.location_code                  -- _R[h
              , l_emp_info_rec.license_code                   -- iR[h
              , l_emp_info_rec.job_post                       -- EÊR[h
              , l_emp_info_rec.job_duty                       -- E±R[h
              , l_emp_info_rec.job_type                       -- EíR[h
              , l_emp_info_rec.dpt1_cd                        -- PKwÚåR[h
              , l_emp_info_rec.dpt2_cd                        -- QKwÚåR[h
              , l_emp_info_rec.dpt3_cd                        -- RKwÚåR[h
              , l_emp_info_rec.dpt4_cd                        -- SKwÚåR[h
              , l_emp_info_rec.dpt5_cd                        -- TKwÚåR[h
              , l_emp_info_rec.dpt6_cd                        -- UKwÚåR[h
              , l_emp_info_rec.sup_assignment_number          -- ã·ATCgÔ
              , l_emp_info_rec.date_start                     -- Jnú
              , l_emp_info_rec.actual_termination_date        -- ÞEú
              , cn_created_by                                 -- ì¬Ò
              , cd_creation_date                              -- ì¬ú
              , cn_last_updated_by                            -- ÅIXVÒ
              , cd_last_update_date                           -- ÅIXVú
              , cn_last_update_login                          -- ÅIXVOC
              , cn_request_id                                 -- vID
              , cn_program_application_id                     -- RJgEvOEAvP[VID
              , cn_program_id                                 -- RJgEvOID
              , cd_program_update_date                        -- vOXVú
            );
          EXCEPTION
            WHEN OTHERS THEN
              -- o^É¸sµ½ê
              lv_errmsg := SUBSTRB(
                             xxccp_common_pkg.get_msg(
                               iv_application  => cv_appl_xxcmm             -- AvP[VZk¼FXXCMM
                             , iv_name         => cv_insert_err_msg         -- bZ[W¼F}üG[bZ[W
                             , iv_token_name1  => cv_tkn_table              -- g[N¼1FTABLE
                             , iv_token_value1 => cv_oic_emp_info_tbl_msg   -- g[Nl1FOICÐõ·ªîñe[u
                             , iv_token_name2  => cv_tkn_err_msg            -- g[N¼2FERR_MSG
                             , iv_token_value2 => SQLERRM                   -- g[Nl2FSQLERRM
                             )
                           , 1
                           , 5000
                           );
              lv_errbuf  := lv_errmsg;
              RAISE global_process_expt;
          END;
        --
        ELSE
          -- ÂlIDiÐõ·ªîñjªNOT NULLÌê
          --
          BEGIN
            -- OICÐõ·ªîñe[uÌXV
            UPDATE
                xxcmm_oic_emp_diff_info  xoedi  -- OICÐõ·ªîñe[u
            SET
                xoedi.last_name                = l_emp_info_rec.last_name                   -- Ji©
              , xoedi.first_name               = l_emp_info_rec.first_name                  -- Ji¼
              , xoedi.location_code            = l_emp_info_rec.location_code               -- _R[h
              , xoedi.license_code             = l_emp_info_rec.license_code                -- iR[h
              , xoedi.job_post                 = l_emp_info_rec.job_post                    -- EÊR[h
              , xoedi.job_duty                 = l_emp_info_rec.job_duty                    -- E±R[h
              , xoedi.job_type                 = l_emp_info_rec.job_type                    -- EíR[h
              , xoedi.dpt1_cd                  = l_emp_info_rec.dpt1_cd                     -- PKwÚåR[h
              , xoedi.dpt2_cd                  = l_emp_info_rec.dpt2_cd                     -- QKwÚåR[h
              , xoedi.dpt3_cd                  = l_emp_info_rec.dpt3_cd                     -- RKwÚåR[h
              , xoedi.dpt4_cd                  = l_emp_info_rec.dpt4_cd                     -- SKwÚåR[h
              , xoedi.dpt5_cd                  = l_emp_info_rec.dpt5_cd                     -- TKwÚåR[h
              , xoedi.dpt6_cd                  = l_emp_info_rec.dpt6_cd                     -- UKwÚåR[h
              , xoedi.sup_assignment_number    = l_emp_info_rec.sup_assignment_number       -- ã·ATCgÔ
              , xoedi.date_start               = l_emp_info_rec.date_start                  -- Jnú
              , xoedi.actual_termination_date  = l_emp_info_rec.actual_termination_date     -- ÞEú
              , xoedi.last_update_date         = cd_last_update_date                        -- ÅIXVú
              , xoedi.last_updated_by          = cn_last_updated_by                         -- ÅIXVÒ
              , xoedi.last_update_login        = cn_last_update_login                       -- ÅIXVOC
              , xoedi.request_id               = cn_request_id                              -- vID
              , xoedi.program_application_id   = cn_program_application_id                  -- vOAvP[VID
              , xoedi.program_id               = cn_program_id                              -- vOID
              , xoedi.program_update_date      = cd_program_update_date                     -- vOXVú
            WHERE
                xoedi.person_id                = l_emp_info_rec.xoedi_person_id             -- ÂlIDiÐõ·ªîñj
            ;
          EXCEPTION
            WHEN OTHERS THEN
              -- XVÉ¸sµ½ê
              lv_errmsg := SUBSTRB(
                             xxccp_common_pkg.get_msg(
                               iv_application  => cv_appl_xxcmm             -- AvP[VZk¼FXXCMM
                             , iv_name         => cv_update_err_msg         -- bZ[W¼FXVG[bZ[W
                             , iv_token_name1  => cv_tkn_table              -- g[N¼1FTABLE
                             , iv_token_value1 => cv_oic_emp_info_tbl_msg   -- g[Nl1FOICÐõ·ªîñe[u
                             , iv_token_name2  => cv_tkn_err_msg            -- g[N¼2FERR_MSG
                             , iv_token_value2 => SQLERRM                   -- g[Nl2FSQLERRM
                             )
                           , 1
                           , 5000
                           );
              lv_errbuf  := lv_errmsg;
              RAISE global_process_expt;
          END;
        END IF;
      END IF;
      --
      --
-- Ver1.17 Mod Start
--      -- ==============================================================
--      -- OICÐõ·ªîñobNAbve[uÌo^(A-6-5)
--      -- ==============================================================
      -- ==============================================================
      -- OICÐõ·ªîñobNAbve[uÌo^(A-6-6)
      -- ==============================================================

-- Ver1.17 Mod End
      IF (    l_emp_info_rec.roll_change_flag  = cv_y
           OR l_emp_info_rec.other_change_flag = cv_y ) THEN
        -- [ÏXtOªYAÜ½ÍA»Ì¼ÏXtOªYÌê
        --
        BEGIN
          -- OICÐõ·ªîñobNAbve[uÌo^
          INSERT INTO xxcmm_oic_emp_diff_info_bk (
              person_id                                     -- ÂlID
            , employee_number                               -- ]ÆõÔ
            , user_name                                     -- [U[¼
            , pre_last_name                                 -- OñJi©
            , pre_first_name                                -- OñJi¼
            , pre_location_code                             -- Oñ_R[h
            , pre_license_code                              -- OñiR[h
            , pre_job_post                                  -- OñEÊR[h
            , pre_job_duty                                  -- OñE±R[h
            , pre_job_type                                  -- OñEíR[h
            , pre_dpt1_cd                                   -- OñPKwÚåR[h
            , pre_dpt2_cd                                   -- OñQKwÚåR[h
            , pre_dpt3_cd                                   -- OñRKwÚåR[h
            , pre_dpt4_cd                                   -- OñSKwÚåR[h
            , pre_dpt5_cd                                   -- OñTKwÚåR[h
            , pre_dpt6_cd                                   -- OñUKwÚåR[h
            , pre_sup_assignment_number                     -- Oñã·ATCgÔ
            , pre_date_start                                -- OñJnú
            , pre_actual_termination_date                   -- OñÞEú
            , last_name                                     -- Ji©
            , first_name                                    -- Ji¼
            , location_code                                 -- _R[h
            , license_code                                  -- iR[h
            , job_post                                      -- EÊR[h
            , job_duty                                      -- E±R[h
            , job_type                                      -- EíR[h
            , dpt1_cd                                       -- PKwÚåR[h
            , dpt2_cd                                       -- QKwÚåR[h
            , dpt3_cd                                       -- RKwÚåR[h
            , dpt4_cd                                       -- SKwÚåR[h
            , dpt5_cd                                       -- TKwÚåR[h
            , dpt6_cd                                       -- UKwÚåR[h
            , sup_assignment_number                         -- ã·ATCgÔ
            , date_start                                    -- Jnú
            , actual_termination_date                       -- ÞEú
            , created_by                                    -- ì¬Ò
            , creation_date                                 -- ì¬ú
            , last_updated_by                               -- ÅIXVÒ
            , last_update_date                              -- ÅIXVú
            , last_update_login                             -- ÅIXVOC
            , request_id                                    -- vID
            , program_application_id                        -- RJgEvOEAvP[VID
            , program_id                                    -- RJgEvOID
            , program_update_date                           -- vOXVú
          ) VALUES (
              l_emp_info_rec.person_id                      -- ÂlID
            , l_emp_info_rec.employee_number                -- ]ÆõÔ
            , l_emp_info_rec.user_name                      -- [U[¼
            , l_emp_info_rec.pre_last_name                  -- OñJi©
            , l_emp_info_rec.pre_first_name                 -- OñJi¼
            , l_emp_info_rec.pre_location_code              -- Oñ_R[h
            , l_emp_info_rec.pre_license_code               -- OñiR[h
            , l_emp_info_rec.pre_job_post                   -- OñEÊR[h
            , l_emp_info_rec.pre_job_duty                   -- OñE±R[h
            , l_emp_info_rec.pre_job_type                   -- OñEíR[h
            , l_emp_info_rec.pre_dpt1_cd                    -- OñPKwÚåR[h
            , l_emp_info_rec.pre_dpt2_cd                    -- OñQKwÚåR[h
            , l_emp_info_rec.pre_dpt3_cd                    -- OñRKwÚåR[h
            , l_emp_info_rec.pre_dpt4_cd                    -- OñSKwÚåR[h
            , l_emp_info_rec.pre_dpt5_cd                    -- OñTKwÚåR[h
            , l_emp_info_rec.pre_dpt6_cd                    -- OñUKwÚåR[h
            , l_emp_info_rec.pre_sup_assignment_number      -- Oñã·ATCgÔ
            , l_emp_info_rec.pre_date_start                 -- OñJnú
            , l_emp_info_rec.pre_actual_termination_date    -- OñÞEú
            , l_emp_info_rec.last_name                      -- Ji©
            , l_emp_info_rec.first_name                     -- Ji¼
            , l_emp_info_rec.location_code                  -- _R[h
            , l_emp_info_rec.license_code                   -- iR[h
            , l_emp_info_rec.job_post                       -- EÊR[h
            , l_emp_info_rec.job_duty                       -- E±R[h
            , l_emp_info_rec.job_type                       -- EíR[h
            , l_emp_info_rec.dpt1_cd                        -- PKwÚåR[h
            , l_emp_info_rec.dpt2_cd                        -- QKwÚåR[h
            , l_emp_info_rec.dpt3_cd                        -- RKwÚåR[h
            , l_emp_info_rec.dpt4_cd                        -- SKwÚåR[h
            , l_emp_info_rec.dpt5_cd                        -- TKwÚåR[h
            , l_emp_info_rec.dpt6_cd                        -- UKwÚåR[h
            , l_emp_info_rec.sup_assignment_number          -- ã·ATCgÔ
            , l_emp_info_rec.date_start                     -- Jnú
            , l_emp_info_rec.actual_termination_date        -- ÞEú
            , cn_created_by                                 -- ì¬Ò
            , cd_creation_date                              -- ì¬ú
            , cn_last_updated_by                            -- ÅIXVÒ
            , cd_last_update_date                           -- ÅIXVú
            , cn_last_update_login                          -- ÅIXVOC
            , cn_request_id                                 -- vID
            , cn_program_application_id                     -- RJgEvOEAvP[VID
            , cn_program_id                                 -- RJgEvOID
            , cd_program_update_date                        -- vOXVú
          );
        EXCEPTION
          WHEN OTHERS THEN
            -- o^É¸sµ½ê
            lv_errmsg := SUBSTRB(
                           xxccp_common_pkg.get_msg(
                             iv_application  => cv_appl_xxcmm             -- AvP[VZk¼FXXCMM
                           , iv_name         => cv_insert_err_msg         -- bZ[W¼F}üG[bZ[W
                           , iv_token_name1  => cv_tkn_table              -- g[N¼1FTABLE
                           , iv_token_value1 => cv_oic_emp_inf_bk_tbl_msg -- g[Nl1FOICÐõ·ªîñobNAbve[u
                           , iv_token_name2  => cv_tkn_err_msg            -- g[N¼2FERR_MSG
                           , iv_token_value2 => SQLERRM                   -- g[Nl2FSQLERRM
                           )
                         , 1
                         , 5000
                         );
            lv_errbuf  := lv_errmsg;
            RAISE global_process_expt;
        END;
      END IF;
    --
    END LOOP output_emp_info_loop;
--
    -- J[\N[Y
    CLOSE emp_info_cur;
--
  EXCEPTION
    -- *** bNG[áOnh ***
    WHEN global_lock_expt THEN
      -- J[\N[Y
      IF ( emp_info_cur%ISOPEN ) THEN
        CLOSE emp_info_cur;
      END IF;
-- Ver1.17 Add Start
      -- J[\N[Y
      IF ( new_emp_cur%ISOPEN ) THEN
        CLOSE new_emp_cur;
      END IF;
-- Ver1.17 Add End
      --
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_xxcmm             -- AvP[VZk¼FXXCMM
                   , iv_name         => cv_lock_err_msg           -- bZ[W¼FbNG[bZ[W
                   , iv_token_name1  => cv_tkn_ng_table           -- g[N¼1FNG_TABLE
                   , iv_token_value1 => cv_oic_emp_info_tbl_msg   -- g[Nl1FOICÐõ·ªîñ
                   );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000);
      ov_retcode := cv_status_error;
--
    -- *** t@CoÍáOnh ***
    WHEN global_fileout_expt THEN
      -- J[\N[Y
      IF ( emp_info_cur%ISOPEN ) THEN
        CLOSE emp_info_cur;
      END IF;
-- Ver1.17 Add Start
      -- J[\N[Y
      IF ( new_emp_cur%ISOPEN ) THEN
        CLOSE new_emp_cur;
      END IF;
-- Ver1.17 Add End
      --
      lv_errmsg := SUBSTRB(
                     xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_xxcmm             -- AvP[VZk¼FXXCMM
                     , iv_name         => cv_file_write_err_msg     -- bZ[W¼Ft@C«ÝG[bZ[W
                     , iv_token_name1  => cv_tkn_sqlerrm            -- g[N¼1FSQLERRM
                     , iv_token_value1 => SQLERRM                   -- g[Nl1FSQLERRM
                     )
                   , 1
                   , 5000
                   );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  ÅèáO START   ####################################
--
    -- *** ¤ÊáOnh ***
    WHEN global_process_expt THEN
      -- J[\N[Y
      IF ( emp_info_cur%ISOPEN ) THEN
        CLOSE emp_info_cur;
      END IF;
-- Ver1.17 Add Start
      -- J[\N[Y
      IF ( new_emp_cur%ISOPEN ) THEN
        CLOSE new_emp_cur;
      END IF;
-- Ver1.17 Add End
      --
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ¤ÊÖáOnh ***
    WHEN global_api_expt THEN
      -- J[\N[Y
      IF ( emp_info_cur%ISOPEN ) THEN
        CLOSE emp_info_cur;
      END IF;
-- Ver1.17 Add Start
      -- J[\N[Y
      IF ( new_emp_cur%ISOPEN ) THEN
        CLOSE new_emp_cur;
      END IF;
-- Ver1.17 Add End
      --
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ¤ÊÖOTHERSáOnh ***
    WHEN global_api_others_expt THEN
      -- J[\N[Y
      IF ( emp_info_cur%ISOPEN ) THEN
        CLOSE emp_info_cur;
      END IF;
-- Ver1.17 Add Start
      -- J[\N[Y
      IF ( new_emp_cur%ISOPEN ) THEN
        CLOSE new_emp_cur;
      END IF;
-- Ver1.17 Add End
      --
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERSáOnh ***
    WHEN OTHERS THEN
      -- J[\N[Y
      IF ( emp_info_cur%ISOPEN ) THEN
        CLOSE emp_info_cur;
      END IF;
-- Ver1.17 Add Start
      -- J[\N[Y
      IF ( new_emp_cur%ISOPEN ) THEN
        CLOSE new_emp_cur;
      END IF;
-- Ver1.17 Add End
      --
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  Åè END   ##########################################
--
  END output_emp_info;
--
--
  /**********************************************************************************
   * Procedure Name   : update_mng_tbl
   * Description      : Çe[uo^EXV(A-7)
   ***********************************************************************************/
  PROCEDURE update_mng_tbl(
    ov_errbuf     OUT VARCHAR2,     --   G[EbZ[W           --# Åè #
    ov_retcode    OUT VARCHAR2,     --   ^[ER[h             --# Åè #
    ov_errmsg     OUT VARCHAR2)     --   [U[EG[EbZ[W --# Åè #
  IS
    -- ===============================
    -- Åè[Jè
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'update_mng_tbl';       -- vO¼
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
  BEGIN
--
--##################  ÅèXe[^Xú» START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  Åè END   ############################
--
    IF ( gv_first_proc_flag = cv_y ) THEN
      -- ñtOªYÌê
      --
      BEGIN
        -- OICAgÇe[uÌo^
        INSERT INTO xxccp_oic_if_process_mng (
            program_name                -- vO¼
          , pre_process_date            -- Oñú
          , created_by                  -- ì¬Ò
          , creation_date               -- ì¬ú
          , last_updated_by             -- ÅIXVÒ
          , last_update_date            -- ÅIXVú
          , last_update_login           -- ÅIXVOC
          , request_id                  -- vID
          , program_application_id      -- RJgEvOEAvP[VID
          , program_id                  -- RJgEvOID
          , program_update_date         -- vOXVú
        ) VALUES (
            gt_conc_program_name        -- vO¼
          , gt_cur_process_date         -- Oñú
          , cn_created_by               -- ì¬Ò
          , cd_creation_date            -- ì¬ú
          , cn_last_updated_by          -- ÅIXVÒ
          , cd_last_update_date         -- ÅIXVú
          , cn_last_update_login        -- ÅIXVOC
          , cn_request_id               -- vID
          , cn_program_application_id   -- RJgEvOEAvP[VID
          , cn_program_id               -- RJgEvOID
          , cd_program_update_date      -- vOXVú
        );
      EXCEPTION
        WHEN OTHERS THEN
          -- o^É¸sµ½ê
          lv_errmsg := SUBSTRB(
                         xxccp_common_pkg.get_msg(
                           iv_application  => cv_appl_xxcmm             -- AvP[VZk¼FXXCMM
                         , iv_name         => cv_insert_err_msg         -- bZ[W¼F}üG[bZ[W
                         , iv_token_name1  => cv_tkn_table              -- g[N¼1FTABLE
                         , iv_token_value1 => cv_oic_proc_mng_tbl_msg   -- g[Nl1FOICAgÇe[u
                         , iv_token_name2  => cv_tkn_err_msg            -- g[N¼2FERR_MSG
                         , iv_token_value2 => SQLERRM                   -- g[Nl2FSQLERRM
                         )
                       , 1
                       , 5000
                       );
          lv_errbuf  := lv_errmsg;
          RAISE global_process_expt;
      END;
    --
    ELSE
      --
      -- ñtOªNÌê
      BEGIN
        -- OICAgÇe[uÌXV
        UPDATE
            xxccp_oic_if_process_mng  xoipm  -- OICAgÇe[u
        SET
            xoipm.pre_process_date       = gt_cur_process_date          -- Oñú
          , xoipm.last_update_date       = cd_last_update_date          -- ÅIXVú
          , xoipm.last_updated_by        = cn_last_updated_by           -- ÅIXVÒ
          , xoipm.last_update_login      = cn_last_update_login         -- ÅIXVOC
          , xoipm.request_id             = cn_request_id                -- vID
          , xoipm.program_application_id = cn_program_application_id    -- vOAvP[VID
          , xoipm.program_id             = cn_program_id                -- vOID
          , xoipm.program_update_date    = cd_program_update_date       -- vOXVú
        WHERE
            xoipm.program_name           = gt_conc_program_name         -- vO¼
        ;
      EXCEPTION
        WHEN OTHERS THEN
          -- XVÉ¸sµ½ê
          lv_errmsg := SUBSTRB(
                         xxccp_common_pkg.get_msg(
                           iv_application  => cv_appl_xxcmm             -- AvP[VZk¼FXXCMM
                         , iv_name         => cv_update_err_msg         -- bZ[W¼FXVG[bZ[W
                         , iv_token_name1  => cv_tkn_table              -- g[N¼1FTABLE
                         , iv_token_value1 => cv_oic_proc_mng_tbl_msg   -- g[Nl1FOICAgÇe[u
                         , iv_token_name2  => cv_tkn_err_msg            -- g[N¼2FERR_MSG
                         , iv_token_value2 => SQLERRM                   -- g[Nl2FSQLERRM
                         )
                       , 1
                       , 5000
                       );
          lv_errbuf  := lv_errmsg;
          RAISE global_process_expt;
      END;
    END IF;
--
  EXCEPTION
--
--#################################  ÅèáO START   ####################################
--
    -- *** ¤ÊáOnh ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
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
  END update_mng_tbl;
--
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : CvV[W
   **********************************************************************************/
  PROCEDURE submain(
    iv_proc_date_for_recovery  IN   VARCHAR2,       -- 1.Æ±útiJopj
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
    -- ÂÊÌú»
    -- o
    gn_get_wk_cnt             := 0;     -- AÆÒo
    gn_get_per_name_cnt       := 0;     -- Âl¼o
    gn_get_per_legi_cnt       := 0;     -- ÂlÊdlf[^o
    gn_get_per_email_cnt      := 0;     -- ÂlE[o
    gn_get_wk_rel_cnt         := 0;     -- ÙpÖWiÞEÒjo
    gn_get_new_user_cnt       := 0;     -- [U[îñiVKjo
    gn_get_new_user_paas_cnt  := 0;     -- [U[îñiVKjPaaSpo
    gn_get_wk_terms_cnt       := 0;     -- Ùpðo
    gn_get_ass_cnt            := 0;     -- ATCgîño
    gn_get_user_cnt           := 0;     -- [U[îño
-- Ver1.2(E055) Add Start
    gn_get_user2_cnt          := 0;     -- [U[îñiíjo
-- Ver1.2(E055) Add End
    gn_get_ass_sup_cnt        := 0;     -- ATCgîñiã·jo
    gn_get_wk_rel2_cnt        := 0;     -- ÙpÖWiVKÌpÞEÒjo
    gn_get_bank_acc_cnt       := 0;     -- ]ÆõoïûÀîño
    gn_get_emp_info_cnt       := 0;     -- Ðõ·ªîño
    -- oÍ
    gn_out_wk_cnt             := 0;     -- ]ÆõîñAgf[^t@CoÍ
    gn_out_p_new_user_cnt     := 0;     -- PaaSpÌVK[U[îñt@CoÍ
    gn_out_user_cnt           := 0;     -- [U[îñAgf[^t@CoÍ
-- Ver1.2(E055) Add Start
    gn_out_user2_cnt          := 0;     -- [U[îñiíjAgf[^t@CoÍ
-- Ver1.2(E055) Add End
    gn_out_wk2_cnt            := 0;     -- ]Æõîñiã·EVKÌpÞEÒjAgf[^t@CoÍ
    gn_out_p_bank_acct_cnt    := 0;     -- PaaSpÌ]ÆõoïûÀîñt@CoÍ
    gn_out_p_emp_info_cnt     := 0;     -- PaaSpÌÐõ·ªîñt@CoÍ
-- Ver1.17 Add Start
    gn_out_p_new_emp_cnt      := 0;     -- PaaSpÌVüÐõîñt@CoÍ
-- Ver1.17 Add End
--
    --
    --===============================================
    -- ú(A-1)
    --===============================================
    init(
      iv_proc_date_for_recovery => iv_proc_date_for_recovery  -- Æ±útiJopjID
    , ov_errbuf                 => lv_errbuf                  -- G[EbZ[W
    , ov_retcode                => lv_retcode                 -- ^[ER[h
    , ov_errmsg                 => lv_errmsg                  -- [U[EG[EbZ[W
    );
    --
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    --================================================================
    -- ]ÆõîñÌoEt@CoÍ(A-2)
    --================================================================
    output_worker(
      ov_errbuf          => lv_errbuf           -- G[EbZ[W
    , ov_retcode         => lv_retcode          -- ^[ER[h
    , ov_errmsg          => lv_errmsg           -- [U[EG[EbZ[W
    );
    --
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    --================================================================
    -- [U[îñÌoEt@CoÍ(A-3)
    --================================================================
    output_user(
      ov_errbuf          => lv_errbuf           -- G[EbZ[W
    , ov_retcode         => lv_retcode          -- ^[ER[h
    , ov_errmsg          => lv_errmsg           -- [U[EG[EbZ[W
    );
    --
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    --================================================================
    -- ]Æõîñiã·EVKÌpÞEÒjÌoEt@CoÍ(A-4)
    --================================================================
    output_worker2(
      ov_errbuf          => lv_errbuf           -- G[EbZ[W
    , ov_retcode         => lv_retcode          -- ^[ER[h
    , ov_errmsg          => lv_errmsg           -- [U[EG[EbZ[W
    );
    --
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    --================================================================
    -- ]ÆõoïûÀîñÌoEt@CoÍ(A-5)
    --================================================================
    output_emp_bank_acct(
      ov_errbuf          => lv_errbuf           -- G[EbZ[W
    , ov_retcode         => lv_retcode          -- ^[ER[h
    , ov_errmsg          => lv_errmsg           -- [U[EG[EbZ[W
    );
    --
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    --================================================================
    -- Ðõ·ªîñÌoEt@CoÍiPaaSpj(A-6)
    --================================================================
    output_emp_info(
      ov_errbuf          => lv_errbuf           -- G[EbZ[W
    , ov_retcode         => lv_retcode          -- ^[ER[h
    , ov_errmsg          => lv_errmsg           -- [U[EG[EbZ[W
    );
    --
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    --===============================================
    -- Çe[uo^EXV(A-7)
    --===============================================
    update_mng_tbl(
      ov_errbuf          => lv_errbuf           -- G[EbZ[W
    , ov_retcode         => lv_retcode          -- ^[ER[h
    , ov_errmsg          => lv_errmsg           -- [U[EG[EbZ[W
    );
    --
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
  EXCEPTION
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
    errbuf                     OUT VARCHAR2,      --   G[EbZ[W  --# Åè #
    retcode                    OUT VARCHAR2,      --   ^[ER[h    --# Åè #
    iv_proc_date_for_recovery  IN  VARCHAR2       --   Æ±útiJopj
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
--
    lv_msg             VARCHAR2(3000);  -- bZ[W
    -- opR[h
    TYPE l_get_cnt_rtype IS RECORD
    (
      target           VARCHAR2(100)    -- oÎÛ
    , cnt              VARCHAR2(10)     -- ibZ[Wpj
    );
    -- ope[u
    TYPE l_get_cnt_ttype IS TABLE OF l_get_cnt_rtype INDEX BY BINARY_INTEGER;
    l_get_cnt_tab    l_get_cnt_ttype;
--
    -- oÍpR[h
    TYPE l_out_cnt_rtype IS RECORD
    (
      target           VARCHAR2(100)    -- oÍÎÛ
    , cnt              VARCHAR2(10)     -- ibZ[Wpj
    );
    -- oÍpe[u
    TYPE l_out_cnt_ttype IS TABLE OF l_out_cnt_rtype INDEX BY BINARY_INTEGER;
    l_out_cnt_tab    l_out_cnt_ttype;
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
       iv_proc_date_for_recovery
      ,lv_errbuf   -- G[EbZ[W           --# Åè #
      ,lv_retcode  -- ^[ER[h             --# Åè #
      ,lv_errmsg   -- [U[EG[EbZ[W --# Åè #
    );
    --
    -- G[Ìê
    IF (lv_retcode = cv_status_error) THEN
      --
      -- eoÍÌú»i0j
      gn_out_wk_cnt           := 0;     -- ]ÆõîñAgf[^t@CoÍ
      gn_out_p_new_user_cnt   := 0;     -- PaaSpÌVK[U[îñt@CoÍ
      gn_out_user_cnt         := 0;     -- [U[îñAgf[^t@CoÍ
-- Ver1.2(E055) Add Start
      gn_out_user2_cnt        := 0;     -- [U[îñiíjAgf[^t@CoÍ
-- Ver1.2(E055) Add End
      gn_out_wk2_cnt          := 0;     -- ]Æõîñiã·EVKÌpÞEÒjAgf[^t@CoÍ
      gn_out_p_bank_acct_cnt  := 0;     -- PaaSpÌ]ÆõoïûÀîñt@CoÍ
      gn_out_p_emp_info_cnt   := 0;     -- PaaSpÌÐõ·ªîñt@CoÍ
-- Ver1.17 Add Start
      gn_out_p_new_emp_cnt    := 0;     -- PaaSpÌVüÐõîñt@CoÍ
-- Ver1.17 Add End
      --
      -- G[ÌÝè
      gn_error_cnt            := 1;
      --
      -- XLbvÌú»i0j
      gn_warn_cnt             := 0;
      --
      -- G[bZ[WÌoÍ
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg --[U[EG[bZ[W
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --G[bZ[W
      );
    END IF;
    -- ós}ü
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
--
    --===============================================
    -- I¹(A-8)
    --===============================================
--
    -------------------------------------------------
    -- t@CN[Y
    -------------------------------------------------
    -- ]ÆõîñAgf[^t@C
    IF ( UTL_FILE.IS_OPEN ( gf_wrk_file_handle )) THEN
      UTL_FILE.FCLOSE( gf_wrk_file_handle );
    END IF;
    -- ]Æõîñiã·EVKÌpÞEÒjAgf[^t@C
    IF ( UTL_FILE.IS_OPEN ( gf_wrk2_file_handle )) THEN
      UTL_FILE.FCLOSE( gf_wrk2_file_handle );
    END IF;
    -- [U[îñAgf[^t@C
    IF ( UTL_FILE.IS_OPEN ( gf_usr_file_handle )) THEN
      UTL_FILE.FCLOSE( gf_usr_file_handle );
    END IF;
-- Ver1.2(E055) Add Start
    -- [U[îñiíjAgf[^t@C
    IF ( UTL_FILE.IS_OPEN ( gf_usr2_file_handle )) THEN
      UTL_FILE.FCLOSE( gf_usr2_file_handle );
    END IF;
-- Ver1.2(E055) Add End
    -- PaaSpÌVK[U[îñt@C
    IF ( UTL_FILE.IS_OPEN ( gf_new_usr_file_handle )) THEN
      UTL_FILE.FCLOSE( gf_new_usr_file_handle );
    END IF;
    -- PaaSpÌ]ÆõoïûÀîñt@C
    IF ( UTL_FILE.IS_OPEN ( gf_emp_bnk_file_handle )) THEN
      UTL_FILE.FCLOSE( gf_emp_bnk_file_handle );
    END IF;
    -- PaaSpÌÐõ·ªîñt@C
    IF ( UTL_FILE.IS_OPEN ( gf_emp_inf_file_handle )) THEN
      UTL_FILE.FCLOSE( gf_emp_inf_file_handle );
    END IF;
-- Ver1.17 Add Start
    -- PaaSpÌVüÐõîñt@C
    IF ( UTL_FILE.IS_OPEN ( gf_new_emp_file_handle )) THEN
      UTL_FILE.FCLOSE( gf_new_emp_file_handle );
    END IF;
-- Ver1.17 Add End
--    
    -------------------------------------------------
    -- oÌoÍ
    -------------------------------------------------
    -- AÆÒo
    l_get_cnt_tab(1).target  := cv_worker_msg;
    l_get_cnt_tab(1).cnt     := TO_CHAR(gn_get_wk_cnt);
    -- Âl¼o
    l_get_cnt_tab(2).target  := cv_per_name_msg;
    l_get_cnt_tab(2).cnt     := TO_CHAR(gn_get_per_name_cnt);
    -- ÂlÊdlf[^o
    l_get_cnt_tab(3).target  := cv_per_legi_msg;
    l_get_cnt_tab(3).cnt     := TO_CHAR(gn_get_per_legi_cnt);
    -- ÂlE[o
    l_get_cnt_tab(4).target  := cv_per_email_msg;
    l_get_cnt_tab(4).cnt     := TO_CHAR(gn_get_per_email_cnt);
    -- ÙpÖWiÞEÒjo
    l_get_cnt_tab(5).target  := cv_work_relation_msg;
    l_get_cnt_tab(5).cnt     := TO_CHAR(gn_get_wk_rel_cnt);
    -- [U[îñiVKjo
    l_get_cnt_tab(6).target  := cv_new_user_info_msg;
    l_get_cnt_tab(6).cnt     := TO_CHAR(gn_get_new_user_cnt);
    -- [U[îñiVKjPaaSpo
    l_get_cnt_tab(7).target  := cv_new_user_info_paas_msg;
    l_get_cnt_tab(7).cnt     := TO_CHAR(gn_get_new_user_paas_cnt);
    -- Ùpðo
    l_get_cnt_tab(8).target  := cv_work_term_msg;
    l_get_cnt_tab(8).cnt     := TO_CHAR(gn_get_wk_terms_cnt);
    -- ATCgîño
    l_get_cnt_tab(9).target  := cv_assignment_msg;
    l_get_cnt_tab(9).cnt     := TO_CHAR(gn_get_ass_cnt);
    -- [U[îño
    l_get_cnt_tab(10).target  := cv_user_info_msg;
    l_get_cnt_tab(10).cnt     := TO_CHAR(gn_get_user_cnt);
-- Ver1.2(E055) Add Start
    -- [U[îñiíjo
    l_get_cnt_tab(11).target  := cv_user2_info_msg;
    l_get_cnt_tab(11).cnt     := TO_CHAR(gn_get_user2_cnt);
-- Ver1.2(E055) Add End
    -- ATCgîñiã·jo
    l_get_cnt_tab(12).target := cv_sup_assignment_msg;
    l_get_cnt_tab(12).cnt    := TO_CHAR(gn_get_ass_sup_cnt);
    -- ÙpÖWiVKÌpÞEÒjo
    l_get_cnt_tab(13).target := cv_work_relation_2_msg;
    l_get_cnt_tab(13).cnt    := TO_CHAR(gn_get_wk_rel2_cnt);
    -- ]ÆõoïûÀîño
    l_get_cnt_tab(14).target := cv_emp_bank_acct_msg;
    l_get_cnt_tab(14).cnt    := TO_CHAR(gn_get_bank_acc_cnt);
    -- Ðõ·ªîño
    l_get_cnt_tab(15).target := cv_emp_info_msg;
    l_get_cnt_tab(15).cnt    := TO_CHAR(gn_get_emp_info_cnt);
    --
    <<get_count_out_loop>>
    FOR i IN 1..l_get_cnt_tab.COUNT LOOP
      --
      lv_msg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_appl_xxcmm             -- AvP[VZk¼FXXCMM
                , iv_name         => cv_search_trgt_cnt_msg    -- bZ[W¼FõÎÛEbZ[W
                , iv_token_name1  => cv_tkn_target             -- g[N¼1FTARGET
                , iv_token_value1 => l_get_cnt_tab(i).target   -- g[Nl1FoÎÛ
                , iv_token_name2  => cv_tkn_count              -- g[N¼2FCOUNT
                , iv_token_value2 => l_get_cnt_tab(i).cnt      -- g[Nl2Fo
                );
      --
      FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => lv_msg
      );
    END LOOP file_name_out_loop;
    --
    --ós}ü
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
--  
    -------------------------------------------------
    -- oÍÌoÍ
    -------------------------------------------------
    -- ]ÆõîñAgf[^t@C
    l_out_cnt_tab(1).target  := gt_prf_val_wrk_out_file;
    l_out_cnt_tab(1).cnt     := TO_CHAR(gn_out_wk_cnt);
    -- PaaSpÌVK[U[îñt@C
    l_out_cnt_tab(2).target  := gt_prf_val_new_usr_out_file;
    l_out_cnt_tab(2).cnt     := TO_CHAR(gn_out_p_new_user_cnt);
    -- [U[îñAgf[^t@C
    l_out_cnt_tab(3).target  := gt_prf_val_usr_out_file;
    l_out_cnt_tab(3).cnt     := TO_CHAR(gn_out_user_cnt);
-- Ver1.2(E055) Add Start
    -- [U[îñiíjAgf[^t@C
    l_out_cnt_tab(4).target  := gt_prf_val_usr2_out_file;
    l_out_cnt_tab(4).cnt     := TO_CHAR(gn_out_user2_cnt);
-- Ver1.2(E055) Add End
    -- ]Æõîñiã·EVKÌpÞEÒjAgf[^t@C
    l_out_cnt_tab(5).target  := gt_prf_val_wrk2_out_file;
    l_out_cnt_tab(5).cnt     := TO_CHAR(gn_out_wk2_cnt);
    -- PaaSpÌ]ÆõoïûÀîñt@C
    l_out_cnt_tab(6).target  := gt_prf_val_emp_bnk_out_file;
    l_out_cnt_tab(6).cnt     := TO_CHAR(gn_out_p_bank_acct_cnt);
    -- PaaSpÌÐõ·ªîñt@C
    l_out_cnt_tab(7).target  := gt_prf_val_emp_inf_out_file;
    l_out_cnt_tab(7).cnt     := TO_CHAR(gn_out_p_emp_info_cnt);
-- Ver1.17 Add Start
    -- PaaSpÌVüÐõîñt@C
    l_out_cnt_tab(8).target  := gt_prf_val_new_emp_out_file;
    l_out_cnt_tab(8).cnt     := TO_CHAR(gn_out_p_new_emp_cnt);
-- Ver1.17 Add End
    --
    <<out_count_out_loop>>
    FOR i IN 1..l_out_cnt_tab.COUNT LOOP
      --
      lv_msg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_appl_xxcmm             -- AvP[VZk¼FXXCMM
                , iv_name         => cv_file_trgt_cnt_msg      -- bZ[W¼Ft@CoÍÎÛEbZ[W
                , iv_token_name1  => cv_tkn_target             -- g[N¼1FTARGET
                , iv_token_value1 => l_out_cnt_tab(i).target   -- g[Nl1FoÍÎÛ
                , iv_token_name2  => cv_tkn_count              -- g[N¼2FCOUNT
                , iv_token_value2 => l_out_cnt_tab(i).cnt      -- g[Nl2FoÍ
                );
      --
      FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => lv_msg
      );
    END LOOP out_count_out_loop;
    --
    --ós}ü
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
--
    -------------------------------------------------
    -- vÌoÍ
    -------------------------------------------------
    -- ÎÛioÌvjðÝè
    gn_target_cnt := gn_get_wk_cnt +
                     gn_get_per_name_cnt +
                     gn_get_per_legi_cnt +
                     gn_get_per_email_cnt +
                     gn_get_wk_rel_cnt +
                     gn_get_new_user_cnt +
                     gn_get_new_user_paas_cnt +
                     gn_get_wk_terms_cnt +
                     gn_get_ass_cnt +
                     gn_get_user_cnt +
-- Ver1.2(E055) Add Start
                     gn_get_user2_cnt +
-- Ver1.2(E055) Add End
                     gn_get_ass_sup_cnt +
                     gn_get_wk_rel2_cnt +
                     gn_get_bank_acc_cnt +
                     gn_get_emp_info_cnt;
    --
    -- ¬÷ioÍÌvjðÝè
    gn_normal_cnt := gn_out_wk_cnt +
                     gn_out_p_new_user_cnt +
                     gn_out_user_cnt +
-- Ver1.2(E055) Add Start
                     gn_out_user2_cnt +
-- Ver1.2(E055) Add End
                     gn_out_wk2_cnt +
                     gn_out_p_bank_acct_cnt +
-- Ver1.17 Mod Start
--                     gn_out_p_emp_info_cnt;
                     gn_out_p_emp_info_cnt +
                     gn_out_p_new_emp_cnt;
-- Ver1.17 Mod End
--
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
END XXCMM002A10C;
/
