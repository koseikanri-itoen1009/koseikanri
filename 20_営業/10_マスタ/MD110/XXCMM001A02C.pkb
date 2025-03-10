CREATE OR REPLACE PACKAGE BODY APPS.XXCMM001A02C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2022. All rights reserved.
 *
 * Package Name     : XXCMM001A02C (body)
 * Description      : düæ}X^IFo_EBSRJg
 * MD.050           : T_MD050_CMM_001_A02_düæ}X^IFo_EBSRJg
 * Version          : 1.14
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  nvl_by_status_code     Xe[^XER[hÉæéNVL
 *  to_csv_string          CSVt@Cp¶ñÏ·iXe[^XER[hwè èj
 *  to_csv_string          CSVt@Cp¶ñÏ·
 *  init                   ú(A-1)
 *  output_supplier        u@TvCvAgf[^ÌoEt@CoÍ(A-2)
 *  output_sup_addr        uATvCEZvAgf[^ÌoEt@CoÍ(A-3)
 *  output_sup_site        uBTvCETCgvAgf[^ÌoEt@CoÍ(A-4)
 *  output_sup_site_ass    uCTvCEBUvAgf[^ÌoEt@CoÍ(A-5)
 *  output_sup_contact     uDTvCESÒvAgf[^ÌoEt@CoÍ(A-6)
 *  output_sup_contact_addruETvCESÒZvAgf[^ÌoEt@CoÍ(A-7)
 *  output_sup_payee       uFTvCEx¥ævAgf[^ÌoEt@CoÍ(A-8)
 *  output_sup_bank_acct   uGTvCEâsûÀvAgf[^ÌoEt@CoÍ(A-9)
 *  output_sup_bank_use    uHTvCEâsûÀvAgf[^ÌoEt@CoÍ(A-10)
 *  output_party_tax_prf   uIp[eBÅàvt@CvAgf[^ÌoEt@CoÍ(A-11)
 *  output_bank_update     uJâsûÀXVpvf[^ÌoEt@CoÍ(A-12)
 *  update_mng_tbl         Çe[uo^EXV(A-13)
 *  submain                CvV[W
 *  main                   RJgÀst@Co^vV[W
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2022-12-02    1.0   Y.Ooyama         VKì¬
 *  2022-12-12    1.1   Y.Ooyama         E113Î
 *  2022-12-13    1.2   Y.Ooyama         E114,E115Î
 *  2022-12-15    1.3   Y.Ooyama         E117,E118,E119,E120,E121Î
 *  2022-12-20    1.4   Y.Ooyama         E123,E124,E125,E126Î
 *  2023-01-06    1.5   Y.Fuku           p»ÎiÚsü¯j
 *  2023-02-07    1.6   Y.Ooyama         ÚsáQNo.11Î
 *  2023-02-08    1.7   Y.Ooyama         ViIeXgsïNo.ST0003Î
 *  2023-02-21    1.8   Y.Ooyama         ViIeXgsïNo.ST0018Î
 *  2023-03-22    1.9   Y.Ooyama         ÚsáQNo.5Î
 *  2023-06-20    1.10  F.Hasebe         ú¬®áQNo.4Î
 *  2023-07-03    1.11  Y.Sato           E_{Ò®_19314Î
 *  2023-09-21    1.12  S.hosonuma       E_{Ò®_19311Î
 *  2024-02-09    1.13  Y.Sato           E_{Ò®_19496Î
 *  2024-03-29    1.14  K.Sudo           E_{Ò®_19828y}X^zdüæ}X^vC}ÏXÎ
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
  -- [U[è`áO
  -- ===============================
  -- bNG[áO
  global_lock_expt          EXCEPTION;
  PRAGMA EXCEPTION_INIT(global_lock_expt, -54);
--
  -- ===============================
  -- [U[è`O[oè
  -- ===============================
  cv_pkg_name      CONSTANT VARCHAR2(100) := 'XXCMM001A02C'; -- pbP[W¼
--
  -- AvP[VZk¼
  cv_appl_xxcmm             CONSTANT VARCHAR2(5) := 'XXCMM';                -- AhIF}X^E}X^Ìæ
  cv_appl_xxccp             CONSTANT VARCHAR2(5) := 'XXCCP';                -- AhIF¤ÊEIFÌæ
  cv_appl_xxcoi             CONSTANT VARCHAR2(5) := 'XXCOI';                -- AhIFÝÉÌæ
--
  -- út®
  cv_date_fmt               CONSTANT VARCHAR2(10) := 'YYYY/MM/DD';
  cv_datetime_fmt           CONSTANT VARCHAR2(21) := 'YYYY/MM/DD HH24:MI:SS';
  cv_datetime_id_fmt        CONSTANT VARCHAR2(16) := 'YYYYMMDDHH24MISS';
--
  -- Åè¶
  cv_slash                  CONSTANT VARCHAR2(1)  := '/';
  cv_comma                  CONSTANT VARCHAR2(1)  := ',';
  cv_space                  CONSTANT VARCHAR2(1)  := ' ';
  cv_ast                    CONSTANT VARCHAR2(1)  := '*';
--
  cv_open_mode_w            CONSTANT VARCHAR2(1)  := 'W';                               -- «Ý[h
  cn_max_linesize           CONSTANT BINARY_INTEGER := 32767;                           -- t@CTCY
  cv_sharp_null             CONSTANT VARCHAR2(5)  := '#NULL';                           -- #NULL
--
  cv_target_ou_name         CONSTANT VARCHAR2(8)  := 'SALES-OU';                        -- õÎÛOU
  cv_status_create          CONSTANT VARCHAR2(6)  := 'CREATE';
  cv_status_update          CONSTANT VARCHAR2(6)  := 'UPDATE';
  cv_spend_authorized       CONSTANT VARCHAR2(16) := 'SPEND_AUTHORIZED';
  cv_employee               CONSTANT VARCHAR2(8)  := 'EMPLOYEE';
  cv_corporation            CONSTANT VARCHAR2(11) := 'Corporation';
  cv_jp                     CONSTANT VARCHAR2(2)  := 'JP';
  cv_express                CONSTANT VARCHAR2(7)  := 'EXPRESS';
  cv_email                  CONSTANT VARCHAR2(5)  := 'EMAIL';
  cv_fax                    CONSTANT VARCHAR2(3)  := 'FAX';
  cv_receipt                CONSTANT VARCHAR2(7)  := 'RECEIPT';
  cv_bearer_i               CONSTANT VARCHAR2(1)  := 'I';
  cv_bearer_x               CONSTANT VARCHAR2(1)  := 'X';
  cv_bearer_s               CONSTANT VARCHAR2(1)  := 'S';
  cv_bearer_n               CONSTANT VARCHAR2(1)  := 'N';
  cv_bearer_d               CONSTANT VARCHAR2(1)  := 'D';
  cv_sales_bu               CONSTANT VARCHAR2(8)  := 'SALES-BU';
  cv_party_sup              CONSTANT VARCHAR2(8)  := 'Supplier';
-- Ver1.3 Mod Start
--  cv_party_sup_site         CONSTANT VARCHAR2(13) := 'Supplier Site';
  cv_party_sup_site         CONSTANT VARCHAR2(13) := 'Supplier site';
-- Ver1.3 Mod End
  cv_line                   CONSTANT VARCHAR2(1)  := 'L';
  cv_line_desc              CONSTANT VARCHAR2(4)  := 'Line';
  cv_header                 CONSTANT VARCHAR2(1)  := 'Y';
  cv_header_desc            CONSTANT VARCHAR2(6)  := 'Header';
  cv_rule_n                 CONSTANT VARCHAR2(1)  := 'N';
-- Ver1.3 Mod Start
--  cv_rule_n_desc            CONSTANT VARCHAR2(4)  := 'Near';
  cv_rule_n_desc            CONSTANT VARCHAR2(7)  := 'Nearest';
-- Ver1.3 Mod End
  cv_rule_d                 CONSTANT VARCHAR2(1)  := 'D';
  cv_rule_d_desc            CONSTANT VARCHAR2(4)  := 'Down';
  cv_y                      CONSTANT VARCHAR2(1)  := 'Y';
  cv_yes                    CONSTANT VARCHAR2(3)  := 'Yes';
  cv_n                      CONSTANT VARCHAR2(1)  := 'N';
  cv_no                     CONSTANT VARCHAR2(2)  := 'No';
  cv_level_3                CONSTANT VARCHAR2(1)  := '3';
  cv_evac_create            CONSTANT VARCHAR2(1)  := 'C';
  cv_evac_update            CONSTANT VARCHAR2(1)  := 'U';
-- Ver1.4(E126) Add Start
  cv_yen                    CONSTANT VARCHAR2(3)  := 'JPY';
-- Ver1.4(E126) Add End
-- Ver1.9 Del Start
---- Ver1.5 Add Start
--  cn_divisor_ten            CONSTANT NUMBER       := 10;
---- Ver1.5 Add End
-- Ver1.9 Del End
--
  -- vt@C
  -- XXCMM:OICAgf[^t@Ci[fBNg¼
  cv_prf_out_file_dir       CONSTANT VARCHAR2(30)  := 'XXCMM1_OIC_OUT_FILE_DIR';
  -- XXCMM:TvCAgf[^t@C¼iOICAgj
  cv_prf_sup_out_file       CONSTANT VARCHAR2(30)  := 'XXCMM1_001A02_S_OUT_FILE_FIL';
  -- XXCMM:TvCEZAgf[^t@C¼iOICAgj
  cv_prf_sup_addr_out_file  CONSTANT VARCHAR2(30)  := 'XXCMM1_001A02_SA_OUT_FILE_FIL';
  -- XXCMM:TvCETCgAgf[^t@C¼iOICAgj
  cv_prf_site_out_file      CONSTANT VARCHAR2(30)  := 'XXCMM1_001A02_SS_OUT_FILE_FIL';
  -- XXCMM:TvCEBUAgf[^t@C¼iOICAgj
  cv_prf_site_ass_out_file  CONSTANT VARCHAR2(30)  := 'XXCMM1_001A02_SSA_OUT_FILE_FIL';
  -- XXCMM:TvCESÒAgf[^t@C¼iOICAgj
  cv_prf_cont_out_file      CONSTANT VARCHAR2(30)  := 'XXCMM1_001A02_SC_OUT_FILE_FIL';
  -- XXCMM:TvCESÒZAgf[^t@C¼iOICAgj
  cv_prf_cont_addr_out_file CONSTANT VARCHAR2(30)  := 'XXCMM1_001A02_SCA_OUT_FILE_FIL';
  -- XXCMM:TvCEx¥æAgf[^t@C¼iOICAgj
  cv_prf_payee_out_file     CONSTANT VARCHAR2(30)  := 'XXCMM1_001A02_SP_OUT_FILE_FIL';
  -- XXCMM:TvCEâsûÀAgf[^t@C¼iOICAgj
  cv_prf_bnk_acct_out_file  CONSTANT VARCHAR2(30)  := 'XXCMM1_001A02_SBA_OUT_FILE_FIL';
  -- XXCMM:TvCEâsûÀAgf[^t@C¼iOICAgj
  cv_prf_bnk_use_out_file   CONSTANT VARCHAR2(30)  := 'XXCMM1_001A02_SBU_OUT_FILE_FIL';
  -- XXCMM:p[eBÅàvt@CAgf[^t@C¼iOICAgj
  cv_prf_tax_prf_out_file   CONSTANT VARCHAR2(30)  := 'XXCMM1_001A02_TID_OUT_FILE_FIL';
  -- XXCMM:âsûÀXVpt@C¼iOICAgj
  cv_prf_bnk_upd_out_file   CONSTANT VARCHAR2(30)  := 'XXCMM1_001A02_BAU_OUT_FILE_FIL';
  -- XXCMM:düæx¥p_~[iOICAgj
  cv_prf_dmy_sup_payment    CONSTANT VARCHAR2(30)  := 'XXCMM1_001A02_DMY_SUP_PAYMENT';
-- Ver1.3 Add Start
  -- XXCMM:p[eBÅàvt@CR[h^CviOICAgj
  cv_prf_ptp_record_type    CONSTANT VARCHAR2(30)  := 'XXCMM1_001A02_PTP_RECORD_TYPE';
-- Ver1.3 Add End
-- Ver1.9 Add Start
  -- XXCMM:piOICAgj
  cv_prf_parallel_num       CONSTANT VARCHAR2(30)  := 'XXCMM1_001A02_PARALLEL_NUM';
-- Ver1.9 Add End
--
  -- bZ[W¼
  cv_prof_get_err_msg       CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00002';                -- vt@Cæ¾G[bZ[W
  cv_dir_path_get_err_msg   CONSTANT VARCHAR2(16)  := 'APP-XXCOI1-00029';                -- fBNgtpXæ¾G[bZ[W
  cv_if_file_name_msg       CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-60003';                -- IFt@C¼oÍbZ[W
  cv_file_exist_err_msg     CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-60004';                -- ¯êt@C¶ÝG[bZ[W
  cv_lock_err_msg           CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00008';                -- bNG[bZ[W
  cv_process_date_msg       CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-60005';                -- úoÍbZ[W
  cv_orgid_get_err_msg      CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00015';                -- gDIDæ¾G[bZ[W
  cv_search_trgt_cnt_msg    CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-60006';                -- õÎÛEbZ[W
  cv_file_open_err_msg      CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00487';                -- t@CI[vG[bZ[W
  cv_file_write_err_msg     CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00488';                -- t@C«ÝG[bZ[W
  cv_file_trgt_cnt_msg      CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-60007';                -- t@CoÍÎÛEbZ[W
  cv_insert_err_msg         CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00054';                -- }üG[bZ[W
  cv_update_err_msg         CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00055';                -- XVG[bZ[W
  cv_evac_data_out_msg      CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-60013';                -- ÞðîñXVoÍbZ[W
  -- bZ[W¼(g[N)
  cv_oic_proc_mng_tbl_msg   CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-60008';                -- OICAgÇe[u
  cv_oic_sup_evac_tbl_msg   CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-60014';                -- OICdüæÞðe[u
  cv_oic_site_evac_tbl_msg  CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-60015';                -- OICdüæTCgÞðe[u
  cv_oic_cont_evac_tbl_msg  CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-60016';                -- OICdüæSÒÞðe[u
  cv_oic_bank_evac_tbl_msg  CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-60017';                -- OICâsûÀÞðe[u
  cv_sup_msg                CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-60018';                -- TvC
  cv_sup_addr_msg           CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-60019';                -- TvCEZ
  cv_site_msg               CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-60020';                -- TvCETCg
  cv_site_ass_msg           CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-60021';                -- TvCEBU
  cv_cont_msg               CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-60022';                -- TvCESÒ
  cv_cont_addr_msg          CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-60023';                -- TvCESÒZ
  cv_payee_msg              CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-60024';                -- TvCEx¥æ
  cv_bnk_acct_msg           CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-60025';                -- TvCEâsûÀ
  cv_bnk_use_msg            CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-60026';                -- TvCEâsûÀ
  cv_tax_prf_msg            CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-60027';                -- p[eBÅàvt@C
  cv_bnk_upd_msg            CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-60028';                -- âsûÀXVp
--
  -- g[N¼
  cv_tkn_ng_profile         CONSTANT VARCHAR2(30)  := 'NG_PROFILE';                      -- g[N¼(NG_PROFILE)
  cv_tkn_dir_tok            CONSTANT VARCHAR2(30)  := 'DIR_TOK';                         -- g[N¼(DIR_TOK)
  cv_tkn_file_name          CONSTANT VARCHAR2(30)  := 'FILE_NAME';                       -- g[N¼(FILE_NAME)
  cv_tkn_ng_table           CONSTANT VARCHAR2(30)  := 'NG_TABLE';                        -- g[N¼(NG_TABLE)
  cv_tkn_date1              CONSTANT VARCHAR2(30)  := 'DATE1';                           -- g[N¼(DATE1)
  cv_tkn_date2              CONSTANT VARCHAR2(30)  := 'DATE2';                           -- g[N¼(DATE2)
  cv_tkn_ng_ou_name         CONSTANT VARCHAR2(30)  := 'NG_OU_NAME';                      -- g[N¼(NG_OU_NAME)
  cv_tkn_target             CONSTANT VARCHAR2(30)  := 'TARGET';                          -- g[N¼(TARGET)
  cv_tkn_count              CONSTANT VARCHAR2(30)  := 'COUNT';                           -- g[N¼(COUNT)
  cv_tkn_table              CONSTANT VARCHAR2(30)  := 'TABLE';                           -- g[N¼(TABLE)
  cv_tkn_err_msg            CONSTANT VARCHAR2(30)  := 'ERR_MSG';                         -- g[N¼(ERR_MSG)
  cv_tkn_sqlerrm            CONSTANT VARCHAR2(30)  := 'SQLERRM';                         -- g[N¼(SQLERRM)
  cv_tkn_id                 CONSTANT VARCHAR2(30)  := 'ID';                              -- g[N¼(ID)
  cv_tkn_before_value       CONSTANT VARCHAR2(30)  := 'BEFORE_VALUE';                    -- g[N¼(BEFORE_VALUE)
  cv_tkn_after_value        CONSTANT VARCHAR2(30)  := 'AFTER_VALUE';                     -- g[N¼(AFTER_VALUE)
--
  -- ===============================
  -- [U[è`O[o^
  -- ===============================
--
  -- ===============================
  -- [U[è`O[oÏ
  -- ===============================
  -- vt@C
  -- XXCMM:OICAgf[^t@Ci[fBNg¼
  gt_prf_val_out_file_dir       fnd_profile_option_values.profile_option_value%TYPE;
  -- XXCMM:TvCAgf[^t@C¼iOICAgj
  gt_prf_val_sup_out_file       fnd_profile_option_values.profile_option_value%TYPE;
  -- XXCMM:TvCEZAgf[^t@C¼iOICAgj
  gt_prf_val_sup_addr_out_file  fnd_profile_option_values.profile_option_value%TYPE;
  -- XXCMM:TvCETCgAgf[^t@C¼iOICAgj
  gt_prf_val_site_out_file      fnd_profile_option_values.profile_option_value%TYPE;
  -- XXCMM:TvCEBUAgf[^t@C¼iOICAgj
  gt_prf_val_site_ass_out_file  fnd_profile_option_values.profile_option_value%TYPE;
  -- XXCMM:TvCESÒAgf[^t@C¼iOICAgj
  gt_prf_val_cont_out_file      fnd_profile_option_values.profile_option_value%TYPE;
  -- XXCMM:TvCESÒZAgf[^t@C¼iOICAgj
  gt_prf_val_cont_addr_out_file fnd_profile_option_values.profile_option_value%TYPE;
  -- XXCMM:TvCEx¥æAgf[^t@C¼iOICAgj
  gt_prf_val_payee_out_file     fnd_profile_option_values.profile_option_value%TYPE;
  -- XXCMM:TvCEâsûÀAgf[^t@C¼iOICAgj
  gt_prf_val_bnk_acct_out_file  fnd_profile_option_values.profile_option_value%TYPE;
  -- XXCMM:TvCEâsûÀAgf[^t@C¼iOICAgj
  gt_prf_val_bnk_use_out_file   fnd_profile_option_values.profile_option_value%TYPE;
  -- XXCMM:p[eBÅàvt@CAgf[^t@C¼iOICAgj
  gt_prf_val_tax_prf_out_file   fnd_profile_option_values.profile_option_value%TYPE;
  -- XXCMM:âsûÀXVpt@C¼iOICAgj
  gt_prf_val_bnk_upd_out_file   fnd_profile_option_values.profile_option_value%TYPE;
  -- XXCMM:düæx¥p_~[iOICAgj
  gt_prf_val_dmy_sup_payment    fnd_profile_option_values.profile_option_value%TYPE;
-- Ver1.3 Add Start
  -- XXCMM:p[eBÅàvt@CR[h^CviOICAgj
  gt_prf_ptp_record_type        fnd_profile_option_values.profile_option_value%TYPE;
-- Ver1.3 Add End
-- Ver1.9 Add Start
  -- XXCMM:piOICAgj
  gt_prf_parallel_num           fnd_profile_option_values.profile_option_value%TYPE;
-- Ver1.9 Add End
--
  -- OICAgÇe[uÌo^EXVf[^
  gt_conc_program_name          fnd_concurrent_programs.concurrent_program_name%TYPE;    -- RJgvO¼
  gt_pre_process_date           xxccp_oic_if_process_mng.pre_process_date%TYPE;          -- Oñú
  gt_cur_process_date           xxccp_oic_if_process_mng.pre_process_date%TYPE;          -- ¡ñú
--
  -- õð
  gt_target_organization_id     hr_all_organization_units.organization_id%TYPE;          -- õÎÛgDID
--
  -- t@Cnh
  gf_sup_file_handle            UTL_FILE.FILE_TYPE;         -- TvCAgf[^t@C
  gf_sup_addr_file_handle       UTL_FILE.FILE_TYPE;         -- TvCEZAgf[^t@C
  gf_site_file_handle           UTL_FILE.FILE_TYPE;         -- TvCETCgAgf[^t@C
  gf_site_ass_file_handle       UTL_FILE.FILE_TYPE;         -- TvCEBUAgf[^t@C
  gf_cont_file_handle           UTL_FILE.FILE_TYPE;         -- TvCESÒAgf[^t@C
  gf_cont_addr_file_handle      UTL_FILE.FILE_TYPE;         -- TvCESÒZAgf[^t@C
  gf_payee_file_handle          UTL_FILE.FILE_TYPE;         -- TvCEx¥æAgf[^t@C
  gf_bnk_acct_file_handle       UTL_FILE.FILE_TYPE;         -- TvCEâsûÀAgf[^t@C
  gf_bnk_use_file_handle        UTL_FILE.FILE_TYPE;         -- TvCEâsûÀAgf[^t@C
  gf_tax_prf_file_handle        UTL_FILE.FILE_TYPE;         -- p[eBÅàvt@CAgf[^t@C
  gf_bnk_upd_file_handle        UTL_FILE.FILE_TYPE;         -- âsûÀXVpt@C
--
  -- ÂÊ
  -- o
  gn_get_sup_cnt                NUMBER;                     -- TvCo
  gn_get_sup_addr_cnt           NUMBER;                     -- TvCEZo
  gn_get_site_cnt               NUMBER;                     -- TvCETCgo
  gn_get_site_ass_cnt           NUMBER;                     -- TvCEBUo
  gn_get_cont_cnt               NUMBER;                     -- TvCESÒo
  gn_get_cont_addr_cnt          NUMBER;                     -- TvCESÒZo
  gn_get_payee_cnt              NUMBER;                     -- TvCEx¥æo
  gn_get_bnk_acct_cnt           NUMBER;                     -- TvCEâsûÀo
  gn_get_bnk_use_cnt            NUMBER;                     -- TvCEâsûÀo
  gn_get_tax_prf_cnt            NUMBER;                     -- p[eBÅàvt@Co
  gn_get_bnk_upd_cnt            NUMBER;                     -- âsûÀXVpo
  -- oÍ
  gn_out_sup_cnt                NUMBER;                     -- TvCAgf[^t@CoÍ
  gn_out_sup_addr_cnt           NUMBER;                     -- TvCEZAgf[^t@CoÍ
  gn_out_site_cnt               NUMBER;                     -- TvCETCgAgf[^t@CoÍ
  gn_out_site_ass_cnt           NUMBER;                     -- TvCEBUAgf[^t@CoÍ
  gn_out_cont_cnt               NUMBER;                     -- TvCESÒAgf[^t@CoÍ
  gn_out_cont_addr_cnt          NUMBER;                     -- TvCESÒZAgf[^t@CoÍ
  gn_out_payee_cnt              NUMBER;                     -- TvCEx¥æAgf[^t@CoÍ
  gn_out_bnk_acct_cnt           NUMBER;                     -- TvCEâsûÀAgf[^t@CoÍ
  gn_out_bnk_use_cnt            NUMBER;                     -- TvCEâsûÀAgf[^t@CoÍ
  gn_out_tax_prf_cnt            NUMBER;                     -- p[eBÅàvt@CAgf[^t@CoÍ
  gn_out_bnk_upd_cnt            NUMBER;                     -- âsûÀXVpt@CoÍ
--
-- Ver1.9 Add Start
  gn_parallel_num               NUMBER;                     -- vt@CluXXCMM:piOICAgjvðlÏ·
-- Ver1.9 Add End
--
  /**********************************************************************************
   * Function Name    : nvl_by_status_code
   * Description      : Xe[^XER[hÉæéNVL
   ***********************************************************************************/
  FUNCTION nvl_by_status_code(
              iv_string          IN VARCHAR2,                 -- ÎÛ¶ñ
              iv_status_code     IN VARCHAR2,                 -- Xe[^XER[hiCREATE/UPDATEj
              iv_c_nvl_string    IN VARCHAR2 DEFAULT NULL,    -- NULLÏ·¶ñ(CREATE)
              iv_u_nvl_string    IN VARCHAR2 DEFAULT NULL     -- NULLÏ·¶ñ(UPDATE)
           )
    RETURN VARCHAR2
  IS
  --
    -- *** [Jè ***
    cv_prg_name         CONSTANT VARCHAR2(100) := 'nvl_by_status_code';
--
    -- *** [JÏ ***
    lv_string           VARCHAR2(3000);
  --
  BEGIN
--
    lv_string := iv_string;
    -- 
    IF ( lv_string IS NULL) THEN
      -- ÎÛ¶ñªNULLÌê
      IF ( iv_status_code = cv_status_create ) THEN
        -- Xe[^XER[hªCREATEÌê
        IF ( iv_c_nvl_string IS NOT NULL ) THEN
          -- NULLÏ·¶ñ(CREATE)Ìwèª éê ¨ NULLÏ·¶ñ(CREATE)
          lv_string := iv_c_nvl_string;
        ELSE
          -- NULLÏ·¶ñ(CREATE)ÌwèªÈ¢ê ¨ NULL
          lv_string := NULL;
        END IF;
      --
      ELSE
        -- Xe[^XER[hªCREATEÈOiUPDATEjÌê
        IF ( iv_u_nvl_string IS NOT NULL ) THEN
          -- NULLÏ·¶ñ(UPDATE)Ìwèª éê ¨ NULLÏ·¶ñ(UPDATE)
          lv_string := iv_u_nvl_string;
        ELSE
          -- NULLÏ·¶ñ(UPDATE)ÌwèªÈ¢ê ¨ #NULL
          lv_string := cv_sharp_null;
        END IF;
      END IF;
    END IF;
--
    RETURN lv_string;
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
  END nvl_by_status_code;
--
--
  /**********************************************************************************
   * Function Name    : to_csv_string
   * Description      : CSVt@Cp¶ñÏ·iXe[^XER[hwè èj
   ***********************************************************************************/
  FUNCTION to_csv_string(
              iv_string          IN VARCHAR2,                 -- ÎÛ¶ñ
              iv_status_code     IN VARCHAR2,                 -- Xe[^XER[hiCREATE/UPDATEj
              iv_c_nvl_string    IN VARCHAR2 DEFAULT NULL,    -- NULLÏ·¶ñ(CREATE)
              iv_u_nvl_string    IN VARCHAR2 DEFAULT NULL     -- NULLÏ·¶ñ(UPDATE)
           )
    RETURN VARCHAR2
  IS
  --
    -- *** [Jè ***
    cv_prg_name         CONSTANT VARCHAR2(100) := 'to_csv_string';
--
    -- *** [JÏ ***
  --
  BEGIN
--
    -- 
    -- ÎÛ¶ñªNULLÌê
    IF ( iv_string IS NULL) THEN
      -- Xe[^XER[hiCREATE/UPDATEjÉæéNVLðÀ{
      RETURN nvl_by_status_code(
               iv_string
             , iv_status_code
             , iv_c_nvl_string
             , iv_u_nvl_string
             );
    END IF;
--
    -- ÎÛ¶ñªNOT NULLÌê
    -- OIC¤ÊÖÌCSVt@Cp¶ñÏ·ðÀ{iLFu·PêÍ¼pXy[Xðwèj
    RETURN xxccp_oiccommon_pkg.to_csv_string( iv_string , cv_space );
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
  END to_csv_string;
--
--
  /**********************************************************************************
   * Function Name    : to_csv_string
   * Description      : CSVt@Cp¶ñÏ·
   ***********************************************************************************/
  FUNCTION to_csv_string(
              iv_string          IN VARCHAR2                  -- ÎÛ¶ñ
           )
    RETURN VARCHAR2
  IS
  --
    -- *** [Jè ***
    cv_prg_name         CONSTANT VARCHAR2(100) := 'to_csv_string';
--
    -- *** [JÏ ***
  --
  BEGIN
--
    -- ÎÛ¶ñªNULLÌê
    IF ( iv_string IS NULL) THEN
      RETURN iv_string;
    END IF;
    --
    -- OIC¤ÊÖÌCSVt@Cp¶ñÏ·ðÀ{iLFu·PêÍ¼pXy[Xðwèj
    RETURN xxccp_oiccommon_pkg.to_csv_string( iv_string , cv_space );
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
  END to_csv_string;
--
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ú(A-1)
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
    lv_msg               VARCHAR2(3000);
    lt_dir_path          all_directories.directory_path%TYPE; -- fBNgpX
    lb_fexists           BOOLEAN;                             -- t@Cª¶Ý·é©Ç¤©
    ln_file_length       NUMBER;                              -- t@C·
    ln_block_size        NUMBER;                              -- ubNTCY
    ln_prf_idx           NUMBER;                              -- vt@CpCfbNX
    ln_file_name_idx     NUMBER;                              -- t@C¼pCfbNX
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
    -- üÍp[^Èµ
--
    -- ==============================================================
    -- 2.vt@ClÌæ¾
    -- ==============================================================
    ln_prf_idx := 0;
    -- 1.XXCMM:OICAgf[^t@Ci[fBNg¼
    gt_prf_val_out_file_dir := FND_PROFILE.VALUE( cv_prf_out_file_dir );
    -- vt@Cpe[uÉÝè
    ln_prf_idx := ln_prf_idx + 1;
    l_prf_tab(ln_prf_idx).prf_name  := cv_prf_out_file_dir;
    l_prf_tab(ln_prf_idx).prf_value := gt_prf_val_out_file_dir;
    --
    -- 2.XXCMM:TvCAgf[^t@C¼iOICAgj
    gt_prf_val_sup_out_file := FND_PROFILE.VALUE( cv_prf_sup_out_file );
    -- vt@Cpe[uÉÝè
    ln_prf_idx := ln_prf_idx + 1;
    l_prf_tab(ln_prf_idx).prf_name  := cv_prf_sup_out_file;
    l_prf_tab(ln_prf_idx).prf_value := gt_prf_val_sup_out_file;
    --
    -- 3.XXCMM:TvCEZAgf[^t@C¼iOICAgj
    gt_prf_val_sup_addr_out_file := FND_PROFILE.VALUE( cv_prf_sup_addr_out_file );
    -- vt@Cpe[uÉÝè
    ln_prf_idx := ln_prf_idx + 1;
    l_prf_tab(ln_prf_idx).prf_name  := cv_prf_sup_addr_out_file;
    l_prf_tab(ln_prf_idx).prf_value := gt_prf_val_sup_addr_out_file;
    --
    -- 4.XXCMM:TvCETCgAgf[^t@C¼iOICAgj
    gt_prf_val_site_out_file := FND_PROFILE.VALUE( cv_prf_site_out_file );
    -- vt@Cpe[uÉÝè
    ln_prf_idx := ln_prf_idx + 1;
    l_prf_tab(ln_prf_idx).prf_name  := cv_prf_site_out_file;
    l_prf_tab(ln_prf_idx).prf_value := gt_prf_val_site_out_file;
    --
    -- 5.XXCMM:TvCEBUAgf[^t@C¼iOICAgj
    gt_prf_val_site_ass_out_file := FND_PROFILE.VALUE( cv_prf_site_ass_out_file );
    -- vt@Cpe[uÉÝè
    ln_prf_idx := ln_prf_idx + 1;
    l_prf_tab(ln_prf_idx).prf_name  := cv_prf_site_ass_out_file;
    l_prf_tab(ln_prf_idx).prf_value := gt_prf_val_site_ass_out_file;
    --
    -- 6.XXCMM:TvCESÒAgf[^t@C¼iOICAgj
    gt_prf_val_cont_out_file := FND_PROFILE.VALUE( cv_prf_cont_out_file );
    -- vt@Cpe[uÉÝè
    ln_prf_idx := ln_prf_idx + 1;
    l_prf_tab(ln_prf_idx).prf_name  := cv_prf_cont_out_file;
    l_prf_tab(ln_prf_idx).prf_value := gt_prf_val_cont_out_file;
    --
    -- 7.XXCMM:TvCESÒZAgf[^t@C¼iOICAgj
    gt_prf_val_cont_addr_out_file := FND_PROFILE.VALUE( cv_prf_cont_addr_out_file );
    -- vt@Cpe[uÉÝè
    ln_prf_idx := ln_prf_idx + 1;
    l_prf_tab(ln_prf_idx).prf_name  := cv_prf_cont_addr_out_file;
    l_prf_tab(ln_prf_idx).prf_value := gt_prf_val_cont_addr_out_file;
    --
    -- 8.XXCMM:TvCEx¥æAgf[^t@C¼iOICAgj
    gt_prf_val_payee_out_file := FND_PROFILE.VALUE( cv_prf_payee_out_file );
    -- vt@Cpe[uÉÝè
    ln_prf_idx := ln_prf_idx + 1;
    l_prf_tab(ln_prf_idx).prf_name  := cv_prf_payee_out_file;
    l_prf_tab(ln_prf_idx).prf_value := gt_prf_val_payee_out_file;
    --
    -- 9.XXCMM:TvCEâsûÀAgf[^t@C¼iOICAgj
    gt_prf_val_bnk_acct_out_file := FND_PROFILE.VALUE( cv_prf_bnk_acct_out_file );
    -- vt@Cpe[uÉÝè
    ln_prf_idx := ln_prf_idx + 1;
    l_prf_tab(ln_prf_idx).prf_name  := cv_prf_bnk_acct_out_file;
    l_prf_tab(ln_prf_idx).prf_value := gt_prf_val_bnk_acct_out_file;
    --
    -- 10.XXCMM:TvCEâsûÀAgf[^t@C¼iOICAgj
    gt_prf_val_bnk_use_out_file := FND_PROFILE.VALUE( cv_prf_bnk_use_out_file );
    -- vt@Cpe[uÉÝè
    ln_prf_idx := ln_prf_idx + 1;
    l_prf_tab(ln_prf_idx).prf_name  := cv_prf_bnk_use_out_file;
    l_prf_tab(ln_prf_idx).prf_value := gt_prf_val_bnk_use_out_file;
    --
    -- 11.XXCMM:p[eBÅàvt@CAgf[^t@C¼iOICAgj
    gt_prf_val_tax_prf_out_file := FND_PROFILE.VALUE( cv_prf_tax_prf_out_file );
    -- vt@Cpe[uÉÝè
    ln_prf_idx := ln_prf_idx + 1;
    l_prf_tab(ln_prf_idx).prf_name  := cv_prf_tax_prf_out_file;
    l_prf_tab(ln_prf_idx).prf_value := gt_prf_val_tax_prf_out_file;
    --
    -- 12.XXCMM:âsûÀXVpt@C¼iOICAgj
    gt_prf_val_bnk_upd_out_file := FND_PROFILE.VALUE( cv_prf_bnk_upd_out_file );
    -- vt@Cpe[uÉÝè
    ln_prf_idx := ln_prf_idx + 1;
    l_prf_tab(ln_prf_idx).prf_name  := cv_prf_bnk_upd_out_file;
    l_prf_tab(ln_prf_idx).prf_value := gt_prf_val_bnk_upd_out_file;
    --
    -- 13.XXCMM:düæx¥p_~[iOICAgj
    gt_prf_val_dmy_sup_payment := FND_PROFILE.VALUE( cv_prf_dmy_sup_payment );
    -- vt@Cpe[uÉÝè
    ln_prf_idx := ln_prf_idx + 1;
    l_prf_tab(ln_prf_idx).prf_name  := cv_prf_dmy_sup_payment;
    l_prf_tab(ln_prf_idx).prf_value := gt_prf_val_dmy_sup_payment;
    --
-- Ver1.3 Add Start
    -- 14.XXCMM:p[eBÅàvt@CR[h^CviOICAgj
    gt_prf_ptp_record_type := FND_PROFILE.VALUE( cv_prf_ptp_record_type );
    -- vt@Cpe[uÉÝè
    ln_prf_idx := ln_prf_idx + 1;
    l_prf_tab(ln_prf_idx).prf_name  := cv_prf_ptp_record_type;
    l_prf_tab(ln_prf_idx).prf_value := gt_prf_ptp_record_type;
-- Ver1.3 Add End
    --
-- Ver1.9 Add Start
    -- 15.XXCMM:piOICAgj
    gt_prf_parallel_num := FND_PROFILE.VALUE( cv_prf_parallel_num );
    -- vt@Cpe[uÉÝè
    ln_prf_idx := ln_prf_idx + 1;
    l_prf_tab(ln_prf_idx).prf_name  := cv_prf_parallel_num;
    l_prf_tab(ln_prf_idx).prf_value := gt_prf_parallel_num;
-- Ver1.9 Add End
    --
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
-- Ver1.9 Add Start
    -- vt@CluXXCMM:piOICAgjvÌlÏ·
    BEGIN
      gn_parallel_num := TO_NUMBER(gt_prf_parallel_num);
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg :=  xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_xxcmm              -- AvP[VZk¼FXXCMM
                      , iv_name         => cv_prof_get_err_msg        -- bZ[W¼Fvt@Cæ¾G[bZ[W
                      , iv_token_name1  => cv_tkn_ng_profile          -- g[N¼1FNG_PROFILE
                      , iv_token_value1 => cv_prf_parallel_num      -- g[Nl1Fvt@C
                      );
        lv_errbuf :=  lv_errmsg;
        RAISE global_process_expt;
    END;
-- Ver1.9 Add End
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
    -- 4.IFt@C¼ÌoÍ
    -- ==============================================================
    ln_file_name_idx := 0;
    --
    -- TvCAgf[^t@C¼
    ln_file_name_idx := ln_file_name_idx + 1;
    l_file_name_tab(ln_file_name_idx) := gt_prf_val_sup_out_file;
    --
    -- TvCEZAgf[^t@C¼
    ln_file_name_idx := ln_file_name_idx + 1;
    l_file_name_tab(ln_file_name_idx) := gt_prf_val_sup_addr_out_file;
    --
    -- TvCETCgAgf[^t@C¼
    ln_file_name_idx := ln_file_name_idx + 1;
    l_file_name_tab(ln_file_name_idx) := gt_prf_val_site_out_file;
    --
    -- TvCEBUAgf[^t@C¼
    ln_file_name_idx := ln_file_name_idx + 1;
    l_file_name_tab(ln_file_name_idx) := gt_prf_val_site_ass_out_file;
    --
    -- TvCESÒAgf[^t@C¼
    ln_file_name_idx := ln_file_name_idx + 1;
    l_file_name_tab(ln_file_name_idx) := gt_prf_val_cont_out_file;
    --
    -- TvCESÒZAgf[^t@C¼
    ln_file_name_idx := ln_file_name_idx + 1;
    l_file_name_tab(ln_file_name_idx) := gt_prf_val_cont_addr_out_file;
    --
    -- TvCEx¥æAgf[^t@C¼
    ln_file_name_idx := ln_file_name_idx + 1;
    l_file_name_tab(ln_file_name_idx) := gt_prf_val_payee_out_file;
    --
    -- TvCEâsûÀAgf[^t@C¼
    ln_file_name_idx := ln_file_name_idx + 1;
    l_file_name_tab(ln_file_name_idx) := gt_prf_val_bnk_acct_out_file;
    --
    -- TvCEâsûÀAgf[^t@C¼
    ln_file_name_idx := ln_file_name_idx + 1;
    l_file_name_tab(ln_file_name_idx) := gt_prf_val_bnk_use_out_file;
    --
    -- p[eBÅàvt@CAgf[^t@C¼
    ln_file_name_idx := ln_file_name_idx + 1;
    l_file_name_tab(ln_file_name_idx) := gt_prf_val_tax_prf_out_file;
    --
    -- âsûÀXVpt@C¼
    ln_file_name_idx := ln_file_name_idx + 1;
    l_file_name_tab(ln_file_name_idx) := gt_prf_val_bnk_upd_out_file;
    --
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
    -- 5.t@C¶Ý`FbN
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
    -- 6.RJgvO¼A¨æÑOñúÌæ¾
    -- ==============================================================
    SELECT
        fcp.concurrent_program_name     AS conc_program_name        -- RJgvO¼
      , xoipm.pre_process_date          AS pre_process_date         -- Oñú
    INTO
        gt_conc_program_name
      , gt_pre_process_date
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
    -- 7.¡ñúÌæ¾
    -- ==============================================================
    gt_cur_process_date := SYSDATE;
--
    -- ==============================================================
    -- 8.OñE¡ñúÌoÍ
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
    -- 9.gDIDÌæ¾
    -- ==============================================================
    BEGIN
      SELECT
          haouv.organization_id       AS  organization_id        -- gDID
      INTO
          gt_target_organization_id
      FROM
          hr_all_organization_units_vl  haouv     -- gDPÊr[
      WHERE
          haouv.name = cv_target_ou_name
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_errbuf :=  xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_xxcmm             -- AvP[VZk¼FXXCMM
                      , iv_name         => cv_orgid_get_err_msg      -- bZ[W¼FgDIDæ¾G[bZ[W
                      , iv_token_name1  => cv_tkn_ng_ou_name         -- g[N¼1FNG_OU_NAME
                      , iv_token_value1 => cv_target_ou_name         -- g[Nl1FõÎÛOU
                      );
        --
        lv_errmsg :=  lv_errbuf;
        RAISE  global_process_expt;
    END;
--
    -- ==============================================================
    -- 10.t@CI[v
    -- ==============================================================
    BEGIN
      -- TvCAgf[^t@C
      gf_sup_file_handle       := UTL_FILE.FOPEN(
                                    location     => gt_prf_val_out_file_dir
                                  , filename     => gt_prf_val_sup_out_file
                                  , open_mode    => cv_open_mode_w
                                  , max_linesize => cn_max_linesize
                                  );
      --
      -- TvCEZAgf[^t@C
      gf_sup_addr_file_handle  := UTL_FILE.FOPEN(
                                    location     => gt_prf_val_out_file_dir
                                  , filename     => gt_prf_val_sup_addr_out_file
                                  , open_mode    => cv_open_mode_w
                                  , max_linesize => cn_max_linesize
                                  );
      --
      -- TvCETCgAgf[^t@C
      gf_site_file_handle      := UTL_FILE.FOPEN(
                                    location     => gt_prf_val_out_file_dir
                                  , filename     => gt_prf_val_site_out_file
                                  , open_mode    => cv_open_mode_w
                                  , max_linesize => cn_max_linesize
                                  );
      --
      -- TvCEBUAgf[^t@C
      gf_site_ass_file_handle  := UTL_FILE.FOPEN(
                                    location     => gt_prf_val_out_file_dir
                                  , filename     => gt_prf_val_site_ass_out_file
                                  , open_mode    => cv_open_mode_w
                                  , max_linesize => cn_max_linesize
                                  );
      --
      -- TvCESÒAgf[^t@C
      gf_cont_file_handle      := UTL_FILE.FOPEN(
                                    location     => gt_prf_val_out_file_dir
                                  , filename     => gt_prf_val_cont_out_file
                                  , open_mode    => cv_open_mode_w
                                  , max_linesize => cn_max_linesize
                                  );
      --
      -- TvCESÒZAgf[^t@C
      gf_cont_addr_file_handle := UTL_FILE.FOPEN(
                                    location     => gt_prf_val_out_file_dir
                                  , filename     => gt_prf_val_cont_addr_out_file
                                  , open_mode    => cv_open_mode_w
                                  , max_linesize => cn_max_linesize
                                  );
      --
      -- TvCEx¥æAgf[^t@C
      gf_payee_file_handle     := UTL_FILE.FOPEN(
                                    location     => gt_prf_val_out_file_dir
                                  , filename     => gt_prf_val_payee_out_file
                                  , open_mode    => cv_open_mode_w
                                  , max_linesize => cn_max_linesize
                                  );
      --
      -- TvCEâsûÀAgf[^t@C
      gf_bnk_acct_file_handle  := UTL_FILE.FOPEN(
                                    location     => gt_prf_val_out_file_dir
                                  , filename     => gt_prf_val_bnk_acct_out_file
                                  , open_mode    => cv_open_mode_w
                                  , max_linesize => cn_max_linesize
                                  );
      --
      -- TvCEâsûÀAgf[^t@C
      gf_bnk_use_file_handle   := UTL_FILE.FOPEN(
                                    location     => gt_prf_val_out_file_dir
                                  , filename     => gt_prf_val_bnk_use_out_file
                                  , open_mode    => cv_open_mode_w
                                  , max_linesize => cn_max_linesize
                                  );
      --
      -- p[eBÅàvt@CAgf[^t@C
      gf_tax_prf_file_handle   := UTL_FILE.FOPEN(
                                    location     => gt_prf_val_out_file_dir
                                  , filename     => gt_prf_val_tax_prf_out_file
                                  , open_mode    => cv_open_mode_w
                                  , max_linesize => cn_max_linesize
                                  );
      --
      -- âsûÀXVpt@C
      gf_bnk_upd_file_handle   := UTL_FILE.FOPEN(
                                    location     => gt_prf_val_out_file_dir
                                  , filename     => gt_prf_val_bnk_upd_out_file
                                  , open_mode    => cv_open_mode_w
                                  , max_linesize => cn_max_linesize
                                  );
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
  EXCEPTION
--
    -- *** bNG[áOnh ***
    WHEN global_lock_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_xxcmm             -- AvP[VZk¼FXXCMM
                   , iv_name         => cv_lock_err_msg           -- bZ[W¼FbNG[bZ[W
                   , iv_token_name1  => cv_tkn_ng_table           -- g[N¼1FNG_TABLE
                   , iv_token_value1 => cv_oic_proc_mng_tbl_msg   -- g[Nl1Fe[u¼FOICAgÇe[u
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
   * Procedure Name   : output_supplier
   * Description      : u@TvCvAgf[^ÌoEt@CoÍ(A-2)
   ***********************************************************************************/
  PROCEDURE output_supplier(
    ov_errbuf     OUT VARCHAR2,     --   G[EbZ[W           --# Åè #
    ov_retcode    OUT VARCHAR2,     --   ^[ER[h             --# Åè #
    ov_errmsg     OUT VARCHAR2)     --   [U[EG[EbZ[W --# Åè #
  IS
    -- ===============================
    -- Åè[Jè
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'output_supplier';       -- vO¼
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
    lv_file_data         VARCHAR2(30000) DEFAULT NULL;       -- oÍàe
--
    -- *** [JEJ[\ ***
    -- u@TvCvÌoJ[\
    CURSOR supplier_cur
    IS
      SELECT
          (CASE
             WHEN (    gt_pre_process_date IS NULL
                   OR  pv.creation_date > gt_pre_process_date) THEN
               cv_status_create
             ELSE
               cv_status_update
           END)                                          AS status_code                -- Xe[^XER[h
        , (CASE
             WHEN xove.vendor_id IS NOT NULL THEN
               xove.vendor_name
             ELSE
               pv.vendor_name
           END)                                          AS vendor_name                -- düæ¼
        , (CASE
             WHEN (xove.vendor_id IS NOT NULL
                   AND xove.vendor_name <> pv.vendor_name) THEN
               pv.vendor_name
             ELSE
               NULL
           END)                                          AS new_vendor_name            -- Vdüæ¼
        , pv.segment1                                    AS segment1                   -- düæÔ
        , pv.vendor_name_alt                             AS vendor_name_alt            -- düæ¼Ji
        , pv.vendor_type_lookup_code                     AS vendor_type_lookup_code    -- düæ^Cv
        , TO_CHAR(pv.end_date_active, cv_date_fmt)       AS end_date_active            -- ³øú
        , (CASE
             WHEN (    gt_pre_process_date IS NULL
                   OR  pv.creation_date > gt_pre_process_date) THEN
               cv_spend_authorized
             ELSE
               NULL
           END)                                          AS business_relationship      -- rWlXÖA
        , pv.one_time_flag                               AS one_time_flag              -- êtO
        , pv.auto_tax_calc_override                      AS auto_tax_calc_override     -- ©®ÅàvZã«
        , pv.pay_group_lookup_code                       AS pay_group_lookup_code      -- x¥O[v
        , pv.vendor_id                                   AS vendor_id                  -- düæID
        , pv.vendor_name                                 AS pv_vendor_name             -- düæ¼i}X^j
        , xove.vendor_name                               AS xove_vendor_name           -- düæ¼iÞðe[uj
        , (CASE
             WHEN xove.vendor_id IS NULL THEN
               cv_evac_create
             WHEN xove.vendor_name <> pv.vendor_name THEN
               cv_evac_update
             ELSE
               NULL
           END)                                          AS key_ins_upd_flag           -- L[îño^EXVtO
-- Ver1.5 Add Start
        , (CASE 
            WHEN ( gt_pre_process_date IS NULL ) THEN 
-- Ver1.9 Mod Start
--              TO_CHAR( gt_cur_process_date , cv_datetime_id_fmt ) || MOD( pv.vendor_id , cn_divisor_ten )
              TO_CHAR( gt_cur_process_date , cv_datetime_id_fmt ) || MOD( pv.vendor_id , gn_parallel_num )
-- Ver1.9 Mod End
            ELSE
              NULL
          END)                                           AS batch_id                   -- ob`ID
-- Ver1.5 Add End
      FROM
          po_vendors         pv    -- düæ}X^
        , xxcmm_oic_vd_evac  xove  -- OICdüæÞðe[u
      WHERE
          (   gt_pre_process_date IS NULL
-- Ver1.11 Mod Start
--           OR pv.last_update_date > gt_pre_process_date)
           OR (    pv.last_update_date > gt_pre_process_date
               AND pv.last_update_date <= gt_cur_process_date)
           )
-- Ver1.11 Mod End
      AND NVL(pv.vendor_type_lookup_code, 'X') <> cv_employee
      AND EXISTS (
              SELECT
                  1  AS flag
              FROM
                  po_vendor_sites_all  pvsa  -- düæTCg
              WHERE
                  pvsa.vendor_id = pv.vendor_id
              AND pvsa.org_id    = gt_target_organization_id
          )
      AND pv.vendor_id = xove.vendor_id (+)
      ORDER BY
          pv.segment1 ASC  -- düæÔ
      FOR UPDATE OF xove.vendor_name NOWAIT  -- sbNFOICdüæÞðe[u
    ;
--
    -- *** [JER[h ***
    -- u@TvCvÌoJ[\R[h
    l_supplier_rec     supplier_cur%ROWTYPE;
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
    -- u@TvCvÌo
    -- ==============================================================
    -- J[\I[v
    OPEN  supplier_cur;
    <<output_supplier_loop>>
    LOOP
      --
      FETCH supplier_cur INTO l_supplier_rec;
      EXIT WHEN supplier_cur%NOTFOUND;
      --
      -- oJEgAbv
      gn_get_sup_cnt := gn_get_sup_cnt + 1;
      --
      -- ==============================================================
      -- u@TvCvÌt@CoÍ
      -- ==============================================================
      -- f[^sÌì¬
      lv_file_data := l_supplier_rec.status_code;                     --   1 : Import Action * (Xe[^XER[h)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string(
-- Ver1.6 Mod Start
--                        l_supplier_rec.vendor_name
                        xxccp_oiccommon_pkg.trim_space_tab(l_supplier_rec.vendor_name)
-- Ver1.6 Mod End
                      , l_supplier_rec.status_code
                      );                                              --   2 : Supplier Name* (TvC¼Ì)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string(
-- Ver1.6 Mod Start
--                        l_supplier_rec.new_vendor_name
                        xxccp_oiccommon_pkg.trim_space_tab(l_supplier_rec.new_vendor_name)
-- Ver1.6 Mod End
-- Ver1.3 Del Start(ÖAÎ)
--                      , l_supplier_rec.status_code
-- Ver1.3 Del End
                      );                                              --   3 : Supplier Name New (VTvC¼Ì)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string(
                        l_supplier_rec.segment1
                      , l_supplier_rec.status_code
                      );                                              --   4 : Supplier Number (TvCÔ)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string(
                        l_supplier_rec.vendor_name_alt
                      , l_supplier_rec.status_code
                      );                                              --   5 : Alternate Name (TvC¼Ì(Ji))
      lv_file_data := lv_file_data || cv_comma || cv_corporation;     --   6 : Tax Organization Type (ÅgD^Cv)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string(
                        l_supplier_rec.vendor_type_lookup_code
                      , l_supplier_rec.status_code
                      );                                              --   7 : Supplier Type (TvCE^Cv)
      lv_file_data := lv_file_data || cv_comma || 
                      nvl_by_status_code(
                        l_supplier_rec.end_date_active
                      , l_supplier_rec.status_code
                      );                                              --   8 : Inactive Date (ñANeBuú)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string(
                        l_supplier_rec.business_relationship
-- Ver1.3 Del Start(ÖAÎ)
--                      , l_supplier_rec.status_code
-- Ver1.3 Del End
                      );                                              --   9 : Business Relationship* (rWlXÖA)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  10 : Parent Supplier (eTvC)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  11 : Alias (Ê¼)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  12 : D-U-N-S Number (D-U-N-SÔ)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string(
                        l_supplier_rec.one_time_flag
                      , l_supplier_rec.status_code
                      , cv_n
                      , cv_n
                      );                                              --  13 : One-time supplier (êTvC)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  14 : Customer Number (ÚqÔ)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  15 : SIC (WYÆªÞ)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  16 : National Insurance Number (¯Û¯Ô)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  17 : Corporate Web Site (@lWebTCg)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  18 : Chief Executive Title (ÅocÓCÒ^Cg)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  19 : Chief Executive Name (ÅocÓCÒ¼)
      lv_file_data := lv_file_data || cv_comma || cv_y;               --  20 : Business Classifications Not Applicable (ÆªÞÌL³)
      lv_file_data := lv_file_data || cv_comma || cv_jp;              --  21 : Taxpayer Country ([ÅÒ)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  22 : Taxpayer ID ([ÅÒID)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  23 : Federal reportable (AM|[gÂ\)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  24 : Federal Income Tax Type (AM¾Å^Cv)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  25 : State reportable (s¹{§|[gÂ\)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  26 : Tax Reporting Name (Åà|[g¼)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  27 : Name Control (¼OÇ)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  28 : Tax Verification Date (mFú)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  29 : Use withholding tax (¹ò¥ûÅÌgp)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  30 : Withholding Tax Group (¹ò¥ûÅO[v)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  31 : Vat Code (tÁ¿lÅR[h)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  32 : Tax Registration Number (tÁ¿lÅo^Ô)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string(
                        l_supplier_rec.auto_tax_calc_override
                      , l_supplier_rec.status_code
                      , cv_n
                      , cv_n
                      );                                              --  33 : Auto Tax Calc Override (©®ÅàvZã«)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string(
                        l_supplier_rec.pay_group_lookup_code
                      , l_supplier_rec.status_code
                      );                                              --  34 : Payment Method (x¥û@)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  35 : Delivery Channel (Ï`l)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  36 : Bank Instruction 1 (âsw}1)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  37 : Bank Instruction 2 (âsw}2)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  38 : Bank Instruction (âsw}Ú×)
      lv_file_data := lv_file_data || cv_comma || cv_express;         --  39 : Settlement Priority (¸ZDæx)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  40 : Payment Text Message 1 (x¥eLXgEbZ[W1)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  41 : Payment Text Message 2 (x¥eLXgEbZ[W2)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  42 : Payment Text Message 3 (x¥eLXgEbZ[W3)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  43 : Bank Charge Bearer (âsè¿SÒ)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  44 : Payment Reason (x¥R)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  45 : Payment Reason Comments (x¥RRg)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  46 : Payment Format (x¥tH[}bgR[h)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  47 : ATTRIBUTE_CATEGORY (ÇÁîñJeS)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  48 : ATTRIBUTE1 (ÇÁîñ1)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  49 : ATTRIBUTE2 (ÇÁîñ2)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  50 : ATTRIBUTE3 (ÇÁîñ3)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  51 : ATTRIBUTE4 (ÇÁîñ4)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  52 : ATTRIBUTE5 (ÇÁîñ5)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  53 : ATTRIBUTE6 (ÇÁîñ6)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  54 : ATTRIBUTE7 (ÇÁîñ7)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  55 : ATTRIBUTE8 (ÇÁîñ8)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  56 : ATTRIBUTE9 (ÇÁîñ9)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  57 : ATTRIBUTE10 (ÇÁîñ10)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  58 : ATTRIBUTE11 (ÇÁîñ11)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  59 : ATTRIBUTE12 (ÇÁîñ12)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  60 : ATTRIBUTE13 (ÇÁîñ13)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  61 : ATTRIBUTE14 (ÇÁîñ14)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  62 : ATTRIBUTE15 (ÇÁîñ15)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  63 : ATTRIBUTE16 (ÇÁîñ16)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  64 : ATTRIBUTE17 (ÇÁîñ17)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  65 : ATTRIBUTE18 (ÇÁîñ18)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  66 : ATTRIBUTE19 (ÇÁîñ19)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  67 : ATTRIBUTE20 (ÇÁîñ20)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  68 : ATTRIBUTE_DATE1 (ÇÁîñ_út1)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  69 : ATTRIBUTE_DATE2 (ÇÁîñ_út2)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  70 : ATTRIBUTE_DATE3 (ÇÁîñ_út3)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  71 : ATTRIBUTE_DATE4 (ÇÁîñ_út4)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  72 : ATTRIBUTE_DATE5 (ÇÁîñ_út5)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  73 : ATTRIBUTE_DATE6 (ÇÁîñ_út6)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  74 : ATTRIBUTE_DATE7 (ÇÁîñ_út7)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  75 : ATTRIBUTE_DATE8 (ÇÁîñ_út8)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  76 : ATTRIBUTE_DATE9 (ÇÁîñ_út9)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  77 : ATTRIBUTE_DATE10 (ÇÁîñ_út10)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  78 : ATTRIBUTE_TIMESTAMP1 (ÇÁîñ_À²Ñ½ÀÝÌß1)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  79 : ATTRIBUTE_TIMESTAMP2 (ÇÁîñ_À²Ñ½ÀÝÌß2)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  80 : ATTRIBUTE_TIMESTAMP3 (ÇÁîñ_À²Ñ½ÀÝÌß3)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  81 : ATTRIBUTE_TIMESTAMP4 (ÇÁîñ_À²Ñ½ÀÝÌß4)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  82 : ATTRIBUTE_TIMESTAMP5 (ÇÁîñ_À²Ñ½ÀÝÌß5)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  83 : ATTRIBUTE_TIMESTAMP6 (ÇÁîñ_À²Ñ½ÀÝÌß6)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  84 : ATTRIBUTE_TIMESTAMP7 (ÇÁîñ_À²Ñ½ÀÝÌß7)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  85 : ATTRIBUTE_TIMESTAMP8 (ÇÁîñ_À²Ñ½ÀÝÌß8)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  86 : ATTRIBUTE_TIMESTAMP9 (ÇÁîñ_À²Ñ½ÀÝÌß9)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  87 : ATTRIBUTE_TIMESTAMP10 (ÇÁîñ_À²Ñ½ÀÝÌß10)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  88 : ATTRIBUTE_NUMBER1 (ÇÁîñ_Ô1)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  89 : ATTRIBUTE_NUMBER2 (ÇÁîñ_Ô2)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  90 : ATTRIBUTE_NUMBER3 (ÇÁîñ_Ô3)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  91 : ATTRIBUTE_NUMBER4 (ÇÁîñ_Ô4)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  92 : ATTRIBUTE_NUMBER5 (ÇÁîñ_Ô5)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  93 : ATTRIBUTE_NUMBER6 (ÇÁîñ_Ô6)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  94 : ATTRIBUTE_NUMBER7 (ÇÁîñ_Ô7)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  95 : ATTRIBUTE_NUMBER8 (ÇÁîñ_Ô8)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  96 : ATTRIBUTE_NUMBER9 (ÇÁîñ_Ô9)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  97 : ATTRIBUTE_NUMBER10 (ÇÁîñ_Ô10)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  98 : GLOBAL_ATTRIBUTE_CATEGORY (ÇÁîñJeS)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  99 : GLOBAL_ATTRIBUTE1 (ÇÁîñ1)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 100 : GLOBAL_ATTRIBUTE2 (ÇÁîñ2)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 101 : GLOBAL_ATTRIBUTE3 (ÇÁîñ3)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 102 : GLOBAL_ATTRIBUTE4 (ÇÁîñ4)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 103 : GLOBAL_ATTRIBUTE5 (ÇÁîñ5)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 104 : GLOBAL_ATTRIBUTE6 (ÇÁîñ6)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 105 : GLOBAL_ATTRIBUTE7 (ÇÁîñ7)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 106 : GLOBAL_ATTRIBUTE8 (ÇÁîñ8)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 107 : GLOBAL_ATTRIBUTE9 (ÇÁîñ9)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 108 : GLOBAL_ATTRIBUTE10 (ÇÁîñ10)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 109 : GLOBAL_ATTRIBUTE11 (ÇÁîñ11)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 110 : GLOBAL_ATTRIBUTE12 (ÇÁîñ12)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 111 : GLOBAL_ATTRIBUTE13 (ÇÁîñ13)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 112 : GLOBAL_ATTRIBUTE14 (ÇÁîñ14)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 113 : GLOBAL_ATTRIBUTE15 (ÇÁîñ15)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 114 : GLOBAL_ATTRIBUTE16 (ÇÁîñ16)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 115 : GLOBAL_ATTRIBUTE17 (ÇÁîñ17)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 116 : GLOBAL_ATTRIBUTE18 (ÇÁîñ18)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 117 : GLOBAL_ATTRIBUTE19 (ÇÁîñ19)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 118 : GLOBAL_ATTRIBUTE20 (ÇÁîñ20)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 119 : GLOBAL_ATTRIBUTE_DATE1 (ÇÁîñ_út1)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 120 : GLOBAL_ATTRIBUTE_DATE2 (ÇÁîñ_út2)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 121 : GLOBAL_ATTRIBUTE_DATE3 (ÇÁîñ_út3)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 122 : GLOBAL_ATTRIBUTE_DATE4 (ÇÁîñ_út4)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 123 : GLOBAL_ATTRIBUTE_DATE5 (ÇÁîñ_út5)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 124 : GLOBAL_ATTRIBUTE_DATE6 (ÇÁîñ_út6)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 125 : GLOBAL_ATTRIBUTE_DATE7 (ÇÁîñ_út7)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 126 : GLOBAL_ATTRIBUTE_DATE8 (ÇÁîñ_út8)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 127 : GLOBAL_ATTRIBUTE_DATE9 (ÇÁîñ_út9)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 128 : GLOBAL_ATTRIBUTE_DATE10 (ÇÁîñ_út10)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 129 : GLOBAL_ATTRIBUTE_TIMESTAMP1 (ÇÁîñ_À²Ñ½ÀÝÌß1)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 130 : GLOBAL_ATTRIBUTE_TIMESTAMP2 (ÇÁîñ_À²Ñ½ÀÝÌß2)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 131 : GLOBAL_ATTRIBUTE_TIMESTAMP3 (ÇÁîñ_À²Ñ½ÀÝÌß3)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 132 : GLOBAL_ATTRIBUTE_TIMESTAMP4 (ÇÁîñ_À²Ñ½ÀÝÌß4)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 133 : GLOBAL_ATTRIBUTE_TIMESTAMP5 (ÇÁîñ_À²Ñ½ÀÝÌß5)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 134 : GLOBAL_ATTRIBUTE_TIMESTAMP6 (ÇÁîñ_À²Ñ½ÀÝÌß6)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 135 : GLOBAL_ATTRIBUTE_TIMESTAMP7 (ÇÁîñ_À²Ñ½ÀÝÌß7)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 136 : GLOBAL_ATTRIBUTE_TIMESTAMP8 (ÇÁîñ_À²Ñ½ÀÝÌß8)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 137 : GLOBAL_ATTRIBUTE_TIMESTAMP9 (ÇÁîñ_À²Ñ½ÀÝÌß9)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 138 : GLOBAL_ATTRIBUTE_TIMESTAMP10 (ÇÁîñ_À²Ñ½ÀÝÌß10)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 139 : GLOBAL_ATTRIBUTE_NUMBER1 (ÇÁîñ_Ô1)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 140 : GLOBAL_ATTRIBUTE_NUMBER2 (ÇÁîñ_Ô2)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 141 : GLOBAL_ATTRIBUTE_NUMBER3 (ÇÁîñ_Ô3)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 142 : GLOBAL_ATTRIBUTE_NUMBER4 (ÇÁîñ_Ô4)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 143 : GLOBAL_ATTRIBUTE_NUMBER5 (ÇÁîñ_Ô5)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 144 : GLOBAL_ATTRIBUTE_NUMBER6 (ÇÁîñ_Ô6)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 145 : GLOBAL_ATTRIBUTE_NUMBER7 (ÇÁîñ_Ô7)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 146 : GLOBAL_ATTRIBUTE_NUMBER8 (ÇÁîñ_Ô8)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 147 : GLOBAL_ATTRIBUTE_NUMBER9 (ÇÁîñ_Ô9)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 148 : GLOBAL_ATTRIBUTE_NUMBER10 (ÇÁîñ_Ô10)
-- Ver1.5 Mod Start
--    lv_file_data := lv_file_data || cv_comma || NULL;               -- 149 : Batch ID (ob`ID)
      lv_file_data := lv_file_data || cv_comma 
        || l_supplier_rec.batch_id;                                   -- 149 : Batch ID (ob`ID)
-- Ver1.5 Mod End
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 150 : Registry ID (o^ID)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 151 : Payee Service Level ()
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 152 : Pay Each Document Alone ()
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 153 : Delivery Method ()
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 154 : Remittance E-mail ()
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 155 : Remittance Fax ()
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 156 : DataFox ID ()
      --
      BEGIN
        -- f[^sÌt@CoÍ
        UTL_FILE.PUT_LINE( gf_sup_file_handle
                         , lv_file_data
                         );
        --
        -- oÍJEgAbv
        gn_out_sup_cnt := gn_out_sup_cnt + 1;
      EXCEPTION
        WHEN OTHERS THEN
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
          lv_errbuf := lv_errmsg;
          RAISE global_process_expt;
      END;
      --
      -- ==============================================================
      -- OICdüæÞðe[uÌo^EXV
      -- ==============================================================
      IF ( l_supplier_rec.key_ins_upd_flag = cv_evac_create ) THEN
        -- Þðe[uo^EXVtOªCreateÌê
        BEGIN
          -- OICdüæÞðe[uÌo^
          INSERT INTO xxcmm_oic_vd_evac (
              vendor_id                      -- düæID
            , vendor_name                    -- düæ¼
            , created_by                     -- ì¬Ò
            , creation_date                  -- ì¬ú
            , last_updated_by                -- ÅIXVÒ
            , last_update_date               -- ÅIXVú
            , last_update_login              -- ÅIXVOC
            , request_id                     -- vID
            , program_application_id         -- RJgEvOEAvP[VID
            , program_id                     -- RJgEvOID
            , program_update_date            -- vOXVú
          ) VALUES (
              l_supplier_rec.vendor_id       -- düæID
            , l_supplier_rec.pv_vendor_name  -- düæ¼
            , cn_created_by                  -- ì¬Ò
            , cd_creation_date               -- ì¬ú
            , cn_last_updated_by             -- ÅIXVÒ
            , cd_last_update_date            -- ÅIXVú
            , cn_last_update_login           -- ÅIXVOC
            , cn_request_id                  -- vID
            , cn_program_application_id      -- RJgEvOEAvP[VID
            , cn_program_id                  -- RJgEvOID
            , cd_program_update_date         -- vOXVú
          );
        EXCEPTION
          WHEN OTHERS THEN
            -- o^É¸sµ½ê
            lv_errmsg := SUBSTRB(
                           xxccp_common_pkg.get_msg(
                             iv_application  => cv_appl_xxcmm             -- AvP[VZk¼FXXCMM
                           , iv_name         => cv_insert_err_msg         -- bZ[W¼F}üG[bZ[W
                           , iv_token_name1  => cv_tkn_table              -- g[N¼1FTABLE
                           , iv_token_value1 => cv_oic_sup_evac_tbl_msg   -- g[Nl1FOICdüæÞðe[u
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
      ELSIF ( l_supplier_rec.key_ins_upd_flag = cv_evac_update ) THEN
        -- Þðe[uo^EXVtOªUpdateÌê
        BEGIN
          -- OICdüæÞðe[uÌXV
          UPDATE
              xxcmm_oic_vd_evac  xove  -- OICdüæÞðe[u
          SET
              xove.vendor_name            = l_supplier_rec.pv_vendor_name  -- düæ¼
            , xove.last_update_date       = cd_last_update_date            -- ÅIXVú
            , xove.last_updated_by        = cn_last_updated_by             -- ÅIXVÒ
            , xove.last_update_login      = cn_last_update_login           -- ÅIXVOC
            , xove.request_id             = cn_request_id                  -- vID
            , xove.program_application_id = cn_program_application_id      -- vOAvP[VID
            , xove.program_id             = cn_program_id                  -- vOID
            , xove.program_update_date    = cd_program_update_date         -- vOXVú
          WHERE
              xove.vendor_id              = l_supplier_rec.vendor_id       -- düæID
          ;
        EXCEPTION
          WHEN OTHERS THEN
            -- XVÉ¸sµ½ê
            lv_errmsg := SUBSTRB(
                           xxccp_common_pkg.get_msg(
                             iv_application  => cv_appl_xxcmm             -- AvP[VZk¼FXXCMM
                           , iv_name         => cv_update_err_msg         -- bZ[W¼FXVG[bZ[W
                           , iv_token_name1  => cv_tkn_table              -- g[N¼1FTABLE
                           , iv_token_value1 => cv_oic_sup_evac_tbl_msg   -- g[Nl1FOICdüæÞðe[u
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
        -- XVÉ¬÷µ½êAXVOÆXVãÌdüæ¼ðoÍ
        lv_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_appl_xxcmm                      -- AvP[VZk¼FXXCMM
                  , iv_name         => cv_evac_data_out_msg               -- bZ[W¼FÞðîñXVoÍbZ[W
                  , iv_token_name1  => cv_tkn_table                       -- g[N¼1FTABLE
                  , iv_token_value1 => cv_oic_sup_evac_tbl_msg            -- g[Nl1FOICdüæÞðe[u
                  , iv_token_name2  => cv_tkn_id                          -- g[N¼2FID
                  , iv_token_value2 => TO_CHAR(l_supplier_rec.vendor_id)  -- g[Nl2FdüæID
                  , iv_token_name3  => cv_tkn_before_value                -- g[N¼3FBEFORE_VALUE
                  , iv_token_value3 => l_supplier_rec.xove_vendor_name    -- g[Nl3Fdüæ¼iÞðe[uj
                  , iv_token_name4  => cv_tkn_after_value                 -- g[N¼4FAFTER_VALUE
                  , iv_token_value4 => l_supplier_rec.pv_vendor_name      -- g[Nl4Fdüæ¼i}X^j
                  );
        --
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
        , buff   => lv_msg
        );
      END IF;
    --
    END LOOP output_supplier_loop;
--
    -- J[\N[Y
    CLOSE supplier_cur;
--
    -- ÞðîñXVoÍbZ[WðoÍµÄ¢éê
    IF ( lv_msg IS NOT NULL ) THEN
      -- ós}ü
      FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => ''
      );
    END IF;
--
  EXCEPTION
--
    -- *** bNG[áOnh ***
    WHEN global_lock_expt THEN
      -- J[\N[Y
      IF ( supplier_cur%ISOPEN ) THEN
        CLOSE supplier_cur;
      END IF;
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_xxcmm             -- AvP[VZk¼FXXCMM
                   , iv_name         => cv_lock_err_msg           -- bZ[W¼FbNG[bZ[W
                   , iv_token_name1  => cv_tkn_ng_table           -- g[N¼1FNG_TABLE
                   , iv_token_value1 => cv_oic_sup_evac_tbl_msg   -- g[Nl1Fe[u¼FOICdüæÞðe[u
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
      IF ( supplier_cur%ISOPEN ) THEN
        CLOSE supplier_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ¤ÊÖáOnh ***
    WHEN global_api_expt THEN
      -- J[\N[Y
      IF ( supplier_cur%ISOPEN ) THEN
        CLOSE supplier_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ¤ÊÖOTHERSáOnh ***
    WHEN global_api_others_expt THEN
      -- J[\N[Y
      IF ( supplier_cur%ISOPEN ) THEN
        CLOSE supplier_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERSáOnh ***
    WHEN OTHERS THEN
      -- J[\N[Y
      IF ( supplier_cur%ISOPEN ) THEN
        CLOSE supplier_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  Åè END   ##########################################
--
  END output_supplier;
--
--
  /**********************************************************************************
   * Procedure Name   : output_sup_addr
   * Description      : uATvCEZvAgf[^ÌoEt@CoÍ(A-3)
   ***********************************************************************************/
  PROCEDURE output_sup_addr(
    ov_errbuf     OUT VARCHAR2,     --   G[EbZ[W           --# Åè #
    ov_retcode    OUT VARCHAR2,     --   ^[ER[h             --# Åè #
    ov_errmsg     OUT VARCHAR2)     --   [U[EG[EbZ[W --# Åè #
  IS
    -- ===============================
    -- Åè[Jè
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'output_sup_addr';       -- vO¼
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
    lv_file_data         VARCHAR2(30000) DEFAULT NULL;       -- oÍàe
--
    -- *** [JEJ[\ ***
    -- uATvCEZvÌoJ[\
    CURSOR sup_addr_cur
    IS
      SELECT
          (CASE
             WHEN (    gt_pre_process_date IS NULL
                   OR  pv.creation_date > gt_pre_process_date) THEN
               cv_status_create
             ELSE
               cv_status_update
           END)                                          AS status_code                -- Xe[^XER[h
        , pv.vendor_name                                 AS vendor_name                -- düæ¼
        , (CASE
              WHEN xovse.vendor_site_id IS NOT NULL THEN
                xovse.vendor_site_code
              ELSE
                pvsa.vendor_site_code
           END)                                          AS vendor_site_code           -- düæTCgR[h
        , (CASE
             WHEN (xovse.vendor_site_id IS NOT NULL
                   AND xovse.vendor_site_code <> pvsa.vendor_site_code) THEN
               pvsa.vendor_site_code
             ELSE
               NULL
           END)                                          AS new_vendor_site_code       -- VdüæTCgR[h
-- Ver1.2 Mod Start
--        , pvsa.country                                   AS country                    -- 
        , NVL(pvsa.country, cv_jp)                       AS country                    -- 
-- Ver1.2 Mod End
-- Ver1.2 Mod Start
--        , pvsa.address_line1                             AS address_line1              -- Z1
        , NVL(pvsa.address_line1 ,cv_ast)                AS address_line1              -- Z1
-- Ver1.2 Mod End
        , pvsa.address_line2                             AS address_line2              -- Z2
        , pvsa.address_line3                             AS address_line3              -- Z3
        , pvsa.address_line4                             AS address_line4              -- Z4
        , pvsa.address_lines_alt                         AS address_lines_alt          -- ZJi
        , pvsa.city                                      AS city                       -- s
        , pvsa.state                                     AS state                      -- B
        , pvsa.province                                  AS province                   -- s¹{§
        , pvsa.county                                    AS county                     -- S
-- Ver1.2 Mod Start
--        , pvsa.zip                                       AS zip                        -- XÖÔ
        , NVL(pvsa.zip ,cv_ast)                          AS zip                        -- XÖÔ
-- Ver1.2 Mod End
        , TO_CHAR(pvsa.inactive_date, cv_date_fmt)       AS inactive_date              -- ³øú
        , pvsa.area_code                                 AS area_code                  -- sOÇÔ
        , pvsa.phone                                     AS phone                      -- dbÔ
        , pvsa.fax_area_code                             AS fax_area_code              -- FAXsOÇÔ
        , pvsa.fax                                       AS fax                        -- FAXÔ
        , pvsa.rfq_only_site_flag                        AS rfq_only_site_flag         -- TCggpF©ÏÌÝ
        , pvsa.purchasing_site_flag                      AS purchasing_site_flag       -- TCggpFw
-- Ver1.3 Mod Start
--        , pvsa.pay_site_flag                             AS pay_site_flag              -- TCggpFx¥
        , (CASE
             WHEN (    NVL(pvsa.pay_site_flag        , cv_n) = cv_n
                   AND NVL(pvsa.rfq_only_site_flag   , cv_n) = cv_n
                   AND NVL(pvsa.purchasing_site_flag , cv_n) = cv_n) THEN
               cv_y
             ELSE
               pvsa.pay_site_flag
           END)                                          AS pay_site_flag              -- TCggpFx¥
-- Ver1.3 Mod End
        , pvsa.email_address                             AS email_address              -- dq[AhX
-- Ver1.5 Add Start
        , (CASE 
            WHEN ( gt_pre_process_date IS NULL ) THEN 
-- Ver1.9 Mod Start
--              TO_CHAR( gt_cur_process_date , cv_datetime_id_fmt ) || MOD( pv.vendor_id , cn_divisor_ten )
              TO_CHAR( gt_cur_process_date , cv_datetime_id_fmt ) || MOD( pv.vendor_id , gn_parallel_num )
-- Ver1.9 Mod End
            ELSE
              NULL
          END)                                           AS batch_id                   -- ob`ID
-- Ver1.5 Add End
      FROM
          po_vendor_sites_all     pvsa   -- düæTCg
        , po_vendors              pv     -- düæ}X^
        , xxcmm_oic_vd_site_evac  xovse  -- OICdüæTCgÞðe[u
      WHERE
          (   gt_pre_process_date IS NULL
-- Ver1.11 Mod Start
--           OR pvsa.last_update_date > gt_pre_process_date)
           OR (    pvsa.last_update_date > gt_pre_process_date
               AND pvsa.last_update_date <= gt_cur_process_date)
           )
-- Ver1.11 Mod End
      AND pvsa.org_id         = gt_target_organization_id
      AND pvsa.vendor_id      = pv.vendor_id
      AND NVL(pv.vendor_type_lookup_code, 'X') <> cv_employee
      AND pvsa.vendor_site_id = xovse.vendor_site_id (+)
      ORDER BY
          pv.segment1           ASC  -- düæÔ
        , pvsa.vendor_site_code ASC  -- düæTCgR[h
    ;
--
    -- *** [JER[h ***
    -- uATvCEZvÌoJ[\R[h
    l_sup_addr_rec     sup_addr_cur%ROWTYPE;
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
    -- uATvCEZvÌo
    -- ==============================================================
    -- J[\I[v
    OPEN  sup_addr_cur;
    <<output_sup_addr_loop>>
    LOOP
      --
      FETCH sup_addr_cur INTO l_sup_addr_rec;
      EXIT WHEN sup_addr_cur%NOTFOUND;
      --
      -- oJEgAbv
      gn_get_sup_addr_cnt := gn_get_sup_addr_cnt + 1;
      --
      -- ==============================================================
      -- uATvCEZvÌt@CoÍ
      -- ==============================================================
      -- f[^sÌì¬
      lv_file_data := l_sup_addr_rec.status_code;                     --   1 : Import Action * (Xe[^XER[h)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string(
-- Ver1.6 Mod Start
--                        l_sup_addr_rec.vendor_name
                        xxccp_oiccommon_pkg.trim_space_tab(l_sup_addr_rec.vendor_name)
-- Ver1.6 Mod End
                      , l_sup_addr_rec.status_code
                      );                                              --   2 : Supplier Name* (TvC¼Ì)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string(
-- Ver1.6 Mod Start
--                        l_sup_addr_rec.vendor_site_code
                        xxccp_oiccommon_pkg.trim_space_tab(l_sup_addr_rec.vendor_site_code)
-- Ver1.6 Mod End
                      , l_sup_addr_rec.status_code
                      );                                              --   3 : Address Name * (Z¼)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string(
-- Ver1.6 Mod Start
--                        l_sup_addr_rec.new_vendor_site_code
                        xxccp_oiccommon_pkg.trim_space_tab(l_sup_addr_rec.new_vendor_site_code)
-- Ver1.6 Mod End
-- Ver1.3 Del Start(ÖAÎ)
--                      , l_sup_addr_rec.status_code
-- Ver1.3 Del End
                      );                                              --   4 : Address Name New (Z¼)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string(
                        l_sup_addr_rec.country
                      , l_sup_addr_rec.status_code
                      );                                              --   5 : Country ()
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string(
                        l_sup_addr_rec.address_line1
                      , l_sup_addr_rec.status_code
                      );                                              --   6 : Address Line 1 (Z1)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string(
                        l_sup_addr_rec.address_line2
                      , l_sup_addr_rec.status_code
                      );                                              --   7 : Address Line 2 (Z2)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string(
                        l_sup_addr_rec.address_line3
                      , l_sup_addr_rec.status_code
                      );                                              --   8 : Address Line 3 (Z3)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string(
                        l_sup_addr_rec.address_line4
                      , l_sup_addr_rec.status_code
                      );                                              --   9 : Address Line 4 (Z4)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string(
                        l_sup_addr_rec.address_lines_alt
                      , l_sup_addr_rec.status_code
                      );                                              --  10 : Phonetic Address Line (JiZ)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  11 : Address Element Attribute 1 (ZÇÁîñ1)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  12 : Address Element Attribute 2 (ZÇÁîñ2)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  13 : Address Element Attribute 3 (ZÇÁîñ3)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  14 : Address Element Attribute 4 (ZÇÁîñ4)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  15 : Address Element Attribute 5 (ZÇÁîñ5)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  16 : Building (¨¼)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  17 : Floor Number (tAÔ)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string(
                        l_sup_addr_rec.city
                      , l_sup_addr_rec.status_code
                      );                                              --  18 : City (sæ¬º)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string(
                        l_sup_addr_rec.state
                      , l_sup_addr_rec.status_code
                      );                                              --  19 : State (B)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string(
                        l_sup_addr_rec.province
                      , l_sup_addr_rec.status_code
                      );                                              --  20 : Province (s¹{§)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string(
                        l_sup_addr_rec.county
                      , l_sup_addr_rec.status_code
                      );                                              --  21 : County (S)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string(
                        l_sup_addr_rec.zip
                      , l_sup_addr_rec.status_code
                      );                                              --  22 : Postal code (XÖÔ)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  23 : Postal Plus 4 code (ÇÁXÖÔ)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  24 : Addressee (¼¶l)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  25 : Global Location Number (O[onæîñ)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  26 : Language (¾ê)
      lv_file_data := lv_file_data || cv_comma || 
                      nvl_by_status_code(
                        l_sup_addr_rec.inactive_date
                      , l_sup_addr_rec.status_code
                      );                                              --  27 : Inactive Date (ñANeBuú)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  28 : Phone Country Code (dbR[h)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string(
                        l_sup_addr_rec.area_code
                      , l_sup_addr_rec.status_code
                      );                                              --  29 : Phone Area Code (dbsOÇÔ)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string(
                        l_sup_addr_rec.phone
                      , l_sup_addr_rec.status_code
                      );                                              --  30 : Phone (dbÔ)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  31 : Phone Extension (dbÔàü)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  32 : Fax Country Code (FAXR[h)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string(
                        l_sup_addr_rec.fax_area_code
                      , l_sup_addr_rec.status_code
                      );                                              --  33 : Fax Area Code (FAXsOÇÔ)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string(
                        l_sup_addr_rec.fax
                      , l_sup_addr_rec.status_code
                      );                                              --  34 : Fax (FAXÔ)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string(
                        l_sup_addr_rec.rfq_only_site_flag
                      , l_sup_addr_rec.status_code
                      , cv_n
                      , cv_n
                      );                                              --  35 : RFQ Or Bidding (yZÚIz©ÏËÜ½ÍüD)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string(
                        l_sup_addr_rec.purchasing_site_flag
                      , l_sup_addr_rec.status_code
                      , cv_n
                      , cv_n
                      );                                              --  36 : Ordering (yZÚIzI[_[)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string(
                        l_sup_addr_rec.pay_site_flag
                      , l_sup_addr_rec.status_code
                      , cv_n
                      , cv_n
                      );                                              --  37 : Pay (yZÚIzàæ)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  38 : ATTRIBUTE_CATEGORY (ÇÁJeS)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  39 : ATTRIBUTE1 (ÇÁîñ1)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  40 : ATTRIBUTE2 (ÇÁîñ2)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  41 : ATTRIBUTE3 (ÇÁîñ3)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  42 : ATTRIBUTE4 (ÇÁîñ4)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  43 : ATTRIBUTE5 (ÇÁîñ5)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  44 : ATTRIBUTE6 (ÇÁîñ6)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  45 : ATTRIBUTE7 (ÇÁîñ7)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  46 : ATTRIBUTE8 (ÇÁîñ8)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  47 : ATTRIBUTE9 (ÇÁîñ9)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  48 : ATTRIBUTE10 (ÇÁîñ10)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  49 : ATTRIBUTE11 (ÇÁîñ11)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  50 : ATTRIBUTE12 (ÇÁîñ12)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  51 : ATTRIBUTE13 (ÇÁîñ13)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  52 : ATTRIBUTE14 (ÇÁîñ14)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  53 : ATTRIBUTE15 (ÇÁîñ15)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  54 : ATTRIBUTE16 (ÇÁîñ16)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  55 : ATTRIBUTE17 (ÇÁîñ17)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  56 : ATTRIBUTE18 (ÇÁîñ18)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  57 : ATTRIBUTE19 (ÇÁîñ19)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  58 : ATTRIBUTE20 (ÇÁîñ20)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  59 : ATTRIBUTE21 (ÇÁîñ21)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  60 : ATTRIBUTE22 (ÇÁîñ22)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  61 : ATTRIBUTE23 (ÇÁîñ23)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  62 : ATTRIBUTE24 (ÇÁîñ24)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  63 : ATTRIBUTE25 (ÇÁîñ25)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  64 : ATTRIBUTE26 (ÇÁîñ26)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  65 : ATTRIBUTE27 (ÇÁîñ27)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  66 : ATTRIBUTE28 (ÇÁîñ28)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  67 : ATTRIBUTE29 (ÇÁîñ29)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  68 : ATTRIBUTE30 (ÇÁîñ30)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  69 : ATTRIBUTE_NUMBER1 (ÇÁÔ1)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  70 : ATTRIBUTE_NUMBER2 (ÇÁÔ2)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  71 : ATTRIBUTE_NUMBER3 (ÇÁÔ3)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  72 : ATTRIBUTE_NUMBER4 (ÇÁÔ4)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  73 : ATTRIBUTE_NUMBER5 (ÇÁÔ5)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  74 : ATTRIBUTE_NUMBER6 (ÇÁÔ6)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  75 : ATTRIBUTE_NUMBER7 (ÇÁÔ7)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  76 : ATTRIBUTE_NUMBER8 (ÇÁÔ8)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  77 : ATTRIBUTE_NUMBER9 (ÇÁÔ9)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  78 : ATTRIBUTE_NUMBER10 (ÇÁÔ10)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  79 : ATTRIBUTE_NUMBER11 (ÇÁÔ11)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  80 : ATTRIBUTE_NUMBER12 (ÇÁÔ12)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  81 : ATTRIBUTE_DATE1 (ÇÁút1)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  82 : ATTRIBUTE_DATE2 (ÇÁút2)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  83 : ATTRIBUTE_DATE3 (ÇÁút3)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  84 : ATTRIBUTE_DATE4 (ÇÁút4)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  85 : ATTRIBUTE_DATE5 (ÇÁút5)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  86 : ATTRIBUTE_DATE6 (ÇÁút6)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  87 : ATTRIBUTE_DATE7 (ÇÁút7)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  88 : ATTRIBUTE_DATE8 (ÇÁút8)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  89 : ATTRIBUTE_DATE9 (ÇÁút9)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  90 : ATTRIBUTE_DATE10 (ÇÁút10)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  91 : ATTRIBUTE_DATE11 (ÇÁút11)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  92 : ATTRIBUTE_DATE12 (ÇÁút12)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string(
                        l_sup_addr_rec.email_address
                      , l_sup_addr_rec.status_code
                      );                                              --  93 : E-Mail (dq[AhX)
-- Ver1.5 Mod Start
--      lv_file_data := lv_file_data || cv_comma || NULL;               --  94 : Batch ID (ob`ID)
      lv_file_data := lv_file_data || cv_comma || 
                      l_sup_addr_rec.batch_id;                        --  94 : Batch ID (ob`ID)
-- Ver1.5 Mod End
      lv_file_data := lv_file_data || cv_comma || NULL;               --  95 : Delivery Channel (Ï`l)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  96 : Bank Instruction 1 (âsw}1)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  97 : Bank Instruction 2 (âsw}2)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  98 : Bank Instruction (âsw}Ú×)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  99 : Settlement Priority (¸ZDæx)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 100 : Payment Text Message 1 (x¥eLXgEbZ[W1)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 101 : Payment Text Message 2 (x¥eLXgEbZ[W2)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 102 : Payment Text Message 3 (x¥eLXgEbZ[W3)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 103 : Payee Service Level (óælT[rXx)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 104 : Pay Each Document Alone (PÆx¥)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 105 : Bank Charge Bearer (âsè¿SÒ)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 106 : Payment Reason (x¥R)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 107 : Payment Reason Comments (x¥RRg)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 108 : Delivery Method (Êmû@)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 109 : Remittance E-Mail (tæE-MailAhX)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 110 : Remittance Fax (tæFAX)
      --
      BEGIN
        -- f[^sÌt@CoÍ
        UTL_FILE.PUT_LINE( gf_sup_addr_file_handle
                         , lv_file_data
                         );
        --
        -- oÍJEgAbv
        gn_out_sup_addr_cnt := gn_out_sup_addr_cnt + 1;
      EXCEPTION
        WHEN OTHERS THEN
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
          lv_errbuf := lv_errmsg;
          RAISE global_process_expt;
      END;
    --
    END LOOP output_sup_addr_loop;
--
    -- J[\N[Y
    CLOSE sup_addr_cur;
--
  EXCEPTION
--
--#################################  ÅèáO START   ####################################
--
    -- *** ¤ÊáOnh ***
    WHEN global_process_expt THEN
      -- J[\N[Y
      IF ( sup_addr_cur%ISOPEN ) THEN
        CLOSE sup_addr_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ¤ÊÖáOnh ***
    WHEN global_api_expt THEN
      -- J[\N[Y
      IF ( sup_addr_cur%ISOPEN ) THEN
        CLOSE sup_addr_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ¤ÊÖOTHERSáOnh ***
    WHEN global_api_others_expt THEN
      -- J[\N[Y
      IF ( sup_addr_cur%ISOPEN ) THEN
        CLOSE sup_addr_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERSáOnh ***
    WHEN OTHERS THEN
      -- J[\N[Y
      IF ( sup_addr_cur%ISOPEN ) THEN
        CLOSE sup_addr_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  Åè END   ##########################################
--
  END output_sup_addr;
--
--
  /**********************************************************************************
   * Procedure Name   : output_sup_site
   * Description      : uBTvCETCgvAgf[^ÌoEt@CoÍ(A-4)
   ***********************************************************************************/
  PROCEDURE output_sup_site(
    ov_errbuf     OUT VARCHAR2,     --   G[EbZ[W           --# Åè #
    ov_retcode    OUT VARCHAR2,     --   ^[ER[h             --# Åè #
    ov_errmsg     OUT VARCHAR2)     --   [U[EG[EbZ[W --# Åè #
  IS
    -- ===============================
    -- Åè[Jè
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'output_sup_site';       -- vO¼
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
    lv_file_data         VARCHAR2(30000) DEFAULT NULL;       -- oÍàe
--
    -- *** [JEJ[\ ***
    -- uBTvCETCgvÌoJ[\
    CURSOR sup_site_cur
    IS
      SELECT
          (CASE
             WHEN (    gt_pre_process_date IS NULL
                   OR  pvsa.creation_date > gt_pre_process_date) THEN
               cv_status_create
             ELSE
               cv_status_update
           END)                                          AS status_code                     -- Xe[^XER[h
        , pv.vendor_name                                 AS vendor_name                     -- düæ¼
        , (CASE
             WHEN (    gt_pre_process_date IS NULL
                   OR  pvsa.creation_date > gt_pre_process_date) THEN
               pvsa.vendor_site_code
             ELSE
               NULL
           END)                                          AS vendor_site_code_new            -- düæTCgR[h(VK)
        , (CASE
             WHEN xovse.vendor_site_id IS NOT NULL THEN
               xovse.vendor_site_code
             ELSE
               pvsa.vendor_site_code
           END)                                          AS vendor_site_code                -- düæTCgR[h
        , (CASE
             WHEN (xovse.vendor_site_id IS NOT NULL
                   AND xovse.vendor_site_code <> pvsa.vendor_site_code) THEN
               pvsa.vendor_site_code
             ELSE
               NULL
           END)                                          AS new_vendor_site_code            -- VdüæTCgR[h
        , TO_CHAR(pvsa.inactive_date, cv_date_fmt)       AS inactive_date                   -- ³øú
        , pvsa.rfq_only_site_flag                        AS rfq_only_site_flag              -- TCggpF\[VOÌÝ
        , pvsa.purchasing_site_flag                      AS purchasing_site_flag            -- TCggpFw
-- Ver1.7 Mod Start
--        , pvsa.purchasing_site_flag                      AS procurement_site_flag           -- TCggpF²BJ[h
        , (CASE
             WHEN pvsa.purchasing_site_flag = cv_y THEN
               pvsa.pcard_site_flag
             ELSE
               cv_n
           END)                                          AS procurement_site_flag           -- TCggpF²BJ[h
-- Ver1.7 Mod End
-- Ver1.3 Mod Start
--        , pvsa.pay_site_flag                             AS pay_site_flag                   -- TCggpFx¥
        , (CASE
             WHEN (    NVL(pvsa.pay_site_flag        , cv_n) = cv_n
                   AND NVL(pvsa.rfq_only_site_flag   , cv_n) = cv_n
                   AND NVL(pvsa.purchasing_site_flag , cv_n) = cv_n) THEN
               cv_y
             ELSE
               pvsa.pay_site_flag
           END)                                          AS pay_site_flag              -- TCggpFx¥
-- Ver1.3 Mod End
        , pvsa.primary_pay_site_flag                     AS primary_pay_site_flag           -- TCggpFåx¥
        , pvsa.vendor_site_code_alt                      AS vendor_site_code_alt            -- düæTCgJi
        , pvsa.customer_num                              AS customer_num                    -- ÚqÔ
        , pvsa.supplier_notif_method                     AS supplier_notif_method           -- düæÊmû@
        , (CASE
             WHEN pvsa.supplier_notif_method = cv_email THEN
               pvsa.email_address
             ELSE
               NULL
           END)                                          AS email_address                   -- [AhX
        , (CASE
             WHEN pvsa.supplier_notif_method = cv_fax THEN
               pvsa.fax_area_code
             ELSE
               NULL
           END)                                          AS fax_area_code                   -- FAXsOÇÔ
        , (CASE
             WHEN pvsa.supplier_notif_method = cv_fax
               THEN pvsa.fax
             ELSE
               NULL
           END)                                          AS fax                             -- FAXÔ
        , pvsa.hold_reason                               AS hold_reason                     -- Û¯R
        , pvsa.ship_via_lookup_code                      AS ship_via_lookup_code            -- ^û@
-- Ver1.3 Del Start
--        , pvsa.freight_terms_lookup_code                 AS freight_terms_lookup_code       -- ^ðFw
-- Ver1.3 Del End
        , (CASE
             WHEN pvsa.pay_on_code = cv_receipt THEN
               cv_y
             ELSE
-- Ver1.4(E123) Mod Start
--               NULL
               cv_n
-- Ver1.4(E123) Mod End
           END)                                          AS pay_on_code                     -- óüx¥Ìx¥ú
        , pvsa.fob_lookup_code                           AS fob_lookup_code                 -- FOBR[h
--        , pvsa.country_of_origin_code                    AS country_of_origin_code          -- ´Y -- aÊmFÉsv»è
        , pvsa_pay.vendor_site_code                      AS pay_vendor_site_code            -- ftHgx¥TCg
-- Ver1.4(E123) Mod Start
--        , pvsa.pay_on_receipt_summary_code               AS pay_on_receipt_summary_code     -- óüx¥Ì¿vñx
        , (CASE
             WHEN pvsa.pay_on_code = cv_receipt THEN
               pvsa.pay_on_receipt_summary_code
             ELSE
               NULL
           END)                                          AS pay_on_receipt_summary_code     -- óüx¥Ì¿vñx
-- Ver1.4(E123) Mod End
--        , pvsa.gapless_inv_num_flag                      AS gapless_inv_num_flag            -- ÔÈµÌ¿ÌÔ -- aÊmFÉsv»è
-- Ver1.3 Del Start
--        , pvsa.selling_company_identifier                AS selling_company_identifier      -- ÌïÐ¯Êq
-- Ver1.3 Del End
        , pvsa.invoice_currency_code                     AS invoice_currency_code           -- ¿ÊÝ
        , pvsa.invoice_amount_limit                      AS invoice_amount_limit            -- ¿Àxz
        , pvsa.match_option                              AS match_option                    -- ¿ÆIvV
        , pvsa.payment_currency_code                     AS payment_currency_code           -- x¥ÊÝ
        , pvsa.payment_priority                          AS payment_priority                -- x¥Dæx
        , pvsa.hold_all_payments_flag                    AS hold_all_payments_flag          -- ·×ÄÌ¿ÌÛ¯
        , pvsa.hold_unmatched_invoices_flag              AS hold_unmatched_invoices_flag    -- ¢Æ¿ÌÛ¯
        , pvsa.hold_future_payments_flag                 AS hold_future_payments_flag       -- ¢Ø¿ÌÛ¯
        , pvsa.hold_reason                               AS pay_hold_reason                 -- x¥Û¯R
        , at.name                                        AS name                            -- x¥ð¼
        , pvsa.terms_date_basis                          AS terms_date_basis                -- x¥NZú
        , pvsa.pay_date_basis_lookup_code                AS pay_date_basis_lookup_code      -- x¥úúî
        , (CASE
             WHEN pvsa.bank_charge_bearer = cv_bearer_i THEN
               cv_bearer_x
             WHEN pvsa.bank_charge_bearer = cv_bearer_s THEN
               cv_bearer_s
             WHEN pvsa.bank_charge_bearer = cv_bearer_n THEN
               cv_bearer_n
             WHEN pvsa.bank_charge_bearer IS NULL THEN
               cv_bearer_d
          END)                                           AS bank_charge_bearer              -- âsè¿SÒ
        , pvsa.always_take_disc_flag                     AS always_take_disc_flag           -- øívã
        , pvsa.exclude_freight_from_discount             AS exclude_freight_from_discount   -- ø©ç^ïð­
        , pvsa.pay_group_lookup_code                     AS pay_group_lookup_code           -- x¥O[v
        , (CASE
             WHEN pvsa.remittance_email IS NOT NULL THEN
               cv_email
             ELSE
               NULL
           END)                                          AS remittance_notif_method         -- Êmû@
        , pvsa.remittance_email                          AS remittance_email                -- tæE-MailAhX
        , pvsa.attribute1                                AS pvsa_attribute1                 -- düæ³®¼Ì
        , pvsa.attribute2                                AS pvsa_attribute2                 -- x¥Êmû@
        , pvsa.attribute3                                AS pvsa_attribute3                 -- åüÍÅvZx
        , pvsa.attribute4                                AS pvsa_attribute4                 -- BMx¥æª
        , pvsa.attribute5                                AS pvsa_attribute5                 -- â¹S_R[h
        , pvsa.attribute6                                AS pvsa_attribute6                 -- BMÅæª
        , pvsa.attribute7                                AS pvsa_attribute7                 -- düæTCgE[AhX
-- Ver1.13 Add Start
        , pvsa.attribute8                                AS pvsa_attribute8                 -- Ki¿­sÆÒo^
        , pvsa.attribute9                                AS pvsa_attribute9                 -- ÛÅÆÒÔ
        , pvsa.attribute10                               AS pvsa_attribute10                -- ÅvZæª
        , pvsa.attribute11                               AS pvsa_attribute11                -- `[ì¬ïÐ
-- Ver1.13 Add End
        , pvsa.vendor_site_id                            AS vendor_site_id                  -- düæTCgID
        , pvsa.vendor_site_code                          AS pvsa_vendor_site_code           -- düæTCgR[hi}X^j
        , xovse.vendor_site_code                         AS xovse_vendor_site_code          -- düæTCgR[hiÞðe[uj
        , (CASE
             WHEN xovse.vendor_site_id IS NULL THEN
               cv_evac_create
             WHEN pvsa.vendor_site_code <> xovse.vendor_site_code THEN
               cv_evac_update
             ELSE
               NULL
           END)                                           AS key_ins_upd_flag                -- L[îño^EXVtO
-- Ver1.5 Add Start
        , (CASE 
            WHEN ( gt_pre_process_date IS NULL ) THEN 
-- Ver1.9 Mod Start
--              TO_CHAR( gt_cur_process_date , cv_datetime_id_fmt ) || MOD( pv.vendor_id , cn_divisor_ten )
              TO_CHAR( gt_cur_process_date , cv_datetime_id_fmt ) || MOD( pv.vendor_id , gn_parallel_num )
-- Ver1.9 Mod End
            ELSE
              NULL
          END)                                           AS batch_id                   -- ob`ID
-- Ver1.5 Add Start
      FROM
          po_vendor_sites_all     pvsa      -- düæTCg
        , po_vendors              pv        -- düæ}X^
        , xxcmm_oic_vd_site_evac  xovse     -- OICdüæTCgÞðe[u
        , po_vendor_sites_all     pvsa_pay  -- düæTCg_x¥
        , ap_terms                at        -- x¥ð
      WHERE
          (   gt_pre_process_date IS NULL
-- Ver1.11 Mod Start
--           OR pvsa.last_update_date > gt_pre_process_date)
           OR (    pvsa.last_update_date > gt_pre_process_date
               AND pvsa.last_update_date <= gt_cur_process_date)
           )
-- Ver1.11 Mod End
      AND pvsa.org_id              = gt_target_organization_id
      AND pvsa.vendor_id           = pv.vendor_id
      AND NVL(pv.vendor_type_lookup_code, 'X') <> cv_employee
      AND pvsa.vendor_site_id      = xovse.vendor_site_id (+)
      AND pvsa.default_pay_site_id = pvsa_pay.vendor_site_id (+)
      AND pvsa.terms_id            = at.term_id (+)
      ORDER BY
          pv.segment1           ASC  -- düæÔ
        , pvsa.vendor_site_code ASC  -- düæTCgR[h
      FOR UPDATE OF xovse.vendor_site_code NOWAIT  -- sbNFOICdüæTCgÞðe[u
    ;
--
    -- *** [JER[h ***
    -- uBTvCETCgvÌoJ[\R[h
    l_sup_site_rec     sup_site_cur%ROWTYPE;
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
    -- uBTvCETCgvÌo
    -- ==============================================================
    -- J[\I[v
    OPEN  sup_site_cur;
    <<output_sup_site_loop>>
    LOOP
      --
      FETCH sup_site_cur INTO l_sup_site_rec;
      EXIT WHEN sup_site_cur%NOTFOUND;
      --
      -- oJEgAbv
      gn_get_site_cnt := gn_get_site_cnt + 1;
      --
      -- ==============================================================
      -- uBTvCETCgvÌt@CoÍ
      -- ==============================================================
      -- f[^sÌì¬
      lv_file_data := l_sup_site_rec.status_code;                     --   1 : Import Action * (Xe[^XER[h)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string(
-- Ver1.6 Mod Start
--                        l_sup_site_rec.vendor_name
                        xxccp_oiccommon_pkg.trim_space_tab(l_sup_site_rec.vendor_name)
-- Ver1.6 Mod End
                      , l_sup_site_rec.status_code
                      );                                              --   2 : Supplier Name* (TvC¼Ì)
      lv_file_data := lv_file_data || cv_comma || cv_sales_bu;        --   3 : Procurement BU* (²BrWlXEjbg)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string(
-- Ver1.6 Mod Start
--                        l_sup_site_rec.vendor_site_code_new
                        xxccp_oiccommon_pkg.trim_space_tab(l_sup_site_rec.vendor_site_code_new)
-- Ver1.6 Mod End
-- Ver1.3 Del Start(ÖAÎ)
--                      , l_sup_site_rec.status_code
-- Ver1.3 Del End
                      );                                              --   4 : Address Name  (Z¼)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string(
-- Ver1.6 Mod Start
--                        l_sup_site_rec.vendor_site_code
                        xxccp_oiccommon_pkg.trim_space_tab(l_sup_site_rec.vendor_site_code)
-- Ver1.6 Mod End
                      , l_sup_site_rec.status_code
                      );                                              --   5 : Supplier Site* (TvCETCgR[h)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string(
-- Ver1.6 Mod Start
--                        l_sup_site_rec.new_vendor_site_code
                        xxccp_oiccommon_pkg.trim_space_tab(l_sup_site_rec.new_vendor_site_code)
-- Ver1.6 Mod End
-- Ver1.3 Del Start(ÖAÎ)
--                      , l_sup_site_rec.status_code
-- Ver1.3 Del End
                      );                                              --   6 : Supplier Site New (VTvCETCgR[h)
      lv_file_data := lv_file_data || cv_comma || 
                      nvl_by_status_code(
                        l_sup_site_rec.inactive_date
                      , l_sup_site_rec.status_code
                      );                                              --   7 : Inactive Date (ñANeBuú)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string(
                        l_sup_site_rec.rfq_only_site_flag
                      , l_sup_site_rec.status_code
                      , cv_n
                      , cv_n
                      );                                              --   8 : Sourcing only (yTCgÚIz\[VOÌÝ)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string(
                        l_sup_site_rec.purchasing_site_flag
                      , l_sup_site_rec.status_code
                      , cv_n
                      , cv_n
                      );                                              --   9 : Purchasing (yTCgÚIzw)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string(
                        l_sup_site_rec.procurement_site_flag
                      , l_sup_site_rec.status_code
                      , cv_n
                      , cv_n
                      );                                              --  10 : Procurement card (yTCgÚIz²BJ[h)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string(
                        l_sup_site_rec.pay_site_flag
                      , l_sup_site_rec.status_code
                      , cv_n
                      , cv_n
                      );                                              --  11 : Pay (yTCgÚIzx¥)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string(
                        l_sup_site_rec.primary_pay_site_flag
                      , l_sup_site_rec.status_code
                      , cv_n
                      , cv_n
                      );                                              --  12 : Primary Pay (yTCgÚIzvC}x¥)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  13 : Income tax reporting site (¾Å|[gTCg)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string(
                        l_sup_site_rec.vendor_site_code_alt
                      , l_sup_site_rec.status_code
                      );                                              --  14 : Alternate Site Name (TvCETCg(ãÖ¼))
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string(
                        l_sup_site_rec.customer_num
                      , l_sup_site_rec.status_code
                      );                                              --  15 : Customer Number (ÚqÔ)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  16 : Enable B2B Messaging (B2BÊMû@)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  17 : B2B Supplier Site Code (B2BTvCTCgR[h)"
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string(
                        l_sup_site_rec.supplier_notif_method
                      , l_sup_site_rec.status_code
                      );                                              --  18 : Communication Method (ÊMû@)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string(
                        l_sup_site_rec.email_address
                      , l_sup_site_rec.status_code
                      );                                              --  19 : E-Mail (E-MailAhX)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  20 : Fax Country Code (FAXR[h)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string(
                        l_sup_site_rec.fax_area_code
                      , l_sup_site_rec.status_code
                      );                                              --  21 : Fax Area Code (FAXsOÇÔ)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string(
                        l_sup_site_rec.fax
                      , l_sup_site_rec.status_code
                      );                                              --  22 : Fax (FAXÔ)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  23 : Hold all new purchasing documents (SVKw¶ÌÛ¯)
-- Ver1.3 Mod Start
--      lv_file_data := lv_file_data || cv_comma || 
--                      to_csv_string(
--                        l_sup_site_rec.hold_reason
--                      , l_sup_site_rec.status_code
--                      );                                              --  24 : Purchasing Hold Reason (Û¯R)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  24 : Purchasing Hold Reason (Û¯R)
-- Ver1.3 Mod End
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string(
                        l_sup_site_rec.ship_via_lookup_code
                      , l_sup_site_rec.status_code
                      );                                              --  25 : Carrier (o×û@)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  26 : Mode of Transport (Að)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  27 : Service Level (T[rXx)
-- Ver1.3 Mod Start
--      lv_file_data := lv_file_data || cv_comma || 
--                      to_csv_string(
--                        l_sup_site_rec.freight_terms_lookup_code
--                      , l_sup_site_rec.status_code
--                      );                                              --  28 : Freight Terms (^ð)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  28 : Freight Terms (^ð)
-- Ver1.3 Mod End
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string(
                        l_sup_site_rec.pay_on_code
                      , l_sup_site_rec.status_code
                      );                                              --  29 : Pay on receipt (óüx¥)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string(
                        l_sup_site_rec.fob_lookup_code
                      , l_sup_site_rec.status_code
                      );                                              --  30 : FOB (FOB)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  31 : Country of Origin (´Y)
      lv_file_data := lv_file_data || cv_comma || cv_n;               --  32 : Buyer Managed Transportation (Buyer Managed Transportation)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  33 : Pay on use (gpx¥)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  34 : Aging Onset Point (oßúÔJn_)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  35 : Aging Period Days (oßúÔú)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  36 : Consumption Advice Frequency (ÁïÊmpx)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  37 : Consumption Advice Summary (ÁïÊmvñ)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string(
-- Ver1.6 Mod Start
--                        l_sup_site_rec.pay_vendor_site_code
                        xxccp_oiccommon_pkg.trim_space_tab(l_sup_site_rec.pay_vendor_site_code)
-- Ver1.6 Mod End
                      , l_sup_site_rec.status_code
                      );                                              --  38 : Alternate Pay Site (ftHgx¥TCg)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string(
                        l_sup_site_rec.pay_on_receipt_summary_code
                      , l_sup_site_rec.status_code
                      );                                              --  39 : Invoice Summary Level (¿vñx)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  40 : Gapless invoice numbering (ÔÈµÌ¿ÌÔ)
-- Ver1.3 Mod Start
--      lv_file_data := lv_file_data || cv_comma || 
--                      to_csv_string(
--                        l_sup_site_rec.selling_company_identifier
--                      , l_sup_site_rec.status_code
--                      );                                              --  41 : Selling Company Identifier (ÌïÐ¯Êq)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  41 : Selling Company Identifier (ÌïÐ¯Êq)
-- Ver1.3 Mod End
      lv_file_data := lv_file_data || cv_comma || cv_y;               --  42 : Create debit memo from return (Ôi©çÌfrbgEÌì¬)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  43 : Ship-to Exception Action  (o×æáO)
      lv_file_data := lv_file_data || cv_comma || cv_level_3;         --  44 : Receipt Routing (óüoH)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  45 : Over-receipt Tolerance (´ßóüeÍÍ)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  46 : Over-receipt Action (´ßóü)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  47 : Early Receipt Tolerance in Days ([úOóüeú)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  48 : Late Receipt Tolerance in Days ([úãóüeú)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  49 : Allow Substitute Receipts (ãÖóüÌÂ)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  50 : Allow unordered receipts (¢I[_[óüÌÂ)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  51 : Receipt Date Exception (óüúáO)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string(
                        l_sup_site_rec.invoice_currency_code
                      , l_sup_site_rec.status_code
                      );                                              --  52 : Invoice Currency (¿ÊÝ)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string(
                        l_sup_site_rec.invoice_amount_limit
                      , l_sup_site_rec.status_code
                      );                                              --  53 : Invoice Amount Limit (¿Àxz)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string(
                        l_sup_site_rec.match_option
                      , l_sup_site_rec.status_code
                      );                                              --  54 : Invoice Match Option (¿ÆIvV)
      lv_file_data := lv_file_data || cv_comma || cv_level_3;         --  55 : Match Approval Level (Æ³Fx)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string(
                        l_sup_site_rec.payment_currency_code
                      , l_sup_site_rec.status_code
                      );                                              --  56 : Payment Currency (x¥ÊÝ)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string(
                        l_sup_site_rec.payment_priority
                      , l_sup_site_rec.status_code
                      );                                              --  57 : Payment Priority (x¥Dæx)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string(
                        gt_prf_val_dmy_sup_payment
                      , l_sup_site_rec.status_code
                      );                                              --  58 : Pay Group (x¥O[v)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  59 : Quantity Tolerances (ÊeÍÍ)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  60 : Amount Tolerance (àzeÍÍ)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string(
                        l_sup_site_rec.hold_all_payments_flag
                      , l_sup_site_rec.status_code
                      , cv_n
                      , cv_n
                      );                                              --  61 : Hold All Invoices (·×ÄÌ¿ÌÛ¯)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string(
                        l_sup_site_rec.hold_unmatched_invoices_flag
                      , l_sup_site_rec.status_code
                      , cv_n
                      , cv_n
                      );                                              --  62 : Hold Unmatched Invoices (¢Æ¿ÌÛ¯)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string(
                        l_sup_site_rec.hold_future_payments_flag
                      , l_sup_site_rec.status_code
                      , cv_n
                      , cv_n
                      );                                              --  63 : Hold Unvalidated Invoices (¢Ø¿ÌÛ¯)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  64 : Payment Hold By (x¥Û¯Ò)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  65 : Payment Hold Date (x¥Û¯µ½út)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string(
                        l_sup_site_rec.pay_hold_reason
                      , l_sup_site_rec.status_code
                      );                                              --  66 : Payment Hold Reason (x¥Û¯R)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string(
                        l_sup_site_rec.name
                      , l_sup_site_rec.status_code
                      );                                              --  67 : Payment Terms (x¥ð)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string(
                        l_sup_site_rec.terms_date_basis
                      , l_sup_site_rec.status_code
                      );                                              --  68 : Terms Date Basis (x¥NZú)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string(
                        l_sup_site_rec.pay_date_basis_lookup_code
                      , l_sup_site_rec.status_code
                      );                                              --  69 : Pay Date Basis (x¥úúî)
      lv_file_data := lv_file_data || cv_comma || 
                      l_sup_site_rec.bank_charge_bearer;              --  70 : Bank Charge Deduction Type (âsè¿T^Cv)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string(
                        l_sup_site_rec.always_take_disc_flag
                      , l_sup_site_rec.status_code
                      , cv_n
                      , cv_n
                      );                                              --  71 : Always Take Discount (øívã)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string(
                        l_sup_site_rec.exclude_freight_from_discount
                      , l_sup_site_rec.status_code
                      , cv_n
                      , cv_n
                      );                                              --  72 : Exclude Freight From Discount (ø©ç^ïð­)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  73 : Exclude Tax From Discount (ø©çÅàð­)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  74 : Create Interest Invoices (§¿Ìì¬)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  75 : Vat Code-Obsoleted (tÁ¿lÅR[h)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  76 : Tax Registration Number-Obsoleted (tÁ¿lÅo^Ô)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string(
                        l_sup_site_rec.pay_group_lookup_code
                      , l_sup_site_rec.status_code
                      );                                              --  77 : Payment Method (x¥û@)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  78 : Delivery Channel (Ï`l)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  79 : Bank Instruction 1 (âsw}1)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  80 : Bank Instruction 2 (âsw}2)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  81 : Bank Instruction (âsw}Ú×)
      lv_file_data := lv_file_data || cv_comma || cv_express;         --  82 : Settlement Priority (¸ZDæx)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  83 : Payment Text Message 1 (x¥eLXgbZ[W1)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  84 : Payment Text Message 2 (x¥eLXgbZ[W2)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  85 : Payment Text Message 3 (x¥eLXgbZ[W3)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  86 : Bank Charge Bearer (âsè¿SÒ)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  87 : Payment Reason (x¥R)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  88 : Payment Reason Comments (x¥RRg)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string(
                        l_sup_site_rec.remittance_notif_method
                      , l_sup_site_rec.status_code
                      );                                              --  89 : Delivery Method (Êmû@)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string(
                        l_sup_site_rec.remittance_email
                      , l_sup_site_rec.status_code
                      );                                              --  90 : Remittance E-Mail (tæE-MailAhX)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  91 : Remittance Fax (tæFAX)
      lv_file_data := lv_file_data || cv_comma || cv_sales_bu;        --  92 : ATTRIBUTE_CATEGORY (ÇÁîñJeS)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string(
                        l_sup_site_rec.pvsa_attribute1
                      , l_sup_site_rec.status_code
                      );                                              --  93 : ATTRIBUTE1idüæ³®¼Ìj
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string(
                        l_sup_site_rec.pvsa_attribute2
                      , l_sup_site_rec.status_code
                      );                                              --  94 : ATTRIBUTE2ix¥Êmû@j
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string(
                        l_sup_site_rec.pvsa_attribute3
                      , l_sup_site_rec.status_code
                      );                                              --  95 : ATTRIBUTE3iåüÍÅvZxj
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string(
                        l_sup_site_rec.pvsa_attribute4
                      , l_sup_site_rec.status_code
                      );                                              --  96 : ATTRIBUTE4iBMx¥æªj
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string(
                        l_sup_site_rec.pvsa_attribute5
                      , l_sup_site_rec.status_code
                      );                                              --  97 : ATTRIBUTE5iâ¹S_R[hj
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string(
                        l_sup_site_rec.pvsa_attribute6
                      , l_sup_site_rec.status_code
                      );                                              --  98 : ATTRIBUTE6iBMÅæªj
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string(
                        l_sup_site_rec.pvsa_attribute7
                      , l_sup_site_rec.status_code
                      );                                              --  99 : ATTRIBUTE7idüæTCgE[AhXj
-- Ver1.13 Mod Start
--      lv_file_data := lv_file_data || cv_comma || NULL;               -- 100 : ATTRIBUTE8 (ÇÁîñ8)
--      lv_file_data := lv_file_data || cv_comma || NULL;               -- 101 : ATTRIBUTE9 (ÇÁîñ9)
--      lv_file_data := lv_file_data || cv_comma || NULL;               -- 102 : ATTRIBUTE10 (ÇÁîñ10)
--      lv_file_data := lv_file_data || cv_comma || NULL;               -- 103 : ATTRIBUTE11 (ÇÁîñ11)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string(
                        l_sup_site_rec.pvsa_attribute8
                      , l_sup_site_rec.status_code
                      );                                              -- 100 : ATTRIBUTE8 (Ki¿­sÆÒo^)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string(
                        l_sup_site_rec.pvsa_attribute9
                      , l_sup_site_rec.status_code
                      );                                              -- 101 : ATTRIBUTE9 (ÛÅÆÒÔ)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string(
                        l_sup_site_rec.pvsa_attribute10
                      , l_sup_site_rec.status_code
                      );                                              -- 102 : ATTRIBUTE10 (ÅvZæª)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string(
                        l_sup_site_rec.pvsa_attribute11
                      , l_sup_site_rec.status_code
                      );                                              -- 103 : ATTRIBUTE11 (`[ì¬ïÐ)
-- Ver1.13 Mod End
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 104 : ATTRIBUTE12 (ÇÁîñ12)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 105 : ATTRIBUTE13 (ÇÁîñ13)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 106 : ATTRIBUTE14 (ÇÁîñ14)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 107 : ATTRIBUTE15 (ÇÁîñ15)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 108 : ATTRIBUTE16 (ÇÁîñ16)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 109 : ATTRIBUTE17 (ÇÁîñ17)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 110 : ATTRIBUTE18 (ÇÁîñ18)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 111 : ATTRIBUTE19 (ÇÁîñ19)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 112 : ATTRIBUTE20 (ÇÁîñ20)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 113 : ATTRIBUTE_DATE1 (ÇÁîñ_út1)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 114 : ATTRIBUTE_DATE2 (ÇÁîñ_út2)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 115 : ATTRIBUTE_DATE3 (ÇÁîñ_út3)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 116 : ATTRIBUTE_DATE4 (ÇÁîñ_út4)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 117 : ATTRIBUTE_DATE5 (ÇÁîñ_út5)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 118 : ATTRIBUTE_DATE6 (ÇÁîñ_út6)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 119 : ATTRIBUTE_DATE7 (ÇÁîñ_út7)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 120 : ATTRIBUTE_DATE8 (ÇÁîñ_út8)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 121 : ATTRIBUTE_DATE9 (ÇÁîñ_út9)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 122 : ATTRIBUTE_DATE10 (ÇÁîñ_út10)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 123 : ATTRIBUTE_TIMESTAMP1 (ÇÁîñ_À²Ñ½ÀÝÌß1)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 124 : ATTRIBUTE_TIMESTAMP2 (ÇÁîñ_À²Ñ½ÀÝÌß2)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 125 : ATTRIBUTE_TIMESTAMP3 (ÇÁîñ_À²Ñ½ÀÝÌß3)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 126 : ATTRIBUTE_TIMESTAMP4 (ÇÁîñ_À²Ñ½ÀÝÌß4)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 127 : ATTRIBUTE_TIMESTAMP5 (ÇÁîñ_À²Ñ½ÀÝÌß5)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 128 : ATTRIBUTE_TIMESTAMP6 (ÇÁîñ_À²Ñ½ÀÝÌß6)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 129 : ATTRIBUTE_TIMESTAMP7 (ÇÁîñ_À²Ñ½ÀÝÌß7)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 130 : ATTRIBUTE_TIMESTAMP8 (ÇÁîñ_À²Ñ½ÀÝÌß8)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 131 : ATTRIBUTE_TIMESTAMP9 (ÇÁîñ_À²Ñ½ÀÝÌß9)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 132 : ATTRIBUTE_TIMESTAMP10 (ÇÁîñ_À²Ñ½ÀÝÌß10)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 133 : ATTRIBUTE_NUMBER1 (ÇÁîñ_Ô1)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 134 : ATTRIBUTE_NUMBER2 (ÇÁîñ_Ô2)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 135 : ATTRIBUTE_NUMBER3 (ÇÁîñ_Ô3)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 136 : ATTRIBUTE_NUMBER4 (ÇÁîñ_Ô4)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 137 : ATTRIBUTE_NUMBER5 (ÇÁîñ_Ô5)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 138 : ATTRIBUTE_NUMBER6 (ÇÁîñ_Ô6)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 139 : ATTRIBUTE_NUMBER7 (ÇÁîñ_Ô7)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 140 : ATTRIBUTE_NUMBER8 (ÇÁîñ_Ô8)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 141 : ATTRIBUTE_NUMBER9 (ÇÁîñ_Ô9)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 142 : ATTRIBUTE_NUMBER10 (ÇÁîñ_Ô10)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 143 : GLOBAL_ATTRIBUTE_CATEGORY (¸ÞÛ°ÊÞÙÇÁîñJeS)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 144 : GLOBAL_ATTRIBUTE1 (¸ÞÛ°ÊÞÙÇÁîñ1)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 145 : GLOBAL_ATTRIBUTE2 (¸ÞÛ°ÊÞÙÇÁîñ2)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 146 : GLOBAL_ATTRIBUTE3 (¸ÞÛ°ÊÞÙÇÁîñ3)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 147 : GLOBAL_ATTRIBUTE4 (¸ÞÛ°ÊÞÙÇÁîñ4)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 148 : GLOBAL_ATTRIBUTE5 (¸ÞÛ°ÊÞÙÇÁîñ5)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 149 : GLOBAL_ATTRIBUTE6 (¸ÞÛ°ÊÞÙÇÁîñ6)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 150 : GLOBAL_ATTRIBUTE7 (¸ÞÛ°ÊÞÙÇÁîñ7)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 151 : GLOBAL_ATTRIBUTE8 (¸ÞÛ°ÊÞÙÇÁîñ8)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 152 : GLOBAL_ATTRIBUTE9 (¸ÞÛ°ÊÞÙÇÁîñ9)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 153 : GLOBAL_ATTRIBUTE10 (¸ÞÛ°ÊÞÙÇÁîñ10)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 154 : GLOBAL_ATTRIBUTE11 (¸ÞÛ°ÊÞÙÇÁîñ11)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 155 : GLOBAL_ATTRIBUTE12 (¸ÞÛ°ÊÞÙÇÁîñ12)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 156 : GLOBAL_ATTRIBUTE13 (¸ÞÛ°ÊÞÙÇÁîñ13)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 157 : GLOBAL_ATTRIBUTE14 (¸ÞÛ°ÊÞÙÇÁîñ14)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 158 : GLOBAL_ATTRIBUTE15 (¸ÞÛ°ÊÞÙÇÁîñ15)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 159 : GLOBAL_ATTRIBUTE16 (¸ÞÛ°ÊÞÙÇÁîñ16)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 160 : GLOBAL_ATTRIBUTE17 (¸ÞÛ°ÊÞÙÇÁîñ17)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 161 : GLOBAL_ATTRIBUTE18 (¸ÞÛ°ÊÞÙÇÁîñ18)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 162 : GLOBAL_ATTRIBUTE19 (¸ÞÛ°ÊÞÙÇÁîñ19)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 163 : GLOBAL_ATTRIBUTE20 (¸ÞÛ°ÊÞÙÇÁîñ20)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 164 : GLOBAL_ATTRIBUTE_DATE1 (¸ÞÛ°ÊÞÙÇÁîñ_út1)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 165 : GLOBAL_ATTRIBUTE_DATE2 (¸ÞÛ°ÊÞÙÇÁîñ_út2)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 166 : GLOBAL_ATTRIBUTE_DATE3 (¸ÞÛ°ÊÞÙÇÁîñ_út3)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 167 : GLOBAL_ATTRIBUTE_DATE4 (¸ÞÛ°ÊÞÙÇÁîñ_út4)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 168 : GLOBAL_ATTRIBUTE_DATE5 (¸ÞÛ°ÊÞÙÇÁîñ_út5)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 169 : GLOBAL_ATTRIBUTE_DATE6 (¸ÞÛ°ÊÞÙÇÁîñ_út6)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 170 : GLOBAL_ATTRIBUTE_DATE7 (¸ÞÛ°ÊÞÙÇÁîñ_út7)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 171 : GLOBAL_ATTRIBUTE_DATE8 (¸ÞÛ°ÊÞÙÇÁîñ_út8)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 172 : GLOBAL_ATTRIBUTE_DATE9 (¸ÞÛ°ÊÞÙÇÁîñ_út9)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 173 : GLOBAL_ATTRIBUTE_DATE10 (¸ÞÛ°ÊÞÙÇÁîñ_út10)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 174 : GLOBAL_ATTRIBUTE_TIMESTAMP1 (¸ÞÛ°ÊÞÙÇÁîñ_À²Ñ½ÀÝÌß1)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 175 : GLOBAL_ATTRIBUTE_TIMESTAMP2 (¸ÞÛ°ÊÞÙÇÁîñ_À²Ñ½ÀÝÌß2)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 176 : GLOBAL_ATTRIBUTE_TIMESTAMP3 (¸ÞÛ°ÊÞÙÇÁîñ_À²Ñ½ÀÝÌß3)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 177 : GLOBAL_ATTRIBUTE_TIMESTAMP4 (¸ÞÛ°ÊÞÙÇÁîñ_À²Ñ½ÀÝÌß4)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 178 : GLOBAL_ATTRIBUTE_TIMESTAMP5 (¸ÞÛ°ÊÞÙÇÁîñ_À²Ñ½ÀÝÌß5)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 179 : GLOBAL_ATTRIBUTE_TIMESTAMP6 (¸ÞÛ°ÊÞÙÇÁîñ_À²Ñ½ÀÝÌß6)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 180 : GLOBAL_ATTRIBUTE_TIMESTAMP7 (¸ÞÛ°ÊÞÙÇÁîñ_À²Ñ½ÀÝÌß7)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 181 : GLOBAL_ATTRIBUTE_TIMESTAMP8 (¸ÞÛ°ÊÞÙÇÁîñ_À²Ñ½ÀÝÌß8)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 182 : GLOBAL_ATTRIBUTE_TIMESTAMP9 (¸ÞÛ°ÊÞÙÇÁîñ_À²Ñ½ÀÝÌß9)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 183 : GLOBAL_ATTRIBUTE_TIMESTAMP10 (¸ÞÛ°ÊÞÙÇÁîñ_À²Ñ½ÀÝÌß10)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 184 : GLOBAL_ATTRIBUTE_NUMBER1 (¸ÞÛ°ÊÞÙÇÁîñ_Ô1)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 185 : GLOBAL_ATTRIBUTE_NUMBER2 (¸ÞÛ°ÊÞÙÇÁîñ_Ô2)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 186 : GLOBAL_ATTRIBUTE_NUMBER3 (¸ÞÛ°ÊÞÙÇÁîñ_Ô3)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 187 : GLOBAL_ATTRIBUTE_NUMBER4 (¸ÞÛ°ÊÞÙÇÁîñ_Ô4)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 188 : GLOBAL_ATTRIBUTE_NUMBER5 (¸ÞÛ°ÊÞÙÇÁîñ_Ô5)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 189 : GLOBAL_ATTRIBUTE_NUMBER6 (¸ÞÛ°ÊÞÙÇÁîñ_Ô6)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 190 : GLOBAL_ATTRIBUTE_NUMBER7 (¸ÞÛ°ÊÞÙÇÁîñ_Ô7)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 191 : GLOBAL_ATTRIBUTE_NUMBER8 (¸ÞÛ°ÊÞÙÇÁîñ_Ô8)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 192 : GLOBAL_ATTRIBUTE_NUMBER9 (¸ÞÛ°ÊÞÙÇÁîñ_Ô9)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 193 : GLOBAL_ATTRIBUTE_NUMBER10 (¸ÞÛ°ÊÞÙÇÁîñ_Ô10)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 194 : Required Acknowledgement (vmF)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 195 : Acknowledge Within Days (mFúÀú)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 196 : Invoice Channel (¿`l)
-- Ver1.5 Mod Start
--      lv_file_data := lv_file_data || cv_comma || NULL;               -- 197 : Batch ID (ob`ID)
      lv_file_data := lv_file_data || cv_comma || 
                        l_sup_site_rec.batch_id;                      -- 197 : Batch ID (ob`ID)
-- Ver1.5 Mod End
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 198 : Payee Service Level (óælT[rXx)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 199 : Pay Each Document Alone (PÆx¥)
      --
      BEGIN
        -- f[^sÌt@CoÍ
        UTL_FILE.PUT_LINE( gf_site_file_handle
                         , lv_file_data
                         );
        --
        -- oÍJEgAbv
        gn_out_site_cnt := gn_out_site_cnt + 1;
      EXCEPTION
        WHEN OTHERS THEN
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
          lv_errbuf := lv_errmsg;
          RAISE global_process_expt;
      END;
      --
      -- ==============================================================
      -- OICdüæTCgÞðe[uÌo^EXV
      -- ==============================================================
      IF ( l_sup_site_rec.key_ins_upd_flag = cv_evac_create ) THEN
        -- Þðe[uo^EXVtOªCreateÌê
        BEGIN
          -- OICdüæTCgÞðe[uÌo^
          INSERT INTO xxcmm_oic_vd_site_evac (
              vendor_site_id                        -- düæTCgID
            , vendor_site_code                      -- düæTCgR[h
            , created_by                            -- ì¬Ò
            , creation_date                         -- ì¬ú
            , last_updated_by                       -- ÅIXVÒ
            , last_update_date                      -- ÅIXVú
            , last_update_login                     -- ÅIXVOC
            , request_id                            -- vID
            , program_application_id                -- RJgEvOEAvP[VID
            , program_id                            -- RJgEvOID
            , program_update_date                   -- vOXVú
          ) VALUES (
              l_sup_site_rec.vendor_site_id         -- düæTCgID
            , l_sup_site_rec.pvsa_vendor_site_code  -- düæTCgR[h
            , cn_created_by                         -- ì¬Ò
            , cd_creation_date                      -- ì¬ú
            , cn_last_updated_by                    -- ÅIXVÒ
            , cd_last_update_date                   -- ÅIXVú
            , cn_last_update_login                  -- ÅIXVOC
            , cn_request_id                         -- vID
            , cn_program_application_id             -- RJgEvOEAvP[VID
            , cn_program_id                         -- RJgEvOID
            , cd_program_update_date                -- vOXVú
          );
        EXCEPTION
          WHEN OTHERS THEN
            -- o^É¸sµ½ê
            lv_errmsg := SUBSTRB(
                           xxccp_common_pkg.get_msg(
                             iv_application  => cv_appl_xxcmm             -- AvP[VZk¼FXXCMM
                           , iv_name         => cv_insert_err_msg         -- bZ[W¼F}üG[bZ[W
                           , iv_token_name1  => cv_tkn_table              -- g[N¼1FTABLE
                           , iv_token_value1 => cv_oic_site_evac_tbl_msg  -- g[Nl1FOICdüæTCgÞðe[u
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
      ELSIF ( l_sup_site_rec.key_ins_upd_flag = cv_evac_update ) THEN
        -- Þðe[uo^EXVtOªUpdateÌê
        BEGIN
          -- OICdüæTCgÞðe[uÌXV
          UPDATE
              xxcmm_oic_vd_site_evac  xovse  -- OICdüæTCgÞðe[u
          SET
              xovse.vendor_site_code       = l_sup_site_rec.pvsa_vendor_site_code  -- düæTCgR[h
            , xovse.last_update_date       = cd_last_update_date                   -- ÅIXVú
            , xovse.last_updated_by        = cn_last_updated_by                    -- ÅIXVÒ
            , xovse.last_update_login      = cn_last_update_login                  -- ÅIXVOC
            , xovse.request_id             = cn_request_id                         -- vID
            , xovse.program_application_id = cn_program_application_id             -- vOAvP[VID
            , xovse.program_id             = cn_program_id                         -- vOID
            , xovse.program_update_date    = cd_program_update_date                -- vOXVú
          WHERE
              xovse.vendor_site_id         = l_sup_site_rec.vendor_site_id         -- düæTCgID
          ;
        EXCEPTION
          WHEN OTHERS THEN
            -- XVÉ¸sµ½ê
            lv_errmsg := SUBSTRB(
                           xxccp_common_pkg.get_msg(
                             iv_application  => cv_appl_xxcmm             -- AvP[VZk¼FXXCMM
                           , iv_name         => cv_update_err_msg         -- bZ[W¼FXVG[bZ[W
                           , iv_token_name1  => cv_tkn_table              -- g[N¼1FTABLE
                           , iv_token_value1 => cv_oic_site_evac_tbl_msg  -- g[Nl1FOICdüæTCgÞðe[u
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
        -- XVÉ¬÷µ½êAXVOÆXVãÌdüæ¼ðoÍ
        lv_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_appl_xxcmm                           -- AvP[VZk¼FXXCMM
                  , iv_name         => cv_evac_data_out_msg                    -- bZ[W¼FÞðîñXVoÍbZ[W
                  , iv_token_name1  => cv_tkn_table                            -- g[N¼1FTABLE
                  , iv_token_value1 => cv_oic_site_evac_tbl_msg                -- g[Nl1FOICdüæTCgÞðe[u
                  , iv_token_name2  => cv_tkn_id                               -- g[N¼2FID
                  , iv_token_value2 => TO_CHAR(l_sup_site_rec.vendor_site_id)  -- g[Nl2FdüæTCgID
                  , iv_token_name3  => cv_tkn_before_value                     -- g[N¼3FBEFORE_VALUE
                  , iv_token_value3 => l_sup_site_rec.xovse_vendor_site_code   -- g[Nl3FdüæTCgR[hiÞðe[uj
                  , iv_token_name4  => cv_tkn_after_value                      -- g[N¼4FAFTER_VALUE
                  , iv_token_value4 => l_sup_site_rec.pvsa_vendor_site_code    -- g[Nl4FdüæTCgR[hi}X^j
                  );
        --
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
        , buff   => lv_msg
        );
      END IF;
    --
    END LOOP output_sup_site_loop;
--
    -- J[\N[Y
    CLOSE sup_site_cur;
--
    -- ÞðîñXVoÍbZ[WðoÍµÄ¢éê
    IF ( lv_msg IS NOT NULL ) THEN
      -- ós}ü
      FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => ''
      );
    END IF;
--
  EXCEPTION
--
    -- *** bNG[áOnh ***
    WHEN global_lock_expt THEN
      -- J[\N[Y
      IF ( sup_site_cur%ISOPEN ) THEN
        CLOSE sup_site_cur;
      END IF;
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_xxcmm             -- AvP[VZk¼FXXCMM
                   , iv_name         => cv_lock_err_msg           -- bZ[W¼FbNG[bZ[W
                   , iv_token_name1  => cv_tkn_ng_table           -- g[N¼1FNG_TABLE
                   , iv_token_value1 => cv_oic_site_evac_tbl_msg  -- g[Nl1Fe[u¼FOICdüæTCgÞðe[u
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
      IF ( sup_site_cur%ISOPEN ) THEN
        CLOSE sup_site_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ¤ÊÖáOnh ***
    WHEN global_api_expt THEN
      -- J[\N[Y
      IF ( sup_site_cur%ISOPEN ) THEN
        CLOSE sup_site_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ¤ÊÖOTHERSáOnh ***
    WHEN global_api_others_expt THEN
      -- J[\N[Y
      IF ( sup_site_cur%ISOPEN ) THEN
        CLOSE sup_site_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERSáOnh ***
    WHEN OTHERS THEN
      -- J[\N[Y
      IF ( sup_site_cur%ISOPEN ) THEN
        CLOSE sup_site_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  Åè END   ##########################################
--
  END output_sup_site;
--
--
  /**********************************************************************************
   * Procedure Name   : output_sup_site_ass
   * Description      : uCTvCEBUvAgf[^ÌoEt@CoÍ(A-5)
   ***********************************************************************************/
  PROCEDURE output_sup_site_ass(
    ov_errbuf     OUT VARCHAR2,     --   G[EbZ[W           --# Åè #
    ov_retcode    OUT VARCHAR2,     --   ^[ER[h             --# Åè #
    ov_errmsg     OUT VARCHAR2)     --   [U[EG[EbZ[W --# Åè #
  IS
    -- ===============================
    -- Åè[Jè
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'output_sup_site_ass';       -- vO¼
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
    lv_file_data         VARCHAR2(30000) DEFAULT NULL;       -- oÍàe
--
    -- *** [JEJ[\ ***
    -- uCTvCEBUvÌoJ[\
    CURSOR sup_site_ass_cur
    IS
      SELECT
          (CASE
             WHEN (    gt_pre_process_date IS NULL
                   OR  pvsa.creation_date > gt_pre_process_date) THEN
               cv_status_create
             ELSE
               cv_status_update
           END)                                          AS status_code                -- Xe[^XER[h
        , pv.vendor_name                                 AS vendor_name                -- düæ¼
        , pvsa.vendor_site_code                          AS vendor_site_code           -- düæTCgR[h
        , hl_ship.location_code                          AS ship_loc_code              -- ÆR[hio×æj
        , hl_bill.location_code                          AS bill_loc_code              -- ÆR[hi¿æj
-- Ver1.3 Mod Start
--        , gcck_accts_pay.concatenated_segments           AS accts_pay_conc_segments    -- AZOgiÂzªj
--        , gcck_prepay.concatenated_segments              AS prepay_conc_segments       -- AZOgiO¥zªj
--        , gcck_future_pay.concatenated_segments          AS future_pay_conc_segments   -- AZOgix¥è`zªj
        , (CASE
             WHEN gcck_accts_pay.code_combination_id IS NOT NULL THEN
               (gcck_accts_pay.segment1 || '-' ||
                gcck_accts_pay.segment2 || '-' ||
                gcck_accts_pay.segment3 || '-' ||
                gcck_accts_pay.segment3 || gcck_accts_pay.segment4 || '-' ||
                gcck_accts_pay.segment5 || '-' ||
                gcck_accts_pay.segment6 || '-' ||
                gcck_accts_pay.segment7 || '-' ||
                gcck_accts_pay.segment8)
             ELSE
               NULL
           END)                                          AS accts_pay_conc_segments    -- AZOgiÂzªj
        , (CASE
             WHEN gcck_prepay.code_combination_id IS NOT NULL THEN
               (gcck_prepay.segment1 || '-' ||
                gcck_prepay.segment2 || '-' ||
                gcck_prepay.segment3 || '-' ||
                gcck_prepay.segment3 || gcck_prepay.segment4 || '-' ||
                gcck_prepay.segment5 || '-' ||
                gcck_prepay.segment6 || '-' ||
                gcck_prepay.segment7 || '-' ||
                gcck_prepay.segment8)
             ELSE
               NULL
           END)                                          AS prepay_conc_segments       -- AZOgiO¥zªj
        , (CASE
             WHEN gcck_future_pay.code_combination_id IS NOT NULL THEN
               (gcck_future_pay.segment1 || '-' ||
                gcck_future_pay.segment2 || '-' ||
                gcck_future_pay.segment3 || '-' ||
                gcck_future_pay.segment3 || gcck_future_pay.segment4 || '-' ||
                gcck_future_pay.segment5 || '-' ||
                gcck_future_pay.segment6 || '-' ||
                gcck_future_pay.segment7 || '-' ||
                gcck_future_pay.segment8)
             ELSE
               NULL
           END)                                          AS future_pay_conc_segments   -- AZOgix¥è`zªj
-- Ver1.3 Mod End
        , ads.distribution_set_name                      AS distribution_set_name      -- zªZbg¼
        , TO_CHAR(pvsa.inactive_date, cv_date_fmt)       AS inactive_date              -- ³øú
-- Ver1.5 Add Start
        , (CASE 
            WHEN ( gt_pre_process_date IS NULL ) THEN 
-- Ver1.9 Mod Start
--              TO_CHAR( gt_cur_process_date , cv_datetime_id_fmt ) || MOD( pv.vendor_id , cn_divisor_ten )
              TO_CHAR( gt_cur_process_date , cv_datetime_id_fmt ) || MOD( pv.vendor_id , gn_parallel_num )
-- Ver1.9 Mod End
            ELSE
              NULL
          END)                                           AS batch_id                   -- ob`ID
-- Ver1.5 Add End
      FROM
          po_vendor_sites_all       pvsa             -- düæTCg
        , po_vendors                pv               -- düæ}X^
        , hr_locations              hl_ship          -- Æ}X^_o×æ
        , hr_locations              hl_bill          -- Æ}X^_¿æ
        , gl_code_combinations_kfv  gcck_accts_pay   -- ¨èÈÚgÝí¹_KFV_Âzª
        , gl_code_combinations_kfv  gcck_prepay      -- ¨èÈÚgÝí¹_KFV_O¥zª
        , gl_code_combinations_kfv  gcck_future_pay  -- ¨èÈÚgÝí¹_KFV_x¥è`zª
        , ap_distribution_sets      ads              -- zªZbg
      WHERE
          (   gt_pre_process_date IS NULL
-- Ver1.11 Mod Start
--           OR pvsa.last_update_date > gt_pre_process_date)
           OR (    pvsa.last_update_date > gt_pre_process_date
               AND pvsa.last_update_date <= gt_cur_process_date)
           )
-- Ver1.11 Mod End
      AND pvsa.org_id                        = gt_target_organization_id
      AND pvsa.vendor_id                     = pv.vendor_id
      AND NVL(pv.vendor_type_lookup_code, 'X') <> cv_employee
      AND pvsa.ship_to_location_id           = hl_ship.location_id (+)
      AND pvsa.bill_to_location_id           = hl_bill.location_id (+)
      AND pvsa.accts_pay_code_combination_id = gcck_accts_pay.code_combination_id (+)
      AND pvsa.prepay_code_combination_id    = gcck_prepay.code_combination_id (+)
      AND pvsa.future_dated_payment_ccid     = gcck_future_pay.code_combination_id (+)
      AND pvsa.distribution_set_id           = ads.distribution_set_id (+)
      ORDER BY
          pv.segment1           ASC  -- düæÔ
        , pvsa.vendor_site_code ASC  -- düæTCgR[h
    ;
--
    -- *** [JER[h ***
    -- uCTvCEBUvÌoJ[\R[h
    l_sup_site_ass_rec     sup_site_ass_cur%ROWTYPE;
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
    -- uCTvCEBUvÌo
    -- ==============================================================
    -- J[\I[v
    OPEN  sup_site_ass_cur;
    <<output_sup_site_ass_loop>>
    LOOP
      --
      FETCH sup_site_ass_cur INTO l_sup_site_ass_rec;
      EXIT WHEN sup_site_ass_cur%NOTFOUND;
      --
      -- oJEgAbv
      gn_get_site_ass_cnt := gn_get_site_ass_cnt + 1;
      --
      -- ==============================================================
      -- uCTvCEBUvÌt@CoÍ
      -- ==============================================================
      -- f[^sÌì¬
      lv_file_data := l_sup_site_ass_rec.status_code;                 --  1 : Import Action * (Xe[^XER[h)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string(
-- Ver1.6 Mod Start
--                        l_sup_site_ass_rec.vendor_name
                        xxccp_oiccommon_pkg.trim_space_tab(l_sup_site_ass_rec.vendor_name)
-- Ver1.6 Mod End
                      , l_sup_site_ass_rec.status_code
                      );                                              --  2 : Supplier Name* (TvC¼Ì)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string(
-- Ver1.6 Mod Start
--                        l_sup_site_ass_rec.vendor_site_code
                        xxccp_oiccommon_pkg.trim_space_tab(l_sup_site_ass_rec.vendor_site_code)
-- Ver1.6 Mod End
                      , l_sup_site_ass_rec.status_code
                      );                                              --  3 : Supplier Site* (TvCETCgER[h)
      lv_file_data := lv_file_data || cv_comma || cv_sales_bu;        --  4 : Procurement BU* (²BrWlXEjbg)
      lv_file_data := lv_file_data || cv_comma || cv_sales_bu;        --  5 : Client BU* (NCAgrWlXEjbg)
      lv_file_data := lv_file_data || cv_comma || cv_sales_bu;        --  6 : Bill-to BU (¿ærWlXEjbg)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string(
                        l_sup_site_ass_rec.ship_loc_code
                      , l_sup_site_ass_rec.status_code
                      );                                              --  7 : Ship-to Location (o×æÆ)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string(
                        l_sup_site_ass_rec.bill_loc_code
                      , l_sup_site_ass_rec.status_code
                      );                                              --  8 : Bill-to Location (¿æÆ)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  9 : Use Withholding Tax (¹ò¥ûÅÌgp)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 10 : Withholding Tax Group (¹ò¥ûÅO[v)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string(
                        l_sup_site_ass_rec.accts_pay_conc_segments
                      , l_sup_site_ass_rec.status_code
                      );                                              -- 11 : Liability Distribution (Âzª)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string(
                        l_sup_site_ass_rec.prepay_conc_segments
                      , l_sup_site_ass_rec.status_code
                      );                                              -- 12 : Prepayment Distribution (O¥zª)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string(
                        l_sup_site_ass_rec.future_pay_conc_segments
                      , l_sup_site_ass_rec.status_code
                      );                                              -- 13 : Bills Payable Distribution (x¥è`zª)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string(
                        l_sup_site_ass_rec.distribution_set_name
                      , l_sup_site_ass_rec.status_code
                      );                                              -- 14 : Distribution Set (zªZbg)
      lv_file_data := lv_file_data || cv_comma || 
                      nvl_by_status_code(
                        l_sup_site_ass_rec.inactive_date
                      , l_sup_site_ass_rec.status_code
                      );                                              -- 15 : Inactive Date (ñANeBuú)
-- Ver1.5 Mod Start
--      lv_file_data := lv_file_data || cv_comma || NULL;               -- 16 : Batch ID (ob`ID)
      lv_file_data := lv_file_data || cv_comma || 
                        l_sup_site_ass_rec.batch_id;                  -- 16 : Batch ID (ob`ID)
-- Ver1.5 Mod Start
      --
      BEGIN
        -- f[^sÌt@CoÍ
        UTL_FILE.PUT_LINE( gf_site_ass_file_handle
                         , lv_file_data
                         );
        --
        -- oÍJEgAbv
        gn_out_site_ass_cnt := gn_out_site_ass_cnt + 1;
      EXCEPTION
        WHEN OTHERS THEN
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
          lv_errbuf := lv_errmsg;
          RAISE global_process_expt;
      END;
    --
    END LOOP output_sup_site_ass_loop;
--
    -- J[\N[Y
    CLOSE sup_site_ass_cur;
--
  EXCEPTION
--
--#################################  ÅèáO START   ####################################
--
    -- *** ¤ÊáOnh ***
    WHEN global_process_expt THEN
      -- J[\N[Y
      IF ( sup_site_ass_cur%ISOPEN ) THEN
        CLOSE sup_site_ass_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ¤ÊÖáOnh ***
    WHEN global_api_expt THEN
      -- J[\N[Y
      IF ( sup_site_ass_cur%ISOPEN ) THEN
        CLOSE sup_site_ass_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ¤ÊÖOTHERSáOnh ***
    WHEN global_api_others_expt THEN
      -- J[\N[Y
      IF ( sup_site_ass_cur%ISOPEN ) THEN
        CLOSE sup_site_ass_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERSáOnh ***
    WHEN OTHERS THEN
      -- J[\N[Y
      IF ( sup_site_ass_cur%ISOPEN ) THEN
        CLOSE sup_site_ass_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  Åè END   ##########################################
--
  END output_sup_site_ass;
--
--
  /**********************************************************************************
   * Procedure Name   : output_sup_contact
   * Description      : uDTvCESÒvAgf[^ÌoEt@CoÍ(A-6)
   ***********************************************************************************/
  PROCEDURE output_sup_contact(
    ov_errbuf     OUT VARCHAR2,     --   G[EbZ[W           --# Åè #
    ov_retcode    OUT VARCHAR2,     --   ^[ER[h             --# Åè #
    ov_errmsg     OUT VARCHAR2)     --   [U[EG[EbZ[W --# Åè #
  IS
    -- ===============================
    -- Åè[Jè
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'output_sup_contact';       -- vO¼
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
    lv_file_data         VARCHAR2(30000) DEFAULT NULL;       -- oÍàe
--
    -- *** [JEJ[\ ***
    -- uDTvCESÒvÌoJ[\
    CURSOR sup_contact_cur
    IS
      SELECT
          (CASE
             WHEN (    gt_pre_process_date IS NULL
                   OR  pvc.creation_date > gt_pre_process_date) THEN
               cv_status_create
             ELSE
               cv_status_update
           END)                                          AS status_code                -- Xe[^XER[h
        , pv.vendor_name                                 AS vendor_name                -- düæ¼
-- Ver1.3 Del Start
--        , pvc.prefix                                     AS prefix                     -- hÌ
-- Ver1.3 Del End
        , (CASE
             WHEN xovce.vendor_contact_id IS NOT NULL THEN
               xovce.first_name
             ELSE
-- Ver1.3 Mod Start
--               pvc.first_name
               NVL(pvc.first_name, cv_ast)
-- Ver1.3 Mod End
           END)                                          AS first_name                 -- düæSÒ¼(¼)
        , (CASE
             WHEN (    xovce.vendor_contact_id IS NOT NULL
-- Ver1.3 Mod Start
--                   AND NVL(xovce.first_name, '@') <> NVL(pvc.first_name, '@') ) THEN
                   AND xovce.first_name <> NVL(pvc.first_name, cv_ast) ) THEN
-- Ver1.3 Mod End
-- Ver1.3 Mod Start
--               pvc.first_name
               NVL(pvc.first_name, cv_ast)
-- Ver1.3 Mod End
             ELSE
               NULL
           END)                                          AS first_name_new             -- VdüæSÒ¼(¼)
        , pvc.middle_name                                AS middle_name                -- ~hl[
        , (CASE
             WHEN xovce.vendor_contact_id IS NOT NULL THEN
               xovce.last_name
             ELSE
               pvc.last_name
           END)                                          AS last_name                  -- düæSÒ¼(©)
        , (CASE
             WHEN (    xovce.vendor_contact_id IS NOT NULL
-- Ver1.3 Mod Start(©ÍK{ÚÌ½ßÎÉÄNVLí)
--                   AND NVL(xovce.last_name, '@') <> NVL(pvc.last_name, '@') ) THEN
                   AND xovce.last_name <> pvc.last_name ) THEN
-- Ver1.3 Mod End
               pvc.last_name
             ELSE
               NULL
           END)                                          AS last_name_new              -- VdüæSÒ¼(©)
        , pvc.title                                      AS title                      -- Wu^Cg
        , (CASE
             WHEN ROW_NUMBER()
                  OVER(PARTITION BY pv.vendor_id ORDER BY pvc.vendor_contact_id) = 1 THEN
               cv_y
             ELSE
               cv_n
           END)                                          AS admin_contact              -- ÇS
-- Ver1.4(E124) Mod Start
--        , pvc.email_address                              AS email_address              -- E[
        , (CASE
             WHEN (    gt_pre_process_date IS NULL
                   OR  pvc.creation_date > gt_pre_process_date) THEN
               pvc.email_address
             ELSE
               NULL
           END)                                          AS email_address              -- E[
-- Ver1.4(E124) Mod End
-- Ver1.3 Add Start
        , (CASE
             WHEN (    gt_pre_process_date IS NULL
                   OR  pvc.creation_date > gt_pre_process_date) THEN
               NULL
             ELSE
               pvc.email_address
           END)                                          AS email_address_new          -- E[iXVpj
-- Ver1.3 Add End
        , pvc.area_code                                  AS area_code                  -- sOÇÔ
        , pvc.phone                                      AS phone                      -- dbÔ
        , pvc.fax_area_code                              AS fax_area_code              -- FAXsOÇÔ
        , pvc.fax                                        AS fax                        -- FAXÔ
-- Ver1.3 Del Start
--        , TO_CHAR(pvc.inactive_date, cv_date_fmt)        AS inactive_date              -- ³øú
-- Ver1.3 Del End
        , pvc.vendor_contact_id                          AS vendor_contact_id          -- düæSÒID
-- Ver1.3 Mod Start
--        , pvc.first_name                                 AS pvc_first_name             -- düæSÒi¼ji}X^j
        , NVL(pvc.first_name, cv_ast)                    AS pvc_first_name             -- düæSÒi¼ji}X^j
-- Ver1.3 Mod End
        , pvc.last_name                                  AS pvc_last_name              -- düæSÒi©ji}X^j
        , xovce.first_name                               AS xovce_first_name           -- düæSÒi¼jiÞðe[uj
        , xovce.last_name                                AS xovce_last_name            -- düæSÒi©jiÞðe[uj
        , (CASE
             WHEN xovce.vendor_contact_id IS NULL THEN
               cv_evac_create
-- Ver1.3 Mod Start(©ÍK{ÚÌ½ßÎÉÄNVLí)
--             WHEN (   NVL(xovce.first_name, '@') <> NVL(pvc.first_name, '@')
--                   OR NVL(xovce.last_name , '@') <> NVL(pvc.last_name , '@') ) THEN
             WHEN (   xovce.first_name <> NVL(pvc.first_name, cv_ast)
                   OR xovce.last_name  <> pvc.last_name ) THEN
-- Ver1.3 Mod End
               cv_evac_update
             ELSE
               NULL
           END)                                          AS key_ins_upd_flag           -- L[îño^EXVtO
      FROM
          po_vendor_contacts         pvc    -- düæSÒ
        , po_vendor_sites_all        pvsa   -- düæTCg
        , po_vendors                 pv     -- düæ}X^
        , xxcmm_oic_vd_contact_evac  xovce  -- OICdüæSÒÞðe[u
      WHERE
          (   gt_pre_process_date IS NULL
-- Ver1.11 Mod Start
--           OR pvc.last_update_date > gt_pre_process_date
           OR (    pvc.last_update_date > gt_pre_process_date
               AND pvc.last_update_date <= gt_cur_process_date)
           )
-- Ver1.11 Mod End
      AND pvc.vendor_site_id    = pvsa.vendor_site_id
      AND pvsa.org_id           = gt_target_organization_id
      AND pvsa.vendor_id        = pv.vendor_id
      AND NVL(pv.vendor_type_lookup_code, 'X') <> cv_employee
      AND pvc.vendor_contact_id = xovce.vendor_contact_id (+)
      ORDER BY
          pv.segment1           ASC  -- düæÔ
        , pvsa.vendor_site_code ASC  -- düæTCgR[h
        , pvc.vendor_contact_id ASC  -- düæSÒID
      FOR UPDATE OF xovce.first_name NOWAIT  -- sbNFOICdüæSÒÞðe[u
    ;
--
    -- *** [JER[h ***
    -- uDTvCESÒvÌoJ[\R[h
    l_sup_contact_rec     sup_contact_cur%ROWTYPE;
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
    -- uDTvCESÒvÌo
    -- ==============================================================
    -- J[\I[v
    OPEN  sup_contact_cur;
    <<output_sup_contact_loop>>
    LOOP
      --
      FETCH sup_contact_cur INTO l_sup_contact_rec;
      EXIT WHEN sup_contact_cur%NOTFOUND;
      --
      -- oJEgAbv
      gn_get_cont_cnt := gn_get_cont_cnt + 1;
      --
      -- ==============================================================
      -- uDTvCESÒvÌt@CoÍ
      -- ==============================================================
      -- f[^sÌì¬
      lv_file_data := l_sup_contact_rec.status_code;                  --  1 : Import Action * (Xe[^XER[h)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string(
-- Ver1.6 Mod Start
--                        l_sup_contact_rec.vendor_name
                        xxccp_oiccommon_pkg.trim_space_tab(l_sup_contact_rec.vendor_name)
-- Ver1.6 Mod End
                      , l_sup_contact_rec.status_code
                      );                                              --  2 : Supplier Name* (TvC¼Ì)
-- Ver1.3 Mod Start
--      lv_file_data := lv_file_data || cv_comma || 
--                      to_csv_string(
--                        l_sup_contact_rec.prefix
--                      , l_sup_contact_rec.status_code
--                      );                                              --  3 : Prefix (hÌ)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  3 : Prefix (hÌ)
-- Ver1.3 Mod End
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string(
                        l_sup_contact_rec.first_name
                      , l_sup_contact_rec.status_code
                      );                                              --  4 : First Name (¼)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string(
                        l_sup_contact_rec.first_name_new
-- Ver1.3 Del Start(ÖAÎ)
--                      , l_sup_contact_rec.status_code
-- Ver1.3 Del End
                      );                                              --  5 : First Name New (¼iXVpj)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string(
                        l_sup_contact_rec.middle_name
                      , l_sup_contact_rec.status_code
                      );                                              --  6 : Middle Name (~hl[)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string(
                        l_sup_contact_rec.last_name
                      , l_sup_contact_rec.status_code
                      );                                              --  7 : Last Name (©)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string(
                        l_sup_contact_rec.last_name_new
-- Ver1.3 Del Start(ÖAÎ)
--                      , l_sup_contact_rec.status_code
-- Ver1.3 Del End
                      );                                              --  8 : Last Name New (©iXVpj)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string(
                        l_sup_contact_rec.title
                      , l_sup_contact_rec.status_code
                      );                                              --  9 : Job Title (Wu^Cg)
      lv_file_data := lv_file_data || cv_comma || 
                      l_sup_contact_rec.admin_contact;                -- 10 : Administrative Contact (ÇS)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string(
                        l_sup_contact_rec.email_address
                      , l_sup_contact_rec.status_code
                      );                                              -- 11 : E-Mail (E[)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string(
-- Ver1.3 Mod Start
--                        l_sup_contact_rec.email_address
                        l_sup_contact_rec.email_address_new
-- Ver1.3 Mod End
                      , l_sup_contact_rec.status_code
                      );                                              -- 12 : E-Mail New (E[iXVpj)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 13 : Phone Country Code (dbR[h)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string(
                        l_sup_contact_rec.area_code
                      , l_sup_contact_rec.status_code
                      );                                              -- 14 : Phone Area Code (dbsOÇÔ)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string(
                        l_sup_contact_rec.phone
                      , l_sup_contact_rec.status_code
                      );                                              -- 15 : Phone (dbÔ)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 16 : Phone Extension (dbÔàü)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 17 : Fax Country Code (FAXR[h)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string(
                        l_sup_contact_rec.fax_area_code
                      , l_sup_contact_rec.status_code
                      );                                              -- 18 : Fax Area Code (FAXsOÇÔ)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string(
                        l_sup_contact_rec.fax
                      , l_sup_contact_rec.status_code
                      );                                              -- 19 : Fax (FAXÔ)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 20 : Mobile Country Code (ÔigÑ))
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 21 : Mobile Area Code (næÔ(gÑ))
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 22 : Mobile (gÑÔ)
-- Ver1.3 Mod Start
--      lv_file_data := lv_file_data || cv_comma || 
--                      nvl_by_status_code(
--                        l_sup_contact_rec.inactive_date
--                      , l_sup_contact_rec.status_code
--                      );                                              -- 23 : Inactive Date (ñANeBuú)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 23 : Inactive Date (ñANeBuú)
-- Ver1.3 Mod End
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 24 : ATTRIBUTE_CATEGORY (ÇÁJeS)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 25 : ATTRIBUTE1 (ÇÁîñ1)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 26 : ATTRIBUTE2 (ÇÁîñ2)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 27 : ATTRIBUTE3 (ÇÁîñ3)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 28 : ATTRIBUTE4 (ÇÁîñ4)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 29 : ATTRIBUTE5 (ÇÁîñ5)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 30 : ATTRIBUTE6 (ÇÁîñ6)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 31 : ATTRIBUTE7 (ÇÁîñ7)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 32 : ATTRIBUTE8 (ÇÁîñ8)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 33 : ATTRIBUTE9 (ÇÁîñ9)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 34 : ATTRIBUTE10 (ÇÁîñ10)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 35 : ATTRIBUTE11 (ÇÁîñ11)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 36 : ATTRIBUTE12 (ÇÁîñ12)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 37 : ATTRIBUTE13 (ÇÁîñ13)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 38 : ATTRIBUTE14 (ÇÁîñ14)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 39 : ATTRIBUTE15 (ÇÁîñ15)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 40 : ATTRIBUTE16 (ÇÁîñ16)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 41 : ATTRIBUTE17 (ÇÁîñ17)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 42 : ATTRIBUTE18 (ÇÁîñ18)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 43 : ATTRIBUTE19 (ÇÁîñ19)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 44 : ATTRIBUTE20 (ÇÁîñ20)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 45 : ATTRIBUTE21 (ÇÁîñ21)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 46 : ATTRIBUTE22 (ÇÁîñ22)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 47 : ATTRIBUTE23 (ÇÁîñ23)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 48 : ATTRIBUTE24 (ÇÁîñ24)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 49 : ATTRIBUTE25 (ÇÁîñ25)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 50 : ATTRIBUTE26 (ÇÁîñ26)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 51 : ATTRIBUTE27 (ÇÁîñ27)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 52 : ATTRIBUTE28 (ÇÁîñ28)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 53 : ATTRIBUTE29 (ÇÁîñ29)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 54 : ATTRIBUTE30 (ÇÁîñ30)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 55 : ATTRIBUTE_NUMBER1 (ÇÁÔ1)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 56 : ATTRIBUTE_NUMBER2 (ÇÁÔ2)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 57 : ATTRIBUTE_NUMBER3 (ÇÁÔ3)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 58 : ATTRIBUTE_NUMBER4 (ÇÁÔ4)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 59 : ATTRIBUTE_NUMBER5 (ÇÁÔ5)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 60 : ATTRIBUTE_NUMBER6 (ÇÁÔ6)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 61 : ATTRIBUTE_NUMBER7 (ÇÁÔ7)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 62 : ATTRIBUTE_NUMBER8 (ÇÁÔ8)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 63 : ATTRIBUTE_NUMBER9 (ÇÁÔ9)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 64 : ATTRIBUTE_NUMBER10 (ÇÁÔ10)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 65 : ATTRIBUTE_NUMBER11 (ÇÁÔ11)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 66 : ATTRIBUTE_NUMBER12 (ÇÁÔ12)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 67 : ATTRIBUTE_DATE1 (ÇÁút1)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 68 : ATTRIBUTE_DATE2 (ÇÁút2)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 69 : ATTRIBUTE_DATE3 (ÇÁút3)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 70 : ATTRIBUTE_DATE4 (ÇÁút4)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 71 : ATTRIBUTE_DATE5 (ÇÁút5)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 72 : ATTRIBUTE_DATE6 (ÇÁút6)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 73 : ATTRIBUTE_DATE7 (ÇÁút7)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 74 : ATTRIBUTE_DATE8 (ÇÁút8)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 75 : ATTRIBUTE_DATE9 (ÇÁút9)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 76 : ATTRIBUTE_DATE10 (ÇÁút10)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 77 : ATTRIBUTE_DATE11 (ÇÁút11)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 78 : ATTRIBUTE_DATE12 (ÇÁút12)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 79 : Batch ID (ob`ID)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 80 : User Account Action ([U[EAJEgEANV)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 81 : Role 1 ([1)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 82 : Role 2 ([2)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 83 : Role 3 ([3)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 84 : Role 4 ([4)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 85 : Role 5 ([5)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 86 : Role 6 ([6)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 87 : Role 7 ([7)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 88 : Role 8 ([8)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 89 : Role 9 ([9)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 90 : Role 10 ([10)
      --
      BEGIN
        -- f[^sÌt@CoÍ
        UTL_FILE.PUT_LINE( gf_cont_file_handle
                         , lv_file_data
                         );
        --
        -- oÍJEgAbv
        gn_out_cont_cnt := gn_out_cont_cnt + 1;
      EXCEPTION
        WHEN OTHERS THEN
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
          lv_errbuf := lv_errmsg;
          RAISE global_process_expt;
      END;
      --
      -- ==============================================================
      -- OICdüæSÒÞðe[uÌo^EXV
      -- ==============================================================
      IF ( l_sup_contact_rec.key_ins_upd_flag = cv_evac_create ) THEN
        -- Þðe[uo^EXVtOªCreateÌê
        BEGIN
          -- OICdüæSÒÞðe[uÌo^
          INSERT INTO xxcmm_oic_vd_contact_evac (
              vendor_contact_id                    -- düæSÒID
            , first_name                           -- ¼
            , last_name                            -- ©
            , created_by                           -- ì¬Ò
            , creation_date                        -- ì¬ú
            , last_updated_by                      -- ÅIXVÒ
            , last_update_date                     -- ÅIXVú
            , last_update_login                    -- ÅIXVOC
            , request_id                           -- vID
            , program_application_id               -- RJgEvOEAvP[VID
            , program_id                           -- RJgEvOID
            , program_update_date                  -- vOXVú
          ) VALUES (
              l_sup_contact_rec.vendor_contact_id  -- düæSÒID
            , l_sup_contact_rec.pvc_first_name     -- ¼
            , l_sup_contact_rec.pvc_last_name      -- ©
            , cn_created_by                        -- ì¬Ò
            , cd_creation_date                     -- ì¬ú
            , cn_last_updated_by                   -- ÅIXVÒ
            , cd_last_update_date                  -- ÅIXVú
            , cn_last_update_login                 -- ÅIXVOC
            , cn_request_id                        -- vID
            , cn_program_application_id            -- RJgEvOEAvP[VID
            , cn_program_id                        -- RJgEvOID
            , cd_program_update_date               -- vOXVú
          );
        EXCEPTION
          WHEN OTHERS THEN
            -- o^É¸sµ½ê
            lv_errmsg := SUBSTRB(
                           xxccp_common_pkg.get_msg(
                             iv_application  => cv_appl_xxcmm             -- AvP[VZk¼FXXCMM
                           , iv_name         => cv_insert_err_msg         -- bZ[W¼F}üG[bZ[W
                           , iv_token_name1  => cv_tkn_table              -- g[N¼1FTABLE
                           , iv_token_value1 => cv_oic_cont_evac_tbl_msg  -- g[Nl1FOICdüæSÒÞðe[u
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
      ELSIF ( l_sup_contact_rec.key_ins_upd_flag = cv_evac_update ) THEN
        -- Þðe[uo^EXVtOªUpdateÌê
        BEGIN
          -- OICdüæSÒÞðe[uÌXV
          UPDATE
              xxcmm_oic_vd_contact_evac  xovce  -- OICdüæSÒÞðe[u
          SET
              xovce.first_name             = l_sup_contact_rec.pvc_first_name     -- ¼
            , xovce.last_name              = l_sup_contact_rec.pvc_last_name      -- ©
            , xovce.last_update_date       = cd_last_update_date                  -- ÅIXVú
            , xovce.last_updated_by        = cn_last_updated_by                   -- ÅIXVÒ
            , xovce.last_update_login      = cn_last_update_login                 -- ÅIXVOC
            , xovce.request_id             = cn_request_id                        -- vID
            , xovce.program_application_id = cn_program_application_id            -- vOAvP[VID
            , xovce.program_id             = cn_program_id                        -- vOID
            , xovce.program_update_date    = cd_program_update_date               -- vOXVú
          WHERE
              xovce.vendor_contact_id      = l_sup_contact_rec.vendor_contact_id  -- düæSÒID
          ;
        EXCEPTION
          WHEN OTHERS THEN
            -- XVÉ¸sµ½ê
            lv_errmsg := SUBSTRB(
                           xxccp_common_pkg.get_msg(
                             iv_application  => cv_appl_xxcmm             -- AvP[VZk¼FXXCMM
                           , iv_name         => cv_update_err_msg         -- bZ[W¼FXVG[bZ[W
                           , iv_token_name1  => cv_tkn_table              -- g[N¼1FTABLE
                           , iv_token_value1 => cv_oic_cont_evac_tbl_msg  -- g[Nl1FOICdüæSÒÞðe[u
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
        -- XVÉ¬÷µ½êAXVOÆXVãÌdüæ¼ðoÍ
        lv_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_appl_xxcmm                                 -- AvP[VZk¼FXXCMM
                  , iv_name         => cv_evac_data_out_msg                          -- bZ[W¼FÞðîñXVoÍbZ[W
                  , iv_token_name1  => cv_tkn_table                                  -- g[N¼1FTABLE
                  , iv_token_value1 => cv_oic_cont_evac_tbl_msg                      -- g[Nl1FOICdüæSÒÞðe[u
                  , iv_token_name2  => cv_tkn_id                                     -- g[N¼2FID
                  , iv_token_value2 => TO_CHAR(l_sup_contact_rec.vendor_contact_id)  -- g[Nl2FdüæSÒID
                  , iv_token_name3  => cv_tkn_before_value                           -- g[N¼3FBEFORE_VALUE
                  , iv_token_value3 => l_sup_contact_rec.xovce_first_name
                                         || ' , '
                                         || l_sup_contact_rec.xovce_last_name        -- g[Nl3FdüæSÒi¼jiÞðe[uj{
                                                                                     --              düæSÒi©jiÞðe[uj
                  , iv_token_name4  => cv_tkn_after_value                            -- g[N¼4FAFTER_VALUE
                  , iv_token_value4 => l_sup_contact_rec.pvc_first_name
                                         || ' , '
                                         || l_sup_contact_rec.pvc_last_name          -- g[Nl4FdüæSÒi¼ji}X^j{
                                                                                     --              düæSÒi©ji}X^j
                  );
        --
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
        , buff   => lv_msg
        );
      END IF;
    --
    END LOOP output_sup_contact_loop;
--
    -- J[\N[Y
    CLOSE sup_contact_cur;
--
    -- ÞðîñXVoÍbZ[WðoÍµÄ¢éê
    IF ( lv_msg IS NOT NULL ) THEN
        -- ós}ü
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
        , buff   => ''
        );
    END IF;
--
  EXCEPTION
--
    -- *** bNG[áOnh ***
    WHEN global_lock_expt THEN
      -- J[\N[Y
      IF ( sup_contact_cur%ISOPEN ) THEN
        CLOSE sup_contact_cur;
      END IF;
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_xxcmm             -- AvP[VZk¼FXXCMM
                   , iv_name         => cv_lock_err_msg           -- bZ[W¼FbNG[bZ[W
                   , iv_token_name1  => cv_tkn_ng_table           -- g[N¼1FNG_TABLE
                   , iv_token_value1 => cv_oic_cont_evac_tbl_msg  -- g[Nl1Fe[u¼FOICdüæSÒÞðe[u
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
      IF ( sup_contact_cur%ISOPEN ) THEN
        CLOSE sup_contact_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ¤ÊÖáOnh ***
    WHEN global_api_expt THEN
      -- J[\N[Y
      IF ( sup_contact_cur%ISOPEN ) THEN
        CLOSE sup_contact_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ¤ÊÖOTHERSáOnh ***
    WHEN global_api_others_expt THEN
      -- J[\N[Y
      IF ( sup_contact_cur%ISOPEN ) THEN
        CLOSE sup_contact_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERSáOnh ***
    WHEN OTHERS THEN
      -- J[\N[Y
      IF ( sup_contact_cur%ISOPEN ) THEN
        CLOSE sup_contact_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  Åè END   ##########################################
--
  END output_sup_contact;
--
--
  /**********************************************************************************
   * Procedure Name   : output_sup_contact_addr
   * Description      : uETvCESÒZvAgf[^ÌoEt@CoÍ(A-7)
   ***********************************************************************************/
  PROCEDURE output_sup_contact_addr(
    ov_errbuf     OUT VARCHAR2,     --   G[EbZ[W           --# Åè #
    ov_retcode    OUT VARCHAR2,     --   ^[ER[h             --# Åè #
    ov_errmsg     OUT VARCHAR2)     --   [U[EG[EbZ[W --# Åè #
  IS
    -- ===============================
    -- Åè[Jè
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'output_sup_contact_addr';       -- vO¼
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
    lv_file_data         VARCHAR2(30000) DEFAULT NULL;       -- oÍàe
--
    -- *** [JEJ[\ ***
    -- uETvCESÒZvÌoJ[\
    CURSOR sup_contact_addr_cur
    IS
      SELECT
-- Ver1.4(E125) Mod Start
--          (CASE
--             WHEN (    gt_pre_process_date IS NULL
--                   OR  pvc.creation_date > gt_pre_process_date) THEN
--               cv_status_create
--             ELSE
--               cv_status_update
--           END)                                          AS status_code                -- Xe[^XER[h
           cv_status_create                              AS status_code                -- Xe[^XER[h
-- Ver1.4(E125) Mod End
         , pv.vendor_name                                AS vendor_name                -- düæ¼
         , pvsa.vendor_site_code                         AS vendor_site_code           -- düæTCgR[h
-- Ver1.3 Mod Start
--         , pvc.first_name                                AS first_name                 -- düæSÒ¼(¼)
         , NVL(pvc.first_name, cv_ast)                   AS first_name                 -- düæSÒ¼(¼)
-- Ver1.3 Mod End
         , pvc.last_name                                 AS last_name                  -- düæSÒ¼(©)
         , pvc.email_address                             AS email_address              -- E[
      FROM
          po_vendor_contacts   pvc   -- düæSÒ
        , po_vendor_sites_all  pvsa  -- düæTCg
        , po_vendors           pv    -- düæ}X^
      WHERE
-- Ver1.4(E125) Mod Start
--          (   gt_pre_process_date IS NULL
--           OR pvc.last_update_date > gt_pre_process_date)
          (   gt_pre_process_date IS NULL
-- Ver1.11 Mod Start
--           OR pvc.creation_date > gt_pre_process_date)
           OR (    pvc.creation_date > gt_pre_process_date
               AND pvc.creation_date <= gt_cur_process_date)
          )
-- Ver1.11 Mod End
-- Ver1.4(E125) Mod End
      AND pvc.vendor_site_id = pvsa.vendor_site_id
      AND pvsa.org_id        = gt_target_organization_id
      AND pvsa.vendor_id     = pv.vendor_id
      AND NVL(pv.vendor_type_lookup_code, 'X') <> cv_employee
      ORDER BY
          pv.segment1           ASC  -- düæÔ
        , pvsa.vendor_site_code ASC  -- düæTCgR[h
        , pvc.vendor_contact_id ASC  -- düæSÒID
    ;
--
    -- *** [JER[h ***
    -- uETvCESÒZvÌoJ[\R[h
    l_sup_contact_addr_rec     sup_contact_addr_cur%ROWTYPE;
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
    -- uETvCESÒZvÌo
    -- ==============================================================
    -- J[\I[v
    OPEN  sup_contact_addr_cur;
    <<output_sup_contact_addr_loop>>
    LOOP
      --
      FETCH sup_contact_addr_cur INTO l_sup_contact_addr_rec;
      EXIT WHEN sup_contact_addr_cur%NOTFOUND;
      --
      -- oJEgAbv
      gn_get_cont_addr_cnt := gn_get_cont_addr_cnt + 1;
      --
      -- ==============================================================
      -- uETvCESÒZvÌt@CoÍ
      -- ==============================================================
      -- f[^sÌì¬
      lv_file_data := l_sup_contact_addr_rec.status_code;             -- 1 : Import Action * (Xe[^XER[h)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string(
-- Ver1.6 Mod Start
--                        l_sup_contact_addr_rec.vendor_name
                        xxccp_oiccommon_pkg.trim_space_tab(l_sup_contact_addr_rec.vendor_name)
-- Ver1.6 Mod End
                      , l_sup_contact_addr_rec.status_code
                      );                                              -- 2 : Supplier Name* (TvC¼Ì)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string(
-- Ver1.6 Mod Start
--                        l_sup_contact_addr_rec.vendor_site_code
                        xxccp_oiccommon_pkg.trim_space_tab(l_sup_contact_addr_rec.vendor_site_code)
-- Ver1.6 Mod End
                      , l_sup_contact_addr_rec.status_code
                      );                                              -- 3 : Address Name * (Z¼)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string(
                        l_sup_contact_addr_rec.first_name
                      , l_sup_contact_addr_rec.status_code
                      );                                              -- 4 : First Name (¼)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string(
                        l_sup_contact_addr_rec.last_name
                      , l_sup_contact_addr_rec.status_code
                      );                                              -- 5 : Last Name (©)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string(
                        l_sup_contact_addr_rec.email_address
                      , l_sup_contact_addr_rec.status_code
                      );                                              -- 6 : E-Mail (E[)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 7 : Batch ID (ob`ID)
      --
      BEGIN
        -- f[^sÌt@CoÍ
        UTL_FILE.PUT_LINE( gf_cont_addr_file_handle
                         , lv_file_data
                         );
        --
        -- oÍJEgAbv
        gn_out_cont_addr_cnt := gn_out_cont_addr_cnt + 1;
      EXCEPTION
        WHEN OTHERS THEN
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
          lv_errbuf := lv_errmsg;
          RAISE global_process_expt;
      END;
    --
    END LOOP output_sup_contact_addr_loop;
--
    -- J[\N[Y
    CLOSE sup_contact_addr_cur;
--
  EXCEPTION
--
--#################################  ÅèáO START   ####################################
--
    -- *** ¤ÊáOnh ***
    WHEN global_process_expt THEN
      -- J[\N[Y
      IF ( sup_contact_addr_cur%ISOPEN ) THEN
        CLOSE sup_contact_addr_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ¤ÊÖáOnh ***
    WHEN global_api_expt THEN
      -- J[\N[Y
      IF ( sup_contact_addr_cur%ISOPEN ) THEN
        CLOSE sup_contact_addr_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ¤ÊÖOTHERSáOnh ***
    WHEN global_api_others_expt THEN
      -- J[\N[Y
      IF ( sup_contact_addr_cur%ISOPEN ) THEN
        CLOSE sup_contact_addr_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERSáOnh ***
    WHEN OTHERS THEN
      -- J[\N[Y
      IF ( sup_contact_addr_cur%ISOPEN ) THEN
        CLOSE sup_contact_addr_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  Åè END   ##########################################
--
  END output_sup_contact_addr;
--
--
  /**********************************************************************************
   * Procedure Name   : output_sup_payee
   * Description      : uFTvCEx¥ævAgf[^ÌoEt@CoÍ(A-8)
   ***********************************************************************************/
  PROCEDURE output_sup_payee(
    ov_errbuf     OUT VARCHAR2,     --   G[EbZ[W           --# Åè #
    ov_retcode    OUT VARCHAR2,     --   ^[ER[h             --# Åè #
    ov_errmsg     OUT VARCHAR2)     --   [U[EG[EbZ[W --# Åè #
  IS
    -- ===============================
    -- Åè[Jè
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'output_sup_payee';       -- vO¼
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
    lv_file_data         VARCHAR2(30000) DEFAULT NULL;       -- oÍàe
--
    -- *** [JEJ[\ ***
    -- uFTvCEx¥ævÌoJ[\
    CURSOR sup_payee_cur
    IS
-- Ver1.8 Add Start
      WITH add_filter AS (
        SELECT
            pvsa.vendor_id                   AS vendor_id
          , pvsa.vendor_site_id              AS vendor_site_id
-- Ver1.10 Mod Start
--          , pv.last_update_date              AS last_update_date_pv
--          , pvsa.last_update_date            AS last_update_date_pvsa
--          , abaua.last_update_date           AS last_update_date_abaua
          , pv.creation_date                 AS creation_date_pv
          , pvsa.creation_date               AS creation_date_pvsa
-- Ver1.14 Mod Start
--          , abaua.creation_date              AS creation_date_abaua
          , abaua.last_update_date           AS last_update_date_abaua
-- Ver1.14 Mod End
-- Ver1.10 Mod End
          , abaa.last_update_date            AS last_update_date_abaa
-- Ver1.12 Add Start
          , abb. last_update_date            AS last_update_date_abb
-- Ver1.12 Add End
          , (CASE
               WHEN (   NVL(xobae.bank_account_num, '@')   <> NVL(abaa.bank_account_num, '@')
                     OR NVL(xobae.bank_number, '@')        <> NVL(abb.bank_number, '@')
                     OR NVL(xobae.bank_branch_number, '@') <> NVL(abb.bank_num, '@') ) THEN
                 cv_y
               ELSE
                 cv_n
             END)                            AS spec_items_chg_flag
        FROM
            ap_bank_branches          abb    -- âsxX
          , ap_bank_accounts_all      abaa   -- âsûÀ
          , ap_bank_account_uses_all  abaua  -- âsûÀgp
          , po_vendor_sites_all       pvsa   -- düæTCg
          , po_vendors                pv     -- düæ}X^
          , xxcmm_oic_bank_acct_evac  xobae  -- OICâsûÀÞðe[u
        WHERE
-- Ver1.11 Mod Start
--            (   abaa.last_update_date  > gt_pre_process_date
--             OR abaua.last_update_date > gt_pre_process_date)
            (   (      abaa.last_update_date  > gt_pre_process_date
                   AND abaa.last_update_date  <= gt_cur_process_date)
             OR (      abaua.last_update_date > gt_pre_process_date
-- Ver1.12 Mod Start
--                   AND abaua.last_update_date <= gt_cur_process_date))
                   AND abaua.last_update_date <= gt_cur_process_date)
             OR (
                       abb.last_update_date > gt_pre_process_date
                   AND abb.last_update_date <= gt_cur_process_date)
            )
-- Ver1.12 Mod End
-- Ver1.11 Mod End
        AND abb.bank_branch_id   = abaa.bank_branch_id
        AND abaa.bank_account_id = abaua.external_bank_account_id
        AND abaua.vendor_id      = pvsa.vendor_id
        AND abaua.vendor_site_id = pvsa.vendor_site_id
        AND pvsa.org_id          = gt_target_organization_id
        AND pvsa.vendor_id       = pv.vendor_id
        AND NVL(pv.vendor_type_lookup_code, 'X') <> cv_employee
        AND abaa.bank_account_id = xobae.bank_account_id (+)
      )
-- Ver1.8 Add End
      SELECT
          pvsa.vendor_site_id                            AS vendor_site_id             -- düæTCgID
        , pv.segment1                                    AS segment1                   -- düæÔ
        , pvsa.vendor_site_code                          AS vendor_site_code           -- düæTCgR[h
        , pvsa.exclusive_payment_flag                    AS exclusive_payment_flag     -- ÂÊx¥
        , pvsa.pay_group_lookup_code                     AS pay_group_lookup_code      -- x¥O[v
        , (CASE
              WHEN pvsa.remittance_email IS NOT NULL THEN
                cv_email
              ELSE
                NULL 
            END)                                         AS remit_delivery_method      -- àÊmû@
        , pvsa.remittance_email                          AS remittance_email           -- tæE-MailAhX
-- Ver1.5 Add Start
        , (CASE 
            WHEN ( gt_pre_process_date IS NULL ) THEN 
-- Ver1.9 Mod Start
--              TO_CHAR( gt_cur_process_date , cv_datetime_id_fmt ) || MOD( pv.vendor_id , cn_divisor_ten )
              TO_CHAR( gt_cur_process_date , cv_datetime_id_fmt ) || MOD( pv.vendor_id , gn_parallel_num )
-- Ver1.9 Mod End
            ELSE
              TO_CHAR( gt_cur_process_date , cv_datetime_id_fmt )
          END)                                           AS batch_id                   -- ob`ID
-- Ver1.5 Add End
      FROM
          po_vendor_sites_all  pvsa  -- düæTCg
        , po_vendors           pv    -- düæ}X^
      WHERE
          pvsa.org_id    = gt_target_organization_id
      AND pvsa.vendor_id = pv.vendor_id
      AND NVL(pv.vendor_type_lookup_code, 'X') <> cv_employee
-- Ver1.12 Add Start
      AND ( pvsa.inactive_date IS NULL
            OR pvsa.inactive_date > gt_cur_process_date
          )
      AND ( pv.end_date_active IS NULL
            OR pv.end_date_active > gt_cur_process_date
          )
-- Ver1.12 Add End
      AND EXISTS (
              SELECT
                  1  AS flag
              FROM
                  ap_bank_accounts_all      abaa
                  ,ap_bank_account_uses_all  abaua
-- Ver1.12 Add Start
                  ,ap_bank_branches         abb
-- Ver1.12 Add End
              WHERE
                  (   gt_pre_process_date IS NULL
-- Ver1.11 Mod Start
--                   OR abaa.last_update_date  > gt_pre_process_date
--                   OR abaua.last_update_date > gt_pre_process_date)
                   OR (    abaa.last_update_date  > gt_pre_process_date
                       AND abaa.last_update_date  <= gt_cur_process_date)
                   OR (    abaua.last_update_date > gt_pre_process_date
                       AND abaua.last_update_date <= gt_cur_process_date)
-- Ver1.12 Add Start
                   OR (    abb.last_update_date > gt_pre_process_date
                       AND abb.last_update_date <= gt_cur_process_date)
-- Ver1.12 Add End
                  )
-- Ver1.11 Mod End
-- Ver1.12 Add Start
              AND abb.bank_branch_id   = abaa.bank_branch_id
-- Ver1.12 Add End
              AND abaa.bank_account_id = abaua.external_bank_account_id
              AND abaua.vendor_id      = pvsa.vendor_id
              AND abaua.vendor_site_id = pvsa.vendor_site_id
          )
-- Ver1.8 Add Start
      AND (
            gt_pre_process_date IS NULL
            OR
            EXISTS (
                SELECT
                    1  AS flag
                FROM
                    add_filter  af
                WHERE
                    af.vendor_id      = pvsa.vendor_id
                AND af.vendor_site_id = pvsa.vendor_site_id
-- Ver1.10 Mod Start
--                AND ((   af.last_update_date_pv    > gt_pre_process_date
--                      OR af.last_update_date_pvsa  > gt_pre_process_date
--                      OR af.last_update_date_abaua > gt_pre_process_date
-- Ver1.11 Mod Start
--                AND ((   af.creation_date_pv    > gt_pre_process_date
--                      OR af.creation_date_pvsa  > gt_pre_process_date
--                      OR af.creation_date_abaua > gt_pre_process_date
                AND ((   (    af.creation_date_pv    > gt_pre_process_date
                          AND af.creation_date_pv    <= gt_cur_process_date)
                      OR (    af.creation_date_pvsa  > gt_pre_process_date
                          AND af.creation_date_pvsa  <= gt_cur_process_date)
-- Ver1.14 Mod Start
--                      OR (    af.creation_date_abaua > gt_pre_process_date
--                          AND af.creation_date_abaua <= gt_cur_process_date)
                      OR (    af.last_update_date_abaua > gt_pre_process_date
                          AND af.last_update_date_abaua <= gt_cur_process_date)
-- Ver1.14 Mod End
-- Ver1.11 Mod End
-- Ver1.10 Mod End
                     )
                     OR
-- Ver1.11 Mod Start
--                     (    af.last_update_date_abaa > gt_pre_process_date
-- Ver1.12 Mod Start
--                     (  (      af.last_update_date_abaa > gt_pre_process_date
--                           AND af.last_update_date_abaa <= gt_cur_process_date)
                     ((  (      af.last_update_date_abaa > gt_pre_process_date
                           AND af.last_update_date_abaa <= gt_cur_process_date)
                      OR (    af.last_update_date_abb > gt_pre_process_date
                              AND af.last_update_date_abb <= gt_cur_process_date)
                      )
-- Ver1.12 Mod End
-- Ver1.11 Mod End
                      AND af.spec_items_chg_flag = cv_y
                     ))
            )
          )
-- Ver1.8 Add End
      ORDER BY
          pv.segment1           ASC  -- düæÔ
        , pvsa.vendor_site_code ASC  -- düæTCgR[h
    ;
--
    -- *** [JER[h ***
    -- uFTvCEx¥ævÌoJ[\R[h
    l_sup_payee_rec     sup_payee_cur%ROWTYPE;
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
    -- uFTvCEx¥ævÌo
    -- ==============================================================
    -- J[\I[v
    OPEN  sup_payee_cur;
    <<output_sup_payee_loop>>
    LOOP
      --
      FETCH sup_payee_cur INTO l_sup_payee_rec;
      EXIT WHEN sup_payee_cur%NOTFOUND;
      --
      -- oJEgAbv
      gn_get_payee_cnt := gn_get_payee_cnt + 1;
      --
      -- ==============================================================
      -- uFTvCEx¥ævÌt@CoÍ
      -- ==============================================================
      -- f[^sÌì¬
-- Ver1.5 Mod Start
--      lv_file_data := TO_CHAR( gt_cur_process_date , cv_datetime_id_fmt );      --  1 : *Import Batch Identifier (C|[gEob`¯Êq)
      lv_file_data := l_sup_payee_rec.batch_id;                                 --  1 : *Import Batch Identifier (C|[gEob`¯Êq)
-- Ver1.5 Mod End
      lv_file_data := lv_file_data || cv_comma || 
                      l_sup_payee_rec.vendor_site_id;                           --  2 : *Payee Identifier (x¥æ¯Êq)
      lv_file_data := lv_file_data || cv_comma || cv_sales_bu;                  --  3 : Business Unit Name (rWlXEjbg¼)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string( l_sup_payee_rec.segment1 );                --  4 : *Supplier Number (TvCÔ)
      lv_file_data := lv_file_data || cv_comma || 
-- Ver1.6 Mod Start
--                      to_csv_string( l_sup_payee_rec.vendor_site_code );        --  5 : Supplier Site (TvCETCg¼)
                      to_csv_string( 
                        xxccp_oiccommon_pkg.trim_space_tab(l_sup_payee_rec.vendor_site_code)
                      );                                                        --  5 : Supplier Site (TvCETCg¼)
-- Ver1.6 Mod End
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string( l_sup_payee_rec.exclusive_payment_flag );  --  6 : *Pay Each Document Alone (r¼x¥tO)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string( l_sup_payee_rec.pay_group_lookup_code );   --  7 : Payment Method Code (x¥û@R[h)
      lv_file_data := lv_file_data || cv_comma || NULL;                         --  8 : Delivery Channel Code (x¥`lR[h)
      lv_file_data := lv_file_data || cv_comma || cv_express;                   --  9 : Settlement Priority (ÏDæx)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string( l_sup_payee_rec.remit_delivery_method );   -- 10 : Remit Delivery Method (àÊmû@)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string( l_sup_payee_rec.remittance_email );        -- 11 : Remit Advice Email (àÊm[AhX)
      lv_file_data := lv_file_data || cv_comma || NULL;                         -- 12 : Remit Advice Fax (àÊmFax)
      lv_file_data := lv_file_data || cv_comma || NULL;                         -- 13 : Bank Instructions 1 (âsw}1)
      lv_file_data := lv_file_data || cv_comma || NULL;                         -- 14 : Bank Instructions 2 (âsw}2)
      lv_file_data := lv_file_data || cv_comma || NULL;                         -- 15 : Bank Instruction Details (âsw}Ú×)
      lv_file_data := lv_file_data || cv_comma || NULL;                         -- 16 : Payment Reason Code (x¥RR[h)
      lv_file_data := lv_file_data || cv_comma || NULL;                         -- 17 : Payment Reason Comments (x¥RRg)
      lv_file_data := lv_file_data || cv_comma || NULL;                         -- 18 : Payment Message1 (x¥bZ[W1)
      lv_file_data := lv_file_data || cv_comma || NULL;                         -- 19 : Payment Message2 (x¥bZ[W2)
      lv_file_data := lv_file_data || cv_comma || NULL;                         -- 20 : Payment Message3 (x¥bZ[W3)
      lv_file_data := lv_file_data || cv_comma || NULL;                         -- 21 : Bank Charge Bearer Code (è¿SÒR[h)
      --
      BEGIN
        -- f[^sÌt@CoÍ
        UTL_FILE.PUT_LINE( gf_payee_file_handle
                         , lv_file_data
                         );
        --
        -- oÍJEgAbv
        gn_out_payee_cnt := gn_out_payee_cnt + 1;
      EXCEPTION
        WHEN OTHERS THEN
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
          lv_errbuf := lv_errmsg;
          RAISE global_process_expt;
      END;
    --
    END LOOP output_sup_payee_loop;
--
    -- J[\N[Y
    CLOSE sup_payee_cur;
--
  EXCEPTION
--
--#################################  ÅèáO START   ####################################
--
    -- *** ¤ÊáOnh ***
    WHEN global_process_expt THEN
      -- J[\N[Y
      IF ( sup_payee_cur%ISOPEN ) THEN
        CLOSE sup_payee_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ¤ÊÖáOnh ***
    WHEN global_api_expt THEN
      -- J[\N[Y
      IF ( sup_payee_cur%ISOPEN ) THEN
        CLOSE sup_payee_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ¤ÊÖOTHERSáOnh ***
    WHEN global_api_others_expt THEN
      -- J[\N[Y
      IF ( sup_payee_cur%ISOPEN ) THEN
        CLOSE sup_payee_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERSáOnh ***
    WHEN OTHERS THEN
      -- J[\N[Y
      IF ( sup_payee_cur%ISOPEN ) THEN
        CLOSE sup_payee_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  Åè END   ##########################################
--
  END output_sup_payee;
--
--
  /**********************************************************************************
   * Procedure Name   : output_sup_bank_acct
   * Description      : uGTvCEâsûÀvAgf[^ÌoEt@CoÍ(A-9)
   ***********************************************************************************/
  PROCEDURE output_sup_bank_acct(
    ov_errbuf     OUT VARCHAR2,     --   G[EbZ[W           --# Åè #
    ov_retcode    OUT VARCHAR2,     --   ^[ER[h             --# Åè #
    ov_errmsg     OUT VARCHAR2)     --   [U[EG[EbZ[W --# Åè #
  IS
    -- ===============================
    -- Åè[Jè
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'output_sup_bank_acct';       -- vO¼
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
    lv_file_data         VARCHAR2(30000) DEFAULT NULL;       -- oÍàe
--
    -- *** [JEJ[\ ***
    -- uGTvCEâsûÀvÌoJ[\
    CURSOR sup_bank_acct_cur
    IS
-- Ver1.8 Add Start
      WITH add_filter AS (
        SELECT
            pvsa.vendor_id                   AS vendor_id
          , pvsa.vendor_site_id              AS vendor_site_id
-- Ver1.10 Mod Start
--          , pv.last_update_date              AS last_update_date_pv
--          , pvsa.last_update_date            AS last_update_date_pvsa
--          , abaua.last_update_date           AS last_update_date_abaua
          , pv.creation_date                 AS creation_date_pv
          , pvsa.creation_date               AS creation_date_pvsa
-- Ver1.14 Mod Start
--          , abaua.creation_date              AS creation_date_abaua
          , abaua.last_update_date           AS last_update_date_abaua
-- Ver1.14 Mod End
-- Ver1.10 Mod End
          , abaa.last_update_date            AS last_update_date_abaa
-- Ver1.12 Add Start
          , abb. last_update_date            AS last_update_date_abb
-- Ver1.12 Add End
          , (CASE
               WHEN (   NVL(xobae.bank_account_num, '@')   <> NVL(abaa.bank_account_num, '@')
                     OR NVL(xobae.bank_number, '@')        <> NVL(abb.bank_number, '@')
                     OR NVL(xobae.bank_branch_number, '@') <> NVL(abb.bank_num, '@') ) THEN
                 cv_y
               ELSE
                 cv_n
             END)                            AS spec_items_chg_flag
        FROM
            ap_bank_branches          abb    -- âsxX
          , ap_bank_accounts_all      abaa   -- âsûÀ
          , ap_bank_account_uses_all  abaua  -- âsûÀgp
          , po_vendor_sites_all       pvsa   -- düæTCg
          , po_vendors                pv     -- düæ}X^
          , xxcmm_oic_bank_acct_evac  xobae  -- OICâsûÀÞðe[u
        WHERE
-- Ver1.11 Mod Start
--            (   abaa.last_update_date  > gt_pre_process_date
--             OR abaua.last_update_date > gt_pre_process_date)
            (   (      abaa.last_update_date  > gt_pre_process_date
                   AND abaa.last_update_date  <= gt_cur_process_date)
             OR (      abaua.last_update_date > gt_pre_process_date
-- Ver1.12 Mod Start
--                   AND abaua.last_update_date <= gt_cur_process_date))
                   AND abaua.last_update_date <= gt_cur_process_date)
             OR (      abb.last_update_date > gt_pre_process_date
                   AND abb.last_update_date <= gt_cur_process_date)
            )
-- Ver1.12 Mod End
-- Ver1.11 Mod End
        AND abb.bank_branch_id   = abaa.bank_branch_id
        AND abaa.bank_account_id = abaua.external_bank_account_id
        AND abaua.vendor_id      = pvsa.vendor_id
        AND abaua.vendor_site_id = pvsa.vendor_site_id
        AND pvsa.org_id          = gt_target_organization_id
        AND pvsa.vendor_id       = pv.vendor_id
        AND NVL(pv.vendor_type_lookup_code, 'X') <> cv_employee
        AND abaa.bank_account_id = xobae.bank_account_id (+)
      )
-- Ver1.8 Add End
      SELECT
          pvsa.vendor_site_id                            AS vendor_site_id             -- düæTCgID
        , abaua.bank_account_uses_id                     AS bank_account_uses_id       -- âsûÀgpID
        , abb.bank_name                                  AS bank_name                  -- âs¼
        , abb.bank_branch_name                           AS bank_branch_name           -- âsxX¼
-- Ver1.1 Mod Start
--        , abb.country                                    AS country                    -- 
        , NVL(abb.country, cv_jp)                        AS country                    -- 
-- Ver1.1 Mod End
        , abaa.account_holder_name                       AS account_holder_name        -- ûÀ¼`l
-- Ver1.14 Mod Start
--        , (CASE
--             WHEN xobae.bank_account_id IS NOT NULL THEN
--               xobae.bank_account_num
--             ELSE
--               abaa.bank_account_num
--           END)                                          AS bank_account_num           -- âsûÀÔ
        , abaa.bank_account_num                          AS bank_account_num           -- âsûÀÔ
-- Ver1.14 Mod End
-- Ver1.4(E126) Mod Start
--        , abaa.currency_code                             AS currency_code              -- ÊÝ
        , NVL(abaa.currency_code, cv_yen)                AS currency_code              -- ÊÝ
-- Ver1.4(E126) Mod End
        , abaa.multi_currency_flag                       AS multi_currency_flag        -- ½ÊÝ@\
        , TO_CHAR(abaa.creation_date, cv_date_fmt)       AS creation_date              -- ì¬ú
        , TO_CHAR(abaa.inactive_date, cv_date_fmt)       AS inactive_date              -- ñANeBuú
        , abaa.account_holder_name_alt                   AS account_holder_name_alt    -- ûÀ¼`lJi
        , abaa.bank_account_type                         AS bank_account_type          -- âsûÀÌíÞ
        , abaa.bank_account_name                         AS bank_account_name          -- âsûÀ¼
-- Ver1.5 Add Start
        , (CASE 
            WHEN ( gt_pre_process_date IS NULL ) THEN 
-- Ver1.9 Mod Start
--              TO_CHAR( gt_cur_process_date , cv_datetime_id_fmt ) || MOD( pv.vendor_id , cn_divisor_ten )
              TO_CHAR( gt_cur_process_date , cv_datetime_id_fmt ) || MOD( pv.vendor_id , gn_parallel_num )
-- Ver1.9 Mod End
            ELSE
              TO_CHAR( gt_cur_process_date , cv_datetime_id_fmt )
          END)                                           AS batch_id                   -- ob`ID
-- Ver1.5 Add End
      FROM
          ap_bank_branches          abb    -- âsxX
        , ap_bank_accounts_all      abaa   -- âsûÀ
        , ap_bank_account_uses_all  abaua  -- âsûÀgp
        , po_vendor_sites_all       pvsa   -- düæTCg
        , po_vendors                pv     -- düæ}X^
        , xxcmm_oic_bank_acct_evac  xobae  -- OICâsûÀÞðe[u
      WHERE
          (   gt_pre_process_date IS NULL
-- Ver1.11 Mod Start
--           OR abaa.last_update_date  > gt_pre_process_date
--           OR abaua.last_update_date > gt_pre_process_date)
              OR (   (      abaa.last_update_date  > gt_pre_process_date
                        AND abaa.last_update_date  <= gt_cur_process_date)
              OR (          abaua.last_update_date > gt_pre_process_date
-- Ver1.12 Mod Start             
--                        AND abaua.last_update_date <= gt_cur_process_date))
                        AND abaua.last_update_date <= gt_cur_process_date)
              OR (          abb.last_update_date > gt_pre_process_date
                        AND abb.last_update_date <= gt_cur_process_date)
                )
           )
-- Ver1.12 Mod End
-- Ver1.11 Mod End
      AND abb.bank_branch_id   = abaa.bank_branch_id
      AND abaa.bank_account_id = abaua.external_bank_account_id
      AND abaua.vendor_id      = pvsa.vendor_id
      AND abaua.vendor_site_id = pvsa.vendor_site_id
      AND pvsa.org_id          = gt_target_organization_id
      AND pvsa.vendor_id       = pv.vendor_id
      AND NVL(pv.vendor_type_lookup_code, 'X') <> cv_employee
      AND abaa.bank_account_id = xobae.bank_account_id (+)
-- Ver1.12 Add Start
      AND ( pvsa.inactive_date IS NULL
            OR pvsa.inactive_date > gt_cur_process_date
          )
      AND ( pv.end_date_active IS NULL
            OR pv.end_date_active > gt_cur_process_date
          )
-- Ver1.12 Add End
-- Ver1.8 Add Start
      AND (
            gt_pre_process_date IS NULL
            OR
            EXISTS (
                SELECT
                    1  AS flag
                FROM
                    add_filter  af
                WHERE
                    af.vendor_id      = pvsa.vendor_id
                AND af.vendor_site_id = pvsa.vendor_site_id
-- Ver1.10 Mod Start
--                AND ((   af.last_update_date_pv    > gt_pre_process_date
--                      OR af.last_update_date_pvsa  > gt_pre_process_date
--                      OR af.last_update_date_abaua > gt_pre_process_date
-- Ver1.11 Mod Start
--                AND ((   af.creation_date_pv    > gt_pre_process_date
--                      OR af.creation_date_pvsa  > gt_pre_process_date
--                      OR af.creation_date_abaua > gt_pre_process_date
                AND ((   (    af.creation_date_pv    > gt_pre_process_date
                          AND af.creation_date_pv    <= gt_cur_process_date)
                      OR (    af.creation_date_pvsa  > gt_pre_process_date
                          AND af.creation_date_pvsa  <= gt_cur_process_date)
-- Ver1.14 Mod Start
--                      OR (    af.creation_date_abaua > gt_pre_process_date
--                          AND af.creation_date_abaua <= gt_cur_process_date)
                      OR (    af.last_update_date_abaua > gt_pre_process_date
                          AND af.last_update_date_abaua <= gt_cur_process_date)
-- Ver1.14 Mod End
-- Ver1.11 Mod End
-- Ver1.10 Mod End
                     )
                     OR
-- Ver1.11 Mod Start
--                     (    af.last_update_date_abaa > gt_pre_process_date
-- Ver1.12 Mod Start
--                     (  (      af.last_update_date_abaa > gt_pre_process_date
--                           AND af.last_update_date_abaa <= gt_cur_process_date)
                     ((  (      af.last_update_date_abaa > gt_pre_process_date
                           AND af.last_update_date_abaa <= gt_cur_process_date)
                      OR (    af.last_update_date_abb > gt_pre_process_date
                              AND af.last_update_date_abb <= gt_cur_process_date)
                      )
-- Ver1.12 Mod End
-- Ver1.11 Mod End
                      AND af.spec_items_chg_flag = cv_y
                     ))
            )
          )
-- Ver1.8 Add End
      ORDER BY
          pv.segment1           ASC  -- düæÔ
        , pvsa.vendor_site_code ASC  -- düæTCgR[h
        , abaa.bank_account_num ASC  -- âsûÀÔ
    ;
--
    -- *** [JER[h ***
    -- uGTvCEâsûÀvÌoJ[\R[h
    l_sup_bank_acct_rec     sup_bank_acct_cur%ROWTYPE;
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
    -- uGTvCEâsûÀvÌo
    -- ==============================================================
    -- J[\I[v
    OPEN  sup_bank_acct_cur;
    <<output_sup_bank_acct_loop>>
    LOOP
      --
      FETCH sup_bank_acct_cur INTO l_sup_bank_acct_rec;
      EXIT WHEN sup_bank_acct_cur%NOTFOUND;
      --
      -- oJEgAbv
      gn_get_bnk_acct_cnt := gn_get_bnk_acct_cnt + 1;
      --
      -- ==============================================================
      -- uGTvCEâsûÀvÌt@CoÍ
      -- ==============================================================
      -- f[^sÌì¬
-- Ver1.5 Mod Start
--      lv_file_data := TO_CHAR( gt_cur_process_date , cv_datetime_id_fmt );           --  1 : *Import Batch Identifier (C|[gEob`¯Êq)
      lv_file_data := l_sup_bank_acct_rec.batch_id;                                  --  1 : *Import Batch Identifier (C|[gEob`¯Êq)
-- Ver1.5 Mod End
      lv_file_data := lv_file_data || cv_comma || 
                      l_sup_bank_acct_rec.vendor_site_id;                            --  2 : *Payee Identifier (x¥æ¯Êq)
      lv_file_data := lv_file_data || cv_comma || 
                      l_sup_bank_acct_rec.bank_account_uses_id;                      --  3 : *Payee Bank Account Identifier (x¥æâsûÀ¯Êq)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string( l_sup_bank_acct_rec.bank_name );                --  4 : **Bank Name (âs¼)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string( l_sup_bank_acct_rec.bank_branch_name );         --  5 : **Branch Name (âsxX¼)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string( l_sup_bank_acct_rec.country );                  --  6 : *Account Country Code (ûÀR[h)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string( l_sup_bank_acct_rec.account_holder_name );      --  7 : Account Name (ûÀ¼)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string( l_sup_bank_acct_rec.bank_account_num );         --  8 : *Account Number (ûÀÔ)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string( l_sup_bank_acct_rec.currency_code );            --  9 : Account Currency Code (ûÀÊÝR[h)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string( l_sup_bank_acct_rec.multi_currency_flag );      -- 10 : Allow International Payments (Ox¥ÂtO)
      lv_file_data := lv_file_data || cv_comma || 
                      l_sup_bank_acct_rec.creation_date;                             -- 11 : Account Start Date (útF©)
      lv_file_data := lv_file_data || cv_comma || 
                      l_sup_bank_acct_rec.inactive_date;                             -- 12 : Account End Date (ñANeBuú)
      lv_file_data := lv_file_data || cv_comma || NULL;                              -- 13 : IBAN (IBAN)
      lv_file_data := lv_file_data || cv_comma || NULL;                              -- 14 : Check Digits (`FbNEfBWbg)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string( l_sup_bank_acct_rec.account_holder_name_alt );  -- 15 : Account Alternate Name (ûÀÊ¼)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string( l_sup_bank_acct_rec.bank_account_type );        -- 16 : Account Type Code (ûÀ^CvR[h)
      lv_file_data := lv_file_data || cv_comma || NULL;                              -- 17 : Account Suffix (ûÀÚö«)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string( l_sup_bank_acct_rec.bank_account_name );        -- 18 : Account Description (ûÀEv)
      lv_file_data := lv_file_data || cv_comma || NULL;                              -- 19 : Agency Location Code (ãXÝnR[h)
      lv_file_data := lv_file_data || cv_comma || NULL;                              -- 20 : Exchange Rate Agreement Number (×Ö[g_ñÔ)
      lv_file_data := lv_file_data || cv_comma || NULL;                              -- 21 : Exchange Rate Agreement Type (×Ö[g_ñ^Cv)
      lv_file_data := lv_file_data || cv_comma || NULL;                              -- 22 : Exchange Rate (×Ö[g)
      lv_file_data := lv_file_data || cv_comma || NULL;                              -- 23 : Secondary Account Reference (æñQÆûÀ)
      lv_file_data := lv_file_data || cv_comma || NULL;                              -- 24 : Attribute Category (ÇÁîñJeS)
      lv_file_data := lv_file_data || cv_comma || NULL;                              -- 25 : Attribute 1 (ÇÁîñ1)
      lv_file_data := lv_file_data || cv_comma || NULL;                              -- 26 : Attribute 2 (ÇÁîñ2)
      lv_file_data := lv_file_data || cv_comma || NULL;                              -- 27 : Attribute 3 (ÇÁîñ3)
      lv_file_data := lv_file_data || cv_comma || NULL;                              -- 28 : Attribute 4 (ÇÁîñ4)
      lv_file_data := lv_file_data || cv_comma || NULL;                              -- 29 : Attribute 5 (ÇÁîñ5)
      lv_file_data := lv_file_data || cv_comma || NULL;                              -- 30 : Attribute 6 (ÇÁîñ6)
      lv_file_data := lv_file_data || cv_comma || NULL;                              -- 31 : Attribute 7 (ÇÁîñ7)
      lv_file_data := lv_file_data || cv_comma || NULL;                              -- 32 : Attribute 8 (ÇÁîñ8)
      lv_file_data := lv_file_data || cv_comma || NULL;                              -- 33 : Attribute 9 (ÇÁîñ9)
      lv_file_data := lv_file_data || cv_comma || NULL;                              -- 34 : Attribute 10 (ÇÁîñ10)
      lv_file_data := lv_file_data || cv_comma || NULL;                              -- 35 : Attribute 11 (ÇÁîñ11)
      lv_file_data := lv_file_data || cv_comma || NULL;                              -- 36 : Attribute 12 (ÇÁîñ12)
      lv_file_data := lv_file_data || cv_comma || NULL;                              -- 37 : Attribute 13 (ÇÁîñ13)
      lv_file_data := lv_file_data || cv_comma || NULL;                              -- 38 : Attribute 14 (ÇÁîñ14)
      lv_file_data := lv_file_data || cv_comma || NULL;                              -- 39 : Attribute 15 (ÇÁîñ15)
      --
      BEGIN
        -- f[^sÌt@CoÍ
        UTL_FILE.PUT_LINE( gf_bnk_acct_file_handle
                         , lv_file_data
                         );
        --
        -- oÍJEgAbv
        gn_out_bnk_acct_cnt := gn_out_bnk_acct_cnt + 1;
      EXCEPTION
        WHEN OTHERS THEN
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
          lv_errbuf := lv_errmsg;
          RAISE global_process_expt;
      END;
    --
    END LOOP output_sup_bank_acct_loop;
--
    -- J[\N[Y
    CLOSE sup_bank_acct_cur;
--
  EXCEPTION
--
--#################################  ÅèáO START   ####################################
--
    -- *** ¤ÊáOnh ***
    WHEN global_process_expt THEN
      -- J[\N[Y
      IF ( sup_bank_acct_cur%ISOPEN ) THEN
        CLOSE sup_bank_acct_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ¤ÊÖáOnh ***
    WHEN global_api_expt THEN
      -- J[\N[Y
      IF ( sup_bank_acct_cur%ISOPEN ) THEN
        CLOSE sup_bank_acct_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ¤ÊÖOTHERSáOnh ***
    WHEN global_api_others_expt THEN
      -- J[\N[Y
      IF ( sup_bank_acct_cur%ISOPEN ) THEN
        CLOSE sup_bank_acct_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERSáOnh ***
    WHEN OTHERS THEN
      -- J[\N[Y
      IF ( sup_bank_acct_cur%ISOPEN ) THEN
        CLOSE sup_bank_acct_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  Åè END   ##########################################
--
  END output_sup_bank_acct;
--
--
  /**********************************************************************************
   * Procedure Name   : output_sup_bank_use
   * Description      : uHTvCEâsûÀvAgf[^ÌoEt@CoÍ(A-10)
   ***********************************************************************************/
  PROCEDURE output_sup_bank_use(
    ov_errbuf     OUT VARCHAR2,     --   G[EbZ[W           --# Åè #
    ov_retcode    OUT VARCHAR2,     --   ^[ER[h             --# Åè #
    ov_errmsg     OUT VARCHAR2)     --   [U[EG[EbZ[W --# Åè #
  IS
    -- ===============================
    -- Åè[Jè
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'output_sup_bank_use';       -- vO¼
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
    lv_file_data         VARCHAR2(30000) DEFAULT NULL;       -- oÍàe
--
    -- *** [JEJ[\ ***
    -- uHTvCEâsûÀvÌoJ[\
    CURSOR sup_bank_use_cur
    IS
-- Ver1.8 Add Start
      WITH add_filter AS (
        SELECT
            pvsa.vendor_id                   AS vendor_id
          , pvsa.vendor_site_id              AS vendor_site_id
-- Ver1.10 Mod Start
--          , pv.last_update_date              AS last_update_date_pv
--          , pvsa.last_update_date            AS last_update_date_pvsa
--          , abaua.last_update_date           AS last_update_date_abaua
          , pv.creation_date                 AS creation_date_pv
          , pvsa.creation_date               AS creation_date_pvsa
-- Ver1.14 Mod Start
--          , abaua.creation_date              AS creation_date_abaua
          , abaua.last_update_date           AS last_update_date_abaua
-- Ver1.14 Mod End
-- Ver1.10 Mod End
          , abaa.last_update_date            AS last_update_date_abaa
-- Ver1.12 Add Start
          , abb. last_update_date            AS last_update_date_abb
-- Ver1.12 Add End
          , (CASE
               WHEN (   NVL(xobae.bank_account_num, '@')   <> NVL(abaa.bank_account_num, '@')
                     OR NVL(xobae.bank_number, '@')        <> NVL(abb.bank_number, '@')
                     OR NVL(xobae.bank_branch_number, '@') <> NVL(abb.bank_num, '@') ) THEN
                 cv_y
               ELSE
                 cv_n
             END)                            AS spec_items_chg_flag
        FROM
            ap_bank_branches          abb    -- âsxX
          , ap_bank_accounts_all      abaa   -- âsûÀ
          , ap_bank_account_uses_all  abaua  -- âsûÀgp
          , po_vendor_sites_all       pvsa   -- düæTCg
          , po_vendors                pv     -- düæ}X^
          , xxcmm_oic_bank_acct_evac  xobae  -- OICâsûÀÞðe[u
        WHERE
-- Ver1.11 Mod Start
--            (   abaa.last_update_date  > gt_pre_process_date
--             OR abaua.last_update_date > gt_pre_process_date)
            (   (      abaa.last_update_date  > gt_pre_process_date
                   AND abaa.last_update_date  <= gt_cur_process_date)
             OR (      abaua.last_update_date > gt_pre_process_date
-- Ver1.12 Mod Start
--                   AND abaua.last_update_date <= gt_cur_process_date))
                   AND abaua.last_update_date <= gt_cur_process_date)
             OR (
                       abb.last_update_date > gt_pre_process_date
                   AND abb.last_update_date <= gt_cur_process_date)
            )
-- Ver1.12 Mod End
-- Ver1.11 Mod End
        AND abb.bank_branch_id   = abaa.bank_branch_id
        AND abaa.bank_account_id = abaua.external_bank_account_id
        AND abaua.vendor_id      = pvsa.vendor_id
        AND abaua.vendor_site_id = pvsa.vendor_site_id
        AND pvsa.org_id          = gt_target_organization_id
        AND pvsa.vendor_id       = pv.vendor_id
        AND NVL(pv.vendor_type_lookup_code, 'X') <> cv_employee
        AND abaa.bank_account_id = xobae.bank_account_id (+)
      )
-- Ver1.8 Add End
      SELECT
          pvsa.vendor_site_id                            AS vendor_site_id             -- düæTCgID
        , abaua.bank_account_uses_id                     AS bank_account_uses_id       -- âsûÀgpID
        , abaua.primary_flag                             AS primary_flag               -- vC}EtO
        , TO_CHAR(abaua.start_date, cv_date_fmt)         AS start_date                 -- Jnú
        , TO_CHAR(abaua.end_date, cv_date_fmt)           AS end_date                   -- I¹ú
-- Ver1.5 Add Start
        , (CASE 
            WHEN ( gt_pre_process_date IS NULL ) THEN 
-- Ver1.9 Mod Start
--              TO_CHAR( gt_cur_process_date , cv_datetime_id_fmt ) || MOD( pv.vendor_id , cn_divisor_ten )
              TO_CHAR( gt_cur_process_date , cv_datetime_id_fmt ) || MOD( pv.vendor_id , gn_parallel_num )
-- Ver1.9 Mod End
            ELSE
              TO_CHAR( gt_cur_process_date , cv_datetime_id_fmt )
          END)                                           AS batch_id                   -- ob`ID
-- Ver1.5 Add End
      FROM
          ap_bank_accounts_all      abaa   -- âsûÀ
        , ap_bank_account_uses_all  abaua  -- âsûÀgp
        , po_vendor_sites_all       pvsa   -- düæTCg
        , po_vendors                pv     -- düæ}X^
-- Ver1.12 Add Start
        , ap_bank_branches          abb    -- âsxX
-- Ver1.12 Add End
      WHERE
          (   gt_pre_process_date IS NULL
-- Ver1.11 Mod Start
--           OR abaa.last_update_date  > gt_pre_process_date
--           OR abaua.last_update_date > gt_pre_process_date)
             OR  (      abaa.last_update_date  > gt_pre_process_date
                   AND abaa.last_update_date  <= gt_cur_process_date)
             OR (      abaua.last_update_date > gt_pre_process_date
-- Ver1.12 Mod Start
--                   AND abaua.last_update_date <= gt_cur_process_date))
                   AND abaua.last_update_date <= gt_cur_process_date)
                   OR (    abb.last_update_date > gt_pre_process_date
                       AND abb.last_update_date <= gt_cur_process_date)
          )
-- Ver1.12 Mod End
-- Ver1.11 Mod End
-- Ver1.12 Add Start
      AND abb.bank_branch_id = abaa.bank_branch_id
-- Ver1.12 Add End
      AND abaa.bank_account_id = abaua.external_bank_account_id
      AND abaua.vendor_id      = pvsa.vendor_id
      AND abaua.vendor_site_id = pvsa.vendor_site_id
      AND pvsa.org_id          = gt_target_organization_id
      AND pvsa.vendor_id       = pv.vendor_id
      AND NVL(pv.vendor_type_lookup_code, 'X') <> cv_employee
-- Ver1.12 Add Start
      AND ( pvsa.inactive_date IS NULL
            OR pvsa.inactive_date > gt_cur_process_date
          )
      AND ( pv.end_date_active IS NULL
            OR pv.end_date_active > gt_cur_process_date
          )
-- Ver1.12 Add End
-- Ver1.8 Add Start
      AND (
            gt_pre_process_date IS NULL
            OR
            EXISTS (
                SELECT
                    1  AS flag
                FROM
                    add_filter  af
                WHERE
                    af.vendor_id      = pvsa.vendor_id
                AND af.vendor_site_id = pvsa.vendor_site_id
-- Ver1.10 Mod Start
--                AND ((   af.last_update_date_pv    > gt_pre_process_date
--                      OR af.last_update_date_pvsa  > gt_pre_process_date
--                      OR af.last_update_date_abaua > gt_pre_process_date
-- Ver1.11 Mod Start
--                AND ((   af.creation_date_pv    > gt_pre_process_date
--                      OR af.creation_date_pvsa  > gt_pre_process_date
--                      OR af.creation_date_abaua > gt_pre_process_date
                AND ((   (    af.creation_date_pv    > gt_pre_process_date
                          AND af.creation_date_pv    <= gt_cur_process_date)
                      OR (    af.creation_date_pvsa  > gt_pre_process_date
                          AND af.creation_date_pvsa  <= gt_cur_process_date)
-- Ver1.14 Mod Start
--                      OR (    af.creation_date_abaua > gt_pre_process_date
--                          AND af.creation_date_abaua <= gt_cur_process_date)
                      OR (    af.last_update_date_abaua > gt_pre_process_date
                          AND af.last_update_date_abaua <= gt_cur_process_date)
-- Ver1.14 Mod End
-- Ver1.11 Mod End
-- Ver1.10 Mod End
                     )
                     OR
-- Ver1.11 Mod Start
--                     (    af.last_update_date_abaa > gt_pre_process_date
-- Ver1.12 Mod Start
--                     (  (      af.last_update_date_abaa > gt_pre_process_date
--                           AND af.last_update_date_abaa <= gt_cur_process_date)
                     ((  (      af.last_update_date_abaa > gt_pre_process_date
                           AND af.last_update_date_abaa <= gt_cur_process_date)
                      OR (    af.last_update_date_abb > gt_pre_process_date
                              AND af.last_update_date_abb <= gt_cur_process_date)
                      )
-- Ver1.11 Mod End
                      AND af.spec_items_chg_flag = cv_y
                     ))
            )
          )
-- Ver1.8 Add End
      ORDER BY
          pv.segment1           ASC  -- düæÔ
        , pvsa.vendor_site_code ASC  -- düæTCgR[h
        , abaa.bank_account_num ASC  -- âsûÀÔ
    ;
--
    -- *** [JER[h ***
    -- uHTvCEâsûÀvÌoJ[\R[h
    l_sup_bank_use_rec     sup_bank_use_cur%ROWTYPE;
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
    -- uHTvCEâsûÀvÌo
    -- ==============================================================
    -- J[\I[v
    OPEN  sup_bank_use_cur;
    <<output_sup_bank_use_loop>>
    LOOP
      --
      FETCH sup_bank_use_cur INTO l_sup_bank_use_rec;
      EXIT WHEN sup_bank_use_cur%NOTFOUND;
      --
      -- oJEgAbv
      gn_get_bnk_use_cnt := gn_get_bnk_use_cnt + 1;
      --
      -- ==============================================================
      -- uHTvCEâsûÀvÌt@CoÍ
      -- ==============================================================
      -- f[^sÌì¬
-- Ver1.5 Mod Start
--      lv_file_data := TO_CHAR( gt_cur_process_date , cv_datetime_id_fmt );  -- 1 : *Import Batch Identifier (C|[gEob`¯Êq)
      lv_file_data := l_sup_bank_use_rec.batch_id;                          -- 1 : *Import Batch Identifier (C|[gEob`¯Êq)
-- Ver1.5 Mod Start
      lv_file_data := lv_file_data || cv_comma || 
                      l_sup_bank_use_rec.vendor_site_id;                    -- 2 : *Payee Identifier (x¥æ¯Êq)
      lv_file_data := lv_file_data || cv_comma || 
                      l_sup_bank_use_rec.bank_account_uses_id;              -- 3 : *Payee Bank Account Identifier (x¥æâsûÀ¯Êq)
      lv_file_data := lv_file_data || cv_comma || 
                      l_sup_bank_use_rec.bank_account_uses_id;              -- 4 : *Payee Bank Account Assignment Identifier (x¥æâsûÀ¯Êq)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string( l_sup_bank_use_rec.primary_flag );     -- 5 : *Primary Flag (vC}EtO)
      lv_file_data := lv_file_data || cv_comma || 
                      l_sup_bank_use_rec.start_date;                        -- 6 : Account Assignment Start Date (úF©)
      lv_file_data := lv_file_data || cv_comma || 
                      l_sup_bank_use_rec.end_date;                          -- 7 : Account Assignment End Date (úñANeBuú)
      --
      BEGIN
        -- f[^sÌt@CoÍ
        UTL_FILE.PUT_LINE( gf_bnk_use_file_handle
                         , lv_file_data
                         );
        --
        -- oÍJEgAbv
        gn_out_bnk_use_cnt := gn_out_bnk_use_cnt + 1;
      EXCEPTION
        WHEN OTHERS THEN
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
          lv_errbuf := lv_errmsg;
          RAISE global_process_expt;
      END;
    --
    END LOOP output_sup_bank_use_loop;
--
    -- J[\N[Y
    CLOSE sup_bank_use_cur;
--
  EXCEPTION
--
--#################################  ÅèáO START   ####################################
--
    -- *** ¤ÊáOnh ***
    WHEN global_process_expt THEN
      -- J[\N[Y
      IF ( sup_bank_use_cur%ISOPEN ) THEN
        CLOSE sup_bank_use_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ¤ÊÖáOnh ***
    WHEN global_api_expt THEN
      -- J[\N[Y
      IF ( sup_bank_use_cur%ISOPEN ) THEN
        CLOSE sup_bank_use_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ¤ÊÖOTHERSáOnh ***
    WHEN global_api_others_expt THEN
      -- J[\N[Y
      IF ( sup_bank_use_cur%ISOPEN ) THEN
        CLOSE sup_bank_use_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERSáOnh ***
    WHEN OTHERS THEN
      -- J[\N[Y
      IF ( sup_bank_use_cur%ISOPEN ) THEN
        CLOSE sup_bank_use_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  Åè END   ##########################################
--
  END output_sup_bank_use;
--
--
  /**********************************************************************************
   * Procedure Name   : output_party_tax_prf
   * Description      : uIp[eBÅàvt@CvAgf[^ÌoEt@CoÍ(A-11)
   ***********************************************************************************/
  PROCEDURE output_party_tax_prf(
    ov_errbuf     OUT VARCHAR2,     --   G[EbZ[W           --# Åè #
    ov_retcode    OUT VARCHAR2,     --   ^[ER[h             --# Åè #
    ov_errmsg     OUT VARCHAR2)     --   [U[EG[EbZ[W --# Åè #
  IS
    -- ===============================
    -- Åè[Jè
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'output_party_tax_prf';       -- vO¼
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
    lv_file_data         VARCHAR2(30000) DEFAULT NULL;       -- oÍàe
--
    -- *** [JEJ[\ ***
    -- uIp[eBÅàvt@CvÌoJ[\
    CURSOR party_tax_prf_cur
    IS
      -- düæÌê
      SELECT
          cv_party_sup                                   AS party_type                 -- p[eB[^Cv
        , pv.segment1                                    AS party_num                  -- p[eB[Ô
        , NULL                                           AS party_name                 -- p[eB[¼
        , cv_yes                                         AS allow_tax_appl             -- ÅàKpÌÂ
        , (CASE
             WHEN pv.auto_tax_calc_flag = cv_line THEN
               cv_line_desc
             WHEN pv.auto_tax_calc_flag = cv_header THEN
               cv_header_desc
             ELSE
               NULL 
           END)                                          AS auto_tax_calc_flag         -- [x
        , (CASE
             WHEN pv.ap_tax_rounding_rule  = cv_rule_n THEN
               cv_rule_n_desc
             WHEN pv.ap_tax_rounding_rule  = cv_rule_d THEN
               cv_rule_d_desc
             ELSE
               NULL 
           END)                                          AS ap_tax_rounding_rule       -- [[
        , pv.vat_code                                    AS vat_code                   -- ÅªÞR[h
        , (CASE
             WHEN pv.amount_includes_tax_flag  = cv_n THEN
               cv_no
             WHEN pv.amount_includes_tax_flag  = cv_y THEN
               cv_yes
             ELSE
               NULL 
           END)                                          AS amt_includes_tax_flag      -- Åàzªàz
        , (CASE
             WHEN pv.offset_tax_flag  = cv_n THEN
               cv_no
             WHEN pv.offset_tax_flag  = cv_y THEN
               cv_yes
             ELSE
               NULL
           END)                                          AS offset_tax_flag            -- EÅÌgp
      FROM
          po_vendors  pv  -- düæ}X^
      WHERE
          (   gt_pre_process_date IS NULL
-- Ver1.11 Mod Start
--           OR pv.last_update_date > gt_pre_process_date)
           OR (    pv.last_update_date > gt_pre_process_date
               AND pv.last_update_date <= gt_cur_process_date)
          )
-- Ver1.11 Mod End
      AND NVL(pv.vendor_type_lookup_code, 'X') <> cv_employee
      AND EXISTS (
              SELECT
                  1  AS flag
              FROM
                  po_vendor_sites_all  pvsa  -- düæTCg
              WHERE
                  pvsa.vendor_id = pv.vendor_id
              AND pvsa.org_id    = gt_target_organization_id
          )
      UNION ALL
      -- düæTCgÌê
      SELECT
          cv_party_sup_site                              AS party_type                 -- p[eB[^Cv
        , pvsa.vendor_site_code                          AS party_num                  -- p[eB[Ô
        , pv.vendor_name                                 AS party_name                 -- p[eB[¼
        , cv_yes                                         AS allow_tax_appl             -- ÅàKpÌÂ
        , (CASE
             WHEN pvsa.auto_tax_calc_flag = cv_line THEN
               cv_line_desc
             WHEN pvsa.auto_tax_calc_flag = cv_header THEN
               cv_header_desc
             ELSE
               NULL 
           END)                                          AS auto_tax_calc_flag         -- [x
        , (CASE
             WHEN pvsa.ap_tax_rounding_rule  = cv_rule_n THEN
               cv_rule_n_desc
             WHEN pvsa.ap_tax_rounding_rule  = cv_rule_d THEN
               cv_rule_d_desc
             ELSE
               NULL 
           END)                                          AS ap_tax_rounding_rule       -- [[
        , pvsa.vat_code                                  AS vat_code                   -- ÅªÞR[h
        , (CASE
             WHEN pvsa.amount_includes_tax_flag  = cv_n THEN
               cv_no
             WHEN pvsa.amount_includes_tax_flag  = cv_y THEN
               cv_yes
             ELSE
               NULL 
           END)                                          AS amt_includes_tax_flag      -- Åàzªàz
        , (CASE
             WHEN pvsa.offset_tax_flag  = cv_n THEN
               cv_no
             WHEN pvsa.offset_tax_flag  = cv_y THEN
               cv_yes
             ELSE
               NULL
           END)                                          AS offset_tax_flag            -- EÅÌgp
      FROM
          po_vendor_sites_all  pvsa  -- düæTCg
        , po_vendors           pv    -- düæ}X^
      WHERE
          (   gt_pre_process_date IS NULL
-- Ver1.11 Mod Start
--           OR pvsa.last_update_date > gt_pre_process_date)
           OR (    pvsa.last_update_date > gt_pre_process_date
               AND pvsa.last_update_date <= gt_cur_process_date)
           )
-- Ver1.11 Mod End
      AND pvsa.org_id    = gt_target_organization_id
      AND pvsa.vendor_id = pv.vendor_id
      AND NVL(pv.vendor_type_lookup_code, 'X') <> cv_employee
      ORDER BY
          party_type  ASC  -- p[eB[^Cv
        , party_num   ASC  -- p[eB[Ô
    ;
--
    -- *** [JER[h ***
    -- uIp[eBÅàvt@CvÌoJ[\R[h
    l_party_tax_prf_rec     party_tax_prf_cur%ROWTYPE;
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
    -- uIp[eBÅàvt@CvÌo
    -- ==============================================================
    -- J[\I[v
    OPEN  party_tax_prf_cur;
    <<output_party_tax_prf_loop>>
    LOOP
      --
      FETCH party_tax_prf_cur INTO l_party_tax_prf_rec;
      EXIT WHEN party_tax_prf_cur%NOTFOUND;
      --
      -- oJEgAbv
      gn_get_tax_prf_cnt := gn_get_tax_prf_cnt + 1;
      --
      -- ==============================================================
      -- uIp[eBÅàvt@CvÌt@CoÍ
      -- ==============================================================
      -- f[^sÌì¬
-- Ver1.3 Add Start
      lv_file_data := to_csv_string( gt_prf_ptp_record_type );                     --  1 : *Record Type (R[h^Cv)
-- Ver1.3 Add End
-- Ver1.3 Mod Start
--      lv_file_data := to_csv_string( l_party_tax_prf_rec.party_type );             --  1 : *Party Type (p[eB[^Cv)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string( l_party_tax_prf_rec.party_type );             --  2 : *Party Type (p[eB[^Cv)
-- Ver1.3 Mod End
      lv_file_data := lv_file_data || cv_comma || 
-- Ver1.6 Mod Start
--                      to_csv_string( l_party_tax_prf_rec.party_num );              --  3 : *Party Number (p[eB[Ô)
                      to_csv_string(
                        xxccp_oiccommon_pkg.trim_space_tab(l_party_tax_prf_rec.party_num)
                      );                                                           --  3 : *Party Number (p[eB[Ô)
-- Ver1.6 Mod End
      lv_file_data := lv_file_data || cv_comma || 
-- Ver1.6 Mod Start
--                      to_csv_string( l_party_tax_prf_rec.party_name );             --  4 : Party Name (p[eB[¼)
                      to_csv_string(
                        xxccp_oiccommon_pkg.trim_space_tab(l_party_tax_prf_rec.party_name)
                      );                                                           --  4 : Party Name (p[eB[¼)
-- Ver1.6 Mod End
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string( l_party_tax_prf_rec.allow_tax_appl );         --  5 : Allow tax applicability (ÅàKpÌÂ)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string( l_party_tax_prf_rec.auto_tax_calc_flag );     --  6 : Rounding Level ([x)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string( l_party_tax_prf_rec.ap_tax_rounding_rule );   --  7 : Rounding Rule ([[)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string( l_party_tax_prf_rec.vat_code );               --  8 : Tax Classification (ÅªÞR[h)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string( l_party_tax_prf_rec.amt_includes_tax_flag );  --  9 : Set Invoice value as Tax Inclusive (Åàzªàz)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string( l_party_tax_prf_rec.offset_tax_flag );        -- 10 : Allow Offset Taxes (EÅÌgp)
      lv_file_data := lv_file_data || cv_comma || NULL;                            -- 11 : Country Code ()
      lv_file_data := lv_file_data || cv_comma || NULL;                            -- 12 : Tax Registration Type  ()
      lv_file_data := lv_file_data || cv_comma || NULL;                            -- 13 : Registration Number ()
      --
      BEGIN
        -- f[^sÌt@CoÍ
        UTL_FILE.PUT_LINE( gf_tax_prf_file_handle
                         , lv_file_data
                         );
        --
        -- oÍJEgAbv
        gn_out_tax_prf_cnt := gn_out_tax_prf_cnt + 1;
      EXCEPTION
        WHEN OTHERS THEN
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
          lv_errbuf := lv_errmsg;
          RAISE global_process_expt;
      END;
    --
    END LOOP output_party_tax_prf_loop;
--
    -- J[\N[Y
    CLOSE party_tax_prf_cur;
--
  EXCEPTION
--
--#################################  ÅèáO START   ####################################
--
    -- *** ¤ÊáOnh ***
    WHEN global_process_expt THEN
      -- J[\N[Y
      IF ( party_tax_prf_cur%ISOPEN ) THEN
        CLOSE party_tax_prf_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ¤ÊÖáOnh ***
    WHEN global_api_expt THEN
      -- J[\N[Y
      IF ( party_tax_prf_cur%ISOPEN ) THEN
        CLOSE party_tax_prf_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ¤ÊÖOTHERSáOnh ***
    WHEN global_api_others_expt THEN
      -- J[\N[Y
      IF ( party_tax_prf_cur%ISOPEN ) THEN
        CLOSE party_tax_prf_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERSáOnh ***
    WHEN OTHERS THEN
      -- J[\N[Y
      IF ( party_tax_prf_cur%ISOPEN ) THEN
        CLOSE party_tax_prf_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  Åè END   ##########################################
--
  END output_party_tax_prf;
--
--
  /**********************************************************************************
   * Procedure Name   : output_bank_update
   * Description      : uJâsûÀXVpvf[^ÌoEt@CoÍ(A-12)
   ***********************************************************************************/
  PROCEDURE output_bank_update(
    ov_errbuf     OUT VARCHAR2,     --   G[EbZ[W           --# Åè #
    ov_retcode    OUT VARCHAR2,     --   ^[ER[h             --# Åè #
    ov_errmsg     OUT VARCHAR2)     --   [U[EG[EbZ[W --# Åè #
  IS
    -- ===============================
    -- Åè[Jè
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'output_bank_update';       -- vO¼
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
    lv_file_data         VARCHAR2(30000) DEFAULT NULL;       -- oÍàe
--
    -- *** [JEJ[\ ***
    -- uJâsûÀXVpvÌoJ[\
    CURSOR bank_update_cur
    IS
      SELECT
          abb.bank_name                                  AS bank_name                  -- âs¼
        , abb.bank_branch_name                           AS bank_branch_name           -- âsxX¼
-- Ver1.1 Mod Start
--        , abb.country                                    AS country                    -- 
        , NVL(abb.country, cv_jp)                        AS country                    -- 
-- Ver1.1 Mod End
        , abaa.account_holder_name                       AS account_holder_name        -- ûÀ¼`l
        , abaa.bank_account_num                          AS bank_account_num           -- âsûÀÔ
-- Ver1.4(E126) Mod Start
--        , abaa.currency_code                             AS currency_code              -- ÊÝ
        , NVL(abaa.currency_code, cv_yen)                AS currency_code              -- ÊÝ
-- Ver1.4(E126) Mod End
        , abaa.multi_currency_flag                       AS multi_currency_flag        -- ½ÊÝ@\
        , TO_CHAR(abaa.creation_date, cv_date_fmt)       AS creation_date              -- ì¬ú
        , TO_CHAR(abaa.inactive_date, cv_date_fmt)       AS inactive_date              -- ñANeBuú
        , abaa.account_holder_name_alt                   AS account_holder_name_alt    -- ûÀ¼`lJi
        , abaa.bank_account_type                         AS bank_account_type          -- âsûÀÌíÞ
        , (CASE
             WHEN xobae.bank_account_id IS NOT NULL THEN
               xobae.bank_account_num
             ELSE
               abaa.bank_account_num
           END)                                          AS bank_account_num_for_id    -- âsûÀÔiàIDæ¾pj
        , abaa.bank_account_id                           AS bank_account_id            -- âsûÀID
-- Ver1.8 Add Start
        , abb.bank_number                                AS bank_number                -- âsÔ
        , abb.bank_num                                   AS bank_num                   -- âsxXÔ
-- Ver1.8 Add End
        , xobae.bank_account_num                         AS xobae_bank_account_num     -- âsûÀÔiÞðe[uj
-- Ver1.8 Add Start
        , xobae.bank_number                              AS xobae_bank_number          -- âsÔiÞðe[uj
        , xobae.bank_branch_number                       AS xobae_bank_num             -- âsxXÔiÞðe[uj
-- Ver1.8 Add End
        , (CASE
             WHEN xobae.bank_account_id IS NULL THEN
               cv_evac_create
-- Ver1.8 Mod Start
--             WHEN xobae.bank_account_num <> abaa.bank_account_num  THEN
             WHEN (   NVL(xobae.bank_account_num, '@')   <> NVL(abaa.bank_account_num, '@')
                   OR NVL(xobae.bank_number, '@')        <> NVL(abb.bank_number, '@')
                   OR NVL(xobae.bank_branch_number, '@') <> NVL(abb.bank_num, '@')
                  ) THEN
-- Ver1.8 Mod End
               cv_evac_update
             ELSE
               NULL
           END)                                          AS key_ins_upd_flag           -- L[îño^EXVtO
      FROM
          ap_bank_accounts_all      abaa   -- âsûÀ
        , ap_bank_branches          abb    -- âsxX
        , xxcmm_oic_bank_acct_evac  xobae  -- OICâsûÀÞðe[u
      WHERE
          abaa.bank_branch_id  = abb.bank_branch_id
      AND abaa.bank_account_id = xobae.bank_account_id (+)
      AND EXISTS (
              SELECT
                  1  AS flag
              FROM
                  ap_bank_accounts_all      abaa_sub   -- âsûÀ
                , ap_bank_account_uses_all  abaua      -- âsûÀgp
                , po_vendor_sites_all       pvsa       -- düæTCg
                , po_vendors                pv         -- düæ}X^
-- Ver1.12 Add Start
                , ap_bank_branches          abb_sub    -- âsxX
-- Ver1.12 Add End
              WHERE
                   (   gt_pre_process_date IS NULL
-- Ver1.11 Mod Start
--                    OR abaa_sub.last_update_date > gt_pre_process_date
--                    OR abaua.last_update_date    > gt_pre_process_date)
                    OR (      abaa_sub.last_update_date > gt_pre_process_date
                          AND abaa_sub.last_update_date <= gt_cur_process_date)
                    OR (      abaua.last_update_date    > gt_pre_process_date
-- Ver1.12 Mod Start
--                          AND abaua.last_update_date    <= gt_cur_process_date))
                          AND abaua.last_update_date    <= gt_cur_process_date)
                    OR (     abb_sub.last_update_date > gt_pre_process_date
                          AND abb_sub.last_update_date <= gt_cur_process_date)
                  )
-- Ver1.12 Mod End
-- Ver1.11 Mod End
-- Ver1.12 Add Start
                AND ( pvsa.inactive_date IS NULL
                      OR pvsa.inactive_date > gt_cur_process_date
                    )
                AND ( pv.end_date_active IS NULL
                      OR pv.end_date_active > gt_cur_process_date
                    )
                AND abb_sub.bank_branch_id = abaa_sub.bank_branch_id
-- Ver1.12 Add End
               AND abaa_sub.bank_account_id = abaa.bank_account_id
               AND abaa_sub.bank_account_id = abaua.external_bank_account_id
               AND abaua.vendor_id          = pvsa.vendor_id
               AND abaua.vendor_site_id     = pvsa.vendor_site_id
               AND pvsa.org_id              = gt_target_organization_id
               AND pvsa.vendor_id           = pv.vendor_id
               AND NVL(pv.vendor_type_lookup_code, 'X') <> cv_employee
          )
      ORDER BY
          abaa.bank_account_num ASC  -- âsûÀÔ
      FOR UPDATE OF xobae.bank_account_num NOWAIT  -- sbNFOICâsûÀÞðe[u
    ;
--
    -- *** [JER[h ***
    -- uJâsûÀXVpvÌoJ[\R[h
    l_bank_update_rec     bank_update_cur%ROWTYPE;
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
    -- uJâsûÀXVpvÌo
    -- ==============================================================
    -- J[\I[v
    OPEN  bank_update_cur;
    <<output_bank_update_loop>>
    LOOP
      --
      FETCH bank_update_cur INTO l_bank_update_rec;
      EXIT WHEN bank_update_cur%NOTFOUND;
      --
      -- oJEgAbv
      gn_get_bnk_upd_cnt := gn_get_bnk_upd_cnt + 1;
      --
      -- ==============================================================
      -- uJâsûÀXVpvÌt@CoÍ
      -- ==============================================================
      -- ñiOñúªNULLÌêjAt@CoÍÍsíÈ¢
      IF (gt_pre_process_date IS NOT NULL) THEN
        -- f[^sÌì¬
        lv_file_data := to_csv_string( l_bank_update_rec.bank_name );                --  1 : Bank Name (âs¼)
        lv_file_data := lv_file_data || cv_comma || 
                        to_csv_string( l_bank_update_rec.bank_branch_name );         --  2 : Branch Name (âsxX¼)
        lv_file_data := lv_file_data || cv_comma || 
                        to_csv_string( l_bank_update_rec.country );                  --  3 : Account Country Code (ûÀR[h)
        lv_file_data := lv_file_data || cv_comma || 
                        to_csv_string( l_bank_update_rec.account_holder_name );      --  4 : Account Name (ûÀ¼)
        lv_file_data := lv_file_data || cv_comma || 
                        to_csv_string( l_bank_update_rec.bank_account_num );         --  5 : *Account Number (ûÀÔ)
        lv_file_data := lv_file_data || cv_comma || 
                        to_csv_string( l_bank_update_rec.currency_code );            --  6 : Account Currency Code (ûÀÊÝR[h)
        lv_file_data := lv_file_data || cv_comma || 
                        to_csv_string( l_bank_update_rec.multi_currency_flag );      --  7 : Allow International Payments (Ox¥ÂtO)
        lv_file_data := lv_file_data || cv_comma || 
                        l_bank_update_rec.creation_date;                             --  8 : Account Start Date (útF©)
        lv_file_data := lv_file_data || cv_comma || 
                        l_bank_update_rec.inactive_date;                             --  9 : Account End Date (ñANeBuú)
        lv_file_data := lv_file_data || cv_comma || 
                        to_csv_string( l_bank_update_rec.account_holder_name_alt );  -- 10 : Account Alternate Name (ûÀÊ¼)
        lv_file_data := lv_file_data || cv_comma || 
                        to_csv_string( l_bank_update_rec.bank_account_type );        -- 11 : Account Type Code (ûÀ^CvR[h)
        lv_file_data := lv_file_data || cv_comma || 
                        to_csv_string( l_bank_update_rec.bank_account_num_for_id );  -- 12 : *Account Number for Search(àIDæ¾pûÀÔ)
        --
        BEGIN
          -- f[^sÌt@CoÍ
          UTL_FILE.PUT_LINE( gf_bnk_upd_file_handle
                           , lv_file_data
                           );
          --
          -- oÍJEgAbv
          gn_out_bnk_upd_cnt := gn_out_bnk_upd_cnt + 1;
        EXCEPTION
          WHEN OTHERS THEN
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
            lv_errbuf := lv_errmsg;
            RAISE global_process_expt;
        END;
      --
      END IF;
      --
      -- ==============================================================
      -- OICâsûÀÞðe[uÌo^EXV
      -- ==============================================================
      IF ( l_bank_update_rec.key_ins_upd_flag = cv_evac_create ) THEN
        -- Þðe[uo^EXVtOªCreateÌê
        BEGIN
          -- OICâsûÀÞðe[uÌo^
          INSERT INTO xxcmm_oic_bank_acct_evac (
              bank_account_id                     -- âsûÀID
            , bank_account_num                    -- âsûÀÔ
-- Ver1.8 Add Start
            , bank_number                         -- âsÔ
            , bank_branch_number                  -- âsxXÔ
-- Ver1.8 Add End
            , created_by                          -- ì¬Ò
            , creation_date                       -- ì¬ú
            , last_updated_by                     -- ÅIXVÒ
            , last_update_date                    -- ÅIXVú
            , last_update_login                   -- ÅIXVOC
            , request_id                          -- vID
            , program_application_id              -- RJgEvOEAvP[VID
            , program_id                          -- RJgEvOID
            , program_update_date                 -- vOXVú
          ) VALUES (
              l_bank_update_rec.bank_account_id   -- âsûÀID
            , l_bank_update_rec.bank_account_num  -- âsûÀÔ
-- Ver1.8 Add Start
            , l_bank_update_rec.bank_number       -- âsÔ
            , l_bank_update_rec.bank_num          -- âsxXÔ
-- Ver1.8 Add End
            , cn_created_by                       -- ì¬Ò
            , cd_creation_date                    -- ì¬ú
            , cn_last_updated_by                  -- ÅIXVÒ
            , cd_last_update_date                 -- ÅIXVú
            , cn_last_update_login                -- ÅIXVOC
            , cn_request_id                       -- vID
            , cn_program_application_id           -- RJgEvOEAvP[VID
            , cn_program_id                       -- RJgEvOID
            , cd_program_update_date              -- vOXVú
          );
        EXCEPTION
          WHEN OTHERS THEN
            -- o^É¸sµ½ê
            lv_errmsg := SUBSTRB(
                           xxccp_common_pkg.get_msg(
                             iv_application  => cv_appl_xxcmm             -- AvP[VZk¼FXXCMM
                           , iv_name         => cv_insert_err_msg         -- bZ[W¼F}üG[bZ[W
                           , iv_token_name1  => cv_tkn_table              -- g[N¼1FTABLE
                           , iv_token_value1 => cv_oic_bank_evac_tbl_msg  -- g[Nl1FOICâsûÀÞðe[u
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
      ELSIF ( l_bank_update_rec.key_ins_upd_flag = cv_evac_update ) THEN
        -- Þðe[uo^EXVtOªUpdateÌê
        BEGIN
          -- OICâsûÀÞðe[uÌXV
          UPDATE
              xxcmm_oic_bank_acct_evac  xobae  -- OICâsûÀÞðe[u
          SET
              xobae.bank_account_num       = l_bank_update_rec.bank_account_num  -- âsûÀÔ
-- Ver1.8 Add Start
            , xobae.bank_number            = l_bank_update_rec.bank_number       -- âsÔ
            , xobae.bank_branch_number     = l_bank_update_rec.bank_num          -- âsxXÔ
-- Ver1.8 Add End
            , xobae.last_update_date       = cd_last_update_date                 -- ÅIXVú
            , xobae.last_updated_by        = cn_last_updated_by                  -- ÅIXVÒ
            , xobae.last_update_login      = cn_last_update_login                -- ÅIXVOC
            , xobae.request_id             = cn_request_id                       -- vID
            , xobae.program_application_id = cn_program_application_id           -- vOAvP[VID
            , xobae.program_id             = cn_program_id                       -- vOID
            , xobae.program_update_date    = cd_program_update_date              -- vOXVú
          WHERE
              xobae.bank_account_id        = l_bank_update_rec.bank_account_id   -- âsûÀID
          ;
        EXCEPTION
          WHEN OTHERS THEN
            -- XVÉ¸sµ½ê
            lv_errmsg := SUBSTRB(
                           xxccp_common_pkg.get_msg(
                             iv_application  => cv_appl_xxcmm             -- AvP[VZk¼FXXCMM
                           , iv_name         => cv_update_err_msg         -- bZ[W¼FXVG[bZ[W
                           , iv_token_name1  => cv_tkn_table              -- g[N¼1FTABLE
                           , iv_token_value1 => cv_oic_bank_evac_tbl_msg  -- g[Nl1FOICâsûÀÞðe[u
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
        -- XVÉ¬÷µ½êAXVOÆXVãÌâsûÀÔAâsÔAâsxXÔðoÍ
        lv_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_appl_xxcmm                               -- AvP[VZk¼FXXCMM
                  , iv_name         => cv_evac_data_out_msg                        -- bZ[W¼FÞðîñXVoÍbZ[W
                  , iv_token_name1  => cv_tkn_table                                -- g[N¼1FTABLE
                  , iv_token_value1 => cv_oic_bank_evac_tbl_msg                    -- g[Nl1FOICâsûÀÞðe[u
                  , iv_token_name2  => cv_tkn_id                                   -- g[N¼2FID
-- Ver1.8 Mod Start
--                  , iv_token_value2 => TO_CHAR(l_bank_update_rec.bank_account_id)  -- g[Nl2FâsûÀID
                  , iv_token_value2 => TO_CHAR(l_bank_update_rec.bank_account_id)  -- g[Nl2FâsûÀID
                                       || ' [BANK_ACCOUNT_NUM]'                    -- g[Nl1FâsûÀID{[BANK_ACCOUNT_NUM]
-- Ver1.8 Mod End
                  , iv_token_name3  => cv_tkn_before_value                         -- g[N¼3FBEFORE_VALUE
                  , iv_token_value3 => l_bank_update_rec.xobae_bank_account_num    -- g[Nl3FâsûÀÔiÞðe[uj
                  , iv_token_name4  => cv_tkn_after_value                          -- g[N¼4FAFTER_VALUE
                  , iv_token_value4 => l_bank_update_rec.bank_account_num          -- g[Nl4FâsûÀÔ
                  );
        --
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
        , buff   => lv_msg
        );
        --
-- Ver1.8 Add Start
        lv_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_appl_xxcmm                               -- AvP[VZk¼FXXCMM
                  , iv_name         => cv_evac_data_out_msg                        -- bZ[W¼FÞðîñXVoÍbZ[W
                  , iv_token_name1  => cv_tkn_table                                -- g[N¼1FTABLE
                  , iv_token_value1 => cv_oic_bank_evac_tbl_msg                    -- g[Nl1FOICâsûÀÞðe[u
                  , iv_token_name2  => cv_tkn_id                                   -- g[N¼2FID
                  , iv_token_value2 => TO_CHAR(l_bank_update_rec.bank_account_id)
                                       || ' [BANK_NUMBER]'                         -- g[Nl1FâsûÀID{[BANK_NUMBER]
                  , iv_token_name3  => cv_tkn_before_value                         -- g[N¼3FBEFORE_VALUE
                  , iv_token_value3 => l_bank_update_rec.xobae_bank_number         -- g[Nl3FâsÔiÞðe[uj
                  , iv_token_name4  => cv_tkn_after_value                          -- g[N¼4FAFTER_VALUE
                  , iv_token_value4 => l_bank_update_rec.bank_number               -- g[Nl4FâsÔ
                  );
        --
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
        , buff   => lv_msg
        );
        --
        lv_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_appl_xxcmm                               -- AvP[VZk¼FXXCMM
                  , iv_name         => cv_evac_data_out_msg                        -- bZ[W¼FÞðîñXVoÍbZ[W
                  , iv_token_name1  => cv_tkn_table                                -- g[N¼1FTABLE
                  , iv_token_value1 => cv_oic_bank_evac_tbl_msg                    -- g[Nl1FOICâsûÀÞðe[u
                  , iv_token_name2  => cv_tkn_id                                   -- g[N¼2FID
                  , iv_token_value2 => TO_CHAR(l_bank_update_rec.bank_account_id)
                                       || ' [BANK_BRANCH_NUMBER]'                  -- g[Nl1FâsûÀID{[BANK_BRANCH_NUMBER]
                  , iv_token_name3  => cv_tkn_before_value                         -- g[N¼3FBEFORE_VALUE
                  , iv_token_value3 => l_bank_update_rec.xobae_bank_num            -- g[Nl3FâsxXÔiÞðe[uj
                  , iv_token_name4  => cv_tkn_after_value                          -- g[N¼4FAFTER_VALUE
                  , iv_token_value4 => l_bank_update_rec.bank_num                  -- g[Nl4FâsxXÔ
                  );
        --
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
        , buff   => lv_msg
        );
-- Ver1.8 Add End
      END IF;
    --
    END LOOP output_bank_update_loop;
--
    -- J[\N[Y
    CLOSE bank_update_cur;
--
    -- ÞðîñXVoÍbZ[WðoÍµÄ¢éê
    IF ( lv_msg IS NOT NULL ) THEN
        -- ós}ü
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
        , buff   => ''
        );
    END IF;
--
  EXCEPTION
--
    -- *** bNG[áOnh ***
    WHEN global_lock_expt THEN
      -- J[\N[Y
      IF ( bank_update_cur%ISOPEN ) THEN
        CLOSE bank_update_cur;
      END IF;
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_xxcmm             -- AvP[VZk¼FXXCMM
                   , iv_name         => cv_lock_err_msg           -- bZ[W¼FbNG[bZ[W
                   , iv_token_name1  => cv_tkn_ng_table           -- g[N¼1FNG_TABLE
                   , iv_token_value1 => cv_oic_bank_evac_tbl_msg  -- g[Nl1Fe[u¼FOICâsûÀÞðe[u
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
      IF ( bank_update_cur%ISOPEN ) THEN
        CLOSE bank_update_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ¤ÊÖáOnh ***
    WHEN global_api_expt THEN
      -- J[\N[Y
      IF ( bank_update_cur%ISOPEN ) THEN
        CLOSE bank_update_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ¤ÊÖOTHERSáOnh ***
    WHEN global_api_others_expt THEN
      -- J[\N[Y
      IF ( bank_update_cur%ISOPEN ) THEN
        CLOSE bank_update_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERSáOnh ***
    WHEN OTHERS THEN
      -- J[\N[Y
      IF ( bank_update_cur%ISOPEN ) THEN
        CLOSE bank_update_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  Åè END   ##########################################
--
  END output_bank_update;
--
--
  /**********************************************************************************
   * Procedure Name   : update_mng_tbl
   * Description      : Çe[uo^EXV(A-14)
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
    IF ( gt_pre_process_date IS NULL ) THEN
      -- OñúªNULLÌê
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
                       , 5000);
          lv_errbuf  := lv_errmsg;
          RAISE global_process_expt;
      END;
    --
    ELSE
      -- OñúªNOT NULLÌê
      --
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
                       , 5000);
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
    gn_get_sup_cnt        := 0;         -- TvCo
    gn_out_sup_cnt        := 0;         -- TvCoÍ
    gn_get_sup_addr_cnt   := 0;         -- TvCEZo
    gn_out_sup_addr_cnt   := 0;         -- TvCEZoÍ
    gn_get_site_cnt       := 0;         -- TvCETCgo
    gn_out_site_cnt       := 0;         -- TvCETCgoÍ
    gn_get_site_ass_cnt   := 0;         -- TvCEBUo
    gn_out_site_ass_cnt   := 0;         -- TvCEBUoÍ
    gn_get_cont_cnt       := 0;         -- TvCESÒo
    gn_out_cont_cnt       := 0;         -- TvCESÒoÍ
    gn_get_cont_addr_cnt  := 0;         -- TvCESÒZo
    gn_out_cont_addr_cnt  := 0;         -- TvCESÒZoÍ
    gn_get_payee_cnt      := 0;         -- TvCEx¥æo
    gn_out_payee_cnt      := 0;         -- TvCEx¥æoÍ
    gn_get_bnk_acct_cnt   := 0;         -- TvCEâsûÀo
    gn_out_bnk_acct_cnt   := 0;         -- TvCEâsûÀoÍ
    gn_get_bnk_use_cnt    := 0;         -- TvCEâsûÀo
    gn_out_bnk_use_cnt    := 0;         -- TvCEâsûÀoÍ
    gn_get_tax_prf_cnt    := 0;         -- p[eBÅàvt@Co
    gn_out_tax_prf_cnt    := 0;         -- p[eBÅàvt@CoÍ
    gn_get_bnk_upd_cnt    := 0;         -- âsûÀXVpo
    gn_out_bnk_upd_cnt    := 0;         -- âsûÀXVpoÍ
--
    --
    --===============================================
    -- ú(A-1)
    --===============================================
    init(
      ov_errbuf          => lv_errbuf           -- G[EbZ[W
    , ov_retcode         => lv_retcode          -- ^[ER[h
    , ov_errmsg          => lv_errmsg           -- [U[EG[EbZ[W
    );
    --
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    --==========================================================================
    -- u@TvCvAgf[^ÌoEt@CoÍ(A-2)
    --==========================================================================
    output_supplier(
      ov_errbuf          => lv_errbuf           -- G[EbZ[W
    , ov_retcode         => lv_retcode          -- ^[ER[h
    , ov_errmsg          => lv_errmsg           -- [U[EG[EbZ[W
    );
    --
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    --==========================================================================
    -- uATvCEZvAgf[^ÌoEt@CoÍ(A-3)
    --==========================================================================
    output_sup_addr(
      ov_errbuf          => lv_errbuf           -- G[EbZ[W
    , ov_retcode         => lv_retcode          -- ^[ER[h
    , ov_errmsg          => lv_errmsg           -- [U[EG[EbZ[W
    );
    --
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    --==========================================================================
    -- uBTvCETCgvAgf[^ÌoEt@CoÍ(A-4)
    --==========================================================================
    output_sup_site(
      ov_errbuf          => lv_errbuf           -- G[EbZ[W
    , ov_retcode         => lv_retcode          -- ^[ER[h
    , ov_errmsg          => lv_errmsg           -- [U[EG[EbZ[W
    );
    --
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    --==========================================================================
    -- uCTvCEBUvAgf[^ÌoEt@CoÍ(A-5)
    --==========================================================================
    output_sup_site_ass(
      ov_errbuf          => lv_errbuf           -- G[EbZ[W
    , ov_retcode         => lv_retcode          -- ^[ER[h
    , ov_errmsg          => lv_errmsg           -- [U[EG[EbZ[W
    );
    --
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    --==========================================================================
    -- uDTvCESÒvAgf[^ÌoEt@CoÍ(A-6)
    --==========================================================================
    output_sup_contact(
      ov_errbuf          => lv_errbuf           -- G[EbZ[W
    , ov_retcode         => lv_retcode          -- ^[ER[h
    , ov_errmsg          => lv_errmsg           -- [U[EG[EbZ[W
    );
    --
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    --==========================================================================
    -- uETvCESÒZvAgf[^ÌoEt@CoÍ(A-7)
    --==========================================================================
    output_sup_contact_addr(
      ov_errbuf          => lv_errbuf           -- G[EbZ[W
    , ov_retcode         => lv_retcode          -- ^[ER[h
    , ov_errmsg          => lv_errmsg           -- [U[EG[EbZ[W
    );
    --
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    --==========================================================================
    -- uFTvCEx¥ævAgf[^ÌoEt@CoÍ(A-8)
    --==========================================================================
    output_sup_payee(
      ov_errbuf          => lv_errbuf           -- G[EbZ[W
    , ov_retcode         => lv_retcode          -- ^[ER[h
    , ov_errmsg          => lv_errmsg           -- [U[EG[EbZ[W
    );
    --
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    --==========================================================================
    -- uGTvCEâsûÀvAgf[^ÌoEt@CoÍ(A-9)
    --==========================================================================
    output_sup_bank_acct(
      ov_errbuf          => lv_errbuf           -- G[EbZ[W
    , ov_retcode         => lv_retcode          -- ^[ER[h
    , ov_errmsg          => lv_errmsg           -- [U[EG[EbZ[W
    );
    --
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    --==========================================================================
    -- uHTvCEâsûÀvAgf[^ÌoEt@CoÍ(A-10)
    --==========================================================================
    output_sup_bank_use(
      ov_errbuf          => lv_errbuf           -- G[EbZ[W
    , ov_retcode         => lv_retcode          -- ^[ER[h
    , ov_errmsg          => lv_errmsg           -- [U[EG[EbZ[W
    );
    --
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    --==========================================================================
    -- uIp[eBÅàvt@CvAgf[^ÌoEt@CoÍ(A-11)
    --==========================================================================
    output_party_tax_prf(
      ov_errbuf          => lv_errbuf           -- G[EbZ[W
    , ov_retcode         => lv_retcode          -- ^[ER[h
    , ov_errmsg          => lv_errmsg           -- [U[EG[EbZ[W
    );
    --
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    --==========================================================================
    -- uJâsûÀXVpvf[^ÌoEt@CoÍ(A-12)
    --==========================================================================
    output_bank_update(
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
    -- Çe[uo^EXV(A-13)
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
    errbuf        OUT VARCHAR2,      --   G[EbZ[W  --# Åè #
    retcode       OUT VARCHAR2       --   ^[ER[h    --# Åè #
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
       lv_errbuf   -- G[EbZ[W           --# Åè #
      ,lv_retcode  -- ^[ER[h             --# Åè #
      ,lv_errmsg   -- [U[EG[EbZ[W --# Åè #
    );
    --
    -- G[Ìê
    IF (lv_retcode = cv_status_error) THEN
      --
      -- eoÍÌú»i0j
      gn_out_sup_cnt          := 0;     -- TvCAgf[^t@CoÍ
      gn_out_sup_addr_cnt     := 0;     -- TvCEZAgf[^t@CoÍ
      gn_out_site_cnt         := 0;     -- TvCETCgAgf[^t@CoÍ
      gn_out_site_ass_cnt     := 0;     -- TvCEBUAgf[^t@CoÍ
      gn_out_cont_cnt         := 0;     -- TvCESÒAgf[^t@CoÍ
      gn_out_cont_addr_cnt    := 0;     -- TvCESÒZAgf[^t@CoÍ
      gn_out_payee_cnt        := 0;     -- TvCEx¥æAgf[^t@CoÍ
      gn_out_bnk_acct_cnt     := 0;     -- TvCEâsûÀAgf[^t@CoÍ
      gn_out_bnk_use_cnt      := 0;     -- TvCEâsûÀAgf[^t@CoÍ
      gn_out_tax_prf_cnt      := 0;     -- p[eBÅàvt@CAgf[^t@CoÍ
      gn_out_bnk_upd_cnt      := 0;     -- âsûÀXVpt@CoÍ
      --
      -- G[ÌÝè
      gn_error_cnt            := 1;
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
    -- I¹(A-14)
    --===============================================
--
    -------------------------------------------------
    -- t@CN[Y
    -------------------------------------------------
    -- TvCAgf[^t@C
    IF ( UTL_FILE.IS_OPEN ( gf_sup_file_handle )) THEN
      UTL_FILE.FCLOSE( gf_sup_file_handle );
    END IF;
    -- TvCEZAgf[^t@C
    IF ( UTL_FILE.IS_OPEN ( gf_sup_addr_file_handle )) THEN
      UTL_FILE.FCLOSE( gf_sup_addr_file_handle );
    END IF;
    -- TvCETCgAgf[^t@C
    IF ( UTL_FILE.IS_OPEN ( gf_site_file_handle )) THEN
      UTL_FILE.FCLOSE( gf_site_file_handle );
    END IF;
    -- TvCEBUAgf[^t@C
    IF ( UTL_FILE.IS_OPEN ( gf_site_ass_file_handle )) THEN
      UTL_FILE.FCLOSE( gf_site_ass_file_handle );
    END IF;
    -- TvCESÒAgf[^t@C
    IF ( UTL_FILE.IS_OPEN ( gf_cont_file_handle )) THEN
      UTL_FILE.FCLOSE( gf_cont_file_handle );
    END IF;
    -- TvCESÒZAgf[^t@C
    IF ( UTL_FILE.IS_OPEN ( gf_cont_addr_file_handle )) THEN
      UTL_FILE.FCLOSE( gf_cont_addr_file_handle );
    END IF;
    -- TvCEx¥æAgf[^t@C
    IF ( UTL_FILE.IS_OPEN ( gf_payee_file_handle )) THEN
      UTL_FILE.FCLOSE( gf_payee_file_handle );
    END IF;
    -- TvCEâsûÀAgf[^t@C
    IF ( UTL_FILE.IS_OPEN ( gf_bnk_acct_file_handle )) THEN
      UTL_FILE.FCLOSE( gf_bnk_acct_file_handle );
    END IF;
    -- TvCEâsûÀAgf[^t@C
    IF ( UTL_FILE.IS_OPEN ( gf_bnk_use_file_handle )) THEN
      UTL_FILE.FCLOSE( gf_bnk_use_file_handle );
    END IF;
    -- p[eBÅàvt@CAgf[^t@C
    IF ( UTL_FILE.IS_OPEN ( gf_tax_prf_file_handle )) THEN
      UTL_FILE.FCLOSE( gf_tax_prf_file_handle );
    END IF;
    -- âsûÀXVpt@C
    IF ( UTL_FILE.IS_OPEN ( gf_bnk_upd_file_handle )) THEN
      UTL_FILE.FCLOSE( gf_bnk_upd_file_handle );
    END IF;
--
    -------------------------------------------------
    -- oÌoÍ
    -------------------------------------------------
    -- TvCo
    l_get_cnt_tab(1).target  := cv_sup_msg;
    l_get_cnt_tab(1).cnt     := TO_CHAR(gn_get_sup_cnt);
    -- TvCEZo
    l_get_cnt_tab(2).target  := cv_sup_addr_msg;
    l_get_cnt_tab(2).cnt     := TO_CHAR(gn_get_sup_addr_cnt);
    -- TvCETCgo
    l_get_cnt_tab(3).target  := cv_site_msg;
    l_get_cnt_tab(3).cnt     := TO_CHAR(gn_get_site_cnt);
    -- TvCEBUo
    l_get_cnt_tab(4).target  := cv_site_ass_msg;
    l_get_cnt_tab(4).cnt     := TO_CHAR(gn_get_site_ass_cnt);
    -- TvCESÒo
    l_get_cnt_tab(5).target  := cv_cont_msg;
    l_get_cnt_tab(5).cnt     := TO_CHAR(gn_get_cont_cnt);
    -- TvCESÒZo
    l_get_cnt_tab(6).target  := cv_cont_addr_msg;
    l_get_cnt_tab(6).cnt     := TO_CHAR(gn_get_cont_addr_cnt);
    -- TvCEx¥æo
    l_get_cnt_tab(7).target  := cv_payee_msg;
    l_get_cnt_tab(7).cnt     := TO_CHAR(gn_get_payee_cnt);
    -- TvCEâsûÀo
    l_get_cnt_tab(8).target  := cv_bnk_acct_msg;
    l_get_cnt_tab(8).cnt     := TO_CHAR(gn_get_bnk_acct_cnt);
    -- TvCEâsûÀo
    l_get_cnt_tab(9).target  := cv_bnk_use_msg;
    l_get_cnt_tab(9).cnt     := TO_CHAR(gn_get_bnk_use_cnt);
    -- p[eBÅàvt@Co
    l_get_cnt_tab(10).target := cv_tax_prf_msg;
    l_get_cnt_tab(10).cnt    := TO_CHAR(gn_get_tax_prf_cnt);
    -- âsûÀXVpo
    l_get_cnt_tab(11).target := cv_bnk_upd_msg;
    l_get_cnt_tab(11).cnt    := TO_CHAR(gn_get_bnk_upd_cnt);
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
    -- TvCAgf[^t@CoÍ
    l_out_cnt_tab(1).target  := gt_prf_val_sup_out_file;
    l_out_cnt_tab(1).cnt     := TO_CHAR(gn_out_sup_cnt);
    -- TvCEZAgf[^t@CoÍ
    l_out_cnt_tab(2).target  := gt_prf_val_sup_addr_out_file;
    l_out_cnt_tab(2).cnt     := TO_CHAR(gn_out_sup_addr_cnt);
    -- TvCETCgAgf[^t@CoÍ
    l_out_cnt_tab(3).target  := gt_prf_val_site_out_file;
    l_out_cnt_tab(3).cnt     := TO_CHAR(gn_out_site_cnt);
    -- TvCEBUAgf[^t@CoÍ
    l_out_cnt_tab(4).target  := gt_prf_val_site_ass_out_file;
    l_out_cnt_tab(4).cnt     := TO_CHAR(gn_out_site_ass_cnt);
    -- TvCESÒAgf[^t@CoÍ
    l_out_cnt_tab(5).target  := gt_prf_val_cont_out_file;
    l_out_cnt_tab(5).cnt     := TO_CHAR(gn_out_cont_cnt);
    -- TvCESÒZAgf[^t@CoÍ
    l_out_cnt_tab(6).target  := gt_prf_val_cont_addr_out_file;
    l_out_cnt_tab(6).cnt     := TO_CHAR(gn_out_cont_addr_cnt);
    -- TvCEx¥æAgf[^t@CoÍ
    l_out_cnt_tab(7).target  := gt_prf_val_payee_out_file;
    l_out_cnt_tab(7).cnt     := TO_CHAR(gn_out_payee_cnt);
    -- TvCEâsûÀAgf[^t@CoÍ
    l_out_cnt_tab(8).target  := gt_prf_val_bnk_acct_out_file;
    l_out_cnt_tab(8).cnt     := TO_CHAR(gn_out_bnk_acct_cnt);
    -- TvCEâsûÀAgf[^t@CoÍ
    l_out_cnt_tab(9).target  := gt_prf_val_bnk_use_out_file;
    l_out_cnt_tab(9).cnt     := TO_CHAR(gn_out_bnk_use_cnt);
    -- p[eBÅàvt@CAgf[^t@CoÍ
    l_out_cnt_tab(10).target := gt_prf_val_tax_prf_out_file;
    l_out_cnt_tab(10).cnt    := TO_CHAR(gn_out_tax_prf_cnt);
    -- âsûÀXVpt@CoÍ
    l_out_cnt_tab(11).target := gt_prf_val_bnk_upd_out_file;
    l_out_cnt_tab(11).cnt    := TO_CHAR(gn_out_bnk_upd_cnt);
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
    gn_target_cnt := gn_get_sup_cnt +
                     gn_get_sup_addr_cnt +
                     gn_get_site_cnt +
                     gn_get_site_ass_cnt +
                     gn_get_cont_cnt +
                     gn_get_cont_addr_cnt +
                     gn_get_payee_cnt +
                     gn_get_bnk_acct_cnt +
                     gn_get_bnk_use_cnt +
                     gn_get_tax_prf_cnt +
                     gn_get_bnk_upd_cnt;
    --
    -- ¬÷ioÍÌvjðÝè
    gn_normal_cnt := gn_out_sup_cnt +
                     gn_out_sup_addr_cnt +
                     gn_out_site_cnt +
                     gn_out_site_ass_cnt +
                     gn_out_cont_cnt +
                     gn_out_cont_addr_cnt +
                     gn_out_payee_cnt +
                     gn_out_bnk_acct_cnt +
                     gn_out_bnk_use_cnt +
                     gn_out_tax_prf_cnt +
                     gn_out_bnk_upd_cnt;
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
--    --XLbvoÍ
--    gv_out_msg := xxccp_common_pkg.get_msg(
--                     iv_application  => cv_appl_short_name
--                    ,iv_name         => cv_skip_rec_msg
--                    ,iv_token_name1  => cv_cnt_token
--                    ,iv_token_value1 => TO_CHAR(gn_warn_cnt)
--                   );
--    FND_FILE.PUT_LINE(
--       which  => FND_FILE.OUTPUT
--      ,buff   => gv_out_msg
--    );
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
END XXCMM001A02C;
/
