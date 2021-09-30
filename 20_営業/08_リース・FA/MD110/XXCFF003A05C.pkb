create or replace
PACKAGE BODY XXCFF003A05C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCFF003A05C(body)
 * Description      : �x���v��쐬
 * MD.050           : MD050_CFF_003_A05_�x���v��쐬.doc
 * Version          : 1.10
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  get_process_date       �Ɩ��������t�擾����                      (A-1)
 *  chk_data_validy        ���͍��ڃ`�F�b�N����                      (A-2)
 *  get_contract_info      ���[�X�_���񒊏o����                    (A-3)
 *  ins_pat_plan_class11   ���[�X�x���v��쐬���� �i���̋@�E���_��j (A-10)
 *  ins_pat_planning       ���[�X�x���v��쐬����                    (A-5)
 *  upd_pat_planning       ���[�X�x���v��T���z�ύX����              (A-6)
 *  can_pat_planning       ���[�X�x���v�撆�r��񏈗�                (A-7)
 *  del_pat_planning       ���[�X�x���v��폜����                    (A-8)
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
 * 2009/7/9       1.2   SCS�����L��     [�����e�X�g��Q00000417]���r�����X�V���̏����ύX
 * 2011/12/19     1.3   SCSK��������    [E_�{�ғ�_08123] ���r��񎞂̍X�V�����ύX
 * 2012/2/6       1.4   SCSK�������    [E_�{�ғ�_08356] �x���v��쐬���̉�v���Ԕ�r�����ύX 
 * 2016/9/6       1.5   SCSK���H���O    [E_�{�ғ�_13658] �ϗp�N���ύX�Ή�
 * 2016/10/26     1.6   SCSK�s          E_�{�ғ�_13658 ���̋@�ϗp�N���ύX�Ή��E�t�F�[�Y3
 * 2018/3/27      1.7   SCSK���        E_�{�ғ�_14830 IFRS���[�X���Y�Ή�
 * 2018/09/10     1.8   SCSK���X�؍G�V  E_�{�ғ�_14830 �ǉ��Ή�
 * 2019/10/03     1.9   SCSK��ΏG��    E_�{�ғ�_15913
 * 2021/09/22     1.10  SCSK���H���O    E_�{�ғ�_17431
 *
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
-- 2012/02/06 Ver.1.4 D.Sugahara ADD Start
  --���[�X���������Ԏ擾�G���[
  cv_msg_cff_00194   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-00194';  
-- 2012/02/06 Ver.1.4 D.Sugahara ADD End  
  -- ���b�Z�[�W�g�[�N��
  cv_tk_cff_00005_01 CONSTANT VARCHAR2(15)  := 'INPUT';       -- �J�����_����
  cv_tk_cff_00101_01 CONSTANT VARCHAR2(15)  := 'TABLE_NAME';  -- �e�[�u����
-- 2012/02/06 Ver.1.4 D.Sugahara ADD Start
  --���[�X���������Ԏ擾�G���[
  cv_tk_cff_00194_01 CONSTANT VARCHAR2(15)  := 'BOOK_ID';  -- �e�[�u����  
-- 2012/02/06 Ver.1.4 D.Sugahara ADD End  
-- 2018/03/27 Ver1.7 Otsuka ADD Start
  cv_tkn_lookup_type CONSTANT VARCHAR2(20) := 'LOOKUP_TYPE'; -- ���b�N�A�b�v�^�C�v
  cv_tk_cff_00094_01 CONSTANT VARCHAR2(15) := 'FUNC_NAME';   -- ���ʊ֐�
--
  -- ���ʊ֐��G���[
  cv_msg_cff_00094   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-00094';
  -- ���ʊ֐����b�Z�[�W
  cv_msg_cff_00095   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-00095';
  cv_msg_cff_00189   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-00189';  -- �Q�ƃ^�C�v�擾�G���[
-- 2018/03/27 Ver1.7 Otsuka ADD End
--
  -- �g�[�N��
  cv_msg_cff_50028   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-50028';  -- �_�񖾍ד���ID
  cv_msg_cff_50088   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-50088';  -- ���[�X�x���v��
-- 2018/03/27 Ver1.7 Otsuka ADD Start
  cv_msg_cff_50323   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-50323';  -- ���[�X���菈��
-- 2018/03/27 Ver1.7 Otsuka ADD End
--
-- 2016/09/06 Ver.1.5 Y.Shoji ADD Start
  --�v���t�@�C��
  cv_set_of_bks_id   CONSTANT VARCHAR2(30) := 'GL_SET_OF_BKS_ID';   --XXCFF: ���[�X�_����t�@�C������
-- V1.8 2018/09/10 Added START
  cv_ifrs_set_of_bks_id   CONSTANT VARCHAR2(30) := 'XXCFF1_IFRS_SET_OF_BKS_ID';   --  XXCFF:IFRS����ID
-- V1.8 2018/09/10 Added END
-- 2016/09/06 Ver.1.5 Y.Shoji ADD End
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
-- 2016/09/06 Ver.1.5 Y.Shoji ADD Start
  cv_lease_class11   CONSTANT VARCHAR2(2) := '11';       -- ���[�X��ʁF1�i���̋@�j
  cv_lease_type1     CONSTANT VARCHAR2(1) := '1';        -- ���[�X�敪�F1�i���_��j
  cv_lease_type2     CONSTANT VARCHAR2(1) := '2';        -- ���[�X�敪�F2�i�ă��[�X�j
--
  -- ���t�t�H�[�}�b�g
  cv_format_yyyymm   CONSTANT VARCHAR2(7) := 'YYYY-MM';  -- YYYY-MM�t�H�[�}�b�g
-- 2016/09/06 Ver.1.5 Y.Shoji ADD End
-- 2016/10/26 Ver.1.6 Y.Koh ADD Start
  cd_start_date      CONSTANT DATE := TO_DATE('2016/05/01','YYYY/MM/DD');
-- 2016/10/26 Ver.1.6 Y.Koh ADD End
-- 2018/03/27 Ver1.7 Otsuka ADD Start
  -- ���[�X����
  cv_lease_cls_chk2   CONSTANT VARCHAR2(1)  := '2';        -- ���[�X���茋�ʁF2
-- 2018/03/27 Ver1.7 Otsuka ADD End
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gd_process_date             date;                                                -- �Ɩ����t
  gn_payment_frequency        xxcff_contract_headers.payment_frequency%TYPE;       -- �x����
  gn_lease_class              xxcff_contract_headers.lease_class%TYPE;             -- ���[�X���
  gn_lease_type               xxcff_contract_headers.lease_type%TYPE;              -- ���[�X�敪
-- 2016/10/26 Ver.1.6 Y.Koh ADD Start
  gd_contract_date            xxcff_contract_headers.contract_date%TYPE;           -- ���[�X�_���
-- 2016/10/26 Ver.1.6 Y.Koh ADD End
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
-- == 2011/12/19 V1.3 Added START ======================================================================================
  gd_cancellation_date        xxcff_contract_lines.cancellation_date%TYPE;         -- ���r����
-- == 2011/12/19 V1.3 Added END   ======================================================================================
-- 2016/09/06 Ver.1.5 Y.Shoji ADD Start
  gt_re_lease_times           xxcff_contract_headers.re_lease_times%TYPE;          -- �ă��[�X��
  gt_original_cost_type1      xxcff_contract_lines.original_cost_type1%TYPE;       -- ���[�X���z_���_��
  gt_original_cost_type2      xxcff_contract_lines.original_cost_type2%TYPE;       -- ���[�X���z_�ă��[�X
-- 2016/09/06 Ver.1.5 Y.Shoji ADD End
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
-- 2016/10/26 Ver.1.6 Y.Koh ADD Start
           ,xch.contract_date             -- ���[�X�_���
-- 2016/10/26 Ver.1.6 Y.Koh ADD End
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
-- == 2011/12/19 V1.3 Added START ======================================================================================
           ,xcl.cancellation_date         -- ���r����
-- == 2011/12/19 V1.3 Added END   ======================================================================================
-- 2016/09/06 Ver.1.5 Y.Shoji ADD Start
           ,xch.re_lease_times            -- �ă��[�X��
           ,xcl.original_cost_type1       -- ���[�X���z_���_��
           ,xcl.original_cost_type2       -- ���[�X���z_�ă��[�X
-- 2016/09/06 Ver.1.5 Y.Shoji ADD End
    INTO    gn_payment_frequency          -- �x����
           ,gn_lease_class                -- ���[�X���
           ,gn_lease_type                 -- ���[�X�敪
-- 2016/10/26 Ver.1.6 Y.Koh ADD Start
           ,gd_contract_date              -- ���[�X�_���
-- 2016/10/26 Ver.1.6 Y.Koh ADD End
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
-- == 2011/12/19 V1.3 Added START ======================================================================================
           ,gd_cancellation_date          -- ���r����
-- == 2011/12/19 V1.3 Added END   ======================================================================================
-- 2016/09/06 Ver.1.5 Y.Shoji ADD Start
           ,gt_re_lease_times             -- �ă��[�X��
           ,gt_original_cost_type1        -- ���[�X���z_���_��
           ,gt_original_cost_type2        -- ���[�X���z_�ă��[�X
-- 2016/09/06 Ver.1.5 Y.Shoji ADD End
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
-- 2016/09/06 Ver.1.5 Y.Shoji ADD Start
 /**********************************************************************************
   * Procedure Name   : ins_pat_plan_class11
   * Description      : ���[�X�x���v��쐬���� �i���̋@�E���_��j (A-10)
   ***********************************************************************************/
  PROCEDURE ins_pat_plan_class11(
    in_contract_line_id    IN  NUMBER            -- �_�񖾍ד���ID
   ,ov_errbuf              OUT NOCOPY VARCHAR2   -- �G���[�E���b�Z�[�W
   ,ov_retcode             OUT NOCOPY VARCHAR2   -- ���^�[���E�R�[�h
   ,ov_errmsg              OUT NOCOPY VARCHAR2   -- ���[�U�[�E�G���[�E���b�Z�[�W
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_pat_plan_class11'; -- �v���O������
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
    cv_accounting_if_flag1   CONSTANT VARCHAR2(1) := '1';  -- '�����M'
    cv_accounting_if_flag2   CONSTANT VARCHAR2(1) := '2';  -- '���M��'
    cn_last_payment_date     CONSTANT NUMBER(2)   :=  31;  -- '31��'
    cv_payment_type_0        CONSTANT VARCHAR2(1) := '0';  -- '��'
    cn_payment_frequency85   CONSTANT NUMBER(2)   :=  85;  -- �x���񐔁F85��
    cv_const_9               CONSTANT VARCHAR2(1) := '9';  -- '�ΏۊO'
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
    lt_debt_re               xxcff_pay_planning.debt_re%TYPE;                -- ���[�X���z_�ă��[�X
    lt_interest_due_re       xxcff_pay_planning.interest_due_re%TYPE;        -- ���[�X�x������_�ă��[�X
    lt_debt_rem_re           xxcff_pay_planning.debt_rem_re%TYPE;            -- ���[�X���c_�ă��[�X
    ln_payment_match_flag    xxcff_pay_planning.payment_match_flag%TYPE;     -- �ƍ��σt���O
    ln_accounting_if_flag    xxcff_pay_planning.accounting_if_flag%TYPE;     -- ��vIF�t���O
    lv_close_period_name     xxcff_lease_closed_periods.period_name%TYPE;    -- ���[�X���������ԁi���߂�ꂽ�ŏI���j
    ln_set_of_book_id        gl_sets_of_books.set_of_books_id%TYPE;          -- ��v����ID
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    CURSOR pay_data_cur
    IS
      SELECT payment_frequency payment_frequency
      FROM   xxcff_pay_planning xpp
      WHERE  xpp.contract_line_id   = in_contract_line_id
      FOR UPDATE OF xpp.payment_frequency NOWAIT;
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
    -- 3.��v����ID���擾
    -- ==================================
    ln_set_of_book_id := TO_NUMBER(fnd_profile.value(cv_set_of_bks_id));
--
    -- ========================================
    -- 4.���[�X�������ߊ��Ԃ�茻��v���Ԃ̎擾
    -- ========================================
    BEGIN
--
      SELECT TO_CHAR(TO_DATE(period_name ,cv_format_yyyymm) ,cv_format_yyyymm) period_name  -- ���[�X�������ߊ���
      INTO   lv_close_period_name                                                           -- ����ꂽ�ŏI��
      FROM   xxcff_lease_closed_periods xlcp                                                -- ���[�X�������ߊ���
      WHERE  xlcp.set_of_books_id = ln_set_of_book_id                                       -- ��v����ID
      AND    xlcp.period_name IS NOT NULL
      ;
--
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_app_kbn_cff                       -- XXCFF
                                                      ,cv_msg_cff_00194                     -- ���[�X���������Ԏ擾�G���[
                                                      ,cv_tk_cff_00194_01                   -- ����ID�FBOOK_ID
                                                      ,TO_CHAR(ln_set_of_book_id))
                                                      ,1
                                                      ,5000);
        lv_errbuf := CHR(10) || lv_errmsg;
        RAISE global_api_expt;
    END;
--
    -- ==================================
    -- 5.�x���v��̍쐬�i�x����85�񕪁j
    -- ==================================
    --������
    ln_cnt := 1;
--
    --�v�Z���q���͌����ɂ���
    ln_calc_interested_rate := round(gn_calc_interested_rate/12,7);
--
    -- �Y�����������[�v����
    FOR ln_cnt IN 1..cn_payment_frequency85 LOOP
--
      -- ==============================
      -- #5.�x����
      -- ==============================
      -- ���_��1��ڕ�
      IF (ln_cnt = 1) THEN
        ld_payment_date := gn_first_payment_date;
      -- ���_��2��ڕ�
      ELSIF (ln_cnt = 2) THEN
        ld_payment_date := gn_second_payment_date;
      -- ���_�񂻂̑��A�ă��[�X��
      ELSE
        --3��ڎx������31��
        IF (gn_third_payment_date = cn_last_payment_date) THEN
          ld_payment_date := LAST_DAY(ADD_MONTHS(gn_second_payment_date,ln_cnt-2));
        --3��ڎx������31���ȊO
        ELSE
          ld_payment_date := ADD_MONTHS(gn_second_payment_date,ln_cnt-2);
        END IF;
      END IF;
--
      -- ==============================
      -- #4.��v����
      -- ==============================
      ld_period_name := TO_CHAR(ld_payment_date,cv_format_yyyymm);
--
      -- ==============================
      -- #6.���[�X��
      -- ==============================
      -- ���_��1��ڕ�
      IF (ln_cnt = 1) THEN
        ln_lease_charge := gn_first_charge;
      -- ���_��1��ڈȊO��
      ELSIF (ln_cnt BETWEEN 2 AND 60) THEN
        ln_lease_charge := gn_second_charge;
      -- �ă��[�X��
      ELSE
        ln_lease_charge := 0;
      END IF;
--
      -- ==============================
      -- #7.���[�X��_�����
      -- ==============================
      -- ���_��1��ڕ�
      IF (ln_cnt = 1) THEN
        ln_tax_charge := gn_first_tax_charge;
      -- ���_��1��ڈȊO��
      ELSIF (ln_cnt BETWEEN 2 AND 60) THEN
        ln_tax_charge := gn_second_tax_charge;
      -- �ă��[�X��
      ELSE
        ln_tax_charge := 0;
      END IF;
--
      -- ==============================
      -- #8.���[�X�T���z
      -- ==============================
      -- ���_��1��ڕ�
      IF (ln_cnt = 1) THEN
        ln_lease_deduction := gn_first_deduction;
      -- ���_��1��ڈȊO��
      ELSIF (ln_cnt BETWEEN 2 AND 60) THEN
        ln_lease_deduction := gn_second_deduction;
      -- �ă��[�X��
      ELSE
        ln_lease_deduction := 0;
      END IF;
--
      -- ==============================
      -- #9.���[�X�T���z_�����
      -- ==============================
      -- ���_��1��ڕ�
      IF (ln_cnt = 1) THEN
        ln_lease_tax_deduction := gn_first_tax_deduction;
      -- ���_��1��ڈȊO��
      ELSIF (ln_cnt BETWEEN 2 AND 60) THEN
        ln_lease_tax_deduction := gn_second_tax_deduction;
      -- �ă��[�X��
      ELSE
        ln_lease_tax_deduction := 0;
      END IF;
--
      -- ==============================
      -- #10.�n�o���[�X��
      -- ==============================
      -- ���_��1��ڕ�
      IF (ln_cnt = 1) THEN
        ln_op_charge := gn_first_charge - gn_first_deduction;
      -- ���_��1��ڈȊO��
      ELSIF (ln_cnt BETWEEN 2 AND 60) THEN
        ln_op_charge := gn_second_charge - gn_second_deduction;
      -- �ă��[�X1��ڕ�
      ELSIF (ln_cnt = 61) THEN
        ln_op_charge := TRUNC((gn_second_charge - gn_second_deduction) * 12 / 12);
      -- �ă��[�X2��ڕ�
      ELSIF (ln_cnt = 73) THEN
        ln_op_charge := TRUNC((gn_second_charge - gn_second_deduction) * 12 / 14);
      -- �ă��[�X3��ڕ�
      ELSIF (ln_cnt = 85) THEN
        ln_op_charge := TRUNC((gn_second_charge - gn_second_deduction) * 12 / 18);
      -- �ă��[�X���̑���
      ELSE
        ln_op_charge := 0;
      END IF;
--
      -- ==============================
      -- #11.�n�o���[�X���z_����Ŋz
      -- ==============================
      -- ���_��1��ڕ�
      IF (ln_cnt = 1) THEN
        ln_op_tax_charge := gn_first_tax_charge - gn_first_tax_deduction;
      -- ���_��1��ڈȊO��
      ELSIF (ln_cnt BETWEEN 2 AND 60) THEN
        ln_op_tax_charge := gn_second_tax_charge - gn_second_tax_deduction;
      -- �ă��[�X��
      ELSE
        ln_op_tax_charge := 0;
      END IF;
--
      -- ==============================
      -- #14.�e�h�m���[�X�x������
      -- ==============================
      -- ���_��1��ڕ�
      IF (ln_cnt = 1) THEN
        ln_fin_interest_due := ROUND(gt_original_cost_type1 * ln_calc_interested_rate);
      -- ���_��1��ڈȊO��
      ELSIF (ln_cnt BETWEEN 2 AND 60) THEN
        ln_fin_interest_due := ROUND(ln_fin_debt_rem * ln_calc_interested_rate);
      -- �ă��[�X��
      ELSE
        ln_fin_interest_due := 0;
      END IF;
--
      -- ==============================
      -- #12.�e�h�m���[�X���z
      -- ==============================
      -- ���_��1��ڕ�
      IF (ln_cnt = 1) THEN
        ln_fin_debt := gn_first_charge - gn_first_deduction - ln_fin_interest_due;
      -- ���_��1��ڈȊO��
      ELSIF (ln_cnt BETWEEN 2 AND 60) THEN
        ln_fin_debt := gn_second_charge - gn_second_deduction - ln_fin_interest_due;
      -- �ă��[�X��
      ELSE
        ln_fin_debt := 0;
      END IF;
--
      -- ==============================
      -- #13.�e�h�m���[�X���z_�����
      -- ==============================
      -- ���_��1��ڕ�
      IF (ln_cnt = 1) THEN
          ln_fin_tax_debt := gn_first_tax_charge - gn_first_tax_deduction;
      -- ���_��1��ڈȊO��
      ELSIF (ln_cnt BETWEEN 2 AND 60) THEN
        ln_fin_tax_debt := gn_second_tax_charge - gn_second_tax_deduction;
      -- �ă��[�X��
      ELSE
        ln_fin_tax_debt := 0;
      END IF;
--
      -- ==============================
      -- #15.�e�h�m���[�X���c
      -- ==============================
      -- ���_��1��ڕ�
      IF (ln_cnt = 1) THEN
        ln_fin_debt_rem := gt_original_cost_type1 - ln_fin_debt;
      -- ���_��1��ڈȊO��
      ELSIF (ln_cnt BETWEEN 2 AND 60) THEN
        ln_fin_debt_rem := ln_fin_debt_rem - ln_fin_debt;
        -- �x���񐔂�60���0�ɂȂ�Ȃ��ꍇ
        IF ((ln_cnt = 60) AND (ln_fin_debt_rem <> 0)) THEN
            -- �e�h�m���[�X���z
            ln_fin_debt := ln_fin_debt +  ln_fin_debt_rem;
            -- �x������
            ln_fin_interest_due := ln_fin_interest_due - ln_fin_debt_rem;
            -- �e�h�m���[�X���c
            ln_fin_debt_rem := 0;
        -- �x���񐔂�2-59��̎�
        ELSE
          -- �}�C�i�X�ɂȂ����ꍇ
          IF (ln_fin_debt_rem < 0) THEN
            ln_fin_debt_rem := 0;
          END IF;
        END IF;
      -- �ă��[�X��
      ELSE
        ln_fin_debt_rem := 0;
      END IF;
--
      -- ==============================
      -- #16.�e�h�m���[�X���c_�����
      -- ==============================
      -- ���_��1��ڕ�
      IF (ln_cnt = 1) THEN
        ln_fin_tax_debt_rem := gn_gross_tax_charge - gn_gross_tax_deduction - ln_fin_tax_debt;
      -- ���_��1��ڈȊO��
      ELSIF (ln_cnt BETWEEN 2 AND 60) THEN
        ln_fin_tax_debt_rem := ln_fin_tax_debt_rem - ln_fin_tax_debt;
        -- �}�C�i�X�ɂȂ����ꍇ
        IF (ln_fin_tax_debt_rem < 0) THEN
          ln_fin_tax_debt_rem := 0;
        END IF;
      -- �ă��[�X��
      ELSE
        ln_fin_tax_debt_rem := 0;
      END IF;
--
      -- ==============================
      -- #18.���[�X�x������_�ă��[�X
      -- ==============================
      -- ���_��1��ڕ�
      IF (ln_cnt = 1) THEN
        lt_interest_due_re := ROUND(gt_original_cost_type2 * ln_calc_interested_rate);
      ELSE
        lt_interest_due_re := ROUND(lt_debt_rem_re * ln_calc_interested_rate);
      END IF;
--
      -- ==============================
      -- #17.���[�X���z_�ă��[�X
      -- ==============================
      IF (ln_cnt BETWEEN 1 AND 60) THEN
        lt_debt_re := - lt_interest_due_re;
      ELSE
        lt_debt_re := ln_op_charge - lt_interest_due_re;
      END IF;
--
      -- ==============================
      -- #19.���[�X���c_�ă��[�X
      -- ==============================
      IF (ln_cnt = 1) THEN
        lt_debt_rem_re := gt_original_cost_type2 - lt_debt_re;
      ELSE
        lt_debt_rem_re := lt_debt_rem_re - lt_debt_re;
        -- �x���񐔂�85���0�ɂȂ�Ȃ��ꍇ
        IF ((ln_cnt = 85) AND (lt_debt_rem_re <> 0)) THEN
          -- 17.���[�X���z_�ă��[�X
          lt_debt_re := lt_debt_re + lt_debt_rem_re;
          -- 18.���[�X�x������_�ă��[�X
          lt_interest_due_re := lt_interest_due_re - lt_debt_rem_re;
          -- 19.���[�X���c_�ă��[�X
          lt_debt_rem_re := 0;
        -- �x���񐔂�2-84��̎�
        ELSE
          -- �}�C�i�X�ɂȂ����ꍇ
          IF (lt_debt_rem_re < 0) THEN
            lt_debt_rem_re := 0;
          END IF;
        END IF;
      END IF;
--
      -- ==============================
      -- #20.��vIF�t���O
      -- ==============================
      IF ( ld_period_name <= lv_close_period_name ) THEN
        ln_accounting_if_flag := cv_accounting_if_flag2;
      ELSE
        ln_accounting_if_flag := cv_accounting_if_flag1;
      END IF;
--
      -- ==============================
      -- #21.�ƍ��σt���O
      -- ==============================
      -- ���_��
      IF (ln_cnt BETWEEN 1 AND 60) THEN
        ln_payment_match_flag := cv_const_0;
      -- �ă��[�X��
      ELSE
        ln_payment_match_flag := cv_const_9;
      END IF;
--
      -- ==================================
      -- �x���v��̓o�^
      -- ==================================
      INSERT INTO xxcff_pay_planning(
         contract_line_id                                 -- 1.�_�񖾍ד���ID
       , payment_frequency                                -- 2.�x����
       , contract_header_id                               -- 3.�_�����ID
       , period_name                                      -- 4.��v����
       , payment_date                                     -- 5.�x����
       , lease_charge                                     -- 6.���[�X��
       , lease_tax_charge                                 -- 7.���[�X��_�����
       , lease_deduction                                  -- 8.���[�X�T���z
       , lease_tax_deduction                              -- 9.���[�X�T���z_�����
       , op_charge                                        -- 10.�n�o���[�X��
       , op_tax_charge                                    -- 11.�n�o���[�X���z_�����
       , fin_debt                                         -- 12.�e�h�m���[�X���z
       , fin_tax_debt                                     -- 13.�e�h�m���[�X���z_�����
       , fin_interest_due                                 -- 14.�e�h�m���[�X�x������
       , fin_debt_rem                                     -- 15.�e�h�m���[�X���c
       , fin_tax_debt_rem                                 -- 16.�e�h�m���[�X���c_�����
       , debt_re                                          -- 17.���[�X���z_�ă��[�X
       , interest_due_re                                  -- 18.���[�X�x������_�ă��[�X
       , debt_rem_re                                      -- 19.���[�X���c_�ă��[�X
       , accounting_if_flag                               -- 20.��v�h�e�t���O
       , payment_match_flag                               -- 21.�ƍ��σt���O
       , created_by                                       -- 22.�쐬��
       , creation_date                                    -- 23.�쐬��
       , last_updated_by                                  -- 24.�ŏI�X�V��
       , last_update_date                                 -- 25.�ŏI�X�V��
       , last_update_login                                -- 26.�ŏI�X�V۸޲�
       , request_id                                       -- 27.�v��ID
       , program_application_id                           -- 28.�ݶ��ĥ��۸��ѥ���ع����ID
       , program_id                                       -- 29.�ݶ��ĥ��۸���ID
       , program_update_date                              -- 30.��۸��эX�V��
      ) VALUES (
         gn_contract_line_id                              -- 1.�_���������ID
       , ln_cnt                                           -- 2.�x����
       , gn_contract_header_id                            -- 3.�_�����ID
       , ld_period_name                                   -- 4.��v����
       , ld_payment_date                                  -- 5.�x����
       , ln_lease_charge                                  -- 6.���[�X��
       , ln_tax_charge                                    -- 7.���[�X��_�����
       , ln_lease_deduction                               -- 8.���[�X�T���z 
       , ln_lease_tax_deduction                           -- 9.���[�X�T���z_����Ŋz
       , ln_op_charge                                     -- 10.�n�o���[�X��
       , ln_op_tax_charge                                 -- 11.�n�o���[�X���z_�����
       , ln_fin_debt                                      -- 12.�e�h�m���[�X���z
       , ln_fin_tax_debt                                  -- 13.�e�h�m���[�X���z_�����
       , ln_fin_interest_due                              -- 14.�e�h�m���[�X�x������
       , ln_fin_debt_rem                                  -- 15.�e�h�m���[�X���c
       , ln_fin_tax_debt_rem                              -- 16.�e�h�m���[�X���c_�����
       , lt_debt_re                                       -- 17.���[�X���z_�ă��[�X
       , lt_interest_due_re                               -- 18.���[�X�x������_�ă��[�X
       , lt_debt_rem_re                                   -- 19.���[�X���c_�ă��[�X
       , ln_accounting_if_flag                            -- 20.��v�h�e�t���O
       , ln_payment_match_flag                            -- 21.�ƍ��σt���O
       , cn_created_by                                    -- 22.�쐬��
       , cd_creation_date                                 -- 23.�쐬��
       , cn_last_updated_by                               -- 24.�ŏI�X�V��
       , cd_last_update_date                              -- 25.�ŏI�X�V��
       , cn_last_update_login                             -- 26.�ŏI�X�V۸޲�
       , cn_request_id                                    -- 27.�v��ID
       , cn_program_application_id                        -- 28.�ݶ��ĥ��۸��ѥ���ع����ID
       , cn_program_id                                    -- 29.�ݶ��ĥ��۸���ID
       , cd_program_update_date                           -- 30.��۸��эX�V��
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
  END ins_pat_plan_class11;
--
-- 2016/09/06 Ver.1.5 Y.Shoji ADD End
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
-- 00000417 2009/07/06 ADD START
    cv_accounting_if_flag2   CONSTANT VARCHAR2(1) := '2';  -- '���M��'
-- 00000417 2009/07/06 ADD END    
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
-- 2012/02/06 Ver.1.4 D.Sugahara ADD Start
    lv_close_period_name     xxcff_lease_closed_periods.period_name%TYPE;    --���[�X���������ԁi���߂�ꂽ�ŏI���j
    ln_set_of_book_id        gl_sets_of_books.set_of_books_id%TYPE;          --��v����ID
-- 2012/02/06 Ver.1.4 D.Sugahara ADD End
-- 2018/03/27 Ver1.7 Otsuka ADD Start
    lv_lease_class VARCHAR2(2);    -- ���[�X���
    lv_ret_dff4    VARCHAR2(1);    -- ���[�X����DFF4
    lv_ret_dff5    VARCHAR2(1);    -- ���[�X����DFF5
    lv_ret_dff6    VARCHAR2(1);    -- ���[�X����DFF6
    lv_ret_dff7    VARCHAR2(1);    -- ���[�X����DFF7
-- 2018/03/27 Ver1.7 Otsuka ADD End
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
-- V1.8 2018/09/10 Added START ������ړ�
    lv_lease_class := gn_lease_class;
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
    --  ���[�X���菈�� 
    xxcff_common2_pkg.get_lease_class_info(
        iv_lease_class  =>  lv_lease_class
      , ov_ret_dff4     =>  lv_ret_dff4           --  DFF4(���{��A�g)
      , ov_ret_dff5     =>  lv_ret_dff5           --  DFF5(IFRS�A�g)
      , ov_ret_dff6     =>  lv_ret_dff6           --  DFF6(�d��쐬)
      , ov_ret_dff7     =>  lv_ret_dff7           --  DFF7(���[�X���菈��)
      , ov_errbuf       =>  lv_errbuf
      , ov_retcode      =>  lv_retcode
      , ov_errmsg       =>  lv_errmsg
     );
    -- ���ʊ֐��G���[�̏ꍇ
    IF (lv_retcode <> cv_status_normal) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_app_kbn_cff,      -- �A�v���P�[�V�����Z�k���FXXCFF
                                                     cv_msg_cff_00094,    -- ���b�Z�[�W�F���ʊ֐��G���[
                                                     cv_tk_cff_00094_01,  -- ���ʊ֐���
                                                     cv_msg_cff_50323  )  -- �t�@�C��ID
                                                    || cv_msg_part
                                                    || lv_errmsg          --���ʊ֐���װү����
                                                    ,1
                                                    ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
-- V1.8 2018/09/10 Added END
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
-- 2012/02/06 Ver.1.4 D.Sugahara ADD Start

-- V1.8 2018/09/10 Modified START
--    --��v����ID�̎擾
--    ln_set_of_book_id := TO_NUMBER(fnd_profile.value('GL_SET_OF_BKS_ID'));
    --��v����ID�̎擾
    IF ( lv_ret_dff7 = '1' ) THEN
      ln_set_of_book_id := TO_NUMBER(fnd_profile.value(cv_set_of_bks_id));
    ELSE
      ln_set_of_book_id := TO_NUMBER(fnd_profile.value(cv_ifrs_set_of_bks_id));
    END IF;
-- V1.8 2018/09/10 Modified END
    --���[�X�������ߊ��Ԃ�茻��v���Ԃ̎擾
    BEGIN
--
      SELECT TO_CHAR(TO_DATE(period_name,'YYYY-MM'),'YYYY-MM') period_name  -- ���[�X�������ߊ���
      INTO   lv_close_period_name                                           -- ����ꂽ�ŏI��
      FROM   xxcff_lease_closed_periods xlcp                                -- ���[�X�������ߊ���
      WHERE  xlcp.set_of_books_id = ln_set_of_book_id                       -- ��v����ID
      AND    xlcp.period_name IS NOT NULL
      ;
--
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_app_kbn_cff                       -- XXCFF
                                                      ,cv_msg_cff_00194                     -- ���[�X���������Ԏ擾�G���[
                                                      ,cv_tk_cff_00194_01                   -- ����ID�FBOOK_ID
                                                      ,TO_CHAR(ln_set_of_book_id))
                                                      ,1
                                                      ,5000);
        lv_errbuf := CHR(10) || lv_errmsg;
        RAISE global_api_expt;
    END;
--
-- 2012/02/06 Ver.1.4 D.Sugahara ADD End
--
-- V1.8 2018/09/10 Deleted START ��������ֈړ�
-- 2018/03/27 Ver1.7 Otsuka ADD Start
--
--    lv_lease_class := gn_lease_class;
--    -- ***************************************
--    -- ***        �������̋L�q             ***
--    -- ***       ���ʊ֐��̌Ăяo��        ***
--    -- ***************************************
--    --  ���[�X���菈�� 
--    xxcff_common2_pkg.get_lease_class_info(
--        iv_lease_class  =>    lv_lease_class
--        ,ov_ret_dff4    =>    lv_ret_dff4           -- DFF4(���{��A�g)
--        ,ov_ret_dff5    =>    lv_ret_dff5           -- DFF5(IFRS�A�g)
--        ,ov_ret_dff6    =>    lv_ret_dff6           -- DFF6(�d��쐬)
--        ,ov_ret_dff7    =>    lv_ret_dff7           -- DFF7(���[�X���菈��)
--        ,ov_errbuf      =>    lv_errbuf
--        ,ov_retcode     =>    lv_retcode
--        ,ov_errmsg      =>    lv_errmsg
--     );
--    -- ���ʊ֐��G���[�̏ꍇ
--    IF (lv_retcode <> cv_status_normal) THEN
--      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_app_kbn_cff,      -- �A�v���P�[�V�����Z�k���FXXCFF
--                                                     cv_msg_cff_00094,    -- ���b�Z�[�W�F���ʊ֐��G���[
--                                                     cv_tk_cff_00094_01,  -- ���ʊ֐���
--                                                     cv_msg_cff_50323  )  -- �t�@�C��ID
--                                                    || cv_msg_part
--                                                    || lv_errmsg          --���ʊ֐���װү����
--                                                    ,1
--                                                    ,5000);
--      lv_errbuf := lv_errmsg;
--      RAISE global_api_expt;
--   END IF;
-- 2018/03/27 Ver1.7 Otsuka ADD End
-- V1.8 2018/09/10 Deleted END
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
-- 2018/03/27 Ver1.7 Otsuka MOD Start
--      IF (gn_lease_type  = cv_gn_lease_type1) THEN
--    ���[�X�敪���f���_��'�̏ꍇ����сA���[�X���肪'2'�̏ꍇ
      IF (gn_lease_type  = cv_gn_lease_type1) OR (lv_ret_dff7 = cv_lease_cls_chk2)THEN
-- 2018/03/27 Ver1.7 Otsuka MOD End
        IF (ln_cnt = 1) THEN
-- V1.8 2018/09/10 Modified START
--          ln_fin_interest_due := round(gn_original_cost * ln_calc_interested_rate);
          IF ( lv_ret_dff7 = cv_lease_cls_chk2 ) THEN
            ln_fin_interest_due :=  0;
          ELSE
            ln_fin_interest_due := round(gn_original_cost * ln_calc_interested_rate);
          END IF;
-- V1.8 2018/09/10 Modified END
        ELSE
          ln_fin_interest_due := round(ln_fin_debt_rem * ln_calc_interested_rate);
        END IF;
      END IF;
--
      --�e�h�m���[�X���z
-- 2018/03/27 Ver1.7 Otsuka MOD Start
--      IF (gn_lease_type  = cv_gn_lease_type1) THEN
      IF (gn_lease_type  = cv_gn_lease_type1) OR (lv_ret_dff7 = cv_lease_cls_chk2)THEN
-- 2018/03/27 Ver1.7 Otsuka MOD End
        IF (ln_cnt = 1) THEN
          ln_fin_debt := gn_first_charge - gn_first_deduction - ln_fin_interest_due;
        ELSE
          ln_fin_debt := gn_second_charge - gn_second_deduction - ln_fin_interest_due;
       END IF;
      END IF;
      --
      --�e�h�m���[�X���z_�����
-- 2018/03/27 Ver1.7 Otsuka MOD Start
--      IF (gn_lease_type  = cv_gn_lease_type1) THEN
      IF (gn_lease_type  = cv_gn_lease_type1) OR (lv_ret_dff7 = cv_lease_cls_chk2)THEN
-- 2018/03/27 Ver1.7 Otsuka MOD End
        IF (ln_cnt = 1) THEN
          ln_fin_tax_debt := gn_first_tax_charge - gn_first_tax_deduction;
        ELSE
          ln_fin_tax_debt := gn_second_tax_charge - gn_second_tax_deduction;
        END IF;
      END IF;
--
      --�e�h�m���[�X���c
-- 2018/03/27 Ver1.7 Otsuka MOD Start
--      IF (gn_lease_type  = cv_gn_lease_type1) THEN
      IF (gn_lease_type  = cv_gn_lease_type1) OR (lv_ret_dff7 = cv_lease_cls_chk2)THEN
-- 2018/03/27 Ver1.7 Otsuka MOD End
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
-- 2018/03/27 Ver1.7 Otsuka MOD Start
--      IF (gn_lease_type  = cv_gn_lease_type1) THEN
      IF (gn_lease_type  = cv_gn_lease_type1) OR (lv_ret_dff7 = cv_lease_cls_chk2)THEN
-- 2018/03/27 Ver1.7 Otsuka MOD End
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
-- 2012/02/06 Ver.1.4 D.Sugahara MOD Start  
-- �E���ׂ��Ή�    
--   �Ώێx���v��̉�v���ԂƋƖ����t�x�[�X�̉�v���Ԃ̔�r
-- ���Ώێx���v��̉�v���Ԃƃ��[�X���������Ԃ̔�r�@�ɏC��
--      IF ( ld_period_name < TO_CHAR(gd_process_date,'YYYY-MM')) THEN
      IF ( ld_period_name <= lv_close_period_name ) THEN
-- 2012/02/06 Ver.1.4 D.Sugahara MOD End      
-- 00000417 2009/07/06  START
--        ln_accounting_if_flag := cv_accounting_if_flag0;
        ln_accounting_if_flag := cv_accounting_if_flag2;
-- 00000417 2009/07/06  END
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
-- V1.8 2018/09/10 Modified START
--       , cv_const_0                                       -- �ƍ��σt���O
       , CASE WHEN lv_ret_dff7 = cv_lease_cls_chk2
           THEN  cv_const_1
           ELSE  cv_const_0
         END                                              -- �ƍ��σt���O
-- V1.8 2018/09/10 Modified END
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
-- 2016/09/06 Ver.1.5 Y.Shoji ADD Start
    cv_payment_match_flag9   CONSTANT VARCHAR2(1) := '9';  -- '�ΏۊO'
-- 2016/09/06 Ver.1.5 Y.Shoji ADD End
--
    --*** ���[�J���ϐ� ***
    ln_payment_frequency     xxcff_contract_headers.payment_frequency%TYPE;  --�x����
    ln_lease_charge          NUMBER;
-- V1.8 2018/09/10 Added START
    lv_ret_dff4           VARCHAR2(1);                                    --  ���[�X����DFF4
    lv_ret_dff5           VARCHAR2(1);                                    --  ���[�X����DFF5
    lv_ret_dff6           VARCHAR2(1);                                    --  ���[�X����DFF6
    lv_ret_dff7           VARCHAR2(1);                                    --  ���[�X����DFF7
    ln_set_of_book_id     gl_sets_of_books.set_of_books_id%TYPE;          --  ��v����ID
    lv_close_period_name  xxcff_lease_closed_periods.period_name%TYPE;    --  ���[�X���������ԁi���߂�ꂽ�ŏI���j
-- V1.8 2018/09/10 Added END
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    CURSOR pay_data_cur
    IS
      SELECT lease_charge         --���[�X��
      FROM   xxcff_pay_planning xpp
      WHERE  xpp.contract_line_id  =  in_contract_line_id
-- 2016/09/06 Ver.1.5 Y.Shoji ADD Start
      AND    xpp.payment_match_flag <> cv_payment_match_flag9
-- 2016/09/06 Ver.1.5 Y.Shoji ADD End
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
-- V1.8 2018/09/10 Added START
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
    --  ���[�X���菈�� 
    xxcff_common2_pkg.get_lease_class_info(
        iv_lease_class  =>  gn_lease_class
      , ov_ret_dff4     =>  lv_ret_dff4           --  DFF4(���{��A�g)
      , ov_ret_dff5     =>  lv_ret_dff5           --  DFF5(IFRS�A�g)
      , ov_ret_dff6     =>  lv_ret_dff6           --  DFF6(�d��쐬)
      , ov_ret_dff7     =>  lv_ret_dff7           --  DFF7(���[�X���菈��)
      , ov_errbuf       =>  lv_errbuf
      , ov_retcode      =>  lv_retcode
      , ov_errmsg       =>  lv_errmsg
     );
    -- ���ʊ֐��G���[�̏ꍇ
    IF (lv_retcode <> cv_status_normal) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_app_kbn_cff,      -- �A�v���P�[�V�����Z�k���FXXCFF
                                                     cv_msg_cff_00094,    -- ���b�Z�[�W�F���ʊ֐��G���[
                                                     cv_tk_cff_00094_01,  -- ���ʊ֐���
                                                     cv_msg_cff_50323  )  -- �t�@�C��ID
                                                    || cv_msg_part
                                                    || lv_errmsg          --���ʊ֐���װү����
                                                    ,1
                                                    ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    --
    --��v����ID�̎擾
    IF ( lv_ret_dff7 = '1' ) THEN
      ln_set_of_book_id := TO_NUMBER(fnd_profile.value(cv_set_of_bks_id));
    ELSE
      ln_set_of_book_id := TO_NUMBER(fnd_profile.value(cv_ifrs_set_of_bks_id));
    END IF;
    --
    --���[�X�������ߊ��Ԃ�茻��v���Ԃ̎擾
    BEGIN
      SELECT TO_CHAR(TO_DATE(period_name,'YYYY-MM'),'YYYY-MM') period_name  -- ���[�X�������ߊ���
      INTO   lv_close_period_name                                           -- ����ꂽ�ŏI��
      FROM   xxcff_lease_closed_periods xlcp                                -- ���[�X�������ߊ���
      WHERE  xlcp.set_of_books_id = ln_set_of_book_id                       -- ��v����ID
      AND    xlcp.period_name IS NOT NULL
      ;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_app_kbn_cff                       -- XXCFF
                                                      ,cv_msg_cff_00194                     -- ���[�X���������Ԏ擾�G���[
                                                      ,cv_tk_cff_00194_01                   -- ����ID�FBOOK_ID
                                                      ,TO_CHAR(ln_set_of_book_id))
                                                      ,1
                                                      ,5000);
        lv_errbuf := CHR(10) || lv_errmsg;
        RAISE global_api_expt;
    END;
-- V1.8 2018/09/10 Added END
--
    -- ***************************************************
    -- 1.MIN�l���擾����
    -- ***************************************************
    SELECT  MIN(xpp.payment_frequency)         -- �x����
    INTO    ln_payment_frequency               -- �x����
    FROM    xxcff_pay_planning xpp
    WHERE  xpp.contract_line_id   = in_contract_line_id
    AND    xpp.accounting_if_flag = cv_accounting_if_flag1
-- V1.8 2018/09/10 Modified START
--    AND    xpp.period_name        >= TO_CHAR(gd_process_date,'YYYY-MM');
    AND    xpp.period_name        > lv_close_period_name;
-- V1.8 2018/09/10 Modified END
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
-- 2016/09/06 Ver.1.5 Y.Shoji ADD Start
    AND    xpp.payment_match_flag <> cv_payment_match_flag9
-- 2016/09/06 Ver.1.5 Y.Shoji ADD End
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
-- 2016/09/06 Ver.1.5 Y.Shoji ADD Start
    cn_re_lease_times1       CONSTANT NUMBER(1)   :=  1;   -- '�ă��[�X1���'
    cn_re_lease_times2       CONSTANT NUMBER(1)   :=  2;   -- '�ă��[�X2���'
    cn_re_lease_times3       CONSTANT NUMBER(1)   :=  3;   -- '�ă��[�X3���'
-- 2016/09/06 Ver.1.5 Y.Shoji ADD End
-- 2019/10/03 Ver.1.9 Y.Ohishi ADD Start
    cv_lease_class_fin       CONSTANT VARCHAR2(1) := '1';  -- '���{��A�g'
    cv_lease_class_ifrs      CONSTANT VARCHAR2(1) := '2';  -- 'IFRS�A�g'
    cn_const_zero            CONSTANT NUMBER(1)   :=  0;
-- 2019/10/03 Ver.1.9 Y.Ohishi ADD End
-- Ver.1.10 Y.Shoji ADD Start
  cv_const_9                 CONSTANT VARCHAR2(1) := '9';  -- '�ΏۊO'
-- Ver.1.10 Y.Shoji ADD End
--
    --*** ���[�J���ϐ� ***
    ln_payment_frequency     xxcff_contract_headers.payment_frequency%TYPE;  --�x����
-- 2016/09/06 Ver.1.5 Y.Shoji ADD Start
    lt_payment_frequency2    xxcff_pay_planning.payment_frequency%TYPE;  -- �x���񐔁i�ă��[�X�p�j
    lt_contract_line_id      xxcff_pay_planning.contract_line_id%TYPE;   -- �_�񖾍ד���ID
-- 2016/09/06 Ver.1.5 Y.Shoji ADD End
-- 2019/10/03 Ver.1.9 Y.Ohishi ADD Start
    lv_lease_class           VARCHAR2(2);    -- ���[�X���
    lv_ret_dff4              VARCHAR2(1);    -- ���[�X����DFF4
    lv_ret_dff5              VARCHAR2(1);    -- ���[�X����DFF5
    lv_ret_dff6              VARCHAR2(1);    -- ���[�X����DFF6
    lv_ret_dff7              VARCHAR2(1);    -- ���[�X����DFF7
-- 2019/10/03 Ver.1.9 Y.Ohishi ADD End
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    CURSOR pay_data_cur
    IS
      SELECT xpp.payment_frequency
      FROM   xxcff_pay_planning xpp
-- 2016/09/06 Ver.1.5 Y.Shoji MOD Start
--      WHERE  xpp.contract_line_id   =  in_contract_line_id
--      AND    xpp.payment_frequency  >= ln_payment_frequency
      WHERE  ( xpp.contract_line_id   =  in_contract_line_id
-- 2019/10/03 Ver.1.9 Y.Ohishi ADD Start
        AND    lv_ret_dff7            =  cv_lease_class_fin
-- Ver.1.10 Y.Shoji MOD Start
--        AND    xpp.payment_match_flag =  cv_const_0
        AND    xpp.payment_match_flag IN  (cv_const_0 ,cv_const_9)
-- Ver.1.10 Y.Shoji MOD End
-- 2019/10/03 Ver.1.9 Y.Ohishi ADD End
        AND    xpp.payment_frequency  >= ln_payment_frequency)
-- 2019/10/03 Ver.1.9 Y.Ohishi ADD Start
      OR     ( xpp.contract_line_id   =  in_contract_line_id
        AND    lv_ret_dff7            =  cv_lease_class_ifrs
        AND    xpp.payment_frequency  >  ln_payment_frequency)
-- 2019/10/03 Ver.1.9 Y.Ohishi ADD End
-- 2019/10/03 Ver.1.9 Y.Ohishi MOD Start
--      OR     ( lt_payment_frequency2  IS NOT NULL
      OR     ( lt_payment_frequency2  <> cn_const_zero
-- 2019/10/03 Ver.1.9 Y.Ohishi MOD End
        AND    xpp.contract_line_id   =  lt_contract_line_id
        AND    xpp.payment_frequency  >  lt_payment_frequency2)
-- 2016/09/06 Ver.1.5 Y.Shoji MOD End
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
-- == 2011/12/19 V1.3 Modified START ===================================================================================
--    AND    xpp.period_name        >= TO_CHAR(gd_process_date,'YYYY-MM');
    AND    xpp.period_name        >= TO_CHAR(gd_cancellation_date,'YYYY-MM');
-- == 2011/12/19 V1.3 Modified END   ===================================================================================
--    
    --�x���񐔂��擾�ł��Ȃ��ꍇ�͂O��ݒ肷��
    ln_payment_frequency  := NVL(ln_payment_frequency,0);
--
-- 2016/09/06 Ver.1.5 Y.Shoji MOD Start
--    --�Y���f�[�^�����݂��Ȃ��ꍇ
--    IF (ln_payment_frequency = 0) THEN
--      RETURN;  
--    END IF;
    -- ***************************************************
    -- 2.���[�X��ʂ�11�A���[�X�敪��2�A�ă��[�X�񐔂�1�`3�̏ꍇ�A
    --   ���_�񕪂̎x���񐔂�MIN�l���擾����
    -- ***************************************************
    lt_payment_frequency2  := 0;
