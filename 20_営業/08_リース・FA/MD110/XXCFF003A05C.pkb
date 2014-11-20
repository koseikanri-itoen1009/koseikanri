create or replace
PACKAGE BODY XXCFF003A05C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCFF003A05C(body)
 * Description      : �x���v��쐬
 * MD.050           : MD050_CFF_003_A05_�x���v��쐬.doc
 * Version          : 1.1
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  get_process_date       �Ɩ��������t�擾����           (A-1)
 *  chk_data_validy        ���͍��ڃ`�F�b�N����           (A-2)
 *  get_contract_info      ���[�X�_���񒊏o����         (A-3)
 *  ins_pat_planning       ���[�X�x���v��쐬����         (A-5)
 *  upd_pat_planning       ���[�X�x���v��T���z�ύX����   (A-6)
 *  can_pat_planning       ���[�X�x���v�撆�r��񏈗�     (A-7)
 *  del_pat_planning       ���[�X�x���v��폜����         (A-8)
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor          Description
 * ------------- ----- ---------------- -------------------------------------------------
 * 2008/12/02     1.0   SCS�E��S��     �V�K�쐬
 * 2008/12/25     1.0   SCS�E��S��     �ƍ��σt���O�́A0,1�ɕύX
 * 2008/1/13      1.0   SCS�E��S��     �p�x���N�̏ꍇ�̎x�����Ή�
 * 2009/1/22      1.0   SCS�E��S��     �e�h�m���[�X���c���O�ɂȂ�Ȃ��ꍇ��
 *                                      �x�������̒������s��
 * 2009/2/5       1.1   SCS�E��S��     [��QCFF_010] �x���񐔎Z�o�s��Ή�
 *****************************************************************************************/
--
--#######################  �Œ�O���[�o���萔�錾�� START   #######################
  --
  --�X�e�[�^�X�E�R�[�h
  cv_status_normal  CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal;  -- ����:0
  cv_status_warn    CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_warn;    -- �x��:1
  cv_status_error   CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_error;   -- �ُ�:2
  --WHO�J����
  cn_created_by             CONSTANT NUMBER      := fnd_global.user_id;          --CREATED_BY
  cd_creation_date          CONSTANT DATE        := SYSDATE;                     --CREATION_DATE
  cn_last_updated_by        CONSTANT NUMBER      := fnd_global.user_id;          --LAST_UPDATED_BY
  cd_last_update_date       CONSTANT DATE        := SYSDATE;                     --LAST_UPDATE_DATE
  cn_last_update_login      CONSTANT NUMBER      := fnd_global.login_id;         --LAST_UPDATE_LOGIN
  cn_request_id             CONSTANT NUMBER      := fnd_global.conc_request_id;  --REQUEST_ID
  cn_program_application_id CONSTANT NUMBER      := fnd_global.prog_appl_id;     --PROGRAM_APPLICATION_ID
  cn_program_id             CONSTANT NUMBER      := fnd_global.conc_program_id;  --PROGRAM_ID
  cd_program_update_date    CONSTANT DATE        := SYSDATE;                     --PROGRAM_UPDATE_DATE
--
--#######################  �Œ�O���[�o���ϐ��錾�� START   #######################
--
  gv_out_msg        VARCHAR2(2000);
  gv_sep_msg        VARCHAR2(2000);
  gv_exec_user      VARCHAR2(100);
  gv_conc_name      VARCHAR2(30);
  gv_conc_status    VARCHAR2(30);
  gn_target_cnt     NUMBER;                       -- �Ώی���
  gn_normal_cnt     NUMBER;                       -- ���팏��
  gn_error_cnt      NUMBER;                       -- �G���[����
  gn_warn_cnt       NUMBER;                       -- �X�L�b�v����
--
--################################  �Œ蕔 END   ##################################
--
  cv_msg_part       CONSTANT VARCHAR2(1) := ':';  -- �R����
  cv_msg_cont       CONSTANT VARCHAR2(1) := '.';  -- �s���I�h
  --
--cv_const_n        CONSTANT VARCHAR2(1) := 'N';  -- 'N'
--cv_const_y        CONSTANT VARCHAR2(1) := 'Y';  -- 'Y'
  cv_const_0        CONSTANT VARCHAR2(1) := '0';  -- '���ƍ�'
  cv_const_1        CONSTANT VARCHAR2(1) := '1';  -- '�ƍ���'
  --
  cv_null_byte      CONSTANT VARCHAR2(1) := '';  -- ''
  --
  cv_shori_type1    CONSTANT VARCHAR2(1) := '1';  -- '�ǉ�'
  cv_shori_type2    CONSTANT VARCHAR2(1) := '2';  -- '�T���z�ύX'
  cv_shori_type3    CONSTANT VARCHAR2(1) := '3';  -- '���r���'
  cv_shori_type4    CONSTANT VARCHAR2(1) := '4';  -- '���'
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
  
  lock_expt              EXCEPTION;     -- ���b�N�擾�G���[
  PRAGMA EXCEPTION_INIT(lock_expt, -54);
  --
--################################  �Œ蕔 END   ##################################
  --
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name        CONSTANT VARCHAR2(100) := 'XXCFF003A05C'; -- �p�b�P�[�W��
  cv_app_kbn_cff     CONSTANT VARCHAR2(5)   := 'XXCFF';
--
  -- ���b�Z�[�W�ԍ�
  -- �_�񖾍ד���ID�G���[
  cv_msg_cff_00005   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-00005';
  -- ���b�N�G���[
  cv_msg_cff_00007   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-00007';
  -- �����敪�G���[
  cv_msg_cff_00060   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-00060';
  -- �Ɩ��������t�擾�G���[
  cv_msg_cff_00092   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-00092';
  -- ���b�Z�[�W�g�[�N��
  cv_tk_cff_00005_01 CONSTANT VARCHAR2(15)  := 'INPUT';       -- �J�����_����
  cv_tk_cff_00101_01 CONSTANT VARCHAR2(15)  := 'TABLE_NAME';  -- �e�[�u����
--
  -- �g�[�N��
  cv_msg_cff_50028   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-50028';  -- �_�񖾍ד���ID
  cv_msg_cff_50088   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-50088';  -- ���[�X�x���v��
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gd_process_date             date;                                                -- �Ɩ����t
  gn_payment_frequency        xxcff_contract_headers.payment_frequency%TYPE;       -- �x����
  gn_lease_class              xxcff_contract_headers.lease_class%TYPE;             -- ���[�X���
  gn_lease_type               xxcff_contract_headers.lease_type%TYPE;              -- ���[�X�敪
  gn_first_payment_date       xxcff_contract_headers.first_payment_date%TYPE;      -- ����x����
  gn_second_payment_date      xxcff_contract_headers.second_payment_date%TYPE;     -- �Q��ڎx����
  gn_third_payment_date       xxcff_contract_headers.third_payment_date%TYPE;      -- �R��ڈȍ~�x����
  gn_payment_type             xxcff_contract_headers.payment_type%TYPE;            -- �p�x
  gn_contract_header_id       xxcff_contract_headers.contract_header_id%TYPE;      -- �_�����ID
  gn_contract_line_id         xxcff_contract_lines.contract_line_id%TYPE;          -- �_�񖾍ד���ID
  gn_first_charge             xxcff_contract_lines.first_charge%TYPE;              -- ���񌎊z���[�X��_���[�X��
  gn_first_tax_charge         xxcff_contract_lines.first_tax_charge%TYPE;          -- �������Ŋz_���[�X��
  gn_first_deduction          xxcff_contract_lines.first_deduction%TYPE;           -- ���񌎊z���[�X��_�T���z
  gn_first_tax_deduction      xxcff_contract_lines.first_tax_deduction%TYPE;       -- �������Ŋz_�T���z
  gn_second_charge            xxcff_contract_lines.second_charge%TYPE;             -- �Q��ڌ��z���[�X��_���[�X��
  gn_second_tax_charge        xxcff_contract_lines.second_tax_charge%TYPE;         -- �Q��ڏ���Ŋz_���[�X��
  gn_second_deduction         xxcff_contract_lines.second_deduction%TYPE;          -- �Q��ڈȍ~���z���[�X��_�T���z
  gn_second_tax_deduction     xxcff_contract_lines.second_tax_deduction%TYPE;      -- �Q��ڈȍ~����Ŋz_�T���z
  gn_gross_tax_charge         xxcff_contract_lines.gross_tax_charge%TYPE;          -- ���z�����_���[�X��
  gn_gross_tax_deduction      xxcff_contract_lines.gross_tax_deduction%TYPE;       -- ���z�����_�T���z
  gn_original_cost            xxcff_contract_lines.original_cost%TYPE;             -- �擾���i
  gn_calc_interested_rate     xxcff_contract_lines.calc_interested_rate%TYPE;      -- �v�Z���q��
--
  /**********************************************************************************
   * Procedure Name   : get_process_date
   * Description      : �Ɩ��������t�擾����(A-1)
   ***********************************************************************************/
  PROCEDURE get_process_date(
    ov_errbuf              OUT NOCOPY VARCHAR2   -- �G���[�E���b�Z�[�W
   ,ov_retcode             OUT NOCOPY VARCHAR2   -- ���^�[���E�R�[�h
   ,ov_errmsg              OUT NOCOPY VARCHAR2   -- ���[�U�[�E�G���[�E���b�Z�[�W
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_process_date'; -- �v���O������
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
-- 
    --*** ���[�J���萔 ***
--
    --*** ���[�J���ϐ� ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************************
    -- �Ɩ��������t�擾����
    -- ***************************************************
    gd_process_date := xxccp_common_pkg2.get_process_date;
--
    IF (gd_process_date IS NULL ) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg(
                     cv_app_kbn_cff,      -- �A�v���P�[�V�����Z�k���FXXCFF
                     cv_msg_cff_00092     -- ���b�Z�[�W�F�Ɩ��������t�擾�G���[
                     ),1,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
--#################################  �Œ��O������ START   ####################################
--
  EXCEPTION
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
  END get_process_date;
--
 /**********************************************************************************
   * Procedure Name   : chk_data_validy 
   * Description      : ���͍��ڃ`�F�b�N���� (A-2)
   ***********************************************************************************/
  PROCEDURE chk_data_validy(
    iv_shori_type          IN  VARCHAR2         -- �����敪
   ,in_contract_line_id    IN  NUMBER           -- �_�񖾍ד���ID
   ,ov_errbuf              OUT NOCOPY VARCHAR2  -- �G���[�E���b�Z�[�W
   ,ov_retcode             OUT NOCOPY VARCHAR2  -- ���^�[���E�R�[�h
   ,ov_errmsg              OUT NOCOPY VARCHAR2  -- ���[�U�[�E�G���[�E���b�Z�[�W
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_data_validy'; -- �v���O������
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
--
    --*** ���[�J���萔 ***
--
    --*** ���[�J���ϐ� ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
    -- ***************************************************
    -- 1.�K�{�`�F�b�N
    -- ***************************************************
    -- �����敪
    IF ((iv_shori_type < cv_shori_type1) OR (iv_shori_type > cv_shori_type4)) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg(
                     cv_app_kbn_cff,       -- �A�v���P�[�V�����Z�k���FXXCFF
                     cv_msg_cff_00060      -- ���b�Z�[�W�F�����敪�G���[
                     ),1,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    -- �_�񖾍ד���ID
    IF (in_contract_line_id IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg(
                     cv_app_kbn_cff,       -- �A�v���P�[�V�����Z�k���FXXCFF
                     cv_msg_cff_00005,     -- ���b�Z�[�W�F�_�񖾍ד���ID�K�{�G���[
                     cv_tk_cff_00005_01,   -- �g�[�N�����FINPUT
                     cv_msg_cff_50028      -- �g�[�N��  �F�_�񖾍ד���ID
                     ),1,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
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
  END chk_data_validy;
--
 /**********************************************************************************
   * Procedure Name   : get_contract_info
   * Description      : ���[�X�_���񒊏o����       (A-3)
   ***********************************************************************************/
  PROCEDURE get_contract_info(
    in_contract_line_id  IN  NUMBER            -- �_�񖾍ד���ID
   ,ov_errbuf            OUT NOCOPY VARCHAR2   -- �G���[�E���b�Z�[�W
   ,ov_retcode           OUT NOCOPY VARCHAR2   -- ���^�[���E�R�[�h
   ,ov_errmsg            OUT NOCOPY VARCHAR2   -- ���[�U�[�E�G���[�E���b�Z�[�W
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_contract_info'; -- �v���O������
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
--
    --*** ���[�J���萔 ***
--
    --*** ���[�J���ϐ� ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************************
    -- 1.���[�X�_��A���[�X�_�񖾍ׂ̎擾
    -- ***************************************************
    --
    SELECT  xch.payment_frequency         -- �x����
           ,xch.lease_class               -- ���[�X���
           ,xch.lease_type                -- ���[�X�敪
           ,xch.first_payment_date        -- ����x����
           ,xch.second_payment_date       -- �Q��ڎx����
           ,xch.third_payment_date        -- �R��ڈȍ~�x����
           ,xch.payment_type              -- �p�x
           ,xcl.contract_header_id        -- �_�����ID
           ,xcl.contract_line_id          -- �_�񖾍ד���ID
           ,xcl.first_charge              -- ���񌎊z���[�X��_���[�X��
           ,xcl.first_tax_charge          -- �������Ŋz_���[�X��
           ,xcl.first_deduction           -- ���񌎊z���[�X��_�T���z
           ,xcl.first_tax_deduction       -- �������Ŋz_�T���z
           ,xcl.second_charge             -- �Q��ڌ��z���[�X��_���[�X��
           ,xcl.second_tax_charge         -- �Q��ڏ���Ŋz_���[�X��
           ,xcl.second_deduction          -- �Q��ڈȍ~���z���[�X��_�T���z
           ,xcl.second_tax_deduction      -- �Q��ڈȍ~����Ŋz_�T���z
           ,xcl.gross_tax_charge          -- ���z�����_���[�X��
           ,xcl.gross_tax_deduction       -- ���z�����_�T���z
           ,xcl.original_cost             -- �擾���i
           ,xcl.calc_interested_rate      -- �v�Z���q��
    INTO    gn_payment_frequency          -- �x����
           ,gn_lease_class                -- ���[�X���
           ,gn_lease_type                 -- ���[�X�敪
           ,gn_first_payment_date         -- ����x����
           ,gn_second_payment_date        -- �Q��ڎx����
           ,gn_third_payment_date         -- �R��ڈȍ~�x����
           ,gn_payment_type               -- �p�x
           ,gn_contract_header_id         -- �_�����ID
           ,gn_contract_line_id           -- �_�񖾍ד���ID
           ,gn_first_charge               -- ���񌎊z���[�X��_���[�X��
           ,gn_first_tax_charge           -- �������Ŋz_���[�X��
           ,gn_first_deduction            -- ���񌎊z���[�X��_�T���z
           ,gn_first_tax_deduction        -- �������Ŋz_�T���z
           ,gn_second_charge              -- �Q��ڌ��z���[�X��_���[�X��
           ,gn_second_tax_charge          -- �Q��ڏ���Ŋz_���[�X��
           ,gn_second_deduction           -- �Q��ڈȍ~���z���[�X��_�T���z
           ,gn_second_tax_deduction       -- �Q��ڈȍ~����Ŋz_�T���z
           ,gn_gross_tax_charge           -- ���z�����_���[�X��
           ,gn_gross_tax_deduction        -- ���z�����_�T���z
           ,gn_original_cost              -- �擾���i
           ,gn_calc_interested_rate       -- �v�Z���q��
    FROM    xxcff_contract_headers  xch   -- ���[�X�_��
           ,xxcff_contract_lines    xcl   -- ���[�X�_�񖾍�
    WHERE  xcl.contract_header_id  = xch.contract_header_id
    AND    xcl.contract_line_id    = in_contract_line_id;
--
--#################################  �Œ��O������ START   ####################################
--
  EXCEPTION
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
  END get_contract_info;
--
 /**********************************************************************************
   * Procedure Name   : ins_pat_planning
   * Description      : ���[�X�x���v��쐬���� (A-5)
   ***********************************************************************************/
  PROCEDURE ins_pat_planning(
    in_contract_line_id    IN  NUMBER            -- �_�񖾍ד���ID
   ,ov_errbuf              OUT NOCOPY VARCHAR2   -- �G���[�E���b�Z�[�W
   ,ov_retcode             OUT NOCOPY VARCHAR2   -- ���^�[���E�R�[�h
   ,ov_errmsg              OUT NOCOPY VARCHAR2   -- ���[�U�[�E�G���[�E���b�Z�[�W
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_pat_planning'; -- �v���O������
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
--
    --*** ���[�J���萔 ***
    cv_gn_lease_type1        CONSTANT VARCHAR2(1) := '1';  -- '���_��'
    cv_accounting_if_flag0   CONSTANT VARCHAR2(1) := '0';  -- '�ΏۊO'
    cv_accounting_if_flag1   CONSTANT VARCHAR2(1) := '1';  -- '�����M'
    cn_last_payment_date     CONSTANT NUMBER(2)   :=  31;  -- '31��'
    cv_payment_type_0        CONSTANT VARCHAR2(1) := '0';  -- '��'
    cv_payment_type_1        CONSTANT VARCHAR2(1) := '1';  -- '�N'
--
    --*** ���[�J���ϐ� ***
    ln_cnt                   NUMBER;      -- �����Ώی���
    ln_month                 NUMBER;      -- ����
--
    ln_calc_interested_rate  xxcff_contract_lines.calc_interested_rate%TYPE; -- �v�Z���q��
    ld_payment_date          xxcff_pay_planning.payment_date%TYPE;           -- �x����
    ld_period_name           xxcff_pay_planning.period_name%TYPE;            -- ��v����
    ln_lease_charge          xxcff_pay_planning.lease_charge%TYPE;           -- ���[�X��
    ln_tax_charge            xxcff_pay_planning.lease_tax_charge%TYPE;       -- ���[�X��_����Ŋz
    ln_lease_deduction       xxcff_pay_planning.lease_deduction%TYPE;        -- ���[�X�T���z
    ln_lease_tax_deduction   xxcff_pay_planning.lease_tax_deduction%TYPE;    -- ���[�X�T���z_�����
    ln_op_charge             xxcff_pay_planning.op_charge%TYPE;              -- �n�o���[�X��
    ln_op_tax_charge         xxcff_pay_planning.op_tax_charge%TYPE;          -- �n�o���[�X���z_�����
    ln_fin_debt              xxcff_pay_planning.fin_debt%TYPE;               -- �e�h�m���[�X���z
    ln_fin_tax_debt          xxcff_pay_planning.fin_tax_debt%TYPE;           -- �e�h�m���[�X���z_�����
    ln_fin_interest_due      xxcff_pay_planning.fin_interest_due%TYPE;       -- �e�h�m���[�X�x������
    ln_fin_debt_rem          xxcff_pay_planning.fin_debt_rem%TYPE;           -- �e�h�m���[�X���c
    ln_fin_tax_debt_rem      xxcff_pay_planning.fin_tax_debt_rem%TYPE;       -- �e�h�m���[�X���c_�����
    ln_accounting_if_flag    xxcff_pay_planning.accounting_if_flag%TYPE;     -- ��vIF�t���O
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    CURSOR pay_data_cur
    IS
      SELECT payment_frequency
      FROM   xxcff_pay_planning xpp
      WHERE  xpp.contract_line_id   = in_contract_line_id
      FOR UPDATE OF xpp.payment_frequency NOWAIT;
--
    -- *** ���[�J���E���R�[�h ***
     pay_data_rec pay_data_cur%ROWTYPE;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************************
    -- 1.���[�X�x���v������b�N����
    -- ***************************************************
--
    BEGIN
    --�J�[�\���̃I�[�v��
      OPEN pay_data_cur;
      CLOSE pay_data_cur;
--
    EXCEPTION
      WHEN lock_expt THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       cv_app_kbn_cff
                     , cv_msg_cff_00007
                     , cv_tk_cff_00101_01
                     , cv_msg_cff_50088
                      );                                              
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
--
    -- ==================================
    -- 2.�x���v�悪���݂���ꍇ�͍폜����
    -- ==================================
    DELETE
    FROM xxcff_pay_planning xpp
    WHERE  xpp.contract_line_id  = in_contract_line_id;
--
    -- ==================================
    -- 3.�x���v��̍쐬
    -- ==================================
    --�v�Z���q���͌����ɂ���
    ln_calc_interested_rate := round(gn_calc_interested_rate/12,7);
--
    --������
    ln_cnt           := 1;
    -- �Y�����������[�v����
    FOR ln_cnt IN 1..gn_payment_frequency LOOP
--
      --�x����
      IF (ln_cnt = 1) THEN
        ld_payment_date := gn_first_payment_date;
      ELSIF (ln_cnt = 2) THEN
        ld_payment_date := gn_second_payment_date;
      ELSE
        IF (gn_payment_type = cv_payment_type_0) THEN
          --3��ڎx������31��
          IF (gn_third_payment_date = cn_last_payment_date) THEN
            ld_payment_date := LAST_DAY(ADD_MONTHS(gn_second_payment_date,ln_cnt-2));
          --3��ڎx������31���ȊO
          ELSE
            ld_payment_date := ADD_MONTHS(gn_second_payment_date,ln_cnt-2);
          END IF;
        ELSE
          ln_month := (ln_cnt-2) * 12;
          ld_payment_date := ADD_MONTHS(gn_second_payment_date,ln_month); 
        END IF;
      END IF;
--
      --��v����
      ld_period_name := TO_CHAR(ld_payment_date,'YYYY-MM');
--
      --���[�X��
      IF (ln_cnt = 1) THEN
        ln_lease_charge := gn_first_charge;
      ELSE
        ln_lease_charge := gn_second_charge;
      END IF;
--
      --���[�X��_�����
      IF (ln_cnt = 1) THEN
        ln_tax_charge := gn_first_tax_charge;
      ELSE
        ln_tax_charge := gn_second_tax_charge;
      END IF;
--
      --���[�X�T���z
      IF (ln_cnt = 1) THEN
        ln_lease_deduction := gn_first_deduction;
      ELSE
        ln_lease_deduction := gn_second_deduction;
      END IF;
--
      --���[�X�T���z_�����
      IF (ln_cnt = 1) THEN
        ln_lease_tax_deduction := gn_first_tax_deduction;
      ELSE
        ln_lease_tax_deduction := gn_second_tax_deduction;
      END IF;
--
      --�n�o���[�X��
      IF (ln_cnt = 1) THEN
        ln_op_charge := gn_first_charge - gn_first_deduction;
      ELSE
        ln_op_charge := gn_second_charge - gn_second_deduction;
      END IF;
--
      --�n�o���[�X���z_����Ŋz
      IF (ln_cnt = 1) THEN
        ln_op_tax_charge := gn_first_tax_charge - gn_first_tax_deduction;
      ELSE
        ln_op_tax_charge := gn_second_tax_charge - gn_second_tax_deduction;
      END IF;
--
      --�e�h�m���[�X�x������      
      IF (gn_lease_type  = cv_gn_lease_type1) THEN
        IF (ln_cnt = 1) THEN
          ln_fin_interest_due := round(gn_original_cost * ln_calc_interested_rate);
        ELSE
          ln_fin_interest_due := round(ln_fin_debt_rem * ln_calc_interested_rate);
        END IF;
      END IF;
--
      --�e�h�m���[�X���z
      IF (gn_lease_type  = cv_gn_lease_type1) THEN
        IF (ln_cnt = 1) THEN
          ln_fin_debt := gn_first_charge - gn_first_deduction - ln_fin_interest_due;
        ELSE
          ln_fin_debt := gn_second_charge - gn_second_deduction - ln_fin_interest_due;
       END IF;
      END IF;
      --
      --�e�h�m���[�X���z_�����
      IF (gn_lease_type  = cv_gn_lease_type1) THEN
        IF (ln_cnt = 1) THEN
          ln_fin_tax_debt := gn_first_tax_charge - gn_first_tax_deduction;
        ELSE
          ln_fin_tax_debt := gn_second_tax_charge - gn_second_tax_deduction;
        END IF;
      END IF;
--
      --�e�h�m���[�X���c
       IF (gn_lease_type  = cv_gn_lease_type1) THEN
        IF (ln_cnt = 1) THEN
          ln_fin_debt_rem := gn_original_cost - ln_fin_debt;
        ELSE
          ln_fin_debt_rem := ln_fin_debt_rem - ln_fin_debt;
          --�x���񐔂��ŏI��łO�ɂȂ�Ȃ��ꍇ
          IF ((ln_cnt = gn_payment_frequency) AND (ln_fin_debt_rem <> 0)) THEN
              --�e�h�m���[�X���z
              ln_fin_debt := ln_fin_debt +  ln_fin_debt_rem;
              --�x������
              ln_fin_interest_due := ln_fin_interest_due - ln_fin_debt_rem;
              --�e�h�m���[�X���c          
              ln_fin_debt_rem := 0;
          ELSE
            IF (ln_fin_debt_rem < 0) THEN
              ln_fin_debt_rem := 0;
            END IF;          
          END IF;    
        END IF;
      END IF;
--
      --�e�h�m���[�X���c_�����
       IF (gn_lease_type  = cv_gn_lease_type1) THEN
        IF (ln_cnt = 1) THEN
          ln_fin_tax_debt_rem  := gn_gross_tax_charge - gn_gross_tax_deduction - ln_fin_tax_debt;
        ELSE
          ln_fin_tax_debt_rem  := ln_fin_tax_debt_rem - ln_fin_tax_debt;
            IF (ln_fin_tax_debt_rem< 0) THEN
              ln_fin_tax_debt_rem := 0;
            END IF;          
        END IF;
      END IF;
--
      --��vIF�t���O
      IF ( ld_period_name < TO_CHAR(gd_process_date,'YYYY-MM')) THEN
        ln_accounting_if_flag := cv_accounting_if_flag0;
      ELSE
        ln_accounting_if_flag := cv_accounting_if_flag1;
      END IF;
--
      -- ==================================
      -- �x���v��̓o�^
      -- ==================================
       INSERT INTO xxcff_pay_planning(
         contract_line_id                                 -- �_�񖾍ד���ID
       , payment_frequency                                -- �x����
       , contract_header_id                               -- �_�����ID
       , period_name                                      -- ��v����
       , payment_date                                     -- �x����
       , lease_charge                                     -- ���[�X��
       , lease_tax_charge                                 -- ���[�X��_�����
       , lease_deduction                                  -- ���[�X�T���z
       , lease_tax_deduction                              -- ���[�X�T���z_�����
       , op_charge                                        -- �n�o���[�X��
       , op_tax_charge                                    -- �n�o���[�X���z_�����
       , fin_debt                                         -- �e�h�m���[�X���z
       , fin_tax_debt                                     -- �e�h�m���[�X���z_�����
       , fin_interest_due                                 -- �e�h�m���[�X�x������
       , fin_debt_rem                                     -- �e�h�m���[�X���c
       , fin_tax_debt_rem                                 -- �e�h�m���[�X���c_�����
       , accounting_if_flag                               -- ��v�h�e�t���O
       , payment_match_flag                               -- �ƍ��σt���O
       , created_by                                       -- �쐬��
       , creation_date                                    -- �쐬��
       , last_updated_by                                  -- �ŏI�X�V��
       , last_update_date                                 -- �ŏI�X�V��
       , last_update_login                                -- �ŏI�X�V۸޲�
       , request_id                                       -- �v��ID
       , program_application_id                           -- �ݶ��ĥ��۸��ѥ���ع����ID
       , program_id                                       -- �ݶ��ĥ��۸���ID
       , program_update_date                              -- ��۸��эX�V��
       )
       VALUES(
         gn_contract_line_id                              -- �_���������ID
       , ln_cnt                                           -- �x����
       , gn_contract_header_id                            -- �_�����ID
       , ld_period_name                                   -- ��v����
       , ld_payment_date                                  -- �x����
       , ln_lease_charge                                  -- ���[�X��
       , ln_tax_charge                                    -- ���[�X��_�����
       , ln_lease_deduction                               -- ���[�X�T���z 
       , ln_lease_tax_deduction                           -- ���[�X�T���z_����Ŋz
       , ln_op_charge                                     -- �n�o���[�X��
       , ln_op_tax_charge                                 -- �n�o���[�X���z_�����
       , ln_fin_debt                                      -- �e�h�m���[�X���z
       , ln_fin_tax_debt                                  -- �e�h�m���[�X���z_�����
       , ln_fin_interest_due                              -- �e�h�m���[�X�x������
       , ln_fin_debt_rem                                  -- �e�h�m���[�X���c
       , ln_fin_tax_debt_rem                              -- �e�h�m���[�X���c_�����
       , ln_accounting_if_flag                            -- ��v�h�e�t���O
       , cv_const_0                                       -- �ƍ��σt���O
       , cn_created_by                                    -- �쐬��
       , cd_creation_date                                 -- �쐬��
       , cn_last_updated_by                               -- �ŏI�X�V��
       , cd_last_update_date                              -- �ŏI�X�V��
       , cn_last_update_login                             -- �ŏI�X�V۸޲�
       , cn_request_id                                    -- �v��ID
       , cn_program_application_id                        -- �ݶ��ĥ��۸��ѥ���ع����ID
       , cn_program_id                                    -- �ݶ��ĥ��۸���ID
       , cd_program_update_date                           -- ��۸��эX�V��
    );
    END LOOP;
--
--#################################  �Œ��O������ START   ####################################
--
  EXCEPTION
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
  END ins_pat_planning;
--
  /**********************************************************************************
   * Procedure Name   : upd_pat_planning 
   * Description      : ���[�X�x���v��T���z�ύX����   (A-6)
   ***********************************************************************************/
  PROCEDURE upd_pat_planning(
    in_contract_line_id    IN  NUMBER            -- �_�񖾍ד���ID
   ,ov_errbuf              OUT NOCOPY VARCHAR2   -- �G���[�E���b�Z�[�W
   ,ov_retcode             OUT NOCOPY VARCHAR2   -- ���^�[���E�R�[�h
   ,ov_errmsg              OUT NOCOPY VARCHAR2   -- ���[�U�[�E�G���[�E���b�Z�[�W
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_pat_planning'; -- �v���O������
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
--
    --*** ���[�J���萔 ***
    cv_accounting_if_flag1   CONSTANT VARCHAR2(1) := '1';  -- '�����M'
--
    --*** ���[�J���ϐ� ***
    ln_payment_frequency     xxcff_contract_headers.payment_frequency%TYPE;  --�x����
    ln_lease_charge          NUMBER;
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    CURSOR pay_data_cur
    IS
      SELECT lease_charge         --���[�X��
      FROM   xxcff_pay_planning xpp
      WHERE  xpp.contract_line_id  =  in_contract_line_id
      AND    xpp.payment_frequency >= ln_payment_frequency
      FOR UPDATE OF xpp.lease_charge NOWAIT;
--
    -- *** ���[�J���E���R�[�h ***
     pay_data_rec pay_data_cur%ROWTYPE;
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************************
    -- 1.MIN�l���擾����
    -- ***************************************************
    SELECT  MIN(xpp.payment_frequency)         -- �x����
    INTO    ln_payment_frequency               -- �x����
    FROM    xxcff_pay_planning xpp
    WHERE  xpp.contract_line_id   = in_contract_line_id
    AND    xpp.accounting_if_flag = cv_accounting_if_flag1
    AND    xpp.period_name        >= TO_CHAR(gd_process_date,'YYYY-MM');
--    
    --�x���񐔂��擾�ł��Ȃ��ꍇ�͂O��ݒ肷��
    ln_payment_frequency  := NVL(ln_payment_frequency,0);
--
    --�Y���f�[�^�����݂��Ȃ��ꍇ
    IF (ln_payment_frequency = 0) THEN
      RETURN;  
    END IF;
--
    -- ***************************************************
    -- 2.���[�X�x���v������b�N����
    -- ***************************************************
--
    BEGIN
    --�J�[�\���̃I�[�v��
      OPEN pay_data_cur;
      CLOSE pay_data_cur;
--
    EXCEPTION
      WHEN lock_expt THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       cv_app_kbn_cff
                     , cv_msg_cff_00007
                     , cv_tk_cff_00101_01
                     , cv_msg_cff_50088
                      );                                              
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
--    
    -- ***************************************************
    -- 3.���[�X�x���v���ΏۊO�ɂ���
    -- ***************************************************
--
    UPDATE xxcff_pay_planning xpp  -- ���[�X�x���v��
    SEt    xpp.lease_charge            = gn_second_charge                       -- �Q��ڌ��z���[�X��_���[�X��
         , xpp.lease_tax_charge        = gn_second_tax_charge                   -- �Q��ڏ���Ŋz_���[�X��
         , xpp.lease_deduction         = gn_second_deduction                    -- �Q��ڈȍ~���z���[�X��_�T���z
         , xpp.lease_tax_deduction     = gn_second_tax_deduction                -- �Q��ڈȍ~����Ŋz_�T���z
         , xpp.last_updated_by         = cn_last_updated_by                     -- �ŏI�X�V��
         , xpp.last_update_date        = cd_last_update_date                    -- �ŏI�X�V��
         , xpp.last_update_login       = cn_last_update_login                   -- �ŏI�X�V۸޲�
         , xpp.request_id              = cn_request_id                          -- �v��ID
         , xpp.program_application_id  = cn_program_application_id              -- �ݶ��ĥ��۸��ѥ���ع����ID
         , xpp.program_id              = cn_program_id                          -- �ݶ��ĥ��۸���ID
         , xpp.program_update_date     = cd_program_update_date                 -- ��۸��эX�V��
    WHERE  xpp.contract_line_id   =  in_contract_line_id
    AND    xpp.payment_frequency  >= ln_payment_frequency;
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
  END upd_pat_planning;
--
  /**********************************************************************************
   * Procedure Name   : can_pat_planning 
   * Description      : ���[�X�x���v�撆�r��񏈗�     (A-7)
   ***********************************************************************************/
  PROCEDURE can_pat_planning(
    in_contract_line_id    IN  NUMBER            -- �_�񖾍ד���ID
   ,ov_errbuf              OUT NOCOPY VARCHAR2   -- �G���[�E���b�Z�[�W
   ,ov_retcode             OUT NOCOPY VARCHAR2   -- ���^�[���E�R�[�h
   ,ov_errmsg              OUT NOCOPY VARCHAR2   -- ���[�U�[�E�G���[�E���b�Z�[�W
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'can_pat_planning'; -- �v���O������
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
--
    --*** ���[�J���萔 ***
    cv_accounting_if_flag0   CONSTANT VARCHAR2(1) := '0';  -- '�ΏۊO'    
    cv_accounting_if_flag1   CONSTANT VARCHAR2(1) := '1';  -- '�����M'
--
    --*** ���[�J���ϐ� ***
    ln_payment_frequency     xxcff_contract_headers.payment_frequency%TYPE;  --�x����
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    CURSOR pay_data_cur
    IS
      SELECT xpp.payment_frequency
      FROM   xxcff_pay_planning xpp
      WHERE  xpp.contract_line_id   =  in_contract_line_id
      AND    xpp.payment_frequency  >= ln_payment_frequency
      FOR UPDATE OF xpp.payment_frequency NOWAIT;
--
    -- *** ���[�J���E���R�[�h ***
     pay_data_rec pay_data_cur%ROWTYPE;
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************************
    -- 1.MIN�l���擾����
    -- ***************************************************
    ln_payment_frequency  := 0;
--
    SELECT MIN(xpp.payment_frequency)
    INTO   ln_payment_frequency
    FROM   xxcff_pay_planning xpp
    WHERE  xpp.contract_line_id   = in_contract_line_id
    AND    xpp.accounting_if_flag = cv_accounting_if_flag1
    AND    xpp.period_name        >= TO_CHAR(gd_process_date,'YYYY-MM');
--    
    --�x���񐔂��擾�ł��Ȃ��ꍇ�͂O��ݒ肷��
    ln_payment_frequency  := NVL(ln_payment_frequency,0);
--
    --�Y���f�[�^�����݂��Ȃ��ꍇ
    IF (ln_payment_frequency = 0) THEN
      RETURN;  
    END IF;
--
    -- ***************************************************
    -- 2.���[�X�x���v������b�N����
    -- ***************************************************
    BEGIN
    --�J�[�\���̃I�[�v��
      OPEN pay_data_cur;
      CLOSE pay_data_cur;
--
    EXCEPTION
      WHEN lock_expt THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       cv_app_kbn_cff
                     , cv_msg_cff_00007
                     , cv_tk_cff_00101_01
                     , cv_msg_cff_50088
                      );                                              
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
--    
    -- ***************************************************
    -- 3.���[�X�x���v���ΏۊO�ɂ���
    -- ***************************************************
    --
    UPDATE xxcff_pay_planning xpp  -- ���[�X�x���v��
    SET    xpp.accounting_if_flag      = cv_accounting_if_flag0                 -- ��vIF�t���O
         , xpp.last_updated_by         = cn_last_updated_by                     -- �ŏI�X�V��
         , xpp.last_update_date        = cd_last_update_date                    -- �ŏI�X�V��
         , xpp.last_update_login       = cn_last_update_login                   -- �ŏI�X�V۸޲�
         , xpp.request_id              = cn_request_id                          -- �v��ID
         , xpp.program_application_id  = cn_program_application_id              -- �ݶ��ĥ��۸��ѥ���ع����ID
         , xpp.program_id              = cn_program_id                          -- �ݶ��ĥ��۸���ID
         , xpp.program_update_date     = cd_program_update_date                 -- ��۸��эX�V��
    WHERE  xpp.contract_line_id        = in_contract_line_id
    AND    xpp.payment_frequency      >= ln_payment_frequency;
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
  END can_pat_planning;
--  
  /**********************************************************************************
   * Procedure Name   : del_pat_planning
   * Description      : ���[�X�x���v��쐬����       (A-8)
   ***********************************************************************************/
  PROCEDURE del_pat_planning(
    in_contract_line_id    IN  NUMBER            -- �_�񖾍ד���ID
   ,ov_errbuf              OUT NOCOPY VARCHAR2   -- �G���[�E���b�Z�[�W
   ,ov_retcode             OUT NOCOPY VARCHAR2   -- ���^�[���E�R�[�h
   ,ov_errmsg              OUT NOCOPY VARCHAR2   -- ���[�U�[�E�G���[�E���b�Z�[�W
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'del_pat_planning'; -- �v���O������
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
--
    --*** ���[�J���萔 ***
--
    --*** ���[�J���ϐ� ***
    ln_payment_frequency NUMBER;
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    CURSOR pay_data_cur
    IS
      SELECT payment_frequency
      FROM   xxcff_pay_planning xpp
      WHERE  xpp.contract_line_id   = in_contract_line_id
      FOR UPDATE OF xpp.payment_frequency NOWAIT;
--
    -- *** ���[�J���E���R�[�h ***
     pay_data_rec pay_data_cur%ROWTYPE;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************************
    -- 1.���[�X�x���v������b�N����
    -- ***************************************************
    BEGIN
    --�J�[�\���̃I�[�v��
      OPEN pay_data_cur;
      CLOSE pay_data_cur;
--
    EXCEPTION
      WHEN lock_expt THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       cv_app_kbn_cff
                     , cv_msg_cff_00007
                     , cv_tk_cff_00101_01
                     , cv_msg_cff_50088
                      );                                              
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
--
    -- ***************************************************
    -- 2.���[�X�x���v��̍폜����B
    -- ***************************************************
    DELETE
    FROM   xxcff_pay_planning xpp
    WHERE  xpp.contract_line_id   = in_contract_line_id;
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
  END del_pat_planning;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    iv_shori_type        IN  VARCHAR2,            --   �����敪
    in_contract_line_id  IN  NUMBER,              --   �_�񖾍ד���ID
    ov_errbuf            OUT NOCOPY VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode           OUT NOCOPY VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg            OUT NOCOPY VARCHAR2) --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    lv_check_flag        VARCHAR2(1);     -- �G���[�`�F�b�N�p�t���O
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
    gn_warn_cnt   := 0;
--
    --*********************************************
    --***      MD.050�̃t���[�}��\��           ***
    --***      ����Ə������̌Ăяo�����s��     ***
    --*********************************************
--
    -- ==================================
    -- �Ɩ��������t�擾����         (A-1)
    -- ==================================
    get_process_date(
      lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ==================================
    -- ���͍��ڃ`�F�b�N����         (A-2)
    -- ==================================
    chk_data_validy(
      iv_shori_type,       -- �����敪
      in_contract_line_id, -- �_�񖾍ד���ID
      lv_errbuf,           -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,          -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ==================================
    -- ���[�X�_���񒊏o����      (A-3)
    -- ==================================
    get_contract_info(
      in_contract_line_id, -- �_�񖾍ד���ID
      lv_errbuf,           -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,          -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ==================================
    -- ���[�X�x���v��쐬����      (A-5)
    -- ==================================
    IF (iv_shori_type = cv_shori_type1) THEN
      ins_pat_planning(
        in_contract_line_id, -- �_�񖾍ד���ID
        lv_errbuf,           -- �G���[�E���b�Z�[�W           --# �Œ� #
        lv_retcode,          -- ���^�[���E�R�[�h             --# �Œ� #
        lv_errmsg);          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    -- ==================================
    -- ���[�X�x���v��T���z�ύX���� (A-6)
    -- ==================================
    ELSIF (iv_shori_type = cv_shori_type2) THEN
      upd_pat_planning(
        in_contract_line_id, -- �_�񖾍ד���ID
        lv_errbuf,           -- �G���[�E���b�Z�[�W           --# �Œ� #
        lv_retcode,          -- ���^�[���E�R�[�h             --# �Œ� #
        lv_errmsg);          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    -- ==================================
    -- ���[�X�x���v�撆�r��񏈗�   (A-7)
    -- ==================================
    ELSIF (iv_shori_type = cv_shori_type3) THEN
      can_pat_planning(
        in_contract_line_id, -- �_�񖾍ד���ID
        lv_errbuf,           -- �G���[�E���b�Z�[�W           --# �Œ� #
        lv_retcode,          -- ���^�[���E�R�[�h             --# �Œ� #
        lv_errmsg);          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    -- ==================================
    -- ���[�X�x���v��쐬����       (A-8)
    -- ==================================
    ELSIF (iv_shori_type = cv_shori_type4) THEN
      del_pat_planning(
        in_contract_line_id, -- �_�񖾍ד���ID
        lv_errbuf,           -- �G���[�E���b�Z�[�W           --# �Œ� #
        lv_retcode,          -- ���^�[���E�R�[�h             --# �Œ� #
        lv_errmsg);          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    END IF;
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
--#################################  �Œ��O������ START   ###################################
--
  EXCEPTION
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
    iv_shori_type              IN VARCHAR2            --   1.�����敪
   ,in_contract_line_id        IN NUMBER              --   2.�_�񖾍ד���ID
   ,ov_errbuf                  OUT NOCOPY VARCHAR2    -- �G���[�E���b�Z�[�W
   ,ov_retcode                 OUT NOCOPY VARCHAR2    -- ���^�[���E�R�[�h
   ,ov_errmsg                  OUT NOCOPY VARCHAR2    -- ���[�U�[�E�G���[�E���b�Z�[�W
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
    -- ===============================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ===============================================
    submain(
       iv_shori_type         -- 1.�����敪
      ,in_contract_line_id   -- 2.�_�񖾍ד���ID
      ,lv_errbuf             -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode            -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg             -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    --�G���[�E���b�Z�[�W
    ov_errbuf  := lv_errbuf;
    --�X�e�[�^�X�Z�b�g
    ov_retcode := lv_retcode;
    -- ���[�U�[�E�G���[�E���b�Z�[�W
    ov_errmsg  := lv_errmsg;
--
    --�I���X�e�[�^�X���G���[�̏ꍇ��ROLLBACK����
    IF (ov_retcode = cv_status_error) THEN
      ROLLBACK;
    END IF;
--
  EXCEPTION
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
      ROLLBACK;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
      ROLLBACK;
  END main;
--
--###########################  �Œ蕔 END   #######################################################
--
END XXCFF003A05C;
/
