CREATE OR REPLACE PACKAGE BODY XXCFF003A03C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCFF003A03C(body)
 * Description      : ���[�X��ޔ���
 * MD.050           : MD050_CFF_003_A03_���[�X��ޔ���
 * Version          : 1.2
 *
 * Program List
 * ------------------------- ---- ----- --------------------------------------------------
 *  Name                     Type  Ret   Description
 * ------------------------- ---- ----- --------------------------------------------------
 *  check_in_param            P          ���͍��ڃ`�F�b�N����         (A-1)
 *  judge_lease_type          F    VAR   ���[�X�敪���菈��           (A-2)
 *  calc_discount_rate        P          ���݉��l�������Z�菈��       (A-3)
 *  calc_present_value_re     F    NUM   �ă��[�X���݉��l�Z�菈��     (A-9)
 *  calc_debt_lease           P          ���[�X���z�Z�菈��         (A-8)
 *  calc_present_value        F    NUM   ���݉��l�Z�菈��             (A-4)
 *  judge_lease_kind          F    VAR   ���[�X��ޔ��菈��           (A-5)
 *  calc_original_cost        F    NUM   �擾���z�Z�菈��             (A-6)
 *  calc_interested_rate      P          �v�Z���q���Z�菈��           (A-7)
 *  main                      P          �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008-12-04    1.0   SCS ���q �G�K    �V�K�쐬
 *  2016-08-10    1.1   SCSK �m�� �d�l   [E_�{�ғ�_13658]���̋@�ϗp�N���ύX�Ή�
 *  2016-10-26    1.2   SCSK�s           E_�{�ғ�_13658 ���̋@�ϗp�N���ύX�Ή��E�t�F�[�Y3
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
--
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
  cv_pkg_name        CONSTANT VARCHAR2(100) := 'XXCFF003A03C';  -- �p�b�P�[�W��
  cv_app_kbn_cff     CONSTANT VARCHAR2(5)   := 'XXCFF';         -- �A�v���P�[�V�����Z�k��
--
  -- ���b�Z�[�W�ԍ�
  cv_msg_cff_00005   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-00005';  -- �K�{�`�F�b�N�G���[
  cv_msg_cff_00059   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-00059';  -- ���[�X�敪�G���[
  cv_msg_cff_00088   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-00088';  -- �v�Z�G���[
  cv_msg_cff_00089   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-00089';  -- �������擾�G���[
  cv_msg_cff_00109   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-00109';  -- ���������ݒ�G���[
--
  -- �g�[�N��
  cv_tk_cff_00005_01 CONSTANT VARCHAR2(15) := 'INPUT';    -- �����͍��ږ�
--
  -- �g�[�N���l
  cv_msg_cff_50032   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-50032';  -- �@��ϗp�N��
  cv_msg_cff_50033   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-50033';  -- �x����
  cv_msg_cff_50108   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-50108';  -- ���񌎊z���[�X��
  cv_msg_cff_50109   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-50109';  -- �Q��ڈȍ~���z���[�X��
  cv_msg_cff_50110   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-50110';  -- ���ό����w�����z
  cv_msg_cff_50111   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-50111';  -- �_��N��
-- Ver.1.1 ADD Start
  cv_msg_cff_50041   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-50041';  -- ���[�X���
-- Ver.1.1 ADD End
--
  -- ���[�X�敪
  cv_lease_type_1    CONSTANT VARCHAR2(1)  := '1';        -- 1:���_��
  cv_lease_type_2    CONSTANT VARCHAR2(1)  := '2';        -- 2:�ă��[�X�_��
--
  -- ���[�X���
  cv_lease_kind_0    CONSTANT VARCHAR2(1)  := '0';        -- 0:Fin
  cv_lease_kind_1    CONSTANT VARCHAR2(1)  := '1';        -- 1:Op
  cv_lease_kind_2    CONSTANT VARCHAR2(1)  := '2';        -- 2:��Fin
--
  -- �v�Z���q��
  cn_calc_rate_max   CONSTANT NUMBER       := 0.5;        -- �v�Z���q��MAX�l:50%
  cn_calc_rate_min   CONSTANT NUMBER       := 0.0000001;  -- �v�Z���q��MIN�l:0.00001%
--
-- Ver.1.1 ADD Start
  -- ���[�X���
  cv_lease_class_11  CONSTANT VARCHAR2(2)  := '11';       -- 11:�����̔��@
  -- �ă��[�X���x����
  cn_first_freq      CONSTANT NUMBER       := 61;         -- �ă��[�X�P���
  cn_second_freq     CONSTANT NUMBER       := 73;         -- �ă��[�X�Q���
  cn_third_freq      CONSTANT NUMBER       := 85;         -- �ă��[�X�R���
-- Ver.1.1 ADD End
-- 2016/10/26 Ver.1.2 Y.Koh ADD Start
  cd_start_date      CONSTANT DATE := TO_DATE('2016/05/01','YYYY/MM/DD');
-- 2016/10/26 Ver.1.2 Y.Koh ADD End
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
--
  /**********************************************************************************
   * Procedure Name   : check_in_param
   * Description      : ���͍��ڃ`�F�b�N���� (A-1)
   ***********************************************************************************/
  PROCEDURE check_in_param(
    in_lease_type           IN  VARCHAR2,    -- 1.���[�X�敪
    in_payment_frequency    IN  NUMBER,      -- 2.�x����
    in_first_charge         IN  NUMBER,      -- 3.���񌎊z���[�X��
    in_second_charge        IN  NUMBER,      -- 4.�Q��ڈȍ~���z���[�X��
    in_estimated_cash_price IN  NUMBER,      -- 5.���ό����w�����z
    in_life_in_months       IN  NUMBER,      -- 6.�@��ϗp�N��
    id_contract_ym          IN  DATE,        -- 7.�_��N��
-- Ver.1.1 ADD Start
    iv_lease_class          IN  VARCHAR2,    -- 8.���[�X���
-- Ver.1.1 ADD End
    ov_errbuf               OUT VARCHAR2,    -- �G���[�E���b�Z�[�W
    ov_retcode              OUT VARCHAR2,    -- ���^�[���E�R�[�h
    ov_errmsg               OUT VARCHAR2     -- ���[�U�[�E�G���[�E���b�Z�[�W
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name CONSTANT VARCHAR2(100) := 'check_in_param';  -- �v���O������
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
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ���͍��ڃ`�F�b�N
    -- 1.���[�X�敪
    IF ( (in_lease_type IS NULL)
      OR (in_lease_type NOT IN(cv_lease_type_1, cv_lease_type_2) ) )
    THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application => cv_app_kbn_cff,   -- �A�v���P�[�V�����Z�k��
                     iv_name        => cv_msg_cff_00059  -- ���b�Z�[�W�R�[�h
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- 2.�x����
    IF (in_payment_frequency IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_kbn_cff,      -- �A�v���P�[�V�����Z�k��
                     iv_name         => cv_msg_cff_00005,    -- ���b�Z�[�W�R�[�h
                     iv_token_name1  => cv_tk_cff_00005_01,  -- �g�[�N���R�[�h1
                     iv_token_value1 => cv_msg_cff_50033     -- �g�[�N���l1
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- 3.���񌎊z���[�X��
    IF ( (in_first_charge IS NULL) OR (in_first_charge <= 0) ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_kbn_cff,      -- �A�v���P�[�V�����Z�k��
                     iv_name         => cv_msg_cff_00005,    -- ���b�Z�[�W�R�[�h
                     iv_token_name1  => cv_tk_cff_00005_01,  -- �g�[�N���R�[�h1
                     iv_token_value1 => cv_msg_cff_50108     -- �g�[�N���l1
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- 4.�Q��ڈȍ~���z���[�X��
    IF ( (in_second_charge IS NULL) OR (in_second_charge <= 0) ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_kbn_cff,      -- �A�v���P�[�V�����Z�k��
                     iv_name         => cv_msg_cff_00005,    -- ���b�Z�[�W�R�[�h
                     iv_token_name1  => cv_tk_cff_00005_01,  -- �g�[�N���R�[�h1
                     iv_token_value1 => cv_msg_cff_50109     -- �g�[�N���l1
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- 5.���ό����w�����z
    IF ( (in_estimated_cash_price IS NULL) OR (in_estimated_cash_price <= 0) ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_kbn_cff,      -- �A�v���P�[�V�����Z�k��
                     iv_name         => cv_msg_cff_00005,    -- ���b�Z�[�W�R�[�h
                     iv_token_name1  => cv_tk_cff_00005_01,  -- �g�[�N���R�[�h1
                     iv_token_value1 => cv_msg_cff_50110     -- �g�[�N���l1
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- 6.�@��ϗp�N��
    IF ( (in_life_in_months IS NULL) OR (in_life_in_months <= 0) ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_kbn_cff,      -- �A�v���P�[�V�����Z�k��
                     iv_name         => cv_msg_cff_00005,    -- ���b�Z�[�W�R�[�h
                     iv_token_name1  => cv_tk_cff_00005_01,  -- �g�[�N���R�[�h1
                     iv_token_value1 => cv_msg_cff_50032     -- �g�[�N���l1
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- 7.�_��N��
    IF (id_contract_ym IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_kbn_cff,      -- �A�v���P�[�V�����Z�k��
                     iv_name         => cv_msg_cff_00005,    -- ���b�Z�[�W�R�[�h
                     iv_token_name1  => cv_tk_cff_00005_01,  -- �g�[�N���R�[�h1
                     iv_token_value1 => cv_msg_cff_50111     -- �g�[�N���l1
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
-- Ver.1.1 ADD Start
    -- 8.���[�X���
    IF (iv_lease_class IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_kbn_cff,      -- �A�v���P�[�V�����Z�k��
                     iv_name         => cv_msg_cff_00005,    -- ���b�Z�[�W�R�[�h
                     iv_token_name1  => cv_tk_cff_00005_01,  -- �g�[�N���R�[�h1
                     iv_token_value1 => cv_msg_cff_50041     -- �g�[�N���l1
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
-- Ver.1.1 ADD End
--
  EXCEPTION
    -- *** ���������ʗ�O�n���h�� ***
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
  END check_in_param;
--
  /**********************************************************************************
   * Function Name    : judge_lease_type
   * Description      : ���[�X�敪���菈�� (A-2)
   ***********************************************************************************/
  FUNCTION judge_lease_type(
    in_lease_type IN VARCHAR2)    -- 1.���[�X�敪
  RETURN VARCHAR2                 -- ���[�X��� '1'(Op)/NULL
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'judge_lease_type';  -- �v���O������
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lv_lease_kind VARCHAR2(1);  -- ���[�X���
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
    lv_lease_kind := NULL;
--
    -- ���[�X�敪����
    -- ���[�X�敪��'2'(�ă��[�X)�̏ꍇ�A���[�X��ނɁuOp�v��ݒ�
    IF (in_lease_type = cv_lease_type_2) THEN
      lv_lease_kind := cv_lease_kind_1;
    END IF;
--
    RETURN lv_lease_kind;
--
  EXCEPTION
--
--###############################  �Œ��O������ START   ###################################
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,2000),TRUE);
--
--###################################  �Œ蕔 END   #########################################
--
  END judge_lease_type;
  /**********************************************************************************
   * Procedure Name   : calc_discount_rate
   * Description      : ���݉��l�������Z�菈�� (A-3)
   ***********************************************************************************/
  PROCEDURE calc_discount_rate(
    in_payment_frequency           IN  NUMBER,      -- 1.�x����
    id_contract_ym                 IN  DATE,        -- 2.�_��N��
    on_present_value_discount_rate OUT NUMBER,      -- 3.���݉��l������
    ov_errbuf                      OUT VARCHAR2,    -- �G���[�E���b�Z�[�W
    ov_retcode                     OUT VARCHAR2,    -- ���^�[���E�R�[�h
    ov_errmsg                      OUT VARCHAR2     -- ���[�U�[�E�G���[�E���b�Z�[�W
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name CONSTANT VARCHAR2(100) := 'calc_discount_rate';  -- �v���O������
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
    ln_payment_years NUMBER;  -- �x���񐔂���Z�肷��N��
    ln_discount_rate NUMBER;  -- ������
--
    -- *** ���[�J���E�J�[�\�� ***
    CURSOR get_discount_rate_rec_cur(
      p_application_date DATE)
    IS
      SELECT xdrm.discount_rate_01 discount_rate_01,
             xdrm.discount_rate_02 discount_rate_02,
             xdrm.discount_rate_03 discount_rate_03,
             xdrm.discount_rate_04 discount_rate_04,
             xdrm.discount_rate_05 discount_rate_05,
             xdrm.discount_rate_06 discount_rate_06,
             xdrm.discount_rate_07 discount_rate_07,
             xdrm.discount_rate_08 discount_rate_08,
             xdrm.discount_rate_09 discount_rate_09,
             xdrm.discount_rate_10 discount_rate_10,
             xdrm.discount_rate_11 discount_rate_11,
             xdrm.discount_rate_12 discount_rate_12,
             xdrm.discount_rate_13 discount_rate_13,
             xdrm.discount_rate_14 discount_rate_14,
             xdrm.discount_rate_15 discount_rate_15,
             xdrm.discount_rate_16 discount_rate_16,
             xdrm.discount_rate_17 discount_rate_17,
             xdrm.discount_rate_18 discount_rate_18,
             xdrm.discount_rate_19 discount_rate_19,
             xdrm.discount_rate_20 discount_rate_20,
             xdrm.discount_rate_21 discount_rate_21,
             xdrm.discount_rate_22 discount_rate_22,
             xdrm.discount_rate_23 discount_rate_23,
             xdrm.discount_rate_24 discount_rate_24,
             xdrm.discount_rate_25 discount_rate_25,
             xdrm.discount_rate_26 discount_rate_26,
             xdrm.discount_rate_27 discount_rate_27,
             xdrm.discount_rate_28 discount_rate_28,
             xdrm.discount_rate_29 discount_rate_29,
             xdrm.discount_rate_30 discount_rate_30,
             xdrm.discount_rate_31 discount_rate_31,
             xdrm.discount_rate_32 discount_rate_32,
             xdrm.discount_rate_33 discount_rate_33,
             xdrm.discount_rate_34 discount_rate_34,
             xdrm.discount_rate_35 discount_rate_35,
             xdrm.discount_rate_36 discount_rate_36,
             xdrm.discount_rate_37 discount_rate_37,
             xdrm.discount_rate_38 discount_rate_38,
             xdrm.discount_rate_39 discount_rate_39,
             xdrm.discount_rate_40 discount_rate_40,
             xdrm.discount_rate_41 discount_rate_41,
             xdrm.discount_rate_42 discount_rate_42,
             xdrm.discount_rate_43 discount_rate_43,
             xdrm.discount_rate_44 discount_rate_44,
             xdrm.discount_rate_45 discount_rate_45,
             xdrm.discount_rate_46 discount_rate_46,
             xdrm.discount_rate_47 discount_rate_47,
             xdrm.discount_rate_48 discount_rate_48,
             xdrm.discount_rate_49 discount_rate_49,
             xdrm.discount_rate_50 discount_rate_50
      FROM   xxcff_discount_rate_mst xdrm
      WHERE  xdrm.application_date = p_application_date;
    lt_discount_rate_rec get_discount_rate_rec_cur%ROWTYPE;
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
    ln_discount_rate := NULL;
--
    -- �x���񐔂���N�����Z��
    ln_payment_years := in_payment_frequency / 12;
--
    -- �������}�X�^����
    OPEN  get_discount_rate_rec_cur(id_contract_ym);
    FETCH get_discount_rate_rec_cur INTO lt_discount_rate_rec;
--
    -- ���R�[�h�����݂��Ȃ��ꍇ�A�G���[
    IF (get_discount_rate_rec_cur%NOTFOUND) THEN
      CLOSE get_discount_rate_rec_cur;
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_kbn_cff,        -- �A�v���P�[�V�����Z�k��
                     iv_name         => cv_msg_cff_00089       -- ���b�Z�[�W�R�[�h
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
    CLOSE get_discount_rate_rec_cur;
--
    -- �K�p�N���ɊY�����銄�������擾
    CASE ln_payment_years
      WHEN  1 THEN ln_discount_rate := lt_discount_rate_rec.discount_rate_01;
      WHEN  2 THEN ln_discount_rate := lt_discount_rate_rec.discount_rate_02;
      WHEN  3 THEN ln_discount_rate := lt_discount_rate_rec.discount_rate_03;
      WHEN  4 THEN ln_discount_rate := lt_discount_rate_rec.discount_rate_04;
      WHEN  5 THEN ln_discount_rate := lt_discount_rate_rec.discount_rate_05;
      WHEN  6 THEN ln_discount_rate := lt_discount_rate_rec.discount_rate_06;
      WHEN  7 THEN ln_discount_rate := lt_discount_rate_rec.discount_rate_07;
      WHEN  8 THEN ln_discount_rate := lt_discount_rate_rec.discount_rate_08;
      WHEN  9 THEN ln_discount_rate := lt_discount_rate_rec.discount_rate_09;
      WHEN 10 THEN ln_discount_rate := lt_discount_rate_rec.discount_rate_10;
      WHEN 11 THEN ln_discount_rate := lt_discount_rate_rec.discount_rate_11;
      WHEN 12 THEN ln_discount_rate := lt_discount_rate_rec.discount_rate_12;
      WHEN 13 THEN ln_discount_rate := lt_discount_rate_rec.discount_rate_13;
      WHEN 14 THEN ln_discount_rate := lt_discount_rate_rec.discount_rate_14;
      WHEN 15 THEN ln_discount_rate := lt_discount_rate_rec.discount_rate_15;
      WHEN 16 THEN ln_discount_rate := lt_discount_rate_rec.discount_rate_16;
      WHEN 17 THEN ln_discount_rate := lt_discount_rate_rec.discount_rate_17;
      WHEN 18 THEN ln_discount_rate := lt_discount_rate_rec.discount_rate_18;
      WHEN 19 THEN ln_discount_rate := lt_discount_rate_rec.discount_rate_19;
      WHEN 20 THEN ln_discount_rate := lt_discount_rate_rec.discount_rate_20;
      WHEN 21 THEN ln_discount_rate := lt_discount_rate_rec.discount_rate_21;
      WHEN 22 THEN ln_discount_rate := lt_discount_rate_rec.discount_rate_22;
      WHEN 23 THEN ln_discount_rate := lt_discount_rate_rec.discount_rate_23;
      WHEN 24 THEN ln_discount_rate := lt_discount_rate_rec.discount_rate_24;
      WHEN 25 THEN ln_discount_rate := lt_discount_rate_rec.discount_rate_25;
      WHEN 26 THEN ln_discount_rate := lt_discount_rate_rec.discount_rate_26;
      WHEN 27 THEN ln_discount_rate := lt_discount_rate_rec.discount_rate_27;
      WHEN 28 THEN ln_discount_rate := lt_discount_rate_rec.discount_rate_28;
      WHEN 29 THEN ln_discount_rate := lt_discount_rate_rec.discount_rate_29;
      WHEN 30 THEN ln_discount_rate := lt_discount_rate_rec.discount_rate_30;
      WHEN 31 THEN ln_discount_rate := lt_discount_rate_rec.discount_rate_31;
      WHEN 32 THEN ln_discount_rate := lt_discount_rate_rec.discount_rate_32;
      WHEN 33 THEN ln_discount_rate := lt_discount_rate_rec.discount_rate_33;
      WHEN 34 THEN ln_discount_rate := lt_discount_rate_rec.discount_rate_34;
      WHEN 35 THEN ln_discount_rate := lt_discount_rate_rec.discount_rate_35;
      WHEN 36 THEN ln_discount_rate := lt_discount_rate_rec.discount_rate_36;
      WHEN 37 THEN ln_discount_rate := lt_discount_rate_rec.discount_rate_37;
      WHEN 38 THEN ln_discount_rate := lt_discount_rate_rec.discount_rate_38;
      WHEN 39 THEN ln_discount_rate := lt_discount_rate_rec.discount_rate_39;
      WHEN 40 THEN ln_discount_rate := lt_discount_rate_rec.discount_rate_40;
      WHEN 41 THEN ln_discount_rate := lt_discount_rate_rec.discount_rate_41;
      WHEN 42 THEN ln_discount_rate := lt_discount_rate_rec.discount_rate_42;
      WHEN 43 THEN ln_discount_rate := lt_discount_rate_rec.discount_rate_43;
      WHEN 44 THEN ln_discount_rate := lt_discount_rate_rec.discount_rate_44;
      WHEN 45 THEN ln_discount_rate := lt_discount_rate_rec.discount_rate_45;
      WHEN 46 THEN ln_discount_rate := lt_discount_rate_rec.discount_rate_46;
      WHEN 47 THEN ln_discount_rate := lt_discount_rate_rec.discount_rate_47;
      WHEN 48 THEN ln_discount_rate := lt_discount_rate_rec.discount_rate_48;
      WHEN 49 THEN ln_discount_rate := lt_discount_rate_rec.discount_rate_49;
      WHEN 50 THEN ln_discount_rate := lt_discount_rate_rec.discount_rate_50;
      ELSE NULL;
    END CASE;
--
    -- �����������ݒ�̏ꍇ�A�G���[
    IF (ln_discount_rate IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_kbn_cff,        -- �A�v���P�[�V�����Z�k��
                     iv_name         => cv_msg_cff_00109       -- ���b�Z�[�W�R�[�h
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    on_present_value_discount_rate := ln_discount_rate / 100;
--
  EXCEPTION
    -- *** ���������ʗ�O�n���h�� ***
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
      IF (get_discount_rate_rec_cur%ISOPEN) THEN
        CLOSE get_discount_rate_rec_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END calc_discount_rate;
-- Ver.1.1 ADD Start
  /**********************************************************************************
   * Function Name    : calc_present_value_re
   * Description      : �ă��[�X���݉��l�Z�菈�� (A-9)
   ***********************************************************************************/
  FUNCTION calc_present_value_re(
    in_second_charge               IN  NUMBER,      -- 1.�Q��ڈȍ~���z���[�X��
    in_calc_rate                   IN  NUMBER       -- 2.�v�Z��
  )
  RETURN NUMBER                                     -- �ă��[�X���݉��l
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'calc_present_value_re';  -- �v���O������
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    ln_first_charge_re  NUMBER;  -- �ă��[�X�P��ڃ��[�X��
    ln_second_charge_re NUMBER;  -- �ă��[�X�Q��ڃ��[�X��
    ln_third_charge_re  NUMBER;  -- �ă��[�X�R��ڃ��[�X��
    ln_re_lease_value   NUMBER;  -- �ă��[�X���̌��݉��l
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
    -- ������
    ln_re_lease_value := 0 ;
--
    -- �ă��[�X���̃��[�X�����Z�o
    ln_first_charge_re  := in_second_charge;                       -- �ă��[�X�P��ڃ��[�X��
    ln_second_charge_re := TRUNC( in_second_charge * 12 / 14 );    -- �ă��[�X�Q��ڃ��[�X��
    ln_third_charge_re  := TRUNC( in_second_charge * 12 / 18 );    -- �ă��[�X�R��ڃ��[�X��
--
    -- �ă��[�X���̌��݉��l���Z�o
    ln_re_lease_value   := TRUNC( ln_first_charge_re  / POWER( (1 + in_calc_rate), cn_first_freq  ) )
                        +  TRUNC( ln_second_charge_re / POWER( (1 + in_calc_rate), cn_second_freq ) )
                        +  TRUNC( ln_third_charge_re  / POWER( (1 + in_calc_rate), cn_third_freq  ) )
    ;
--
    RETURN ln_re_lease_value;
--
  EXCEPTION
--
--###############################  �Œ��O������ START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,2000),TRUE);
--
--###################################  �Œ蕔 END   #########################################
--
  END calc_present_value_re;
--
  /**********************************************************************************
   * Procedure Name   : calc_debt_lease
   * Description      : ���[�X���z�Z�菈�� (A-8)
   ***********************************************************************************/
  PROCEDURE calc_debt_lease(
    in_estimated_cash_price   IN  NUMBER,      -- 1.���ό����w�����z
    in_present_value          IN  NUMBER,      -- 2.���݉��l�����z
-- 2016/10/26 Ver.1.2 Y.Koh ADD Start
    id_contract_ym            IN  DATE,        -- �_��N��
-- 2016/10/26 Ver.1.2 Y.Koh ADD End
    iv_lease_class            IN  VARCHAR2,    -- 3.���[�X���
    in_second_charge          IN  NUMBER,      -- 4.�Q��ڈȍ~���z���[�X��
    in_calc_interested_rate   IN  NUMBER,      -- 5.�v�Z���q��
    on_original_cost_type1    OUT NUMBER,      -- 6.���[�X���z_���_��
    on_original_cost_type2    OUT NUMBER,      -- 7.���[�X���z_�ă��[�X
    ov_errbuf                 OUT VARCHAR2,    -- �G���[�E���b�Z�[�W
    ov_retcode                OUT VARCHAR2,    -- ���^�[���E�R�[�h
    ov_errmsg                 OUT VARCHAR2     -- ���[�U�[�E�G���[�E���b�Z�[�W
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name CONSTANT VARCHAR2(100) := 'calc_debt_lease';  -- �v���O������
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
    ln_original_cost    NUMBER;  -- �擾���z
    ln_re_lease_value   NUMBER;  -- �ă��[�X���̌��݉��l
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
    -- ���[�J���ϐ�������
--
    -- ���[�X��ʂ��u�����̔��@�v�ȊO�̏ꍇ�͏����X�L�b�v
-- 2016/10/26 Ver.1.2 Y.Koh MOD Start
--    IF ( iv_lease_class <> cv_lease_class_11 ) THEN
    IF ( iv_lease_class <> cv_lease_class_11 OR id_contract_ym < cd_start_date ) THEN
-- 2016/10/26 Ver.1.2 Y.Koh MOD End
      -- ���[�X���z_���_��
      on_original_cost_type1 := 0;
      -- ���[�X���z_�ă��[�X
      on_original_cost_type2 := 0;
      RETURN;
    END IF;
--
    -- ���݉��l�ƌ��ό����w�����z���r���A�Ⴂ�����擾���z�ɐݒ�
    IF (in_present_value <= in_estimated_cash_price) THEN
      ln_original_cost := in_present_value;
    ELSE
      ln_original_cost := in_estimated_cash_price;
    END IF;
--
    --========================================
    --  �ă��[�X���݉��l�Z�菈�� (A-9)
    --========================================
    ln_re_lease_value  := calc_present_value_re(
                            in_second_charge,                -- �Q��ڈȍ~���z���[�X��
                            in_calc_interested_rate / 12     -- �v�Z���q��
                          );
--
    -- ���[�X���z_���_��
    on_original_cost_type1 := ln_original_cost - ln_re_lease_value;
    -- ���[�X���z_�ă��[�X
    on_original_cost_type2 := ln_re_lease_value;
--
  EXCEPTION
    -- *** ���������ʗ�O�n���h�� ***
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
  END calc_debt_lease;
-- Ver.1.1 ADD End
  /**********************************************************************************
   * Function Name    : calc_present_value
   * Description      : ���݉��l�Z�菈�� (A-4)
   ***********************************************************************************/
  FUNCTION calc_present_value(
    in_payment_frequency           IN  NUMBER,      -- 1.�x����
    in_first_charge                IN  NUMBER,      -- 2.���񌎊z���[�X��
    in_second_charge               IN  NUMBER,      -- 3.�Q��ڈȍ~���z���[�X��
-- Ver.1.1 MOD Start
--    in_present_value_discount_rate IN  NUMBER)      -- 4.���݉��l������
    in_present_value_discount_rate IN  NUMBER,      -- 4.���݉��l������
-- 2016/10/26 Ver.1.2 Y.Koh ADD Start
    id_contract_ym                 IN  DATE,        -- �_��N��
-- 2016/10/26 Ver.1.2 Y.Koh ADD End
    iv_lease_class                 IN  VARCHAR2     -- 5.���[�X���
  )
-- Ver.1.1 MOD End
  RETURN NUMBER                                     -- ���݉��l
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'calc_present_value';  -- �v���O������
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    ln_present_value   NUMBER;  -- ���݉��l
    ln_second_value    NUMBER;  -- �Q��ڈȍ~���݉��l
-- Ver.1.1 ADD Start
    ln_re_lease_value  NUMBER;  -- �ă��[�X���̌��݉��l
-- Ver.1.1 ADD End
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
    -- ���񌎊z���[�X���������ݒ�
    ln_present_value  := in_first_charge;
-- Ver.1.1 ADD Start
    ln_re_lease_value := 0 ;
-- Ver.1.1 ADD End
--
    -- �Q��ڈȍ~���z���[�X�����x���񐔕����Z
    <<present_value_calc_loop>>
    FOR i IN 2..in_payment_frequency LOOP
      -- �Q��ڈȍ~���z���[�X�����x����ɉ��������݉��l�Ɋ��Z
      ln_second_value := in_second_charge / POWER( (1 + in_present_value_discount_rate / 12), (i - 1) );
      -- ��L�Ŋ��Z�����l�����݉��l�ɉ��Z
      ln_present_value := ln_present_value + ln_second_value;
    END LOOP present_value_calc_loop;
-- Ver.1.1 ADD Start
    -- ���[�X��ʂ��u�����̔��@�v�̏ꍇ�A�ă��[�X���̌��݉��l���Z��
-- 2016/10/26 Ver.1.2 Y.Koh MOD Start
--    IF ( iv_lease_class = cv_lease_class_11 ) THEN
    IF ( iv_lease_class = cv_lease_class_11 AND id_contract_ym >= cd_start_date ) THEN
-- 2016/10/26 Ver.1.2 Y.Koh MOD End
      --========================================
      --  �ă��[�X���݉��l�Z�菈�� (A-9)
      --========================================
      ln_re_lease_value  := calc_present_value_re(
                              in_second_charge,                    -- �Q��ڈȍ~���z���[�X��
                              in_present_value_discount_rate / 12  -- ���݉��l������
                            );
    END IF;
--
    -- �ă��[�X���̌��݉��l�����Z
    ln_present_value := ln_present_value + ln_re_lease_value;
-- Ver.1.1 ADD End
--
    RETURN ROUND(ln_present_value, 0);
--
  EXCEPTION
--
--###############################  �Œ��O������ START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,2000),TRUE);
--
--###################################  �Œ蕔 END   #########################################
--
  END calc_present_value;
  /**********************************************************************************
   * Function Name    : judge_lease_kind
   * Description      : ���[�X��ޔ��菈�� (A-5)
   ***********************************************************************************/
  FUNCTION judge_lease_kind(
    in_payment_frequency    IN NUMBER,    -- 1.�x����
    in_estimated_cash_price IN NUMBER,    -- 2.���ό����w�����z
    in_life_in_months       IN NUMBER,    -- 3.�@��ϗp�N��
    in_present_value        IN NUMBER)    -- 4.���݉��l
  RETURN VARCHAR2                         -- ���[�X��� '0'(Fin)/'1'(Op)
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'judge_lease_kind';  -- �v���O������
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lv_lease_kind VARCHAR2(1);  -- ���[�X���
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
    -- ���݉��l�����ό����w�����z��90%�ȏ�ł���ꍇ�A�܂���
    -- �x����(���[�X����)���@��ϗp�N����75%�ȏ�ł���ꍇ�A���[�X��ނɁuFin�v��ݒ�
    IF ( (in_present_value >= in_estimated_cash_price * 0.9)
      OR (in_payment_frequency >= in_life_in_months * 12 * 0.75) )
    THEN
      lv_lease_kind := cv_lease_kind_0;
    -- ����ȊO�̏ꍇ�A���[�X��ނɁuOp�v��ݒ�
    ELSE
      lv_lease_kind := cv_lease_kind_1;
    END IF;
--
    RETURN lv_lease_kind;
--
  EXCEPTION
--
--###############################  �Œ��O������ START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,2000),TRUE);
--
--###################################  �Œ蕔 END   #########################################
--
  END judge_lease_kind;
  /**********************************************************************************
   * Function Name    : calc_original_cost
   * Description      : �擾���z�Z�菈�� (A-6)
   ***********************************************************************************/
  FUNCTION calc_original_cost(
    in_estimated_cash_price IN NUMBER,    -- 1.���ό����w�����z
    in_present_value        IN NUMBER)    -- 2.���݉��l
  RETURN NUMBER                           -- �擾���z
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'calc_original_cost';  -- �v���O������
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    ln_original_cost NUMBER;  -- �擾���z
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
    -- ���݉��l�ƌ��ό����w�����z���r���A�Ⴂ�����擾���z�ɐݒ�
    IF (in_present_value <= in_estimated_cash_price) THEN
      ln_original_cost := in_present_value;
    ELSE
      ln_original_cost := in_estimated_cash_price;
    END IF;
--
    RETURN ln_original_cost;
--
  EXCEPTION
--
--###############################  �Œ��O������ START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,2000),TRUE);
--
--###################################  �Œ蕔 END   #########################################
--
  END calc_original_cost;
  /**********************************************************************************
   * Procedure Name   : calc_interested_rate
   * Description      : �v�Z���q���Z�菈�� (A-7)
   ***********************************************************************************/
  PROCEDURE calc_interested_rate(
    in_payment_frequency    IN  NUMBER,      -- 1.�x����
    in_first_charge         IN  NUMBER,      -- 2.���񌎊z���[�X��
    in_second_charge        IN  NUMBER,      -- 3.�Q��ڈȍ~���z���[�X��
    in_original_cost        IN  NUMBER,      -- 4.�擾���z
-- 2016/10/26 Ver.1.2 Y.Koh ADD Start
    id_contract_ym          IN  DATE,        -- �_��N��
-- 2016/10/26 Ver.1.2 Y.Koh ADD End
-- Ver.1.1 ADD Start
    iv_lease_class          IN  VARCHAR2,    -- 5.���[�X���
-- Ver.1.1 ADD End
    on_calc_interested_rate OUT NUMBER,      -- 6.�v�Z���q��
    ov_errbuf               OUT VARCHAR2,    -- �G���[�E���b�Z�[�W
    ov_retcode              OUT VARCHAR2,    -- ���^�[���E�R�[�h
    ov_errmsg               OUT VARCHAR2     -- ���[�U�[�E�G���[�E���b�Z�[�W
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name CONSTANT VARCHAR2(100) := 'calc_interested_rate';  -- �v���O������
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
    cn_a NUMBER := in_first_charge;       -- ���񌎊z���[�X��
    cn_b NUMBER := in_second_charge;      -- �Q��ڈȍ~���z���[�X��
    cn_n NUMBER := in_payment_frequency;  -- �x����
--
    -- *** ���[�J���ϐ� ***
    ln_calc_interested_rate NUMBER;       -- �v�Z���q��
    ln_latest_rate          NUMBER;       -- �v�Z���q���Z�o���̑ޔ�p
    ln_latest_over_rate     NUMBER;       -- ���߂Ŏx���z > �擾���z�ƂȂ����v�Z���q��
    ln_r                    NUMBER;       -- �v�Z��R�l(1/(1+�v�Z���q��))
    ln_i                    NUMBER;       -- �x���z
-- Ver.1.1 ADD Start
    ln_i_re                 NUMBER;       -- �x���z(�ă��[�X��)
-- Ver.1.1 ADD End
    ln_decrement            NUMBER;       -- �����l
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
    -- ���[�J���ϐ�������
    ln_calc_interested_rate := cn_calc_rate_max;  -- �v�Z���q���ɍő�l��ݒ�
    ln_latest_over_rate     := cn_calc_rate_min;  -- �v�Z���q�����ŏ��l�����̏ꍇ�A�ŏ��l�Ƃ���
    ln_decrement            := 0.1;               -- �ŏ��̗L�����͏����_�ȉ���P��
-- Ver.1.1 ADD Start
    ln_i_re                 := 0;                 -- �x���z(�ă��[�X��)
-- Ver.1.1 ADD End
--
    --========================================
    -- �v�Z���q�����ő�l�̏ꍇ�̎x���z�Z�o
    --========================================
    -- �v�Z��R�l�̎Z�o
    ln_r := 1 / (1 + ln_calc_interested_rate);
--
    -- �v�Z���ɂ��x���z���Z�o
    ln_i := cn_a * ln_r + (cn_b * POWER(ln_r, 2) - cn_b * POWER(ln_r, (cn_n + 1) ) ) / (1 - ln_r);
-- Ver.1.1 ADD Start
    -- ���[�X��ʂ��u�����̔��@�v�̏ꍇ�A�ă��[�X���̎x���z���Z��
-- 2016/10/26 Ver.1.2 Y.Koh MOD Start
--    IF ( iv_lease_class = cv_lease_class_11 ) THEN
    IF ( iv_lease_class = cv_lease_class_11 AND id_contract_ym >= cd_start_date ) THEN
-- 2016/10/26 Ver.1.2 Y.Koh MOD End
      --========================================
      --  �ă��[�X���݉��l�Z�菈�� (A-9)
      --========================================
      ln_i_re := calc_present_value_re(
                   in_second_charge,             -- �Q��ڈȍ~���z���[�X��
                   ln_calc_interested_rate       -- �v�Z���q��
                 );
    END IF;
--
    -- �ă��[�X���̎x���z�����Z
    ln_i := ln_i + ln_i_re;
-- Ver.1.1 ADD End
--
    -- ��L�x���z���擾���z���傫���ꍇ�A�G���[
    IF (ln_i > in_original_cost) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_kbn_cff,        -- �A�v���P�[�V�����Z�k��
                     iv_name         => cv_msg_cff_00088       -- ���b�Z�[�W�R�[�h
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    --========================================
    -- �x���z���擾���z�ƈ�v�A�܂��͋ߎ��l�ƂȂ鎞�̌v�Z���q���Z�o
    --========================================
    <<interested_rate_calc_loop>>
    LOOP
      -- �x���z �� �擾���z�̏ꍇ�A�v�Z���q����ϐ��ɑޔ����A�L�����ɉ����ĂP��������
      IF (ln_i < in_original_cost) THEN
        ln_latest_rate := ln_calc_interested_rate;
        ln_calc_interested_rate := ln_calc_interested_rate - ln_decrement;
        -- �L������0�ƂȂ�ꍇ�͗L�������P�E�V�t�g���ĂP��������
        IF (MOD(ln_calc_interested_rate, ln_decrement * 10) = 0) THEN
          ln_decrement := ln_decrement * 0.1;
          -- �L�����������_�ȉ��V������������ꍇ�A���߂Ŏx���z > �擾���z�ƂȂ����v�Z���q����
          -- �ݒ肵�A���[�v�𔲂���
          IF (ln_decrement < cn_calc_rate_min) THEN
            ln_calc_interested_rate := ln_latest_over_rate;
            EXIT interested_rate_calc_loop;
          END IF;
          ln_calc_interested_rate := ln_latest_rate - ln_decrement;
        END IF;
      -- �x���z �� �擾���z�̏ꍇ�A�v�Z���q����ϐ��ɑޔ����A�ޔ������v�Z���q������L������
      -- �P�E�V�t�g���ĂP��������
      ELSIF (ln_i > in_original_cost) THEN
        ln_latest_over_rate := ln_calc_interested_rate;
        ln_decrement := ln_decrement * 0.1;
        -- �����Ώی��������_�ȉ��V������������ꍇ�A���[�v�𔲂���
        IF (ln_decrement < cn_calc_rate_min) THEN
          EXIT interested_rate_calc_loop;
        END IF;
        ln_calc_interested_rate := ln_latest_rate - ln_decrement;
      -- �x���z �� �擾���z�̏ꍇ�A���[�v�𔲂���
      ELSE
        EXIT interested_rate_calc_loop;
      END IF;
--
      -- �v�Z��R�l�̎Z�o
      ln_r := 1 / (1 + ln_calc_interested_rate);
--
      -- �v�Z���ɂ��x���z���Z�o
      ln_i := cn_a * ln_r + (cn_b * POWER(ln_r, 2) - cn_b * POWER(ln_r, (cn_n + 1) ) ) / (1 - ln_r);
-- Ver.1.1 ADD Start
      -- ���[�X��ʂ��u�����̔��@�v�̏ꍇ�A�ă��[�X���̎x���z���Z��
-- 2016/10/26 Ver.1.2 Y.Koh MOD Start
--      IF ( iv_lease_class = cv_lease_class_11 ) THEN
      IF ( iv_lease_class = cv_lease_class_11 AND id_contract_ym >= cd_start_date ) THEN
-- 2016/10/26 Ver.1.2 Y.Koh MOD End
        --========================================
        --  �ă��[�X���݉��l�Z�菈�� (A-9)
        --========================================
        ln_i_re := calc_present_value_re(
                     in_second_charge,             -- �Q��ڈȍ~���z���[�X��
                     ln_calc_interested_rate       -- �v�Z���q��
                   );
      END IF;
--
      -- �ă��[�X���̎x���z�����Z
      ln_i := ln_i + ln_i_re;
-- Ver.1.1 ADD End
--
    END LOOP interested_rate_calc_loop;
--
    -- �Z�o�����v�Z���q����N���ɕϊ����A�A�E�g�p�����[�^�ɐݒ�
    on_calc_interested_rate := ln_calc_interested_rate * 12;
--
  EXCEPTION
    -- *** ���������ʗ�O�n���h�� ***
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
  END calc_interested_rate;
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : �R���J�����g���s�t�@�C���o�^�v���V�[�W��
   ***********************************************************************************/
  PROCEDURE main(
    iv_lease_type                  IN  VARCHAR2,    -- 1.���[�X�敪
    in_payment_frequency           IN  NUMBER,      -- 2.�x����
    in_first_charge                IN  NUMBER,      -- 3.���񌎊z���[�X��
    in_second_charge               IN  NUMBER,      -- 4.�Q��ڈȍ~���z���[�X��
    in_estimated_cash_price        IN  NUMBER,      -- 5.���ό����w�����z
    in_life_in_months              IN  NUMBER,      -- 6.�@��ϗp�N��
    id_contract_ym                 IN  DATE,        -- 7.�_��N��
-- Ver.1.1 ADD Start
    iv_lease_class                 IN  VARCHAR2,    -- 8.���[�X���
-- Ver.1.1 ADD End
    ov_lease_kind                  OUT VARCHAR2,    -- 9.���[�X���
    on_present_value_discount_rate OUT NUMBER,      -- 10.���݉��l������
    on_present_value               OUT NUMBER,      -- 11.���݉��l
    on_original_cost               OUT NUMBER,      -- 12.�擾���z
    on_calc_interested_rate        OUT NUMBER,      -- 13.�v�Z���q��
-- Ver.1.1 ADD Start
    on_original_cost_type1         OUT NUMBER,      -- 14.���[�X���z_���_��
    on_original_cost_type2         OUT NUMBER,      -- 15.���[�X���z_�ă��[�X
-- Ver.1.1 ADD End
    ov_errbuf                      OUT VARCHAR2,    -- �G���[�E���b�Z�[�W
    ov_retcode                     OUT VARCHAR2,    -- ���^�[���E�R�[�h
    ov_errmsg                      OUT VARCHAR2     -- ���[�U�[�E�G���[�E���b�Z�[�W
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name CONSTANT VARCHAR2(100) := 'main';  -- �v���O������
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
    lv_lease_kind                  VARCHAR2(1);  -- ���[�X���
    ln_present_value_discount_rate NUMBER;       -- ���݉��l������
    ln_present_value               NUMBER;       -- ���݉��l
    ln_original_cost               NUMBER;       -- �擾���z
    ln_calc_interested_rate        NUMBER;       -- �v�Z���q��
-- Ver.1.1 ADD Start
    ln_original_cost_type1         NUMBER;       -- ���[�X���z_���_��
    ln_original_cost_type2         NUMBER;       -- ���[�X���z_�ă��[�X
-- Ver.1.1 ADD End
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
    -- =====================================================
    --  ���͍��ڃ`�F�b�N���� (A-1)
    -- =====================================================
    check_in_param(
      iv_lease_type,            -- ���[�X�敪
      in_payment_frequency,     -- �x����
      in_first_charge,          -- ���񌎊z���[�X��
      in_second_charge,         -- �Q��ڈȍ~���z���[�X��
      in_estimated_cash_price,  -- ���ό����w�����z
      in_life_in_months,        -- �@��ϗp�N��
      id_contract_ym,           -- �_��N��
-- Ver.1.1 ADD Start
      iv_lease_class,           -- ���[�X���
-- Ver.1.1 ADD End
      lv_errbuf,                -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,               -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);               -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- =====================================================
    --  ���[�X�敪���菈�� (A-2)
    -- =====================================================
    lv_lease_kind := judge_lease_type(
                       iv_lease_type);  -- ���[�X�敪
    -- ���[�X��ނ�'1'(Op)�̏ꍇ�͏����I��
    IF (lv_lease_kind = cv_lease_kind_1) THEN
      ov_lease_kind                  := lv_lease_kind;
      on_present_value_discount_rate := 0;
      on_present_value               := 0;
      on_original_cost               := 0;
      on_calc_interested_rate        := 0;
-- Ver.1.1 ADD Start
      on_original_cost_type1         := 0;   -- ���[�X���z_���_��
      on_original_cost_type2         := 0;   -- ���[�X���z_�ă��[�X
-- Ver.1.1 ADD End
      RETURN;
    END IF;
--
    -- =====================================================
    --  ���݉��l�������Z�菈�� (A-3)
    -- =====================================================
    calc_discount_rate(
      in_payment_frequency,            -- �x����
      id_contract_ym,                  -- �_��N��
      ln_present_value_discount_rate,  -- ���݉��l������
      lv_errbuf,                       -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,                      -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);                      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- =====================================================
    --  ���݉��l�Z�菈�� (A-4)
    -- =====================================================
    ln_present_value := calc_present_value(
                          in_payment_frequency,             -- �x����
                          in_first_charge,                  -- ���񌎊z���[�X��
                          in_second_charge,                 -- �Q��ڈȍ~���z���[�X��
-- Ver.1.1 MOD Start
--                          ln_present_value_discount_rate);  -- ���݉��l������
                          ln_present_value_discount_rate,   -- ���݉��l������
-- 2016/10/26 Ver.1.2 Y.Koh ADD Start
                          id_contract_ym,                   -- �_��N��
-- 2016/10/26 Ver.1.2 Y.Koh ADD End
                          iv_lease_class                    -- ���[�X���
                        );
-- Ver.1.1 MOD End
--
    -- =====================================================
    --  ���[�X��ޔ��菈�� (A-5)
    -- =====================================================
    lv_lease_kind := judge_lease_kind(
                       in_payment_frequency,     -- �x����
                       in_estimated_cash_price,  -- ���ό����w�����z
                       in_life_in_months,        -- �@��ϗp�N��
                       ln_present_value);        -- ���݉��l
--
    -- =====================================================
    --  �擾���z�Z�菈�� (A-6)
    -- =====================================================
    ln_original_cost := calc_original_cost(
                          in_estimated_cash_price,  -- ���ό����w�����z
                          ln_present_value);        -- ���݉��l
--
    -- =====================================================
    --  �v�Z���q���Z�菈�� (A-7)
    -- =====================================================
    calc_interested_rate(
      in_payment_frequency,     -- �x����
      in_first_charge,          -- ���񌎊z���[�X��
      in_second_charge,         -- �Q��ڈȍ~���z���[�X��
      ln_original_cost,         -- �擾���z
-- 2016/10/26 Ver.1.2 Y.Koh ADD Start
      id_contract_ym,           -- �_��N��
-- 2016/10/26 Ver.1.2 Y.Koh ADD End
-- Ver.1.1 ADD Start
      iv_lease_class,           -- ���[�X���
-- Ver.1.1 ADD End
      ln_calc_interested_rate,  -- �v�Z���q��
      lv_errbuf,                -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,               -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);               -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
-- Ver.1.1 ADD Start
    -- =====================================================
    --  ���[�X���z�Z�菈�� (A-8)
    -- =====================================================
    calc_debt_lease(
      in_estimated_cash_price,  -- ���ό����w�����z
      ln_present_value,         -- ���݉��l�����z
-- 2016/10/26 Ver.1.2 Y.Koh ADD Start
      id_contract_ym,           -- �_��N��
-- 2016/10/26 Ver.1.2 Y.Koh ADD End
      iv_lease_class,           -- ���[�X���
      in_second_charge,         -- �Q��ڈȍ~���z���[�X��
      ln_calc_interested_rate,  -- �v�Z���q��
      ln_original_cost_type1,   -- ���[�X���z_���_��
      ln_original_cost_type2,   -- ���[�X���z_�ă��[�X
      lv_errbuf,                -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,               -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg                 -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
-- Ver.1.1 ADD End
--
    -- ����I�����̖߂�l�ݒ�
    ov_lease_kind                  := lv_lease_kind;
    on_present_value_discount_rate := ln_present_value_discount_rate;
    on_present_value               := ln_present_value;
    on_original_cost               := ln_original_cost;
    on_calc_interested_rate        := ln_calc_interested_rate;
-- Ver.1.1 ADD Start
    on_original_cost_type1         := ln_original_cost_type1;          -- ���[�X���z_���_��
    on_original_cost_type2         := ln_original_cost_type2;          -- ���[�X���z_�ă��[�X
-- Ver.1.1 ADD End
--
  EXCEPTION
    -- *** ���������ʗ�O�n���h�� ***
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
  END main;
--
END XXCFF003A03C
;
/
