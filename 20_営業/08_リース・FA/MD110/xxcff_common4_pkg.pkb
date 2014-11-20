create or replace PACKAGE BODY XXCFF_COMMON4_PKG
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : xxcff_common4_pkg(body)
 * Description      : ���[�X�_��֘A���ʊ֐�
 * MD.050           : �Ȃ�
 * Version          : 1.1
 *
 * Program List
 * --------------------      ---- ----- --------------------------------------------------
 *  Name                     Type  Ret   Description
 * --------------------      ---- ----- --------------------------------------------------
 *  insert_co_hed             P           ���[�X�_��o�^�֐�
 *  insert_co_lin             P           ���[�X�_�񖾍דo�^�֐�
 *  insert_co_his             P           ���[�X�_�񗚗�o�^�֐�
 *  update_co_hed             P           ���[�X�_��X�V�֐�
 *  update_co_lin             P           ���[�X�_�񖾍׍X�V�֐�
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008-11-19    1.0   SCS�E��S��      �V�K�쐬
 *  2013-06-26    1.1   SCSK����O��     [E_�{�ғ�_10871]����ő��őΉ�
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
  --
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name        CONSTANT VARCHAR2(100) := 'xxcff_common4_pkg'; -- �p�b�P�[�W��
  cv_app_kbn_cff     CONSTANT VARCHAR2(5)   := 'XXCFF';
  --
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
--
  /**********************************************************************************
   * Function Name    : insert_co_hed
   * Description      : ���[�X�_��o�^
   ***********************************************************************************/
  PROCEDURE insert_co_hed(
    io_contract_data_rec   IN OUT NOCOPY cont_hed_data_rtype  -- �_����
   ,ov_errbuf              OUT NOCOPY VARCHAR2                -- �G���[�E���b�Z�[�W
   ,ov_retcode             OUT NOCOPY VARCHAR2                -- ���^�[���E�R�[�h
   ,ov_errmsg              OUT NOCOPY VARCHAR2                -- ���[�U�[�E�G���[�E���b�Z�[�W
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name     CONSTANT VARCHAR2(100) := 'insert_co_hed';   -- �v���O������
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf       VARCHAR2(5000) := NULL;              -- �G���[�E���b�Z�[�W
    lv_retcode      VARCHAR2(1)    := cv_status_normal;  -- ���^�[���E�R�[�h
    lv_errmsg       VARCHAR2(5000) := NULL;              -- ���[�U�[�E�G���[�E���b�Z�[�W
    --
    -- ===============================
    -- ���[�J���e�[�u���^
    -- ===============================
    --
    -- ===============================
    -- ���[�J���e�[�u���^�ϐ�
    -- ===============================
    --
    --
  BEGIN
  --
    -- ������
    ov_errbuf  := NULL;
    ov_retcode := cv_status_normal;
    ov_errmsg  := NULL;
    --
    -- ***************************************************
    -- 1.�V�[�P���X�̎擾
    -- ***************************************************
    --
    SELECT    xxcff_contract_headers_s1.NEXTVAL
    INTO      io_contract_data_rec.contract_header_id
    FROM      dual
    ;
    --
    -- ***************************************************
    -- 2.���[�X�_��o�^
    -- ***************************************************
    --
    INSERT INTO xxcff_contract_headers(
       contract_header_id         -- �_�����ID
     , contract_number            -- �_��ԍ�
     , lease_class                -- ���[�X���
     , lease_type                 -- ���[�X�敪
     , lease_company              -- ���[�X���
     , re_lease_times             -- �ă��[�X��
     , comments                   -- ����
     , contract_date              -- ���[�X�_���
     , payment_frequency          -- �x����
     , payment_type               -- �p�x
     , payment_years              -- �N�x
     , lease_start_date           -- ���[�X�J�n��
     , lease_end_date             -- ���[�X�I����
     , first_payment_date         -- ����x����
     , second_payment_date        -- �Q��ڎx����
     , third_payment_date         -- �R��ڈȍ~�x����
     , start_period_name          -- ��p�v���v��v����   
     , lease_payment_flag         -- �x���v�抮���t���O
     , tax_code                   -- �ŋ��R�[�h
     , created_by                 -- �쐬��
     , creation_date              -- �쐬��
     , last_updated_by            -- �ŏI�X�V��
     , last_update_date           -- �ŏI�X�V��
     , last_update_login          -- �ŏI�X�V۸޲�
     , request_id                 -- �v��ID
     , program_application_id     -- �ݶ��ĥ��۸��ѥ���ع����ID
     , program_id                 -- �ݶ��ĥ��۸���ID
     , program_update_date        -- ��۸��эX�V��
    )
     VALUES(
       io_contract_data_rec.contract_header_id         -- �_�����ID
     , io_contract_data_rec.contract_number            -- �_��ԍ�
     , io_contract_data_rec.lease_class                -- ���[�X���
     , io_contract_data_rec.lease_type                 -- ���[�X�敪
     , io_contract_data_rec.lease_company              -- ���[�X���
     , io_contract_data_rec.re_lease_times             -- �ă��[�X��
     , io_contract_data_rec.comments                   -- ����
     , io_contract_data_rec.contract_date              -- ���[�X�_���
     , io_contract_data_rec.payment_frequency          -- �x����
     , io_contract_data_rec.payment_type               -- �p�x
     , io_contract_data_rec.payment_years              -- �N�x
     , io_contract_data_rec.lease_start_date           -- ���[�X�J�n��
     , io_contract_data_rec.lease_end_date             -- ���[�X�I����
     , io_contract_data_rec.first_payment_date         -- ����x����
     , io_contract_data_rec.second_payment_date        -- �Q��ڎx����
     , io_contract_data_rec.third_payment_date         -- �R��ڈȍ~�x����
     , io_contract_data_rec.start_period_name          -- ��p�v���v��v����   
     , io_contract_data_rec.lease_payment_flag         -- �x���v�抮���t���O
     , io_contract_data_rec.tax_code                   -- �ŋ��R�[�h
     , io_contract_data_rec.created_by                 -- �쐬��
     , io_contract_data_rec.creation_date              -- �쐬��
     , io_contract_data_rec.last_updated_by            -- �ŏI�X�V��
     , io_contract_data_rec.last_update_date           -- �ŏI�X�V��
     , io_contract_data_rec.last_update_login          -- �ŏI�X�V۸޲�
     , io_contract_data_rec.request_id                 -- �v��ID
     , io_contract_data_rec.program_application_id     -- �ݶ��ĥ��۸��ѥ���ع����ID
     , io_contract_data_rec.program_id                 -- �ݶ��ĥ��۸���ID
     , io_contract_data_rec.program_update_date        -- ��۸��эX�V��
    )
    ;
  --
--
  EXCEPTION
--###############################  �Œ��O������ START   ###################################
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
--###################################  �Œ蕔 END   #########################################
--
  END insert_co_hed;
  --
  /**********************************************************************************
   * Function Name    : insert_co_lin
   * Description      : ���[�X�_�񖾍דo�^
   ***********************************************************************************/
  PROCEDURE insert_co_lin(
    io_contract_data_rec   IN OUT NOCOPY cont_lin_data_rtype  -- �_�񖾍׏��
   ,ov_errbuf              OUT NOCOPY VARCHAR2                -- �G���[�E���b�Z�[�W
   ,ov_retcode             OUT NOCOPY VARCHAR2                -- ���^�[���E�R�[�h
   ,ov_errmsg              OUT NOCOPY VARCHAR2                -- ���[�U�[�E�G���[�E���b�Z�[�W
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name     CONSTANT VARCHAR2(100) := 'insert_co_lin';   -- �v���O������
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf       VARCHAR2(5000) := NULL;              -- �G���[�E���b�Z�[�W
    lv_retcode      VARCHAR2(1)    := cv_status_normal;  -- ���^�[���E�R�[�h
    lv_errmsg       VARCHAR2(5000) := NULL;              -- ���[�U�[�E�G���[�E���b�Z�[�W
    --
    -- ===============================
    -- ���[�J���e�[�u���^
    -- ===============================
    --
    -- ===============================
    -- ���[�J���e�[�u���^�ϐ�
    -- ===============================
    --
  BEGIN
  --
    -- ������
    ov_errbuf  := NULL;
    ov_retcode := cv_status_normal;
    ov_errmsg  := NULL;
    --
    -- ***************************************************
    -- 1.�V�[�P���X�̎擾
    -- ***************************************************
    --
    SELECT    xxcff_contract_lines_s1.NEXTVAL
    INTO      io_contract_data_rec.contract_line_id
    FROM      dual
    ;
    --
    -- ***************************************************
    -- 2.���[�X�_�񖾍דo�^
    -- ***************************************************
    --
    INSERT INTO xxcff_contract_lines(
       contract_line_id            -- �_���������ID
     , contract_header_id          -- �_�����ID
     , contract_line_num           -- �_��}��
     , contract_status             -- �_��X�e�[�^�X
     , first_charge                -- ���񌎊z���[�X��_���[�X��
     , first_tax_charge            -- �������Ŋz_���[�X��
     , first_total_charge          -- ����v���[�X��
     , second_charge               -- �Q��ڌ��z���[�X��_���[�X��
     , second_tax_charge           -- �Q��ڏ���Ŋz_���[�X��
     , second_total_charge         -- �Q��ڌv���[�X��
     , first_deduction             -- ���񌎊z���[�X��_�T���z
     , first_tax_deduction         -- �������Ŋz_�T���z
     , first_total_deduction       -- ����v�T���z
     , second_deduction            -- �Q��ڈȍ~���z���[�X��_�T���z
     , second_tax_deduction        -- �Q��ڈȍ~����Ŋz_�T���z
     , second_total_deduction      -- �Q��ڈȍ~�v�T���z
     , gross_charge                -- ���z���[�X��_���[�X��
     , gross_tax_charge            -- ���z����Ŋz_���[�X��
     , gross_total_charge          -- ���z�v_���[�X��
     , gross_deduction             -- ���z���[�X��_�T���z
     , gross_tax_deduction         -- ���z�����_�T���z
     , gross_total_deduction       -- ���z�v_�T���z
     , lease_kind                  -- ���[�X���
     , estimated_cash_price        -- ���ό����w�����z
     , present_value_discount_rate -- �������l������
     , present_value               -- �������l
     , life_in_months              -- �@��ϗp�N��
     , original_cost               -- �擾���i
     , calc_interested_rate        -- �v�Z���q��
     , object_header_id            -- ��������id
     , asset_category              -- ���Y���
     , expiration_date             -- ������
     , cancellation_date           -- ���r����
     , vd_if_date                  -- ���[�X�_����A�g��
     , info_sys_if_date            -- ���[�X�Ǘ����A�g��
     , first_installation_address  -- ����ݒu�ꏊ
     , first_installation_place    -- ����ݒu��
-- 2013/06/26 Ver.1.1 T.Nakano ADD Start
     , tax_code                    -- �ŋ��R�[�h
-- 2013/06/26 Ver.1.1 T.Nakano ADD End
     , created_by                  -- �쐬��
     , creation_date               -- �쐬��
     , last_updated_by             -- �ŏI�X�V��
     , last_update_date            -- �ŏI�X�V��
     , last_update_login           -- �ŏI�X�V۸޲�
     , request_id                  -- �v��ID
     , program_application_id      -- �ݶ��ĥ��۸��ѥ���ع����ID
     , program_id                  -- �ݶ��ĥ��۸���ID
     , program_update_date         -- ��۸��эX�V��
    )
    VALUES(
       io_contract_data_rec.contract_line_id            -- �_���������ID
     , io_contract_data_rec.contract_header_id          -- �_�����ID
     , io_contract_data_rec.contract_line_num           -- �_��}��
     , io_contract_data_rec.contract_status             -- �_��X�e�[�^�X
     , io_contract_data_rec.first_charge                -- ���񌎊z���[�X��_���[�X��
     , io_contract_data_rec.first_tax_charge            -- �������Ŋz_���[�X��
     , io_contract_data_rec.first_total_charge          -- ����v���[�X��
     , io_contract_data_rec.second_charge               -- �Q��ڌ��z���[�X��_���[�X��
     , io_contract_data_rec.second_tax_charge           -- �Q��ڏ���Ŋz_���[�X��
     , io_contract_data_rec.second_total_charge         -- �Q��ڌv���[�X��
     , io_contract_data_rec.first_deduction             -- ���񌎊z���[�X��_�T���z
     , io_contract_data_rec.first_tax_deduction         -- �������Ŋz_�T���z
     , io_contract_data_rec.first_total_deduction       -- ����v�T���z
     , io_contract_data_rec.second_deduction            -- �Q��ڈȍ~���z���[�X��_�T���z
     , io_contract_data_rec.second_tax_deduction        -- �Q��ڈȍ~����Ŋz_�T���z
     , io_contract_data_rec.second_total_deduction      -- �Q��ڈȍ~�v�T���z
     , io_contract_data_rec.gross_charge                -- ���z���[�X��_���[�X��
     , io_contract_data_rec.gross_tax_charge            -- ���z����Ŋz_���[�X��
     , io_contract_data_rec.gross_total_charge          -- ���z�v_���[�X��
     , io_contract_data_rec.gross_deduction             -- ���z���[�X��_�T���z
     , io_contract_data_rec.gross_tax_deduction         -- ���z�����_�T���z
     , io_contract_data_rec.gross_total_deduction       -- ���z�v_�T���z
     , io_contract_data_rec.lease_kind                  -- ���[�X���
     , io_contract_data_rec.estimated_cash_price        -- ���ό����w�����z
     , io_contract_data_rec.present_value_discount_rate -- �������l������
     , io_contract_data_rec.present_value               -- �������l
     , io_contract_data_rec.life_in_months              -- �@��ϗp�N��
     , io_contract_data_rec.original_cost               -- �擾���i
     , io_contract_data_rec.calc_interested_rate        -- �v�Z���q��
     , io_contract_data_rec.object_header_id            -- ��������id
     , io_contract_data_rec.asset_category              -- ���Y���
     , io_contract_data_rec.expiration_date             -- ������
     , io_contract_data_rec.cancellation_date           -- ���r����
     , io_contract_data_rec.vd_if_date                  -- ���[�X�_����A�g��
     , io_contract_data_rec.info_sys_if_date            -- ���[�X�Ǘ����A�g��
     , io_contract_data_rec.first_installation_address  -- ����ݒu�ꏊ
     , io_contract_data_rec.first_installation_place    -- ����ݒu��
-- 2013/06/26 Ver.1.1 T.Nakano ADD Start
     , io_contract_data_rec.tax_code                    -- �ŋ��R�[�h
-- 2013/06/26 Ver.1.1 T.Nakano ADD End
     , io_contract_data_rec.created_by                  -- �쐬��
     , io_contract_data_rec.creation_date               -- �쐬��
     , io_contract_data_rec.last_updated_by             -- �ŏI�X�V��
     , io_contract_data_rec.last_update_date            -- �ŏI�X�V��
     , io_contract_data_rec.last_update_login           -- �ŏI�X�V۸޲�
     , io_contract_data_rec.request_id                  -- �v��ID
     , io_contract_data_rec.program_application_id      -- �ݶ��ĥ��۸��ѥ���ع����ID
     , io_contract_data_rec.program_id                  -- �ݶ��ĥ��۸���ID
     , io_contract_data_rec.program_update_date         -- ��۸��эX�V��
    )
    ;
    --
--
  EXCEPTION
--###############################  �Œ��O������ START   ###################################
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
--###################################  �Œ蕔 END   #########################################
--
  END insert_co_lin;
  --
  /**********************************************************************************
   * Function Name    : insert_co_his
   * Description      : ���[�X�_�񗚗�o�^
   ***********************************************************************************/
  PROCEDURE insert_co_his(
    io_contract_lin_data_rec IN OUT NOCOPY cont_lin_data_rtype  -- �_�񖾍׏��
   ,io_contract_his_data_rec IN OUT NOCOPY cont_his_data_rtype  -- �_�񗚗����
   ,ov_errbuf                  OUT NOCOPY VARCHAR2               -- �G���[�E���b�Z�[�W
   ,ov_retcode                 OUT NOCOPY VARCHAR2               -- ���^�[���E�R�[�h
   ,ov_errmsg                  OUT NOCOPY VARCHAR2               -- ���[�U�[�E�G���[�E���b�Z�[�W
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name     CONSTANT VARCHAR2(100) := 'insert_co_his';   -- �v���O������
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf       VARCHAR2(5000) := NULL;              -- �G���[�E���b�Z�[�W
    lv_retcode      VARCHAR2(1)    := cv_status_normal;  -- ���^�[���E�R�[�h
    lv_errmsg       VARCHAR2(5000) := NULL;              -- ���[�U�[�E�G���[�E���b�Z�[�W
    --
    ln_history_num  xxcff_contract_histories.history_num%TYPE; --�ύX������
    --
    -- ===============================
    -- ���[�J���e�[�u���^
    -- ===============================
    --
    -- ===============================
    -- ���[�J���e�[�u���^�ϐ�
    -- ===============================
    --
  BEGIN
  --
    -- ������
    ov_errbuf  := NULL;
    ov_retcode := cv_status_normal;
    ov_errmsg  := NULL;
    --
    -- ***************************************************
    -- 1.�V�[�P���X�̎擾
    -- ***************************************************
    --
    SELECT    xxcff_contract_histories_s1.NEXTVAL
    INTO      ln_history_num
    FROM      dual
    ;
    --
    -- ***************************************************
    -- 2.���[�X�_�񗚗�o�^
    -- ***************************************************
    --
    INSERT INTO xxcff_contract_histories(
       contract_header_id          -- �_�����ID
     , contract_line_id            -- �_���������ID
     , history_num                 -- �ύX������
     , contract_status             -- �_��X�e�[�^�X
     , first_charge                -- ���񌎊z���[�X��_���[�X��
     , first_tax_charge            -- �������Ŋz_���[�X��
     , first_total_charge          -- ����v���[�X��
     , second_charge               -- �Q��ڌ��z���[�X��_���[�X��
     , second_tax_charge           -- �Q��ڏ���Ŋz_���[�X��
     , second_total_charge         -- �Q��ڌv���[�X��
     , first_deduction             -- ���񌎊z���[�X��_�T���z
     , first_tax_deduction         -- �������Ŋz_�T���z
     , first_total_deduction       -- ����v�T���z
     , second_deduction            -- �Q��ڈȍ~���z���[�X��_�T���z
     , second_tax_deduction        -- �Q��ڈȍ~����Ŋz_�T���z
     , second_total_deduction      -- �Q��ڈȍ~�v�T���z
     , gross_charge                -- ���z���[�X��_���[�X��
     , gross_tax_charge            -- ���z����Ŋz_���[�X��
     , gross_total_charge          -- ���z�v_���[�X��
     , gross_deduction             -- ���z���[�X��_�T���z
     , gross_tax_deduction         -- ���z�����_�T���z
     , gross_total_deduction       -- ���z�v_�T���z
     , lease_kind                  -- ���[�X���
     , estimated_cash_price        -- ���ό����w�����z
     , present_value_discount_rate -- �������l������
     , present_value               -- �������l
     , life_in_months              -- �@��ϗp�N��
     , original_cost               -- �擾���i
     , calc_interested_rate        -- �v�Z���q��
     , object_header_id            -- ��������id
     , asset_category              -- ���Y���
     , expiration_date             -- ������
     , cancellation_date           -- ���r����
     , vd_if_date                  -- ���[�X�_����A�g��
     , info_sys_if_date            -- ���[�X�Ǘ����A�g��
     , first_installation_address  -- ����ݒu�ꏊ
     , first_installation_place    -- ����ݒu��
-- 2013/06/26 Ver.1.1 T.Nakano ADD Start
     , tax_code                    -- �ŋ��R�[�h
-- 2013/06/26 Ver.1.1 T.Nakano ADD End
     , accounting_date             -- �v���
     , accounting_if_flag          -- ��vIF�t���O
     , description                 -- �E�v
     , created_by                  -- �쐬��
     , creation_date               -- �쐬��
     , last_updated_by             -- �ŏI�X�V��
     , last_update_date            -- �ŏI�X�V��
     , last_update_login           -- �ŏI�X�V۸޲�
     , request_id                  -- �v��ID
     , program_application_id      -- �ݶ��ĥ��۸��ѥ���ع����ID
     , program_id                  -- �ݶ��ĥ��۸���ID
     , program_update_date         -- ��۸��эX�V��
     )
    VALUES(
       io_contract_lin_data_rec.contract_header_id          -- �_�����ID
     , io_contract_lin_data_rec.contract_line_id            -- �_���������ID
     , ln_history_num                                       -- �ύX������
     , io_contract_lin_data_rec.contract_status             -- �_��X�e�[�^�X
     , io_contract_lin_data_rec.first_charge                -- ���񌎊z���[�X��_���[�X��
     , io_contract_lin_data_rec.first_tax_charge            -- �������Ŋz_���[�X��
     , io_contract_lin_data_rec.first_total_charge          -- ����v���[�X��
     , io_contract_lin_data_rec.second_charge               -- �Q��ڌ��z���[�X��_���[�X��
     , io_contract_lin_data_rec.second_tax_charge           -- �Q��ڏ���Ŋz_���[�X��
     , io_contract_lin_data_rec.second_total_charge         -- �Q��ڌv���[�X��
     , io_contract_lin_data_rec.first_deduction             -- ���񌎊z���[�X��_�T���z
     , io_contract_lin_data_rec.first_tax_deduction         -- �������Ŋz_�T���z
     , io_contract_lin_data_rec.first_total_deduction       -- ����v�T���z
     , io_contract_lin_data_rec.second_deduction            -- �Q��ڈȍ~���z���[�X��_�T���z
     , io_contract_lin_data_rec.second_tax_deduction        -- �Q��ڈȍ~����Ŋz_�T���z
     , io_contract_lin_data_rec.second_total_deduction      -- �Q��ڈȍ~�v�T���z
     , io_contract_lin_data_rec.gross_charge                -- ���z���[�X��_���[�X��
     , io_contract_lin_data_rec.gross_tax_charge            -- ���z����Ŋz_���[�X��
     , io_contract_lin_data_rec.gross_total_charge          -- ���z�v_���[�X��
     , io_contract_lin_data_rec.gross_deduction             -- ���z���[�X��_�T���z
     , io_contract_lin_data_rec.gross_tax_deduction         -- ���z�����_�T���z
     , io_contract_lin_data_rec.gross_total_deduction       -- ���z�v_�T���z
     , io_contract_lin_data_rec.lease_kind                  -- ���[�X���
     , io_contract_lin_data_rec.estimated_cash_price        -- ���ό����w�����z
     , io_contract_lin_data_rec.present_value_discount_rate -- �������l������
     , io_contract_lin_data_rec.present_value               -- �������l
     , io_contract_lin_data_rec.life_in_months              -- �@��ϗp�N��
     , io_contract_lin_data_rec.original_cost               -- �擾���i
     , io_contract_lin_data_rec.calc_interested_rate        -- �v�Z���q��
     , io_contract_lin_data_rec.object_header_id            -- ��������id
     , io_contract_lin_data_rec.asset_category              -- ���Y���
     , io_contract_lin_data_rec.expiration_date             -- ������
     , io_contract_lin_data_rec.cancellation_date           -- ���r����
     , io_contract_lin_data_rec.vd_if_date                  -- ���[�X�_����A�g��
     , io_contract_lin_data_rec.info_sys_if_date            -- ���[�X�Ǘ����A�g��
     , io_contract_lin_data_rec.first_installation_address  -- ����ݒu�ꏊ
     , io_contract_lin_data_rec.first_installation_place    -- ����ݒu��
-- 2013/06/26 Ver.1.1 T.Nakano ADD Start
     , io_contract_lin_data_rec.tax_code                    -- �ŋ��R�[�h
-- 2013/06/26 Ver.1.1 T.Nakano ADD End
     , io_contract_his_data_rec.accounting_date             -- �v���
     , io_contract_his_data_rec.accounting_if_flag          -- ��vIF�t���O
     , io_contract_his_data_rec.description                 -- �E�v
     , io_contract_lin_data_rec.created_by                  -- �쐬��
     , io_contract_lin_data_rec.creation_date               -- �쐬��
     , io_contract_lin_data_rec.last_updated_by             -- �ŏI�X�V��
     , io_contract_lin_data_rec.last_update_date            -- �ŏI�X�V��
     , io_contract_lin_data_rec.last_update_login           -- �ŏI�X�V۸޲�
     , io_contract_lin_data_rec.request_id                  -- �v��ID
     , io_contract_lin_data_rec.program_application_id      -- �ݶ��ĥ��۸��ѥ���ع����ID
     , io_contract_lin_data_rec.program_id                  -- �ݶ��ĥ��۸���ID
     , io_contract_lin_data_rec.program_update_date         -- ��۸��эX�V��
    )
    ;
  --
--
  EXCEPTION
--###############################  �Œ��O������ START   ###################################
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
--###################################  �Œ蕔 END   #########################################
--
  END insert_co_his;
  --
  /**********************************************************************************
   * Function Name    : update_co_hed
   * Description      : ���[�X�_��X�V
   ***********************************************************************************/
  PROCEDURE update_co_hed(
    io_contract_data_rec IN OUT NOCOPY cont_hed_data_rtype    -- �_����
   ,ov_errbuf               OUT NOCOPY VARCHAR2               -- �G���[�E���b�Z�[�W
   ,ov_retcode              OUT NOCOPY VARCHAR2               -- ���^�[���E�R�[�h
   ,ov_errmsg               OUT NOCOPY VARCHAR2               -- ���[�U�[�E�G���[�E���b�Z�[�W
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name     CONSTANT VARCHAR2(100) := 'update_co_hed';   -- �v���O������
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf       VARCHAR2(5000) := NULL;              -- �G���[�E���b�Z�[�W
    lv_retcode      VARCHAR2(1)    := cv_status_normal;  -- ���^�[���E�R�[�h
    lv_errmsg       VARCHAR2(5000) := NULL;              -- ���[�U�[�E�G���[�E���b�Z�[�W
    --
    -- ===============================
    -- ���[�J���e�[�u���^
    -- ===============================
    --
    -- ===============================
    -- ���[�J���e�[�u���^�ϐ�
    -- ===============================
    --
  BEGIN
  --
    -- ������
    ov_errbuf  := NULL;
    ov_retcode := cv_status_normal;
    ov_errmsg  := NULL;
    --
    -- ***************************************************
    -- 1.���[�X�_��X�V
    -- ***************************************************
    --
    UPDATE xxcff_contract_headers  xch  -- ���[�X�_��e�[�u��
    SET    xch.contract_number         = io_contract_data_rec.contract_number            -- �_��ԍ�
         , xch.lease_class             = io_contract_data_rec.lease_class                -- ���[�X���
         , xch.lease_type              = io_contract_data_rec.lease_type                 -- ���[�X�敪
         , xch.lease_company           = io_contract_data_rec.lease_company              -- ���[�X���
         , xch.re_lease_times          = io_contract_data_rec.re_lease_times             -- �ă��[�X��
         , xch.comments                = io_contract_data_rec.comments                   -- ����
         , xch.contract_date           = io_contract_data_rec.contract_date              -- ���[�X�_���
         , xch.payment_frequency       = io_contract_data_rec.payment_frequency          -- �x����
         , xch.payment_type            = io_contract_data_rec.payment_type               -- �p�x
         , xch.payment_years           = io_contract_data_rec.payment_years              -- �N�x
         , xch.lease_start_date        = io_contract_data_rec.lease_start_date           -- ���[�X�J�n��
         , xch.lease_end_date          = io_contract_data_rec.lease_end_date             -- ���[�X�I����
         , xch.first_payment_date      = io_contract_data_rec.first_payment_date         -- ����x����
         , xch.second_payment_date     = io_contract_data_rec.second_payment_date        -- �Q��ڎx����
         , xch.third_payment_date      = io_contract_data_rec.third_payment_date         -- �R��ڈȍ~�x����
         , xch.start_period_name       = io_contract_data_rec.start_period_name          -- ��p�v���v��v����   
         , xch.lease_payment_flag      = io_contract_data_rec.lease_payment_flag         -- �x���v�抮���t���O
         , xch.tax_code                = io_contract_data_rec.tax_code                   -- �ŃR�[�h
         , xch.created_by              = io_contract_data_rec.created_by                 -- �쐬��
         , xch.creation_date           = io_contract_data_rec.creation_date              -- �쐬��
         , xch.last_updated_by         = io_contract_data_rec.last_updated_by            -- �ŏI�X�V��
         , xch.last_update_date        = io_contract_data_rec.last_update_date           -- �ŏI�X�V��
         , xch.last_update_login       = io_contract_data_rec.last_update_login          -- �ŏI�X�V۸޲�
         , xch.request_id              = io_contract_data_rec.request_id                 -- �v��ID
         , xch.program_application_id  = io_contract_data_rec.program_application_id     -- �ݶ��ĥ��۸��ѥ���ع����ID
         , xch.program_id              = io_contract_data_rec.program_id                 -- �ݶ��ĥ��۸���ID
         , xch.program_update_date     = io_contract_data_rec.program_update_date        -- ��۸��эX�V��     
    WHERE  xch.contract_header_id      = io_contract_data_rec.contract_header_id         -- �_�����ID
    ;
--
  EXCEPTION
--###############################  �Œ��O������ START   ###################################
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
--###################################  �Œ蕔 END   #########################################
--
  END update_co_hed;
  --
  /**********************************************************************************
   * Function Name    : update_co_lin
   * Description      : ���[�X�_�񖾍׍X�V
   ***********************************************************************************/
  PROCEDURE update_co_lin(
    io_contract_data_rec IN OUT NOCOPY cont_lin_data_rtype    -- �_�񖾍׏��
   ,ov_errbuf               OUT NOCOPY VARCHAR2               -- �G���[�E���b�Z�[�W
   ,ov_retcode              OUT NOCOPY VARCHAR2               -- ���^�[���E�R�[�h
   ,ov_errmsg               OUT NOCOPY VARCHAR2               -- ���[�U�[�E�G���[�E���b�Z�[�W
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name     CONSTANT VARCHAR2(100) := 'update_co_lin';   -- �v���O������
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf       VARCHAR2(5000) := NULL;              -- �G���[�E���b�Z�[�W
    lv_retcode      VARCHAR2(1)    := cv_status_normal;  -- ���^�[���E�R�[�h
    lv_errmsg       VARCHAR2(5000) := NULL;              -- ���[�U�[�E�G���[�E���b�Z�[�W
    --
    -- ===============================
    -- ���[�J���e�[�u���^
    -- ===============================
    TYPE null_check_ttype IS TABLE OF VARCHAR2(5000);
    -- ===============================
    -- ���[�J���e�[�u���^�ϐ�
    -- ===============================
    l_null_check_tab   null_check_ttype := null_check_ttype();  -- �K�{�`�F�b�N
    --
  BEGIN
  --
    -- ������
    ov_errbuf  := NULL;
    ov_retcode := cv_status_normal;
    ov_errmsg  := NULL;
    -- ***************************************************
    -- 1.���[�X�_��X�V
    -- ***************************************************
    --
    UPDATE xxcff_contract_lines xcl  -- ���[�X�_�񖾍׃e�[�u��
    SET    xcl.contract_line_num           = io_contract_data_rec.contract_line_num           -- �_��}��
         , xcl.contract_status             = io_contract_data_rec.contract_status             -- �_��X�e�[�^�X
         , xcl.first_charge                = io_contract_data_rec.first_charge                -- ���񌎊z���[�X��_���[�X��
         , xcl.first_tax_charge            = io_contract_data_rec.first_tax_charge            -- �������Ŋz_���[�X��
         , xcl.first_total_charge          = io_contract_data_rec.first_total_charge          -- ����v���[�X��
         , xcl.second_charge               = io_contract_data_rec.second_charge               -- �Q��ڌ��z���[�X��_���[�X��
         , xcl.second_tax_charge           = io_contract_data_rec.second_tax_charge           -- �Q��ڏ���Ŋz_���[�X��
         , xcl.second_total_charge         = io_contract_data_rec.second_total_charge         -- �Q��ڌv���[�X��
         , xcl.first_deduction             = io_contract_data_rec.first_deduction             -- ���񌎊z���[�X��_�T���z
         , xcl.first_tax_deduction         = io_contract_data_rec.first_tax_deduction         -- �������Ŋz_�T���z
         , xcl.first_total_deduction       = io_contract_data_rec.first_total_deduction       -- ����v�T���z
         , xcl.second_deduction            = io_contract_data_rec.second_deduction            -- �Q��ڈȍ~���z���[�X��_�T���z
         , xcl.second_tax_deduction        = io_contract_data_rec.second_tax_deduction        -- �Q��ڈȍ~����Ŋz_�T���z
         , xcl.second_total_deduction      = io_contract_data_rec.second_total_deduction      -- �Q��ڈȍ~�v�T���z
         , xcl.gross_charge                = io_contract_data_rec.gross_charge                -- ���z���[�X��_���[�X��
         , xcl.gross_tax_charge            = io_contract_data_rec.gross_tax_charge            -- ���z����Ŋz_���[�X��
         , xcl.gross_total_charge          = io_contract_data_rec.gross_total_charge          -- ���z�v_���[�X��
         , xcl.gross_deduction             = io_contract_data_rec.gross_deduction             -- ���z���[�X��_�T���z
         , xcl.gross_tax_deduction         = io_contract_data_rec.gross_tax_deduction         -- ���z�����_�T���z
         , xcl.gross_total_deduction       = io_contract_data_rec.gross_total_deduction       -- ���z�v_�T���z
         , xcl.lease_kind                  = io_contract_data_rec.lease_kind                  -- ���[�X���
         , xcl.estimated_cash_price        = io_contract_data_rec.estimated_cash_price        -- ���ό����w�����z
         , xcl.present_value_discount_rate = io_contract_data_rec.present_value_discount_rate -- �������l������
         , xcl.present_value               = io_contract_data_rec.present_value               -- �������l
         , xcl.life_in_months              = io_contract_data_rec.life_in_months              -- �@��ϗp�N��
         , xcl.original_cost               = io_contract_data_rec.original_cost               -- �擾���i
         , xcl.calc_interested_rate        = io_contract_data_rec.calc_interested_rate        -- �v�Z���q��
         , xcl.object_header_id            = io_contract_data_rec.object_header_id            -- ��������id
         , xcl.asset_category              = io_contract_data_rec.asset_category              -- ���Y���
         , xcl.expiration_date             = io_contract_data_rec.expiration_date             -- ������
         , xcl.cancellation_date           = io_contract_data_rec.cancellation_date           -- ���r����
         , xcl.vd_if_date                  = io_contract_data_rec.vd_if_date                  -- ���[�X�_����A�g��
         , xcl.info_sys_if_date            = io_contract_data_rec.info_sys_if_date            -- ���[�X�Ǘ����A�g��
         , xcl.first_installation_address  = io_contract_data_rec.first_installation_address  -- ����ݒu�ꏊ
         , xcl.first_installation_place    = io_contract_data_rec.first_installation_place    -- ����ݒu��
-- 2013/06/26 Ver.1.1 T.Nakano ADD Start
         , xcl.tax_code                    = io_contract_data_rec.tax_code                    -- �ŋ��R�[�h
-- 2013/06/26 Ver.1.1 T.Nakano ADD End
         , xcl.created_by                  = io_contract_data_rec.created_by                  -- �쐬��
         , xcl.creation_date               = io_contract_data_rec.creation_date               -- �쐬��
         , xcl.last_updated_by             = io_contract_data_rec.last_updated_by             -- �ŏI�X�V��
         , xcl.last_update_date            = io_contract_data_rec.last_update_date            -- �ŏI�X�V��
         , xcl.last_update_login           = io_contract_data_rec.last_update_login           -- �ŏI�X�V۸޲�
         , xcl.request_id                  = io_contract_data_rec.request_id                  -- �v��ID
         , xcl.program_application_id      = io_contract_data_rec.program_application_id      -- �ݶ��ĥ��۸��ѥ���ع����ID
         , xcl.program_id                  = io_contract_data_rec.program_id                  -- �ݶ��ĥ��۸���ID
         , xcl.program_update_date         = io_contract_data_rec.program_update_date         -- ��۸��эX�V��
    WHERE  xcl.contract_header_id          = io_contract_data_rec.contract_header_id          -- �_�����ID
      AND  xcl.contract_line_id            = io_contract_data_rec.contract_line_id            -- �_�񖾍ד���ID
    ;
--
  EXCEPTION
--###############################  �Œ��O������ START   ###################################
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
--###################################  �Œ蕔 END   #########################################
--
  END update_co_lin;
  --
END XXCFF_COMMON4_PKG;
/