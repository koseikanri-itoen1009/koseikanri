CREATE OR REPLACE PACKAGE BODY XXCSO020A03C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCSO020A03C(body)
 * Description      : �t���x���_�[�p�r�o�ꌈ�E�o�^��ʂɂ���ēo�^���ꂽ�V�K�ڋq�����ڋq
 *                    �}�X�^�A�_���}�X�^�ɓo�^���܂��B�܂��A�t���x���_�[�p�r�o�ꌈ�E�o�^
 *                    ��ʂɂĕύX���ꂽ�����ڋq�����ڋq�}�X�^�ɔ��f���܂��B
 * MD.050           : MD050_CSO_020_A03_�e��}�X�^���f�����@�\
 *
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  start_proc              ��������(A-1)
 *  get_install_at_info     �ݒu���񒊏o(A-2)
 *  regist_party            �p�[�e�B�}�X�^�o�^�X�V(A-3)
 *  regist_locat_party_site �ڋq���Ə��^�p�[�e�B�T�C�g�}�X�^�o�^�X�V(A-4)
 *  regist_cust_account     �ڋq�}�X�^�o�^�X�V(A-5)
 *  regist_cust_acct_site   �ڋq���ݒn�}�X�^�o�^(A-6)
 *  regist_cust_site_use    �ڋq�g�p�ړI�}�X�^�o�^(A-7)
 *  regist_account_addon    �ڋq�A�h�I���}�X�^�o�^�X�V(A-8)
 *  get_contract            �_����񒊏o(A-9)
 *  regist_contract         �_���o�^(A-10)
 *  submain                 ���C�������v���V�[�W��
 *  main                    ���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008-12-09    1.0   Kazuo.Satomura   �V�K�쐬
 *  2008-12-16          Kazuo.Satomura   �P�̃e�X�g�o�O�C��
 *  2009-02-19          Kazuo.Satomura   �d�l�ύX�Ή�
 *                                       �E�����ΏۊO�̏ꍇ���ݒu��h�c�E�_���h�c��߂�
 *                                         �悤�C��
 *  2009-02-20          Kazuo.Satomura   �d�l�ύX�Ή�
 *                                       �E�ڋq�X�e�[�^�X�A�ڋq�敪��萔�ɕύX
 *****************************************************************************************/
  --
  --#######################  �Œ�O���[�o���萔�錾�� START   #######################
  --
  -- �X�e�[�^�X�E�R�[�h
  cv_status_normal CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal; -- ����:0
  cv_status_warn   CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_warn;   -- �x��:1
  cv_status_error  CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_error;  -- �ُ�:2
  --
  -- WHO�J����
  cn_created_by             CONSTANT NUMBER := fnd_global.user_id;         -- CREATED_BY
  cd_creation_date          CONSTANT DATE   := SYSDATE;                    -- CREATION_DATE
  cn_last_updated_by        CONSTANT NUMBER := fnd_global.user_id;         -- LAST_UPDATED_BY
  cd_last_update_date       CONSTANT DATE   := SYSDATE;                    -- LAST_UPDATE_DATE
  cn_last_update_login      CONSTANT NUMBER := fnd_global.login_id;        -- LAST_UPDATE_LOGIN
  cn_request_id             CONSTANT NUMBER := fnd_global.conc_request_id; -- REQUEST_ID
  cn_program_application_id CONSTANT NUMBER := fnd_global.prog_appl_id;    -- PROGRAM_APPLICATION_ID
  cn_program_id             CONSTANT NUMBER := fnd_global.conc_program_id; -- PROGRAM_ID
  cd_program_update_date    CONSTANT DATE   := SYSDATE;                    -- PROGRAM_UPDATE_DATE
  --
  cv_msg_part CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont CONSTANT VARCHAR2(3) := '.';
  --
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
  gn_target_cnt    NUMBER; -- �Ώی���
  gn_normal_cnt    NUMBER; -- ���팏��
  gn_error_cnt     NUMBER; -- �G���[����
  gn_warn_cnt      NUMBER; -- �X�L�b�v����
  --
  --################################  �Œ蕔 END   ##################################
  --
  --##########################  �Œ苤�ʗ�O�錾�� START  ###########################
  --
  --*** ���������ʗ�O ***
  global_process_expt EXCEPTION;
  --
  --*** ���ʊ֐���O ***
  global_api_expt           EXCEPTION;
  --
  --*** ���ʊ֐�OTHERS��O ***
  global_api_others_expt    EXCEPTION;
  --
  PRAGMA EXCEPTION_INIT(global_api_others_expt,-20000);
  --
  --################################  �Œ蕔 END   ##################################
  --
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name              CONSTANT VARCHAR2(100) := 'XXCSO020A03C';  -- �p�b�P�[�W��
  cv_sales_appl_short_name CONSTANT VARCHAR2(5)   := 'XXCSO';         -- �c�Ɨp�A�v���P�[�V�����Z�k��
  cv_com_appl_short_name   CONSTANT VARCHAR2(5)   := 'XXCCP';         -- ���ʗp�A�v���P�[�V�����Z�k��
  cv_proc_type_create      CONSTANT VARCHAR2(1)   := 'C';             -- �o�^����
  cv_proc_type_update      CONSTANT VARCHAR2(1)   := 'U';             -- �X�V����
  cv_proc_type_outside     CONSTANT VARCHAR2(1)   := 'O';             -- �����ΏۊO
  cv_flag_yes              CONSTANT VARCHAR2(1)   := 'Y';
  cv_flag_no               CONSTANT VARCHAR2(1)   := 'N';
  cn_number_one            CONSTANT NUMBER        := 1;
  cv_customer_status       CONSTANT VARCHAR2(2)   := '25';            -- �ڋq�X�e�[�^�X
  cv_customer_class_code   CONSTANT VARCHAR2(2)   := '10';            -- �ڋq�敪
  --
  -- ���b�Z�[�W�R�[�h
  cv_tkn_number_01 CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00382'; -- ���̓p�����[�^�`�F�b�N�G���[
  cv_tkn_number_02 CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00014'; -- �v���t�@�C���擾�G���[
  cv_tkn_number_03 CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00323'; -- �f�[�^���݃G���[
  cv_tkn_number_04 CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00324'; -- �f�[�^���o����O�G���[
  cv_tkn_number_05 CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00387'; -- �r�o�ꌈ�ڋq���s�����G���[
  cv_tkn_number_06 CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00388'; -- �ڋq�}�X�^�o�^���G���[
  cv_tkn_number_07 CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00389'; -- �ڋq�}�X�^�X�V���G���[
  cv_tkn_number_08 CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00383'; -- �V�[�P���X�擾�G���[
  cv_tkn_number_09 CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00042'; -- �c�a�o�^�E�X�V�G���[
  cv_tkn_number_10 CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00386'; -- ���b�N���s�G���[
  --
  -- �g�[�N���R�[�h
  cv_tkn_errmsg   CONSTANT VARCHAR2(20) := 'ERRMSG';
  cv_tkn_prof_nm  CONSTANT VARCHAR2(20) := 'PROF_NAME';
  cv_tkn_item     CONSTANT VARCHAR2(20) := 'ITEM';
  cv_tkn_table    CONSTANT VARCHAR2(20) := 'TABLE';
  cv_tkn_key      CONSTANT VARCHAR2(20) := 'KEY';
  cv_tkn_err_msg  CONSTANT VARCHAR2(20) := 'ERR_MSG';
  cv_tkn_api_name CONSTANT VARCHAR2(20) := 'API_NAME';
  cv_tkn_api_msg  CONSTANT VARCHAR2(20) := 'API_MSG';
  cv_tkn_sequence CONSTANT VARCHAR2(20) := 'SEQUENCE';
  cv_tkn_action   CONSTANT VARCHAR2(20) := 'ACTION';
  --
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  --
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  -- �}�X�^�o�^���p�\����
  TYPE g_mst_regist_info_rtype IS RECORD(
    -- �r�o�ꌈ�w�b�_���
     application_code xxcso_sp_decision_headers.application_code%TYPE -- �\���҃R�[�h
    ,app_base_code    xxcso_sp_decision_headers.app_base_code%TYPE    -- �\�����_�R�[�h
    -- �r�o�ꌈ�ڋq���
    ,customer_id                  xxcso_sp_decision_custs.customer_id%TYPE                  -- �ڋq�h�c
    ,party_name                   xxcso_sp_decision_custs.party_name%TYPE                   -- �ڋq��
    ,party_name_alt               xxcso_sp_decision_custs.party_name_alt%TYPE               -- �ڋq���J�i
    ,employee_number              xxcso_sp_decision_custs.employee_number%TYPE              -- �Ј���
    ,representative_name          xxcso_sp_decision_custs.representative_name%TYPE          -- ��\�Җ�
    ,postal_code                  xxcso_sp_decision_custs.postal_code%TYPE                  -- �X�֔ԍ�
    ,state                        xxcso_sp_decision_custs.state%TYPE                        -- �s���{��
    ,city                         xxcso_sp_decision_custs.city%TYPE                         -- �s�E��
    ,address1                     xxcso_sp_decision_custs.address1%TYPE                     -- �Z���P
    ,address2                     xxcso_sp_decision_custs.address2%TYPE                     -- �Z���Q
    ,address_lines_phonetic       xxcso_sp_decision_custs.address_lines_phonetic%TYPE       -- �d�b�ԍ�
    ,business_condition_type      xxcso_sp_decision_custs.business_condition_type%TYPE      -- �Ƒԁi�����ށj
    ,business_type                xxcso_sp_decision_custs.business_type%TYPE                -- �Ǝ�
    ,publish_base_code            xxcso_sp_decision_custs.publish_base_code%TYPE            -- �S�����_�R�[�h
    ,install_name                 xxcso_sp_decision_custs.install_name%TYPE                 -- �ݒu�於
    ,install_location             xxcso_sp_decision_custs.install_location%TYPE             -- �ݒu���P�[�V����
    ,external_reference_opcl_type xxcso_sp_decision_custs.external_reference_opcl_type%TYPE -- �����I�[�v���E�N���[�Y�敪
    ,new_customer_flag            xxcso_sp_decision_custs.new_customer_flag%TYPE            -- �V�K�ڋq�t���O
  );
  --
  /**********************************************************************************
   * Procedure Name   : start_proc
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE start_proc(
     it_sp_decision_header_id IN         xxcso_sp_decision_headers.sp_decision_header_id%TYPE -- �r�o�ꌈ�w�b�_�h�c
    ,ot_mst_regist_info_rec   OUT NOCOPY g_mst_regist_info_rtype                              -- �}�X�^�o�^���
    ,ov_errbuf                OUT NOCOPY VARCHAR2                                             -- �G���[�E���b�Z�[�W --# �Œ� #
    ,ov_retcode               OUT NOCOPY VARCHAR2                                             -- ���^�[���E�R�[�h   --# �Œ� #
    ,ov_errmsg                OUT NOCOPY VARCHAR2                                             -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  )
  IS
    --
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name CONSTANT VARCHAR2(100) := 'start_proc'; -- �v���V�[�W����
    --
    --#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
    --
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    --
    --###########################  �Œ蕔 END   ####################################
    --
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_nm_sp_decision_header_id CONSTANT VARCHAR2(30)                          := '�r�o�ꌈ�w�b�_�h�c';        -- �r�o�ꌈ�w�b�_�h�c�a��
    ct_lookup_type_cust_status  CONSTANT fnd_lookup_values_vl.lookup_type%TYPE := 'XXCMM_CUST_KOKYAKU_STATUS'; -- �ڋq�X�e�[�^�X
    ct_lookup_type_cust_type    CONSTANT fnd_lookup_values_vl.lookup_type%TYPE := 'CUSTOMER CLASS';            -- �ڋq�敪
    cv_msg_const1               CONSTANT VARCHAR2(100)                         := '�^�C�v�F';
    cv_msg_const2               CONSTANT VARCHAR2(100)                         := '�A�R�[�h�F';
    cv_nm_table                 CONSTANT VARCHAR2(100)                         := '�N�C�b�N�R�[�h�r���[';
    --
    -- �v���t�@�C���I�v�V������
    cv_profile_option_name1 CONSTANT VARCHAR2(40) := 'XXCSO1_CUST_STATUS_SP_DECISION';
    cv_profile_option_name2 CONSTANT VARCHAR2(40) := 'XXCSO1_CUST_TYPE_CUSTOMER';
    --
    -- *** ���[�J���ϐ� ***
    lt_cust_status_profile fnd_profile_option_values.profile_option_value%TYPE; -- �v���t�@�C���I�v�V�����l�i�ڋq�X�e�[�^�X�j
    lt_cust_type_profile   fnd_profile_option_values.profile_option_value%TYPE; -- �v���t�@�C���I�v�V�����l�i�ڋq�敪�j
    --
  BEGIN
    --
    --##################  �Œ�X�e�[�^�X�������� START   ###################
    --
    ov_retcode := cv_status_normal;
    --
    --###########################  �Œ蕔 END   ############################
    --
    ot_mst_regist_info_rec := NULL;
    --
    -- ======================
    -- ���̓p�����[�^�`�F�b�N
    -- ======================
    IF (it_sp_decision_header_id IS NULL) THEN
      -- �r�o�ꌈ�w�b�_�h�c�������͂̏ꍇ�G���[
      lv_errbuf := xxccp_common_pkg.get_msg(
                      iv_application  => cv_sales_appl_short_name    -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_tkn_number_01            -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_item                 -- �g�[�N�R�[�h1
                     ,iv_token_value1 => cv_nm_sp_decision_header_id -- �g�[�N���l1
                   );
      --
      RAISE global_api_expt;
      --
    END IF;
    --
  EXCEPTION
    --
    --#################################  �Œ��O������ START   ####################################
    --
    WHEN global_api_expt THEN
      -- *** ���ʊ֐���O�n���h�� ***
      ov_errbuf  := SUBSTRB(cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000);
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
    WHEN global_api_others_expt THEN
      -- *** ���ʊ֐�OTHERS��O�n���h�� ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
    WHEN OTHERS THEN
      -- *** OTHERS��O�n���h�� ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
    --
    --#####################################  �Œ蕔 END   ##########################################
    --
  END start_proc;
  --
  --
  /**********************************************************************************
   * Procedure Name   : get_install_at_info
   * Description      :  �ݒu���񒊏o(A-2)
   ***********************************************************************************/
  PROCEDURE get_install_at_info(
     it_sp_decision_header_id IN            xxcso_sp_decision_headers.sp_decision_header_id%TYPE -- �r�o�ꌈ�w�b�_�h�c
    ,iot_mst_regist_info_rec  IN OUT NOCOPY g_mst_regist_info_rtype                              -- �}�X�^�o�^���
    ,ov_proc_type             OUT    NOCOPY VARCHAR2                                             -- �����敪
    ,ov_errbuf                OUT    NOCOPY VARCHAR2                                             -- �G���[�E���b�Z�[�W --# �Œ� #
    ,ov_retcode               OUT    NOCOPY VARCHAR2                                             -- ���^�[���E�R�[�h   --# �Œ� #
    ,ov_errmsg                OUT    NOCOPY VARCHAR2                                             -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  )
  IS
    --
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name CONSTANT VARCHAR2(100) := 'get_install_at_info'; -- �v���V�[�W����
    --
    --#######################  �Œ胍�[�J���ϐ��錾�� START   ######################
    --
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    --
    --###########################  �Œ蕔 END   ####################################
    --
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    -- �g�[�N���p�萔
    cv_tkn_value_sp_dec_head    CONSTANT VARCHAR2(30) := '�r�o�ꌈ�w�b�_�e�[�u��';         -- �r�o�ꌈ�w�b�_�e�[�u���a��
    cv_tkn_value_sp_dec_custs   CONSTANT VARCHAR2(30) := '�r�o�ꌈ�ڋq�e�[�u���i�ݒu��j'; -- �r�o�ꌈ�ڋq�e�[�u���a��
    cv_tkn_value_sp_dec_head_id CONSTANT VARCHAR2(30) := '�r�o�ꌈ�w�b�_�h�c';             -- �r�o�ꌈ�w�b�_�h�c�a��
    --
    ct_sp_dec_cust_class_install CONSTANT xxcso_sp_decision_custs.sp_decision_customer_class%TYPE := '1'; -- �r�o�ꌈ�ڋq�敪=�ݒu��
    --
    -- *** ���[�J���ϐ� ***
    lv_proc_type VARCHAR2(1); -- �����敪
    --
  BEGIN
    --
    --##################  �Œ�X�e�[�^�X�������� START   ###################
    --
    ov_retcode := cv_status_normal;
    --
    --###########################  �Œ蕔 END   ############################
    --
    -- ==============
    -- �ϐ�����������
    -- ==============
    lv_proc_type := NULL;
    --
    -- ============================
    -- �ݒu����i�w�b�_�j�擾����
    -- ============================
    BEGIN
      SELECT xsd.application_code application_code -- �\���҃R�[�h
            ,xsd.app_base_code    app_base_code    -- �\�����_�R�[�h
      INTO   iot_mst_regist_info_rec.application_code
            ,iot_mst_regist_info_rec.app_base_code
      FROM   xxcso_sp_decision_headers xsd -- �r�o�ꌈ�w�b�_�e�[�u��
      WHERE  xsd.sp_decision_header_id = it_sp_decision_header_id
      ;
      --
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- �f�[�^�����݂��Ȃ��ꍇ
        lv_errbuf := xxccp_common_pkg.get_msg(
                        iv_application  => cv_sales_appl_short_name  -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_03          -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_item               -- �g�[�N���R�[�h1
                       ,iv_token_value1 => cv_tkn_value_sp_dec_head_id ||
                                           cv_msg_part                 ||
                                           it_sp_decision_header_id  -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_table              -- �g�[�N���R�[�h2
                       ,iv_token_value2 => cv_tkn_value_sp_dec_head  -- �g�[�N���l2
                    );
        --
        RAISE global_api_expt;
        --
      WHEN OTHERS THEN
        -- ���̑��̗�O�̏ꍇ
        lv_errbuf := xxccp_common_pkg.get_msg(
                        iv_application  => cv_sales_appl_short_name -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_04         -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_table             -- �g�[�N���R�[�h1
                       ,iv_token_value1 => cv_tkn_value_sp_dec_head -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_key               -- �g�[�N���R�[�h2
                       ,iv_token_value2 => it_sp_decision_header_id -- �g�[�N���l2
                       ,iv_token_name3  => cv_tkn_err_msg           -- �g�[�N���R�[�h3
                       ,iv_token_value3 => SQLERRM                  -- �g�[�N���l3
                    );
        --
        RAISE global_api_expt;
        --
    END;
    --
    -- ==========================
    -- �ݒu����i�ڋq�j�擾����
    -- ==========================
    BEGIN
      SELECT xsd.customer_id                  customer_id                  -- �ڋq�h�c
            ,xsd.party_name                   party_name                   -- �ڋq��
            ,xsd.party_name_alt               party_name_alt               -- �ڋq���J�i
            ,xsd.employee_number              employee_number              -- �Ј���
            ,xsd.postal_code                  postal_code                  -- �X�֔ԍ�
            ,xsd.state                        state                        -- �s���{��
            ,xsd.city                         city                         -- �s�E��
            ,xsd.address1                     address1                     -- �Z���P
            ,xsd.address2                     address2                     -- �Z���Q
            ,xsd.address_lines_phonetic       address_lines_phonetic       -- �d�b�ԍ�
            ,xsd.business_condition_type      business_condition_type      -- �Ƒԁi�����ށj
            ,xsd.business_type                business_type                -- �Ǝ�
            ,xsd.publish_base_code            publish_base_code            -- �S�����_�R�[�h
            ,xsd.install_name                 install_name                 -- �ݒu�於
            ,xsd.install_location             install_location             -- �ݒu���P�[�V����
            ,xsd.external_reference_opcl_type external_reference_opcl_type -- �����I�[�v���E�N���[�Y�敪
            ,xsd.new_customer_flag            new_customer_flag            -- �V�K�ڋq�t���O
      INTO   iot_mst_regist_info_rec.customer_id
            ,iot_mst_regist_info_rec.party_name
            ,iot_mst_regist_info_rec.party_name_alt
            ,iot_mst_regist_info_rec.employee_number
            ,iot_mst_regist_info_rec.postal_code
            ,iot_mst_regist_info_rec.state
            ,iot_mst_regist_info_rec.city
            ,iot_mst_regist_info_rec.address1
            ,iot_mst_regist_info_rec.address2
            ,iot_mst_regist_info_rec.address_lines_phonetic
            ,iot_mst_regist_info_rec.business_condition_type
            ,iot_mst_regist_info_rec.business_type
            ,iot_mst_regist_info_rec.publish_base_code
            ,iot_mst_regist_info_rec.install_name
            ,iot_mst_regist_info_rec.install_location
            ,iot_mst_regist_info_rec.external_reference_opcl_type
            ,iot_mst_regist_info_rec.new_customer_flag
      FROM   xxcso_sp_decision_custs xsd -- �r�o�ꌈ�ڋq�e�[�u��
      WHERE  xsd.sp_decision_header_id      = it_sp_decision_header_id
      AND    xsd.sp_decision_customer_class = ct_sp_dec_cust_class_install
      ;
      --
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- �f�[�^�����݂��Ȃ��ꍇ
        lv_errbuf := xxccp_common_pkg.get_msg(
                        iv_application  => cv_sales_appl_short_name  -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_03          -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_item               -- �g�[�N���R�[�h1
                       ,iv_token_value1 => cv_tkn_value_sp_dec_head_id ||
                                           cv_msg_part                 ||
                                           it_sp_decision_header_id  -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_table              -- �g�[�N���R�[�h2
                       ,iv_token_value2 => cv_tkn_value_sp_dec_custs -- �g�[�N���l2
                    );
        --
        RAISE global_api_expt;
        --
      WHEN OTHERS THEN
        -- ���̑��̗�O�̏ꍇ
        lv_errbuf := xxccp_common_pkg.get_msg(
                        iv_application  => cv_sales_appl_short_name  -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_04          -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_table              -- �g�[�N���R�[�h1
                       ,iv_token_value1 => cv_tkn_value_sp_dec_custs -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_key                -- �g�[�N���R�[�h2
                       ,iv_token_value2 => it_sp_decision_header_id  -- �g�[�N���l2
                       ,iv_token_name3  => cv_tkn_err_msg            -- �g�[�N���R�[�h3
                       ,iv_token_value3 => SQLERRM                   -- �g�[�N���l3
                    );
        --
        RAISE global_api_expt;
        --
    END;
    --
    -- ============
    -- �������@����
    -- ============
    IF (iot_mst_regist_info_rec.customer_id IS NULL) THEN
      -- �ڋq�h�c��NULL�̏ꍇ
      IF (iot_mst_regist_info_rec.new_customer_flag = cv_flag_yes) THEN
        -- �V�K�ڋq�t���O��Y�̏ꍇ
        lv_proc_type := cv_proc_type_create;
        --
      ELSE
        -- �V�K�ڋq�t���O��Y�ȊO�̏ꍇ�̓G���[
        lv_errbuf := xxccp_common_pkg.get_msg(
                        iv_application  => cv_sales_appl_short_name -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_05         -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_key               -- �g�[�N���R�[�h1
                       ,iv_token_value1 => it_sp_decision_header_id -- �g�[�N���l1
                    );
        --
        RAISE global_api_expt;
        --
      END IF;
      --
    ELSIF (iot_mst_regist_info_rec.customer_id IS NOT NULL) THEN
      -- �ڋq�h�c��NOT NULL�̏ꍇ
      IF (iot_mst_regist_info_rec.new_customer_flag = cv_flag_yes) THEN
        -- �V�K�ڋq�t���O��Y�̏ꍇ
        lv_proc_type := cv_proc_type_update;
        --
      ELSE
        -- �V�K�ڋq�t���O��Y�ȊO�̏ꍇ
        lv_proc_type := cv_proc_type_outside;
        --
      END IF;
      --
    END IF;
    --
    ov_proc_type := lv_proc_type;
    --
  EXCEPTION
    --
    --#################################  �Œ��O������ START   ####################################
    --
    WHEN global_api_expt THEN
      -- *** ���ʊ֐���O�n���h�� ***
      ov_errbuf  := SUBSTRB(cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000);
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
    WHEN global_api_others_expt THEN
      -- *** ���ʊ֐�OTHERS��O�n���h�� ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
    WHEN OTHERS THEN
      -- *** OTHERS��O�n���h�� ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
    --
    --#####################################  �Œ蕔 END   ##########################################
    --
  END get_install_at_info;
  --
  --
  /**********************************************************************************
   * Procedure Name   : regist_party
   * Description      : �p�[�e�B�}�X�^�o�^�X�V(A-3)
   ***********************************************************************************/
  PROCEDURE regist_party(
     iv_proc_type           IN         VARCHAR2                 -- �����敪
    ,it_mst_regist_info_rec IN         g_mst_regist_info_rtype  -- �}�X�^�o�^���
    ,ot_party_id            OUT NOCOPY hz_parties.party_id%TYPE -- �p�[�e�B�h�c
    ,ov_errbuf              OUT NOCOPY VARCHAR2                 -- �G���[�E���b�Z�[�W --# �Œ� #
    ,ov_retcode             OUT NOCOPY VARCHAR2                 -- ���^�[���E�R�[�h   --# �Œ� #
    ,ov_errmsg              OUT NOCOPY VARCHAR2                 -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  )
  IS
    --
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name CONSTANT VARCHAR2(100) := 'regist_party'; -- �v���V�[�W����
    --
    --#######################  �Œ胍�[�J���ϐ��錾�� START   ######################
    --
    lv_errbuf  VARCHAR2(5000); -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);    -- ���^�[���E�R�[�h
    --
    --###########################  �Œ蕔 END   ####################################
    --
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    --
    -- �g�[�N���p�萔
    cv_tkn_item_name          CONSTANT VARCHAR2(30) := '�ݒu��h�c�F';
    cv_tkn_table_name         CONSTANT VARCHAR2(30) := '�p�[�e�B�}�X�^';
    cv_tkn_value_party_create CONSTANT VARCHAR2(30) := '�p�[�e�B�}�X�^�o�^';
    cv_tkn_value_party_update CONSTANT VARCHAR2(30) := '�p�[�e�B�}�X�^�X�V';
    --
    -- *** ���[�J���ϐ� ***
    -- �p�[�e�B�}�X�^�o�^�`�o�h�p�ϐ�
    lt_organization_rec      hz_party_v2pub.organization_rec_type;
    lv_return_status         VARCHAR2(1);
    ln_msg_count             NUMBER;
    lv_msg_data              VARCHAR2(5000);
    lt_party_id              hz_parties.party_id%TYPE;
    lt_party_number          hz_parties.party_number%TYPE;
    lt_profile_id            hz_organization_profiles.organization_profile_id%TYPE;
    lt_object_version_number hz_parties.object_version_number%TYPE;
    --
    -- *** ���[�J����O ***
    --
  BEGIN
    --
    --##################  �Œ�X�e�[�^�X�������� START   ###################
    --
    ov_retcode := cv_status_normal;
    --
    --###########################  �Œ蕔 END   ############################
    --
    IF (iv_proc_type = cv_proc_type_create) THEN
      -- �����敪��C�̏ꍇ
      -- ==================
      -- �p�[�e�B�}�X�^�V�K
      -- ==================
      lt_organization_rec.organization_name          := SUBSTRB(it_mst_regist_info_rec.party_name, 1, 360);               -- �ڋq��
      lt_organization_rec.organization_name_phonetic := SUBSTRB(it_mst_regist_info_rec.party_name_alt, 1, 320);           -- �ڋq���J�i
      lt_organization_rec.duns_number_c              := SUBSTRB(cv_customer_status, 1, 30);                               -- �ڋq�X�e�[�^�X
      lt_organization_rec.created_by_module          := SUBSTRB(cv_pkg_name, 1, 150);
      lt_organization_rec.party_rec.attribute2       := SUBSTRB(TO_CHAR(it_mst_regist_info_rec.employee_number), 1, 150); -- �Ј���
      --
      hz_party_v2pub.create_organization(
         p_init_msg_list    => fnd_api.g_true
        ,p_organization_rec => lt_organization_rec
        ,x_return_status    => lv_return_status
        ,x_msg_count        => ln_msg_count
        ,x_msg_data         => lv_msg_data
        ,x_party_id         => lt_party_id
        ,x_party_number     => lt_party_number
        ,x_profile_id       => lt_profile_id
      );
      --
      IF (lv_return_status <> fnd_api.g_ret_sts_success) THEN
        -- ���^�[���R�[�h��S�ȊO�̏ꍇ
        IF (ln_msg_count > 1) THEN
          lv_msg_data := fnd_msg_pub.get(
                            p_msg_index => cn_number_one
                           ,p_encoded   => fnd_api.g_true
                         );
          --
        END IF;
        --
        lv_errbuf := xxccp_common_pkg.get_msg(
                        iv_application  => cv_sales_appl_short_name  -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_06          -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_api_name           -- �g�[�N���R�[�h1
                       ,iv_token_value1 => cv_tkn_value_party_create -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_api_msg            -- �g�[�N���R�[�h2
                       ,iv_token_value2 => lv_msg_data               -- �g�[�N���l2
                    );
        --
        RAISE global_api_expt;
        --
      END IF;
      --
    ELSIF (iv_proc_type = cv_proc_type_update) THEN
      -- �����敪��U�̏ꍇ
      -- ==================
      -- �p�[�e�B�}�X�^�X�V
      -- ==================
      -- �p�[�e�B���擾
      BEGIN
        SELECT hpa.party_id              party_id              -- �p�[�e�B�h�c
              ,hpa.object_version_number object_version_number -- �I�u�W�F�N�g�o�[�W�����ԍ�
        INTO   lt_party_id
              ,lt_object_version_number
        FROM   hz_parties       hpa -- �p�[�e�B�}�X�^
              ,hz_cust_accounts hca -- �ڋq�}�X�^
        WHERE  hpa.party_id        = hca.party_id
        AND    hca.cust_account_id = it_mst_regist_info_rec.customer_id
        ;
        --
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          -- �f�[�^�����݂��Ȃ��ꍇ
          lv_errbuf := xxccp_common_pkg.get_msg(
                          iv_application  => cv_sales_appl_short_name           -- �A�v���P�[�V�����Z�k��
                         ,iv_name         => cv_tkn_number_03                   -- ���b�Z�[�W�R�[�h
                         ,iv_token_name1  => cv_tkn_item                        -- �g�[�N���R�[�h1
                         ,iv_token_value1 => cv_tkn_item_name ||
                                             it_mst_regist_info_rec.customer_id -- �g�[�N���l1
                         ,iv_token_name2  => cv_tkn_table                       -- �g�[�N���R�[�h2
                         ,iv_token_value2 => cv_tkn_table_name                  -- �g�[�N���l2
                      );
          --
          RAISE global_api_expt;
          --
        WHEN OTHERS THEN
          -- ���̑��̃G���[�̏ꍇ
          lv_errbuf := xxccp_common_pkg.get_msg(
                          iv_application  => cv_sales_appl_short_name           -- �A�v���P�[�V�����Z�k��
                         ,iv_name         => cv_tkn_number_04                   -- ���b�Z�[�W�R�[�h
                         ,iv_token_name1  => cv_tkn_table                       -- �g�[�N���R�[�h1
                         ,iv_token_value1 => cv_tkn_table_name                  -- �g�[�N���l1
                         ,iv_token_name2  => cv_tkn_key                         -- �g�[�N���R�[�h2
                         ,iv_token_value2 => it_mst_regist_info_rec.customer_id -- �g�[�N���l2
                         ,iv_token_name3  => cv_tkn_err_msg                     -- �g�[�N���R�[�h3
                         ,iv_token_value3 => SQLERRM                            -- �g�[�N���l3
                      );
          --
          RAISE global_api_expt;
          --
      END;
      --
      lt_organization_rec.organization_name          := SUBSTRB(it_mst_regist_info_rec.party_name, 1, 360);               -- �ڋq��
      lt_organization_rec.organization_name_phonetic := SUBSTRB(it_mst_regist_info_rec.party_name_alt, 1, 320);           -- �ڋq���J�i
      lt_organization_rec.duns_number_c              := SUBSTRB(cv_customer_status, 1, 30);                               -- �ڋq�X�e�[�^�X
      lt_organization_rec.party_rec.attribute2       := SUBSTRB(TO_CHAR(it_mst_regist_info_rec.employee_number), 1, 150); -- �Ј���
      lt_organization_rec.party_rec.party_id         := lt_party_id;                                                      -- �p�[�e�B�h�c
      --
      hz_party_v2pub.update_organization(
         p_init_msg_list               => fnd_api.g_true
        ,p_organization_rec            => lt_organization_rec
        ,p_party_object_version_number => lt_object_version_number
        ,x_profile_id                  => lt_profile_id
        ,x_return_status               => lv_return_status
        ,x_msg_count                   => ln_msg_count
        ,x_msg_data                    => lv_msg_data
      );
      --
      IF (lv_return_status <> fnd_api.g_ret_sts_success) THEN
        -- ���^�[���R�[�h��S�ȊO�̏ꍇ
        IF (ln_msg_count > 1) THEN
          lv_msg_data := fnd_msg_pub.get(
                            p_msg_index => cn_number_one
                           ,p_encoded   => fnd_api.g_true
                         );
          --
        END IF;
        --
        lv_errbuf := xxccp_common_pkg.get_msg(
                        iv_application  => cv_sales_appl_short_name  -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_07          -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_api_name           -- �g�[�N���R�[�h1
                       ,iv_token_value1 => cv_tkn_value_party_update -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_api_msg            -- �g�[�N���R�[�h2
                       ,iv_token_value2 => lv_msg_data               -- �g�[�N���l2
                    );
        --
        RAISE global_api_expt;
        --
      END IF;
      --
    END IF;
    --
    ot_party_id := lt_party_id;
    --
  EXCEPTION
    --
    --#################################  �Œ��O������ START   ####################################
    --
    WHEN global_api_expt THEN
      -- *** ���ʊ֐���O�n���h�� ***
      ov_errbuf  := SUBSTRB(cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000);
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
    WHEN global_api_others_expt THEN
      -- *** ���ʊ֐�OTHERS��O�n���h�� ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
    WHEN OTHERS THEN
     -- *** OTHERS��O�n���h�� ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
    --
    --#####################################  �Œ蕔 END   ##########################################
    --
  END regist_party;
  --
  --
  /**********************************************************************************
   * Procedure Name   : regist_locat_party_site
   * Description      : �ڋq���Ə��^�p�[�e�B�T�C�g�}�X�^�o�^�X�V(A-4)
   ***********************************************************************************/
  PROCEDURE regist_locat_party_site(
     iv_proc_type           IN         VARCHAR2                          -- �����敪
    ,it_mst_regist_info_rec IN         g_mst_regist_info_rtype           -- �}�X�^�o�^���
    ,it_party_id            IN         hz_parties.party_id%TYPE          -- �p�[�e�B�h�c
    ,ot_party_site_id       OUT NOCOPY hz_party_sites.party_site_id%TYPE -- �p�[�e�B�T�C�g�h�c
    ,ov_errbuf              OUT NOCOPY VARCHAR2                          -- �G���[�E���b�Z�[�W --# �Œ� #
    ,ov_retcode             OUT NOCOPY VARCHAR2                          -- ���^�[���E�R�[�h   --# �Œ� #
    ,ov_errmsg              OUT NOCOPY VARCHAR2                          -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  )
  IS
    --
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name CONSTANT VARCHAR2(100) := 'regist_locat_party_site'; -- �v���V�[�W����
    --
    --#######################  �Œ胍�[�J���ϐ��錾�� START   ######################
    --
    lv_errbuf  VARCHAR2(5000); -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);    -- ���^�[���E�R�[�h
    --
    --###########################  �Œ蕔 END   ####################################
    --
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    -- �g�[�N���p�萔
    cv_territory_short_name        CONSTANT VARCHAR2(40) := '���{';
    cv_tkn_value_item              CONSTANT VARCHAR2(40) := '���R�[�h�F���{';
    cv_tkn_value_table_name        CONSTANT VARCHAR2(40) := '�e���g���r���[';
    cv_tkn_value_location_create   CONSTANT VARCHAR2(40) := '�ڋq���Ə��}�X�^�o�^';
    cv_tkn_value_location_update   CONSTANT VARCHAR2(40) := '�ڋq���Ə��}�X�^�X�V';
    cv_tkn_value_party_site_create CONSTANT VARCHAR2(40) := '�p�[�e�B�T�C�g�}�X�^�o�^';
    cv_tkn_item_name               CONSTANT VARCHAR2(40) := '�ݒu��h�c�F';
    cv_tkn_table_name              CONSTANT VARCHAR2(40) := '�p�[�e�B�T�C�g�^�ڋq���Ə��}�X�^';
    --
    -- *** ���[�J���ϐ� ***
    -- �ڋq���Ə��}�X�^�o�^�`�o�h�p�ϐ�
    lt_location_rec          hz_location_v2pub.location_rec_type;
    lt_location_id           hz_locations.location_id%TYPE;
    lv_return_status         VARCHAR2(1);
    ln_msg_count             NUMBER;
    lv_msg_data              VARCHAR2(5000);
    lt_object_version_number hz_locations.object_version_number%TYPE;
    --
    -- �p�[�e�B�T�C�g�}�X�^�o�^�`�o�h�p�ϐ�
    lt_party_site_rec    hz_party_site_v2pub.party_site_rec_type;
    lt_party_site_id     hz_party_sites.party_site_id%TYPE;
    lt_party_site_number hz_party_sites.party_site_number%TYPE;
    --
    lt_territory_code fnd_territories_vl.territory_code%TYPE;
    --
    -- *** ���[�J����O ***
    --
  BEGIN
    --
    --##################  �Œ�X�e�[�^�X�������� START   ###################
    --
    ov_retcode := cv_status_normal;
    --
    --###########################  �Œ蕔 END   ############################
    --
    -- ���R�[�h�擾
    BEGIN
      SELECT ftv.territory_code territory_code -- �e���g���[�R�[�h
      INTO   lt_territory_code
      FROM   fnd_territories_vl ftv -- �e���g���r���[
      WHERE  ftv.territory_short_name = cv_territory_short_name
      ;
      --
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- �f�[�^�����݂��Ȃ��ꍇ
        lv_errbuf := xxccp_common_pkg.get_msg(
                        iv_application  => cv_sales_appl_short_name -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_03         -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_item              -- �g�[�N���R�[�h1
                       ,iv_token_value1 => cv_tkn_value_item        -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_table             -- �g�[�N���R�[�h2
                       ,iv_token_value2 => cv_tkn_value_table_name  -- �g�[�N���l2
                    );
        --
        RAISE global_api_expt;
        --
      WHEN OTHERS THEN
        -- ���̑��̃G���[�̏ꍇ
        lv_errbuf := xxccp_common_pkg.get_msg(
                        iv_application  => cv_sales_appl_short_name -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_04         -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_table             -- �g�[�N���R�[�h1
                       ,iv_token_value1 => cv_tkn_value_table_name  -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_key               -- �g�[�N���R�[�h2
                       ,iv_token_value2 => cv_territory_short_name  -- �g�[�N���l2
                       ,iv_token_name3  => cv_tkn_err_msg           -- �g�[�N���R�[�h3
                       ,iv_token_value3 => SQLERRM                  -- �g�[�N���l3
                    );
        --
        RAISE global_api_expt;
        --
    END;
    --
    IF (iv_proc_type = cv_proc_type_create) THEN
      -- �����敪��C�̏ꍇ
      -- ====================
      -- �ڋq���Ə��}�X�^�V�K
      -- ====================
      lt_location_rec.country                := SUBSTRB(lt_territory_code, 1, 60);                              -- ���R�[�h
      lt_location_rec.postal_code            := SUBSTRB(it_mst_regist_info_rec.postal_code, 1, 60);             -- �X�֔ԍ�
      lt_location_rec.state                  := SUBSTRB(it_mst_regist_info_rec.state, 1, 60);                   -- �s���{��
      lt_location_rec.city                   := SUBSTRB(it_mst_regist_info_rec.city, 1, 60);                    -- �s�E��
      lt_location_rec.address1               := SUBSTRB(it_mst_regist_info_rec.address1, 1, 240);               -- �Z���P
      lt_location_rec.address2               := SUBSTRB(it_mst_regist_info_rec.address2, 1, 240);               -- �Z���Q
      lt_location_rec.address_lines_phonetic := SUBSTRB(it_mst_regist_info_rec.address_lines_phonetic, 1, 560); -- �d�b�ԍ�
      lt_location_rec.created_by_module      := SUBSTRB(cv_pkg_name, 1, 150);
     --
      hz_location_v2pub.create_location(
         p_init_msg_list => fnd_api.g_true
        ,p_location_rec  => lt_location_rec
        ,x_location_id   => lt_location_id
        ,x_return_status => lv_return_status
        ,x_msg_count     => ln_msg_count
        ,x_msg_data      => lv_msg_data
      );
      --
      IF (lv_return_status <> fnd_api.g_ret_sts_success) THEN
        -- ���^�[���R�[�h��S�ȊO�̏ꍇ
        IF (ln_msg_count > 1) THEN
          lv_msg_data := fnd_msg_pub.get(
                            p_msg_index => cn_number_one
                           ,p_encoded   => fnd_api.g_true
                         );
          --
        END IF;
        --
        lv_errbuf := xxccp_common_pkg.get_msg(
                        iv_application  => cv_sales_appl_short_name     -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_06             -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_api_name              -- �g�[�N���R�[�h1
                       ,iv_token_value1 => cv_tkn_value_location_create -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_api_msg               -- �g�[�N���R�[�h2
                       ,iv_token_value2 => lv_msg_data                  -- �g�[�N���l2
                    );
        --
        RAISE global_api_expt;
        --
      END IF;
      --
      -- ========================
      -- �p�[�e�B�T�C�g�}�X�^�V�K
      -- ========================
      lt_party_site_rec.party_id          := it_party_id;    -- �p�[�e�B�h�c
      lt_party_site_rec.location_id       := lt_location_id; -- �ڋq���Ə��h�c
      lt_party_site_rec.created_by_module := SUBSTRB(cv_pkg_name, 1, 150);
      --
      hz_party_site_v2pub.create_party_site(
         p_init_msg_list     => fnd_api.g_true
        ,p_party_site_rec    => lt_party_site_rec
        ,x_party_site_id     => lt_party_site_id
        ,x_party_site_number => lt_party_site_number
        ,x_return_status     => lv_return_status
        ,x_msg_count         => ln_msg_count
        ,x_msg_data          => lv_msg_data
       );
       --
       IF (lv_return_status <> fnd_api.g_ret_sts_success) THEN
        -- ���^�[���R�[�h��S�ȊO�̏ꍇ
        IF (ln_msg_count > 1) THEN
          lv_msg_data := fnd_msg_pub.get(
                            p_msg_index => cn_number_one
                           ,p_encoded   => fnd_api.g_true
                         );
          --
        END IF;
        --
        lv_errbuf := xxccp_common_pkg.get_msg(
                        iv_application  => cv_sales_appl_short_name       -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_06               -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_api_name                -- �g�[�N���R�[�h1
                       ,iv_token_value1 => cv_tkn_value_party_site_create -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_api_msg                 -- �g�[�N���R�[�h2
                       ,iv_token_value2 => lv_msg_data                    -- �g�[�N���l2
                    );
        --
        RAISE global_api_expt;
        --
      END IF;
      --
      ot_party_site_id := lt_party_site_id;
      --
    ELSIF (iv_proc_type = cv_proc_type_update) THEN
      -- �����敪��U�̏ꍇ
      -- ====================
      -- �ڋq���Ə��}�X�^�X�V
      -- ====================
      -- �ڋq���Ə����擾
      BEGIN
        SELECT hlo.location_id           location_id           -- ���Ə��h�c
              ,hlo.object_version_number object_version_number -- �I�u�W�F�N�g�o�[�W�����ԍ�
        INTO   lt_location_id
              ,lt_object_version_number
        FROM   hz_locations   hlo -- �ڋq���Ə��}�X�^
              ,hz_party_sites hps -- �p�[�e�B�T�C�g�}�X�^
        WHERE  hps.party_id    = it_party_id
        AND    hps.location_id = hlo.location_id
        ;
        --
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          -- �f�[�^�����݂��Ȃ��ꍇ
          lv_errbuf := xxccp_common_pkg.get_msg(
                          iv_application  => cv_sales_appl_short_name           -- �A�v���P�[�V�����Z�k��
                         ,iv_name         => cv_tkn_number_03                   -- ���b�Z�[�W�R�[�h
                         ,iv_token_name1  => cv_tkn_item                        -- �g�[�N���R�[�h1
                         ,iv_token_value1 => cv_tkn_item_name ||
                                             it_mst_regist_info_rec.customer_id -- �g�[�N���l1
                         ,iv_token_name2  => cv_tkn_table                       -- �g�[�N���R�[�h2
                         ,iv_token_value2 => cv_tkn_table_name                  -- �g�[�N���l2
                      );
          --
          RAISE global_api_expt;
          --
        WHEN OTHERS THEN
          -- ���̑��̃G���[�̏ꍇ
          lv_errbuf := xxccp_common_pkg.get_msg(
                          iv_application  => cv_sales_appl_short_name           -- �A�v���P�[�V�����Z�k��
                         ,iv_name         => cv_tkn_number_04                   -- ���b�Z�[�W�R�[�h
                         ,iv_token_name1  => cv_tkn_table                       -- �g�[�N���R�[�h1
                         ,iv_token_value1 => cv_tkn_table_name                  -- �g�[�N���l1
                         ,iv_token_name2  => cv_tkn_key                         -- �g�[�N���R�[�h2
                         ,iv_token_value2 => it_mst_regist_info_rec.customer_id -- �g�[�N���l2
                         ,iv_token_name3  => cv_tkn_err_msg                     -- �g�[�N���R�[�h3
                         ,iv_token_value3 => SQLERRM                            -- �g�[�N���l3
                      );
          --
          RAISE global_api_expt;
          --
      END;
      --
      lt_location_rec.location_id            := lt_location_id;                                                 -- �ڋq���Ə��h�c
      lt_location_rec.country                := SUBSTRB(lt_territory_code, 1, 60);                              -- ���R�[�h
      lt_location_rec.postal_code            := SUBSTRB(it_mst_regist_info_rec.postal_code, 1, 60);             -- �X�֔ԍ�
      lt_location_rec.state                  := SUBSTRB(it_mst_regist_info_rec.state, 1, 60);                   -- �s���{��
      lt_location_rec.city                   := SUBSTRB(it_mst_regist_info_rec.city, 1, 60);                    -- �s�E��
      lt_location_rec.address1               := SUBSTRB(it_mst_regist_info_rec.address1, 1, 240);               -- �Z���P
      lt_location_rec.address2               := SUBSTRB(it_mst_regist_info_rec.address2, 1, 240);               -- �Z���Q
      lt_location_rec.address_lines_phonetic := SUBSTRB(it_mst_regist_info_rec.address_lines_phonetic, 1, 560); -- �d�b�ԍ�
      --
      hz_location_v2pub.update_location(
         p_init_msg_list         => fnd_api.g_true
        ,p_location_rec          => lt_location_rec
        ,p_object_version_number => lt_object_version_number
        ,x_return_status         => lv_return_status
        ,x_msg_count             => ln_msg_count
        ,x_msg_data              => lv_msg_data
      );
      --
      IF (lv_return_status <> fnd_api.g_ret_sts_success) THEN
        -- ���^�[���R�[�h��S�ȊO�̏ꍇ
        IF (ln_msg_count > 1) THEN
          lv_msg_data := fnd_msg_pub.get(
                            p_msg_index => cn_number_one
                           ,p_encoded   => fnd_api.g_true
                         );
          --
        END IF;
        --
        lv_errbuf := xxccp_common_pkg.get_msg(
                        iv_application  => cv_sales_appl_short_name     -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_07             -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_api_name              -- �g�[�N���R�[�h1
                       ,iv_token_value1 => cv_tkn_value_location_update -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_api_msg               -- �g�[�N���R�[�h2
                       ,iv_token_value2 => lv_msg_data                  -- �g�[�N���l2
                    );
        --
        RAISE global_api_expt;
        --
      END IF;
      --
    END IF;
    --
  EXCEPTION
    --
    --#################################  �Œ��O������ START   ####################################
    --
    WHEN global_api_expt THEN
      -- *** ���ʊ֐���O�n���h�� ***
      ov_errbuf  := SUBSTRB(cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000);
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
    WHEN global_api_others_expt THEN
      -- *** ���ʊ֐�OTHERS��O�n���h�� ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
    WHEN OTHERS THEN
      -- *** OTHERS��O�n���h�� ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
    --
    --#####################################  �Œ蕔 END   ##########################################
    --
  END regist_locat_party_site;
  --
  --
  /**********************************************************************************
   * Procedure Name   : regist_cust_account
   * Description      : �ڋq�}�X�^�o�^�X�V(A-5)
   ***********************************************************************************/
  PROCEDURE regist_cust_account(
     iv_proc_type           IN         VARCHAR2                              -- �����敪
    ,it_mst_regist_info_rec IN         g_mst_regist_info_rtype               -- �}�X�^�o�^���
    ,it_party_id            IN         hz_parties.party_id%TYPE              -- �p�[�e�B�h�c
    ,ot_cust_account_id     OUT NOCOPY hz_cust_accounts.cust_account_id%TYPE -- �ڋq�h�c
    ,ot_account_number      OUT NOCOPY hz_cust_accounts.account_number%TYPE  -- �ڋq�ԍ�
    ,ov_errbuf              OUT NOCOPY VARCHAR2                              -- �G���[�E���b�Z�[�W --# �Œ� #
    ,ov_retcode             OUT NOCOPY VARCHAR2                              -- ���^�[���E�R�[�h   --# �Œ� #
    ,ov_errmsg                OUT NOCOPY VARCHAR2                            -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  )
  IS
    --
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'regist_cust_account';  -- �v���O������
    --
    --#######################  �Œ胍�[�J���ϐ��錾�� START   ######################
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
    -- �g�[�N���p�萔
    cv_tkn_value_sequence       CONSTANT VARCHAR2(30) := '�ڋq�ԍ��V�[�P���X';
    cv_tkn_value_account_create CONSTANT VARCHAR2(30) := '�ڋq�}�X�^�o�^';
    cv_tkn_value_account_update CONSTANT VARCHAR2(30) := '�ڋq�}�X�^�X�V';
    cv_tkn_item_name            CONSTANT VARCHAR2(30) := '�ݒu��h�c�F';
    cv_tkn_table_name           CONSTANT VARCHAR2(30) := '�ڋq�}�X�^';
    --
    -- *** ���[�J���ϐ� ***
    -- �ڋq�}�X�^�p�`�o�h�ϐ�
    lt_cust_account_rec      hz_cust_account_v2pub.cust_account_rec_type;
    lt_organization_rec      hz_party_v2pub.organization_rec_type;
    lt_customer_profile_rec  hz_customer_profile_v2pub.customer_profile_rec_type;
    lt_create_profile_amt    VARCHAR2(1);
    lt_cust_account_id       hz_cust_accounts.cust_account_id%TYPE;
    lt_account_number        hz_cust_accounts.account_number%TYPE;
    lt_party_id              hz_parties.party_id%TYPE;
    lt_party_number          hz_parties.party_number%TYPE;
    lt_profile_id            hz_organization_profiles.organization_profile_id%TYPE;
    lv_return_status         VARCHAR2(1);
    ln_msg_count             NUMBER;
    lv_msg_data              VARCHAR2(5000);
    lt_object_version_number hz_cust_accounts.object_version_number%TYPE;
    --
  BEGIN
    --
    --##################  �Œ�X�e�[�^�X�������� START   ###################
    --
    ov_retcode := cv_status_normal;
    --
    --###########################  �Œ蕔 END   ############################
    --
    IF (iv_proc_type = cv_proc_type_create) THEN
      -- �����敪��C�̏ꍇ
      -- ====================
      -- �ڋq���Ə��}�X�^�V�K
      -- ====================
      -- �ڋq�ԍ��̎擾
      BEGIN
        SELECT hz_cust_accounts_s1.NEXTVAL account_number
        INTO   ot_account_number
        FROM   DUAL
        ;
        --
      EXCEPTION
        WHEN OTHERS THEN
          -- ���̑��̃G���[�̏ꍇ 
          lv_errbuf := xxccp_common_pkg.get_msg(
                          iv_application  => cv_sales_appl_short_name -- �A�v���P�[�V�����Z�k��
                         ,iv_name         => cv_tkn_number_08         -- ���b�Z�[�W�R�[�h
                         ,iv_token_name1  => cv_tkn_sequence          -- �g�[�N���R�[�h1
                         ,iv_token_value1 => cv_tkn_value_sequence    -- �g�[�N���l1
                         ,iv_token_name2  => cv_tkn_err_msg           -- �g�[�N���R�[�h2
                         ,iv_token_value2 => SQLERRM                  -- �g�[�N���l2
                      );
          --
          RAISE global_api_expt;
          --
      END;
      --
      lt_cust_account_rec.account_number      := SUBSTRB(ot_account_number, 1, 30);                  -- �ڋq�ԍ�
      lt_cust_account_rec.account_name        := SUBSTRB(it_mst_regist_info_rec.party_name, 1, 240); -- �A�J�E���g��
      lt_cust_account_rec.customer_class_code := SUBSTRB(cv_customer_class_code, 1, 30);             -- �ڋq�敪
      lt_organization_rec.party_rec.party_id  := it_party_id;                                        -- �p�[�e�B�h�c
      lt_cust_account_rec.created_by_module   := SUBSTRB(cv_pkg_name, 1, 150);
      --
      hz_cust_account_v2pub.create_cust_account(
         p_init_msg_list        => fnd_api.g_true
        ,p_cust_account_rec     => lt_cust_account_rec
        ,p_organization_rec     => lt_organization_rec
        ,p_customer_profile_rec => lt_customer_profile_rec
        ,p_create_profile_amt   => fnd_api.g_false
        ,x_cust_account_id      => lt_cust_account_id
        ,x_account_number       => lt_account_number
        ,x_party_id             => lt_party_id
        ,x_party_number         => lt_party_number
        ,x_profile_id           => lt_profile_id
        ,x_return_status        => lv_return_status
        ,x_msg_count            => ln_msg_count
        ,x_msg_data             => lv_msg_data
      );
      --
      IF (lv_return_status <> fnd_api.g_ret_sts_success) THEN
        -- ���^�[���R�[�h��S�ȊO�̏ꍇ
        IF (ln_msg_count > 1) THEN
          lv_msg_data := fnd_msg_pub.get(
                            p_msg_index => cn_number_one
                           ,p_encoded   => fnd_api.g_true
                         );
          --
        END IF;
        --
        lv_errbuf := xxccp_common_pkg.get_msg(
                        iv_application  => cv_sales_appl_short_name    -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_06            -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_api_name             -- �g�[�N���R�[�h1
                       ,iv_token_value1 => cv_tkn_value_account_create -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_api_msg              -- �g�[�N���R�[�h2
                       ,iv_token_value2 => lv_msg_data                 -- �g�[�N���l2
                    );
        --
        RAISE global_api_expt;
        --
      END IF;
      --
      ot_cust_account_id := lt_cust_account_id;
      --
    ELSIF (iv_proc_type = cv_proc_type_update) THEN
      -- �����敪��U�̏ꍇ
      -- ==============
      -- �ڋq�}�X�^�X�V
      -- ==============
      -- �ڋq�}�X�^���擾
      BEGIN
        SELECT hca.account_number        account_number        -- �ڋq�ԍ�
              ,hca.object_version_number object_version_number -- �I�u�W�F�N�g�o�[�W�����ԍ�
        INTO   ot_account_number
              ,lt_object_version_number
        FROM   hz_cust_accounts hca -- �ڋq�}�X�^
        WHERE  cust_account_id = it_mst_regist_info_rec.customer_id
        ;
        --
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          -- �f�[�^�����݂��Ȃ��ꍇ
          lv_errbuf := xxccp_common_pkg.get_msg(
                          iv_application  => cv_sales_appl_short_name           -- �A�v���P�[�V�����Z�k��
                         ,iv_name         => cv_tkn_number_03                   -- ���b�Z�[�W�R�[�h
                         ,iv_token_name1  => cv_tkn_item                        -- �g�[�N���R�[�h1
                         ,iv_token_value1 => cv_tkn_item_name ||
                                             it_mst_regist_info_rec.customer_id -- �g�[�N���l1
                         ,iv_token_name2  => cv_tkn_table                       -- �g�[�N���R�[�h2
                         ,iv_token_value2 => cv_tkn_table_name                  -- �g�[�N���l2
                       );
          --
          RAISE global_api_expt;
          --
        WHEN OTHERS THEN
          -- ���̑��̃G���[�̏ꍇ
          lv_errbuf := xxccp_common_pkg.get_msg(
                          iv_application  => cv_sales_appl_short_name           -- �A�v���P�[�V�����Z�k��
                         ,iv_name         => cv_tkn_number_04                   -- ���b�Z�[�W�R�[�h
                         ,iv_token_name1  => cv_tkn_table                       -- �g�[�N���R�[�h1
                         ,iv_token_value1 => cv_tkn_table_name                  -- �g�[�N���l1
                         ,iv_token_name2  => cv_tkn_key                         -- �g�[�N���R�[�h2
                         ,iv_token_value2 => it_mst_regist_info_rec.customer_id -- �g�[�N���l2
                         ,iv_token_name3  => cv_tkn_err_msg                     -- �g�[�N���R�[�h3
                         ,iv_token_value3 => SQLERRM                            -- �g�[�N���l3
                       );
          --
          RAISE global_api_expt;
          --
      END;
      --
      lt_cust_account_rec.cust_account_id     := it_mst_regist_info_rec.customer_id;                 -- �ڋq�h�c
      lt_cust_account_rec.account_name        := SUBSTRB(it_mst_regist_info_rec.party_name, 1, 240); -- �A�J�E���g��
      lt_cust_account_rec.customer_class_code := SUBSTRB(cv_customer_class_code, 1, 30);             -- �ڋq�敪
      --
      hz_cust_account_v2pub.update_cust_account(
         p_init_msg_list         => fnd_api.g_true
        ,p_cust_account_rec      => lt_cust_account_rec
        ,p_object_version_number => lt_object_version_number
        ,x_return_status         => lv_return_status
        ,x_msg_count             => ln_msg_count
        ,x_msg_data              => lv_msg_data
      );
      --
      IF (lv_return_status <> fnd_api.g_ret_sts_success) THEN
        -- ���^�[���R�[�h��S�ȊO�̏ꍇ
        IF (ln_msg_count > 1) THEN
          lv_msg_data := fnd_msg_pub.get(
                            p_msg_index => cn_number_one
                           ,p_encoded   => fnd_api.g_true
                         );
          --
        END IF;
        --
        lv_errbuf := xxccp_common_pkg.get_msg(
                        iv_application  => cv_sales_appl_short_name    -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_07            -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_api_name             -- �g�[�N���R�[�h1
                       ,iv_token_value1 => cv_tkn_value_account_update -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_api_msg              -- �g�[�N���R�[�h2
                       ,iv_token_value2 => lv_msg_data                 -- �g�[�N���l2
                    );
        --
        RAISE global_api_expt;
        --
      END IF;
      --
      ot_cust_account_id := it_mst_regist_info_rec.customer_id;
      --
    END IF;
    --
  EXCEPTION
    --
    --#################################  �Œ��O������ START   ####################################
    --
    WHEN global_api_expt THEN
      -- *** ���ʊ֐���O�n���h�� ***
      ov_errbuf  := SUBSTRB(cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000);
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
    WHEN global_api_others_expt THEN
      -- *** ���ʊ֐�OTHERS��O�n���h�� ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
    WHEN OTHERS THEN
      -- *** OTHERS��O�n���h�� ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
    --
    --#####################################  �Œ蕔 END   ##########################################
    --
  END regist_cust_account;
  --
  --
  /**********************************************************************************
   * Procedure Name   : regist_cust_acct_site
   * Description      : �ڋq���ݒn�}�X�^�o�^(A-6)
   ***********************************************************************************/
  PROCEDURE regist_cust_acct_site(
     iv_proc_type           IN         VARCHAR2                                      -- �����敪
    ,it_mst_regist_info_rec IN         g_mst_regist_info_rtype                       -- �}�X�^�o�^���
    ,it_party_site_id       IN         hz_party_sites.party_site_id%TYPE             -- �p�[�e�B�T�C�g�h�c
    ,it_cust_account_id     IN         hz_cust_accounts.cust_account_id%TYPE         -- �ڋq�h�c
    ,ot_cust_acct_site_id   OUT NOCOPY hz_cust_acct_sites_all.cust_acct_site_id%TYPE -- �ڋq���ݒn�h�c
    ,ov_errbuf              OUT NOCOPY VARCHAR2                                      -- �G���[�E���b�Z�[�W --# �Œ� #
    ,ov_retcode             OUT NOCOPY VARCHAR2                                      -- ���^�[���E�R�[�h   --# �Œ� #
    ,ov_errmsg              OUT NOCOPY VARCHAR2                                      -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  )
  IS
    --
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name CONSTANT VARCHAR2(100) := 'regist_cust_acct_site'; -- �v���V�[�W����
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
    -- �g�[�N���p�萔
    cv_tkn_value_cust_acct_site CONSTANT VARCHAR2(30) := '�ڋq���ݒn�}�X�^�o�^';
    cv_tkn_item_name            CONSTANT VARCHAR2(30) := '�ݒu��h�c�F';
    cv_tkn_table_name           CONSTANT VARCHAR2(30) := '�ڋq���ݒn�}�X�^';
   --
    -- *** ���[�J���ϐ� ***
    -- �ڋq�}�X�^�p�`�o�h�ϐ�
    lt_cust_acct_site_rec hz_cust_account_site_v2pub.cust_acct_site_rec_type;
    lt_cust_acct_site_id  hz_cust_acct_sites_all.cust_acct_site_id%TYPE;
    lv_return_status      VARCHAR2(1);
    ln_msg_count          NUMBER;
    lv_msg_data           VARCHAR2(5000);
    --
  BEGIN
    --
    --##################  �Œ�X�e�[�^�X�������� START   ###################
    --
    ov_retcode := cv_status_normal;
    --
    --###########################  �Œ蕔 END   ############################
    --
    IF (iv_proc_type = cv_proc_type_create) THEN
      -- �����敪��C�̏ꍇ
      -- ====================
      -- �ڋq���ݒn�}�X�^�V�K
      -- ====================
      lt_cust_acct_site_rec.party_site_id     := it_party_site_id;   -- �p�[�e�B�T�C�g�h�c
      lt_cust_acct_site_rec.cust_account_id   := it_cust_account_id; -- �ڋq�h�c
      lt_cust_acct_site_rec.created_by_module := SUBSTRB(cv_pkg_name, 1, 150);
      --
      hz_cust_account_site_v2pub.create_cust_acct_site(
         p_init_msg_list      => fnd_api.g_true
        ,p_cust_acct_site_rec => lt_cust_acct_site_rec
        ,x_cust_acct_site_id  => lt_cust_acct_site_id
        ,x_return_status      => lv_return_status
        ,x_msg_count          => ln_msg_count
        ,x_msg_data           => lv_msg_data
      );
      --
      IF (lv_return_status <> fnd_api.g_ret_sts_success) THEN
        -- ���^�[���R�[�h��S�ȊO�̏ꍇ
        IF (ln_msg_count > 1) THEN
          lv_msg_data := fnd_msg_pub.get(
                            p_msg_index => cn_number_one
                           ,p_encoded   => fnd_api.g_true
                         );
          --
        END IF;
        --
        lv_errbuf := xxccp_common_pkg.get_msg(
                        iv_application  => cv_sales_appl_short_name    -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_06            -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_api_name             -- �g�[�N���R�[�h1
                       ,iv_token_value1 => cv_tkn_value_cust_acct_site -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_api_msg              -- �g�[�N���R�[�h2
                       ,iv_token_value2 => lv_msg_data                 -- �g�[�N���l2
                    );
        --
        RAISE global_api_expt;
        --
      END IF;
      --
    ELSE
      -- �����敪��C�ȊO�̏ꍇ
      BEGIN
        SELECT hca.cust_acct_site_id cust_acct_site_id -- �ڋq���ݒn�h�c
        INTO   lt_cust_acct_site_id
        FROM   hz_cust_acct_sites hca -- �ڋq���ݒn�}�X�^�r���[
        WHERE  cust_account_id = it_cust_account_id
        ;
        --
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          -- �f�[�^�����݂��Ȃ��ꍇ
          lv_errbuf := xxccp_common_pkg.get_msg(
                          iv_application  => cv_sales_appl_short_name -- �A�v���P�[�V�����Z�k��
                         ,iv_name         => cv_tkn_number_03         -- ���b�Z�[�W�R�[�h
                         ,iv_token_name1  => cv_tkn_item              -- �g�[�N���R�[�h1
                         ,iv_token_value1 => cv_tkn_item_name ||
                                             cv_msg_part      ||
                                             it_cust_account_id       -- �g�[�N���l1
                         ,iv_token_name2  => cv_tkn_table             -- �g�[�N���R�[�h2
                         ,iv_token_value2 => cv_tkn_table_name        -- �g�[�N���l2
                       );
          --
          RAISE global_api_expt;
          --
        WHEN OTHERS THEN
          -- ���̑��̃G���[�̏ꍇ
          lv_errbuf := xxccp_common_pkg.get_msg(
                          iv_application  => cv_sales_appl_short_name -- �A�v���P�[�V�����Z�k��
                         ,iv_name         => cv_tkn_number_04         -- ���b�Z�[�W�R�[�h
                         ,iv_token_name1  => cv_tkn_table             -- �g�[�N���R�[�h1
                         ,iv_token_value1 => cv_tkn_table_name        -- �g�[�N���l1
                         ,iv_token_name2  => cv_tkn_key               -- �g�[�N���R�[�h2
                         ,iv_token_value2 => it_cust_account_id       -- �g�[�N���l2
                         ,iv_token_name3  => cv_tkn_err_msg           -- �g�[�N���R�[�h3
                         ,iv_token_value3 => SQLERRM                  -- �g�[�N���l3
                      );
          --
          RAISE global_api_expt;
          --
      END;
      --
    END IF;
    --
    ot_cust_acct_site_id := lt_cust_acct_site_id;
    --
  EXCEPTION
    --
    --#################################  �Œ��O������ START   ####################################
    --
    WHEN global_api_expt THEN
      -- *** ���ʊ֐���O�n���h�� ***
      ov_errbuf  := SUBSTRB(cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000);
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
    WHEN global_api_others_expt THEN
      -- *** ���ʊ֐�OTHERS��O�n���h�� ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
    WHEN OTHERS THEN
      -- *** OTHERS��O�n���h�� ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
    --
    --#####################################  �Œ蕔 END   ##########################################
    --
  END regist_cust_acct_site;
  --
  --
  /**********************************************************************************
   * Procedure Name   : regist_cust_site_use
   * Description      : �ڋq�g�p�ړI�}�X�^�o�^(A-7)
   ***********************************************************************************/
  PROCEDURE regist_cust_site_use(
     iv_proc_type           IN         VARCHAR2                                      -- �����敪
    ,it_mst_regist_info_rec IN         g_mst_regist_info_rtype                       -- �}�X�^�o�^���
    ,it_cust_acct_site_id   IN         hz_cust_acct_sites_all.cust_acct_site_id%TYPE -- �ڋq���ݒn�h�c
    ,ov_errbuf              OUT NOCOPY VARCHAR2                                      -- �G���[�E���b�Z�[�W --# �Œ� #
    ,ov_retcode             OUT NOCOPY VARCHAR2                                      -- ���^�[���E�R�[�h   --# �Œ� #
    ,ov_errmsg              OUT NOCOPY VARCHAR2                                      -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  )
  IS
    --
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name CONSTANT VARCHAR2(100) := 'regist_cust_site_use';  -- �v���V�[�W����
    --
    --#######################  �Œ胍�[�J���ϐ��錾�� START   ######################
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
    cv_ship_to_site_code CONSTANT VARCHAR2(30) := 'SHIP_TO';
    cv_bill_to_site_code CONSTANT VARCHAR2(30) := 'BILL_TO';
    --
    -- �g�[�N���p�萔
    cv_tkn_value_site_use_ship CONSTANT VARCHAR2(40) := '�ڋq�g�p�ړI�}�X�^�o�^�i�o�א�j';
    cv_tkn_value_site_use_bill CONSTANT VARCHAR2(40) := '�ڋq�g�p�ړI�}�X�^�o�^�i������j';
    --
    -- *** ���[�J���ϐ� ***
    -- �ڋq�g�p�ړI�p�`�o�h�ϐ�
    lt_cust_site_use_rec    hz_cust_account_site_v2pub.cust_site_use_rec_type;
    lt_customer_profile_rec hz_customer_profile_v2pub.customer_profile_rec_type;
    lt_site_use_id          hz_cust_site_uses_all.site_use_id%TYPE;
    lv_return_status        VARCHAR2(1);
    ln_msg_count            NUMBER;
    lv_msg_data             VARCHAR2(5000);
    --
    ln_count NUMBER;
    --
  BEGIN
    --
    --##################  �Œ�X�e�[�^�X�������� START   ###################
    --
    ov_retcode := cv_status_normal;
    --
    --###########################  �Œ蕔 END   ############################
    --
    -- �ڋq�g�p�ړI(SHIP_TO)�̑��݃`�F�b�N
    IF (iv_proc_type = cv_proc_type_update) THEN
      -- �����敪��U�̏ꍇ
      SELECT COUNT(1)
      INTO   ln_count
      FROM   hz_cust_site_uses  hcs -- �ڋq�g�p�ړI�}�X�^�r���[
            ,hz_cust_acct_sites hca -- �ڋq���ݒn�}�X�^�r���[
      WHERE  hca.cust_account_id   = it_mst_regist_info_rec.customer_id
      AND    hca.cust_acct_site_id = hcs.cust_acct_site_id
      AND    hcs.site_use_code     = cv_ship_to_site_code
      ;
      --
    END IF;
    --
    IF ((iv_proc_type = cv_proc_type_create)
      OR ((ln_count <= 0)
      AND (iv_proc_type = cv_proc_type_update)))
    THEN
      -- �����敪��C���́A�ڋq�g�p�ړI(SHIP_TO)�����݂��Ȃ��ꍇ�̏ꍇ
      -- ===============================
      -- �ڋq�g�p�ړI(SHIP_TO)�}�X�^�V�K
      -- ===============================
      -- �o�א�̓o�^
      lt_cust_site_use_rec.cust_acct_site_id := it_cust_acct_site_id; -- �ڋq���ݒn�h�c
      lt_cust_site_use_rec.site_use_code     := cv_ship_to_site_code; -- �g�p�ړI
      lt_cust_site_use_rec.created_by_module := SUBSTRB(cv_pkg_name, 1, 150);
      --
      hz_cust_account_site_v2pub.create_cust_site_use(
         p_init_msg_list        => fnd_api.g_true
        ,p_cust_site_use_rec    => lt_cust_site_use_rec
        ,p_customer_profile_rec => lt_customer_profile_rec
        ,p_create_profile       => fnd_api.g_false
        ,p_create_profile_amt   => fnd_api.g_false
        ,x_site_use_id          => lt_site_use_id
        ,x_return_status        => lv_return_status
        ,x_msg_count            => ln_msg_count
        ,x_msg_data             => lv_msg_data
      );
      --
      IF (lv_return_status <> fnd_api.g_ret_sts_success) THEN
        -- ���^�[���R�[�h��S�ȊO�̏ꍇ
        IF (ln_msg_count > 1) THEN
          lv_msg_data := fnd_msg_pub.get(
                            p_msg_index => cn_number_one
                           ,p_encoded   => fnd_api.g_true
                         );
          --
        END IF;
        --
        lv_errbuf := xxccp_common_pkg.get_msg(
                        iv_application  => cv_sales_appl_short_name   -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_06           -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_api_name            -- �g�[�N���R�[�h1
                       ,iv_token_value1 => cv_tkn_value_site_use_ship -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_api_msg             -- �g�[�N���R�[�h2
                       ,iv_token_value2 => lv_msg_data                -- �g�[�N���l2
                    );
        --
        RAISE global_api_expt;
        --
      END IF;
      --
    END IF;
    --
    -- �ڋq�g�p�ړI(BILL_TO)�̑��݃`�F�b�N
    IF (iv_proc_type = cv_proc_type_update) THEN
      -- �����敪��U�̏ꍇ
      SELECT COUNT(1)
      INTO   ln_count
      FROM   hz_cust_site_uses  hcs -- �ڋq�g�p�ړI�}�X�^�r���[
            ,hz_cust_acct_sites hca -- �ڋq���ݒn�}�X�^�r���[
      WHERE  hca.cust_account_id   = it_mst_regist_info_rec.customer_id
      AND    hca.cust_acct_site_id = hcs.cust_acct_site_id
      AND    hcs.site_use_code     = cv_bill_to_site_code
      ;
      --
    END IF;
    --
    IF ((iv_proc_type = cv_proc_type_create)
      OR ((ln_count <= 0)
      AND (iv_proc_type = cv_proc_type_update)))
    THEN
      -- �����敪��C���́A�ڋq�g�p�ړI(BILL_TO)�����݂��Ȃ��ꍇ�̏ꍇ
      -- ===============================
      -- �ڋq�g�p�ړI(BILL_TO)�}�X�^�V�K
      -- ===============================
      -- ������̓o�^
      lt_cust_site_use_rec.cust_acct_site_id := it_cust_acct_site_id; -- �ڋq���ݒn�h�c
      lt_cust_site_use_rec.site_use_code     := cv_bill_to_site_code; -- �g�p�ړI
      lt_cust_site_use_rec.created_by_module := SUBSTRB(cv_pkg_name, 1, 150);
      --
      hz_cust_account_site_v2pub.create_cust_site_use(
         p_init_msg_list        => fnd_api.g_true
        ,p_cust_site_use_rec    => lt_cust_site_use_rec
        ,p_customer_profile_rec => lt_customer_profile_rec
        ,p_create_profile       => fnd_api.g_false
        ,p_create_profile_amt   => fnd_api.g_false
        ,x_site_use_id          => lt_site_use_id
        ,x_return_status        => lv_return_status
        ,x_msg_count            => ln_msg_count
        ,x_msg_data             => lv_msg_data
      );
      --
      IF (lv_return_status <> fnd_api.g_ret_sts_success) THEN
        -- ���^�[���R�[�h��S�ȊO�̏ꍇ
        IF (ln_msg_count > 1) THEN
          lv_msg_data := fnd_msg_pub.get(
                            p_msg_index => cn_number_one
                           ,p_encoded   => fnd_api.g_true
                         );
          --
        END IF;
        --
        lv_errbuf := xxccp_common_pkg.get_msg(
                        iv_application  => cv_sales_appl_short_name   -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_06           -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_api_name            -- �g�[�N���R�[�h1
                       ,iv_token_value1 => cv_tkn_value_site_use_bill -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_api_msg             -- �g�[�N���R�[�h2
                       ,iv_token_value2 => lv_msg_data                -- �g�[�N���l2
                    );
        --
        RAISE global_api_expt;
        --
      END IF;
      --
    END IF;
    --
  EXCEPTION
    --
    --#################################  �Œ��O������ START   ####################################
    --
    WHEN global_api_expt THEN
      -- *** ���ʊ֐���O�n���h�� ***
      ov_errbuf  := SUBSTRB(cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000);
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
    WHEN global_api_others_expt THEN
      -- *** ���ʊ֐�OTHERS��O�n���h�� ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
    WHEN OTHERS THEN
      -- *** OTHERS��O�n���h�� ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
    --
    --#####################################  �Œ蕔 END   ##########################################
    --
  END regist_cust_site_use;
  --
  --
  /**********************************************************************************
   * Procedure Name   : regist_account_addon
   * Description      : �ڋq�A�h�I���}�X�^�o�^�X�V(A-8)
   ***********************************************************************************/
  PROCEDURE regist_account_addon(
     iv_proc_type           IN         VARCHAR2                              -- �����敪
    ,it_mst_regist_info_rec IN         g_mst_regist_info_rtype               -- �}�X�^�o�^���
    ,it_cust_account_id     IN         hz_cust_accounts.cust_account_id%TYPE -- �ڋq�h�c
    ,it_account_number      IN         hz_cust_accounts.account_number%TYPE  -- �ڋq�ԍ�
    ,ov_errbuf              OUT NOCOPY VARCHAR2                              -- �G���[�E���b�Z�[�W --# �Œ� #
    ,ov_retcode             OUT NOCOPY VARCHAR2                              -- ���^�[���E�R�[�h   --# �Œ� #
    ,ov_errmsg              OUT NOCOPY VARCHAR2                              -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  )
  IS
    --
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name CONSTANT VARCHAR2(100) := 'regist_account_addon';  -- �v���V�[�W����
    --
    --#######################  �Œ胍�[�J���ϐ��錾�� START   ######################
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
    -- �g�[�N���p�萔
    cv_tkn_value_action_create CONSTANT VARCHAR2(30) := '�ڋq�A�h�I���}�X�^�̓o�^';
    cv_tkn_value_action_update CONSTANT VARCHAR2(30) := '�ڋq�A�h�I���}�X�^�̍X�V';
    cv_tkn_value_table         CONSTANT VARCHAR2(30) := '�ڋq�A�h�I���}�X�^';
    --
    ct_cust_update_flag CONSTANT xxcmm_cust_accounts.cust_update_flag%TYPE := '1';
    ct_vist_target_div  CONSTANT xxcmm_cust_accounts.vist_target_div%TYPE  := '1';
    --
    -- *** ���[�J���ϐ� ***
    lt_last_update_date xxcmm_cust_accounts.last_update_date%TYPE;
    ln_count            NUMBER;
    --
  BEGIN
    --
    --##################  �Œ�X�e�[�^�X�������� START   ###################
    --
    ov_retcode := cv_status_normal;
    --
    --###########################  �Œ蕔 END   ############################
    --
    -- �ڋq�A�h�I���}�X�^���݃`�F�b�N
    IF (iv_proc_type = cv_proc_type_update) THEN
      SELECT COUNT(1)
      INTO   ln_count
      FROM   xxcmm_cust_accounts xca-- �ڋq�A�h�I���}�X�^
      WHERE  xca.customer_id = it_cust_account_id
      ;
      --
    END IF;
    --
    IF ((iv_proc_type = cv_proc_type_create)
      OR ((ln_count <= 0)
      AND (iv_proc_type = cv_proc_type_update)))
    THEN
      -- �����敪��C���́A�ڋq�A�h�I���}�X�^�����݂��Ȃ��ꍇ
      -- ======================
      -- �ڋq�A�h�I���}�X�^�V�K
      -- ======================
      BEGIN
        INSERT INTO xxcmm_cust_accounts(
           customer_id            -- �ڋq�h�c
          ,customer_code          -- �ڋq�R�[�h
          ,business_low_type      -- �Ƒԁi�����ށj
          ,industry_div           -- �Ǝ�
          ,sale_base_code         -- ���㋒�_�R�[�h
          ,past_sale_base_code    -- �O�����㋒�_�R�[�h
          ,delivery_base_code     -- �[�i���_�R�[�h
          ,established_site_name  -- �ݒu�於�i�����j
          ,establishment_location -- �ݒu���P�[�V����
          ,open_close_div         -- �����I�[�v���E�N���[�Y�敪
          ,cnvs_business_person   -- �l���c�ƈ�
          ,cnvs_base_code         -- �l�����_�R�[�h
          ,cust_update_flag       -- �V�K�^�X�V�t���O
          ,vist_target_div        -- �K��Ώۋ敪
          ,created_by             -- �쐬��
          ,creation_date          -- �쐬��
          ,last_updated_by        -- �ŏI�X�V��
          ,last_update_date       -- �ŏI�X�V��
          ,last_update_login)     -- �ŏI�X�V���O�C��
        VALUES (
           it_cust_account_id                                  -- �ڋq�h�c
          ,it_account_number                                   -- �ڋq�R�[�h
          ,it_mst_regist_info_rec.business_condition_type      -- �Ƒԁi�����ށj
          ,it_mst_regist_info_rec.business_type                -- �Ǝ�
          ,it_mst_regist_info_rec.publish_base_code            -- ���㋒�_�R�[�h
          ,it_mst_regist_info_rec.publish_base_code            -- �O�����㋒�_�R�[�h
          ,it_mst_regist_info_rec.publish_base_code            -- �[�i���_�R�[�h
          ,it_mst_regist_info_rec.install_name                 -- �ݒu�於�i�����j
          ,it_mst_regist_info_rec.install_location             -- �ݒu���P�[�V����
          ,it_mst_regist_info_rec.external_reference_opcl_type -- �����I�[�v���E�N���[�Y�敪
          ,it_mst_regist_info_rec.application_code             -- �l���c�ƈ�
          ,it_mst_regist_info_rec.app_base_code                -- �l�����_�R�[�h
          ,ct_cust_update_flag                                 -- �V�K�^�X�V�t���O
          ,ct_vist_target_div                                  -- �K��Ώۋ敪
          ,cn_created_by                                       -- �쐬��
          ,cd_creation_date                                    -- �쐬��
          ,cn_last_updated_by                                  -- �ŏI�X�V��
          ,cd_last_update_date                                 -- �ŏI�X�V��
          ,cn_last_update_login                                -- �ŏI�X�V���O�C��
        );
        --
      EXCEPTION
        WHEN OTHERS THEN
          -- ���̑��̃G���[�̏ꍇ
          lv_errbuf := xxccp_common_pkg.get_msg(
                          iv_application  => cv_sales_appl_short_name   -- �A�v���P�[�V�����Z�k��
                         ,iv_name         => cv_tkn_number_09           -- ���b�Z�[�W�R�[�h
                         ,iv_token_name1  => cv_tkn_action              -- �g�[�N���R�[�h1
                         ,iv_token_value1 => cv_tkn_value_action_create -- �g�[�N���l1
                         ,iv_token_name2  => cv_tkn_err_msg             -- �g�[�N���R�[�h2
                         ,iv_token_value2 => SQLERRM                    -- �g�[�N���l2
                      );
          --
          RAISE global_api_expt;
          --
      END;
      --
    ELSIF ((iv_proc_type = cv_proc_type_update)
      AND (ln_count >= 1))
    THEN
      -- �����敪��U�̏ꍇ
      -- ======================
      -- �ڋq�A�h�I���}�X�^�X�V
      -- ======================
      -- �ڋq�A�h�I���}�X�^�̃��b�N
      BEGIN
        SELECT xca.last_update_date last_update_date -- �ŏI�X�V��
        INTO   lt_last_update_date
        FROM   xxcmm_cust_accounts xca -- �ڋq�A�h�I���}�X�^
        WHERE  xca.customer_id = it_cust_account_id
        FOR UPDATE NOWAIT
        ;
        --
      EXCEPTION
        WHEN OTHERS THEN
          -- ���̑��̃G���[�̏ꍇ
          lv_errbuf := xxccp_common_pkg.get_msg(
                          iv_application  => cv_sales_appl_short_name -- �A�v���P�[�V�����Z�k��
                         ,iv_name         => cv_tkn_number_10         -- ���b�Z�[�W�R�[�h
                         ,iv_token_name1  => cv_tkn_table             -- �g�[�N���R�[�h1
                         ,iv_token_value1 => cv_tkn_value_table       -- �g�[�N���l1
                         ,iv_token_name2  => cv_tkn_errmsg            -- �g�[�N���R�[�h2
                         ,iv_token_value2 => SQLERRM                  -- �g�[�N���l2
                      );
          --
          RAISE global_api_expt;
          --
      END;
      --
      -- �ڋq�A�h�I���}�X�^�̍X�V
      BEGIN
        UPDATE xxcmm_cust_accounts
        SET    business_low_type      = it_mst_regist_info_rec.business_condition_type      -- �Ƒԁi�����ށj
              ,industry_div           = it_mst_regist_info_rec.business_type                -- �Ǝ�
              ,sale_base_code         = it_mst_regist_info_rec.publish_base_code            -- ���㋒�_�R�[�h
              ,past_sale_base_code    = it_mst_regist_info_rec.publish_base_code            -- �O�����㋒�_�R�[�h
              ,delivery_base_code     = it_mst_regist_info_rec.publish_base_code            -- �[�i���_�R�[�h
              ,established_site_name  = it_mst_regist_info_rec.install_name                 -- �ݒu�於�i�����j
              ,establishment_location = it_mst_regist_info_rec.install_location             -- �ݒu���P�[�V����
              ,open_close_div         = it_mst_regist_info_rec.external_reference_opcl_type -- �����I�[�v���E�N���[�Y�敪
              ,cnvs_business_person   = it_mst_regist_info_rec.application_code             -- �l���c�ƈ�
              ,cnvs_base_code         = it_mst_regist_info_rec.app_base_code                -- �l�����_�R�[�h
              ,cust_update_flag       = ct_cust_update_flag                                 -- �V�K�^�X�V�t���O
              ,vist_target_div        = ct_vist_target_div                                  -- �K��Ώۋ敪
              ,last_updated_by        = cn_last_updated_by                                  -- �ŏI�X�V��
              ,last_update_date       = cd_last_update_date                                 -- �ŏI�X�V��
              ,last_update_login      = cn_last_update_login                                -- �ŏI�X�V���O�C��
        WHERE  customer_id = it_cust_account_id
        ;
        --
      EXCEPTION
        WHEN OTHERS THEN
          -- ���̑��̃G���[�̏ꍇ
          lv_errbuf := xxccp_common_pkg.get_msg(
                          iv_application  => cv_sales_appl_short_name   -- �A�v���P�[�V�����Z�k��
                         ,iv_name         => cv_tkn_number_09           -- ���b�Z�[�W�R�[�h
                         ,iv_token_name1  => cv_tkn_action              -- �g�[�N���R�[�h1
                         ,iv_token_value1 => cv_tkn_value_action_update -- �g�[�N���l1
                         ,iv_token_name2  => cv_tkn_err_msg             -- �g�[�N���R�[�h2
                         ,iv_token_value2 => SQLERRM                    -- �g�[�N���l2
                       );
          --
          RAISE global_api_expt;
          --
      END;
      --
    END IF;
    --
  EXCEPTION
    --
    --#################################  �Œ��O������ START   ####################################
    --
    WHEN global_api_expt THEN
      -- *** ���ʊ֐���O�n���h�� ***
      ov_errbuf  := SUBSTRB(cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000);
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
    WHEN global_api_others_expt THEN
      -- *** ���ʊ֐�OTHERS��O�n���h�� ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
    WHEN OTHERS THEN
      -- *** OTHERS��O�n���h�� ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
    --
    --#####################################  �Œ蕔 END   ##########################################
    --
  END regist_account_addon;
  --
  --
  /**********************************************************************************
   * Procedure Name   : get_contract
   * Description      : �_����񒊏o(A-9)
   ***********************************************************************************/
  PROCEDURE get_contract(
     it_sp_decision_header_id IN  xxcso_sp_decision_headers.sp_decision_header_id%TYPE -- �r�o�ꌈ�w�b�_�h�c
    ,ot_mst_regist_info_rec   OUT NOCOPY g_mst_regist_info_rtype                       -- �}�X�^�o�^���
    ,ov_errbuf                OUT NOCOPY VARCHAR2                                      -- �G���[�E���b�Z�[�W --# �Œ� #
    ,ov_retcode               OUT NOCOPY VARCHAR2                                      -- ���^�[���E�R�[�h   --# �Œ� #
    ,ov_errmsg                OUT NOCOPY VARCHAR2                                      -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  )
  IS
    --
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name CONSTANT VARCHAR2(100) := 'get_contract';  -- �v���V�[�W����
    --
    --#######################  �Œ胍�[�J���ϐ��錾�� START   ######################
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
    ct_sp_dec_cust_class_contract CONSTANT xxcso_sp_decision_custs.sp_decision_customer_class%TYPE := '2'; -- �r�o�ꌈ�ڋq�敪=�_���
    --
    -- �g�[�N���p�萔
    cv_tkn_value_sp_dec_head_id CONSTANT VARCHAR2(30) := '�r�o�ꌈ�w�b�_�h�c';             -- �r�o�ꌈ�w�b�_�h�c�a��
    cv_tkn_value_sp_dec_custs   CONSTANT VARCHAR2(30) := '�r�o�ꌈ�ڋq�e�[�u���i�_���j'; -- �r�o�ꌈ�ڋq�e�[�u���a��
    --
    -- *** ���[�J���ϐ� ***
    --
  BEGIN
    --
    --##################  �Œ�X�e�[�^�X�������� START   ###################
    --
    ov_retcode := cv_status_normal;
    --
    --###########################  �Œ蕔 END   ############################
    --
    -- ============================
    -- �ݒu����i�_���j�擾����
    -- ============================
    ot_mst_regist_info_rec := NULL;
    --
    BEGIN
      SELECT xsd.customer_id            customer_id            -- �ڋq�h�c
            ,xsd.party_name             party_name             -- �ڋq��
            ,xsd.party_name_alt         party_name_alt         -- �ڋq���J�i
            ,xsd.representative_name    representative_name    -- ��\�Җ�
            ,xsd.postal_code            postal_code            -- �X�֔ԍ�
            ,xsd.state                  state                  -- �s���{��
            ,xsd.city                   city                   -- �s�E��
            ,xsd.address1               address1               -- �Z���P
            ,xsd.address2               address2               -- �Z���Q
            ,xsd.address_lines_phonetic address_lines_phonetic -- �d�b�ԍ�
      INTO   ot_mst_regist_info_rec.customer_id
            ,ot_mst_regist_info_rec.party_name
            ,ot_mst_regist_info_rec.party_name_alt
            ,ot_mst_regist_info_rec.representative_name
            ,ot_mst_regist_info_rec.postal_code
            ,ot_mst_regist_info_rec.state
            ,ot_mst_regist_info_rec.city
            ,ot_mst_regist_info_rec.address1
            ,ot_mst_regist_info_rec.address2
            ,ot_mst_regist_info_rec.address_lines_phonetic
      FROM   xxcso_sp_decision_custs xsd -- �r�o�ꌈ�ڋq�e�[�u��
      WHERE  xsd.sp_decision_header_id      = it_sp_decision_header_id
      AND    xsd.sp_decision_customer_class = ct_sp_dec_cust_class_contract
      ;
      --
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- �f�[�^�����݂��Ȃ��ꍇ
        lv_errbuf := xxccp_common_pkg.get_msg(
                        iv_application  => cv_sales_appl_short_name  -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_03          -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_item               -- �g�[�N���R�[�h1
                       ,iv_token_value1 => cv_tkn_value_sp_dec_head_id ||
                                           cv_msg_part                 ||
                                           it_sp_decision_header_id  -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_table              -- �g�[�N���R�[�h2
                       ,iv_token_value2 => cv_tkn_value_sp_dec_custs -- �g�[�N���l2
                    );
        --
        RAISE global_api_expt;
        --
      WHEN OTHERS THEN
        -- ���̑��̗�O�̏ꍇ
        lv_errbuf := xxccp_common_pkg.get_msg(
                        iv_application  => cv_sales_appl_short_name  -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_04          -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_table              -- �g�[�N���R�[�h1
                       ,iv_token_value1 => cv_tkn_value_sp_dec_custs -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_key                -- �g�[�N���R�[�h2
                       ,iv_token_value2 => it_sp_decision_header_id  -- �g�[�N���l2
                       ,iv_token_name3  => cv_tkn_err_msg            -- �g�[�N���R�[�h3
                       ,iv_token_value3 => SQLERRM                   -- �g�[�N���l3
                    );
        --
        RAISE global_api_expt;
        --
    END;
    --
  EXCEPTION
    --
    --#################################  �Œ��O������ START   ####################################
    --
    WHEN global_api_expt THEN
      -- *** ���ʊ֐���O�n���h�� ***
      ov_errbuf  := SUBSTRB(cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000);
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
    WHEN global_api_others_expt THEN
      -- *** ���ʊ֐�OTHERS��O�n���h�� ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
    WHEN OTHERS THEN
      -- *** OTHERS��O�n���h�� ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
    --
    --#####################################  �Œ蕔 END   ##########################################
    --
  END get_contract;
  --
  --
  /**********************************************************************************
   * Procedure Name   : regist_contract
   * Description      : �_���o�^(A-10)
   ***********************************************************************************/
  PROCEDURE regist_contract(
     it_mst_regist_info_rec  IN         g_mst_regist_info_rtype                            -- �}�X�^�o�^���
    ,ot_contract_customer_id OUT NOCOPY xxcso_contract_customers.contract_customer_id%TYPE -- �_���h�c
    ,ov_errbuf               OUT NOCOPY VARCHAR2                                           -- �G���[�E���b�Z�[�W --# �Œ� #
    ,ov_retcode              OUT NOCOPY VARCHAR2                                           -- ���^�[���E�R�[�h   --# �Œ� #
    ,ov_errmsg               OUT NOCOPY VARCHAR2                                           -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  )
  IS
    --
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name CONSTANT VARCHAR2(100) := 'regist_contract';  -- �v���V�[�W����
    --
    --#######################  �Œ胍�[�J���ϐ��錾�� START   ######################
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
    -- �g�[�N���p�萔
    cv_tkn_value_sequence      CONSTANT VARCHAR2(30) := '�_���h�c�V�[�P���X';
    cv_tkn_value_action_create CONSTANT VARCHAR2(30) := '�_���e�[�u���̓o�^';
    --
    -- *** ���[�J���ϐ� ***
    lt_contract_customer_id xxcso_contract_customers.contract_customer_id%TYPE;
    ln_count                NUMBER;
    --
  BEGIN
    --
    --##################  �Œ�X�e�[�^�X�������� START   ###################
    --
    ov_retcode := cv_status_normal;
    --
    --###########################  �Œ蕔 END   ############################
    --
    -- ============================
    -- �ݒu����i�_���j�擾����
    -- ============================
    IF (it_mst_regist_info_rec.customer_id IS NULL) THEN
      -- �ڋq�h�c��NULL�̏ꍇ
      -- �_���h�c�̎擾
      BEGIN
        SELECT xxcso_contract_customers_s01.NEXTVAL contract_customer_id
        INTO   lt_contract_customer_id
        FROM   DUAL
        ;
        --
      EXCEPTION
        WHEN OTHERS THEN
          -- ���̑��̃G���[�̏ꍇ 
          lv_errbuf := xxccp_common_pkg.get_msg(
                          iv_application  => cv_sales_appl_short_name -- �A�v���P�[�V�����Z�k��
                         ,iv_name         => cv_tkn_number_08         -- ���b�Z�[�W�R�[�h
                         ,iv_token_name1  => cv_tkn_sequence          -- �g�[�N���R�[�h1
                         ,iv_token_value1 => cv_tkn_value_sequence    -- �g�[�N���l1
                         ,iv_token_name2  => cv_tkn_err_msg           -- �g�[�N���R�[�h2
                         ,iv_token_value2 => SQLERRM                  -- �g�[�N���l2
                      );
          --
          RAISE global_api_expt;
          --
      END;
      --
      BEGIN
        INSERT INTO xxcso_contract_customers(
           contract_customer_id -- �_���h�c
          ,contract_number      -- �_���ԍ�
          ,contract_name        -- �_��於
          ,contract_name_kana   -- �_��於�J�i
          ,delegate_name        -- ��\�Җ�
          ,post_code            -- �X�֔ԍ�
          ,prefectures          -- �s���{��
          ,city_ward            -- �s�E��
          ,address_1            -- �Z���P
          ,address_2            -- �Z���Q
          ,phone_number         -- �d�b�ԍ�
          ,created_by           -- �쐬��
          ,creation_date        -- �쐬��
          ,last_updated_by      -- �ŏI�X�V��
          ,last_update_date     -- �ŏI�X�V��
          ,last_update_login)   -- �ŏI�X�V���O�C��
        VALUES (
           lt_contract_customer_id                       -- �_���h�c
          ,TO_CHAR(xxcso_contract_customers_s02.NEXTVAL) -- �_���ԍ�
          ,it_mst_regist_info_rec.party_name             -- �_��於
          ,it_mst_regist_info_rec.party_name_alt         -- �_��於�J�i�i
          ,it_mst_regist_info_rec.representative_name    -- ��\�Җ�
          ,it_mst_regist_info_rec.postal_code            -- �X�֔ԍ�
          ,it_mst_regist_info_rec.state                  -- �s���{��
          ,it_mst_regist_info_rec.city                   -- �s�E��
          ,it_mst_regist_info_rec.address1               -- �Z���P
          ,it_mst_regist_info_rec.address2               -- �Z���Q
          ,it_mst_regist_info_rec.address_lines_phonetic -- �d�b�ԍ�
          ,cn_created_by                                 -- �쐬��
          ,cd_creation_date                              -- �쐬��
          ,cn_last_updated_by                            -- �ŏI�X�V��
          ,cd_last_update_date                           -- �ŏI�X�V��
          ,cn_last_update_login                          -- �ŏI�X�V���O�C��
        );
        --
      EXCEPTION
        WHEN OTHERS THEN
          -- ���̑��̃G���[�̏ꍇ
          lv_errbuf := xxccp_common_pkg.get_msg(
                          iv_application  => cv_sales_appl_short_name   -- �A�v���P�[�V�����Z�k��
                         ,iv_name         => cv_tkn_number_09           -- ���b�Z�[�W�R�[�h
                         ,iv_token_name1  => cv_tkn_action              -- �g�[�N���R�[�h1
                         ,iv_token_value1 => cv_tkn_value_action_create -- �g�[�N���l1
                         ,iv_token_name2  => cv_tkn_err_msg             -- �g�[�N���R�[�h2
                         ,iv_token_value2 => SQLERRM                    -- �g�[�N���l2
                      );
          --
          RAISE global_api_expt;
          --
      END;
      --
    ELSE
      lt_contract_customer_id := it_mst_regist_info_rec.customer_id;
      --
    END IF;
    --
    ot_contract_customer_id := lt_contract_customer_id;
    --
  EXCEPTION
    --
    --#################################  �Œ��O������ START   ####################################
    --
    WHEN global_api_expt THEN
      -- *** ���ʊ֐���O�n���h�� ***
      ov_errbuf  := SUBSTRB(cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000);
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
    WHEN global_api_others_expt THEN
      -- *** ���ʊ֐�OTHERS��O�n���h�� ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
     --
    WHEN OTHERS THEN
      -- *** OTHERS��O�n���h�� ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
    --
    --#####################################  �Œ蕔 END   ##########################################
    --
  END regist_contract;
  --
  --
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   ***********************************************************************************/
  PROCEDURE submain(
     it_sp_decision_header_id IN         xxcso_sp_decision_headers.sp_decision_header_id%TYPE -- �r�o�ꌈ�w�b�_�h�c
    ,ot_cust_account_id       OUT NOCOPY hz_cust_accounts.cust_account_id%TYPE                -- �ڋq�h�c
    ,ot_contract_customer_id  OUT NOCOPY xxcso_contract_customers.contract_customer_id%TYPE   -- �_���h�c
    ,ov_errbuf                OUT NOCOPY VARCHAR2                                             -- �G���[�E���b�Z�[�W --# �Œ� #
    ,ov_retcode               OUT NOCOPY VARCHAR2                                             -- ���^�[���E�R�[�h   --# �Œ� #
    ,ov_errmsg                OUT NOCOPY VARCHAR2                                             -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  )
  IS
    --
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name CONSTANT VARCHAR2(100) := 'submain'; -- �v���V�[�W����
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
    lv_proc_type            VARCHAR2(1);                                        -- �����敪
    lt_mst_regist_info_rec  g_mst_regist_info_rtype;                            -- �}�X�^�o�^���
    lt_party_id             hz_parties.party_id%TYPE;                           -- �p�[�e�B�h�c
    lt_party_site_id        hz_party_sites.party_site_id%TYPE;                  -- �p�[�e�B�T�C�g�h�c
    lt_cust_account_id      hz_cust_accounts.cust_account_id%TYPE;              -- �ڋq�h�c
    lt_account_number       hz_cust_accounts.account_number%TYPE;               -- �ڋq�ԍ�
    lt_cust_acct_site_id    hz_cust_acct_sites_all.cust_acct_site_id%TYPE;      -- �ڋq���ݒn�h�c
    lt_contract_customer_id xxcso_contract_customers.contract_customer_id%TYPE; -- �_���h�c
    --
    -- *** ���[�J���E�J�[�\�� ***
    --
    -- *** ���[�J���E���R�[�h ***
    --
    -- *** ���[�J����O ***
    --
  BEGIN
    --
    --##################  �Œ�X�e�[�^�X�������� START   ###################
    --
    ov_retcode := cv_status_normal;
    --
    --###########################  �Œ蕔 END   ############################
    --
    -- �O���[�o���ϐ��̏�����
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
    --
    -- ============
    -- A-1.��������
    -- ============
    start_proc(
       it_sp_decision_header_id => it_sp_decision_header_id -- �r�o�ꌈ�w�b�_�h�c
      ,ot_mst_regist_info_rec   => lt_mst_regist_info_rec   -- �}�X�^�o�^���
      ,ov_errbuf                => lv_errbuf                -- �G���[�E���b�Z�[�W --# �Œ� #
      ,ov_retcode               => lv_retcode               -- ���^�[���E�R�[�h   --# �Œ� #
      ,ov_errmsg                => lv_errmsg                -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
    );
    --
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
      --
    END IF;
    --
    -- ===================
    -- A-2. �ݒu���񒊏o
    -- ===================
    get_install_at_info(
       it_sp_decision_header_id => it_sp_decision_header_id -- �r�o�ꌈ�w�b�_�h�c
      ,iot_mst_regist_info_rec  => lt_mst_regist_info_rec   -- �}�X�^�o�^���
      ,ov_proc_type             => lv_proc_type             -- �����敪
      ,ov_errbuf                => lv_errbuf                -- �G���[�E���b�Z�[�W --# �Œ� #
      ,ov_retcode               => lv_retcode               -- ���^�[���E�R�[�h   --# �Œ� #
      ,ov_errmsg                => lv_errmsg                -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
    );
    --
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
      --
    END IF;
    --
    IF (lv_proc_type <> cv_proc_type_outside) THEN
      -- �����敪��O�ȊO�̏ꍇ
      -- ==========================
      -- A-3.�p�[�e�B�}�X�^�o�^�X�V
      -- ==========================
      regist_party(
         iv_proc_type           => lv_proc_type           -- �����敪
        ,it_mst_regist_info_rec => lt_mst_regist_info_rec -- �}�X�^�o�^���
        ,ot_party_id            => lt_party_id            -- �p�[�e�B�h�c
        ,ov_errbuf              => lv_errbuf              -- �G���[�E���b�Z�[�W --# �Œ� #
        ,ov_retcode             => lv_retcode             -- ���^�[���E�R�[�h   --# �Œ� #
        ,ov_errmsg              => lv_errmsg              -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
      );
      --
      IF (lv_retcode <> cv_status_normal) THEN
        RAISE global_process_expt;
        --
      END IF;
      --
      -- ============================================
      -- A-4.�ڋq���Ə��^�p�[�e�B�T�C�g�}�X�^�o�^�X�V
      -- ============================================
      regist_locat_party_site(
         iv_proc_type           => lv_proc_type           -- �����敪
        ,it_mst_regist_info_rec => lt_mst_regist_info_rec -- �}�X�^�o�^���
        ,it_party_id            => lt_party_id            -- �p�[�e�B�h�c
        ,ot_party_site_id       => lt_party_site_id       -- �p�[�e�B�T�C�g�h�c
        ,ov_errbuf              => lv_errbuf              -- �G���[�E���b�Z�[�W --# �Œ� #
        ,ov_retcode             => lv_retcode             -- ���^�[���E�R�[�h   --# �Œ� #
        ,ov_errmsg              => lv_errmsg              -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
      );
      --
      IF (lv_retcode <> cv_status_normal) THEN
        RAISE global_process_expt;
        --
      END IF;
      --
      -- ======================
      -- A-5.�ڋq�}�X�^�o�^�X�V
      -- ======================
      regist_cust_account(
         iv_proc_type           => lv_proc_type           -- �����敪
        ,it_mst_regist_info_rec => lt_mst_regist_info_rec -- �}�X�^�o�^���
        ,it_party_id            => lt_party_id            -- �p�[�e�B�h�c
        ,ot_cust_account_id     => lt_cust_account_id     -- �ڋq�h�c
        ,ot_account_number      => lt_account_number      -- �ڋq�ԍ�
        ,ov_errbuf              => lv_errbuf              -- �G���[�E���b�Z�[�W --# �Œ� #
        ,ov_retcode             => lv_retcode             -- ���^�[���E�R�[�h   --# �Œ� #
        ,ov_errmsg              => lv_errmsg              -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
      );
      --
      IF (lv_retcode <> cv_status_normal) THEN
        RAISE global_process_expt;
        --
      END IF;
      --
      -- ========================
      -- A-6.�ڋq���ݒn�}�X�^�o�^
      -- ========================
      regist_cust_acct_site(
         iv_proc_type           => lv_proc_type           -- �����敪
        ,it_mst_regist_info_rec => lt_mst_regist_info_rec -- �}�X�^�o�^���
        ,it_party_site_id       => lt_party_site_id       -- �p�[�e�B�T�C�g�h�c
        ,it_cust_account_id     => lt_cust_account_id     -- �ڋq�h�c
        ,ot_cust_acct_site_id   => lt_cust_acct_site_id   -- �ڋq���ݒn�h�c
        ,ov_errbuf              => lv_errbuf              -- �G���[�E���b�Z�[�W --# �Œ� #
        ,ov_retcode             => lv_retcode             -- ���^�[���E�R�[�h   --# �Œ� #
        ,ov_errmsg              => lv_errmsg              -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
      );
      --
      IF (lv_retcode <> cv_status_normal) THEN
        RAISE global_process_expt;
        --
      END IF;
      --
      -- ==========================
      -- A-7.�ڋq�g�p�ړI�}�X�^�o�^
      -- ==========================
      regist_cust_site_use(
         iv_proc_type           => lv_proc_type           -- �����敪
        ,it_mst_regist_info_rec => lt_mst_regist_info_rec -- �}�X�^�o�^���
        ,it_cust_acct_site_id   => lt_cust_acct_site_id   -- �ڋq���ݒn�h�c
        ,ov_errbuf              => lv_errbuf              -- �G���[�E���b�Z�[�W --# �Œ� #
        ,ov_retcode             => lv_retcode             -- ���^�[���E�R�[�h   --# �Œ� #
        ,ov_errmsg              => lv_errmsg              -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
      );
      --
      IF (lv_retcode <> cv_status_normal) THEN
        RAISE global_process_expt;
        --
      END IF;
      --
      -- ==============================
      -- A-8.�ڋq�A�h�I���}�X�^�o�^�X�V
      -- ==============================
      regist_account_addon(
         iv_proc_type           => lv_proc_type           -- �����敪
        ,it_mst_regist_info_rec => lt_mst_regist_info_rec -- �}�X�^�o�^���
        ,it_cust_account_id     => lt_cust_account_id     -- �ڋq�h�c
        ,it_account_number      => lt_account_number      -- �ڋq�ԍ�
        ,ov_errbuf              => lv_errbuf              -- �G���[�E���b�Z�[�W --# �Œ� #
        ,ov_retcode             => lv_retcode             -- ���^�[���E�R�[�h   --# �Œ� #
        ,ov_errmsg              => lv_errmsg              -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
      );
      --
      IF (lv_retcode <> cv_status_normal) THEN
        RAISE global_process_expt;
        --
      END IF;
      --
    ELSE
      lt_cust_account_id := lt_mst_regist_info_rec.customer_id;
      --
    END IF;
    --
    -- ==================
    -- A-9.�_����񒊏o
    -- ==================
    get_contract(
       it_sp_decision_header_id => it_sp_decision_header_id -- �r�o�ꌈ�w�b�_�h�c
      ,ot_mst_regist_info_rec   => lt_mst_regist_info_rec   -- �}�X�^�o�^���
      ,ov_errbuf                => lv_errbuf                -- �G���[�E���b�Z�[�W --# �Œ� #
      ,ov_retcode               => lv_retcode               -- ���^�[���E�R�[�h   --# �Œ� #
      ,ov_errmsg                => lv_errmsg                -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
    );
    --
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
      --
    END IF;
    --
    -- ===============
    -- A-10.�_���o�^
    -- ===============
    regist_contract(
       it_mst_regist_info_rec  => lt_mst_regist_info_rec  -- �}�X�^�o�^���
      ,ot_contract_customer_id => lt_contract_customer_id -- �_���h�c
      ,ov_errbuf               => lv_errbuf               -- �G���[�E���b�Z�[�W --# �Œ� #
      ,ov_retcode              => lv_retcode              -- ���^�[���E�R�[�h   --# �Œ� #
      ,ov_errmsg               => lv_errmsg               -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
    );
    --
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
      --
    END IF;
    --
    ot_cust_account_id      := lt_cust_account_id;
    ot_contract_customer_id := lt_contract_customer_id;
    --
  EXCEPTION
    --
    --#################################  �Œ��O������ START   ####################################
    --
    WHEN global_process_expt THEN
      -- *** ���������ʗ�O�n���h�� ***
      -- �G���[�����J�E���g
      gn_error_cnt := gn_error_cnt + 1;
      --
      ov_errbuf  := SUBSTRB(cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000);
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
    WHEN global_api_others_expt THEN
      -- *** ���ʊ֐�OTHERS��O�n���h�� ***
      -- �G���[�����J�E���g
      gn_error_cnt := gn_error_cnt + 1;
      --
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM || lv_errbuf;
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
    WHEN OTHERS THEN
      -- *** OTHERS��O�n���h�� ***
      -- �G���[�����J�E���g
      gn_error_cnt := gn_error_cnt + 1;
      --
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
   --
    --#####################################  �Œ蕔 END   ##########################################
    --
  END submain;
  --
  --
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : ���s�t�@�C���o�^�v���V�[�W��
   **********************************************************************************/
  --
  PROCEDURE main(
     errbuf                   OUT NOCOPY VARCHAR2                                             -- �G���[�E���b�Z�[�W --# �Œ� #
    ,retcode                  OUT NOCOPY VARCHAR2                                             -- ���^�[���E�R�[�h   --# �Œ� #
    ,it_sp_decision_header_id IN         xxcso_sp_decision_headers.sp_decision_header_id%TYPE -- �r�o�ꌈ�w�b�_�h�c
    ,ot_cust_account_id       OUT NOCOPY hz_cust_accounts.cust_account_id%TYPE                -- �ڋq�h�c
    ,ot_contract_customer_id  OUT NOCOPY xxcso_contract_customers.contract_customer_id%TYPE   -- �_���h�c
  )
  --
  --###########################  �Œ蕔 START   ###########################
  --
  IS
    --
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name CONSTANT VARCHAR2(100) := 'main'; -- �v���O������
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
--    xxccp_common_pkg.put_log_header(
--       ov_retcode => lv_retcode
--      ,ov_errbuf  => lv_errbuf
--    );
--    --
--    IF (lv_retcode = cv_status_error) THEN
--      RAISE global_api_others_expt;
--    END IF;
    --
    --###########################  �Œ蕔 END   #############################
    --
    -- ===============================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ===============================================
    submain(
       it_sp_decision_header_id => it_sp_decision_header_id -- �r�o�ꌈ�w�b�_�h�c
      ,ot_cust_account_id       => ot_cust_account_id       -- �ڋq�h�c
      ,ot_contract_customer_id  => ot_contract_customer_id  -- �_���h�c
      ,ov_errbuf                => lv_errbuf                -- �G���[�E���b�Z�[�W --# �Œ� #
      ,ov_retcode               => lv_retcode               -- ���^�[���E�R�[�h   --# �Œ� #
      ,ov_errmsg                => lv_errmsg                -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
    );
    --
    errbuf  := lv_errbuf;
    retcode := lv_retcode;
/*
    IF (lv_retcode = cv_status_error) THEN
       --�G���[�o��
       fnd_file.put_line(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_errmsg                  --���[�U�[�E�G���[���b�Z�[�W
       );
       fnd_file.put_line(
          which  => FND_FILE.LOG
         ,buff   => cv_pkg_name||cv_msg_cont||
                    cv_prg_name||cv_msg_part||
                    lv_errbuf                  --�G���[���b�Z�[�W
       );
    END IF;
    --
    -- =======================
    -- A-x.�I������ 
    -- =======================
    --��s�̏o��
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    --�Ώی����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_target_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)
                   );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --���������o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_success_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_normal_cnt)
                   );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --�G���[�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_error_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_error_cnt)
                   );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --�I�����b�Z�[�W
    IF (lv_retcode = cv_status_normal) THEN
      lv_message_code := cv_normal_msg;
    ELSIF(lv_retcode = cv_status_error) THEN
      lv_message_code := cv_error_msg;
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
    --�X�e�[�^�X�Z�b�g
    retcode := lv_retcode;
    --�I���X�e�[�^�X���G���[�̏ꍇ��ROLLBACK����
    IF (retcode = cv_status_error) THEN
      ROLLBACK;
      -- *** DEBUG_LOG ***
      -- ���[���o�b�N�������Ƃ����O�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg11 || CHR(10) ||
                   ''
      );
    END IF;
*/
--
  EXCEPTION
    WHEN global_api_others_expt THEN
      -- *** ���ʊ֐�OTHERS��O�n���h�� ***
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM||lv_errbuf;
      retcode := cv_status_error;
      ROLLBACK;
    WHEN OTHERS THEN
      -- *** OTHERS��O�n���h�� ***
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
      ROLLBACK;
  END main;
--
--###########################  �Œ蕔 END   #######################################################
--
END XXCSO020A03C;
/
