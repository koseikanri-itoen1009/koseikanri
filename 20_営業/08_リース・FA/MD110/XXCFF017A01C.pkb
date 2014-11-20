CREATE OR REPLACE PACKAGE BODY XXCFF017A01C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * Package Name     : XXCFF017A01C(body)
 * Description      : ���̋@���A�g
 * MD.050           : MD050_CFF_017_A01_���̋@���A�g
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                    ��������                   (A-1)
 *  select_vd_object_info   ���̋@�����Ǘ���񒊏o���� (A-2)
 *  validate_record         �f�[�^�Ó����`�F�b�N����   (A-3)
 *  ins_upd_vd_object       ���̋@���o�^�^�X�V       (A-4)
 *  ins_vd_obj_hist         ���̋@��������o�^         (A-5)
 *  delete_vd_object_if     ���̋@�����Ǘ�IF�폜����   (A-6)
 *  submain                 ���C�������v���V�[�W��
 *  main                    �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2014-07-17    1.0   SCSK �R�� �đ�   �V�K�쐬
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
--
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
  PRAGMA EXCEPTION_INIT(global_api_others_expt,-20000);
--
--################################  �Œ蕔 END   ##################################
--
  -- ===============================
  -- ���[�U�[��`��O
  -- ===============================
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name         CONSTANT VARCHAR2(100) := 'XXCFF017A01C';  -- �p�b�P�[�W��
  cv_app_kbn_cff      CONSTANT VARCHAR2(5)   := 'XXCFF';         -- �A�v���P�[�V�����Z�k��
--
  -- ���b�Z�[�W�ԍ�
  cv_msg_cff_00062    CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-00062';  -- �Ώۃf�[�^�Ȃ�
  cv_msg_cff_00092    CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-00092';  -- �Ɩ��������t�擾�G���[
  cv_msg_cff_00093    CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-00093';  -- �L�[���t�G���[���b�Z�[�W
  cv_msg_cff_00094    CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-00094';  -- ���ʊ֐��G���[
  cv_msg_cff_00095    CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-00095';  -- ���ʊ֐����b�Z�[�W
  cv_msg_cff_00209    CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-00209';  -- �i���̋@�������j�������G���[���b�Z�[�W
  cv_msg_cff_00210    CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-00210';  -- �i���̋@�������j�����̖����X�e�[�^�X�A�g���b�Z�[�W
  cv_msg_cff_00211    CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-00211';  -- ���E���p���A�g�G���[���b�Z�[�W
  cv_msg_cff_00212    CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-00212';  -- �����p�X�e�[�^�X�G���[���b�Z�[�W
  cv_msg_cff_00213    CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-00213';  -- �V�[�P���X�擾�G���[���b�Z�[�W
--
  -- �g�[�N��
  cv_tkn_cff_00093_01 CONSTANT VARCHAR2(15) := 'ERR_MSG';        -- �G���[���b�Z�[�W
  cv_tkn_cff_00093_02 CONSTANT VARCHAR2(15) := 'KEY_INFO';       -- �L�[���
  cv_tkn_cff_00094    CONSTANT VARCHAR2(15) := 'FUNC_NAME';      -- ���ʊ֐���
  cv_tkn_cff_00095    CONSTANT VARCHAR2(15) := 'ERR_MSG';        -- �G���[���b�Z�[�W
  cv_tkn_cff_00209    CONSTANT VARCHAR2(15) := 'TRX_DATE';       -- �捞�σf�[�^�̐ݒu�x�[�X���A�g��
  cv_tkn_cff_00213    CONSTANT VARCHAR2(15) := 'SEQUENCE';       -- �V�[�P���X��
--
  -- �g�[�N���l
  cv_msg_cff_50137    CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-50137';  -- �����R�[�h�F
  cv_msg_cff_50141    CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-50141';  -- ���Ə��}�X�^�`�F�b�N
--
  -- �t���O
  gv_flag_on          CONSTANT VARCHAR2(1)   := 'Y';           -- �uY�v
  gv_flag_off         CONSTANT VARCHAR2(1)   := 'N';           -- �uN�v
--
  -- �捞�X�e�[�^�X
  cv_import_status_0  CONSTANT VARCHAR2(1)   := '0';           -- ���捞
  cv_import_status_1  CONSTANT VARCHAR2(1)   := '1';           -- �捞��
  cv_import_status_9  CONSTANT VARCHAR2(1)   := '9';           -- �����p�X�e�[�^�X�G���[
--
  -- �����X�e�[�^�X
  cv_obj_status_101   CONSTANT VARCHAR2(3)   := '101';         -- ���m��
  cv_obj_status_102   CONSTANT VARCHAR2(3)   := '102';         -- �m���
  cv_obj_status_103   CONSTANT VARCHAR2(3)   := '103';         -- �ړ�
  cv_obj_status_104   CONSTANT VARCHAR2(3)   := '104';         -- �C��
  cv_obj_status_105   CONSTANT VARCHAR2(3)   := '105';         -- �����p���m��
  cv_obj_status_106   CONSTANT VARCHAR2(3)   := '106';         -- �����p
--
  -- �����}�X�N
  cv_date_format      CONSTANT VARCHAR2(10)  := 'YYYY/MM/DD';  -- ���t����
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  -- ���̋@�����Ǘ����捞�Ώۃf�[�^���R�[�h�^
  TYPE g_vd_object_rtype IS RECORD(
    object_code                 xxcff_vd_object_mng_if.object_code%TYPE,            -- �����R�[�h
    generation_date             xxcff_vd_object_mng_if.generation_date%TYPE,        -- ������
    owner_company_type          xxcff_vd_object_mng_if.owner_company_type%TYPE,     -- �{��/�H��敪
    department_code             xxcff_vd_object_mng_if.department_code%TYPE,        -- �Ǘ�����
    machine_type                xxcff_vd_object_mng_if.machine_type%TYPE,           -- �@��敪
    lease_class                 xxcff_vd_object_mng_if.lease_class%TYPE,            -- ���[�X���
    vendor_code                 xxcff_vd_object_mng_if.vendor_code%TYPE,            -- �d����R�[�h
    manufacturer_name           xxcff_vd_object_mng_if.manufacturer_name%TYPE,      -- ���[�J��
    model                       xxcff_vd_object_mng_if.model%TYPE,                  -- �@��
    age_type                    xxcff_vd_object_mng_if.age_type%TYPE,               -- �N��
    customer_code               xxcff_vd_object_mng_if.customer_code%TYPE,          -- �ڋq�R�[�h
    quantity                    xxcff_vd_object_mng_if.quantity%TYPE,               -- ����
    date_placed_in_service      xxcff_vd_object_mng_if.date_placed_in_service%TYPE, -- ���Ƌ��p��
    assets_cost                 xxcff_vd_object_mng_if.assets_cost%TYPE,            -- �擾���i
    moved_date                  xxcff_vd_object_mng_if.moved_date%TYPE,             -- �ړ���
    installation_place          xxcff_vd_object_mng_if.installation_place%TYPE,     -- �ݒu��
    installation_address        xxcff_vd_object_mng_if.installation_address%TYPE,   -- �ݒu�ꏊ
    dclr_place                  xxcff_vd_object_mng_if.dclr_place%TYPE,             -- �\���n
    location                    xxcff_vd_object_mng_if.location%TYPE,               -- ���Ə�
    date_retired                xxcff_vd_object_mng_if.date_retired%TYPE,           -- ���E���p��
    active_flag                 xxcff_vd_object_mng_if.active_flag%TYPE,            -- �����L���t���O
    import_status               xxcff_vd_object_mng_if.import_status%TYPE,          -- �捞�X�e�[�^�X
    xvoh_object_header_id       xxcff_vd_object_headers.object_header_id%TYPE,      -- ����ID
    xvoh_object_status          xxcff_vd_object_headers.object_status%TYPE,         -- �����X�e�[�^�X
    xvoh_owner_company_type     xxcff_vd_object_headers.owner_company_type%TYPE,    -- �{�Ё^�H��敪
    xvoh_department_code        xxcff_vd_object_headers.department_code%TYPE,       -- �Ǘ�����
    xvoh_manufacturer_name      xxcff_vd_object_headers.manufacturer_name%TYPE,     -- ���[�J��
    xvoh_model                  xxcff_vd_object_headers.model%TYPE,                 -- �@��
    xvoh_age_type               xxcff_vd_object_headers.age_type%TYPE,              -- �N��
    xvoh_customer_code          xxcff_vd_object_headers.customer_code%TYPE,         -- �ڋq�R�[�h
    xvoh_quantity               xxcff_vd_object_headers.quantity%TYPE,              -- ����
    xvoh_date_placed_in_service xxcff_vd_object_headers.date_placed_in_service%TYPE,-- ���Ƌ��p��
    xvoh_assets_cost            xxcff_vd_object_headers.assets_cost%TYPE,           -- �擾���i
    xvoh_moved_date             xxcff_vd_object_headers.moved_date%TYPE,            -- �ړ���
    xvoh_month_lease_charge     xxcff_vd_object_headers.month_lease_charge%TYPE,    -- ���z���[�X��
    xvoh_re_lease_charge        xxcff_vd_object_headers.re_lease_charge%TYPE,       -- �ă��[�X��
    xvoh_assets_date            xxcff_vd_object_headers.assets_date%TYPE,           -- �擾��
    xvoh_installation_place     xxcff_vd_object_headers.installation_place%TYPE,    -- �ݒu��
    xvoh_installation_address   xxcff_vd_object_headers.installation_address%TYPE,  -- �ݒu�ꏊ
    xvoh_dclr_place             xxcff_vd_object_headers.dclr_place%TYPE,            -- �\���n
    xvoh_location               xxcff_vd_object_headers.location%TYPE,              -- ���Ə�
    xvoh_date_retired           xxcff_vd_object_headers.date_retired%TYPE,          -- ���E���p��
    xvoh_proceeds_of_sale       xxcff_vd_object_headers.proceeds_of_sale%TYPE,      -- ���p���i
    xvoh_cost_of_removal        xxcff_vd_object_headers.cost_of_removal%TYPE,       -- �P����p
    xvoh_ib_if_date             xxcff_vd_object_headers.ib_if_date%TYPE             -- �ݒu�x�[�X���A�g��
  );
--
  -- ���̋@�����Ǘ����捞�Ώۃf�[�^���R�[�h�z��
  TYPE g_vd_object_ttype IS TABLE OF g_vd_object_rtype
  INDEX BY BINARY_INTEGER;
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gd_process_date  DATE;               -- �Ɩ����t
  g_vd_object_tab  g_vd_object_ttype;  -- ���̋@�����Ǘ����捞�Ώۃf�[�^
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : �������� (A-1)
   ***********************************************************************************/
  PROCEDURE init(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'init'; -- �v���O������
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
    lv_which_out VARCHAR2(10) := 'OUTPUT';
    lv_which_log VARCHAR2(10) := 'LOG';
--
    -- *** ���[�J���ϐ� ***
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
    -- �R���J�����g�p�����[�^�̒l��\�����郁�b�Z�[�W�̏o��
    xxcff_common1_pkg.put_log_param(
      iv_which   => lv_which_out,  -- �o�͋敪
      ov_retcode => lv_retcode,    -- ���^�[���R�[�h
      ov_errbuf  => lv_errbuf,     -- �G���[���b�Z�[�W
      ov_errmsg  => lv_errmsg      -- ���[�U�[�E�G���[���b�Z�[�W
    );
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_api_expt;
    END IF;
--
    -- -- �R���J�����g�p�����[�^�̒l��\�����郁�b�Z�[�W�̃��O�o��
    xxcff_common1_pkg.put_log_param(
      iv_which   => lv_which_log,  -- �o�͋敪
      ov_retcode => lv_retcode,    -- ���^�[���R�[�h
      ov_errbuf  => lv_errbuf,     -- �G���[���b�Z�[�W
      ov_errmsg  => lv_errmsg      -- ���[�U�[�E�G���[���b�Z�[�W
    );
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_api_expt;
    END IF;
--
    -- ***************************************************
    -- �Ɩ��������t�擾����
    -- ***************************************************
    gd_process_date := xxccp_common_pkg2.get_process_date;
--
    IF (gd_process_date IS NULL ) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg(
                     cv_app_kbn_cff,      -- �A�v���P�[�V�����Z�k��
                     cv_msg_cff_00092     -- ���b�Z�[�W�F�Ɩ��������t�擾�G���[
                     ),1,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
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
  END init;
--
  /**********************************************************************************
   * Procedure Name   : select_vd_object_info
   * Description      : ���̋@�����Ǘ���񒊏o���� (A-2)
   ***********************************************************************************/
  PROCEDURE select_vd_object_info(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'select_vd_object_info'; -- �v���O������
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
    -- ���̋@�����Ǘ����捞�Ώۃf�[�^�擾
    CURSOR get_vd_object_info_cur
    IS
      SELECT xvomi.object_code                object_code,                 -- �����R�[�h
             xvomi.generation_date            generation_date,             -- ������
             xvomi.owner_company_type         owner_company_type,          -- �{��/�H��敪
             xvomi.department_code            department_code,             -- �Ǘ�����
             xvomi.machine_type               machine_type,                -- �@��敪
             xvomi.lease_class                lease_class,                 -- ���[�X���
             xvomi.vendor_code                vendor_code,                 -- �d����R�[�h
             xvomi.manufacturer_name          manufacturer_name,           -- ���[�J��
             xvomi.model                      model,                       -- �@��
             xvomi.age_type                   age_type,                    -- �N��
             xvomi.customer_code              customer_code,               -- �ڋq�R�[�h
             xvomi.quantity                   quantity,                    -- ����
             xvomi.date_placed_in_service     date_placed_in_service,      -- ���Ƌ��p��
             xvomi.assets_cost                assets_cost,                 -- �擾���i
             xvomi.moved_date                 moved_date,                  -- �ړ���
             xvomi.installation_place         installation_place,          -- �ݒu��
             xvomi.installation_address       installation_address,        -- �ݒu�ꏊ
             xvomi.dclr_place                 dclr_place,                  -- �\���n
             xvomi.location                   location,                    -- ���Ə�
             xvomi.date_retired               date_retired,                -- ���E���p��
             xvomi.active_flag                active_flag,                 -- �����L���t���O
             xvomi.import_status              import_status,               -- �捞�X�e�[�^�X
             xvoh.object_header_id            xvoh_object_header_id,       -- ����ID
             xvoh.object_status               xvoh_object_status,          -- �����X�e�[�^�X
             xvoh.owner_company_type          xvoh_owner_company_type,     -- �{�Ё^�H��敪
             xvoh.department_code             xvoh_department_code,        -- �Ǘ�����
             xvoh.manufacturer_name           xvoh_manufacturer_name,      -- ���[�J��
             xvoh.model                       xvoh_model,                  -- �@��
             xvoh.age_type                    xvoh_age_type,               -- �N��
             xvoh.customer_code               xvoh_customer_code,          -- �ڋq�R�[�h
             xvoh.quantity                    xvoh_quantity,               -- ����
             xvoh.date_placed_in_service      xvoh_date_placed_in_service, -- ���Ƌ��p��
             xvoh.assets_cost                 xvoh_assets_cost,            -- �擾���i
             xvoh.moved_date                  xvoh_moved_date,             -- �ړ���
             xvoh.month_lease_charge          xvoh_month_lease_charge,     -- ���z���[�X��
             xvoh.re_lease_charge             xvoh_re_lease_charge,        -- �ă��[�X��
             xvoh.assets_date                 xvoh_assets_date,            -- �擾��
             xvoh.installation_place          xvoh_installation_place,     -- �ݒu��
             xvoh.installation_address        xvoh_installation_address,   -- �ݒu�ꏊ
             xvoh.dclr_place                  xvoh_dclr_place,             -- �\���n
             xvoh.location                    xvoh_location,               -- ���Ə�
             xvoh.date_retired                xvoh_date_retired,           -- ���E���p��
             xvoh.proceeds_of_sale            xvoh_proceeds_of_sale,       -- ���p���i
             xvoh.cost_of_removal             xvoh_cost_of_removal,        -- �P����p
             xvoh.ib_if_date                  xvoh_ib_if_date              -- �ݒu�x�[�X���A�g��
      FROM   xxcff_vd_object_mng_if xvomi,    -- ���̋@�����Ǘ�IF
             xxcff_vd_object_headers xvoh     -- ���̋@�����Ǘ�
      WHERE  xvomi.object_code = xvoh.object_code(+)
        AND  xvomi.import_status = cv_import_status_0
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
    -- �捞�Ώۃf�[�^�̒��o
    OPEN  get_vd_object_info_cur;
    FETCH get_vd_object_info_cur BULK COLLECT INTO g_vd_object_tab;
    CLOSE get_vd_object_info_cur;
--
    -- �Ώۃf�[�^��0���̏ꍇ�A���b�Z�[�W�o��(�x���I��)
    IF (g_vd_object_tab.COUNT = 0) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application => cv_app_kbn_cff,   -- �A�v���P�[�V�����Z�k��
                     iv_name        => cv_msg_cff_00062  -- ���b�Z�[�W�R�[�h
                   );
      FND_FILE.PUT_LINE(
        which => FND_FILE.OUTPUT,
        buff  => lv_errmsg
      );
      ov_retcode := cv_status_warn;
    END IF;
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      IF (get_vd_object_info_cur%ISOPEN) THEN
        CLOSE get_vd_object_info_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END select_vd_object_info;
--
  /**********************************************************************************
   * Procedure Name   : validate_record
   * Description      : �f�[�^�Ó����`�F�b�N���� (A-3)
   ***********************************************************************************/
  PROCEDURE validate_record(
    in_rec_no     IN  NUMBER,       --   �`�F�b�N�Ώۃ��R�[�h�ԍ�
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'validate_record'; -- �v���O������
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
--
    -- *** ���[�J���ϐ� ***
    ln_lb_chk_err_flg BOOLEAN;        -- �������`�F�b�N�G���[�t���O
    ln_location_id    NUMBER;         -- ���Ə�ID
    lv_token_value    VARCHAR2(100);  -- ���b�Z�[�W�o�͎��̃g�[�N�����`�p
--
    -- *** ���[�J���E�J�[�\�� ***
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
    -- �t���O�̏�����
    ln_lb_chk_err_flg := FALSE;
--
    -- �y�}�X�^�`�F�b�N�z
    -- ���ʊ֐�(���Ə��}�X�^�`�F�b�N)�̌Ăяo��
    xxcff_common1_pkg.chk_fa_location(
      iv_segment1    => g_vd_object_tab(in_rec_no).dclr_place,         -- �\���n
      iv_segment2    => g_vd_object_tab(in_rec_no).department_code,    -- �Ǘ�����
      iv_segment3    => g_vd_object_tab(in_rec_no).location,           -- ���Ə�
      iv_segment5    => g_vd_object_tab(in_rec_no).owner_company_type, -- �{�Ё^�H��敪
      on_location_id => ln_location_id,  -- ���Ə�ID
      ov_retcode     => lv_retcode,      -- ���^�[���R�[�h
      ov_errbuf      => lv_errbuf,       -- �G���[���b�Z�[�W
      ov_errmsg      => lv_errmsg        -- ���[�U�[�E�G���[���b�Z�[�W
    );
    IF (lv_retcode = cv_status_error) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_kbn_cff,    -- �A�v���P�[�V�����Z�k��
                     iv_name         => cv_msg_cff_00094,  -- ���b�Z�[�W�R�[�h
                     iv_token_name1  => cv_tkn_cff_00094,  -- �g�[�N���R�[�h1
                     iv_token_value1 => cv_msg_cff_50141   -- �g�[�N���l1
                   );
      lv_errbuf := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_kbn_cff,    -- �A�v���P�[�V�����Z�k��
                     iv_name         => cv_msg_cff_00095,  -- ���b�Z�[�W�R�[�h
                     iv_token_name1  => cv_tkn_cff_00095,  -- �g�[�N���R�[�h1
                     iv_token_value1 => lv_errbuf          -- �g�[�N���l1
                   );
      lv_errmsg := lv_errmsg || lv_errbuf;
      FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT,
        buff   => lv_errmsg
      );
      FND_FILE.PUT_LINE(
        which  => FND_FILE.LOG,
        buff   => lv_errmsg
      );
      ln_lb_chk_err_flg := TRUE;
    END IF;
--
    -- �y�������`�F�b�N�z
    -- �u�捞�σf�[�^�̐ݒu�x�[�X���A�g���v���u�������v�̊֌W�łȂ��ꍇ�A���b�Z�[�W�o��
    IF (g_vd_object_tab(in_rec_no).xvoh_ib_if_date >= g_vd_object_tab(in_rec_no).generation_date) THEN
      -- �u�捞�σf�[�^�̐ݒu�x�[�X���A�g���v�𕶎���^�ɕϊ����A�g�[�N���l�ɐݒ�
      lv_token_value := TO_CHAR(g_vd_object_tab(in_rec_no).xvoh_ib_if_date, cv_date_format);
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_kbn_cff,       -- �A�v���P�[�V�����Z�k��
                     iv_name         => cv_msg_cff_00209,     -- ���b�Z�[�W�R�[�h
                     iv_token_name1  => cv_tkn_cff_00209,     -- �g�[�N���R�[�h1
                     iv_token_value1 => lv_token_value        -- �g�[�N���l1
                   );
      lv_token_value := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_kbn_cff,       -- �A�v���P�[�V�����Z�k��
                     iv_name         => cv_msg_cff_50137      -- ���b�Z�[�W�R�[�h
                   );
      -- �u�����R�[�h�v���g�[�N���l�ɐݒ�
      lv_token_value := lv_token_value || g_vd_object_tab(in_rec_no).object_code;
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_kbn_cff,       -- �A�v���P�[�V�����Z�k��
                     iv_name         => cv_msg_cff_00093,     -- ���b�Z�[�W�R�[�h
                     iv_token_name1  => cv_tkn_cff_00093_01,  -- �g�[�N���R�[�h1
                     iv_token_value1 => lv_errmsg,            -- �g�[�N���l1
                     iv_token_name2  => cv_tkn_cff_00093_02,  -- �g�[�N���R�[�h2
                     iv_token_value2 => lv_token_value        -- �g�[�N���l2
                   );
      FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT,
        buff   => lv_errmsg
      );
      FND_FILE.PUT_LINE(
        which  => FND_FILE.LOG,
        buff   => lv_errmsg
      );
      ln_lb_chk_err_flg := TRUE;
    END IF;
--
    -- �y�����p�X�e�[�^�X�G���[�`�F�b�N�z
    -- �捞�σf�[�^�́u�����X�e�[�^�X�v�� '106'�i�����p�j�̏ꍇ
    IF ( g_vd_object_tab(in_rec_no).xvoh_object_status = cv_obj_status_106) THEN
      -- ���̋@�����Ǘ�IF�̎捞�X�e�[�^�X��'9'�i�����p�X�e�[�^�X�G���[�j�ɍX�V
      UPDATE xxcff_vd_object_mng_if  xvomi    -- ���̋@�����Ǘ�IF
      SET    xvomi.import_status           =  cv_import_status_9,         -- �捞�X�e�[�^�X
             xvomi.last_updated_by         =  cn_last_updated_by,         -- �ŏI�X�V��
             xvomi.last_update_date        =  cd_last_update_date,        -- �ŏI�X�V��
             xvomi.last_update_login       =  cn_last_update_login,       -- �ŏI�X�V���O�C��
             xvomi.request_id              =  cn_request_id,              -- �v��ID
             xvomi.program_application_id  =  cn_program_application_id,  -- �R���J�����g��v���O������A�v���P�[�V����
             xvomi.program_id              =  cn_program_id,              -- �R���J�����g��v���O����ID
             xvomi.program_update_date     =  cd_program_update_date      -- �v���O�����X�V��
      WHERE  g_vd_object_tab(in_rec_no).object_code = xvomi.object_code   -- �����R�[�h
      ;
--
      -- �u�����p�X�e�[�^�X�G���[���b�Z�[�W�v��\��
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_kbn_cff,       -- �A�v���P�[�V�����Z�k��
                     iv_name         => cv_msg_cff_00212      -- ���b�Z�[�W�R�[�h
                   );
      lv_token_value := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_kbn_cff,       -- �A�v���P�[�V�����Z�k��
                     iv_name         => cv_msg_cff_50137      -- ���b�Z�[�W�R�[�h
                   );
      -- �u�����R�[�h�v���g�[�N���l�ɐݒ�
      lv_token_value := lv_token_value || g_vd_object_tab(in_rec_no).object_code;
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_kbn_cff,       -- �A�v���P�[�V�����Z�k��
                     iv_name         => cv_msg_cff_00093,     -- ���b�Z�[�W�R�[�h
                     iv_token_name1  => cv_tkn_cff_00093_01,  -- �g�[�N���R�[�h1
                     iv_token_value1 => lv_errmsg,            -- �g�[�N���l1
                     iv_token_name2  => cv_tkn_cff_00093_02,  -- �g�[�N���R�[�h2
                     iv_token_value2 => lv_token_value        -- �g�[�N���l2
                   );
      FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT,
        buff   => lv_errmsg
      );
      FND_FILE.PUT_LINE(
        which  => FND_FILE.LOG,
        buff   => lv_errmsg
      );
      ln_lb_chk_err_flg := TRUE;
    END IF;
--
    -- �y���E���p���A�g�G���[�`�F�b�N�z
    -- �u�����X�e�[�^�X�v�����̋@�����Ǘ��A�h�I���ɑ��݂��Ȃ��A�܂���'101'�i���m��j�Ɠ������ꍇ
    --  ���A���̋@�����Ǘ�IF����u���E���p���v���A�g���ꂽ�ꍇ
    IF ( (g_vd_object_tab(in_rec_no).xvoh_object_status IS NULL
        OR g_vd_object_tab(in_rec_no).xvoh_object_status = cv_obj_status_101)
      AND g_vd_object_tab(in_rec_no).date_retired IS NOT NULL )
    THEN
      -- �u���E���p���A�g�G���[���b�Z�[�W�v��\��
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_kbn_cff,       -- �A�v���P�[�V�����Z�k��
                     iv_name         => cv_msg_cff_00211      -- ���b�Z�[�W�R�[�h
                   );
      lv_token_value := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_kbn_cff,       -- �A�v���P�[�V�����Z�k��
                     iv_name         => cv_msg_cff_50137      -- ���b�Z�[�W�R�[�h
                   );
      -- �u�����R�[�h�v���g�[�N���l�ɐݒ�
      lv_token_value := lv_token_value || g_vd_object_tab(in_rec_no).object_code;
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_kbn_cff,       -- �A�v���P�[�V�����Z�k��
                     iv_name         => cv_msg_cff_00093,     -- ���b�Z�[�W�R�[�h
                     iv_token_name1  => cv_tkn_cff_00093_01,  -- �g�[�N���R�[�h1
                     iv_token_value1 => lv_errmsg,            -- �g�[�N���l1
                     iv_token_name2  => cv_tkn_cff_00093_02,  -- �g�[�N���R�[�h2
                     iv_token_value2 => lv_token_value        -- �g�[�N���l2
                   );
      FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT,
        buff   => lv_errmsg
      );
      FND_FILE.PUT_LINE(
        which  => FND_FILE.LOG,
        buff   => lv_errmsg
      );
      ln_lb_chk_err_flg := TRUE;
    END IF;
--
    -- �������`�F�b�N�ŃG���[�̏ꍇ�A�X�e�[�^�X��'1'(�x��)��ݒ�
    IF (ln_lb_chk_err_flg) THEN
      ov_retcode := cv_status_warn;
    END IF;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
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
  END validate_record;
--
  /**********************************************************************************
   * Procedure Name   : ins_vd_obj_hist
   * Description      : ���̋@��������o�^ (A-5)
   ***********************************************************************************/
  PROCEDURE ins_vd_obj_hist(
    in_rec_no           IN NUMBER,     -- �`�F�b�N�Ώۃ��R�[�h�ԍ�
    in_object_header_id IN NUMBER,     -- ����ID
    iv_process_type     IN VARCHAR2,   -- �����敪
    iv_object_status    IN VARCHAR2,   -- �����X�e�[�^�X
    ov_errbuf           OUT VARCHAR2,  -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT VARCHAR2,  -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT VARCHAR2)  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_vd_obj_hist'; -- �v���O������
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
    ln_history_num_max NUMBER; -- ����ԍ��i�ő�l�j
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
    -- ����ԍ��i�ő�l�j��ݒ�
    -- �u���m��v�̏ꍇ�A����ԍ���'1'�Œ�
    IF ( iv_object_status = cv_obj_status_101 ) THEN
      ln_history_num_max := 1;
    ELSE
      SELECT MAX(xvohi.history_num)
      INTO   ln_history_num_max
      FROM   xxcff_vd_object_histories xvohi  -- ���̋@��������
      WHERE  xvohi.object_header_id = in_object_header_id
      ;
      ln_history_num_max := ln_history_num_max + 1;
    END IF;
--
    -- ***************************************************
    -- ���̋@��������o�^
    -- ***************************************************
    INSERT INTO xxcff_vd_object_histories(
           object_header_id        -- ����ID
         , object_code             -- �����R�[�h
         , history_num             -- ����ԍ�
         , process_type            -- �����敪
         , process_date            -- ������
         , object_status           -- �����X�e�[�^�X
         , owner_company_type      -- �{�Ё^�H��敪
         , department_code         -- �Ǘ�����
         , machine_type            -- �@��敪
         , manufacturer_name       -- ���[�J�[��
         , model                   -- �@��
         , age_type                -- �N��
         , customer_code           -- �ڋq�R�[�h
         , quantity                -- ����
         , date_placed_in_service  -- ���Ƌ��p��
         , assets_cost             -- �擾���i
         , month_lease_charge      -- ���z���[�X��
         , re_lease_charge         -- �ă��[�X��
         , assets_date             -- �擾��
         , moved_date              -- �ړ���
         , installation_place      -- �ݒu��
         , installation_address    -- �ݒu�ꏊ
         , dclr_place              -- �\���n
         , location                -- ���Ə�
         , date_retired            -- ���E���p��
         , proceeds_of_sale        -- ���p���i
         , cost_of_removal         -- �P����p
         , retired_flag            -- �����p�m��t���O
         , ib_if_date              -- �ݒu�x�[�X���A�g��
         , fa_if_date              -- FA���A�g��
         , fa_if_flag              -- FA�A�g�t���O
         , created_by              -- �쐬��
         , creation_date           -- �쐬��
         , last_updated_by         -- �ŏI�X�V��
         , last_update_date        -- �ŏI�X�V��
         , last_update_login       -- �ŏI�X�V۸޲�
         , request_id              -- �v��ID
         , program_application_id  -- �ݶ��ĥ��۸��ѥ���ع����ID
         , program_id              -- �ݶ��ĥ��۸���ID
         , program_update_date     -- ��۸��эX�V��
        )
        VALUES(
           in_object_header_id                                -- ����ID
         , g_vd_object_tab(in_rec_no).object_code             -- �����R�[�h
         , ln_history_num_max                                 -- ����ԍ�
         , iv_process_type                                    -- �����敪
         , gd_process_date                                    -- ������
         , iv_object_status                                   -- �����X�e�[�^�X
         , g_vd_object_tab(in_rec_no).owner_company_type      -- �{�Ё^�H��敪
         , g_vd_object_tab(in_rec_no).department_code         -- �Ǘ�����
         , g_vd_object_tab(in_rec_no).machine_type            -- �@��敪
         , g_vd_object_tab(in_rec_no).manufacturer_name       -- ���[�J�[��
         , g_vd_object_tab(in_rec_no).model                   -- �@��
         , g_vd_object_tab(in_rec_no).age_type                -- �N��
         , g_vd_object_tab(in_rec_no).customer_code           -- �ڋq�R�[�h
         , g_vd_object_tab(in_rec_no).quantity                -- ����
         , g_vd_object_tab(in_rec_no).date_placed_in_service  -- ���Ƌ��p��
         , g_vd_object_tab(in_rec_no).assets_cost             -- �擾���i
         , g_vd_object_tab(in_rec_no).xvoh_month_lease_charge -- ���z���[�X��
         , g_vd_object_tab(in_rec_no).xvoh_re_lease_charge    -- �ă��[�X��
         , g_vd_object_tab(in_rec_no).xvoh_assets_date        -- �擾��
         , g_vd_object_tab(in_rec_no).moved_date              -- �ړ���
         , g_vd_object_tab(in_rec_no).installation_place      -- �ݒu��
         , g_vd_object_tab(in_rec_no).installation_address    -- �ݒu�ꏊ
         , g_vd_object_tab(in_rec_no).dclr_place              -- �\���n
         , g_vd_object_tab(in_rec_no).location                -- ���Ə�
         , g_vd_object_tab(in_rec_no).date_retired            -- ���E���p��
         , g_vd_object_tab(in_rec_no).xvoh_proceeds_of_sale   -- ���p���i
         , g_vd_object_tab(in_rec_no).xvoh_cost_of_removal    -- �P����p
         , gv_flag_off                                        -- �����p�m��t���O
         , g_vd_object_tab(in_rec_no).generation_date         -- �ݒu�x�[�X���A�g��
         , NULL                                               -- FA���A�g��
         , gv_flag_off                                        -- FA�A�g�t���O
         , cn_created_by                                      -- �쐬��
         , cd_creation_date                                   -- �쐬��
         , cn_last_updated_by                                 -- �ŏI�X�V��
         , cd_last_update_date                                -- �ŏI�X�V��
         , cn_last_update_login                               -- �ŏI�X�V۸޲�
         , cn_request_id                                      -- �v��ID
         , cn_program_application_id                          -- �ݶ��ĥ��۸��ѥ���ع����ID
         , cn_program_id                                      -- �ݶ��ĥ��۸���ID
         , cd_program_update_date                             -- ��۸��эX�V��
        )
        ;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errmsg  := SQLERRM;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END ins_vd_obj_hist;
--
  /**********************************************************************************
   * Procedure Name   : ins_upd_vd_object
   * Description      : ���̋@���o�^�^�X�V (A-4)
   ***********************************************************************************/
  PROCEDURE ins_upd_vd_object(
    in_rec_no     IN  NUMBER,       --   �`�F�b�N�Ώۃ��R�[�h�ԍ�
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_upd_vd_object'; -- �v���O������
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
    cv_dummy             CONSTANT VARCHAR2(5)  := 'XXXXX';    -- NVL�p�_�~�[�l
    cv_tkn_val_00213     CONSTANT VARCHAR2(16) := '����ID';   -- �V�[�P���X�擾�G���[�g�[�N���l
--
    -- *** ���[�J���ϐ� ***
    lv_token_value      VARCHAR2(100);         -- ���b�Z�[�W�o�͎��̃g�[�N�����`�p
    lv_object_header_id NUMBER;                -- ����ID
    lv_process_type     NUMBER;                -- �����敪
    lv_object_status    NUMBER;                -- �����X�e�[�^�X
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
    -- �P�DA-2�Ŏ擾���������X�e�[�^�X�����̋@�����Ǘ��A�h�I���ɑ��݂��Ȃ��ꍇ
    IF ( g_vd_object_tab(in_rec_no).xvoh_object_status IS NULL ) THEN
--
      -- ***************************************************
      -- �V�[�P���X�̎擾
      -- ***************************************************
      SELECT xxcff_vd_object_headers_s1.NEXTVAL
      INTO   lv_object_header_id
      FROM   dual
      ;
--
      IF ( lv_object_header_id IS NULL ) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_kbn_cff,    -- �A�v���P�[�V�����Z�k��
                     iv_name         => cv_msg_cff_00213,  -- ���b�Z�[�W�R�[�h
                     iv_token_name1  => cv_tkn_cff_00213,  -- �g�[�N���R�[�h1
                     iv_token_value1 => cv_tkn_val_00213   -- �g�[�N���l1
                   );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
--
      -- ***************************************************
      -- ���̋@�����Ǘ��o�^
      -- ***************************************************
      INSERT INTO xxcff_vd_object_headers(
         object_header_id        -- ����ID
       , object_code             -- �����R�[�h
       , object_status           -- �����X�e�[�^�X
       , owner_company_type      -- �{�Ё^�H��敪
       , department_code         -- �Ǘ�����
       , machine_type            -- �@��敪
       , lease_class             -- ���[�X���
       , vendor_code             -- �d����R�[�h
       , manufacturer_name       -- ���[�J�[��
       , model                   -- �@��
       , age_type                -- �N��
       , customer_code           -- �ڋq�R�[�h
       , quantity                -- ����
       , date_placed_in_service  -- ���Ƌ��p��
       , assets_cost             -- �擾���i
       , assets_date             -- �擾��
       , moved_date              -- �ړ���
       , installation_place      -- �ݒu��
       , installation_address    -- �ݒu�ꏊ
       , dclr_place              -- �\���n
       , location                -- ���Ə�
       , date_retired            -- ���E���p��
       , proceeds_of_sale        -- ���p���i
       , cost_of_removal         -- �P����p
       , retired_flag            -- �����p�m��t���O
       , ib_if_date              -- �ݒu�x�[�X���A�g��
       , created_by              -- �쐬��
       , creation_date           -- �쐬��
       , last_updated_by         -- �ŏI�X�V��
       , last_update_date        -- �ŏI�X�V��
       , last_update_login       -- �ŏI�X�V۸޲�
       , request_id              -- �v��ID
       , program_application_id  -- �ݶ��ĥ��۸��ѥ���ع����ID
       , program_id              -- �ݶ��ĥ��۸���ID
       , program_update_date     -- ��۸��эX�V��
      )
      VALUES(
         lv_object_header_id                                -- ����ID
       , g_vd_object_tab(in_rec_no).object_code             -- �����R�[�h
       , cv_obj_status_101                                  -- �����X�e�[�^�X
       , g_vd_object_tab(in_rec_no).owner_company_type      -- �{�Ё^�H��敪
       , g_vd_object_tab(in_rec_no).department_code         -- �Ǘ�����
       , g_vd_object_tab(in_rec_no).machine_type            -- �@��敪
       , g_vd_object_tab(in_rec_no).lease_class             -- ���[�X���
       , g_vd_object_tab(in_rec_no).vendor_code             -- �d����R�[�h
       , g_vd_object_tab(in_rec_no).manufacturer_name       -- ���[�J�[��
       , g_vd_object_tab(in_rec_no).model                   -- �@��
       , g_vd_object_tab(in_rec_no).age_type                -- �N��
       , g_vd_object_tab(in_rec_no).customer_code           -- �ڋq�R�[�h
       , g_vd_object_tab(in_rec_no).quantity                -- ����
       , g_vd_object_tab(in_rec_no).date_placed_in_service  -- ���Ƌ��p��
       , g_vd_object_tab(in_rec_no).assets_cost             -- �擾���i
       , g_vd_object_tab(in_rec_no).xvoh_assets_date        -- �擾��
       , g_vd_object_tab(in_rec_no).moved_date              -- �ړ���
       , g_vd_object_tab(in_rec_no).installation_place      -- �ݒu��
       , g_vd_object_tab(in_rec_no).installation_address    -- �ݒu�ꏊ
       , g_vd_object_tab(in_rec_no).dclr_place              -- �\���n
       , g_vd_object_tab(in_rec_no).location                -- ���Ə�
       , g_vd_object_tab(in_rec_no).date_retired            -- ���E���p��
       , g_vd_object_tab(in_rec_no).xvoh_proceeds_of_sale   -- ���p���i
       , g_vd_object_tab(in_rec_no).xvoh_cost_of_removal    -- �P����p
       , gv_flag_off                                        -- �����p�m��t���O
       , g_vd_object_tab(in_rec_no).generation_date         -- �ݒu�x�[�X���A�g��
       , cn_created_by                                      -- �쐬��
       , cd_creation_date                                   -- �쐬��
       , cn_last_updated_by                                 -- �ŏI�X�V��
       , cd_last_update_date                                -- �ŏI�X�V��
       , cn_last_update_login                               -- �ŏI�X�V۸޲�
       , cn_request_id                                      -- �v��ID
       , cn_program_application_id                          -- �ݶ��ĥ��۸��ѥ���ع����ID
       , cn_program_id                                      -- �ݶ��ĥ��۸���ID
       , cd_program_update_date                             -- ��۸��эX�V��
      )
      ;
--
      -- =====================================================
      --  ���̋@��������o�^ (A-5)
      -- =====================================================
      ins_vd_obj_hist(
        in_rec_no,            -- �`�F�b�N�Ώۃ��R�[�h�ԍ�
        lv_object_header_id,  -- ����ID
        cv_obj_status_101,    -- �����敪�i'101' ���m��j
        cv_obj_status_101,    -- �����X�e�[�^�X�i'101' ���m��j 
        lv_errbuf,            -- �G���[�E���b�Z�[�W           --# �Œ� #
        lv_retcode,           -- ���^�[���E�R�[�h             --# �Œ� #
        lv_errmsg);           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      IF (lv_retcode = cv_status_error) THEN
        RAISE global_api_expt;
      END IF;
    END IF;
--
    -- �Q�D���̋@�����Ǘ��A�h�I���̕����X�e�[�^�X���u���m��v�̏ꍇ
    IF ( g_vd_object_tab(in_rec_no).xvoh_object_status = cv_obj_status_101 ) THEN
--
      -- ***************************************************
      -- ���̋@�����Ǘ��X�V
      -- ***************************************************
      UPDATE xxcff_vd_object_headers  xvoh    -- ���̋@�����Ǘ�
      SET    xvoh.owner_company_type     = g_vd_object_tab(in_rec_no).owner_company_type,    -- �{�Ё^�H��敪
             xvoh.department_code        = g_vd_object_tab(in_rec_no).department_code,       -- �Ǘ�����
             xvoh.machine_type           = g_vd_object_tab(in_rec_no).machine_type,          -- �@��敪
             xvoh.lease_class            = g_vd_object_tab(in_rec_no).lease_class,           -- ���[�X���
             xvoh.manufacturer_name      = g_vd_object_tab(in_rec_no).manufacturer_name,     -- ���[�J�[��
             xvoh.model                  = g_vd_object_tab(in_rec_no).model,                 -- �@��
             xvoh.age_type               = g_vd_object_tab(in_rec_no).age_type,              -- �N��
             xvoh.customer_code          = g_vd_object_tab(in_rec_no).customer_code,         -- �ڋq�R�[�h
             xvoh.quantity               = g_vd_object_tab(in_rec_no).quantity,              -- ����
             xvoh.date_placed_in_service = g_vd_object_tab(in_rec_no).date_placed_in_service,-- ���Ƌ��p��
             xvoh.assets_cost            = g_vd_object_tab(in_rec_no).assets_cost,           -- �擾���i
             xvoh.assets_date            = g_vd_object_tab(in_rec_no).xvoh_assets_date,      -- �擾��
             xvoh.moved_date             = g_vd_object_tab(in_rec_no).moved_date,            -- �ړ���
             xvoh.installation_place     = g_vd_object_tab(in_rec_no).installation_place,    -- �ݒu��
             xvoh.installation_address   = g_vd_object_tab(in_rec_no).installation_address,  -- �ݒu�ꏊ
             xvoh.dclr_place             = g_vd_object_tab(in_rec_no).dclr_place,            -- �\���n
             xvoh.location               = g_vd_object_tab(in_rec_no).location,              -- ���Ə�
             xvoh.date_retired           = g_vd_object_tab(in_rec_no).date_retired,          -- ���E���p��
             xvoh.proceeds_of_sale       = g_vd_object_tab(in_rec_no).xvoh_proceeds_of_sale, -- ���p���i
             xvoh.cost_of_removal        = g_vd_object_tab(in_rec_no).xvoh_cost_of_removal,  -- �P����p
             xvoh.ib_if_date             = g_vd_object_tab(in_rec_no).generation_date,       -- �ݒu�x�[�X���A�g��
             xvoh.last_updated_by        = cn_last_updated_by,                               -- �ŏI�X�V��
             xvoh.last_update_date       = cd_last_update_date,                              -- �ŏI�X�V��
             xvoh.last_update_login      = cn_last_update_login,                             -- �ŏI�X�V���O�C��
             xvoh.request_id             = cn_request_id,                                    -- �v��ID
             xvoh.program_application_id = cn_program_application_id,                        -- �R���J�����g��v���O������A�v���P�[�V����
             xvoh.program_id             = cn_program_id,                                    -- �R���J�����g��v���O����ID
             xvoh.program_update_date    = cd_program_update_date                            -- �v���O�����X�V��
      WHERE  xvoh.object_header_id  = g_vd_object_tab(in_rec_no).xvoh_object_header_id   -- ����ID
      ;
--
      -- ***************************************************
      -- ���̋@���������X�V
      -- ***************************************************
      UPDATE xxcff_vd_object_histories  xvohi  -- ���̋@�����Ǘ�
      SET    xvohi.process_date           = gd_process_date,                                  -- ������
             xvohi.owner_company_type     = g_vd_object_tab(in_rec_no).owner_company_type,    -- �{�Ё^�H��敪
             xvohi.department_code        = g_vd_object_tab(in_rec_no).department_code,       -- �Ǘ�����
             xvohi.machine_type           = g_vd_object_tab(in_rec_no).machine_type,          -- �@��敪
             xvohi.manufacturer_name      = g_vd_object_tab(in_rec_no).manufacturer_name,     -- ���[�J�[��
             xvohi.model                  = g_vd_object_tab(in_rec_no).model,                 -- �@��
             xvohi.age_type               = g_vd_object_tab(in_rec_no).age_type,              -- �N��
             xvohi.customer_code          = g_vd_object_tab(in_rec_no).customer_code,         -- �ڋq�R�[�h
             xvohi.quantity               = g_vd_object_tab(in_rec_no).quantity,              -- ����
             xvohi.date_placed_in_service = g_vd_object_tab(in_rec_no).date_placed_in_service,-- ���Ƌ��p��
             xvohi.assets_cost            = g_vd_object_tab(in_rec_no).assets_cost,           -- �擾���i
             xvohi.assets_date            = g_vd_object_tab(in_rec_no).xvoh_assets_date,      -- �擾��
             xvohi.moved_date             = g_vd_object_tab(in_rec_no).moved_date,            -- �ړ���
             xvohi.installation_place     = g_vd_object_tab(in_rec_no).installation_place,    -- �ݒu��
             xvohi.installation_address   = g_vd_object_tab(in_rec_no).installation_address,  -- �ݒu�ꏊ
             xvohi.dclr_place             = g_vd_object_tab(in_rec_no).dclr_place,            -- �\���n
             xvohi.location               = g_vd_object_tab(in_rec_no).location,              -- ���Ə�
             xvohi.date_retired           = g_vd_object_tab(in_rec_no).date_retired,          -- ���E���p��
             xvohi.proceeds_of_sale       = g_vd_object_tab(in_rec_no).xvoh_proceeds_of_sale, -- ���p���i
             xvohi.cost_of_removal        = g_vd_object_tab(in_rec_no).xvoh_cost_of_removal,  -- �P����p
             xvohi.ib_if_date             = g_vd_object_tab(in_rec_no).generation_date,       -- �ݒu�x�[�X���A�g��
             xvohi.last_updated_by        = cn_last_updated_by,                               -- �ŏI�X�V��
             xvohi.last_update_date       = cd_last_update_date,                              -- �ŏI�X�V��
             xvohi.last_update_login      = cn_last_update_login,                             -- �ŏI�X�V���O�C��
             xvohi.request_id             = cn_request_id,                                    -- �v��ID
             xvohi.program_application_id = cn_program_application_id,                        -- �R���J�����g��v���O������A�v���P�[�V����
             xvohi.program_id             = cn_program_id,                                    -- �R���J�����g��v���O����ID
             xvohi.program_update_date    = cd_program_update_date                            -- �v���O�����X�V��
      WHERE  xvohi.object_header_id  = g_vd_object_tab(in_rec_no).xvoh_object_header_id   -- ����ID
        AND  xvohi.history_num = 1   -- ����ԍ�
      ;
    END IF;
--
    -- �R�D���̋@�����Ǘ��A�h�I���̕����X�e�[�^�X���u�m��ρv�A�܂��́u�����p���m��v�̏ꍇ
    IF ( g_vd_object_tab(in_rec_no).xvoh_object_status = cv_obj_status_102
      OR g_vd_object_tab(in_rec_no).xvoh_object_status = cv_obj_status_105)
    THEN
      -- �ړ��̏ꍇ
      IF ( g_vd_object_tab(in_rec_no).owner_company_type
             <> NVL(g_vd_object_tab(in_rec_no).xvoh_owner_company_type,cv_dummy)   -- �{��/�H��敪
        OR g_vd_object_tab(in_rec_no).department_code
             <> NVL(g_vd_object_tab(in_rec_no).xvoh_department_code,cv_dummy)      -- �Ǘ�����
        OR g_vd_object_tab(in_rec_no).installation_address
             <> NVL(g_vd_object_tab(in_rec_no).xvoh_installation_address,cv_dummy) -- �ݒu�ꏊ
        OR g_vd_object_tab(in_rec_no).dclr_place
             <> NVL(g_vd_object_tab(in_rec_no).xvoh_dclr_place,cv_dummy)           -- �\���n
        OR g_vd_object_tab(in_rec_no).location
             <> NVL(g_vd_object_tab(in_rec_no).xvoh_location,cv_dummy)             -- ���Ə�
        OR g_vd_object_tab(in_rec_no).customer_code
             <> NVL(g_vd_object_tab(in_rec_no).xvoh_customer_code,cv_dummy)        -- �ڋq�R�[�h
        OR g_vd_object_tab(in_rec_no).installation_place
             <> NVL(g_vd_object_tab(in_rec_no).xvoh_installation_place,cv_dummy)   -- �ݒu��
      )
      THEN
        -- �ړ�����NULL�̏ꍇ�͋Ɩ����t���Z�b�g
        IF ( g_vd_object_tab(in_rec_no).moved_date IS NULL) THEN
          g_vd_object_tab(in_rec_no).moved_date := gd_process_date;
        END IF;
--        
        -- ***************************************************
        -- ���̋@�����Ǘ��X�V
        -- ***************************************************
        UPDATE xxcff_vd_object_headers  xvoh    -- ���̋@�����Ǘ�
        SET    xvoh.owner_company_type     = g_vd_object_tab(in_rec_no).owner_company_type,   -- �{�Ё^�H��敪
               xvoh.department_code        = g_vd_object_tab(in_rec_no).department_code,      -- �Ǘ�����
               xvoh.customer_code          = g_vd_object_tab(in_rec_no).customer_code,        -- �ڋq�R�[�h
               xvoh.installation_place     = g_vd_object_tab(in_rec_no).installation_place,   -- �ݒu��
               xvoh.installation_address   = g_vd_object_tab(in_rec_no).installation_address, -- �ݒu�ꏊ
               xvoh.dclr_place             = g_vd_object_tab(in_rec_no).dclr_place,           -- �\���n
               xvoh.location               = g_vd_object_tab(in_rec_no).location,             -- ���Ə�
               xvoh.moved_date             = g_vd_object_tab(in_rec_no).moved_date,           -- �ړ���
               xvoh.ib_if_date             = g_vd_object_tab(in_rec_no).generation_date,      -- �ݒu�x�[�X���A�g��
               xvoh.last_updated_by        = cn_last_updated_by,                              -- �ŏI�X�V��
               xvoh.last_update_date       = cd_last_update_date,                             -- �ŏI�X�V��
               xvoh.last_update_login      = cn_last_update_login,                            -- �ŏI�X�V���O�C��
               xvoh.request_id             = cn_request_id,                                   -- �v��ID
               xvoh.program_application_id = cn_program_application_id,                       -- �R���J�����g��v���O������A�v���P�[�V����
               xvoh.program_id             = cn_program_id,                                   -- �R���J�����g��v���O����ID
               xvoh.program_update_date    = cd_program_update_date                           -- �v���O�����X�V��
        WHERE  xvoh.object_header_id  = g_vd_object_tab(in_rec_no).xvoh_object_header_id   -- ����ID
        ;
--
        -- =====================================================
        --  ���̋@��������o�^ (A-5)
        -- =====================================================
        ins_vd_obj_hist(
          in_rec_no,                                         -- �`�F�b�N�Ώۃ��R�[�h�ԍ�
          g_vd_object_tab(in_rec_no).xvoh_object_header_id,  -- ����ID
          cv_obj_status_103,                                 -- �����敪�i'103' �ړ��j
          g_vd_object_tab(in_rec_no).xvoh_object_status,     -- �����X�e�[�^�X�i'102' �m��� or '105' �����p���m��j 
          lv_errbuf,            -- �G���[�E���b�Z�[�W           --# �Œ� #
          lv_retcode,           -- ���^�[���E�R�[�h             --# �Œ� #
          lv_errmsg);           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        IF (lv_retcode = cv_status_error) THEN
          RAISE global_api_expt;
        END IF;
      END IF;
--
      -- �C���̏ꍇ
      IF ( g_vd_object_tab(in_rec_no).manufacturer_name
             <> NVL(g_vd_object_tab(in_rec_no).xvoh_manufacturer_name,cv_dummy)     -- ���[�J��
        OR g_vd_object_tab(in_rec_no).model
             <> NVL(g_vd_object_tab(in_rec_no).xvoh_model,cv_dummy)                 -- �@��
        OR g_vd_object_tab(in_rec_no).age_type
             <> NVL(g_vd_object_tab(in_rec_no).xvoh_age_type,cv_dummy)              -- �N��
        OR TO_CHAR( g_vd_object_tab(in_rec_no).quantity )
             <> NVL(TO_CHAR(g_vd_object_tab(in_rec_no).xvoh_quantity),cv_dummy)     -- ����
        OR TO_CHAR( g_vd_object_tab(in_rec_no).date_placed_in_service, cv_date_format)
             <> NVL(TO_CHAR(g_vd_object_tab(in_rec_no).xvoh_date_placed_in_service, cv_date_format),cv_dummy) -- ���Ƌ��p��
        OR TO_CHAR( g_vd_object_tab(in_rec_no).assets_cost )
             <> NVL(TO_CHAR( g_vd_object_tab(in_rec_no).xvoh_assets_cost),cv_dummy) -- �擾���i
      )
      THEN
        -- �ړ����͍X�V���Ȃ�
        g_vd_object_tab(in_rec_no).moved_date := g_vd_object_tab(in_rec_no).xvoh_moved_date;
        -- ***************************************************
        -- ���̋@�����Ǘ��X�V
        -- ***************************************************
        UPDATE xxcff_vd_object_headers  xvoh    -- ���̋@�����Ǘ�
        SET    xvoh.manufacturer_name      = g_vd_object_tab(in_rec_no).manufacturer_name,     -- ���[�J�[��
               xvoh.model                  = g_vd_object_tab(in_rec_no).model,                 -- �@��
               xvoh.age_type               = g_vd_object_tab(in_rec_no).age_type,              -- �N��
               xvoh.quantity               = g_vd_object_tab(in_rec_no).quantity,              -- ����
               xvoh.date_placed_in_service = g_vd_object_tab(in_rec_no).date_placed_in_service,-- ���Ƌ��p��
               xvoh.assets_cost            = g_vd_object_tab(in_rec_no).assets_cost,           -- �擾���i
               xvoh.ib_if_date             = g_vd_object_tab(in_rec_no).generation_date,       -- �ݒu�x�[�X���A�g��
               xvoh.last_updated_by        = cn_last_updated_by,                               -- �ŏI�X�V��
               xvoh.last_update_date       = cd_last_update_date,                              -- �ŏI�X�V��
               xvoh.last_update_login      = cn_last_update_login,                             -- �ŏI�X�V���O�C��
               xvoh.request_id             = cn_request_id,                                    -- �v��ID
               xvoh.program_application_id = cn_program_application_id,                        -- �R���J�����g��v���O������A�v���P�[�V����
               xvoh.program_id             = cn_program_id,                                    -- �R���J�����g��v���O����ID
               xvoh.program_update_date    = cd_program_update_date                            -- �v���O�����X�V��
        WHERE  xvoh.object_header_id  = g_vd_object_tab(in_rec_no).xvoh_object_header_id   -- ����ID
        ;
--
        -- =====================================================
        --  ���̋@��������o�^ (A-5)
        -- =====================================================
        ins_vd_obj_hist(
          in_rec_no,                                         -- �`�F�b�N�Ώۃ��R�[�h�ԍ�
          g_vd_object_tab(in_rec_no).xvoh_object_header_id,  -- ����ID
          cv_obj_status_104,                                 -- �����敪�i'104' �C���j
          g_vd_object_tab(in_rec_no).xvoh_object_status,     -- �����X�e�[�^�X�i'102' �m��� or '105' �����p���m��j 
          lv_errbuf,            -- �G���[�E���b�Z�[�W           --# �Œ� #
          lv_retcode,           -- ���^�[���E�R�[�h             --# �Œ� #
          lv_errmsg);           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        IF (lv_retcode = cv_status_error) THEN
          RAISE global_api_expt;
        END IF;
      END IF;
--
      -- �����p���m��̏ꍇ(�u�m��ρv�ŏ��E���p�����A�g or �u�����p���m��v�ŏ��E���p�����ύX�j
      IF ( (g_vd_object_tab(in_rec_no).xvoh_object_status = cv_obj_status_102
          AND g_vd_object_tab(in_rec_no).date_retired IS NOT NULL)
        OR (g_vd_object_tab(in_rec_no).xvoh_object_status = cv_obj_status_105
          AND g_vd_object_tab(in_rec_no).date_retired <> g_vd_object_tab(in_rec_no).xvoh_date_retired)
      )
      THEN
        -- �ړ����͍X�V���Ȃ�
        g_vd_object_tab(in_rec_no).moved_date := g_vd_object_tab(in_rec_no).xvoh_moved_date;
        -- ***************************************************
        -- ���̋@�����Ǘ��X�V
        -- ***************************************************
        UPDATE xxcff_vd_object_headers  xvoh    -- ���̋@�����Ǘ�
        SET    xvoh.object_status          = cv_obj_status_105,                          -- �����X�e�[�^�X�i'105' �����p���m��j
               xvoh.date_retired           = g_vd_object_tab(in_rec_no).date_retired,    -- ���E���p��
               xvoh.ib_if_date             = g_vd_object_tab(in_rec_no).generation_date, -- �ݒu�x�[�X���A�g��
               xvoh.last_updated_by        = cn_last_updated_by,                         -- �ŏI�X�V��
               xvoh.last_update_date       = cd_last_update_date,                        -- �ŏI�X�V��
               xvoh.last_update_login      = cn_last_update_login,                       -- �ŏI�X�V���O�C��
               xvoh.request_id             = cn_request_id,                              -- �v��ID
               xvoh.program_application_id = cn_program_application_id,                  -- �R���J�����g��v���O������A�v���P�[�V����
               xvoh.program_id             = cn_program_id,                              -- �R���J�����g��v���O����ID
               xvoh.program_update_date    = cd_program_update_date                      -- �v���O�����X�V��
        WHERE  xvoh.object_header_id  = g_vd_object_tab(in_rec_no).xvoh_object_header_id -- ����ID
        ;
--
        -- =====================================================
        --  ���̋@��������o�^ (A-5)
        -- =====================================================
        ins_vd_obj_hist(
          in_rec_no,                                         -- �`�F�b�N�Ώۃ��R�[�h�ԍ�
          g_vd_object_tab(in_rec_no).xvoh_object_header_id,  -- ����ID
          cv_obj_status_105,                                 -- �����敪�i'105' �����p���m��j
          cv_obj_status_105,                                 -- �����X�e�[�^�X�i'105' �����p���m��j
          lv_errbuf,            -- �G���[�E���b�Z�[�W           --# �Œ� #
          lv_retcode,           -- ���^�[���E�R�[�h             --# �Œ� #
          lv_errmsg);           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        IF (lv_retcode = cv_status_error) THEN
          RAISE global_api_expt;
        END IF;
      END IF;
    END IF;
--
    -- ����Ɏ�荞�݂����������f�[�^�Ɋւ��āA�捞�X�e�[�^�X��'1'�i�捞�ρj�ɍX�V
    UPDATE xxcff_vd_object_mng_if  xvomi    -- ���̋@�����Ǘ�IF
    SET    xvomi.import_status           =  cv_import_status_1,         -- �捞�X�e�[�^�X
           xvomi.last_updated_by         =  cn_last_updated_by,         -- �ŏI�X�V��
           xvomi.last_update_date        =  cd_last_update_date,        -- �ŏI�X�V��
           xvomi.last_update_login       =  cn_last_update_login,       -- �ŏI�X�V���O�C��
           xvomi.request_id              =  cn_request_id,              -- �v��ID
           xvomi.program_application_id  =  cn_program_application_id,  -- �R���J�����g��v���O������A�v���P�[�V����
           xvomi.program_id              =  cn_program_id,              -- �R���J�����g��v���O����ID
           xvomi.program_update_date     =  cd_program_update_date      -- �v���O�����X�V��
    WHERE  xvomi.object_code = g_vd_object_tab(in_rec_no).object_code   -- �����R�[�h
    ;
--
    -- �u�����L���t���O�v��'N'(����)�̏ꍇ�A���b�Z�[�W���o�͂��A�I���X�e�[�^�X��'1'(�x��)��ݒ�
    IF (g_vd_object_tab(in_rec_no).active_flag = gv_flag_off) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_kbn_cff,   -- �A�v���P�[�V�����Z�k��
                     iv_name         => cv_msg_cff_00210  -- ���b�Z�[�W�R�[�h
                   );
      lv_token_value := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_kbn_cff,       -- �A�v���P�[�V�����Z�k��
                     iv_name         => cv_msg_cff_50137      -- ���b�Z�[�W�R�[�h
                   );
      -- �u�����R�[�h�v���g�[�N���l�ɐݒ�
      lv_token_value := lv_token_value || g_vd_object_tab(in_rec_no).object_code;
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_kbn_cff,       -- �A�v���P�[�V�����Z�k��
                     iv_name         => cv_msg_cff_00093,     -- ���b�Z�[�W�R�[�h
                     iv_token_name1  => cv_tkn_cff_00093_01,  -- �g�[�N���R�[�h1
                     iv_token_value1 => lv_errmsg,            -- �g�[�N���l1
                     iv_token_name2  => cv_tkn_cff_00093_02,  -- �g�[�N���R�[�h2
                     iv_token_value2 => lv_token_value        -- �g�[�N���l2
                   );
      FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT,
        buff   => lv_errmsg
      );
      FND_FILE.PUT_LINE(
        which  => FND_FILE.LOG,
        buff   => lv_errmsg
      );
      ov_retcode := cv_status_warn;
    END IF;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
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
  END ins_upd_vd_object;
--
  /**********************************************************************************
   * Procedure Name   : delete_vd_object_if
   * Description      : ���̋@�����Ǘ�IF�폜���� (A-7)
   ***********************************************************************************/
  PROCEDURE delete_vd_object_if(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'delete_vd_object_if'; -- �v���O������
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
    -- �捞�X�e�[�^�X��'1'�i�捞�ρj�A'9'�i�����p�X�e�[�^�X�G���[�j�̃f�[�^���폜
    DELETE FROM xxcff_vd_object_mng_if
    WHERE import_status IN (cv_import_status_1, cv_import_status_9)
    ;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
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
  END delete_vd_object_if;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
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
    ln_err_cnt   NUMBER;   -- �Ó����`�F�b�N���̃G���[�����J�E���g�p
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
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
--
    -- ���[�J���ϐ��̏�����
    ln_err_cnt    := 0;
--
    -- =====================================================
    --  �������� (A-1)
    -- =====================================================
    init(
      lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- =====================================================
    --  ���̋@������񒊏o���� (A-2)
    -- =====================================================
    select_vd_object_info(
      lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    ELSIF (lv_retcode = cv_status_warn) THEN
      ov_retcode := cv_status_warn;
    END IF;
--
    -- �����Ώی����̐ݒ�
    gn_target_cnt := g_vd_object_tab.COUNT;
    -- �G���[���������̏����ݒ�
    gn_error_cnt := gn_target_cnt;
--
    -- =====================================================
    --  �f�[�^�Ó����`�F�b�N���� (A-3)
    -- =====================================================
    -- �捞�Ώۃf�[�^�̃��R�[�h�P�ʂ̃`�F�b�N
    <<validate_rec_loop>>
    FOR i IN 1..g_vd_object_tab.COUNT LOOP
      validate_record(
        i,                 -- �`�F�b�N�Ώۃ��R�[�h�ԍ�
        lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
        lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
        lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      IF (lv_retcode = cv_status_error) THEN
        RAISE global_process_expt;
      ELSIF (lv_retcode = cv_status_warn) THEN
        ln_err_cnt := ln_err_cnt + 1;
        ov_retcode := cv_status_warn;
      ELSE -- �������`�F�b�N�G���[���������Ȃ������f�[�^�̂ݏ���
        -- =====================================================
        --  ���̋@���o�^�^�X�V (A-4)
        -- =====================================================
        ins_upd_vd_object(
          i,                 -- �`�F�b�N�Ώۃ��R�[�h�ԍ�
          lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
          lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
          lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        IF (lv_retcode = cv_status_error) THEN
          RAISE global_process_expt;
        ELSIF (lv_retcode = cv_status_warn) THEN
          ov_retcode  := cv_status_warn;
        END IF;
      END IF;
    END LOOP validate_rec_loop;
    -- =====================================================
    --  ���̋@�����Ǘ�IF�폜���� (A-6)
    -- =====================================================
    delete_vd_object_if(
      lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    gn_error_cnt  := ln_err_cnt;                    -- �G���[����
    gn_normal_cnt := gn_target_cnt - gn_error_cnt;  -- ���������F�Ώی��� - �G���[����
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ###################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
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
    retcode       OUT VARCHAR2       --   ���^�[���E�R�[�h    --# �Œ� #
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
--###########################  �Œ蕔 END   #############################
--
    -- ===============================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ===============================================
    submain(
       lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    --�G���[�o��
    IF (lv_retcode = cv_status_error) THEN
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --�G���[���b�Z�[�W
      );
    END IF;
    --��s�}��
    FND_FILE.PUT_LINE(
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
    FND_FILE.PUT_LINE(
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
    FND_FILE.PUT_LINE(
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
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    --�I�����b�Z�[�W
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
    --�X�e�[�^�X�Z�b�g
    retcode := lv_retcode;
    --�I���X�e�[�^�X���G���[�̏ꍇ��ROLLBACK����
    IF (retcode = cv_status_error) THEN
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
END XXCFF017A01C;
/
