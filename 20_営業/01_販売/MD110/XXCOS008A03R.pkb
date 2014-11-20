CREATE OR REPLACE PACKAGE BODY XXCOS008A03R
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOS008A03R (body)
 * Description      : �����󒍗�O�f�[�^���X�g
 * MD.050           : �����󒍗�O�f�[�^���X�g MD050_COS_008_A03
 * Version          : 1.8
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   (A-1)��������
 *  get_data               (A-2)��O�f�[�^�擾
 *  insert_rpt_wrk_data    (A-3)���[�N�e�[�u���f�[�^�o�^
 *  execute_svf            (A-4)SVF�R���J�����g�N��
 *  delete_rpt_wrk_data    (A-5)���[�N�e�[�u���f�[�^�폜
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009/01/09    1.0   T.Miyata         �V�K�쐬
 *  2009/02/16    1.1   SCS K.NAKAMURA   [COS_002] g,mg����kg�ւ̒P�ʊ��Z�̕s��Ή�
 *  2009/02/19    1.2   K.Atsushiba      get_msg�̃p�b�P�[�W���C��
 *  2009/04/10    1.3   T.Kitajima       [T1_0381]�o�׈˗����̐���0�f�[�^���O
 *  2009/05/26    1.4   T.Kitajima       [T1_1183]�󒍐��ʂ̃}�C�i�X��
 *  2009/06/17    1.5   N.Nishimura      [T1_1439]�Ώی���0�����A����I���Ƃ���
 *  2009/06/25    1.6   N.Nishimura      [T1_1437]�f�[�^�p�[�W�s��Ή�
 *  2009/07/08    1.7   N.Maeda          [0000484]�o�וi�ڂ��˗��i�ڂɕύX
 *  2009/07/27    1.8   N.Maeda          [0000834]�P�ʐݒ�擾�ӏ��ύX�Ή�
 *
 *****************************************************************************************/
--
--#######################  �Œ�O���[�o���萔�錾�� START   #######################
--
  --�X�e�[�^�X�E�R�[�h
  cv_status_normal          CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal; --����:0
  cv_status_warn            CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_warn;   --�x��:1
  cv_status_error           CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_error;  --�ُ�:2
  --WHO�J����
  cn_created_by             CONSTANT NUMBER      := fnd_global.user_id;         --CREATED_BY
  cd_creation_date          CONSTANT DATE        := SYSDATE;                    --CREATION_DATE
  cn_last_updated_by        CONSTANT NUMBER      := fnd_global.user_id;         --LAST_UPDATED_BY
  cd_last_update_date       CONSTANT DATE        := SYSDATE;                    --LAST_UPDATE_DATE
  cn_last_update_login      CONSTANT NUMBER      := fnd_global.login_id;        --LAST_UPDATE_LOGIN
  cn_request_id             CONSTANT NUMBER      := fnd_global.conc_request_id; --REQUEST_ID
  cn_program_application_id CONSTANT NUMBER      := fnd_global.prog_appl_id;    --PROGRAM_APPLICATION_ID
  cn_program_id             CONSTANT NUMBER      := fnd_global.conc_program_id; --PROGRAM_ID
  cd_program_update_date    CONSTANT DATE        := SYSDATE;                    --PROGRAM_UPDATE_DATE
  cv_msg_part      CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont      CONSTANT VARCHAR2(3) := '.';
--
--################################  �Œ蕔 END   ##################################
--
--#######################  �Œ�O���[�o���ϐ��錾�� START   #######################
--
  gv_out_msg       VARCHAR2(2000);
  gv_sep_msg       VARCHAR2(2000);
  gv_exec_user     VARCHAR2(100);
  gv_conc_name     VARCHAR2(30);
  gv_conc_status   VARCHAR2(30);
  gn_target_cnt    NUMBER;                    -- �Ώی���
  gn_normal_cnt    NUMBER;                    -- ���팏��
  gn_error_cnt     NUMBER;                    -- �G���[����
  gn_warn_cnt      NUMBER;                    -- �X�L�b�v����
--
--################################  �Œ蕔 END   ##################################
--
--##########################  �Œ苤�ʗ�O�錾�� START  ###########################
--
  --*** ���������ʗ�O ***
  global_process_expt       EXCEPTION;
  --*** ���ʊ֐���O ***
  global_api_expt           EXCEPTION;
  --*** ���ʊ֐�OTHERS��O ***
  global_api_others_expt    EXCEPTION;
--
  PRAGMA EXCEPTION_INIT( global_api_others_expt, -20000 );
--
--################################  �Œ蕔 END   ##################################
--
  -- ===============================
  -- ���[�U�[��`��O
  -- ===============================
  --*** �v���t�@�C���擾��O ***
  global_profile_expt         EXCEPTION;
  --*** �Ɩ����t�擾��O ***
  global_proc_date_expt       EXCEPTION;
  --*** �f�[�^�擾�G���[��O�n���h�� ***
  global_select_data_expt     EXCEPTION;
  --*** �����Ώۃf�[�^�o�^��O ***
  global_data_insert_expt     EXCEPTION;
  --*** SVF�N����O ***
  global_svf_excute_expt      EXCEPTION;
  --*** �����Ώۃf�[�^���b�N��O ***
  global_data_lock_expt       EXCEPTION;
  --*** �����Ώۃf�[�^���b�N��O ***
  global_insert_data_expt     EXCEPTION;
  --*** �����Ώۃf�[�^�폜��O ***
  global_delete_data_expt     EXCEPTION;
--
  PRAGMA EXCEPTION_INIT( global_data_lock_expt, -54 );
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name               CONSTANT  VARCHAR2(100) := 'XXCOS008A03R';        -- �p�b�P�[�W��
  cv_conc_name              CONSTANT  VARCHAR2(100) := 'XXCOS008A03R';        -- �R���J�����g��
--
  -- ���[�o�͊֘A
  cv_report_id              CONSTANT  VARCHAR2(100) := 'XXCOS008A03R';        -- ���[�h�c
  cv_frm_file               CONSTANT  VARCHAR2(100) := 'XXCOS008A03S.xml';    -- �t�H�[���l���t�@�C����
  cv_vrq_file               CONSTANT  VARCHAR2(100) := 'XXCOS008A03S.vrq';    -- �N�G���[�l���t�@�C����
  cv_output_mode            CONSTANT  VARCHAR2(1)   := '1';                   -- �o�͋敪(PDF)
  cv_extension              CONSTANT  VARCHAR2(100) := '.pdf';                -- �g���q(PDF)
  cv_xxcos_short_name       CONSTANT  VARCHAR2(100) := 'XXCOS';               -- �̕��Z�k�A�v����
--
  --���b�Z�[�W
  cv_msg_parameter_note     CONSTANT  VARCHAR2(100) := 'APP-XXCOS1-11701';    -- �p�����[�^�o�̓��b�Z�[�W
  cv_msg_profile_err        CONSTANT  VARCHAR2(100) := 'APP-XXCOS1-00004';    -- �v���t�@�C���擾�G���[
  cv_msg_process_date_err   CONSTANT  VARCHAR2(100) := 'APP-XXCOS1-00014';    -- �Ɩ����t�擾�G���[
  cv_msg_no_data_err        CONSTANT  VARCHAR2(100) := 'APP-XXCOS1-00018';    -- ����0���p���b�Z�[�W
  cv_msg_select_err         CONSTANT  VARCHAR2(100) := 'APP-XXCOS1-00013';    -- �f�[�^���o�G���[���b�Z�[�W
  cv_msg_insert_err         CONSTANT  VARCHAR2(100) := 'APP-XXCOS1-00010';    -- �f�[�^�o�^�G���[���b�Z�[�W
  cv_msg_api_err            CONSTANT  VARCHAR2(100) := 'APP-XXCOS1-00017';    -- API�G���[���b�Z�[�W
  cv_msg_lock_err           CONSTANT  VARCHAR2(100) := 'APP-XXCOS1-00001';    -- ���b�N�G���[
  cv_msg_delete_err         CONSTANT  VARCHAR2(100) := 'APP-XXCOS1-00012';    -- �f�[�^�폜�G���[���b�Z�[�W
--
  --�g�[�N����
  cv_tkn_nm_param_name      CONSTANT  VARCHAR2(100) := 'PARAM1';              -- �p�����[�^�F���_�R�[�h
  cv_tkn_nm_prof_name       CONSTANT  VARCHAR2(100) := 'PROFILE';             -- �v���t�@�C������
  cv_tkn_nm_api_name        CONSTANT  VARCHAR2(100) := 'API_NAME';            -- API����
  cv_tkn_nm_table_name      CONSTANT  VARCHAR2(100) := 'TABLE_NAME';          -- �e�[�u������
  cv_tkn_nm_key_data        CONSTANT  VARCHAR2(100) := 'KEY_DATA';            -- �L�[�f�[�^
  cv_tkn_nm_lock_table_name CONSTANT  VARCHAR2(100) := 'TABLE';               -- �e�[�u������
--
  --�g�[�N���l
  cv_msg_vl_api_name        CONSTANT  VARCHAR2(100) := 'APP-XXCOS1-00041';    -- SVF�N��API
  cv_msg_vl_org_name        CONSTANT  VARCHAR2(100) := 'APP-XXCOS1-00047';    -- MO:�c�ƒP��
  cv_msg_vl_max_date_name   CONSTANT  VARCHAR2(100) := 'APP-XXCOS1-00056';    -- XXCOS:MAX���t
  cv_msg_vl_request_id      CONSTANT  VARCHAR2(100) := 'APP-XXCOS1-11702';    -- ���N�G�X�gID
  cv_msg_vl_table_name      CONSTANT  VARCHAR2(100) := 'APP-XXCOS1-11703';    -- �����󒍗�O�f�[�^���X�g���[���[�N�e�[�u��
  cv_msg_vl_lookup_name     CONSTANT  VARCHAR2(100) := 'APP-XXCOS1-00066';    -- �N�C�b�N�R�[�h�}�X�^
--
  --�v���t�@�C��
  cv_prof_org_id            CONSTANT  VARCHAR2(100) := 'ORG_ID';              -- �c�ƒP��
  cv_prof_max_date          CONSTANT  VARCHAR2(100) := 'XXCOS1_MAX_DATE';     -- �v���t�@�C����(MAX���t)
--
  --�N�C�b�N�^�C�v
  -- �ۊǏꏊ���ޒ�������}�X�^
  cv_hokan_direct_type_mst  CONSTANT  fnd_lookup_values.lookup_type%TYPE := 'XXCOS1_HOKAN_DIRECT_TYPE_MST';
  -- ��݌ɕi�ڃR�[�h
  cv_no_inv_item_code       CONSTANT  fnd_lookup_values.lookup_type%TYPE := 'XXCOS1_NO_INV_ITEM_CODE';
  -- �d�ʊ��Z�}�X�^
  cv_weight_uom_cnv_mst     CONSTANT  fnd_lookup_values.lookup_type%TYPE := 'XXCOS1_WEIGHT_UOM_CNV';
--
  --�N�C�b�N�R�[�h
  -- �ۊǏꏊ���ޒ�������}�X�^
  cv_hokan_direct_11        CONSTANT  fnd_lookup_values.lookup_code%TYPE := 'XXCOS_DIRECT_11';
--
  -- ���t�t�H�[�}�b�g
  cv_yyyymmdd               CONSTANT  VARCHAR2(8)   := 'YYYYMMDD';               -- YYYYMMDD
  cv_fmt_date               CONSTANT  VARCHAR2(10)  := 'YYYY/MM/DD';             -- YYYY/MM/DD
  cv_yyyymmddhhmiss         CONSTANT  VARCHAR2(21)  := 'YYYY/MM/DD HH24:MI:SS';  -- YYYY/MM/DD HH24:MI:SS
--
  -- Y/N�t���O
  cv_yes_flg                CONSTANT  VARCHAR2(1)   := 'Y';                   -- Yes
  cv_no_flg                 CONSTANT  VARCHAR2(1)   := 'N';                   -- No
--
  -- �p�����[�^�F���_ALL
  cv_base_all               CONSTANT  VARCHAR2(3)   := 'ALL';                 -- ���i���S�ʏo�͔���
--
  -- �ڋq�敪
  cv_party_type_1           CONSTANT  VARCHAR2(1)   := '1';                   -- �ڋq�敪�F���_
--
  -- �󒍃X�e�[�^�X
  cv_status_booked          CONSTANT  VARCHAR2(10)  := 'BOOKED';              -- �L���ς�
  cv_status_closed          CONSTANT  VARCHAR2(10)  := 'CLOSED';              -- �N���[�Y
  cv_status_cancelled       CONSTANT  VARCHAR2(10)  := 'CANCELLED';           -- ���
--
  -- �󒍃w�b�_�A�h�I���X�e�[�^�X
  cv_h_add_status_04        CONSTANT  VARCHAR2(2)   := '04';                  -- �o�׎��ьv���
  cv_h_add_status_99        CONSTANT  VARCHAR2(2)   := '99';                  -- ���
--
  -- �󒍖��׃^�C�v
  cv_order                  CONSTANT  VARCHAR2(10)  := 'ORDER';               -- ��
--
  -- �����ȂǗ�O���o��SQL����肷��ׂɍ��ځB�������͒l���Z�b�g���ĉ������B
  -- �f�[�^�敪
  cv_data_class_1           CONSTANT  VARCHAR2(1)   := '';                   -- ��O�P�擾�r�p�k
  cv_data_class_2           CONSTANT  VARCHAR2(1)   := '';                   -- ��O�Q�擾�r�p�k
  cv_data_class_3           CONSTANT  VARCHAR2(1)   := '';                   -- ��O�R�|�P�擾�r�p�k
  cv_data_class_4           CONSTANT  VARCHAR2(1)   := '';                   -- ��O�R�|�Q�擾�r�p�k
  cv_data_class_5           CONSTANT  VARCHAR2(1)   := '';                   -- ��O�S�擾�r�p�k
  cv_data_class_6           CONSTANT  VARCHAR2(1)   := '';                   -- ��O�T�擾�r�p�k
--
--****************************** 2009/04/10 1.3 T.Kitajima ADD START ******************************--
  cn_ship_zero              CONSTANT  NUMBER        := 0;                    -- �o�׎���0
--****************************** 2009/04/10 1.3 T.Kitajima ADD  END  ******************************--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  -- ���[���[�N�p�e�[�u���^��`
  TYPE g_rpt_data_ttype IS TABLE OF xxcos_rep_direct_list%ROWTYPE INDEX BY BINARY_INTEGER;
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  -- ���[���[�N�����e�[�u��
  gt_rpt_data_tab        g_rpt_data_ttype;
--
  -- �����擾
  gd_process_date        DATE;                     -- �Ɩ����t
  gn_org_id              NUMBER;                   -- �c�ƒP��
  gd_max_date            DATE;                     -- MAX���t
--
  --�ۊǏꏊ����
  gv_subinventory_class  VARCHAR2(2);
--
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    iv_base_code  IN  VARCHAR2,     --   1.���_�R�[�h
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name     CONSTANT VARCHAR2(100) := 'init';                 -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lv_para_msg      VARCHAR2(5000);
    lv_profile_name  VARCHAR2(5000);
    lv_max_date      VARCHAR2(5000);
    lv_table_name    VARCHAR2(5000);
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    --==================================
    -- 1.�p�����[�^�o��
    --==================================
    lv_para_msg := xxccp_common_pkg.get_msg(
                     iv_application        => cv_xxcos_short_name,
                     iv_name               => cv_msg_parameter_note,
                     iv_token_name1        => cv_tkn_nm_param_name,
                     iv_token_value1       => iv_base_code
                   );
--
    FND_FILE.PUT_LINE(
       which  =>  FND_FILE.LOG
      ,buff   =>  lv_para_msg
    );
--
    --1�s��
    FND_FILE.PUT_LINE(
       which  =>  FND_FILE.LOG
      ,buff   =>  NULL
    );
--
    --==================================
    -- 2.MO:�c�ƒP��
    --==================================
    gn_org_id := FND_PROFILE.VALUE( cv_prof_org_id );
--
    -- �v���t�@�C�����擾�ł��Ȃ��ꍇ�̓G���[
    IF ( gn_org_id IS NULL ) THEN
      lv_profile_name := xxccp_common_pkg.get_msg(
                           iv_application => cv_xxcos_short_name,
                           iv_name        => cv_msg_vl_org_name
                         );
      RAISE global_profile_expt;
    END IF;
--
    --==================================
    -- 3.XXCOS:MAX���t
    --==================================
    lv_max_date := FND_PROFILE.VALUE( cv_prof_max_date );
--
    -- �v���t�@�C�����擾�ł��Ȃ��ꍇ�̓G���[
    IF ( lv_max_date IS NULL ) THEN
      --�v���t�@�C����������擾
      lv_profile_name := xxccp_common_pkg.get_msg(
                           iv_application => cv_xxcos_short_name,
                           iv_name        => cv_msg_vl_max_date_name
                         );
--
      RAISE global_profile_expt;
    END IF;
    gd_max_date := TO_DATE( lv_max_date, cv_fmt_date );
--
    --==================================
    -- 4.�Ɩ����t�擾
    --==================================
    gd_process_date := TRUNC( xxccp_common_pkg2.get_process_date );
--
    IF ( gd_process_date IS NULL ) THEN
      RAISE global_proc_date_expt;
    END IF;
--
    --==================================
    -- 5.�Q�ƃR�[�h�擾�i�ۊǏꏊ���ޒ�������}�X�^�j
    --==================================
    BEGIN
      SELECT
        flv.meaning
      INTO
        gv_subinventory_class
      FROM
        fnd_application               fa,
        fnd_lookup_types              flt,
        fnd_lookup_values             flv
      WHERE
          fa.application_id           = flt.application_id
      AND flt.lookup_type             = flv.lookup_type
      AND fa.application_short_name   = cv_xxcos_short_name
      AND flv.lookup_type             = cv_hokan_direct_type_mst
      AND flv.lookup_code             = cv_hokan_direct_11
      AND flv.start_date_active      <= gd_process_date
      AND gd_process_date            <= NVL( flv.end_date_active, gd_max_date )
      AND flv.enabled_flag            = cv_yes_flg
      AND flv.language                = USERENV( 'LANG' )
      ;
--
   EXCEPTION
     WHEN OTHERS THEN
       lv_table_name := xxccp_common_pkg.get_msg(
                          iv_application => cv_xxcos_short_name,
                          iv_name        => cv_msg_vl_lookup_name
                        );
       RAISE global_select_data_expt;
   END;
--
--
  EXCEPTION
    -- �v���t�@�C���擾��O
    WHEN global_profile_expt THEN
--
      ov_errmsg := xxccp_common_pkg.get_msg(
                     iv_application        => cv_xxcos_short_name,
                     iv_name               => cv_msg_profile_err,
                     iv_token_name1        => cv_tkn_nm_prof_name,
                     iv_token_value1       => lv_profile_name
                   );
--
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg, 1, 5000 );
      ov_retcode := cv_status_error;
--
    -- �Ɩ����t�擾��O
    WHEN global_proc_date_expt THEN
--
      ov_errmsg := xxccp_common_pkg.get_msg(
                     iv_application         => cv_xxcos_short_name,
                     iv_name                => cv_msg_process_date_err
                   );
--
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg, 1, 5000 );
      ov_retcode := cv_status_error;
--
    -- �f�[�^�擾��O
    WHEN global_select_data_expt THEN
--
      ov_errmsg := xxccp_common_pkg.get_msg(
                     iv_application         => cv_xxcos_short_name,
                     iv_name                => cv_msg_select_err,
                     iv_token_name1         => cv_tkn_nm_table_name,
                     iv_token_value1        => lv_table_name,
                     iv_token_name2         => cv_tkn_nm_key_data,
                     iv_token_value2        => NULL
                   );
--
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg, 1, 5000 );
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END init;
--
  /**********************************************************************************
   * Procedure Name   : get_data
   * Description      : ��O�f�[�^�擾(A-2)
   ***********************************************************************************/
  PROCEDURE get_data(
    iv_base_code  IN  VARCHAR2,     --   1.���_�R�[�h
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_data'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lv_key_info      VARCHAR2(5000);
    ln_idx           NUMBER;
    ln_record_id     NUMBER;
--
    -- *** ���[�J���E�J�[�\�� ***
--
    CURSOR data_cur
    IS
  --** ����O�P�擾SQL
      SELECT
         ooa1.base_code                  base_code                -- �ڋq�ǉ����Ͻ�.�[�i���_���ށF���_����
        ,ooa1.base_name                  base_name                -- �ڋqϽ�2.�ڋq����           �F���_����
        ,ooa1.order_number               order_number             -- ��ͯ��.�󒍔ԍ�           �F�󒍔ԍ�
        ,ooa1.order_line_no              order_line_no            -- �󒍖���.���הԍ�           �F�󒍖���No
        ,ooa2.line_no                    line_no                  -- �󒍖��ױ�޵�.���הԍ�      �F����No
        ,ooa1.deliver_requested_no       deliver_requested_no     -- ��ͯ�ޱ�޵�.�˗�No        �F�o�׈˗�No
        ,ooa1.deliver_from_whse_number   deliver_from_whse_number -- ��ͯ�ޱ�޵�.�o�׌��ۊǏꏊ�F�o�׌��q�ɔԍ�
        ,ooa1.deliver_from_whse_name     deliver_from_whse_name   -- �ۊǏꏊ.�ۊǏꏊ����       �F�o�׌��q�ɖ�
        ,ooa1.customer_number            customer_number          -- ��ͯ�ޱ�޵�.�ڋq          �F�ڋq�ԍ�
        ,ooa1.customer_name              customer_name            -- �ڋqϽ�.�ڋq����            �F�ڋq��
        ,ooa1.item_code                  item_code                -- �󒍖��ױ�޵�.�˗��i��      �F�i�ں���
        ,ooa1.item_name                  item_name                -- OPM�i�ڱ�޵�                �F�i��
        ,TRUNC( ooa1.schedule_dlv_date ) schedule_dlv_date        -- ��ͯ��.����               �F�[�i�\���
        ,ooa1.schedule_inspect_date      schedule_inspect_date    -- �󒍖���.�����\���         �F�����\���
        ,ooa2.arrival_date               arrival_date             -- ��ͯ�ޱ�޵�.���ד�        �F����
        ,ooa1.order_quantity             order_quantity           -- �󒍖���.�󒍐���           �F�󒍐�
        ,ooa2.deliver_actual_quantity    deliver_actual_quantity  -- �󒍖��ױ�޵�.�o�׎��ѐ���  �F�o�׎��ѐ�
-- ******************** 2009/07/27 1.8 N.Maeda MOD start ******************************* --
--        ,ooa1.uom_code                   uom_code                 -- �󒍖��ױ�޵�.�P��          �F�P��
        ,ooa2.uom_code                   uom_code                 -- �󒍖��ױ�޵�.�P��          �F�P��
-- ******************** 2009/07/27 1.8 N.Maeda MOD  end  ******************************* --
        ,ooa1.order_quantity
          - ooa2.deliver_actual_quantity output_quantity          -- ���ِ�
        ,cv_data_class_1                 data_class               -- ��O�f�[�^�P                �F�f�[�^�敪
      FROM
        -- ****** ��O�P�c�ƃT�u�N�G���Fooa1 ******
        ( SELECT
             xca.delivery_base_code     base_code                -- �ڋq�ǉ����Ͻ�.�[�i���_���ށF���_����
            ,hca2.account_name          base_name                -- �ڋqϽ�2.�ڋq����           �F���_����
            ,ooha.order_number          order_number             -- ��ͯ��.�󒍔ԍ�           �F�󒍔ԍ�
            ,oola.line_number           order_line_no            -- �󒍖���.���הԍ�           �F�󒍖���No
            ,oola.packing_instructions  deliver_requested_no     -- �󒍖���.����w��           �F�o�׈˗�No
            ,oola.subinventory          deliver_from_whse_number -- �󒍖���.�ۊǏꏊ           �F�o�׌��q�ɔԍ�
            ,mtsi.description           deliver_from_whse_name   -- �ۊǏꏊ.�ۊǏꏊ����       �F�o�׌��q�ɖ�
            ,hca.account_number         customer_number          -- �ڋqϽ�.�ڋq����            �F�ڋq�ԍ�
            ,hca.account_name           customer_name            -- �ڋqϽ�.�ڋq����            �F�ڋq��
            ,NVL( oola.attribute6, oola.ordered_item )
                                        item_code                -- �󒍖���.�󒍕i��           �F�i�ں���
            ,ximb.item_short_name       item_name                -- OPM�i�ڱ�޵�                �F�i��
            ,oola.request_date          schedule_dlv_date        -- �󒍖���.�v����             �F�[�i�\���
            ,oola.attribute4            schedule_inspect_date    -- �󒍖���.�����\���         �F�����\���
            ,ooas.order_quantity        order_quantity           -- �󒍖���.�󒍐���           �F�󒍐�
            ,oola.order_quantity_uom    uom_code                 -- �󒍖���.�󒍒P��           �F�P��
          FROM
             oe_order_headers_all       ooha  -- ��ͯ��ð���
            ,oe_order_lines_all         oola  -- �󒍖���ð���
            ,hz_cust_accounts           hca   -- �ڋqϽ�
            ,xxcmm_cust_accounts        xca   -- �ڋq�ǉ����Ͻ�
            ,mtl_secondary_inventories  mtsi  -- �ۊǏꏊϽ�
            ,hz_cust_accounts           hca2  -- �ڋqϽ�2
            ,ic_item_mst_b              iimb  -- OPM�i��
            ,xxcmn_item_mst_b           ximb  -- OPM�i�ڱ�޵�
            -- �ŏI��p�T�u�N�G���Fooal
            ,( SELECT
--MIYATA DELETE ����ID��ͯ�ށ^���׋��ɓ���ł���̂ŕs�v
--                  MAX(ooha.header_id)        header_id   -- ��ͯ��.��ͯ��ID
--                 ,MAX(line_id)               line_id     -- �󒍖���.�󒍖���ID
                 MAX( line_id )              line_id     -- �󒍖���.�󒍖���ID
--MIYATA DELETE
               FROM
                  oe_order_headers_all       ooha        -- ��ͯ��ð���
                 ,oe_order_lines_all         oola        -- �󒍖���ð���
                 ,hz_cust_accounts           hca         -- �ڋqϽ�
                 ,xxcmm_cust_accounts        xca         -- �ڋq�ǉ����Ͻ�
                 ,mtl_secondary_inventories  mtsi        -- �ۊǏꏊϽ�
               WHERE
                    ooha.header_id    =  oola.header_id                      -- ��ͯ��.��ͯ��ID = �󒍖���.��ͯ��ID
               AND  ooha.org_id       =  gn_org_id                           -- ��ͯ��.�g�DID = A-1�擾�̉c�ƒP��
               AND  oola.subinventory =  mtsi.secondary_inventory_name       -- �󒍖���.�ۊǏꏊ = �ۊǏꏊϽ�.�ۊǏꏊ����
               AND  oola.ship_from_org_id  =  mtsi.organization_id           -- �󒍖���.�o�׌��g�DID = �ۊǏꏊϽ�.�g�DID
               AND  mtsi.attribute13       =  gv_subinventory_class          -- �ۊǏꏊϽ�.�ۊǏꏊ���� = '11':����
               AND  ooha.flow_status_code  =  cv_status_booked               -- ��ͯ��.�ð�� = 'BOOKED'
                                                                             -- �󒍖���.�ð�� NOT IN( 'CLOSED','CANCELLED')
               AND  oola.flow_status_code  NOT IN ( cv_status_closed, cv_status_cancelled )
               AND  oola.packing_instructions  IS NOT NULL                   -- �󒍖���.����w�� IS NOT NULL
               AND  NOT EXISTS ( SELECT                                      -- NVL(�󒍖���.�q�R�[�h,�󒍖���.�󒍕i��)����݌ɕi�ڃR�[�h
                                   'X'                 exists_flag -- EXISTS�׸�
                                 FROM
                                    fnd_application    fa
                                   ,fnd_lookup_types   flt
                                   ,fnd_lookup_values  flv
                                 WHERE
                                      fa.application_id           = flt.application_id
                                 AND  flt.lookup_type             = flv.lookup_type
                                 AND  fa.application_short_name   = cv_xxcos_short_name
                                 AND  flv.lookup_type             = cv_no_inv_item_code
                                 AND  flv.start_date_active      <= gd_process_date
                                 AND  gd_process_date            <= NVL( flv.end_date_active, gd_max_date )
                                 AND  flv.enabled_flag            = cv_yes_flg
                                 AND  flv.language                = USERENV( 'LANG' )
                                 AND  NVL(oola.attribute6,oola.ordered_item) = flv.lookup_code
                               )
               AND  ooha.sold_to_org_id        =  hca.cust_account_id        -- ��ͯ��.�ڋqID = �ڋqϽ�.�ڋqID
               AND  hca.cust_account_id        =  xca.customer_id            -- �ڋqϽ�.�ڋqID  = �ڋq�ǉ����Ͻ�.�ڋqID
                                                                             -- �ڋq�ǉ����Ͻ�.�[�i���_ = DECODE('ALL','ALL',���Ұ�.���_����)
               AND  xca.delivery_base_code     =  DECODE( iv_base_code
                                                         ,cv_base_all
                                                         ,xca.delivery_base_code
                                                         ,iv_base_code )
               GROUP BY
                  oola.packing_instructions
                 ,NVL( oola.attribute6, oola.ordered_item )
             ) ooal
             ,
             -- �T�}���[�p�T�u�N�G���Fooas
             ( SELECT
                  oola.packing_instructions                    deliver_requested_no     -- �󒍖���.����w���i�o�׈˗�No�j
                 ,NVL( oola.attribute6, oola.ordered_item )    item_code                -- NVL(�󒍖���.�q�R�[�h,�󒍖���.�󒍕i��)
                 ,SUM( oola.ordered_quantity * DECODE ( otta.order_category_code, cv_order, 1, -1 )
                        * CASE oola.order_quantity_uom
                          WHEN msib.primary_unit_of_measure THEN 1
                          WHEN item_cnv.uom_code THEN TO_NUMBER( item_cnv.cnv_value )
                          ELSE NVL( xicv.conversion_rate, 0 )
                        END
                  ) AS order_quantity
               FROM
                  oe_order_headers_all       ooha        -- ��ͯ��ð���
                 ,oe_order_lines_all         oola        -- �󒍖���ð���
                 ,hz_cust_accounts           hca         -- �ڋqϽ�
                 ,xxcmm_cust_accounts        xca         -- �ڋq�ǉ����Ͻ�
                 ,mtl_secondary_inventories  mtsi        -- �ۊǏꏊϽ�
                 ,mtl_system_items_b         msib        -- Disc�i�ځi�c�Ƒg�D�j
                 ,oe_transaction_types_tl    ottt        -- �󒍎���^�C�v�i�E�v�j
                 ,oe_transaction_types_all   otta        -- �󒍎���^�C�v�}�X�^
                 ,xxcos_item_conversions_v   xicv        -- �i�ڊ��ZView
                 ,(
                   SELECT
                       flv.meaning      AS UOM_CODE
                     , flv.description  AS CNV_VALUE
                   FROM
                     fnd_application   fa,
                     fnd_lookup_types  flt,
                     fnd_lookup_values flv
                   WHERE
                         fa.application_id         = flt.application_id
                     AND flt.lookup_type           = flv.lookup_type
                     AND fa.application_short_name = cv_xxcos_short_name
                     AND flv.enabled_flag          = cv_yes_flg
                     AND flv.language              = USERENV( 'LANG' )
                     AND flv.start_date_active    <= gd_process_date
                     AND gd_process_date          <= NVL( flv.end_date_active, gd_max_date )
                     AND flv.lookup_type           = cv_weight_uom_cnv_mst
                 ) item_cnv
               WHERE
                    ooha.header_id    =  oola.header_id                      -- ��ͯ��.��ͯ��ID = �󒍖���.��ͯ��ID
               AND  ooha.org_id       =  gn_org_id                           -- ��ͯ��.�g�DID = A-1�擾�̉c�ƒP��
               AND  oola.line_type_id        = ottt.transaction_type_id      -- �󒍖���.��������ID = �󒍎������(�E�v).����ID
               AND  ottt.transaction_type_id = otta.transaction_type_id      -- �󒍎������(�E�v).����ID = �󒍎������.����ID
               AND  ottt.language            = USERENV( 'LANG' )             -- �󒍎������(�E�v).����ID = 'JA'
               AND  oola.subinventory =  mtsi.secondary_inventory_name       -- �󒍖���.�ۊǏꏊ = �ۊǏꏊϽ�.�ۊǏꏊ����
               AND  oola.ship_from_org_id  =  mtsi.organization_id           -- �󒍖���.�o�׌��g�DID = �ۊǏꏊϽ�.�g�DID
               AND  mtsi.attribute13       =  gv_subinventory_class          -- �ۊǏꏊϽ�.�ۊǏꏊ���� = '11':����
                                                                             -- ��ͯ��.�ð�� IN ( 'BOOKED','CLOSED' )
               AND  ooha.flow_status_code      IN ( cv_status_booked, cv_status_closed )
               AND  oola.flow_status_code      <> cv_status_cancelled        -- �󒍖���.�ð�� <> 'CANCELLED'
               AND  oola.packing_instructions  IS NOT NULL                   -- �󒍖���.����w�� IS NOT NULL
               AND  NOT EXISTS ( SELECT                                      -- NVL(�󒍖���.�q�R�[�h,�󒍖���.�󒍕i��)����݌ɕi�ڃR�[�h
                                   'X'                 exists_flag -- EXISTS�׸�
                                 FROM
                                    fnd_application    fa
                                   ,fnd_lookup_types   flt
                                   ,fnd_lookup_values  flv
                                 WHERE
                                      fa.application_id           = flt.application_id
                                 AND  flt.lookup_type             = flv.lookup_type
                                 AND  fa.application_short_name   = cv_xxcos_short_name
                                 AND  flv.lookup_type             = cv_no_inv_item_code
                                 AND  flv.start_date_active      <= gd_process_date
                                 AND  gd_process_date            <= NVL( flv.end_date_active, gd_max_date )
                                 AND  flv.enabled_flag            = cv_yes_flg
                                 AND  flv.language                = USERENV( 'LANG' )
                                 AND  NVL(oola.attribute6,oola.ordered_item) = flv.lookup_code
                               )
               AND  ooha.sold_to_org_id        =  hca.cust_account_id        -- ��ͯ��.�ڋqID = �ڋqϽ�.�ڋqID
               AND  hca.cust_account_id        =  xca.customer_id            -- �ڋqϽ�.�ڋqID  = �ڋq�ǉ����Ͻ�.�ڋqID
                                                                             -- �ڋq�ǉ����Ͻ�.�[�i���_ = DECODE('ALL','ALL',���Ұ�.���_����)
               AND  xca.delivery_base_code     =  DECODE( iv_base_code
                                                         ,cv_base_all
                                                         ,xca.delivery_base_code
                                                         ,iv_base_code )
                                                                             -- NVL(�󒍖���.�q�R�[�h,�󒍖���.�󒍕i��)
                                                                             --     = Disc�i��.�i�ڃR�[�h
               AND  NVL( oola.attribute6, oola.ordered_item ) = msib.segment1
               AND  oola.ship_from_org_id      = msib.organization_id        -- �󒍖���.�o�׌��g�D = Disc�i��.�g�DID
                                                                             -- NVL(�󒍖���.�q�R�[�h,�󒍖���.�󒍕i��)
               AND  NVL( oola.attribute6, oola.ordered_item ) = xicv.item_code(+)  --     = �i�ڊ��ZView.�i�ڃR�[�h
               AND  oola.order_quantity_uom    = xicv.to_uom_code(+)         -- �󒍖���.�󒍒P�� = �i�ڊ��ZView.�ϊ���P��
               AND  oola.order_quantity_uom    = item_cnv.uom_code(+)
               GROUP BY
                  oola.packing_instructions
                 ,NVL( oola.attribute6, oola.ordered_item )
             ) ooas
          WHERE
               ooha.header_id    =  oola.header_id                    -- ��ͯ��.��ͯ��ID = �󒍖���.��ͯ��ID
          AND  ooha.org_id       =  gn_org_id                         -- ��ͯ��.�g�DID = A-1�擾�̉c�ƒP��
          AND  oola.subinventory =  mtsi.secondary_inventory_name     -- �󒍖���.�ۊǏꏊ = �ۊǏꏊϽ�.�ۊǏꏊ����
          AND  oola.ship_from_org_id  =  mtsi.organization_id         -- �󒍖���.�o�׌��g�DID = �ۊǏꏊϽ�.�g�DID
          AND  mtsi.attribute13       =  gv_subinventory_class        -- �ۊǏꏊϽ�.�ۊǏꏊ���� = '11':����
          AND  ooha.flow_status_code  =  cv_status_booked             -- ��ͯ��.�ð�� = 'BOOKED'
                                                                      -- �󒍖���.�ð�� NOT IN( 'CLOSED','CANCELLED')
          AND  oola.flow_status_code  NOT IN ( cv_status_closed, cv_status_cancelled )
          AND  oola.packing_instructions  IS NOT NULL                 -- �󒍖���.����w�� IS NOT NULL
          AND  ooha.sold_to_org_id     =  hca.cust_account_id         -- ��ͯ��.�ڋqID = �ڋqϽ�.�ڋqID
          AND  hca.cust_account_id     =  xca.customer_id             -- �ڋqϽ�.�ڋqID  = �ڋq�ǉ����Ͻ�.�ڋqID
                                                                      -- �ڋq�ǉ����Ͻ�.�[�i���_ = DECODE('ALL','ALL',���Ұ�.���_����)
          AND  xca.delivery_base_code  =  DECODE( iv_base_code
                                                 ,cv_base_all
                                                 ,xca.delivery_base_code
                                                 ,iv_base_code )
          AND  hca2.customer_class_code  =  cv_party_type_1               -- �ڋqϽ�2.�ڋq�敪 = '1':���_
          AND  hca2.account_number       =  xca.delivery_base_code        -- �ڋqϽ�2.�ڋq���� = �ڋq�ǉ����Ͻ�.�[�i���_����
          AND  NVL( oola.attribute6, oola.ordered_item ) = iimb.item_no   -- NVL(�󒍖���.�q�R�[�h,�󒍖���.�󒍕i�� = OPM�i��.�i�ں���
          AND  iimb.item_id              =  ximb.item_id                  -- OPM�i��.�i��ID = OPM�i�ڱ�޵�.�i��id
          AND  TRUNC( ximb.start_date_active )                    <=  gd_process_date    -- OPM�i�ڱ�޵�.�K�p�J�n�� <= �Ɩ����t
          AND  TRUNC( NVL( ximb.end_date_active, gd_max_date ) )  >=  gd_process_date    -- OPM�i�ڱ�޵�.�K�p�I���� >= �Ɩ����t
--MIYATA DELETE ����ID��ͯ�ށ^���׋��ɓ���ł���̂ŕs�v
--          AND  ooha.header_id             = ooal.header_id                -- ��ͯ��.��ͯ��ID = �ŏI��p.��ͯ��ID
--MIYATA DELETE
          AND  oola.line_id               = ooal.line_id                  -- �󒍖���.�󒍖���ID = �ŏI��p.�󒍖���ID
          AND  oola.packing_instructions  = ooas.deliver_requested_no     -- ��O�P�c�ƃT�u�N�G��.�o�׈˗�No = �T�}���[�p�T�u�N�G��.�o�׈˗�No
          AND  NVL( oola.attribute6, oola.ordered_item ) = ooas.item_code -- ��O�P�c�ƃT�u�N�G��.�i�ڃR�[�h = �T�}���[�p�T�u�N�G��.�i�ڃR�[�h
        )
        ooa1,
        -- ****** ��O�P���Y�T�u�N�G���Fooa2 ******
        ( SELECT
             xola.order_line_number     line_no                  -- �󒍖��ױ�޵�.���הԍ�      �F����No
            ,xoha.request_no            deliver_requested_no     -- ��ͯ�ޱ�޵�.�˗�No        �F�o�׈˗�No
-- ******************** 2009/07/08 1.7 N.Maeda MOD start ******************************* --
            ,xola.request_item_code     item_code                -- �󒍖��ױ�޵�.�˗��i��      �F�i�ں���
--            ,xola.shipping_item_code    item_code                -- �󒍖��ױ�޵�.�o�וi��      �F�i�ں���
-- ******************** 2009/07/08 1.7 N.Maeda MOD  end  ******************************* --
            ,xoha.arrival_date          arrival_date             -- ��ͯ�ޱ�޵�.���ד�        �F����
            ,xola.shipped_quantity      deliver_actual_quantity  -- �󒍖��ױ�޵�.�o�׎��ѐ���  �F�o�׎��ѐ�
-- ******************** 2009/07/27 1.8 N.Maeda MOD start ******************************* --
            ,xola.uom_code              uom_code                 -- �󒍖��ױ�޵�.�P��          �F�P��
-- ******************** 2009/07/27 1.8 N.Maeda MOD  end  ******************************* --
          FROM
             xxwsh_order_headers_all    xoha  -- ��ͯ�ޱ�޵�
            ,xxwsh_order_lines_all      xola  -- �󒍖��ױ�޵�
            ,hz_cust_accounts           hca   -- �ڋqϽ�
            ,xxcmm_cust_accounts        xca   -- �ڋq�ǉ����Ͻ�
          WHERE
               xoha.order_header_id      =   xola.order_header_id      -- ��ͯ�ޱ�޵�.��ͯ�ޱ�޵�ID = �󒍖��ױ�޵�.��ͯ�ޱ�޵�ID
          AND  xoha.req_status           =   cv_h_add_status_04        -- ��ͯ�ޱ�޵�.�ð�� = �o�׎��ьv���
          AND  xoha.latest_external_flag =   cv_yes_flg                -- ��ͯ�ޱ�޵�.�ŐV�׸� = 'Y'
          AND  NVL( xola.delete_flag, cv_no_flg ) = cv_no_flg          -- �󒍖��ױ�޵�.�폜�׸� = 'N'
--****************************** 2009/04/10 1.3 T.Kitajima ADD START ******************************--
          AND  NVL( xola.shipped_quantity, cn_ship_zero ) != cn_ship_zero  -- �󒍖��ױ�޵�.�o�׎��ѐ��ʂ�0�ȊO
--****************************** 2009/04/10 1.3 T.Kitajima ADD  END  ******************************--
--MIYATA MODIFY
--          AND  xoha.customer_id          =   hca.cust_account_id       -- ��ͯ�ޱ�޵�.�ڋqID = �ڋqϽ�.�ڋqID
          AND  xoha.customer_code        =   hca.account_number        -- ��ͯ�ޱ�޵�.�ڋq = �ڋqϽ�.�ڋq�R�[�h
--MIYATA MODIFY
          AND  hca.cust_account_id       =   xca.customer_id           -- �ڋqϽ�.�ڋqID  = �ڋq�ǉ����Ͻ�.�ڋqID
          AND  xca.delivery_base_code    =   DECODE( iv_base_code      -- �ڋq�ǉ����Ͻ�.�[�i���_ = DECODE('ALL','ALL',���Ұ�.���_����)
                                                    ,cv_base_all
                                                    ,xca.delivery_base_code
                                                    ,iv_base_code )
        )
        ooa2
      WHERE
           ooa1.deliver_requested_no =   ooa2.deliver_requested_no -- ��O�P�c�ƃT�u�N�G��.�o�׈˗�No = ��O�P���Y�T�u�N�G��.�o�׈˗�No
      AND  ooa1.item_code            =   ooa2.item_code            -- ��O�P�c�ƃT�u�N�G��.�i�ڃR�[�h = ��O�P���Y�T�u�N�G��.�i�ڃR�[�h
      AND                                                          -- ��O�P�c�ƃT�u�N�G��.�󒍐� <> ��O�P���Y�T�u�N�G��.�o�׎��ѐ�
        (  ooa1.order_quantity                 <>  ooa2.deliver_actual_quantity
         OR                                                        -- ��O�P�c�ƃT�u�N�G��.�[�i�\��� <> ��O�P���Y�T�u�N�G��.����
           TRUNC( ooa1.schedule_dlv_date )     <>  ooa2.arrival_date
         OR
           (                                                       -- ��O�P�c�ƃT�u�N�G��.�[�i�\��� =  ��O�P���Y�T�u�N�G��.����
             ( TRUNC( ooa1.schedule_dlv_date ) =   ooa2.arrival_date )
             AND
             ( ooa1.schedule_inspect_date IS NOT NULL )            -- ��O�P�c�ƃT�u�N�G��.�����\��� IS NOT NULL
             AND                                                   -- ��O�P�c�ƃT�u�N�G��.�����\��� < ��O�P���Y�T�u�N�G��.����
             ( TO_DATE( ooa1.schedule_inspect_date, cv_yyyymmddhhmiss ) < ooa2.arrival_date )
           )
        )
--
      UNION
--
  --** ����O�Q�擾SQL
      SELECT
         ooa1.base_code                  base_code                -- �ڋq�ǉ����Ͻ�.�[�i���_���ށF���_����
        ,ooa1.base_name                  base_name                -- �ڋqϽ�2.�ڋq����           �F���_����
        ,ooa1.order_number               order_number             -- ��ͯ��.�󒍔ԍ�           �F�󒍔ԍ�
        ,ooa1.order_line_no              order_line_no            -- �󒍖���.���הԍ�           �F�󒍖���No
        ,ooa2.line_no                    line_no                  -- �󒍖��ױ�޵�.���הԍ�      �F����No
        ,ooa1.deliver_requested_no       deliver_requested_no     -- ��ͯ�ޱ�޵�.�˗�No        �F�o�׈˗�No
        ,ooa1.deliver_from_whse_number   deliver_from_whse_number -- ��ͯ�ޱ�޵�.�o�׌��ۊǏꏊ�F�o�׌��q�ɔԍ�
        ,ooa1.deliver_from_whse_name     deliver_from_whse_name   -- �ۊǏꏊ.�ۊǏꏊ����       �F�o�׌��q�ɖ�
        ,ooa1.customer_number            customer_number          -- ��ͯ�ޱ�޵�.�ڋq          �F�ڋq�ԍ�
        ,ooa1.customer_name              customer_name            -- �ڋqϽ�.�ڋq����            �F�ڋq��
        ,ooa1.item_code                  item_code                -- �󒍖��ױ�޵�.�˗��i��      �F�i�ں���
        ,ooa1.item_name                  item_name                -- OPM�i�ڱ�޵�                �F�i��
        ,TRUNC( ooa1.schedule_dlv_date ) schedule_dlv_date        -- ��ͯ�ޱ�޵�.����          �F�[�i�\���
        ,ooa1.schedule_inspect_date      schedule_inspect_date    -- �󒍖���.�����\���         �F�����\���
        ,ooa2.arrival_date               arrival_date             -- ��ͯ�ޱ�޵�.���ד�        �F����
        ,ooa3.order_quantity             order_quantity           -- �󒍖���.�󒍐���           �F�󒍐�
        ,ooa2.deliver_actual_quantity    deliver_actual_quantity  -- �󒍖��ױ�޵�.�o�׎��ѐ���  �F�o�׎��ѐ�
-- ******************** 2009/07/27 1.8 N.Maeda MOD start ******************************* --
--        ,ooa1.uom_code                   uom_code                 -- �󒍖��ױ�޵�.�P��          �F�P��
        ,ooa2.uom_code                   uom_code                 -- �󒍖��ױ�޵�.�P��          �F�P��
-- ******************** 2009/07/27 1.8 N.Maeda MOD  end  ******************************* --
        ,ooa3.order_quantity
          - ooa2.deliver_actual_quantity output_quantity          -- ���ِ�
        ,cv_data_class_2                 data_class               -- ��O�f�[�^�Q                �F�f�[�^�敪
      FROM
        -- ****** ��O�Q�c�ƃT�u�N�G���Fooa1 ******
        ( SELECT
             xca.delivery_base_code     base_code                -- �ڋq�ǉ����Ͻ�.�[�i���_���ށF���_����
            ,hca2.account_name          base_name                -- �ڋqϽ�2.�ڋq����           �F���_����
            ,ooha.order_number          order_number             -- ��ͯ��.�󒍔ԍ�           �F�󒍔ԍ�
            ,oola.line_number           order_line_no            -- �󒍖���.���הԍ�           �F�󒍖���No
            ,oola.packing_instructions  deliver_requested_no     -- �󒍖���.����w��           �F�o�׈˗�No
            ,oola.subinventory          deliver_from_whse_number -- �󒍖���.�ۊǏꏊ           �F�o�׌��q�ɔԍ�
            ,mtsi.description           deliver_from_whse_name   -- �ۊǏꏊ.�ۊǏꏊ����       �F�o�׌��q�ɖ�
            ,hca.account_number         customer_number          -- �ڋqϽ�.�ڋq����            �F�ڋq�ԍ�
            ,hca.account_name           customer_name            -- �ڋqϽ�.�ڋq����            �F�ڋq��
            ,NVL( oola.attribute6, oola.ordered_item )
                                        item_code                -- �󒍖���.�󒍕i��           �F�i�ں���
            ,ximb.item_short_name       item_name                -- OPM�i�ڱ�޵�                �F�i��
            ,oola.request_date          schedule_dlv_date        -- �󒍖���.�v����             �F�[�i�\���
            ,oola.attribute4            schedule_inspect_date    -- �󒍖���.�����\���         �F�����\���
            ,oola.ordered_quantity      order_quantity           -- �󒍖���.�󒍐���           �F�󒍐�
            ,oola.order_quantity_uom    uom_code                 -- �󒍖���.�󒍒P��           �F�P��
          FROM
             oe_order_headers_all       ooha  -- ��ͯ��ð���
            ,oe_order_lines_all         oola  -- �󒍖���ð���
            ,hz_cust_accounts           hca   -- �ڋqϽ�
            ,xxcmm_cust_accounts        xca   -- �ڋq�ǉ����Ͻ�
            ,mtl_secondary_inventories  mtsi  -- �ۊǏꏊϽ�
            ,hz_cust_accounts           hca2  -- �ڋqϽ�2
            ,ic_item_mst_b              iimb  -- OPM�i��
            ,xxcmn_item_mst_b           ximb  -- OPM�i�ڱ�޵�
            ,( SELECT
--MIYATA DELETE ����ID��ͯ�ށ^���׋��ɓ���ł���̂ŕs�v
--                  MAX( ooha.header_id )      header_id   -- ��ͯ��.��ͯ��ID
--                 ,MAX( line_id )             line_id     -- �󒍖���.�󒍖���ID
                 MAX( line_id )             line_id     -- �󒍖���.�󒍖���ID
--MIYATA DELTE
               FROM
                  oe_order_headers_all       ooha        -- ��ͯ��ð���
                 ,oe_order_lines_all         oola        -- �󒍖���ð���
                 ,hz_cust_accounts           hca         -- �ڋqϽ�
                 ,xxcmm_cust_accounts        xca         -- �ڋq�ǉ����Ͻ�
                 ,mtl_secondary_inventories  mtsi        -- �ۊǏꏊϽ�
               WHERE
                    ooha.header_id    =  oola.header_id                      -- ��ͯ��.��ͯ��ID = �󒍖���.��ͯ��ID
               AND  ooha.org_id       =  gn_org_id                           -- ��ͯ��.�g�DID = A-1�擾�̉c�ƒP��
               AND  oola.subinventory =  mtsi.secondary_inventory_name       -- �󒍖���.�ۊǏꏊ = �ۊǏꏊϽ�.�ۊǏꏊ����
               AND  oola.ship_from_org_id  =  mtsi.organization_id           -- �󒍖���.�o�׌��g�DID = �ۊǏꏊϽ�.�g�DID
               AND  mtsi.attribute13       =  gv_subinventory_class          -- �ۊǏꏊϽ�.�ۊǏꏊ���� = '11':����
               AND  ooha.flow_status_code  =  cv_status_booked               -- ��ͯ��.�ð�� = 'BOOKED'
                                                                             -- �󒍖���.�ð�� NOT IN( 'CLOSED','CANCELLED')
               AND  oola.flow_status_code  NOT IN ( cv_status_closed, cv_status_cancelled )
               AND  oola.packing_instructions  IS NOT NULL                   -- �󒍖���.����w�� IS NOT NULL
               AND  NOT EXISTS ( SELECT                                      -- NVL(�󒍖���.�q�R�[�h,�󒍖���.�󒍕i��)����݌ɕi�ڃR�[�h
                                   'X'                 exists_flag -- EXISTS�׸�
                                 FROM
                                    fnd_application    fa
                                   ,fnd_lookup_types   flt
                                   ,fnd_lookup_values  flv
                                 WHERE
                                      fa.application_id           = flt.application_id
                                 AND  flt.lookup_type             = flv.lookup_type
                                 AND  fa.application_short_name   = cv_xxcos_short_name
                                 AND  flv.lookup_type             = cv_no_inv_item_code
                                 AND  flv.start_date_active      <= gd_process_date
                                 AND  gd_process_date            <= NVL( flv.end_date_active, gd_max_date )
                                 AND  flv.enabled_flag            = cv_yes_flg
                                 AND  flv.language                = USERENV( 'LANG' )
                                 AND  NVL(oola.attribute6,oola.ordered_item) = flv.lookup_code
                               )
               AND  ooha.sold_to_org_id        =  hca.cust_account_id        -- ��ͯ��.�ڋqID = �ڋqϽ�.�ڋqID
               AND  hca.cust_account_id        =  xca.customer_id            -- �ڋqϽ�.�ڋqID  = �ڋq�ǉ����Ͻ�.�ڋqID
                                                                             -- �ڋq�ǉ����Ͻ�.�[�i���_ = DECODE('ALL','ALL',���Ұ�.���_����)
               AND  xca.delivery_base_code     =  DECODE( iv_base_code
                                                         ,cv_base_all
                                                         ,xca.delivery_base_code
                                                         ,iv_base_code )
               GROUP BY
                  oola.packing_instructions
                 ,NVL( oola.attribute6, oola.ordered_item )
             )
             ooal   -- �ŏI��p�T�u�N�G��
          WHERE
               ooha.header_id    =  oola.header_id                    -- ��ͯ��.��ͯ��ID = �󒍖���.��ͯ��ID
          AND  ooha.org_id       =  gn_org_id                         -- ��ͯ��.�g�DID = A-1�擾�̉c�ƒP��
          AND  oola.subinventory =  mtsi.secondary_inventory_name     -- �󒍖���.�ۊǏꏊ = �ۊǏꏊϽ�.�ۊǏꏊ����
          AND  oola.ship_from_org_id  =  mtsi.organization_id         -- �󒍖���.�o�׌��g�DID = �ۊǏꏊϽ�.�g�DID
          AND  mtsi.attribute13       =  gv_subinventory_class        -- �ۊǏꏊϽ�.�ۊǏꏊ���� = '11':����
          AND  ooha.flow_status_code  =  cv_status_booked             -- ��ͯ��.�ð�� = 'BOOKED'
                                                                      -- �󒍖���.�ð�� NOT IN( 'CLOSED','CANCELLED')
          AND  oola.flow_status_code  NOT IN ( cv_status_closed, cv_status_cancelled )
          AND  oola.packing_instructions  IS NOT NULL                 -- �󒍖���.����w�� IS NOT NULL
          AND  ooha.sold_to_org_id     =  hca.cust_account_id         -- ��ͯ��.�ڋqID = �ڋqϽ�.�ڋqID
          AND  hca.cust_account_id     =  xca.customer_id             -- �ڋqϽ�.�ڋqID   = �ڋq�ǉ����Ͻ�.�ڋqID
                                                                      -- �ڋq�ǉ����Ͻ�.�[�i���_ = DECODE('ALL','ALL',���Ұ�.���_����)
          AND  xca.delivery_base_code  =  DECODE( iv_base_code
                                                 ,cv_base_all
                                                 ,xca.delivery_base_code
                                                 ,iv_base_code )
          AND  hca2.customer_class_code  =  cv_party_type_1              -- �ڋqϽ�2.�ڋq�敪 = '1':���_
          AND  hca2.account_number       =  xca.delivery_base_code       -- �ڋqϽ�2.�ڋq���� = �ڋq�ǉ����Ͻ�.�[�i���_����
          AND  NVL( oola.attribute6, oola.ordered_item ) = iimb.item_no  -- NVL(�󒍖���.�q�R�[�h,�󒍖���.�󒍕i�� = OPM�i��.�i�ں���
          AND  iimb.item_id              =  ximb.item_id                 -- OPM�i��.�i��ID = OPM�i�ڱ�޵�.�i��id
          AND  TRUNC( ximb.start_date_active )                    <=  gd_process_date    -- OPM�i�ڱ�޵�.�K�p�J�n�� <= �Ɩ����t
          AND  TRUNC( NVL( ximb.end_date_active, gd_max_date ) )  >=  gd_process_date    -- OPM�i�ڱ�޵�.�K�p�I���� >= �Ɩ����t
--MIYATA DELETE ����ID��ͯ�ށ^���׋��ɓ���ł���̂ŕs�v
--          AND  ooha.header_id             = ooal.header_id               -- ��ͯ��.��ͯ��ID = �ŏI��p��޸��.��ͯ��ID
--MIYATA DELETE
          AND  oola.line_id               = ooal.line_id                 -- �󒍖���.�󒍖���ID = �ŏI��p��޸��.�󒍖���ID
        )
        ooa1,
        -- ****** ��O�Q���Y�T�u�N�G���Fooa2 ******
        ( SELECT
             xola.order_line_number     line_no                  -- �󒍖��ױ�޵�.���הԍ�      �F����No
            ,xoha.request_no            deliver_requested_no     -- ��ͯ�ޱ�޵�.�˗�No        �F�o�׈˗�No
-- ******************** 2009/07/08 1.7 N.Maeda MOD start ******************************* --
            ,xola.request_item_code       item_code                -- �󒍖��ױ�޵�.�˗��i��      �F�i�ں���
--            ,xola.shipping_item_code    item_code                -- �󒍖��ױ�޵�.�o�וi��      �F�i�ں���
-- ******************** 2009/07/08 1.7 N.Maeda MOD  end  ******************************* --
            ,xoha.arrival_date          arrival_date             -- ��ͯ�ޱ�޵�.���ד�        �F����
--MIYATA MODIFY �o�׎��эς݂ł͂Ȃ��̂Ő��ʂɕύX
--            ,xola.shipped_quantity      deliver_actual_quantity  -- �󒍖��ױ�޵�.�o�׎��ѐ���  �F�o�׎��ѐ�
            ,xola.quantity              deliver_actual_quantity  -- �󒍖��ױ�޵�.����          �F�o�׎��ѐ�
-- ******************** 2009/07/27 1.8 N.Maeda MOD start ******************************* --
            ,xola.uom_code              uom_code                 -- �󒍖��ױ�޵�.�P��          �F�P��
-- ******************** 2009/07/27 1.8 N.Maeda MOD  end  ******************************* --
--MIYATA MODIFY
          FROM
             xxwsh_order_headers_all    xoha  -- ��ͯ�ޱ�޵�
            ,xxwsh_order_lines_all      xola  -- �󒍖��ױ�޵�
            ,hz_cust_accounts           hca   -- �ڋqϽ�
            ,xxcmm_cust_accounts        xca   -- �ڋq�ǉ����Ͻ�
          WHERE
               xoha.order_header_id      =   xola.order_header_id      -- ��ͯ�ޱ�޵�.��ͯ�ޱ�޵�ID = �󒍖��ױ�޵�.��ͯ�ޱ�޵�ID
                                                                       -- ��ͯ�ޱ�޵�.�ð�� NOT IN( �o�׎��ьv��� , ��� )
          AND  xoha.req_status      NOT IN ( cv_h_add_status_04, cv_h_add_status_99 )
          AND  xoha.latest_external_flag =   cv_yes_flg                -- ��ͯ�ޱ�޵�.�ŐV�׸� = 'Y'
          AND  NVL( xola.delete_flag, cv_no_flg ) = cv_no_flg          -- �󒍖��ױ�޵�.�폜�׸� = 'N'
--MIYATA MODIFY
--          AND  xoha.customer_id          =   hca.cust_account_id       -- ��ͯ�ޱ�޵�.�ڋqID = �ڋqϽ�.�ڋqID
          AND  xoha.customer_code        =   hca.account_number        -- ��ͯ�ޱ�޵�.�ڋq = �ڋqϽ�.�ڋq�R�[�h
--MIYATA MODIFY
          AND  hca.cust_account_id       =   xca.customer_id           -- �ڋqϽ�.�ڋqID       = �ڋq�ǉ����Ͻ�.�ڋqID
          AND  xca.delivery_base_code    =   DECODE( iv_base_code      -- �ڋq�ǉ����Ͻ�.�[�i���_ = DECODE('ALL','ALL',���Ұ�.���_����)
                                                    ,cv_base_all
                                                    ,xca.delivery_base_code
                                                    ,iv_base_code )
        )
        ooa2,
        -- ****** ��O�Q���ʃT�u�N�G���Fooa3 ******
        ( SELECT
             oola.packing_instructions                    deliver_requested_no     -- �󒍖���.����w���i�o�׈˗�No�j
            ,NVL( oola.attribute6, oola.ordered_item )    item_code                -- NVL(�󒍖���.�q�R�[�h,�󒍖���.�󒍕i��)
            ,SUM( oola.ordered_quantity * DECODE ( otta.order_category_code, cv_order, 1, -1 )
                   * CASE oola.order_quantity_uom
                     WHEN msib.primary_unit_of_measure THEN 1
                     WHEN item_cnv.uom_code THEN TO_NUMBER( item_cnv.cnv_value )
                     ELSE NVL( xicv.conversion_rate, 0 )
                   END
             ) AS order_quantity
          FROM
             oe_order_headers_all       ooha        -- ��ͯ��ð���
            ,oe_order_lines_all         oola        -- �󒍖���ð���
            ,hz_cust_accounts           hca         -- �ڋqϽ�
            ,xxcmm_cust_accounts        xca         -- �ڋq�ǉ����Ͻ�
            ,mtl_secondary_inventories  mtsi        -- �ۊǏꏊϽ�
            ,mtl_system_items_b         msib        -- Disc�i�ځi�c�Ƒg�D�j
            ,oe_transaction_types_tl    ottt        -- �󒍎���^�C�v�i�E�v�j
            ,oe_transaction_types_all   otta        -- �󒍎���^�C�v�}�X�^
            ,xxcos_item_conversions_v   xicv        -- �i�ڊ��ZView
            ,(
              SELECT
                  flv.meaning      AS UOM_CODE
                , flv.description  AS CNV_VALUE
              FROM
                fnd_application   fa,
                fnd_lookup_types  flt,
                fnd_lookup_values flv
              WHERE
                    fa.application_id         = flt.application_id
                AND flt.lookup_type           = flv.lookup_type
                AND fa.application_short_name = cv_xxcos_short_name
                AND flv.enabled_flag          = cv_yes_flg
                AND flv.language              = USERENV( 'LANG' )
                AND flv.start_date_active    <= gd_process_date
                AND gd_process_date          <= NVL( flv.end_date_active, gd_max_date )
                AND flv.lookup_type           = cv_weight_uom_cnv_mst
            ) item_cnv
          WHERE
               ooha.header_id    =  oola.header_id                      -- ��ͯ��.��ͯ��ID = �󒍖���.��ͯ��ID
          AND  ooha.org_id       =  gn_org_id                           -- ��ͯ��.�g�DID = A-1�擾�̉c�ƒP��
          AND  oola.line_type_id        = ottt.transaction_type_id      -- �󒍖���.��������ID = �󒍎������(�E�v).����ID
          AND  ottt.transaction_type_id = otta.transaction_type_id      -- �󒍎������(�E�v).����ID = �󒍎������.����ID
          AND  ottt.language            = USERENV( 'LANG' )             -- �󒍎������(�E�v).����ID = 'JA'
          AND  oola.subinventory =  mtsi.secondary_inventory_name       -- �󒍖���.�ۊǏꏊ = �ۊǏꏊϽ�.�ۊǏꏊ����
          AND  oola.ship_from_org_id  =  mtsi.organization_id           -- �󒍖���.�o�׌��g�DID = �ۊǏꏊϽ�.�g�DID
          AND  mtsi.attribute13       =  gv_subinventory_class          -- �ۊǏꏊϽ�.�ۊǏꏊ���� = '11':����
                                                                        -- ��ͯ��.�ð�� IN ( 'BOOKED','CLOSED' )
          AND  ooha.flow_status_code      IN ( cv_status_booked, cv_status_closed )
          AND  oola.flow_status_code      <> cv_status_cancelled        -- �󒍖���.�ð�� <> 'CANCELLED'
          AND  oola.packing_instructions  IS NOT NULL                   -- �󒍖���.����w�� IS NOT NULL
          AND  NOT EXISTS ( SELECT                                      -- NVL(�󒍖���.�q�R�[�h,�󒍖���.�󒍕i��)����݌ɕi�ڃR�[�h
                              'X'                 exists_flag -- EXISTS�׸�
                            FROM
                               fnd_application    fa
                              ,fnd_lookup_types   flt
                              ,fnd_lookup_values  flv
                            WHERE
                                 fa.application_id           = flt.application_id
                            AND  flt.lookup_type             = flv.lookup_type
                            AND  fa.application_short_name   = cv_xxcos_short_name
                            AND  flv.lookup_type             = cv_no_inv_item_code
                            AND  flv.start_date_active      <= gd_process_date
                            AND  gd_process_date            <= NVL( flv.end_date_active, gd_max_date )
                            AND  flv.enabled_flag            = cv_yes_flg
                            AND  flv.language                = USERENV( 'LANG' )
                            AND  NVL(oola.attribute6,oola.ordered_item) = flv.lookup_code
                          )
          AND  ooha.sold_to_org_id        =  hca.cust_account_id        -- ��ͯ��.�ڋqID = �ڋqϽ�.�ڋqID
          AND  hca.cust_account_id        =  xca.customer_id            -- �ڋqϽ�.�ڋqID  = �ڋq�ǉ����Ͻ�.�ڋqID
                                                                        -- �ڋq�ǉ����Ͻ�.�[�i���_ = DECODE('ALL','ALL',���Ұ�.���_����)
          AND  xca.delivery_base_code     =  DECODE( iv_base_code
                                                    ,cv_base_all
                                                    ,xca.delivery_base_code
                                                    ,iv_base_code )
                                                                        -- NVL(�󒍖���.�q�R�[�h,�󒍖���.�󒍕i��)
                                                                        --     = Disc�i��.�i�ڃR�[�h
          AND  NVL( oola.attribute6, oola.ordered_item ) = msib.segment1
          AND  oola.ship_from_org_id      = msib.organization_id        -- �󒍖���.�o�׌��g�D = Disc�i��.�g�DID
                                                                             -- NVL(�󒍖���.�q�R�[�h,�󒍖���.�󒍕i��)
          AND  NVL( oola.attribute6, oola.ordered_item ) = xicv.item_code(+)  --     = �i�ڊ��ZView.�i�ڃR�[�h
          AND  oola.order_quantity_uom    = xicv.to_uom_code(+)         -- �󒍖���.�󒍒P�� = �i�ڊ��ZView.�ϊ���P��
          AND  oola.order_quantity_uom    = item_cnv.uom_code(+)
          GROUP BY
             oola.packing_instructions
            ,NVL( oola.attribute6, oola.ordered_item )
        )
        ooa3
      WHERE
           ooa1.deliver_requested_no       =  ooa2.deliver_requested_no -- ��O�Q�c�ƃT�u�N�G��.�o�׈˗�No = ��O�Q���Y�T�u�N�G��.�o�׈˗�No
      AND  ooa1.item_code                  =  ooa2.item_code            -- ��O�Q�c�ƃT�u�N�G��.�i�ڃR�[�h = ��O�Q���Y�T�u�N�G��.�i�ڃR�[�h
      AND  ooa1.deliver_requested_no       =  ooa3.deliver_requested_no -- ��O�Q�c�ƃT�u�N�G��.�o�׈˗�No = ��O�Q���ʃT�u�N�G��.�o�׈˗�No
      AND  ooa1.item_code                  =  ooa3.item_code            -- ��O�Q�c�ƃT�u�N�G��.�i�ڃR�[�h = ��O�Q���ʃT�u�N�G��.�i�ڃR�[�h
      AND  TRUNC( ooa1.schedule_dlv_date ) <  gd_process_date           -- ��O�Q�c�ƃT�u�N�G��.�[�i�\���(�v����) < A.1�擾�̋Ɩ����t
--
      UNION
--
  --** ����O�R�|�P�擾SQL
      SELECT
         xca.delivery_base_code     base_code                -- �ڋq�ǉ����Ͻ�.�[�i���_���ށF���_����
        ,hca2.account_name          base_name                -- �ڋqϽ�2.�ڋq����           �F���_����
        ,ooha.order_number          order_number             -- ��ͯ��.�󒍔ԍ�           �F�󒍔ԍ�
        ,oola.line_number           order_line_no            -- �󒍖���.���הԍ�           �F�󒍖���No
        ,NULL                       line_no                  -- �󒍖��ױ�޵�.���הԍ�      �F����No
        ,oola.packing_instructions  deliver_requested_no     -- �󒍖���.����w��           �F�o�׈˗�No
        ,oola.subinventory          deliver_from_whse_number -- �󒍖���.�ۊǏꏊ           �F�o�׌��q�ɔԍ�
        ,mtsi.description           deliver_from_whse_name   -- �ۊǏꏊ.�ۊǏꏊ����       �F�o�׌��q�ɖ�
        ,hca.account_number         customer_number          -- �ڋqϽ�.�ڋq����            �F�ڋq�ԍ�
        ,hca.account_name           customer_name            -- �ڋqϽ�.�ڋq����            �F�ڋq��
        ,NVL( oola.attribute6, oola.ordered_item )
                                    item_code                -- �󒍖���.�󒍕i��           �F�i�ں���
        ,ximb.item_short_name       item_name                -- OPM�i�ڱ�޵�                �F�i��
        ,TRUNC( oola.request_date ) schedule_dlv_date        -- �󒍖���.�v����             �F�[�i�\���
        ,oola.attribute4            schedule_inspect_date    -- �󒍖���.�����\���         �F�����\���
        ,NULL                       arrival_date             -- ��ͯ�ޱ�޵�.���ד�        �F����
--****************************** 2009/05/26 1.4 T.Kitajima MOD START ******************************--
--        ,oola.ordered_quantity      order_quantity           -- �󒍖���.�󒍐���           �F�󒍐�
        ,oola.ordered_quantity * 
          DECODE ( otta.order_category_code, cv_order, 1, -1 )
                                    order_quantity           -- �󒍖���.�󒍐���           �F�󒍐�
--****************************** 2009/05/26 1.4 T.Kitajima MOD  END  ******************************--
        ,0                          deliver_actual_quantity  -- �󒍖��ױ�޵�.�o�׎��ѐ���  �F�o�׎��ѐ�
        ,oola.order_quantity_uom    uom_code                 -- �󒍖���.�󒍒P��           �F�P��
        ,oola.ordered_quantity      output_quantity          -- ���ِ�
        ,cv_data_class_3            data_class               -- ��O�f�[�^�R�|�P            �F�f�[�^�敪
      FROM
         oe_order_headers_all       ooha  -- ��ͯ��ð���
        ,oe_order_lines_all         oola  -- �󒍖���ð���
        ,hz_cust_accounts           hca   -- �ڋqϽ�
        ,xxcmm_cust_accounts        xca   -- �ڋq�ǉ����Ͻ�
        ,mtl_secondary_inventories  mtsi  -- �ۊǏꏊϽ�
        ,hz_cust_accounts           hca2  -- �ڋqϽ�2
        ,ic_item_mst_b              iimb  -- OPM�i��
        ,xxcmn_item_mst_b           ximb  -- OPM�i�ڱ�޵�
--****************************** 2009/05/26 1.4 T.Kitajima ADD START ******************************--
        ,oe_transaction_types_tl    ottt  -- �󒍎���^�C�v�i�E�v�j
        ,oe_transaction_types_all   otta  -- �󒍎���^�C�v�}�X�^
--****************************** 2009/05/26 1.4 T.Kitajima ADD  END  ******************************--
      WHERE
           ooha.header_id    =  oola.header_id                    -- ��ͯ��.��ͯ��ID = �󒍖���.��ͯ��ID
      AND  ooha.org_id       =  gn_org_id                         -- ��ͯ��.�g�DID = A-1�擾�̉c�ƒP��
--****************************** 2009/05/26 1.4 T.Kitajima ADD START ******************************--
      AND  oola.line_type_id        = ottt.transaction_type_id    -- �󒍖���.��������ID = �󒍎������(�E�v).����ID
      AND  ottt.transaction_type_id = otta.transaction_type_id    -- �󒍎������(�E�v).����ID = �󒍎������.����ID
      AND  ottt.language            = USERENV( 'LANG' )           -- �󒍎������(�E�v).����ID = 'JA'
--****************************** 2009/05/26 1.4 T.Kitajima ADD  END  ******************************--
      AND  oola.subinventory =  mtsi.secondary_inventory_name     -- �󒍖���.�ۊǏꏊ = �ۊǏꏊϽ�.�ۊǏꏊ����
      AND  oola.ship_from_org_id  =  mtsi.organization_id         -- �󒍖���.�o�׌��g�DID = �ۊǏꏊϽ�.�g�DID
      AND  mtsi.attribute13       =  gv_subinventory_class        -- �ۊǏꏊϽ�.�ۊǏꏊ���� = '11':����
      AND  ooha.flow_status_code  =  cv_status_booked             -- ��ͯ��.�ð�� = 'BOOKED'
                                                                  -- �󒍖���.�ð�� NOT IN( 'CLOSED','CANCELLED')
      AND  oola.flow_status_code  NOT IN ( cv_status_closed, cv_status_cancelled )
      AND  oola.packing_instructions  IS NOT NULL                 -- �󒍖���.����w�� IS NOT NULL
      AND  NOT EXISTS ( SELECT                                    -- NVL(�󒍖���.�q�R�[�h,�󒍖���.�󒍕i��)����݌ɕi�ڃR�[�h
                          'X'                 exists_flag -- EXISTS�׸�
                        FROM
                           fnd_application    fa
                          ,fnd_lookup_types   flt
                          ,fnd_lookup_values  flv
                        WHERE
                             fa.application_id           = flt.application_id
                        AND  flt.lookup_type             = flv.lookup_type
                        AND  fa.application_short_name   = cv_xxcos_short_name
                        AND  flv.lookup_type             = cv_no_inv_item_code
                        AND  flv.start_date_active      <= gd_process_date
                        AND  gd_process_date            <= NVL( flv.end_date_active, gd_max_date )
                        AND  flv.enabled_flag            = cv_yes_flg
                        AND  flv.language                = USERENV( 'LANG' )
                        AND  NVL(oola.attribute6,oola.ordered_item) = flv.lookup_code
                     )
      AND  ooha.sold_to_org_id     =  hca.cust_account_id         -- ��ͯ��.�ڋqID = �ڋqϽ�.�ڋqID
      AND  hca.cust_account_id     =  xca.customer_id             -- �ڋqϽ�.�ڋqID  = �ڋq�ǉ����Ͻ�.�ڋqID
                                                                  -- �ڋq�ǉ����Ͻ�.�[�i���_ = DECODE('ALL','ALL',���Ұ�.���_����)
      AND  xca.delivery_base_code  =  DECODE( iv_base_code
                                             ,cv_base_all
                                             ,xca.delivery_base_code
                                             ,iv_base_code )
      AND  hca2.customer_class_code  =  cv_party_type_1              -- �ڋqϽ�2.�ڋq�敪 = '1':���_
      AND  hca2.account_number       =  xca.delivery_base_code       -- �ڋqϽ�2.�ڋq���� = �ڋq�ǉ����Ͻ�.�[�i���_����
      AND  NVL( oola.attribute6, oola.ordered_item ) = iimb.item_no  -- NVL(�󒍖���.�q�R�[�h,�󒍖���.�󒍕i�� = OPM�i��.�i�ں���
      AND  iimb.item_id              =  ximb.item_id                 -- OPM�i��.�i��ID = OPM�i�ڱ�޵�.�i��id
      AND  TRUNC( ximb.start_date_active )                   <= gd_process_date    -- OPM�i�ڱ�޵�.�K�p�J�n�� <= �Ɩ����t
      AND  TRUNC( NVL( ximb.end_date_active, gd_max_date ) ) >= gd_process_date    -- OPM�i�ڱ�޵�.�K�p�I���� >= �Ɩ����t
      AND NOT EXISTS(
              SELECT
                'X'                          exists_flag -- EXISTS�׸�
              FROM
                 xxwsh_order_headers_all     xoha        -- ��ͯ�ޱ�޵�
                ,xxwsh_order_lines_all       xola        -- �󒍖��ױ�޵�
                ,hz_cust_accounts            hca         -- �ڋqϽ�
                ,xxcmm_cust_accounts         xca         -- �ڋq�ǉ����Ͻ�
              WHERE
                   xoha.order_header_id      =   xola.order_header_id      -- ��ͯ�ޱ�޵�.��ͯ�ޱ�޵�ID = �󒍖��ױ�޵�.��ͯ�ޱ�޵�ID
              AND  xoha.req_status           <>  cv_h_add_status_99        -- ��ͯ�ޱ�޵�.�ð�� <> ���
              AND  xoha.latest_external_flag =   cv_yes_flg                -- ��ͯ�ޱ�޵�.�ŐV�׸� = 'Y'
              AND  NVL( xola.delete_flag, cv_no_flg ) = cv_no_flg          -- �󒍖��ױ�޵�.�폜�׸� = 'N'
--MIYATA MODIFY
--              AND  xoha.customer_id          =   hca.cust_account_id       -- ��ͯ�ޱ�޵�.�ڋqID = �ڋqϽ�.�ڋqID
              AND  xoha.customer_code        =   hca.account_number        -- ��ͯ�ޱ�޵�.�ڋq = �ڋqϽ�.�ڋq�R�[�h
--MIYATA MODIFY
              AND  hca.cust_account_id       =   xca.customer_id           -- �ڋqϽ�.�ڋqID       = �ڋq�ǉ����Ͻ�.�ڋqID
              AND  xca.delivery_base_code    =   DECODE( iv_base_code      -- �ڋq�ǉ����Ͻ�.�[�i���_ = DECODE('ALL','ALL',���Ұ�.���_����)
                                                        ,cv_base_all
                                                        ,xca.delivery_base_code
                                                        ,iv_base_code )
              AND  oola.packing_instructions =   xoha.request_no   -- �󒍖���.����w�� = ��ͯ�ޱ�޵�.�˗�No
                                                                   -- NVL(�󒍖���.�q�R�[�h,�󒍖���.�󒍕i�� = ��ͯ�ޱ�޵�.�˗��i��
-- ******************** 2009/07/08 1.7 N.Maeda MOD start ******************************* --
              AND  NVL( oola.attribute6, oola.ordered_item ) = xola.request_item_code
--              AND  NVL( oola.attribute6, oola.ordered_item ) = xola.shipping_item_code
-- ******************** 2009/07/08 1.7 N.Maeda MOD  end  ******************************* --
              )
--
      UNION
--
  --** ����O�R�|�Q�擾SQL
      SELECT
         xca.delivery_base_code     base_code                -- �ڋq�ǉ����Ͻ�.�[�i���_���ށF���_����
        ,hca2.account_name          base_name                -- �ڋqϽ�2.�ڋq����           �F���_����
        ,NULL                       order_number             -- ��ͯ��.�󒍔ԍ�           �F�󒍔ԍ�
        ,NULL                       order_line_no            -- �󒍖���.���הԍ�           �F�󒍖���No
        ,xola.order_line_number     line_no                  -- �󒍖��ױ�޵�.���הԍ�      �F����No
        ,xoha.request_no            deliver_requested_no     -- ��ͯ�ޱ�޵�.�˗�No        �F�o�׈˗�No
        ,xoha.deliver_from          deliver_from_whse_number -- ��ͯ�ޱ�޵�.�o�׌��ۊǏꏊ�F�o�׌��q�ɔԍ�
        ,xilv.description           deliver_from_whse_name   -- �ۊǏꏊ.�ۊǏꏊ����       �F�o�׌��q�ɖ�
        ,xoha.customer_code         customer_number          -- ��ͯ�ޱ�޵�.�ڋq          �F�ڋq�ԍ�
        ,hca.account_name           customer_name            -- �ڋqϽ�.�ڋq����            �F�ڋq��
-- ******************** 2009/07/08 1.7 N.Maeda MOD start ******************************* --
        ,xola.request_item_code     item_code                -- �󒍖��ױ�޵�.�˗��i��      �F�i�ں���
--        ,xola.shipping_item_code    item_code                -- �󒍖��ױ�޵�.�o�וi��      �F�i�ں���
-- ******************** 2009/07/08 1.7 N.Maeda MOD  end  ******************************* --
        ,ximb.item_short_name       item_name                -- OPM�i�ڱ�޵�                �F�i��
        ,NULL                       schedule_dlv_date        -- ��ͯ�ޱ�޵�.����          �F�[�i�\���
        ,NULL                       schedule_inspect_date    -- �󒍖���.�����\���         �F�����\���
        ,xoha.arrival_date          arrival_date             -- ��ͯ�ޱ�޵�.���ד�        �F����
        ,0                          order_quantity           -- �󒍖���.�󒍐���           �F�󒍐�
        ,NVL( xola.shipped_quantity, 0 )
                                    deliver_actual_quantity  -- �󒍖��ױ�޵�.�o�׎��ѐ���  �F�o�׎��ѐ�
        ,xola.uom_code              uom_code                 -- �󒍖��ױ�޵�.�P��          �F�P��
        ,0 - NVL( xola.shipped_quantity, 0 )
                                    output_quantity          -- ���ِ�
        ,cv_data_class_4            data_class               -- ��O�f�[�^�R�|�Q            �F�f�[�^�敪
      FROM
         xxwsh_order_headers_all    xoha  -- ��ͯ�ޱ�޵�
        ,xxwsh_order_lines_all      xola  -- �󒍖��ױ�޵�
        ,xxcmn_item_locations2_v    xilv  -- OPM�ۊǏꏊϽ�
        ,hz_cust_accounts           hca   -- �ڋqϽ�
        ,xxcmm_cust_accounts        xca   -- �ڋq�ǉ����Ͻ�
        ,hz_cust_accounts           hca2  -- �ڋqϽ�2
        ,ic_item_mst_b              iimb  -- OPM�i��
        ,xxcmn_item_mst_b           ximb  -- OPM�i�ڱ�޵�
      WHERE
           xoha.order_header_id      =   xola.order_header_id      -- ��ͯ�ޱ�޵�.��ͯ�ޱ�޵�ID = �󒍖��ױ�޵�.��ͯ�ޱ�޵�ID
      AND  xoha.req_status           =   cv_h_add_status_04        -- ��ͯ�ޱ�޵�.�ð�� = �o�׎��ьv���
      AND  xoha.latest_external_flag =   cv_yes_flg                -- ��ͯ�ޱ�޵�.�ŐV�׸� = 'Y'
      AND  NVL( xola.delete_flag, cv_no_flg ) = cv_no_flg          -- �󒍖��ױ�޵�.�폜�׸� = 'N'
--****************************** 2009/04/10 1.3 T.Kitajima ADD START ******************************--
      AND NVL( xola.shipped_quantity, cn_ship_zero ) != cn_ship_zero -- �󒍖��ױ�޵�.�o�׎��ѐ��ʂ�0�ȊO
--****************************** 2009/04/10 1.3 T.Kitajima ADD  END  ******************************--
      AND  xoha.deliver_from         =   xilv.segment1             -- ��ͯ�ޱ�޵�.�o�׌��ۊǏꏊ = OPM�ۊǏꏊϽ�.�ۊǑq�ɃR�[�h
      AND  xilv.date_from                            <= gd_process_date  -- OPM�ۊǏꏊϽ�.�g�D�L���J�n�� <= �Ɩ����t
      AND  TRUNC( NVL( xilv.date_to, gd_max_date ) ) >= gd_process_date  -- OPM�ۊǏꏊϽ�.�g�D�L���J�n�� >= �Ɩ����t
--MIYATA MODIFY
--      AND  xoha.customer_id          =   hca.cust_account_id       -- ��ͯ�ޱ�޵�.�ڋqID = �ڋqϽ�.�ڋqID
      AND  xoha.customer_code        =   hca.account_number        -- ��ͯ�ޱ�޵�.�ڋq = �ڋqϽ�.�ڋq�R�[�h
--MIYATA MODIFY
      AND  hca.cust_account_id       =   xca.customer_id           -- �ڋqϽ�.�ڋqID       = �ڋq�ǉ����Ͻ�.�ڋqID
      AND  xca.delivery_base_code    =   DECODE( iv_base_code      -- �ڋq�ǉ����Ͻ�.�[�i���_ = DECODE('ALL','ALL',���Ұ�.���_����)
                                                ,cv_base_all
                                                ,xca.delivery_base_code
                                                ,iv_base_code )
      AND  hca2.customer_class_code  =  cv_party_type_1            -- �ڋqϽ�2.�ڋq�敪 = '1':���_
      AND  hca2.account_number       =  xca.delivery_base_code     -- �ڋqϽ�2.�ڋq���� = �ڋq�ǉ����Ͻ�.�[�i���_����
-- ******************** 2009/07/08 1.7 N.Maeda MOD start ******************************* --
      AND  xola.request_item_code   =  iimb.item_no               -- �󒍖��ױ�޵�.�˗��i�� = OPM�i��.�i�ں���
--      AND  xola.shipping_item_code   =  iimb.item_no               -- �󒍖��ױ�޵�.�o�וi�� = OPM�i��.�i�ں���
-- ******************** 2009/07/08 1.7 N.Maeda MOD  end  ******************************* --
      AND  iimb.item_id              =  ximb.item_id               -- OPM�i��.�i��ID = OPM�i�ڱ�޵�.�i��id
      AND  TRUNC( ximb.start_date_active )                   <= gd_process_date    -- OPM�i�ڱ�޵�.�K�p�J�n�� <= �Ɩ����t
      AND  TRUNC( NVL( ximb.end_date_active, gd_max_date ) ) >= gd_process_date    -- OPM�i�ڱ�޵�.�K�p�I���� >= �Ɩ����t
      AND NOT EXISTS(
              SELECT
                'X'                         exists_flag -- EXISTS�׸�
              FROM
                 oe_order_headers_all       ooha        -- ��ͯ��ð���
                ,oe_order_lines_all         oola        -- �󒍖���ð���
                ,hz_cust_accounts           hca         -- �ڋqϽ�
                ,xxcmm_cust_accounts        xca         -- �ڋq�ǉ����Ͻ�
                ,mtl_secondary_inventories  mtsi        -- �ۊǏꏊϽ�
              WHERE
                   ooha.header_id    =  oola.header_id                      -- ��ͯ��.��ͯ��ID = �󒍖���.��ͯ��ID
              AND  ooha.org_id       =  gn_org_id                           -- ��ͯ��.�g�DID = A-1�擾�̉c�ƒP��
              AND  oola.subinventory =  mtsi.secondary_inventory_name       -- �󒍖���.�ۊǏꏊ = �ۊǏꏊϽ�.�ۊǏꏊ����
              AND  oola.ship_from_org_id  =  mtsi.organization_id           -- �󒍖���.�o�׌��g�DID = �ۊǏꏊϽ�.�g�DID
              AND  mtsi.attribute13       =  gv_subinventory_class          -- �ۊǏꏊϽ�.�ۊǏꏊ���� = '11':����
                                                                            -- ��ͯ��.�ð�� IN ( 'BOOKED','CLOSED' )
              AND  ooha.flow_status_code      IN ( cv_status_booked, cv_status_closed )
              AND  oola.flow_status_code      <> cv_status_cancelled        -- �󒍖���.�ð�� <> 'CANCELLED'
              AND  oola.packing_instructions  IS NOT NULL                   -- �󒍖���.����w�� IS NOT NULL
              AND  NOT EXISTS ( SELECT                                      -- NVL(�󒍖���.�q�R�[�h,�󒍖���.�󒍕i��)����݌ɕi�ڃR�[�h
                                  'X'                 exists_flag -- EXISTS�׸�
                                FROM
                                   fnd_application    fa
                                  ,fnd_lookup_types   flt
                                  ,fnd_lookup_values  flv
                                WHERE
                                     fa.application_id           = flt.application_id
                                AND  flt.lookup_type             = flv.lookup_type
                                AND  fa.application_short_name   = cv_xxcos_short_name
                                AND  flv.lookup_type             = cv_no_inv_item_code
                                AND  flv.start_date_active      <= gd_process_date
                                AND  gd_process_date            <= NVL( flv.end_date_active, gd_max_date )
                                AND  flv.enabled_flag            = cv_yes_flg
                                AND  flv.language                = USERENV( 'LANG' )
                                AND  NVL(oola.attribute6,oola.ordered_item) = flv.lookup_code
                              )
              AND  ooha.sold_to_org_id        =  hca.cust_account_id        -- ��ͯ��.�ڋqID = �ڋqϽ�.�ڋqID
              AND  hca.cust_account_id        =  xca.customer_id            -- �ڋqϽ�.�ڋqID  = �ڋq�ǉ����Ͻ�.�ڋqID
                                                                            -- �ڋq�ǉ����Ͻ�.�[�i���_ = DECODE('ALL','ALL',���Ұ�.���_����)
              AND  xca.delivery_base_code     =  DECODE( iv_base_code
                                                        ,cv_base_all
                                                        ,xca.delivery_base_code
                                                        ,iv_base_code )
              AND  xoha.request_no            =  oola.packing_instructions -- ��ͯ�ޱ�޵�.�˗�No = �󒍖���.����w��
-- ******************** 2009/07/08 1.7 N.Maeda MOD start ******************************* --
                                                                           -- �󒍖��ױ�޵�.�˗��i�� = NVL(�󒍖���.�q�R�[�h,�󒍖���.�󒍕i��
              AND  xola.request_item_code    =  NVL( oola.attribute6, oola.ordered_item )
--                                                                           -- �󒍖��ױ�޵�.�o�וi�� = NVL(�󒍖���.�q�R�[�h,�󒍖���.�󒍕i��
--              AND  xola.shipping_item_code    =  NVL( oola.attribute6, oola.ordered_item )
-- ******************** 2009/07/08 1.7 N.Maeda MOD  end  ******************************* --
              )
--
      UNION
--
  --** ����O�S�擾SQL
      SELECT
         xca.delivery_base_code     base_code                -- �ڋq�ǉ����Ͻ�.�[�i���_���ށF���_����
        ,hca2.account_name          base_name                -- �ڋqϽ�2.�ڋq����           �F���_����
        ,NULL                       order_number             -- ��ͯ��.�󒍔ԍ�           �F�󒍔ԍ�
        ,NULL                       order_line_no            -- �󒍖���.���הԍ�           �F�󒍖���No
        ,xola.order_line_number     line_no                  -- �󒍖��ױ�޵�.���הԍ�      �F����No
        ,xoha.request_no            deliver_requested_no     -- ��ͯ�ޱ�޵�.�˗�No        �F�o�׈˗�No
        ,xoha.deliver_from          deliver_from_whse_number -- ��ͯ�ޱ�޵�.�o�׌��ۊǏꏊ�F�o�׌��q�ɔԍ�
        ,xilv.description           deliver_from_whse_name   -- �ۊǏꏊ.�ۊǏꏊ����       �F�o�׌��q�ɖ�
        ,xoha.customer_code         customer_number          -- ��ͯ�ޱ�޵�.�ڋq          �F�ڋq�ԍ�
        ,hca.account_name           customer_name            -- �ڋqϽ�.�ڋq����            �F�ڋq��
-- ******************** 2009/07/08 1.7 N.Maeda MOD start ******************************* --
        ,xola.request_item_code     item_code                -- �󒍖��ױ�޵�.�˗��i��      �F�i�ں���
--        ,xola.shipping_item_code    item_code                -- �󒍖��ױ�޵�.�o�וi��      �F�i�ں���
-- ******************** 2009/07/08 1.7 N.Maeda MOD  end  ******************************* --
        ,ximb.item_short_name       item_name                -- OPM�i�ڱ�޵�                �F�i��
        ,NULL                       schedule_dlv_date        -- ��ͯ�ޱ�޵�.����          �F�[�i�\���
        ,NULL                       schedule_inspect_date    -- �󒍖���.�����\���         �F�����\���
        ,xoha.arrival_date          arrival_date             -- ��ͯ�ޱ�޵�.���ד�        �F����
        ,0                          order_quantity           -- �󒍖���.�󒍐���           �F�󒍐�
        ,NVL( xola.shipped_quantity, 0 )
                                    deliver_actual_quantity  -- �󒍖��ױ�޵�.�o�׎��ѐ���  �F�o�׎��ѐ�
        ,xola.uom_code              uom_code                 -- �󒍖��ױ�޵�.�P��          �F�P��
        ,0 - NVL( xola.shipped_quantity, 0 )
                                    output_quantity          -- ���ِ�
        ,cv_data_class_5            data_class               -- ��O�f�[�^�S                �F�f�[�^�敪
      FROM
         xxwsh_order_headers_all    xoha  -- ��ͯ�ޱ�޵�
        ,xxwsh_order_lines_all      xola  -- �󒍖��ױ�޵�
        ,xxcmn_item_locations2_v    xilv  -- OPM�ۊǏꏊϽ�
        ,hz_cust_accounts           hca   -- �ڋqϽ�
        ,xxcmm_cust_accounts        xca   -- �ڋq�ǉ����Ͻ�
        ,hz_cust_accounts           hca2  -- �ڋqϽ�2
        ,ic_item_mst_b              iimb  -- OPM�i��
        ,xxcmn_item_mst_b           ximb  -- OPM�i�ڱ�޵�
      WHERE
           xoha.order_header_id      =   xola.order_header_id      -- ��ͯ�ޱ�޵�.��ͯ�ޱ�޵�ID = �󒍖��ױ�޵�.��ͯ�ޱ�޵�ID
      AND  xoha.req_status           =   cv_h_add_status_04        -- ��ͯ�ޱ�޵�.�ð�� = �o�׎��ьv���
      AND  xoha.latest_external_flag =   cv_yes_flg                -- ��ͯ�ޱ�޵�.�ŐV�׸� = 'Y'
      AND  NVL( xola.delete_flag, cv_no_flg ) = cv_no_flg          -- �󒍖��ױ�޵�.�폜�׸� = 'N'
--****************************** 2009/04/10 1.3 T.Kitajima ADD START ******************************--
      AND NVL( xola.shipped_quantity, cn_ship_zero ) != cn_ship_zero  -- �󒍖��ױ�޵�.�o�׎��ѐ��ʂ�0�ȊO
--****************************** 2009/04/10 1.3 T.Kitajima ADD  END  ******************************--
      AND  xoha.deliver_from         =   xilv.segment1             -- ��ͯ�ޱ�޵�.�o�׌��ۊǏꏊ = OPM�ۊǏꏊϽ�.�ۊǑq�ɃR�[�h
      AND  xilv.date_from                             <=  gd_process_date  -- OPM�ۊǏꏊϽ�.�g�D�L���J�n�� <= �Ɩ����t
      AND  TRUNC( NVL( xilv.date_to, gd_max_date ) )  >=  gd_process_date  -- OPM�ۊǏꏊϽ�.�g�D�L���J�n�� >= �Ɩ����t
--MIYATA MODIFY
--      AND  xoha.customer_id          =   hca.cust_account_id       -- ��ͯ�ޱ�޵�.�ڋqID = �ڋqϽ�.�ڋqID
      AND  xoha.customer_code        =   hca.account_number        -- ��ͯ�ޱ�޵�.�ڋq = �ڋqϽ�.�ڋq�R�[�h
--MIYATA MODIFY
      AND  hca.cust_account_id       =   xca.customer_id           -- �ڋqϽ�.�ڋqID       = �ڋq�ǉ����Ͻ�.�ڋqID
      AND  xca.delivery_base_code    =   DECODE( iv_base_code      -- �ڋq�ǉ����Ͻ�.�[�i���_ = DECODE('ALL','ALL',���Ұ�.���_����)
                                                ,cv_base_all
                                                ,xca.delivery_base_code
                                                ,iv_base_code )
      AND  hca2.customer_class_code  =  cv_party_type_1            -- �ڋqϽ�2.�ڋq�敪 = '1':���_
      AND  hca2.account_number       =  xca.delivery_base_code     -- �ڋqϽ�2.�ڋq���� = �ڋq�ǉ����Ͻ�.�[�i���_����
-- ******************** 2009/07/08 1.7 N.Maeda MOD start ******************************* --
      AND  xola.request_item_code   =  iimb.item_no               -- �󒍖��ױ�޵�.�˗��i�� = OPM�i��.�i�ں���
--      AND  xola.shipping_item_code   =  iimb.item_no               -- �󒍖��ױ�޵�.�o�וi�� = OPM�i��.�i�ں���
-- ******************** 2009/07/08 1.7 N.Maeda MOD  end  ******************************* --
      AND  iimb.item_id              =  ximb.item_id               -- OPM�i��.�i��ID = OPM�i�ڱ�޵�.�i��id
      AND  TRUNC( ximb.start_date_active )                    <=  gd_process_date    -- OPM�i�ڱ�޵�.�K�p�J�n�� <= �Ɩ����t
      AND  TRUNC( NVL( ximb.end_date_active, gd_max_date ) )  >=  gd_process_date    -- OPM�i�ڱ�޵�.�K�p�I���� >= �Ɩ����t
      AND NOT EXISTS(
              SELECT
                'X'                       exists_flag -- EXISTS�׸�
              FROM
                 oe_order_headers_all       ooha        -- ��ͯ��ð���
                ,oe_order_lines_all         oola        -- �󒍖���ð���
                ,hz_cust_accounts           hca         -- �ڋqϽ�
                ,xxcmm_cust_accounts        xca         -- �ڋq�ǉ����Ͻ�
                ,mtl_secondary_inventories  mtsi        -- �ۊǏꏊϽ�
              WHERE
                   ooha.header_id    =  oola.header_id                      -- ��ͯ��.��ͯ��ID = �󒍖���.��ͯ��ID
              AND  ooha.org_id       =  gn_org_id                           -- ��ͯ��.�g�DID = A-1�擾�̉c�ƒP��
              AND  oola.subinventory =  mtsi.secondary_inventory_name       -- �󒍖���.�ۊǏꏊ = �ۊǏꏊϽ�.�ۊǏꏊ����
              AND  oola.ship_from_org_id  =  mtsi.organization_id           -- �󒍖���.�o�׌��g�DID = �ۊǏꏊϽ�.�g�DID
              AND  mtsi.attribute13       =  gv_subinventory_class          -- �ۊǏꏊϽ�.�ۊǏꏊ���� = '11':����
                                                                            -- ��ͯ��.�ð�� IN ( 'BOOKED','CLOSED' )
              AND  ooha.flow_status_code      IN ( cv_status_booked, cv_status_closed )
              AND  oola.flow_status_code      <> cv_status_cancelled        -- �󒍖���.�ð�� <> 'CANCELLED'
              AND  oola.packing_instructions  IS NOT NULL                   -- �󒍖���.����w�� IS NOT NULL
              AND  NOT EXISTS ( SELECT                                      -- NVL(�󒍖���.�q�R�[�h,�󒍖���.�󒍕i��)����݌ɕi�ڃR�[�h
                                  'X'                 exists_flag -- EXISTS�׸�
                                FROM
                                   fnd_application    fa
                                  ,fnd_lookup_types   flt
                                  ,fnd_lookup_values  flv
                                WHERE
                                     fa.application_id           = flt.application_id
                                AND  flt.lookup_type             = flv.lookup_type
                                AND  fa.application_short_name   = cv_xxcos_short_name
                                AND  flv.lookup_type             = cv_no_inv_item_code
                                AND  flv.start_date_active      <= gd_process_date
                                AND  gd_process_date            <= NVL( flv.end_date_active, gd_max_date )
                                AND  flv.enabled_flag            = cv_yes_flg
                                AND  flv.language                = USERENV( 'LANG' )
                                AND  NVL(oola.attribute6,oola.ordered_item) = flv.lookup_code
                              )
              AND  ooha.sold_to_org_id        =  hca.cust_account_id        -- ��ͯ��.�ڋqID = �ڋqϽ�.�ڋqID
              AND  hca.cust_account_id        =  xca.customer_id            -- �ڋqϽ�.�ڋqID  = �ڋq�ǉ����Ͻ�.�ڋqID
                                                                            -- �ڋq�ǉ����Ͻ�.�[�i���_ = DECODE('ALL','ALL',���Ұ�.���_����)
              AND  xca.delivery_base_code     =  DECODE( iv_base_code
                                                        ,cv_base_all
                                                        ,xca.delivery_base_code
                                                        ,iv_base_code )
              AND  xoha.request_no            =  oola.packing_instructions  -- ��ͯ�ޱ�޵�.�˗�No = �󒍖���.����w��
              )
--
      UNION
--
  --** ����O�T�擾SQL
      SELECT
         xca.delivery_base_code     base_code                -- �ڋq�ǉ����Ͻ�.�[�i���_���ށF���_����
        ,hca2.account_name          base_name                -- �ڋqϽ�2.�ڋq����           �F���_����
        ,ooha.order_number          order_number             -- ��ͯ��.�󒍔ԍ�           �F�󒍔ԍ�
        ,oola.line_number           order_line_no            -- �󒍖���.���הԍ�           �F�󒍖���No
        ,NULL                       line_no                  -- �󒍖��ױ�޵�.���הԍ�      �F����No
        ,oola.packing_instructions  deliver_requested_no     -- �󒍖���.����w��           �F�o�׈˗�No
        ,oola.subinventory          deliver_from_whse_number -- �󒍖���.�ۊǏꏊ           �F�o�׌��q�ɔԍ�
        ,mtsi.description           deliver_from_whse_name   -- �ۊǏꏊ.�ۊǏꏊ����       �F�o�׌��q�ɖ�
        ,hca.account_number         customer_number          -- �ڋqϽ�.�ڋq����            �F�ڋq�ԍ�
        ,hca.account_name           customer_name            -- �ڋqϽ�.�ڋq����            �F�ڋq��
        ,NVL( oola.attribute6, oola.ordered_item )
                                    item_code                -- �󒍖���.�󒍕i��           �F�i�ں���
        ,ximb.item_short_name       item_name                -- OPM�i�ڱ�޵�                �F�i��
        ,TRUNC( oola.request_date ) schedule_dlv_date        -- �󒍖���.�v����             �F�[�i�\���
        ,oola.attribute4            schedule_inspect_date    -- �󒍖���.�����\���         �F�����\���
        ,NULL                       arrival_date             -- ��ͯ�ޱ�޵�.���ד�        �F����
--****************************** 2009/05/26 1.4 T.Kitajima MOD START ******************************--
--        ,oola.ordered_quantity      order_quantity           -- �󒍖���.�󒍐���           �F�󒍐�
        ,oola.ordered_quantity * 
          DECODE ( otta.order_category_code, cv_order, 1, -1 )
                                    order_quantity           -- �󒍖���.�󒍐���           �F�󒍐�
--****************************** 2009/05/26 1.4 T.Kitajima MOD  END  ******************************--
        ,0                          deliver_actual_quantity  -- �󒍖��ױ�޵�.�o�׎��ѐ���  �F�o�׎��ѐ�
        ,oola.order_quantity_uom    uom_code                 -- �󒍖���.�󒍒P��           �F�P��
        ,oola.ordered_quantity      output_quantity          -- ���ِ�
        ,cv_data_class_6            data_class               -- ��O�f�[�^�T                �F�f�[�^�敪
      FROM
         oe_order_headers_all       ooha  -- ��ͯ��ð���
        ,oe_order_lines_all         oola  -- �󒍖���ð���
        ,hz_cust_accounts           hca   -- �ڋqϽ�
        ,xxcmm_cust_accounts        xca   -- �ڋq�ǉ����Ͻ�
        ,mtl_secondary_inventories  mtsi  -- �ۊǏꏊϽ�
        ,hz_cust_accounts           hca2  -- �ڋqϽ�2
        ,ic_item_mst_b              iimb  -- OPM�i��
        ,xxcmn_item_mst_b           ximb  -- OPM�i�ڱ�޵�
--****************************** 2009/05/26 1.4 T.Kitajima ADD START ******************************--
        ,oe_transaction_types_tl    ottt  -- �󒍎���^�C�v�i�E�v�j
        ,oe_transaction_types_all   otta  -- �󒍎���^�C�v�}�X�^
--****************************** 2009/05/26 1.4 T.Kitajima ADD  END  ******************************--
      WHERE
           ooha.header_id    =  oola.header_id                    -- ��ͯ��.��ͯ��ID = �󒍖���.��ͯ��ID
      AND  ooha.org_id       =  gn_org_id                         -- ��ͯ��.�g�DID = A-1�擾�̉c�ƒP��
      AND  oola.subinventory =  mtsi.secondary_inventory_name     -- �󒍖���.�ۊǏꏊ = �ۊǏꏊϽ�.�ۊǏꏊ����
--****************************** 2009/05/26 1.4 T.Kitajima ADD START ******************************--
      AND  oola.line_type_id        = ottt.transaction_type_id    -- �󒍖���.��������ID = �󒍎������(�E�v).����ID
      AND  ottt.transaction_type_id = otta.transaction_type_id    -- �󒍎������(�E�v).����ID = �󒍎������.����ID
      AND  ottt.language            = USERENV( 'LANG' )           -- �󒍎������(�E�v).����ID = 'JA'
--****************************** 2009/05/26 1.4 T.Kitajima ADD  END  ******************************--
      AND  oola.ship_from_org_id  =  mtsi.organization_id         -- �󒍖���.�o�׌��g�DID = �ۊǏꏊϽ�.�g�DID
      AND  mtsi.attribute13       =  gv_subinventory_class        -- �ۊǏꏊϽ�.�ۊǏꏊ���� = '11':����
      AND  ooha.flow_status_code  =  cv_status_booked             -- ��ͯ��.�ð�� = 'BOOKED'
                                                                  -- �󒍖���.�ð�� NOT IN( 'CLOSED','CANCELLED')
      AND  oola.flow_status_code  NOT IN ( cv_status_closed, cv_status_cancelled )
      AND  oola.packing_instructions  IS NOT NULL                 -- �󒍖���.����w�� IS NOT NULL
      AND  NOT EXISTS ( SELECT                                    -- NVL(�󒍖���.�q�R�[�h,�󒍖���.�󒍕i��)����݌ɕi�ڃR�[�h
                          'X'                 exists_flag -- EXISTS�׸�
                        FROM
                           fnd_application    fa
                          ,fnd_lookup_types   flt
                          ,fnd_lookup_values  flv
                        WHERE
                             fa.application_id           = flt.application_id
                        AND  flt.lookup_type             = flv.lookup_type
                        AND  fa.application_short_name   = cv_xxcos_short_name
                        AND  flv.lookup_type             = cv_no_inv_item_code
                        AND  flv.start_date_active      <= gd_process_date
                        AND  gd_process_date            <= NVL( flv.end_date_active, gd_max_date )
                        AND  flv.enabled_flag            = cv_yes_flg
                        AND  flv.language                = USERENV( 'LANG' )
                        AND  NVL(oola.attribute6,oola.ordered_item) = flv.lookup_code
                     )
      AND  ooha.sold_to_org_id     =  hca.cust_account_id         -- ��ͯ��.�ڋqID = �ڋqϽ�.�ڋqID
      AND  hca.cust_account_id     =  xca.customer_id             -- �ڋqϽ�.�ڋqID  = �ڋq�ǉ����Ͻ�.�ڋqID
                                                                  -- �ڋq�ǉ����Ͻ�.�[�i���_ = DECODE('ALL','ALL',���Ұ�.���_����)
      AND  xca.delivery_base_code  =  DECODE( iv_base_code
                                             ,cv_base_all
                                             ,xca.delivery_base_code
                                             ,iv_base_code )
      AND  hca2.customer_class_code  =  cv_party_type_1              -- �ڋqϽ�2.�ڋq�敪 = '1':���_
      AND  hca2.account_number       =  xca.delivery_base_code       -- �ڋqϽ�2.�ڋq���� = �ڋq�ǉ����Ͻ�.�[�i���_����
      AND  NVL( oola.attribute6, oola.ordered_item ) = iimb.item_no  -- NVL(�󒍖���.�q�R�[�h,�󒍖���.�󒍕i�� = OPM�i��.�i�ں���
      AND  iimb.item_id              =  ximb.item_id                 -- OPM�i��.�i��ID = OPM�i�ڱ�޵�.�i��id
      AND  TRUNC( ximb.start_date_active )                    <=  gd_process_date    -- OPM�i�ڱ�޵�.�K�p�J�n�� <= �Ɩ����t
      AND  TRUNC( NVL( ximb.end_date_active, gd_max_date ) )  >=  gd_process_date    -- OPM�i�ڱ�޵�.�K�p�I���� >= �Ɩ����t
      AND NOT EXISTS(
              SELECT
                'X'                          exists_flag -- EXISTS�׸�
              FROM
                 xxwsh_order_headers_all     xoha        -- ��ͯ�ޱ�޵�
                ,xxwsh_order_lines_all       xola        -- �󒍖��ױ�޵�
                ,hz_cust_accounts            hca         -- �ڋqϽ�
                ,xxcmm_cust_accounts         xca         -- �ڋq�ǉ����Ͻ�
              WHERE
                   xoha.order_header_id      =   xola.order_header_id      -- ��ͯ�ޱ�޵�.��ͯ�ޱ�޵�ID = �󒍖��ױ�޵�.��ͯ�ޱ�޵�ID
              AND  xoha.req_status           <>  cv_h_add_status_99        -- ��ͯ�ޱ�޵�.�ð�� <> ���
              AND  xoha.latest_external_flag =   cv_yes_flg                -- ��ͯ�ޱ�޵�.�ŐV�׸� = 'Y'
              AND  NVL( xola.delete_flag, cv_no_flg ) = cv_no_flg          -- �󒍖��ױ�޵�.�폜�׸� = 'N'
--MIYATA MODIFY
--              AND  xoha.customer_id          =   hca.cust_account_id       -- ��ͯ�ޱ�޵�.�ڋqID = �ڋqϽ�.�ڋqID
              AND  xoha.customer_code        =   hca.account_number        -- ��ͯ�ޱ�޵�.�ڋq = �ڋqϽ�.�ڋq�R�[�h
--MIYATA MODIFY
              AND  hca.cust_account_id       =   xca.customer_id           -- �ڋqϽ�.�ڋqID = �ڋq�ǉ����Ͻ�.�ڋqID
              AND  xca.delivery_base_code    =   DECODE( iv_base_code      -- �ڋq�ǉ����Ͻ�.�[�i���_ = DECODE('ALL','ALL',���Ұ�.���_����)
                                                        ,cv_base_all
                                                        ,xca.delivery_base_code
                                                        ,iv_base_code )
              AND  oola.packing_instructions =   xoha.request_no           -- �󒍖���.����w�� = ��ͯ�ޱ�޵�.�˗�No
              )
      ;
--
    -- *** ���[�J���E���R�[�h ***
    l_data_rec       data_cur%ROWTYPE;
--
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    --���[�v�J�E���g������
    ln_idx := 0;
--
    --==================================
    -- 1.�f�[�^�擾
    --==================================
    <<loop_get_data>>
    FOR l_data_rec IN data_cur LOOP
      -- ���R�[�hID�̎擾
      BEGIN
--
        SELECT
          xxcos_rep_direct_list_s01.nextval
        INTO
          ln_record_id
        FROM
          dual
        ;
      END;
--
      -- �J�E���g�A�b�v
      ln_idx := ln_idx + 1;
--
      -- �ϐ��֊i�[
      gt_rpt_data_tab( ln_idx ).record_id                := ln_record_id;                          -- ���R�[�hID 
      gt_rpt_data_tab( ln_idx ).base_code                := l_data_rec.base_code;                  -- ���_�R�[�h
                                                                                                   -- ���_����
      gt_rpt_data_tab( ln_idx ).base_name                := SUBSTRB( l_data_rec.base_name, 1, 40 );
      gt_rpt_data_tab( ln_idx ).order_number             := l_data_rec.order_number;               -- �󒍔ԍ�
      gt_rpt_data_tab( ln_idx ).order_line_no            := l_data_rec.order_line_no;              -- �󒍖���No.
      gt_rpt_data_tab( ln_idx ).line_no                  := l_data_rec.line_no;                    -- ����No.
      gt_rpt_data_tab( ln_idx ).deliver_requested_no     := l_data_rec.deliver_requested_no;       -- �o�׈˗�No
      gt_rpt_data_tab( ln_idx ).deliver_from_whse_number := l_data_rec.deliver_from_whse_number;   -- �o�׌��q�ɔԍ�
                                                                                                   -- �o�׌��q�ɖ�
      gt_rpt_data_tab( ln_idx ).deliver_from_whse_name   := SUBSTRB( l_data_rec.deliver_from_whse_name, 1, 20 );
      gt_rpt_data_tab( ln_idx ).customer_number          := l_data_rec.customer_number;            -- �ڋq�ԍ�
                                                                                                   -- �ڋq��
      gt_rpt_data_tab( ln_idx ).customer_name            := SUBSTRB( l_data_rec.customer_name, 1, 20 );
      gt_rpt_data_tab( ln_idx ).item_code                := l_data_rec.item_code;                  -- �i�ڃR�[�h
      gt_rpt_data_tab( ln_idx ).item_name                := SUBSTRB( l_data_rec.item_name, 1, 20 );-- �i��
      gt_rpt_data_tab( ln_idx ).schedule_dlv_date        := l_data_rec.schedule_dlv_date;          -- �[�i�\���
                                                                                                   -- �����\���
      gt_rpt_data_tab( ln_idx ).schedule_inspect_date    := TO_DATE( l_data_rec.schedule_inspect_date, cv_yyyymmddhhmiss );
      gt_rpt_data_tab( ln_idx ).arrival_date             := l_data_rec.arrival_date;               -- ����
      gt_rpt_data_tab( ln_idx ).order_quantity           := l_data_rec.order_quantity;             -- �󒍐�
      gt_rpt_data_tab( ln_idx ).deliver_actual_quantity  := l_data_rec.deliver_actual_quantity;    -- �o�׎��ѐ�
      gt_rpt_data_tab( ln_idx ).uom_code                 := l_data_rec.uom_code;                   -- �P��
      gt_rpt_data_tab( ln_idx ).output_quantity          := l_data_rec.output_quantity;            -- ���ِ�
      gt_rpt_data_tab( ln_idx ).data_class               := l_data_rec.data_class;                 -- �f�[�^�敪
      gt_rpt_data_tab( ln_idx ).created_by               := cn_created_by;                         -- �쐬��
      gt_rpt_data_tab( ln_idx ).creation_date            := cd_creation_date;                      -- �쐬��
      gt_rpt_data_tab( ln_idx ).last_updated_by          := cn_last_updated_by;                    -- �ŏI�X�V��
      gt_rpt_data_tab( ln_idx ).last_update_date         := cd_last_update_date;                   -- �ŏI�X�V��
      gt_rpt_data_tab( ln_idx ).last_update_login        := cn_last_update_login;                  -- �ŏI�X�V۸޲�
      gt_rpt_data_tab( ln_idx ).request_id               := cn_request_id;                         -- �v��ID
      gt_rpt_data_tab( ln_idx ).program_application_id   := cn_program_application_id;             -- �ݶ��ĥ��۸��ѥ���ع����ID
      gt_rpt_data_tab( ln_idx ).program_id               := cn_program_id;                         -- �ݶ��ĥ��۸���ID
      gt_rpt_data_tab( ln_idx ).program_update_date      := cd_program_update_date;                -- ��۸��эX�V��
--
    END LOOP loop_get_data;
--
    --���������J�E���g
    gn_target_cnt := gt_rpt_data_tab.COUNT;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_data;
--
--
  /**********************************************************************************
   * Procedure Name   : insert_rpt_wrk_data
   * Description      : ���[�N�e�[�u���f�[�^�o�^(A-3)
   ***********************************************************************************/
  PROCEDURE insert_rpt_wrk_data(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'insert_rpt_wrk_data'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lv_table_name    VARCHAR2(5000);
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    --==================================
    -- 1.���[���[�N�e�[�u���o�^����
    --==================================
    <<loop_insert_rpt_wrk_data>>
    BEGIN
--
      FORALL i IN 1..gt_rpt_data_tab.COUNT
        INSERT INTO
          xxcos_rep_direct_list
        VALUES
          gt_rpt_data_tab(i)
      ;
--
    EXCEPTION
      WHEN OTHERS THEN
        RAISE global_insert_data_expt;
    END;
--
    -- ���팏��
    gn_normal_cnt := gt_rpt_data_tab.COUNT;
--
  EXCEPTION
    --���[���[�N�e�[�u���o�^���s
    WHEN global_insert_data_expt THEN
--
      lv_table_name := xxccp_common_pkg.get_msg(
                         iv_application         => cv_xxcos_short_name,
                         iv_name                => cv_msg_vl_table_name
                       );
--
      ov_errmsg     := xxccp_common_pkg.get_msg(
                         iv_application        => cv_xxcos_short_name,
                         iv_name               => cv_msg_insert_err,
                         iv_token_name1        => cv_tkn_nm_table_name,
                         iv_token_value1       => lv_table_name,
                         iv_token_name2        => cv_tkn_nm_key_data,
                         iv_token_value2       => NULL
                       );
--
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg, 1, 5000 );
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END insert_rpt_wrk_data;
--
--
  /**********************************************************************************
   * Procedure Name   : execute_svf
   * Description      : SVF�N��(A-4)
   ***********************************************************************************/
  PROCEDURE execute_svf(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'execute_svf'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
    lv_nodata_msg       VARCHAR2(5000);
    lv_file_name        VARCHAR2(100);
    lv_tkn_vl_api_name  VARCHAR2(100);
--
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    --����0���p���b�Z�[�W�擾
    lv_nodata_msg := xxccp_common_pkg.get_msg(
                       iv_application        => cv_xxcos_short_name,
                       iv_name               => cv_msg_no_data_err
                     );
--
    --�o�̓t�@�C�����ҏW
    lv_file_name := cv_report_id || TO_CHAR( SYSDATE, cv_yyyymmdd ) || TO_CHAR( cn_request_id ) || cv_extension;
--
    --SVF�N��
    xxccp_svfcommon_pkg.submit_svf_request(
      ov_retcode              => lv_retcode,
      ov_errbuf               => lv_errbuf,
      ov_errmsg               => lv_errmsg,
      iv_conc_name            => cv_conc_name,
      iv_file_name            => lv_file_name,
      iv_file_id              => cv_report_id,
      iv_output_mode          => cv_output_mode,
      iv_frm_file             => cv_frm_file,
      iv_vrq_file             => cv_vrq_file,
      iv_org_id               => NULL,
      iv_user_name            => NULL,
      iv_resp_name            => NULL,
      iv_doc_name             => NULL,
      iv_printer_name         => NULL,
      iv_request_id           => TO_CHAR( cn_request_id ),
      iv_nodata_msg           => lv_nodata_msg,
      iv_svf_param1           => NULL,
      iv_svf_param2           => NULL,
      iv_svf_param3           => NULL,
      iv_svf_param4           => NULL,
      iv_svf_param5           => NULL,
      iv_svf_param6           => NULL,
      iv_svf_param7           => NULL,
      iv_svf_param8           => NULL,
      iv_svf_param9           => NULL,
      iv_svf_param10          => NULL,
      iv_svf_param11          => NULL,
      iv_svf_param12          => NULL,
      iv_svf_param13          => NULL,
      iv_svf_param14          => NULL,
      iv_svf_param15          => NULL
    );
    --SVF�N�����s
    IF  ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_svf_excute_expt;
    END IF;
--
  EXCEPTION
    --*** SVF�N����O ***
    WHEN global_svf_excute_expt THEN
      lv_tkn_vl_api_name := xxccp_common_pkg.get_msg(
                              iv_application        => cv_xxcos_short_name,
                              iv_name               => cv_msg_vl_api_name
                            );
--
      ov_errmsg          := xxccp_common_pkg.get_msg(
                              iv_application        => cv_xxcos_short_name,
                              iv_name               => cv_msg_api_err,
                              iv_token_name1        => cv_tkn_nm_api_name,
                              iv_token_value1       => lv_tkn_vl_api_name
                            );
--
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg, 1, 5000 );
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END execute_svf;
--
--
  /**********************************************************************************
   * Procedure Name   : delete_rpt_wrk_data
   * Description      : ���[���[�N�e�[�u���폜(A-5)
   ***********************************************************************************/
  PROCEDURE delete_rpt_wrk_data(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'delete_rpt_wrk_data'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lv_key_info      VARCHAR2(5000);
    lv_table_name    VARCHAR2(5000);
    lv_request_name  VARCHAR2(5000);
--
    -- *** ���[�J���E�J�[�\�� ***
    CURSOR lock_cur
    IS
      SELECT
        xrdl.record_id rec_id              -- ���|�[�gID
      FROM
        xxcos_rep_direct_list xrdl         -- �����󒍗�O�f�[�^���X�g���[���[�N�e�[�u��
      WHERE
        xrdl.request_id = cn_request_id    -- ���N�G�X�gID
      FOR UPDATE NOWAIT
      ;
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    --�����Ώۃf�[�^���b�N
    BEGIN
      -- ���b�N�p�J�[�\���I�[�v��
      OPEN lock_cur;
      -- ���b�N�p�J�[�\���N���[�Y
      CLOSE lock_cur;
--
    EXCEPTION
      --�����Ώۃf�[�^���b�N��O
      WHEN global_data_lock_expt THEN
        RAISE global_data_lock_expt;
--
    END;
--
    --�����Ώۃf�[�^�폜
    BEGIN
      --�Ώۃf�[�^�폜
      DELETE
      FROM 
        xxcos_rep_direct_list xrdl          -- �����󒍗�O�f�[�^���X�g���[���[�N�e�[�u��
      WHERE
        xrdl.request_id = cn_request_id     -- ���N�G�X�gID
      ;
--
    EXCEPTION
      --�����Ώۃf�[�^�폜���s
      WHEN OTHERS THEN
        RAISE global_delete_data_expt;
--
    END;
--
  EXCEPTION
    -- *** �����Ώۃf�[�^���b�N��O�n���h�� ***
    WHEN global_data_lock_expt THEN
      lv_table_name := xxccp_common_pkg.get_msg(
                         iv_application        => cv_xxcos_short_name,
                         iv_name               => cv_msg_vl_table_name
                       );
--
      ov_errmsg     := xxccp_common_pkg.get_msg(
                         iv_application        => cv_xxcos_short_name,
                         iv_name               => cv_msg_lock_err,
                         iv_token_name1        => cv_tkn_nm_lock_table_name,
                         iv_token_value1       => lv_table_name
                       );
--
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg, 1, 5000 );
      ov_retcode := cv_status_error;
--
    --*** �����Ώۃf�[�^�폜��O�n���h�� ***
    WHEN global_delete_data_expt THEN
      lv_table_name   := xxccp_common_pkg.get_msg(
                           iv_application       => cv_xxcos_short_name,
                           iv_name              => cv_msg_vl_table_name
                         );
--
      lv_request_name := xxccp_common_pkg.get_msg(
                           iv_application       => cv_xxcos_short_name,
                           iv_name              => cv_msg_vl_request_id
                         );
--
      xxcos_common_pkg.makeup_key_info(
                           iv_item_name1      => lv_request_name,
                           iv_data_value1     => TO_CHAR( cn_request_id ),
                           ov_key_info        => lv_key_info,             --�ҏW���ꂽ�L�[���
                           ov_errbuf          => lv_errbuf,               --�G���[���b�Z�[�W
                           ov_retcode         => lv_retcode,              --���^�[���R�[�h
                           ov_errmsg          => lv_errmsg                --���[�U�E�G���[�E���b�Z�[�W
      );
--
      ov_errmsg     :=  xxccp_common_pkg.get_msg(
                          iv_application      => cv_xxcos_short_name,
                          iv_name             => cv_msg_delete_err,
                          iv_token_name1      => cv_tkn_nm_table_name,
                          iv_token_value1     => lv_table_name,
                          iv_token_name2      => cv_tkn_nm_key_data,
                          iv_token_value2     => lv_key_info
                        );
--
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg, 1, 5000 );
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END delete_rpt_wrk_data;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    iv_base_code  IN  VARCHAR2,     --   1.���_�R�[�h
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
--
--#####################  �Œ胍�[�J���萔�ϐ��錾�� START   ####################
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'submain'; -- �v���O������
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
--2009/06/25  Ver1.6 T1_1437  Add start
    lv_errbuf_svf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W(SVF���s���ʕێ��p)
    lv_retcode_svf VARCHAR2(1);     -- ���^�[���E�R�[�h(SVF���s���ʕێ��p)
    lv_errmsg_svf  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W(SVF���s���ʕێ��p)
--2009/06/25  Ver1.6 T1_1437  Add end
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
--
    -- �O���[�o���ϐ��̏�����
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
    gn_warn_cnt   := 0;
--
    -- ===============================
    -- A-1  ��������
    -- ===============================
    init(
      iv_base_code,      -- 1.���_�R�[�h
      lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    IF ( lv_retcode = cv_status_normal ) THEN
      NULL;
    ELSE
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- A-2  ��O�f�[�^�擾
    -- ===============================
    get_data(
      iv_base_code,      -- 1.���_�R�[�h
      lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    IF ( lv_retcode = cv_status_normal ) THEN
      NULL;
    ELSE
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- A-3  ���[�N�e�[�u���f�[�^�o�^
    -- ===============================
    insert_rpt_wrk_data(
      lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    IF ( lv_retcode = cv_status_normal ) THEN
      COMMIT;
    ELSE
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- A-4  SVF�R���J�����g�N��
    -- ===============================
    execute_svf(
      lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
-- 2009/06/25  Ver1.6  T1_1437  Mod Start
--    IF ( lv_retcode = cv_status_normal ) THEN
--      NULL;
--    ELSE
--      RAISE global_process_expt;
--    END IF;
--
    --
    --�G���[�ł����[�N�e�[�u�����폜����ׁA�G���[����ێ�
    lv_errbuf_svf  := lv_errbuf;
    lv_retcode_svf := lv_retcode;
    lv_errmsg_svf  := lv_errmsg;
-- 2009/06/25  Ver1.6 T1_1437  Mod End
--
    -- ===============================
    -- A-5  ���[�N�e�[�u���f�[�^�폜
    -- ===============================
    delete_rpt_wrk_data(
      lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    IF ( lv_retcode = cv_status_normal ) THEN
      NULL;
    ELSE
      RAISE global_process_expt;
    END IF;
--
-- 2009/06/25  Ver1.6 T1_1437  Add start
    --�G���[�̏ꍇ�A���[���o�b�N����̂ł����ŃR�~�b�g
    COMMIT;
--
    --SVF���s���ʊm�F
    IF ( lv_retcode_svf = cv_status_error ) THEN
      lv_errbuf  := lv_errbuf_svf;
      lv_retcode := lv_retcode_svf;
      lv_errmsg  := lv_errmsg_svf;
      RAISE global_process_expt;
    END IF;
-- 2009/06/25  Ver1.6 T1_1437  Add End
--
    --����0�����X�e�[�^�X���䏈��
--****************************** 2009/06/17 1.5 N.Nishimura MOD START ******************************--
--    IF ( gn_target_cnt = 0 ) THEN
    IF ( gn_target_cnt <> 0 ) THEN
--****************************** 2009/06/17 1.5 N.Nishimura MOD  END  ******************************--
      ov_retcode := cv_status_warn;
    END IF;
--
  EXCEPTION
      -- *** �C�ӂŗ�O�������L�q���� ****
      -- �J�[�\���̃N���[�Y�������ɋL�q����
--
--#################################  �Œ��O������ START   ###################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--####################################  �Œ蕔 END   ##########################################
--
  END submain;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : �R���J�����g���s�t�@�C���o�^�v���V�[�W��
   **********************************************************************************/
--
  PROCEDURE main(
    errbuf        OUT VARCHAR2,      --   �G���[�E���b�Z�[�W  --# �Œ� #
    retcode       OUT VARCHAR2,      --   ���^�[���E�R�[�h    --# �Œ� #
    iv_base_code  IN  VARCHAR2       --   1.���_�R�[�h
  )
--
--
--###########################  �Œ蕔 START   ###########################
--
  IS
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name        CONSTANT VARCHAR2(100) := 'main';             -- �v���O������
--
    cv_appl_short_name CONSTANT VARCHAR2(10)  := 'XXCCP';            -- �A�h�I���F���ʁEIF�̈�
    cv_target_rec_msg  CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90000'; -- �Ώی������b�Z�[�W
    cv_success_rec_msg CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90001'; -- �����������b�Z�[�W
    cv_error_rec_msg   CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90002'; -- �G���[�������b�Z�[�W
    cv_skip_rec_msg    CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90003'; -- �X�L�b�v�������b�Z�[�W
    cv_cnt_token       CONSTANT VARCHAR2(10)  := 'COUNT';            -- �������b�Z�[�W�p�g�[�N����
    cv_normal_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004'; -- ����I�����b�Z�[�W
    cv_warn_msg        CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005'; -- �x���I�����b�Z�[�W
    cv_error_msg       CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006'; -- �G���[�I���S���[���o�b�N
    cv_log_header_out  CONSTANT VARCHAR2(6)   := 'OUTPUT';           -- �R���J�����g�w�b�_���b�Z�[�W�o�͐�F�o��
    cv_log_header_log  CONSTANT VARCHAR2(6)   := 'LOG';              -- �R���J�����g�w�b�_���b�Z�[�W�o�͐�F���O(���[�̂�)
--
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf          VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode         VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg          VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_message_code    VARCHAR2(100);   -- �I�����b�Z�[�W�R�[�h
    --
  BEGIN
--
--###########################  �Œ蕔 START   #####################################################
--
    -- �Œ�o��
    -- �R���J�����g�w�b�_���b�Z�[�W�o�͊֐��̌Ăяo��
    xxccp_common_pkg.put_log_header(
       iv_which   => cv_log_header_log
      ,ov_retcode => lv_retcode
      ,ov_errbuf  => lv_errbuf
      ,ov_errmsg  => lv_errmsg
    );
    --
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_api_others_expt;
    END IF;
    --
--###########################  �Œ蕔 END   #############################
--
    -- ===============================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ===============================================
    submain(
       iv_base_code  -- 1.���_�R�[�h
      ,lv_errbuf     -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode    -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    --�G���[�o��
    IF ( lv_retcode = cv_status_error ) THEN
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --�G���[���b�Z�[�W
      );
    END IF;
    --��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
    --�Ώی����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_target_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR( gn_target_cnt )
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --
    --���������o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_success_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR( gn_normal_cnt )
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --
    --�G���[�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_error_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR( gn_error_cnt )
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --
/****
    --�X�L�b�v�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_skip_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR( gn_warn_cnt )
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
****/
    --
    --��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
--
    --�I�����b�Z�[�W
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
                    ,iv_name         => lv_message_code
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
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
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
      ROLLBACK;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
      ROLLBACK;
  END main;
--
--###########################  �Œ蕔 END   #######################################################
--
END XXCOS008A03R;
/
