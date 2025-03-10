CREATE OR REPLACE PACKAGE BODY APPS.XXCFF019A01C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2017. All rights reserved.
 *
 * Package Name     : XXCFF019A01C(body)
 * Description      : ÅèYf[^Abv[h
 * MD.050           : MD050_CFF_019_A01_ÅèYf[^Abv[h
 * Version          : 1.1
 *
 * Program List
 * ---------------------------- ------------------------------------------------------------
 *  Name                         Description
 * ---------------------------- ------------------------------------------------------------
 *  init                         ú(A-1)
 *  get_for_validation           Ã«`FbNpÌlæ¾(A-2)
 *  get_upload_data              t@CAbv[hIFf[^æ¾(A-3)
 *  divide_item                  f~^¶Úª(A-4)
 *  check_item_value             Úl`FbN(A-5)
 *  ins_upload_wk                ÅèYAbv[h[Nì¬(A-6)
 *  get_upload_wk                ÅèYAbv[h[Næ¾(A-7)
 *  data_validation              f[^Ã«`FbN(A-8)
 *  insert_add_oif               ÇÁOIFo^(A-9)
 *  insert_adj_oif               C³OIFo^(A-10)
 *  submain                      CvV[W
 *  main                         RJgÀst@Co^vV[W
 *                               ÎÛf[^í(A-11)
 *                               I¹(A-12)
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2017/10/31    1.0   S.Niki           E_{Ò®_14502ÎiVKì¬j
 *  2024/02/09    1.1   Y.Sato           E_{Ò®_19496 O[vïÐÎ
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
  -- bNG[
  lock_expt             EXCEPTION;
  -- ïvúÔ`FbNG[
  chk_period_expt       EXCEPTION;
--
  PRAGMA EXCEPTION_INIT(lock_expt, -54);
--
  -- ===============================
  -- [U[è`O[oè
  -- ===============================
  cv_pkg_name         CONSTANT VARCHAR2(100) := 'XXCFF019A01C';          -- pbP[W¼
--
  -- AvP[VZk¼
  cv_msg_kbn_cff      CONSTANT VARCHAR2(5)   := 'XXCFF';                 -- AhIFïvE[XEFAÌæ
  cv_msg_kbn_ccp      CONSTANT VARCHAR2(5)   := 'XXCCP';                 -- AhIF¤ÊEIFÌæ
--
  -- vt@C
  cv_prf_cmp_cd_itoen CONSTANT VARCHAR2(30)  := 'XXCFF1_COMPANY_CD_ITOEN';       -- ïÐR[h_{Ð
  cv_prf_fixd_ast_reg CONSTANT VARCHAR2(30)  := 'XXCFF1_FIXED_ASSET_REGISTER';   -- ä íÞ_ÅèYä 
-- Ver1.1 Del Start
--  cv_prf_own_itoen    CONSTANT VARCHAR2(30)  := 'XXCFF1_OWN_COMP_ITOEN';         -- {ÐHêæª_{Ð
--  cv_prf_own_sagara   CONSTANT VARCHAR2(30)  := 'XXCFF1_OWN_COMP_SAGARA';        -- {ÐHêæª_Hê
-- Ver1.1 Del End
  cv_prf_feed_sys_nm  CONSTANT VARCHAR2(30)  := 'XXCFF1_FEEDER_SYSTEM_NAME_FA';  -- VXe¼_FAAbv[h
  cv_prf_cat_dep_ifrs CONSTANT VARCHAR2(30)  := 'XXCFF1_CAT_DEPRN_IFRS';         -- IFRSpû@
--
  -- bZ[W¼
  cv_msg_name_00234   CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00234';      -- Abv[hCSVt@C¼æ¾G[
  cv_msg_name_00167   CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00167';      -- Abv[ht@Cîñ
  cv_msg_name_00020   CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00020';      -- vt@Cæ¾G[
  cv_msg_name_00236   CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00236';      -- ÅVïvúÔ¼æ¾x
  cv_msg_name_00037   CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00037';      -- ïvúÔ`FbNG[
  cv_msg_name_00062   CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00062';      -- ÎÛf[^³µ
  cv_msg_name_00252   CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00252';      -- æªG[
  cv_msg_name_00253   CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00253';      -- üÍÚÃ«`FbNG[
  cv_msg_name_00279   CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00279';      -- YÔd¡G[
  cv_msg_name_00254   CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00254';      -- YÔo^ÏÝG[
  cv_msg_name_00255   CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00255';      -- Ú¢Ýè`FbNG[
  cv_msg_name_00256   CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00256';      -- ¶Ý`FbNG[
  cv_msg_name_00257   CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00257';      -- ÏpNG[
  cv_msg_name_00258   CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00258';      -- ¤ÊÖG[
  cv_msg_name_00259   CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00259';      -- YJeS¢o^G[
  cv_msg_name_00260   CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00260';      -- YL[CCIDæ¾G[
  cv_msg_name_00261   CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00261';      -- C³Nú`FbNG[
  cv_msg_name_00270   CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00270';      -- Æpú`FbNG[
  cv_msg_name_00271   CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00271';      -- «ElG[
  cv_msg_name_00264   CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00264';      -- YÔÌÔG[
  cv_msg_name_00265   CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00265';      -- Oñf[^¶Ý`FbNG[
  cv_msg_name_00102   CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00102';      -- o^G[
  cv_msg_name_00104   CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00104';      -- íG[
  cv_msg_name_00266   CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00266';      -- ÇÁOIFo^bZ[W
  cv_msg_name_00267   CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00267';      -- C³OIFo^bZ[W
--Ver1.1 Add Start
  cv_msg_name_00189   CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00189';      -- QÆ^Cvæ¾G[
--Ver1.1 Add End
--
  -- bZ[W¼(g[N)
  cv_tkn_val_50295    CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50295';      -- ÅèYf[^
  cv_tkn_val_50130    CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50130';      -- ú
  cv_tkn_val_50131    CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50131';      -- BLOBf[^Ï·pÖ
  cv_tkn_val_50165    CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50165';      -- f~^¶ªÖ
  cv_tkn_val_50166    CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50166';      -- Ú`FbN
  cv_tkn_val_50175    CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50175';      -- t@CAbv[hI/Fe[u
  cv_tkn_val_50076    CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50076';      -- XXCFF:ïÐR[h_{Ð
  cv_tkn_val_50228    CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50228';      -- XXCFF:ä íÞ_ÅèYä 
-- Ver1.1 Del Start
--  cv_tkn_val_50095    CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50095';      -- XXCFF:{ÐHêæª_{Ð
--  cv_tkn_val_50096    CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50096';      -- XXCFF:{ÐHêæª_Hê
-- Ver1.1 Del End
  cv_tkn_val_50305    CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50305';      -- XXCFF:VXe¼_FAAbv[h
  cv_tkn_val_50318    CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50318';      -- XXCFF:IFRSpû@
  cv_tkn_val_50296    CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50296';      -- ÅèYAbv[h[N
  cv_tkn_val_50241    CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50241';      -- YÔ
  cv_tkn_val_50242    CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50242';      -- Ev
  cv_tkn_val_50297    CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50297';      -- o^
  cv_tkn_val_50298    CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50298';      -- C³
  cv_tkn_val_50072    CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50072';      -- YíÞ
  cv_tkn_val_50299    CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50299';      -- p\
  cv_tkn_val_50270    CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50270';      -- Y¨è
  cv_tkn_val_50300    CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50300';      -- pÈÚ
  cv_tkn_val_50302    CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50302';      -- pâÈÚ
  cv_tkn_val_50307    CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50307';      -- ÏpN
  cv_tkn_val_50097    CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50097';      -- pû@
  cv_tkn_val_50017    CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50017';      -- [XíÊ
  cv_tkn_val_50262    CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50262';      -- Æpú
  cv_tkn_val_50308    CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50308';      -- æ¾¿z
  cv_tkn_val_50309    CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50309';      -- PÊÊ
  cv_tkn_val_50274    CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50274';      -- ïÐR[h
  cv_tkn_val_50301    CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50301';      -- åR[h
  cv_tkn_val_50246    CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50246';      -- \n
  cv_tkn_val_50265    CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50265';      -- Æ
  cv_tkn_val_50266    CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50266';      -- Ýuê
  cv_tkn_val_50310    CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50310';      -- æ¾ú
  cv_tkn_val_50311    CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50311';      -- \õ1
  cv_tkn_val_50312    CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50312';      -- \õ2
  cv_tkn_val_50313    CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50313';      -- C³Nú
  cv_tkn_val_50317    CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50317';      -- IFRSp
  cv_tkn_val_50306    CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50306';      -- IFRSYÈÚ
  cv_tkn_val_50303    CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50303';      -- YJeS`FbN
  cv_tkn_val_50304    CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50304';      -- CCIDæ¾Ö
  cv_tkn_val_50141    CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50141';      -- Æ}X^`FbN
  cv_tkn_val_50319    CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50319';      -- ÇÁOIF
  cv_tkn_val_50320    CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50320';      -- C³OIF
  cv_tkn_val_50321    CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50321';      -- IFRSæ¾¿zvl
-- Ver1.1 Add Start
  cv_tkn_val_50331    CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50331';      -- {Ð/HêæªR[h  
-- Ver1.1 Add End
--
  -- g[N¼
  cv_tkn_file_name    CONSTANT VARCHAR2(100) := 'FILE_NAME';             -- t@C¼
  cv_tkn_csv_name     CONSTANT VARCHAR2(100) := 'CSV_NAME';              -- CSVt@C¼
  cv_tkn_prof_name    CONSTANT VARCHAR2(100) := 'PROF_NAME';             -- vt@C¼
  cv_tkn_param_name   CONSTANT VARCHAR2(100) := 'PARAM_NAME';            -- p[^¼
  cv_tkn_book_type    CONSTANT VARCHAR2(100) := 'BOOK_TYPE_CODE';        -- ä ¼
  cv_tkn_period_name  CONSTANT VARCHAR2(100) := 'PERIOD_NAME';           -- ïvúÔ¼
  cv_tkn_open_date    CONSTANT VARCHAR2(100) := 'PERIOD_OPEN_DATE';      -- ïvúÔI[vú
  cv_tkn_close_date   CONSTANT VARCHAR2(100) := 'PERIOD_CLOSE_DATE';     -- ïvúÔN[Yú
  cv_tkn_min_value    CONSTANT VARCHAR2(100) := 'MIN_VALUE';             -- «El
  cv_tkn_func_name    CONSTANT VARCHAR2(100) := 'FUNC_NAME';             -- ¤ÊÖ¼
  cv_tkn_proc_type    CONSTANT VARCHAR2(100) := 'PROC_TYPE';             -- æª
  cv_tkn_input        CONSTANT VARCHAR2(100) := 'INPUT';                 -- Ú¼
  cv_tkn_column_data  CONSTANT VARCHAR2(100) := 'COLUMN_DATA';           -- Úl
  cv_tkn_line_no      CONSTANT VARCHAR2(100) := 'LINE_NO';               -- sÔ
  cv_tkn_err_msg      CONSTANT VARCHAR2(100) := 'ERR_MSG';               -- G[bZ[W
  cv_tkn_table_name   CONSTANT VARCHAR2(100) := 'TABLE_NAME';            -- e[u¼
  cv_tkn_info         CONSTANT VARCHAR2(100) := 'INFO';                  -- Ú×îñ
--Ver1.1 Add Start
  cv_tkn_lookup_type  CONSTANT VARCHAR2(100) := 'LOOKUP_TYPE';           -- QÆ^Cv¼
--Ver1.1 Add End
--
  -- lZbg¼
  cv_ffv_dclr_dprn    CONSTANT VARCHAR2(100) := 'XXCFF_DCLR_DPRN';       -- p\
  cv_ffv_asset_acct   CONSTANT VARCHAR2(100) := 'XXCFF_ASSET_ACCOUNT';   -- Y¨è
  cv_ffv_deprn_acct   CONSTANT VARCHAR2(100) := 'XXCFF_DEPRN_ACCOUNT';   -- pÈÚ
  cv_ffv_dprn_method  CONSTANT VARCHAR2(100) := 'XXCFF_DPRN_METHOD';     -- pû@
  cv_ffv_dclr_place   CONSTANT VARCHAR2(100) := 'XXCFF_DCLR_PLACE';      -- \n
  cv_ffv_mng_place    CONSTANT VARCHAR2(100) := 'XXCFF_MNG_PLACE';       -- Æ
--
--Ver1.1 Add Start 
  -- QÆ^CvER[h
  cv_flvv_own_comp_cd CONSTANT VARCHAR2(100) := 'XXCFF1_OWNER_COMPANY_CODE'; -- {Ð/HêæªR[h
--Ver1.1 Add End
  -- oÍ^Cv
  cv_file_type_out    CONSTANT VARCHAR2(10)  := 'OUTPUT';                -- oÍ
  cv_file_type_log    CONSTANT VARCHAR2(10)  := 'LOG';                   -- O
--
  -- f~^¶
  cv_csv_delimiter    CONSTANT VARCHAR2(1)   := ',';                     -- J}
--
  -- æª
  cv_process_type_1   CONSTANT VARCHAR2(1)   := '1';                     -- 1io^j
  cv_process_type_2   CONSTANT VARCHAR2(1)   := '2';                     -- 2iC³j
--
  cv_yes              CONSTANT VARCHAR2(1)   := 'Y';                     -- YES
  cv_no               CONSTANT VARCHAR2(1)   := 'N';                     -- NO
  cv_date_fmt_std     CONSTANT VARCHAR2(10)  := 'YYYY/MM/DD';            -- út®
  cv_lang_ja          CONSTANT VARCHAR2(2)   := 'JA';                    -- ú{ê
--
  -- ZOgl
  cv_segment5_dummy   CONSTANT VARCHAR2(30)  := '000000000';             -- ÚqR[h
  cv_segment6_dummy   CONSTANT VARCHAR2(30)  := '000000';                -- éÆR[h
  cv_segment7_dummy   CONSTANT VARCHAR2(30)  := '0';                     -- \õP
  cv_segment8_dummy   CONSTANT VARCHAR2(30)  := '0';                     -- \õQ
--
  -- Åèl
  cn_0                CONSTANT NUMBER        := 0;                       -- l0
  cn_1                CONSTANT NUMBER        := 1;                       -- l1
--
  -- ===============================
  -- [U[è`O[o^
  -- ===============================
--
  -- ¶Úªãf[^i[zñ
  TYPE g_load_data_ttype           IS TABLE OF VARCHAR2(600) INDEX BY PLS_INTEGER;
--
  -- Ã«`FbNpÌlæ¾pè`
  TYPE g_column_desc_ttype         IS TABLE OF xxcff_fa_upload_v.column_desc%TYPE INDEX BY PLS_INTEGER;
  TYPE g_byte_count_ttype          IS TABLE OF xxcff_fa_upload_v.byte_count%TYPE INDEX BY PLS_INTEGER;
  TYPE g_byte_count_decimal_ttype  IS TABLE OF xxcff_fa_upload_v.byte_count_decimal%TYPE INDEX BY PLS_INTEGER;
  TYPE g_pay_match_flag_name_ttype IS TABLE OF xxcff_fa_upload_v.payment_match_flag_name%TYPE INDEX BY PLS_INTEGER;
  TYPE g_item_attribute_ttype      IS TABLE OF xxcff_fa_upload_v.item_attribute%TYPE INDEX BY PLS_INTEGER;
--
    -- ÅèYAbv[h[Næ¾f[^R[h^
  TYPE g_upload_rtype IS RECORD(
     line_no                       xxcff_fa_upload_work.line_no%TYPE                     -- sÔ
    ,process_type                  xxcff_fa_upload_work.process_type%TYPE                -- æª
    ,asset_number                  xxcff_fa_upload_work.asset_number%TYPE                -- YÔ
    ,description                   xxcff_fa_upload_work.description%TYPE                 -- Ev
    ,asset_category                xxcff_fa_upload_work.asset_category%TYPE              -- íÞ
    ,deprn_declaration             xxcff_fa_upload_work.deprn_declaration%TYPE           -- p\
    ,asset_account                 xxcff_fa_upload_work.asset_account%TYPE               -- Y¨è
    ,deprn_account                 xxcff_fa_upload_work.deprn_account%TYPE               -- pÈÚ
    ,deprn_sub_account             xxcff_fa_upload_work.deprn_sub_account%TYPE           -- pâÈÚ
    ,life_in_months                xxcff_fa_upload_work.life_in_months%TYPE              -- ÏpN
    ,cat_deprn_method              xxcff_fa_upload_work.cat_deprn_method%TYPE            -- pû@
    ,lease_class                   xxcff_fa_upload_work.lease_class%TYPE                 -- [XíÊ
    ,date_placed_in_service        xxcff_fa_upload_work.date_placed_in_service%TYPE      -- Æpú
    ,original_cost                 xxcff_fa_upload_work.original_cost%TYPE               -- æ¾¿z
    ,quantity                      xxcff_fa_upload_work.quantity%TYPE                    -- PÊÊ
    ,company_code                  xxcff_fa_upload_work.company_code%TYPE                -- ïÐ
    ,department_code               xxcff_fa_upload_work.department_code%TYPE             -- å
    ,dclr_place                    xxcff_fa_upload_work.dclr_place%TYPE                  -- \n
    ,location_name                 xxcff_fa_upload_work.location_name%TYPE               -- Æ
    ,location_place                xxcff_fa_upload_work.location_place%TYPE              -- ê
    ,yobi1                         xxcff_fa_upload_work.yobi1%TYPE                       -- \õ1
    ,yobi2                         xxcff_fa_upload_work.yobi2%TYPE                       -- \õ2
    ,assets_date                   xxcff_fa_upload_work.assets_date%TYPE                 -- æ¾ú
    ,ifrs_life_in_months           xxcff_fa_upload_work.ifrs_life_in_months%TYPE         -- IFRSÏpN
    ,ifrs_cat_deprn_method         xxcff_fa_upload_work.ifrs_cat_deprn_method%TYPE       -- IFRSp
    ,real_estate_acq_tax           xxcff_fa_upload_work.real_estate_acq_tax%TYPE         -- s®Yæ¾Å
    ,borrowing_cost                xxcff_fa_upload_work.borrowing_cost%TYPE              -- ØüRXg
    ,other_cost                    xxcff_fa_upload_work.other_cost%TYPE                  -- »Ì¼
    ,ifrs_asset_account            xxcff_fa_upload_work.ifrs_asset_account%TYPE          -- IFRSYÈÚ
    ,correct_date                  xxcff_fa_upload_work.correct_date%TYPE                -- C³Nú
  );
--
    -- ÅèYf[^R[h^
  TYPE g_fa_rtype IS RECORD(
     asset_number_old              xx01_adjustment_oif.asset_number_old%TYPE              -- YÔ
    ,dpis_old                      xx01_adjustment_oif.dpis_old%TYPE                      -- ÆpúiC³Oj
    ,category_id_old               xx01_adjustment_oif.category_id_old%TYPE               -- YJeSIDiC³Oj
    ,cat_attribute_category_old    xx01_adjustment_oif.cat_attribute_category_old%TYPE    -- YJeSR[hiC³Oj
    ,description                   xx01_adjustment_oif.description%TYPE                   -- Ev
    ,transaction_units             xx01_adjustment_oif.transaction_units%TYPE             -- PÊ
    ,cost                          xx01_adjustment_oif.cost%TYPE                          -- æ¾¿z
    ,original_cost                 xx01_adjustment_oif.original_cost%TYPE                 -- æ¾¿z
    ,asset_number_new              xx01_adjustment_oif.asset_number_new%TYPE              -- YÔiC³ãj
    ,tag_number                    xx01_adjustment_oif.tag_number%TYPE                    -- »i[Ô
    ,category_id_new               xx01_adjustment_oif.category_id_new%TYPE               -- YJeSIDiC³ãj
    ,serial_number                 xx01_adjustment_oif.serial_number%TYPE                 -- VAÔ
    ,asset_key_ccid                xx01_adjustment_oif.asset_key_ccid%TYPE                -- YL[CCID
    ,key_segment1                  xx01_adjustment_oif.key_segment1%TYPE                  -- YL[ZOg1
    ,key_segment2                  xx01_adjustment_oif.key_segment2%TYPE                  -- YL[ZOg2
    ,parent_asset_id               xx01_adjustment_oif.parent_asset_id%TYPE               -- eYID
    ,lease_id                      xx01_adjustment_oif.lease_id%TYPE                      -- [XID
    ,model_number                  xx01_adjustment_oif.model_number%TYPE                  -- f
    ,in_use_flag                   xx01_adjustment_oif.in_use_flag%TYPE                   -- gpóµ
    ,inventorial                   xx01_adjustment_oif.inventorial%TYPE                   -- ÀnIµtO
    ,owned_leased                  xx01_adjustment_oif.owned_leased%TYPE                  -- L 
    ,new_used                      xx01_adjustment_oif.new_used%TYPE                      -- Vi/Ã
    ,cat_attribute1                xx01_adjustment_oif.cat_attribute1%TYPE                -- JeSDFF1
    ,cat_attribute2                xx01_adjustment_oif.cat_attribute2%TYPE                -- JeSDFF2
    ,cat_attribute3                xx01_adjustment_oif.cat_attribute3%TYPE                -- JeSDFF3
    ,cat_attribute4                xx01_adjustment_oif.cat_attribute4%TYPE                -- JeSDFF4
    ,cat_attribute5                xx01_adjustment_oif.cat_attribute5%TYPE                -- JeSDFF5
    ,cat_attribute6                xx01_adjustment_oif.cat_attribute6%TYPE                -- JeSDFF6
    ,cat_attribute7                xx01_adjustment_oif.cat_attribute7%TYPE                -- JeSDFF7
    ,cat_attribute8                xx01_adjustment_oif.cat_attribute8%TYPE                -- JeSDFF8
    ,cat_attribute9                xx01_adjustment_oif.cat_attribute9%TYPE                -- JeSDFF9
    ,cat_attribute10               xx01_adjustment_oif.cat_attribute10%TYPE               -- JeSDFF10
    ,cat_attribute11               xx01_adjustment_oif.cat_attribute11%TYPE               -- JeSDFF11
    ,cat_attribute12               xx01_adjustment_oif.cat_attribute12%TYPE               -- JeSDFF12
    ,cat_attribute13               xx01_adjustment_oif.cat_attribute13%TYPE               -- JeSDFF13
    ,cat_attribute14               xx01_adjustment_oif.cat_attribute14%TYPE               -- JeSDFF14
    ,cat_attribute15               xx01_adjustment_oif.cat_attribute15%TYPE               -- JeSDFF15(IFRSÏpN)
    ,cat_attribute16               xx01_adjustment_oif.cat_attribute16%TYPE               -- JeSDFF16(IFRSp)
    ,cat_attribute17               xx01_adjustment_oif.cat_attribute17%TYPE               -- JeSDFF17(s®Yæ¾Å)
    ,cat_attribute18               xx01_adjustment_oif.cat_attribute18%TYPE               -- JeSDFF18(ØüRXg)
    ,cat_attribute19               xx01_adjustment_oif.cat_attribute19%TYPE               -- JeSDFF19(»Ì¼)
    ,cat_attribute20               xx01_adjustment_oif.cat_attribute20%TYPE               -- JeSDFF20(IFRSYÈÚ)
    ,cat_attribute21               xx01_adjustment_oif.cat_attribute21%TYPE               -- JeSDFF21(C³Nú)
    ,cat_attribute22               xx01_adjustment_oif.cat_attribute22%TYPE               -- JeSDFF22
    ,cat_attribute23               xx01_adjustment_oif.cat_attribute23%TYPE               -- JeSDFF23
    ,cat_attribute24               xx01_adjustment_oif.cat_attribute24%TYPE               -- JeSDFF24
    ,cat_attribute25               xx01_adjustment_oif.cat_attribute25%TYPE               -- JeSDFF27
    ,cat_attribute26               xx01_adjustment_oif.cat_attribute26%TYPE               -- JeSDFF25
    ,cat_attribute27               xx01_adjustment_oif.cat_attribute27%TYPE               -- JeSDFF26
    ,cat_attribute28               xx01_adjustment_oif.cat_attribute28%TYPE               -- JeSDFF28
    ,cat_attribute29               xx01_adjustment_oif.cat_attribute29%TYPE               -- JeSDFF29
    ,cat_attribute30               xx01_adjustment_oif.cat_attribute30%TYPE               -- JeSDFF30
    ,cat_attribute_category_new    xx01_adjustment_oif.cat_attribute_category_new%TYPE    -- YJeSR[hiC³ãj
    ,salvage_value                 xx01_adjustment_oif.salvage_value%TYPE                 -- c¶¿z
    ,percent_salvage_value         xx01_adjustment_oif.percent_salvage_value%TYPE         -- c¶¿z%
    ,allowed_deprn_limit_amount    xx01_adjustment_oif.allowed_deprn_limit_amount%TYPE    -- pÀxz
    ,allowed_deprn_limit           xx01_adjustment_oif.allowed_deprn_limit%TYPE           -- pÀx¦
    ,ytd_deprn                     xx01_adjustment_oif.ytd_deprn%TYPE                     -- NpÝvz
    ,deprn_reserve                 xx01_adjustment_oif.deprn_reserve%TYPE                 -- pÝvz
    ,depreciate_flag               xx01_adjustment_oif.depreciate_flag%TYPE               -- pïvãtO
    ,deprn_method_code             xx01_adjustment_oif.deprn_method_code%TYPE             -- pû@
    ,basic_rate                    xx01_adjustment_oif.basic_rate%TYPE                    -- Êp¦
    ,adjusted_rate                 xx01_adjustment_oif.adjusted_rate%TYPE                 -- ãp¦
    ,life_in_months                NUMBER                                                 -- ÏpN{
    ,bonus_rule                    xx01_adjustment_oif.bonus_rule%TYPE                    -- {[iX[
    ,bonus_ytd_deprn               xx01_adjustment_oif.bonus_ytd_deprn%TYPE               -- {[iXNpÝvz
    ,bonus_deprn_reserve           xx01_adjustment_oif.bonus_deprn_reserve%TYPE           -- {[iXpÝvz
  );
--
  -- ÅèYf[^æÎÛf[^R[hzñ
  TYPE g_upload_ttype          IS TABLE OF g_upload_rtype
    INDEX BY BINARY_INTEGER;
  -- ÅèYf[^R[hzñ
  TYPE g_fa_ttype              IS TABLE OF g_fa_rtype
    INDEX BY BINARY_INTEGER;
--
  -- ===============================
  -- [U[è`O[oÏ
  -- ===============================
--
  -- p[^
  gn_file_id                   NUMBER;                                           -- t@CID
  gd_process_date              DATE;                                             -- Æ±út
  gn_set_of_book_id            NUMBER(15);                                       -- ïv ëID
  gt_chart_of_account_id       gl_sets_of_books.chart_of_accounts_id%TYPE;       -- ÈÚÌnID
  gt_application_short_name    fnd_application.application_short_name%TYPE;      -- GLAvP[VZk¼
  gt_id_flex_code              fnd_id_flex_structures_vl.id_flex_code%TYPE;      -- L[tbNXR[h
--
  -- vt@Cl
  gv_company_cd_itoen          VARCHAR2(100);                                    -- ïÐR[h_{Ð
  gv_fixed_asset_register      VARCHAR2(100);                                    -- ä íÞ_ÅèYä 
-- Ver1.1 Del Start
--  gv_own_comp_itoen            VARCHAR2(100);                                    -- {ÐHêæª_{Ð
--  gv_own_comp_sagara           VARCHAR2(100);                                    -- {ÐHêæª_Hê
-- Ver1.1 Del End
  gv_feed_sys_nm               VARCHAR2(100);                                    -- VXe¼_FAAbv[h
  gv_cat_dep_ifrs              VARCHAR2(100);                                    -- IFRSpû@
--
  gt_period_name               fa_deprn_periods.period_name%TYPE;                -- ÅVïvúÔ¼
  gt_period_open_date          fa_deprn_periods.calendar_period_open_date%TYPE;  -- ÅVïvúÔJnú
  gt_period_close_date         fa_deprn_periods.calendar_period_close_date%TYPE; -- ÅVïvúÔI¹ú
--
  -- 
  -- ÇÁOIFo^É¨¯é
  gn_add_target_cnt            NUMBER;        -- ÎÛ
  gn_add_normal_cnt            NUMBER;        -- ³í
  gn_add_error_cnt             NUMBER;        -- G[
  -- C³OIFo^É¨¯é
  gn_adj_target_cnt            NUMBER;        -- ÎÛ
  gn_adj_normal_cnt            NUMBER;        -- ³í
  gn_adj_error_cnt             NUMBER;        -- G[
--
  -- úlîñ
  g_init_rec                   xxcff_common1_pkg.init_rtype;
--
  --t@CAbv[hIFf[^
  g_if_data_tab                xxccp_common_pkg2.g_file_data_tbl;
--
  --¶Úªãf[^i[zñ
  g_load_data_tab              g_load_data_ttype;
--
  -- Úl`FbNpÌlæ¾pè`
  g_column_desc_tab            g_column_desc_ttype;
  g_byte_count_tab             g_byte_count_ttype;
  g_byte_count_decimal_tab     g_byte_count_decimal_ttype;
  g_pay_match_flag_name_tab    g_pay_match_flag_name_ttype;
  g_item_attribute_tab         g_item_attribute_ttype;
--
  -- ZOglzñ(EBSWÖfnd_flex_extp)
  g_segments_tab               fnd_flex_ext.segmentarray;
--
  -- ÅèYAbv[h[Næ¾ÎÛf[^
  g_upload_tab                 g_upload_ttype;
  -- ÅèYf[^
  g_fa_tab                     g_fa_ttype;
--
  -- G[tO
  gb_err_flag                  BOOLEAN;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ú(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    in_file_id    IN  NUMBER       --   1.t@CID
   ,ov_errbuf     OUT VARCHAR2     --   G[EbZ[W           --# Åè #
   ,ov_retcode    OUT VARCHAR2     --   ^[ER[h             --# Åè #
   ,ov_errmsg     OUT VARCHAR2     --   [U[EG[EbZ[W --# Åè #
  )
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
    lt_file_name         xxccp_mrp_file_ul_interface.file_name%TYPE;        -- CSVt@C¼
    lt_deprn_run         fa_deprn_periods.deprn_run%TYPE;                   -- ¸¿pÀstO
    lv_param             VARCHAR2(1000);                                    -- p[^oÍp
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
    -- ***************************************
    -- ***        ÀÌLq             ***
    -- ***       ¤ÊÖÌÄÑoµ        ***
    -- ***************************************
--
    -- ===============================
    -- CSVt@C¼æ¾
    -- ===============================
    BEGIN
      SELECT xfu.file_name AS file_name
      INTO   lt_file_name
      FROM   xxccp_mrp_file_ul_interface  xfu  -- t@CAbv[hI/Fe[u
      WHERE  xfu.file_id   = in_file_id
      ;
    EXCEPTION
      -- Abv[hCSVt@C¼ªæ¾Å«È¢ê
      WHEN NO_DATA_FOUND THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_msg_kbn_cff       -- AvP[VZk¼
                      ,iv_name         => cv_msg_name_00234    -- bZ[W
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
--
    -- ===============================
    -- p[^oÍ
    -- ===============================
    lv_param := xxccp_common_pkg.get_msg(
                   iv_application  => cv_msg_kbn_cff         -- AvP[VZk¼
                  ,iv_name         => cv_msg_name_00167      -- bZ[W
                  ,iv_token_name1  => cv_tkn_file_name       -- g[NR[h1
                  ,iv_token_value1 => cv_tkn_val_50295       -- g[Nl1
                  ,iv_token_name2  => cv_tkn_csv_name        -- g[NR[h2
                  ,iv_token_value2 => lt_file_name           -- g[Nl2
                );
--
    -- Abv[ht@C¼ÌACSVt@C¼oÍiOj
    FND_FILE.PUT_LINE(
      which  => FND_FILE.LOG
     ,buff   => lv_param
    );
    -- Abv[ht@C¼ÌACSVt@C¼oÍioÍj
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_param
    );
--
    -- RJgp[^loÍ(O)
    xxcff_common1_pkg.put_log_param(
       iv_which     => cv_file_type_log    -- oÍæª
      ,ov_errbuf    => lv_errbuf           -- G[EbZ[W           --# Åè #
      ,ov_retcode   => lv_retcode          -- ^[ER[h             --# Åè #
      ,ov_errmsg    => lv_errmsg           -- [U[EG[EbZ[W --# Åè #
    );
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_api_expt;
    END IF;
--
    -- RJgp[^loÍ(oÍ)
    xxcff_common1_pkg.put_log_param(
       iv_which     => cv_file_type_out    -- oÍæª
      ,ov_errbuf    => lv_errbuf           -- G[EbZ[W           --# Åè #
      ,ov_retcode   => lv_retcode          -- ^[ER[h             --# Åè #
      ,ov_errmsg    => lv_errmsg           -- [U[EG[EbZ[W --# Åè #
    );
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_api_expt;
    END IF;
--
    -- ===============================
    -- úlîñæ¾
    -- ===============================
    xxcff_common1_pkg.init(
       or_init_rec  => g_init_rec           -- úlîñ
      ,ov_errbuf    => lv_errbuf            -- G[EbZ[W           --# Åè #
      ,ov_retcode   => lv_retcode           -- ^[ER[h             --# Åè #
      ,ov_errmsg    => lv_errmsg            -- [U[EG[EbZ[W --# Åè #
    );
    -- ¤ÊÖªG[Ìê
    IF ( lv_retcode <> cv_status_normal ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_cff         -- AvP[VZk¼
                     ,iv_name         => cv_msg_name_00258      -- bZ[W
                     ,iv_token_name1  => cv_tkn_line_no         -- g[NR[h1
                     ,iv_token_value1 => 0                      -- g[Nl1
                     ,iv_token_name2  => cv_tkn_func_name       -- g[NR[h2
                     ,iv_token_value2 => cv_tkn_val_50130       -- g[Nl2
                     ,iv_token_name3  => cv_tkn_info            -- g[NR[h3
                     ,iv_token_value3 => lv_errmsg              -- g[Nl3
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ===============================
    -- vt@Cæ¾
    -- ===============================
    -- XXCFF:ïÐR[h_{Ð
    gv_company_cd_itoen := FND_PROFILE.VALUE(cv_prf_cmp_cd_itoen);
    -- æ¾lªNULLÌê
    IF ( gv_company_cd_itoen IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_cff         -- AvP[VZk¼
                     ,iv_name         => cv_msg_name_00020      -- bZ[W
                     ,iv_token_name1  => cv_tkn_prof_name       -- g[NR[h1
                     ,iv_token_value1 => cv_tkn_val_50076       -- g[Nl1
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- XXCFF:ä íÞ_ÅèYä 
    gv_fixed_asset_register := FND_PROFILE.VALUE(cv_prf_fixd_ast_reg);
    -- æ¾lªNULLÌê
    IF ( gv_fixed_asset_register IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_cff         -- AvP[VZk¼
                     ,iv_name         => cv_msg_name_00020      -- bZ[W
                     ,iv_token_name1  => cv_tkn_prof_name       -- g[NR[h1
                     ,iv_token_value1 => cv_tkn_val_50228       -- g[Nl1
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
-- Ver1.1 Del Start
----
--    -- XXCFF:{ÐHêæª_{Ð
--    gv_own_comp_itoen := FND_PROFILE.VALUE(cv_prf_own_itoen);
--    -- æ¾lªNULLÌê
--    IF ( gv_own_comp_itoen IS NULL ) THEN
--      lv_errmsg := xxccp_common_pkg.get_msg(
--                      iv_application  => cv_msg_kbn_cff         -- AvP[VZk¼
--                     ,iv_name         => cv_msg_name_00020      -- bZ[W
--                     ,iv_token_name1  => cv_tkn_prof_name       -- g[NR[h1
--                     ,iv_token_value1 => cv_tkn_val_50095       -- g[Nl1
--                   );
--      lv_errbuf := lv_errmsg;
--      RAISE global_api_expt;
--    END IF;
----
--    -- XXCFF:{ÐHêæª_Hê
--    gv_own_comp_sagara := FND_PROFILE.VALUE(cv_prf_own_sagara);
--    -- æ¾lªNULLÌê
--    IF ( gv_own_comp_sagara IS NULL ) THEN
--      lv_errmsg := xxccp_common_pkg.get_msg(
--                      iv_application  => cv_msg_kbn_cff         -- AvP[VZk¼
--                     ,iv_name         => cv_msg_name_00020      -- bZ[W
--                     ,iv_token_name1  => cv_tkn_prof_name       -- g[NR[h1
--                     ,iv_token_value1 => cv_tkn_val_50096       -- g[Nl1
--                   );
--      lv_errbuf := lv_errmsg;
--      RAISE global_api_expt;
--    END IF;
-- Ver1.1 Del End
--
    -- XXCFF:VXe¼_FAAbv[h
    gv_feed_sys_nm := FND_PROFILE.VALUE(cv_prf_feed_sys_nm);
    -- æ¾lªNULLÌê
    IF ( gv_feed_sys_nm IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_cff         -- AvP[VZk¼
                     ,iv_name         => cv_msg_name_00020      -- bZ[W
                     ,iv_token_name1  => cv_tkn_prof_name       -- g[NR[h1
                     ,iv_token_value1 => cv_tkn_val_50305       -- g[Nl1
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- XXCFF:IFRSpû@
    gv_cat_dep_ifrs := FND_PROFILE.VALUE(cv_prf_cat_dep_ifrs);
    -- æ¾lªNULLÌê
    IF ( gv_cat_dep_ifrs IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_cff         -- AvP[VZk¼
                     ,iv_name         => cv_msg_name_00020      -- bZ[W
                     ,iv_token_name1  => cv_tkn_prof_name       -- g[NR[h1
                     ,iv_token_value1 => cv_tkn_val_50318       -- g[Nl1
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ===============================
    -- ÅVïvúÔæ¾
    -- ===============================
    SELECT MAX(fdp.period_name)                AS period_name
          ,MAX(fdp.calendar_period_open_date)  AS period_open_date
          ,MAX(fdp.calendar_period_close_date) AS period_close_date
    INTO   gt_period_name
          ,gt_period_open_date
          ,gt_period_close_date
    FROM   fa_deprn_periods  fdp  -- ¸¿púÔ
    WHERE  fdp.book_type_code  =  gv_fixed_asset_register
    ;
    -- ÅVïvúÔªæ¾Å«È¢ê
    IF ( gt_period_name IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_cff           -- AvP[VZk¼
                    ,iv_name         => cv_msg_name_00236        -- bZ[W
                    ,iv_token_name1  => cv_tkn_param_name        -- g[NR[h1
                    ,iv_token_value1 => gv_fixed_asset_register  -- g[Nl1
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ===============================
    -- ïvúÔ`FbN
    -- ===============================
    BEGIN
      SELECT fdp.deprn_run AS deprn_run
      INTO   lt_deprn_run
      FROM   fa_deprn_periods  fdp  -- ¸¿púÔ
      WHERE  fdp.book_type_code    = gv_fixed_asset_register
      AND    fdp.period_name       = gt_period_name
      AND    fdp.period_close_date IS NULL
      ;
    EXCEPTION
      -- ¸¿pÀstOªæ¾Å«È¢ê
      WHEN NO_DATA_FOUND THEN
        RAISE chk_period_expt;
    END;
--
    -- ¸¿pÀsÏÝÌê
    IF ( lt_deprn_run = cv_yes ) THEN
      RAISE chk_period_expt;
    END IF;
--
    -- úlðO[oÏÉi[
    gn_file_id                 := in_file_id;                            -- t@CID
    gd_process_date            := g_init_rec.process_date;               -- Æ±út
    gn_set_of_book_id          := g_init_rec.set_of_books_id;            -- ïv ëID
    gt_chart_of_account_id     := g_init_rec.chart_of_accounts_id;       -- ÈÚÌnID
    gt_application_short_name  := g_init_rec.gl_application_short_name;  -- GLAvP[VZk¼
    gt_id_flex_code            := g_init_rec.id_flex_code;               -- L[tbNXR[h
--
  EXCEPTION
--
    -- *** ïvúÔ`FbNG[nh ***
    WHEN chk_period_expt THEN
      ov_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_cff           -- AvP[VZk¼
                     ,iv_name         => cv_msg_name_00037        -- bZ[W
                     ,iv_token_name1  => cv_tkn_book_type         -- g[NR[h1
                     ,iv_token_value1 => gv_fixed_asset_register  -- g[Nl1
                     ,iv_token_name2  => cv_tkn_period_name       -- g[NR[h2
                     ,iv_token_value2 => gt_period_name           -- g[Nl2
                    );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
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
  END init;
--
  /**********************************************************************************
   * Procedure Name   : get_for_validation
   * Description      : Ã«`FbNpÌlæ¾(A-2)
   ***********************************************************************************/
  PROCEDURE get_for_validation(
    ov_errbuf     OUT VARCHAR2     --   G[EbZ[W           --# Åè #
   ,ov_retcode    OUT VARCHAR2     --   ^[ER[h             --# Åè #
   ,ov_errmsg     OUT VARCHAR2     --   [U[EG[EbZ[W --# Åè #
  )
  IS
    -- ===============================
    -- Åè[Jè
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_for_validation'; -- vO¼
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
    CURSOR get_validate_cur
    IS
      SELECT xfu.column_desc               AS column_desc               -- Ú¼Ì
            ,xfu.byte_count                AS byte_count                -- oCg
            ,xfu.byte_count_decimal        AS byte_count_decimal        -- oCg_¬_Èº
            ,xfu.payment_match_flag_name   AS payment_match_flag_name   -- K{tO
            ,xfu.item_attribute            AS item_attribute            -- Ú®«
      FROM   xxcff_fa_upload_v  xfu    -- ÅèYAbv[hr[
      ORDER BY
             xfu.code ASC
    ;
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
    -- ***************************************
    -- ***        ÀÌLq             ***
    -- ***       ¤ÊÖÌÄÑoµ        ***
    -- ***************************************
--
    --J[\ÌI[v
    OPEN get_validate_cur;
    FETCH get_validate_cur
    BULK COLLECT INTO g_column_desc_tab               -- Ú¼Ì
                     ,g_byte_count_tab                -- oCg
                     ,g_byte_count_decimal_tab        -- oCg_¬_Èº
                     ,g_pay_match_flag_name_tab       -- K{tO
                     ,g_item_attribute_tab            -- Ú®«
    ;
--
    --J[\ÌN[Y
    CLOSE get_validate_cur;
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
      IF ( get_validate_cur%ISOPEN ) THEN
        CLOSE get_validate_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  Åè END   ##########################################
--
  END get_for_validation;
--
  /**********************************************************************************
   * Procedure Name   : get_upload_data
   * Description      : t@CAbv[hIFf[^æ¾(A-3)
   ***********************************************************************************/
  PROCEDURE get_upload_data(
    ov_errbuf     OUT VARCHAR2     --   G[EbZ[W           --# Åè #
   ,ov_retcode    OUT VARCHAR2     --   ^[ER[h             --# Åè #
   ,ov_errmsg     OUT VARCHAR2     --   [U[EG[EbZ[W --# Åè #
  )
  IS
    -- ===============================
    -- Åè[Jè
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_upload_data'; -- vO¼
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
    -- t@CAbv[hIFf[^ðæ¾
    xxccp_common_pkg2.blob_to_varchar2(
      in_file_id   => gn_file_id       -- t@CID
     ,ov_file_data => g_if_data_tab    -- Ï·ãVARCHAR2f[^
     ,ov_errbuf    => lv_errbuf        -- G[EbZ[W           --# Åè #
     ,ov_retcode   => lv_retcode       -- ^[ER[h             --# Åè #
     ,ov_errmsg    => lv_errmsg        -- [U[EG[EbZ[W --# Åè #
    );
    -- ¤ÊÖG[Ìê
    IF ( lv_retcode <> cv_status_normal ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_cff         -- AvP[VZk¼
                     ,iv_name         => cv_msg_name_00258      -- bZ[W
                     ,iv_token_name1  => cv_tkn_line_no         -- g[NR[h1
                     ,iv_token_value1 => 0                      -- g[Nl1
                     ,iv_token_name2  => cv_tkn_func_name       -- g[NR[h2
                     ,iv_token_value2 => cv_tkn_val_50131       -- g[Nl2
                     ,iv_token_name3  => cv_tkn_info            -- g[NR[h3
                     ,iv_token_value3 => lv_errmsg              -- g[Nl3
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ÎÛði[(wb_ð­)
    gn_target_cnt := g_if_data_tab.COUNT - 1 ;
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
  END get_upload_data;
--
  /**********************************************************************************
   * Procedure Name   : divide_item
   * Description      : f~^¶Úª(A-4)
   ***********************************************************************************/
  PROCEDURE divide_item(
    in_loop_cnt_1 IN  NUMBER       --   [vJE^1
   ,in_loop_cnt_2 IN  NUMBER       --   [vJE^2
   ,ov_errbuf     OUT VARCHAR2     --   G[EbZ[W           --# Åè #
   ,ov_retcode    OUT VARCHAR2     --   ^[ER[h             --# Åè #
   ,ov_errmsg     OUT VARCHAR2     --   [U[EG[EbZ[W --# Åè #
  )
  IS
    -- ===============================
    -- Åè[Jè
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'divide_item'; -- vO¼
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
    -- f~^¶ªÌ¤ÊÖÌÄo
    g_load_data_tab(in_loop_cnt_2) := xxccp_common_pkg.char_delim_partition(
                                         g_if_data_tab(in_loop_cnt_1)         -- ª³¶ñ
                                        ,cv_csv_delimiter                     -- f~^¶
                                        ,in_loop_cnt_2                        -- ÔpÎÛINDEX
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
  END divide_item;
--
  /**********************************************************************************
   * Procedure Name   : check_item_value
   * Description      : Úl`FbN(A-5)
   ***********************************************************************************/
  PROCEDURE check_item_value(
    in_lino_no    IN  NUMBER       -- sÔJE^
   ,in_loop_cnt_2 IN  NUMBER       -- [vJE^2
   ,ov_errbuf     OUT VARCHAR2     --   G[EbZ[W           --# Åè #
   ,ov_retcode    OUT VARCHAR2     --   ^[ER[h             --# Åè #
   ,ov_errmsg     OUT VARCHAR2     --   [U[EG[EbZ[W --# Åè #
  )
  IS
    -- ===============================
    -- Åè[Jè
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'check_item_value'; -- vO¼
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
    -- Ú`FbNÌ¤ÊÖÌÄo
    xxccp_common_pkg2.upload_item_check(
       iv_item_name    => g_column_desc_tab(in_loop_cnt_2)            -- Ú¼Ì
      ,iv_item_value   => g_load_data_tab(in_loop_cnt_2)              -- ÚÌl
      ,in_item_len     => g_byte_count_tab(in_loop_cnt_2)             -- oCg/ÚÌ·³
      ,in_item_decimal => g_byte_count_decimal_tab(in_loop_cnt_2)     -- oCg_¬_Èº/ÚÌ·³i¬_Èºj
      ,iv_item_nullflg => g_pay_match_flag_name_tab(in_loop_cnt_2)    -- K{tO
      ,iv_item_attr    => g_item_attribute_tab(in_loop_cnt_2)         -- Ú®«
      ,ov_errbuf       => lv_errbuf                                   -- G[EbZ[W           --# Åè #
      ,ov_retcode      => lv_retcode                                  -- ^[ER[h             --# Åè #
      ,ov_errmsg       => lv_errmsg                                   -- [U[EG[EbZ[W --# Åè #
    );
    -- ^[R[hªxÌêiÎÛf[^Ésõª Á½êj
    IF ( lv_retcode = cv_status_warn ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_cff               -- AvP[VZk¼
                     ,iv_name         => cv_msg_name_00258            -- bZ[W
                     ,iv_token_name1  => cv_tkn_line_no               -- g[NR[h1
                     ,iv_token_value1 => TO_CHAR(in_lino_no)          -- g[Nl1
                     ,iv_token_name2  => cv_tkn_func_name             -- g[NR[h2
                     ,iv_token_value2 => cv_tkn_val_50166             -- g[Nl2
                     ,iv_token_name3  => cv_tkn_info                  -- g[NR[h3
                     ,iv_token_value3 => LTRIM(lv_errmsg)             -- g[Nl3
                   );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg
      );
      -- G[tOðXV
      gb_err_flag := TRUE;
    -- ^[R[hªG[ÌêiÚ`FbNÅVXeG[ª­¶µ½êj
    ELSIF ( lv_retcode <> cv_status_normal ) THEN
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
  END check_item_value;
--
  /**********************************************************************************
   * Procedure Name   : ins_upload_wk
   * Description      : ÅèYAbv[h[Nì¬(A-6)
   ***********************************************************************************/
  PROCEDURE ins_upload_wk(
    in_line_no    IN  NUMBER       -- sÔ
   ,ov_errbuf     OUT VARCHAR2     --   G[EbZ[W           --# Åè #
   ,ov_retcode    OUT VARCHAR2     --   ^[ER[h             --# Åè #
   ,ov_errmsg     OUT VARCHAR2     --   [U[EG[EbZ[W --# Åè #
  )
  IS
    -- ===============================
    -- Åè[Jè
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_upload_wk'; -- vO¼
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
    -- ***************************************
    -- ***        ÀÌLq             ***
    -- ***       ¤ÊÖÌÄÑoµ        ***
    -- ***************************************
--
    BEGIN
      -- ÅèYAbv[h[Nì¬
      INSERT INTO xxcff_fa_upload_work(
        file_id                        -- t@CID
       ,line_no                        -- sÔ
       ,process_type                   -- æª
       ,asset_number                   -- YÔ
       ,description                    -- Ev
       ,asset_category                 -- íÞ
       ,deprn_declaration              -- p\
       ,asset_account                  -- Y¨è
       ,deprn_account                  -- pÈÚ
       ,deprn_sub_account              -- pâÈÚ
       ,life_in_months                 -- ÏpN
       ,cat_deprn_method               -- pû@
       ,lease_class                    -- [XíÊ
       ,date_placed_in_service         -- Æpú
       ,original_cost                  -- æ¾¿z
       ,quantity                       -- PÊÊ
       ,company_code                   -- ïÐ
       ,department_code                -- å
       ,dclr_place                     -- \n
       ,location_name                  -- Æ
       ,location_place                 -- ê
       ,yobi1                          -- \õ1
       ,yobi2                          -- \õ2
       ,assets_date                    -- æ¾ú
       ,ifrs_life_in_months            -- IFRSÏpN
       ,ifrs_cat_deprn_method          -- IFRSp
       ,real_estate_acq_tax            -- s®Yæ¾Å
       ,borrowing_cost                 -- ØüRXg
       ,other_cost                     -- »Ì¼
       ,ifrs_asset_account             -- IFRSYÈÚ
       ,correct_date                   -- C³Nú
       ,created_by                     -- ì¬Ò
       ,creation_date                  -- ì¬ú
       ,last_updated_by                -- ÅIXVÒ
       ,last_update_date               -- ÅIXVú
       ,last_update_login              -- ÅIXVOC
       ,request_id                     -- vID
       ,program_application_id         -- RJgEvOEAvP[VID
       ,program_id                     -- RJgEvOID
       ,program_update_date            -- vOXVú
      )
      VALUES (
        gn_file_id                                      -- t@CID
       ,in_line_no                                      -- sÔ
       ,g_load_data_tab(1)                              -- æª
       ,g_load_data_tab(2)                              -- YÔ
       ,g_load_data_tab(3)                              -- Ev
       ,g_load_data_tab(4)                              -- íÞ
       ,g_load_data_tab(5)                              -- p\
       ,g_load_data_tab(6)                              -- Y¨è
       ,g_load_data_tab(7)                              -- pÈÚ
       ,g_load_data_tab(8)                              -- pâÈÚ
       ,g_load_data_tab(9)                              -- ÏpN
       ,g_load_data_tab(10)                             -- pû@
       ,g_load_data_tab(11)                             -- [XíÊ
       ,TO_DATE(g_load_data_tab(12) ,cv_date_fmt_std)   -- Æpú
       ,g_load_data_tab(13)                             -- æ¾¿z
       ,g_load_data_tab(14)                             -- PÊÊ
       ,g_load_data_tab(15)                             -- ïÐ
       ,g_load_data_tab(16)                             -- å
       ,g_load_data_tab(17)                             -- \n
       ,g_load_data_tab(18)                             -- Æ
       ,g_load_data_tab(19)                             -- ê
       ,g_load_data_tab(20)                             -- \õ1
       ,g_load_data_tab(21)                             -- \õ2
       ,TO_DATE(g_load_data_tab(22) ,cv_date_fmt_std)   -- æ¾ú
       ,g_load_data_tab(23)                             -- IFRSÏpN
       ,g_load_data_tab(24)                             -- IFRSp
       ,g_load_data_tab(25)                             -- s®Yæ¾Å
       ,g_load_data_tab(26)                             -- ØüRXg
       ,g_load_data_tab(27)                             -- »Ì¼
       ,g_load_data_tab(28)                             -- IFRSYÈÚ
       ,TO_DATE(g_load_data_tab(29) ,cv_date_fmt_std)   -- C³Nú
       ,cn_created_by                                   -- ì¬Ò
       ,cd_creation_date                                -- ì¬ú
       ,cn_last_updated_by                              -- ÅIXVÒ
       ,cd_last_update_date                             -- ÅIXVú
       ,cn_last_update_login                            -- ÅIXVOC
       ,cn_request_id                                   -- vID
       ,cn_program_application_id                       -- RJgEvOEAvP[VI
       ,cn_program_id                                   -- RJgEvOID
       ,cd_program_update_date                          -- vOXVú
      );
    EXCEPTION
      WHEN OTHERS THEN
        -- o^G[
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_msg_kbn_cff           -- AvP[VZk¼
                       ,iv_name         => cv_msg_name_00102        -- bZ[W
                       ,iv_token_name1  => cv_tkn_table_name        -- g[NR[h1
                       ,iv_token_value1 => cv_tkn_val_50296         -- g[Nl1
                       ,iv_token_name2  => cv_tkn_info              -- g[NR[h2
                       ,iv_token_value2 => SQLERRM                  -- g[Nl2
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
--
    -- YÔªÝè³êÄ¢éê
    IF ( g_load_data_tab(2) IS NOT NULL ) THEN
      -- YÔ`FbNê\ì¬
      INSERT INTO xxcff_tmp_check_asset_num(
        asset_number    -- YÔ
       ,line_no         -- sÔ
      )
      VALUES (
        g_load_data_tab(2)  -- YÔ
       ,in_line_no          -- sÔ
      );
    END IF;
--
    --==============================================================
    --bZ[WoÍð·éKvª éêÍðLq
    --==============================================================
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
      ov_errmsg  := SQLERRM;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  Åè END   ##########################################
--
  END ins_upload_wk;
--
  /**********************************************************************************
   * Procedure Name   : get_upload_wk
   * Description      : ÅèYAbv[h[Næ¾(A-7)
   ***********************************************************************************/
  PROCEDURE get_upload_wk(
    ov_errbuf     OUT VARCHAR2     --   G[EbZ[W           --# Åè #
   ,ov_retcode    OUT VARCHAR2     --   ^[ER[h             --# Åè #
   ,ov_errmsg     OUT VARCHAR2     --   [U[EG[EbZ[W --# Åè #
  )
  IS
    -- ===============================
    -- Åè[Jè
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_upload_wk'; -- vO¼
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
    CURSOR get_fa_upload_wk_cur
    IS
      SELECT xfuw.line_no                     AS line_no                      -- sÔ
            ,xfuw.process_type                AS process_type                 -- æª
            ,xfuw.asset_number                AS asset_number                 -- YÔ
            ,xfuw.description                 AS description                  -- Ev
            ,xfuw.asset_category              AS asset_category               -- íÞ
            ,xfuw.deprn_declaration           AS deprn_declaration            -- p\
            ,xfuw.asset_account               AS asset_account                -- Y¨è
            ,xfuw.deprn_account               AS deprn_account                -- pÈÚ
            ,xfuw.deprn_sub_account           AS deprn_sub_account            -- pâÈÚ
            ,xfuw.life_in_months              AS life_in_months               -- ÏpN
            ,xfuw.cat_deprn_method            AS cat_deprn_method             -- pû@
            ,xfuw.lease_class                 AS lease_class                  -- [XíÊ
            ,xfuw.date_placed_in_service      AS date_placed_in_service       -- Æpú
            ,xfuw.original_cost               AS original_cost                -- æ¾¿z
            ,xfuw.quantity                    AS quantity                     -- PÊÊ
            ,xfuw.company_code                AS company_code                 -- ïÐ
            ,xfuw.department_code             AS department_code              -- å
            ,xfuw.dclr_place                  AS dclr_place                   -- \n
            ,xfuw.location_name               AS location_name                -- Æ
            ,xfuw.location_place              AS location_place               -- ê
            ,xfuw.yobi1                       AS yobi1                        -- \õ1
            ,xfuw.yobi2                       AS yobi2                        -- \õ2
            ,xfuw.assets_date                 AS assets_date                  -- æ¾ú
            ,xfuw.ifrs_life_in_months         AS ifrs_life_in_months          -- IFRSÏpN
            ,xfuw.ifrs_cat_deprn_method       AS ifrs_cat_deprn_method        -- IFRSp
            ,xfuw.real_estate_acq_tax         AS real_estate_acq_tax          -- s®Yæ¾Å
            ,xfuw.borrowing_cost              AS borrowing_cost               -- ØüRXg
            ,xfuw.other_cost                  AS other_cost                   -- »Ì¼
            ,xfuw.ifrs_asset_account          AS ifrs_asset_account           -- IFRSYÈÚ
            ,xfuw.correct_date                AS correct_date                 -- C³Nú
      FROM   xxcff_fa_upload_work  xfuw  -- ÅèYAbv[h[N
      WHERE  xfuw.file_id   = gn_file_id
      ORDER BY
             xfuw.line_no
    ;
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
    -- ***************************************
    -- ***        ÀÌLq             ***
    -- ***       ¤ÊÖÌÄÑoµ        ***
    -- ***************************************
--
    -- ÅèYAbv[h[Næ¾
    OPEN  get_fa_upload_wk_cur;
    FETCH get_fa_upload_wk_cur BULK COLLECT INTO g_upload_tab;
    CLOSE get_fa_upload_wk_cur;
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
      IF ( get_fa_upload_wk_cur%ISOPEN ) THEN
        CLOSE get_fa_upload_wk_cur;
      END IF;
      ov_errmsg  := SQLERRM;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  Åè END   ##########################################
--
  END get_upload_wk;
--
  /**********************************************************************************
   * Procedure Name   : data_validation
   * Description      : f[^Ã«`FbN(A-8)
   ***********************************************************************************/
  PROCEDURE data_validation(
    in_rec_no     IN  NUMBER        --   ÎÛR[hÔ
   ,ov_errbuf     OUT VARCHAR2      --   G[EbZ[W           --# Åè #
   ,ov_retcode    OUT VARCHAR2      --   ^[ER[h             --# Åè #
   ,ov_errmsg     OUT VARCHAR2      --   [U[EG[EbZ[W --# Åè #
  )
  IS
    -- ===============================
    -- Åè[Jè
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'data_validation'; -- vO¼
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
    ln_tmp_asset_number          NUMBER;                                                  -- ¼YÔ
    lt_initial_asset_id          fa_system_controls.initial_asset_id%TYPE;                -- úYID
    lt_use_cust_asset_num_flag   fa_system_controls.use_custom_asset_numbers_flag%TYPE;   -- [U[YÔgptO
    lt_adjustment_oif_id         xx01_adjustment_oif.adjustment_oif_id%TYPE;              -- C³OIFID
    ln_ifrs_org_cost             NUMBER;                                                  -- IFRSæ¾¿z
--
    lv_asset_number              VARCHAR2(15);                                            -- YÔ
    lt_asset_category            xxcff_category_v.category_code%TYPE;                     -- YíÞ
    lt_deprn_declaration         fnd_flex_values.flex_value%TYPE;                         -- p\
    lt_asset_account             fnd_flex_values.flex_value%TYPE;                         -- Y¨è
    lt_deprn_account             fnd_flex_values.flex_value%TYPE;                         -- pÈÚ
    lt_deprn_sub_account         xxcff_aff_sub_account_v.aff_sub_account_code%TYPE;       -- pâÈÚ
    lt_cat_deprn_method          fnd_flex_values.flex_value%TYPE;                         -- pû@
    lt_lease_class               xxcff_lease_class_v.lease_class_code%TYPE;               -- [XíÊ
    lt_company_code              xxcff_aff_company_v.aff_company_code%TYPE;               -- ïÐ
    lt_department_code           xxcff_aff_department_v.aff_department_code%TYPE;         -- å
    lt_dclr_place                fnd_flex_values.flex_value%TYPE;                         -- \n
    lt_location_name             fnd_flex_values.flex_value%TYPE;                         -- Æ
    lt_yobi1                     xxcff_aff_project_v.aff_project_code%TYPE;               -- \õ1
    lt_yobi2                     xxcff_aff_project_v.aff_project_code%TYPE;               -- \õ2
    lt_ifrs_cat_deprn_method     fnd_flex_values.flex_value%TYPE;                         -- IFRSp
    lt_ifrs_asset_account        xxcff_aff_account_v.aff_account_code%TYPE;               -- IFRSYÈÚ
--
    -- *** [JEJ[\ ***
    -- lZbg`FbNJ[\
    CURSOR check_flex_value_cur(
       iv_flex_value_set_name IN VARCHAR2    -- lZbg¼
      ,iv_flex_value          IN VARCHAR2    -- l
    )
    IS
      SELECT ffv.flex_value    AS flex_value
      FROM   fnd_flex_value_sets   ffvs    -- lZbg
            ,fnd_flex_values       ffv     -- lZbgl
      WHERE  ffvs.flex_value_set_id   = ffv.flex_value_set_id
      AND    ffvs.flex_value_set_name = iv_flex_value_set_name
      AND    ffv.flex_value           = iv_flex_value
      AND    ffv.enabled_flag         = cv_yes
      AND    gd_process_date         >= NVL(ffv.start_date_active ,gd_process_date)
      AND    gd_process_date         <= NVL(ffv.end_date_active ,gd_process_date)
      ;
    -- lZbg`FbNJ[\R[h^
    check_flex_value_rec  check_flex_value_cur%ROWTYPE;
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
    -- ***************************************
    -- ***        ÀÌLq             ***
    -- ***       ¤ÊÖÌÄÑoµ        ***
    -- ***************************************
--
    -- [JÏÌú»
    ln_tmp_asset_number          := NULL;  -- ¼YÔ
    lt_initial_asset_id          := NULL;  -- úYID
    lt_use_cust_asset_num_flag   := NULL;  -- [U[YÔgptO
    lt_adjustment_oif_id         := NULL;  -- C³OIFID
    ln_ifrs_org_cost             := NULL;  -- IFRSæ¾¿z
    lv_asset_number              := NULL;  -- YÔ
    lt_asset_category            := NULL;  -- YíÞ
    lt_deprn_declaration         := NULL;  -- p\
    lt_asset_account             := NULL;  -- Y¨è
    lt_deprn_account             := NULL;  -- pÈÚ
    lt_deprn_sub_account         := NULL;  -- pâÈÚ
    lt_cat_deprn_method          := NULL;  -- pû@
    lt_lease_class               := NULL;  -- [XíÊ
    lt_company_code              := NULL;  -- ïÐ
    lt_department_code           := NULL;  -- å
    lt_dclr_place                := NULL;  -- \n
    lt_location_name             := NULL;  -- Æ
    lt_yobi1                     := NULL;  -- \õ1
    lt_yobi2                     := NULL;  -- \õ2
    lt_ifrs_cat_deprn_method     := NULL;  -- IFRSp
    lt_ifrs_asset_account        := NULL;  -- IFRSYÈÚ
--
    -- ===============================
    -- üÍÚÃ«`FbN
    -- ===============================
--
    -- æªªu 1io^jvÌê
    IF ( g_upload_tab(in_rec_no).process_type = cv_process_type_1 ) THEN
      -- ÎÛJEg
      gn_add_target_cnt := gn_add_target_cnt + 1;
--
    -- æªªu 2iC³jvÌê
    ELSIF ( g_upload_tab(in_rec_no).process_type = cv_process_type_2 ) THEN
      -- ÎÛJEg
      gn_adj_target_cnt := gn_adj_target_cnt + 1;
--
      -- IFRSÚÌ¢¸êàNULLÅÈ¢©`FbN
      IF (  ( g_upload_tab(in_rec_no).ifrs_life_in_months IS NULL )    -- IFRSÏpN
        AND ( g_upload_tab(in_rec_no).ifrs_cat_deprn_method IS NULL )  -- IFRSp
        AND ( g_upload_tab(in_rec_no).real_estate_acq_tax IS NULL )    -- s®Yæ¾Å
        AND ( g_upload_tab(in_rec_no).borrowing_cost IS NULL )         -- ØüRXg
        AND ( g_upload_tab(in_rec_no).other_cost IS NULL )             -- »Ì¼
        AND ( g_upload_tab(in_rec_no).ifrs_asset_account IS NULL )     -- IFRSYÈÚ
      ) THEN
        -- üÍÚÃ«`FbNG[
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_msg_kbn_cff         -- AvP[VZk¼
                       ,iv_name         => cv_msg_name_00253      -- bZ[W
                       ,iv_token_name1  => cv_tkn_line_no         -- g[NR[h1
                       ,iv_token_value1 => TO_CHAR(in_rec_no)     -- g[Nl1
                     );
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_errmsg
        );
        -- G[tOðXV
        gb_err_flag := TRUE;
      END IF;
--
    -- æªªãLÈOÌê
    ELSE
--
      -- æªG[
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_cff         -- AvP[VZk¼
                     ,iv_name         => cv_msg_name_00252      -- bZ[W
                     ,iv_token_name1  => cv_tkn_line_no         -- g[NR[h1
                     ,iv_token_value1 => TO_CHAR(in_rec_no)     -- g[Nl1
                   );
      FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
       ,buff   => lv_errmsg
      );
      -- G[tOðXV
      gb_err_flag := TRUE;
--
    END IF;
--
    -- æªªu 1io^jvu 2iC³jvÌê
    IF ( g_upload_tab(in_rec_no).process_type IN ( cv_process_type_1 ,cv_process_type_2 ) ) THEN
      -- ===============================
      -- YÔ
      -- ===============================
      -- æªªu 2iC³jv©ÂAYÔªNULLÌê
      IF ( g_upload_tab(in_rec_no).process_type = cv_process_type_2 )
        AND ( g_upload_tab(in_rec_no).asset_number IS NULL ) THEN
        -- Ú¢ÝèG[
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_msg_kbn_cff         -- AvP[VZk¼
                       ,iv_name         => cv_msg_name_00255      -- bZ[W
                       ,iv_token_name1  => cv_tkn_line_no         -- g[NR[h1
                       ,iv_token_value1 => TO_CHAR(in_rec_no)     -- g[Nl1
                       ,iv_token_name2  => cv_tkn_proc_type       -- g[NR[h2
                       ,iv_token_value2 => cv_tkn_val_50298       -- g[Nl2
                       ,iv_token_name3  => cv_tkn_input           -- g[NR[h3
                       ,iv_token_value3 => cv_tkn_val_50241       -- g[Nl3
                     );
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_errmsg
        );
        -- G[tOðXV
        gb_err_flag := TRUE;
--
      -- YÔªNULLÈOÌê
      ELSIF ( g_upload_tab(in_rec_no).asset_number IS NOT NULL ) THEN
--
        -- ****************************
        -- YÔd¡`FbN
        -- ****************************
        BEGIN
          SELECT xtcan.asset_number  AS asset_number
          INTO   lv_asset_number
          FROM   xxcff_tmp_check_asset_num xtcan  -- YÔ`FbNê\
          WHERE  xtcan.asset_number =  g_upload_tab(in_rec_no).asset_number
          AND    xtcan.line_no      <> g_upload_tab(in_rec_no).line_no
          AND    ROWNUM             =  cn_1
          ;
          -- YÔd¡G[
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_msg_kbn_cff                           -- AvP[VZk¼
                         ,iv_name         => cv_msg_name_00279                        -- bZ[W
                         ,iv_token_name1  => cv_tkn_line_no                           -- g[NR[h1
                         ,iv_token_value1 => TO_CHAR(in_rec_no)                       -- g[Nl1
                         ,iv_token_name2  => cv_tkn_column_data                       -- g[NR[h2
                         ,iv_token_value2 => g_upload_tab(in_rec_no).asset_number     -- g[Nl2
                       );
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => lv_errmsg
          );
          -- G[tOðXV
          gb_err_flag := TRUE;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            NULL;
        END;
--
        -- ****************************
        -- YÔ`FbN
        -- ****************************
        BEGIN
          SELECT /*+
                   INDEX(fab FA_ADDITIONS_B_U2)
                   INDEX(fb  FA_BOOKS_N1)
                 */
                 fab.asset_number                  AS asset_number_old            -- YÔ
                ,fb.date_placed_in_service         AS dpis_old                    -- Æpú
                ,fab.asset_category_id             AS category_id_old             -- YJeSID
                ,fab.attribute_category_code       AS cat_attribute_category_old  -- YJeSR[h
                ,fat.description                   AS description                 -- Ev
                ,fab.current_units                 AS transaction_units           -- »ÝPÊ
                ,fb.cost                           AS cost                        -- æ¾¿z
                ,fb.original_cost                  AS original_cost               -- æ¾¿z
                ,fab.asset_number                  AS asset_number_new            -- YÔ
                ,fab.tag_number                    AS tag_number                  -- »i[Ô
                ,fab.asset_category_id             AS category_id_new             -- YJeSID
                ,fab.serial_number                 AS serial_number               -- VAÔ
                ,fab.asset_key_ccid                AS asset_key_ccid              -- YL[CCID
                ,fak.segment1                      AS key_segment1                -- YL[ZOg1
                ,fak.segment2                      AS key_segment2                -- YL[ZOg2
                ,fab.parent_asset_id               AS parent_asset_id             -- eYID
                ,fab.lease_id                      AS lease_id                    -- [XID
                ,fab.model_number                  AS model_number                -- f
                ,fab.in_use_flag                   AS in_use_flag                 -- gpóµ
                ,fab.inventorial                   AS inventorial                 -- ÀnIµtO
                ,fab.owned_leased                  AS owned_leased                -- L 
                ,fab.new_used                      AS new_used                    -- Vi/Ã
                ,fab.attribute1                    AS cat_attribute1              -- JeSDFF1
                ,fab.attribute2                    AS cat_attribute2              -- JeSDFF2
                ,fab.attribute3                    AS cat_attribute3              -- JeSDFF3
                ,fab.attribute4                    AS cat_attribute4              -- JeSDFF4
                ,fab.attribute5                    AS cat_attribute5              -- JeSDFF5
                ,fab.attribute6                    AS cat_attribute6              -- JeSDFF6
                ,fab.attribute7                    AS cat_attribute7              -- JeSDFF7
                ,fab.attribute8                    AS cat_attribute8              -- JeSDFF8
                ,fab.attribute9                    AS cat_attribute9              -- JeSDFF9
                ,fab.attribute10                   AS cat_attribute10             -- JeSDFF10
                ,fab.attribute11                   AS cat_attribute11             -- JeSDFF11
                ,fab.attribute12                   AS cat_attribute12             -- JeSDFF12
                ,fab.attribute13                   AS cat_attribute13             -- JeSDFF13
                ,fab.attribute14                   AS cat_attribute14             -- JeSDFF14
                ,fab.attribute15                   AS cat_attribute15             -- JeSDFF15(IFRSÏpN)
                ,fab.attribute16                   AS cat_attribute16             -- JeSDFF16(IFRSp)
                ,fab.attribute17                   AS cat_attribute17             -- JeSDFF17(s®Yæ¾Å)
                ,fab.attribute18                   AS cat_attribute18             -- JeSDFF18(ØüRXg)
                ,fab.attribute19                   AS cat_attribute19             -- JeSDFF19(»Ì¼)
                ,fab.attribute20                   AS cat_attribute20             -- JeSDFF20(IFRSYÈÚ)
                ,fab.attribute21                   AS cat_attribute21             -- JeSDFF21(C³Nú)
                ,fab.attribute22                   AS cat_attribute22             -- JeSDFF22
                ,fab.attribute23                   AS cat_attribute23             -- JeSDFF23
                ,fab.attribute24                   AS cat_attribute24             -- JeSDFF24
                ,fab.attribute25                   AS cat_attribute25             -- JeSDFF27
                ,fab.attribute26                   AS cat_attribute26             -- JeSDFF25
                ,fab.attribute27                   AS cat_attribute27             -- JeSDFF26
                ,fab.attribute28                   AS cat_attribute28             -- JeSDFF28
                ,fab.attribute29                   AS cat_attribute29             -- JeSDFF29
                ,fab.attribute30                   AS cat_attribute30             -- JeSDFF30
                ,fab.attribute_category_code       AS cat_attribute_category_new  -- YJeSR[h
                ,fb.salvage_value                  AS salvage_value               -- c¶¿z
                ,fb.percent_salvage_value          AS percent_salvage_value       -- c¶¿z%
                ,fb.allowed_deprn_limit_amount     AS allowed_deprn_limit_amount  -- pÀxz
                ,fb.allowed_deprn_limit            AS allowed_deprn_limit         -- pÀx¦
                ,fb.depreciate_flag                AS depreciate_flag             -- pïvãtO
                ,fb.deprn_method_code              AS deprn_method_code           -- pû@
                ,fb.basic_rate                     AS basic_rate                  -- Êp¦
                ,fb.adjusted_rate                  AS adjusted_rate               -- ãp¦
                ,fb.life_in_months                 AS life_in_months              -- ÏpN{
                ,fb.bonus_rule                     AS bonus_rule                  -- {[iX[
            INTO g_fa_tab(in_rec_no).asset_number_old            -- YÔiC³Oj
                ,g_fa_tab(in_rec_no).dpis_old                    -- ÆpúiC³Oj
                ,g_fa_tab(in_rec_no).category_id_old             -- YJeSIDiC³Oj
                ,g_fa_tab(in_rec_no).cat_attribute_category_old  -- YJeSR[hiC³Oj
                ,g_fa_tab(in_rec_no).description                 -- EviC³ãj
                ,g_fa_tab(in_rec_no).transaction_units           -- PÊ
                ,g_fa_tab(in_rec_no).cost                        -- æ¾¿z
                ,g_fa_tab(in_rec_no).original_cost               -- æ¾¿z
                ,g_fa_tab(in_rec_no).asset_number_new            -- YÔiC³ãj
                ,g_fa_tab(in_rec_no).tag_number                  -- »i[Ô
                ,g_fa_tab(in_rec_no).category_id_new             -- YJeSIDiC³ãj
                ,g_fa_tab(in_rec_no).serial_number               -- VAÔ
                ,g_fa_tab(in_rec_no).asset_key_ccid              -- YL[CCID
                ,g_fa_tab(in_rec_no).key_segment1                -- YL[ZOg1
                ,g_fa_tab(in_rec_no).key_segment2                -- YL[ZOg2
                ,g_fa_tab(in_rec_no).parent_asset_id             -- eYID
                ,g_fa_tab(in_rec_no).lease_id                    -- [XID
                ,g_fa_tab(in_rec_no).model_number                -- f
                ,g_fa_tab(in_rec_no).in_use_flag                 -- gpóµ
                ,g_fa_tab(in_rec_no).inventorial                 -- ÀnIµtO
                ,g_fa_tab(in_rec_no).owned_leased                -- L 
                ,g_fa_tab(in_rec_no).new_used                    -- Vi/Ã
                ,g_fa_tab(in_rec_no).cat_attribute1              -- JeSDFF1
                ,g_fa_tab(in_rec_no).cat_attribute2              -- JeSDFF2
                ,g_fa_tab(in_rec_no).cat_attribute3              -- JeSDFF3
                ,g_fa_tab(in_rec_no).cat_attribute4              -- JeSDFF4
                ,g_fa_tab(in_rec_no).cat_attribute5              -- JeSDFF5
                ,g_fa_tab(in_rec_no).cat_attribute6              -- JeSDFF6
                ,g_fa_tab(in_rec_no).cat_attribute7              -- JeSDFF7
                ,g_fa_tab(in_rec_no).cat_attribute8              -- JeSDFF8
                ,g_fa_tab(in_rec_no).cat_attribute9              -- JeSDFF9
                ,g_fa_tab(in_rec_no).cat_attribute10             -- JeSDFF10
                ,g_fa_tab(in_rec_no).cat_attribute11             -- JeSDFF11
                ,g_fa_tab(in_rec_no).cat_attribute12             -- JeSDFF12
                ,g_fa_tab(in_rec_no).cat_attribute13             -- JeSDFF13
                ,g_fa_tab(in_rec_no).cat_attribute14             -- JeSDFF14
                ,g_fa_tab(in_rec_no).cat_attribute15             -- JeSDFF15(IFRSÏpN)
                ,g_fa_tab(in_rec_no).cat_attribute16             -- JeSDFF16(IFRSp)
                ,g_fa_tab(in_rec_no).cat_attribute17             -- JeSDFF17(s®Yæ¾Å)
                ,g_fa_tab(in_rec_no).cat_attribute18             -- JeSDFF18(ØüRXg)
                ,g_fa_tab(in_rec_no).cat_attribute19             -- JeSDFF19(»Ì¼)
                ,g_fa_tab(in_rec_no).cat_attribute20             -- JeSDFF20(IFRSYÈÚ)
                ,g_fa_tab(in_rec_no).cat_attribute21             -- JeSDFF21(C³Nú)
                ,g_fa_tab(in_rec_no).cat_attribute22             -- JeSDFF22
                ,g_fa_tab(in_rec_no).cat_attribute23             -- JeSDFF23
                ,g_fa_tab(in_rec_no).cat_attribute24             -- JeSDFF24
                ,g_fa_tab(in_rec_no).cat_attribute25             -- JeSDFF27
                ,g_fa_tab(in_rec_no).cat_attribute26             -- JeSDFF25
                ,g_fa_tab(in_rec_no).cat_attribute27             -- JeSDFF26
                ,g_fa_tab(in_rec_no).cat_attribute28             -- JeSDFF28
                ,g_fa_tab(in_rec_no).cat_attribute29             -- JeSDFF29
                ,g_fa_tab(in_rec_no).cat_attribute30             -- JeSDFF30
                ,g_fa_tab(in_rec_no).cat_attribute_category_new  -- YJeSR[hiC³ãj
                ,g_fa_tab(in_rec_no).salvage_value               -- c¶¿z
                ,g_fa_tab(in_rec_no).percent_salvage_value       -- c¶¿z%
                ,g_fa_tab(in_rec_no).allowed_deprn_limit_amount  -- pÀxz
                ,g_fa_tab(in_rec_no).allowed_deprn_limit         -- pÀx¦
                ,g_fa_tab(in_rec_no).depreciate_flag             -- pïvãtO
                ,g_fa_tab(in_rec_no).deprn_method_code           -- pû@
                ,g_fa_tab(in_rec_no).basic_rate                  -- Êp¦
                ,g_fa_tab(in_rec_no).adjusted_rate               -- ãp¦
                ,g_fa_tab(in_rec_no).life_in_months              -- ÏpN{
                ,g_fa_tab(in_rec_no).bonus_rule                  -- {[iX[
          FROM   fa_additions_b         fab   -- YÚ×îñ
                ,fa_additions_tl        fat   -- YEvîñ
                ,fa_asset_keywords      fak   -- YL[
                ,fa_books               fb    -- Yä îñ
          WHERE  fab.asset_id                 = fb.asset_id
          AND    fat.asset_id                 = fab.asset_id
          AND    fat.language                 = cv_lang_ja
          AND    fab.asset_key_ccid           = fak.code_combination_id(+)
          AND    fab.asset_number             = g_upload_tab(in_rec_no).asset_number
          AND    fb.book_type_code            = gv_fixed_asset_register
          AND    fb.date_ineffective          IS NULL
          ;
--
          -- æªªu 1io^jvÌê
          IF ( g_upload_tab(in_rec_no).process_type = cv_process_type_1 ) THEN
--
            -- o^ÏÝG[
            lv_errmsg := xxccp_common_pkg.get_msg(
                            iv_application  => cv_msg_kbn_cff                           -- AvP[VZk¼
                           ,iv_name         => cv_msg_name_00254                        -- bZ[W
                           ,iv_token_name1  => cv_tkn_line_no                           -- g[NR[h1
                           ,iv_token_value1 => TO_CHAR(in_rec_no)                       -- g[Nl1
                           ,iv_token_name2  => cv_tkn_column_data                       -- g[NR[h2
                           ,iv_token_value2 => g_upload_tab(in_rec_no).asset_number     -- g[Nl2
                         );
            FND_FILE.PUT_LINE(
              which  => FND_FILE.OUTPUT
             ,buff   => lv_errmsg
            );
            -- G[tOðXV
            gb_err_flag := TRUE;
--
          -- æªªu 2iC³jvÌê
          ELSE
--
            -- ****************************
            -- Oñf[^¶Ý`FbN
            -- ****************************
            BEGIN
              SELECT xao.adjustment_oif_id  AS adjustment_oif_id
              INTO   lt_adjustment_oif_id
              FROM   xx01_adjustment_oif  xao   -- C³OIF
              WHERE  xao.book_type_code    = gv_fixed_asset_register
              AND    xao.asset_number_old  = g_fa_tab(in_rec_no).asset_number_old
              ;
              -- Oñf[^¶Ý`FbNG[
              lv_errmsg := xxccp_common_pkg.get_msg(
                              iv_application  => cv_msg_kbn_cff                           -- AvP[VZk¼
                             ,iv_name         => cv_msg_name_00265                        -- bZ[W
                             ,iv_token_name1  => cv_tkn_line_no                           -- g[NR[h1
                             ,iv_token_value1 => TO_CHAR(in_rec_no)                       -- g[Nl1
                             ,iv_token_name2  => cv_tkn_column_data                       -- g[NR[h2
                             ,iv_token_value2 => g_fa_tab(in_rec_no).asset_number_old     -- g[Nl2
                           );
              FND_FILE.PUT_LINE(
                which  => FND_FILE.OUTPUT
               ,buff   => lv_errmsg
              );
              -- G[tOðXV
              gb_err_flag := TRUE;
            EXCEPTION
              WHEN NO_DATA_FOUND THEN
                NULL;
            END;
          END IF;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
--
            -- æªªu 1io^jvÌê
            IF ( g_upload_tab(in_rec_no).process_type = cv_process_type_1 ) THEN
--
              -- ¼YÔ
              ln_tmp_asset_number := TO_NUMBER(g_upload_tab(in_rec_no).asset_number);
--
              BEGIN
                SELECT fsc.initial_asset_id               AS initial_asset_id
                      ,fsc.use_custom_asset_numbers_flag  AS use_custom_asset_numbers_flag
                INTO   lt_initial_asset_id
                      ,lt_use_cust_asset_num_flag
                FROM   fa_system_controls fsc       -- FAVXeRg[
                ;
                -- ****************************
                -- YÔÌÔ`FbN
                -- ****************************
                IF ( ln_tmp_asset_number >= lt_initial_asset_id )
                  AND ( NVL(lt_use_cust_asset_num_flag, cv_no) <> cv_yes ) THEN
                  -- YÔÌÔG[
                  lv_errmsg := xxccp_common_pkg.get_msg(
                                  iv_application  => cv_msg_kbn_cff                           -- AvP[VZk¼
                                 ,iv_name         => cv_msg_name_00264                        -- bZ[W
                                 ,iv_token_name1  => cv_tkn_line_no                           -- g[NR[h1
                                 ,iv_token_value1 => TO_CHAR(in_rec_no)                       -- g[Nl1
                                 ,iv_token_name2  => cv_tkn_column_data                       -- g[NR[h2
                                 ,iv_token_value2 => g_upload_tab(in_rec_no).asset_number     -- g[Nl2
                               );
                  FND_FILE.PUT_LINE(
                    which  => FND_FILE.OUTPUT
                   ,buff   => lv_errmsg
                  );
                  -- G[tOðXV
                  gb_err_flag := TRUE;
                END IF;
              EXCEPTION
                WHEN INVALID_NUMBER OR VALUE_ERROR THEN
                 NULL;
              END;
--
            -- æªªu 2iC³jvÌê
            ELSE
--
              -- ¶Ý`FbNG[
              lv_errmsg := xxccp_common_pkg.get_msg(
                              iv_application  => cv_msg_kbn_cff                           -- AvP[VZk¼
                             ,iv_name         => cv_msg_name_00256                        -- bZ[W
                             ,iv_token_name1  => cv_tkn_line_no                           -- g[NR[h1
                             ,iv_token_value1 => TO_CHAR(in_rec_no)                       -- g[Nl1
                             ,iv_token_name2  => cv_tkn_input                             -- g[NR[h2
                             ,iv_token_value2 => cv_tkn_val_50241                         -- g[Nl2
                             ,iv_token_name3  => cv_tkn_column_data                       -- g[NR[h3
                             ,iv_token_value3 => g_upload_tab(in_rec_no).asset_number     -- g[Nl3
                           );
              FND_FILE.PUT_LINE(
                which  => FND_FILE.OUTPUT
               ,buff   => lv_errmsg
              );
              -- G[tOðXV
              gb_err_flag := TRUE;
            END IF;
        END;
      END IF;
    END IF;
--
    -- æªªu 1io^jvÌê
    IF ( g_upload_tab(in_rec_no).process_type = cv_process_type_1 ) THEN
--
      -- ===============================
      -- Ev
      -- ===============================
      IF ( g_upload_tab(in_rec_no).description IS NULL ) THEN
        -- Ú¢ÝèG[
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_msg_kbn_cff         -- AvP[VZk¼
                       ,iv_name         => cv_msg_name_00255      -- bZ[W
                       ,iv_token_name1  => cv_tkn_line_no         -- g[NR[h1
                       ,iv_token_value1 => TO_CHAR(in_rec_no)     -- g[Nl1
                       ,iv_token_name2  => cv_tkn_proc_type       -- g[NR[h2
                       ,iv_token_value2 => cv_tkn_val_50297       -- g[Nl2
                       ,iv_token_name3  => cv_tkn_input           -- g[NR[h3
                       ,iv_token_value3 => cv_tkn_val_50242       -- g[Nl3
                     );
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_errmsg
        );
        -- G[tOðXV
        gb_err_flag := TRUE;
      END IF;
--
      -- ===============================
      -- íÞ
      -- ===============================
      IF ( g_upload_tab(in_rec_no).asset_category IS NULL ) THEN
        -- Ú¢ÝèG[
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_msg_kbn_cff         -- AvP[VZk¼
                       ,iv_name         => cv_msg_name_00255      -- bZ[W
                       ,iv_token_name1  => cv_tkn_line_no         -- g[NR[h1
                       ,iv_token_value1 => TO_CHAR(in_rec_no)     -- g[Nl1
                       ,iv_token_name2  => cv_tkn_proc_type       -- g[NR[h2
                       ,iv_token_value2 => cv_tkn_val_50297       -- g[Nl2
                       ,iv_token_name3  => cv_tkn_input           -- g[NR[h3
                       ,iv_token_value3 => cv_tkn_val_50072       -- g[Nl3
                     );
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_errmsg
        );
        -- G[tOðXV
        gb_err_flag := TRUE;
      ELSE
        BEGIN
          SELECT xcv.category_code  AS asset_category
          INTO   lt_asset_category
          FROM   xxcff_category_v  xcv   -- YíÞr[
          WHERE  xcv.category_code  = g_upload_tab(in_rec_no).asset_category
          AND    xcv.enabled_flag   = cv_yes
          AND    gd_process_date   >= NVL(xcv.start_date_active ,gd_process_date)
          AND    gd_process_date   <= NVL(xcv.end_date_active ,gd_process_date)
          ;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            -- ¶Ý`FbNG[
            lv_errmsg := xxccp_common_pkg.get_msg(
                            iv_application  => cv_msg_kbn_cff                           -- AvP[VZk¼
                           ,iv_name         => cv_msg_name_00256                        -- bZ[W
                           ,iv_token_name1  => cv_tkn_line_no                           -- g[NR[h1
                           ,iv_token_value1 => TO_CHAR(in_rec_no)                       -- g[Nl1
                           ,iv_token_name2  => cv_tkn_input                             -- g[NR[h2
                           ,iv_token_value2 => cv_tkn_val_50072                         -- g[Nl2
                           ,iv_token_name3  => cv_tkn_column_data                       -- g[NR[h3
                           ,iv_token_value3 => g_upload_tab(in_rec_no).asset_category   -- g[Nl3
                         );
            FND_FILE.PUT_LINE(
              which  => FND_FILE.OUTPUT
             ,buff   => lv_errmsg
            );
            -- G[tOðXV
            gb_err_flag := TRUE;
        END;
      END IF;
--
      -- ===============================
      -- p\
      -- ===============================
      IF ( g_upload_tab(in_rec_no).deprn_declaration IS NULL ) THEN
        -- Ú¢ÝèG[
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_msg_kbn_cff         -- AvP[VZk¼
                       ,iv_name         => cv_msg_name_00255      -- bZ[W
                       ,iv_token_name1  => cv_tkn_line_no         -- g[NR[h1
                       ,iv_token_value1 => TO_CHAR(in_rec_no)     -- g[Nl1
                       ,iv_token_name2  => cv_tkn_proc_type       -- g[NR[h2
                       ,iv_token_value2 => cv_tkn_val_50297       -- g[Nl2
                       ,iv_token_name3  => cv_tkn_input           -- g[NR[h3
                       ,iv_token_value3 => cv_tkn_val_50299       -- g[Nl3
                     );
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_errmsg
        );
        -- G[tOðXV
        gb_err_flag := TRUE;
      ELSE
        << check_deprn_declaration_loop >>
        FOR check_flex_value_rec IN check_flex_value_cur(
                                       cv_ffv_dclr_dprn                            -- XXCFF_DCLR_DPRN
                                      ,g_upload_tab(in_rec_no).deprn_declaration   -- p\
                                    )
        LOOP
          lt_deprn_declaration := check_flex_value_rec.flex_value;
        END LOOP check_deprn_declaration_loop;
        -- æ¾lªNULLÌê
        IF ( lt_deprn_declaration IS NULL ) THEN
          -- ¶Ý`FbNG[
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_msg_kbn_cff                             -- AvP[VZk¼
                         ,iv_name         => cv_msg_name_00256                          -- bZ[W
                         ,iv_token_name1  => cv_tkn_line_no                             -- g[NR[h1
                         ,iv_token_value1 => TO_CHAR(in_rec_no)                         -- g[Nl1
                         ,iv_token_name2  => cv_tkn_input                               -- g[NR[h2
                         ,iv_token_value2 => cv_tkn_val_50299                           -- g[Nl2
                         ,iv_token_name3  => cv_tkn_column_data                         -- g[NR[h3
                         ,iv_token_value3 => g_upload_tab(in_rec_no).deprn_declaration  -- g[Nl3
                       );
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => lv_errmsg
          );
          -- G[tOðXV
          gb_err_flag := TRUE;
        END IF;
      END IF;
--
      -- ===============================
      -- Y¨è
      -- ===============================
      IF ( g_upload_tab(in_rec_no).asset_account IS NULL ) THEN
        -- Ú¢ÝèG[
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_msg_kbn_cff         -- AvP[VZk¼
                       ,iv_name         => cv_msg_name_00255      -- bZ[W
                       ,iv_token_name1  => cv_tkn_line_no         -- g[NR[h1
                       ,iv_token_value1 => TO_CHAR(in_rec_no)     -- g[Nl1
                       ,iv_token_name2  => cv_tkn_proc_type       -- g[NR[h2
                       ,iv_token_value2 => cv_tkn_val_50297       -- g[Nl2
                       ,iv_token_name3  => cv_tkn_input           -- g[NR[h3
                       ,iv_token_value3 => cv_tkn_val_50270       -- g[Nl3
                     );
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_errmsg
        );
        -- G[tOðXV
        gb_err_flag := TRUE;
      ELSE
        << check_asset_account_loop >>
        FOR check_flex_value_rec IN check_flex_value_cur(
                                       cv_ffv_asset_acct                        -- XXCFF_ASSET_ACCOUNT
                                      ,g_upload_tab(in_rec_no).asset_account    -- Y¨è
                                    )
        LOOP
          lt_asset_account := check_flex_value_rec.flex_value;
        END LOOP check_asset_account_loop;
        -- æ¾lªNULLÌê
        IF ( lt_asset_account IS NULL ) THEN
          -- ¶Ý`FbNG[
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_msg_kbn_cff                           -- AvP[VZk¼
                         ,iv_name         => cv_msg_name_00256                        -- bZ[W
                         ,iv_token_name1  => cv_tkn_line_no                           -- g[NR[h1
                         ,iv_token_value1 => TO_CHAR(in_rec_no)                       -- g[Nl1
                         ,iv_token_name2  => cv_tkn_input                             -- g[NR[h2
                         ,iv_token_value2 => cv_tkn_val_50270                         -- g[Nl2
                         ,iv_token_name3  => cv_tkn_column_data                       -- g[NR[h3
                         ,iv_token_value3 => g_upload_tab(in_rec_no).asset_account    -- g[Nl3
                       );
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => lv_errmsg
          );
          -- G[tOðXV
          gb_err_flag := TRUE;
        END IF;
      END IF;
--
      -- ===============================
      -- pÈÚ
      -- ===============================
      IF ( g_upload_tab(in_rec_no).deprn_account IS NULL ) THEN
        -- Ú¢ÝèG[
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_msg_kbn_cff         -- AvP[VZk¼
                       ,iv_name         => cv_msg_name_00255      -- bZ[W
                       ,iv_token_name1  => cv_tkn_line_no         -- g[NR[h1
                       ,iv_token_value1 => TO_CHAR(in_rec_no)     -- g[Nl1
                       ,iv_token_name2  => cv_tkn_proc_type       -- g[NR[h2
                       ,iv_token_value2 => cv_tkn_val_50297       -- g[Nl2
                       ,iv_token_name3  => cv_tkn_input           -- g[NR[h3
                       ,iv_token_value3 => cv_tkn_val_50300       -- g[Nl3
                     );
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_errmsg
        );
        -- G[tOðXV
        gb_err_flag := TRUE;
      ELSE
        << check_deprn_account_loop >>
        FOR check_flex_value_rec IN check_flex_value_cur(
                                       cv_ffv_deprn_acct                       -- XXCFF_DEPRN_ACCOUNT
                                      ,g_upload_tab(in_rec_no).deprn_account   -- pÈÚ
                                    )
        LOOP
          lt_deprn_account := check_flex_value_rec.flex_value;
        END LOOP check_deprn_account_loop;
        -- æ¾lªNULLÌê
        IF ( lt_deprn_account IS NULL ) THEN
          -- ¶Ý`FbNG[
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_msg_kbn_cff                           -- AvP[VZk¼
                         ,iv_name         => cv_msg_name_00256                        -- bZ[W
                         ,iv_token_name1  => cv_tkn_line_no                           -- g[NR[h1
                         ,iv_token_value1 => TO_CHAR(in_rec_no)                       -- g[Nl1
                         ,iv_token_name2  => cv_tkn_input                             -- g[NR[h2
                         ,iv_token_value2 => cv_tkn_val_50300                         -- g[Nl2
                         ,iv_token_name3  => cv_tkn_column_data                       -- g[NR[h3
                         ,iv_token_value3 => g_upload_tab(in_rec_no).deprn_account    -- g[Nl3
                       );
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => lv_errmsg
          );
          -- G[tOðXV
          gb_err_flag := TRUE;
        END IF;
      END IF;
--
      -- ===============================
      -- pâÈÚ
      -- ===============================
      IF ( g_upload_tab(in_rec_no).deprn_sub_account IS NULL ) THEN
        -- Ú¢ÝèG[
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_msg_kbn_cff         -- AvP[VZk¼
                       ,iv_name         => cv_msg_name_00255      -- bZ[W
                       ,iv_token_name1  => cv_tkn_line_no         -- g[NR[h1
                       ,iv_token_value1 => TO_CHAR(in_rec_no)     -- g[Nl1
                       ,iv_token_name2  => cv_tkn_proc_type       -- g[NR[h2
                       ,iv_token_value2 => cv_tkn_val_50297       -- g[Nl2
                       ,iv_token_name3  => cv_tkn_input           -- g[NR[h3
                       ,iv_token_value3 => cv_tkn_val_50302       -- g[Nl3
                     );
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_errmsg
        );
        -- G[tOðXV
        gb_err_flag := TRUE;
--
      -- pâÈÚApÈÚªNULLÈOÌê
      ELSIF ( g_upload_tab(in_rec_no).deprn_sub_account IS NOT NULL )
        AND ( lt_deprn_account IS NOT NULL ) THEN
--
        BEGIN
          SELECT xasav.aff_sub_account_code  AS deprn_sub_account
          INTO   lt_deprn_sub_account
          FROM   xxcff_aff_sub_account_v  xasav   -- âÈÚr[
          WHERE  xasav.aff_sub_account_code = g_upload_tab(in_rec_no).deprn_sub_account
          AND    xasav.aff_account_name     = lt_deprn_account
          AND    xasav.enabled_flag         = cv_yes
          AND    gd_process_date           >= NVL(xasav.start_date_active ,gd_process_date)
          AND    gd_process_date           <= NVL(xasav.end_date_active ,gd_process_date)
          ;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            -- ¶Ý`FbNG[
            lv_errmsg := xxccp_common_pkg.get_msg(
                            iv_application  => cv_msg_kbn_cff                             -- AvP[VZk¼
                           ,iv_name         => cv_msg_name_00256                          -- bZ[W
                           ,iv_token_name1  => cv_tkn_line_no                             -- g[NR[h1
                           ,iv_token_value1 => TO_CHAR(in_rec_no)                         -- g[Nl1
                           ,iv_token_name2  => cv_tkn_input                               -- g[NR[h2
                           ,iv_token_value2 => cv_tkn_val_50302                           -- g[Nl2
                           ,iv_token_name3  => cv_tkn_column_data                         -- g[NR[h3
                           ,iv_token_value3 => g_upload_tab(in_rec_no).deprn_sub_account  -- g[Nl3
                         );
            FND_FILE.PUT_LINE(
              which  => FND_FILE.OUTPUT
             ,buff   => lv_errmsg
            );
            -- G[tOðXV
            gb_err_flag := TRUE;
        END;
--
      -- ãLÈOÌê
      ELSE
        NULL;
      END IF;
--
      -- ===============================
      -- ÏpN
      -- ===============================
      IF ( g_upload_tab(in_rec_no).life_in_months IS NULL ) THEN
        -- Ú¢ÝèG[
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_msg_kbn_cff         -- AvP[VZk¼
                       ,iv_name         => cv_msg_name_00255      -- bZ[W
                       ,iv_token_name1  => cv_tkn_line_no         -- g[NR[h1
                       ,iv_token_value1 => TO_CHAR(in_rec_no)     -- g[Nl1
                       ,iv_token_name2  => cv_tkn_proc_type       -- g[NR[h2
                       ,iv_token_value2 => cv_tkn_val_50297       -- g[Nl2
                       ,iv_token_name3  => cv_tkn_input           -- g[NR[h3
                       ,iv_token_value3 => cv_tkn_val_50307       -- g[Nl3
                     );
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_errmsg
        );
        -- G[tOðXV
        gb_err_flag := TRUE;
--
      -- YíÞAÏpNªNULLÈOÌê
      ELSIF ( lt_asset_category IS NOT NULL )
        AND ( g_upload_tab(in_rec_no).life_in_months IS NOT NULL ) THEN
--
        -- ÏpN`FbN
        xxcff_common1_pkg.chk_life(
          iv_category     => lt_asset_category                        -- 1.YíÞ
         ,iv_life         => g_upload_tab(in_rec_no).life_in_months   -- 2.ÏpN
         ,ov_errbuf       => lv_errbuf
         ,ov_retcode      => lv_retcode
         ,ov_errmsg       => lv_errmsg
        );
        IF ( lv_retcode <> cv_status_normal ) THEN
          -- ÏpNG[
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_msg_kbn_cff                           -- AvP[VZk¼
                         ,iv_name         => cv_msg_name_00257                        -- bZ[W
                         ,iv_token_name1  => cv_tkn_line_no                           -- g[NR[h1
                         ,iv_token_value1 => TO_CHAR(in_rec_no)                       -- g[Nl1
                       );
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => lv_errmsg
          );
          -- G[tOðXV
          gb_err_flag := TRUE;
        END IF;
      END IF;
--
      -- ===============================
      -- pû@
      -- ===============================
      IF ( g_upload_tab(in_rec_no).cat_deprn_method IS NULL ) THEN
        -- Ú¢ÝèG[
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_msg_kbn_cff         -- AvP[VZk¼
                       ,iv_name         => cv_msg_name_00255      -- bZ[W
                       ,iv_token_name1  => cv_tkn_line_no         -- g[NR[h1
                       ,iv_token_value1 => TO_CHAR(in_rec_no)     -- g[Nl1
                       ,iv_token_name2  => cv_tkn_proc_type       -- g[NR[h2
                       ,iv_token_value2 => cv_tkn_val_50297       -- g[Nl2
                       ,iv_token_name3  => cv_tkn_input           -- g[NR[h3
                       ,iv_token_value3 => cv_tkn_val_50097       -- g[Nl3
                     );
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_errmsg
        );
        -- G[tOðXV
        gb_err_flag := TRUE;
      ELSE
        << check_cat_deprn_method_loop >>
        FOR check_flex_value_rec IN check_flex_value_cur(
                                       cv_ffv_dprn_method                        -- XXCFF_DPRN_METHOD
                                      ,g_upload_tab(in_rec_no).cat_deprn_method  -- pû@
                                    )
        LOOP
          lt_cat_deprn_method := check_flex_value_rec.flex_value;
        END LOOP check_cat_deprn_method_loop;
        -- æ¾lªNULLÌê
        IF ( lt_cat_deprn_method IS NULL ) THEN
          -- ¶Ý`FbNG[
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_msg_kbn_cff                            -- AvP[VZk¼
                         ,iv_name         => cv_msg_name_00256                         -- bZ[W
                         ,iv_token_name1  => cv_tkn_line_no                            -- g[NR[h1
                         ,iv_token_value1 => TO_CHAR(in_rec_no)                        -- g[Nl1
                         ,iv_token_name2  => cv_tkn_input                              -- g[NR[h2
                         ,iv_token_value2 => cv_tkn_val_50097                          -- g[Nl2
                         ,iv_token_name3  => cv_tkn_column_data                        -- g[NR[h3
                         ,iv_token_value3 => g_upload_tab(in_rec_no).cat_deprn_method  -- g[Nl3
                       );
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => lv_errmsg
          );
          -- G[tOðXV
          gb_err_flag := TRUE;
        END IF;
      END IF;
--
      -- ===============================
      -- [XíÊ
      -- ===============================
      IF ( g_upload_tab(in_rec_no).lease_class IS NULL ) THEN
        -- Ú¢ÝèG[
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_msg_kbn_cff         -- AvP[VZk¼
                       ,iv_name         => cv_msg_name_00255      -- bZ[W
                       ,iv_token_name1  => cv_tkn_line_no         -- g[NR[h1
                       ,iv_token_value1 => TO_CHAR(in_rec_no)     -- g[Nl1
                       ,iv_token_name2  => cv_tkn_proc_type       -- g[NR[h2
                       ,iv_token_value2 => cv_tkn_val_50297       -- g[Nl2
                       ,iv_token_name3  => cv_tkn_input           -- g[NR[h3
                       ,iv_token_value3 => cv_tkn_val_50017       -- g[Nl3
                     );
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_errmsg
        );
        -- G[tOðXV
        gb_err_flag := TRUE;
      END IF;
--
      -- ===============================
      -- Æpú
      -- ===============================
      IF ( g_upload_tab(in_rec_no).date_placed_in_service IS NULL ) THEN
        -- Ú¢ÝèG[
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_msg_kbn_cff         -- AvP[VZk¼
                       ,iv_name         => cv_msg_name_00255      -- bZ[W
                       ,iv_token_name1  => cv_tkn_line_no         -- g[NR[h1
                       ,iv_token_value1 => TO_CHAR(in_rec_no)     -- g[Nl1
                       ,iv_token_name2  => cv_tkn_proc_type       -- g[NR[h2
                       ,iv_token_value2 => cv_tkn_val_50297       -- g[Nl2
                       ,iv_token_name3  => cv_tkn_input           -- g[NR[h3
                       ,iv_token_value3 => cv_tkn_val_50262       -- g[Nl3
                     );
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_errmsg
        );
        -- G[tOðXV
        gb_err_flag := TRUE;
      ELSE
        -- ********************************
        -- Æpú`FbN
        -- ********************************
        IF ( gt_period_close_date < g_upload_tab(in_rec_no).date_placed_in_service ) THEN
            -- Æpú`FbNG[
            lv_errmsg := xxccp_common_pkg.get_msg(
                            iv_application  => cv_msg_kbn_cff                                  -- AvP[VZk¼
                           ,iv_name         => cv_msg_name_00270                               -- bZ[W
                           ,iv_token_name1  => cv_tkn_line_no                                  -- g[NR[h1
                           ,iv_token_value1 => TO_CHAR(in_rec_no)                              -- g[Nl1
                           ,iv_token_name2  => cv_tkn_close_date                               -- g[NR[h2
                           ,iv_token_value2 => TO_CHAR(gt_period_close_date ,cv_date_fmt_std)  -- g[Nl2
                         );
            FND_FILE.PUT_LINE(
              which  => FND_FILE.OUTPUT
             ,buff   => lv_errmsg
            );
            -- G[tOðXV
            gb_err_flag := TRUE;
        END IF;
      END IF;
--
      -- ===============================
      -- æ¾¿z
      -- ===============================
      IF ( g_upload_tab(in_rec_no).original_cost IS NULL ) THEN
        -- Ú¢ÝèG[
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_msg_kbn_cff         -- AvP[VZk¼
                       ,iv_name         => cv_msg_name_00255      -- bZ[W
                       ,iv_token_name1  => cv_tkn_line_no         -- g[NR[h1
                       ,iv_token_value1 => TO_CHAR(in_rec_no)     -- g[Nl1
                       ,iv_token_name2  => cv_tkn_proc_type       -- g[NR[h2
                       ,iv_token_value2 => cv_tkn_val_50297       -- g[Nl2
                       ,iv_token_name3  => cv_tkn_input           -- g[NR[h3
                       ,iv_token_value3 => cv_tkn_val_50308       -- g[Nl3
                     );
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_errmsg
        );
        -- G[tOðXV
        gb_err_flag := TRUE;
      ELSE
        -- ********************************
        -- «ElG[`FbN
        -- ********************************
        IF ( g_upload_tab(in_rec_no).original_cost < cn_1 ) THEN
            -- «ElG[
            lv_errmsg := xxccp_common_pkg.get_msg(
                            iv_application  => cv_msg_kbn_cff         -- AvP[VZk¼
                           ,iv_name         => cv_msg_name_00271      -- bZ[W
                           ,iv_token_name1  => cv_tkn_line_no         -- g[NR[h1
                           ,iv_token_value1 => TO_CHAR(in_rec_no)     -- g[Nl1
                           ,iv_token_name2  => cv_tkn_input           -- g[NR[h2
                           ,iv_token_value2 => cv_tkn_val_50308       -- g[Nl2
                           ,iv_token_name3  => cv_tkn_min_value       -- g[NR[h3
                           ,iv_token_value3 => cn_1                   -- g[Nl3
                         );
            FND_FILE.PUT_LINE(
              which  => FND_FILE.OUTPUT
             ,buff   => lv_errmsg
            );
            -- G[tOðXV
            gb_err_flag := TRUE;
        END IF;
      END IF;
--
      -- ===============================
      -- PÊÊ
      -- ===============================
      IF ( g_upload_tab(in_rec_no).quantity IS NULL ) THEN
        -- Ú¢ÝèG[
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_msg_kbn_cff         -- AvP[VZk¼
                       ,iv_name         => cv_msg_name_00255      -- bZ[W
                       ,iv_token_name1  => cv_tkn_line_no         -- g[NR[h1
                       ,iv_token_value1 => TO_CHAR(in_rec_no)     -- g[Nl1
                       ,iv_token_name2  => cv_tkn_proc_type       -- g[NR[h2
                       ,iv_token_value2 => cv_tkn_val_50297       -- g[Nl2
                       ,iv_token_name3  => cv_tkn_input           -- g[NR[h3
                       ,iv_token_value3 => cv_tkn_val_50309       -- g[Nl3
                     );
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_errmsg
        );
        -- G[tOðXV
        gb_err_flag := TRUE;
      ELSE
        -- ********************************
        -- «ElG[`FbN
        -- ********************************
        IF ( g_upload_tab(in_rec_no).quantity < cn_1 ) THEN
            -- «ElG[
            lv_errmsg := xxccp_common_pkg.get_msg(
                            iv_application  => cv_msg_kbn_cff         -- AvP[VZk¼
                           ,iv_name         => cv_msg_name_00271      -- bZ[W
                           ,iv_token_name1  => cv_tkn_line_no         -- g[NR[h1
                           ,iv_token_value1 => TO_CHAR(in_rec_no)     -- g[Nl1
                           ,iv_token_name2  => cv_tkn_input           -- g[NR[h2
                           ,iv_token_value2 => cv_tkn_val_50309       -- g[Nl2
                           ,iv_token_name3  => cv_tkn_min_value       -- g[NR[h3
                           ,iv_token_value3 => cn_1                   -- g[Nl3
                         );
            FND_FILE.PUT_LINE(
              which  => FND_FILE.OUTPUT
             ,buff   => lv_errmsg
            );
            -- G[tOðXV
            gb_err_flag := TRUE;
        END IF;
      END IF;
--
      -- ===============================
      -- ïÐ
      -- ===============================
      IF ( g_upload_tab(in_rec_no).company_code IS NULL ) THEN
        -- Ú¢ÝèG[
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_msg_kbn_cff         -- AvP[VZk¼
                       ,iv_name         => cv_msg_name_00255      -- bZ[W
                       ,iv_token_name1  => cv_tkn_line_no         -- g[NR[h1
                       ,iv_token_value1 => TO_CHAR(in_rec_no)     -- g[Nl1
                       ,iv_token_name2  => cv_tkn_proc_type       -- g[NR[h2
                       ,iv_token_value2 => cv_tkn_val_50297       -- g[Nl2
                       ,iv_token_name3  => cv_tkn_input           -- g[NR[h3
                       ,iv_token_value3 => cv_tkn_val_50274       -- g[Nl3
                     );
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_errmsg
        );
        -- G[tOðXV
        gb_err_flag := TRUE;
      ELSE
        BEGIN
          SELECT xacv.aff_company_code  AS company_code
          INTO   lt_company_code
          FROM   xxcff_aff_company_v  xacv   -- ïÐr[
          WHERE  xacv.aff_company_code  = g_upload_tab(in_rec_no).company_code
          AND    xacv.enabled_flag      = cv_yes
          AND    gd_process_date       >= NVL(xacv.start_date_active ,gd_process_date)
          AND    gd_process_date       <= NVL(xacv.end_date_active ,gd_process_date)
          ;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            -- ¶Ý`FbNG[
            lv_errmsg := xxccp_common_pkg.get_msg(
                            iv_application  => cv_msg_kbn_cff                           -- AvP[VZk¼
                           ,iv_name         => cv_msg_name_00256                        -- bZ[W
                           ,iv_token_name1  => cv_tkn_line_no                           -- g[NR[h1
                           ,iv_token_value1 => TO_CHAR(in_rec_no)                       -- g[Nl1
                           ,iv_token_name2  => cv_tkn_input                             -- g[NR[h2
                           ,iv_token_value2 => cv_tkn_val_50274                         -- g[Nl2
                           ,iv_token_name3  => cv_tkn_column_data                       -- g[NR[h3
                           ,iv_token_value3 => g_upload_tab(in_rec_no).company_code     -- g[Nl3
                         );
            FND_FILE.PUT_LINE(
              which  => FND_FILE.OUTPUT
             ,buff   => lv_errmsg
            );
            -- G[tOðXV
            gb_err_flag := TRUE;
        END;
      END IF;
--
      -- ===============================
      -- å
      -- ===============================
      IF ( g_upload_tab(in_rec_no).department_code IS NULL ) THEN
        -- Ú¢ÝèG[
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_msg_kbn_cff         -- AvP[VZk¼
                       ,iv_name         => cv_msg_name_00255      -- bZ[W
                       ,iv_token_name1  => cv_tkn_line_no         -- g[NR[h1
                       ,iv_token_value1 => TO_CHAR(in_rec_no)     -- g[Nl1
                       ,iv_token_name2  => cv_tkn_proc_type       -- g[NR[h2
                       ,iv_token_value2 => cv_tkn_val_50297       -- g[Nl2
                       ,iv_token_name3  => cv_tkn_input           -- g[NR[h3
                       ,iv_token_value3 => cv_tkn_val_50301       -- g[Nl3
                     );
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_errmsg
        );
        -- G[tOðXV
        gb_err_flag := TRUE;
      ELSE
        BEGIN
          SELECT xadv.aff_department_code  AS department_code
          INTO   lt_department_code
          FROM   xxcff_aff_department_v  xadv   -- år[
          WHERE  xadv.aff_department_code  = g_upload_tab(in_rec_no).department_code
          AND    xadv.enabled_flag         = cv_yes
          AND    gd_process_date          >= NVL(xadv.start_date_active ,gd_process_date)
          AND    gd_process_date          <= NVL(xadv.end_date_active ,gd_process_date)
          ;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            -- ¶Ý`FbNG[
            lv_errmsg := xxccp_common_pkg.get_msg(
                            iv_application  => cv_msg_kbn_cff                           -- AvP[VZk¼
                           ,iv_name         => cv_msg_name_00256                        -- bZ[W
                           ,iv_token_name1  => cv_tkn_line_no                           -- g[NR[h1
                           ,iv_token_value1 => TO_CHAR(in_rec_no)                       -- g[Nl1
                           ,iv_token_name2  => cv_tkn_input                             -- g[NR[h2
                           ,iv_token_value2 => cv_tkn_val_50301                         -- g[Nl2
                           ,iv_token_name3  => cv_tkn_column_data                       -- g[NR[h3
                           ,iv_token_value3 => g_upload_tab(in_rec_no).department_code  -- g[Nl3
                         );
            FND_FILE.PUT_LINE(
              which  => FND_FILE.OUTPUT
             ,buff   => lv_errmsg
            );
            -- G[tOðXV
            gb_err_flag := TRUE;
        END;
      END IF;
--
      -- ===============================
      -- \n
      -- ===============================
      IF ( g_upload_tab(in_rec_no).dclr_place IS NULL ) THEN
        -- Ú¢ÝèG[
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_msg_kbn_cff         -- AvP[VZk¼
                       ,iv_name         => cv_msg_name_00255      -- bZ[W
                       ,iv_token_name1  => cv_tkn_line_no         -- g[NR[h1
                       ,iv_token_value1 => TO_CHAR(in_rec_no)     -- g[Nl1
                       ,iv_token_name2  => cv_tkn_proc_type       -- g[NR[h2
                       ,iv_token_value2 => cv_tkn_val_50297       -- g[Nl2
                       ,iv_token_name3  => cv_tkn_input           -- g[NR[h3
                       ,iv_token_value3 => cv_tkn_val_50246       -- g[Nl3
                     );
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_errmsg
        );
        -- G[tOðXV
        gb_err_flag := TRUE;
      ELSE
        << check_dclr_place_loop >>
        FOR check_flex_value_rec IN check_flex_value_cur(
                                       cv_ffv_dclr_place                        -- XXCFF_DCLR_PLACE
                                      ,g_upload_tab(in_rec_no).dclr_place       -- \n
                                    )
        LOOP
          lt_dclr_place := check_flex_value_rec.flex_value;
        END LOOP check_dclr_place_loop;
        -- æ¾lªNULLÌê
        IF ( lt_dclr_place IS NULL ) THEN
          -- ¶Ý`FbNG[
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_msg_kbn_cff                           -- AvP[VZk¼
                         ,iv_name         => cv_msg_name_00256                        -- bZ[W
                         ,iv_token_name1  => cv_tkn_line_no                           -- g[NR[h1
                         ,iv_token_value1 => TO_CHAR(in_rec_no)                       -- g[Nl1
                         ,iv_token_name2  => cv_tkn_input                             -- g[NR[h2
                         ,iv_token_value2 => cv_tkn_val_50246                         -- g[Nl2
                         ,iv_token_name3  => cv_tkn_column_data                       -- g[NR[h3
                         ,iv_token_value3 => g_upload_tab(in_rec_no).dclr_place       -- g[Nl3
                       );
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => lv_errmsg
          );
          -- G[tOðXV
          gb_err_flag := TRUE;
        END IF;
      END IF;
--
      -- ===============================
      -- Æ
      -- ===============================
      IF ( g_upload_tab(in_rec_no).location_name IS NULL ) THEN
        -- Ú¢ÝèG[
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_msg_kbn_cff         -- AvP[VZk¼
                       ,iv_name         => cv_msg_name_00255      -- bZ[W
                       ,iv_token_name1  => cv_tkn_line_no         -- g[NR[h1
                       ,iv_token_value1 => TO_CHAR(in_rec_no)     -- g[Nl1
                       ,iv_token_name2  => cv_tkn_proc_type       -- g[NR[h2
                       ,iv_token_value2 => cv_tkn_val_50297       -- g[Nl2
                       ,iv_token_name3  => cv_tkn_input           -- g[NR[h3
                       ,iv_token_value3 => cv_tkn_val_50265       -- g[Nl3
                     );
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_errmsg
        );
        -- G[tOðXV
        gb_err_flag := TRUE;
      ELSE
        << check_dclr_place_loop >>
        FOR check_flex_value_rec IN check_flex_value_cur(
                                       cv_ffv_mng_place                         -- XXCFF_MNG_PLACE
                                      ,g_upload_tab(in_rec_no).location_name    -- Æ
                                    )
        LOOP
          lt_location_name := check_flex_value_rec.flex_value;
        END LOOP check_dclr_place_loop;
        -- æ¾lªNULLÌê
        IF ( lt_location_name IS NULL ) THEN
          -- ¶Ý`FbNG[
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_msg_kbn_cff                           -- AvP[VZk¼
                         ,iv_name         => cv_msg_name_00256                        -- bZ[W
                         ,iv_token_name1  => cv_tkn_line_no                           -- g[NR[h1
                         ,iv_token_value1 => TO_CHAR(in_rec_no)                       -- g[Nl1
                         ,iv_token_name2  => cv_tkn_input                             -- g[NR[h2
                         ,iv_token_value2 => cv_tkn_val_50265                         -- g[Nl2
                         ,iv_token_name3  => cv_tkn_column_data                       -- g[NR[h3
                         ,iv_token_value3 => g_upload_tab(in_rec_no).location_name    -- g[Nl3
                       );
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => lv_errmsg
          );
          -- G[tOðXV
          gb_err_flag := TRUE;
        END IF;
      END IF;
--
      -- ===============================
      -- ê
      -- ===============================
      IF ( g_upload_tab(in_rec_no).location_place IS NULL ) THEN
        -- Ú¢ÝèG[
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_msg_kbn_cff         -- AvP[VZk¼
                       ,iv_name         => cv_msg_name_00255      -- bZ[W
                       ,iv_token_name1  => cv_tkn_line_no         -- g[NR[h1
                       ,iv_token_value1 => TO_CHAR(in_rec_no)     -- g[Nl1
                       ,iv_token_name2  => cv_tkn_proc_type       -- g[NR[h2
                       ,iv_token_value2 => cv_tkn_val_50297       -- g[Nl2
                       ,iv_token_name3  => cv_tkn_input           -- g[NR[h3
                       ,iv_token_value3 => cv_tkn_val_50266       -- g[Nl3
                     );
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_errmsg
        );
        -- G[tOðXV
        gb_err_flag := TRUE;
      END IF;
--
      -- ===============================
      -- \õ1
      -- ===============================
      IF ( g_upload_tab(in_rec_no).yobi1 IS NOT NULL ) THEN
        BEGIN
          SELECT xcapv.aff_project_code  AS yobi1
          INTO   lt_yobi1
          FROM   xxcff_aff_project_v  xcapv   -- \õPr[
          WHERE  xcapv.aff_project_code  = g_upload_tab(in_rec_no).yobi1
          AND    xcapv.enabled_flag      = cv_yes
          AND    gd_process_date        >= NVL(xcapv.start_date_active ,gd_process_date)
          AND    gd_process_date        <= NVL(xcapv.end_date_active ,gd_process_date)
          ;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            -- ¶Ý`FbNG[
            lv_errmsg := xxccp_common_pkg.get_msg(
                            iv_application  => cv_msg_kbn_cff                           -- AvP[VZk¼
                           ,iv_name         => cv_msg_name_00256                        -- bZ[W
                           ,iv_token_name1  => cv_tkn_line_no                           -- g[NR[h1
                           ,iv_token_value1 => TO_CHAR(in_rec_no)                       -- g[Nl1
                           ,iv_token_name2  => cv_tkn_input                             -- g[NR[h2
                           ,iv_token_value2 => cv_tkn_val_50311                         -- g[Nl2
                           ,iv_token_name3  => cv_tkn_column_data                       -- g[NR[h3
                           ,iv_token_value3 => g_upload_tab(in_rec_no).yobi1            -- g[Nl3
                         );
            FND_FILE.PUT_LINE(
              which  => FND_FILE.OUTPUT
             ,buff   => lv_errmsg
            );
            -- G[tOðXV
            gb_err_flag := TRUE;
        END;
      END IF;
--
      -- ===============================
      -- \õ2
      -- ===============================
      IF ( g_upload_tab(in_rec_no).yobi2 IS NOT NULL ) THEN
        BEGIN
          SELECT xafv.aff_future_code  AS yobi2
          INTO   lt_yobi2
          FROM   xxcff_aff_future_v  xafv   -- \õQr[
          WHERE  xafv.aff_future_code   = g_upload_tab(in_rec_no).yobi2
          AND    xafv.enabled_flag      = cv_yes
          AND    gd_process_date       >= NVL(xafv.start_date_active ,gd_process_date)
          AND    gd_process_date       <= NVL(xafv.end_date_active ,gd_process_date)
          ;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            -- ¶Ý`FbNG[
            lv_errmsg := xxccp_common_pkg.get_msg(
                            iv_application  => cv_msg_kbn_cff                           -- AvP[VZk¼
                           ,iv_name         => cv_msg_name_00256                        -- bZ[W
                           ,iv_token_name1  => cv_tkn_line_no                           -- g[NR[h1
                           ,iv_token_value1 => TO_CHAR(in_rec_no)                       -- g[Nl1
                           ,iv_token_name2  => cv_tkn_input                             -- g[NR[h2
                           ,iv_token_value2 => cv_tkn_val_50312                         -- g[Nl2
                           ,iv_token_name3  => cv_tkn_column_data                       -- g[NR[h3
                           ,iv_token_value3 => g_upload_tab(in_rec_no).yobi2            -- g[Nl3
                         );
            FND_FILE.PUT_LINE(
              which  => FND_FILE.OUTPUT
             ,buff   => lv_errmsg
            );
            -- G[tOðXV
            gb_err_flag := TRUE;
        END;
      END IF;
--
      -- ===============================
      -- æ¾ú
      -- ===============================
      IF ( g_upload_tab(in_rec_no).assets_date IS NULL ) THEN
        -- Ú¢ÝèG[
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_msg_kbn_cff         -- AvP[VZk¼
                       ,iv_name         => cv_msg_name_00255      -- bZ[W
                       ,iv_token_name1  => cv_tkn_line_no         -- g[NR[h1
                       ,iv_token_value1 => TO_CHAR(in_rec_no)     -- g[Nl1
                       ,iv_token_name2  => cv_tkn_proc_type       -- g[NR[h2
                       ,iv_token_value2 => cv_tkn_val_50297       -- g[Nl2
                       ,iv_token_name3  => cv_tkn_input           -- g[NR[h3
                       ,iv_token_value3 => cv_tkn_val_50310       -- g[Nl3
                     );
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_errmsg
        );
        -- G[tOðXV
        gb_err_flag := TRUE;
      END IF;
--
    END IF;
--
    -- æªªu 1io^jvu 2iC³jvÌê
    IF ( g_upload_tab(in_rec_no).process_type IN ( cv_process_type_1 ,cv_process_type_2 ) ) THEN
--
      -- ===============================
      -- IFRSæ¾¿z
      -- ===============================
      -- æªªu 1io^jvÌê
      IF ( g_upload_tab(in_rec_no).process_type = cv_process_type_1 ) THEN
        -- IFRSæ¾¿zÌZo
        ln_ifrs_org_cost := NVL(g_upload_tab(in_rec_no).original_cost ,cn_0)         -- æ¾¿z
                          + NVL(g_upload_tab(in_rec_no).real_estate_acq_tax ,cn_0)   -- s®Yæ¾Å
                          + NVL(g_upload_tab(in_rec_no).borrowing_cost ,cn_0)        -- ØüRXg
                          + NVL(g_upload_tab(in_rec_no).other_cost ,cn_0)            -- »Ì¼
                         ;
--
      -- æªªãLÈOÌê
      ELSE
--
        -- IFRSæ¾¿zÌZo
        ln_ifrs_org_cost := g_fa_tab(in_rec_no).cost                                 -- æ¾¿z
                          + CASE WHEN g_upload_tab(in_rec_no).real_estate_acq_tax IS NOT NULL THEN
                              g_upload_tab(in_rec_no).real_estate_acq_tax
                            ELSE
                              NVL(g_fa_tab(in_rec_no).cat_attribute17 ,cn_0)
                            END                                                      -- s®Yæ¾Å
                          + CASE WHEN g_upload_tab(in_rec_no).borrowing_cost IS NOT NULL THEN
                              g_upload_tab(in_rec_no).borrowing_cost
                            ELSE
                              NVL(g_fa_tab(in_rec_no).cat_attribute18 ,cn_0)
                            END                                                      -- ØüRXg
                          + CASE WHEN g_upload_tab(in_rec_no).other_cost IS NOT NULL THEN
                              g_upload_tab(in_rec_no).other_cost
                            ELSE
                              NVL(g_fa_tab(in_rec_no).cat_attribute19 ,cn_0)
                            END                                                      -- »Ì¼
                         ;
--
      END IF;
--
      -- ********************************
      -- «ElG[`FbN
      -- ********************************
      IF ( ln_ifrs_org_cost < cn_1 ) THEN
          -- «ElG[
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_msg_kbn_cff         -- AvP[VZk¼
                         ,iv_name         => cv_msg_name_00271      -- bZ[W
                         ,iv_token_name1  => cv_tkn_line_no         -- g[NR[h1
                         ,iv_token_value1 => TO_CHAR(in_rec_no)     -- g[Nl1
                         ,iv_token_name2  => cv_tkn_input           -- g[NR[h2
                         ,iv_token_value2 => cv_tkn_val_50321       -- g[Nl2
                         ,iv_token_name3  => cv_tkn_min_value       -- g[NR[h3
                         ,iv_token_value3 => cn_1                   -- g[Nl3
                       );
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => lv_errmsg
          );
          -- G[tOðXV
          gb_err_flag := TRUE;
      END IF;
--
      -- ===============================
      -- IFRSp
      -- ===============================
      IF ( g_upload_tab(in_rec_no).ifrs_cat_deprn_method IS NOT NULL ) THEN
        << check_ifrs_cat_dep_metd_loop >>
        FOR check_flex_value_rec IN check_flex_value_cur(
                                       cv_ffv_dprn_method                             -- XXCFF_DPRN_METHOD
                                      ,g_upload_tab(in_rec_no).ifrs_cat_deprn_method  -- IFRSp
                                    )
        LOOP
          lt_ifrs_cat_deprn_method := check_flex_value_rec.flex_value;
        END LOOP check_ifrs_cat_dep_metd_loop;
        -- æ¾lªNULLÌê
        IF ( lt_ifrs_cat_deprn_method IS NULL ) THEN
          -- ¶Ý`FbNG[
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_msg_kbn_cff                                 -- AvP[VZk¼
                         ,iv_name         => cv_msg_name_00256                              -- bZ[W
                         ,iv_token_name1  => cv_tkn_line_no                                 -- g[NR[h1
                         ,iv_token_value1 => TO_CHAR(in_rec_no)                             -- g[Nl1
                         ,iv_token_name2  => cv_tkn_input                                   -- g[NR[h2
                         ,iv_token_value2 => cv_tkn_val_50317                               -- g[Nl2
                         ,iv_token_name3  => cv_tkn_column_data                             -- g[NR[h3
                         ,iv_token_value3 => g_upload_tab(in_rec_no).ifrs_cat_deprn_method  -- g[Nl3
                       );
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => lv_errmsg
          );
          -- G[tOðXV
          gb_err_flag := TRUE;
        END IF;
      END IF;
--
      -- ===============================
      -- IFRSYÈÚ
      -- ===============================
      IF ( g_upload_tab(in_rec_no).ifrs_asset_account IS NOT NULL ) THEN
        BEGIN
          SELECT xaav.aff_account_code  AS ifrs_asset_account
          INTO   lt_ifrs_asset_account
          FROM   xxcff_aff_account_v  xaav   -- ¨èÈÚr[
          WHERE  xaav.aff_account_code  = g_upload_tab(in_rec_no).ifrs_asset_account
          AND    xaav.enabled_flag      = cv_yes
          AND    gd_process_date       >= NVL(xaav.start_date_active ,gd_process_date)
          AND    gd_process_date       <= NVL(xaav.end_date_active ,gd_process_date)
          ;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            -- ¶Ý`FbNG[
            lv_errmsg := xxccp_common_pkg.get_msg(
                            iv_application  => cv_msg_kbn_cff                              -- AvP[VZk¼
                           ,iv_name         => cv_msg_name_00256                           -- bZ[W
                           ,iv_token_name1  => cv_tkn_line_no                              -- g[NR[h1
                           ,iv_token_value1 => TO_CHAR(in_rec_no)                          -- g[Nl1
                           ,iv_token_name2  => cv_tkn_input                                -- g[NR[h2
                           ,iv_token_value2 => cv_tkn_val_50306                            -- g[Nl2
                           ,iv_token_name3  => cv_tkn_column_data                          -- g[NR[h3
                           ,iv_token_value3 => g_upload_tab(in_rec_no).ifrs_asset_account  -- g[Nl3
                         );
            FND_FILE.PUT_LINE(
              which  => FND_FILE.OUTPUT
             ,buff   => lv_errmsg
            );
            -- G[tOðXV
            gb_err_flag := TRUE;
        END;
      END IF;
    END IF;
--
    -- æªªu 2iC³jvÌê
    IF ( g_upload_tab(in_rec_no).process_type = cv_process_type_2 ) THEN
--
      -- ===============================
      -- C³Nú
      -- ===============================
      IF ( g_upload_tab(in_rec_no).correct_date IS NULL ) THEN
        -- Ú¢ÝèG[
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_msg_kbn_cff         -- AvP[VZk¼
                       ,iv_name         => cv_msg_name_00255      -- bZ[W
                       ,iv_token_name1  => cv_tkn_line_no         -- g[NR[h1
                       ,iv_token_value1 => TO_CHAR(in_rec_no)     -- g[Nl1
                       ,iv_token_name2  => cv_tkn_proc_type       -- g[NR[h2
                       ,iv_token_value2 => cv_tkn_val_50298       -- g[Nl2
                       ,iv_token_name3  => cv_tkn_input           -- g[NR[h3
                       ,iv_token_value3 => cv_tkn_val_50313       -- g[Nl3
                     );
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_errmsg
        );
        -- G[tOðXV
        gb_err_flag := TRUE;
      ELSE
        -- ********************************
        -- C³Nú`FbN
        -- ********************************
        IF ( gt_period_open_date > g_upload_tab(in_rec_no).correct_date ) THEN
            -- C³Nú`FbNG[
            lv_errmsg := xxccp_common_pkg.get_msg(
                            iv_application  => cv_msg_kbn_cff                                 -- AvP[VZk¼
                           ,iv_name         => cv_msg_name_00261                              -- bZ[W
                           ,iv_token_name1  => cv_tkn_line_no                                 -- g[NR[h1
                           ,iv_token_value1 => TO_CHAR(in_rec_no)                             -- g[Nl1
                           ,iv_token_name2  => cv_tkn_open_date                               -- g[NR[h2
                           ,iv_token_value2 => TO_CHAR(gt_period_open_date ,cv_date_fmt_std)  -- g[Nl2
                         );
            FND_FILE.PUT_LINE(
              which  => FND_FILE.OUTPUT
             ,buff   => lv_errmsg
            );
            -- G[tOðXV
            gb_err_flag := TRUE;
        END IF;
      END IF;
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
      IF ( check_flex_value_cur%ISOPEN ) THEN
        CLOSE check_flex_value_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  Åè END   ##########################################
--
  END data_validation;
--
  /**********************************************************************************
   * Procedure Name   : insert_add_oif
   * Description      : ÇÁOIFo^(A-9)
   ***********************************************************************************/
  PROCEDURE insert_add_oif(
    in_rec_no     IN  NUMBER        --   ÎÛR[hÔ
   ,ov_errbuf     OUT VARCHAR2      --   G[EbZ[W           --# Åè #
   ,ov_retcode    OUT VARCHAR2      --   ^[ER[h             --# Åè #
   ,ov_errmsg     OUT VARCHAR2      --   [U[EG[EbZ[W --# Åè #
  )
  IS
    -- ===============================
    -- Åè[Jè
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'insert_add_oif'; -- vO¼
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
    cn_segment_cnt            CONSTANT NUMBER        := 8;              -- ZOg
    cv_posting_status         CONSTANT VARCHAR2(4)   := 'POST';         -- ]LXe[^X
    cv_queue_name             CONSTANT VARCHAR2(4)   := 'POST';         -- L[¼
    cv_depreciate_flag        CONSTANT VARCHAR2(3)   := 'YES';          -- pïvãtO
    cv_asset_type             CONSTANT VARCHAR2(11)  := 'CAPITALIZED';  -- Y^Cv
    cv_dummy                  CONSTANT VARCHAR2(5)   := 'DUMMY';        -- _~[
--
    -- *** [JÏ ***
    lb_ret                    BOOLEAN;                                         -- Ö^[ER[h
    lt_asset_category_id      gl_code_combinations.code_combination_id%TYPE;   -- YJeSCCID
    lt_exp_code_comb_id       gl_code_combinations.code_combination_id%TYPE;   -- ¸¿pï¨èCCID
    lt_location_id            gl_code_combinations.code_combination_id%TYPE;   -- ÆCCID
    lt_asset_key_ccid         fa_asset_keywords.code_combination_id%TYPE;      -- YL[CCID
    lt_deprn_method           fa_category_book_defaults.deprn_method%TYPE;     -- pû@
    lt_life_in_months         fa_category_book_defaults.life_in_months%TYPE;   -- vZ
    lt_basic_rate             fa_category_book_defaults.basic_rate%TYPE;       -- Êp¦
    lt_adjusted_rate          fa_category_book_defaults.adjusted_rate%TYPE;    -- ãp¦
    lv_segment5               VARCHAR2(100);                                   -- {ÐHêæª
--
    lt_ifrs_life_in_months    fa_mass_additions.attribute15%TYPE;              -- IFRSÏpN
    lt_ifrs_cat_deprn_method  fa_mass_additions.attribute16%TYPE;              -- IFRSp
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
    -- ***************************************
    -- ***        ÀÌLq             ***
    -- ***       ¤ÊÖÌÄÑoµ        ***
    -- ***************************************
--
    -- [JÏÌú»
    lb_ret                     := FALSE;   -- Ö^[ER[h
    lt_asset_category_id       := NULL;    -- YJeSCCID
    lt_exp_code_comb_id        := NULL;    -- ¸¿pï¨èCCID
    lt_location_id             := NULL;    -- ÆCCID
    lt_asset_key_ccid          := NULL;    -- YL[CCID
    lt_deprn_method            := NULL;    -- pû@
    lt_life_in_months          := NULL;    -- vZ
    lt_basic_rate              := NULL;    -- Êp¦
    lt_adjusted_rate           := NULL;    -- ãp¦
    lv_segment5                := NULL;    -- {ÐHêæª
    lt_ifrs_life_in_months     := NULL;    -- IFRSÏpN
    lt_ifrs_cat_deprn_method   := NULL;    -- IFRSp
--
    -- æªªu 1io^jvÌê
    IF ( g_upload_tab(in_rec_no).process_type = cv_process_type_1 ) THEN
--
      -- ===============================
      -- YJeSCCIDæ¾
      -- ===============================
      -- YJeS`FbN
      xxcff_common1_pkg.chk_fa_category(
        iv_segment1    => g_upload_tab(in_rec_no).asset_category      -- íÞ
       ,iv_segment2    => g_upload_tab(in_rec_no).deprn_declaration   -- p\
       ,iv_segment3    => g_upload_tab(in_rec_no).asset_account       -- Y¨è
       ,iv_segment4    => g_upload_tab(in_rec_no).deprn_account       -- pÈÚ
       ,iv_segment5    => g_upload_tab(in_rec_no).life_in_months      -- ÏpN
       ,iv_segment6    => g_upload_tab(in_rec_no).cat_deprn_method    -- pû@
       ,iv_segment7    => g_upload_tab(in_rec_no).lease_class         -- [XíÊ
       ,on_category_id => lt_asset_category_id                        -- YJeSCCID
       ,ov_errbuf      => lv_errbuf 
       ,ov_retcode     => lv_retcode
       ,ov_errmsg      => lv_errmsg
      );
      IF ( lv_retcode <> cv_status_normal ) THEN
        -- ¤ÊÖG[
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_msg_kbn_cff         -- AvP[VZk¼
                       ,iv_name         => cv_msg_name_00258      -- bZ[W
                       ,iv_token_name1  => cv_tkn_line_no         -- g[NR[h1
                       ,iv_token_value1 => TO_CHAR(in_rec_no)     -- g[Nl1
                       ,iv_token_name2  => cv_tkn_func_name       -- g[NR[h2
                       ,iv_token_value2 => cv_tkn_val_50303       -- g[Nl2
                       ,iv_token_name3  => cv_tkn_info            -- g[NR[h3
                       ,iv_token_value3 => lv_errmsg              -- g[Nl3
                     );
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_errmsg
        );
        -- G[tOðXV
        gb_err_flag := TRUE;
      END IF;
--
      -- ===============================
      -- YJeSîñæ¾
      -- ===============================
      IF ( lt_asset_category_id IS NOT NULL ) THEN
        BEGIN
          SELECT fcbd.deprn_method      AS deprn_method     -- pû@
                ,fcbd.life_in_months    AS life_in_months   -- vZ
                ,fcbd.basic_rate        AS basic_rate       -- Êp¦
                ,fcbd.adjusted_rate     AS adjusted_rate    -- ãp¦
          INTO   lt_deprn_method
                ,lt_life_in_months
                ,lt_basic_rate
                ,lt_adjusted_rate
          FROM   fa_categories_b            fcb     -- YJeS}X^
                ,fa_category_book_defaults  fcbd    -- YJeSpî
          WHERE  fcb.category_id       = fcbd.category_id
          AND    fcb.category_id       = lt_asset_category_id  -- YJeSCCID
          AND    fcbd.book_type_code   = gv_fixed_asset_register
          AND    gd_process_date      >= fcbd.start_dpis
          AND    gd_process_date      <= NVL(fcbd.end_dpis ,gd_process_date)
          ;
        EXCEPTION
          -- YJeSªæ¾Å«È¢ê
          WHEN NO_DATA_FOUND THEN
            lv_errmsg := xxccp_common_pkg.get_msg(
                            iv_application  => cv_msg_kbn_cff           -- AvP[VZk¼
                           ,iv_name         => cv_msg_name_00259        -- bZ[W
                           ,iv_token_name1  => cv_tkn_line_no           -- g[NR[h1
                           ,iv_token_value1 => TO_CHAR(in_rec_no)       -- g[Nl1
                           ,iv_token_name2  => cv_tkn_param_name        -- g[NR[h2
                           ,iv_token_value2 => gv_fixed_asset_register  -- g[Nl2
                         );
            FND_FILE.PUT_LINE(
              which  => FND_FILE.OUTPUT
             ,buff   => lv_errmsg
            );
            -- G[tOðXV
            gb_err_flag := TRUE;
        END;
      END IF;
--
      -- ===============================
      -- ¸¿pï¨èCCIDæ¾
      -- ===============================
      -- ZOglzñú»
      g_segments_tab.DELETE;
      -- ZOglzñÝè(SEG1:ïÐ)
      g_segments_tab(1) := g_upload_tab(in_rec_no).company_code;
      -- ZOglzñÝè(SEG2:åR[h)
      g_segments_tab(2) := g_upload_tab(in_rec_no).department_code;
      -- ZOglzñÝè(SEG3:pÈÚ)
      g_segments_tab(3) := g_upload_tab(in_rec_no).deprn_account;
      -- ZOglzñÝè(SEG4:âÈÚ)
      g_segments_tab(4) := g_upload_tab(in_rec_no).deprn_sub_account;
      -- ZOglzñÝè(SEG5:ÚqR[h)
      g_segments_tab(5) := cv_segment5_dummy;
      -- ZOglzñÝè(SEG6:éÆR[h)
      g_segments_tab(6) := cv_segment6_dummy;
      -- ZOglzñÝè(SEG7:\õP)
      g_segments_tab(7) := cv_segment7_dummy;
      -- ZOglzñÝè(SEG8:\õQ)
      g_segments_tab(8) := cv_segment8_dummy;
--
      -- CCIDæ¾ÖÄÑoµ
      lb_ret := fnd_flex_ext.get_combination_id(
                   application_short_name  => gt_application_short_name       -- AvP[VZk¼(GL)
                  ,key_flex_code           => gt_id_flex_code                 -- L[tbNXR[h
                  ,structure_number        => gt_chart_of_account_id          -- ¨èÈÚÌnÔ
                  ,validation_date         => gd_process_date                 -- út`FbN
                  ,n_segments              => cn_segment_cnt                  -- ZOg
                  ,segments                => g_segments_tab                  -- ZOglzñ
                  ,combination_id          => lt_exp_code_comb_id             -- ¸¿pï¨èCCID
                );
      IF NOT lb_ret THEN
        lv_errmsg := fnd_flex_ext.get_message;
        -- ¤ÊÖG[
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_msg_kbn_cff         -- AvP[VZk¼
                       ,iv_name         => cv_msg_name_00258      -- bZ[W
                       ,iv_token_name1  => cv_tkn_line_no         -- g[NR[h1
                       ,iv_token_value1 => TO_CHAR(in_rec_no)     -- g[Nl1
                       ,iv_token_name2  => cv_tkn_func_name       -- g[NR[h2
                       ,iv_token_value2 => cv_tkn_val_50304       -- g[Nl2
                       ,iv_token_name3  => cv_tkn_info            -- g[NR[h3
                       ,iv_token_value3 => lv_errmsg              -- g[Nl3
                     );
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_errmsg
        );
        -- G[tOðXV
        gb_err_flag := TRUE;
      END IF;
--
      -- ===============================
      -- ÆCCIDæ¾
      -- ===============================
-- Ver1.1 Mod Start
--      -- {ÐHêæªÌ»è
--      IF ( g_upload_tab(in_rec_no).company_code = gv_company_cd_itoen ) THEN
--        -- {ÐHêæª_{Ð
--        lv_segment5 := gv_own_comp_itoen;
--      ELSE
--        -- {ÐHêæª_Hê
--        lv_segment5 := gv_own_comp_sagara;
--      END IF;
      -- {ÐHêæª
      BEGIN
        SELECT flvv.description AS segment5                   --ïÐ¼
        INTO   lv_segment5
        FROM   fnd_lookup_values_vl flvv
        WHERE  flvv.lookup_type   = cv_flvv_own_comp_cd
        AND    flvv.lookup_code   = g_upload_tab(in_rec_no).company_code
        AND    flvv.enabled_flag  = cv_yes
        AND    gd_process_date   >= NVL(flvv.start_date_active ,gd_process_date)
        AND    gd_process_date   <= NVL(flvv.end_date_active ,gd_process_date)
        ;
      EXCEPTION
        WHEN OTHERS THEN
        -- QÆ^CvER[hªæ¾Å«È¢ê
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  =>cv_msg_kbn_cff
                         ,iv_name         => cv_msg_name_00189
                         ,iv_token_name1  => cv_tkn_lookup_type
                         ,iv_token_value1 => cv_tkn_val_50331
                       );
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
      END;
-- Ver1.1 Mod End
--
      -- Æ}X^`FbN
      xxcff_common1_pkg.chk_fa_location(
         iv_segment1      => g_upload_tab(in_rec_no).dclr_place        -- \n
        ,iv_segment2      => g_upload_tab(in_rec_no).department_code   -- å
        ,iv_segment3      => g_upload_tab(in_rec_no).location_name     -- Æ
        ,iv_segment4      => g_upload_tab(in_rec_no).location_place    -- ê
        ,iv_segment5      => lv_segment5                               -- {ÐHêæª
        ,on_location_id   => lt_location_id                            -- ÆCCID
        ,ov_errbuf        => lv_errbuf                                 -- G[EbZ[W           --# Åè # 
        ,ov_retcode       => lv_retcode                                -- ^[ER[h             --# Åè #
        ,ov_errmsg        => lv_errmsg                                 -- [U[EG[EbZ[W --# Åè #
      );
      IF ( lv_retcode <> cv_status_normal ) THEN
        -- ¤ÊÖG[
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_msg_kbn_cff         -- AvP[VZk¼
                       ,iv_name         => cv_msg_name_00258      -- bZ[W
                       ,iv_token_name1  => cv_tkn_line_no         -- g[NR[h1
                       ,iv_token_value1 => TO_CHAR(in_rec_no)     -- g[Nl1
                       ,iv_token_name2  => cv_tkn_func_name       -- g[NR[h2
                       ,iv_token_value2 => cv_tkn_val_50141       -- g[Nl2
                       ,iv_token_name3  => cv_tkn_info            -- g[NR[h3
                       ,iv_token_value3 => lv_errmsg              -- g[Nl3
                     );
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_errmsg
        );
        -- G[tOðXV
        gb_err_flag := TRUE;
      END IF;
--
      -- ===============================
      -- YL[CCIDæ¾
      -- ===============================
      BEGIN
        SELECT fak.code_combination_id   AS asset_key_ccid     -- YL[CCID
        INTO   lt_asset_key_ccid
        FROM   fa_asset_keywords  fak       -- YL[
        WHERE  NVL(fak.segment1 ,cv_dummy)  = NVL(g_upload_tab(in_rec_no).yobi1 ,cv_dummy)
        AND    NVL(fak.segment2 ,cv_dummy)  = NVL(g_upload_tab(in_rec_no).yobi2 ,cv_dummy)
        AND    fak.enabled_flag             = cv_yes
        AND    gd_process_date             >= NVL(fak.start_date_active ,gd_process_date)
        AND    gd_process_date             <= NVL(fak.end_date_active ,gd_process_date)
        ;
      EXCEPTION
        -- YL[CCIDªæ¾Å«È¢ê
        WHEN NO_DATA_FOUND THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_msg_kbn_cff           -- AvP[VZk¼
                         ,iv_name         => cv_msg_name_00260        -- bZ[W
                         ,iv_token_name1  => cv_tkn_line_no           -- g[NR[h1
                         ,iv_token_value1 => TO_CHAR(in_rec_no)       -- g[Nl1
                       );
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => lv_errmsg
          );
          -- G[tOðXV
          gb_err_flag := TRUE;
      END;
--
      -- G[ªÈ¯êÎp±
      IF ( gb_err_flag ) THEN
        NULL;
      ELSE
--
        -- ===============================
        -- IFRSÏpNAIFRSpZbg
        -- ===============================
        -- IFRSÏpN
        IF ( g_upload_tab(in_rec_no).ifrs_life_in_months IS NOT NULL ) THEN
          -- IFRSÏpNðZbg
          lt_ifrs_life_in_months := g_upload_tab(in_rec_no).ifrs_life_in_months;
        ELSE
          -- ÏpNðZbg
          lt_ifrs_life_in_months := g_upload_tab(in_rec_no).life_in_months;
        END IF;
        -- IFRSp
        IF ( g_upload_tab(in_rec_no).ifrs_cat_deprn_method IS NOT NULL ) THEN
          -- IFRSpðZbg
          lt_ifrs_cat_deprn_method := g_upload_tab(in_rec_no).ifrs_cat_deprn_method;
        ELSE
          -- IFRSpû@(úl)ðZbg
          lt_ifrs_cat_deprn_method := gv_cat_dep_ifrs;
        END IF;
--
        -- ****************************
        -- ÇÁOIFo^
        -- ****************************
        BEGIN
          INSERT INTO fa_mass_additions(
             mass_addition_id                  -- ÇÁOIFàID
            ,asset_number                      -- YÔ
            ,description                       -- Ev
            ,asset_category_id                 -- YJeSCCID
            ,book_type_code                    -- ä 
            ,date_placed_in_service            -- Æpú
            ,fixed_assets_cost                 -- æ¾¿z
            ,payables_units                    -- APÊ
            ,fixed_assets_units                -- YÊ
            ,expense_code_combination_id       -- ¸¿pï¨èCCID
            ,location_id                       -- ÆtbNXtB[hCCID
            ,feeder_system_name                -- VXe¼
            ,last_update_date                  -- ÅIXVú
            ,last_updated_by                   -- ÅIXVÒ
            ,posting_status                    -- ]LXe[^X
            ,queue_name                        -- L[¼
            ,payables_cost                     -- Yæ¾¿z
            ,depreciate_flag                   -- pïvãtO
            ,asset_key_ccid                    -- YL[CCID
            ,asset_type                        -- Y^Cv
            ,deprn_method_code                 -- pû@
            ,life_in_months                    -- vZ
            ,basic_rate                        -- Êp¦
            ,adjusted_rate                     -- ãp¦
            ,attribute2                        -- DFF2(æ¾ú)
            ,attribute15                       -- DFF15(IFRSÏpN)
            ,attribute16                       -- DFF16(IFRSp)
            ,attribute17                       -- DFF17(s®Yæ¾Å)
            ,attribute18                       -- DFF18(ØüRXg)
            ,attribute19                       -- DFF19(»Ì¼)
            ,attribute20                       -- DFF20(IFRSYÈÚ)
            ,created_by                        -- ì¬ÒID
            ,creation_date                     -- ì¬ú
            ,last_update_login                 -- ÅIXVOCID
            ,request_id                        -- vID
          )
          VALUES (
             fa_mass_additions_s.NEXTVAL                                     -- ÇÁOIFàID
            ,g_upload_tab(in_rec_no).asset_number                            -- YÔ
            ,g_upload_tab(in_rec_no).description                             -- Ev
            ,lt_asset_category_id                                            -- YJeSCCID
            ,gv_fixed_asset_register                                         -- ä 
            ,g_upload_tab(in_rec_no).date_placed_in_service                  -- Æpú
            ,g_upload_tab(in_rec_no).original_cost                           -- æ¾¿z
            ,g_upload_tab(in_rec_no).quantity                                -- APÊ
            ,g_upload_tab(in_rec_no).quantity                                -- YÊ
            ,lt_exp_code_comb_id                                             -- ¸¿pï¨èCCID
            ,lt_location_id                                                  -- ÆtbNXtB[hCCID
            ,gv_feed_sys_nm                                                  -- VXe¼_FAAbv[h
            ,cd_last_update_date                                             -- ÅIXVú
            ,cn_last_updated_by                                              -- ÅIXVÒ
            ,cv_posting_status                                               -- ]LXe[^X
            ,cv_queue_name                                                   -- L[¼
            ,g_upload_tab(in_rec_no).original_cost                           -- æ¾¿z
            ,cv_depreciate_flag                                              -- pïvãtO
            ,lt_asset_key_ccid                                               -- YL[CCID
            ,cv_asset_type                                                   -- Y^Cv
            ,lt_deprn_method                                                 -- pû@
            ,lt_life_in_months                                               -- vZ
            ,lt_basic_rate                                                   -- Êp¦
            ,lt_adjusted_rate                                                -- ãp¦
            ,TO_CHAR(g_upload_tab(in_rec_no).assets_date ,cv_date_fmt_std)   -- æ¾ú
            ,lt_ifrs_life_in_months                                          -- IFRSÏpN
            ,lt_ifrs_cat_deprn_method                                        -- IFRSp
            ,g_upload_tab(in_rec_no).real_estate_acq_tax                     -- s®Yæ¾Å
            ,g_upload_tab(in_rec_no).borrowing_cost                          -- ØüRXg
            ,g_upload_tab(in_rec_no).other_cost                              -- »Ì¼
            ,g_upload_tab(in_rec_no).ifrs_asset_account                      -- IFRSYÈÚ
            ,cn_created_by                                                   -- ì¬Ò
            ,cd_creation_date                                                -- ì¬ú
            ,cn_last_update_login                                            -- ÅIXVOC
            ,cn_request_id                                                   -- vID
          );
        EXCEPTION
          WHEN OTHERS THEN
            -- o^G[
            lv_errmsg := xxccp_common_pkg.get_msg(
                            iv_application  => cv_msg_kbn_cff           -- AvP[VZk¼
                           ,iv_name         => cv_msg_name_00102        -- bZ[W
                           ,iv_token_name1  => cv_tkn_table_name        -- g[NR[h1
                           ,iv_token_value1 => cv_tkn_val_50319         -- g[Nl1
                           ,iv_token_name2  => cv_tkn_info              -- g[NR[h2
                           ,iv_token_value2 => SQLERRM                  -- g[Nl2
                         );
            lv_errbuf := lv_errmsg;
            RAISE global_api_expt;
        END;
--
        -- ÇÁOIFo^JEg
        gn_add_normal_cnt := gn_add_normal_cnt + 1;
--
      END IF;
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
  END insert_add_oif;
--
  /**********************************************************************************
   * Procedure Name   : insert_adj_oif
   * Description      : C³OIFo^(A-10)
   ***********************************************************************************/
  PROCEDURE insert_adj_oif(
    in_rec_no     IN  NUMBER        --   ÎÛR[hÔ
   ,ov_errbuf     OUT VARCHAR2      --   G[EbZ[W           --# Åè #
   ,ov_retcode    OUT VARCHAR2      --   ^[ER[h             --# Åè #
   ,ov_errmsg     OUT VARCHAR2      --   [U[EG[EbZ[W --# Åè #
  )
  IS
    -- ===============================
    -- Åè[Jè
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'insert_adj_oif'; -- vO¼
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
    cv_status                 CONSTANT VARCHAR2(11)  := 'PENDING';  -- Xe[^X
    cn_months                 NUMBER                 := 12;         -- 12
--
    -- *** [JÏ ***
    ln_life_years             NUMBER;                                      -- ÏpN
    ln_life_months            NUMBER;                                      -- Ïp
    lt_cat_attribute15        xx01_adjustment_oif.cat_attribute15%TYPE;    -- JeSDFF15(IFRSÏpN)
    lt_cat_attribute16        xx01_adjustment_oif.cat_attribute16%TYPE;    -- JeSDFF16(IFRSp)
    lt_cat_attribute17        xx01_adjustment_oif.cat_attribute17%TYPE;    -- JeSDFF17(s®Yæ¾Å)
    lt_cat_attribute18        xx01_adjustment_oif.cat_attribute18%TYPE;    -- JeSDFF18(ØüRXg)
    lt_cat_attribute19        xx01_adjustment_oif.cat_attribute19%TYPE;    -- JeSDFF19(»Ì¼)
    lt_cat_attribute20        xx01_adjustment_oif.cat_attribute20%TYPE;    -- JeSDFF20(IFRSYÈÚ)
    lt_cat_attribute21        xx01_adjustment_oif.cat_attribute21%TYPE;    -- JeSDFF21(C³Nú)
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
    -- ***************************************
    -- ***        ÀÌLq             ***
    -- ***       ¤ÊÖÌÄÑoµ        ***
    -- ***************************************
--
    -- [JÏÌú»
    ln_life_years       := NULL;  -- ÏpN
    ln_life_months      := NULL;  -- Ïp
    lt_cat_attribute15  := NULL;  -- JeSDFF15(IFRSÏpN)
    lt_cat_attribute16  := NULL;  -- JeSDFF16(IFRSp)
    lt_cat_attribute17  := NULL;  -- JeSDFF17(s®Yæ¾Å)
    lt_cat_attribute18  := NULL;  -- JeSDFF18(ØüRXg)
    lt_cat_attribute19  := NULL;  -- JeSDFF19(»Ì¼)
    lt_cat_attribute20  := NULL;  -- JeSDFF20(IFRSYÈÚ)
    lt_cat_attribute21  := NULL;  -- JeSDFF21(C³Nú)
--
    -- æªªu 2iC³jvÌê
    IF ( g_upload_tab(in_rec_no).process_type = cv_process_type_2 ) THEN
--
      -- ===============================
      -- ÏpNAÏpZo
      -- ===============================
      -- ÏpN
      ln_life_years  := TRUNC(g_fa_tab(in_rec_no).life_in_months / cn_months);
      -- Ïp
      ln_life_months := MOD(g_fa_tab(in_rec_no).life_in_months, cn_months);
--
      -- ===============================
      -- IFRSÚZbg
      -- ===============================
      -- JeSDFF15(IFRSÏpN)
      IF ( g_upload_tab(in_rec_no).ifrs_life_in_months IS NOT NULL ) THEN
        lt_cat_attribute15 := g_upload_tab(in_rec_no).ifrs_life_in_months;
      ELSE
        lt_cat_attribute15 := g_fa_tab(in_rec_no).cat_attribute15;
      END IF;
--
      -- JeSDFF16(IFRSp)
      IF ( g_upload_tab(in_rec_no).ifrs_cat_deprn_method IS NOT NULL ) THEN
        lt_cat_attribute16 := g_upload_tab(in_rec_no).ifrs_cat_deprn_method;
      ELSE
        lt_cat_attribute16 := g_fa_tab(in_rec_no).cat_attribute16;
      END IF;
--
      -- JeSDFF17(s®Yæ¾Å)
      IF ( g_upload_tab(in_rec_no).real_estate_acq_tax IS NOT NULL ) THEN
        lt_cat_attribute17 := g_upload_tab(in_rec_no).real_estate_acq_tax;
      ELSE
        lt_cat_attribute17 := g_fa_tab(in_rec_no).cat_attribute17;
      END IF;
--
      -- JeSDFF18(ØüRXg)
      IF ( g_upload_tab(in_rec_no).borrowing_cost IS NOT NULL ) THEN
        lt_cat_attribute18 := g_upload_tab(in_rec_no).borrowing_cost;
      ELSE
        lt_cat_attribute18 := g_fa_tab(in_rec_no).cat_attribute18;
      END IF;
--
      -- JeSDFF19(»Ì¼)
      IF ( g_upload_tab(in_rec_no).other_cost IS NOT NULL ) THEN
        lt_cat_attribute19 := g_upload_tab(in_rec_no).other_cost;
      ELSE
        lt_cat_attribute19 := g_fa_tab(in_rec_no).cat_attribute19;
      END IF;
--
      -- JeSDFF20(IFRSYÈÚ)
      IF ( g_upload_tab(in_rec_no).ifrs_asset_account IS NOT NULL ) THEN
        lt_cat_attribute20 := g_upload_tab(in_rec_no).ifrs_asset_account;
      ELSE
        lt_cat_attribute20 := g_fa_tab(in_rec_no).cat_attribute20;
      END IF;
--
      -- ****************************
      -- C³OIFo^
      -- ****************************
      BEGIN
        INSERT INTO xx01_adjustment_oif(
           adjustment_oif_id               -- ID
          ,book_type_code                  -- ä ¼
          ,asset_number_old                -- YÔ
          ,dpis_old                        -- ÆpúiC³Oj
          ,category_id_old                 -- YJeSIDiC³Oj
          ,cat_attribute_category_old      -- YJeSR[hiC³Oj
          ,dpis_new                        -- ÆpúiC³ãj
          ,description                     -- EviC³ãj
          ,transaction_units               -- PÊ
          ,cost                            -- æ¾¿z
          ,original_cost                   -- æ¾¿z
          ,posting_flag                    -- ]L`FbNtO
          ,status                          -- Xe[^X
          ,asset_number_new                -- YÔiC³ãj
          ,tag_number                      -- »i[Ô
          ,category_id_new                 -- YJeSIDiC³ãj
          ,serial_number                   -- VAÔ
          ,asset_key_ccid                  -- YL[CCID
          ,key_segment1                    -- YL[ZOg1
          ,key_segment2                    -- YL[ZOg2
          ,parent_asset_id                 -- eYID
          ,lease_id                        -- [XID
          ,model_number                    -- f
          ,in_use_flag                     -- gpóµ
          ,inventorial                     -- ÀnIµtO
          ,owned_leased                    -- L 
          ,new_used                        -- Vi/Ã
          ,cat_attribute1                  -- JeSDFF1
          ,cat_attribute2                  -- JeSDFF2
          ,cat_attribute3                  -- JeSDFF3
          ,cat_attribute4                  -- JeSDFF4
          ,cat_attribute5                  -- JeSDFF5
          ,cat_attribute6                  -- JeSDFF6
          ,cat_attribute7                  -- JeSDFF7
          ,cat_attribute8                  -- JeSDFF8
          ,cat_attribute9                  -- JeSDFF9
          ,cat_attribute10                 -- JeSDFF10
          ,cat_attribute11                 -- JeSDFF11
          ,cat_attribute12                 -- JeSDFF12
          ,cat_attribute13                 -- JeSDFF13
          ,cat_attribute14                 -- JeSDFF14
          ,cat_attribute15                 -- JeSDFF15
          ,cat_attribute16                 -- JeSDFF16
          ,cat_attribute17                 -- JeSDFF17
          ,cat_attribute18                 -- JeSDFF18
          ,cat_attribute19                 -- JeSDFF19
          ,cat_attribute20                 -- JeSDFF20
          ,cat_attribute21                 -- JeSDFF21
          ,cat_attribute22                 -- JeSDFF22
          ,cat_attribute23                 -- JeSDFF23
          ,cat_attribute24                 -- JeSDFF24
          ,cat_attribute25                 -- JeSDFF27
          ,cat_attribute26                 -- JeSDFF25
          ,cat_attribute27                 -- JeSDFF26
          ,cat_attribute28                 -- JeSDFF28
          ,cat_attribute29                 -- JeSDFF29
          ,cat_attribute30                 -- JeSDFF30
          ,cat_attribute_category_new      -- YJeSR[hiC³ãj
          ,salvage_value                   -- c¶¿z
          ,percent_salvage_value           -- c¶¿z%
          ,allowed_deprn_limit_amount      -- pÀxz
          ,allowed_deprn_limit             -- pÀx¦
          ,ytd_deprn                       -- NpÝvz
          ,deprn_reserve                   -- pÝvz
          ,depreciate_flag                 -- pïvãtO
          ,deprn_method_code               -- pû@
          ,basic_rate                      -- Êp¦
          ,adjusted_rate                   -- ãp¦
          ,life_years                      -- ÏpN
          ,life_months                     -- Ïp
          ,bonus_rule                      -- {[iX[
          ,bonus_ytd_deprn                 -- {[iXNpÝvz
          ,bonus_deprn_reserve             -- {[iXpÝvz
          ,created_by                      -- ì¬Ò
          ,creation_date                   -- ì¬ú
          ,last_updated_by                 -- ÅIXVÒ
          ,last_update_date                -- ÅIXVú
          ,last_update_login               -- ÅIXVOCID
          ,request_id                      -- vID
          ,program_application_id          -- AvP[VID
          ,program_id                      -- vOID
          ,program_update_date             -- vOÅIXVú
        )
        VALUES (
           xx01_adjustment_oif_s.NEXTVAL                                    -- ID
          ,gv_fixed_asset_register                                          -- ä ¼
          ,g_fa_tab(in_rec_no).asset_number_old                             -- YÔiC³Oj
          ,g_fa_tab(in_rec_no).dpis_old                                     -- ÆpúiC³Oj
          ,g_fa_tab(in_rec_no).category_id_old                              -- YJeSIDiC³Oj
          ,g_fa_tab(in_rec_no).cat_attribute_category_old                   -- YJeSR[hiC³Oj
          ,g_fa_tab(in_rec_no).dpis_old                                     -- ÆpúiC³Oj
          ,g_fa_tab(in_rec_no).description                                  -- EviC³ãj
          ,g_fa_tab(in_rec_no).transaction_units                            -- PÊ
          ,g_fa_tab(in_rec_no).cost                                         -- æ¾¿z
          ,g_fa_tab(in_rec_no).original_cost                                -- æ¾¿z
          ,cv_yes                                                           -- ]L`FbNtO
          ,cv_status                                                        -- Xe[^X
          ,g_fa_tab(in_rec_no).asset_number_new                             -- YÔiC³ãj
          ,g_fa_tab(in_rec_no).tag_number                                   -- »i[Ô
          ,g_fa_tab(in_rec_no).category_id_new                              -- YJeSIDiC³ãj
          ,g_fa_tab(in_rec_no).serial_number                                -- VAÔ
          ,g_fa_tab(in_rec_no).asset_key_ccid                               -- YL[CCID
          ,g_fa_tab(in_rec_no).key_segment1                                 -- YL[ZOg1
          ,g_fa_tab(in_rec_no).key_segment2                                 -- YL[ZOg2
          ,g_fa_tab(in_rec_no).parent_asset_id                              -- eYID
          ,g_fa_tab(in_rec_no).lease_id                                     -- [XID
          ,g_fa_tab(in_rec_no).model_number                                 -- f
          ,g_fa_tab(in_rec_no).in_use_flag                                  -- gpóµ
          ,g_fa_tab(in_rec_no).inventorial                                  -- ÀnIµtO
          ,g_fa_tab(in_rec_no).owned_leased                                 -- L 
          ,g_fa_tab(in_rec_no).new_used                                     -- Vi/Ã
          ,g_fa_tab(in_rec_no).cat_attribute1                               -- JeSDFF1
          ,g_fa_tab(in_rec_no).cat_attribute2                               -- JeSDFF2
          ,g_fa_tab(in_rec_no).cat_attribute3                               -- JeSDFF3
          ,g_fa_tab(in_rec_no).cat_attribute4                               -- JeSDFF4
          ,g_fa_tab(in_rec_no).cat_attribute5                               -- JeSDFF5
          ,g_fa_tab(in_rec_no).cat_attribute6                               -- JeSDFF6
          ,g_fa_tab(in_rec_no).cat_attribute7                               -- JeSDFF7
          ,g_fa_tab(in_rec_no).cat_attribute8                               -- JeSDFF8
          ,g_fa_tab(in_rec_no).cat_attribute9                               -- JeSDFF9
          ,g_fa_tab(in_rec_no).cat_attribute10                              -- JeSDFF10
          ,g_fa_tab(in_rec_no).cat_attribute11                              -- JeSDFF11
          ,g_fa_tab(in_rec_no).cat_attribute12                              -- JeSDFF12
          ,g_fa_tab(in_rec_no).cat_attribute13                              -- JeSDFF13
          ,g_fa_tab(in_rec_no).cat_attribute14                              -- JeSDFF14
          ,lt_cat_attribute15                                               -- IFRSÏpNiDFF15j
          ,lt_cat_attribute16                                               -- IFRSpiDFF16j
          ,lt_cat_attribute17                                               -- s®Yæ¾ÅiDFF17j
          ,lt_cat_attribute18                                               -- ØüRXgiDFF18j
          ,lt_cat_attribute19                                               -- »Ì¼iDFF19j
          ,lt_cat_attribute20                                               -- IFRSYÈÚiDFF20j
          ,TO_CHAR(g_upload_tab(in_rec_no).correct_date ,cv_date_fmt_std)   -- C³NúiDFF21j
          ,g_fa_tab(in_rec_no).cat_attribute22                              -- JeSDFF22
          ,g_fa_tab(in_rec_no).cat_attribute23                              -- JeSDFF23
          ,g_fa_tab(in_rec_no).cat_attribute24                              -- JeSDFF24
          ,g_fa_tab(in_rec_no).cat_attribute25                              -- JeSDFF27
          ,g_fa_tab(in_rec_no).cat_attribute26                              -- JeSDFF25
          ,g_fa_tab(in_rec_no).cat_attribute27                              -- JeSDFF26
          ,g_fa_tab(in_rec_no).cat_attribute28                              -- JeSDFF28
          ,g_fa_tab(in_rec_no).cat_attribute29                              -- JeSDFF29
          ,g_fa_tab(in_rec_no).cat_attribute30                              -- JeSDFF30
          ,g_fa_tab(in_rec_no).cat_attribute_category_new                   -- YJeSR[hiC³ãj
          ,g_fa_tab(in_rec_no).salvage_value                                -- c¶¿z
          ,g_fa_tab(in_rec_no).percent_salvage_value                        -- c¶¿z%
          ,g_fa_tab(in_rec_no).allowed_deprn_limit_amount                   -- pÀxz
          ,g_fa_tab(in_rec_no).allowed_deprn_limit                          -- pÀx¦
          ,g_fa_tab(in_rec_no).ytd_deprn                                    -- NpÝvz
          ,g_fa_tab(in_rec_no).deprn_reserve                                -- pÝvz
          ,g_fa_tab(in_rec_no).depreciate_flag                              -- pïvãtO
          ,g_fa_tab(in_rec_no).deprn_method_code                            -- pû@
          ,g_fa_tab(in_rec_no).basic_rate                                   -- Êp¦
          ,g_fa_tab(in_rec_no).adjusted_rate                                -- ãp¦
          ,ln_life_years                                                    -- ÏpN
          ,ln_life_months                                                   -- Ïp
          ,g_fa_tab(in_rec_no).bonus_rule                                   -- {[iX[
          ,g_fa_tab(in_rec_no).bonus_ytd_deprn                              -- {[iXNpÝvz
          ,g_fa_tab(in_rec_no).bonus_deprn_reserve                          -- {[iXpÝvz
          ,cn_created_by                                                    -- ì¬Ò
          ,cd_creation_date                                                 -- ì¬ú
          ,cn_last_updated_by                                               -- ÅIXVÒ
          ,cd_last_update_date                                              -- ÅIXVú
          ,cn_last_update_login                                             -- ÅIXVOCID
          ,cn_request_id                                                    -- vID
          ,cn_program_application_id                                        -- AvP[VID
          ,cn_program_id                                                    -- vOID
          ,cd_program_update_date                                           -- vOÅIXVú
        )
        ;
        EXCEPTION
          WHEN OTHERS THEN
            -- o^G[
            lv_errmsg := xxccp_common_pkg.get_msg(
                            iv_application  => cv_msg_kbn_cff           -- AvP[VZk¼
                           ,iv_name         => cv_msg_name_00102        -- bZ[W
                           ,iv_token_name1  => cv_tkn_table_name        -- g[NR[h1
                           ,iv_token_value1 => cv_tkn_val_50320         -- g[Nl1
                           ,iv_token_name2  => cv_tkn_info              -- g[NR[h2
                           ,iv_token_value2 => SQLERRM                  -- g[Nl2
                         );
            lv_errbuf := lv_errmsg;
            RAISE global_api_expt;
        END;
--
      -- C³OIFo^JEg
      gn_adj_normal_cnt := gn_adj_normal_cnt + 1;
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
  END insert_adj_oif;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : CvV[W
   **********************************************************************************/
  PROCEDURE submain(
    in_file_id      IN   NUMBER       -- 1.t@CID
   ,iv_file_format  IN   VARCHAR2     -- 2.t@CtH[}bg
   ,ov_errbuf       OUT  VARCHAR2     --   G[EbZ[W           --# Åè #
   ,ov_retcode      OUT  VARCHAR2     --   ^[ER[h             --# Åè #
   ,ov_errmsg       OUT  VARCHAR2     --   [U[EG[EbZ[W --# Åè #
  )
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
    ln_error_cnt   NUMBER;
--
    -- [vÌJEg
    ln_loop_cnt_1  NUMBER;   -- [vJE^1
    ln_loop_cnt_2  NUMBER;   -- [vJE^2
    ln_loop_cnt_3  NUMBER;   -- [vJE^3
    ln_line_no     NUMBER;   -- sÔJE^(^CgsðÜÜÈ¢JE^)
--
  BEGIN
--
--##################  ÅèXe[^Xú» START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  Åè END   ############################
--
    -- O[oÏÌú»
    gn_target_cnt      := 0;
    gn_normal_cnt      := 0;
    gn_error_cnt       := 0;
    gn_warn_cnt        := 0;
--
    gn_add_target_cnt  := 0;
    gn_add_normal_cnt  := 0;
    gn_add_error_cnt   := 0;
    gn_adj_target_cnt  := 0;
    gn_adj_normal_cnt  := 0;
    gn_adj_error_cnt   := 0;
    gb_err_flag        := FALSE;
    -- [JÏÌú»
    ln_loop_cnt_1      := 0;
    ln_loop_cnt_2      := 0;
    ln_loop_cnt_3      := 0;
    ln_line_no         := 0;
    ln_error_cnt       := 0;
--
    --*********************************************
    --***      MD.050Ìt[}ð\·           ***
    --***      ªòÆÌÄÑoµðs¤     ***
    --*********************************************
--
    -- ============================================
    -- ú(A-1)
    -- ============================================
    init(
       in_file_id        -- 1.t@CID
      ,lv_errbuf         -- G[EbZ[W           --# Åè #
      ,lv_retcode        -- ^[ER[h             --# Åè #
      ,lv_errmsg         -- [U[EG[EbZ[W --# Åè #
    );
    -- Ê`FbN
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ============================================
    -- Ã«`FbNpÌlæ¾(A-2)
    -- ============================================
    get_for_validation(
       lv_errbuf         -- G[EbZ[W           --# Åè #
      ,lv_retcode        -- ^[ER[h             --# Åè #
      ,lv_errmsg         -- [U[EG[EbZ[W --# Åè #
    );
    -- Ê`FbN
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ============================================
    -- t@CAbv[hIFf[^æ¾(A-3)
    -- ============================================
    get_upload_data(
       lv_errbuf         -- G[EbZ[W           --# Åè #
      ,lv_retcode        -- ^[ER[h             --# Åè #
      ,lv_errmsg         -- [U[EG[EbZ[W --# Åè #
    );
    -- Ê`FbN
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_process_expt;
    END IF;
--
    --C[v@
    <<main_loop_1>>
    FOR ln_loop_cnt_1 IN g_if_data_tab.FIRST .. g_if_data_tab.LAST LOOP
--
      -- G[tOú»
      gb_err_flag := FALSE;
--
      --PsÚÍJsÌ½ßXLbv
      IF ( ln_loop_cnt_1 <> 1 ) THEN
        -- sÔÌJEg
        ln_line_no := ln_line_no + 1;
        --C[vAJE^ÌZbg
        ln_loop_cnt_2 := 0;
--
        --C[vA
        <<main_loop_2>>
        FOR ln_loop_cnt_2 IN g_column_desc_tab.FIRST .. g_column_desc_tab.LAST LOOP
          -- ============================================
          -- f~^¶Úª(A-4)
          -- ============================================
          divide_item(
             ln_loop_cnt_1     -- [vJE^1
            ,ln_loop_cnt_2     -- [vJE^2
            ,lv_errbuf         -- G[EbZ[W           --# Åè #
            ,lv_retcode        -- ^[ER[h             --# Åè #
            ,lv_errmsg         -- [U[EG[EbZ[W --# Åè #
          );
          -- Ê`FbN
          IF ( lv_retcode <> cv_status_normal ) THEN
            RAISE global_process_expt;
          END IF;
--
          -- ============================================
          -- Úl`FbN(A-5)
          -- ============================================
          check_item_value(
             ln_line_no        -- sÔJE^
            ,ln_loop_cnt_2     -- [vJE^2
            ,lv_errbuf         -- G[EbZ[W           --# Åè #
            ,lv_retcode        -- ^[ER[h             --# Åè #
            ,lv_errmsg         -- [U[EG[EbZ[W --# Åè #
          );
          -- Ê`FbN
          IF ( lv_retcode = cv_status_error ) THEN
            RAISE global_process_expt;
          END IF;
--
        END LOOP main_loop_2;
--
        -- Úl`FbNÅG[ª­¶µ½êÍAA-6XLbv
        IF ( gb_err_flag ) THEN
          -- G[ðJEg
          ln_error_cnt := ln_error_cnt + 1;
        ELSE
          -- ============================================
          -- ÅèYAbv[h[Nì¬(A-6)
          -- ============================================
          ins_upload_wk(
             ln_line_no        -- sÔJE^
            ,lv_errbuf         -- G[EbZ[W           --# Åè #
            ,lv_retcode        -- ^[ER[h             --# Åè #
            ,lv_errmsg         -- [U[EG[EbZ[W --# Åè #
          );
          -- Ê`FbN
          IF ( lv_retcode = cv_status_error ) THEN
            RAISE global_process_expt;
          END IF;
        END IF;
      END IF;
--
    END LOOP main_loop_1;
--
    -- 1ÅàG[ª¶Ý·éêÍðI¹·é
    IF ( ln_error_cnt <> 0 ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ============================================
    -- ÅèYAbv[h[Næ¾(A-7)
    -- ============================================
    get_upload_wk(
       lv_errbuf         -- G[EbZ[W           --# Åè #
      ,lv_retcode        -- ^[ER[h             --# Åè #
      ,lv_errmsg         -- [U[EG[EbZ[W --# Åè #
    );
    -- Ê`FbN
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- A-7Åæ¾ª1ÈãÌê
    IF ( g_upload_tab.COUNT <> 0 ) THEN
--
      -- C[vB
      <<main_loop_3>>
      FOR ln_loop_cnt_3 IN g_upload_tab.FIRST .. g_upload_tab.LAST LOOP
--
        -- G[tOÌú»
        gb_err_flag := FALSE;
--
        -- ============================================
        -- f[^Ã«`FbN(A-8)
        -- ============================================
        data_validation(
           ln_loop_cnt_3     -- [vJE^3iÎÛR[hÔj
          ,lv_errbuf         -- G[EbZ[W           --# Åè #
          ,lv_retcode        -- ^[ER[h             --# Åè #
          ,lv_errmsg         -- [U[EG[EbZ[W --# Åè #
        );
        -- G[ª­¶µ½êAG[ðJEg
        IF ( gb_err_flag ) THEN
          ln_error_cnt := ln_error_cnt + 1;
        -- `FbNG[ªÈ¢êÍðp±
        ELSE
          -- ============================================
          -- ÇÁOIFo^(A-9)
          -- ============================================
          insert_add_oif(
             ln_loop_cnt_3     -- [vJE^3iÎÛR[hÔj
            ,lv_errbuf         -- G[EbZ[W           --# Åè #
            ,lv_retcode        -- ^[ER[h             --# Åè #
            ,lv_errmsg         -- [U[EG[EbZ[W --# Åè #
          );
          -- Ê`FbN
          IF ( lv_retcode <> cv_status_normal ) THEN
            RAISE global_process_expt;
          END IF;
          -- G[ª­¶µ½êAG[ðJEg
          IF ( gb_err_flag ) THEN
            ln_error_cnt := ln_error_cnt + 1;
          END IF;
--
          -- ============================================
          -- C³OIFo^(A-10)
          -- ============================================
          insert_adj_oif(
             ln_loop_cnt_3     -- [vJE^3iÎÛR[hÔj
            ,lv_errbuf         -- G[EbZ[W           --# Åè #
            ,lv_retcode        -- ^[ER[h             --# Åè #
            ,lv_errmsg         -- [U[EG[EbZ[W --# Åè #
          );
          -- Ê`FbN
          IF ( lv_retcode <> cv_status_normal ) THEN
            RAISE global_process_expt;
          END IF;
        END IF;
--
      END LOOP main_loop_3;
--
      -- 1ÅàG[ª¶Ý·éêÍG[I¹
      IF ( ln_error_cnt <> 0 ) THEN
        ov_retcode := cv_status_error;
      END IF;
--
    ELSE
      -- ÎÛf[^ª¶ÝµÈ¢êÍAÎÛf[^ÈµbZ[Wð\¦
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application => cv_msg_kbn_cff       -- AvP[VZk¼
                     ,iv_name        => cv_msg_name_00062    -- bZ[WR[h
                   );
      FND_FILE.PUT_LINE(
        which => FND_FILE.OUTPUT,
        buff  => lv_errmsg
      );
      ov_retcode := cv_status_error;
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
  --RJgÀst@Co^vV[W
  PROCEDURE main(
    errbuf           OUT   VARCHAR2,        --   G[bZ[W #Åè#
    retcode          OUT   VARCHAR2,        --   G[R[h     #Åè#
    in_file_id       IN    NUMBER,          --   1.t@CID
    iv_file_format   IN    VARCHAR2         --   2.t@CtH[}bg
  )
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
    cv_normal_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004'; -- ³íI¹bZ[W
    cv_warn_msg        CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005'; -- xI¹bZ[W
    cv_error_msg       CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006'; -- G[I¹S[obN
--
    cv_cnt_token       CONSTANT VARCHAR2(10)  := 'COUNT';            -- bZ[Wpg[N¼
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
      ,iv_which   => cv_file_type_out
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
       in_file_id      -- 1.t@CID
      ,iv_file_format  -- 2.t@CtH[}bg
      ,lv_errbuf       -- G[EbZ[W           --# Åè #
      ,lv_retcode      -- ^[ER[h             --# Åè #
      ,lv_errmsg       -- [U[EG[EbZ[W --# Åè #
    );
--
    -- G[oÍ
    IF (lv_retcode = cv_status_error) THEN
--
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg --[U[EG[bZ[W
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --G[bZ[W
      );
      -- ós}ü
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => ''
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => ''
      );
      -- ÇÁOIFo^É¨¯é
      gn_add_target_cnt := 0;  -- ÎÛ
      gn_add_normal_cnt := 0;  -- ³í
      gn_add_error_cnt  := 1;  -- G[
      -- C³OIFo^É¨¯é
      gn_adj_target_cnt := 0;  -- ÎÛ
      gn_adj_normal_cnt := 0;  -- ³í
      gn_adj_error_cnt  := 1;  -- G[
--
    END IF;
--
    IF ( lv_retcode <> cv_status_normal ) THEN
      -- ³íÈOÌêA[obNð­s
      ROLLBACK;
    ELSE
      -- ============================================
      -- ÎÛf[^í(A-11)
      -- ============================================
      -- ÅèYAbv[h[Ní
      DELETE FROM
        xxcff_fa_upload_work xfuw
      WHERE
        xfuw.file_id = in_file_id
      ;
--
      -- t@CAbv[hI/Fe[uí
      DELETE FROM
        xxccp_mrp_file_ul_interface xmfui
      WHERE
        xmfui.file_id = in_file_id
      ;
    END IF;
--
    -- e[uíãÌR~bg
    IF ( lv_retcode <> cv_status_normal ) THEN
      COMMIT;
    END IF;
--
    --===============================================================
    --ÇÁOIFo^É¨¯éoÍ
    --===============================================================
    -- ÇÁOIFo^bZ[WoÍ
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_cff               -- AvP[VZk¼
                    ,iv_name         => cv_msg_name_00266            -- bZ[W
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT  -- bZ[WoÍ
      ,buff   => gv_out_msg
    );
    -- ÎÛoÍ
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_ccp               -- AvP[VZk¼
                    ,iv_name         => cv_target_rec_msg            -- bZ[W
                    ,iv_token_name1  => cv_cnt_token                 -- g[NR[h1
                    ,iv_token_value1 => TO_CHAR(gn_add_target_cnt)   -- g[Nl1
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT  -- bZ[WoÍ
      ,buff   => gv_out_msg
    );
    -- ¬÷oÍ
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_ccp               -- AvP[VZk¼
                    ,iv_name         => cv_success_rec_msg           -- bZ[W
                    ,iv_token_name1  => cv_cnt_token                 -- g[NR[h1
                    ,iv_token_value1 => TO_CHAR(gn_add_normal_cnt)   -- g[Nl1
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT  -- bZ[WoÍ
      ,buff   => gv_out_msg
    );
    -- G[oÍ
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_ccp               -- AvP[VZk¼
                    ,iv_name         => cv_error_rec_msg             -- bZ[W
                    ,iv_token_name1  => cv_cnt_token                 -- g[NR[h1
                    ,iv_token_value1 => TO_CHAR(gn_add_error_cnt)    -- g[Nl1
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT  -- bZ[WoÍ
      ,buff   => gv_out_msg
    );
--
    -- ós}ü
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
--
    --===============================================================
    --C³OIFo^É¨¯éoÍ
    --===============================================================
    -- C³OIFo^bZ[WoÍ
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_cff               -- AvP[VZk¼
                    ,iv_name         => cv_msg_name_00267            -- bZ[W
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT  -- bZ[WoÍ
      ,buff   => gv_out_msg
    );
    -- ÎÛoÍ
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_ccp               -- AvP[VZk¼
                    ,iv_name         => cv_target_rec_msg            -- bZ[W
                    ,iv_token_name1  => cv_cnt_token                 -- g[NR[h1
                    ,iv_token_value1 => TO_CHAR(gn_adj_target_cnt)   -- g[Nl1
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT  -- bZ[WoÍ
      ,buff   => gv_out_msg
    );
    -- ¬÷oÍ
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_ccp               -- AvP[VZk¼
                    ,iv_name         => cv_success_rec_msg           -- bZ[W
                    ,iv_token_name1  => cv_cnt_token                 -- g[NR[h1
                    ,iv_token_value1 => TO_CHAR(gn_adj_normal_cnt)   -- g[Nl1
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT  -- bZ[WoÍ
      ,buff   => gv_out_msg
    );
    -- G[oÍ
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_ccp               -- AvP[VZk¼
                    ,iv_name         => cv_error_rec_msg             -- bZ[W
                    ,iv_token_name1  => cv_cnt_token                 -- g[NR[h1
                    ,iv_token_value1 => TO_CHAR(gn_adj_error_cnt)    -- g[Nl1
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT  -- bZ[WoÍ
      ,buff   => gv_out_msg
    );
--
    -- ós}ü
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
--
    -- I¹bZ[WÌÝèAoÍ
    IF (lv_retcode = cv_status_normal) THEN
      lv_message_code := cv_normal_msg;
    ELSIF(lv_retcode = cv_status_warn) THEN
      lv_message_code := cv_warn_msg;
    ELSIF(lv_retcode = cv_status_error) THEN
      lv_message_code := cv_error_msg;
    END IF;
    --
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_ccp           -- AvP[VZk¼
                    ,iv_name         => lv_message_code          -- bZ[W
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG     -- OoÍ
      ,buff   => gv_out_msg
    );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT  -- bZ[WoÍ
      ,buff   => gv_out_msg
    );
--
    --Xe[^XZbg
    retcode := lv_retcode;
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
END XXCFF019A01C;
/