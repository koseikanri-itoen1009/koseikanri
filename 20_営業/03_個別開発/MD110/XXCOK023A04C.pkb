CREATE OR REPLACE PACKAGE BODY XXCOK023A04C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOK023A04C(body)
 * Description      : �^������я��Ɖ^����\�Z�����W�v���A�^����Ǘ��\(����)��CSV�`���ō쐬���܂��B
 * MD.050           : �^����Ǘ��\�o�� MD050_COK_023_A04
 * Version          : 1.3
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                  ��������(A-1)
 *  put_file_date         �^����Ǘ��\�̗v���o�͏���(A-6)
 *  get_budget_data       �^����\�Z���擾����(A-5)
 *  get_result_info_data  �^������я��擾����(A-3)
 *  get_base_data         ���_���o����(A-2)
 *  get_put_file_data     �v���o�͑Ώۃf�[�^�̎擾�E�o�͏���(A-2 �` A-6)
 *  submain               ���C�������v���V�[�W��
 *  main                  �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/12/03    1.0   SCS T.Taniguchi  �V�K�쐬
 *  2009/02/06    1.1   SCS T.Taniguchi  [��QCOK_018] �N�C�b�N�R�[�h�r���[�̗L�����E�������̔���ǉ�
 *  2009/03/02    1.2   SCS T.Taniguchi  [��QCOK_070] ���̓p�����[�^�u�E�Ӄ^�C�v�v�ɂ��A���_�̎擾�͈͂𐧌�
 *  2009/10/02    1.3   SCS S.Moriyama   [��QE_T3_00630] VDBM�c���ꗗ�\���o�͂���Ȃ��i���ޕs������j
 *
 *****************************************************************************************/
--
  -- �X�e�[�^�X�E�R�[�h
  cv_status_normal          CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal; --����:0
  cv_status_warn            CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_warn;   --�x��:1
  cv_status_error           CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_error;  --�ُ�:2
  -- WHO�J����
  cn_created_by             CONSTANT NUMBER      := fnd_global.user_id;         --CREATED_BY
  cd_creation_date          CONSTANT DATE        := SYSDATE;                    --CREATION_DATE
  cn_last_updated_by        CONSTANT NUMBER      := fnd_global.user_id;         --LAST_UPDATED_BY
  cd_last_update_date       CONSTANT DATE        := SYSDATE;                    --LAST_UPDATE_DATE
  cn_last_update_login      CONSTANT NUMBER      := fnd_global.login_id;        --LAST_UPDATE_LOGIN
  cn_request_id             CONSTANT NUMBER      := fnd_global.conc_request_id; --REQUEST_ID
  cn_program_application_id CONSTANT NUMBER      := fnd_global.prog_appl_id;    --PROGRAM_APPLICATION_ID
  cn_program_id             CONSTANT NUMBER      := fnd_global.conc_program_id; --PROGRAM_ID
  cd_program_update_date    CONSTANT DATE        := SYSDATE;                    --PROGRAM_UPDATE_DATE
  cv_msg_part               CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont               CONSTANT VARCHAR2(1) := '.';
  cn_number_0               CONSTANT NUMBER        := 0;
  cn_number_1               CONSTANT NUMBER        := 1;
  cn_month_5                CONSTANT NUMBER        := 5; -- 5��
-- �O���[�o���ϐ�
  gv_out_msg                VARCHAR2(2000) DEFAULT NULL;
  gv_sep_msg                VARCHAR2(2000) DEFAULT NULL;
  gv_exec_user              VARCHAR2(100)  DEFAULT NULL;
  gv_conc_name              VARCHAR2(30)   DEFAULT NULL;
  gv_conc_status            VARCHAR2(30)   DEFAULT NULL;
  gn_target_cnt             NUMBER DEFAULT 0;       -- �Ώی���
  gn_normal_cnt             NUMBER DEFAULT 0;       -- ���팏��
  gn_error_cnt              NUMBER DEFAULT 0;       -- �G���[����
  gn_warn_cnt               NUMBER DEFAULT 0;       -- �X�L�b�v����
--
  --*** ���������ʗ�O ***
  global_process_expt       EXCEPTION;
  --*** ���ʊ֐���O ***
  global_api_expt           EXCEPTION;
  --*** ���ʊ֐�OTHERS��O ***
  global_api_others_expt    EXCEPTION;
--
  PRAGMA EXCEPTION_INIT(global_api_others_expt,-20000);
--
  -- ===============================
  -- ���[�U�[��`��O
  -- ===============================
--  <exception_name>          EXCEPTION;     -- <��O�̃R�����g>
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  gv_pkg_name      CONSTANT VARCHAR2(12) := 'XXCOK023A04C'; -- �p�b�P�[�W��
  -- ���b�Z�[�W
  cv_normal_msg             CONSTANT VARCHAR2(16) := 'APP-XXCCP1-90004'; -- ����I�����b�Z�[�W
  cv_warn_msg               CONSTANT VARCHAR2(16) := 'APP-XXCCP1-90005'; -- �x���I�����b�Z�[�W
  cv_error_msg              CONSTANT VARCHAR2(16) := 'APP-XXCCP1-90006'; -- �G���[�I�����b�Z�[�W
  cv_msg_xxccp1_90000       CONSTANT VARCHAR2(16) := 'APP-XXCCP1-90000'; -- �Ώی����o��
  cv_msg_xxccp1_90001       CONSTANT VARCHAR2(16) := 'APP-XXCCP1-90001'; -- ���������o��
  cv_msg_xxccp1_90002       CONSTANT VARCHAR2(16) := 'APP-XXCCP1-90002'; -- �G���[�����o��
  cv_msg_xxccp1_90003       CONSTANT VARCHAR2(16) := 'APP-XXCCP1-90003'; -- �X�L�b�v�����o��
  cv_msg_xxcok1_10186       CONSTANT VARCHAR2(16) := 'APP-XXCOK1-10186'; -- �Ώۃf�[�^����
  cv_msg_xxcok1_00052       CONSTANT VARCHAR2(16) := 'APP-XXCOK1-00052'; -- �E��ID�擾�G���[
  cv_msg_xxcok1_10182       CONSTANT VARCHAR2(16) := 'APP-XXCOK1-10182'; -- ���_�擾�G���[
  cv_msg_xxcok1_00018       CONSTANT VARCHAR2(16) := 'APP-XXCOK1-00018'; -- �R���J�����g���̓p�����[�^(���_�R�[�h)
  cv_msg_xxcok1_00020       CONSTANT VARCHAR2(16) := 'APP-XXCOK1-00020'; -- �R���J�����g���̓p�����[�^2(�N�x)
  cv_msg_xxcok1_00021       CONSTANT VARCHAR2(16) := 'APP-XXCOK1-00021'; -- �R���J�����g���̓p�����[�^3(��)
  cv_msg_xxcok1_00012       CONSTANT VARCHAR2(16) := 'APP-XXCOK1-00012'; -- �������_�G���[
  cv_msg_xxcok1_10367       CONSTANT VARCHAR2(16) := 'APP-XXCOK1-10367'; -- �v���o�̓G���[
  cv_msg_xxcok1_00015       CONSTANT VARCHAR2(16) := 'APP-XXCOK1-00015'; -- �N�C�b�N�R�[�h�擾�G���[
  cv_msg_xxcok1_00028       CONSTANT VARCHAR2(16) := 'APP-XXCOK1-00028'; -- �Ɩ��������t�擾�G���[
  -- �g�[�N��
  cv_year                   CONSTANT VARCHAR2(4)  := 'YEAR';             -- �N�x
  cv_month                  CONSTANT VARCHAR2(5)  := 'MONTH';            -- ��
  cv_resp_name              CONSTANT VARCHAR2(9)  := 'RESP_NAME';        -- �E�Ӗ�
  cv_location_code          CONSTANT VARCHAR2(13) := 'LOCATION_CODE';    -- ���_�R�[�h
  cv_count                  CONSTANT VARCHAR2(5)  := 'COUNT';            -- ��������
  cv_token_lookup_value_set CONSTANT VARCHAR2(16) := 'LOOKUP_VALUE_SET'; -- �Q�ƃ^�C�v
  cv_user_id                CONSTANT VARCHAR2(7)  := 'USER_ID';          -- ���[�U�[ID
  -- application_short_name
  cv_appl_name_xxcok        CONSTANT VARCHAR2(5)  := 'XXCOK'; -- �A�v���P�[�V�����V���[�g�l�[��(XXCOK)
  cv_appl_name_xxccp        CONSTANT VARCHAR2(5)  := 'XXCCP'; -- �A�v���P�[�V�����V���[�g�l�[��(XXCCP)
  -- �l�Z�b�g��
  cv_flex_st_name_department  CONSTANT VARCHAR2(15) := 'XX03_DEPARTMENT'; -- ����
  -- �Q�ƃ^�C�v
  cv_lookup_type_put_val      CONSTANT VARCHAR2(30)  := 'XXCOK1_COST_MANAGEMENT_PUT_VAL';
  -- ���̑�
  cv_yyyymmdd               CONSTANT VARCHAR2(10)  := 'YYYY/MM/DD'; -- ���t�t�H�[�}�b�g
  cv_yyyymm                 CONSTANT VARCHAR2(6)   := 'YYYYMM';     -- ���t�t�H�[�}�b�g
  cv_dd                     CONSTANT VARCHAR2(2)   := 'DD';         -- ���t�t�H�[�}�b�g
  cv_dy                     CONSTANT VARCHAR2(2)   := 'DY';         -- ���t�t�H�[�}�b�g
  cv_cust_cd_base           CONSTANT VARCHAR2(1)   := '1';          -- �ڋq�敪('1':���_)
  cv_comma                  CONSTANT VARCHAR2(1)   := ',';          -- �J���}
  cv_kbn_koguchi            CONSTANT VARCHAR2(1)   := '1';          -- �����敪('1':����)
  cv_kbn_syatate            CONSTANT VARCHAR2(1)   := '0';          -- �����敪('0':�ԗ�)
  cv_resp_name_val          CONSTANT VARCHAR2(100) := fnd_global.resp_name; -- �E�Ӗ�
  cv_resp_type_1            CONSTANT VARCHAR2(1)   := '1';          -- �{������S���ҐE��
  cv_resp_type_2            CONSTANT VARCHAR2(1)   := '2';          -- ���_����_�S���ҐE��
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gv_base_code            VARCHAR2(4)  DEFAULT NULL; -- ���̓p�����[�^�̋��_�R�[�h
  gv_budget_year          VARCHAR2(4)  DEFAULT NULL; -- ���̓p�����[�^�̗\�Z�N�x
  gv_result_year          VARCHAR2(4)  DEFAULT NULL; -- ���̓p�����[�^�̔N�x
  gv_budget_month         VARCHAR2(2)  DEFAULT NULL; -- ���̓p�����[�^�̌�
  gn_resp_id              NUMBER       DEFAULT NULL; -- ���O�C���E��ID
  gn_user_id              NUMBER       DEFAULT NULL; -- ���O�C�����[�U�[ID
  gn_last_day             NUMBER       DEFAULT NULL; -- ������
  gd_process_date         DATE         DEFAULT NULL; -- �Ɩ��������t
  gv_resp_type            VARCHAR2(1)  DEFAULT NULL; -- �E�Ӄ^�C�v
--
  -- ===============================
  -- ���R�[�h�^�C�v�̐錾��
  -- ===============================
--
  -- ���_���̃��R�[�h�^�C�v
  TYPE base_rec IS RECORD(
    base_code        VARCHAR2(4), -- ���_�R�[�h
    base_name        VARCHAR2(50) -- ���_��
  );
--
  -- ===============================
  -- �e�[�u���^�C�v�̐錾��
  -- ===============================
  -- ���_���̃e�[�u���^�C�v
  TYPE base_tbl IS TABLE OF base_rec INDEX BY BINARY_INTEGER;
  -- ���z�E���ʃf�[�^�i�[
  TYPE number_tbl IS TABLE OF NUMBER INDEX BY BINARY_INTEGER;
  -- �ҏW�f�[�^�i�[
  TYPE varchar2_tbl IS TABLE OF VARCHAR2(100) INDEX BY BINARY_INTEGER;
--
  /**********************************************************************************
   * Procedure Name   : put_file_date
   * Description      : �^����Ǘ��\�̗v���o�͏���(A-6)
   ***********************************************************************************/
  PROCEDURE put_file_date(
    ov_errbuf                  OUT VARCHAR2,              -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode                 OUT VARCHAR2,              -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                  OUT VARCHAR2,              -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    iv_base_code               IN  VARCHAR2 DEFAULT NULL, -- ���_�R�[�h
    iv_base_name               IN  VARCHAR2 DEFAULT NULL, -- ���_��
    i_result_syatate_amt_ttype IN  number_tbl,            -- ����(�ԗ�)_���z
    i_result_koguchi_amt_ttype IN  number_tbl,            -- ����(����)_���z
    i_sum_amt_ttype            IN  number_tbl,            -- ���v
    i_total_amt_ttype          IN  number_tbl,            -- �݌v
    in_sum_syatate_amt         IN  NUMBER DEFAULT 0,      -- ���_�v_�ԗ����z
    in_sum_koguchi_amt         IN  NUMBER DEFAULT 0,      -- ���_�v_�������z
    in_sum_budget_amt          IN  NUMBER DEFAULT 0,      -- ���_�v_�\�Z���z
    in_sum_result_amt          IN  NUMBER DEFAULT 0,      -- ���_�v_���ы��z
    in_sum_diff_amt            IN  NUMBER DEFAULT 0)      -- ���_�v_���z���z
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(13) := 'put_file_date'; -- �v���O������
--
    lv_errbuf     VARCHAR2(5000) DEFAULT NULL; -- �G���[�E���b�Z�[�W
    lv_retcode    VARCHAR2(1)    DEFAULT NULL; -- ���^�[���E�R�[�h
    lv_errmsg     VARCHAR2(5000) DEFAULT NULL; -- ���[�U�[�E�G���[�E���b�Z�[�W
    -- *** ���[�J���E�J�[�\�� ***
    -- ���o���擾�J�[�\��
    CURSOR put_value_cur
    IS
      SELECT attribute1 AS put_val
      FROM   xxcok_lookups_v
      WHERE  lookup_type = cv_lookup_type_put_val
      AND    NVL( start_date_active,gd_process_date ) <= gd_process_date  -- �K�p�J�n��
      AND    NVL( end_date_active,gd_process_date )   >= gd_process_date  -- �K�p�I����
      ORDER BY TO_NUMBER(lookup_code)
    ;
    TYPE put_value_ttype IS TABLE OF put_value_cur%ROWTYPE INDEX BY BINARY_INTEGER;
    put_value_tab put_value_ttype;
    -- *** ���[�J���ϐ� ***
    lv_day        VARCHAR2(2)    DEFAULT NULL; -- �j��
    lv_manth_day  VARCHAR2(12)   DEFAULT NULL; -- ���ɔN����
    lb_retcode    BOOLEAN;
    ln_target_cnt NUMBER         DEFAULT 0;    -- �N�C�b�N�R�[�h�f�[�^�擾����
    -- *** ��O ***
    no_data_expt             EXCEPTION;      -- �f�[�^�擾�G���[
  BEGIN
--
    ov_retcode := cv_status_normal;
--
    OPEN  put_value_cur;
    FETCH put_value_cur BULK COLLECT INTO put_value_tab;
    CLOSE put_value_cur;
    -- ===============================================
    -- �Ώی����擾
    -- ===============================================
    ln_target_cnt := put_value_tab.COUNT;
    IF ( ln_target_cnt = 0 ) THEN
      RAISE no_data_expt;
    END IF;
    -- ===============================
    -- ���_�s�o��
    -- ===============================
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.OUTPUT, --OUTPUT
                    iv_message  => put_value_tab(1).put_val || iv_base_code || cv_comma || iv_base_name, --�o�̓f�[�^
                    in_new_line => cn_number_0      -- ���s��
                  );
    -- ===============================
    -- ���ږ��s�o��
    -- ===============================
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.OUTPUT, --OUTPUT
                    iv_message  => put_value_tab(2).put_val,    --�o�̓f�[�^
                    in_new_line => cn_number_0      -- ���s��
                  );
    -- ���ʃf�[�^�s�o��(1���`����)
    <<day_loop>>
    FOR i IN 1..gn_last_day LOOP
      -- �j���̎擾
      lv_day := TO_CHAR( TO_DATE( gv_result_year || TO_CHAR( gv_budget_month,'FM00' )
                || TO_CHAR( i,'FM00' ),cv_yyyymmdd ),cv_dy );
      -- ���ɔN�����̕ҏW
      lv_manth_day := gv_budget_month || put_value_tab(8).put_val || i
                      || put_value_tab(9).put_val || put_value_tab(10).put_val || lv_day || put_value_tab(11).put_val;
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.OUTPUT, --OUTPUT
                      iv_message  => lv_manth_day || cv_comma || i_result_syatate_amt_ttype(i)
                                     || cv_comma || i_result_koguchi_amt_ttype(i)
                                     || cv_comma || i_sum_amt_ttype(i)
                                     || cv_comma || i_total_amt_ttype(i),--�o�̓f�[�^
                      in_new_line => cn_number_0      -- ���s��
                    );
    END LOOP day_loop;
    -- ===============================
    -- ���_�v_�ԗ����z�s�o��
    -- ===============================
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.OUTPUT, --OUTPUT
                    iv_message  => put_value_tab(3).put_val || in_sum_syatate_amt, --�o�̓f�[�^
                    in_new_line => cn_number_0      -- ���s��
                  );
    -- ===============================
    -- ���_�v_�������z�s�o��
    -- ===============================
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.OUTPUT, --OUTPUT
                    iv_message  => put_value_tab(4).put_val || in_sum_koguchi_amt, --�o�̓f�[�^
                    in_new_line => cn_number_0      -- ���s��
                  );
    -- ===============================
    -- ���_�v_�\�Z���z�s�o��
    -- ===============================
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.OUTPUT, --OUTPUT
                    iv_message  => put_value_tab(5).put_val || in_sum_budget_amt, --�o�̓f�[�^
                    in_new_line => cn_number_0      -- ���s��
                  );
    -- ===============================
    -- ���_�v_���ы��z�s�o��
    -- ===============================
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.OUTPUT, --OUTPUT
                    iv_message  => put_value_tab(6).put_val || in_sum_result_amt, --�o�̓f�[�^
                    in_new_line => cn_number_0      -- ���s��
                  );
    -- ===============================
    -- ���_�v_���z���z�s�o��
    -- ===============================
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.OUTPUT, --OUTPUT
                    iv_message  => put_value_tab(7).put_val || in_sum_diff_amt, --�o�̓f�[�^
                    in_new_line => cn_number_0      -- ���s��
                  );
--
  EXCEPTION
    -- *** �f�[�^�擾��O ***
    WHEN no_data_expt THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_name_xxcok
                    , iv_name         => cv_msg_xxcok1_00015
                    , iv_token_name1  => cv_token_lookup_value_set
                    , iv_token_value1 => cv_lookup_type_put_val
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.LOG
                    , iv_message  => lv_errmsg
                    , in_new_line => cn_number_0
                    );
--
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( gv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errmsg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
  END put_file_date;
--
  /**********************************************************************************
   * Procedure Name   : get_budget_data
   * Description      : �^����\�Z���擾����(A-5)
   ***********************************************************************************/
  PROCEDURE get_budget_data(
    ov_errbuf                   OUT   VARCHAR2, -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode                  OUT   VARCHAR2, -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                   OUT   VARCHAR2, -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    iv_base_code                IN    xxcok_dlv_cost_result_info.base_code%TYPE  DEFAULT NULL, -- ���_�R�[�h
    ot_budget_amt               OUT   NUMBER)   -- �\�Z_���z
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(15) := 'get_budget_data'; -- �v���O������
--
    lv_errbuf     VARCHAR2(5000) DEFAULT NULL; -- �G���[�E���b�Z�[�W
    lv_retcode    VARCHAR2(1)    DEFAULT NULL; -- ���^�[���E�R�[�h
    lv_errmsg     VARCHAR2(5000) DEFAULT NULL; -- ���[�U�[�E�G���[�E���b�Z�[�W
  BEGIN
--
    ov_retcode := cv_status_normal;
--
    BEGIN
      -- ===============================
      -- �^����\�Z���擾
      -- ===============================
      -- �^����\�Z�e�[�u�����u�N�x�v�A�u���v�A�u���_�R�[�h�v�������ɁA�^����\�Z���z���W�v����
      SELECT NVL( SUM( dlv_cost_budget_amt ),0 )
      INTO   ot_budget_amt
      FROM   xxcok_dlv_cost_calc_budget
      WHERE  budget_year  = gv_budget_year
      AND    target_month = TO_CHAR( gv_budget_month,'FM00' )
      AND    base_code    = iv_base_code
      ;
    EXCEPTION
      -- *** NO_DATA_FOUND ***
      WHEN NO_DATA_FOUND THEN
        ot_budget_amt := 0;
    END;
--
  EXCEPTION
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
  END get_budget_data;
--
  /**********************************************************************************
   * Procedure Name   : get_result_info_data
   * Description      : �^������я��擾����(A-3)
   ***********************************************************************************/
  PROCEDURE get_result_info_data(
    ov_errbuf                   OUT   VARCHAR2, -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode                  OUT   VARCHAR2, -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                   OUT   VARCHAR2, -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    iv_base_code                IN    xxcok_dlv_cost_result_info.base_code%TYPE DEFAULT NULL,     -- ���_�R�[�h
    id_arrival_date             IN    xxcok_dlv_cost_result_info.arrival_date%TYPE DEFAULT NULL,  -- ���ד�
    ot_result_syatate_amt       OUT   xxcok_dlv_cost_result_info.dlv_cost_result_amt%TYPE, -- ����(�ԗ�)_���z
    ot_result_koguchi_amt       OUT   xxcok_dlv_cost_result_info.dlv_cost_result_amt%TYPE, -- ����(����)_���z
    on_sum_amt                  OUT   NUMBER)                                              -- ���v_���z
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(20) := 'get_result_info_data'; -- �v���O������
--
    lv_errbuf     VARCHAR2(5000) DEFAULT NULL; -- �G���[�E���b�Z�[�W
    lv_retcode    VARCHAR2(1)    DEFAULT NULL; -- ���^�[���E�R�[�h
    lv_errmsg     VARCHAR2(5000) DEFAULT NULL; -- ���[�U�[�E�G���[�E���b�Z�[�W
    -- *** ���[�J���E�J�[�\�� ***
    -- �^������уJ�[�\��
    CURSOR result_info_cur(
      i_base_code    IN xxcok_dlv_cost_result_info.base_code%TYPE,      -- ���_�R�[�h
      i_arrival_date IN xxcok_dlv_cost_result_info.arrival_date%TYPE)   -- ���ד�
    IS
      SELECT small_amt_type                      AS small_amt_type, -- �����敪
             NVL( SUM( dlv_cost_result_amt ),0 ) AS result_sum_amt  -- ���яW�v���z
      FROM   xxcok_dlv_cost_result_info
      WHERE  target_year           = gv_result_year
      AND    target_month          = TO_CHAR( gv_budget_month,'FM00' )
      AND    base_code             = i_base_code
      AND    TRUNC( arrival_date ) = i_arrival_date
      GROUP BY small_amt_type
      ORDER BY small_amt_type
    ;
    -- �^������уJ�[�\�����R�[�h�^
    result_info_rec result_info_cur%ROWTYPE;
  BEGIN
--
    ov_retcode := cv_status_normal;
--
    -- ���ѐ��ʁE���z�f�t�H���g�ݒ�
    ot_result_syatate_amt := 0; -- ����(�ԗ�)_���z
    ot_result_koguchi_amt := 0; -- ����(����)_���z
    on_sum_amt            := 0; -- ���v_���z
    -- ===============================
    -- �^������я��擾����
    -- ===============================
    <<result_info_loop>>
    FOR result_info_rec IN result_info_cur(
      iv_base_code,     -- ���_�R�[�h
      id_arrival_date   -- ���ד�
      ) LOOP
      -- ===============================
      -- ���ы��z�i�[����
      -- ===============================
      -- �����敪�ʂɋ��z��ݒ�
      -- �ԗ��̏ꍇ
      IF ( result_info_rec.small_amt_type = cv_kbn_syatate ) THEN
        ot_result_syatate_amt := result_info_rec.result_sum_amt; -- ����(�ԗ�)_���z
        -- ���v���z�W�v
        on_sum_amt := on_sum_amt + result_info_rec.result_sum_amt;
      -- �����̏ꍇ
      ELSIF ( result_info_rec.small_amt_type = cv_kbn_koguchi ) THEN
        ot_result_koguchi_amt := result_info_rec.result_sum_amt; -- ����(����)_���z
        -- ���v���z�W�v
        on_sum_amt := on_sum_amt + result_info_rec.result_sum_amt;
      ELSE
        -- ���v���z�W�v
        on_sum_amt := on_sum_amt + 0;
      END IF;
    END LOOP result_info_loop;
--
  EXCEPTION
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
  END get_result_info_data;
--
  /**********************************************************************************
   * Procedure Name   : get_base_data
   * Description      : ���_���o����(A-2)
   ***********************************************************************************/
  PROCEDURE get_base_data(
    ov_errbuf           OUT    VARCHAR2, -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT    VARCHAR2, -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT    VARCHAR2, -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    o_budget_ttype      OUT    base_tbl) -- ���_���
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(13) := 'get_base_data'; -- �v���O������
--
    lv_errbuf  VARCHAR2(5000) DEFAULT NULL; -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1)    DEFAULT NULL; -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000) DEFAULT NULL; -- ���[�U�[�E�G���[�E���b�Z�[�W
    -- *** ���[�J���ϐ� ***
    ln_base_index     NUMBER       DEFAULT 1;    -- ���_���p�C���f�b�N�X
    lv_resp_nm        VARCHAR2(40) DEFAULT NULL; -- �E�Ӗ�
    ln_main_resp_id   NUMBER       DEFAULT NULL; -- �{������S����
    ln_sales_resp_id  NUMBER       DEFAULT NULL; -- ���_����S����
    lv_belong_base_cd VARCHAR2(4)  DEFAULT NULL; -- �������_
    lb_retcode        BOOLEAN;
    -- *** ���[�J���E�J�[�\�� ***
    -- �E��ID�J�[�\��
    CURSOR resp_id_cur(
      iv_resp_name IN VARCHAR2) -- �E�Ӗ�
    IS
      SELECT responsibility_id AS responsibility_id
      FROM   fnd_responsibility_vl
      WHERE  responsibility_name = iv_resp_name
    ;
    -- �E��ID�J�[�\�����R�[�h�^
    resp_id_rec resp_id_cur%ROWTYPE;
    -- ���_���J�[�\��
    CURSOR base_name_cur(
      iv_base_code IN VARCHAR2) -- ���_�R�[�h
    IS
      SELECT account_name AS base_name
      FROM   hz_cust_accounts
      WHERE  account_number      = iv_base_code
      AND    customer_class_code = cv_cust_cd_base -- ���_
    ;
    -- ���_���J�[�\�����R�[�h�^
    base_name_rec base_name_cur%ROWTYPE;
    -- �z�����_�J�[�\��
    CURSOR child_base_cur(
      iv_base_code IN VARCHAR2) -- ���_�R�[�h
    IS
      SELECT  ffvnh.child_flex_value_high AS base_code, -- ���_�R�[�h
              hca.account_name            AS base_name  -- ���_��
      FROM    fnd_flex_value_norm_hierarchy ffvnh,
              fnd_flex_values_vl ffvv,
              hz_cust_accounts hca
      WHERE   ffvnh.parent_flex_value = (SELECT ffvnh.parent_flex_value
                                         FROM   fnd_flex_value_sets ffvs,
                                                fnd_flex_value_norm_hierarchy ffvnh
                                         WHERE  ffvs.flex_value_set_name    = cv_flex_st_name_department
                                         AND    ffvs.flex_value_set_id      = ffvnh.flex_value_set_id
                                         AND    ffvnh.child_flex_value_high = iv_base_code -- �������_�R�[�h
                                        )
      AND     ffvv.value_category         = cv_flex_st_name_department
      AND     ffvnh.child_flex_value_high = ffvv.flex_value
      AND     hca.account_number          = ffvv.flex_value
      AND     hca.customer_class_code     = cv_cust_cd_base -- ���_
      ORDER BY ffvnh.child_flex_value_high
    ;
    -- �z�����_�J�[�\�����R�[�h�^
    child_base_rec child_base_cur%ROWTYPE;
    -- *** ���[�J���E��O ***
    no_resp_id_expt EXCEPTION;
--
  BEGIN
--
    ov_retcode := cv_status_normal;
--
    -- ===============================
    -- ���_���̎擾
    -- ===============================
    -- ���̓p�����[�^�̋��_�����擾
    IF ( gv_base_code IS NOT NULL ) THEN
      <<base_name_loop>>
      FOR base_name_rec IN base_name_cur( gv_base_code ) LOOP
        o_budget_ttype(ln_base_index).base_code := gv_base_code;            -- ���_�R�[�h
        o_budget_ttype(ln_base_index).base_name := base_name_rec.base_name; -- ���_��
      END LOOP base_name_loop;
      -- ���_��񂪎擾�ł��Ȃ������ꍇ
      IF ( o_budget_ttype(1).base_name IS NULL ) THEN
        -- �G���[����
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_name_xxcok,
                       iv_name         => cv_msg_xxcok1_10182,
                       iv_token_name1  => cv_resp_name,
                       iv_token_value1 => cv_resp_name_val,
                       iv_token_name2  => cv_location_code,
                       iv_token_value2 => gv_base_code
                     );
        lv_errbuf := lv_errmsg;
        lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which    => FND_FILE.LOG
                      , iv_message  => lv_errmsg
                      , in_new_line => cn_number_0
                      );
        RAISE global_process_expt;
      END IF;
    -- �E�ӕʂɋ��_���擾
    ELSE
      -- ���ʊ֐���莩���_�R�[�h���擾����
-- 2009/10/02 Ver.1.3 [��QE_T3_00630] SCS S.Moriyama UPD START
--      lv_belong_base_cd := xxcok_common_pkg.get_base_code_f( SYSDATE,gn_user_id );
      lv_belong_base_cd := xxcok_common_pkg.get_base_code_f( gd_process_date, gn_user_id );
-- 2009/10/02 Ver.1.3 [��QE_T3_00630] SCS S.Moriyama UPD END
      -- �����_�R�[�h���擾�ł��Ȃ������ꍇ
      IF lv_belong_base_cd IS NULL THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_name_xxcok,
                       iv_name         => cv_msg_xxcok1_00012,
                       iv_token_name1  => cv_user_id,
                       iv_token_value1 => gn_user_id
                     );
        lv_errbuf := lv_errmsg;
        lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which    => FND_FILE.LOG
                      , iv_message  => lv_errmsg
                      , in_new_line => cn_number_0
                      );
        RAISE global_process_expt;
      END IF;
      -- ===============================
      -- �E�ӕʂ̋��_�擾����
      -- ===============================
      -- �{������S���ҐE�ӂ̏ꍇ
      IF ( gv_resp_type = cv_resp_type_1 ) THEN
        -- ���O�C�����[�U�[�̎����_���z���̋��_���擾
        <<child_base_loop>>
        FOR child_base_rec IN child_base_cur( lv_belong_base_cd ) LOOP
          o_budget_ttype(ln_base_index).base_code := child_base_rec.base_code; -- ���_�R�[�h
          o_budget_ttype(ln_base_index).base_name := child_base_rec.base_name; -- ���_��
          ln_base_index := ln_base_index + 1;
        END LOOP child_base_loop;
      -- ���_����_�S���ҐE�ӂ̏ꍇ
      ELSE
        -- �����_���擾
        o_budget_ttype(ln_base_index).base_code   := lv_belong_base_cd;        -- ���_�R�[�h
        <<resp_loop>>
        FOR base_name_rec IN base_name_cur( lv_belong_base_cd ) LOOP
          o_budget_ttype(ln_base_index).base_name := base_name_rec.base_name;  -- ���_��
        END LOOP resp_loop;
      END IF;
    END IF;
--
  EXCEPTION
    --*** �E��ID�擾�G���[ ***
    WHEN no_resp_id_expt THEN
--
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_name_xxcok,
                      iv_name         => cv_msg_xxcok1_00052,
                      iv_token_name1  => cv_resp_name,
                      iv_token_value1 => lv_resp_nm
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.LOG
                    , iv_message  => lv_errmsg
                    , in_new_line => cn_number_0
                    );
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( gv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errmsg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
  END get_base_data;
--
  /**********************************************************************************
   * Procedure Name   : get_put_file_data
   * Description      : �v���o�͑Ώۃf�[�^�̎擾�E�o�͏���(A-2 �` A-6)
   ***********************************************************************************/
  PROCEDURE get_put_file_data(
    ov_errbuf     OUT VARCHAR2, -- �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode    OUT VARCHAR2, -- ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg     OUT VARCHAR2) -- ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(17) := 'get_put_file_data'; -- �v���O������
--
    lv_errbuf  VARCHAR2(5000) DEFAULT NULL; -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1)    DEFAULT NULL; -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000) DEFAULT NULL; -- ���[�U�[�E�G���[�E���b�Z�[�W
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���ϐ� ***
    l_base_ttype                base_tbl;
    l_base_loop_index           NUMBER DEFAULT NULL;
    ld_target_date              DATE;
    -- �W�v�p�ϐ�
    ln_result_syatate_amt       NUMBER DEFAULT 0; -- ����(�ԗ�)_���z
    ln_result_koguchi_amt       NUMBER DEFAULT 0; -- ����(����)_���z
    ln_sum_syatate_amt          NUMBER DEFAULT 0; -- ���_�v_�ԗ����z
    ln_sum_koguchi_amt          NUMBER DEFAULT 0; -- ���_�v_�������z
    ln_sum_budget_amt           NUMBER DEFAULT 0; -- ���_�v_�\�Z���z
    ln_sum_result_amt           NUMBER DEFAULT 0; -- ���_�v_���ы��z
    ln_sum_diff_amt             NUMBER DEFAULT 0; -- ���_�v_���z���z
    ln_sum_amt                  NUMBER DEFAULT 0; -- ���v_���z
    ln_total_amt                NUMBER DEFAULT 0; -- �݌v_���z
    -- �o�͕ҏW��i�[�ϐ�
    l_result_syatate_amt_ttype  number_tbl; -- ����(�ԗ�)_���z
    l_result_koguchi_amt_ttype  number_tbl; -- ����(����)_���z
    l_sum_amt_ttype             number_tbl; -- ���v
    l_total_amt_ttype           number_tbl; -- �݌v
--
  BEGIN
--
    ov_retcode := cv_status_normal;
--
    -- ===============================
    -- ���_�f�[�^�̎擾(A-2.)
    -- ===============================
    get_base_data(
      ov_errbuf      => lv_errbuf,    -- �G���[�E���b�Z�[�W
      ov_retcode     => lv_retcode,   -- ���^�[���E�R�[�h
      ov_errmsg      => lv_errmsg,    -- ���[�U�[�E�G���[�E���b�Z�[�W
      o_budget_ttype => l_base_ttype  -- ���_���
    );
    -- �G���[����
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
    l_base_loop_index := l_base_ttype.FIRST;
    -- �擾�������_�̐������[�v���܂�
    <<base_loop>>
    WHILE ( l_base_loop_index IS NOT NULL ) LOOP
      -- ������
      ln_result_syatate_amt   := 0;      -- ����(�ԗ�)_���z
      ln_result_koguchi_amt   := 0;      -- ����(����)_���z
      ln_sum_amt              := 0;      -- ���v
      ln_total_amt            := 0;      -- �݌v
      ln_sum_syatate_amt      := 0;      -- ���_�v_�ԗ����z
      ln_sum_koguchi_amt      := 0;      -- ���_�v_�������z
      ln_sum_budget_amt       := 0;      -- ���_�v_�\�Z���z
      ln_sum_result_amt       := 0;      -- ���_�v_���ы��z
      ln_sum_diff_amt         := 0;      -- ���_�v_���z���z
      l_result_syatate_amt_ttype.DELETE; -- ����(�ԗ�)_���z
      l_result_koguchi_amt_ttype.DELETE; -- ����(����)_���z
      l_sum_amt_ttype.DELETE;            -- ���v
      l_total_amt_ttype.DELETE;          -- �݌v
      -- ===============================
      -- ���ʃ��[�v
      -- ===============================
      <<day_loop>>
      FOR i IN 1..gn_last_day LOOP
        -- �����Ώۓ�
        ld_target_date := TO_DATE( gv_result_year || TO_CHAR( gv_budget_month, 'FM00' )
                          || TO_CHAR( i, 'FM00' ),cv_yyyymmdd );
        -- ===============================
        -- �^������я��擾����(A-3)
        -- ===============================
        get_result_info_data(
          ov_errbuf             => lv_errbuf,    -- �G���[�E���b�Z�[�W
          ov_retcode            => lv_retcode,   -- ���^�[���E�R�[�h
          ov_errmsg             => lv_errmsg,    -- ���[�U�[�E�G���[�E���b�Z�[�W
          iv_base_code          => l_base_ttype(l_base_loop_index).base_code, -- ���_�R�[�h
          id_arrival_date       => ld_target_date,                            -- ���ד�
          ot_result_syatate_amt => ln_result_syatate_amt,                     -- ����(�ԗ�)_���z
          ot_result_koguchi_amt => ln_result_koguchi_amt,                     -- ����(����)_���z
          on_sum_amt            => ln_sum_amt                                 -- ���v_���z
        );
        -- �G���[����
        IF ( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        END IF;
        -- ===============================
        -- ���уf�[�^PL/SQL�\�i�[����(A-4.)
        -- ===============================
        -- ���ʂ̋��z��PL/SQL�\�Ɋi�[����
        l_result_syatate_amt_ttype(i) := ln_result_syatate_amt;     -- ����(�ԗ�)_���z
        l_result_koguchi_amt_ttype(i) := ln_result_koguchi_amt;     -- ����(����)_���z
        l_sum_amt_ttype(i)            := ln_sum_amt;                -- ���v_���z
        ln_total_amt                  := ln_total_amt + ln_sum_amt; -- �݌v���z�̏W�v
        l_total_amt_ttype(i)          := ln_total_amt;              -- �݌v���z
        -- ���z���W�v
        ln_sum_syatate_amt   := ln_sum_syatate_amt + ln_result_syatate_amt; -- ���_�v_�ԗ����z
        ln_sum_koguchi_amt   := ln_sum_koguchi_amt + ln_result_koguchi_amt; -- ���_�v_�������z
        ln_sum_result_amt    := ln_sum_result_amt + ln_sum_amt;             -- ���_�v_���ы��z
      END LOOP day_loop;
      -- ===============================
      -- �^����\�Z���擾����(A-5)
      -- ===============================
      get_budget_data(
        ov_errbuf     => lv_errbuf,                                 -- �G���[�E���b�Z�[�W           --# �Œ� #
        ov_retcode    => lv_retcode,                                -- ���^�[���E�R�[�h             --# �Œ� #
        ov_errmsg     => lv_errmsg,                                 -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        iv_base_code  => l_base_ttype(l_base_loop_index).base_code, -- ���_�R�[�h
        ot_budget_amt => ln_sum_budget_amt                          -- �\�Z_���z
      );
      -- ���ы��z�Ɨ\�Z���z���擾�ł����ꍇ(�\�Z�E���тƂ��ɋ��z��0�̏ꍇ�A�v���o�͂��Ȃ�)
      IF ( ln_sum_budget_amt > 0 ) OR ( ln_total_amt > 0 ) THEN
        -- ���z�v�Z
        ln_sum_diff_amt := ln_sum_budget_amt - ln_total_amt;
        -- �Ώی����J�E���g
        gn_target_cnt := gn_target_cnt + 1;
        -- ===============================
        -- �^����Ǘ��\�̗v���o�͏���(A-6)
        -- ===============================
        put_file_date(
          ov_errbuf                  => lv_errbuf,    -- �G���[�E���b�Z�[�W
          ov_retcode                 => lv_retcode,   -- ���^�[���E�R�[�h
          ov_errmsg                  => lv_errmsg,    -- ���[�U�[�E�G���[�E���b�Z�[�W
          iv_base_code               => l_base_ttype(l_base_loop_index).base_code, -- ���_�R�[�h
          iv_base_name               => l_base_ttype(l_base_loop_index).base_name, -- ���_��
          i_result_syatate_amt_ttype => l_result_syatate_amt_ttype,                -- ����(�ԗ�)_���z
          i_result_koguchi_amt_ttype => l_result_koguchi_amt_ttype,                -- ����(����)_���z
          i_sum_amt_ttype            => l_sum_amt_ttype,                           -- ���v
          i_total_amt_ttype          => l_total_amt_ttype,                         -- �݌v
          in_sum_syatate_amt         => ln_sum_syatate_amt,                        -- ���_�v_�ԗ����z
          in_sum_koguchi_amt         => ln_sum_koguchi_amt,                        -- ���_�v_�������z
          in_sum_budget_amt          => ln_sum_budget_amt,                         -- ���_�v_�\�Z���z
          in_sum_result_amt          => ln_sum_result_amt,                         -- ���_�v_���ы��z
          in_sum_diff_amt            => ln_sum_diff_amt                            -- ���_�v_���z���z
        );
        -- �G���[����
        IF ( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        END IF;
        -- ���������J�E���g
        gn_normal_cnt := gn_normal_cnt + 1;
      END IF;
      -- ���̃C���f�b�N�X��ԍ����擾
      l_base_loop_index := l_base_ttype.NEXT(l_base_loop_index);
    END LOOP base_loop;
--
  EXCEPTION
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
  END get_put_file_data;
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    ov_errbuf       OUT VARCHAR2,              -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode      OUT VARCHAR2,              -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg       OUT VARCHAR2,              -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    iv_base_code    IN  VARCHAR2 DEFAULT NULL, -- ���_�R�[�h
    iv_budget_year  IN  VARCHAR2 DEFAULT NULL, -- �N�x
    iv_budget_month IN  VARCHAR2 DEFAULT NULL, -- ��
    iv_resp_type    IN  VARCHAR2 DEFAULT NULL  -- �E�Ӄ^�C�v
   )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(4) := 'init'; -- �v���O������
--
    lv_errbuf  VARCHAR2(5000) DEFAULT NULL; -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1)    DEFAULT NULL; -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000) DEFAULT NULL; -- ���[�U�[�E�G���[�E���b�Z�[�W
    -- *** ���[�J���ϐ� ***
    lv_profile_nm   VARCHAR2(30) DEFAULT NULL; -- �v���t�@�C�����̂̊i�[�p
    lb_retcode      BOOLEAN;
    -- *** ���[�J���E��O ***
    no_profile_expt EXCEPTION; -- �v���t�@�C���l�擾�G���[
    no_process_date EXCEPTION; -- �Ɩ����t�擾�G���[
--
  BEGIN
--
    ov_retcode := cv_status_normal;
--
    -- ===============================
    -- ���̓p�����[�^�̑ޔ�
    -- ===============================
    gv_base_code    := iv_base_code;    -- ���_�R�[�h
    gv_budget_year  := iv_budget_year;  -- �N�x
    gv_resp_type    := iv_resp_type;    -- �E�Ӄ^�C�v
    -- 1�`4���͔N�x�̗��N�Ƃ��A5�`12���͔N�x�Ƃ���
    IF ( TO_NUMBER( iv_budget_month ) < cn_month_5 ) THEN
      gv_result_year  := TO_NUMBER( iv_budget_year ) + 1;  -- �N�x
    ELSE
      gv_result_year  := TO_NUMBER( iv_budget_year );      -- �N�x
    END IF;
    gv_budget_month := iv_budget_month; -- ��
    -- ===============================
    -- ���̓p�����[�^�̏o��
    -- ===============================
    -- �R���J�����g���̓p�����[�^���b�Z�[�W�o��(1:���_�R�[�h)
    gv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_appl_name_xxcok,
                    iv_name         => cv_msg_xxcok1_00018,
                    iv_token_name1  => cv_location_code,
                    iv_token_value1 => gv_base_code
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.LOG, -- LOG
                    iv_message  => gv_out_msg,   -- ���b�Z�[�W
                    in_new_line => cn_number_0   -- ���s��
                  );
    -- �R���J�����g���̓p�����[�^���b�Z�[�W�o��(2:�N�x)
    gv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_appl_name_xxcok,
                    iv_name         => cv_msg_xxcok1_00020,
                    iv_token_name1  => cv_year,
                    iv_token_value1 => gv_budget_year
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.LOG, -- LOG
                    iv_message  => gv_out_msg,   -- ���b�Z�[�W
                    in_new_line => cn_number_0   -- ���s��
                  );
    -- �R���J�����g���̓p�����[�^���b�Z�[�W�o��(3:��)
    gv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_appl_name_xxcok,
                    iv_name         => cv_msg_xxcok1_00021,
                    iv_token_name1  => cv_month,
                    iv_token_value1 => gv_budget_month
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.LOG, -- LOG
                    iv_message  => gv_out_msg,   -- ���b�Z�[�W
                    in_new_line => cn_number_1   -- ���s��
                  );
    -- ===============================
    -- �������̎擾
    -- ===============================
    -- ���̓p�����[�^�̔N�x�ƌ���茎�������擾����
    gn_last_day := TO_NUMBER( TO_CHAR( LAST_DAY( TO_DATE( gv_result_year
                   || TO_CHAR( gv_budget_month,'FM00' ),cv_yyyymm ) ),cv_dd ) );
    -- ===============================
    -- ���O�C�����̏��擾
    -- ===============================
    gn_resp_id := fnd_global.resp_id; -- �E��ID
    gn_user_id := fnd_global.user_id; -- ���[�U�[ID
    -- =============================================
    -- �Ɩ��������t�擾
    -- =============================================
    gd_process_date := xxccp_common_pkg2.get_process_date;
    IF( gd_process_date IS NULL ) THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_name_xxcok
                    , iv_name         => cv_msg_xxcok1_00028
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.LOG
                    , iv_message  => lv_errmsg
                    , in_new_line => cn_number_0
                    );
      RAISE no_process_date;
    END IF;
--
  EXCEPTION
    --*** �Ɩ����t�擾�擾�G���[ ***
    WHEN no_process_date THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( gv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errmsg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
  END init;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    ov_errbuf       OUT VARCHAR2,              -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode      OUT VARCHAR2,              -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg       OUT VARCHAR2,              -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    iv_base_code    IN  VARCHAR2 DEFAULT NULL, -- ���_�R�[�h
    iv_budget_year  IN  VARCHAR2 DEFAULT NULL, -- �N�x
    iv_budget_month IN  VARCHAR2 DEFAULT NULL, -- ��
    iv_resp_type    IN  VARCHAR2 DEFAULT NULL  -- �E�Ӄ^�C�v
    )
  IS
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(7) := 'submain'; -- �v���O������
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf  VARCHAR2(5000) DEFAULT NULL;  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1)    DEFAULT NULL;     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000) DEFAULT NULL;  -- ���[�U�[�E�G���[�E���b�Z�[�W
  BEGIN
--
    ov_retcode := cv_status_normal;
--
    -- �O���[�o���ϐ��̏�����
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
    -- ===============================
    -- ��������(A-1)
    -- ===============================
    init(
      ov_errbuf       => lv_errbuf,       -- �G���[�E���b�Z�[�W
      ov_retcode      => lv_retcode,      -- ���^�[���E�R�[�h
      ov_errmsg       => lv_errmsg,       -- ���[�U�[�E�G���[�E���b�Z�[�W
      iv_base_code    => iv_base_code,    -- ���_�R�[�h
      iv_budget_year  => iv_budget_year,  -- �N�x
      iv_budget_month => iv_budget_month, -- ��
      iv_resp_type    => iv_resp_type     -- �E�Ӄ^�C�v
    );
    -- �G���[����
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
    -- ===============================
    -- �v���o�͑Ώۃf�[�^�擾����(A2�`A6)
    -- ===============================
    get_put_file_data(
      lv_errbuf,  -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode, -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    -- �G���[����
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
  EXCEPTION
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
  END submain;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : �R���J�����g���s�t�@�C���o�^�v���V�[�W��
   **********************************************************************************/
  PROCEDURE main(
    errbuf          OUT VARCHAR2, -- �G���[�E���b�Z�[�W --# �Œ� #
    retcode         OUT VARCHAR2, -- ���^�[���E�R�[�h   --# �Œ� #
    iv_base_code    IN  VARCHAR2, -- 1.���_�R�[�h
    iv_budget_year  IN  VARCHAR2, -- 2.�N�x
    iv_budget_month IN  VARCHAR2, -- 3.��
    iv_resp_type    IN  VARCHAR2  -- 4.�E�Ӄ^�C�v
  )
--
  IS
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name         CONSTANT VARCHAR2(4)  := 'main';  -- �v���O������
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf       VARCHAR2(5000) DEFAULT NULL; -- �G���[�E���b�Z�[�W
    lv_retcode      VARCHAR2(1)    DEFAULT NULL; -- ���^�[���E�R�[�h
    lv_errmsg       VARCHAR2(5000) DEFAULT NULL; -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_message_code VARCHAR2(16)   DEFAULT NULL; -- ���b�Z�[�W�R�[�h
    lb_retcode      BOOLEAN;
--
  BEGIN
--
    -- �Œ�o��
    -- �R���J�����g�w�b�_���b�Z�[�W�o�͊֐��̌Ăяo��
    xxccp_common_pkg.put_log_header(
      iv_which   => 'LOG',--cn_fut_kbn_log, -- ���O�o��
      ov_retcode => lv_retcode,
      ov_errbuf  => lv_errbuf,
      ov_errmsg  => lv_errmsg
    );
    --
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_expt;
    END IF;
    -- ===============================
    -- submain�̌Ăяo��
    -- ===============================
    submain(
      ov_errbuf        => lv_errbuf,      -- �G���[�E���b�Z�[�W           --# �Œ� #
      ov_retcode       => lv_retcode,     -- ���^�[���E�R�[�h             --# �Œ� #
      ov_errmsg        => lv_errmsg,      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      iv_base_code    => iv_base_code,    -- ���_�R�[�h
      iv_budget_year  => iv_budget_year,  -- �N�x
      iv_budget_month => iv_budget_month, -- ��
      iv_resp_type    => iv_resp_type     -- �E�Ӄ^�C�v
    );
    --�G���[�o��
    IF ( lv_retcode = cv_status_error ) THEN
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.LOG, -- LOG
                      iv_message  => lv_errbuf ,   -- ���b�Z�[�W
                      in_new_line => cn_number_1   -- ���s��
                    );
      -- �Ώی����E���������E�G���[�����̐ݒ�
      gn_target_cnt := 0;
      gn_normal_cnt := 0;
      gn_error_cnt  := 1;
    END IF;
    -- �o�͌�����0���̏ꍇ
    IF (gn_normal_cnt = 0) AND ( lv_retcode = cv_status_normal )THEN
      -- �Ώۃf�[�^�����̃��b�Z�[�W�o��
      gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_name_xxcok,
                      iv_name         => cv_msg_xxcok1_10186,
                      iv_token_name1  => cv_year,
                      iv_token_value1 => gv_budget_year,
                      iv_token_name2  => cv_month,
                      iv_token_value2 => gv_budget_month
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                     in_which    => FND_FILE.LOG, -- LOG
                     iv_message  => gv_out_msg,   -- ���b�Z�[�W
                     in_new_line => cn_number_1   -- ���s��
                    );
    END IF;
    --�Ώی����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_appl_name_xxccp,
                    iv_name         => cv_msg_xxccp1_90000,
                    iv_token_name1  => cv_count,
                    iv_token_value1 => TO_CHAR( gn_target_cnt )
                   );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.LOG, -- LOG
                    iv_message  => gv_out_msg,   -- ���b�Z�[�W
                    in_new_line => cn_number_0   -- ���s��
                  );
    --���������o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_appl_name_xxccp,
                    iv_name         => cv_msg_xxccp1_90001,
                    iv_token_name1  => cv_count,
                    iv_token_value1 => TO_CHAR( gn_normal_cnt )
                   );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.LOG, -- LOG
                    iv_message  => gv_out_msg,   -- ���b�Z�[�W
                    in_new_line => cn_number_0   -- ���s��
                  );
    --�G���[�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_appl_name_xxccp,
                    iv_name         => cv_msg_xxccp1_90002,
                    iv_token_name1  => cv_count,
                    iv_token_value1 => TO_CHAR( gn_error_cnt )
                   );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.LOG, -- LOG
                    iv_message  => gv_out_msg,   -- ���b�Z�[�W
                    in_new_line => cn_number_1   -- ���s��
                  );
    --�I�����b�Z�[�W
    IF ( lv_retcode = cv_status_normal ) THEN
      lv_message_code := cv_normal_msg;
    ELSIF ( lv_retcode = cv_status_warn ) THEN
      lv_message_code := cv_warn_msg;
    ELSIF ( lv_retcode = cv_status_error ) THEN
      lv_message_code := cv_error_msg;
    END IF;
    gv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_appl_name_xxccp,
                    iv_name         => lv_message_code
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.LOG, -- LOG
                    iv_message  => gv_out_msg,   -- ���b�Z�[�W
                    in_new_line => cn_number_0   -- ���s��
                  );
    --�X�e�[�^�X�Z�b�g
    retcode := lv_retcode;
    --�I���X�e�[�^�X���G���[�̏ꍇ��ROLLBACK����
    IF ( retcode = cv_status_error ) THEN
      ROLLBACK;
    END IF;
--
  EXCEPTION
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      errbuf  := gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
      ROLLBACK;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      errbuf  := gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
      ROLLBACK;
  END main;
--
END XXCOK023A04C;
/
