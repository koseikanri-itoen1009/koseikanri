CREATE OR REPLACE PACKAGE BODY APPS.XXCSO020A02C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCSO020A02C(body)
 * Description      : �t���x���_�[�p�r�o�ꌈ�E�o�^��ʂ���n�����������ƂɎw�肳�ꂽ
 *                    �񑗐�Ƀ��[�N�t���[�ʒm�𑗕t���܂��B
 * MD.050           : MD050_CSO_020_A02_�ʒm�E���F���[�N�t���[�@�\
 *
 * Version          : 1.3
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                    ��������(A-1)
 *  get_notify_info         �ʒm��񒊏o(A-2)
 *  start_sp_dec_wf_proc    �r�o�ꌈ���[�N�t���[�N��(A-7)
 *  submain                 ���C�������v���V�[�W��
 *                            ���F�^�m�F�ʒm���t(A-3)
 *                            �ی��^�ԋp�ʒm���񒊏o(A-4)
 *                            �ی��^�ԋp�ʒm���t(A-5)
 *                            �\���Ҍ����ی��^�ԋp�ʒm���t(A-6)
 *  main                    ���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008-12-22    1.0   Noriyuki.Yabuki  �V�K�쐬
 *  2009-02-05          Kazuo.Satomura   �]�ƈ��ԍ����烆�[�U�[�����擾
 *  2009-02-27          Noriyuki.Yabuki  ���[�N�t���[�pAPI�̖��̂�����������啶���ɏC��
 *  2009-05-01    1.1   Tomoko.Mori      T1_0897�Ή�
 *  2009-06-29    1.2   Kazuo.Satomura   �����e�X�g��Q�Ή�(0000209)
 *  2009-10-21    1.3   Daisuke.Abe      E_T4_00050�Ή�
 *****************************************************************************************/
  --
  --#######################  �Œ�O���[�o���萔�錾�� START   #######################
  --
  -- �X�e�[�^�X�E�R�[�h
  cv_status_normal CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal;  -- ����:0
  cv_status_warn   CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_warn;    -- �x��:1
  cv_status_error  CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_error;   -- �ُ�:2
  --
  -- WHO�J����
  cn_created_by             CONSTANT NUMBER := fnd_global.user_id;          -- CREATED_BY
  cd_creation_date          CONSTANT DATE   := SYSDATE;                     -- CREATION_DATE
  cn_last_updated_by        CONSTANT NUMBER := fnd_global.user_id;          -- LAST_UPDATED_BY
  cd_last_update_date       CONSTANT DATE   := SYSDATE;                     -- LAST_UPDATE_DATE
  cn_last_update_login      CONSTANT NUMBER := fnd_global.login_id;         -- LAST_UPDATE_LOGIN
  cn_request_id             CONSTANT NUMBER := fnd_global.conc_request_id;  -- REQUEST_ID
  cn_program_application_id CONSTANT NUMBER := fnd_global.prog_appl_id;     -- PROGRAM_APPLICATION_ID
  cn_program_id             CONSTANT NUMBER := fnd_global.conc_program_id;  -- PROGRAM_ID
  cd_program_update_date    CONSTANT DATE   := SYSDATE;                     -- PROGRAM_UPDATE_DATE
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
  global_process_expt       EXCEPTION;
  --
  --*** ���ʊ֐���O ***
  global_api_expt           EXCEPTION;
  --
  --*** ���ʊ֐�OTHERS��O ***
  global_api_others_expt    EXCEPTION;
  --
  PRAGMA EXCEPTION_INIT( global_api_others_expt, -20000 );
  --
  --################################  �Œ蕔 END   ##################################
  --
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name              CONSTANT VARCHAR2(100) := 'XXCSO020A02C';  -- �p�b�P�[�W��
  cv_sales_appl_short_name CONSTANT VARCHAR2(5)   := 'XXCSO';         -- �c�Ɨp�A�v���P�[�V�����Z�k��
  cv_com_appl_short_name   CONSTANT VARCHAR2(5)   := 'XXCCP';         -- ���ʗp�A�v���P�[�V�����Z�k��
  --
  -- ���b�Z�[�W�R�[�h
  cv_tkn_number_01 CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00011';  -- �Ɩ��������t�擾�G���[
  cv_tkn_number_02 CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00382';  -- ���̓p�����[�^�K�{�G���[
  cv_tkn_number_03 CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00323';  -- �f�[�^�擾�G���[
  cv_tkn_number_04 CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00324';  -- �f�[�^���o����O�G���[
  cv_tkn_number_05 CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00340';  -- ���[�N�t���[API�G���[
  --
  -- �g�[�N���R�[�h
  cv_tkn_item     CONSTANT VARCHAR2(20) := 'ITEM';
  cv_tkn_table    CONSTANT VARCHAR2(20) := 'TABLE';
  cv_tkn_key      CONSTANT VARCHAR2(20) := 'KEY';
  cv_tkn_err_msg  CONSTANT VARCHAR2(20) := 'ERR_MSG';
  cv_tkn_func_nm  CONSTANT VARCHAR2(20) := 'FUNC_NAME';
  --
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  --
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  --
  --
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
      iv_notify_type           IN         VARCHAR2    -- �ʒm�敪
    , it_sp_decision_header_id IN         xxcso_sp_decision_headers.sp_decision_header_id%TYPE  -- �r�o�ꌈ�w�b�_�h�c
    , iv_send_employee_number  IN         VARCHAR2    -- �񑗌��]�ƈ��ԍ�
    , iv_dest_employee_number  IN         VARCHAR2    -- �񑗐�]�ƈ��ԍ�
    , od_process_date          OUT NOCOPY DATE        -- �Ɩ��������t
    , ov_errbuf                OUT NOCOPY VARCHAR2    -- �G���[�E���b�Z�[�W --# �Œ� #
    , ov_retcode               OUT NOCOPY VARCHAR2    -- ���^�[���E�R�[�h   --# �Œ� #
  ) IS
    --
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name CONSTANT VARCHAR2(100) := 'init'; -- �v���V�[�W����

    /* 2009.10.21 D.Abe E_T4_00050�Ή� START */
    ct_item_type    CONSTANT VARCHAR2(30) := 'XXCSO020'; -- �A�C�e���^�C�v
    ct_item_name    CONSTANT VARCHAR2(30) := 'XXCSO_SP_DECISION_HEADER_ID'; -- �A�C�e�����ږ�
    ct_wf_status_o  CONSTANT VARCHAR2(30) := 'OPEN';   -- �ʒm�X�e�[�^�X
    ct_wf_status_c  CONSTANT VARCHAR2(30) := 'CLOSED'; -- �ʒm�X�e�[�^�X
    /* 2009.10.21 D.Abe E_T4_00050�Ή� END */

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
    cv_nm_notify_type           CONSTANT VARCHAR2(30) := '�ʒm�敪';
    cv_nm_sp_decision_header_id CONSTANT VARCHAR2(30) := '�r�o�ꌈ�w�b�_�h�c';
    cv_nm_send_employee_number  CONSTANT VARCHAR2(30) := '�񑗌��]�ƈ��ԍ�';
    cv_nm_dest_employee_number  CONSTANT VARCHAR2(30) := '�񑗐�]�ƈ��ԍ�';
    /* 2009.10.21 D.Abe E_T4_00050�Ή� START */
    cv_nm_wf_notifications      CONSTANT VARCHAR2(30) := '�ʒm�N���[�Y����';
    /* 2009.10.21 D.Abe E_T4_00050�Ή� END */
    --
    -- *** ���[�J���ϐ� ***
    /* 2009.10.21 D.Abe E_T4_00050�Ή� START */
    lt_login_user_name fnd_user.user_name%TYPE;    -- ���O�C�����[�U�[��
    /* 2009.10.21 D.Abe E_T4_00050�Ή� END */
    --
    -- *** ���[�J����O ***
    input_parameter_expt  EXCEPTION;
    --
  BEGIN
    --
    --##################  �Œ�X�e�[�^�X�������� START   ###################
    --
    ov_retcode := cv_status_normal;
    --
    --###########################  �Œ蕔 END   ############################
    --
    -- ======================
    -- ���̓p�����[�^�`�F�b�N
    -- ======================
    -- �ʒm�敪�������͂̏ꍇ�G���[
    IF ( iv_notify_type IS NULL ) THEN
      lv_errbuf := xxccp_common_pkg.get_msg(
                       iv_application  => cv_sales_appl_short_name     -- �A�v���P�[�V�����Z�k��
                     , iv_name         => cv_tkn_number_02             -- ���b�Z�[�W�R�[�h
                     , iv_token_name1  => cv_tkn_item                  -- �g�[�N�R�[�h1
                     , iv_token_value1 => cv_nm_notify_type            -- �g�[�N���l1
                   );
      --
      RAISE input_parameter_expt;
      --
    END IF;
    --
    -- �r�o�ꌈ�w�b�_�h�c�������͂̏ꍇ�G���[
    IF ( it_sp_decision_header_id IS NULL ) THEN
      lv_errbuf := xxccp_common_pkg.get_msg(
                       iv_application  => cv_sales_appl_short_name     -- �A�v���P�[�V�����Z�k��
                     , iv_name         => cv_tkn_number_02             -- ���b�Z�[�W�R�[�h
                     , iv_token_name1  => cv_tkn_item                  -- �g�[�N�R�[�h1
                     , iv_token_value1 => cv_nm_sp_decision_header_id  -- �g�[�N���l1
                   );
      --
      RAISE input_parameter_expt;
      --
    END IF;
    --
    -- �񑗌��]�ƈ��ԍ��������͂̏ꍇ�G���[
    IF ( iv_send_employee_number IS NULL ) THEN
      lv_errbuf := xxccp_common_pkg.get_msg(
                       iv_application  => cv_sales_appl_short_name    -- �A�v���P�[�V�����Z�k��
                     , iv_name         => cv_tkn_number_02            -- ���b�Z�[�W�R�[�h
                     , iv_token_name1  => cv_tkn_item                 -- �g�[�N�R�[�h1
                     , iv_token_value1 => cv_nm_send_employee_number  -- �g�[�N���l1
                   );
      --
      RAISE input_parameter_expt;
      --
    END IF;
    --
    -- �񑗐�]�ƈ��ԍ��������͂̏ꍇ�G���[
    IF ( iv_dest_employee_number IS NULL ) THEN
      lv_errbuf := xxccp_common_pkg.get_msg(
                       iv_application  => cv_sales_appl_short_name    -- �A�v���P�[�V�����Z�k��
                     , iv_name         => cv_tkn_number_02            -- ���b�Z�[�W�R�[�h
                     , iv_token_name1  => cv_tkn_item                 -- �g�[�N�R�[�h1
                     , iv_token_value1 => cv_nm_dest_employee_number  -- �g�[�N���l1
                   );
      --
      RAISE input_parameter_expt;
      --
    END IF;
    --
    -- ======================
    -- �Ɩ��������t�擾
    -- ======================
    od_process_date := xxccp_common_pkg2.get_process_date;
    --
    IF ( od_process_date IS NULL ) THEN
      lv_errbuf := xxccp_common_pkg.get_msg(
                       iv_application  => cv_sales_appl_short_name    -- �A�v���P�[�V�����Z�k��
                     , iv_name         => cv_tkn_number_01            -- ���b�Z�[�W�R�[�h
                   );
      --
      RAISE global_api_expt;
    END IF;
    /* 2009.10.21 D.Abe E_T4_00050�Ή� START */
    --
    -- ============================
    -- ���O�C�����[�U���擾����
    -- ============================
    BEGIN
      lt_login_user_name := NULL;
      SELECT USER_NAME
      INTO   lt_login_user_name
      FROM   FND_USER
      WHERE  USER_ID = fnd_global.user_id
      ;
      --
    EXCEPTION
      WHEN OTHERS THEN
        NULL;
    END;
    -- ============================
    -- �������[�N�t���[�ʒm�N���[�Y����
    -- ============================
    BEGIN
      UPDATE wf_notifications wn
      SET    status   = ct_wf_status_c,
             end_date = SYSDATE,
             responder = lt_login_user_name
      WHERE  EXISTS(SELECT 1
                    FROM   wf_item_attribute_values  wiav
                          ,wf_item_activity_statuses wias
                    WHERE  wiav.item_type     = wias.item_type
                    AND    wiav.item_key      = wias.item_key
                    AND    wiav.item_type     = ct_item_type
                    AND    wiav.name          = ct_item_name
                    AND    wiav.number_value  = it_sp_decision_header_id
                    AND    wn.notification_id = wias.notification_id)
      AND    wn.status = ct_wf_status_o
      ;
      --
    EXCEPTION
      WHEN OTHERS THEN
        -- ���̑��̗�O�̏ꍇ
        lv_errbuf := xxccp_common_pkg.get_msg(
                       iv_application  => cv_sales_appl_short_name  -- �A�v���P�[�V�����Z�k��
                     , iv_name         => cv_tkn_number_05          -- ���b�Z�[�W�R�[�h
                     , iv_token_name1  => cv_tkn_func_nm            -- �g�[�N���R�[�h1
                     , iv_token_value1 => cv_nm_wf_notifications    -- �g�[�N���l1
                     , iv_token_name2  => cv_tkn_err_msg            -- �g�[�N���R�[�h2
                     , iv_token_value2 => SQLERRM                   -- �g�[�N���l2
                    );
        --
        RAISE global_api_expt;
        --
    END;
    /* 2009.10.21 D.Abe E_T4_00050�Ή� END */
    --
  EXCEPTION
    --
    WHEN input_parameter_expt THEN
      -- *** ���̓p�����[�^�`�F�b�N�G���[�� ***
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
      --
    --#################################  �Œ��O������ START   ####################################
    --
    WHEN global_api_expt THEN
      -- *** ���ʊ֐���O�n���h�� ***
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
      --
    WHEN global_api_others_expt THEN
      -- *** ���ʊ֐�OTHERS��O�n���h�� ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      --
    WHEN OTHERS THEN
      -- *** OTHERS��O�n���h�� ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      --
    --
    --#####################################  �Œ蕔 END   ##########################################
    --
  END init;
  --
  --
  /**********************************************************************************
   * Procedure Name   : get_notify_info
   * Description      : �ʒm��񒊏o(A-2)
   ***********************************************************************************/
  PROCEDURE get_notify_info(
      iv_notify_type           IN         VARCHAR2                                 -- �ʒm�敪
    , id_process_date          IN         DATE                                     -- �Ɩ��������t
    , it_sp_decision_header_id IN         xxcso_sp_decision_headers.sp_decision_header_id%TYPE  -- �r�o�ꌈ�w�b�_�h�c
    , iv_send_employee_number  IN         VARCHAR2                                 -- �񑗌��]�ƈ��ԍ�
    , iv_dest_employee_number  IN         VARCHAR2                                 -- �񑗐�]�ƈ��ԍ�
    , ot_notify_subject        OUT NOCOPY fnd_lookup_values_vl.attribute1%TYPE     -- ����
    , ot_notify_body           OUT NOCOPY fnd_lookup_values_vl.attribute2%TYPE     -- �{��
    , ot_party_name            OUT NOCOPY hz_parties.party_name%TYPE               -- �ڋq��
    , ot_send_user_name        OUT NOCOPY VARCHAR2                                 -- �񑗌����[�U�[��
    , ot_dest_user_name        OUT NOCOPY VARCHAR2                                 -- �񑗐惆�[�U�[��
    , ov_errbuf                OUT NOCOPY VARCHAR2                                 -- �G���[�E���b�Z�[�W  --# �Œ� #
    , ov_retcode               OUT NOCOPY VARCHAR2                                 -- ���^�[���E�R�[�h    --# �Œ� #
  ) IS
    --
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'get_notify_info';  -- �v���V�[�W����
    --
    --#######################  �Œ胍�[�J���ϐ��錾�� START   ######################
    --
    lv_errbuf     VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode    VARCHAR2(1);     -- ���^�[���E�R�[�h
    --
    --###########################  �Œ蕔 END   ####################################
    --
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    ct_lookup_type_sp_wf_notify    CONSTANT fnd_lookup_values_vl.lookup_type%TYPE := 'XXCSO1_SP_WF_NOTICE_TEXT';
                                                                                        -- �r�o���[�N�t���[�ʒm
    ct_sp_dec_cust_class_install   CONSTANT xxcso_sp_decision_custs.sp_decision_customer_class%TYPE := '1';
                                                                                        -- �r�o�ꌈ�ڋq�敪=�ݒu��
    --
    -- �g�[�N���p�萔
    cv_tkn_val_notify_type        CONSTANT VARCHAR2(100) := '�ʒm�敪�F';
    cv_tkn_val_lookup_vals_vl     CONSTANT VARCHAR2(100) := '�N�C�b�N�R�[�h�r���[';
    cv_tkn_val_sp_dec_head_id     CONSTANT VARCHAR2(100) := '�r�o�ꌈ�w�b�_�h�c�F';
    cv_tkn_val_sp_cst_and_cst_mst CONSTANT VARCHAR2(100) := '�r�o�ꌈ�ڋq�e�[�u���^�ڋq�}�X�^';
    cv_tkn_val_send_emp_number    CONSTANT VARCHAR2(100) := '�񑗌��]�ƈ��ԍ��F';
    cv_tkn_val_dest_emp_number    CONSTANT VARCHAR2(100) := '�񑗐�]�ƈ��ԍ��F';
    cv_tkn_val_employee_v         CONSTANT VARCHAR2(100) := '�]�ƈ��}�X�^�i�ŐV�j�r���[';
    --
    -- *** ���[�J���ϐ� ***
    lt_notify_subject fnd_lookup_values_vl.attribute1%TYPE; -- ����
    lt_notify_body    fnd_lookup_values_vl.attribute2%TYPE; -- �{��
    lt_party_name     hz_parties.party_name%TYPE;           -- �ڋq��
    lt_send_user_name xxcso_employees_v2.user_name%TYPE;    -- �񑗌����[�U�[��
    lt_dest_user_name xxcso_employees_v2.user_name%TYPE;    -- �񑗐惆�[�U�[��
    --
    -- *** ���[�J����O ***
    sql_expt  EXCEPTION;
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
    lt_notify_subject := NULL;
    lt_notify_body    := NULL;
    lt_party_name     := NULL;
    --
    -- ============================
    -- �����A�{���擾����
    -- ============================
    BEGIN
      SELECT flvv.attribute1  notify_subject    -- ����
           , flvv.attribute2  notify_body       -- �{��
      INTO   lt_notify_subject
           , lt_notify_body
      FROM   fnd_lookup_values_vl  flvv    -- �N�C�b�N�R�[�h�r���[
      WHERE  flvv.lookup_type  = ct_lookup_type_sp_wf_notify
      AND    flvv.lookup_code  = iv_notify_type
      AND    flvv.enabled_flag = 'Y'
      AND    TRUNC( NVL( flvv.start_date_active, id_process_date ) ) <= TRUNC( id_process_date )
      AND    TRUNC( NVL( flvv.end_date_active, id_process_date ) )   >= TRUNC( id_process_date )
      ;
      --
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- �f�[�^�����݂��Ȃ��ꍇ
        lv_errbuf := xxccp_common_pkg.get_msg(
                         iv_application  => cv_sales_appl_short_name   -- �A�v���P�[�V�����Z�k��
                       , iv_name         => cv_tkn_number_03           -- ���b�Z�[�W�R�[�h
                       , iv_token_name1  => cv_tkn_item                -- �g�[�N���R�[�h1
                       , iv_token_value1 => cv_tkn_val_notify_type ||
                                            cv_msg_part            ||
                                            iv_notify_type             -- �g�[�N���l1
                       , iv_token_name2  => cv_tkn_table               -- �g�[�N���R�[�h2
                       , iv_token_value2 => cv_tkn_val_lookup_vals_vl  -- �g�[�N���l2
                    );
        --
        RAISE sql_expt;
        --
      WHEN OTHERS THEN
        -- ���̑��̗�O�̏ꍇ
        lv_errbuf := xxccp_common_pkg.get_msg(
                         iv_application  => cv_sales_appl_short_name   -- �A�v���P�[�V�����Z�k��
                       , iv_name         => cv_tkn_number_04           -- ���b�Z�[�W�R�[�h
                       , iv_token_name1  => cv_tkn_table               -- �g�[�N���R�[�h1
                       , iv_token_value1 => cv_tkn_val_lookup_vals_vl  -- �g�[�N���l1
                       , iv_token_name2  => cv_tkn_key                 -- �g�[�N���R�[�h2
                       , iv_token_value2 => iv_notify_type             -- �g�[�N���l2
                       , iv_token_name3  => cv_tkn_err_msg             -- �g�[�N���R�[�h3
                       , iv_token_value3 => SQLERRM                    -- �g�[�N���l3
                    );
        --
        RAISE sql_expt;
        --
    END;
    --
    -- ==========================
    -- �r�o�ꌈ�ڋq�擾����
    -- ==========================
    BEGIN
      SELECT DECODE(  xsdc.new_customer_flag
                    , 'Y'
                    , xsdc.party_name
                    , xcav.party_name )  party_name    -- �ڋq��
      INTO   lt_party_name
      FROM   xxcso_sp_decision_custs  xsdc    -- �r�o�ꌈ�ڋq�e�[�u��
           , xxcso_cust_accounts_v    xcav    -- �ڋq�}�X�^�r���[
      WHERE  xsdc.sp_decision_header_id      = it_sp_decision_header_id
      AND    xsdc.sp_decision_customer_class = ct_sp_dec_cust_class_install
      AND    xsdc.customer_id                = xcav.cust_account_id(+)
      ;
      --
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- �f�[�^�����݂��Ȃ��ꍇ
        lv_errbuf := xxccp_common_pkg.get_msg(
                         iv_application  => cv_sales_appl_short_name       -- �A�v���P�[�V�����Z�k��
                       , iv_name         => cv_tkn_number_03               -- ���b�Z�[�W�R�[�h
                       , iv_token_name1  => cv_tkn_item                    -- �g�[�N���R�[�h1
                       , iv_token_value1 => cv_tkn_val_sp_dec_head_id ||
                                            cv_msg_part               ||
                                            it_sp_decision_header_id       -- �g�[�N���l1
                       , iv_token_name2  => cv_tkn_table                   -- �g�[�N���R�[�h2
                       , iv_token_value2 => cv_tkn_val_sp_cst_and_cst_mst  -- �g�[�N���l2
                    );
        --
        RAISE sql_expt;
        --
      WHEN OTHERS THEN
        -- ���̑��̗�O�̏ꍇ
        lv_errbuf := xxccp_common_pkg.get_msg(
                         iv_application  => cv_sales_appl_short_name       -- �A�v���P�[�V�����Z�k��
                       , iv_name         => cv_tkn_number_04               -- ���b�Z�[�W�R�[�h
                       , iv_token_name1  => cv_tkn_table                   -- �g�[�N���R�[�h1
                       , iv_token_value1 => cv_tkn_val_sp_cst_and_cst_mst  -- �g�[�N���l1
                       , iv_token_name2  => cv_tkn_key                     -- �g�[�N���R�[�h2
                       , iv_token_value2 => it_sp_decision_header_id       -- �g�[�N���l2
                       , iv_token_name3  => cv_tkn_err_msg                 -- �g�[�N���R�[�h3
                       , iv_token_value3 => SQLERRM                        -- �g�[�N���l3
                    );
        --
        RAISE sql_expt;
        --
    END;
    --
    -- ==========================
    -- �񑗌����[�U�[���擾����
    -- ==========================
    BEGIN
      SELECT xev.user_name user_name -- ���[�U�[��
      INTO   lt_send_user_name
      FROM   xxcso_employees_v2 xev -- �]�ƈ��}�X�^�i�ŐV�j�r���[
      WHERE  xev.employee_number = iv_send_employee_number
      ;
      --
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- �f�[�^�����݂��Ȃ��ꍇ
        lv_errbuf := xxccp_common_pkg.get_msg(
                         iv_application  => cv_sales_appl_short_name -- �A�v���P�[�V�����Z�k��
                       , iv_name         => cv_tkn_number_03         -- ���b�Z�[�W�R�[�h
                       , iv_token_name1  => cv_tkn_item              -- �g�[�N���R�[�h1
                       , iv_token_value1 => cv_tkn_val_send_emp_number ||
                                            iv_send_employee_number  -- �g�[�N���l1
                       , iv_token_name2  => cv_tkn_table             -- �g�[�N���R�[�h2
                       , iv_token_value2 => cv_tkn_val_employee_v    -- �g�[�N���l2
                    );
        --
        RAISE sql_expt;
        --
      WHEN OTHERS THEN
        -- ���̑��̗�O�̏ꍇ
        lv_errbuf := xxccp_common_pkg.get_msg(
                         iv_application  => cv_sales_appl_short_name -- �A�v���P�[�V�����Z�k��
                       , iv_name         => cv_tkn_number_04         -- ���b�Z�[�W�R�[�h
                       , iv_token_name1  => cv_tkn_table             -- �g�[�N���R�[�h1
                       , iv_token_value1 => cv_tkn_val_employee_v    -- �g�[�N���l1
                       , iv_token_name2  => cv_tkn_key               -- �g�[�N���R�[�h2
                       , iv_token_value2 => iv_send_employee_number  -- �g�[�N���l2
                       , iv_token_name3  => cv_tkn_err_msg           -- �g�[�N���R�[�h3
                       , iv_token_value3 => SQLERRM                  -- �g�[�N���l3
                    );
        --
        RAISE sql_expt;
        --
    END;
    --
    -- ==========================
    -- �񑗐惆�[�U�[���擾����
    -- ==========================
    BEGIN
      SELECT xev.user_name user_name -- ���[�U�[��
      INTO   lt_dest_user_name
      FROM   xxcso_employees_v2 xev -- �]�ƈ��}�X�^�i�ŐV�j�r���[
      WHERE  xev.employee_number = iv_dest_employee_number
      ;
      --
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- �f�[�^�����݂��Ȃ��ꍇ
        lv_errbuf := xxccp_common_pkg.get_msg(
                         iv_application  => cv_sales_appl_short_name -- �A�v���P�[�V�����Z�k��
                       , iv_name         => cv_tkn_number_03         -- ���b�Z�[�W�R�[�h
                       , iv_token_name1  => cv_tkn_item              -- �g�[�N���R�[�h1
                       , iv_token_value1 => cv_tkn_val_dest_emp_number ||
                                            iv_dest_employee_number  -- �g�[�N���l1
                       , iv_token_name2  => cv_tkn_table             -- �g�[�N���R�[�h2
                       , iv_token_value2 => cv_tkn_val_employee_v    -- �g�[�N���l2
                    );
        --
        RAISE sql_expt;
        --
      WHEN OTHERS THEN
        -- ���̑��̗�O�̏ꍇ
        lv_errbuf := xxccp_common_pkg.get_msg(
                         iv_application  => cv_sales_appl_short_name -- �A�v���P�[�V�����Z�k��
                       , iv_name         => cv_tkn_number_04         -- ���b�Z�[�W�R�[�h
                       , iv_token_name1  => cv_tkn_table             -- �g�[�N���R�[�h1
                       , iv_token_value1 => cv_tkn_val_employee_v    -- �g�[�N���l1
                       , iv_token_name2  => cv_tkn_key               -- �g�[�N���R�[�h2
                       , iv_token_value2 => iv_dest_employee_number  -- �g�[�N���l2
                       , iv_token_name3  => cv_tkn_err_msg           -- �g�[�N���R�[�h3
                       , iv_token_value3 => SQLERRM                  -- �g�[�N���l3
                    );
        --
        RAISE sql_expt;
        --
    END;
    --
    ot_notify_subject := lt_notify_subject;
    ot_notify_body    := lt_notify_body;
    ot_party_name     := lt_party_name;
    ot_send_user_name := lt_send_user_name;
    ot_dest_user_name := lt_dest_user_name;
    --
  EXCEPTION
    --
    WHEN sql_expt THEN
      -- *** �f�[�^�擾SQL��O�n���h�� ***
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
      --
    --#################################  �Œ��O������ START   ####################################
    --
    WHEN global_api_others_expt THEN
      -- *** ���ʊ֐�OTHERS��O�n���h�� ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      --
    WHEN OTHERS THEN
      -- *** OTHERS��O�n���h�� ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      --
    --
    --#####################################  �Œ蕔 END   ##########################################
    --
  END get_notify_info;
  --
  --
  /**********************************************************************************
   * Procedure Name   : start_sp_dec_wf_proc
   * Description      : �r�o�ꌈ���[�N�t���[�N��(A-7)
   ***********************************************************************************/
  PROCEDURE start_sp_dec_wf_proc(
      it_sp_decision_header_id IN         xxcso_sp_decision_headers.sp_decision_header_id%TYPE  -- �r�o�ꌈ�w�b�_�h�c
    , iv_dest_user_name        IN         VARCHAR2    -- �񑗐惆�[�U�[��
    , iv_send_user_name        IN         VARCHAR2    -- �񑗌����[�U�[��
    , it_notify_subject        IN         VARCHAR2    -- ����
    , it_notify_body           IN         VARCHAR2    -- �{��
    , in_seq_num               IN         NUMBER      -- �A��
    , ov_errbuf                OUT NOCOPY VARCHAR2    -- �G���[�E���b�Z�[�W  --# �Œ� #
    , ov_retcode               OUT NOCOPY VARCHAR2    -- ���^�[���E�R�[�h    --# �Œ� #
  ) IS
    --
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name CONSTANT VARCHAR2(100) := 'start_sp_dec_wf_proc';  -- �v���V�[�W����
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
    cv_wf_itemtype              CONSTANT VARCHAR2(30) := 'XXCSO020';
    cv_wf_process               CONSTANT VARCHAR2(30) := 'XXCSO020002P01';
    cv_wf_pkg_name              CONSTANT VARCHAR2(30) := 'wf_engine';
    cv_wf_createprocess         CONSTANT VARCHAR2(30) := 'createprocess';
    cv_wf_setitemattrnumber     CONSTANT VARCHAR2(30) := 'setitemattrnumber';
    cv_wf_setitemattrtext       CONSTANT VARCHAR2(30) := 'setitemattrtext';
    cv_wf_startprocess          CONSTANT VARCHAR2(30) := 'startprocess';
    --
    -- ���[�N�t���[������
    cv_wf_aname_sp_dec_head_id  CONSTANT VARCHAR2(30) := 'XXCSO_SP_DECISION_HEADER_ID';
    cv_wf_aname_dest_user_nm    CONSTANT VARCHAR2(30) := 'XXCSO_DESTINATION_USER_NAME';
    cv_wf_aname_send_user_nm    CONSTANT VARCHAR2(30) := 'XXCSO_SENDER_USER_NAME';
    cv_wf_aname_notify_subject  CONSTANT VARCHAR2(30) := 'XXCSO_NOTIFY_SUBJECT';
    cv_wf_aname_notify_body     CONSTANT VARCHAR2(30) := 'XXCSO_NOTIFY_BODY';
    --
    -- �g�[�N���p�萔
    --
    -- *** ���[�J���ϐ� ***
    -- ���[�N�t���[API��O
    lv_itemkey                  VARCHAR2(100);
    lv_token_value              VARCHAR2(60);
    --
    -- *** ���[�J����O ***
    wf_api_others_expt          EXCEPTION;
    --
    PRAGMA EXCEPTION_INIT( wf_api_others_expt, -20002 );
    --
  BEGIN
    --
    --##################  �Œ�X�e�[�^�X�������� START   ###################
    --
    ov_retcode := cv_status_normal;
    --
    --###########################  �Œ蕔 END   ############################
    --
    lv_itemkey := cv_sales_appl_short_name
                    || TO_CHAR( SYSDATE, 'YYYYMMDDHH24MISS' )
                    /* 2009.06.29 K.Satomura �����e�X�g��Q�Ή�(0000209) START */
                    --|| LPAD( TO_CHAR( in_seq_num ), 2, '0' );
                    || LPAD( TO_CHAR( in_seq_num ), 2, '0' )
                    || TO_CHAR(it_sp_decision_header_id)
                    ;
                    /* 2009.06.29 K.Satomura �����e�X�g��Q�Ή�(0000209) END */
    --
    -- ==========================
    -- ���[�N�t���[�v���Z�X����
    -- ==========================
    lv_token_value := cv_wf_pkg_name || cv_wf_createprocess;
    --
    WF_ENGINE.CREATEPROCESS(
        itemtype => cv_wf_itemtype
      , itemkey  => lv_itemkey
      , process  => cv_wf_process
    );
    --
    -- ==========================
    -- ���[�N�t���[�����ݒ�
    -- ==========================
    lv_token_value := cv_wf_pkg_name || cv_wf_setitemattrnumber;
    --
    -- �r�o�ꌈ�w�b�_�h�c
    WF_ENGINE.SETITEMATTRNUMBER(
        itemtype => cv_wf_itemtype
      , itemkey  => lv_itemkey
      , aname    => cv_wf_aname_sp_dec_head_id
      , avalue   => it_sp_decision_header_id
    );
    --
    lv_token_value := cv_wf_pkg_name || cv_wf_setitemattrtext;
    --
    -- �ʒm�񑗐�
    WF_ENGINE.SETITEMATTRTEXT(
        itemtype => cv_wf_itemtype
      , itemkey  => lv_itemkey
      , aname    => cv_wf_aname_dest_user_nm
      , avalue   => iv_dest_user_name
    );
    --
    -- �ʒm�񑗌�
    WF_ENGINE.SETITEMATTRTEXT(
        itemtype => cv_wf_itemtype
      , itemkey  => lv_itemkey
      , aname    => cv_wf_aname_send_user_nm
      , avalue   => iv_send_user_name
    );
    --
    -- �ʒm����
    WF_ENGINE.SETITEMATTRTEXT(
        itemtype => cv_wf_itemtype
      , itemkey  => lv_itemkey
      , aname    => cv_wf_aname_notify_subject
      , avalue   => it_notify_subject
    );
    --
    -- �ʒm�{��
    WF_ENGINE.SETITEMATTRTEXT(
        itemtype => cv_wf_itemtype
      , itemkey  => lv_itemkey
      , aname    => cv_wf_aname_notify_body
      , avalue   => it_notify_body
    );
    --
    -- ==========================
    -- ���[�N�t���[�v���Z�X�N��
    -- ==========================
    lv_token_value := cv_wf_pkg_name || cv_wf_startprocess;
    --
    WF_ENGINE.STARTPROCESS(
        itemtype => cv_wf_itemtype
      , itemkey  => lv_itemkey
    );
    --
  EXCEPTION
    --
    WHEN wf_api_others_expt THEN
      -- *** ���[�N�t���[API��O�n���h�� ***
      lv_errbuf := xxccp_common_pkg.get_msg(
                       iv_application  => cv_sales_appl_short_name  -- �A�v���P�[�V�����Z�k��
                     , iv_name         => cv_tkn_number_05          -- ���b�Z�[�W�R�[�h
                     , iv_token_name1  => cv_tkn_func_nm            -- �g�[�N���R�[�h1
                     , iv_token_value1 => lv_token_value            -- �g�[�N���l1
                     , iv_token_name2  => cv_tkn_err_msg            -- �g�[�N���R�[�h2
                     , iv_token_value2 => SQLERRM                   -- �g�[�N���l2
                  );
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
      --
    --#################################  �Œ��O������ START   ####################################
    --
    WHEN global_api_others_expt THEN
      -- *** ���ʊ֐�OTHERS��O�n���h�� ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      --
    WHEN OTHERS THEN
     -- *** OTHERS��O�n���h�� ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      --
    --
    --#####################################  �Œ蕔 END   ##########################################
    --
  END start_sp_dec_wf_proc;
  --
  --
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   ***********************************************************************************/
  PROCEDURE submain(
      iv_notify_type           IN         VARCHAR2    -- �ʒm�敪
    , it_sp_decision_header_id IN         xxcso_sp_decision_headers.sp_decision_header_id%TYPE  -- �r�o�ꌈ�w�b�_�h�c
    , iv_send_employee_number  IN         VARCHAR2    -- �񑗌��]�ƈ��ԍ�
    , iv_dest_employee_number  IN         VARCHAR2    -- �񑗐�]�ƈ��ԍ�
    , ov_errbuf                OUT NOCOPY VARCHAR2    -- �G���[�E���b�Z�[�W  --# �Œ� #
    , ov_retcode               OUT NOCOPY VARCHAR2    -- ���^�[���E�R�[�h    --# �Œ� #
  ) IS
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
    ct_approval_state_type_in_prc  CONSTANT xxcso_sp_decision_sends.approval_state_type%TYPE := '1';
                                                                                        -- ���ُ�ԋ敪=������
    ct_approval_state_type_prcssd  CONSTANT xxcso_sp_decision_sends.approval_state_type%TYPE := '2';
                                                                                        -- ���ُ�ԋ敪=������
    cv_notify_type_aprv_req        CONSTANT VARCHAR2(1) := '1';    -- ���F�˗��ʒm
    cv_notify_type_cnfrm_req       CONSTANT VARCHAR2(1) := '2';    -- �m�F�˗��ʒm
    cv_notify_type_rjct            CONSTANT VARCHAR2(1) := '3';    -- �ی��ʒm
    cv_notify_type_rtrn            CONSTANT VARCHAR2(1) := '4';    -- �ԋp�ʒm
    cv_notify_type_aprv_cmplt      CONSTANT VARCHAR2(1) := '5';    -- ���F�����ʒm
    cv_seq_num                     CONSTANT NUMBER(1)   := 1;      -- �A��
    --
    -- *** ���[�J���ϐ� ***
    ld_process_date   DATE;                                 -- �Ɩ��������t
    lt_notify_subject fnd_lookup_values_vl.attribute1%TYPE; -- ����
    lt_notify_body    fnd_lookup_values_vl.attribute2%TYPE; -- �{��
    lt_party_name     hz_parties.party_name%TYPE;           -- �ڋq��
    lt_send_user_name xxcso_employees_v2.user_name%TYPE;    -- �񑗌����[�U�[��
    lt_dest_user_name xxcso_employees_v2.user_name%TYPE;    -- �񑗐惆�[�U�[��
    ln_seq_num        NUMBER;                               -- �A��
    --
    -- *** ���[�J���E�J�[�\�� ***
    CURSOR xsds_data_cur
    IS
      SELECT   xev.user_name dest_user_name -- �񑗐惆�[�U�[��
      FROM     xxcso_sp_decision_sends xsds -- �r�o�ꌈ�񑗐�e�[�u��
              ,xxcso_employees_v2      xev  -- �]�ƈ��}�X�^�i�ŐV�j�r���[
      WHERE    xsds.sp_decision_header_id = it_sp_decision_header_id
      AND      xsds.approval_state_type   IN ( ct_approval_state_type_in_prc, ct_approval_state_type_prcssd )
      AND      xsds.approve_code          <> '*'
      AND      xsds.approve_code          = xev.employee_number
      ORDER BY xsds.approval_authority_number DESC
      ;
    --
    -- *** ���[�J���E���R�[�h ***
    l_xsds_data_rec xsds_data_cur%ROWTYPE;
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
    ln_seq_num    := 0;
    --
    -- ========================================
    -- A-1.��������
    -- ========================================
    init(
        iv_notify_type           => iv_notify_type            -- �ʒm�敪
      , it_sp_decision_header_id => it_sp_decision_header_id  -- �r�o�ꌈ�w�b�_�h�c
      , iv_send_employee_number  => iv_send_employee_number   -- �񑗌��]�ƈ��ԍ�
      , iv_dest_employee_number  => iv_dest_employee_number   -- �񑗐�]�ƈ��ԍ�
      , od_process_date          => ld_process_date           -- �Ɩ��������t
      , ov_errbuf                => lv_errbuf                 -- �G���[�E���b�Z�[�W --# �Œ� #
      , ov_retcode               => lv_retcode                -- ���^�[���E�R�[�h   --# �Œ� #
    );
    --
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_process_expt;
      --
    END IF;
    --
    -- ========================================
    -- A-2. �ʒm��񒊏o
    -- ========================================
    get_notify_info(
        iv_notify_type           => iv_notify_type            -- �ʒm�敪
      , id_process_date          => ld_process_date           -- �Ɩ��������t
      , it_sp_decision_header_id => it_sp_decision_header_id  -- �r�o�ꌈ�w�b�_�h�c
      , iv_send_employee_number  => iv_send_employee_number   -- �񑗌��]�ƈ��ԍ�
      , iv_dest_employee_number  => iv_dest_employee_number   -- �񑗐�]�ƈ��ԍ�
      , ot_notify_subject        => lt_notify_subject         -- ����
      , ot_notify_body           => lt_notify_body            -- �{��
      , ot_party_name            => lt_party_name             -- �ڋq��
      , ot_send_user_name        => lt_send_user_name         -- �񑗌����[�U�[��
      , ot_dest_user_name        => lt_dest_user_name         -- �񑗐惆�[�U�[��
      , ov_errbuf                => lv_errbuf                 -- �G���[�E���b�Z�[�W  --# �Œ� #
      , ov_retcode               => lv_retcode                -- ���^�[���E�R�[�h    --# �Œ� #
    );
    --
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_process_expt;
      --
    END IF;
    --
    ------------------------------------------------------------
    -- �ʒm�敪���u���F�˗��v�u�m�F�˗��v�u���F�����v�̏ꍇ
    ------------------------------------------------------------
    IF ( iv_notify_type in ( cv_notify_type_aprv_req, cv_notify_type_cnfrm_req, cv_notify_type_aprv_cmplt ) ) THEN
      -- ========================================
      -- A-3.���F�^�m�F�ʒm���t
      -- (A-7.�r�o�ꌈ�ʒm���[�N�t���[�N�������s)
      -- ========================================
      start_sp_dec_wf_proc(
          it_sp_decision_header_id => it_sp_decision_header_id            -- �r�o�ꌈ�w�b�_�h�c
        , iv_dest_user_name        => lt_dest_user_name                   -- �ʒm�񑗐�
        , iv_send_user_name        => lt_send_user_name                   -- �ʒm�񑗌�
        , it_notify_subject        => lt_notify_subject || lt_party_name  -- �ʒm�����iA-2�Ŏ擾���������{�ڋq���j
        , it_notify_body           => lt_notify_body                      -- �ʒm�{���iA-2�Ŏ擾�����{���j
        , in_seq_num               => cv_seq_num                          -- �A��
        , ov_errbuf                => lv_errbuf                           -- �G���[�E���b�Z�[�W  --# �Œ� #
        , ov_retcode               => lv_retcode                          -- ���^�[���E�R�[�h    --# �Œ� #
      );
      --
      IF ( lv_retcode <> cv_status_normal ) THEN
        RAISE global_process_expt;
        --
      END IF;
      --
    ------------------------------------------------------------
    -- �ʒm�敪���u�ی��ʒm�v�u�ԋp�ʒm�v�̏ꍇ
    ------------------------------------------------------------
    ELSE
      -- ========================================
      -- A-4. �ی��^�ԋp�ʒm���񒊏o
      -- ========================================
      -- �J�[�\���I�[�v��
      OPEN xsds_data_cur;
--
      <<get_data_loop>>
      LOOP
        FETCH xsds_data_cur INTO l_xsds_data_rec;
        -- �����Ώی����i�[
        gn_target_cnt := xsds_data_cur%ROWCOUNT;
--
        EXIT WHEN xsds_data_cur%NOTFOUND
        OR  xsds_data_cur%ROWCOUNT = 0;
        --
        -- �A�Ԃ��J�E���g�A�b�v
        ln_seq_num := ln_seq_num + 1;
        --
        -- ========================================
        -- A-5.�ی��^�ԋp�ʒm���t
        -- (A-7.�r�o�ꌈ�ʒm���[�N�t���[�N�������s)
        -- ========================================
        start_sp_dec_wf_proc(
            it_sp_decision_header_id => it_sp_decision_header_id           -- �r�o�ꌈ�w�b�_�h�c
          , iv_dest_user_name        => l_xsds_data_rec.dest_user_name     -- �ʒm�񑗐�
          , iv_send_user_name        => lt_send_user_name                  -- �ʒm�񑗌�
          , it_notify_subject        => lt_notify_subject || lt_party_name -- �ʒm�����iA-2�Ŏ擾���������{�ڋq���j
          , it_notify_body           => lt_notify_body                     -- �ʒm�{���iA-2�Ŏ擾�����{���j
          , in_seq_num               => ln_seq_num                         -- �A��
          , ov_errbuf                => lv_errbuf                          -- �G���[�E���b�Z�[�W  --# �Œ� #
          , ov_retcode               => lv_retcode                         -- ���^�[���E�R�[�h    --# �Œ� #
        );
        --
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE global_process_expt;
          --
        END IF;
        --
--
      END LOOP get_data_loop;
--
      -- �J�[�\���N���[�Y
      CLOSE xsds_data_cur;
      --
      -- �A�Ԃ��J�E���g�A�b�v
      ln_seq_num := ln_seq_num + 1;
      --
      -- ========================================
      -- A-6.�\���Ҍ����ی��^�ԋp�ʒm���t
      -- (A-7.�r�o�ꌈ�ʒm���[�N�t���[�N�������s)
      -- ========================================
      start_sp_dec_wf_proc(
          it_sp_decision_header_id => it_sp_decision_header_id           -- �r�o�ꌈ�w�b�_�h�c
        , iv_dest_user_name        => lt_dest_user_name                  -- �ʒm�񑗐�
        , iv_send_user_name        => lt_send_user_name                  -- �ʒm�񑗌�
        , it_notify_subject        => lt_notify_subject || lt_party_name -- �ʒm�����iA-2�Ŏ擾���������{�ڋq���j
        , it_notify_body           => lt_notify_body                     -- �ʒm�{���iA-2�Ŏ擾�����{���j
        , in_seq_num               => ln_seq_num                         -- �A��
        , ov_errbuf                => lv_errbuf                          -- �G���[�E���b�Z�[�W  --# �Œ� #
        , ov_retcode               => lv_retcode                         -- ���^�[���E�R�[�h    --# �Œ� #
      );
      --
      IF ( lv_retcode <> cv_status_normal ) THEN
        RAISE global_process_expt;
        --
      END IF;
      --
    END IF;
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
      -- �J�[�\�����N���[�Y����Ă��Ȃ��ꍇ
      IF (xsds_data_cur%ISOPEN) THEN
        -- �J�[�\���N���[�Y
        CLOSE xsds_data_cur;
      END IF;
      --
      ov_errbuf  := SUBSTRB(cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000);
      ov_retcode := cv_status_error;
      --
    WHEN global_api_others_expt THEN
      -- *** ���ʊ֐�OTHERS��O�n���h�� ***
      -- �G���[�����J�E���g
      gn_error_cnt := gn_error_cnt + 1;
      --
      -- �J�[�\�����N���[�Y����Ă��Ȃ��ꍇ
      IF (xsds_data_cur%ISOPEN) THEN
        -- �J�[�\���N���[�Y
        CLOSE xsds_data_cur;
      END IF;
      --
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM || lv_errbuf;
      ov_retcode := cv_status_error;
      --
    WHEN OTHERS THEN
      -- *** OTHERS��O�n���h�� ***
      -- �G���[�����J�E���g
      gn_error_cnt := gn_error_cnt + 1;
      --
      -- �J�[�\�����N���[�Y����Ă��Ȃ��ꍇ
      IF (xsds_data_cur%ISOPEN) THEN
        -- �J�[�\���N���[�Y
        CLOSE xsds_data_cur;
      END IF;
      --
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
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
      iv_notify_type           IN         VARCHAR2    -- �ʒm�敪
    , it_sp_decision_header_id IN         xxcso_sp_decision_headers.sp_decision_header_id%TYPE  -- �r�o�ꌈ�w�b�_�h�c
    , iv_send_employee_number  IN         VARCHAR2    -- �񑗌��]�ƈ��ԍ�
    , iv_dest_employee_number  IN         VARCHAR2    -- �񑗐�]�ƈ��ԍ�
    , errbuf                   OUT NOCOPY VARCHAR2    -- �G���[�E���b�Z�[�W  --# �Œ� #
    , retcode                  OUT NOCOPY VARCHAR2    -- ���^�[���E�R�[�h    --# �Œ� #
  )
  --
  --###########################  �Œ蕔 START   ###########################
  --
  IS
    --
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'main';  -- �v���O������
    --
/*
    cv_appl_short_name CONSTANT VARCHAR2(10)  := 'XXCCP';            -- �A�h�I���F���ʁEIF�̈�
    cv_target_rec_msg  CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90000'; -- �Ώی������b�Z�[�W
    cv_success_rec_msg CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90001'; -- �����������b�Z�[�W
    cv_error_rec_msg   CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90002'; -- �G���[�������b�Z�[�W
    cv_skip_rec_msg    CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90003'; -- �X�L�b�v�������b�Z�[�W
    cv_cnt_token       CONSTANT VARCHAR2(10)  := 'COUNT';            -- �������b�Z�[�W�p�g�[�N����
    cv_normal_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004'; -- ����I�����b�Z�[�W
    cv_warn_msg        CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005'; -- �x���I�����b�Z�[�W
    cv_error_msg       CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006'; -- �G���[�I���S���[���o�b�N
*/
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf          VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode         VARCHAR2(1);     -- ���^�[���E�R�[�h
--    lv_errmsg          VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--    lv_message_code    VARCHAR2(100);   -- �I�����b�Z�[�W�R�[�h
    --
  BEGIN
    --
/*
    --###########################  �Œ蕔 START   #####################################################
    --
    -- �Œ�o��
    -- �R���J�����g�w�b�_���b�Z�[�W�o�͊֐��̌Ăяo��
    xxccp_common_pkg.put_log_header(
       ov_retcode => lv_retcode
      ,ov_errbuf  => lv_errbuf
    );
    --
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_others_expt;
    END IF;
    --
    --###########################  �Œ蕔 END   #############################
*/
    --
    -- ===============================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ===============================================
    submain(
        iv_notify_type           => iv_notify_type            -- �ʒm�敪
      , it_sp_decision_header_id => it_sp_decision_header_id  -- �r�o�ꌈ�w�b�_�h�c
      , iv_send_employee_number  => iv_send_employee_number   -- �񑗌��]�ƈ��ԍ�
      , iv_dest_employee_number  => iv_dest_employee_number   -- �񑗐�]�ƈ��ԍ�
      , ov_errbuf                => lv_errbuf                 -- �G���[�E���b�Z�[�W  --# �Œ� #
      , ov_retcode               => lv_retcode                -- ���^�[���E�R�[�h    --# �Œ� #
    );
    --
    errbuf  := lv_errbuf;
/*
    IF ( lv_retcode = cv_status_error ) THEN
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
    IF ( lv_retcode = cv_status_normal ) THEN
      lv_message_code := cv_normal_msg;
    ELSIF( lv_retcode = cv_status_error ) THEN
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
*/
    --�X�e�[�^�X�Z�b�g
    retcode := lv_retcode;
    --�I���X�e�[�^�X���G���[�̏ꍇ��ROLLBACK����
    IF ( retcode = cv_status_error ) THEN
      ROLLBACK;
/*
      -- *** DEBUG_LOG ***
      -- ���[���o�b�N�������Ƃ����O�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg11 || CHR(10) ||
                   ''
      );
*/
    END IF;
--
  EXCEPTION
    WHEN global_api_others_expt THEN
      -- *** ���ʊ֐�OTHERS��O�n���h�� ***
      errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM || lv_errbuf;
      retcode := cv_status_error;
      ROLLBACK;
    WHEN OTHERS THEN
      -- *** OTHERS��O�n���h�� ***
      errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      retcode := cv_status_error;
      ROLLBACK;
  END main;
--
--###########################  �Œ蕔 END   #######################################################
--
END XXCSO020A02C;
/