--
    IF (  gn_lease_class    =  cv_lease_class11 
      AND gn_lease_type     =  cv_lease_type2
      AND gt_re_lease_times IN (cn_re_lease_times1 ,cn_re_lease_times2 ,cn_re_lease_times3) ) THEN
--
      BEGIN
        SELECT xpp.contract_line_id
              ,MIN(xpp.payment_frequency)
        INTO   lt_contract_line_id
              ,lt_payment_frequency2
        FROM   xxcff_pay_planning      xpp   -- ���[�X�x���v��
              ,xxcff_contract_headers  xch   -- ���[�X�_��w�b�_
              ,xxcff_contract_lines    xcl1  -- ���[�X�_�񖾍�1�i���_��j
              ,xxcff_contract_lines    xcl2  -- ���[�X�_�񖾍�2�i�ă��[�X�j
        WHERE  xcl2.contract_line_id   =  in_contract_line_id     -- ���͍���. �_�񖾍ד���ID
        AND    xcl2.object_header_id   =  xcl1.object_header_id
        AND    xcl1.contract_header_id =  xch.contract_header_id
        AND    xch.lease_type          =  cv_lease_type1                                  -- ���_��
        AND    xcl1.contract_line_id   =  xpp.contract_line_id
        AND    xpp.period_name         >= TO_CHAR(gd_cancellation_date ,cv_format_yyyymm) -- ���r����
        AND    xpp.accounting_if_flag  =  cv_accounting_if_flag1                          -- �����M
        GROUP BY xpp.contract_line_id
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          --�x���񐔂��擾�ł��Ȃ��ꍇ��0��ݒ肷��
          lt_payment_frequency2  := NVL(lt_payment_frequency2 ,0);
      END;
    END IF;
--
    --�Y���f�[�^�����݂��Ȃ��ꍇ
    IF (ln_payment_frequency = 0 AND lt_payment_frequency2 = 0) THEN
      RETURN;  
    END IF;
-- 2016/09/06 Ver.1.5 Y.Shoji MOD End
-- 2019/10/03 Ver.1.9 Y.Ohishi ADD Start
    lv_lease_class := gn_lease_class;
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
    --  ���[�X���菈�� 
    xxcff_common2_pkg.get_lease_class_info(
        iv_lease_class  =>  lv_lease_class
      , ov_ret_dff4     =>  lv_ret_dff4           --  DFF4(���{��A�g)
      , ov_ret_dff5     =>  lv_ret_dff5           --  DFF5(IFRS�A�g)
      , ov_ret_dff6     =>  lv_ret_dff6           --  DFF6(�d��쐬)
      , ov_ret_dff7     =>  lv_ret_dff7           --  DFF7(���[�X���菈��)
      , ov_errbuf       =>  lv_errbuf
      , ov_retcode      =>  lv_retcode
      , ov_errmsg       =>  lv_errmsg
     );
    -- ���ʊ֐��G���[�̏ꍇ
    IF (lv_retcode <> cv_status_normal) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_app_kbn_cff,      -- �A�v���P�[�V�����Z�k���FXXCFF
                                                     cv_msg_cff_00094,    -- ���b�Z�[�W�F���ʊ֐��G���[
                                                     cv_tk_cff_00094_01,  -- ���ʊ֐���
                                                     cv_msg_cff_50323  )  -- �t�@�C��ID
                                                    || cv_msg_part
                                                    || lv_errmsg          --���ʊ֐���װү����
                                                    ,1
                                                    ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
-- 2019/10/03 Ver.1.9 Y.Ohishi ADD End
--
    -- ***************************************************
    -- 3.���[�X�x���v������b�N����
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
    -- 4.���[�X�x���v���ΏۊO�ɂ���
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
-- 2016/09/06 Ver.1.5 Y.Shoji MOD Start
--    WHERE  xpp.contract_line_id        = in_contract_line_id
-- 00000417 2009/07/09 ADD START
--      AND    xpp.payment_match_flag =  cv_const_0
-- 00000417 2009/07/09 ADD END
--    AND    xpp.payment_frequency      >= ln_payment_frequency;
    WHERE  ( xpp.contract_line_id   =  in_contract_line_id
-- 2019/10/03 Ver.1.9 Y.Ohishi ADD Start
      AND    lv_ret_dff7            =  cv_lease_class_fin
-- 2019/10/03 Ver.1.9 Y.Ohishi ADD End
-- Ver.1.10 Y.Shoji MOD Start
--      AND    xpp.payment_match_flag =  cv_const_0
      AND    xpp.payment_match_flag IN  (cv_const_0 ,cv_const_9)
-- Ver.1.10 Y.Shoji MOD End
      AND    xpp.payment_frequency  >= ln_payment_frequency)
-- 2019/10/03 Ver.1.9 Y.Ohishi ADD Start
    OR     ( xpp.contract_line_id   =  in_contract_line_id
      AND    lv_ret_dff7            =  cv_lease_class_ifrs
      AND    xpp.payment_frequency  >  ln_payment_frequency)
-- 2019/10/03 Ver.1.9 Y.Ohishi ADD End
-- 2019/10/03 Ver.1.9 Y.Ohishi MOD Start
--    OR     ( lt_payment_frequency2  IS NOT NULL
    OR     ( lt_payment_frequency2  <> cn_const_zero
-- 2019/10/03 Ver.1.9 Y.Ohishi MOD End
      AND    xpp.contract_line_id   =  lt_contract_line_id
      AND    xpp.payment_frequency  >  lt_payment_frequency2)
    ;
-- 2016/09/06 Ver.1.5 Y.Shoji MOD End
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
   * Description      : ���[�X�x���v��폜����       (A-8)
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
    -- ���[�X�x���v��쐬����
    -- ==================================
    IF (iv_shori_type = cv_shori_type1) THEN
-- 2016/09/06 Ver.1.5 Y.Shoji MOD Start
--      ins_pat_planning(
--        in_contract_line_id, -- �_�񖾍ד���ID
--        lv_errbuf,           -- �G���[�E���b�Z�[�W           --# �Œ� #
--        lv_retcode,          -- ���^�[���E�R�[�h             --# �Œ� #
--        lv_errmsg);          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      -- ���[�X���:11�i���̋@�j�A���[�X�敪�F1�i���_��j�̏ꍇ
-- 2016/10/26 Ver.1.6 Y.Koh MOD Start
--      IF (  gn_lease_class = cv_lease_class11
--        AND gn_lease_type  = cv_lease_type1  ) THEN
      IF (  gn_lease_class   =  cv_lease_class11
        AND gn_lease_type    =  cv_lease_type1
        AND gd_contract_date >= cd_start_date  ) THEN
-- 2016/10/26 Ver.1.6 Y.Koh MOD End
        -- ==============================================
        -- ���[�X�x���v��쐬���� �i���̋@�E���_��j (A-10)
        -- ==============================================
        ins_pat_plan_class11(
          in_contract_line_id, -- �_�񖾍ד���ID
          lv_errbuf,           -- �G���[�E���b�Z�[�W           --# �Œ� #
          lv_retcode,          -- ���^�[���E�R�[�h             --# �Œ� #
          lv_errmsg);          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      ELSE
        -- ==================================
        -- ���[�X�x���v��쐬����      (A-5)
        -- ==================================
        ins_pat_planning(
          in_contract_line_id, -- �_�񖾍ד���ID
          lv_errbuf,           -- �G���[�E���b�Z�[�W           --# �Œ� #
          lv_retcode,          -- ���^�[���E�R�[�h             --# �Œ� #
          lv_errmsg);          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      END IF;
-- 2016/09/06 Ver.1.5 Y.Shoji MOD End
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
    -- ���[�X�x���v��폜����       (A-8)
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
