CREATE OR REPLACE PACKAGE BODY XXCMM002A07C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2017. All rights reserved.
 *
 * Package Name     : XXCMM002A07C(body)
 * Description      : $B<R0w%^%9%?O"7H!J(BeSM$B!K(B
 * MD.050           : MD050_CMM_002_A07_$B<R0w%^%9%?O"7H!J(BeSM$B!K(B
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   $B=i4|=hM}(B(A-1)
 *  open_csv_file          $B%U%!%$%k%*!<%W%s=hM}(B(A-2)
 *  get_emp_data           $B=>6H0w%G!<%?<hF@=hM}(B(A-3)
 *  output_csv_data        CSV$B%U%!%$%k=PNO=hM}(B(A-4)
 *  submain                $B%a%$%s=hM}%W%m%7!<%8%c(B
 *  main                   $B%3%s%+%l%s%H<B9T%U%!%$%kEPO?%W%m%7!<%8%c(B
 *                         $B=*N;=hM}(B(A-5)
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2017/02/15    1.0   S.Niki           $B?75,:n@.(B
 *
 *****************************************************************************************/
--
--#######################  $B8GDj%0%m!<%P%kDj?t@k8@It(B START   #######################
--
  --$B%9%F!<%?%9!&%3!<%I(B
  cv_status_normal          CONSTANT VARCHAR2(1)  := xxccp_common_pkg.set_status_normal; --$B@5>o(B:0
  cv_status_warn            CONSTANT VARCHAR2(1)  := xxccp_common_pkg.set_status_warn;   --$B7Y9p(B:1
  cv_status_error           CONSTANT VARCHAR2(1)  := xxccp_common_pkg.set_status_error;  --$B0[>o(B:2
  --WHO$B%+%i%`(B
  cn_created_by             CONSTANT NUMBER       := fnd_global.user_id;         --CREATED_BY
  cd_creation_date          CONSTANT DATE         := SYSDATE;                    --CREATION_DATE
  cn_last_updated_by        CONSTANT NUMBER       := fnd_global.user_id;         --LAST_UPDATED_BY
  cd_last_update_date       CONSTANT DATE         := SYSDATE;                    --LAST_UPDATE_DATE
  cn_last_update_login      CONSTANT NUMBER       := fnd_global.login_id;        --LAST_UPDATE_LOGIN
  cn_request_id             CONSTANT NUMBER       := fnd_global.conc_request_id; --REQUEST_ID
  cn_program_application_id CONSTANT NUMBER       := fnd_global.prog_appl_id;    --PROGRAM_APPLICATION_ID
  cn_program_id             CONSTANT NUMBER       := fnd_global.conc_program_id; --PROGRAM_ID
  cd_program_update_date    CONSTANT DATE         := SYSDATE;                    --PROGRAM_UPDATE_DATE
--
  cv_msg_part               CONSTANT VARCHAR2(3)  := ' : ';
  cv_msg_cont               CONSTANT VARCHAR2(3)  := '.';
--
--################################  $B8GDjIt(B END   ##################################
--
--#######################  $B8GDj%0%m!<%P%kJQ?t@k8@It(B START   #######################
--
  gv_out_msg       VARCHAR2(2000);
  gv_sep_msg       VARCHAR2(2000);
  gv_exec_user     VARCHAR2(100);
  gv_conc_name     VARCHAR2(30);
  gv_conc_status   VARCHAR2(30);
  gn_target_cnt    NUMBER;                    -- $BBP>]7o?t(B
  gn_normal_cnt    NUMBER;                    -- $B@5>o7o?t(B
  gn_error_cnt     NUMBER;                    -- $B%(%i!<7o?t(B
  gn_warn_cnt      NUMBER;                    -- $B%9%-%C%W7o?t(B
--
--################################  $B8GDjIt(B END   ##################################
--
--##########################  $B8GDj6&DLNc30@k8@It(B START  ###########################
--
  --*** $B=hM}It6&DLNc30(B ***
  global_process_expt       EXCEPTION;
  --*** $B6&DL4X?tNc30(B ***
  global_api_expt           EXCEPTION;
  --*** $B6&DL4X?t(BOTHERS$BNc30(B ***
  global_api_others_expt    EXCEPTION;
--
  PRAGMA EXCEPTION_INIT(global_api_others_expt,-20000);
--
--################################  $B8GDjIt(B END   ##################################
--
  -- ===============================
  -- $B%f!<%6!<Dj5ANc30(B
  -- ===============================
  global_init_err_expt      EXCEPTION; -- $B=i4|=hM}%(%i!<(B
  global_f_open_err_expt    EXCEPTION; -- $B%U%!%$%k%*!<%W%s%(%i!<(B
  global_write_err_expt     EXCEPTION; -- CSV$B%G!<%?=PNO%(%i!<(B
  global_f_close_err_expt   EXCEPTION; -- $B%U%!%$%k%/%m!<%:%(%i!<(B
--
  -- ===============================
  -- $B%f!<%6!<Dj5A%0%m!<%P%kDj?t(B
  -- ===============================
  cv_pkg_name               CONSTANT VARCHAR2(12)  := 'XXCMM002A07C';         -- $B%Q%C%1!<%8L>(B
  -- $B%"%W%j%1!<%7%g%sC;=LL>(B
  cv_appl_xxcmm             CONSTANT VARCHAR2(5)   := 'XXCMM';                -- $B%"%I%*%s!'%^%9%?!&%^%9%?NN0h(B
  cv_appl_xxccp             CONSTANT VARCHAR2(5)   := 'XXCCP';                -- $B%"%I%*%s!'6&DL!&(BIF$BNN0h(B
--
  -- $BJ8;zNs(B
  cv_comma                  CONSTANT VARCHAR2(1)   := ',';                    -- $B%+%s%^(B
  cv_space_full             CONSTANT VARCHAR2(2)   := '$B!!(B';                   -- $BA43Q%9%Z!<%9(B
  cv_hyphen                 CONSTANT VARCHAR2(1)   := '-';                    -- $B%O%$%U%s(B
--
  -- $B%W%m%U%!%$%k(B
  cv_prf_org_id             CONSTANT VARCHAR2(30)  := 'ORG_ID';                         -- $B1D6HC10L(BID
  cv_prf_out_file_dir       CONSTANT VARCHAR2(30)  := 'XXCMM1_JIHANKI_OUT_DIR';         -- CSV$B%U%!%$%k=PNO@h(B
  cv_prf_out_file_name      CONSTANT VARCHAR2(30)  := 'XXCMM1_002A07_OUT_FILE';         -- CSV$B%U%!%$%kL>(B
  cv_prf_stop_bumon         CONSTANT VARCHAR2(30)  := 'XXCMM1_002A07_STOP_BUMON';       -- $BMxMQDd;_It=pL>(B
  cv_prf_other_wk_honbu     CONSTANT VARCHAR2(30)  := 'XXCMM1_002A07_OTHER_WK_HONBU';   -- $BB>$NC4Ev6HL3!JK\It1D6H!K(B
  cv_prf_other_wk_tenpo     CONSTANT VARCHAR2(30)  := 'XXCMM1_002A07_OTHER_WK_TENPO';   -- $BB>$NC4Ev6HL3!JE9J^1D6H!K(B
  cv_prf_other_wk_shanai    CONSTANT VARCHAR2(30)  := 'XXCMM1_002A07_OTHER_WK_SHANAI';  -- $BB>$NC4Ev6HL3!J<RFb6HL3!K(B
  cv_prf_licensed_prdcts    CONSTANT VARCHAR2(30)  := 'XXCMM1_002A07_LICENSED_PRDCTS';  -- $B%i%$%;%s%9$9$k@=IJ(B
  cv_prf_timezone           CONSTANT VARCHAR2(30)  := 'XXCMM1_002A07_TIMEZONE';         -- $B%?%$%`%>!<%s(B
  cv_prf_date_format        CONSTANT VARCHAR2(30)  := 'XXCMM1_002A07_DATE_FORMAT';      -- $BF|IU%U%)!<%^%C%H(B
  cv_prf_language           CONSTANT VARCHAR2(30)  := 'XXCMM1_002A07_LANGUAGE';         -- $B8@8l(B
  cv_prf_holiday_pattern    CONSTANT VARCHAR2(30)  := 'XXCMM1_002A07_HOLIDAY_PATTERN';  -- $B5YF|%Q%?!<%s(B
  cv_prf_role               CONSTANT VARCHAR2(30)  := 'XXCMM1_002A07_ROLE';             -- $B%m!<%k(B
--
  -- $B%?%$%W(B
  cv_lkp_qual_code          CONSTANT VARCHAR2(30)  := 'XXCMM_QUALIFICATION_CODE';       -- $B;q3J%3!<%I(B
  cv_lkp_posi_code          CONSTANT VARCHAR2(30)  := 'XXCMM_POSITION_CODE';            -- $B?&0L%3!<%I(B
  cv_lkp_main_work          CONSTANT VARCHAR2(30)  := 'XXCSO1_ESM_MAIN_WORK';           -- $B<g6HL3(B
--
  -- $B%a%C%;!<%8(B
  cv_file_name_msg          CONSTANT VARCHAR2(16)  := 'APP-XXCCP1-05102';     -- $B%U%!%$%kL>%a%C%;!<%8(B
  cv_input_param_msg        CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00225';     -- $BF~NO%Q%i%a!<%?J8;zNs(B
  cv_csv_header_msg         CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00226';     -- CSV$B%X%C%@J8;zNs(B
  cv_process_date_err_msg   CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00018';     -- $B6HL3F|IU<hF@%(%i!<%a%C%;!<%8(B
  cv_profile_err_msg        CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00002';     -- $B%W%m%U%!%$%k<hF@%(%i!<(B
  cv_date_reversal_err_msg  CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00227';     -- $B:G=*99?7F|5UE>%A%'%C%/%(%i!<(B
  cv_e_date_select_err_msg  CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00220';     -- $B:G=*99?7F|!J=*N;!K;XDj%(%i!<(B
  cv_file_exists_err_msg    CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00010';     -- $B%U%!%$%k:n@.:Q$_%(%i!<(B
  cv_main_work_err_msg      CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00228';     -- eSM$B<g6HL3L$@_Dj%(%i!<(B
  cv_resource_err_msg       CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00229';     -- $B%j%=!<%9%0%k!<%WLr3d=EJ#%(%i!<(B
  cv_file_open_err_msg      CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00487';     -- $B%U%!%$%k%*!<%W%s%(%i!<(B
  cv_file_write_err_msg     CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00488';     -- CSV$B%G!<%?=PNO%(%i!<(B
  cv_file_close_err_msg     CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00489';     -- $B%U%!%$%k%/%m!<%:%(%i!<(B
--
  -- $B%H!<%/%s(B
  cv_tkn_date_from          CONSTANT VARCHAR2(30)  := 'DATE_FROM';            -- $B3+;OF|(B
  cv_tkn_date_to            CONSTANT VARCHAR2(30)  := 'DATE_TO';              -- $B=*N;F|(B
  cv_tkn_file_name          CONSTANT VARCHAR2(30)  := 'FILE_NAME';            -- CSV$B%U%!%$%kL>(B
  cv_tkn_ng_profile         CONSTANT VARCHAR2(30)  := 'NG_PROFILE';           -- $B%W%m%U%!%$%kL>(B
  cv_tkn_sqlerrm            CONSTANT VARCHAR2(30)  := 'SQLERRM';              -- SQL$B%(%i!<%a%C%;!<%8(B
  cv_tkn_employee_number    CONSTANT VARCHAR2(30)  := 'EMPLOYEE_NUMBER';      -- $B=>6H0wHV9f(B
  cv_tkn_start_date_active  CONSTANT VARCHAR2(30)  := 'START_DATE_ACTIVE';    -- $BE,MQ3+;OF|(B
--
  cv_fmt_std                CONSTANT VARCHAR2(10)  := 'YYYY/MM/DD';           -- $BF|IU=q<0!'(BYYYY/MM/DD
  cv_max_date               CONSTANT VARCHAR2(10)  := '9999/12/31';           -- $B:GBgF|IU(B
  ct_lang                   CONSTANT fnd_lookup_values.language%TYPE
                                                   := USERENV('LANG');        -- $B8@8l(B
  cv_category_emp           CONSTANT VARCHAR2(8)   := 'EMPLOYEE';             -- $B%+%F%4%j!'=>6H0w(B
  cv_resource_type_gm       CONSTANT VARCHAR2(15)  := 'RS_GROUP_MEMBER';      -- $B%j%=!<%9%?%$%W!'%0%k!<%W%a%s%P!<(B
  cv_cust_class_base        CONSTANT VARCHAR2(1)   := '1';                    -- $B8\5R6hJ,!'5rE@(B
  cv_flag_y                 CONSTANT VARCHAR2(1)   := 'Y';                    -- $B%U%i%0!'(BY
  cv_flag_n                 CONSTANT VARCHAR2(1)   := 'N';                    -- $B%U%i%0!'(BN
  cv_main_wk_honbu          CONSTANT VARCHAR2(1)   := '1';                    -- $B<g6HL3!'K\It1D6H(B
  cv_main_wk_tenpo          CONSTANT VARCHAR2(1)   := '2';                    -- $B<g6HL3!'E9J^1D6H(B
  cv_main_wk_shanai         CONSTANT VARCHAR2(1)   := '3';                    -- $B<g6HL3!'<RFb6HL3(B
--
  -- ===============================
  -- $B%f!<%6!<Dj5A%0%m!<%P%k7?(B
  -- ===============================
--
  -- ===============================
  -- $B%f!<%6!<Dj5A%0%m!<%P%kJQ?t(B
  -- ===============================
  gd_process_date           DATE;                -- $B6HL3F|IU(B
  gf_file_handler           UTL_FILE.FILE_TYPE;  -- $B%U%!%$%k!&%O%s%I%i(B
--
  gd_active_s_date          DATE;                -- $BE,MQF|(B($B3+;O(B)
  gd_active_e_date          DATE;                -- $BE,MQF|(B($B=*N;(B)
  gd_update_s_date          DATE;                -- $B:G=*99?7F|(B($B3+;O(B)
  gd_update_e_date          DATE;                -- $B:G=*99?7F|(B($B=*N;(B)
--
  -- $B%W%m%U%!%$%k(B
  gt_org_id                 mtl_parameters.organization_id%TYPE;
                                                 -- $B1D6HC10L(BID
  gv_out_file_dir           VARCHAR2(100);       -- CSV$B%U%!%$%k=PNO@h(B
  gv_out_file_name          VARCHAR2(100);       -- CSV$B%U%!%$%kL>(B
  gv_stop_bumon             VARCHAR2(100);       -- $BMxMQDd;_It=pL>(B
  gv_other_wk_honbu         VARCHAR2(500);       -- $BB>$NC4Ev6HL3!JK\It1D6H!K(B
  gv_other_wk_tenpo         VARCHAR2(500);       -- $BB>$NC4Ev6HL3!JE9J^1D6H!K(B
  gv_other_wk_shanai        VARCHAR2(500);       -- $BB>$NC4Ev6HL3!J<RFb6HL3!K(B
  gv_licensed_prdcts        VARCHAR2(500);       -- $B%i%$%;%s%9$9$k@=IJ(B
  gv_timezone               VARCHAR2(100);       -- $B%?%$%`%>!<%s(B
  gv_date_format            VARCHAR2(100);       -- $BF|IU%U%)!<%^%C%H(B
  gv_language               VARCHAR2(100);       -- $B8@8l(B
  gv_holiday_pattern        VARCHAR2(100);       -- $B5YF|%Q%?!<%s(B
  gv_role                   VARCHAR2(500);       -- $B%m!<%k(B
--
  -- ===============================
  -- $B%f!<%6!<Dj5A%0%m!<%P%k%+!<%=%k(B
  -- ===============================
  CURSOR get_emp_data_cur
  IS
    SELECT /*+
             INDEX( jrrr JTF_RS_ROLE_RELATIONS_N1 )
           */
           papf.employee_number                    AS employee_number     -- $B<R0wHV9f(B
         , papf.per_information18
             || cv_space_full
             || papf.per_information19             AS employee_name       -- $B<R0w;aL>(B
         , papf.last_name
             || cv_space_full
             || papf.first_name                    AS employee_name_kana  -- $B<R0w;aL>(B($B%+%J(B)
         , flvq.job_duty_name                      AS job_duty_name1      -- $BLr?&L>(B1
         , flvp.job_duty_name                      AS job_duty_name2      -- $BLr?&L>(B2
         , NVL( flvq.un_licence_kbn ,cv_flag_n )   AS un_licence_kbn      -- $B@=IJ%i%$%;%s%9ITMW6hJ,(B
         , hp.party_name                           AS location_name       -- $BIt=pL>(B
         , papf.attribute28                        AS location_code       -- $BIt=pHV9f(B
         , SUBSTRB( hl.postal_code ,1 ,3 )
             || cv_hyphen
             || SUBSTRB( hl.postal_code ,4 ,4 )    AS postal_code         -- $BM9JXHV9f(B
         , hl.state
             || hl.city
             || hl.address1
             || hl.address2                        AS address             -- $B=;=j(B
         , jrrr.start_date_active                  AS start_date_active   -- $B%j%=!<%9%0%k!<%WLr3d3+;OF|(B
         , ( CASE
               WHEN ppos.actual_termination_date IS NOT NULL THEN
                 cv_flag_n
               ELSE
                 jrrr.attribute1
             END )                                 AS emp_enabled_flag    -- $B=>6H0wM-8z%U%i%0(B
         , jrrr.attribute2                         AS main_work           -- $B<g6HL3(B
         , flvm.main_work_name                     AS main_work_name      -- $B<g6HL3L>(B
      FROM jtf_rs_resource_extns   jrse      -- $B%j%=!<%9%^%9%?(B
         , jtf_rs_group_members    jrgm      -- $B%j%=!<%9%0%k!<%W%a%s%P!<(B
         , jtf_rs_groups_vl        jrgv      -- $B%j%=!<%9%0%k!<%W(B
         , jtf_rs_role_relations   jrrr      -- $B%j%=!<%9%0%k!<%WLr3d(B
         , per_all_people_f        papf      -- $B=>6H0w%^%9%?(B
         , per_all_assignments_f   paaf      -- $B%"%5%$%a%s%H%^%9%?(B
         , per_periods_of_service  ppos      -- $B=>6H0w%5!<%S%94|4V%^%9%?(B
         , hz_cust_accounts        hca       -- $B8\5R%^%9%?(B
         , hz_parties              hp        -- $B%Q!<%F%#%^%9%?(B
         , hz_party_sites          hps       -- $B%Q!<%F%#%5%$%H%^%9%?(B
         , hz_cust_acct_sites_all  hcasa     -- $B8\5R=j:_CO%^%9%?(B
         , hz_locations            hl        -- $B8\5R;v6H=j%^%9%?(B
         , ( SELECT flv.lookup_code       AS qual_code
                  , flv.attribute1        AS job_duty_name
                  , flv.attribute2        AS un_licence_kbn
               FROM fnd_lookup_values flv
              WHERE flv.language     = ct_lang
                AND flv.lookup_type  = cv_lkp_qual_code      -- $B%?%$%W!';q3J%3!<%I(B
                AND flv.enabled_flag = cv_flag_y
           )                       flvq      -- LOOKUP$BI=(B($B;q3J(B)
         , ( SELECT flv.lookup_code       AS posi_code
                  , flv.attribute1        AS job_duty_name
               FROM fnd_lookup_values flv
              WHERE flv.language     = ct_lang
                AND flv.lookup_type  = cv_lkp_posi_code      -- $B%?%$%W!'?&0L%3!<%I(B
                AND flv.enabled_flag = cv_flag_y
           )                       flvp      -- LOOKUP$BI=(B($B?&0L(B)
         , ( SELECT flv.lookup_code       AS main_work
                  , flv.description       AS main_work_name
               FROM fnd_lookup_values flv
              WHERE flv.language     = ct_lang
                AND flv.lookup_type  = cv_lkp_main_work      -- $B%?%$%W!'(BeSM$B<g6HL3(B
                AND flv.enabled_flag = cv_flag_y
           )                       flvm      -- LOOKUP$BI=(B($B<g6HL3(B)
     WHERE jrse.category                       = cv_category_emp            -- $B%+%F%4%j!'=>6H0w(B
       AND jrse.resource_id                    = jrgm.resource_id
       AND NVL( jrgm.delete_flag ,cv_flag_n )  = cv_flag_n
       AND jrgm.group_id                       = jrgv.group_id
       AND jrgm.group_member_id                = jrrr.role_resource_id
       AND jrrr.role_resource_type             = cv_resource_type_gm
       AND NVL( jrrr.delete_flag ,cv_flag_n )  = cv_flag_n
       AND (
             -- $B%j%=!<%9%0%k!<%WLr3d$N3+;OF|(B
             ( jrrr.start_date_active         >= gd_active_s_date )
             -- $B%j%=!<%9%0%k!<%WLr3d$N:G=*99?7F|(B
         OR  ( TRUNC( jrrr.last_update_date ) >= gd_update_s_date
           AND TRUNC( jrrr.last_update_date ) <= gd_update_e_date )
             -- $B=>6H0w%^%9%?$N:G=*99?7F|(B
         OR  ( TRUNC( papf.last_update_date ) >= gd_update_s_date
           AND TRUNC( papf.last_update_date ) <= gd_update_e_date )
             -- $B%Q!<%F%#%^%9%?$N:G=*99?7F|(B
         OR  ( TRUNC( hp.last_update_date )   >= gd_update_s_date
           AND TRUNC( hp.last_update_date )   <= gd_update_e_date )
             -- $B8\5R;v6H=j%^%9%?$N:G=*99?7F|(B
         OR  ( TRUNC( hl.last_update_date )   >= gd_update_s_date
           AND TRUNC( hl.last_update_date )   <= gd_update_e_date )
           )
       AND jrrr.start_date_active             <= gd_active_e_date
       AND jrse.source_id                      = papf.person_id
       AND papf.person_id                      = paaf.person_id
       AND paaf.period_of_service_id           = ppos.period_of_service_id
       AND papf.effective_start_date           = ppos.date_start
       AND papf.attribute28                    = ( CASE
                                                     WHEN ppos.actual_termination_date IS NOT NULL THEN
                                                       papf.attribute28
                                                     ELSE
                                                       jrgv.attribute1
                                                   END )
       AND gd_process_date                     BETWEEN papf.effective_start_date
                                                   AND TO_DATE( cv_max_date ,cv_fmt_std )
       AND gd_process_date                     BETWEEN paaf.effective_start_date
                                                   AND TO_DATE( cv_max_date ,cv_fmt_std )
       AND hca.customer_class_code             = cv_cust_class_base         -- $B8\5R6hJ,!'5rE@(B
       AND hca.cust_account_id                 = hcasa.cust_account_id
       AND hca.party_id                        = hp.party_id
       AND hcasa.party_site_id                 = hps.party_site_id
       AND hps.location_id                     = hl.location_id
       AND hcasa.org_id                        = gt_org_id                  -- $B1D6HC10L(BID
       AND hca.account_number                  = papf.attribute28           -- $B=jB0ItLg(B
       AND papf.attribute7                     = flvq.qual_code             -- $B;q3J%3!<%I(B
       AND papf.attribute11                    = flvp.posi_code             -- $B?&0L%3!<%I(B
       AND jrrr.attribute2                     = flvm.main_work(+)          -- $B<g6HL3(B
       AND jrrr.attribute1                     IS NOT NULL
    ORDER BY
           papf.employee_number    ASC    -- $B=>6H0wHV9f(B
         , jrrr.start_date_active  DESC   -- $B3+;OF|!J9_=g!K(B
         , jrrr.last_update_date   DESC   -- $B:G=*99?7F|!J9_=g!K(B
    ;
--
  TYPE g_emp_data_ttype IS TABLE OF get_emp_data_cur%ROWTYPE INDEX BY PLS_INTEGER;
  gt_emp_data           g_emp_data_ttype;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : $B=i4|=hM}(B(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    iv_update_from  IN  VARCHAR2     --  $B:G=*99?7F|!J3+;O!K(B
  , iv_update_to    IN  VARCHAR2     --  $B:G=*99?7F|!J=*N;!K(B
  , ov_errbuf       OUT VARCHAR2     --  $B%(%i!<!&%a%C%;!<%8(B           --# $B8GDj(B #
  , ov_retcode      OUT VARCHAR2     --  $B%j%?!<%s!&%3!<%I(B             --# $B8GDj(B #
  , ov_errmsg       OUT VARCHAR2     --  $B%f!<%6!<!&%(%i!<!&%a%C%;!<%8(B --# $B8GDj(B #
  )
  IS
    -- ===============================
    -- $B8GDj%m!<%+%kDj?t(B
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'init'; -- $B%W%m%0%i%`L>(B
--
--#####################  $B8GDj%m!<%+%kJQ?t@k8@It(B START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- $B%(%i!<!&%a%C%;!<%8(B
    lv_retcode VARCHAR2(1);     -- $B%j%?!<%s!&%3!<%I(B
    lv_errmsg  VARCHAR2(5000);  -- $B%f!<%6!<!&%(%i!<!&%a%C%;!<%8(B
--
--###########################  $B8GDjIt(B END   ####################################
--
    -- ===============================
    -- $B%f!<%6!<@k8@It(B
    -- ===============================
    -- *** $B%m!<%+%kDj?t(B ***
--
    -- *** $B%m!<%+%kJQ?t(B ***
    lb_fexists              BOOLEAN;          -- $B%U%!%$%k$,B8:_$9$k$+$I$&$+(B
    ln_file_length          NUMBER;           -- $B%U%!%$%kD9(B
    ln_block_size           NUMBER;           -- $B%V%m%C%/%5%$%:(B
--
    -- *** $B%m!<%+%k!&%+!<%=%k(B ***
--
    -- *** $B%m!<%+%k!&%l%3!<%I(B ***
--
  BEGIN
--
--##################  $B8GDj%9%F!<%?%9=i4|2=It(B START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  $B8GDjIt(B END   ############################
--
    --================================
    -- $BF~NO%Q%i%a!<%?=PNO(B
    --================================
    lv_errmsg := xxccp_common_pkg.get_msg(
                   iv_application  => cv_appl_xxcmm             -- $B%"%W%j%1!<%7%g%sC;=LL>(B
                 , iv_name         => cv_input_param_msg        -- $B%a%C%;!<%8%3!<%I(B
                 , iv_token_name1  => cv_tkn_date_from          -- $B%H!<%/%s%3!<%I(B1
                 , iv_token_value1 => iv_update_from            -- $B%H!<%/%sCM(B1
                 , iv_token_name2  => cv_tkn_date_to            -- $B%H!<%/%s%3!<%I(B2
                 , iv_token_value2 => iv_update_to              -- $B%H!<%/%sCM(B2
                 );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_errmsg
    );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => lv_errmsg
    );
--
    -- $B6u9TA^F~(B
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    -- $B6u9TA^F~(B
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
--
    --================================
    -- $B6HL3F|IU<hF@(B
    --================================
    gd_process_date := xxccp_common_pkg2.get_process_date;
    -- $B6HL3F|IU$,<hF@$G$-$J$$>l9g(B
    IF ( gd_process_date IS NULL ) THEN
      -- $B6HL3F|IU<hF@%(%i!<%a%C%;!<%8(B
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application => cv_appl_xxcmm            -- $B%"%W%j%1!<%7%g%sC;=LL>(B
                   , iv_name        => cv_process_date_err_msg  -- $B%a%C%;!<%8%3!<%I(B
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_init_err_expt;
    END IF;
--
    --================================
    -- $B=hM}4|4V!J3+;OF|!&=*N;F|!K<hF@(B
    --================================
    IF  ( iv_update_from IS NULL )
      AND ( iv_update_to IS NULL ) THEN
      -- $BE,MQF|!J3+;O!K!"E,MQF|!J=*N;!K$K6HL3F|IU!\(B1$B$r%;%C%H(B
      gd_active_s_date := gd_process_date + 1;
      gd_active_e_date := gd_process_date + 1;
      -- $B:G=*99?7F|!J3+;O!K!":G=*99?7F|!J=*N;!K$K6HL3F|IU$r%;%C%H(B
      gd_update_s_date := gd_process_date;
      gd_update_e_date := gd_process_date + 1;
    ELSE
      -- $BE,MQF|!J3+;O!K!"E,MQF|!J=*N;!K$KF~NO%Q%i%a!<%?CM$r%;%C%H(B
      gd_active_s_date := TO_DATE( iv_update_from ,cv_fmt_std );
      gd_active_e_date := TO_DATE( iv_update_to   ,cv_fmt_std );
      -- $B:G=*99?7F|$KE,MQF|$HF1$8CM$r%;%C%H(B
      gd_update_s_date := gd_active_s_date;
      gd_update_e_date := gd_active_e_date;
    END IF;
--
    --================================
    -- $B=hM}BP>]4|4V%A%'%C%/(B
    --================================
    -- $B:G=*99?7F|!J3+;O!K(B > $B:G=*99?7F|!J=*N;!K$N>l9g(B
    IF ( gd_update_s_date > gd_update_e_date ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_xxcmm               -- $B%"%W%j%1!<%7%g%sC;=LL>(B
                   , iv_name         => cv_date_reversal_err_msg    -- $B%a%C%;!<%8%3!<%I(B
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_init_err_expt;
    END IF;
--
    --================================
    -- $B=*N;F|%A%'%C%/(B
    --================================
    -- $BF~NO%Q%i%a!<%?(B.$B:G=*99?7F|!J=*N;!K(B $B!b(B $B6HL3F|IU$N>l9g(B
    IF ( TO_DATE( iv_update_to ,cv_fmt_std ) <> gd_process_date ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_xxcmm               -- $B%"%W%j%1!<%7%g%sC;=LL>(B
                   , iv_name         => cv_e_date_select_err_msg    -- $B%a%C%;!<%8%3!<%I(B
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_init_err_expt;
    END IF;
--
    --================================
    -- $B%W%m%U%!%$%kCM<hF@(B
    --================================
    -- *******************************
    --  $B1D6HC10L(B
    -- *******************************
    gt_org_id := FND_PROFILE.VALUE( cv_prf_org_id );
    -- $B<hF@CM$,(BNULL$B$N>l9g(B
    IF ( gt_org_id IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_xxcmm           -- $B%"%W%j%1!<%7%g%sC;=LL>(B
                   , iv_name         => cv_profile_err_msg      -- $B%a%C%;!<%8%3!<%I(B
                   , iv_token_name1  => cv_tkn_ng_profile       -- $B%H!<%/%s%3!<%I(B1
                   , iv_token_value1 => cv_prf_org_id           -- $B%H!<%/%sCM(B1
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_init_err_expt;
    END IF;
--
    -- *******************************
    --  CSV$B%U%!%$%k=PNO@h(B
    -- *******************************
    gv_out_file_dir := FND_PROFILE.VALUE( cv_prf_out_file_dir );
    -- $B<hF@CM$,(BNULL$B$N>l9g(B
    IF ( gv_out_file_dir IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_xxcmm           -- $B%"%W%j%1!<%7%g%sC;=LL>(B
                   , iv_name         => cv_profile_err_msg      -- $B%a%C%;!<%8%3!<%I(B
                   , iv_token_name1  => cv_tkn_ng_profile       -- $B%H!<%/%s%3!<%I(B1
                   , iv_token_value1 => cv_prf_out_file_dir     -- $B%H!<%/%sCM(B1
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_init_err_expt;
    END IF;
--
    -- *******************************
    --  CSV$B%U%!%$%kL>(B
    -- *******************************
    gv_out_file_name := FND_PROFILE.VALUE( cv_prf_out_file_name );
    -- $B<hF@CM$,(BNULL$B$N>l9g(B
    IF ( gv_out_file_name IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_xxcmm           -- $B%"%W%j%1!<%7%g%sC;=LL>(B
                   , iv_name         => cv_profile_err_msg      -- $B%a%C%;!<%8%3!<%I(B
                   , iv_token_name1  => cv_tkn_ng_profile       -- $B%H!<%/%s%3!<%I(B1
                   , iv_token_value1 => cv_prf_out_file_name    -- $B%H!<%/%sCM(B1
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_init_err_expt;
    END IF;
--
    -- *******************************
    --  $BMxMQDd;_It=p(B
    -- *******************************
    gv_stop_bumon := FND_PROFILE.VALUE( cv_prf_stop_bumon );
    -- $B<hF@CM$,(BNULL$B$N>l9g(B
    IF ( gv_stop_bumon IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_xxcmm           -- $B%"%W%j%1!<%7%g%sC;=LL>(B
                   , iv_name         => cv_profile_err_msg      -- $B%a%C%;!<%8%3!<%I(B
                   , iv_token_name1  => cv_tkn_ng_profile       -- $B%H!<%/%s%3!<%I(B1
                   , iv_token_value1 => cv_prf_stop_bumon       -- $B%H!<%/%sCM(B1
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_init_err_expt;
    END IF;
--
    -- *******************************
    --  $BB>$NC4Ev6HL3!JK\It1D6H!K(B
    -- *******************************
    gv_other_wk_honbu := FND_PROFILE.VALUE( cv_prf_other_wk_honbu );
    -- $B<hF@CM$,(BNULL$B$N>l9g(B
    IF ( gv_other_wk_honbu IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_xxcmm           -- $B%"%W%j%1!<%7%g%sC;=LL>(B
                   , iv_name         => cv_profile_err_msg      -- $B%a%C%;!<%8%3!<%I(B
                   , iv_token_name1  => cv_tkn_ng_profile       -- $B%H!<%/%s%3!<%I(B1
                   , iv_token_value1 => cv_prf_other_wk_honbu   -- $B%H!<%/%sCM(B1
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_init_err_expt;
    END IF;
--
    -- *******************************
    --  $BB>$NC4Ev6HL3!JE9J^1D6H!K(B
    -- *******************************
    gv_other_wk_tenpo := FND_PROFILE.VALUE( cv_prf_other_wk_tenpo );
    -- $B<hF@CM$,(BNULL$B$N>l9g(B
    IF ( gv_other_wk_tenpo IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_xxcmm           -- $B%"%W%j%1!<%7%g%sC;=LL>(B
                   , iv_name         => cv_profile_err_msg      -- $B%a%C%;!<%8%3!<%I(B
                   , iv_token_name1  => cv_tkn_ng_profile       -- $B%H!<%/%s%3!<%I(B1
                   , iv_token_value1 => cv_prf_other_wk_tenpo   -- $B%H!<%/%sCM(B1
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_init_err_expt;
    END IF;
--
    -- *******************************
    --  $BB>$NC4Ev6HL3!J<RFb6HL3!K(B
    -- *******************************
    gv_other_wk_shanai := FND_PROFILE.VALUE( cv_prf_other_wk_shanai );
    -- $B<hF@CM$,(BNULL$B$N>l9g(B
    IF ( gv_other_wk_shanai IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_xxcmm           -- $B%"%W%j%1!<%7%g%sC;=LL>(B
                   , iv_name         => cv_profile_err_msg      -- $B%a%C%;!<%8%3!<%I(B
                   , iv_token_name1  => cv_tkn_ng_profile       -- $B%H!<%/%s%3!<%I(B1
                   , iv_token_value1 => cv_prf_other_wk_shanai  -- $B%H!<%/%sCM(B1
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_init_err_expt;
    END IF;
--
    -- *******************************
    --  $B%i%$%;%s%9$9$k@=IJ(B
    -- *******************************
    gv_licensed_prdcts := FND_PROFILE.VALUE( cv_prf_licensed_prdcts );
    -- $B<hF@CM$,(BNULL$B$N>l9g(B
    IF ( gv_licensed_prdcts IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_xxcmm           -- $B%"%W%j%1!<%7%g%sC;=LL>(B
                   , iv_name         => cv_profile_err_msg      -- $B%a%C%;!<%8%3!<%I(B
                   , iv_token_name1  => cv_tkn_ng_profile       -- $B%H!<%/%s%3!<%I(B1
                   , iv_token_value1 => cv_prf_licensed_prdcts  -- $B%H!<%/%sCM(B1
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_init_err_expt;
    END IF;
--
    -- *******************************
    --  $B%?%$%`%>!<%s(B
    -- *******************************
    gv_timezone := FND_PROFILE.VALUE( cv_prf_timezone );
    -- $B<hF@CM$,(BNULL$B$N>l9g(B
    IF ( gv_timezone IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_xxcmm           -- $B%"%W%j%1!<%7%g%sC;=LL>(B
                   , iv_name         => cv_profile_err_msg      -- $B%a%C%;!<%8%3!<%I(B
                   , iv_token_name1  => cv_tkn_ng_profile       -- $B%H!<%/%s%3!<%I(B1
                   , iv_token_value1 => cv_prf_timezone         -- $B%H!<%/%sCM(B1
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_init_err_expt;
    END IF;
--
    -- *******************************
    --  $BF|IU%U%)!<%^%C%H(B
    -- *******************************
    gv_date_format := FND_PROFILE.VALUE( cv_prf_date_format );
    -- $B<hF@CM$,(BNULL$B$N>l9g(B
    IF ( gv_date_format IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_xxcmm           -- $B%"%W%j%1!<%7%g%sC;=LL>(B
                   , iv_name         => cv_profile_err_msg      -- $B%a%C%;!<%8%3!<%I(B
                   , iv_token_name1  => cv_tkn_ng_profile       -- $B%H!<%/%s%3!<%I(B1
                   , iv_token_value1 => cv_prf_date_format      -- $B%H!<%/%sCM(B1
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_init_err_expt;
    END IF;
--
    -- *******************************
    --  $B8@8l(B
    -- *******************************
    gv_language := FND_PROFILE.VALUE( cv_prf_language );
    -- $B<hF@CM$,(BNULL$B$N>l9g(B
    IF ( gv_language IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_xxcmm           -- $B%"%W%j%1!<%7%g%sC;=LL>(B
                   , iv_name         => cv_profile_err_msg      -- $B%a%C%;!<%8%3!<%I(B
                   , iv_token_name1  => cv_tkn_ng_profile       -- $B%H!<%/%s%3!<%I(B1
                   , iv_token_value1 => cv_prf_language         -- $B%H!<%/%sCM(B1
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_init_err_expt;
    END IF;
--
    -- *******************************
    --  $B5YF|%Q%?!<%s(B
    -- *******************************
    gv_holiday_pattern := FND_PROFILE.VALUE( cv_prf_holiday_pattern );
    -- $B<hF@CM$,(BNULL$B$N>l9g(B
    IF ( gv_holiday_pattern IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_xxcmm           -- $B%"%W%j%1!<%7%g%sC;=LL>(B
                   , iv_name         => cv_profile_err_msg      -- $B%a%C%;!<%8%3!<%I(B
                   , iv_token_name1  => cv_tkn_ng_profile       -- $B%H!<%/%s%3!<%I(B1
                   , iv_token_value1 => cv_prf_holiday_pattern  -- $B%H!<%/%sCM(B1
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_init_err_expt;
    END IF;
--
    -- *******************************
    --  $B%m!<%k(B
    -- *******************************
    gv_role := FND_PROFILE.VALUE( cv_prf_role );
    -- $B<hF@CM$,(BNULL$B$N>l9g(B
    IF ( gv_role IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_xxcmm           -- $B%"%W%j%1!<%7%g%sC;=LL>(B
                   , iv_name         => cv_profile_err_msg      -- $B%a%C%;!<%8%3!<%I(B
                   , iv_token_name1  => cv_tkn_ng_profile       -- $B%H!<%/%s%3!<%I(B1
                   , iv_token_value1 => cv_prf_role             -- $B%H!<%/%sCM(B1
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_init_err_expt;
    END IF;
--
    --================================
    -- CSV$B%U%!%$%kL>=PNO(B
    --================================
    lv_errmsg := xxccp_common_pkg.get_msg(
                   iv_application  => cv_appl_xxccp             -- $B%"%W%j%1!<%7%g%sC;=LL>(B
                 , iv_name         => cv_file_name_msg          -- $B%a%C%;!<%8%3!<%I(B
                 , iv_token_name1  => cv_tkn_file_name          -- $B%H!<%/%s%3!<%I(B1
                 , iv_token_value1 => gv_out_file_name          -- $B%H!<%/%sCM(B1
                 );
    FND_FILE.PUT_LINE(
      which  => FND_FILE.OUTPUT
    , buff   => lv_errmsg
    );
--
    --================================
    -- CSV$B%U%!%$%kB8:_%A%'%C%/(B
    --================================
    UTL_FILE.FGETATTR(
      location     => gv_out_file_dir     -- CSV$B%U%!%$%k=PNO@h(B
    , filename     => gv_out_file_name    -- CSV$B%U%!%$%kL>(B
    , fexists      => lb_fexists
    , file_length  => ln_file_length
    , block_size   => ln_block_size
    );
    IF ( lb_fexists = TRUE ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application => cv_appl_xxcmm             -- $B%"%W%j%1!<%7%g%sC;=LL>(B
                   , iv_name        => cv_file_exists_err_msg    -- $B%a%C%;!<%8%3!<%I(B
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_init_err_expt;
    END IF;
--
    -- $B6u9TA^F~(B
    FND_FILE.PUT_LINE(
      which  => FND_FILE.OUTPUT
    , buff   => ''
    );
--
  EXCEPTION
    --*** $B=i4|=hM}Nc30(B ***
    WHEN global_init_err_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  $B8GDjNc30=hM}It(B START   ####################################
--
    -- *** $B6&DL4X?t(BOTHERS$BNc30%O%s%I%i(B ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS$BNc30%O%s%I%i(B ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  $B8GDjIt(B END   ##########################################
--
  END init;
--
  /**********************************************************************************
   * Procedure Name   : open_csv_file
   * Description      : $B%U%!%$%k%*!<%W%s=hM}(B(A-2)
   ***********************************************************************************/
  PROCEDURE open_csv_file(
    ov_errbuf       OUT VARCHAR2             --   $B%(%i!<!&%a%C%;!<%8(B                  --# $B8GDj(B #
  , ov_retcode      OUT VARCHAR2             --   $B%j%?!<%s!&%3!<%I(B                    --# $B8GDj(B #
  , ov_errmsg       OUT VARCHAR2             --   $B%f!<%6!<!&%(%i!<!&%a%C%;!<%8(B        --# $B8GDj(B #
  )
  IS
    -- ===============================
    -- $B8GDj%m!<%+%kDj?t(B
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'open_csv_file'; -- $B%W%m%0%i%`L>(B
--
--#######################  $B8GDj%m!<%+%kJQ?t@k8@It(B START   ######################
--
    lv_errbuf  VARCHAR2(5000);  -- $B%(%i!<!&%a%C%;!<%8(B
    lv_retcode VARCHAR2(1);     -- $B%j%?!<%s!&%3!<%I(B
    lv_errmsg  VARCHAR2(5000);  -- $B%f!<%6!<!&%(%i!<!&%a%C%;!<%8(B
--
--###########################  $B8GDjIt(B END   ####################################
--
    -- ===============================
    -- $B%f!<%6!<@k8@It(B
    -- ===============================
    -- *** $B%m!<%+%kDj?t(B ***
    cn_record_byte  CONSTANT NUMBER       := 5000;  -- $B%U%!%$%kFI$_9~$_J8;z?t(B
    cv_file_mode    CONSTANT VARCHAR2(1)  := 'W';   -- $B=q$-9~$_%b!<%I(B
--
    -- *** $B%m!<%+%kJQ?t(B ***
--
  BEGIN
--
--##################  $B8GDj%9%F!<%?%9=i4|2=It(B START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  $B8GDjIt(B END   ############################
--
    BEGIN
      --================================
      -- $B%U%!%$%k%*!<%W%s(B
      --================================
      gf_file_handler := UTL_FILE.FOPEN(
                           location      => gv_out_file_dir      -- CSV$B%U%!%$%k=PNO@h(B
                         , filename      => gv_out_file_name     -- CSV$B%U%!%$%kL>(B
                         , open_mode     => cv_file_mode         -- $B=q$-9~$_%b!<%I(B
                         , max_linesize  => cn_record_byte
                         );
    EXCEPTION
      -- $B%U%!%$%k%*!<%W%s%(%i!<(B
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_xxcmm              -- $B%"%W%j%1!<%7%g%sC;=LL>(B
                     , iv_name         => cv_file_open_err_msg       -- $B%a%C%;!<%8%3!<%I(B
                     , iv_token_name1  => cv_tkn_sqlerrm             -- $B%H!<%/%s%3!<%I(B1
                     , iv_token_value1 => SQLERRM                    -- $B%H!<%/%sCM(B1
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_f_open_err_expt;
    END;
--
  EXCEPTION
    --*** $B%U%!%$%k%*!<%W%s%(%i!<(B ***
    WHEN global_f_open_err_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  $B8GDjNc30=hM}It(B START   ####################################
--
    -- *** $B=hM}It6&DLNc30%O%s%I%i(B ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** $B6&DL4X?tNc30%O%s%I%i(B ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** $B6&DL4X?t(BOTHERS$BNc30%O%s%I%i(B ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS$BNc30%O%s%I%i(B ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  $B8GDjIt(B END   ##########################################
--
  END open_csv_file;
--
  /**********************************************************************************
   * Procedure Name   : get_emp_data
   * Description      : $B=>6H0w%G!<%?<hF@=hM}(B(A-3)
   ***********************************************************************************/
  PROCEDURE get_emp_data(
    ov_errbuf     OUT VARCHAR2     --   $B%(%i!<!&%a%C%;!<%8(B           --# $B8GDj(B #
  , ov_retcode    OUT VARCHAR2     --   $B%j%?!<%s!&%3!<%I(B             --# $B8GDj(B #
  , ov_errmsg     OUT VARCHAR2     --   $B%f!<%6!<!&%(%i!<!&%a%C%;!<%8(B --# $B8GDj(B #
  )
  IS
    -- ===============================
    -- $B8GDj%m!<%+%kDj?t(B
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_emp_data';       -- $B%W%m%0%i%`L>(B
--
--#####################  $B8GDj%m!<%+%kJQ?t@k8@It(B START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- $B%(%i!<!&%a%C%;!<%8(B
    lv_retcode VARCHAR2(1);     -- $B%j%?!<%s!&%3!<%I(B
    lv_errmsg  VARCHAR2(5000);  -- $B%f!<%6!<!&%(%i!<!&%a%C%;!<%8(B
--
--###########################  $B8GDjIt(B END   ####################################
--
    -- ===============================
    -- $B%f!<%6!<@k8@It(B
    -- ===============================
    -- *** $B%m!<%+%kDj?t(B ***
--
    -- *** $B%m!<%+%kJQ?t(B ***
--
    -- *** $B%m!<%+%k!&%+!<%=%k(B ***
--
  BEGIN
--
--##################  $B8GDj%9%F!<%?%9=i4|2=It(B START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  $B8GDjIt(B END   ############################
--
    -- ***************************************
    -- ***        $B<B=hM}$N5-=R(B             ***
    -- ***       $B6&DL4X?t$N8F$S=P$7(B        ***
    -- ***************************************
--
    -- $B%+!<%=%k%*!<%W%s(B
    OPEN get_emp_data_cur;
    FETCH get_emp_data_cur BULK COLLECT INTO gt_emp_data;
--
    -- $BBP>]7o?t%+%&%s%H(B
    gn_target_cnt := gt_emp_data.COUNT;
--
    -- $B%+!<%=%k%/%m!<%:(B
    CLOSE get_emp_data_cur;
--
  EXCEPTION
--
--#################################  $B8GDjNc30=hM}It(B START   ####################################
--
    -- *** $B6&DL4X?tNc30%O%s%I%i(B ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** $B6&DL4X?t(BOTHERS$BNc30%O%s%I%i(B ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS$BNc30%O%s%I%i(B ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  $B8GDjIt(B END   ##########################################
--
  END get_emp_data;
--
  /**********************************************************************************
   * Procedure Name   : output_csv_data
   * Description      : CSV$B%U%!%$%k=PNO=hM}(B(A-4)
   ***********************************************************************************/
  PROCEDURE output_csv_data(
    ov_errbuf               OUT VARCHAR2               --   $B%(%i!<!&%a%C%;!<%8(B                  --# $B8GDj(B #
  , ov_retcode              OUT VARCHAR2               --   $B%j%?!<%s!&%3!<%I(B                    --# $B8GDj(B #
  , ov_errmsg               OUT VARCHAR2               --   $B%f!<%6!<!&%(%i!<!&%a%C%;!<%8(B        --# $B8GDj(B #
  )
  IS
    -- ===============================
    -- $B8GDj%m!<%+%kDj?t(B
    -- ===============================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'output_csv_data'; -- $B%W%m%0%i%`L>(B
--
--#######################  $B8GDj%m!<%+%kJQ?t@k8@It(B START   ######################
--
    lv_errbuf  VARCHAR2(5000);  -- $B%(%i!<!&%a%C%;!<%8(B
    lv_retcode VARCHAR2(1);     -- $B%j%?!<%s!&%3!<%I(B
    lv_errmsg  VARCHAR2(5000);  -- $B%f!<%6!<!&%(%i!<!&%a%C%;!<%8(B
--
--###########################  $B8GDjIt(B END   ####################################
--
    -- ===============================
    -- $B%f!<%6!<@k8@It(B
    -- ===============================
    -- *** $B%m!<%+%kDj?t(B ***
--
    -- *** $B%m!<%+%kJQ?t(B ***
    ln_cnt                 NUMBER;               -- $B%k!<%W%+%&%s%?(B
    lv_hdr_text            VARCHAR2(2000);       -- $B%X%C%@J8;zNs3JG<MQJQ?t(B
    lv_csv_text            VARCHAR2(5000);       -- $B=PNOJ8;zNs3JG<MQJQ?t(B
--
    lt_employee_number     per_all_people_f.employee_number%TYPE;
                                                 -- $B=>6H0wHV9fB`HrMQ(B
    lv_job_duty_name       VARCHAR2(100);        -- $BLr?&L>(B
    lv_location_name       VARCHAR2(50);         -- $BIt=pL>(B
    lv_location_code       VARCHAR2(9);          -- $BIt=pHV9f(B
    lv_other_work          VARCHAR2(500);        -- $BB>$NC4Ev6HL3(B
    lv_licensed_prdcts     VARCHAR2(500);        -- $B%i%$%;%s%9$9$k@=IJ(B
    lv_role                VARCHAR2(500);        -- $B%m!<%k(B
--
  BEGIN
--
--##################  $B8GDj%9%F!<%?%9=i4|2=It(B START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  $B8GDjIt(B END   ############################
--
    BEGIN
--
      -- $B%m!<%+%kJQ?t$N=i4|2=(B
      lt_employee_number := NULL;  -- $B=>6H0wHV9fB`HrMQ(B
--
      -- ===============================
      -- CSV$B%U%!%$%k%X%C%@<hF@(B
      -- ===============================
      lv_hdr_text := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_xxcmm       -- $B%"%W%j%1!<%7%g%sC;=LL>(B
                     , iv_name         => cv_csv_header_msg   -- $B%a%C%;!<%8%3!<%I(B
                     );
--
      -- ===============================
      -- CSV$B%U%!%$%k%X%C%@=PNO(B
      -- ===============================
      -- $B%U%!%$%k=q$-9~$_(B
      UTL_FILE.PUT_LINE(
        file      => gf_file_handler
      , buffer    => lv_hdr_text
      , autoflush => FALSE
      );
--
      -- ===============================
      -- $B=>6H0w%G!<%?=PNO(B
      -- ===============================
      -- $BBP>]%l%3!<%I$,B8:_$9$k>l9g(B
      IF ( gn_target_cnt > 0 ) THEN
--
        <<emp_data_loop>>
        FOR ln_cnt IN gt_emp_data.FIRST..gt_emp_data.LAST LOOP
--
          -- *******************************
          --  $B<g6HL3(BNULL$B%A%'%C%/(B
          -- *******************************
          IF ( gt_emp_data(ln_cnt).main_work IS NULL ) THEN
--
           -- eSM$B<g6HL3L$@_Dj%(%i!<(B
            lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_appl_xxcmm                         -- $B%"%W%j%1!<%7%g%sC;=LL>(B
                         , iv_name         => cv_main_work_err_msg                  -- $B%a%C%;!<%8%3!<%I(B
                         , iv_token_name1  => cv_tkn_employee_number                -- $B%H!<%/%s%3!<%I(B1
                         , iv_token_value1 => gt_emp_data(ln_cnt).employee_number   -- $B%H!<%/%sCM(B1
                         , iv_token_name2  => cv_tkn_start_date_active              -- $B%H!<%/%s%3!<%I(B2
                         , iv_token_value2 => TO_CHAR( gt_emp_data(ln_cnt).start_date_active ,cv_fmt_std )
                                                                                    -- $B%H!<%/%sCM(B2
                         );
            -- $B%a%C%;!<%8=PNO(B
            FND_FILE.PUT_LINE(
              which  => FND_FILE.OUTPUT
            , buff   => lv_errmsg --$B%f!<%6!<!&%(%i!<%a%C%;!<%8(B
            );
            -- $B%9%-%C%W7o?t%+%&%s%H(B
            gn_warn_cnt := gn_warn_cnt + 1;
--
          -- $B>e5-0J30$N>l9g(B
          ELSE
--
            -- *******************************
            --  $B%j%=!<%9%0%k!<%WLr3d=EJ#%A%'%C%/(B
            -- *******************************
            -- $B:G=i$N%l%3!<%I!"$^$?$OA0%l%3!<%I$H=>6H0wHV9f$,0[$J$k>l9g(B
            IF ( lt_employee_number IS NULL )
              OR ( lt_employee_number <> gt_emp_data(ln_cnt).employee_number ) THEN
--
              -- $B%m!<%+%kJQ?t$N=i4|2=(B
              lv_job_duty_name   := NULL;  -- $BLr?&L>(B
              lv_location_name   := NULL;  -- $BIt=pL>(B
              lv_location_code   := NULL;  -- $BIt=pHV9f(B
              lv_other_work      := NULL;  -- $BB>$NC4Ev6HL3(B
              lv_licensed_prdcts := NULL;  -- $B%i%$%;%s%9$9$k@=IJ(B
              lv_role            := NULL;  -- $B%m!<%k(B
--
              -- *******************************
              --  CSV$B=PNOCM@_Dj(B
              -- *******************************
              -- $BLr?&(B1$B$,(BNULL$B0J30$N>l9g(B
              IF ( gt_emp_data(ln_cnt).job_duty_name1 IS NOT NULL ) THEN
                -- $BLr?&L>(B
                lv_job_duty_name   := SUBSTRB ( gt_emp_data(ln_cnt).job_duty_name1 ,1 ,100 );
              ELSE
                -- $BLr?&L>(B
                lv_job_duty_name   := SUBSTRB ( gt_emp_data(ln_cnt).job_duty_name2 ,1 ,100 );
              END IF;
--
              -- $BM-8z$J<R0w$N>l9g(B
              IF ( gt_emp_data(ln_cnt).emp_enabled_flag = cv_flag_y ) THEN
                -- $BIt=pL>(B
                lv_location_name   := SUBSTRB ( REPLACE( gt_emp_data(ln_cnt).location_name ,cv_comma ,NULL ) ,1 ,50 );
                -- $BIt=pHV9f(B
                lv_location_code   := gt_emp_data(ln_cnt).location_code;
                -- $B%i%$%;%s%9$9$k@=IJ(B
                lv_licensed_prdcts := gv_licensed_prdcts;
                -- $B%m!<%k(B
                lv_role            := gv_role;
              ELSE
                -- $BIt=pL>(B
                lv_location_name   := NULL;
                -- $BIt=pHV9f(B
                lv_location_code   := gv_stop_bumon;
                -- $B%i%$%;%s%9$9$k@=IJ(B
                lv_licensed_prdcts := NULL;
                -- $B%m!<%k(B
                lv_role            := NULL;
              END IF;
--
              -- $B%i%$%;%s%9ITMW$N>l9g(B
              IF ( gt_emp_data(ln_cnt).un_licence_kbn = cv_flag_y ) THEN
                -- $B%i%$%;%s%9$9$k@=IJ(B
                lv_licensed_prdcts := NULL;
              END IF;
--
              -- $B<g6HL3$,!VK\It1D6H!W$N>l9g(B
              IF ( gt_emp_data(ln_cnt).main_work = cv_main_wk_honbu ) THEN
                -- $BB>$NC4Ev6HL3(B
                lv_other_work      := gv_other_wk_honbu;
              -- $B<g6HL3$,!VE9J^1D6H!W$N>l9g(B
              ELSIF ( gt_emp_data(ln_cnt).main_work = cv_main_wk_tenpo ) THEN
                -- $BB>$NC4Ev6HL3(B
                lv_other_work      := gv_other_wk_tenpo;
              -- $B<g6HL3$,!V<RFb6HL3!W$N>l9g(B
              ELSIF ( gt_emp_data(ln_cnt).main_work = cv_main_wk_shanai ) THEN
                -- $BB>$NC4Ev6HL3(B
                lv_other_work      := gv_other_wk_shanai;
              ELSE
                -- $BB>$NC4Ev6HL3(B
                lv_other_work      := NULL;
              END IF;
--
              -- *******************************
              --  $B=PNOJ8;zNs$N@8@.(B
              -- *******************************
              lv_csv_text :=   SUBSTRB( gt_emp_data(ln_cnt).employee_number ,1 ,50 )  -- $B<R0wHV9f(B
                || cv_comma || SUBSTRB( REPLACE( gt_emp_data(ln_cnt).employee_name ,cv_comma ,NULL ) ,1 ,100 )
                                                                                      -- $B<R0w;aL>(B
                || cv_comma || SUBSTRB( REPLACE( gt_emp_data(ln_cnt).employee_name_kana ,cv_comma ,NULL ) ,1 ,50 )
                                                                                      -- $B<R0w;aL>!J%+%J!K(B
                || cv_comma || lv_job_duty_name                                       -- $BLr?&L>(B
                || cv_comma || lv_location_name                                       -- $BIt=pL>(B
                || cv_comma || lv_location_code                                       -- $BIt=pHV9f(B
                || cv_comma || gt_emp_data(ln_cnt).postal_code                        -- $BM9JXHV9f(B
                || cv_comma || SUBSTRB( REPLACE( gt_emp_data(ln_cnt).address ,cv_comma ,NULL ) ,1 ,900 )
                                                                                      -- $B=;=j(B
                || cv_comma || NULL                                                   -- $BEEOCHV9f(B
                || cv_comma || NULL                                                   -- $BEEOCHV9f(B2
                || cv_comma || NULL                                                   -- $BEEOCHV9f(B3
                || cv_comma || NULL                                                   -- email
                || cv_comma || NULL                                                   -- $B%Q%9%o!<%I(B
                || cv_comma || SUBSTRB( gt_emp_data(ln_cnt).main_work_name ,1 ,60 )   -- $B<g6HL3(B
                || cv_comma || lv_other_work                                          -- $BB>$NC4Ev6HL3(B
                || cv_comma || lv_licensed_prdcts                                     -- $B%i%$%;%s%9$9$k@=IJ(B
                || cv_comma || NULL                                                   -- $B7HBSC<Kv(BID
                || cv_comma || gv_timezone                                            -- $B%?%$%`%>!<%s(B
                || cv_comma || gv_date_format                                         -- $BF|IU%U%)!<%^%C%H(B
                || cv_comma || gv_language                                            -- $B8@8l(B
                || cv_comma || gv_holiday_pattern                                     -- $B5YF|%Q%?!<%s(B
                || cv_comma || lv_role                                                -- $B%m!<%k(B
                || cv_comma || NULL                                                   -- $B7zJ*L>(B
                || cv_comma || NULL                                                   -- $B9V1i%;%_%J!<(B
              ;
--
              -- *******************************
              --  CSV$B%U%!%$%k=q$-9~$_(B
              -- *******************************
              UTL_FILE.PUT_LINE(
                file      => gf_file_handler
              , buffer    => lv_csv_text
              , autoflush => FALSE
              );
--
              -- $B@.8y7o?t%+%&%s%H(B
              gn_normal_cnt := gn_normal_cnt + 1;
              -- $B=>6H0wHV9fB`Hr(B
              lt_employee_number := gt_emp_data(ln_cnt).employee_number;
--
            -- $B>e5-0J30$N>l9g(B
            ELSE
              -- $B%j%=!<%9%0%k!<%WLr3d=EJ#%(%i!<(B
              lv_errmsg := xxccp_common_pkg.get_msg(
                             iv_application  => cv_appl_xxcmm                         -- $B%"%W%j%1!<%7%g%sC;=LL>(B
                           , iv_name         => cv_resource_err_msg                   -- $B%a%C%;!<%8%3!<%I(B
                           , iv_token_name1  => cv_tkn_employee_number                -- $B%H!<%/%s%3!<%I(B1
                           , iv_token_value1 => gt_emp_data(ln_cnt).employee_number   -- $B%H!<%/%sCM(B1
                           , iv_token_name2  => cv_tkn_start_date_active              -- $B%H!<%/%s%3!<%I(B2
                           , iv_token_value2 => TO_CHAR( gt_emp_data(ln_cnt).start_date_active ,cv_fmt_std )
                                                                                      -- $B%H!<%/%sCM(B2
                           );
              -- $B%a%C%;!<%8=PNO(B
              FND_FILE.PUT_LINE(
                which  => FND_FILE.OUTPUT
              , buff   => lv_errmsg --$B%f!<%6!<!&%(%i!<%a%C%;!<%8(B
              );
              -- $B%9%-%C%W7o?t%+%&%s%H(B
              gn_warn_cnt := gn_warn_cnt + 1;
            END IF;
--
          END IF;
--
        END LOOP emp_data_loop;
--
      END IF;
--
    EXCEPTION
      -- CSV$B%G!<%?=PNO%(%i!<(B
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_xxcmm             -- $B%"%W%j%1!<%7%g%sC;=LL>(B
                     , iv_name         => cv_file_write_err_msg     -- $B%a%C%;!<%8%3!<%I(B
                     , iv_token_name1  => cv_tkn_sqlerrm            -- $B%H!<%/%s%3!<%I(B1
                     , iv_token_value1 => SQLERRM                   -- $B%H!<%/%sCM(B1
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
--
    END;
--
  EXCEPTION
--
--#################################  $B8GDjNc30=hM}It(B START   ####################################
--
    -- *** $B=hM}It6&DLNc30%O%s%I%i(B ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** $B6&DL4X?tNc30%O%s%I%i(B ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** $B6&DL4X?t(BOTHERS$BNc30%O%s%I%i(B ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS$BNc30%O%s%I%i(B ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  $B8GDjIt(B END   ##########################################
--
  END output_csv_data;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : $B%a%$%s=hM}%W%m%7!<%8%c(B
   **********************************************************************************/
  PROCEDURE submain(
    ov_errbuf                 OUT VARCHAR2    -- $B%(%i!<!&%a%C%;!<%8(B           --# $B8GDj(B #
  , ov_retcode                OUT VARCHAR2    -- $B%j%?!<%s!&%3!<%I(B             --# $B8GDj(B #
  , ov_errmsg                 OUT VARCHAR2    -- $B%f!<%6!<!&%(%i!<!&%a%C%;!<%8(B --# $B8GDj(B #
  , iv_update_from            IN  VARCHAR2    -- $B:G=*99?7F|!J3+;O!K(B
  , iv_update_to              IN  VARCHAR2    -- $B:G=*99?7F|!J=*N;!K(B
  )
  IS
--
--#####################  $B8GDj%m!<%+%kDj?tJQ?t@k8@It(B START   ####################
--
    -- ===============================
    -- $B8GDj%m!<%+%kDj?t(B
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'submain'; -- $B%W%m%0%i%`L>(B
    -- ===============================
    -- $B%m!<%+%kJQ?t(B
    -- ===============================
    lv_errbuf  VARCHAR2(5000);  -- $B%(%i!<!&%a%C%;!<%8(B
    lv_retcode VARCHAR2(1);     -- $B%j%?!<%s!&%3!<%I(B
    lv_errmsg  VARCHAR2(5000);  -- $B%f!<%6!<!&%(%i!<!&%a%C%;!<%8(B
--
--###########################  $B8GDjIt(B END   ####################################
--
    -- ===============================
    -- $B%f!<%6!<@k8@It(B
    -- ===============================
    -- *** $B%m!<%+%kDj?t(B ***
--
    -- *** $B%m!<%+%kJQ?t(B ***
--
  BEGIN
--
--##################  $B8GDj%9%F!<%?%9=i4|2=It(B START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  $B8GDjIt(B END   ############################
--
    -- $B%0%m!<%P%kJQ?t$N=i4|2=(B
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_warn_cnt   := 0;
    gn_error_cnt  := 0;
--
    -- ===============================
    -- $B=i4|=hM}(B(A-1)
    -- ===============================
    init(
      iv_update_from     -- $B:G=*99?7F|!J3+;O!K(B
    , iv_update_to       -- $B:G=*99?7F|!J=*N;!K(B
    , lv_errbuf          -- $B%(%i!<!&%a%C%;!<%8(B           --# $B8GDj(B #
    , lv_retcode         -- $B%j%?!<%s!&%3!<%I(B             --# $B8GDj(B #
    , lv_errmsg          -- $B%f!<%6!<!&%(%i!<!&%a%C%;!<%8(B --# $B8GDj(B #
    );
    --
    IF ( lv_retcode = cv_status_error ) THEN
      -- $B%(%i!<=hM}(B
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- $B%U%!%$%k%*!<%W%s=hM}(B(A-2)
    -- ===============================
    open_csv_file(
      lv_errbuf          -- $B%(%i!<!&%a%C%;!<%8(B           --# $B8GDj(B #
    , lv_retcode         -- $B%j%?!<%s!&%3!<%I(B             --# $B8GDj(B #
    , lv_errmsg          -- $B%f!<%6!<!&%(%i!<!&%a%C%;!<%8(B --# $B8GDj(B #
    );
    --
    IF ( lv_retcode = cv_status_error ) THEN
      -- $B%(%i!<=hM}(B
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- $B=>6H0w%G!<%?<hF@=hM}(B(A-3)
    -- ===============================
    get_emp_data(
      lv_errbuf               -- $B%(%i!<!&%a%C%;!<%8(B           --# $B8GDj(B #
    , lv_retcode              -- $B%j%?!<%s!&%3!<%I(B             --# $B8GDj(B #
    , lv_errmsg               -- $B%f!<%6!<!&%(%i!<!&%a%C%;!<%8(B --# $B8GDj(B #
    );
    --
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- CSV$B%U%!%$%k=PNO=hM}(B(A-4)
    -- ===============================
    output_csv_data(
      lv_errbuf               -- $B%(%i!<!&%a%C%;!<%8(B           --# $B8GDj(B #
    , lv_retcode              -- $B%j%?!<%s!&%3!<%I(B             --# $B8GDj(B #
    , lv_errmsg               -- $B%f!<%6!<!&%(%i!<!&%a%C%;!<%8(B --# $B8GDj(B #
    );
    --
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- $B=*N;=hM}(B(A-5)
    -- ===============================
    BEGIN
      -- $B%U%!%$%k%/%m!<%:=hM}(B
      IF ( UTL_FILE.IS_OPEN( gf_file_handler ) ) THEN
        -- $B%U%!%$%k%/%m!<%:(B
        UTL_FILE.FCLOSE( gf_file_handler );
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_appl_xxcmm           -- $B%"%W%j%1!<%7%g%sC;=LL>(B
                  , iv_name         => cv_file_close_err_msg   -- $B%a%C%;!<%8%3!<%I(B
                  , iv_token_name1  => cv_tkn_sqlerrm          -- $B%H!<%/%s%3!<%I(B1
                  , iv_token_value1 => SQLERRM                 -- $B%H!<%/%sCM(B1
                  );
        lv_errbuf := lv_errmsg;
        RAISE global_f_close_err_expt;
    END;
--
    -- $B%9%-%C%W7o?t$,(B1$B7o0J>e$N>l9g$O7Y9p$rJV5Q(B
    IF ( gn_warn_cnt > 0 ) THEN
      ov_retcode := cv_status_warn;
    END IF;
--
  EXCEPTION
    -- *** $B%U%!%$%k%/%m!<%:%(%i!<(B ***
    WHEN global_f_close_err_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  $B8GDjNc30=hM}It(B START   ###################################
--
    -- *** $B=hM}It6&DLNc30%O%s%I%i(B ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** $B6&DL4X?t(BOTHERS$BNc30%O%s%I%i(B ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS$BNc30%O%s%I%i(B ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--####################################  $B8GDjIt(B END   ##########################################
--
  END submain;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : $B%3%s%+%l%s%H<B9T%U%!%$%kEPO?%W%m%7!<%8%c(B
   **********************************************************************************/
--
  PROCEDURE main(
    errbuf                    OUT VARCHAR2      -- $B%(%i!<!&%a%C%;!<%8(B  --# $B8GDj(B #
  , retcode                   OUT VARCHAR2      -- $B%j%?!<%s!&%3!<%I(B    --# $B8GDj(B #
  , iv_update_from            IN  VARCHAR2      -- $B:G=*99?7F|!J3+;O!K(B
  , iv_update_to              IN  VARCHAR2      -- $B:G=*99?7F|!J=*N;!K(B
  )
--
--###########################  $B8GDjIt(B START   ###########################
--
  IS
--
    -- ===============================
    -- $B8GDj%m!<%+%kDj?t(B
    -- ===============================
    cv_prg_name        CONSTANT VARCHAR2(100) := 'main';             -- $B%W%m%0%i%`L>(B
--
    cv_appl_short_name CONSTANT VARCHAR2(10)  := 'XXCCP';            -- $B%"%I%*%s!'6&DL!&(BIF$BNN0h(B
    cv_target_rec_msg  CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90000'; -- $BBP>]7o?t%a%C%;!<%8(B
    cv_success_rec_msg CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90001'; -- $B@.8y7o?t%a%C%;!<%8(B
    cv_error_rec_msg   CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90002'; -- $B%(%i!<7o?t%a%C%;!<%8(B
    cv_skip_rec_msg    CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90003'; -- $B%9%-%C%W7o?t%a%C%;!<%8(B
    cv_cnt_token       CONSTANT VARCHAR2(10)  := 'COUNT';            -- $B7o?t%a%C%;!<%8MQ%H!<%/%sL>(B
    cv_normal_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004'; -- $B@5>o=*N;%a%C%;!<%8(B
    cv_warn_msg        CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005'; -- $B7Y9p=*N;%a%C%;!<%8(B
    cv_error_msg       CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006'; -- $B%(%i!<=*N;A4%m!<%k%P%C%/(B
--
    -- ===============================
    -- $B%m!<%+%kJQ?t(B
    -- ===============================
    lv_errbuf          VARCHAR2(5000);  -- $B%(%i!<!&%a%C%;!<%8(B
    lv_retcode         VARCHAR2(1);     -- $B%j%?!<%s!&%3!<%I(B
    lv_errmsg          VARCHAR2(5000);  -- $B%f!<%6!<!&%(%i!<!&%a%C%;!<%8(B
    lv_message_code    VARCHAR2(100);   -- $B=*N;%a%C%;!<%8%3!<%I(B
    --
  BEGIN
--
--###########################  $B8GDjIt(B START   #####################################################
--
    -- $B8GDj=PNO(B
    -- $B%3%s%+%l%s%H%X%C%@%a%C%;!<%8=PNO4X?t$N8F$S=P$7(B
    xxccp_common_pkg.put_log_header(
      ov_retcode => lv_retcode
    , ov_errbuf  => lv_errbuf
    , ov_errmsg  => lv_errmsg
    );
    --
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_others_expt;
    END IF;
    --
--###########################  $B8GDjIt(B END   #############################
--
    -- ===============================================
    -- submain$B$N8F$S=P$7!J<B:]$N=hM}$O(Bsubmain$B$G9T$&!K(B
    -- ===============================================
    submain(
      lv_errbuf        -- $B%(%i!<!&%a%C%;!<%8(B           --# $B8GDj(B #
    , lv_retcode       -- $B%j%?!<%s!&%3!<%I(B             --# $B8GDj(B #
    , lv_errmsg        -- $B%f!<%6!<!&%(%i!<!&%a%C%;!<%8(B --# $B8GDj(B #
    , iv_update_from   -- $B:G=*99?7F|!J3+;O!K(B
    , iv_update_to     -- $B:G=*99?7F|!J=*N;!K(B
    );
--
    -- ===============================
    -- $B=*N;=hM}(B(A-5)
    -- ===============================
    -- $B%(%i!<=PNO(B
    IF ( lv_retcode = cv_status_error ) THEN
      FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => lv_errmsg --$B%f!<%6!<!&%(%i!<%a%C%;!<%8(B
      );
      FND_FILE.PUT_LINE(
        which  => FND_FILE.LOG
      , buff   => lv_errbuf --$B%(%i!<%a%C%;!<%8(B
      );
      -- $B%(%i!<;~7o?t%+%&%s%H(B
      gn_target_cnt := 0;
      gn_normal_cnt := 0;
      gn_warn_cnt   := 0;
      gn_error_cnt  := 1;
    END IF;
--
    -- $B6u9TA^F~(B
    FND_FILE.PUT_LINE(
      which  => FND_FILE.OUTPUT
    , buff   => ''
    );
--
    -- $BBP>]7o?t=PNO(B
    gv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_appl_short_name
                  , iv_name         => cv_target_rec_msg
                  , iv_token_name1  => cv_cnt_token
                  , iv_token_value1 => TO_CHAR( gn_target_cnt )
                  );
    FND_FILE.PUT_LINE(
      which  => FND_FILE.OUTPUT
    , buff   => gv_out_msg
    );
--
    -- $B@.8y7o?t=PNO(B
    gv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_appl_short_name
                  , iv_name         => cv_success_rec_msg
                  , iv_token_name1  => cv_cnt_token
                  , iv_token_value1 => TO_CHAR( gn_normal_cnt )
                  );
    FND_FILE.PUT_LINE(
      which  => FND_FILE.OUTPUT
    , buff   => gv_out_msg
    );
--
    -- $B%9%-%C%W7o?t=PNO(B
    gv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_appl_short_name
                  , iv_name         => cv_skip_rec_msg
                  , iv_token_name1  => cv_cnt_token
                  , iv_token_value1 => TO_CHAR( gn_warn_cnt )
                  );
    FND_FILE.PUT_LINE(
      which  => FND_FILE.OUTPUT
    , buff   => gv_out_msg
    );
--
    -- $B%(%i!<7o?t=PNO(B
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_error_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR( gn_error_cnt )
                   );
    FND_FILE.PUT_LINE(
      which  => FND_FILE.OUTPUT
    , buff   => gv_out_msg
    );
--
    -- $B=*N;%a%C%;!<%8(B
    IF ( lv_retcode = cv_status_normal ) THEN
      lv_message_code := cv_normal_msg;
    ELSIF( lv_retcode = cv_status_warn ) THEN
      lv_message_code := cv_warn_msg;
    ELSIF( lv_retcode = cv_status_error ) THEN
      lv_message_code := cv_error_msg;
    END IF;
    --
    gv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_appl_short_name
                  , iv_name         => lv_message_code
                  );
    FND_FILE.PUT_LINE(
      which  => FND_FILE.OUTPUT
    , buff   => gv_out_msg
    );
--
    -- $B%U%!%$%k$,%/%m!<%:$5$l$F$$$J$+$C$?>l9g!"%/%m!<%:$9$k(B
    IF ( UTL_FILE.IS_OPEN( gf_file_handler ) ) THEN
      -- $B%U%!%$%k%/%m!<%:(B
      UTL_FILE.FCLOSE( gf_file_handler );
    END IF;
--
    -- $B%9%F!<%?%9%;%C%H(B
    retcode := lv_retcode;
--
    -- $B=*N;%9%F!<%?%9$,%(%i!<$N>l9g$O(BROLLBACK$B$9$k(B
    IF ( retcode = cv_status_error ) THEN
      ROLLBACK;
    END IF;
--
  EXCEPTION
    -- *** $B6&DL4X?t(BOTHERS$BNc30%O%s%I%i(B ***
    WHEN global_api_others_expt THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
      ROLLBACK;
    -- *** OTHERS$BNc30%O%s%I%i(B ***
    WHEN OTHERS THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
      ROLLBACK;
  END main;
--
--###########################  $B8GDjIt(B END   #######################################################
--
END XXCMM002A07C;
/
