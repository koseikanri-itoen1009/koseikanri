CREATE OR REPLACE PACKAGE BODY XXCOK023A02C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOK023A02C(body)
 * Description      : �^������юZ�o
 * MD.050           : �^������юZ�o MD050_COK_023_A02
 * Version          : 1.3
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  get_parent_item_code_info   �e�i�ڃR�[�h�擾����(A-16)
 *  get_baracha_div_info        �o�����敪�擾����(A-15)
 *  insert_dlv_cost_result_sum  �^������ь��ʏW�v�e�[�u���o�^����(A-13)
 *  control_item_set_up_month   ���ڐݒ菈��(����)(A-12)
 *  del_dlv_cost_result_info    �^������уe�[�u���폜����(A-11)
 *  control_dlv_cost_result2    �^������уe�[�u�����䏈��2(A-10)
 *  get_mon_trans_freifht_info  �U�։^�����擾����(����)(A-9)
 *  check_lastmonth_fright_rslt �􂢑ւ� ���菈��(A-8)
 *  update_data_coprt_cntrl     �f�[�^�A�g����e�[�u���X�V����(A-7)
 *  insert_dlv_cost_result_info �^������уe�[�u���o�^����(A-6)
 *  update_dlv_cost_result_info �^������уe�[�u���X�V����(A-5)
 *  control_dlv_cost_result     �^������уe�[�u�����䏈��(A-4)
 *  get_sum_trans_freifht       �U�։^��(���ʁE���z�W�v�l)�擾����(A-3)
 *  get_trans_freifht_info      �U�։^�����擾����(����)(A-2)
 *  init                        ��������(A-1)
 *  submain                     ���C�������v���V�[�W��
 *  main                        �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009/01/13    1.0   I.Takahashi      �V�K�쐬
 *  2009/02/09    1.1   A.Yano           [��QCOK_025] ���b�N�擾�s��Ή�
 *  2009/02/23    1.2   T.Taniguchi      [��QCOK_055] ��������A��������s��Ή�
 *  2009/04/23    1.3   A.Yano           [��QT1_0765] �\�[�g���s��Ή�
 *
 *****************************************************************************************/
--
  -- ===============================
  -- �O���[�o���萔
  -- ===============================
  -- �X�e�[�^�X�E�R�[�h
  cv_status_normal          CONSTANT VARCHAR2(1)  := xxccp_common_pkg.set_status_normal; -- ����:0
  cv_status_warn            CONSTANT VARCHAR2(1)  := xxccp_common_pkg.set_status_warn;   -- �x��:1
  cv_status_error           CONSTANT VARCHAR2(1)  := xxccp_common_pkg.set_status_error;  -- �ُ�:2
  -- WHO�J����
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
  cv_pkg_name               CONSTANT VARCHAR2(20) := 'XXCOK023A02C';
  -- �A�v���P�[�V�����Z�k��
  cv_app_short_name_ccp     CONSTANT VARCHAR2(5)  := 'XXCCP';                  -- �A�v���P�[�V�����Z�k��'XXCCP'
  cv_app_short_name_cok     CONSTANT VARCHAR2(5)  := 'XXCOK';                  -- �A�v���P�[�V�����Z�k��'XXCOK'
  -- ���b�Z�[�W
  cv_no_parameter_msg       CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90008';       -- �R���J�����g���̓p�����[�^�Ȃ�
  cv_profile_err_msg        CONSTANT VARCHAR2(20) := 'APP-XXCOK1-00003';       -- �v���t�@�C���l�擾�G���[
  cv_org_id_nodata_msg      CONSTANT VARCHAR2(20) := 'APP-XXCOK1-00013';       -- �݌ɑg�DID�擾�擾�G���[
  cv_get_cop_date_err_msg   CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10170';       -- �ŏI�A�g�����擾�G���[
  cv_get_prnt_itmid_err_msg CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10171';       -- �e�i��ID�擾�G���[
  cv_get_baracha_dv_err_msg CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10172';       -- �o�����敪�擾�G���[
  cv_get_prnt_itmcd_err_msg CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10173';       -- �e�i�ڃR�[�h�擾�G���[
  cv_dpl_prnt_itmcd_err_msg CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10174';       -- �e�i�ڃR�[�h�d���G���[
  cv_lok_dlv_cstrsl_err_msg CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10175';       -- �^������у��b�N�G���[
  cv_lok_coprt_ctrl_err_msg CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10176';       -- �f�[�^�A�g����e�[�u�����b�N�G���[
  cv_chk_lstmnthcls_err_msg CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10177';       -- �O���^������`�F�b�N�G���[
  cv_dl_lok_dlv_cst_err_msg CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10347';       -- �^������э폜���b�N�G���[
  cv_get_prcss_date_err_msg CONSTANT VARCHAR2(20) := 'APP-XXCOK1-00028';       -- �Ɩ��������t�擾�G���[
  cv_month_sum_cnt_msg      CONSTANT VARCHAR2(20) := 'APP-XXCOK1-00091';       -- �������ʏ�������
  cv_day_proc_count_msg     CONSTANT VARCHAR2(20) := 'APP-XXCOK1-00092';       -- �������я�������
  cv_month_result_cnt_msg   CONSTANT VARCHAR2(20) := 'APP-XXCOK1-00093';       -- �������я�������
  -- �g�[�N��
  cv_profile_token          CONSTANT VARCHAR2(10) := 'PROFILE';                -- �v���t�@�C����
  cv_item_code_token        CONSTANT VARCHAR2(10) := 'ITEM_CODE';              -- �i�ڃR�[�h
  cv_org_code_token         CONSTANT VARCHAR2(10) := 'ORG_CODE';               -- �݌ɑg�D�R�[�h
  cv_seigyo_id_token        CONSTANT VARCHAR2(20) := 'SEIGYO_ID';              -- ����ID
  cv_target_year_token      CONSTANT VARCHAR2(20) := 'TARGET_YEAR';            -- ���Ώ۔N�x
  cv_target_month_token     CONSTANT VARCHAR2(20) := 'TARGET_MONTH';           -- ��
  cv_arrival_date_token     CONSTANT VARCHAR2(20) := 'ARRIVAL_DATE';           -- ���ד�
  cv_kyoten_code_token      CONSTANT VARCHAR2(20) := 'KYOTEN_CODE';            -- ���_�R�[�h
  cv_small_lot_class_token  CONSTANT VARCHAR2(20) := 'SMALL_LOT_CLASS';        -- �����敪
  cv_item_id_token          CONSTANT VARCHAR2(20) := 'ITEM_ID';                -- �i��ID
  -- �v���t�@�C������
  cv_org_code_sales         CONSTANT VARCHAR2(30) := 'XXCOK1_ORG_CODE_SALES';        -- XXCOK:�݌ɑg�D�R�[�h_�c�Ƒg�D
  cv_item_div_h             CONSTANT VARCHAR2(30) := 'XXCOS1_ITEM_DIV_H';            -- XXCOS:�{�Џ��i�敪
  cv_month_seq_id           CONSTANT VARCHAR2(30) := 'XXCOK1_COST_RESULT_MONTH_SEQ'; -- XXCOK1:��������ID
  cv_day_seq_id             CONSTANT VARCHAR2(30) := 'XXCOK1_COST_RESULT_DAY_SEQ';   -- XXCOK1:��������ID
  -- �o�����敪
  cn_baracya_type           CONSTANT NUMBER       := 1;    -- �o����
  -- �{�Џ��i�敪
  cv_office_item_drink      CONSTANT VARCHAR2(1)  := '2';  -- �h�����N
  -- �􂢊������茋��
  cv_arai_gae_on            CONSTANT VARCHAR2(1)  := '1';  -- ������������
  cv_arai_gae_off           CONSTANT VARCHAR2(1)  := '0';  -- ���������Ȃ�
  -- �ŐV���R�[�h
  cv_new_record             CONSTANT VARCHAR2(1)  := 'Y';
  -- ���l
  cn_zero                   CONSTANT NUMBER       := 0;
  cn_one                    CONSTANT NUMBER       := 1;
  -- ���ߋ敪
  cv_type_y                 CONSTANT VARCHAR2(1)  := 'Y';  -- �^�C�v�FY
  cv_type_n                 CONSTANT VARCHAR2(1)  := 'N';  -- �^�C�v�FN
  -- ���Z���錎��(�O�������߂�)
  cn_month_count            CONSTANT NUMBER       := -1;
  -- ===============================
  -- �O���[�o���ϐ�
  -- ===============================
  gn_target_cnt             NUMBER;            -- ���� �Ώی���
  gn_normal_cnt             NUMBER;            -- ���� ���팏��
  gn_error_cnt              NUMBER;            -- ���� �G���[����
  gn_month_target_cnt1      NUMBER;            -- ���� �Ώی��� ����
  gn_month_normal_cnt1      NUMBER;            -- ���� ���팏�� ����
  gn_month_error_cnt1       NUMBER;            -- ���� �G���[���� ����
  gn_month_target_cnt2      NUMBER;            -- ���� �Ώی��� ����
  gn_month_normal_cnt2      NUMBER;            -- ���� ���팏�� ����
  gn_month_error_cnt2       NUMBER;            -- ���� �G���[���� ����
  gn_warn_cnt               NUMBER;            -- �X�L�b�v����
  gn_organization_id        NUMBER;            -- �݌ɑg�DID
  gv_item_div_h             VARCHAR2(20);      -- �{�Џ��i�敪��
  gd_day_last_coprt_date    DATE;              -- �ŏI�A�g����(����)
  gd_month_last_coprt_date  DATE;              -- �ŏI�A�g����(����)
  gn_day_control_id         NUMBER;            -- ����ID(����)
  gn_month_control_id       NUMBER;            -- ����ID(����)
  gd_process_date           DATE;              -- �Ɩ��������t
  gd_sysdate                DATE;              -- �V�X�e�����t
  gv_check_result           VARCHAR2(1);       -- �􂢑ւ�����
  gv_day_process_result     VARCHAR2(3);       -- �������я������ʃX�e�[�^�X
  gv_month_proc_result      VARCHAR2(3);       -- �������я������ʃX�e�[�^�X
  gv_process_date_ym        VARCHAR2(6);       -- ����̎��s���̑O��
  gv_target_year            VARCHAR2(4);       -- �����̑Ώ۔N�x
  gv_target_month           VARCHAR2(2);       -- �����̑Ώی�
  -- ===============================
  -- �O���[�o��RECORD�^
  -- ===============================
  -- �U�։^���e�[�u��
  TYPE g_trans_freifht_rtype IS RECORD(
     target_year         VARCHAR2(4)                                     -- �Ώ۔N��
    ,target_month        VARCHAR2(2)                                     -- �Ώی�
    ,arrival_date        xxwsh_order_headers_all.arrival_date%TYPE       -- ���ד�
    ,jurisdicyional_hub  xxwip_transfer_fare_inf.jurisdicyional_hub%TYPE -- �Ǌ����_
    ,parent_item_code    xxwip_transfer_fare_inf.item_code%TYPE          -- �e�i�ڃR�[�h
    ,small_division      fnd_lookup_values.attribute6%TYPE               -- �����敪
    ,sum_actual_qty      xxwip_transfer_fare_inf.actual_qty%TYPE         -- ���ې���(�W�v�l)
    ,sum_amount          xxwip_transfer_fare_inf.amount%TYPE             -- ���z(�W�v�l)
  );
  -- �^������ь��ʏW�v�e�[�u��
  TYPE g_dlv_cost_result_sum_rtype IS RECORD(
     target_year         VARCHAR2(4)                                     -- �Ώ۔N��
    ,target_month        VARCHAR2(2)                                     -- �Ώی�
    ,jurisdicyional_hub  xxwip_transfer_fare_inf.jurisdicyional_hub%TYPE -- �Ǌ����_
    ,parent_item_code    xxwip_transfer_fare_inf.item_code%TYPE          -- �e�i�ڃR�[�h
    ,small_division      fnd_lookup_values.attribute6%TYPE               -- �����敪
    ,sum_actual_qty      xxwip_transfer_fare_inf.actual_qty%TYPE         -- ���ې���(�W�v�l)
    ,sum_amount          xxwip_transfer_fare_inf.amount%TYPE             -- ���z(�W�v�l)
  );
  -- ===============================
  -- �O���[�o��TABLE�^
  -- ===============================
  -- �U�։^���e�[�u��
  TYPE g_trans_freifht_ttype IS TABLE OF g_trans_freifht_rtype
  INDEX BY BINARY_INTEGER;
  -- �^������ь��ʏW�v�e�[�u��
  TYPE g_dlv_cost_result_sum_ttype IS TABLE OF g_dlv_cost_result_sum_rtype
  INDEX BY BINARY_INTEGER;
  -- ===============================
  -- �O���[�o��PL/SQL�\
  -- ===============================
  -- �U�։^���e�[�u��
  g_trans_freifht_tab         g_trans_freifht_ttype;         -- �U�։^���e�[�u��PL/SQL�\
  -- �^������ь��ʏW�v�e�[�u��
  g_dlv_cost_result_sum_tab   g_dlv_cost_result_sum_ttype;   -- �^������ь��ʏW�v�e�[�u��PL/SQL�\
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
  global_lock_expt            EXCEPTION;      -- ���b�N������O
  PRAGMA EXCEPTION_INIT( global_api_others_expt, -20000 );
  PRAGMA EXCEPTION_INIT( global_lock_expt, -54 );
--
  /**********************************************************************************
   * Procedure Name   : get_parent_item_code_info
   * Description      : �e�i�ڃR�[�h�擾����(A-16)
   ***********************************************************************************/
  PROCEDURE get_parent_item_code_info(
     ov_errbuf       OUT VARCHAR2       -- �G���[�E���b�Z�[�W
    ,ov_retcode      OUT VARCHAR2       -- ���^�[���E�R�[�h
    ,ov_errmsg       OUT VARCHAR2       -- ���[�U�[�E�G���[�E���b�Z�[�W
    ,in_item_id      IN  NUMBER         -- �e�i��ID
    ,ov_item_no      OUT VARCHAR2       -- �e�i�ڃR�[�h
  )
  IS
    -- ===============================
    -- �錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_prg_name      CONSTANT VARCHAR2(30) := 'get_parent_item_code_info'; -- �v���O������
    -- *** ���[�J���ϐ� ***
    lv_errbuf        VARCHAR2(5000);      -- �G���[�E���b�Z�[�W
    lv_retcode       VARCHAR2(3);         -- ���^�[���E�R�[�h
    lv_errmsg        VARCHAR2(5000);      -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_out_msg       VARCHAR2(2000);      -- �o�̓��b�Z�[�W
    lb_retcode       BOOLEAN;             -- ���b�Z�[�W�o�͂̃��^�[���E�R�[�h
--
  BEGIN
--
    ov_retcode := cv_status_normal;
--
    -- =============================================
    -- A-16.2 �e�i�ڃR�[�h�擾
    -- =============================================
    SELECT iimb.item_no  AS item_no  -- �e�i�ڃR�[�h
    INTO   ov_item_no
    FROM   ic_item_mst_b   iimb      -- OPM�i�ڃ}�X�^
    WHERE  iimb.item_id    = in_item_id      -- �e�i��ID
    ;
--
  EXCEPTION
    -- *** �e�i�ڃR�[�h�擾�G���[ ��O�n���h�� ****
    WHEN NO_DATA_FOUND THEN
      lv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_short_name_cok
                      ,iv_name         => cv_get_prnt_itmcd_err_msg
                      ,iv_token_name1  => cv_item_id_token           -- �i��ID
                      ,iv_token_value1 => TO_CHAR( in_item_id )      -- �i��ID
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                       in_which    =>   FND_FILE.OUTPUT
                      ,iv_message  =>   lv_out_msg
                      ,in_new_line =>   0
                    );
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg,1,5000 );
      ov_retcode := cv_status_error;
    -- *** �e�i�ڃR�[�h�d���G���[ ��O�n���h�� ****
    WHEN TOO_MANY_ROWS THEN
      lv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_short_name_cok
                      ,iv_name         => cv_dpl_prnt_itmcd_err_msg
                      ,iv_token_name1  => cv_item_id_token           -- �i��ID
                      ,iv_token_value1 => TO_CHAR( in_item_id )      -- �i��ID
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
  END get_parent_item_code_info;
--
  /**********************************************************************************
   * Procedure Name   : get_baracha_div_info
   * Description      : �o�����敪�擾����(A-15)
   ***********************************************************************************/
  PROCEDURE get_baracha_div_info(
     ov_errbuf         OUT VARCHAR2        --   �G���[�E���b�Z�[�W
    ,ov_retcode        OUT VARCHAR2        --   ���^�[���E�R�[�h
    ,ov_errmsg         OUT VARCHAR2        --   ���[�U�[�E�G���[�E���b�Z�[�W
    ,iv_item_code      IN  VARCHAR2        --   �i�ڃR�[�h
    ,on_baracha_div    OUT NUMBER          --   �o�����敪
  )
  IS
    -- ===============================
    -- �錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_prg_name      CONSTANT VARCHAR2(30) := 'get_baracha_div_info'; -- �v���O������
    -- *** ���[�J���ϐ� ***
    lv_errbuf        VARCHAR2(5000);      -- �G���[�E���b�Z�[�W
    lv_retcode       VARCHAR2(3);         -- ���^�[���E�R�[�h
    lv_errmsg        VARCHAR2(5000);      -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_out_msg       VARCHAR2(2000);      -- �o�̓��b�Z�[�W
    lb_retcode       BOOLEAN;             -- ���b�Z�[�W�o�͂̃��^�[���E�R�[�h
--
  BEGIN
--
    ov_retcode := cv_status_normal;
    -- =============================================
    -- A-15.�o�����敪�擾
    -- =============================================
    SELECT xsib.baracha_div     AS baracha_div  -- �o�����敪
    INTO   on_baracha_div
    FROM   xxcmm_system_items_b    xsib         -- �i�ڃA�h�I���}�X�^
    WHERE  xsib.item_code     = iv_item_code
    ;
--
  EXCEPTION
    -- *** �o�����敪�擾�G���[ ��O�n���h�� ****
    WHEN NO_DATA_FOUND THEN
      lv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_short_name_cok
                      ,iv_name         => cv_get_baracha_dv_err_msg
                      ,iv_token_name1  => cv_item_code_token -- �i�ڃR�[�h
                      ,iv_token_value1 => iv_item_code       -- �i�ڃR�[�h
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
  END get_baracha_div_info;
--
  /**********************************************************************************
   * Procedure Name   : insert_dlv_cost_result_sum
   * Description      : �^������ь��ʏW�v�e�[�u���o�^����(A-13)
   ***********************************************************************************/
  PROCEDURE insert_dlv_cost_result_sum(
     ov_errbuf              OUT VARCHAR2       -- �G���[�E���b�Z�[�W
    ,ov_retcode             OUT VARCHAR2       -- ���^�[���E�R�[�h
    ,ov_errmsg              OUT VARCHAR2       -- ���[�U�[�E�G���[�E���b�Z�[�W
  )
  IS
    -- ===============================
    -- �錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_prg_name      CONSTANT VARCHAR2(30) := 'insert_dlv_cost_result_sum'; -- �v���O������
    -- *** ���[�J���ϐ� ***
    lv_errbuf        VARCHAR2(5000);      -- �G���[�E���b�Z�[�W
    lv_retcode       VARCHAR2(3);         -- ���^�[���E�R�[�h
    lv_errmsg        VARCHAR2(5000);      -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_out_msg       VARCHAR2(2000);      -- �o�̓��b�Z�[�W
    lb_retcode       BOOLEAN;             -- ���b�Z�[�W�o�͂̃��^�[���E�R�[�h
--
  BEGIN
--
    ov_retcode := cv_status_normal;
--
    <<insert_loop2>>
    FOR ln_count IN 1 .. g_dlv_cost_result_sum_tab.COUNT LOOP
      -- =============================================
      -- �^������ь��ʏW�v�e�[�u���o�^
      -- =============================================
      INSERT INTO xxcok_dlv_cost_result_sum (
         result_sum_id                  -- �^������яW�vID
        ,target_year                    -- �Ώ۔N�x
        ,target_month                   -- ��
        ,base_code                      -- ���_�R�[�h
        ,item_code                      -- �i�ڃR�[�h
        ,small_amt_type                 -- �����敪
        ,sum_cs_qty                     -- �W�v����(C/S)
        ,sum_amt                        -- �W�v���z
        ,created_by                     -- �쐬��
        ,creation_date                  -- �쐬��
        ,last_updated_by                -- �ŏI�X�V��
        ,last_update_date               -- �ŏI�X�V��
        ,last_update_login              -- �ŏI�X�V���O�C��
        ,request_id                     -- �v��ID
        ,program_application_id         -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
        ,program_id                     -- �R���J�����g�E�v���O����ID
        ,program_update_date            -- �v���O�����X�V��
      ) VALUES (
         xxcok_dlv_cost_result_sum_s01.nextval                    -- �^������яW�vID
        ,g_dlv_cost_result_sum_tab( ln_count ).target_year        -- �Ώ۔N�x
        ,g_dlv_cost_result_sum_tab( ln_count ).target_month       -- ��
        ,g_dlv_cost_result_sum_tab( ln_count ).jurisdicyional_hub -- ���_�R�[�h
        ,g_dlv_cost_result_sum_tab( ln_count ).parent_item_code   -- �i�ڃR�[�h
        ,g_dlv_cost_result_sum_tab( ln_count ).small_division     -- �����敪
        ,g_dlv_cost_result_sum_tab( ln_count ).sum_actual_qty     -- ����(C/S)
        ,g_dlv_cost_result_sum_tab( ln_count ).sum_amount         -- ���z
        ,cn_created_by                                            -- �쐬�҂�USER_ID
        ,SYSDATE                                                  -- �쐬����
        ,cn_last_updated_by                                       -- �ŏI�X�V�҂�USER_ID
        ,SYSDATE                                                  -- �ŏI�X�V����
        ,cn_last_update_login                                     -- �ŏI�X�V����LOGIN_ID
        ,cn_request_id                                            -- �v��ID
        ,cn_program_application_id                                -- �v���O�����A�v���P�[�V����ID
        ,cn_program_id                                            -- �v���O����ID
        ,SYSDATE                                                  -- �v���O�����ŏI�X�V��
      );
      -- ���������̏W�v
      gn_month_normal_cnt2 := gn_month_normal_cnt2 + 1;
    END LOOP insert_loop2;
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
  END insert_dlv_cost_result_sum;
--
  /**********************************************************************************
   * Procedure Name   : del_dlv_cost_result_info
   * Description      : �^������уe�[�u���폜����(A-11)
   ***********************************************************************************/
  PROCEDURE del_dlv_cost_result_info(
     ov_errbuf       OUT VARCHAR2      -- �G���[�E���b�Z�[�W
    ,ov_retcode      OUT VARCHAR2      -- ���^�[���E�R�[�h
    ,ov_errmsg       OUT VARCHAR2      -- ���[�U�[�E�G���[�E���b�Z�[�W
  )
  IS
    -- ===============================
    -- �錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_prg_name      CONSTANT VARCHAR2(30) := 'del_dlv_cost_result_info'; -- �v���O������
    -- *** ���[�J���ϐ� ***
    lv_errbuf        VARCHAR2(5000);      -- �G���[�E���b�Z�[�W
    lv_retcode       VARCHAR2(3);         -- ���^�[���E�R�[�h
    lv_errmsg        VARCHAR2(5000);      -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_out_msg       VARCHAR2(2000);      -- �o�̓��b�Z�[�W
    lb_retcode       BOOLEAN;             -- ���b�Z�[�W�o�͂̃��^�[���E�R�[�h
--
  BEGIN
--
    ov_retcode := cv_status_normal;
    -- =============================================
    -- �^������уe�[�u���폜
    -- =============================================
    DELETE FROM xxcok_dlv_cost_result_info xdcri
    WHERE xdcri.target_year  = gv_target_year
    AND   xdcri.target_month = gv_target_month
    ;
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
  END del_dlv_cost_result_info;
--
  /**********************************************************************************
   * Procedure Name   : insert_dlv_cost_result_info
   * Description      : �^������уe�[�u���o�^����(A-6)
   ***********************************************************************************/
  PROCEDURE insert_dlv_cost_result_info(
     ov_errbuf              OUT VARCHAR2     -- �G���[�E���b�Z�[�W
    ,ov_retcode             OUT VARCHAR2     -- ���^�[���E�R�[�h
    ,ov_errmsg              OUT VARCHAR2     -- ���[�U�[�E�G���[�E���b�Z�[�W
    ,iv_target_year         IN  VARCHAR2     -- �Ώ۔N�x
    ,iv_target_month        IN  VARCHAR2     -- ��
    ,id_arrival_date        IN  DATE         -- ���ד�
    ,iv_base_code           IN  VARCHAR2     -- ���_�R�[�h
    ,iv_item_code           IN  VARCHAR2     -- �i�ڃR�[�h
    ,iv_small_amt_type      IN  VARCHAR2     -- �����敪
    ,in_cs_qty              IN  NUMBER       -- ����(C/S)
    ,in_dlv_cost_result_amt IN  NUMBER       -- ���z
  )
  IS
    -- ===============================
    -- �錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_prg_name      CONSTANT VARCHAR2(30) := 'insert_dlv_cost_result_info'; -- �v���O������
    -- *** ���[�J���ϐ� ***
    lv_errbuf        VARCHAR2(5000);      -- �G���[�E���b�Z�[�W
    lv_retcode       VARCHAR2(3);         -- ���^�[���E�R�[�h
    lv_errmsg        VARCHAR2(5000);      -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_out_msg       VARCHAR2(2000);      -- �o�̓��b�Z�[�W
    lb_retcode       BOOLEAN;             -- ���b�Z�[�W�o�͂̃��^�[���E�R�[�h
--
  BEGIN
--
    ov_retcode := cv_status_normal;
--
    -- =============================================
    -- �^������уe�[�u���o�^
    -- =============================================
    INSERT INTO xxcok_dlv_cost_result_info (
       result_id                 -- �^�������ID
      ,target_year               -- �Ώ۔N�x
      ,target_month              -- ��
      ,arrival_date              -- ���ד�
      ,base_code                 -- ���_�R�[�h
      ,item_code                 -- �i�ڃR�[�h
      ,small_amt_type            -- �����敪
      ,cs_qty                    -- ����(C/S)
      ,dlv_cost_result_amt       -- ���z
      ,created_by                -- �쐬��
      ,creation_date             -- �쐬��
      ,last_updated_by           -- �ŏI�X�V��
      ,last_update_date          -- �ŏI�X�V��
      ,last_update_login         -- �ŏI�X�V���O�C��
      ,request_id                -- �v��ID
      ,program_application_id    -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
      ,program_id                -- �R���J�����g�E�v���O����ID
      ,program_update_date       -- �v���O�����X�V��
    ) VALUES (
       xxcok_dlv_cost_result_info_s01.nextval --�^�������ID
      ,iv_target_year            -- �Ώ۔N�x
      ,iv_target_month           -- ��
      ,id_arrival_date           -- ���ד�
      ,iv_base_code              -- ���_�R�[�h
      ,iv_item_code              -- �i�ڃR�[�h
      ,iv_small_amt_type         -- �����敪
      ,in_cs_qty                 -- ����(C/S)
      ,in_dlv_cost_result_amt    -- ���z
      ,cn_created_by             -- �쐬�҂�USER_ID
      ,SYSDATE                   -- �쐬����
      ,cn_last_updated_by        -- �ŏI�X�V�҂�USER_ID
      ,SYSDATE                   -- �ŏI�X�V����
      ,cn_last_update_login      -- �ŏI�X�V����LOGIN_ID
      ,cn_request_id             -- �v��ID
      ,cn_program_application_id -- �v���O�����A�v���P�[�V����ID
      ,cn_program_id             -- �v���O����ID
      ,SYSDATE                   -- �v���O�����ŏI�X�V��
    );
--
    -- ���������̏W�v
    IF( gv_check_result = cv_arai_gae_off ) THEN
      gn_normal_cnt := gn_normal_cnt + 1;
    ELSE
      gn_month_normal_cnt1 := gn_month_normal_cnt1 + 1;
    END IF;
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
  END insert_dlv_cost_result_info;
--
  /**********************************************************************************
   * Procedure Name   : control_dlv_cost_result2
   * Description      : �^������уe�[�u�� ���䏈��(A-10)
   ***********************************************************************************/
  PROCEDURE control_dlv_cost_result2(
     ov_errbuf         OUT VARCHAR2      --   �G���[�E���b�Z�[�W
    ,ov_retcode        OUT VARCHAR2      --   ���^�[���E�R�[�h
    ,ov_errmsg         OUT VARCHAR2      --   ���[�U�[�E�G���[�E���b�Z�[�W
  )
  IS
    -- ===============================
    -- �錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_prg_name      CONSTANT VARCHAR2(30) := 'control_dlv_cost_result2'; -- �v���O������
    -- *** ���[�J���ϐ� ***
    lv_errbuf        VARCHAR2(5000);      -- �G���[�E���b�Z�[�W
    lv_retcode       VARCHAR2(3);         -- ���^�[���E�R�[�h
    lv_errmsg        VARCHAR2(5000);      -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_out_msg       VARCHAR2(2000);      -- �o�̓��b�Z�[�W
    lb_retcode       BOOLEAN;             -- ���b�Z�[�W�o�͂̃��^�[���E�R�[�h
--
    -- *** ���[�J���J�[�\�� ***
    CURSOR l_lock_cur
    IS
      SELECT xdcri.result_id AS result_id         -- �^�������ID
      FROM   xxcok_dlv_cost_result_info xdcri     -- �^������уe�[�u��
      WHERE  xdcri.target_year  = gv_target_year  -- �Ώ۔N�x
      AND    xdcri.target_month = gv_target_month -- ��
      FOR UPDATE OF xdcri.result_id NOWAIT
    ;
    l_lock_rec l_lock_cur%ROWTYPE;
--
  BEGIN
--
    ov_retcode := cv_status_normal;
    -- =============================================
    -- 2. �^������уe�[�u�����b�N�擾
    -- =============================================
    OPEN  l_lock_cur;
    FETCH l_lock_cur INTO l_lock_rec;
    CLOSE l_lock_cur;
--
    -- =============================================
    -- 3. �^������уe�[�u���Ƀf�[�^�����݂���ꍇ
    -- =============================================
    IF( l_lock_rec.result_id IS NOT NULL ) THEN
      -- =============================================
      -- A-11.�^������уe�[�u���폜���� �ďo
      -- =============================================
      del_dlv_cost_result_info(
        ov_errbuf       => lv_errbuf        -- �G���[�E���b�Z�[�W
       ,ov_retcode      => lv_retcode       -- ���^�[���E�R�[�h
       ,ov_errmsg       => lv_errmsg        -- ���[�U�[�E�G���[�E���b�Z�[�W
      );
      IF( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
    END IF;
--
    -- =============================================
    -- A-6.�^������уe�[�u���o�^���� �ďo
    -- =============================================
    <<insert_loop2>>
    FOR ln_count IN 1 .. g_trans_freifht_tab.COUNT LOOP
      insert_dlv_cost_result_info(
         ov_errbuf              => lv_errbuf                                          -- �G���[�E���b�Z�[�W
        ,ov_retcode             => lv_retcode                                         -- ���^�[���E�R�[�h
        ,ov_errmsg              => lv_errmsg                                          -- ���[�U�[�E�G���[�E���b�Z�[�W
        ,iv_target_year         => g_trans_freifht_tab( ln_count ).target_year        -- �Ώ۔N�x
        ,iv_target_month        => g_trans_freifht_tab( ln_count ).target_month       -- ��
        ,id_arrival_date        => g_trans_freifht_tab( ln_count ).arrival_date       -- ���ד�
        ,iv_base_code           => g_trans_freifht_tab( ln_count ).jurisdicyional_hub -- ���_�R�[�h
        ,iv_item_code           => g_trans_freifht_tab( ln_count ).parent_item_code   -- �i�ڃR�[�h
        ,iv_small_amt_type      => g_trans_freifht_tab( ln_count ).small_division     -- �����敪
        ,in_cs_qty              => g_trans_freifht_tab( ln_count ).sum_actual_qty     -- ����(C/S)
        ,in_dlv_cost_result_amt => g_trans_freifht_tab( ln_count ).sum_amount         -- ���z
      );
      IF( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
    END LOOP insert_loop2;
--
  EXCEPTION
    -- *** �^������у��b�N��O�n���h�� ****
    WHEN global_lock_expt THEN
      lv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_short_name_cok
                      ,iv_name         => cv_dl_lok_dlv_cst_err_msg
                      ,iv_token_name1  => cv_target_year_token
                      ,iv_token_value1 => gv_target_year
                      ,iv_token_name2  => cv_target_month_token
                      ,iv_token_value2 => gv_target_month
                    );
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
  END control_dlv_cost_result2;
--
  /**********************************************************************************
   * Procedure Name   : control_item_set_up_month
   * Description      : ���ڐݒ菈��(A-12)(����)
   ***********************************************************************************/
  PROCEDURE control_item_set_up_month(
     ov_errbuf               OUT VARCHAR2       -- �G���[�E���b�Z�[�W
    ,ov_retcode              OUT VARCHAR2       -- ���^�[���E�R�[�h
    ,ov_errmsg               OUT VARCHAR2       -- ���[�U�[�E�G���[�E���b�Z�[�W
  )
  IS
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_prg_name       CONSTANT VARCHAR2(30) := 'control_item_set_up_month'; -- �v���O������
    -- *** ���[�J���ϐ� ***
    lv_errbuf                VARCHAR2(5000);    -- �G���[�E���b�Z�[�W
    lv_retcode               VARCHAR2(3);       -- ���^�[���E�R�[�h
    lv_errmsg                VARCHAR2(5000);    -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_out_msg               VARCHAR2(2000);    -- �o�̓��b�Z�[�W
    lb_retcode               BOOLEAN;           -- ���b�Z�[�W�o�͂̃��^�[���E�R�[�h
    ln_out_count             NUMBER;            -- �o�͌���
    ln_loop_count            NUMBER;            -- LOOP����
    lt_bk_jurisdicyional_hub xxwip_transfer_fare_inf.jurisdicyional_hub%TYPE;-- �ޔ����� �Ǌ����_
    lt_bk_item_code          xxwip_transfer_fare_inf.item_code%TYPE;         -- �ޔ����� �i�ڃR�[�h(�q�i�ڃR�[�h)
    lt_bk_small_division     fnd_lookup_values.attribute6%TYPE;              -- �ޔ����� �����敪
    lv_bk_target_year        VARCHAR2(4);                                    -- �ޔ����� �Ώ۔N�x
    lv_bk_target_month       VARCHAR2(2);                                    -- �ޔ����� �Ώی�
    lt_bk_parent_item_code   xxwip_transfer_fare_inf.item_code%TYPE;         -- �ޔ����� �e�i�ڃR�[�h
    lt_sum_actual_qty        xxwip_transfer_fare_inf.actual_qty%TYPE;        -- ���ې���(�W�v�l)
    lt_sum_amount            xxwip_transfer_fare_inf.amount%TYPE;            -- ���z(�W�v�l)
    -- *** ���[�J���J�[�\�� ***
    -- �����i���ʁj
    CURSOR l_month_cur
    IS
      SELECT xdcr.target_year           AS target_year         -- �Ώ۔N�x
            ,xdcr.target_month          AS target_month        -- ��
            ,xdcr.base_code             AS base_code           -- ���_�R�[�h
            ,xdcr.item_code             AS item_code           -- �i�ڃR�[�h
            ,xdcr.small_amt_type        AS small_amt_type      -- �����敪
            ,xdcr.cs_qty                AS cs_qty              -- ����
            ,xdcr.dlv_cost_result_amt   AS dlv_cost_result_amt -- ���z
      FROM  xxcok_dlv_cost_result_info xdcr
      WHERE xdcr.target_year  = SUBSTRB( gv_process_date_ym, 1, 4 )
      AND   xdcr.target_month = SUBSTRB( gv_process_date_ym, 5, 2 )
      ORDER BY xdcr.base_code
              ,xdcr.item_code
              ,xdcr.small_amt_type
    ;
--
  BEGIN
--
    ov_retcode := cv_status_normal;
    -- =============================================
    -- �ϐ��̏�����
    -- =============================================
    lt_bk_jurisdicyional_hub := NULL;
    lt_bk_item_code          := NULL;
    lt_bk_small_division     := NULL;
    lv_bk_target_year        := NULL;
    lv_bk_target_month       := NULL;
    lt_bk_parent_item_code   := NULL;
    lt_sum_actual_qty        := cn_zero;
    lt_sum_amount            := cn_zero;
    ln_out_count             := cn_zero;
    ln_loop_count            := cn_zero;
--
    -- =============================================
    -- 1. ���ʗp�f�[�^�擾
    -- =============================================
    << month_loop >>
    FOR l_month_rec IN l_month_cur LOOP
      -- =============================================
      -- 1���ڂ̏ꍇ�܂��́A�O��ƍ���̋��_�R�[�h�A
      -- �i�ڃR�[�h�A�����敪����v�����ꍇ
      -- =============================================
      IF(    ln_loop_count            <> cn_zero                    )
        AND( lt_bk_jurisdicyional_hub <> l_month_rec.base_code      )   -- ���_�R�[�h
        OR ( lt_bk_parent_item_code   <> l_month_rec.item_code      )   -- �i�ڃR�[�h
        OR ( lt_bk_small_division     <> l_month_rec.small_amt_type )   -- �����敪
      THEN
        -- =============================================
        -- PL/SQL�\�ɑޔ�
        -- =============================================
        ln_out_count :=  ln_out_count + cn_one;
        -- �Ώی����̏W�v
        gn_month_target_cnt2 := gn_month_target_cnt2 + 1;
        g_dlv_cost_result_sum_tab( ln_out_count ).target_year        := lv_bk_target_year;        -- �Ώ۔N
        g_dlv_cost_result_sum_tab( ln_out_count ).target_month       := lv_bk_target_month;       -- ��
        g_dlv_cost_result_sum_tab( ln_out_count ).jurisdicyional_hub := lt_bk_jurisdicyional_hub; -- �Ǌ����_
        g_dlv_cost_result_sum_tab( ln_out_count ).parent_item_code   := lt_bk_parent_item_code;   -- �e�i�ڃR�[�h
        g_dlv_cost_result_sum_tab( ln_out_count ).small_division     := lt_bk_small_division;     -- �����敪
        g_dlv_cost_result_sum_tab( ln_out_count ).sum_actual_qty     := lt_sum_actual_qty;        -- ���ې���(�W�v�l)
        g_dlv_cost_result_sum_tab( ln_out_count ).sum_amount         := lt_sum_amount;            -- ���z(�W�v�l)
--
        -- =============================================
        -- ���ʂƋ��z�̏�����
        -- =============================================
        lt_sum_actual_qty := cn_zero;        -- ���ې���(�W�v�l)
        lt_sum_amount     := cn_zero;        -- ���z(�W�v�l)
        -- =============================================
        -- ���ʂƋ��z���Đݒ肷��
        -- =============================================
        lt_sum_actual_qty := l_month_rec.cs_qty;               -- ���ې���(�W�v�l)
        lt_sum_amount     := l_month_rec.dlv_cost_result_amt;  -- ���z(�W�v�l)
--
      ELSE
        -- =============================================
        -- ����(C/S)�A���z�l���W�v
        -- =============================================
        lt_sum_actual_qty := lt_sum_actual_qty + l_month_rec.cs_qty;
        lt_sum_amount     := lt_sum_amount     + l_month_rec.dlv_cost_result_amt;
      END IF;
--
      -- =============================================
      -- �ޔ����ڂɊi�[
      -- =============================================
      lv_bk_target_year        := l_month_rec.target_year;    -- �ޔ� �Ώ۔N�x
      lv_bk_target_month       := l_month_rec.target_month;   -- �ޔ� �Ώی�
      lt_bk_jurisdicyional_hub := l_month_rec.base_code;      -- �ޔ� �Ǌ����_
      lt_bk_small_division     := l_month_rec.small_amt_type; -- �ޔ� �����敪
      lt_bk_parent_item_code   := l_month_rec.item_code;      -- �ޔ� �e�i�ڃR�[�h
      -- LOOP�J�E���g
      ln_loop_count := ln_loop_count + cn_one;
--
    END LOOP month_loop;
    -- PL/SQL�\�ւ̏o�͌��������v
    ln_out_count :=  ln_out_count + cn_one;
    -- �Ώی����̏W�v
    gn_month_target_cnt2 := gn_month_target_cnt2 + 1;
    -- =============================================
    -- PL/SQL�\�ɑޔ�
    -- ���C�����[�v�̍ŏI�s
    -- =============================================
    g_dlv_cost_result_sum_tab( ln_out_count ).target_year        := lv_bk_target_year;        -- �Ώ۔N�x
    g_dlv_cost_result_sum_tab( ln_out_count ).target_month       := lv_bk_target_month;       -- ��
    g_dlv_cost_result_sum_tab( ln_out_count ).jurisdicyional_hub := lt_bk_jurisdicyional_hub; -- �Ǌ����_
    g_dlv_cost_result_sum_tab( ln_out_count ).parent_item_code   := lt_bk_parent_item_code;   -- �e�i�ڃR�[�h
    g_dlv_cost_result_sum_tab( ln_out_count ).small_division     := lt_bk_small_division;     -- �����敪
    g_dlv_cost_result_sum_tab( ln_out_count ).sum_actual_qty     := lt_sum_actual_qty;        -- ���ې���(�W�v�l)
    g_dlv_cost_result_sum_tab( ln_out_count ).sum_amount         := lt_sum_amount;            -- ���z(�W�v�l)
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
  END control_item_set_up_month;
--
  /**********************************************************************************
   * Procedure Name   : get_mon_trans_freifht_info
   * Description      : �U�։^�����擾����(����)(A-9)
   ***********************************************************************************/
  PROCEDURE get_mon_trans_freifht_info(
     ov_errbuf             OUT VARCHAR2      -- �G���[�E���b�Z�[�W
    ,ov_retcode            OUT VARCHAR2      -- ���^�[���E�R�[�h
    ,ov_errmsg             OUT VARCHAR2      -- ���[�U�[�E�G���[�E���b�Z�[�W
  )
  IS
    -- ===============================
    -- �錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_prg_name           CONSTANT VARCHAR2(30) := 'get_mon_trans_freifht_info'; -- �v���O������
    -- *** ���[�J���ϐ� ***
    lv_errbuf                 VARCHAR2(5000);    -- �G���[�E���b�Z�[�W
    lv_retcode                VARCHAR2(3);       -- ���^�[���E�R�[�h
    lv_errmsg                 VARCHAR2(5000);    -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_out_msg                VARCHAR2(2000);    -- �o�̓��b�Z�[�W
    lb_retcode                BOOLEAN;           -- ���b�Z�[�W�o�͂̃��^�[���E�R�[�h
    lt_item_code              xxwip_transfer_fare_inf.item_code%TYPE          DEFAULT NULL; -- �i�ڃR�[�h(�q�i�ڃR�[�h)
    -- ���ڑޔ�p
    lt_bk_arrival_date        xxwsh_order_headers_all.arrival_date%TYPE       DEFAULT NULL; -- ���ד�
    lt_bk_jurisdicyional_hub  xxwip_transfer_fare_inf.jurisdicyional_hub%TYPE DEFAULT NULL; -- �Ǌ����_
    lt_bk_item_code           xxwip_transfer_fare_inf.item_code%TYPE          DEFAULT NULL; -- �i�ڃR�[�h(�q�i�ڃR�[�h)
    lt_bk_parent_item_id      xxcmn_item_mst_b.parent_item_id%TYPE            DEFAULT NULL; -- �e�i��ID
    lt_bk_small_division      fnd_lookup_values.attribute6%TYPE               DEFAULT NULL; -- �����敪
    lv_bk_target_year         VARCHAR2(4) DEFAULT NULL;  -- �Ώ۔N�x
    lv_bk_target_month        VARCHAR2(2) DEFAULT NULL;  -- �Ώی�
    -- ����E�W�v�p
    lt_bk_baracha_div         xxcmm_system_items_b.baracha_div%TYPE           DEFAULT NULL; -- �o�����敪
    lt_bk_parent_item_code    xxwip_transfer_fare_inf.item_code%TYPE          DEFAULT NULL; -- �e�i�ڃR�[�h
    lt_baracha_div            xxcmm_system_items_b.baracha_div%TYPE           DEFAULT NULL; -- �o�����敪
    lt_parent_item_code       xxwip_transfer_fare_inf.item_code%TYPE          DEFAULT NULL; -- �e�i�ڃR�[�h
    lt_sum_actual_qty         xxwip_transfer_fare_inf.actual_qty%TYPE         DEFAULT 0;    -- ���ې���(�W�v�l)
    lt_sum_amount             xxwip_transfer_fare_inf.amount%TYPE             DEFAULT 0;    -- ���z(�W�v�l)
    ln_execute_count          NUMBER      DEFAULT 0;     -- �o�����`�F�b�N�ʉߌ���
    ln_out_count              NUMBER      DEFAULT 0;     -- �o�͌���
    -- �U�։^���J�[�\��(�����p)
    CURSOR trans_freifht_info_cur
    IS
      SELECT  xtfi.target_date            AS target_date        -- �Ώ۔N��
             ,xoha.arrival_date           AS arrival_date       -- ���ד�
             ,xtfi.jurisdicyional_hub     AS jurisdicyional_hub -- �Ǌ����_
             ,xtfi.item_code              AS item_code          -- �i�ڃR�[�h
             ,seq_0_v.parent_item_id      AS parent_item_id     -- �e�i�sID
             ,xsmv.small_amount_class     AS small_amount_class -- �����敪
             ,xtfi.actual_qty             AS actual_qty         -- ���ې���
             ,xtfi.amount                 AS amount             -- ���z
      FROM    xxwip_transfer_fare_inf  xtfi  -- �U�։^�����A�h�I���e�[�u��
             ,xxwsh_order_headers_all  xoha  -- �󒍃w�b�_�A�h�I���e�[�u��
             ,xxwsh_ship_method2_v     xsmv  -- �z���敪���VIEW2
             ,( SELECT ximb.parent_item_id  AS parent_item_id -- �e�i��ID
                      ,iimb.item_id         AS item_id        -- �i��ID
                      ,iimb.item_no         AS item_no        -- �i��NO
                FROM   mtl_system_items_b      msib     -- �i�ڃ}�X�^
                      ,ic_item_mst_b           iimb     -- OPM�i��
                      ,xxcmn_item_mst_b        ximb     -- OPM�i�ڃA�h�I��
                      ,mtl_category_sets_b     mcsb     -- �i�ڃJ�e�S���Z�b�g
                      ,mtl_category_sets_tl    mcst     -- �i�ڃJ�e�S���Z�b�g���{��
                      ,mtl_categories_b        mcb      -- �i�ڃJ�e�S���}�X�^
                      ,mtl_item_categories     mic      -- �i�ڃJ�e�S������
                WHERE  iimb.item_no             = msib.segment1
                AND    ximb.item_id             = iimb.item_id
                AND    mcst.category_set_id     = mcsb.category_set_id
                AND    mcb.structure_id         = mcsb.structure_id
                AND    mcb.category_id          = mic.category_id
                AND    mcsb.category_set_id     = mic.category_set_id
                AND    mcst.language            = USERENV( 'LANG' )
                AND    mcst.category_set_name   = gv_item_div_h
                AND    mcb.segment1             = cv_office_item_drink
                AND    msib.organization_id     = gn_organization_id
                AND    msib.organization_id     = mic.organization_id
                AND    msib.inventory_item_id   = mic.inventory_item_id
             )                         seq_0_v
      WHERE  xtfi.request_no                  = xoha.request_no
      AND    xtfi.delivery_date               = xoha.arrival_date
      AND    xtfi.goods_classe                = xoha.prod_class
      AND    xtfi.jurisdicyional_hub          = xoha.head_sales_branch
      AND    xtfi.delivery_whs                = xoha.deliver_from
      AND    xtfi.ship_to                     = xoha.result_deliver_to
      AND    xoha.latest_external_flag        = cv_new_record
      AND    xoha.result_shipping_method_code = xsmv.ship_method_code
      AND    seq_0_v.item_no(+)               = xtfi.item_code
      AND    xtfi.target_date                 = gv_process_date_ym
      ORDER BY xoha.arrival_date             -- ���ד�
              ,xtfi.jurisdicyional_hub       -- �Ǌ����_
              ,seq_0_v.parent_item_id        -- �e�i��ID
--�y2009/04/23 A.Yano Ver.1.3 START�z------------------------------------------------------
--              ,xtfi.item_code                -- �i�ڃR�[�h
              ,xsmv.small_amount_class       -- �����敪
              ,xtfi.item_code                -- �i�ڃR�[�h
--�y2009/04/23 A.Yano Ver.1.3 END  �z------------------------------------------------------
    ;
--
  BEGIN
--
    ov_retcode := cv_status_normal;
--
    -- =============================================
    -- 1. ����̎��s���̑O�����擾
    -- =============================================
    gv_process_date_ym := TO_CHAR( ADD_MONTHS( gd_process_date, cn_month_count ), 'YYYYMM' );
    -- =============================================
    -- �O���̑Ώ۔N�x�ƌ����擾
    -- =============================================
    gv_target_year     := SUBSTRB( gv_process_date_ym, 1, 4 );
    gv_target_month    := SUBSTRB( gv_process_date_ym, 5, 2 );
    -- =============================================
    -- 2. �U�։^�����擾
    -- =============================================
    <<trans_freifht_info_loop>>
    FOR trans_freifht_info_rec IN trans_freifht_info_cur LOOP
      -- =============================================
      -- 3. �o�����敪�擾����
      -- =============================================
      IF(   lt_bk_item_code  <> trans_freifht_info_rec.item_code )
        OR( ln_execute_count =  0 )
      THEN
        -- =============================================
        -- A-15.�o�����敪�擾����
        -- =============================================
        get_baracha_div_info(
          ov_errbuf         => lv_errbuf                        -- �G���[�E���b�Z�[�W
         ,ov_retcode        => lv_retcode                       -- ���^�[���E�R�[�h
         ,ov_errmsg         => lv_errmsg                        -- ���[�U�[�E�G���[�E���b�Z�[�W
         ,iv_item_code      => trans_freifht_info_rec.item_code -- �i�ڃR�[�h
         ,on_baracha_div    => lt_baracha_div                   -- �o�����敪
        );
        IF( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        END IF;
        -- �o�����敪�̑ޔ�
        lt_bk_baracha_div := lt_baracha_div;
      END IF;
--
      -- =============================================
      -- �o�����敪��1(�o����)�ȊO�̏ꍇ
      -- =============================================
      IF( lt_baracha_div <> cn_baracya_type ) THEN
        -- �J�E���g�擾
        ln_execute_count := ln_execute_count + 1;
        -- =============================================
        -- 4. �e�i�ڃR�[�h�擾����
        -- =============================================
        IF(   lt_bk_parent_item_id <> trans_freifht_info_rec.parent_item_id )
          OR( ln_execute_count     =  1 )
          OR( trans_freifht_info_rec.parent_item_id IS NULL )
        THEN
          -- �e�i��ID��NULL�̏ꍇ
          IF( trans_freifht_info_rec.parent_item_id IS NULL ) THEN
            lt_item_code := trans_freifht_info_rec.item_code;
            RAISE global_no_data_expt;
          END IF;
          -- =============================================
          -- A-16.�e�i�ڃR�[�h�擾����
          -- =============================================
          get_parent_item_code_info(
             ov_errbuf       => lv_errbuf                             -- �G���[�E���b�Z�[�W
            ,ov_retcode      => lv_retcode                            -- ���^�[���E�R�[�h
            ,ov_errmsg       => lv_errmsg                             -- ���[�U�[�E�G���[�E���b�Z�[�W
            ,in_item_id      => trans_freifht_info_rec.parent_item_id -- �e�i��ID
            ,ov_item_no      => lt_parent_item_code                   -- �e�i�ڃR�[�h
          );
          IF( lv_retcode = cv_status_error ) THEN
            RAISE global_process_expt;
          END IF;
        END IF;
        -- =============================================
        -- 5. PL/SQL�\�i�[�u���C�N����
        -- (���ד��A�Ǌ����_�A�e�i�ڃR�[�h�A�����敪�̂����ꂩ���Ⴄ�ꍇ)
        -- =============================================
        IF(  ( lt_bk_arrival_date       <> trans_freifht_info_rec.arrival_date       )
          OR ( lt_bk_jurisdicyional_hub <> trans_freifht_info_rec.jurisdicyional_hub )
          OR ( lt_bk_parent_item_code   <> lt_parent_item_code                       )
          OR ( lt_bk_small_division     <> trans_freifht_info_rec.small_amount_class )
          AND( ln_execute_count         >  0 ) )
        THEN
--
          -- PL/SQL�\�ւ̏o�͌��������v
          ln_out_count :=  ln_out_count + cn_one;
          -- =============================================
          -- 6. PL/SQL�\�Ɋi�[
          -- =============================================
          g_trans_freifht_tab( ln_out_count ).target_year        := lv_bk_target_year;        -- �Ώ۔N
          g_trans_freifht_tab( ln_out_count ).target_month       := lv_bk_target_month;       -- ��
          g_trans_freifht_tab( ln_out_count ).arrival_date       := lt_bk_arrival_date;       -- ���ד�
          g_trans_freifht_tab( ln_out_count ).jurisdicyional_hub := lt_bk_jurisdicyional_hub; -- �Ǌ����_
          g_trans_freifht_tab( ln_out_count ).parent_item_code   := lt_bk_parent_item_code;   -- �e�i�ڃR�[�h
          g_trans_freifht_tab( ln_out_count ).small_division     := lt_bk_small_division;     -- �����敪
          g_trans_freifht_tab( ln_out_count ).sum_actual_qty     := lt_sum_actual_qty;        -- ���ې���(�W�v�l)
          g_trans_freifht_tab( ln_out_count ).sum_amount         := lt_sum_amount;            -- ���z(�W�v�l)
          -- �����Ώی����̏W�v
          gn_month_target_cnt1 := gn_month_target_cnt1 + 1;
--
          -- =============================================
          -- ���ې���(�W�v�l)�A���z(�W�v�l)�̏�����
          -- =============================================
          lt_sum_actual_qty := trans_freifht_info_rec.actual_qty;    -- ���ې���(�W�v�l)
          lt_sum_amount     := trans_freifht_info_rec.amount;        -- ���z(�W�v�l)
        ELSE
          -- =============================================
          -- 7. ����(C/S)�A���z�l���W�v
          -- =============================================
          lt_sum_actual_qty := lt_sum_actual_qty + trans_freifht_info_rec.actual_qty;
          lt_sum_amount     := lt_sum_amount     + trans_freifht_info_rec.amount;
        END IF;
--
        -- =============================================
        -- 8. �擾�������ڂ�ޔ����ڂɊi�[
        -- =============================================
        lv_bk_target_year        := SUBSTRB( trans_freifht_info_rec.target_date, 1, 4 ); -- �Ώ۔N�x
        lv_bk_target_month       := SUBSTRB( trans_freifht_info_rec.target_date, 5, 2 ); -- �Ώی�
        lt_bk_arrival_date       := trans_freifht_info_rec.arrival_date;                 -- ���ד�
        lt_bk_jurisdicyional_hub := trans_freifht_info_rec.jurisdicyional_hub;           -- �Ǌ����_
        lt_bk_item_code          := trans_freifht_info_rec.item_code;                    -- �i�ڃR�[�h
        lt_bk_parent_item_id     := trans_freifht_info_rec.parent_item_id;               -- �e�i��ID
        lt_bk_small_division     := trans_freifht_info_rec.small_amount_class;           -- �����敪
        lt_bk_parent_item_code   := lt_parent_item_code;                                 -- �e�i�ڃR�[�h
--
      END IF;
    END LOOP trans_freifht_info_loop;
--
    -- =============================================
    -- �ŏI�s�f�[�^���ڐݒ� ���{����
    -- =============================================
    IF( ln_execute_count > 0 ) THEN
      -- PL/SQL�\�ւ̏o�͌��������v
      ln_out_count :=  ln_out_count + cn_one;
      -- =============================================
      -- 6. PL/SQL�\�Ɋi�[
      -- =============================================
      g_trans_freifht_tab( ln_out_count ).target_year        := lv_bk_target_year;        -- �Ώ۔N
      g_trans_freifht_tab( ln_out_count ).target_month       := lv_bk_target_month;       -- ��
      g_trans_freifht_tab( ln_out_count ).arrival_date       := lt_bk_arrival_date;       -- ���ד�
      g_trans_freifht_tab( ln_out_count ).jurisdicyional_hub := lt_bk_jurisdicyional_hub; -- �Ǌ����_
      g_trans_freifht_tab( ln_out_count ).parent_item_code   := lt_bk_parent_item_code;   -- �e�i�ڃR�[�h
      g_trans_freifht_tab( ln_out_count ).small_division     := lt_bk_small_division;     -- �����敪
      g_trans_freifht_tab( ln_out_count ).sum_actual_qty     := lt_sum_actual_qty;        -- ���ې���(�W�v�l)
      g_trans_freifht_tab( ln_out_count ).sum_amount         := lt_sum_amount;            -- ���z(�W�v�l)
      -- �����Ώی����̏W�v
      gn_month_target_cnt1 := gn_month_target_cnt1 + 1;
    END IF;
--
  EXCEPTION
    -- *** �e�i��ID�擾�G���[ ��O�n���h�� ****
    WHEN global_no_data_expt THEN
      lv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_short_name_cok
                      ,iv_name         => cv_get_prnt_itmid_err_msg
                      ,iv_token_name1  => cv_item_code_token -- �i�ڃR�[�h
                      ,iv_token_value1 => lt_item_code       -- �i�ڃR�[�h
                    );
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
  END get_mon_trans_freifht_info;
--
  /**********************************************************************************
   * Procedure Name   : check_lastmonth_fright_rslt
   * Description      : �􂢑ւ����菈��(A-8)
   ***********************************************************************************/
  PROCEDURE check_lastmonth_fright_rslt(
     ov_errbuf       OUT VARCHAR2    --   �G���[�E���b�Z�[�W
    ,ov_retcode      OUT VARCHAR2    --   ���^�[���E�R�[�h
    ,ov_errmsg       OUT VARCHAR2    --   ���[�U�[�E�G���[�E���b�Z�[�W
    ,ov_check_result OUT VARCHAR2    --   �􂢑ւ����茋��
  )
  IS
    -- ===============================
    -- �錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_prg_name      CONSTANT VARCHAR2(30) := 'check_lastmonth_fright_rslt'; -- �v���O������
    -- *** ���[�J���ϐ� ***
    lv_errbuf             VARCHAR2(5000);      -- �G���[�E���b�Z�[�W
    lv_retcode            VARCHAR2(3);         -- ���^�[���E�R�[�h
    lv_errmsg             VARCHAR2(5000);      -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_out_msg            VARCHAR2(2000);      -- �o�̓��b�Z�[�W
    lb_retcode            BOOLEAN;             -- ���b�Z�[�W�o�͂̃��^�[���E�R�[�h
    lv_check_type         VARCHAR2(1);         -- �^�C�v
    lv_mnth_lstcoprt_d_ym VARCHAR2(6);         -- YYYYMM
    lv_prces_date_ym      VARCHAR2(6);         -- �Ɩ����t��YYYYMM
--
  BEGIN
--
    ov_retcode := cv_status_normal;
--
    -- =============================================
    -- �O���^������`�F�b�N����
    -- =============================================
    xxwip_common3_pkg.check_lastmonth_close(
                            ov_close_type => lv_check_type
                           ,ov_retcode    => lv_retcode
                           ,ov_errbuf     => lv_errbuf
                           ,ov_errmsg     => lv_errmsg
    );
    -- =============================================
    -- �O���^������`�F�b�N�������ʔ���
    -- =============================================
    IF( lv_retcode <> cv_status_normal ) THEN
      RAISE global_no_data_expt;
    END IF;
--
    -- =============================================
    -- �􂢑ւ����菈��
    -- =============================================
    -- ���ߋ敪='Y'(���ߓ��O)�̏ꍇ
    IF( lv_check_type = cv_type_y ) THEN
      -- �􂢑ւ����茋�ʂɐ􂢑ւ��Ȃ�'0'��ݒ�
      ov_check_result := cv_arai_gae_off;
    ELSE
      -- �����̑O��o�b�`�I����������YYYYMM������؏o��
      lv_mnth_lstcoprt_d_ym :=   SUBSTR( TO_CHAR( gd_month_last_coprt_date, 'YYYYMM' ), 1 , 6 );
      -- �Ɩ����t����YYYYMM������؏o��
      lv_prces_date_ym      :=   SUBSTR( TO_CHAR( gd_process_date, 'YYYYMM' ), 1 , 6 );
--
      IF( lv_mnth_lstcoprt_d_ym = lv_prces_date_ym ) THEN
        -- �􂢑ւ����茋�ʂɐ􂢑ւ��Ȃ�'0'��ݒ�
        ov_check_result := cv_arai_gae_off;
      ELSE
        -- �􂢑ւ����茋�ʂɐ􂢑ւ�����'1'��ݒ�
        ov_check_result := cv_arai_gae_on;
      END IF;
    END IF;
--
  EXCEPTION
    -- *** �O���^������`�F�b�N�G���[ ��O�n���h�� ****
    WHEN global_no_data_expt THEN
      lv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_short_name_cok
                      ,iv_name         => cv_chk_lstmnthcls_err_msg
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
  END check_lastmonth_fright_rslt;
--
  /**********************************************************************************
   * Procedure Name   : update_data_coprt_cntrl
   * Description      : �f�[�^�A�g����e�[�u���X�V����(A-7)
   ***********************************************************************************/
  PROCEDURE update_data_coprt_cntrl(
     ov_errbuf         OUT VARCHAR2    --   �G���[�E���b�Z�[�W
    ,ov_retcode        OUT VARCHAR2    --   ���^�[���E�R�[�h
    ,ov_errmsg         OUT VARCHAR2    --   ���[�U�[�E�G���[�E���b�Z�[�W
    ,in_control_id     IN  NUMBER      --   ����ID
  )
  IS
    -- ===============================
    -- �錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_prg_name      CONSTANT VARCHAR2(30) := 'update_data_coprt_cntrl'; -- �v���O������
    -- *** ���[�J���ϐ� ***
    lv_errbuf        VARCHAR2(5000);      -- �G���[�E���b�Z�[�W
    lv_retcode       VARCHAR2(3);         -- ���^�[���E�R�[�h
    lv_errmsg        VARCHAR2(5000);      -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_out_msg       VARCHAR2(2000);      -- �o�̓��b�Z�[�W
    lb_retcode       BOOLEAN;             -- ���b�Z�[�W�o�͂̃��^�[���E�R�[�h
--
  BEGIN
--
    ov_retcode := cv_status_normal;
    -- =============================================
    -- �f�[�^�A�g����e�[�u���X�V
    -- =============================================
    UPDATE xxcoi_cooperation_control xcc
    SET xcc.last_cooperation_date  = gd_sysdate                -- �V�X�e�����t�i�ŏI�A�g�����j
       ,xcc.last_updated_by        = cn_last_updated_by        -- �ŏI�X�V�҂�USER_ID
       ,xcc.last_update_date       = SYSDATE                   -- �ŏI�X�V����
       ,xcc.last_update_login      = cn_last_update_login      -- �ŏI�X�V����LOGIN_ID
       ,xcc.request_id             = cn_request_id             -- �v��ID
       ,xcc.program_application_id = cn_program_application_id -- �v���O�����A�v���P�[�V����ID
       ,xcc.program_id             = cn_program_id             -- �v���O����ID
       ,xcc.program_update_date    = SYSDATE                   -- �v���O�����ŏI�X�V��
    WHERE  xcc.control_id   = in_control_id  -- ����ID
    ;
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
  END update_data_coprt_cntrl;
--
  /**********************************************************************************
   * Procedure Name   : update_dlv_cost_result_info
   * Description      : �^������уe�[�u���X�V����(A-5)
   ***********************************************************************************/
  PROCEDURE update_dlv_cost_result_info(
     ov_errbuf              OUT VARCHAR2      -- �G���[�E���b�Z�[�W
    ,ov_retcode             OUT VARCHAR2      -- ���^�[���E�R�[�h
    ,ov_errmsg              OUT VARCHAR2      -- ���[�U�[�E�G���[�E���b�Z�[�W
    ,in_cs_qty              IN  NUMBER        -- ����(C/S)
    ,in_dlv_cost_result_amt IN  NUMBER        -- ���z
    ,in_result_id           IN  NUMBER        -- �^�������ID
  )
  IS
    -- ===============================
    -- �錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_prg_name      CONSTANT VARCHAR2(30) := 'update_dlv_cost_result_info'; -- �v���O������
    -- *** ���[�J���ϐ� ***
    lv_errbuf        VARCHAR2(5000);      -- �G���[�E���b�Z�[�W
    lv_retcode       VARCHAR2(3);         -- ���^�[���E�R�[�h
    lv_errmsg        VARCHAR2(5000);      -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_out_msg       VARCHAR2(2000);      -- �o�̓��b�Z�[�W
    lb_retcode       BOOLEAN;             -- ���b�Z�[�W�o�͂̃��^�[���E�R�[�h
--
  BEGIN
--
    ov_retcode := cv_status_normal;
--
    -- =============================================
    -- �^������уe�[�u���X�V
    -- =============================================
    UPDATE xxcok_dlv_cost_result_info xdcri     -- �^������уe�[�u��
    SET xdcri.cs_qty                 = in_cs_qty                 -- ����(C/S)
       ,xdcri.dlv_cost_result_amt    = in_dlv_cost_result_amt    -- ���z
       ,xdcri.last_updated_by        = cn_last_updated_by        -- �ŏI�X�V�҂�USER_ID
       ,xdcri.last_update_date       = SYSDATE                   -- �ŏI�X�V����
       ,xdcri.last_update_login      = cn_last_update_login      -- �ŏI�X�V����LOGIN_ID
       ,xdcri.request_id             = cn_request_id             -- �v��ID
       ,xdcri.program_application_id = cn_program_application_id -- �v���O�����A�v���P�[�V����ID
       ,xdcri.program_id             = cn_program_id             -- �v���O����ID
       ,xdcri.program_update_date    = SYSDATE                   -- �v���O�����ŏI�X�V��
    WHERE xdcri.result_id  = in_result_id
    ;
--
    -- ��������
    gn_normal_cnt := gn_normal_cnt + 1;
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
  END update_dlv_cost_result_info;
--
  /**********************************************************************************
   * Procedure Name   : control_dlv_cost_result
   * Description      : �^������уe�[�u�����䏈��(A-4)
   ***********************************************************************************/
  PROCEDURE control_dlv_cost_result(
     ov_errbuf         OUT VARCHAR2      --   �G���[�E���b�Z�[�W
    ,ov_retcode        OUT VARCHAR2      --   ���^�[���E�R�[�h
    ,ov_errmsg         OUT VARCHAR2      --   ���[�U�[�E�G���[�E���b�Z�[�W
  )
  IS
    -- ===============================
    -- �錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_prg_name      CONSTANT VARCHAR2(30) := 'control_dlv_cost_result'; -- �v���O������
    -- *** ���[�J���ϐ� ***
    lv_errbuf        VARCHAR2(5000);      -- �G���[�E���b�Z�[�W
    lv_retcode       VARCHAR2(3);         -- ���^�[���E�R�[�h
    lv_errmsg        VARCHAR2(5000);      -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_out_msg       VARCHAR2(2000);      -- �o�̓��b�Z�[�W
    lb_retcode       BOOLEAN;             -- ���b�Z�[�W�o�͂̃��^�[���E�R�[�h
    ln_result_id     xxcok_dlv_cost_result_info.result_id%TYPE; -- �^�������ID
--
    lock_expt EXCEPTION;
  BEGIN
--
    ov_retcode := cv_status_normal;
--
    <<day_loop>>
    FOR ln_count IN 1 .. g_trans_freifht_tab.COUNT LOOP
    -- =============================================
    -- �Ώۃf�[�^�̑��݃`�F�b�N
    -- =============================================
      BEGIN
        SELECT xdcri.result_id AS result_id   -- �^�������ID
        INTO   ln_result_id
        FROM   xxcok_dlv_cost_result_info xdcri     -- �^������уe�[�u��
        WHERE xdcri.target_year    = g_trans_freifht_tab( ln_count ).target_year        -- �Ώ۔N�x
        AND   xdcri.target_month   = g_trans_freifht_tab( ln_count ).target_month       -- ��
        AND   xdcri.arrival_date   = g_trans_freifht_tab( ln_count ).arrival_date       -- ���ד�
        AND   xdcri.base_code      = g_trans_freifht_tab( ln_count ).jurisdicyional_hub -- ���_�R�[�h
        AND   xdcri.item_code      = g_trans_freifht_tab( ln_count ).parent_item_code   -- �i�ڃR�[�h
        AND   xdcri.small_amt_type = g_trans_freifht_tab( ln_count ).small_division     -- �����敪
        FOR UPDATE OF xdcri.result_id NOWAIT
        ;
      EXCEPTION
        -- *** �f�[�^�A�g����e�[�u�����b�N��O�n���h�� ****
        WHEN global_lock_expt THEN
          lv_out_msg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_app_short_name_cok
                          ,iv_name         => cv_lok_dlv_cstrsl_err_msg
                          ,iv_token_name1  => cv_target_year_token
                          ,iv_token_value1 => g_trans_freifht_tab( ln_count ).target_year        -- �Ώ۔N�x
                          ,iv_token_name2  => cv_target_month_token
                          ,iv_token_value2 => g_trans_freifht_tab( ln_count ).target_month       -- ��
                          ,iv_token_name3  => cv_arrival_date_token                              -- ���ד�
                          ,iv_token_value3 => TO_CHAR( g_trans_freifht_tab( ln_count ).arrival_date, 'YYYY/MM/DD' )
                          ,iv_token_name4  => cv_kyoten_code_token
                          ,iv_token_value4 => g_trans_freifht_tab( ln_count ).jurisdicyional_hub -- ���_�R�[�h
                          ,iv_token_name5  => cv_item_code_token
                          ,iv_token_value5 => g_trans_freifht_tab( ln_count ).parent_item_code   -- �i�ڃR�[�h
                          ,iv_token_name6  => cv_small_lot_class_token
                          ,iv_token_value6 => g_trans_freifht_tab( ln_count ).small_division     -- �����敪
                        );
          lb_retcode := xxcok_common_pkg.put_message_f(
                           in_which    =>   FND_FILE.OUTPUT
                          ,iv_message  =>   lv_out_msg
                          ,in_new_line =>   0
                        );
          RAISE lock_expt;
        WHEN NO_DATA_FOUND THEN
          ln_result_id := NULL;
      END;
--
      -- =============================================
      -- �^������уe�[�u���Ƀf�[�^�����݂���ꍇ
      -- =============================================
      IF( ln_result_id IS NOT NULL ) THEN
        -- =============================================
        -- A-5.�^������уe�[�u���X�V
        -- =============================================
        update_dlv_cost_result_info(
           ov_errbuf              => lv_errbuf                                          -- �G���[�E���b�Z�[�W
          ,ov_retcode             => lv_retcode                                         -- ���^�[���E�R�[�h
          ,ov_errmsg              => lv_errmsg                                          -- ���[�U�[�E�G���[�E���b�Z�[�W
          ,in_cs_qty              => g_trans_freifht_tab( ln_count ).sum_actual_qty     -- ����(C/S)
          ,in_dlv_cost_result_amt => g_trans_freifht_tab( ln_count ).sum_amount         -- ���z
          ,in_result_id           => ln_result_id                                       -- ����ID
        );
        IF( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        END IF;
      -- =============================================
      -- �^������уe�[�u���Ƀf�[�^�����݂��Ȃ��ꍇ
      -- =============================================
      ELSE
        -- =============================================
        -- A-6.�^������уe�[�u���o�^
        -- =============================================
        insert_dlv_cost_result_info(
           ov_errbuf              => lv_errbuf                                          -- �G���[�E���b�Z�[�W
          ,ov_retcode             => lv_retcode                                         -- ���^�[���E�R�[�h
          ,ov_errmsg              => lv_errmsg                                          -- ���[�U�[�E�G���[�E���b�Z�[�W
          ,iv_target_year         => g_trans_freifht_tab( ln_count ).target_year        -- �Ώ۔N�x
          ,iv_target_month        => g_trans_freifht_tab( ln_count ).target_month       -- ��
          ,id_arrival_date        => g_trans_freifht_tab( ln_count ).arrival_date       -- ���ד�
          ,iv_base_code           => g_trans_freifht_tab( ln_count ).jurisdicyional_hub -- ���_�R�[�h
          ,iv_item_code           => g_trans_freifht_tab( ln_count ).parent_item_code   -- �i�ڃR�[�h
          ,iv_small_amt_type      => g_trans_freifht_tab( ln_count ).small_division     -- �����敪
          ,in_cs_qty              => g_trans_freifht_tab( ln_count ).sum_actual_qty     -- ����(C/S)
          ,in_dlv_cost_result_amt => g_trans_freifht_tab( ln_count ).sum_amount         -- ���z
        );
        IF( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        END IF;
--
      END IF;
--
    END LOOP day_loop;
--
  EXCEPTION
    -- *** ���b�N��O�n���h�� ***
    WHEN lock_expt THEN
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
  END control_dlv_cost_result;
--
  /**********************************************************************************
   * Procedure Name   : get_sum_trans_freifht
   * Description      : �U�։^��(���ʁE���z�W�v�l)�擾����(A-3)
   ***********************************************************************************/
  PROCEDURE get_sum_trans_freifht(
     ov_errbuf             OUT VARCHAR2     -- �G���[�E���b�Z�[�W
    ,ov_retcode            OUT VARCHAR2     -- ���^�[���E�R�[�h
    ,ov_errmsg             OUT VARCHAR2     -- ���[�U�[�E�G���[�E���b�Z�[�W
    ,it_delivery_date      IN  xxwip_transfer_fare_inf.delivery_date%TYPE      DEFAULT NULL -- ���ד�
    ,it_jurisdicyional_hub IN  xxwip_transfer_fare_inf.jurisdicyional_hub%TYPE DEFAULT NULL -- �Ǌ����_
    ,it_item_code          IN  xxwip_transfer_fare_inf.item_code%TYPE          DEFAULT NULL -- �i�ڃR�[�h
    ,it_small_amount_class IN  xxwsh_ship_method2_v.small_amount_class%TYPE    DEFAULT NULL -- �����敪
    ,on_sum_actual_qty     OUT NUMBER      -- �W�v����(C/S)
    ,on_sum_amount         OUT NUMBER      -- �W�v���z
  )
  IS
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_prg_name    CONSTANT VARCHAR2(30) := 'get_sum_trans_freifht'; -- �v���O������
    -- *** ���[�J���ϐ� ***
    lv_errbuf      VARCHAR2(5000);    -- �G���[�E���b�Z�[�W
    lv_retcode     VARCHAR2(3);       -- ���^�[���E�R�[�h
    lv_errmsg      VARCHAR2(5000);    -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_out_msg     VARCHAR2(2000);    -- �o�̓��b�Z�[�W
    lb_retcode     BOOLEAN;           -- ���b�Z�[�W�o�͂̃��^�[���E�R�[�h
--
  BEGIN
--
    ov_retcode := cv_status_normal;
--
    -- =============================================
    -- A-3.�U�։^��(���ʁE���z)�W�v�l�擾
    -- =============================================
    SELECT SUM( NVL( xtfi.actual_qty, cn_zero ) ) AS  sum_actual_qty   -- ���ې��� ���v�l
          ,SUM( NVL( xtfi.amount    , cn_zero ) ) AS  sum_amount       -- ���z ���v�l
    INTO   on_sum_actual_qty
          ,on_sum_amount
    FROM   xxwip_transfer_fare_inf  xtfi  -- �U�։^�����A�h�I���e�[�u��
          ,xxwsh_order_headers_all  xoha  -- �󒍃w�b�_�A�h�I���e�[�u��
          ,xxwsh_ship_method2_v     xsmv  -- �z���敪���VIEW2
    WHERE xtfi.delivery_date               = it_delivery_date
    AND   xtfi.jurisdicyional_hub          = it_jurisdicyional_hub
    AND   xtfi.item_code                   = it_item_code
    AND   xtfi.request_no                  = xoha.request_no
    AND   xtfi.delivery_date               = xoha.arrival_date
    AND   xtfi.goods_classe                = xoha.prod_class
    AND   xtfi.jurisdicyional_hub          = xoha.head_sales_branch
    AND   xtfi.delivery_whs                = xoha.deliver_from
    AND   xtfi.ship_to                     = xoha.result_deliver_to
    AND   xoha.latest_external_flag        = cv_new_record
    AND   xoha.result_shipping_method_code = xsmv.ship_method_code
    AND   xsmv.small_amount_class          = it_small_amount_class
    ;
--
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1 , 5000 );
      ov_retcode := cv_status_normal;
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
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
  END get_sum_trans_freifht;
--
  /**********************************************************************************
   * Procedure Name   : get_trans_freifht_info
   * Description      : �U�։^�����擾����(A-2)
   ***********************************************************************************/
  PROCEDURE get_trans_freifht_info(
     ov_errbuf             OUT VARCHAR2      -- �G���[�E���b�Z�[�W
    ,ov_retcode            OUT VARCHAR2      -- ���^�[���E�R�[�h
    ,ov_errmsg             OUT VARCHAR2      -- ���[�U�[�E�G���[�E���b�Z�[�W
  )
  IS
    -- ===============================
    -- �錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_prg_name       CONSTANT VARCHAR2(30) := 'get_trans_freifht_info'; -- �v���O������
    -- *** ���[�J���ϐ� ***
    lv_errbuf                VARCHAR2(5000);    -- �G���[�E���b�Z�[�W
    lv_retcode               VARCHAR2(3);       -- ���^�[���E�R�[�h
    lv_errmsg                VARCHAR2(5000);    -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_out_msg               VARCHAR2(2000);    -- �o�̓��b�Z�[�W
    lb_retcode               BOOLEAN;           -- ���b�Z�[�W�o�͂̃��^�[���E�R�[�h
    lt_item_code             xxwip_transfer_fare_inf.item_code%TYPE          DEFAULT NULL; -- �i�ڃR�[�h(�q�i�ڃR�[�h)
    -- ���ڑޔ�p
    lt_bk_arrival_date       xxwsh_order_headers_all.arrival_date%TYPE       DEFAULT NULL; -- ���ד�
    lt_bk_jurisdicyional_hub xxwip_transfer_fare_inf.jurisdicyional_hub%TYPE DEFAULT NULL; -- �Ǌ����_
    lt_bk_item_code          xxwip_transfer_fare_inf.item_code%TYPE          DEFAULT NULL; -- �i�ڃR�[�h(�q�i�ڃR�[�h)
    lt_bk_parent_item_id     xxcmn_item_mst_b.parent_item_id%TYPE            DEFAULT NULL; -- �e�i��ID
    lt_bk_small_division     fnd_lookup_values.attribute6%TYPE               DEFAULT NULL; -- �����敪
    lv_bk_target_year        VARCHAR2(4) DEFAULT NULL;  -- �Ώ۔N�x
    lv_bk_target_month       VARCHAR2(2) DEFAULT NULL;  -- �Ώی�
    -- ����E�W�v�p
    lt_bk_baracha_div        xxcmm_system_items_b.baracha_div%TYPE           DEFAULT NULL; -- �o�����敪
    lt_bk_parent_item_code   xxwip_transfer_fare_inf.item_code%TYPE          DEFAULT NULL; -- �e�i�ڃR�[�h
    lt_baracha_div           xxcmm_system_items_b.baracha_div%TYPE           DEFAULT NULL; -- �o�����敪
    lt_parent_item_code      xxwip_transfer_fare_inf.item_code%TYPE          DEFAULT NULL; -- �e�i�ڃR�[�h
    lt_sum_actual_qty        xxwip_transfer_fare_inf.actual_qty%TYPE         DEFAULT 0;    -- ���ې���(�W�v�l)
    lt_sum_amount            xxwip_transfer_fare_inf.amount%TYPE             DEFAULT 0;    -- ���z(�W�v�l)
    lt_sum_actual_qty_get    xxwip_transfer_fare_inf.actual_qty%TYPE         DEFAULT 0;    -- ���ې���(�W�v�l)�擾
    lt_sum_amount_get        xxwip_transfer_fare_inf.amount%TYPE             DEFAULT 0;    -- ���z(�W�v�l)�擾
    ln_execute_count         NUMBER      DEFAULT 0;     -- �o�����`�F�b�N�ʉߌ���
    ln_out_count             NUMBER      DEFAULT 0;     -- �o�͌���
    -- *** ���[�J���J�[�\�� ***
    -- �U�։^���J�[�\��(�����p)
    CURSOR trans_freifht_info_cur
    IS
      SELECT xtfi.target_date            AS target_date        -- �Ώ۔N��
            ,xoha.arrival_date           AS arrival_date       -- ���ד�
            ,xtfi.jurisdicyional_hub     AS jurisdicyional_hub -- �Ǌ����_
            ,xtfi.item_code              AS item_code          -- �i�ڃR�[�h
            ,seq_0_v.parent_item_id      AS parent_item_id     -- �e�i�sID
            ,xsmv.small_amount_class     AS small_amount_class -- �����敪
      FROM   xxwip_transfer_fare_inf  xtfi     -- �U�։^�����A�h�I���e�[�u��
            ,xxwsh_order_headers_all  xoha     -- �󒍃w�b�_�A�h�I���e�[�u��
            ,xxwsh_ship_method2_v     xsmv     -- �z���敪���VIEW2
            ,( SELECT ximb.parent_item_id  AS parent_item_id -- �e�i��ID
                     ,iimb.item_id         AS item_id        -- �i��ID
                     ,iimb.item_no         AS item_no        -- �i��NO
               FROM   mtl_system_items_b      msib     -- �i�ڃ}�X�^
                     ,ic_item_mst_b           iimb     -- OPM�i��
                     ,xxcmn_item_mst_b        ximb     -- OPM�i�ڃA�h�I��
                     ,mtl_category_sets_b     mcsb     -- �i�ڃJ�e�S���Z�b�g
                     ,mtl_category_sets_tl    mcst     -- �i�ڃJ�e�S���Z�b�g���{��
                     ,mtl_categories_b        mcb      -- �i�ڃJ�e�S���}�X�^
                     ,mtl_item_categories     mic      -- �i�ڃJ�e�S������
               WHERE  iimb.item_no                 = msib.segment1
               AND    ximb.item_id                 = iimb.item_id
               AND    mcst.category_set_id         = mcsb.category_set_id
               AND    mcb.structure_id             = mcsb.structure_id
               AND    mcb.category_id              = mic.category_id
               AND    mcsb.category_set_id         = mic.category_set_id
               AND    mcst.language                = USERENV( 'LANG' )
               AND    mcst.category_set_name       = gv_item_div_h
               AND    mcb.segment1                 = cv_office_item_drink
               AND    msib.organization_id         = gn_organization_id
               AND    msib.organization_id         = mic.organization_id
               AND    msib.inventory_item_id       = mic.inventory_item_id
            )                         seq_0_v  -- �C�����C���r���[
      WHERE  xtfi.request_no                  = xoha.request_no
      AND    xtfi.delivery_date               = xoha.arrival_date
      AND    xtfi.goods_classe                = xoha.prod_class
      AND    xtfi.jurisdicyional_hub          = xoha.head_sales_branch
      AND    xtfi.delivery_whs                = xoha.deliver_from
      AND    xtfi.ship_to                     = xoha.result_deliver_to
      AND    xoha.latest_external_flag        = cv_new_record
      AND    xoha.result_shipping_method_code = xsmv.ship_method_code
      AND    seq_0_v.item_no(+)               = xtfi.item_code
      AND( ( xtfi.creation_date               > gd_day_last_coprt_date )
        OR ( xtfi.last_update_date            > gd_day_last_coprt_date ) )
      ORDER BY xtfi.target_date              -- �Ώ۔N��
              ,xoha.arrival_date             -- ���ד�
              ,xtfi.jurisdicyional_hub       -- �Ǌ����_
              ,seq_0_v.parent_item_id        -- �e�i��ID
--�y2009/04/23 A.Yano Ver.1.3 START�z------------------------------------------------------
--              ,xtfi.item_code                -- �i�ڃR�[�h
              ,xsmv.small_amount_class       -- �����敪
              ,xtfi.item_code                -- �i�ڃR�[�h
--�y2009/04/23 A.Yano Ver.1.3 END  �z------------------------------------------------------
    ;
--
  BEGIN
--
    ov_retcode := cv_status_normal;
    -- =============================================
    -- 1. �U�։^�����擾
    -- =============================================
    <<trans_freifht_info_loop>>
    FOR trans_freifht_info_rec IN trans_freifht_info_cur LOOP
      -- =============================================
      -- 2. �o�����敪�擾����
      -- =============================================
      IF(   lt_bk_item_code  <> trans_freifht_info_rec.item_code )
        OR( ln_execute_count =  0 )
      THEN
        -- =============================================
        -- A-15.�o�����敪�擾����
        -- =============================================
        get_baracha_div_info(
          ov_errbuf         => lv_errbuf                        --   �G���[�E���b�Z�[�W
         ,ov_retcode        => lv_retcode                       --   ���^�[���E�R�[�h
         ,ov_errmsg         => lv_errmsg                        --   ���[�U�[�E�G���[�E���b�Z�[�W
         ,iv_item_code      => trans_freifht_info_rec.item_code --   �i�ڃR�[�h
         ,on_baracha_div    => lt_baracha_div                   --   �o�����敪
        );
        IF( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        END IF;
        -- �o�����敪�̑ޔ�
        lt_bk_baracha_div := lt_baracha_div;
      END IF;
--
      -- =============================================
      -- �o�����敪��1(�o����)�ȊO�̏ꍇ
      -- =============================================
      IF( lt_baracha_div <> cn_baracya_type ) THEN
        -- �J�E���g�擾
        ln_execute_count := ln_execute_count + 1;
        -- =============================================
        -- 3. �e�i�ڃR�[�h�擾����
        -- =============================================
        IF(   lt_bk_parent_item_id <> trans_freifht_info_rec.parent_item_id )
          OR( ln_execute_count     =  1 )
          OR( trans_freifht_info_rec.parent_item_id IS NULL )
        THEN
          -- �e�i��ID��NULL�̏ꍇ
          IF( trans_freifht_info_rec.parent_item_id IS NULL ) THEN
            lt_item_code := trans_freifht_info_rec.item_code;
            RAISE global_no_data_expt;
          END IF;
          -- =============================================
          -- A-16.�e�i�ڃR�[�h�擾����
          -- =============================================
          get_parent_item_code_info(
             ov_errbuf       => lv_errbuf                             -- �G���[�E���b�Z�[�W
            ,ov_retcode      => lv_retcode                            -- ���^�[���E�R�[�h
            ,ov_errmsg       => lv_errmsg                             -- ���[�U�[�E�G���[�E���b�Z�[�W
            ,in_item_id      => trans_freifht_info_rec.parent_item_id -- �e�i��ID
            ,ov_item_no      => lt_parent_item_code                   -- �e�i�ڃR�[�h
          );
          IF( lv_retcode = cv_status_error ) THEN
            RAISE global_process_expt;
          END IF;
        END IF;
        -- =============================================
        -- 4. �U�։^��(���ʁE���z�W�v�l)�擾����
        -- =============================================
        IF( ( lt_bk_arrival_date       <> trans_freifht_info_rec.arrival_date       )
          OR( lt_bk_jurisdicyional_hub <> trans_freifht_info_rec.jurisdicyional_hub )
          OR( lt_bk_item_code          <> trans_freifht_info_rec.item_code          )
          OR( lt_bk_small_division     <> trans_freifht_info_rec.small_amount_class )
          OR( ln_execute_count         =  1 ) )
        THEN
          -- =============================================
          -- A-3.�U�։^��(���ʁE���z�W�v�l)�擾����
          -- =============================================
          get_sum_trans_freifht(
             ov_errbuf              =>    lv_errbuf              -- �G���[�E���b�Z�[�W
            ,ov_retcode             =>    lv_retcode             -- ���^�[���E�R�[�h
            ,ov_errmsg              =>    lv_errmsg              -- ���[�U�[�E�G���[�E���b�Z�[�W
            ,it_delivery_date       =>    trans_freifht_info_rec.arrival_date          -- ���ד�
            ,it_jurisdicyional_hub  =>    trans_freifht_info_rec.jurisdicyional_hub    -- �Ǌ����_
            ,it_item_code           =>    trans_freifht_info_rec.item_code             -- �i�ڃR�[�h
            ,it_small_amount_class  =>    trans_freifht_info_rec.small_amount_class    -- �����敪
            ,on_sum_actual_qty      =>    lt_sum_actual_qty_get                        -- �W�v����(C/S)
            ,on_sum_amount          =>    lt_sum_amount_get                            -- �W�v���z
          );
          IF( lv_retcode = cv_status_error ) THEN
            RAISE global_process_expt;
          END IF;
        ELSE
          lt_sum_actual_qty_get := cn_zero; -- �W�v����(C/S)
          lt_sum_amount_get     := cn_zero; -- �W�v���z
        END IF;
        -- =============================================
        -- 5. PL/SQL�\�i�[�u���C�N����
        -- (���ד��A�Ǌ����_�A�e�i�ڃR�[�h�A�����敪�̂����ꂩ���Ⴄ�ꍇ)
        -- =============================================
        IF(  ( lt_bk_arrival_date       <> trans_freifht_info_rec.arrival_date       )
          OR ( lt_bk_jurisdicyional_hub <> trans_freifht_info_rec.jurisdicyional_hub )
          OR ( lt_bk_parent_item_code   <> lt_parent_item_code                       )
          OR ( lt_bk_small_division     <> trans_freifht_info_rec.small_amount_class )
          AND( ln_execute_count         >  0 ) )
        THEN
          -- PL/SQL�\�ւ̏o�͌��������v
          ln_out_count :=  ln_out_count + cn_one;
          -- =============================================
          -- 6.�@ PL/SQL�\�Ɋi�[
          -- =============================================
          g_trans_freifht_tab( ln_out_count ).target_year        := lv_bk_target_year;        -- �Ώ۔N
          g_trans_freifht_tab( ln_out_count ).target_month       := lv_bk_target_month;       -- ��
          g_trans_freifht_tab( ln_out_count ).arrival_date       := lt_bk_arrival_date;       -- ���ד�
          g_trans_freifht_tab( ln_out_count ).jurisdicyional_hub := lt_bk_jurisdicyional_hub; -- �Ǌ����_
          g_trans_freifht_tab( ln_out_count ).parent_item_code   := lt_bk_parent_item_code;   -- �e�i�ڃR�[�h
          g_trans_freifht_tab( ln_out_count ).small_division     := lt_bk_small_division;     -- �����敪
          g_trans_freifht_tab( ln_out_count ).sum_actual_qty     := lt_sum_actual_qty;        -- ���ې���(�W�v�l)
          g_trans_freifht_tab( ln_out_count ).sum_amount         := lt_sum_amount;            -- ���z(�W�v�l)
          -- �����Ώی����̏W�v
          gn_target_cnt := gn_target_cnt + 1;
--
          -- =============================================
          -- 6.�A ���ې���(�W�v�l)�A���z(�W�v�l)�̏�����
          -- =============================================
          lt_sum_actual_qty := lt_sum_actual_qty_get;    -- ���ې���(�W�v�l)
          lt_sum_amount     := lt_sum_amount_get;        -- ���z(�W�v�l)
        ELSE
          -- =============================================
          -- 7. ����(C/S)�A���z�l���W�v
          -- =============================================
          lt_sum_actual_qty := lt_sum_actual_qty + lt_sum_actual_qty_get;
          lt_sum_amount     := lt_sum_amount + lt_sum_amount_get;
        END IF;
--
        -- =============================================
        -- 8. �擾�������ڂ�ޔ����ڂɊi�[
        -- =============================================
        lv_bk_target_year        := SUBSTRB( trans_freifht_info_rec.target_date, 1, 4 ); -- �Ώ۔N�x
        lv_bk_target_month       := SUBSTRB( trans_freifht_info_rec.target_date, 5, 2 ); -- �Ώی�
        lt_bk_arrival_date       := trans_freifht_info_rec.arrival_date;                 -- ���ד�
        lt_bk_jurisdicyional_hub := trans_freifht_info_rec.jurisdicyional_hub;           -- �Ǌ����_
        lt_bk_item_code          := trans_freifht_info_rec.item_code;                    -- �i�ڃR�[�h
        lt_bk_parent_item_id     := trans_freifht_info_rec.parent_item_id;               -- �e�i��ID
        lt_bk_small_division     := trans_freifht_info_rec.small_amount_class;           -- �����敪
        lt_bk_parent_item_code   := lt_parent_item_code;                                 -- �e�i�ڃR�[�h
--
      END IF;
    END LOOP trans_freifht_info_loop;
--
    -- =============================================
    -- 6. �ŏI�s�f�[�^���ڐݒ� ���{����
    -- =============================================
    IF( ln_execute_count > 0 ) THEN
      -- PL/SQL�\�ւ̏o�͌��������v
      ln_out_count :=  ln_out_count + cn_one;
      -- =============================================
      -- PL/SQL�\�Ɋi�[
      -- =============================================
      g_trans_freifht_tab( ln_out_count ).target_year        := lv_bk_target_year;        -- �Ώ۔N
      g_trans_freifht_tab( ln_out_count ).target_month       := lv_bk_target_month;       -- ��
      g_trans_freifht_tab( ln_out_count ).arrival_date       := lt_bk_arrival_date;       -- ���ד�
      g_trans_freifht_tab( ln_out_count ).jurisdicyional_hub := lt_bk_jurisdicyional_hub; -- �Ǌ����_
      g_trans_freifht_tab( ln_out_count ).parent_item_code   := lt_bk_parent_item_code;   -- �e�i�ڃR�[�h
      g_trans_freifht_tab( ln_out_count ).small_division     := lt_bk_small_division;     -- �����敪
      g_trans_freifht_tab( ln_out_count ).sum_actual_qty     := lt_sum_actual_qty;         -- ���ې���(�W�v�l)
      g_trans_freifht_tab( ln_out_count ).sum_amount         := lt_sum_amount;             -- ���z(�W�v�l)
      -- �����Ώی����̏W�v
      gn_target_cnt := gn_target_cnt + 1;
    END IF;
--
  EXCEPTION
    -- *** �e�i��ID�擾�G���[ ��O�n���h�� ****
    WHEN global_no_data_expt THEN
      lv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_short_name_cok
                      ,iv_name         => cv_get_prnt_itmid_err_msg
                      ,iv_token_name1  => cv_item_code_token -- �i�ڃR�[�h
                      ,iv_token_value1 => lt_item_code       -- �i�ڃR�[�h
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                       in_which    =>   FND_FILE.OUTPUT
                      ,iv_message  =>   lv_out_msg
                      ,in_new_line =>   0
                    );
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg,1,5000 );
      ov_retcode := cv_status_error;
    WHEN NO_DATA_FOUND THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1 , 5000 );
      ov_retcode := cv_status_normal;
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
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1 , 5000 );
      ov_retcode := cv_status_error;
--
  END get_trans_freifht_info;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
     ov_errbuf               OUT VARCHAR2      -- �G���[�E���b�Z�[�W
    ,ov_retcode              OUT VARCHAR2      -- ���^�[���E�R�[�h
    ,ov_errmsg               OUT VARCHAR2      -- ���[�U�[�E�G���[�E���b�Z�[�W
  )
  IS
    -- ===============================
    -- �錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_prg_name           CONSTANT VARCHAR2(5) := 'init'; -- �v���O������
    -- *** ���[�J���ϐ� ***
    lv_errbuf                   VARCHAR2(5000);    -- �G���[�E���b�Z�[�W
    lv_retcode                  VARCHAR2(3);       -- ���^�[���E�R�[�h
    lv_errmsg                   VARCHAR2(5000);    -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_out_msg                  VARCHAR2(2000);    -- �o�̓��b�Z�[�W
    lb_retcode                  BOOLEAN;           -- ���b�Z�[�W�o�͂̃��^�[���E�R�[�h
    lv_org_code_sales           VARCHAR2(30);      -- �݌ɑg�D�R�[�h
    lv_nodata_profile           VARCHAR2(30);      -- ���擾�̃v���t�@�C����
    ln_token_value1             NUMBER;            -- ���b�Z�[�W �g�[�N���l
    -- *** ���[�J����O ***
    local_nodata_profile_expt   EXCEPTION;         -- �v���t�@�C���l�擾��O
    local_get_fail_expt         EXCEPTION;         -- �Ɩ����t�擾�G���[
--
  BEGIN
--
    ov_retcode := cv_status_normal;
    -- =============================================
    -- 1. ���b�Z�[�W�o��
    -- =============================================
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
--
    -- =============================================
    -- 2. �݌ɑg�D�R�[�h�擾
    -- =============================================
    lv_org_code_sales := FND_PROFILE.VALUE( cv_org_code_sales );
    IF( lv_org_code_sales IS NULL ) THEN
      lv_nodata_profile := cv_org_code_sales;
      RAISE local_nodata_profile_expt;
    END IF;
--
    -- =============================================
    -- 3. �݌ɑg�DID�̎擾
    -- =============================================
    gn_organization_id := xxcoi_common_pkg.get_organization_id(
                            lv_org_code_sales
                          );
    IF( gn_organization_id IS NULL ) THEN
      RAISE global_no_data_expt;
    END IF;
--
    -- =============================================
    -- 4. �^������ь�������ID���擾
    -- =============================================
    gn_month_control_id := FND_PROFILE.VALUE( cv_month_seq_id );
    IF( gn_month_control_id IS NULL ) THEN
      lv_nodata_profile := cv_month_seq_id;
      RAISE local_nodata_profile_expt;
    END IF;
--
    -- =============================================
    -- 5. �^������ѓ�������ID���擾
    -- =============================================
    gn_day_control_id := FND_PROFILE.VALUE( cv_day_seq_id );
    IF( gn_day_control_id IS NULL ) THEN
      lv_nodata_profile := cv_day_seq_id;
      RAISE local_nodata_profile_expt;
    END IF;
--
    -- =============================================
    -- 6. �{�Џ��i�敪�����擾
    -- =============================================
    gv_item_div_h := FND_PROFILE.VALUE( cv_item_div_h );
    IF( gv_item_div_h IS NULL ) THEN
      lv_nodata_profile := cv_item_div_h;
      RAISE local_nodata_profile_expt;
    END IF;
--
    -- =============================================
    -- 7. �O��o�b�`����I������(�����p)
    -- =============================================
    -- �G���[���b�Z�[�W.�g�[�N���l��ݒ�
    ln_token_value1 := gn_month_control_id;
    -- �ŏI�A�g����(�����p)�擾
    SELECT xcc.last_cooperation_date AS last_cooperation_date  -- �ŏI�A�g����(�����p)
    INTO   gd_month_last_coprt_date
    FROM   xxcoi_cooperation_control xcc
    WHERE  xcc.control_id = gn_month_control_id
    FOR UPDATE OF xcc.control_id NOWAIT
    ;
--
    -- =============================================
    -- 8. �O��o�b�`����I������(�����p)
    -- =============================================
    -- �G���[���b�Z�[�W.�g�[�N���l��ݒ�
    ln_token_value1 :=gn_day_control_id;
    -- �ŏI�A�g����(�����p)�擾
    SELECT xcc.last_cooperation_date AS last_cooperation_date  -- �ŏI�A�g����(�����p)
    INTO   gd_day_last_coprt_date
    FROM   xxcoi_cooperation_control xcc
    WHERE  xcc.control_id = gn_day_control_id
    FOR UPDATE OF xcc.control_id NOWAIT
    ;
--
    -- =============================================
    -- 9. �V�X�e�����t�̎擾
    -- =============================================
    gd_sysdate := SYSDATE;
--
    -- =============================================
    -- 10.�Ɩ��������t�擾
    -- =============================================
    gd_process_date := xxccp_common_pkg2.get_process_date;
    IF( gd_process_date IS NULL ) THEN
      RAISE local_get_fail_expt;
    END IF;
--
  EXCEPTION
    -- *** �Ɩ����t�擾�擾��O�n���h�� ***
    WHEN local_get_fail_expt THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_short_name_cok
                      ,iv_name         => cv_get_prcss_date_err_msg
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                       in_which    => FND_FILE.LOG
                      ,iv_message  => lv_errmsg
                      ,in_new_line => 0
                    );
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg,1,5000 );
      ov_retcode := cv_status_error;
    -- *** �v���t�@�C���擾��O�n���h�� ***
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
    -- *** �݌ɑg�DID�擾��O�n���h�� ***
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
    -- *** �f�[�^�A�g����e�[�u�����b�N��O�n���h�� ****
    WHEN global_lock_expt THEN
      lv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_short_name_cok
                      ,iv_name         => cv_lok_coprt_ctrl_err_msg
                      ,iv_token_name1  => cv_seigyo_id_token
                      ,iv_token_value1 => ln_token_value1
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                       in_which    =>   FND_FILE.OUTPUT
                      ,iv_message  =>   lv_out_msg
                      ,in_new_line =>   0
                    );
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg,1,5000 );
      ov_retcode := cv_status_error;
    -- *** �ŏI�A�g�����擾��O�n���h�� ****
    WHEN NO_DATA_FOUND THEN
      lv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_short_name_cok
                      ,iv_name         => cv_get_cop_date_err_msg
                      ,iv_token_name1  => cv_seigyo_id_token
                      ,iv_token_value1 => ln_token_value1
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
  END init;
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
    lv_errbuf              VARCHAR2(5000);   -- �G���[�E���b�Z�[�W
    lv_retcode             VARCHAR2(3);      -- ���^�[���E�R�[�h
    lv_errmsg              VARCHAR2(5000);   -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_out_msg             VARCHAR2(2000);   -- �o�̓��b�Z�[�W
    lb_retcode             BOOLEAN;          -- ���b�Z�[�W�o�͂̃��^�[���E�R�[�h
--
  BEGIN
--
    ov_retcode := cv_status_normal;
    -- =============================================
    -- �O���[�o���ϐ��̏�����
    -- =============================================
    gn_target_cnt         := 0;
    gn_normal_cnt         := 0;
    gn_error_cnt          := 0;
    gn_warn_cnt           := 0;
    gn_month_target_cnt1  := 0;
    gn_month_normal_cnt1  := 0;
    gn_month_error_cnt1   := 0;
    gn_month_target_cnt2  := 0;
    gn_month_normal_cnt2  := 0;
    gn_month_error_cnt2   := 0;
    gv_check_result       := cv_arai_gae_off;
    gv_day_process_result := cv_status_normal;
    gv_month_proc_result  := cv_status_normal;
--
    -- =============================================
    -- A-1.��������
    -- =============================================
    init(
       ov_errbuf      =>   lv_errbuf               -- �G���[�E���b�Z�[�W
      ,ov_retcode     =>   lv_retcode              -- ���^�[���E�R�[�h
      ,ov_errmsg      =>   lv_errmsg               -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
    -- ���������̃X�e�[�^�X��ϐ��Ɋi�[
    gv_day_process_result := lv_retcode;
    IF( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- =============================================
    -- A-2.�U�։^�����擾����(����)
    -- =============================================
    get_trans_freifht_info(
       ov_errbuf      =>   lv_errbuf               -- �G���[�E���b�Z�[�W
      ,ov_retcode     =>   lv_retcode              -- ���^�[���E�R�[�h
      ,ov_errmsg      =>   lv_errmsg               -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
    -- ���������̃X�e�[�^�X��ϐ��Ɋi�[
    gv_day_process_result := lv_retcode;
    IF( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- =============================================
    -- �o�^�f�[�^������ꍇ
    -- =============================================
    IF( g_trans_freifht_tab.COUNT > 0 ) THEN
      -- =============================================
      -- A-4.�^������уe�[�u�����䏈��
      -- =============================================
      control_dlv_cost_result(
         ov_errbuf       =>    lv_errbuf          -- �G���[�E���b�Z�[�W
        ,ov_retcode      =>    lv_retcode         -- ���^�[���E�R�[�h
        ,ov_errmsg       =>    lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W
      );
      -- ���������̃X�e�[�^�X��ϐ��Ɋi�[
      gv_day_process_result := lv_retcode;
      IF( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
--
      -- =============================================
      -- A-7.�f�[�^�A�g����e�[�u���X�V����
      -- =============================================
      update_data_coprt_cntrl(
         ov_errbuf         =>    lv_errbuf              -- �G���[�E���b�Z�[�W
        ,ov_retcode        =>    lv_retcode             -- ���^�[���E�R�[�h
        ,ov_errmsg         =>    lv_errmsg              -- ���[�U�[�E�G���[�E���b�Z�[�W
        ,in_control_id     =>    gn_day_control_id      -- ����ID
      );
      -- ���������̃X�e�[�^�X��ϐ��Ɋi�[
      gv_day_process_result := lv_retcode;
      IF( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
--
      -- =============================================
      -- ���������̃R�~�b�g
      -- =============================================
      IF( lv_retcode = cv_status_normal ) THEN
        COMMIT;
      END IF;
--
    END IF;
--
    -- =============================================
    -- A-8.�􂢑ւ����菈��
    -- =============================================
    check_lastmonth_fright_rslt(
       ov_errbuf       =>    lv_errbuf              -- �G���[�E���b�Z�[�W
      ,ov_retcode      =>    lv_retcode             -- ���^�[���E�R�[�h
      ,ov_errmsg       =>    lv_errmsg              -- ���[�U�[�E�G���[�E���b�Z�[�W
      ,ov_check_result =>    gv_check_result        -- �􂢑ւ����茋��
    );
    -- �������я����̃X�e�[�^�X��ϐ��Ɋi�[
    gv_month_proc_result := lv_retcode;
    IF( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- =============================================
    -- �􂢑ւ����茋�ʂ�1�F������������̏ꍇ�A
    -- ���������J�n
    -- =============================================
    IF( gv_check_result = cv_arai_gae_on ) THEN
      -- =============================================
      -- PL/SQL�\�̓����f�[�^�폜
      -- =============================================
      g_trans_freifht_tab.DELETE;
--
      -- =============================================
      -- A-9.�U�։^�����擾����(����)
      -- =============================================
      get_mon_trans_freifht_info(
         ov_errbuf     =>    lv_errbuf              -- �G���[�E���b�Z�[�W
        ,ov_retcode    =>    lv_retcode             -- ���^�[���E�R�[�h
        ,ov_errmsg     =>    lv_errmsg              -- ���[�U�[�E�G���[�E���b�Z�[�W
      );
      -- �������я����̃X�e�[�^�X��ϐ��Ɋi�[
      gv_month_proc_result := lv_retcode;
      IF( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
--
      -- =============================================
      -- ���т̓o�^�f�[�^������ꍇ
      -- =============================================
      IF( g_trans_freifht_tab.COUNT > 0 ) THEN
        -- =============================================
        -- A-10.�^������уe�[�u�����䏈��(����)
        -- =============================================
        control_dlv_cost_result2(
           ov_errbuf       =>    lv_errbuf          -- �G���[�E���b�Z�[�W
          ,ov_retcode      =>    lv_retcode         -- ���^�[���E�R�[�h
          ,ov_errmsg       =>    lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W
        );
        -- �������я����̃X�e�[�^�X��ϐ��Ɋi�[
        gv_month_proc_result := lv_retcode;
        IF( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        END IF;
--
        -- =============================================
        -- A-12.���ڐݒ菈��(����)
        -- =============================================
        control_item_set_up_month(
           ov_errbuf       =>    lv_errbuf          -- �G���[�E���b�Z�[�W
          ,ov_retcode      =>    lv_retcode         -- ���^�[���E�R�[�h
          ,ov_errmsg       =>    lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W
        );
        IF( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        END IF;
--
        -- =============================================
        -- A-13.�^������ь��ʏW�v�e�[�u���o�^����(����)
        -- =============================================
        insert_dlv_cost_result_sum(
           ov_errbuf     =>    lv_errbuf            -- �G���[�E���b�Z�[�W
          ,ov_retcode    =>    lv_retcode           -- ���^�[���E�R�[�h
          ,ov_errmsg     =>    lv_errmsg            -- ���[�U�[�E�G���[�E���b�Z�[�W
        );
        IF( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        END IF;
--
        -- =============================================
        -- A-7.�f�[�^�A�g����e�[�u���X�V����(����)
        -- =============================================
        update_data_coprt_cntrl(
           ov_errbuf         =>    lv_errbuf              -- �G���[�E���b�Z�[�W
          ,ov_retcode        =>    lv_retcode             -- ���^�[���E�R�[�h
          ,ov_errmsg         =>    lv_errmsg              -- ���[�U�[�E�G���[�E���b�Z�[�W
          ,in_control_id     =>    gn_month_control_id    -- ����ID
        );
        IF( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        END IF;
--
      END IF;
--
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
    lv_errbuf          VARCHAR2(5000);       -- �G���[�E���b�Z�[�W
    lv_retcode         VARCHAR2(3);          -- ���^�[���E�R�[�h
    lv_errmsg          VARCHAR2(5000);       -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_out_msg         VARCHAR2(2000);       -- �o�̓��b�Z�[�W
    lv_message_code    VARCHAR2(100);        -- �I�����b�Z�[�W
    lb_retcode         BOOLEAN;              -- ���b�Z�[�W�o�͂̃��^�[���E�R�[�h
    ln_new_line        NUMBER   DEFAULT 1;   -- ���s
--
  BEGIN
--
    -- =============================================
    -- �R���J�����g�w�b�_���b�Z�[�W�o�͊֐��̌Ăяo��
    -- =============================================
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
    -- =============================================
    -- �G���[�o��
    -- =============================================
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
    -- =============================================
    -- �ُ�I���̏ꍇ�̌����Z�b�g
    -- =============================================
    IF( lv_retcode = cv_status_error ) THEN
      IF( gv_day_process_result = cv_status_error ) THEN
        -- �������я����̌�����ݒ�
        gn_target_cnt := 0;
        gn_normal_cnt := 0;
        gn_error_cnt  := 1;
      ELSIF( gv_month_proc_result = cv_status_error ) THEN
        -- �������я����̌�����ݒ�
        gn_month_target_cnt1 := 0;
        gn_month_normal_cnt1 := 0;
        gn_month_error_cnt1  := 1;
      ELSE
        -- �������ʏ����̌�����ݒ�
        gn_month_target_cnt2 := 0;
        gn_month_normal_cnt2 := 0;
        gn_month_error_cnt2  := 1;
      END IF;
    END IF;
--
    -- �􂢑ւ�����̏ꍇ�A���������o�͌���s�Ȃ�
    IF( gv_check_result = cv_arai_gae_on ) THEN
      ln_new_line := 0;
    END IF;
    -- =============================================
    -- �^������юZ�o ��������MSG�o��
    -- =============================================
    lv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_short_name_cok
                    ,iv_name         => cv_day_proc_count_msg
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                     in_which    =>   FND_FILE.OUTPUT
                    ,iv_message  =>   lv_out_msg
                    ,in_new_line =>   0
                  );
    -- =============================================
    -- ���������� �����o��
    -- =============================================
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
    -- =============================================
    -- ���� ���������o��
    -- =============================================
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
    -- =============================================
    -- ���� �G���[�����o��
    -- =============================================
    lv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_short_name_ccp
                    ,iv_name         => cv_error_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR( gn_error_cnt )
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                     in_which    =>   FND_FILE.OUTPUT
                    ,iv_message  =>   lv_out_msg
                    ,in_new_line =>   ln_new_line
                  );
--
    -- =============================================
    -- �������������o�͔���
    -- �􂢑ւ�����̏ꍇ���A�������я����ŃG���[�̏ꍇ
    -- =============================================
    IF(   gv_check_result      = cv_arai_gae_on  )
      OR( gv_month_proc_result = cv_status_error )
    THEN
      -- �������я������G���[�̏ꍇ�A���s����
      IF( gv_month_proc_result = cv_status_error ) THEN
        ln_new_line := 1;
      END IF;
      -- =============================================
      -- �^������юZ�o �������ь���MSG�o��
      -- =============================================
      lv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_short_name_cok
                      ,iv_name         => cv_month_result_cnt_msg
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                       in_which    =>   FND_FILE.OUTPUT
                      ,iv_message  =>   lv_out_msg
                      ,in_new_line =>   0
                    );
      -- =============================================
      -- �������я����� �����o��
      -- =============================================
      lv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_short_name_ccp
                      ,iv_name         => cv_target_rec_msg
                      ,iv_token_name1  => cv_cnt_token
                      ,iv_token_value1 => TO_CHAR( gn_month_target_cnt1 )
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                       in_which    =>   FND_FILE.OUTPUT
                      ,iv_message  =>   lv_out_msg
                      ,in_new_line =>   0
                    );
      -- =============================================
      -- �������� ���������o��
      -- =============================================
      lv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_short_name_ccp
                      ,iv_name         => cv_success_rec_msg
                      ,iv_token_name1  => cv_cnt_token
                      ,iv_token_value1 => TO_CHAR( gn_month_normal_cnt1 )
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                       in_which    =>   FND_FILE.OUTPUT
                      ,iv_message  =>   lv_out_msg
                      ,in_new_line =>   0
                    );
      -- =============================================
      -- �������� �G���[�����o��
      -- =============================================
      lv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_short_name_ccp
                      ,iv_name         => cv_error_rec_msg
                      ,iv_token_name1  => cv_cnt_token
                      ,iv_token_value1 => TO_CHAR( gn_month_error_cnt1 )
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                       in_which    =>   FND_FILE.OUTPUT
                      ,iv_message  =>   lv_out_msg
                      ,in_new_line =>   ln_new_line
                    );
--
      -- =============================================
      -- �������я���������ɏI�����Ă���ꍇ�A
      -- �������ʏ����������o�͂���
      -- =============================================
      IF( gv_month_proc_result = cv_status_normal ) THEN
        -- ����̏ꍇ�A���s����
        ln_new_line := 1;
        -- =============================================
        -- �^������юZ�o �������ʌ���MSG�o��
        -- =============================================
        lv_out_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_app_short_name_cok
                        ,iv_name         => cv_month_sum_cnt_msg
                      );
        lb_retcode := xxcok_common_pkg.put_message_f(
                         in_which    =>   FND_FILE.OUTPUT
                        ,iv_message  =>   lv_out_msg
                        ,in_new_line =>   0
                      );
        -- =============================================
        -- �������ʏ����� �����o��
        -- =============================================
        lv_out_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_app_short_name_ccp
                        ,iv_name         => cv_target_rec_msg
                        ,iv_token_name1  => cv_cnt_token
                        ,iv_token_value1 => TO_CHAR( gn_month_target_cnt2 )
                      );
        lb_retcode := xxcok_common_pkg.put_message_f(
                         in_which    =>   FND_FILE.OUTPUT
                        ,iv_message  =>   lv_out_msg
                        ,in_new_line =>   0
                      );
        -- =============================================
        -- �������� ���������o��
        -- =============================================
        lv_out_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_app_short_name_ccp
                        ,iv_name         => cv_success_rec_msg
                        ,iv_token_name1  => cv_cnt_token
                        ,iv_token_value1 => TO_CHAR( gn_month_normal_cnt2 )
                      );
        lb_retcode := xxcok_common_pkg.put_message_f(
                         in_which    =>   FND_FILE.OUTPUT
                        ,iv_message  =>   lv_out_msg
                        ,in_new_line =>   0
                      );
        -- =============================================
        -- �������� �G���[�����o��
        -- =============================================
        lv_out_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_app_short_name_ccp
                        ,iv_name         => cv_error_rec_msg
                        ,iv_token_name1  => cv_cnt_token
                        ,iv_token_value1 => TO_CHAR( gn_month_error_cnt2 )
                      );
        lb_retcode := xxcok_common_pkg.put_message_f(
                         in_which    =>   FND_FILE.OUTPUT
                        ,iv_message  =>   lv_out_msg
                        ,in_new_line =>   ln_new_line
                      );
      END IF;
    END IF;
--
    -- =============================================
    -- �I�����b�Z�[�W
    -- =============================================
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
    -- =============================================
    -- �X�e�[�^�X�Z�b�g
    -- =============================================
    retcode := lv_retcode;
    -- =============================================
    -- �I���X�e�[�^�X���G���[�̏ꍇ��ROLLBACK����
    -- =============================================
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
END XXCOK023A02C;
/
