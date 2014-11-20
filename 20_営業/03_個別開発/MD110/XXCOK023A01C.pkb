CREATE OR REPLACE PACKAGE BODY XXCOK023A01C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOK023A01C(body)
 * Description      : �^����\�Z�Z�o
 * MD.050           : �^����\�Z�Z�o MD050_COK_023_A01
 * Version          : 1.5
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   ��������(A-1)
 *  get_budget_year        �\�Z�N�x���o����(A-2)
 *  get_item_plan_info     ���i�v��e�[�u����񒊏o����(A-3)
 *  get_item_info          �i�ڃ}�X�^��񒊏o����(A-4)
 *  sum_cs_qty             ����(C/S)�Z�o����(A-5)
 *  get_cust_mst_info      �ڋq�}�X�^��񒊏o����(A-6)
 *  get_drink_dlv_cost     �h�����N�U�։^���A�h�I���}�X�^��񒊏o����(A-7)
 *  sum_dlv_cost_budget    �^����\�Z���z�Z�o����(A-8)
 *  set_dlv_cost_budget    �^����\�Z�e�[�u���o�^���ڂ�PL/SQL�\�i�[����(A-9)
 *  delete_dlv_cost_budget �^����\�Z�e�[�u���폜����(A-10)
 *  insert_dlv_cost_budget �^����\�Z�e�[�u���o�^����(A-11)
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/11/25    1.0   A.Yano           �V�K�쐬
 *  2008/12/11    1.1   A.Yano           ��O�������C��
 *  2008/12/19    1.2   A.Yano           ��O�������C��
 *  2008/12/22    1.3   A.Yano           ���b�Z�[�W�o�́A���O�o�͏C��
 *  2009/03/25    1.4   A.Yano           [��QT1_0064] �I�[�v���N�x���擾��������ǉ�
 *  2009/05/12    1.5   A.Yano           [��QT1_0772] �ݒ�P���G���[���b�Z�[�W�ɕi�ڃR�[�h�ǉ�
 *
 *****************************************************************************************/
--
  -- ===============================
  -- �O���[�o���萔
  -- ===============================
  --�X�e�[�^�X�E�R�[�h
  cv_status_normal          CONSTANT VARCHAR2(1)  := xxccp_common_pkg.set_status_normal; -- ����:0
  cv_status_warn            CONSTANT VARCHAR2(1)  := xxccp_common_pkg.set_status_warn;   -- �x��:1
  cv_status_error           CONSTANT VARCHAR2(1)  := xxccp_common_pkg.set_status_error;  -- �ُ�:2
  --WHO�J����
  cn_created_by             CONSTANT NUMBER       := fnd_global.user_id;          -- CREATED_BY
  cn_last_updated_by        CONSTANT NUMBER       := fnd_global.user_id;          -- LAST_UPDATED_BY
  cn_last_update_login      CONSTANT NUMBER       := fnd_global.login_id;         -- LAST_UPDATE_LOGIN
  cn_request_id             CONSTANT NUMBER       := fnd_global.conc_request_id;  -- REQUEST_ID
  cn_program_application_id CONSTANT NUMBER       := fnd_global.prog_appl_id;     -- PROGRAM_APPLICATION_ID
  cn_program_id             CONSTANT NUMBER       := fnd_global.conc_program_id;  -- PROGRAM_ID
  -- �Z�p���[�^
  cv_msg_part               CONSTANT VARCHAR2(3)  := ' : ';
  cv_msg_cont               CONSTANT VARCHAR2(1)  := '.';
  -- �p�b�P�[�W��
  cv_pkg_name               CONSTANT VARCHAR2(20) := 'XXCOK023A01C';
  -- �A�v���P�[�V�����Z�k��
  cv_app_short_name_ccp     CONSTANT VARCHAR2(5)  := 'XXCCP';                     -- �A�v���P�[�V�����Z�k��'XXCCP'
  cv_app_short_name_cok     CONSTANT VARCHAR2(5)  := 'XXCOK';                     -- �A�v���P�[�V�����Z�k��'XXCOK'
  -- ���b�Z�[�W
  cv_no_parameter_msg       CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90008';          -- �R���J�����g���̓p�����[�^�Ȃ�
  cv_profile_err_msg        CONSTANT VARCHAR2(20) := 'APP-XXCOK1-00003';          -- �v���t�@�C���l�擾�G���[
  cv_budget_yser_nodata_msg CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10113';          -- �\�Z�N�x���擾�G���[
  cv_budget_yser_many_msg   CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10210';          -- �\�Z�N�x��񕡐����G���[
  cv_org_id_nodata_msg      CONSTANT VARCHAR2(20) := 'APP-XXCOK1-00013';          -- �݌ɑg�DID�擾�擾�G���[
  cv_item_plan_nodata_msg   CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10115';          -- ���i�v��e�[�u�����擾�G���[
  cv_item_mst_nodata_msg    CONSTANT VARCHAR2(20) := 'APP-XXCOK1-00056';          -- �i�ڃ}�X�^���擾�G���[
  cv_item_mst_many_msg      CONSTANT VARCHAR2(20) := 'APP-XXCOK1-00055';          -- �i�ڃ}�X�^��񕡐����G���[
  cv_cust_mst_nodata_msg    CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10118';          -- �ڋq�}�X�^���擾�G���[
  cv_cust_mst_many_msg      CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10119';          -- �ڋq�}�X�^��񕡐����G���[
  cv_set_amt_nodata_msg     CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10120';          -- �ݒ�P���擾�G���[
  cv_set_amt_many_msg       CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10121';          -- �ݒ�P���������G���[
  cv_case_qty_err_msg       CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10209';          -- �P�[�X�����擾�G���[��
  cv_lock_err_msg           CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10122';          -- �^����\�Z���b�N�G���[
--�y2009/03/25 A.Yano Ver.1.4 �ǉ�START�z------------------------------------------------------
  cv_process_date_err_msg   CONSTANT VARCHAR2(20) := 'APP-XXCOK1-00028';          -- �Ɩ��������t�擾�G���[
--�y2009/03/25 A.Yano Ver.1.4 �ǉ�END  �z------------------------------------------------------
  -- �g�[�N��
  cv_profile_token          CONSTANT VARCHAR2(10) := 'PROFILE';                   -- �v���t�@�C����
  cv_budget_year_token      CONSTANT VARCHAR2(20) := 'YOSAN_YEAR';                -- �Ώۗ\�Z�N�x
  cv_product_class_token    CONSTANT VARCHAR2(20) := 'PRODUCT_CLASS';             -- ���i����
  cv_location_code_token    CONSTANT VARCHAR2(20) := 'LOCATION_CODE';             -- ���_�R�[�h
  cv_base_major_token       CONSTANT VARCHAR2(20) := 'BASE_MAJOR_DIVISION';       -- ���_�啪��
  cv_item_code_token        CONSTANT VARCHAR2(10) := 'ITEM_CODE';                 -- �i�ڃR�[�h
  cv_org_code_token         CONSTANT VARCHAR2(10) := 'ORG_CODE';                  -- �݌ɑg�D�R�[�h
  cv_flex_value_set_token   CONSTANT VARCHAR2(20) := 'FLEX_VALUE_SET';            -- �l�Z�b�g��
  -- �v���t�@�C������
  cv_org_code_sales         CONSTANT VARCHAR2(30) := 'XXCOK1_ORG_CODE_SALES';     -- XXCOK:�݌ɑg�D�R�[�h_�c�Ƒg�D
  cv_yearplan_calender      CONSTANT VARCHAR2(30) := 'XXCSM1_YEARPLAN_CALENDER';  -- XXCSM:�N�Ԕ̔��v��J�����_
  cv_item_div_h             CONSTANT VARCHAR2(30) := 'XXCOS1_ITEM_DIV_H';         -- XXCOS:�{�Џ��i�敪
  -- ���i�敪
  cv_new_item_code          CONSTANT VARCHAR2(1)  := '2';                         -- �V���i
  -- �N�ԌQ�\�Z�敪
  cv_year_bdgt_kbn          CONSTANT VARCHAR2(1)  := '0';                         -- �e���P�ʗ\�Z
  -- �L���t���O
  cv_enabled_flag_y         CONSTANT VARCHAR2(1)  := 'Y';                         -- �L��
  -- �z���敪
  cv_dellivary_classe       CONSTANT VARCHAR2(2)  := '41';                        -- ��^��
  -- �o�����敪
  cn_baracya_type           CONSTANT NUMBER       := 1;                           -- �o����
  -- �{�Џ��i�敪
  cv_office_item_drink      CONSTANT VARCHAR2(1)  := '2';                         -- �h�����N
  -- �P�[�X����
  cv_nodata_case_qty        CONSTANT VARCHAR2(1)  := '0';                         -- ���擾
  -- �ڋq�敪
  cv_customer_class_code    CONSTANT VARCHAR2(1)  := '1';                         -- ���_
  -- ===============================
  -- �O���[�o���ϐ�
  -- ===============================
  gn_target_cnt           NUMBER;                                 -- �Ώی���
  gn_normal_cnt           NUMBER;                                 -- ���팏��
  gn_error_cnt            NUMBER;                                 -- �G���[����
  gn_warn_cnt             NUMBER;                                 -- �X�L�b�v����
  gn_data_cnt             NUMBER;                                 -- ���i�v����擾����
  gn_organization_id      NUMBER;                                 -- �݌ɑg�DID
  gv_item_div_h           VARCHAR2(20);                           -- �{�Џ��i�敪��
  gt_budget_year          fnd_flex_values.flex_value%TYPE;        -- �Ώۗ\�Z�N�x
--�y2009/03/25 A.Yano Ver.1.4 �ǉ�START�z------------------------------------------------------
  gd_process_date         DATE;                                   -- �Ɩ��������t
--�y2009/03/25 A.Yano Ver.1.4 �ǉ�END  �z------------------------------------------------------
  -- ===============================
  -- �O���[�o��RECORD�^
  -- ===============================
  -- �^����\�Z�e�[�u��
  TYPE g_dlv_cost_budget_rtype IS RECORD(
     budget_year         xxcok_dlv_cost_calc_budget.budget_year%TYPE          -- �\�Z�N�x
    ,target_month        xxcok_dlv_cost_calc_budget.target_month%TYPE         -- ��
    ,base_code           xxcok_dlv_cost_calc_budget.base_code%TYPE            -- ���_�R�[�h
    ,item_code           xxcok_dlv_cost_calc_budget.item_code%TYPE            -- �i�ڃR�[�h
    ,bottle_qty          xxcok_dlv_cost_calc_budget.bottle_qty%TYPE           -- ���ʁi�{�j
    ,cs_qty              xxcok_dlv_cost_calc_budget.cs_qty%TYPE               -- ���ʁiCS�j
    ,dlv_cost_budget_amt xxcok_dlv_cost_calc_budget.dlv_cost_budget_amt%TYPE  -- �^����\�Z���z
  );
  -- ===============================
  -- �O���[�o��TABLE�^
  -- ===============================
  -- �^����\�Z���
  TYPE g_dlv_cost_budget_ttype IS TABLE OF g_dlv_cost_budget_rtype
  INDEX BY BINARY_INTEGER;
  -- ===============================
  -- �O���[�o��PL/SQL�\
  -- ===============================
  -- �^����\�Z���
  g_dlv_cost_budget_tab    g_dlv_cost_budget_ttype;    -- �^����\�Z�e�[�u���o�^����PL/SQL�\
  -- ===============================
  -- �O���[�o���J�[�\��
  -- ===============================
  -- ���i�v����
  CURSOR g_item_plan_cur
  IS
    SELECT xiph.plan_year         AS budget_year    -- �\�Z�N�x
          ,xipl.month_no          AS target_month   -- ��
          ,xiph.location_cd       AS base_code      -- ���_�R�[�h
          ,xipl.item_no           AS item_code      -- ���i�R�[�h
          ,NVL( xipl.amount, 0 )  AS bottle_qty     -- ����
    FROM   xxcsm_item_plan_headers xiph
          ,xxcsm_item_plan_lines   xipl
    WHERE xiph.plan_year            =  TO_NUMBER( gt_budget_year )
    AND   xiph.item_plan_header_id  =  xipl.item_plan_header_id
    AND   xipl.item_no              IS NOT NULL
    AND   xipl.item_kbn             <> cv_new_item_code
    AND   xipl.year_bdgt_kbn        =  cv_year_bdgt_kbn
    ORDER BY xipl.month_no    ASC
            ,xiph.location_cd ASC
            ,xipl.item_no     ASC
  ;
  -- ===============================
  -- �O���[�o����O
  -- ===============================
  --*** ���������ʗ�O ***
  global_process_expt         EXCEPTION;
  --*** ���ʊ֐���O ***
  global_api_expt             EXCEPTION;
  --*** ���ʊ֐�OTHERS��O ***
  global_api_others_expt      EXCEPTION;
  global_no_data_expt         EXCEPTION;      -- �f�[�^�擾��O
  global_loop_process_expt    EXCEPTION;      -- ���C�����[�v��������O
  global_lock_expt            EXCEPTION;      -- ���b�N������O
  PRAGMA EXCEPTION_INIT( global_api_others_expt, -20000 );
  PRAGMA EXCEPTION_INIT( global_lock_expt, -54 );
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
--
  PROCEDURE init(
     ov_errbuf             OUT VARCHAR2      -- �G���[�E���b�Z�[�W
    ,ov_retcode            OUT VARCHAR2      -- ���^�[���E�R�[�h
    ,ov_errmsg             OUT VARCHAR2      -- ���[�U�[�E�G���[�E���b�Z�[�W
    ,ov_yearplan_calender  OUT VARCHAR2      -- �N�Ԕ̔��v��J�����_�̒l�Z�b�g��
  )
  IS
    -- ===============================
    -- �錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_prg_name           CONSTANT VARCHAR2(5) := 'init'; -- �v���O������
    -- *** ���[�J���ϐ� ***
    lv_errbuf                   VARCHAR2(5000);    -- �G���[�E���b�Z�[�W
    lv_retcode                  VARCHAR2(1);       -- ���^�[���E�R�[�h
    lv_errmsg                   VARCHAR2(5000);    -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_out_msg                  VARCHAR2(2000);    -- �o�̓��b�Z�[�W
    lb_retcode                  BOOLEAN;           -- ���b�Z�[�W�o�͂̃��^�[���E�R�[�h
    lv_org_code_sales           VARCHAR2(30);      -- �݌ɑg�D�R�[�h
    lv_nodata_profile           VARCHAR2(30);      -- ���擾�̃v���t�@�C����
    -- *** ���[�J����O ***
    local_nodata_profile_expt   EXCEPTION;         -- �v���t�@�C���l�擾��O
--�y2009/03/25 A.Yano Ver.1.4 �ǉ�START�z------------------------------------------------------
    process_date_expt           EXCEPTION;         -- �Ɩ��������t�擾��O
--�y2009/03/25 A.Yano Ver.1.4 �ǉ�END  �z------------------------------------------------------
--
  BEGIN
--
    ov_retcode := cv_status_normal;
    -- ===============================
    -- 1. ���b�Z�[�W�o��
    -- ===============================
    lv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_short_name_ccp
                    ,iv_name         => cv_no_parameter_msg
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                     in_which    =>   FND_FILE.OUTPUT
                    ,iv_message  =>   lv_out_msg
                    ,in_new_line =>   1
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                     in_which    =>   FND_FILE.LOG
                    ,iv_message  =>   lv_out_msg
                    ,in_new_line =>   2
                  );
    -- ===============================
    -- 2. �݌ɑg�D�R�[�h�擾
    -- ===============================
    lv_org_code_sales := FND_PROFILE.VALUE( cv_org_code_sales );
    IF( lv_org_code_sales IS NULL ) THEN
      lv_nodata_profile := cv_org_code_sales;
      RAISE local_nodata_profile_expt;
    END IF;
    -- ===============================
    -- 3. �N�Ԕ̔��v��J�����_�̒l�Z�b�g���擾
    -- ===============================
    ov_yearplan_calender := FND_PROFILE.VALUE( cv_yearplan_calender );
    IF( ov_yearplan_calender IS NULL ) THEN
      lv_nodata_profile := cv_yearplan_calender;
      RAISE local_nodata_profile_expt;
    END IF;
    -- ===============================
    -- 4. �{�Џ��i�敪�����擾
    -- ===============================
    gv_item_div_h := FND_PROFILE.VALUE( cv_item_div_h );
    IF( gv_item_div_h IS NULL ) THEN
      lv_nodata_profile := cv_item_div_h;
      RAISE local_nodata_profile_expt;
    END IF;
    -- ===============================
    -- 5. �݌ɑg�DID�̎擾
    -- ===============================
    gn_organization_id := xxcoi_common_pkg.get_organization_id(
                            lv_org_code_sales
                          );
    IF( gn_organization_id IS NULL ) THEN
      RAISE global_no_data_expt;
    END IF;
--�y2009/03/25 A.Yano Ver.1.4 �ǉ�START�z------------------------------------------------------
    -- ===============================
    -- 6. �Ɩ��������t�擾
    -- ===============================
    gd_process_date := xxccp_common_pkg2.get_process_date;
    IF( gd_process_date IS NULL ) THEN
      RAISE process_date_expt;
    END IF;
--�y2009/03/25 A.Yano Ver.1.4 �ǉ�END  �z------------------------------------------------------
--
  EXCEPTION
    --*** �v���t�@�C���擾��O�n���h�� ***
    WHEN local_nodata_profile_expt THEN
      lv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_short_name_cok
                      ,iv_name         => cv_profile_err_msg
                      ,iv_token_name1  => cv_profile_token
                      ,iv_token_value1 => lv_nodata_profile
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                       in_which    =>   FND_FILE.OUTPUT
                      ,iv_message  =>   lv_out_msg
                      ,in_new_line =>   0
                    );
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg,1,5000 );
      ov_retcode := cv_status_error;
    --*** �݌ɑg�DID�擾��O�n���h�� ***
    WHEN global_no_data_expt THEN
      lv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_short_name_cok
                      ,iv_name         => cv_org_id_nodata_msg
                      ,iv_token_name1  => cv_org_code_token
                      ,iv_token_value1 => lv_org_code_sales
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                       in_which    =>   FND_FILE.OUTPUT
                      ,iv_message  =>   lv_out_msg
                      ,in_new_line =>   0
                    );
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg,1,5000 );
      ov_retcode := cv_status_error;
--�y2009/03/25 A.Yano Ver.1.4 �ǉ�START�z------------------------------------------------------
    -- *** �Ɩ��������t�擾��O�n���h�� ***
    WHEN process_date_expt THEN
      lv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_short_name_cok
                      ,iv_name         => cv_process_date_err_msg
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                       in_which    =>   FND_FILE.OUTPUT
                      ,iv_message  =>   lv_out_msg
                      ,in_new_line =>   0
                    );
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg,1,5000 );
      ov_retcode := cv_status_error;
--�y2009/03/25 A.Yano Ver.1.4 �ǉ�END  �z------------------------------------------------------
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
      ov_retcode := cv_status_error;
--
  END init;
--
  /**********************************************************************************
   * Procedure Name   : get_budget_year
   * Description      : �\�Z�N�x���o����(A-2)
   ***********************************************************************************/
  PROCEDURE get_budget_year(
     ov_errbuf             OUT VARCHAR2      -- �G���[�E���b�Z�[�W
    ,ov_retcode            OUT VARCHAR2      -- ���^�[���E�R�[�h
    ,ov_errmsg             OUT VARCHAR2      -- ���[�U�[�E�G���[�E���b�Z�[�W
    ,iv_yearplan_calender  IN  VARCHAR2      -- �N�Ԕ̔��v��J�����_�̒l�Z�b�g��
  )
  IS
    -- ===============================
    -- �錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_prg_name     CONSTANT VARCHAR2(20) := 'get_budget_year'; -- �v���O������
    -- *** ���[�J���ϐ� ***
    lv_errbuf       VARCHAR2(5000);        -- �G���[�E���b�Z�[�W
    lv_retcode      VARCHAR2(1);           -- ���^�[���E�R�[�h
    lv_errmsg       VARCHAR2(5000);        -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_out_msg      VARCHAR2(2000);        -- �o�̓��b�Z�[�W
    lb_retcode      BOOLEAN;               -- ���b�Z�[�W�o�͂̃��^�[���E�R�[�h
--
  BEGIN
--
    ov_retcode := cv_status_normal;
    -- ===============================
    -- �L���ȗ\�Z�N�x�擾
    -- ===============================
    SELECT ffv.flex_value AS budget_year    -- �Ώۗ\�Z�N�x
    INTO   gt_budget_year
    FROM   fnd_flex_values     ffv
          ,fnd_flex_value_sets ffvs
    WHERE ffvs.flex_value_set_name  =  iv_yearplan_calender
    AND   ffv.flex_value_set_id     =  ffvs.flex_value_set_id
    AND   ffv.enabled_flag          =  cv_enabled_flag_y
--�y2009/03/25 A.Yano Ver.1.4 �ǉ�START�z------------------------------------------------------
    AND   NVL( ffv.start_date_active, gd_process_date ) <= gd_process_date
    AND   NVL( ffv.end_date_active  , gd_process_date ) >= gd_process_date
--�y2009/03/25 A.Yano Ver.1.4 �ǉ�END  �z------------------------------------------------------
    ;
--
  EXCEPTION
    -- *** �\�Z�N�x���擾��O�n���h�� ****
    WHEN NO_DATA_FOUND THEN
      lv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_short_name_cok
                      ,iv_name         => cv_budget_yser_nodata_msg
                      ,iv_token_name1  => cv_flex_value_set_token
                      ,iv_token_value1 => iv_yearplan_calender
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                       in_which    =>   FND_FILE.OUTPUT
                      ,iv_message  =>   lv_out_msg
                      ,in_new_line =>   0
                    );
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg,1,5000 );
      ov_retcode := cv_status_error;
    WHEN TOO_MANY_ROWS THEN
      -- *** �\�Z�N�x��񕡐�����O�n���h�� ****
      lv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_short_name_cok
                      ,iv_name         => cv_budget_yser_many_msg
                      ,iv_token_name1  => cv_flex_value_set_token
                      ,iv_token_value1 => iv_yearplan_calender
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                       in_which    =>   FND_FILE.OUTPUT
                      ,iv_message  =>   lv_out_msg
                      ,in_new_line =>   0
                    );
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg,1,5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
      ov_retcode := cv_status_error;
--
  END get_budget_year;
--
  /**********************************************************************************
   * Procedure Name   : get_item_info
   * Description      : �i�ڃ}�X�^��񒊏o����(A-4)
   ***********************************************************************************/
  PROCEDURE get_item_info(
     ov_errbuf                 OUT VARCHAR2                                -- �G���[�E���b�Z�[�W
    ,ov_retcode                OUT VARCHAR2                                -- ���^�[���E�R�[�h
    ,ov_errmsg                 OUT VARCHAR2                                -- ���[�U�[�E�G���[�E���b�Z�[�W
    ,it_item_code              IN  xxcsm_item_plan_lines.item_no%TYPE      -- ���i�R�[�h
    ,ot_product_class          OUT xxcmn_item_mst_b.product_class%TYPE     -- ���i����
    ,ot_godds_classification   OUT ic_item_mst_b.attribute11%TYPE          -- �P�[�X����
    ,ot_baracha_div            OUT xxcmm_system_items_b.baracha_div%TYPE   -- �o�����敪
    ,ot_office_item_type       OUT mtl_categories_b.segment1%TYPE          -- �{�Џ��i�敪
  )
  IS
    -- ===============================
    -- �錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_prg_name         CONSTANT VARCHAR2(20) := 'get_item_info'; -- �v���O������
    -- *** ���[�J���ϐ� ***
    lv_errbuf           VARCHAR2(5000);       -- �G���[�E���b�Z�[�W
    lv_retcode          VARCHAR2(1);          -- ���^�[���E�R�[�h
    lv_errmsg           VARCHAR2(5000);       -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_out_msg          VARCHAR2(2000);       -- �o�̓��b�Z�[�W
    lb_retcode          BOOLEAN;              -- ���b�Z�[�W�o�͂̃��^�[���E�R�[�h
--
  BEGIN
--
    ov_retcode := cv_status_normal;
    -- ===============================
    -- �i�ڃ}�X�^���擾
    -- ===============================
    SELECT ximb.product_class   AS product_class         -- ���i����
          ,iimb.attribute11     AS godds_classification  -- �P�[�X����
          ,xsib.baracha_div     AS baracha_div           -- �o�����敪
          ,mcb.segment1         AS item_div_h            -- �{�Џ��i�敪
    INTO   ot_product_class
          ,ot_godds_classification
          ,ot_baracha_div
          ,ot_office_item_type
    FROM   mtl_system_items_b      msib     -- �i�ڃ}�X�^
          ,ic_item_mst_b           iimb     -- OPM�i�ڃ}�X�^
          ,mtl_category_sets_b     mcsb     -- �i�ڃJ�e�S���Z�b�g
          ,mtl_category_sets_tl    mcst     -- �i�ڃJ�e�S���Z�b�g���{��
          ,mtl_categories_b        mcb      -- �i�ڃJ�e�S���}�X�^
          ,mtl_item_categories     mic      -- �i�ڃJ�e�S������
          ,xxcmm_system_items_b    xsib     -- �i�ڃA�h�I���}�X�^
          ,xxcmn_item_mst_b        ximb     -- OPM�i�ڃA�h�I���}�X�^
    WHERE  msib.segment1                = iimb.item_no
    AND    iimb.item_id                 = ximb.item_id
    AND    msib.segment1                = xsib.item_code
    AND    msib.inventory_item_id       = mic.inventory_item_id
    AND    msib.organization_id         = mic.organization_id
    AND    mic.category_id              = mcb.category_id
    AND    mcb.structure_id             = mcsb.structure_id
    AND    mic.category_set_id          = mcsb.category_set_id
    AND    mcst.category_set_id         = mcsb.category_set_id
    AND    msib.segment1                = it_item_code
    AND    mcst.language                = USERENV( 'LANG' )
    AND    mcst.category_set_name       = gv_item_div_h
    AND    msib.organization_id         = gn_organization_id
    ;
--
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      -- *** �i�ڃ}�X�^���擾��O�n���h�� ****
      lv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_short_name_cok
                      ,iv_name         => cv_item_mst_nodata_msg
                      ,iv_token_name1  => cv_item_code_token
                      ,iv_token_value1 => it_item_code
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                       in_which    =>   FND_FILE.OUTPUT
                      ,iv_message  =>   lv_out_msg
                      ,in_new_line =>   0
                    );
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg,1,5000 );
      ov_retcode := cv_status_error;
    WHEN TOO_MANY_ROWS THEN
      -- *** �i�ڃ}�X�^��񕡐�����O�n���h�� ****
      lv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_short_name_cok
                      ,iv_name         => cv_item_mst_many_msg
                      ,iv_token_name1  => cv_item_code_token
                      ,iv_token_value1 => it_item_code
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                       in_which    =>   FND_FILE.OUTPUT
                      ,iv_message  =>   lv_out_msg
                      ,in_new_line =>   0
                    );
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg,1,5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
      ov_retcode := cv_status_error;
--
  END get_item_info;
--
  /**********************************************************************************
   * Procedure Name   : sum_cs_qty
   * Description      : ����(C/S)�Z�o����(A-5)
   ***********************************************************************************/
  PROCEDURE sum_cs_qty(
     ov_errbuf                 OUT VARCHAR2                           -- �G���[�E���b�Z�[�W
    ,ov_retcode                OUT VARCHAR2                           -- ���^�[���E�R�[�h
    ,ov_errmsg                 OUT VARCHAR2                           -- ���[�U�[�E�G���[�E���b�Z�[�W
    ,it_bottle_qty             IN  xxcsm_item_plan_lines.amount%TYPE  -- ����
    ,it_godds_classification   IN  ic_item_mst_b.attribute11%TYPE     -- �P�[�X����
    ,on_cs_qty                 OUT NUMBER                             -- ���ʁiCS�j
  )
  IS
    -- ===============================
    -- �錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_prg_name      CONSTANT VARCHAR2(20) := 'sum_cs_qty'; -- �v���O������
    -- *** ���[�J���ϐ� ***
    lv_errbuf        VARCHAR2(5000);      -- �G���[�E���b�Z�[�W
    lv_retcode       VARCHAR2(1);         -- ���^�[���E�R�[�h
    lv_errmsg        VARCHAR2(5000);      -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_out_msg       VARCHAR2(2000);      -- �o�̓��b�Z�[�W
    lb_retcode       BOOLEAN;             -- ���b�Z�[�W�o�͂̃��^�[���E�R�[�h
--
  BEGIN
--
    ov_retcode := cv_status_normal;
--
    -- ===============================
    -- ���ʁiCS�j�Z�o
    -- ===============================
    on_cs_qty := ROUND( it_bottle_qty / TO_NUMBER( it_godds_classification ) );
--
  EXCEPTION
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
      ov_retcode := cv_status_error;
--
  END sum_cs_qty;
--
  /**********************************************************************************
   * Procedure Name   : get_cust_mst_info
   * Description      : �ڋq�}�X�^��񒊏o����(A-6)
   ***********************************************************************************/
  PROCEDURE get_cust_mst_info(
     ov_errbuf               OUT VARCHAR2                                  -- �G���[�E���b�Z�[�W
    ,ov_retcode              OUT VARCHAR2                                  -- ���^�[���E�R�[�h
    ,ov_errmsg               OUT VARCHAR2                                  -- ���[�U�[�E�G���[�E���b�Z�[�W
    ,it_base_code            IN  xxcsm_item_plan_headers.location_cd%TYPE  -- ���_�R�[�h
    ,ot_base_major_division  OUT xxcmn_parties.base_major_division%TYPE    -- ���_�啪��
  )
  IS
    -- ===============================
    -- �錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_prg_name   CONSTANT VARCHAR2(20) := 'get_cust_mst_info'; -- �v���O������
    -- *** ���[�J���ϐ� ***
    lv_errbuf     VARCHAR2(5000);      -- �G���[�E���b�Z�[�W
    lv_retcode    VARCHAR2(1);         -- ���^�[���E�R�[�h
    lv_errmsg     VARCHAR2(5000);      -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_out_msg    VARCHAR2(2000);      -- �o�̓��b�Z�[�W
    lb_retcode    BOOLEAN;             -- ���b�Z�[�W�o�͂̃��^�[���E�R�[�h
--
  BEGIN
--
    ov_retcode := cv_status_normal;
    -- ===============================
    -- �ڋq�}�X�^���擾
    -- ===============================
    SELECT xp.base_major_division AS base_major_division   -- ���_�啪��
    INTO   ot_base_major_division
    FROM   hz_parties        hp       -- �p�[�e�B�}�X�^
          ,xxcmn_parties     xp       -- �p�[�e�B�A�h�I���}�X�^
          ,hz_cust_accounts  hca      -- �ڋq�}�X�^
    WHERE xp.party_id             = hp.party_id
    AND   hp.party_id             = hca.party_id
    AND   hca.account_number      = it_base_code
    AND   hca.customer_class_code = cv_customer_class_code
    AND   ROWNUM                  = 1
    ;
    -- ===============================
    -- �ڋq�}�X�^��񖢎擾
    -- ===============================
    IF( ot_base_major_division IS NULL ) THEN
      RAISE NO_DATA_FOUND;
    END IF;
--
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      -- *** �ڋq�}�X�^���擾��O�n���h�� ****
      lv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_short_name_cok
                      ,iv_name         => cv_cust_mst_nodata_msg
                      ,iv_token_name1  => cv_location_code_token
                      ,iv_token_value1 => it_base_code
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                       in_which    =>   FND_FILE.OUTPUT
                      ,iv_message  =>   lv_out_msg
                      ,in_new_line =>   0
                    );
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg,1,5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
      ov_retcode := cv_status_error;
--
  END get_cust_mst_info;
--
  /**********************************************************************************
   * Procedure Name   : get_drink_dlv_cost
   * Description      : �h�����N�U�։^���A�h�I���}�X�^��񒊏o����(A-7)
   ***********************************************************************************/
  PROCEDURE get_drink_dlv_cost(
     ov_errbuf               OUT VARCHAR2                                           -- �G���[�E���b�Z�[�W
    ,ov_retcode              OUT VARCHAR2                                           -- ���^�[���E�R�[�h
    ,ov_errmsg               OUT VARCHAR2                                           -- ���[�U�[�E�G���[�E���b�Z�[�W
    ,it_budget_year          IN  xxcsm_item_plan_headers.plan_year%TYPE             -- �\�Z�N�x
    ,it_target_month         IN  xxcsm_item_plan_lines.month_no%TYPE                -- ��
    ,it_base_code            IN  xxcsm_item_plan_headers.location_cd%TYPE           -- ���_�R�[�h
    ,it_product_class        IN  xxcmn_item_mst_b.product_class%TYPE                -- ���i����
    ,it_base_major_division  IN  xxcmn_parties.base_major_division%TYPE             -- ���_�啪��
--�y2009/05/12 A.Yano Ver.1.5 �ǉ�START�z------------------------------------------------------
    ,it_item_code            IN  xxcsm_item_plan_lines.item_no%TYPE                 -- ���i�R�[�h
--�y2009/05/12 A.Yano Ver.1.5 �ǉ�END  �z------------------------------------------------------
    ,ot_set_unit_price       OUT xxwip_drink_trans_deli_chrgs.setting_amount%TYPE   -- �ݒ�P��
  )
  IS
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_prg_name   CONSTANT VARCHAR2(20) := 'get_drink_dlv_cost'; -- �v���O������
    -- *** ���[�J���ϐ� ***
    lv_errbuf     VARCHAR2(5000);    -- �G���[�E���b�Z�[�W
    lv_retcode    VARCHAR2(1);       -- ���^�[���E�R�[�h
    lv_errmsg     VARCHAR2(5000);    -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_out_msg    VARCHAR2(2000);    -- �o�̓��b�Z�[�W
    lb_retcode    BOOLEAN;           -- ���b�Z�[�W�o�͂̃��^�[���E�R�[�h
--
  BEGIN
--
    ov_retcode := cv_status_normal;
    -- ===============================
    -- �h�����N�U�։^���A�h�I���}�X�^���擾
    -- ===============================
    SELECT xdtd.setting_amount AS setting_amount    -- �ݒ�P��
    INTO   ot_set_unit_price
    FROM   xxwip_drink_trans_deli_chrgs xdtd
    WHERE xdtd.godds_classification   = TO_CHAR( it_product_class )
    AND   xdtd.foothold_macrotaxonomy = it_base_major_division
    AND   xdtd.dellivary_classe       = cv_dellivary_classe
    AND   TO_DATE( it_budget_year || TO_CHAR( it_target_month, 'FM00' ) , 'YYYYMM' )
          BETWEEN xdtd.start_date_active AND NVL( xdtd.end_date_active, SYSDATE )
    ;
--
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      -- *** �h�����N�U�։^���A�h�I���}�X�^���擾��O�n���h�� ****
      lv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_short_name_cok
                      ,iv_name         => cv_set_amt_nodata_msg
                      ,iv_token_name1  => cv_product_class_token
                      ,iv_token_value1 => TO_CHAR( it_product_class )
                      ,iv_token_name2  => cv_base_major_token
                      ,iv_token_value2 => it_base_major_division
                      ,iv_token_name3  => cv_location_code_token
                      ,iv_token_value3 => it_base_code
--�y2009/05/12 A.Yano Ver.1.5 �ǉ�START�z------------------------------------------------------
                      ,iv_token_name4  => cv_item_code_token
                      ,iv_token_value4 => it_item_code
--�y2009/05/12 A.Yano Ver.1.5 �ǉ�END  �z------------------------------------------------------
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                       in_which    =>   FND_FILE.OUTPUT
                      ,iv_message  =>   lv_out_msg
                      ,in_new_line =>   0
                    );
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg,1,5000 );
      ov_retcode := cv_status_error;
    WHEN TOO_MANY_ROWS THEN
      -- *** �h�����N�U�։^���A�h�I���}�X�^��񕡐�����O�n���h�� ****
      lv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_short_name_cok
                      ,iv_name         => cv_set_amt_many_msg
                      ,iv_token_name1  => cv_product_class_token
                      ,iv_token_value1 => TO_CHAR( it_product_class )
                      ,iv_token_name2  => cv_base_major_token
                      ,iv_token_value2 => it_base_major_division
                      ,iv_token_name3  => cv_location_code_token
                      ,iv_token_value3 => it_base_code
--�y2009/05/12 A.Yano Ver.1.5 �ǉ�START�z------------------------------------------------------
                      ,iv_token_name4  => cv_item_code_token
                      ,iv_token_value4 => it_item_code
--�y2009/05/12 A.Yano Ver.1.5 �ǉ�END  �z------------------------------------------------------
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                       in_which    =>   FND_FILE.OUTPUT
                      ,iv_message  =>   lv_out_msg
                      ,in_new_line =>   0
                    );
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg,1,5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
      ov_retcode := cv_status_error;
--
  END get_drink_dlv_cost;
--
  /**********************************************************************************
   * Procedure Name   : sum_dlv_cost_budget
   * Description      : �^����\�Z���z�Z�o����(A-8)
   ***********************************************************************************/
  PROCEDURE sum_dlv_cost_budget(
     ov_errbuf               OUT VARCHAR2                                          -- �G���[�E���b�Z�[�W
    ,ov_retcode              OUT VARCHAR2                                          -- ���^�[���E�R�[�h
    ,ov_errmsg               OUT VARCHAR2                                          -- ���[�U�[�E�G���[�E���b�Z�[�W
    ,in_cs_qty               IN  NUMBER                                            -- ���ʁiCS�j
    ,it_set_unit_price       IN  xxwip_drink_trans_deli_chrgs.setting_amount%TYPE  -- �ݒ�P��
    ,on_dlv_cost_budget_amt  OUT NUMBER                                            -- �^����\�Z���z
  )
  IS
    -- ===============================
    -- �錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_prg_name     CONSTANT VARCHAR2(30) := 'sum_dlv_cost_budget'; -- �v���O������
    -- *** ���[�J���ϐ� ***
    lv_errbuf       VARCHAR2(5000);        -- �G���[�E���b�Z�[�W
    lv_retcode      VARCHAR2(1);           -- ���^�[���E�R�[�h
    lv_errmsg       VARCHAR2(5000);        -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_out_msg      VARCHAR2(2000);        -- �o�̓��b�Z�[�W
    lb_retcode      BOOLEAN;               -- ���b�Z�[�W�o�͂̃��^�[���E�R�[�h
--
  BEGIN
--
    ov_retcode := cv_status_normal;
    -- ===============================
    -- �^����\�Z���z�Z�o
    -- ===============================
    on_dlv_cost_budget_amt := in_cs_qty * it_set_unit_price;
--
  EXCEPTION
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
      ov_retcode := cv_status_error;
--
  END sum_dlv_cost_budget;
--
  /**********************************************************************************
   * Procedure Name   : set_dlv_cost_budget
   * Description      : �^����\�Z�e�[�u���o�^���ڂ�PL/SQL�\�i�[����(A-9)
   ***********************************************************************************/
  PROCEDURE set_dlv_cost_budget(
     ov_errbuf               OUT VARCHAR2                 -- �G���[�E���b�Z�[�W
    ,ov_retcode              OUT VARCHAR2                 -- ���^�[���E�R�[�h
    ,ov_errmsg               OUT VARCHAR2                 -- ���[�U�[�E�G���[�E���b�Z�[�W
    ,i_item_plan_rec         IN  g_item_plan_cur%ROWTYPE  -- ���i�v����
    ,in_cs_qty               IN  NUMBER                   -- ���ʁiCS�j
    ,in_dlv_cost_budget_amt  IN  NUMBER                   -- �^����\�Z���z
  )
  IS
    -- ===============================
    -- �錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_prg_name      CONSTANT VARCHAR2(30) := 'set_dlv_cost_budget'; -- �v���O������
    -- *** ���[�J���ϐ� ***
    lv_errbuf        VARCHAR2(5000);      -- �G���[�E���b�Z�[�W
    lv_retcode       VARCHAR2(1);         -- ���^�[���E�R�[�h
    lv_errmsg        VARCHAR2(5000);      -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_out_msg       VARCHAR2(2000);      -- �o�̓��b�Z�[�W
    lb_retcode       BOOLEAN;             -- ���b�Z�[�W�o�͂̃��^�[���E�R�[�h
--
  BEGIN
--
    ov_retcode := cv_status_normal;
    -- ===============================
    -- �^����\�Z�e�[�u���o�^���ڂ�PL/SQL�\�֊i�[
    -- ===============================
    g_dlv_cost_budget_tab( gn_target_cnt ).budget_year         := TO_CHAR( i_item_plan_rec.budget_year );
    g_dlv_cost_budget_tab( gn_target_cnt ).target_month        := TO_CHAR( i_item_plan_rec.target_month, 'FM00' );
    g_dlv_cost_budget_tab( gn_target_cnt ).base_code           := i_item_plan_rec.base_code;
    g_dlv_cost_budget_tab( gn_target_cnt ).item_code           := i_item_plan_rec.item_code;
    g_dlv_cost_budget_tab( gn_target_cnt ).bottle_qty          := i_item_plan_rec.bottle_qty;
    g_dlv_cost_budget_tab( gn_target_cnt ).cs_qty              := in_cs_qty;
    g_dlv_cost_budget_tab( gn_target_cnt ).dlv_cost_budget_amt := in_dlv_cost_budget_amt;
--
  EXCEPTION
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
      ov_retcode := cv_status_error;
--
  END set_dlv_cost_budget;
--
  /**********************************************************************************
   * Procedure Name   : get_item_plan_info
   * Description      : ���i�v��e�[�u����񒊏o����(A-3)
   ***********************************************************************************/
  PROCEDURE get_item_plan_info(
     ov_errbuf     OUT VARCHAR2      --   �G���[�E���b�Z�[�W
    ,ov_retcode    OUT VARCHAR2      --   ���^�[���E�R�[�h
    ,ov_errmsg     OUT VARCHAR2      --   ���[�U�[�E�G���[�E���b�Z�[�W
  )
  IS
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_prg_name             CONSTANT VARCHAR2(20) := 'get_item_plan_info'; -- �v���O������
    -- *** ���[�J���ϐ� ***
    lv_errbuf               VARCHAR2(5000);                                    -- �G���[�E���b�Z�[�W
    lv_retcode              VARCHAR2(1);                                       -- ���^�[���E�R�[�h
    lv_errmsg               VARCHAR2(5000);                                    -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_out_msg              VARCHAR2(2000);                                    -- �o�̓��b�Z�[�W
    lb_retcode              BOOLEAN;                                           -- ���b�Z�[�W�o�͂̃��^�[���E�R�[�h
    lt_product_class        xxcmn_item_mst_b.product_class%TYPE;               -- ���i����
    lt_godds_classification ic_item_mst_b.attribute11%TYPE;                    -- �P�[�X����
    lt_baracha_div          xxcmm_system_items_b.baracha_div%TYPE;             -- �o�����敪
    lt_office_item_type     mtl_categories_b.segment1%TYPE;                    -- �{�Џ��i�敪
    lt_base_code_before     xxcsm_item_plan_headers.location_cd%TYPE;          -- �O��̋��_�R�[�h
    lt_base_major_division  xxcmn_parties.base_major_division%TYPE;            -- ���_�啪��
    lt_set_unit_price       xxwip_drink_trans_deli_chrgs.setting_amount%TYPE;  -- �ݒ�P�� NUMBER
    ln_cs_qty               NUMBER;                                            -- ���ʁiCS�j
    ln_dlv_cost_budget_amt  NUMBER;                                            -- �^����\�Z���z
--
  BEGIN
--
    ov_retcode := cv_status_normal;
    << item_plan_loop >>
    FOR l_item_plan_rec IN g_item_plan_cur LOOP
      -- ���i�v����擾����
      gn_data_cnt := gn_data_cnt + 1;
      -- ================================================
      -- A-4.�i�ڃ}�X�^��񒊏o����
      -- ================================================
      get_item_info(
         ov_errbuf                  =>  lv_errbuf                 -- �G���[�E���b�Z�[�W
        ,ov_retcode                 =>  lv_retcode                -- ���^�[���E�R�[�h
        ,ov_errmsg                  =>  lv_errmsg                 -- ���[�U�[�E�G���[�E���b�Z�[�W
        ,it_item_code               =>  l_item_plan_rec.item_code -- ���i�R�[�h
        ,ot_product_class           =>  lt_product_class          -- ���i����
        ,ot_godds_classification    =>  lt_godds_classification   -- �P�[�X����
        ,ot_baracha_div             =>  lt_baracha_div            -- �o�����敪
        ,ot_office_item_type        =>  lt_office_item_type       -- �{�Џ��i�敪
      );
      IF( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
      -- ===============================
      -- �o�����敪1:�o�����܂��́A
      -- �{�Џ��i�敪'2'�h�����N�ȊO�̏ꍇ
      -- ===============================
      IF(  ( lt_baracha_div      =  cn_baracya_type      )
        OR( lt_office_item_type <> cv_office_item_drink ) )
      THEN
        -- �X�L�b�v����
        gn_warn_cnt   := gn_warn_cnt + 1;
      ELSE
        -- ===============================
        -- �P�[�X�������擾
        -- ===============================
        IF( ( lt_godds_classification IS NULL              )
          OR( lt_godds_classification = cv_nodata_case_qty ) )
        THEN
          lv_out_msg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_app_short_name_cok
                          ,iv_name         => cv_case_qty_err_msg
                          ,iv_token_name1  => cv_item_code_token
                          ,iv_token_value1 => l_item_plan_rec.item_code
                        );
          RAISE global_no_data_expt;
        END IF;
        -- �������s
        -- ================================================
        -- A-5.����(C/S)�Z�o����
        -- ================================================
        sum_cs_qty(
           ov_errbuf                    =>  lv_errbuf                   -- �G���[�E���b�Z�[�W
          ,ov_retcode                   =>  lv_retcode                  -- ���^�[���E�R�[�h
          ,ov_errmsg                    =>  lv_errmsg                   -- ���[�U�[�E�G���[�E���b�Z�[�W
          ,it_bottle_qty                =>  l_item_plan_rec.bottle_qty  -- ����
          ,it_godds_classification      =>  lt_godds_classification     -- �P�[�X����
          ,on_cs_qty                    =>  ln_cs_qty                   -- ���ʁiCS�j
        );
        IF( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        END IF;
        -- ================================================
        -- A-6.�ڋq�}�X�^��񒊏o����
        -- ================================================
        -- ����擾���܂��́A���_���ς�����ꍇ
        IF( ( lt_base_major_division IS NULL                      )
          OR( lt_base_code_before    <> l_item_plan_rec.base_code ) )
        THEN
          lt_base_code_before := l_item_plan_rec.base_code;
          get_cust_mst_info(
             ov_errbuf                 =>   lv_errbuf                 -- �G���[�E���b�Z�[�W
            ,ov_retcode                =>   lv_retcode                -- ���^�[���E�R�[�h
            ,ov_errmsg                 =>   lv_errmsg                 -- ���[�U�[�E�G���[�E���b�Z�[�W
            ,it_base_code              =>   l_item_plan_rec.base_code -- ���_�R�[�h
            ,ot_base_major_division    =>   lt_base_major_division    -- ���_�啪��
          );
          IF( lv_retcode = cv_status_error ) THEN
            RAISE global_process_expt;
          END IF;
        END IF;
        -- ================================================
        -- A-7.�h�����N�U�։^���A�h�I���}�X�^��񒊏o����
        -- ================================================
        get_drink_dlv_cost(
           ov_errbuf                    =>   lv_errbuf                     -- �G���[�E���b�Z�[�W
          ,ov_retcode                   =>   lv_retcode                    -- ���^�[���E�R�[�h
          ,ov_errmsg                    =>   lv_errmsg                     -- ���[�U�[�E�G���[�E���b�Z�[�W
          ,it_budget_year               =>   l_item_plan_rec.budget_year   -- �\�Z�N�x
          ,it_target_month              =>   l_item_plan_rec.target_month  -- ��
          ,it_base_code                 =>   l_item_plan_rec.base_code     -- ���_�R�[�h
          ,it_product_class             =>   lt_product_class              -- ���i����
          ,it_base_major_division       =>   lt_base_major_division        -- ���_�啪��
--�y2009/05/12 A.Yano Ver.1.5 �ǉ�START�z------------------------------------------------------
          ,it_item_code                 =>   l_item_plan_rec.item_code     -- ���i�R�[�h
--�y2009/05/12 A.Yano Ver.1.5 �ǉ�END  �z------------------------------------------------------
          ,ot_set_unit_price            =>   lt_set_unit_price             -- �ݒ�P��
        );
        IF( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        END IF;
        -- ================================================
        -- A-8.�^����\�Z���z�Z�o����
        -- ================================================
        sum_dlv_cost_budget(
           ov_errbuf                    =>   lv_errbuf                -- �G���[�E���b�Z�[�W
          ,ov_retcode                   =>   lv_retcode               -- ���^�[���E�R�[�h
          ,ov_errmsg                    =>   lv_errmsg                -- ���[�U�[�E�G���[�E���b�Z�[�W
          ,in_cs_qty                    =>   ln_cs_qty                -- ���ʁiCS�j
          ,it_set_unit_price            =>   lt_set_unit_price        -- �ݒ�P��
          ,on_dlv_cost_budget_amt       =>   ln_dlv_cost_budget_amt   -- �^����\�Z���z
        );
        IF( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        END IF;
        -- ================================================
        -- A-9.�^����\�Z�e�[�u���o�^���ڂ�PL/SQL�\�i�[����
        -- ================================================
        set_dlv_cost_budget(
           ov_errbuf                    =>   lv_errbuf                -- �G���[�E���b�Z�[�W
          ,ov_retcode                   =>   lv_retcode               -- ���^�[���E�R�[�h
          ,ov_errmsg                    =>   lv_errmsg                -- ���[�U�[�E�G���[�E���b�Z�[�W
          ,i_item_plan_rec              =>   l_item_plan_rec          -- ���i�v����
          ,in_cs_qty                    =>   ln_cs_qty                -- ���ʁiCS�j
          ,in_dlv_cost_budget_amt       =>   ln_dlv_cost_budget_amt   -- �^����\�Z���z
        );
        IF( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        END IF;
        -- �Ώی���
        gn_target_cnt := gn_target_cnt + 1;
      END IF;
    END LOOP item_plan_loop;
    -- ===============================
    -- ���o�f�[�^0���̏ꍇ
    -- ===============================
    IF( gn_data_cnt = 0 ) THEN
      lv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_short_name_cok
                      ,iv_name         => cv_item_plan_nodata_msg
                      ,iv_token_name1  => cv_budget_year_token
                      ,iv_token_value1 => gt_budget_year
                    );
      RAISE global_no_data_expt;
    END IF;
--
  EXCEPTION
    -- *** �f�[�^�擾��O�n���h�� ****
    WHEN global_no_data_expt THEN
      lb_retcode := xxcok_common_pkg.put_message_f(
                       in_which    =>   FND_FILE.OUTPUT
                      ,iv_message  =>   lv_out_msg
                      ,in_new_line =>   0
                    );
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg,1,5000 );
      ov_retcode := cv_status_error;
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
      ov_retcode := cv_status_error;
--
  END get_item_plan_info;
--
  /**********************************************************************************
   * Procedure Name   : delete_dlv_cost_budget
   * Description      : �^����\�Z�e�[�u���폜����(A-10)
   ***********************************************************************************/
  PROCEDURE delete_dlv_cost_budget(
     ov_errbuf       OUT VARCHAR2                                  --   �G���[�E���b�Z�[�W
    ,ov_retcode      OUT VARCHAR2                                  --   ���^�[���E�R�[�h
    ,ov_errmsg       OUT VARCHAR2                                  --   ���[�U�[�E�G���[�E���b�Z�[�W
  )
  IS
    -- ===============================
    -- �錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_prg_name      CONSTANT VARCHAR2(30) := 'delete_dlv_cost_budget'; -- �v���O������
    -- *** ���[�J���ϐ� ***
    lv_errbuf        VARCHAR2(5000);      -- �G���[�E���b�Z�[�W
    lv_retcode       VARCHAR2(1);         -- ���^�[���E�R�[�h
    lv_errmsg        VARCHAR2(5000);      -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_out_msg       VARCHAR2(2000);      -- �o�̓��b�Z�[�W
    lb_retcode       BOOLEAN;             -- ���b�Z�[�W�o�͂̃��^�[���E�R�[�h
    -- *** ���[�J���J�[�\�� ***
    CURSOR l_lock_cur
    IS
      SELECT 'X'
      FROM   xxcok_dlv_cost_calc_budget xdcc
      WHERE  xdcc.budget_year = TO_CHAR( gt_budget_year )
      FOR UPDATE OF xdcc.budget_id NOWAIT
    ;
--
  BEGIN
--
    ov_retcode := cv_status_normal;
    -- ===============================
    -- �^����\�Z�e�[�u�����b�N�擾
    -- ===============================
    OPEN  l_lock_cur;
    CLOSE l_lock_cur;
    -- ===============================
    -- �^����\�Z�e�[�u���폜
    -- ===============================
    DELETE FROM xxcok_dlv_cost_calc_budget xdcc
    WHERE xdcc.budget_year = TO_CHAR( gt_budget_year )
    ;
--
  EXCEPTION
    -- *** �^����\�Z���b�N��O�n���h�� ****
    WHEN global_lock_expt THEN
      lv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_short_name_cok
                      ,iv_name         => cv_lock_err_msg
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                       in_which    =>   FND_FILE.OUTPUT
                      ,iv_message  =>   lv_out_msg
                      ,in_new_line =>   0
                    );
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg,1,5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
      ov_retcode := cv_status_error;
--
  END delete_dlv_cost_budget;
--
  /**********************************************************************************
   * Procedure Name   : insert_dlv_cost_budget
   * Description      : �^����\�Z�e�[�u���o�^����(A-11)
   ***********************************************************************************/
  PROCEDURE insert_dlv_cost_budget(
     ov_errbuf     OUT VARCHAR2      -- �G���[�E���b�Z�[�W
    ,ov_retcode    OUT VARCHAR2      -- ���^�[���E�R�[�h
    ,ov_errmsg     OUT VARCHAR2      -- ���[�U�[�E�G���[�E���b�Z�[�W
  )
  IS
    -- ===============================
    -- �錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_prg_name      CONSTANT VARCHAR2(30) := 'insert_dlv_cost_budget'; -- �v���O������
    -- *** ���[�J���ϐ� ***
    lv_errbuf        VARCHAR2(5000);      -- �G���[�E���b�Z�[�W
    lv_retcode       VARCHAR2(1);         -- ���^�[���E�R�[�h
    lv_errmsg        VARCHAR2(5000);      -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_out_msg       VARCHAR2(2000);      -- �o�̓��b�Z�[�W
    lb_retcode       BOOLEAN;             -- ���b�Z�[�W�o�͂̃��^�[���E�R�[�h
--
  BEGIN
--
    ov_retcode := cv_status_normal;
    -- ===============================
    -- �^����\�Z�e�[�u���o�^
    -- ===============================
    << insert_loop >>
    FOR cnt IN g_dlv_cost_budget_tab.FIRST..g_dlv_cost_budget_tab.LAST LOOP
      INSERT INTO xxcok_dlv_cost_calc_budget(
         budget_id                -- �^����\�ZID
        ,budget_year              -- �\�Z�N�x
        ,target_month             -- ��
        ,base_code                -- ���_�R�[�h
        ,item_code                -- �i�ڃR�[�h
        ,bottle_qty               -- ���ʁi�{�j
        ,cs_qty                   -- ���ʁiCS�j
        ,dlv_cost_budget_amt      -- �^����\�Z���z
        --WHO�J����
        ,created_by
        ,creation_date
        ,last_updated_by
        ,last_update_date
        ,last_update_login
        ,request_id
        ,program_application_id
        ,program_id
        ,program_update_date
      ) VALUES (
         xxcok_dlv_cost_calc_budget_s01.nextval            -- �^����\�ZID
        ,g_dlv_cost_budget_tab( cnt ).budget_year          -- �\�Z�N�x
        ,g_dlv_cost_budget_tab( cnt ).target_month         -- ��
        ,g_dlv_cost_budget_tab( cnt ).base_code            -- ���_�R�[�h
        ,g_dlv_cost_budget_tab( cnt ).item_code            -- �i�ڃR�[�h
        ,g_dlv_cost_budget_tab( cnt ).bottle_qty           -- ���ʁi�{�j
        ,g_dlv_cost_budget_tab( cnt ).cs_qty               -- ���ʁiCS�j
        ,g_dlv_cost_budget_tab( cnt ).dlv_cost_budget_amt  -- �^����\�Z���z
        --WHO�J����
        ,cn_created_by
        ,SYSDATE
        ,cn_last_updated_by
        ,SYSDATE
        ,cn_last_update_login
        ,cn_request_id
        ,cn_program_application_id
        ,cn_program_id
        ,SYSDATE
      );
      -- ���팏��
      gn_normal_cnt := gn_normal_cnt + 1;
    END LOOP insert_loop;
--
  EXCEPTION
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
      ov_retcode := cv_status_error;
--
  END insert_dlv_cost_budget;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
     ov_errbuf     OUT VARCHAR2      --   �G���[�E���b�Z�[�W
    ,ov_retcode    OUT VARCHAR2      --   ���^�[���E�R�[�h
    ,ov_errmsg     OUT VARCHAR2      --   ���[�U�[�E�G���[�E���b�Z�[�W
  )
  IS
    -- ===============================
    -- �錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_prg_name            CONSTANT VARCHAR2(20) := 'submain'; -- �v���O������
    -- *** ���[�J���ϐ� ***
    lv_errbuf              VARCHAR2(5000);                          -- �G���[�E���b�Z�[�W
    lv_retcode             VARCHAR2(1);                             -- ���^�[���E�R�[�h
    lv_errmsg              VARCHAR2(5000);                          -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_out_msg             VARCHAR2(2000);                          -- �o�̓��b�Z�[�W
    lb_retcode             BOOLEAN;                                 -- ���b�Z�[�W�o�͂̃��^�[���E�R�[�h
    lv_yearplan_calender   VARCHAR2(30);                            -- �N�Ԕ̔��v��J�����_�̒l�Z�b�g��
    lt_budget_year         xxcsm_item_plan_headers.plan_year%TYPE;  -- ���i�v����
--
  BEGIN
--
    ov_retcode := cv_status_normal;
    -- �O���[�o���ϐ��̏�����
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
    gn_warn_cnt   := 0;
    gn_data_cnt   := 0;
    -- ====================================
    -- A-1.��������
    -- ====================================
    init(
       ov_errbuf              =>   lv_errbuf               -- �G���[�E���b�Z�[�W
      ,ov_retcode             =>   lv_retcode              -- ���^�[���E�R�[�h
      ,ov_errmsg              =>   lv_errmsg               -- ���[�U�[�E�G���[�E���b�Z�[�W
      ,ov_yearplan_calender   =>   lv_yearplan_calender    -- �N�Ԕ̔��v��J�����_�̒l�Z�b�g��
    );
    IF( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
    -- ====================================
    -- A-2.�\�Z�N�x���o����
    -- ====================================
    get_budget_year(
       ov_errbuf              =>   lv_errbuf               -- �G���[�E���b�Z�[�W
      ,ov_retcode             =>   lv_retcode              -- ���^�[���E�R�[�h
      ,ov_errmsg              =>   lv_errmsg               -- ���[�U�[�E�G���[�E���b�Z�[�W
      ,iv_yearplan_calender   =>   lv_yearplan_calender    -- �N�Ԕ̔��v��J�����_�̒l�Z�b�g��
    );
    IF( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
    -- ====================================
    -- A-3.���i�v��e�[�u����񒊏o����
    -- ====================================
    get_item_plan_info(
       ov_errbuf       =>    lv_errbuf              -- �G���[�E���b�Z�[�W
      ,ov_retcode      =>    lv_retcode             -- ���^�[���E�R�[�h
      ,ov_errmsg       =>    lv_errmsg              -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
    IF( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
    -- ====================================
    -- A-10.�^����\�Z�e�[�u���폜����
    -- ====================================
    -- �o�^�f�[�^�����芎�A�G���[���Ȃ��ꍇ
    IF( g_dlv_cost_budget_tab.COUNT > 0 ) THEN
      delete_dlv_cost_budget(
         ov_errbuf       =>    lv_errbuf          -- �G���[�E���b�Z�[�W
        ,ov_retcode      =>    lv_retcode         -- ���^�[���E�R�[�h
        ,ov_errmsg       =>    lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W
      );
      IF( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
      -- ====================================
      -- A-11.�^����\�Z�e�[�u���o�^����
      -- ====================================
      insert_dlv_cost_budget(
         ov_errbuf     =>    lv_errbuf              -- �G���[�E���b�Z�[�W
        ,ov_retcode    =>    lv_retcode             -- ���^�[���E�R�[�h
        ,ov_errmsg     =>    lv_errmsg              -- ���[�U�[�E�G���[�E���b�Z�[�W
      );
      IF( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
    END IF;
--
  EXCEPTION
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
      ov_retcode := cv_status_error;
--
  END submain;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : �R���J�����g���s�t�@�C���o�^�v���V�[�W��
   **********************************************************************************/
--
  PROCEDURE main(
     errbuf        OUT VARCHAR2        --   �G���[�E���b�Z�[�W
    ,retcode       OUT VARCHAR2        --   ���^�[���E�R�[�h
  )
  IS
--
    -- ===============================
    -- �錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_prg_name        CONSTANT VARCHAR2(5)  := 'main';             -- �v���O������
    cv_target_rec_msg  CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90000'; -- �Ώی������b�Z�[�W
    cv_success_rec_msg CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90001'; -- �����������b�Z�[�W
    cv_error_rec_msg   CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90002'; -- �G���[�������b�Z�[�W
    cv_cnt_token       CONSTANT VARCHAR2(5)  := 'COUNT';            -- �������b�Z�[�W�p�g�[�N����
    cv_normal_msg      CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90004'; -- ����I�����b�Z�[�W
    cv_error_msg       CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90006'; -- �G���[�I���S���[���o�b�N
    -- *** ���[�J���ϐ� ***
    lv_errbuf         VARCHAR2(5000);       -- �G���[�E���b�Z�[�W
    lv_retcode        VARCHAR2(1);          -- ���^�[���E�R�[�h
    lv_errmsg         VARCHAR2(5000);       -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_out_msg        VARCHAR2(2000);       -- �o�̓��b�Z�[�W
    lv_message_code   VARCHAR2(100);        -- �I�����b�Z�[�W
    lb_retcode        BOOLEAN;              -- ���b�Z�[�W�o�͂̃��^�[���E�R�[�h
--
  BEGIN
--
    -- �R���J�����g�w�b�_���b�Z�[�W�o�͊֐��̌Ăяo��
    xxccp_common_pkg.put_log_header(
       ov_retcode => lv_retcode
      ,ov_errbuf  => lv_errbuf
      ,ov_errmsg  => lv_errmsg
    );
    --
    IF( lv_retcode = cv_status_error ) THEN
      RAISE global_api_expt;
    END IF;
    -- ===============================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ===============================================
    submain(
       ov_errbuf    =>   lv_errbuf   -- �G���[�E���b�Z�[�W
      ,ov_retcode   =>   lv_retcode  -- ���^�[���E�R�[�h
      ,ov_errmsg    =>   lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
--
    --�G���[�o��
    IF( lv_retcode = cv_status_error ) THEN
      lb_retcode := xxcok_common_pkg.put_message_f(
                       in_which    =>   FND_FILE.OUTPUT
                      ,iv_message  =>   lv_errmsg  --���[�U�[�E�G���[�E���b�Z�[�W
                      ,in_new_line =>   1
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                       in_which    =>   FND_FILE.LOG
                      ,iv_message  =>   lv_errbuf  --�G���[���b�Z�[�W
                      ,in_new_line =>   1
                    );
    END IF;
    -- �ُ�I���̏ꍇ�̌����Z�b�g
    IF( lv_retcode = cv_status_error ) THEN
      gn_target_cnt := 0;
      gn_normal_cnt := 0;
      gn_error_cnt  := 1;
    END IF;
    --�Ώی����o��
    lv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_short_name_ccp
                    ,iv_name         => cv_target_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR( gn_target_cnt )
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                     in_which    =>   FND_FILE.OUTPUT
                    ,iv_message  =>   lv_out_msg
                    ,in_new_line =>   0
                  );
--
    --���������o��
    lv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_short_name_ccp
                    ,iv_name         => cv_success_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR( gn_normal_cnt )
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                     in_which    =>   FND_FILE.OUTPUT
                    ,iv_message  =>   lv_out_msg
                    ,in_new_line =>   0
                  );
--
    --�G���[�����o��
    lv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_short_name_ccp
                    ,iv_name         => cv_error_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR( gn_error_cnt )
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                     in_which    =>   FND_FILE.OUTPUT
                    ,iv_message  =>   lv_out_msg
                    ,in_new_line =>   1
                  );
--
    --�I�����b�Z�[�W
    IF( lv_retcode = cv_status_normal ) THEN
      lv_message_code := cv_normal_msg;
    ELSIF( lv_retcode = cv_status_error ) THEN
      lv_message_code := cv_error_msg;
    END IF;
    --
    lv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_short_name_ccp
                    ,iv_name         => lv_message_code
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                     in_which    =>   FND_FILE.OUTPUT
                    ,iv_message  =>   lv_out_msg
                    ,in_new_line =>   0
                  );
    --�X�e�[�^�X�Z�b�g
    retcode := lv_retcode;
    --�I���X�e�[�^�X���G���[�̏ꍇ��ROLLBACK����
    IF( retcode = cv_status_error ) THEN
      ROLLBACK;
    END IF;
--
  EXCEPTION
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000 );
      retcode := cv_status_error;
      ROLLBACK;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
      retcode := cv_status_error;
      ROLLBACK;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
      retcode := cv_status_error;
      ROLLBACK;
--
  END main;
--
END XXCOK023A01C;
/
