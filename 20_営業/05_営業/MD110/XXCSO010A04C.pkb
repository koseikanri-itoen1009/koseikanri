CREATE OR REPLACE PACKAGE BODY APPS.XXCSO010A04C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCSO010A04C(body)
 * Description      : �����̔��@�ݒu�_����o�^/�X�V��ʁA�_�񏑌�����ʂ���
 *                    �����̔��@�ݒu�_�񏑂𒠕[�ɏo�͂��܂��B
 * MD.050           : MD050_CSO_010_A04_�����̔��@�ݒu�_��PDF�t�@�C���쐬
 *                    
 * Version          : 1.4
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   ��������(A-1)
 *  get_contract_data      �f�[�^�擾(A-2)
 *  insert_data            ���[�N�e�[�u���o��(A-3)
 *  act_svf                SVF�N��(A-4)
 *  delete_data            ���[�N�e�[�u���f�[�^�폜(A-5)
 *  submain                ���C�������v���V�[�W��
 *                           SVF�N��API�G���[�`�F�b�N(A-6)
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *                         �I������(A-7)
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009-02-03    1.0   Kichi.Cho        �V�K�쐬
 *  2009-03-03    1.1   Kazuyo.Hosoi     SVF�N��API���ߍ���
 *  2009-03-06    1.1   Abe.Daisuke     �y�ۑ�No71�z�����ʏ����A�ꗥ�����E�e��ʏ����̉�ʓ��͐���̕ύX�Ή�
 *  2009-03-13    1.1   Mio.Maruyama    �y��Q052,055,056�z���o�����ύX�E�e�[�u���T�C�Y�ύX
 *  2009-04-27    1.2   Kazuo.Satomura   �V�X�e���e�X�g��Q�Ή�(T1_0705,T1_0778)
 *  2009-05-01    1.3   Tomoko.Mori      T1_0897�Ή�
 *  2009-09-14    1.4   Mio.Maruyama     0001355�Ή�
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
  cv_msg_part               CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont               CONSTANT VARCHAR2(3) := '.';
--
--################################  �Œ蕔 END   ##################################
--
--#######################  �Œ�O���[�o���ϐ��錾�� START   #######################
--
  gv_out_msg       VARCHAR2(2000);
  gn_target_cnt    NUMBER;                    -- �Ώی���
  gn_normal_cnt    NUMBER;                    -- ���팏��
  gn_error_cnt     NUMBER;                    -- �G���[����
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
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name           CONSTANT VARCHAR2(100) := 'XXCSO010A04C';      -- �p�b�P�[�W��
  cv_app_name           CONSTANT VARCHAR2(5)   := 'XXCSO';             -- �A�v���P�[�V�����Z�k��
  cv_svf_name           CONSTANT VARCHAR2(100) := 'XXCSO010A04';       -- �p�b�P�[�W��
  -- ���b�Z�[�W�R�[�h
  cv_tkn_number_01      CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00026';  -- �p�����[�^NULL�G���[
  cv_tkn_number_02      CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00416';  -- �_�񏑔ԍ�
  cv_tkn_number_03      CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00413';  -- �����̔��@�ݒu�_��ID�`�F�b�N�G���[
  cv_tkn_number_04      CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00414';  -- �����̔��@�ݒu�_�񏑏��擾�G���[
  cv_tkn_number_05      CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00415';  -- �����̔��@�ݒu�_�񏑏�񕡐����݃G���[
  cv_tkn_number_06      CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00417';  -- API�G���[���b�Z�[�W
  cv_tkn_number_07      CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00418';  -- �f�[�^�ǉ��G���[���b�Z�[�W
  cv_tkn_number_08      CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00419';  -- �f�[�^�폜�G���[���b�Z�[�W
  cv_tkn_number_09      CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00496';  -- �p�����[�^�o��
  cv_tkn_number_10      CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00024';  -- �f�[�^�擾�G���[
  cv_tkn_number_11      CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00278';  -- ���b�N�G���[���b�Z�[�W
--
  -- �g�[�N���R�[�h
  cv_tkn_param_nm       CONSTANT VARCHAR2(30) := 'PARAM_NAME';
  cv_tkn_val            CONSTANT VARCHAR2(30) := 'VALUE';
  cv_tkn_con_mng_id     CONSTANT VARCHAR2(30) := 'CONTRACT_MANAGEMENT_ID';
  cv_tkn_contract_num   CONSTANT VARCHAR2(30) := 'CONTRACT_NUMBER';
  cv_tkn_err_msg        CONSTANT VARCHAR2(30) := 'ERR_MSG';
  cv_tkn_tbl            CONSTANT VARCHAR2(30) := 'TABLE';
  cv_tkn_api_nm         CONSTANT VARCHAR2(30) := 'API_NAME';
  cv_tkn_request_id     CONSTANT VARCHAR2(30) := 'REQUEST_ID';
--
  -- ���t����
  cv_flag_1             CONSTANT VARCHAR2(1)  := '1';             -- ����A-2-1
  cv_flag_2             CONSTANT VARCHAR2(1)  := '2';             -- ����A-2-2
  -- �L��
  cv_enabled_flag       CONSTANT VARCHAR2(1)  := 'Y';
  -- �A�N�e�B�u
  cv_active_status      CONSTANT VARCHAR2(1)  := 'A';
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gt_con_mng_id         xxcso_contract_managements.contract_management_id%TYPE;      -- �����̔��@�ݒu�_��ID
  gt_contract_number    xxcso_contract_managements.contract_number%TYPE;             -- �_�񏑔ԍ�
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  -- �����̔��@�ݒu�_�񏑒��[���[�N�e�[�u�� �f�[�^�i�[�p���R�[�h�^��`
  TYPE g_rep_cont_data_rtype IS RECORD(
    install_location              xxcso_rep_auto_sale_cont.install_location%TYPE,              -- �ݒu���P�[�V����
    contract_number               xxcso_rep_auto_sale_cont.contract_number%TYPE,               -- �_�񏑔ԍ�
    contract_name                 xxcso_rep_auto_sale_cont.contract_name%TYPE,                 -- �_��Җ�
    contract_period               xxcso_rep_auto_sale_cont.contract_period%TYPE,               -- �_�����
    cancellation_offer_code       xxcso_rep_auto_sale_cont.cancellation_offer_code%TYPE,       -- �_������\���o
    other_content                 xxcso_rep_auto_sale_cont.other_content%TYPE,                 -- ���񎖍�
    sales_charge_details_delivery xxcso_rep_auto_sale_cont.sales_charge_details_delivery%TYPE, -- �萔�����׏����t�於
    delivery_address              xxcso_rep_auto_sale_cont.delivery_address%TYPE,              -- ���t��Z��
    install_name                  xxcso_rep_auto_sale_cont.install_name%TYPE,                  -- �ݒu�於
    install_address               xxcso_rep_auto_sale_cont.install_address%TYPE,               -- �ݒu��Z��
    install_date                  xxcso_rep_auto_sale_cont.install_date%TYPE,                  -- �ݒu��
    bank_name                     xxcso_rep_auto_sale_cont.bank_name%TYPE,                     -- ���Z�@�֖�
    blanches_name                 xxcso_rep_auto_sale_cont.blanches_name%TYPE,                 -- �x�X��
    account_number                xxcso_rep_auto_sale_cont.account_number%TYPE,                -- �ڋq�R�[�h
    bank_account_number           xxcso_rep_auto_sale_cont.bank_account_number%TYPE,           -- �����ԍ�
    bank_account_name_kana        xxcso_rep_auto_sale_cont.bank_account_name_kana%TYPE,        -- �������`�J�i
    publish_base_code             xxcso_rep_auto_sale_cont.publish_base_code%TYPE,             -- �S�����_
    publish_base_name             xxcso_rep_auto_sale_cont.publish_base_name%TYPE,             -- �S�����_��
    contract_effect_date          xxcso_rep_auto_sale_cont.contract_effect_date%TYPE,          -- �_�񏑔�����
    issue_belonging_address       xxcso_rep_auto_sale_cont.issue_belonging_address%TYPE,       -- ���s�������Z��
    issue_belonging_name          xxcso_rep_auto_sale_cont.issue_belonging_name%TYPE,          -- ���s��������
    issue_belonging_boss_position xxcso_rep_auto_sale_cont.issue_belonging_boss_position%TYPE, -- ���s���������E�ʖ�
    issue_belonging_boss          xxcso_rep_auto_sale_cont.issue_belonging_boss%TYPE,          -- ���s����������
    close_day_code                xxcso_rep_auto_sale_cont.close_day_code%TYPE,                -- ����
    transfer_month_code           xxcso_rep_auto_sale_cont.transfer_month_code%TYPE,           -- ������
    transfer_day_code             xxcso_rep_auto_sale_cont.transfer_day_code%TYPE,             -- ������
    exchange_condition            xxcso_rep_auto_sale_cont.exchange_condition%TYPE,            -- �������
    condition_contents_1          xxcso_rep_auto_sale_cont.condition_contents_1%TYPE,          -- �������e1
    condition_contents_2          xxcso_rep_auto_sale_cont.condition_contents_2%TYPE,          -- �������e2
    condition_contents_3          xxcso_rep_auto_sale_cont.condition_contents_3%TYPE,          -- �������e3
    condition_contents_4          xxcso_rep_auto_sale_cont.condition_contents_4%TYPE,          -- �������e4
    condition_contents_5          xxcso_rep_auto_sale_cont.condition_contents_5%TYPE,          -- �������e5
    condition_contents_6          xxcso_rep_auto_sale_cont.condition_contents_6%TYPE,          -- �������e6
    condition_contents_7          xxcso_rep_auto_sale_cont.condition_contents_7%TYPE,          -- �������e7
    condition_contents_8          xxcso_rep_auto_sale_cont.condition_contents_8%TYPE,          -- �������e8
    condition_contents_9          xxcso_rep_auto_sale_cont.condition_contents_9%TYPE,          -- �������e9
    condition_contents_10         xxcso_rep_auto_sale_cont.condition_contents_10%TYPE,         -- �������e10
    condition_contents_11         xxcso_rep_auto_sale_cont.condition_contents_11%TYPE,         -- �������e11
    condition_contents_12         xxcso_rep_auto_sale_cont.condition_contents_12%TYPE,         -- �������e12
    install_support_amt           xxcso_rep_auto_sale_cont.install_support_amt%TYPE,           -- �ݒu���^��
    electricity_information       xxcso_rep_auto_sale_cont.electricity_information%TYPE,       -- �d�C����
    transfer_commission_info      xxcso_rep_auto_sale_cont.transfer_commission_info%TYPE,      -- �U�荞�ݎ萔�����
    electricity_amount            xxcso_sp_decision_headers.electricity_amount%TYPE,           -- �d�C��
    condition_contents_flag       BOOLEAN,                                              -- �̔��萔�����L���t���O
    install_support_amt_flag      BOOLEAN,                                              -- �ݒu���^���L���t���O
    electricity_information_flag  BOOLEAN                                              -- �d�C����L���t���O
  );
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
     ot_status           OUT NOCOPY VARCHAR2       -- �X�e�[�^�X
    ,ot_cooperate_flag   OUT NOCOPY VARCHAR2       -- �}�X�^�A�g�t���O
    ,ov_errbuf           OUT NOCOPY VARCHAR2       -- �G���[�E���b�Z�[�W            --# �Œ� #
    ,ov_retcode          OUT NOCOPY VARCHAR2       -- ���^�[���E�R�[�h              --# �Œ� #
    ,ov_errmsg           OUT NOCOPY VARCHAR2       -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'init';     -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
    -- *** ���[�J���萔 ***
    cv_con_mng_id        CONSTANT VARCHAR2(100)   := '�����̔��@�ݒu�_��ID';
    -- *** ���[�J���ϐ� ***
    -- ���b�Z�[�W�o�͗p
    lv_msg               VARCHAR2(5000);
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ===================================================
    -- �p�����[�^�K�{�`�F�b�N(�����̔��@�ݒu�_��ID)
    -- ===================================================
    IF (gt_con_mng_id IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name              -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_tkn_number_01         -- ���b�Z�[�W�R�[�h
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- ===========================
    -- �N���p�����[�^���b�Z�[�W�o��
    -- ===========================
    lv_msg := xxccp_common_pkg.get_msg(
                 iv_application  => cv_app_name            --�A�v���P�[�V�����Z�k��
                ,iv_name         => cv_tkn_number_09       --���b�Z�[�W�R�[�h
                ,iv_token_name1  => cv_tkn_param_nm        --�g�[�N���R�[�h1
                ,iv_token_value1 => cv_con_mng_id          --�g�[�N���l1
                ,iv_token_name2  => cv_tkn_val             --�g�[�N���R�[�h2
                ,iv_token_value2 => TO_CHAR(gt_con_mng_id) --�g�[�N���l2
              );
    -- ���O�o��
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   =>'' || CHR(10) || lv_msg
    );
--
    -- ===================================================
    -- �_�񏑔ԍ��A�X�e�[�^�X�A�}�X�^�A�g�t���O���擾
    -- ===================================================
    BEGIN
      SELECT xcm.contract_number contract_number
            ,xcm.status status
            ,xcm.cooperate_flag cooperate_flag
      INTO   gt_contract_number
            ,ot_status
            ,ot_cooperate_flag
      FROM   xxcso_contract_managements xcm
      WHERE  xcm.contract_management_id = gt_con_mng_id;
--
    -- ===========================
    -- �_�񏑔ԍ����b�Z�[�W�o��
    -- ===========================
    lv_msg := xxccp_common_pkg.get_msg(
                 iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                ,iv_name         => cv_tkn_number_02             -- ���b�Z�[�W�R�[�h
                ,iv_token_name1  => cv_tkn_contract_num          -- �g�[�N���R�[�h1
                ,iv_token_value1 => gt_contract_number           -- �g�[�N���l1
              );
    -- ���O�o��
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   =>'' || CHR(10) || lv_msg
    );
--
    EXCEPTION
      -- �f�[�^���o�Ɏ��s�����ꍇ�̌㏈��
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_03           -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_con_mng_id          -- �g�[�N���R�[�h1
                       ,iv_token_value1 => TO_CHAR(gt_con_mng_id)     -- �g�[�N���l1
                     );
        lv_errbuf := lv_errmsg || SQLERRM;
        RAISE global_process_expt;
    END;
--
  EXCEPTION
    -- *** ������O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
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
   * Procedure Name   : get_contract_data
   * Description      : �f�[�^�擾(A-2)
   ***********************************************************************************/
  PROCEDURE get_contract_data(
     iv_process_flag       IN         VARCHAR2               -- �����t���O
    ,o_rep_cont_data_rec   OUT NOCOPY g_rep_cont_data_rtype  -- �_�񏑃f�[�^
    ,ov_errbuf             OUT NOCOPY VARCHAR2               -- �G���[�E���b�Z�[�W            --# �Œ� #
    ,ov_retcode            OUT NOCOPY VARCHAR2               -- ���^�[���E�R�[�h              --# �Œ� #
    ,ov_errmsg             OUT NOCOPY VARCHAR2               -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'get_contract_data';  -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    -- �󎆕\���t���O
    cv_stamp_show_1          CONSTANT VARCHAR2(1)   := '1';  -- �\��
    cv_stamp_show_0          CONSTANT VARCHAR2(1)   := '0';  -- ��\��
    -- �ݒu���P�[�V����
    cv_i_location_type_2     CONSTANT VARCHAR2(1)   := '2';  -- ���O
    cv_i_location_type_3     CONSTANT VARCHAR2(1)   := '3';  -- �H��
    -- �d�C��敪
    cv_electricity_type_1    CONSTANT VARCHAR2(1)   := '1';
    cv_electricity_type_2    CONSTANT VARCHAR2(1)   := '2';
    -- �U���萔�����S�敪
    cv_bank_trans_fee_div_1  CONSTANT VARCHAR2(1)   := 'S';
    cv_bank_trans_fee_div_2  CONSTANT VARCHAR2(1)   := 'I';
    -- ��������敪
    cv_cond_b_type_1         CONSTANT VARCHAR2(1)   := '1';  -- �����ʏ���
    cv_cond_b_type_2         CONSTANT VARCHAR2(1)   := '2';  -- �����ʏ����i��t���o�^�p�j
    cv_cond_b_type_3         CONSTANT VARCHAR2(1)   := '3';  -- �ꗥ�E�e��ʏ���
    cv_cond_b_type_4         CONSTANT VARCHAR2(1)   := '4';  -- �ꗥ�E�e��ʏ����i��t���o�^�p�j
    -- SP�ꌈ�ڋq�敪
    cv_sp_d_cust_class_3     CONSTANT VARCHAR2(1)   := '3';  -- �a�l�P
    -- ���t�敪
    cv_delivery_div_1        CONSTANT VARCHAR2(1)   := '1';  -- �a�l�P
    -- �E�ʃR�[�h
    cv_p_code_002            CONSTANT VARCHAR2(3)   := '002';
    cv_p_code_003            CONSTANT VARCHAR2(3)   := '003';
    -- �r�o�ꌈ�e��ʎ������(�N�C�b�N�R�[�h)
    cv_lkup_container_type   CONSTANT VARCHAR2(100) := 'XXCSO1_SP_RULE_BOTTLE';
    -- ���^�C�v(�N�C�b�N�R�[�h)
    cv_lkup_months_type      CONSTANT VARCHAR2(100) := 'XXCSO1_MONTHS_TYPE';
    -- �����̔��@�ݒu�_�񏑌_��ҕ������e(�N�C�b�N�R�[�h)
    cv_lkup_contract_nm_con  CONSTANT VARCHAR2(100) := 'XXCSO1_CONTRACT_NM_CONTENT';
    -- �ȉ��]��
    cv_cond_conts_space      CONSTANT VARCHAR2(8)   := '�ȉ��]��';
    -- �藦
    cv_tei_rate              CONSTANT VARCHAR2(10)  := '�藦�i�z�j';
    -- ������
    cv_uri_rate              CONSTANT VARCHAR2(6)   := '������';
    -- �e���
    cv_youki_rate            CONSTANT VARCHAR2(6)   := '�e���';
    -- �r�o�ꌈ���׃e�[�u��
    cv_sp_decision_lines     CONSTANT VARCHAR2(100) := '�r�o�ꌈ���׃e�[�u��';
    -- �X�փ}�[�N
    cv_post_mark             CONSTANT VARCHAR2(2)   := '��';
    
    -- *** ���[�J���ϐ� ***
    lv_cond_business_type    VARCHAR2(1);       -- ��������敪
    ld_sysdate               DATE;              -- �Ɩ����t
    lv_cond_conts_tmp        xxcso_rep_auto_sale_cont.condition_contents_1%TYPE;    -- �������e1
    ln_lines_cnt             NUMBER;            -- ���׌���
    ln_bm1_bm_rate           NUMBER;            -- �a�l�P�a�l��
    ln_bm1_bm_amount         NUMBER;            -- �a�l�P�a�l���z
    lb_bm1_bm_rate           BOOLEAN;           -- �a�l�P�a�l���ɂ��藦���f�t���O
    lb_bm1_bm_amount         BOOLEAN;           -- �a�l�P�a�l���z�ɂ��藦���f�t���O
    lb_bm1_bm                BOOLEAN;           -- �̔��萔���L���t���O(TRUE:�L,FALSE:��)
--
    -- *** ���[�J���E�J�[�\�� *** 
    CURSOR l_sales_charge_cur
    IS
      SELECT xsdh.sp_decision_header_id sp_decision_header_id        -- �r�o�ꌈ�w�b�_�h�c
            ,xsdl.sp_decision_line_id sp_decision_line_id           -- �r�o�ꌈ���ׂh�c
            ,xcm.close_day_code close_day_code                      -- ���ߓ�
            ,(SELECT flvv_month.meaning                             -- ���e
              FROM   fnd_lookup_values_vl flvv_month                -- �Q�ƃ^�C�v�e�[�u��
              WHERE  flvv_month.lookup_type = cv_lkup_months_type
                AND  TRUNC(SYSDATE) BETWEEN TRUNC(flvv_month.start_date_active)
                                    AND TRUNC(NVL(flvv_month.end_date_active, SYSDATE))
                AND  flvv_month.enabled_flag = cv_enabled_flag
                AND  xcm.transfer_month_code = flvv_month.lookup_code
                AND  ROWNUM = 1
              ) transfer_month_code                                 -- ������
            ,xcm.transfer_day_code transfer_day_code                -- ������
            ,xsdh.condition_business_type condition_business_type   -- ��������敪
            ,xsdl.sp_container_type sp_container_type               -- �r�o�e��敪
            ,xsdl.fixed_price fixed_price                           -- �艿
            ,xsdl.sales_price sales_price                           -- ����
            ,xsdl.bm1_bm_rate bm1_bm_rate                           -- �a�l�P�a�l��
            ,xsdl.bm1_bm_amount bm1_bm_amount                       -- �a�l�P�a�l���z
            ,(CASE
               WHEN ((xsdh.condition_business_type IN (cv_cond_b_type_1, cv_cond_b_type_2))
                       AND (xsdl.bm1_bm_rate IS NOT NULL AND xsdl.bm1_bm_rate <> '0')) THEN
                 '�̔����i ' || TO_CHAR(xsdl.sales_price)
                             || '�~�̂Ƃ��A�P�{�ɂ��̔����i�� '
                             || TO_CHAR(xsdl.bm1_bm_rate) || '%���x����'
               WHEN ((xsdh.condition_business_type IN (cv_cond_b_type_1, cv_cond_b_type_2))
                       AND (xsdl.bm1_bm_amount IS NOT NULL AND xsdl.bm1_bm_amount <> '0')) THEN
                 '�̔����i ' || TO_CHAR(xsdl.sales_price)
                             || '�~�̂Ƃ��A�P�{�ɂ� '
                             || TO_CHAR(xsdl.bm1_bm_amount) || '�~���x����'
               WHEN ((xsdh.condition_business_type IN (cv_cond_b_type_3, cv_cond_b_type_4))
                       AND (xsdl.bm1_bm_rate IS NOT NULL AND xsdl.bm1_bm_rate <> '0')) THEN
                 '�̔��e�킪 ' || flvv.meaning
                               || '�̂Ƃ��A�P�{�ɂ������� '
                               || TO_CHAR(xsdl.bm1_bm_rate) || '%���x����'
               WHEN ((xsdh.condition_business_type IN (cv_cond_b_type_3, cv_cond_b_type_4))
                       AND (xsdl.bm1_bm_amount IS NOT NULL  AND xsdl.bm1_bm_amount <> '0')) THEN
                 '�̔��e�킪 ' || flvv.meaning
                               || '�̂Ƃ��A�P�{�ɂ� '
                               || TO_CHAR(xsdl.bm1_bm_amount) || '�~���x����'
              END) condition_contents                               -- �������e
       FROM   xxcso_contract_managements xcm      -- �_��Ǘ��e�[�u��
             ,xxcso_sp_decision_headers  xsdh     -- �r�o�ꌈ�w�b�_�e�[�u��
             ,xxcso_sp_decision_lines    xsdl     -- �r�o�ꌈ���׃e�[�u��
             ,(SELECT  flv.meaning
                       ,flv.lookup_code
                       /* 2009.04.27 K.Satomura T1_0778�Ή� START */
                       ,flv.attribute4
                       /* 2009.04.27 K.Satomura T1_0778�Ή� END */
                 FROM  fnd_lookup_values_vl flv
                WHERE  flv.lookup_type = cv_lkup_container_type
                  AND  TRUNC(ld_sysdate) BETWEEN TRUNC(flv.start_date_active)
                  AND  TRUNC(NVL(flv.end_date_active, ld_sysdate))
                  AND  flv.enabled_flag = cv_enabled_flag
              )  flvv    -- �Q�ƃ^�C�v
       WHERE  xcm.contract_management_id = gt_con_mng_id
         AND  xcm.sp_decision_header_id  = xsdh.sp_decision_header_id
         AND  xsdh.sp_decision_header_id = xsdl.sp_decision_header_id
         AND  xsdh.condition_business_type
                IN (cv_cond_b_type_1, cv_cond_b_type_2, cv_cond_b_type_3, cv_cond_b_type_4)
       /* 2009.04.27 K.Satomura T1_0778�Ή� START */
         --AND  xsdl.sp_container_type = flvv.lookup_code(+);
         AND  xsdl.sp_container_type = flvv.lookup_code(+)
       ORDER BY DECODE(xsdh.condition_business_type
                      ,cv_cond_b_type_1 ,xsdl.sp_decision_line_id
                      ,cv_cond_b_type_2 ,xsdl.sp_decision_line_id
                      ,cv_cond_b_type_3 ,flvv.attribute4
                      ,cv_cond_b_type_4 ,flvv.attribute4
                      )
       ;
       /* 2009.04.27 K.Satomura T1_0778�Ή� END */

--
    -- *** ���[�J���E���R�[�h *** 
    l_sales_charge_rec  l_sales_charge_cur%ROWTYPE;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- �Ɩ����t
    ld_sysdate := TRUNC(xxcso_util_common_pkg.get_online_sysdate);  -- ���ʊ֐��ɂ��Ɩ����t���i�[
--
    -- �����t���O
    -- �X�e�[�^�X���쐬���̏ꍇ�A�܂��̓X�e�[�^�X���m��ρA���}�X�^�A�g�t���O�����A�g�̏ꍇ
    IF (iv_process_flag = cv_flag_1) THEN
--
      -- ���O�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => '' || CHR(10)
             || '���� �_��֘A���F�X�e�[�^�X���쐬���A�܂��̓X�e�[�^�X���m��ρA���}�X�^�A�g�t���O�����A�g ����'
      );
--
      -- ===========================
      -- �_��֘A���擾�iA-2-1-1�j
      -- ===========================
      BEGIN
        SELECT (CASE
                  WHEN (SUBSTR(xcav.establishment_location, 2, 1)
                          IN (cv_i_location_type_2, cv_i_location_type_3)) THEN
                    cv_stamp_show_1
                  ELSE cv_stamp_show_0
                END) install_location                              -- �ݒu���P�[�V����
              ,xcm.contract_number   contract_number               -- �_�񏑔ԍ�
              /* 2009.09.14 M.Maruyama 0001355�Ή� START */
              --,((SELECT xcc.contract_name 
              ,SUBSTRB(((SELECT SUBSTRB(xcc.contract_name, 1, 100)
                 FROM   xxcso_contract_customers xcc   -- �_���e�[�u��
                 WHERE  xcc.contract_customer_id = xcm.contract_customer_id
                   AND  ROWNUM = 1
               --) || flvv_con.attr) contract_name               -- �_�񏑖�
               ) || flvv_con.attr), 1, 660) contract_name         -- �_�񏑖�
              /* 2009.09.14 M.Maruyama 0001355�Ή� END */
              ,xsdh.contract_year_date contract_period             -- �_�����
              ,xcm.cancellation_offer_code cancellation_offer_code -- �_������\���o
              ,xsdh.other_content other_content                    -- ���񎖍�
              ,xd.payment_name sales_charge_details_delivery       -- �x���於
              ,(NVL2(xd.post_code, cv_post_mark || xd.post_code || ' ', '') || xd.prefectures || xd.city_ward
                             || xd.address_1 || xd.address_2) delivery_address  -- ���t��Z��
              ,xcm.install_party_name install_name                 -- �ݒu��ڋq��
              ,(NVL2(xcm.install_postal_code, cv_post_mark || xcm.install_postal_code || ' ', '')
                           || xcm.install_state || xcm.install_city
                           || xcm.install_address1 || xcm.install_address2) install_address  -- �ݒu��Z��
              ,(SUBSTR(TO_CHAR(xcm.install_date, 'eedl', 'nls_calendar=''japanese imperial''')
                 , 1, INSTR(TO_CHAR(xcm.install_date, 'eedl', 'nls_calendar=''japanese imperial'''), ' ') -1)
                ) install_date                                     -- �ݒu��
              ,xba.bank_name bank_name                             -- ��s��
              ,xba.branch_name blanches_name                       -- �x�X��
              ,xba.bank_account_number bank_account_number         -- �����ԍ�
              ,xba.bank_account_name_kana bank_account_name_kana   -- �������`�J�i
              ,xcm.install_account_number account_number           -- �ݒu��ڋq�R�[�h
              ,xcm.publish_dept_code publish_base_code             -- �S�������R�[�h
              ,xlv2.location_name publish_base_name                -- �S�����_��
              ,(SUBSTR(TO_CHAR(xcm.contract_effect_date, 'eedl', 'nls_calendar=''japanese imperial''')
                 , 1, INSTR(TO_CHAR(xcm.contract_effect_date, 'eedl', 'nls_calendar=''japanese imperial'''), ' ') -1)
                ) contract_effect_date                             -- �_�񏑔�����
              ,(NVL2(xlv2.zip, cv_post_mark || xlv2.zip || ' ', '')
                    || xlv2.address_line1) issue_belonging_address      -- �Z��
              ,xlv2.location_name issue_belonging_name             -- ���s��������
              ,xsdh.install_support_amt install_support_amt        -- ����ݒu���^��
              ,xsdh.electricity_amount electricity_amount          -- �d�C��
              ,(DECODE(xsdh.electricity_type
                          , cv_electricity_type_1,  '���z ��z '|| xsdh.electricity_amount || '�~'
                          , cv_electricity_type_2, '�̔��@�Ɋւ��d�C��́A����ɂĉ����x����'
                          , '')
                ) electricity_information                          -- �d�C����
              ,(DECODE(xd.bank_transfer_fee_charge_div
                          , cv_bank_trans_fee_div_1,  '�U�荞�ݎ萔���͍b�̕��S�Ƃ���'
                          , cv_bank_trans_fee_div_2, '�U�荞�ݎ萔���͉��̕��S�Ƃ���'
                          , '�U�荞�ݎ萔���͔����v���܂���')
                ) transfer_commission_info                         -- �U�荞�ݎ萔�����
        INTO   o_rep_cont_data_rec.install_location              -- �ݒu���P�[�V����
              ,o_rep_cont_data_rec.contract_number               -- �_�񏑔ԍ�
              ,o_rep_cont_data_rec.contract_name                 -- �_��Җ�
              ,o_rep_cont_data_rec.contract_period               -- �_�����
              ,o_rep_cont_data_rec.cancellation_offer_code       -- �_������\���o
              ,o_rep_cont_data_rec.other_content                 -- ���񎖍�
              ,o_rep_cont_data_rec.sales_charge_details_delivery -- �萔�����׏����t�於
              ,o_rep_cont_data_rec.delivery_address              -- ���t��Z��
              ,o_rep_cont_data_rec.install_name                  -- �ݒu�於
              ,o_rep_cont_data_rec.install_address               -- �ݒu��Z��
              ,o_rep_cont_data_rec.install_date                  -- �ݒu��
              ,o_rep_cont_data_rec.bank_name                     -- ���Z�@�֖�
              ,o_rep_cont_data_rec.blanches_name                 -- �x�X��
              ,o_rep_cont_data_rec.bank_account_number           -- �����ԍ�
              ,o_rep_cont_data_rec.bank_account_name_kana        -- �������`�J�i
              ,o_rep_cont_data_rec.account_number                -- �ڋq�R�[�h
              ,o_rep_cont_data_rec.publish_base_code             -- �S�����_
              ,o_rep_cont_data_rec.publish_base_name             -- �S�����_��
              ,o_rep_cont_data_rec.contract_effect_date          -- �_�񏑔�����
              ,o_rep_cont_data_rec.issue_belonging_address       -- ���s�������Z��
              ,o_rep_cont_data_rec.issue_belonging_name          -- ���s��������
              ,o_rep_cont_data_rec.install_support_amt           -- �ݒu���^��
              ,o_rep_cont_data_rec.electricity_amount            -- �d�C��
              ,o_rep_cont_data_rec.electricity_information       -- �d�C����
              ,o_rep_cont_data_rec.transfer_commission_info      -- �U�荞�ݎ萔�����
        FROM   xxcso_cust_accounts_v      xcav     -- �ڋq�}�X�^�r���[
              ,xxcso_contract_managements xcm      -- �_��Ǘ��e�[�u��
              ,xxcso_sp_decision_headers  xsdh     -- �r�o�ꌈ�w�b�_�e�[�u��
              ,xxcso_destinations         xd       -- ���t��e�[�u��
              ,xxcso_bank_accounts        xba      -- ��s�����A�h�I���}�X�^
              ,xxcso_locations_v2         xlv2     -- ���Ə��}�X�^�i�ŐV�j�r���[
              ,(SELECT (flvv.attribute1 || flvv.attribute2) attr
                FROM   fnd_lookup_values_vl flvv -- �Q�ƃ^�C�v
                WHERE
                       flvv.lookup_type = cv_lkup_contract_nm_con
                  AND  TRUNC(ld_sysdate) BETWEEN TRUNC(flvv.start_date_active)
                                         AND TRUNC(NVL(flvv.end_date_active, ld_sysdate))
                  AND  flvv.enabled_flag = cv_enabled_flag
                  AND  ROWNUM = 1
               ) flvv_con
        WHERE  xcm.contract_management_id = gt_con_mng_id
          AND  xcm.install_account_number = xcav.account_number
          AND  xcav.account_status = cv_active_status
          AND  xcav.party_status = cv_active_status
          AND  xcm.sp_decision_header_id = xsdh.sp_decision_header_id
          AND  xd.contract_management_id(+) = xcm.contract_management_id
          AND  xd.delivery_div(+) = cv_delivery_div_1
          AND  xd.delivery_id = xba.delivery_id(+)
          AND  xlv2.dept_code = xcm.publish_dept_code;
--
        SELECT  (CASE
                  WHEN (TRUNC(NVL(TO_DATE(xev2.issue_date, 'YYYY/MM/DD'), ld_sysdate)) > ld_sysdate) THEN
                       xev2.position_name_old
                  ELSE xev2.position_name_new
                END) issue_belonging_boss_position                 -- ���s���������E�ʖ�
                ,xev2.full_name issue_belonging_boss               -- ����
        INTO    o_rep_cont_data_rec.issue_belonging_boss_position  -- ���s���������E�ʖ�
                ,o_rep_cont_data_rec.issue_belonging_boss          -- ����
        FROM   xxcso_employees_v2         xev2     -- �]�ƈ��}�X�^�i�ŐV�j�r���[
        WHERE  ((TRUNC(NVL(TO_DATE(xev2.issue_date, 'YYYY/MM/DD'), ld_sysdate)) <= ld_sysdate
                   AND xev2.position_code_new IN (cv_p_code_002, cv_p_code_003)
                   AND xev2.work_base_code_new = o_rep_cont_data_rec.publish_base_code)
               OR
                (TRUNC(NVL(TO_DATE(xev2.issue_date, 'YYYY/MM/DD'), ld_sysdate)) > ld_sysdate
                   AND xev2.position_code_old IN (cv_p_code_002, cv_p_code_003)
                   AND xev2.work_base_code_old = o_rep_cont_data_rec.publish_base_code)
               )
        AND ROWNUM = 1;
--
      EXCEPTION
        -- ���o���ʂ������̏ꍇ
        WHEN TOO_MANY_ROWS THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                         ,iv_name         => cv_tkn_number_05             -- ���b�Z�[�W�R�[�h
                         ,iv_token_name1  => cv_tkn_contract_num          -- �g�[�N���R�[�h1
                         ,iv_token_value1 => gt_contract_number           -- �g�[�N���l1
                       );
          lv_errbuf := lv_errmsg || SQLERRM;
          RAISE global_process_expt;
        -- �����ȊO�̃G���[�̏ꍇ
        WHEN OTHERS THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                         ,iv_name         => cv_tkn_number_04             -- ���b�Z�[�W�R�[�h
                         ,iv_token_name1  => cv_tkn_contract_num          -- �g�[�N���R�[�h1
                         ,iv_token_value1 => gt_contract_number           -- �g�[�N���l1
                       );
          lv_errbuf := lv_errmsg || SQLERRM;
          RAISE global_process_expt;
      END;
    -- �X�e�[�^�X���m��ρA���}�X�^�A�g�t���O���A�g�ς̏ꍇ
    ELSE
      -- ===========================
      -- �_��֘A���擾�iA-2-2-1�j
      -- ===========================
--
      -- ���O�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => '' || CHR(10) || '���� �_��֘A���F�X�e�[�^�X���m��ρA���}�X�^�A�g�t���O���A�g�� ����'
      );
--
      BEGIN
        SELECT (CASE
                  WHEN (SUBSTR(xcasv.establishment_location, 2, 1)
                          IN (cv_i_location_type_2, cv_i_location_type_3)) THEN
                    cv_stamp_show_1
                  ELSE cv_stamp_show_0
                END) install_location                                  -- �ݒu���P�[�V����
              ,xcm.contract_number   contract_number                   -- �_�񏑔ԍ�
              /* 2009.09.14 M.Maruyama 0001355�Ή� START */
              --,((SELECT xcc.contract_name 
              ,SUBSTRB(((SELECT SUBSTRB(xcc.contract_name, 1, 100)
                 FROM   xxcso_contract_customers xcc  -- �_���e�[�u��
                 WHERE  xcc.contract_customer_id = xcm.contract_customer_id
                   AND  ROWNUM = 1
               --) || flvv_con.attr) contract_name                     -- �_�񏑖�
               ) || flvv_con.attr), 1, 660) contract_name              -- �_�񏑖�
              /* 2009.09.14 M.Maruyama 0001355�Ή� END */
              ,xsdh.contract_year_date contract_period                 -- �_�����
              ,xcm.cancellation_offer_code cancellation_offer_code     -- �_������\���o
              ,xsdh.other_content other_content                        -- ���񎖍�
              ,pv.vendor_name sales_charge_details_delivery            -- �x���於
              ,NVL2(pvs.zip, cv_post_mark || pvs.zip || ' ', '') || pvs.state || pvs.city
                          || pvs.address_line1 || pvs.address_line2 delivery_address -- ���t��Z��
              ,xcasv.party_name install_name                           -- �ݒu��ڋq��
              ,NVL2(xcasv.postal_code, cv_post_mark || xcasv.postal_code || ' ', '') || xcasv.state || xcasv.city
                      || xcasv.address1 || xcasv.address2 install_address -- �ݒu��Z��
              ,(SUBSTR(TO_CHAR(xcm.install_date, 'eedl', 'nls_calendar=''japanese imperial''')
                 , 1, INSTR(TO_CHAR(xcm.install_date, 'eedl', 'nls_calendar=''japanese imperial'''), ' ') -1)
                ) install_date                                         -- �ݒu��
              ,xbav.bank_name bank_name                                -- ��s��
              ,xbav.bank_branch_name blanches_name                     -- �x�X��
              ,xbav.bank_account_num bank_account_number               -- �����ԍ�
              ,xbav.account_holder_name_alt bank_account_name_kana     -- �������`�J�i
              ,xcm.install_account_number account_number               -- �ݒu��ڋq�R�[�h
              ,xcm.publish_dept_code publish_base_code                 -- �S�������R�[�h
              ,xlv2.location_name publish_base_name                    -- �S�����_��
              ,(SUBSTR(TO_CHAR(xcm.contract_effect_date, 'eedl', 'nls_calendar=''japanese imperial''')
                 , 1, INSTR(TO_CHAR(xcm.contract_effect_date, 'eedl', 'nls_calendar=''japanese imperial'''), ' ') -1)
                ) contract_effect_date                                 -- �_�񏑔�����
              ,(NVL2(xlv2.zip, cv_post_mark || xlv2.zip || ' ', '') 
                  || xlv2.address_line1) issue_belonging_address       -- �Z��
              ,xlv2.location_name issue_belonging_name                 -- ���s��������
              ,xsdh.install_support_amt install_support_amt            -- ����ݒu���^��
              ,xsdh.electricity_amount electricity_amount              -- �d�C��
              ,DECODE(xsdh.electricity_type
                      , cv_electricity_type_1, '���z ��z '|| xsdh.electricity_amount || '�~'
                      , cv_electricity_type_2, '�̔��@�Ɋւ��d�C��́A����ɂĉ����x����'
                      , '') electricity_information                   -- �d�C����
              ,DECODE(pvs.bank_charge_bearer
                      , cv_bank_trans_fee_div_1, '�U�荞�ݎ萔���͍b�̕��S�Ƃ���'
                      , cv_bank_trans_fee_div_2, '�U�荞�ݎ萔���͉��̕��S�Ƃ���'
                      , '�U�荞�ݎ萔���͔����v���܂���') transfer_commission_info -- �U�荞�ݎ萔�����
        INTO   o_rep_cont_data_rec.install_location              -- �ݒu���P�[�V����
              ,o_rep_cont_data_rec.contract_number               -- �_�񏑔ԍ�
              ,o_rep_cont_data_rec.contract_name                 -- �_��Җ�
              ,o_rep_cont_data_rec.contract_period               -- �_�����
              ,o_rep_cont_data_rec.cancellation_offer_code       -- �_������\���o
              ,o_rep_cont_data_rec.other_content                 -- ���񎖍�
              ,o_rep_cont_data_rec.sales_charge_details_delivery -- �萔�����׏����t�於
              ,o_rep_cont_data_rec.delivery_address              -- ���t��Z��
              ,o_rep_cont_data_rec.install_name                  -- �ݒu�於
              ,o_rep_cont_data_rec.install_address               -- �ݒu��Z��
              ,o_rep_cont_data_rec.install_date                  -- �ݒu��
              ,o_rep_cont_data_rec.bank_name                     -- ���Z�@�֖�
              ,o_rep_cont_data_rec.blanches_name                 -- �x�X��
              ,o_rep_cont_data_rec.bank_account_number           -- �����ԍ�
              ,o_rep_cont_data_rec.bank_account_name_kana        -- �������`�J�i
              ,o_rep_cont_data_rec.account_number                -- �ڋq�R�[�h
              ,o_rep_cont_data_rec.publish_base_code             -- �S�����_
              ,o_rep_cont_data_rec.publish_base_name             -- �S�����_��
              ,o_rep_cont_data_rec.contract_effect_date          -- �_�񏑔�����
              ,o_rep_cont_data_rec.issue_belonging_address       -- ���s�������Z��
              ,o_rep_cont_data_rec.issue_belonging_name          -- ���s��������
              ,o_rep_cont_data_rec.install_support_amt           -- �ݒu���^��
              ,o_rep_cont_data_rec.electricity_amount            -- �d�C��
              ,o_rep_cont_data_rec.electricity_information       -- �d�C����
              ,o_rep_cont_data_rec.transfer_commission_info      -- �U�荞�ݎ萔�����
        FROM   xxcso_contract_managements xcm      -- �_��Ǘ��e�[�u��
              ,xxcso_cust_acct_sites_v    xcasv    -- �ڋq�}�X�^�T�C�g�r���[
              ,xxcso_sp_decision_headers  xsdh     -- �r�o�ꌈ�w�b�_�e�[�u��
              ,xxcso_sp_decision_custs    xsdc     -- �r�o�ꌈ�ڋq�e�[�u��
              ,xxcso_bank_accts_v         xbav     -- ��s�����}�X�^�i�ŐV�j�r���[
              ,xxcso_locations_v2         xlv2     -- ���Ə��}�X�^�i�ŐV�j�r���[
              ,(SELECT (flvv.attribute1 || flvv.attribute2) attr
                FROM   fnd_lookup_values_vl flvv -- �Q�ƃ^�C�v
                WHERE
                       flvv.lookup_type = cv_lkup_contract_nm_con
                  AND  TRUNC(ld_sysdate) BETWEEN TRUNC(flvv.start_date_active)
                                         AND TRUNC(NVL(flvv.end_date_active,ld_sysdate))
                  AND  flvv.enabled_flag = cv_enabled_flag
                  AND  ROWNUM = 1
               ) flvv_con
               ,po_vendors pv                      -- �d����}�X�^
               ,po_vendor_sites pvs                -- �d����T�C�g�}�X�^
        WHERE  xcm.contract_management_id = gt_con_mng_id
          AND  xcm.sp_decision_header_id = xsdh.sp_decision_header_id
          AND  xsdc.sp_decision_header_id = xsdh.sp_decision_header_id
          AND  xsdc.sp_decision_customer_class = cv_sp_d_cust_class_3
          AND  xcm.install_account_id = xcasv.cust_account_id
          AND  xsdc.customer_id = xbav.vendor_id(+)
          AND  xlv2.dept_code = xcm.publish_dept_code
          AND  pv.vendor_id(+) = NVL(xsdc.customer_id,fnd_api.g_miss_num)
          AND  pvs.vendor_id(+) = NVL(xsdc.customer_id,fnd_api.g_miss_num);
--
        SELECT  (CASE
                  WHEN (TRUNC(NVL(TO_DATE(xev2.issue_date, 'YYYY/MM/DD'), ld_sysdate)) > ld_sysdate) THEN
                       xev2.position_name_old
                  ELSE xev2.position_name_new
                END)  issue_belonging_boss_position                -- ���s���������E�ʖ�
                ,xev2.full_name issue_belonging_boss               -- ����
        INTO    o_rep_cont_data_rec.issue_belonging_boss_position  -- ���s���������E�ʖ�
                ,o_rep_cont_data_rec.issue_belonging_boss          -- ����
        FROM    xxcso_employees_v2         xev2     -- �]�ƈ��}�X�^�i�ŐV�j�r���[
        WHERE   ((TRUNC(NVL(TO_DATE(xev2.issue_date, 'YYYY/MM/DD'), ld_sysdate)) <= ld_sysdate
                   AND xev2.position_code_new IN (cv_p_code_002, cv_p_code_003)
                   AND xev2.work_base_code_new = o_rep_cont_data_rec.publish_base_code)
               OR
                (TRUNC(NVL(TO_DATE(xev2.issue_date, 'YYYY/MM/DD'), ld_sysdate)) > ld_sysdate
                   AND xev2.position_code_old IN (cv_p_code_002, cv_p_code_003)
                   AND xev2.work_base_code_old = o_rep_cont_data_rec.publish_base_code)
               )
        AND ROWNUM = 1;
--
      EXCEPTION
        -- ���o���ʂ������̏ꍇ
        WHEN TOO_MANY_ROWS THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_app_name                -- �A�v���P�[�V�����Z�k��
                         ,iv_name         => cv_tkn_number_05           -- ���b�Z�[�W�R�[�h
                         ,iv_token_name1  => cv_tkn_contract_num        -- �g�[�N���R�[�h1
                         ,iv_token_value1 => gt_contract_number         -- �g�[�N���l1
                       );
          lv_errbuf := lv_errmsg || SQLERRM;
          RAISE global_process_expt;
        -- �����ȊO�̃G���[�̏ꍇ
        WHEN OTHERS THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_app_name                -- �A�v���P�[�V�����Z�k��
                         ,iv_name         => cv_tkn_number_04           -- ���b�Z�[�W�R�[�h
                         ,iv_token_name1  => cv_tkn_contract_num        -- �g�[�N���R�[�h1
                         ,iv_token_value1 => gt_contract_number         -- �g�[�N���l1
                       );
          lv_errbuf := lv_errmsg || SQLERRM;
          RAISE global_process_expt;
      END;
    END IF;
--
    -- =================================
    -- �̔��萔�����擾�iA-2-1,2 -2�j
    -- =================================
    BEGIN
--
      -- �ϐ�������
      ln_lines_cnt             := 0;               -- ���׌���
      ln_bm1_bm_rate           := 0;               -- �a�l�P�a�l��
      ln_bm1_bm_amount         := 0;               -- �a�l�P�a�l���z
      lb_bm1_bm_rate           := TRUE;            -- �a�l�P�a�l���ɂ��藦���f�t���O
      lb_bm1_bm_amount         := TRUE;            -- �a�l�P�a�l���z�ɂ��藦���f�t���O
      lb_bm1_bm                := FALSE;           -- �̔��萔���L���t���O(TRUE:�L,FALSE:��)
--
      -- �r�o�ꌈ���׃J�[�\���I�[�v��
      OPEN l_sales_charge_cur;
--
      <<sales_charge_loop>>
      LOOP
        FETCH l_sales_charge_cur INTO l_sales_charge_rec;
--
        EXIT WHEN l_sales_charge_cur%NOTFOUND
          OR l_sales_charge_cur%ROWCOUNT = 0;
--
        -- �a�l�P�a�l���A���z�A��������敪�A���ߓ��A�������A������
        IF (ln_lines_cnt = 0) THEN
          -- ��������敪
          lv_cond_business_type := l_sales_charge_rec.condition_business_type;
          -- �����
          IF (lv_cond_business_type IN (cv_cond_b_type_1, cv_cond_b_type_2)) THEN
            o_rep_cont_data_rec.exchange_condition := cv_uri_rate;
          -- �e���
          ELSIF (lv_cond_business_type IN (cv_cond_b_type_3, cv_cond_b_type_4)) THEN
            o_rep_cont_data_rec.exchange_condition := cv_youki_rate;
          END IF;
--
          -- �a�l�P�a�l���A���z
          IF (l_sales_charge_rec.bm1_bm_rate IS NULL) THEN
            lb_bm1_bm_rate := FALSE;
          ELSE
            ln_bm1_bm_rate := l_sales_charge_rec.bm1_bm_rate;
          END IF;
          IF (l_sales_charge_rec.bm1_bm_amount IS NULL) THEN
            lb_bm1_bm_amount := FALSE;
          ELSE
            ln_bm1_bm_amount := l_sales_charge_rec.bm1_bm_amount;
          END IF;
--
          -- ���ߓ�
          o_rep_cont_data_rec.close_day_code := l_sales_charge_rec.close_day_code;
          -- ������
          o_rep_cont_data_rec.transfer_month_code := l_sales_charge_rec.transfer_month_code;
          -- ������
          o_rep_cont_data_rec.transfer_day_code := l_sales_charge_rec.transfer_day_code;
        ELSE
          -- �a�l�P�a�l��
          IF (lb_bm1_bm_rate = TRUE) THEN
            IF (l_sales_charge_rec.bm1_bm_rate IS NULL) THEN
              lb_bm1_bm_rate := FALSE;
            ELSIF (ln_bm1_bm_rate <> l_sales_charge_rec.bm1_bm_rate) THEN
              lb_bm1_bm_rate := FALSE;
            END IF;
          END IF;
          -- �a�l�P�a�l���z
          IF (lb_bm1_bm_amount = TRUE) THEN
            IF (l_sales_charge_rec.bm1_bm_amount IS NULL) THEN
              lb_bm1_bm_amount := FALSE;
            ELSIF (ln_bm1_bm_amount <> l_sales_charge_rec.bm1_bm_amount) THEN
              lb_bm1_bm_amount := FALSE;
            END IF;
          END IF;
        END IF;
        
        -- �̔��萔���L���`�F�b�N
        IF ((l_sales_charge_rec.bm1_bm_rate IS NOT NULL AND
              l_sales_charge_rec.bm1_bm_rate <> '0') OR
             (l_sales_charge_rec.bm1_bm_amount IS  NOT NULL AND
              l_sales_charge_rec.bm1_bm_amount <> '0')
            ) THEN
          -- �������e�Z�b�g
          IF (o_rep_cont_data_rec.condition_contents_1 IS NULL) THEN
            o_rep_cont_data_rec.condition_contents_1 := l_sales_charge_rec.condition_contents;
          ELSIF (o_rep_cont_data_rec.condition_contents_2 IS NULL) THEN
            o_rep_cont_data_rec.condition_contents_2 := l_sales_charge_rec.condition_contents;
          ELSIF (o_rep_cont_data_rec.condition_contents_3 IS NULL) THEN
            o_rep_cont_data_rec.condition_contents_3 := l_sales_charge_rec.condition_contents;
          ELSIF (o_rep_cont_data_rec.condition_contents_4 IS NULL) THEN
            o_rep_cont_data_rec.condition_contents_4 := l_sales_charge_rec.condition_contents;
          ELSIF (o_rep_cont_data_rec.condition_contents_5 IS NULL) THEN
            o_rep_cont_data_rec.condition_contents_5 := l_sales_charge_rec.condition_contents;
          ELSIF (o_rep_cont_data_rec.condition_contents_6 IS NULL) THEN
            o_rep_cont_data_rec.condition_contents_6 := l_sales_charge_rec.condition_contents;
          ELSIF (o_rep_cont_data_rec.condition_contents_7 IS NULL) THEN
            o_rep_cont_data_rec.condition_contents_7 := l_sales_charge_rec.condition_contents;
          ELSIF (o_rep_cont_data_rec.condition_contents_8 IS NULL) THEN
            o_rep_cont_data_rec.condition_contents_8 := l_sales_charge_rec.condition_contents;
          ELSIF (o_rep_cont_data_rec.condition_contents_9 IS NULL) THEN
            o_rep_cont_data_rec.condition_contents_9 := l_sales_charge_rec.condition_contents;
          ELSIF (o_rep_cont_data_rec.condition_contents_10 IS NULL) THEN
            o_rep_cont_data_rec.condition_contents_10 := l_sales_charge_rec.condition_contents;
          ELSIF (o_rep_cont_data_rec.condition_contents_11 IS NULL) THEN
            o_rep_cont_data_rec.condition_contents_11 := l_sales_charge_rec.condition_contents;
          ELSIF (o_rep_cont_data_rec.condition_contents_12 IS NULL) THEN
            o_rep_cont_data_rec.condition_contents_12 := l_sales_charge_rec.condition_contents;
          END IF;
          lb_bm1_bm := TRUE;
--
          -- �����v�Z
          ln_lines_cnt := ln_lines_cnt + 1;
        ELSIF (lb_bm1_bm = TRUE) THEN
          lb_bm1_bm := TRUE;
        ELSE
          lb_bm1_bm := FALSE;
        END IF;
--
      END LOOP sales_charge_loop;
--
      -- �J�[�\���E�N���[�Y
      CLOSE l_sales_charge_cur;
--
      -- ���O�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => '' || CHR(10) || '�̔��萔����񌏐��F' || ln_lines_cnt || '��'
      );
--
      -- ���׌�����1���𒴂���ꍇ
      IF (ln_lines_cnt > 1) THEN
        -- �e��ʁA�藦�̏ꍇ
        IF ((lv_cond_business_type IN (cv_cond_b_type_3, cv_cond_b_type_4))
               AND (lb_bm1_bm_rate OR lb_bm1_bm_amount)) THEN
          -- �a�l�P�a�l��
          IF (lb_bm1_bm_rate) THEN
            lv_cond_conts_tmp := '�̔����z�ɂ��A�P�{ ' || ln_bm1_bm_rate || '%���x����';
          -- �a�l�P�a�l���z
          ELSE
            lv_cond_conts_tmp := '�̔����z�ɂ��A�P�{ ' || ln_bm1_bm_amount || '�~���x����';
          END IF;
          -- ��������i�藦�j
          o_rep_cont_data_rec.exchange_condition := cv_tei_rate;
          -- �������e�Z�b�g
          o_rep_cont_data_rec.condition_contents_1 := lv_cond_conts_tmp;
          o_rep_cont_data_rec.condition_contents_2 := cv_cond_conts_space;   -- �ȉ��]��
          o_rep_cont_data_rec.condition_contents_3 := NULL;
          o_rep_cont_data_rec.condition_contents_4 := NULL;
          o_rep_cont_data_rec.condition_contents_5 := NULL;
          o_rep_cont_data_rec.condition_contents_6 := NULL;
          o_rep_cont_data_rec.condition_contents_7 := NULL;
          o_rep_cont_data_rec.condition_contents_8 := NULL;
          o_rep_cont_data_rec.condition_contents_9 := NULL;
          o_rep_cont_data_rec.condition_contents_10 := NULL;
          o_rep_cont_data_rec.condition_contents_11 := NULL;
          o_rep_cont_data_rec.condition_contents_12 := NULL;
--
          -- ���O�o��
          fnd_file.put_line(
             which  => FND_FILE.LOG
            ,buff   => '' || CHR(10) || '�̔��萔����񂪗e��ʁA�藦�ł��B'
          );
--
        ELSE
          -- �������e��12���ɖ����Ȃ��ꍇ�A�ŏI�s�Ɂu�ȉ��]���v���Z�b�g
          IF (ln_lines_cnt < 12) THEN
          -- �������e�Z�b�g
            IF (o_rep_cont_data_rec.condition_contents_2 IS NULL) THEN
              o_rep_cont_data_rec.condition_contents_2 := cv_cond_conts_space;    -- �ȉ��]��
            ELSIF (o_rep_cont_data_rec.condition_contents_3 IS NULL) THEN
              o_rep_cont_data_rec.condition_contents_3 := cv_cond_conts_space;    -- �ȉ��]��
            ELSIF (o_rep_cont_data_rec.condition_contents_4 IS NULL) THEN
              o_rep_cont_data_rec.condition_contents_4 := cv_cond_conts_space;    -- �ȉ��]��
            ELSIF (o_rep_cont_data_rec.condition_contents_5 IS NULL) THEN
              o_rep_cont_data_rec.condition_contents_5 := cv_cond_conts_space;    -- �ȉ��]��
            ELSIF (o_rep_cont_data_rec.condition_contents_6 IS NULL) THEN
              o_rep_cont_data_rec.condition_contents_6 := cv_cond_conts_space;    -- �ȉ��]��
            ELSIF (o_rep_cont_data_rec.condition_contents_7 IS NULL) THEN
              o_rep_cont_data_rec.condition_contents_7 := cv_cond_conts_space;    -- �ȉ��]��
            ELSIF (o_rep_cont_data_rec.condition_contents_8 IS NULL) THEN
              o_rep_cont_data_rec.condition_contents_8 := cv_cond_conts_space;    -- �ȉ��]��
            ELSIF (o_rep_cont_data_rec.condition_contents_9 IS NULL) THEN
              o_rep_cont_data_rec.condition_contents_9 := cv_cond_conts_space;    -- �ȉ��]��
            ELSIF (o_rep_cont_data_rec.condition_contents_10 IS NULL) THEN
              o_rep_cont_data_rec.condition_contents_10 := cv_cond_conts_space;   -- �ȉ��]��
            ELSIF (o_rep_cont_data_rec.condition_contents_11 IS NULL) THEN
              o_rep_cont_data_rec.condition_contents_11 := cv_cond_conts_space;   -- �ȉ��]��
            ELSIF (o_rep_cont_data_rec.condition_contents_12 IS NULL) THEN
              o_rep_cont_data_rec.condition_contents_12 := cv_cond_conts_space;   -- �ȉ��]��
            END IF;
          END IF;
        END IF;
      END IF;
--
      -- �̔��萔���L���̐ݒ�
        o_rep_cont_data_rec.condition_contents_flag := lb_bm1_bm;
      -- �ݒu���^���L��
      /* 2009.04.27 K.Satomura T1_0705�Ή� START */
      --IF (o_rep_cont_data_rec.install_support_amt IS NOT NULL) THEN
      IF ((o_rep_cont_data_rec.install_support_amt IS NOT NULL)
        AND (o_rep_cont_data_rec.install_support_amt <> 0))
      THEN
      /* 2009.04.27 K.Satomura T1_0705�Ή� END */
        o_rep_cont_data_rec.install_support_amt_flag := TRUE;
      -- �ݒu���^������
      ELSE
        o_rep_cont_data_rec.install_support_amt_flag := FALSE;
      END IF;
      -- �d�C����L��
      IF (o_rep_cont_data_rec.electricity_amount IS NOT NULL) THEN
        o_rep_cont_data_rec.electricity_information_flag := TRUE;
      -- �d�C���񖳂�
      ELSE
        o_rep_cont_data_rec.electricity_information_flag := FALSE;
      END IF;
--
    EXCEPTION
      -- ���o�Ɏ��s�����ꍇ�̌㏈��
      WHEN OTHERS THEN
        -- �J�[�\���E�N���[�Y
        IF (l_sales_charge_cur%ISOPEN) THEN
          CLOSE l_sales_charge_cur;
        END IF;
--
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_10             -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_tbl                   -- �g�[�N���R�[�h1
                       ,iv_token_value1 => cv_sp_decision_lines         -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_err_msg               -- �g�[�N���R�[�h2
                       ,iv_token_value2 => SQLERRM                      -- �g�[�N���l2
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
  EXCEPTION
--
    -- *** ������O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
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
  END get_contract_data;
--
  /**********************************************************************************
   * Procedure Name   : insert_data
   * Description      : ���[�N�e�[�u���ɓo�^(A-3)
   ***********************************************************************************/
  PROCEDURE insert_data(
     i_rep_cont_data_rec    IN         g_rep_cont_data_rtype  -- �_�񏑃f�[�^
    ,ov_errbuf              OUT NOCOPY VARCHAR2               -- �G���[�E���b�Z�[�W            --# �Œ� #
    ,ov_retcode             OUT NOCOPY VARCHAR2               -- ���^�[���E�R�[�h              --# �Œ� #
    ,ov_errmsg              OUT NOCOPY VARCHAR2               -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'insert_data';     -- �v���O������
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
    cv_tbl_nm            CONSTANT VARCHAR2(100) := '�����̔��@�ݒu�_�񏑒��[���[�N�e�[�u��';
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
    -- CSV�o�͏��� 
    -- ======================
    BEGIN
      -- ���[�N�e�[�u���ɓo�^
      INSERT INTO xxcso_rep_auto_sale_cont
        (  install_location                 -- �ݒu���P�[�V����
          ,contract_number                  -- �_�񏑔ԍ�
          ,contract_name                    -- �_��Җ�
          ,contract_period                  -- �_�����
          ,cancellation_offer_code          -- �_������\���o
          ,other_content                    -- ���񎖍�
          ,sales_charge_details_delivery    -- �萔�����׏����t�於
          ,delivery_address                 -- ���t��Z��
          ,install_name                     -- �ݒu�於
          ,install_address                  -- �ݒu��Z��
          ,install_date                     -- �ݒu��
          ,bank_name                        -- ���Z�@�֖�
          ,blanches_name                    -- �x�X��
          ,account_number                   -- �ڋq�R�[�h
          ,bank_account_number              -- �����ԍ�
          ,bank_account_name_kana           -- �������`�J�i
          ,publish_base_code                -- �S�����_
          ,publish_base_name                -- �S�����_��
          ,contract_effect_date             -- �_�񏑔�����
          ,issue_belonging_address          -- ���s�������Z��
          ,issue_belonging_name             -- ���s��������
          ,issue_belonging_boss_position    -- ���s���������E�ʖ�
          ,issue_belonging_boss             -- ���s����������
          ,close_day_code                   -- ����
          ,transfer_month_code              -- ������
          ,transfer_day_code                -- ������
          ,exchange_condition               -- �������
          ,condition_contents_1             -- �������e1
          ,condition_contents_2             -- �������e2
          ,condition_contents_3             -- �������e3
          ,condition_contents_4             -- �������e4
          ,condition_contents_5             -- �������e5
          ,condition_contents_6             -- �������e6
          ,condition_contents_7             -- �������e7
          ,condition_contents_8             -- �������e8
          ,condition_contents_9             -- �������e9
          ,condition_contents_10            -- �������e10
          ,condition_contents_11            -- �������e11
          ,condition_contents_12            -- �������e12
          ,install_support_amt              -- �ݒu���^��
          ,electricity_information          -- �d�C����
          ,transfer_commission_info         -- �U�荞�ݎ萔�����
          ,created_by                       -- �쐬��
          ,creation_date                    -- �쐬��
          ,last_updated_by                  -- �ŏI�X�V��
          ,last_update_date                 -- �ŏI�X�V��
          ,last_update_login                -- �ŏI�X�V���O�C��
          ,request_id                       -- �v��id
          ,program_application_id           -- �A�v���P�[�V����id
          ,program_id                       -- �v���O����id
          ,program_update_date              -- �v���O�����X�V��
        )
      VALUES
        (  i_rep_cont_data_rec.install_location                 -- �ݒu���P�[�V����
          ,i_rep_cont_data_rec.contract_number                  -- �_�񏑔ԍ�
          ,i_rep_cont_data_rec.contract_name                    -- �_��Җ�
          ,i_rep_cont_data_rec.contract_period                  -- �_�����
          ,i_rep_cont_data_rec.cancellation_offer_code          -- �_������\���o
          ,i_rep_cont_data_rec.other_content                    -- ���񎖍�
          ,i_rep_cont_data_rec.sales_charge_details_delivery    -- �萔�����׏����t�於
          ,i_rep_cont_data_rec.delivery_address                 -- ���t��Z��
          ,i_rep_cont_data_rec.install_name                     -- �ݒu�於
          ,i_rep_cont_data_rec.install_address                  -- �ݒu��Z��
          ,i_rep_cont_data_rec.install_date                     -- �ݒu��
          ,i_rep_cont_data_rec.bank_name                        -- ���Z�@�֖�
          ,i_rep_cont_data_rec.blanches_name                    -- �x�X��
          ,i_rep_cont_data_rec.account_number                   -- �ڋq�R�[�h
          ,i_rep_cont_data_rec.bank_account_number              -- �����ԍ�
          ,i_rep_cont_data_rec.bank_account_name_kana           -- �������`�J�i
          ,i_rep_cont_data_rec.publish_base_code                -- �S�����_
          ,i_rep_cont_data_rec.publish_base_name                -- �S�����_��
          ,i_rep_cont_data_rec.contract_effect_date             -- �_�񏑔�����
          ,i_rep_cont_data_rec.issue_belonging_address          -- ���s�������Z��
          ,i_rep_cont_data_rec.issue_belonging_name             -- ���s��������
          ,i_rep_cont_data_rec.issue_belonging_boss_position    -- ���s���������E�ʖ�
          ,i_rep_cont_data_rec.issue_belonging_boss             -- ���s����������
          ,i_rep_cont_data_rec.close_day_code                   -- ����
          ,i_rep_cont_data_rec.transfer_month_code              -- ������
          ,i_rep_cont_data_rec.transfer_day_code                -- ������
          ,i_rep_cont_data_rec.exchange_condition               -- �������
          ,i_rep_cont_data_rec.condition_contents_1             -- �������e1
          ,i_rep_cont_data_rec.condition_contents_2             -- �������e2
          ,i_rep_cont_data_rec.condition_contents_3             -- �������e3
          ,i_rep_cont_data_rec.condition_contents_4             -- �������e4
          ,i_rep_cont_data_rec.condition_contents_5             -- �������e5
          ,i_rep_cont_data_rec.condition_contents_6             -- �������e6
          ,i_rep_cont_data_rec.condition_contents_7             -- �������e7
          ,i_rep_cont_data_rec.condition_contents_8             -- �������e8
          ,i_rep_cont_data_rec.condition_contents_9             -- �������e9
          ,i_rep_cont_data_rec.condition_contents_10            -- �������e10
          ,i_rep_cont_data_rec.condition_contents_11            -- �������e11
          ,i_rep_cont_data_rec.condition_contents_12            -- �������e12
          ,i_rep_cont_data_rec.install_support_amt              -- �ݒu���^��
          ,i_rep_cont_data_rec.electricity_information          -- �d�C����
          ,i_rep_cont_data_rec.transfer_commission_info         -- �U�荞�ݎ萔�����
          ,cn_created_by                                        -- �쐬��
          ,cd_creation_date                                     -- �쐬��
          ,cn_last_updated_by                                   -- �ŏI�X�V��
          ,cd_last_update_date                                  -- �ŏI�X�V��
          ,cn_last_update_login                                 -- �ŏI�X�V���O�C��
          ,cn_request_id                                        -- �v���h�c
          ,cn_program_application_id                            -- �ݶ�����۸��ѱ��ع����
          ,cn_program_id                                        -- �ݶ�����۸��тh�c
          ,cd_program_update_date                               -- ��۸��эX�V��
        );
--
      -- ���O�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => '' || CHR(10) || '�_�񏑃f�[�^�����[�N�e�[�u���ɓo�^���܂����B'
      );
--
    EXCEPTION
      WHEN OTHERS THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_app_name                          --�A�v���P�[�V�����Z�k��
                 ,iv_name         => cv_tkn_number_07                     --���b�Z�[�W�R�[�h
                 ,iv_token_name1  => cv_tkn_tbl                           --�g�[�N���R�[�h1
                 ,iv_token_value1 => cv_tbl_nm                            --�g�[�N���l1
                 ,iv_token_name2  => cv_tkn_err_msg                       --�g�[�N���R�[�h2
                 ,iv_token_value2 => SQLERRM                              --�g�[�N���l2
                 ,iv_token_name3  => cv_tkn_contract_num                  --�g�[�N���R�[�h3
                 ,iv_token_value3 => i_rep_cont_data_rec.contract_number  --�g�[�N���l3
                 ,iv_token_name4  => cv_tkn_request_id                    --�g�[�N���R�[�h3
                 ,iv_token_value4 => cn_request_id                        --�g�[�N���l3
                );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
  EXCEPTION
--
    -- *** ������O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END insert_data;
--
  /**********************************************************************************
   * Procedure Name   : act_svf
   * Description      : SVF�N��(A-4)
   ***********************************************************************************/
  PROCEDURE act_svf(
     iv_svf_form_nm         IN  VARCHAR2                 -- �t�H�[���l���t�@�C����
    ,iv_svf_query_nm        IN  VARCHAR2                 -- �N�G���[�l���t�@�C����
    ,ov_errbuf              OUT NOCOPY VARCHAR2          -- �G���[�E���b�Z�[�W            --# �Œ� #
    ,ov_retcode             OUT NOCOPY VARCHAR2          -- ���^�[���E�R�[�h              --# �Œ� #
    ,ov_errmsg              OUT NOCOPY VARCHAR2          -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'act_svf';     -- �v���O������
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
    cv_tkn_api_nm_svf  CONSTANT  VARCHAR2(20) := 'SVF�N��';
    cv_output_mode    CONSTANT  VARCHAR2(1)   := '1';
    -- *** ���[�J���ϐ� ***
    lv_svf_file_name   VARCHAR2(50);
    lv_file_id         VARCHAR2(30)  := NULL;
    lv_conc_name       VARCHAR2(30)  := NULL;
    lv_user_name       VARCHAR2(240) := NULL;
    lv_resp_name       VARCHAR2(240) := NULL;
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
    -- SVF�N������ 
    -- ======================
    -- �t�@�C�����̐ݒ�
    lv_svf_file_name := cv_pkg_name
                       || TO_CHAR (cd_creation_date, 'YYYYMMDD')
                       || TO_CHAR (cn_request_id);
--
    BEGIN
      SELECT  user_concurrent_program_name,
              xx00_global_pkg.user_name   ,
              xx00_global_pkg.resp_name
      INTO    lv_conc_name,
              lv_user_name,
              lv_resp_name
      FROM    fnd_concurrent_programs_tl
      WHERE   concurrent_program_id =cn_request_id
      AND     LANGUAGE = 'JA'
      ;
    EXCEPTION
      WHEN OTHERS THEN
        lv_conc_name := cv_pkg_name;
    END;
--
    lv_file_id := cv_pkg_name;
--
    xxccp_svfcommon_pkg.submit_svf_request(
      ov_errbuf       => lv_errbuf             -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode      => lv_retcode            -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg       => lv_errmsg             -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
     ,iv_conc_name    => lv_conc_name          -- �R���J�����g��
     ,iv_file_name    => lv_svf_file_name      -- �o�̓t�@�C����
     ,iv_file_id      => lv_file_id            -- ���[ID
     ,iv_output_mode  => cv_output_mode        -- �o�͋敪(=1�FPDF�o�́j
     ,iv_frm_file     => iv_svf_form_nm        -- �t�H�[���l���t�@�C����
     ,iv_vrq_file     => iv_svf_query_nm       -- �N�G���[�l���t�@�C����
     ,iv_org_id       => fnd_global.org_id     -- ORG_ID
     ,iv_user_name    => lv_user_name          -- ���O�C���E���[�U��
     ,iv_resp_name    => lv_resp_name          -- ���O�C���E���[�U�̐E�Ӗ�
     ,iv_doc_name     => NULL                  -- ������
     ,iv_printer_name => NULL                  -- �v�����^��
     ,iv_request_id   => cn_request_id         -- �v��ID
     ,iv_nodata_msg   => NULL                  -- �f�[�^�Ȃ����b�Z�[�W
     );
--
    -- SVF�N��API�̌Ăяo���̓G���[��
    IF (lv_retcode <> cv_status_normal) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_app_name             --�A�v���P�[�V�����Z�k��
                 ,iv_name         => cv_tkn_number_06        --���b�Z�[�W�R�[�h
                 ,iv_token_name1  => cv_tkn_api_nm           --�g�[�N���R�[�h1
                 ,iv_token_value1 => cv_tkn_api_nm_svf       --�g�[�N���l1
                );
      lv_errbuf := lv_errmsg || SQLERRM;
      RAISE global_api_expt;
    END IF;
--
      -- ���O�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => '' || CHR(10) || '�����̔��@�ݒu�_��PDF���o�͂��܂����B'
      );
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
--
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END act_svf;
--
  /**********************************************************************************
   * Procedure Name   : delete_data
   * Description      : ���[�N�e�[�u���f�[�^�폜(A-5)
   ***********************************************************************************/
  PROCEDURE delete_data(
     i_rep_cont_data_rec    IN         g_rep_cont_data_rtype  -- �_�񏑃f�[�^
    ,ov_errbuf              OUT NOCOPY VARCHAR2               -- �G���[�E���b�Z�[�W            --# �Œ� #
    ,ov_retcode             OUT NOCOPY VARCHAR2               -- ���^�[���E�R�[�h              --# �Œ� #
    ,ov_errmsg              OUT NOCOPY VARCHAR2               -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'delete_data';     -- �v���O������
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
    cv_tbl_nm         CONSTANT VARCHAR2(100) := '�����̔��@�ݒu�_�񏑒��[���[�N�e�[�u��';
    -- *** ���[�J���ϐ� ***
    lt_con_mng_id         xxcso_contract_managements.contract_management_id%TYPE;      -- �����̔��@�ݒu�_��ID
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ==========================
    -- ���b�N�̊m�F
    -- ==========================
    BEGIN
--
      SELECT xrasc.request_id  request_id
      INTO   lt_con_mng_id
      FROM   xxcso_rep_auto_sale_cont xrasc         -- �����̔��@�ݒu�_�񏑒��[���[�N�e�[�u��
      WHERE  xrasc.request_id = cn_request_id
        AND  ROWNUM = 1
      FOR UPDATE NOWAIT;
--
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_app_name             --�A�v���P�[�V�����Z�k��
                   ,iv_name         => cv_tkn_number_11        --���b�Z�[�W�R�[�h
                   ,iv_token_name1  => cv_tkn_tbl              --�g�[�N���R�[�h1
                   ,iv_token_value1 => cv_tbl_nm               --�g�[�N���l1
                   ,iv_token_name2  => cv_tkn_err_msg          --�g�[�N���R�[�h2
                   ,iv_token_value2 => SQLERRM                 --�g�[�N���l2
                  );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
    -- ==========================
    -- ���[�N�e�[�u���f�[�^�폜
    -- ==========================
    BEGIN
--
      DELETE FROM xxcso_rep_auto_sale_cont xrasc -- �����̔��@�ݒu�_�񏑒��[���[�N�e�[�u��
      WHERE xrasc.request_id = cn_request_id;
--
      -- ���O�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => '' || CHR(10) || '���[�N�e�[�u���̌_�񏑃f�[�^���폜���܂����B'
      );
--
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_app_name                          --�A�v���P�[�V�����Z�k��
                   ,iv_name         => cv_tkn_number_08                     --���b�Z�[�W�R�[�h
                   ,iv_token_name1  => cv_tkn_tbl                           --�g�[�N���R�[�h1
                   ,iv_token_value1 => cv_tbl_nm                            --�g�[�N���l1
                   ,iv_token_name2  => cv_tkn_err_msg                       --�g�[�N���R�[�h2
                   ,iv_token_value2 => SQLERRM                              --�g�[�N���l2
                   ,iv_token_name3  => cv_tkn_contract_num                  --�g�[�N���R�[�h3
                   ,iv_token_value3 => i_rep_cont_data_rec.contract_number  --�g�[�N���l3
                   ,iv_token_name4  => cv_tkn_request_id                    --�g�[�N���R�[�h3
                   ,iv_token_value4 => cn_request_id                        --�g�[�N���l3
                  );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
  EXCEPTION
--
    -- *** ������O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END delete_data;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   ***********************************************************************************/
  PROCEDURE submain(
     ov_errbuf           OUT NOCOPY VARCHAR2   -- �G���[�E���b�Z�[�W            --# �Œ� #
    ,ov_retcode          OUT NOCOPY VARCHAR2   -- ���^�[���E�R�[�h              --# �Œ� #
    ,ov_errmsg           OUT NOCOPY VARCHAR2   -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'submain';     -- �v���O������
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
    cv_status_0           CONSTANT VARCHAR2(1) := '0';  -- �쐬��
    cv_status_1           CONSTANT VARCHAR2(1) := '1';  -- �m���
    cv_cooperate_flag_0   CONSTANT VARCHAR2(1) := '0';  -- ���A�g
    cv_cooperate_flag_1   CONSTANT VARCHAR2(1) := '1';  -- �A�g��
--
    -- *** ���[�J���ϐ� ***
    lv_process_flag       VARCHAR2(1);                                     -- �����t���O
    lt_status             xxcso_contract_managements.status%TYPE;          -- �X�e�[�^�X
    lt_cooperate_flag     xxcso_contract_managements.cooperate_flag%TYPE;  -- �}�X�^�A�g�t���O
    lv_svf_form_nm        VARCHAR2(20);                                    -- �t�H�[���l���t�@�C����
    lv_svf_query_nm       VARCHAR2(20);                                    -- �N�G���[�l���t�@�C����
    -- SVF�N��API�߂�l�i�[�p
    lv_errbuf_svf         VARCHAR2(5000);                                  -- �G���[�E���b�Z�[�W
    lv_retcode_svf        VARCHAR2(1);                                     -- ���^�[���E�R�[�h
    lv_errmsg_svf         VARCHAR2(5000);                                  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
    -- *** ���[�J���E���R�[�h ***
    l_rep_cont_data_rec   g_rep_cont_data_rtype;
--
    -- *** ���[�J����O ***
    init_expt   EXCEPTION;  -- ����������O
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- �J�E���^�̏�����
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
--
    -- ========================================
    -- A-1.��������
    -- ========================================
    init(
      ot_status         => lt_status           -- �X�e�[�^�X
     ,ot_cooperate_flag => lt_cooperate_flag   -- �}�X�^�A�g�t���O
     ,ov_errbuf         => lv_errbuf           -- �G���[�E���b�Z�[�W            --# �Œ� #
     ,ov_retcode        => lv_retcode          -- ���^�[���E�R�[�h              --# �Œ� #
     ,ov_errmsg         => lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE init_expt;
    END IF;
    -- �������������̏ꍇ�A�Ώی����J�E���g
    gn_target_cnt := gn_target_cnt + 1;
--
    -- ==============================================================================================
    -- �����t���O = 1 �X�e�[�^�X���쐬���̏ꍇ�A�܂��̓X�e�[�^�X���m��ρA���}�X�^�A�g�t���O�����A�g�̏ꍇ
    -- �����t���O = 2 �X�e�[�^�X���X�e�[�^�X���m��ρA���}�X�^�A�g�t���O���A�g�ς̏ꍇ
    --===============================================================================================
    IF ((lt_status = cv_status_0)
        OR ((lt_status = cv_status_1) AND (lt_cooperate_flag = cv_cooperate_flag_0))) THEN
      lv_process_flag := cv_flag_1;
    ELSIF ((lt_status = cv_status_1) AND (lt_cooperate_flag = cv_cooperate_flag_1)) THEN
      lv_process_flag := cv_flag_2;
    END IF;
--
    -- ========================================
    -- A-2.�f�[�^�擾
    -- ========================================
    get_contract_data(
      iv_process_flag     => lv_process_flag      -- �����t���O
     ,o_rep_cont_data_rec => l_rep_cont_data_rec  -- �_�񏑃f�[�^
     ,ov_errbuf           => lv_errbuf            -- �G���[�E���b�Z�[�W            --# �Œ� #
     ,ov_retcode          => lv_retcode           -- ���^�[���E�R�[�h              --# �Œ� #
     ,ov_errmsg           => lv_errmsg            -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ========================================
    -- A-3.���[�N�e�[�u���ɓo�^
    -- ========================================
    insert_data(
      i_rep_cont_data_rec    => l_rep_cont_data_rec    -- �_�񏑃f�[�^
     ,ov_errbuf              => lv_errbuf              -- �G���[�E���b�Z�[�W            --# �Œ� #
     ,ov_retcode             => lv_retcode             -- ���^�[���E�R�[�h              --# �Œ� #
     ,ov_errmsg              => lv_errmsg              -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ==============================================================================================
    -- �t�H�[���l���t�@�C�����A�N�G���[�l���t�@�C����
    -- ���[�o�̓p�^�[���i�W��ށj
    --===============================================================================================
--
    -- ���O�o��
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => '' || CHR(10) || '<< ���[�o�̓p�^�[�� >>'
    );
--
    -- �@ �̔��萔���L��A���ݒu���^���L��A���d�C��L��̏ꍇ
    IF ((l_rep_cont_data_rec.condition_contents_flag = TRUE)
          AND (l_rep_cont_data_rec.install_support_amt_flag = TRUE)
          AND (l_rep_cont_data_rec.electricity_information_flag = TRUE)) THEN
      -- �t�H�[���l���t�@�C����
      lv_svf_form_nm  := cv_svf_name || 'S01.xml';
      -- �N�G���[�l���t�@�C����
      lv_svf_query_nm := cv_svf_name || 'S01.vrq';
--
      -- ���O�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => '�@ �̔��萔���L��A���ݒu���^���L��A���d�C��L��'
      );
--
    -- �A �̔��萔���L��A���ݒu���^���L��A���d�C�㖳���̏ꍇ
    ELSIF ((l_rep_cont_data_rec.condition_contents_flag = TRUE)
          AND (l_rep_cont_data_rec.install_support_amt_flag = TRUE)
          AND (l_rep_cont_data_rec.electricity_information_flag = FALSE)) THEN
      -- �t�H�[���l���t�@�C����
      lv_svf_form_nm  := cv_svf_name || 'S02.xml';
      -- �N�G���[�l���t�@�C����
      lv_svf_query_nm := cv_svf_name || 'S02.vrq';
--
      -- ���O�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => '�A �̔��萔���L��A���ݒu���^���L��A���d�C�㖳��'
      );
--
    -- �B �̔��萔���L��A���ݒu���^�������A���d�C��L��̏ꍇ
    ELSIF ((l_rep_cont_data_rec.condition_contents_flag = TRUE)
          AND (l_rep_cont_data_rec.install_support_amt_flag = FALSE)
          AND (l_rep_cont_data_rec.electricity_information_flag = TRUE)) THEN
      -- �t�H�[���l���t�@�C����
      lv_svf_form_nm  := cv_svf_name || 'S03.xml';
      -- �N�G���[�l���t�@�C����
      lv_svf_query_nm := cv_svf_name || 'S03.vrq';
--
      -- ���O�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => '�B �̔��萔���L��A���ݒu���^�������A���d�C��L��'
      );
--
    -- �C �̔��萔���L��A���ݒu���^�������A���d�C�㖳���̏ꍇ
    ELSIF ((l_rep_cont_data_rec.condition_contents_flag = TRUE)
          AND (l_rep_cont_data_rec.install_support_amt_flag = FALSE)
          AND (l_rep_cont_data_rec.electricity_information_flag = FALSE)) THEN
      -- �t�H�[���l���t�@�C����
      lv_svf_form_nm  := cv_svf_name || 'S04.xml';
      -- �N�G���[�l���t�@�C����
      lv_svf_query_nm := cv_svf_name || 'S04.vrq';
--
      -- ���O�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => '�C �̔��萔���L��A���ݒu���^�������A���d�C�㖳��'
      );
--
    -- �D �̔��萔�������A���ݒu���^���L��A���d�C��L��̏ꍇ
    ELSIF ((l_rep_cont_data_rec.condition_contents_flag = FALSE)
          AND (l_rep_cont_data_rec.install_support_amt_flag = TRUE)
          AND (l_rep_cont_data_rec.electricity_information_flag = TRUE)) THEN
      -- �t�H�[���l���t�@�C����
      lv_svf_form_nm  := cv_svf_name || 'S05.xml';
      -- �N�G���[�l���t�@�C����
      lv_svf_query_nm := cv_svf_name || 'S05.vrq';
--
      -- ���O�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => '�D �̔��萔�������A���ݒu���^���L��A���d�C��L��'
      );
--
    -- �E �̔��萔�������A���ݒu���^���L��A���d�C�㖳���̏ꍇ
    ELSIF ((l_rep_cont_data_rec.condition_contents_flag = FALSE)
          AND (l_rep_cont_data_rec.install_support_amt_flag = TRUE)
          AND (l_rep_cont_data_rec.electricity_information_flag = FALSE)) THEN
      -- �t�H�[���l���t�@�C����
      lv_svf_form_nm  := cv_svf_name || 'S06.xml';
      -- �N�G���[�l���t�@�C����
      lv_svf_query_nm := cv_svf_name || 'S06.vrq';
--
      -- ���O�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => '�E �̔��萔�������A���ݒu���^���L��A���d�C�㖳��'
      );
--
    -- �F �̔��萔�������A���ݒu���^�������A���d�C��L��̏ꍇ
    ELSIF ((l_rep_cont_data_rec.condition_contents_flag = FALSE)
          AND (l_rep_cont_data_rec.install_support_amt_flag = FALSE)
          AND (l_rep_cont_data_rec.electricity_information_flag = TRUE)) THEN
      -- �t�H�[���l���t�@�C����
      lv_svf_form_nm  := cv_svf_name || 'S07.xml';
      -- �N�G���[�l���t�@�C����
      lv_svf_query_nm := cv_svf_name || 'S07.vrq';
--
      -- ���O�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => '�F �̔��萔�������A���ݒu���^�������A���d�C��L��'
      );
--
    -- �G �̔��萔�������A���ݒu���^�������A���d�C�㖳���̏ꍇ
    ELSIF ((l_rep_cont_data_rec.condition_contents_flag = FALSE)
          AND (l_rep_cont_data_rec.install_support_amt_flag = FALSE)
          AND (l_rep_cont_data_rec.electricity_information_flag = FALSE)) THEN
      -- �t�H�[���l���t�@�C����
      lv_svf_form_nm  := cv_svf_name || 'S08.xml';
      -- �N�G���[�l���t�@�C����
      lv_svf_query_nm := cv_svf_name || 'S08.vrq';
--
      -- ���O�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => '�G �̔��萔�������A���ݒu���^�������A���d�C�㖳��'
      );
--
    END IF;
--
    -- ���O�o��
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => '�t�H�[���l���F' || lv_svf_form_nm || '�A�N�G���[�l���F' || lv_svf_query_nm
    );
--

    -- ========================================
    -- A-4.SVF�N��
    -- ========================================
    act_svf(
       iv_svf_form_nm  => lv_svf_form_nm
      ,iv_svf_query_nm => lv_svf_query_nm
      ,ov_errbuf       => lv_errbuf_svf                 -- �G���[�E���b�Z�[�W            --# �Œ� #
      ,ov_retcode      => lv_retcode_svf                -- ���^�[���E�R�[�h              --# �Œ� #
      ,ov_errmsg       => lv_errmsg_svf                 -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
    );
--
    -- ========================================
    -- A-5.���[�N�e�[�u���f�[�^�폜
    -- ========================================
    delete_data(
       i_rep_cont_data_rec  => l_rep_cont_data_rec      -- �_�񏑃f�[�^
      ,ov_errbuf            => lv_errbuf                -- �G���[�E���b�Z�[�W            --# �Œ� #
      ,ov_retcode           => lv_retcode               -- ���^�[���E�R�[�h              --# �Œ� #
      ,ov_errmsg            => lv_errmsg                -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ========================================
    -- A-6.SVF�N��API�G���[�`�F�b�N
    -- ========================================
    IF (lv_retcode_svf = cv_status_error) THEN
      lv_errmsg := lv_errmsg_svf;
      lv_errbuf := lv_errbuf_svf;
      RAISE global_process_expt;
    END IF;

--
    -- ���������J�E���g
    gn_normal_cnt := gn_normal_cnt + 1;
--
  EXCEPTION
    -- *** ����������O�n���h�� ***
    WHEN init_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
    -- *** ��������O�n���h�� ***
    WHEN global_process_expt THEN
      -- �G���[�����J�E���g
      gn_error_cnt := gn_error_cnt + 1;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      -- �G���[�����J�E���g
      gn_error_cnt := gn_error_cnt + 1;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM||lv_errbuf;
      ov_retcode := cv_status_error;
--
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      -- �G���[�����J�E���g
      gn_error_cnt := gn_error_cnt + 1;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
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
     errbuf               OUT NOCOPY VARCHAR2    -- �G���[�E���b�Z�[�W  --# �Œ� #
    ,retcode              OUT NOCOPY VARCHAR2    -- ���^�[���E�R�[�h    --# �Œ� #
    ,in_contract_mng_id   IN         NUMBER      -- �����̔��@�ݒu�_��ID
  )
--
-- ###########################  �Œ蕔 START   ###########################
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
-- ###########################  �Œ蕔 START   #####################################################
--
    -- �Œ�o��
    -- �R���J�����g�w�b�_���b�Z�[�W�o�͊֐��̌Ăяo��
    xxccp_common_pkg.put_log_header(
       ov_retcode => lv_retcode
      ,ov_errbuf  => lv_errbuf
      ,ov_errmsg  => lv_errmsg
    );
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_api_others_expt;
    END IF;
    --
-- ###########################  �Œ蕔 END   #############################
--
    -- *** ���̓p�����[�^���Z�b�g(�����̔��@�ݒu�_��ID)
    gt_con_mng_id := in_contract_mng_id;
--
    -- ===============================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ===============================================
    submain(
       ov_errbuf   => lv_errbuf          -- �G���[�E���b�Z�[�W            -- # �Œ� #
      ,ov_retcode  => lv_retcode         -- ���^�[���E�R�[�h              -- # �Œ� #
      ,ov_errmsg   => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W  -- # �Œ� #
    );
--
    IF (lv_retcode = cv_status_error) THEN
       --�G���[�o��
--       fnd_file.put_line(
--          which  => FND_FILE.LOG
--         ,buff   => '' || CHR(10) ||lv_errmsg                  -- ���[�U�[�E�G���[���b�Z�[�W
--       );
       fnd_file.put_line(
          which  => FND_FILE.LOG
         ,buff   => '' || CHR(10)
                   ||cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf    -- �G���[���b�Z�[�W
       );
    END IF;
--
    -- =======================
    -- A-7.�I������ 
    -- =======================
    -- ��s�̏o��
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => ''               -- ��s
    );
    -- �Ώی����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_target_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)
                  );
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
--
    -- ���������o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_success_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_normal_cnt)
                  );
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
--
    -- �G���[�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_error_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_error_cnt)
                  );
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
--
    -- �I�����b�Z�[�W
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
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
--
    -- �X�e�[�^�X�Z�b�g
    retcode := lv_retcode;
    -- �I���X�e�[�^�X���G���[�̏ꍇ��ROLLBACK����
    IF (retcode = cv_status_error) THEN
      ROLLBACK;
    END IF;
--
  EXCEPTION
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM||lv_errbuf;
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
END XXCSO010A04C;
/
