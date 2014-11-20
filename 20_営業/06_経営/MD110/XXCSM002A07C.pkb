create or replace PACKAGE BODY XXCSM002A07C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCSM002A07C(body)
 * Description      : ���i�v��Q�ʃ`�F�b�N���X�g�o��
 * MD.050           : ���i�v��Q�ʃ`�F�b�N���X�g�o�� MD050_CSM_002_A07
 * Version          : 1.3
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   ��������(A-1)
 *  chk_plandata           �N�ԏ��i�v��f�[�^���݃`�F�b�N(A-2)
 *  set_gun_name           ���i�Q���̂̎擾����єN�Ԍv�̑e�����Z�o(A-4)
 *  insert_data            ���i�Q�f�[�^�̓o�^(A-5,11)
 *  set_gun_data           ���i�Q�N�ԃf�[�^��ϐ��֐ݒ�(A-6)
 *  set_gun_sum_data       �Q�v�̔N�ԃf�[�^��ϐ��֐ݒ�(A-9)
 *  set_gun_sum_name       �Q�v���̂̎擾����єN�Ԍv�̑e�����Z�o(A-10)
 *  set_kyoten_name        ���_���̂̎擾����єN�Ԍv�̑e�����A���z�Z�o(A-12)
 *  insert_kyoten_data     ���_�v�����i�v��Q�ʃ��[�N�e�[�u���֓o�^(A-13)
 *  set_kyoten_data        ���_�̔N�ԃf�[�^��ϐ��֐ݒ�(A-14)
 *  output_check_list      �`�F�b�N���X�g�f�[�^�o��(A-15)
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008-12-17    1.0   K.Yamada         �V�K�쐬
 *  2009-02-10    1.1   M.Ohtsuki       �m��QCT_005�n�ގ��@�\���쓝��C��
 *  2009-02-16    1.2   M.Ohtsuki       �m��QCT_019�n����0�̕s��̑Ή�
 *  2009-02-23    1.3   K.Yamada        �m��QCT_058�n�e���v���s��̑Ή�
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
  cv_msg_part               CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont               CONSTANT VARCHAR2(3) := '.';
  cv_xxcsm                  CONSTANT VARCHAR2(100) := 'XXCSM'; 
--*** ADD TEMPLETE Start****************************************
  cv_msg_00111              CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00111';       --�z��O�G���[���b�Z�[�W
--*** ADD TEMPLETE Start****************************************
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
  global_data_check_expt    EXCEPTION;     -- �f�[�^���݃`�F�b�N
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name      CONSTANT VARCHAR2(100) := 'XXCSM002A07C';                 -- �p�b�P�[�W��
  cv_flg_y         CONSTANT VARCHAR2(1)   := 'Y';                            -- �t���OY

  --���b�Z�[�W�[�R�[�h
  cv_prof_err_msg  CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00005';             -- �v���t�@�C���擾�G���[
  cv_noplandt_msg  CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00087';             -- ���i�v�斢�ݒ�
  cv_lst_head_msg  CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00091';             -- �N�ԏ��i�v��Q�ʃ`�F�b�N���X�g�w�b�_�p
  cv_nogun_nm_msg  CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00105';             -- ���i�Q���̖��ݒ�
  cv_nokyo_nm_msg  CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00106';             -- ���_���̖��ݒ�
--//+ADD START 2009/02/10   CT005 M.Ohtsuki
  cv_csm1_msg_10003         CONSTANT VARCHAR2(100) := 'APP-XXCSM1-10003';                           -- ���̓p�����[�^�擾���b�Z�[�W(�Ώ۔N�x)
  cv_csm1_msg_00048         CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00048';                           -- ���̓p�����[�^�擾���b�Z�[�W(���_�R�[�h)
--//+ADD END   2009/02/10   CT005 M.Ohtsuki

  --�g�[�N��
  cv_tkn_cd_prof   CONSTANT VARCHAR2(100) := 'PROF_NAME';                    -- �J�X�^���E�v���t�@�C���E�I�v�V�����̉p��
  cv_tkn_cd_tsym   CONSTANT VARCHAR2(100) := 'TAISYOU_YM';                   -- �Ώ۔N�x
  cv_tkn_cd_kyoten CONSTANT VARCHAR2(100) := 'KYOTEN_CD';                    -- ���_�R�[�h
  cv_tkn_nm_kyoten CONSTANT VARCHAR2(100) := 'KYOTEN_NM';                    -- ���_��
  cv_tkn_nichiji   CONSTANT VARCHAR2(100) := 'SAKUSEI_NICHIJI';              -- �쐬����
  cv_tkn_gun_cd    CONSTANT VARCHAR2(100) := 'SHOUHIN_GUN_CD';               -- ���i�Q�R�[�h
--//+ADD START 2009/02/10   CT005 M.Ohtsuki
  cv_tkn_year               CONSTANT VARCHAR2(100) := 'YYYY';                                       -- �Ώ۔N�x
--//+ADD END   2009/02/10   CT005 M.Ohtsuki
  cv_chk2_profile  CONSTANT VARCHAR2(100) := 'XXCSM1_CHECKLIST_ITEM_2';      -- ���X�g���ڃe�L�X�g�i����l���j�v���t�@�C����
  cv_chk3_profile  CONSTANT VARCHAR2(100) := 'XXCSM1_CHECKLIST_ITEM_3';      -- ���X�g���ڃe�L�X�g�i�����l���j�v���t�@�C����
  cv_chk5_profile  CONSTANT VARCHAR2(100) := 'XXCSM1_CHECKLIST_ITEM_5';      -- ���X�g���ڃe�L�X�g�i����\�Z�j�v���t�@�C����
  cv_chk6_profile  CONSTANT VARCHAR2(100) := 'XXCSM1_CHECKLIST_ITEM_6';      -- ���X�g���ڃe�L�X�g�i�e���v�z�j�v���t�@�C����
  cv_chk7_profile  CONSTANT VARCHAR2(100) := 'XXCSM1_CHECKLIST_ITEM_7';      -- ���X�g���ڃe�L�X�g�i�e���v���j�v���t�@�C����
  cv_chk8_profile  CONSTANT VARCHAR2(100) := 'XXCSM1_CHECKLIST_ITEM_8';      -- ���X�g���ڃe�L�X�g�i�l���O����j�v���t�@�C����
  cv_chk9_profile  CONSTANT VARCHAR2(100) := 'XXCSM1_CHECKLIST_ITEM_9';      -- ���X�g���ڃe�L�X�g�i�l���㔄��j�v���t�@�C����
  cv_chk10_profile CONSTANT VARCHAR2(100) := 'XXCSM1_CHECKLIST_ITEM_10';     -- ���X�g���ڃe�L�X�g�i���z�j�v���t�@�C����
  cv_chk11_profile CONSTANT VARCHAR2(100) := 'XXCSM1_CHECKLIST_ITEM_11';     -- ���X�g���ڃe�L�X�g�i�Q�v�j�v���t�@�C����

  cv_lookup_type   CONSTANT VARCHAR2(100) := 'XXCSM1_FORM_PARAMETER_VALUE';  -- �S���_�R�[�h�擾�p

  cv_item_gun      CONSTANT VARCHAR2(1)   := '0';                            -- ���i�敪�i���i�Q�j

  cv_max_margin_rate CONSTANT NUMBER(15,2):= 9999999999999.99;               -- �i�[�ł���ő�e���v��
  cv_max_rate        CONSTANT NUMBER(15,2):= NULL;                           -- ���x�𒴂���ꍇ�̗�

--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  TYPE g_work_gun_rtype IS RECORD(
       group_cd                xxcsm_tmp_item_plan_gun.code%TYPE          -- �R�[�h
      ,group_nm                xxcsm_tmp_item_plan_gun.code_nm%TYPE       -- ����
      ,sales_bf_disc_nm        xxcsm_tmp_item_plan_gun.item_nm%TYPE       -- �l���O���㖼
      ,sales_bf_disc05         xxcsm_tmp_item_plan_gun.total%TYPE         -- �l���O����T��
      ,sales_bf_disc06         xxcsm_tmp_item_plan_gun.total%TYPE         -- �l���O����U��
      ,sales_bf_disc07         xxcsm_tmp_item_plan_gun.total%TYPE         -- �l���O����V��
      ,sales_bf_disc08         xxcsm_tmp_item_plan_gun.total%TYPE         -- �l���O����W��
      ,sales_bf_disc09         xxcsm_tmp_item_plan_gun.total%TYPE         -- �l���O����X��
      ,sales_bf_disc10         xxcsm_tmp_item_plan_gun.total%TYPE         -- �l���O����P�O��
      ,sales_bf_disc11         xxcsm_tmp_item_plan_gun.total%TYPE         -- �l���O����P�P��
      ,sales_bf_disc12         xxcsm_tmp_item_plan_gun.total%TYPE         -- �l���O����P�Q��
      ,sales_bf_disc01         xxcsm_tmp_item_plan_gun.total%TYPE         -- �l���O����P��
      ,sales_bf_disc02         xxcsm_tmp_item_plan_gun.total%TYPE         -- �l���O����Q��
      ,sales_bf_disc03         xxcsm_tmp_item_plan_gun.total%TYPE         -- �l���O����R��
      ,sales_bf_disc04         xxcsm_tmp_item_plan_gun.total%TYPE         -- �l���O����S��
      ,sales_bf_disc_total     xxcsm_tmp_item_plan_gun.total%TYPE         -- �l���O����N�Ԍv
      ,sales_af_disc_nm        xxcsm_tmp_item_plan_gun.item_nm%TYPE       -- �l���㔄�㖼
      ,sales_af_disc05         xxcsm_tmp_item_plan_gun.total%TYPE         -- �l���㔄��T��
      ,sales_af_disc06         xxcsm_tmp_item_plan_gun.total%TYPE         -- �l���㔄��U��
      ,sales_af_disc07         xxcsm_tmp_item_plan_gun.total%TYPE         -- �l���㔄��V��
      ,sales_af_disc08         xxcsm_tmp_item_plan_gun.total%TYPE         -- �l���㔄��W��
      ,sales_af_disc09         xxcsm_tmp_item_plan_gun.total%TYPE         -- �l���㔄��X��
      ,sales_af_disc10         xxcsm_tmp_item_plan_gun.total%TYPE         -- �l���㔄��P�O��
      ,sales_af_disc11         xxcsm_tmp_item_plan_gun.total%TYPE         -- �l���㔄��P�P��
      ,sales_af_disc12         xxcsm_tmp_item_plan_gun.total%TYPE         -- �l���㔄��P�Q��
      ,sales_af_disc01         xxcsm_tmp_item_plan_gun.total%TYPE         -- �l���㔄��P��
      ,sales_af_disc02         xxcsm_tmp_item_plan_gun.total%TYPE         -- �l���㔄��Q��
      ,sales_af_disc03         xxcsm_tmp_item_plan_gun.total%TYPE         -- �l���㔄��R��
      ,sales_af_disc04         xxcsm_tmp_item_plan_gun.total%TYPE         -- �l���㔄��S��
      ,sales_af_disc_total     xxcsm_tmp_item_plan_gun.total%TYPE         -- �l���㔄��N�Ԍv
      ,sales_disc_nm           xxcsm_tmp_item_plan_gun.item_nm%TYPE       -- ����l����
      ,sales_disc05            xxcsm_tmp_item_plan_gun.total%TYPE         -- ����l���T��
      ,sales_disc06            xxcsm_tmp_item_plan_gun.total%TYPE         -- ����l���U��
      ,sales_disc07            xxcsm_tmp_item_plan_gun.total%TYPE         -- ����l���V��
      ,sales_disc08            xxcsm_tmp_item_plan_gun.total%TYPE         -- ����l���W��
      ,sales_disc09            xxcsm_tmp_item_plan_gun.total%TYPE         -- ����l���X��
      ,sales_disc10            xxcsm_tmp_item_plan_gun.total%TYPE         -- ����l���P�O��
      ,sales_disc11            xxcsm_tmp_item_plan_gun.total%TYPE         -- ����l���P�P��
      ,sales_disc12            xxcsm_tmp_item_plan_gun.total%TYPE         -- ����l���P�Q��
      ,sales_disc01            xxcsm_tmp_item_plan_gun.total%TYPE         -- ����l���P��
      ,sales_disc02            xxcsm_tmp_item_plan_gun.total%TYPE         -- ����l���Q��
      ,sales_disc03            xxcsm_tmp_item_plan_gun.total%TYPE         -- ����l���R��
      ,sales_disc04            xxcsm_tmp_item_plan_gun.total%TYPE         -- ����l���S��
      ,sales_disc_total        xxcsm_tmp_item_plan_gun.total%TYPE         -- ����l���N�Ԍv
      ,receipt_disc_nm         xxcsm_tmp_item_plan_gun.item_nm%TYPE       -- �����l����
      ,receipt_disc05          xxcsm_tmp_item_plan_gun.total%TYPE         -- �����l���T��
      ,receipt_disc06          xxcsm_tmp_item_plan_gun.total%TYPE         -- �����l���U��
      ,receipt_disc07          xxcsm_tmp_item_plan_gun.total%TYPE         -- �����l���V��
      ,receipt_disc08          xxcsm_tmp_item_plan_gun.total%TYPE         -- �����l���W��
      ,receipt_disc09          xxcsm_tmp_item_plan_gun.total%TYPE         -- �����l���X��
      ,receipt_disc10          xxcsm_tmp_item_plan_gun.total%TYPE         -- �����l���P�O��
      ,receipt_disc11          xxcsm_tmp_item_plan_gun.total%TYPE         -- �����l���P�P��
      ,receipt_disc12          xxcsm_tmp_item_plan_gun.total%TYPE         -- �����l���P�Q��
      ,receipt_disc01          xxcsm_tmp_item_plan_gun.total%TYPE         -- �����l���P��
      ,receipt_disc02          xxcsm_tmp_item_plan_gun.total%TYPE         -- �����l���Q��
      ,receipt_disc03          xxcsm_tmp_item_plan_gun.total%TYPE         -- �����l���R��
      ,receipt_disc04          xxcsm_tmp_item_plan_gun.total%TYPE         -- �����l���S��
      ,receipt_disc_total      xxcsm_tmp_item_plan_gun.total%TYPE         -- �����l���N�Ԍv
      ,sales_budget_nm         xxcsm_tmp_item_plan_gun.item_nm%TYPE       -- ����\�Z��
      ,sales_budget05          xxcsm_tmp_item_plan_gun.total%TYPE         -- ����\�Z�T��
      ,sales_budget06          xxcsm_tmp_item_plan_gun.total%TYPE         -- ����\�Z�U��
      ,sales_budget07          xxcsm_tmp_item_plan_gun.total%TYPE         -- ����\�Z�V��
      ,sales_budget08          xxcsm_tmp_item_plan_gun.total%TYPE         -- ����\�Z�W��
      ,sales_budget09          xxcsm_tmp_item_plan_gun.total%TYPE         -- ����\�Z�X��
      ,sales_budget10          xxcsm_tmp_item_plan_gun.total%TYPE         -- ����\�Z�P�O��
      ,sales_budget11          xxcsm_tmp_item_plan_gun.total%TYPE         -- ����\�Z�P�P��
      ,sales_budget12          xxcsm_tmp_item_plan_gun.total%TYPE         -- ����\�Z�P�Q��
      ,sales_budget01          xxcsm_tmp_item_plan_gun.total%TYPE         -- ����\�Z�P��
      ,sales_budget02          xxcsm_tmp_item_plan_gun.total%TYPE         -- ����\�Z�Q��
      ,sales_budget03          xxcsm_tmp_item_plan_gun.total%TYPE         -- ����\�Z�R��
      ,sales_budget04          xxcsm_tmp_item_plan_gun.total%TYPE         -- ����\�Z�S��
      ,sales_budget_total      xxcsm_tmp_item_plan_gun.total%TYPE         -- ����\�Z�N�Ԍv
      ,margin_nm               xxcsm_tmp_item_plan_gun.item_nm%TYPE       -- �e���v�z��
      ,margin05                xxcsm_tmp_item_plan_gun.total%TYPE         -- �e���v�z�T��
      ,margin06                xxcsm_tmp_item_plan_gun.total%TYPE         -- �e���v�z�U��
      ,margin07                xxcsm_tmp_item_plan_gun.total%TYPE         -- �e���v�z�V��
      ,margin08                xxcsm_tmp_item_plan_gun.total%TYPE         -- �e���v�z�W��
      ,margin09                xxcsm_tmp_item_plan_gun.total%TYPE         -- �e���v�z�X��
      ,margin10                xxcsm_tmp_item_plan_gun.total%TYPE         -- �e���v�z�P�O��
      ,margin11                xxcsm_tmp_item_plan_gun.total%TYPE         -- �e���v�z�P�P��
      ,margin12                xxcsm_tmp_item_plan_gun.total%TYPE         -- �e���v�z�P�Q��
      ,margin01                xxcsm_tmp_item_plan_gun.total%TYPE         -- �e���v�z�P��
      ,margin02                xxcsm_tmp_item_plan_gun.total%TYPE         -- �e���v�z�Q��
      ,margin03                xxcsm_tmp_item_plan_gun.total%TYPE         -- �e���v�z�R��
      ,margin04                xxcsm_tmp_item_plan_gun.total%TYPE         -- �e���v�z�S��
      ,margin_total            xxcsm_tmp_item_plan_gun.total%TYPE         -- �e���v�z�N�Ԍv
      ,margin_rate_nm          xxcsm_tmp_item_plan_gun.item_nm%TYPE       -- �e���v����
      ,margin_rate05           xxcsm_tmp_item_plan_gun.total%TYPE         -- �e���v���T��
      ,margin_rate06           xxcsm_tmp_item_plan_gun.total%TYPE         -- �e���v���U��
      ,margin_rate07           xxcsm_tmp_item_plan_gun.total%TYPE         -- �e���v���V��
      ,margin_rate08           xxcsm_tmp_item_plan_gun.total%TYPE         -- �e���v���W��
      ,margin_rate09           xxcsm_tmp_item_plan_gun.total%TYPE         -- �e���v���X��
      ,margin_rate10           xxcsm_tmp_item_plan_gun.total%TYPE         -- �e���v���P�O��
      ,margin_rate11           xxcsm_tmp_item_plan_gun.total%TYPE         -- �e���v���P�P��
      ,margin_rate12           xxcsm_tmp_item_plan_gun.total%TYPE         -- �e���v���P�Q��
      ,margin_rate01           xxcsm_tmp_item_plan_gun.total%TYPE         -- �e���v���P��
      ,margin_rate02           xxcsm_tmp_item_plan_gun.total%TYPE         -- �e���v���Q��
      ,margin_rate03           xxcsm_tmp_item_plan_gun.total%TYPE         -- �e���v���R��
      ,margin_rate04           xxcsm_tmp_item_plan_gun.total%TYPE         -- �e���v���S��
      ,margin_rate_total       xxcsm_tmp_item_plan_gun.total%TYPE         -- �e���v���N�Ԍv
      ,sagaku_nm               xxcsm_tmp_item_plan_gun.item_nm%TYPE       -- ���z��
      ,sagaku05                xxcsm_tmp_item_plan_gun.total%TYPE         -- ���z�T��
      ,sagaku06                xxcsm_tmp_item_plan_gun.total%TYPE         -- ���z�U��
      ,sagaku07                xxcsm_tmp_item_plan_gun.total%TYPE         -- ���z�V��
      ,sagaku08                xxcsm_tmp_item_plan_gun.total%TYPE         -- ���z�W��
      ,sagaku09                xxcsm_tmp_item_plan_gun.total%TYPE         -- ���z�X��
      ,sagaku10                xxcsm_tmp_item_plan_gun.total%TYPE         -- ���z�P�O��
      ,sagaku11                xxcsm_tmp_item_plan_gun.total%TYPE         -- ���z�P�P��
      ,sagaku12                xxcsm_tmp_item_plan_gun.total%TYPE         -- ���z�P�Q��
      ,sagaku01                xxcsm_tmp_item_plan_gun.total%TYPE         -- ���z�P��
      ,sagaku02                xxcsm_tmp_item_plan_gun.total%TYPE         -- ���z�Q��
      ,sagaku03                xxcsm_tmp_item_plan_gun.total%TYPE         -- ���z�R��
      ,sagaku04                xxcsm_tmp_item_plan_gun.total%TYPE         -- ���z�S��
      ,sagaku_total            xxcsm_tmp_item_plan_gun.total%TYPE         -- ���z�N�Ԍv
   );
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gd_sysdate           DATE;
  gt_allkyoten_cd      fnd_lookup_values.lookup_code%TYPE;     -- �S���_�R�[�h
  gv_sales_disc_nm     xxcsm_tmp_item_plan_gun.item_nm%TYPE;   -- �`�F�b�N���X�g���ږ��i����l���j
  gv_receipt_disc_nm   xxcsm_tmp_item_plan_gun.item_nm%TYPE;   -- �`�F�b�N���X�g���ږ��i�����l���j
  gv_sales_budget_nm   xxcsm_tmp_item_plan_gun.item_nm%TYPE;   -- �`�F�b�N���X�g���ږ��i����\�Z�j
  gv_margin_amt_nm     xxcsm_tmp_item_plan_gun.item_nm%TYPE;   -- �`�F�b�N���X�g���ږ��i�e���v�z�j
  gv_margin_rate_nm    xxcsm_tmp_item_plan_gun.item_nm%TYPE;   -- �`�F�b�N���X�g���ږ��i�e���v���j
  gv_sales_bf_disc_nm  xxcsm_tmp_item_plan_gun.item_nm%TYPE;   -- �`�F�b�N���X�g���ږ��i�l���O����j
  gv_sales_af_disc_nm  xxcsm_tmp_item_plan_gun.item_nm%TYPE;   -- �`�F�b�N���X�g���ږ��i�l���㔄��j
  gv_sagaku_nm         xxcsm_tmp_item_plan_gun.item_nm%TYPE;   -- �`�F�b�N���X�g���ږ��i���z�j
  gv_total_gun_nm      xxcsm_tmp_item_plan_gun.item_nm%TYPE;   -- �`�F�b�N���X�g���ږ��i�Q�v�j
  gb_all_kyoten        BOOLEAN;                                -- �S���_�`�F�b�N
--
  -- ===============================
  -- ���[�J���E�J�[�\��
  -- ===============================
  -- ���i�Q�f�[�^(A-3)
  CURSOR item_gun_cur(
    in_yyyy         IN  NUMBER,         -- 1.�Ώ۔N�x
    iv_kyoten_cd    IN  VARCHAR2)       -- 2.���_�R�[�h
  IS
    SELECT
       iph.plan_year                    plan_year      -- �\�Z�N�x
      ,iph.location_cd                  location_cd    -- ���_�R�[�h
      ,ipl.item_group_no                group_cd       -- ���i�Q�R�[�h
      ,ipl.month_no                     month_no       -- ��
      ,NVL(ipl.sales_budget, 0)         sales_budget   -- ������z
      ,NVL(ipl.amount_gross_margin, 0)  margin         -- �e���v(�V)
    FROM
      xxcsm_item_plan_headers    iph,           -- ���i�v��w�b�_�e�[�u��
      xxcsm_item_plan_lines      ipl            -- ���i�v�斾�׃e�[�u��
    WHERE
      iph.item_plan_header_id  = ipl.item_plan_header_id
    AND
      iph.plan_year            = in_yyyy
    AND
      iph.location_cd          = iv_kyoten_cd
    AND
      ipl.item_kbn             = cv_item_gun
    ORDER BY
       ipl.item_group_no         -- ���i�Q�R�[�h
      ,ipl.year_month            -- �N��
    ;
    -- ���i�Q�f�[�^���R�[�h�^
    item_gun_rec                 item_gun_cur%ROWTYPE;

  -- ���_�f�[�^(A-7)
  CURSOR kyoten_cur(
    in_yyyy          IN  NUMBER,         -- 1.�Ώ۔N�x
    iv_kyoten_cd     IN  VARCHAR2,       -- 2.���_�R�[�h
    iv_all_kyoten_cd IN  VARCHAR2)       -- 3.���_�R�[�h
  IS
    SELECT
       iph.plan_year             plan_year      -- �\�Z�N�x
      ,iph.location_cd           location_cd    -- ���_�R�[�h
      ,ipl.month_no              month_no       -- ��
      ,NVL(SUM(ipl.amount_gross_margin), 0)     margin               -- �e���v(�V)
      ,NVL(ipb.sales_discount, 0)               sales_disc           -- ����l��
      ,NVL(ipb.receipt_discount, 0)             receipt_disc         -- �����l��
      ,NVL(ipb.sales_budget, 0)                 sales_af_disc        -- �l���㔄��
      ,NVL(ipb.sales_budget, 0)                 -- �l���㔄��
        - NVL(ipb.sales_discount, 0)            -- ����l��
        - NVL(ipb.receipt_discount, 0)          -- �����l��
                                                sales_bf_disc        -- �l���O����
    FROM
       xxcsm_item_plan_headers   iph            -- ���i�v��w�b�_�e�[�u��
      ,xxcsm_item_plan_lines     ipl            -- ���i�v�斾�׃e�[�u��
      ,xxcsm_item_plan_loc_bdgt  ipb            -- ���i�v�拒�_�ʗ\�Z�e�[�u��
    WHERE
      iph.item_plan_header_id  = ipl.item_plan_header_id
    AND
      iph.item_plan_header_id  = ipb.item_plan_header_id
    AND
      iph.plan_year   = in_yyyy
    AND
      ipb.month_no    = ipl.month_no
    AND
      iph.location_cd = DECODE(iv_kyoten_cd, iv_all_kyoten_cd, iph.location_cd, iv_kyoten_cd)
    AND
      ipl.item_kbn    = cv_item_gun
    GROUP BY
       iph.plan_year             -- �\�Z�N�x
      ,iph.location_cd           -- ���_�R�[�h
      ,ipl.month_no              -- ��
      ,ipb.sales_discount        -- ����l��
      ,ipb.receipt_discount      -- �����l��
      ,ipb.sales_budget          -- ����\�Z
    ORDER BY
       iph.plan_year             -- �\�Z�N�x
      ,iph.location_cd           -- ���_�R�[�h
      ,ipl.month_no              -- ��
    ;
    -- ���_�f�[�^���R�[�h�^
    kyoten_rec                   kyoten_cur%ROWTYPE;
--

  -- �Q�v�f�[�^(A-8)
  CURSOR item_gun_sum_cur(
    in_yyyy         IN  NUMBER,         -- 1.�Ώ۔N�x
    iv_kyoten_cd    IN  VARCHAR2)       -- 2.���_�R�[�h
  IS
    SELECT
       iph.plan_year                         plan_year       -- �\�Z�N�x
      ,iph.location_cd                       location_cd     -- ���_�R�[�h
      ,ipl.month_no                          month_no        -- ��
      ,NVL(SUM(ipl.sales_budget), 0)         sales_budget    -- ������z
      ,NVL(SUM(ipl.amount_gross_margin), 0)  margin          -- �e���v(�V)
    FROM
      xxcsm_item_plan_headers    iph,   --���i�v��w�b�_�e�[�u��
      xxcsm_item_plan_lines      ipl    --���i�v�斾�׃e�[�u��
    WHERE
      iph.item_plan_header_id    = ipl.item_plan_header_id
    AND
      iph.plan_year              = in_yyyy
    AND
      iph.location_cd            = iv_kyoten_cd
    AND
      ipl.item_kbn               = cv_item_gun
    GROUP BY
       iph.plan_year             -- �\�Z�N�x
      ,iph.location_cd           -- ���_�R�[�h
      ,ipl.month_no              -- ��
    ORDER BY
       iph.plan_year             -- �\�Z�N�x
      ,iph.location_cd           -- ���_�R�[�h
      ,ipl.month_no              -- ��
    ;
    -- �Q�v�f�[�^���R�[�h�^
    item_gun_sum_rec             item_gun_sum_cur%ROWTYPE;

  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    iv_yyyy       IN  VARCHAR2,            -- 1.�Ώ۔N�x
    iv_kyoten_cd  IN  VARCHAR2,            -- 2.���_�R�[�h
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
--
    -- *** ���[�J���ϐ� ***
    lv_pram_op      VARCHAR2(100);     -- �p�����[�^���b�Z�[�W�o��
    ld_process_date DATE;              -- �Ɩ����t
--//+ADD START 2009/02/10   CT005 M.Ohtsuki
    lv_pram_op_1            VARCHAR2(100);                                                          --�p�����[�^�o�͗p
    lv_pram_op_2            VARCHAR2(100);                                                          --�p�����[�^�o�͗p
--//+ADD END 2009/02/10   CT005 M.Ohtsuki
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
--//+ADD START 2009/02/10   CT005 M.Ohtsuki
    lv_pram_op_1 := xxccp_common_pkg.get_msg(                                                       -- ���_�R�[�h�̏o��
                      iv_application  => cv_xxcsm                                                   -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_csm1_msg_10003                                          -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_year                                                -- �g�[�N���R�[�h1�i�Ώ۔N�x�j
                     ,iv_token_value1 => iv_yyyy                                                    -- �g�[�N���l1
                     );
    lv_pram_op_2 := xxccp_common_pkg.get_msg(                                                       -- �Ώ۔N�x�̏o��
                      iv_application  => cv_xxcsm                                                   -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_csm1_msg_00048                                          -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_cd_kyoten                                           -- �g�[�N���R�[�h1(���_�R�[�h�j
                     ,iv_token_value1 => iv_kyoten_cd                                               -- �g�[�N���l1
                     );
    fnd_file.put_line(
                      which  => FND_FILE.LOG                                                        -- ���O�ɕ\��
                     ,buff   => lv_pram_op_1  || CHR(10) ||
                                lv_pram_op_2  || CHR(10) ||
                                ''            || CHR(10)                                            -- ��s�̑}��
                                );
--//+ADD END 2009/02/10   CT005 M.Ohtsuki
    -- ===========================
    -- �V�X�e�����t�擾���� 
    -- ===========================
    gd_sysdate := SYSDATE;
    -- =====================
    -- �Ɩ��������t�擾���� 
    -- =====================
    ld_process_date := xxccp_common_pkg2.get_process_date;
--
    -- =====================
    -- �v���t�@�C���擾���� 
    -- =====================
    --���X�g���ڃe�L�X�g�i����l���j�擾
    gv_sales_disc_nm := FND_PROFILE.VALUE(cv_chk2_profile);
    IF (gv_sales_disc_nm IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                                            iv_application  => cv_xxcsm
                                           ,iv_name         => cv_prof_err_msg
                                           ,iv_token_name1  => cv_tkn_cd_prof
                                           ,iv_token_value1 => cv_chk2_profile
                                           );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;

    --���X�g���ڃe�L�X�g�i�����l���j�擾
    gv_receipt_disc_nm := FND_PROFILE.VALUE(cv_chk3_profile);
    IF (gv_receipt_disc_nm IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                                            iv_application  => cv_xxcsm
                                           ,iv_name         => cv_prof_err_msg
                                           ,iv_token_name1  => cv_tkn_cd_prof
                                           ,iv_token_value1 => cv_chk3_profile
                                           );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;

    --���X�g���ڃe�L�X�g�i����\�Z�j�擾
    gv_sales_budget_nm := FND_PROFILE.VALUE(cv_chk5_profile);
    IF (gv_sales_budget_nm IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                                            iv_application  => cv_xxcsm
                                           ,iv_name         => cv_prof_err_msg
                                           ,iv_token_name1  => cv_tkn_cd_prof
                                           ,iv_token_value1 => cv_chk5_profile
                                           );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;

    --���X�g���ڃe�L�X�g�i�e���v�z�j�擾
    gv_margin_amt_nm := FND_PROFILE.VALUE(cv_chk6_profile);
    IF (gv_margin_amt_nm IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                                            iv_application  => cv_xxcsm
                                           ,iv_name         => cv_prof_err_msg
                                           ,iv_token_name1  => cv_tkn_cd_prof
                                           ,iv_token_value1 => cv_chk6_profile
                                           );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;

    --���X�g���ڃe�L�X�g�i�e���v���j�擾
    gv_margin_rate_nm := FND_PROFILE.VALUE(cv_chk7_profile);
    IF (gv_margin_rate_nm IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                                            iv_application  => cv_xxcsm
                                           ,iv_name         => cv_prof_err_msg
                                           ,iv_token_name1  => cv_tkn_cd_prof
                                           ,iv_token_value1 => cv_chk7_profile
                                           );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;

    --���i�v�惊�X�g���ږ��i�l���O����j�擾
    gv_sales_bf_disc_nm := FND_PROFILE.VALUE(cv_chk8_profile);
    IF (gv_sales_bf_disc_nm IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                                            iv_application  => cv_xxcsm
                                           ,iv_name         => cv_prof_err_msg
                                           ,iv_token_name1  => cv_tkn_cd_prof
                                           ,iv_token_value1 => cv_chk8_profile
                                           );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;

    --���i�v�惊�X�g���ږ��i�l���㔄��j�擾
    gv_sales_af_disc_nm := FND_PROFILE.VALUE(cv_chk9_profile);
    IF (gv_sales_af_disc_nm IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                                            iv_application  => cv_xxcsm
                                           ,iv_name         => cv_prof_err_msg
                                           ,iv_token_name1  => cv_tkn_cd_prof
                                           ,iv_token_value1 => cv_chk9_profile
                                           );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;

    --���i�v�惊�X�g���ږ��i���z�j�擾
    gv_sagaku_nm := FND_PROFILE.VALUE(cv_chk10_profile);
    IF (gv_sagaku_nm IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                                            iv_application  => cv_xxcsm
                                           ,iv_name         => cv_prof_err_msg
                                           ,iv_token_name1  => cv_tkn_cd_prof
                                           ,iv_token_value1 => cv_chk10_profile
                                           );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;

    --���i�v�惊�X�g���ږ��i�Q�v�j�擾
    gv_total_gun_nm := FND_PROFILE.VALUE(cv_chk11_profile);
    IF (gv_total_gun_nm IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                                            iv_application  => cv_xxcsm
                                           ,iv_name         => cv_prof_err_msg
                                           ,iv_token_name1  => cv_tkn_cd_prof
                                           ,iv_token_value1 => cv_chk11_profile
                                           );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;

--
    -- =====================
    -- �S���_�R�[�h�擾���� 
    -- =====================
    SELECT
      flv.lookup_code     allkyoten_cd
    INTO
      gt_allkyoten_cd
    FROM
      fnd_lookup_values  flv --�N�C�b�N�R�[�h�l
    WHERE
      flv.lookup_type = cv_lookup_type
    AND
      (flv.start_date_active <= ld_process_date OR flv.start_date_active IS NULL)
    AND
      (flv.end_date_active >= ld_process_date OR flv.end_date_active IS NULL)
    AND
      flv.enabled_flag = cv_flg_y
    AND
      ROWNUM = 1
    ;

    IF iv_kyoten_cd = gt_allkyoten_cd THEN
      gb_all_kyoten := TRUE;
    ELSE
      gb_all_kyoten := FALSE;
    END IF;

--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
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
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END init;
--
  /**********************************************************************************
   * Procedure Name   : chk_plandata
   * Description      : �N�ԏ��i�v��f�[�^���݃`�F�b�N(A-2)
   ***********************************************************************************/
  PROCEDURE chk_plandata(
    iv_yyyy       IN  VARCHAR2,            -- 1.�Ώ۔N�x
    iv_kyoten_cd  IN  VARCHAR2,            -- 2.���_�R�[�h
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_plandata'; -- �v���O������
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
    ln_cnt           NUMBER;
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
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    SELECT
      COUNT(ipl.item_plan_header_id)    cnt
    INTO
      ln_cnt
    FROM
       xxcsm_item_plan_headers  iph   --���i�v��w�b�_�e�[�u��
      ,xxcsm_item_plan_lines    ipl   --���i�v�斾�׃e�[�u��
      ,xxcsm_item_plan_result   ipr   --���i�v��p�̔����уe�[�u��
    WHERE
        iph.item_plan_header_id = ipl.item_plan_header_id
    AND iph.plan_year           = TO_NUMBER(iv_yyyy)
    AND iph.location_cd         = ipr.location_cd
    AND ipr.location_cd         = DECODE(iv_kyoten_cd, gt_allkyoten_cd, ipr.location_cd, iv_kyoten_cd)
    AND ipl.item_kbn            = cv_item_gun
    AND ROWNUM = 1;

    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
    IF (ln_cnt = 0) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                                            iv_application  => cv_xxcsm
                                           ,iv_name         => cv_noplandt_msg
                                           ,iv_token_name1  => cv_tkn_cd_tsym
                                           ,iv_token_value1 => iv_yyyy
                                           ,iv_token_name2  => cv_tkn_cd_kyoten
                                           ,iv_token_value2 => iv_kyoten_cd
                                           );
      RAISE global_data_check_expt;
    END IF;

--
  EXCEPTION
    -- *** �f�[�^���݃`�F�b�N�G���[ ***
    WHEN global_data_check_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000);
      ov_retcode := cv_status_warn;
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
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END chk_plandata;
--
  /**********************************************************************************
   * Procedure Name   : set_gun_name
   * Description      : ���i�Q���̂̎擾����єN�Ԍv�̑e�����Z�o(A-4)
   ***********************************************************************************/
  PROCEDURE set_gun_name(
    ior_work_rec   IN OUT g_work_gun_rtype,                -- ���i�Q�ϐ����R�[�h
    ov_errbuf      OUT NOCOPY VARCHAR2,                    -- �G���[�E���b�Z�[�W
    ov_retcode     OUT NOCOPY VARCHAR2,                    -- ���^�[���E�R�[�h
    ov_errmsg      OUT NOCOPY VARCHAR2)                    -- ���[�U�[�E�G���[�E���b�Z�[�W
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'set_gun_name'; -- �v���O������
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
    ln_margin_rate         NUMBER;                               -- �e���v��
    lv_group_nm            mtl_categories_tl.description%TYPE;   -- ���i�Q����
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

    --���i�Q���̎擾
    BEGIN
      SELECT
        g3v.item_group_nm     group_nm
      INTO
        lv_group_nm
      FROM
        xxcsm_item_group_3_nm_v      g3v           -- ���i�Q3�����̃r���[
      WHERE
        g3v.item_group_cd = ior_work_rec.group_cd  -- ���i�Q�R�[�h
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                                              iv_application  => cv_xxcsm
                                             ,iv_name         => cv_nogun_nm_msg
                                             ,iv_token_name1  => cv_tkn_gun_cd
                                             ,iv_token_value1 => ior_work_rec.group_cd
                                             );
        FND_FILE.PUT_LINE(
           which  => FND_FILE.LOG
          ,buff => lv_errmsg --�G���[���b�Z�[�W
        );
      WHEN OTHERS THEN
        RAISE;
    END;

    --�e���v���N�Ԍv
    IF (ior_work_rec.sales_budget_total = 0) THEN
--//+UPD START 2009/02/10   CT019 M.Ohtsuki
--    ln_margin_rate := NULL;
      ln_margin_rate := 0;
--//+UPD END   2009/02/10   CT019 M.Ohtsuki
    ELSE
      ln_margin_rate := ROUND(ior_work_rec.margin_total / ior_work_rec.sales_budget_total * 100, 2);
      ln_margin_rate := CASE WHEN ABS(ln_margin_rate) > cv_max_margin_rate THEN cv_max_rate ELSE ln_margin_rate END;
    END IF;

    -- �o�^����
    ior_work_rec.group_nm            := lv_group_nm;       -- ���i�Q����
    ior_work_rec.margin_rate_total   := ln_margin_rate;    -- �e���v��
--
    --==============================================================
    --���b�Z�[�W�o�́i�G���[�ȊO�j������K�v������ꍇ�͏������L�q
    --==============================================================
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
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END set_gun_name;
--
  /**********************************************************************************
   * Procedure Name   : insert_data
   * Description      : �f�[�^�o�^(A-5,11)
   ***********************************************************************************/
  PROCEDURE insert_data(
    ir_work_rec    IN  g_work_gun_rtype,                   -- �Ώۃ��R�[�h
    ov_errbuf      OUT NOCOPY VARCHAR2,                    -- �G���[�E���b�Z�[�W
    ov_retcode     OUT NOCOPY VARCHAR2,                    -- ���^�[���E�R�[�h
    ov_errmsg      OUT NOCOPY VARCHAR2)                    -- ���[�U�[�E�G���[�E���b�Z�[�W
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'insert_data'; -- �v���O������
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
    -- �o�^����1�s��

    INSERT INTO xxcsm_tmp_item_plan_gun(     -- ���i�v��Q�ʃ��[�N�e�[�u��
       toroku_no          -- �o�͏�
      ,code               -- �R�[�h
      ,code_nm            -- �R�[�h����
      ,item_nm            -- ���ږ�
      ,data_05            -- �T��
      ,data_06            -- �U��
      ,data_07            -- �V��
      ,data_08            -- �W��
      ,data_09            -- �X��
      ,data_10            -- �P�O��
      ,data_11            -- �P�P��
      ,data_12            -- �P�Q��
      ,data_01            -- �P��
      ,data_02            -- �Q��
      ,data_03            -- �R��
      ,data_04            -- �S��
      ,total              -- �N�Ԍv
    )VALUES(
       xxcsm_tmp_item_plan_gun_s01.NEXTVAL
      ,ir_work_rec.group_cd                  -- ���i�Q�R�[�h
      ,ir_work_rec.group_nm                  -- ���i�Q����
      ,ir_work_rec.sales_budget_nm           -- ����\�Z��
      ,ir_work_rec.sales_budget05            -- ����\�Z�T��
      ,ir_work_rec.sales_budget06            -- ����\�Z�U��
      ,ir_work_rec.sales_budget07            -- ����\�Z�V��
      ,ir_work_rec.sales_budget08            -- ����\�Z�W��
      ,ir_work_rec.sales_budget09            -- ����\�Z�X��
      ,ir_work_rec.sales_budget10            -- ����\�Z�P�O��
      ,ir_work_rec.sales_budget11            -- ����\�Z�P�P��
      ,ir_work_rec.sales_budget12            -- ����\�Z�P�Q��
      ,ir_work_rec.sales_budget01            -- ����\�Z�P��
      ,ir_work_rec.sales_budget02            -- ����\�Z�Q��
      ,ir_work_rec.sales_budget03            -- ����\�Z�R��
      ,ir_work_rec.sales_budget04            -- ����\�Z�S��
      ,ir_work_rec.sales_budget_total        -- ����\�Z�N�Ԍv
    );
--
    -- �o�^����2�s��
    INSERT INTO xxcsm_tmp_item_plan_gun(     -- ���i�v��Q�ʃ��[�N�e�[�u��
       toroku_no          -- �o�͏�
      ,code               -- �R�[�h
      ,code_nm            -- �R�[�h����
      ,item_nm            -- ���ږ�
      ,data_05            -- �T��
      ,data_06            -- �U��
      ,data_07            -- �V��
      ,data_08            -- �W��
      ,data_09            -- �X��
      ,data_10            -- �P�O��
      ,data_11            -- �P�P��
      ,data_12            -- �P�Q��
      ,data_01            -- �P��
      ,data_02            -- �Q��
      ,data_03            -- �R��
      ,data_04            -- �S��
      ,total              -- �N�Ԍv
    )VALUES(
       xxcsm_tmp_item_plan_gun_s01.NEXTVAL
      ,NULL                                  -- ���i�Q�R�[�h
      ,NULL                                  -- ���i�Q����
      ,ir_work_rec.margin_nm                 -- �e���v�z��
      ,ir_work_rec.margin05                  -- �e���v�z�T��
      ,ir_work_rec.margin06                  -- �e���v�z�U��
      ,ir_work_rec.margin07                  -- �e���v�z�V��
      ,ir_work_rec.margin08                  -- �e���v�z�W��
      ,ir_work_rec.margin09                  -- �e���v�z�X��
      ,ir_work_rec.margin10                  -- �e���v�z�P�O��
      ,ir_work_rec.margin11                  -- �e���v�z�P�P��
      ,ir_work_rec.margin12                  -- �e���v�z�P�Q��
      ,ir_work_rec.margin01                  -- �e���v�z�P��
      ,ir_work_rec.margin02                  -- �e���v�z�Q��
      ,ir_work_rec.margin03                  -- �e���v�z�R��
      ,ir_work_rec.margin04                  -- �e���v�z�S��
      ,ir_work_rec.margin_total              -- �e���v�z�N�Ԍv
    );
--
    -- �o�^����3�s��
    INSERT INTO xxcsm_tmp_item_plan_gun(     -- ���i�v��Q�ʃ��[�N�e�[�u��
       toroku_no          -- �o�͏�
      ,code               -- �R�[�h
      ,code_nm            -- �R�[�h����
      ,item_nm            -- ���ږ�
      ,data_05            -- �T��
      ,data_06            -- �U��
      ,data_07            -- �V��
      ,data_08            -- �W��
      ,data_09            -- �X��
      ,data_10            -- �P�O��
      ,data_11            -- �P�P��
      ,data_12            -- �P�Q��
      ,data_01            -- �P��
      ,data_02            -- �Q��
      ,data_03            -- �R��
      ,data_04            -- �S��
      ,total              -- �N�Ԍv
    )VALUES(
       xxcsm_tmp_item_plan_gun_s01.NEXTVAL
      ,NULL                                  -- ���i�Q�R�[�h
      ,NULL                                  -- ���i�Q����
      ,ir_work_rec.margin_rate_nm            -- �e���v����
      ,ir_work_rec.margin_rate05             -- �e���v���T��
      ,ir_work_rec.margin_rate06             -- �e���v���U��
      ,ir_work_rec.margin_rate07             -- �e���v���V��
      ,ir_work_rec.margin_rate08             -- �e���v���W��
      ,ir_work_rec.margin_rate09             -- �e���v���X��
      ,ir_work_rec.margin_rate10             -- �e���v���P�O��
      ,ir_work_rec.margin_rate11             -- �e���v���P�P��
      ,ir_work_rec.margin_rate12             -- �e���v���P�Q��
      ,ir_work_rec.margin_rate01             -- �e���v���P��
      ,ir_work_rec.margin_rate02             -- �e���v���Q��
      ,ir_work_rec.margin_rate03             -- �e���v���R��
      ,ir_work_rec.margin_rate04             -- �e���v���S��
      ,ir_work_rec.margin_rate_total         -- �e���v���N�Ԍv
    );
--
    --==============================================================
    --���b�Z�[�W�o�́i�G���[�ȊO�j������K�v������ꍇ�͏������L�q
    --==============================================================
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
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END insert_data;
--
  /**********************************************************************************
   * Procedure Name   : set_gun_data
   * Description      : ���i�Q�N�ԃf�[�^��ϐ��֐ݒ�(A-6)
   ***********************************************************************************/
  PROCEDURE set_gun_data(
    ir_gun_rec     IN  item_gun_cur%ROWTYPE,               -- ���i�Q�N�ԃ��R�[�h
    ior_work_rec   IN OUT g_work_gun_rtype,                -- ���i�Q�ϐ����R�[�h
    ov_errbuf      OUT NOCOPY VARCHAR2,                    -- �G���[�E���b�Z�[�W
    ov_retcode     OUT NOCOPY VARCHAR2,                    -- ���^�[���E�R�[�h
    ov_errmsg      OUT NOCOPY VARCHAR2)                    -- ���[�U�[�E�G���[�E���b�Z�[�W
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'set_gun_data'; -- �v���O������
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
    ln_margin_rate         NUMBER;    --�e���v��
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
    --�e���v��
    IF (ir_gun_rec.sales_budget = 0) THEN
--//+UPD START 2009/02/10   CT019 M.Ohtsuki
--    ln_margin_rate := NULL;
      ln_margin_rate := 0;
--//+UPD END   2009/02/10   CT019 M.Ohtsuki
    ELSE
      ln_margin_rate := ROUND(ir_gun_rec.margin / ir_gun_rec.sales_budget * 100, 2);
      ln_margin_rate := CASE WHEN ABS(ln_margin_rate) > cv_max_margin_rate THEN cv_max_rate ELSE ln_margin_rate END;
    END IF;

    -- �o�^����
    ior_work_rec.group_cd            := ir_gun_rec.group_cd;      -- ���i�Q�R�[�h
    ior_work_rec.sales_budget_nm     := gv_sales_budget_nm;       -- ����\�Z��
    ior_work_rec.margin_nm           := gv_margin_amt_nm;         -- �e���v�z��
    ior_work_rec.margin_rate_nm      := gv_margin_rate_nm;        -- �e���v����
    CASE ir_gun_rec.month_no
    WHEN 5 THEN
      ior_work_rec.sales_budget05      := ir_gun_rec.sales_budget;  -- ����\�Z�T��
      ior_work_rec.margin05            := ir_gun_rec.margin;        -- �e���v�z�T��
      ior_work_rec.margin_rate05       := ln_margin_rate;           -- �e���v���T��
      ior_work_rec.sales_budget_total  := NVL(ior_work_rec.sales_budget_total, 0) + ir_gun_rec.sales_budget;  -- ����\�Z�N�Ԍv
      ior_work_rec.margin_total        := NVL(ior_work_rec.margin_total, 0)       + ir_gun_rec.margin;        -- �e���v�z�N�Ԍv
    WHEN 6 THEN
      ior_work_rec.sales_budget06      := ir_gun_rec.sales_budget;  -- ����\�Z�U��
      ior_work_rec.margin06            := ir_gun_rec.margin;        -- �e���v�z�U��
      ior_work_rec.margin_rate06       := ln_margin_rate;           -- �e���v���U��
      ior_work_rec.sales_budget_total  := NVL(ior_work_rec.sales_budget_total, 0) + ir_gun_rec.sales_budget;  -- ����\�Z�N�Ԍv
      ior_work_rec.margin_total        := NVL(ior_work_rec.margin_total, 0)       + ir_gun_rec.margin;        -- �e���v�z�N�Ԍv
    WHEN 7 THEN
      ior_work_rec.sales_budget07      := ir_gun_rec.sales_budget;  -- ����\�Z�V��
      ior_work_rec.margin07            := ir_gun_rec.margin;        -- �e���v�z�V��
      ior_work_rec.margin_rate07       := ln_margin_rate;           -- �e���v���V��
      ior_work_rec.sales_budget_total  := NVL(ior_work_rec.sales_budget_total, 0) + ir_gun_rec.sales_budget;  -- ����\�Z�N�Ԍv
      ior_work_rec.margin_total        := NVL(ior_work_rec.margin_total, 0)       + ir_gun_rec.margin;        -- �e���v�z�N�Ԍv
    WHEN 8 THEN
      ior_work_rec.sales_budget08      := ir_gun_rec.sales_budget;  -- ����\�Z�W��
      ior_work_rec.margin08            := ir_gun_rec.margin;        -- �e���v�z�W��
      ior_work_rec.margin_rate08       := ln_margin_rate;           -- �e���v���W��
      ior_work_rec.sales_budget_total  := NVL(ior_work_rec.sales_budget_total, 0) + ir_gun_rec.sales_budget;  -- ����\�Z�N�Ԍv
      ior_work_rec.margin_total        := NVL(ior_work_rec.margin_total, 0)       + ir_gun_rec.margin;        -- �e���v�z�N�Ԍv
    WHEN 9 THEN
      ior_work_rec.sales_budget09      := ir_gun_rec.sales_budget;  -- ����\�Z�X��
      ior_work_rec.margin09            := ir_gun_rec.margin;        -- �e���v�z�X��
      ior_work_rec.margin_rate09       := ln_margin_rate;           -- �e���v���X��
      ior_work_rec.sales_budget_total  := NVL(ior_work_rec.sales_budget_total, 0) + ir_gun_rec.sales_budget;  -- ����\�Z�N�Ԍv
      ior_work_rec.margin_total        := NVL(ior_work_rec.margin_total, 0)       + ir_gun_rec.margin;        -- �e���v�z�N�Ԍv
    WHEN 10 THEN
      ior_work_rec.sales_budget10      := ir_gun_rec.sales_budget;  -- ����\�Z�P�O��
      ior_work_rec.margin10            := ir_gun_rec.margin;        -- �e���v�z�P�O��
      ior_work_rec.margin_rate10       := ln_margin_rate;           -- �e���v���P�O��
      ior_work_rec.sales_budget_total  := NVL(ior_work_rec.sales_budget_total, 0) + ir_gun_rec.sales_budget;  -- ����\�Z�N�Ԍv
      ior_work_rec.margin_total        := NVL(ior_work_rec.margin_total, 0)       + ir_gun_rec.margin;        -- �e���v�z�N�Ԍv
    WHEN 11 THEN
      ior_work_rec.sales_budget11      := ir_gun_rec.sales_budget;  -- ����\�Z�P�P��
      ior_work_rec.margin11            := ir_gun_rec.margin;        -- �e���v�z�P�P��
      ior_work_rec.margin_rate11       := ln_margin_rate;           -- �e���v���P�P��
      ior_work_rec.sales_budget_total  := NVL(ior_work_rec.sales_budget_total, 0) + ir_gun_rec.sales_budget;  -- ����\�Z�N�Ԍv
      ior_work_rec.margin_total        := NVL(ior_work_rec.margin_total, 0)       + ir_gun_rec.margin;        -- �e���v�z�N�Ԍv
    WHEN 12 THEN
      ior_work_rec.sales_budget12      := ir_gun_rec.sales_budget;  -- ����\�Z�P�Q��
      ior_work_rec.margin12            := ir_gun_rec.margin;        -- �e���v�z�P�Q��
      ior_work_rec.margin_rate12       := ln_margin_rate;           -- �e���v���P�Q��
      ior_work_rec.sales_budget_total  := NVL(ior_work_rec.sales_budget_total, 0) + ir_gun_rec.sales_budget;  -- ����\�Z�N�Ԍv
      ior_work_rec.margin_total        := NVL(ior_work_rec.margin_total, 0)       + ir_gun_rec.margin;        -- �e���v�z�N�Ԍv
    WHEN 1 THEN
      ior_work_rec.sales_budget01      := ir_gun_rec.sales_budget;  -- ����\�Z�P��
      ior_work_rec.margin01            := ir_gun_rec.margin;        -- �e���v�z�P��
      ior_work_rec.margin_rate01       := ln_margin_rate;           -- �e���v���P��
      ior_work_rec.sales_budget_total  := NVL(ior_work_rec.sales_budget_total, 0) + ir_gun_rec.sales_budget;  -- ����\�Z�N�Ԍv
      ior_work_rec.margin_total        := NVL(ior_work_rec.margin_total, 0)       + ir_gun_rec.margin;        -- �e���v�z�N�Ԍv
    WHEN 2 THEN
      ior_work_rec.sales_budget02      := ir_gun_rec.sales_budget;  -- ����\�Z�Q��
      ior_work_rec.margin02            := ir_gun_rec.margin;        -- �e���v�z�Q��
      ior_work_rec.margin_rate02       := ln_margin_rate;           -- �e���v���Q��
      ior_work_rec.sales_budget_total  := NVL(ior_work_rec.sales_budget_total, 0) + ir_gun_rec.sales_budget;  -- ����\�Z�N�Ԍv
      ior_work_rec.margin_total        := NVL(ior_work_rec.margin_total, 0)       + ir_gun_rec.margin;        -- �e���v�z�N�Ԍv
    WHEN 3 THEN
      ior_work_rec.sales_budget03      := ir_gun_rec.sales_budget;  -- ����\�Z�R��
      ior_work_rec.margin03            := ir_gun_rec.margin;        -- �e���v�z�R��
      ior_work_rec.margin_rate03       := ln_margin_rate;           -- �e���v���R��
      ior_work_rec.sales_budget_total  := NVL(ior_work_rec.sales_budget_total, 0) + ir_gun_rec.sales_budget;  -- ����\�Z�N�Ԍv
      ior_work_rec.margin_total        := NVL(ior_work_rec.margin_total, 0)       + ir_gun_rec.margin;        -- �e���v�z�N�Ԍv
    WHEN 4 THEN
      ior_work_rec.sales_budget04      := ir_gun_rec.sales_budget;  -- ����\�Z�S��
      ior_work_rec.margin04            := ir_gun_rec.margin;        -- �e���v�z�S��
      ior_work_rec.margin_rate04       := ln_margin_rate;           -- �e���v���S��
      ior_work_rec.sales_budget_total  := NVL(ior_work_rec.sales_budget_total, 0) + ir_gun_rec.sales_budget;  -- ����\�Z�N�Ԍv
      ior_work_rec.margin_total        := NVL(ior_work_rec.margin_total, 0)       + ir_gun_rec.margin;        -- �e���v�z�N�Ԍv
    ELSE
      NULL;
    END CASE;
--
    --==============================================================
    --���b�Z�[�W�o�́i�G���[�ȊO�j������K�v������ꍇ�͏������L�q
    --==============================================================
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
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END set_gun_data;
--
  /**********************************************************************************
   * Procedure Name   : set_gun_sum_data
   * Description      : �Q�v�̔N�ԃf�[�^��ϐ��֐ݒ�(A-9)
   ***********************************************************************************/
  PROCEDURE set_gun_sum_data(
    ir_sum_rec     IN  item_gun_sum_cur%ROWTYPE,           -- �Q�v���R�[�h
    ior_work_rec   IN OUT g_work_gun_rtype,                -- �Q�v�ϐ����R�[�h
    ov_errbuf      OUT NOCOPY VARCHAR2,                    -- �G���[�E���b�Z�[�W
    ov_retcode     OUT NOCOPY VARCHAR2,                    -- ���^�[���E�R�[�h
    ov_errmsg      OUT NOCOPY VARCHAR2)                    -- ���[�U�[�E�G���[�E���b�Z�[�W
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'set_gun_sum_data'; -- �v���O������
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
    ln_margin_rate         NUMBER;    --�e���v��
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
    -- �S���_�̏ꍇ�͔���\�Z�̂ݑΏہi���_�v�̌v�Z�̂��߁j
    IF (gb_all_kyoten = TRUE) THEN
      CASE ir_sum_rec.month_no
      WHEN 5 THEN
        ior_work_rec.sales_budget05      := ir_sum_rec.sales_budget;  -- ����\�Z�T��
        -- ����\�Z�N�Ԍv
        ior_work_rec.sales_budget_total  := NVL(ior_work_rec.sales_budget_total, 0) + ir_sum_rec.sales_budget;
      WHEN 6 THEN
        ior_work_rec.sales_budget06      := ir_sum_rec.sales_budget;  -- ����\�Z�U��
        -- ����\�Z�N�Ԍv
        ior_work_rec.sales_budget_total  := NVL(ior_work_rec.sales_budget_total, 0) + ir_sum_rec.sales_budget;
      WHEN 7 THEN
        ior_work_rec.sales_budget07      := ir_sum_rec.sales_budget;  -- ����\�Z�V��
        -- ����\�Z�N�Ԍv
        ior_work_rec.sales_budget_total  := NVL(ior_work_rec.sales_budget_total, 0) + ir_sum_rec.sales_budget;
      WHEN 8 THEN
        ior_work_rec.sales_budget08      := ir_sum_rec.sales_budget;  -- ����\�Z�W��
        -- ����\�Z�N�Ԍv
        ior_work_rec.sales_budget_total  := NVL(ior_work_rec.sales_budget_total, 0) + ir_sum_rec.sales_budget;
      WHEN 9 THEN
        ior_work_rec.sales_budget09      := ir_sum_rec.sales_budget;  -- ����\�Z�X��
        -- ����\�Z�N�Ԍv
        ior_work_rec.sales_budget_total  := NVL(ior_work_rec.sales_budget_total, 0) + ir_sum_rec.sales_budget;
      WHEN 10 THEN
        ior_work_rec.sales_budget10      := ir_sum_rec.sales_budget;  -- ����\�Z�P�O��
        -- ����\�Z�N�Ԍv
        ior_work_rec.sales_budget_total  := NVL(ior_work_rec.sales_budget_total, 0) + ir_sum_rec.sales_budget;
      WHEN 11 THEN
        ior_work_rec.sales_budget11      := ir_sum_rec.sales_budget;  -- ����\�Z�P�P��
        -- ����\�Z�N�Ԍv
        ior_work_rec.sales_budget_total  := NVL(ior_work_rec.sales_budget_total, 0) + ir_sum_rec.sales_budget;
      WHEN 12 THEN
        ior_work_rec.sales_budget12      := ir_sum_rec.sales_budget;  -- ����\�Z�P�Q��
        -- ����\�Z�N�Ԍv
        ior_work_rec.sales_budget_total  := NVL(ior_work_rec.sales_budget_total, 0) + ir_sum_rec.sales_budget;
      WHEN 1 THEN
        ior_work_rec.sales_budget01      := ir_sum_rec.sales_budget;  -- ����\�Z�P��
        -- ����\�Z�N�Ԍv
        ior_work_rec.sales_budget_total  := NVL(ior_work_rec.sales_budget_total, 0) + ir_sum_rec.sales_budget;
      WHEN 2 THEN
        ior_work_rec.sales_budget02      := ir_sum_rec.sales_budget;  -- ����\�Z�Q��
        -- ����\�Z�N�Ԍv
        ior_work_rec.sales_budget_total  := NVL(ior_work_rec.sales_budget_total, 0) + ir_sum_rec.sales_budget;
      WHEN 3 THEN
        ior_work_rec.sales_budget03      := ir_sum_rec.sales_budget;  -- ����\�Z�R��
        -- ����\�Z�N�Ԍv
        ior_work_rec.sales_budget_total  := NVL(ior_work_rec.sales_budget_total, 0) + ir_sum_rec.sales_budget;
      WHEN 4 THEN
        ior_work_rec.sales_budget04      := ir_sum_rec.sales_budget;  -- ����\�Z�S��
        -- ����\�Z�N�Ԍv
        ior_work_rec.sales_budget_total  := NVL(ior_work_rec.sales_budget_total, 0) + ir_sum_rec.sales_budget;
      ELSE
        NULL;
      END CASE;
    ELSE
      --�e���v��
      IF (ir_sum_rec.sales_budget = 0) THEN
--//+UPD START 2009/02/10   CT019 M.Ohtsuki
--      ln_margin_rate := NULL;
        ln_margin_rate := 0;
--//+UPD END   2009/02/10   CT019 M.Ohtsuki
      ELSE
        ln_margin_rate := ROUND(ir_sum_rec.margin / ir_sum_rec.sales_budget * 100, 2);
        ln_margin_rate := CASE WHEN ABS(ln_margin_rate) > cv_max_margin_rate THEN cv_max_rate ELSE ln_margin_rate END;
      END IF;

      -- �o�^����
      ior_work_rec.group_cd            := NULL;                     -- �R�[�h
      ior_work_rec.sales_budget_nm     := gv_sales_budget_nm;       -- ����\�Z��
      ior_work_rec.margin_nm           := gv_margin_amt_nm;         -- �e���v�z��
      ior_work_rec.margin_rate_nm      := gv_margin_rate_nm;        -- �e���v����
      CASE ir_sum_rec.month_no
      WHEN 5 THEN
        ior_work_rec.sales_budget05      := ir_sum_rec.sales_budget;  -- ����\�Z�T��
        ior_work_rec.margin05            := ir_sum_rec.margin;        -- �e���v�z�T��
        ior_work_rec.margin_rate05       := ln_margin_rate;           -- �e���v���T��
        -- ����\�Z�N�Ԍv
        ior_work_rec.sales_budget_total  := NVL(ior_work_rec.sales_budget_total, 0) + ir_sum_rec.sales_budget;
        -- �e���v�z�N�Ԍv
        ior_work_rec.margin_total        := NVL(ior_work_rec.margin_total, 0)       + ir_sum_rec.margin;
      WHEN 6 THEN
        ior_work_rec.sales_budget06      := ir_sum_rec.sales_budget;  -- ����\�Z�U��
        ior_work_rec.margin06            := ir_sum_rec.margin;        -- �e���v�z�U��
        ior_work_rec.margin_rate06       := ln_margin_rate;           -- �e���v���U��
        -- ����\�Z�N�Ԍv
        ior_work_rec.sales_budget_total  := NVL(ior_work_rec.sales_budget_total, 0) + ir_sum_rec.sales_budget;
        -- �e���v�z�N�Ԍv
        ior_work_rec.margin_total        := NVL(ior_work_rec.margin_total, 0)       + ir_sum_rec.margin;
      WHEN 7 THEN
        ior_work_rec.sales_budget07      := ir_sum_rec.sales_budget;  -- ����\�Z�V��
        ior_work_rec.margin07            := ir_sum_rec.margin;        -- �e���v�z�V��
        ior_work_rec.margin_rate07       := ln_margin_rate;           -- �e���v���V��
        -- ����\�Z�N�Ԍv
        ior_work_rec.sales_budget_total  := NVL(ior_work_rec.sales_budget_total, 0) + ir_sum_rec.sales_budget;
        -- �e���v�z�N�Ԍv
        ior_work_rec.margin_total        := NVL(ior_work_rec.margin_total, 0)       + ir_sum_rec.margin;
      WHEN 8 THEN
        ior_work_rec.sales_budget08      := ir_sum_rec.sales_budget;  -- ����\�Z�W��
        ior_work_rec.margin08            := ir_sum_rec.margin;        -- �e���v�z�W��
        ior_work_rec.margin_rate08       := ln_margin_rate;           -- �e���v���W��
        -- ����\�Z�N�Ԍv
        ior_work_rec.sales_budget_total  := NVL(ior_work_rec.sales_budget_total, 0) + ir_sum_rec.sales_budget;
        -- �e���v�z�N�Ԍv
        ior_work_rec.margin_total        := NVL(ior_work_rec.margin_total, 0)       + ir_sum_rec.margin;
      WHEN 9 THEN
        ior_work_rec.sales_budget09      := ir_sum_rec.sales_budget;  -- ����\�Z�X��
        ior_work_rec.margin09            := ir_sum_rec.margin;        -- �e���v�z�X��
        ior_work_rec.margin_rate09       := ln_margin_rate;           -- �e���v���X��
        -- ����\�Z�N�Ԍv
        ior_work_rec.sales_budget_total  := NVL(ior_work_rec.sales_budget_total, 0) + ir_sum_rec.sales_budget;
        -- �e���v�z�N�Ԍv
        ior_work_rec.margin_total        := NVL(ior_work_rec.margin_total, 0)       + ir_sum_rec.margin;
      WHEN 10 THEN
        ior_work_rec.sales_budget10      := ir_sum_rec.sales_budget;  -- ����\�Z�P�O��
        ior_work_rec.margin10            := ir_sum_rec.margin;        -- �e���v�z�P�O��
        ior_work_rec.margin_rate10       := ln_margin_rate;           -- �e���v���P�O��
        -- ����\�Z�N�Ԍv
        ior_work_rec.sales_budget_total  := NVL(ior_work_rec.sales_budget_total, 0) + ir_sum_rec.sales_budget;
        -- �e���v�z�N�Ԍv
        ior_work_rec.margin_total        := NVL(ior_work_rec.margin_total, 0)       + ir_sum_rec.margin;
      WHEN 11 THEN
        ior_work_rec.sales_budget11      := ir_sum_rec.sales_budget;  -- ����\�Z�P�P��
        ior_work_rec.margin11            := ir_sum_rec.margin;        -- �e���v�z�P�P��
        ior_work_rec.margin_rate11       := ln_margin_rate;           -- �e���v���P�P��
        -- ����\�Z�N�Ԍv
        ior_work_rec.sales_budget_total  := NVL(ior_work_rec.sales_budget_total, 0) + ir_sum_rec.sales_budget;
        -- �e���v�z�N�Ԍv
        ior_work_rec.margin_total        := NVL(ior_work_rec.margin_total, 0)       + ir_sum_rec.margin;
      WHEN 12 THEN
        ior_work_rec.sales_budget12      := ir_sum_rec.sales_budget;  -- ����\�Z�P�Q��
        ior_work_rec.margin12            := ir_sum_rec.margin;        -- �e���v�z�P�Q��
        ior_work_rec.margin_rate12       := ln_margin_rate;           -- �e���v���P�Q��
        -- ����\�Z�N�Ԍv
        ior_work_rec.sales_budget_total  := NVL(ior_work_rec.sales_budget_total, 0) + ir_sum_rec.sales_budget;
        -- �e���v�z�N�Ԍv
        ior_work_rec.margin_total        := NVL(ior_work_rec.margin_total, 0)       + ir_sum_rec.margin;
      WHEN 1 THEN
        ior_work_rec.sales_budget01      := ir_sum_rec.sales_budget;  -- ����\�Z�P��
        ior_work_rec.margin01            := ir_sum_rec.margin;        -- �e���v�z�P��
        ior_work_rec.margin_rate01       := ln_margin_rate;           -- �e���v���P��
        -- ����\�Z�N�Ԍv
        ior_work_rec.sales_budget_total  := NVL(ior_work_rec.sales_budget_total, 0) + ir_sum_rec.sales_budget;
        -- �e���v�z�N�Ԍv
        ior_work_rec.margin_total        := NVL(ior_work_rec.margin_total, 0)       + ir_sum_rec.margin;
      WHEN 2 THEN
        ior_work_rec.sales_budget02      := ir_sum_rec.sales_budget;  -- ����\�Z�Q��
        ior_work_rec.margin02            := ir_sum_rec.margin;        -- �e���v�z�Q��
        ior_work_rec.margin_rate02       := ln_margin_rate;           -- �e���v���Q��
        -- ����\�Z�N�Ԍv
        ior_work_rec.sales_budget_total  := NVL(ior_work_rec.sales_budget_total, 0) + ir_sum_rec.sales_budget;
        -- �e���v�z�N�Ԍv
        ior_work_rec.margin_total        := NVL(ior_work_rec.margin_total, 0)       + ir_sum_rec.margin;
      WHEN 3 THEN
        ior_work_rec.sales_budget03      := ir_sum_rec.sales_budget;  -- ����\�Z�R��
        ior_work_rec.margin03            := ir_sum_rec.margin;        -- �e���v�z�R��
        ior_work_rec.margin_rate03       := ln_margin_rate;           -- �e���v���R��
        -- ����\�Z�N�Ԍv
        ior_work_rec.sales_budget_total  := NVL(ior_work_rec.sales_budget_total, 0) + ir_sum_rec.sales_budget;
        -- �e���v�z�N�Ԍv
        ior_work_rec.margin_total        := NVL(ior_work_rec.margin_total, 0)       + ir_sum_rec.margin;
      WHEN 4 THEN
        ior_work_rec.sales_budget04      := ir_sum_rec.sales_budget;  -- ����\�Z�S��
        ior_work_rec.margin04            := ir_sum_rec.margin;        -- �e���v�z�S��
        ior_work_rec.margin_rate04       := ln_margin_rate;           -- �e���v���S��
        -- ����\�Z�N�Ԍv
        ior_work_rec.sales_budget_total  := NVL(ior_work_rec.sales_budget_total, 0) + ir_sum_rec.sales_budget;
        -- �e���v�z�N�Ԍv
        ior_work_rec.margin_total        := NVL(ior_work_rec.margin_total, 0)       + ir_sum_rec.margin;
      ELSE
        NULL;
      END CASE;
    END IF;
--
    --==============================================================
    --���b�Z�[�W�o�́i�G���[�ȊO�j������K�v������ꍇ�͏������L�q
    --==============================================================
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
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END set_gun_sum_data;
--
  /**********************************************************************************
   * Procedure Name   : set_gun_sum_name
   * Description      : �Q�v���̂̎擾����єN�Ԍv�̑e�����Z�o(A-10)
   ***********************************************************************************/
  PROCEDURE set_gun_sum_name(
    ior_work_rec   IN OUT g_work_gun_rtype,                -- �Q�v�ϐ����R�[�h
    ov_errbuf      OUT NOCOPY VARCHAR2,                    -- �G���[�E���b�Z�[�W
    ov_retcode     OUT NOCOPY VARCHAR2,                    -- ���^�[���E�R�[�h
    ov_errmsg      OUT NOCOPY VARCHAR2)                    -- ���[�U�[�E�G���[�E���b�Z�[�W
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'set_gun_sum_name'; -- �v���O������
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
    ln_margin_rate         NUMBER;                               -- �e���v��
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

    --�e���v���N�Ԍv
    IF (ior_work_rec.sales_budget_total = 0) THEN
--//+UPD START 2009/02/10   CT019 M.Ohtsuki
--    ln_margin_rate := NULL;
      ln_margin_rate := 0;
--//+UPD END   2009/02/10   CT019 M.Ohtsuki
    ELSE
      ln_margin_rate := ROUND(ior_work_rec.margin_total / ior_work_rec.sales_budget_total * 100, 2);
      ln_margin_rate := CASE WHEN ABS(ln_margin_rate) > cv_max_margin_rate THEN cv_max_rate ELSE ln_margin_rate END;
    END IF;

    -- �o�^����
    ior_work_rec.group_nm            := gv_total_gun_nm;   -- �Q�v����
    ior_work_rec.margin_rate_total   := ln_margin_rate;    -- �e���v��
--
    --==============================================================
    --���b�Z�[�W�o�́i�G���[�ȊO�j������K�v������ꍇ�͏������L�q
    --==============================================================
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
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END set_gun_sum_name;
--
  /**********************************************************************************
   * Procedure Name   : set_kyoten_name
   * Description      : ���_���̂̎擾����єN�Ԍv�̑e�����A���z�Z�o(A-12)
   ***********************************************************************************/
  PROCEDURE set_kyoten_name(
    ir_sum_rec     IN  g_work_gun_rtype,                   -- �Q�v�ϐ����R�[�h
    ior_work_rec   IN OUT g_work_gun_rtype,                -- ���_�ϐ����R�[�h
    ov_errbuf      OUT NOCOPY VARCHAR2,                    -- �G���[�E���b�Z�[�W
    ov_retcode     OUT NOCOPY VARCHAR2,                    -- ���^�[���E�R�[�h
    ov_errmsg      OUT NOCOPY VARCHAR2)                    -- ���[�U�[�E�G���[�E���b�Z�[�W
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'set_kyoten_name'; -- �v���O������
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
    cv_kyoten          CONSTANT VARCHAR2(1)  := '1';             -- �ڋq�敪�i���_���́j
--
    -- *** ���[�J���ϐ� ***
    ln_margin_rate         NUMBER;                               -- �e���v��
    lv_kyoten_nm           hz_parties.party_name%TYPE;           -- ���_����
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

    --���_���̎擾
    BEGIN
      SELECT
        hps.party_name         kyoten_nm
      INTO
        lv_kyoten_nm
      FROM
         hz_cust_accounts      hca                     -- �ڋq�}�X�^
        ,hz_parties            hps
      WHERE
        hca.party_id = hps.party_id                    -- 
      AND
        hca.customer_class_code = cv_kyoten            -- �ڋq�敪
      AND
        hca.account_number = ior_work_rec.group_cd     -- �ڋq�R�[�h
      AND
        ROWNUM = 1
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                                              iv_application  => cv_xxcsm
                                             ,iv_name         => cv_nokyo_nm_msg
                                             ,iv_token_name1  => cv_tkn_cd_kyoten
                                             ,iv_token_value1 => ior_work_rec.group_cd
                                             );
        FND_FILE.PUT_LINE(
           which  => FND_FILE.LOG
          ,buff => lv_errmsg --�G���[���b�Z�[�W
        );
      WHEN OTHERS THEN
        RAISE;
    END;

    --�e���v���N�Ԍv
--//+UPD START 2009/02/23   CT058 K.Yamada
--  IF (ior_work_rec.sales_af_disc_total = 0) THEN
    IF (ior_work_rec.sales_bf_disc_total = 0) THEN
--//+UPD END   2009/02/23   CT058 K.Yamada
--//+UPD START 2009/02/10   CT019 M.Ohtsuki
--    ln_margin_rate := NULL;
      ln_margin_rate := 0;
--//+UPD END   2009/02/10   CT019 M.Ohtsuki
    ELSE
--//+UPD START 2009/02/23   CT058 K.Yamada
--    ln_margin_rate := ROUND(ior_work_rec.margin_total / ior_work_rec.sales_af_disc_total * 100, 2);
      ln_margin_rate := ROUND(ior_work_rec.margin_total / ior_work_rec.sales_bf_disc_total * 100, 2);
--//+UPD END   2009/02/23   CT058 K.Yamada
      ln_margin_rate := CASE WHEN ABS(ln_margin_rate) > cv_max_margin_rate THEN cv_max_rate ELSE ln_margin_rate END;
    END IF;

    -- �o�^����
    ior_work_rec.group_nm            := lv_kyoten_nm;      -- ���_����
    ior_work_rec.margin_rate_total   := ln_margin_rate;    -- �e���v��

    ior_work_rec.sagaku_nm           := gv_sagaku_nm;      -- ���z��

    ior_work_rec.sagaku05        := ior_work_rec.sales_bf_disc05     - ir_sum_rec.sales_budget05;      -- ���z�T��
    ior_work_rec.sagaku06        := ior_work_rec.sales_bf_disc06     - ir_sum_rec.sales_budget06;      -- ���z�U��
    ior_work_rec.sagaku07        := ior_work_rec.sales_bf_disc07     - ir_sum_rec.sales_budget07;      -- ���z�V��
    ior_work_rec.sagaku08        := ior_work_rec.sales_bf_disc08     - ir_sum_rec.sales_budget08;      -- ���z�W��
    ior_work_rec.sagaku09        := ior_work_rec.sales_bf_disc09     - ir_sum_rec.sales_budget09;      -- ���z�X��
    ior_work_rec.sagaku10        := ior_work_rec.sales_bf_disc10     - ir_sum_rec.sales_budget10;      -- ���z�P�O��
    ior_work_rec.sagaku11        := ior_work_rec.sales_bf_disc11     - ir_sum_rec.sales_budget11;      -- ���z�P�P��
    ior_work_rec.sagaku12        := ior_work_rec.sales_bf_disc12     - ir_sum_rec.sales_budget12;      -- ���z�P�Q��
    ior_work_rec.sagaku01        := ior_work_rec.sales_bf_disc01     - ir_sum_rec.sales_budget01;      -- ���z�P��
    ior_work_rec.sagaku02        := ior_work_rec.sales_bf_disc02     - ir_sum_rec.sales_budget02;      -- ���z�Q��
    ior_work_rec.sagaku03        := ior_work_rec.sales_bf_disc03     - ir_sum_rec.sales_budget03;      -- ���z�R��
    ior_work_rec.sagaku04        := ior_work_rec.sales_bf_disc04     - ir_sum_rec.sales_budget04;      -- ���z�S��
    ior_work_rec.sagaku_total    := ior_work_rec.sales_bf_disc_total - ir_sum_rec.sales_budget_total;

--
    --==============================================================
    --���b�Z�[�W�o�́i�G���[�ȊO�j������K�v������ꍇ�͏������L�q
    --==============================================================
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
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END set_kyoten_name;
--
  /**********************************************************************************
   * Procedure Name   : insert_kyoten_data
   * Description      : ���_�v�����i�v��Q�ʃ��[�N�e�[�u���֓o�^(A-13)
   ***********************************************************************************/
  PROCEDURE insert_kyoten_data(
    ir_work_rec    IN  g_work_gun_rtype,                   -- ���_�ϐ����R�[�h
    ov_errbuf      OUT NOCOPY VARCHAR2,                    -- �G���[�E���b�Z�[�W
    ov_retcode     OUT NOCOPY VARCHAR2,                    -- ���^�[���E�R�[�h
    ov_errmsg      OUT NOCOPY VARCHAR2)                    -- ���[�U�[�E�G���[�E���b�Z�[�W
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'insert_kyoten_data'; -- �v���O������
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
    IF NOT ((gb_all_kyoten = TRUE) AND (gn_target_cnt = 1)) THEN
      -- ��s
      INSERT INTO xxcsm_tmp_item_plan_gun(     -- ���i�v��Q�ʃ��[�N�e�[�u��
         toroku_no          -- �o�͏�
      )VALUES(
         xxcsm_tmp_item_plan_gun_s01.NEXTVAL
      );
    END IF;
--


    -- �o�^����1�s��
    INSERT INTO xxcsm_tmp_item_plan_gun(     -- ���i�v��Q�ʃ��[�N�e�[�u��
       toroku_no          -- �o�͏�
      ,code               -- �R�[�h
      ,code_nm            -- �R�[�h����
      ,item_nm            -- ���ږ�
      ,data_05            -- �T��
      ,data_06            -- �U��
      ,data_07            -- �V��
      ,data_08            -- �W��
      ,data_09            -- �X��
      ,data_10            -- �P�O��
      ,data_11            -- �P�P��
      ,data_12            -- �P�Q��
      ,data_01            -- �P��
      ,data_02            -- �Q��
      ,data_03            -- �R��
      ,data_04            -- �S��
      ,total              -- �N�Ԍv
    )VALUES(
       xxcsm_tmp_item_plan_gun_s01.NEXTVAL
      ,ir_work_rec.group_cd                  -- �R�[�h
      ,ir_work_rec.group_nm                  -- ����
      ,ir_work_rec.sales_bf_disc_nm          -- �l���O���㖼
      ,ir_work_rec.sales_bf_disc05           -- �l���O����T��
      ,ir_work_rec.sales_bf_disc06           -- �l���O����U��
      ,ir_work_rec.sales_bf_disc07           -- �l���O����V��
      ,ir_work_rec.sales_bf_disc08           -- �l���O����W��
      ,ir_work_rec.sales_bf_disc09           -- �l���O����X��
      ,ir_work_rec.sales_bf_disc10           -- �l���O����P�O��
      ,ir_work_rec.sales_bf_disc11           -- �l���O����P�P��
      ,ir_work_rec.sales_bf_disc12           -- �l���O����P�Q��
      ,ir_work_rec.sales_bf_disc01           -- �l���O����P��
      ,ir_work_rec.sales_bf_disc02           -- �l���O����Q��
      ,ir_work_rec.sales_bf_disc03           -- �l���O����R��
      ,ir_work_rec.sales_bf_disc04           -- �l���O����S��
      ,ir_work_rec.sales_bf_disc_total       -- �l���O����N�Ԍv
    );
--
    -- �o�^����2�s��
    INSERT INTO xxcsm_tmp_item_plan_gun(     -- ���i�v��Q�ʃ��[�N�e�[�u��
       toroku_no          -- �o�͏�
      ,code               -- �R�[�h
      ,code_nm            -- �R�[�h����
      ,item_nm            -- ���ږ�
      ,data_05            -- �T��
      ,data_06            -- �U��
      ,data_07            -- �V��
      ,data_08            -- �W��
      ,data_09            -- �X��
      ,data_10            -- �P�O��
      ,data_11            -- �P�P��
      ,data_12            -- �P�Q��
      ,data_01            -- �P��
      ,data_02            -- �Q��
      ,data_03            -- �R��
      ,data_04            -- �S��
      ,total              -- �N�Ԍv
    )VALUES(
       xxcsm_tmp_item_plan_gun_s01.NEXTVAL
      ,NULL                                  -- �R�[�h
      ,NULL                                  -- ����
      ,ir_work_rec.sales_disc_nm             -- ����l����
      ,ir_work_rec.sales_disc05              -- ����l���T��
      ,ir_work_rec.sales_disc06              -- ����l���U��
      ,ir_work_rec.sales_disc07              -- ����l���V��
      ,ir_work_rec.sales_disc08              -- ����l���W��
      ,ir_work_rec.sales_disc09              -- ����l���X��
      ,ir_work_rec.sales_disc10              -- ����l���P�O��
      ,ir_work_rec.sales_disc11              -- ����l���P�P��
      ,ir_work_rec.sales_disc12              -- ����l���P�Q��
      ,ir_work_rec.sales_disc01              -- ����l���P��
      ,ir_work_rec.sales_disc02              -- ����l���Q��
      ,ir_work_rec.sales_disc03              -- ����l���R��
      ,ir_work_rec.sales_disc04              -- ����l���S��
      ,ir_work_rec.sales_disc_total          -- ����l���N�Ԍv
    );
--
    -- �o�^����3�s��
    INSERT INTO xxcsm_tmp_item_plan_gun(     -- ���i�v��Q�ʃ��[�N�e�[�u��
       toroku_no          -- �o�͏�
      ,code               -- �R�[�h
      ,code_nm            -- �R�[�h����
      ,item_nm            -- ���ږ�
      ,data_05            -- �T��
      ,data_06            -- �U��
      ,data_07            -- �V��
      ,data_08            -- �W��
      ,data_09            -- �X��
      ,data_10            -- �P�O��
      ,data_11            -- �P�P��
      ,data_12            -- �P�Q��
      ,data_01            -- �P��
      ,data_02            -- �Q��
      ,data_03            -- �R��
      ,data_04            -- �S��
      ,total              -- �N�Ԍv
    )VALUES(
       xxcsm_tmp_item_plan_gun_s01.NEXTVAL
      ,NULL                                  -- �R�[�h
      ,NULL                                  -- ����
      ,ir_work_rec.receipt_disc_nm           -- �����l����
      ,ir_work_rec.receipt_disc05            -- �����l���T��
      ,ir_work_rec.receipt_disc06            -- �����l���U��
      ,ir_work_rec.receipt_disc07            -- �����l���V��
      ,ir_work_rec.receipt_disc08            -- �����l���W��
      ,ir_work_rec.receipt_disc09            -- �����l���X��
      ,ir_work_rec.receipt_disc10            -- �����l���P�O��
      ,ir_work_rec.receipt_disc11            -- �����l���P�P��
      ,ir_work_rec.receipt_disc12            -- �����l���P�Q��
      ,ir_work_rec.receipt_disc01            -- �����l���P��
      ,ir_work_rec.receipt_disc02            -- �����l���Q��
      ,ir_work_rec.receipt_disc03            -- �����l���R��
      ,ir_work_rec.receipt_disc04            -- �����l���S��
      ,ir_work_rec.receipt_disc_total        -- �����l���N�Ԍv
    );
--
    -- �o�^����4�s��
    INSERT INTO xxcsm_tmp_item_plan_gun(     -- ���i�v��Q�ʃ��[�N�e�[�u��
       toroku_no          -- �o�͏�
      ,code               -- �R�[�h
      ,code_nm            -- �R�[�h����
      ,item_nm            -- ���ږ�
      ,data_05            -- �T��
      ,data_06            -- �U��
      ,data_07            -- �V��
      ,data_08            -- �W��
      ,data_09            -- �X��
      ,data_10            -- �P�O��
      ,data_11            -- �P�P��
      ,data_12            -- �P�Q��
      ,data_01            -- �P��
      ,data_02            -- �Q��
      ,data_03            -- �R��
      ,data_04            -- �S��
      ,total              -- �N�Ԍv
    )VALUES(
       xxcsm_tmp_item_plan_gun_s01.NEXTVAL
      ,NULL                                  -- �R�[�h
      ,NULL                                  -- ����
      ,ir_work_rec.sales_af_disc_nm          -- �l���㔄�㖼
      ,ir_work_rec.sales_af_disc05           -- �l���㔄��T��
      ,ir_work_rec.sales_af_disc06           -- �l���㔄��U��
      ,ir_work_rec.sales_af_disc07           -- �l���㔄��V��
      ,ir_work_rec.sales_af_disc08           -- �l���㔄��W��
      ,ir_work_rec.sales_af_disc09           -- �l���㔄��X��
      ,ir_work_rec.sales_af_disc10           -- �l���㔄��P�O��
      ,ir_work_rec.sales_af_disc11           -- �l���㔄��P�P��
      ,ir_work_rec.sales_af_disc12           -- �l���㔄��P�Q��
      ,ir_work_rec.sales_af_disc01           -- �l���㔄��P��
      ,ir_work_rec.sales_af_disc02           -- �l���㔄��Q��
      ,ir_work_rec.sales_af_disc03           -- �l���㔄��R��
      ,ir_work_rec.sales_af_disc04           -- �l���㔄��S��
      ,ir_work_rec.sales_af_disc_total       -- �l���㔄��N�Ԍv
    );
--
    -- �o�^����5�s��
    INSERT INTO xxcsm_tmp_item_plan_gun(     -- ���i�v��Q�ʃ��[�N�e�[�u��
       toroku_no          -- �o�͏�
      ,code               -- �R�[�h
      ,code_nm            -- �R�[�h����
      ,item_nm            -- ���ږ�
      ,data_05            -- �T��
      ,data_06            -- �U��
      ,data_07            -- �V��
      ,data_08            -- �W��
      ,data_09            -- �X��
      ,data_10            -- �P�O��
      ,data_11            -- �P�P��
      ,data_12            -- �P�Q��
      ,data_01            -- �P��
      ,data_02            -- �Q��
      ,data_03            -- �R��
      ,data_04            -- �S��
      ,total              -- �N�Ԍv
    )VALUES(
       xxcsm_tmp_item_plan_gun_s01.NEXTVAL
      ,NULL                                  -- �R�[�h
      ,NULL                                  -- ����
      ,ir_work_rec.margin_nm                 -- �e���v�z��
      ,ir_work_rec.margin05                  -- �e���v�z�T��
      ,ir_work_rec.margin06                  -- �e���v�z�U��
      ,ir_work_rec.margin07                  -- �e���v�z�V��
      ,ir_work_rec.margin08                  -- �e���v�z�W��
      ,ir_work_rec.margin09                  -- �e���v�z�X��
      ,ir_work_rec.margin10                  -- �e���v�z�P�O��
      ,ir_work_rec.margin11                  -- �e���v�z�P�P��
      ,ir_work_rec.margin12                  -- �e���v�z�P�Q��
      ,ir_work_rec.margin01                  -- �e���v�z�P��
      ,ir_work_rec.margin02                  -- �e���v�z�Q��
      ,ir_work_rec.margin03                  -- �e���v�z�R��
      ,ir_work_rec.margin04                  -- �e���v�z�S��
      ,ir_work_rec.margin_total              -- �e���v�z�N�Ԍv
    );
--
    -- �o�^����6�s��
    INSERT INTO xxcsm_tmp_item_plan_gun(     -- ���i�v��Q�ʃ��[�N�e�[�u��
       toroku_no          -- �o�͏�
      ,code               -- �R�[�h
      ,code_nm            -- �R�[�h����
      ,item_nm            -- ���ږ�
      ,data_05            -- �T��
      ,data_06            -- �U��
      ,data_07            -- �V��
      ,data_08            -- �W��
      ,data_09            -- �X��
      ,data_10            -- �P�O��
      ,data_11            -- �P�P��
      ,data_12            -- �P�Q��
      ,data_01            -- �P��
      ,data_02            -- �Q��
      ,data_03            -- �R��
      ,data_04            -- �S��
      ,total              -- �N�Ԍv
    )VALUES(
       xxcsm_tmp_item_plan_gun_s01.NEXTVAL
      ,NULL                                  -- ���i�Q�R�[�h
      ,NULL                                  -- ���i�Q����
      ,ir_work_rec.margin_rate_nm            -- �e���v����
      ,ir_work_rec.margin_rate05             -- �e���v���T��
      ,ir_work_rec.margin_rate06             -- �e���v���U��
      ,ir_work_rec.margin_rate07             -- �e���v���V��
      ,ir_work_rec.margin_rate08             -- �e���v���W��
      ,ir_work_rec.margin_rate09             -- �e���v���X��
      ,ir_work_rec.margin_rate10             -- �e���v���P�O��
      ,ir_work_rec.margin_rate11             -- �e���v���P�P��
      ,ir_work_rec.margin_rate12             -- �e���v���P�Q��
      ,ir_work_rec.margin_rate01             -- �e���v���P��
      ,ir_work_rec.margin_rate02             -- �e���v���Q��
      ,ir_work_rec.margin_rate03             -- �e���v���R��
      ,ir_work_rec.margin_rate04             -- �e���v���S��
      ,ir_work_rec.margin_rate_total         -- �e���v���N�Ԍv
    );
--
    -- �o�^����7�s��
    INSERT INTO xxcsm_tmp_item_plan_gun(     -- ���i�v��Q�ʃ��[�N�e�[�u��
       toroku_no          -- �o�͏�
      ,code               -- �R�[�h
      ,code_nm            -- �R�[�h����
      ,item_nm            -- ���ږ�
      ,data_05            -- �T��
      ,data_06            -- �U��
      ,data_07            -- �V��
      ,data_08            -- �W��
      ,data_09            -- �X��
      ,data_10            -- �P�O��
      ,data_11            -- �P�P��
      ,data_12            -- �P�Q��
      ,data_01            -- �P��
      ,data_02            -- �Q��
      ,data_03            -- �R��
      ,data_04            -- �S��
      ,total              -- �N�Ԍv
    )VALUES(
       xxcsm_tmp_item_plan_gun_s01.NEXTVAL
      ,NULL                                  -- ���i�Q�R�[�h
      ,NULL                                  -- ���i�Q����
      ,ir_work_rec.sagaku_nm            -- ���z��
      ,ir_work_rec.sagaku05             -- ���z�T��
      ,ir_work_rec.sagaku06             -- ���z�U��
      ,ir_work_rec.sagaku07             -- ���z�V��
      ,ir_work_rec.sagaku08             -- ���z�W��
      ,ir_work_rec.sagaku09             -- ���z�X��
      ,ir_work_rec.sagaku10             -- ���z�P�O��
      ,ir_work_rec.sagaku11             -- ���z�P�P��
      ,ir_work_rec.sagaku12             -- ���z�P�Q��
      ,ir_work_rec.sagaku01             -- ���z�P��
      ,ir_work_rec.sagaku02             -- ���z�Q��
      ,ir_work_rec.sagaku03             -- ���z�R��
      ,ir_work_rec.sagaku04             -- ���z�S��
      ,ir_work_rec.sagaku_total         -- ���z�N�Ԍv
    );
--
    --==============================================================
    --���b�Z�[�W�o�́i�G���[�ȊO�j������K�v������ꍇ�͏������L�q
    --==============================================================
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
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END insert_kyoten_data;
--
  /**********************************************************************************
   * Procedure Name   : set_kyoten_data
   * Description      : ���_�N�ԃf�[�^��ϐ��֐ݒ�(A-14)
   ***********************************************************************************/
  PROCEDURE set_kyoten_data(
    ir_kyoten_rec  IN  kyoten_cur%ROWTYPE,                 -- ���_���R�[�h
    ior_work_rec   IN OUT g_work_gun_rtype,                -- ���_�ϐ����R�[�h
    ov_errbuf      OUT NOCOPY VARCHAR2,                    -- �G���[�E���b�Z�[�W
    ov_retcode     OUT NOCOPY VARCHAR2,                    -- ���^�[���E�R�[�h
    ov_errmsg      OUT NOCOPY VARCHAR2)                    -- ���[�U�[�E�G���[�E���b�Z�[�W
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'set_kyoten_data'; -- �v���O������
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
    ln_margin_rate         NUMBER;    --�e���v��
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
    -- �e���v��
--//+UPD START 2009/02/23   CT058 K.Yamada
--  IF (ir_kyoten_rec.sales_af_disc = 0) THEN
    IF (ir_kyoten_rec.sales_bf_disc = 0) THEN
--//+UPD END   2009/02/23   CT058 K.Yamada
--//+UPD START 2009/02/10   CT019 M.Ohtsuki
--    ln_margin_rate := NULL;
      ln_margin_rate := 0;
--//+UPD END   2009/02/10   CT019 M.Ohtsuki
    ELSE
--//+UPD START 2009/02/23   CT058 K.Yamada
--    ln_margin_rate := ROUND(ir_kyoten_rec.margin / ir_kyoten_rec.sales_af_disc * 100, 2);
      ln_margin_rate := ROUND(ir_kyoten_rec.margin / ir_kyoten_rec.sales_bf_disc * 100, 2);
--//+UPD END   2009/02/23   CT058 K.Yamada
      ln_margin_rate := CASE WHEN ABS(ln_margin_rate) > cv_max_margin_rate THEN cv_max_rate ELSE ln_margin_rate END;
    END IF;

    -- �o�^����
    ior_work_rec.group_cd            := ir_kyoten_rec.location_cd;   -- ���_�R�[�h
    ior_work_rec.sales_bf_disc_nm    := gv_sales_bf_disc_nm;         -- �l���O���㖼
    ior_work_rec.sales_disc_nm       := gv_sales_disc_nm;            -- ����l����
    ior_work_rec.receipt_disc_nm     := gv_receipt_disc_nm;          -- �����l����
    ior_work_rec.sales_af_disc_nm    := gv_sales_af_disc_nm;         -- �l���㔄�㖼
    ior_work_rec.margin_nm           := gv_margin_amt_nm;            -- �e���v�z��
    ior_work_rec.margin_rate_nm      := gv_margin_rate_nm;           -- �e���v����
    CASE ir_kyoten_rec.month_no
    WHEN 5 THEN
      ior_work_rec.sales_bf_disc05     := ir_kyoten_rec.sales_bf_disc; -- �l���O����T��
      ior_work_rec.sales_disc05        := ir_kyoten_rec.sales_disc;    -- ����l���T��
      ior_work_rec.receipt_disc05      := ir_kyoten_rec.receipt_disc;  -- �����l���T��
      ior_work_rec.sales_af_disc05     := ir_kyoten_rec.sales_af_disc; -- �l���㔄��T��
      ior_work_rec.margin05            := ir_kyoten_rec.margin;        -- �e���v�z�T��
      ior_work_rec.margin_rate05       := ln_margin_rate;              -- �e���v���T��
      ior_work_rec.sales_disc_total    := NVL(ior_work_rec.sales_disc_total, 0)    + ir_kyoten_rec.sales_disc;    -- ����l���N�Ԍv
      ior_work_rec.receipt_disc_total  := NVL(ior_work_rec.receipt_disc_total, 0)  + ir_kyoten_rec.receipt_disc;  -- �����l���N�Ԍv
      ior_work_rec.margin_total        := NVL(ior_work_rec.margin_total, 0)        + ir_kyoten_rec.margin;        -- �e���v�z�N�Ԍv
      ior_work_rec.sales_bf_disc_total := NVL(ior_work_rec.sales_bf_disc_total, 0) + ir_kyoten_rec.sales_bf_disc; -- �l���O����N�Ԍv
      ior_work_rec.sales_af_disc_total := NVL(ior_work_rec.sales_af_disc_total, 0) + ir_kyoten_rec.sales_af_disc; -- �l���㔄��N�Ԍv
    WHEN 6 THEN
      ior_work_rec.sales_bf_disc06     := ir_kyoten_rec.sales_bf_disc; -- �l���O����U��
      ior_work_rec.sales_disc06        := ir_kyoten_rec.sales_disc;    -- ����l���U��
      ior_work_rec.receipt_disc06      := ir_kyoten_rec.receipt_disc;  -- �����l���U��
      ior_work_rec.sales_af_disc06     := ir_kyoten_rec.sales_af_disc; -- �l���㔄��U��
      ior_work_rec.margin06            := ir_kyoten_rec.margin;        -- �e���v�z�U��
      ior_work_rec.margin_rate06       := ln_margin_rate;              -- �e���v���U��
      ior_work_rec.sales_disc_total    := NVL(ior_work_rec.sales_disc_total, 0)    + ir_kyoten_rec.sales_disc;    -- ����l���N�Ԍv
      ior_work_rec.receipt_disc_total  := NVL(ior_work_rec.receipt_disc_total, 0)  + ir_kyoten_rec.receipt_disc;  -- �����l���N�Ԍv
      ior_work_rec.margin_total        := NVL(ior_work_rec.margin_total, 0)        + ir_kyoten_rec.margin;        -- �e���v�z�N�Ԍv
      ior_work_rec.sales_bf_disc_total := NVL(ior_work_rec.sales_bf_disc_total, 0) + ir_kyoten_rec.sales_bf_disc; -- �l���O����N�Ԍv
      ior_work_rec.sales_af_disc_total := NVL(ior_work_rec.sales_af_disc_total, 0) + ir_kyoten_rec.sales_af_disc; -- �l���㔄��N�Ԍv
    WHEN 7 THEN
      ior_work_rec.sales_bf_disc07     := ir_kyoten_rec.sales_bf_disc; -- �l���O����V��
      ior_work_rec.sales_disc07        := ir_kyoten_rec.sales_disc;    -- ����l���V��
      ior_work_rec.receipt_disc07      := ir_kyoten_rec.receipt_disc;  -- �����l���V��
      ior_work_rec.sales_af_disc07     := ir_kyoten_rec.sales_af_disc; -- �l���㔄��V��
      ior_work_rec.margin07            := ir_kyoten_rec.margin;        -- �e���v�z�V��
      ior_work_rec.margin_rate07       := ln_margin_rate;              -- �e���v���V��
      ior_work_rec.sales_disc_total    := NVL(ior_work_rec.sales_disc_total, 0)    + ir_kyoten_rec.sales_disc;    -- ����l���N�Ԍv
      ior_work_rec.receipt_disc_total  := NVL(ior_work_rec.receipt_disc_total, 0)  + ir_kyoten_rec.receipt_disc;  -- �����l���N�Ԍv
      ior_work_rec.margin_total        := NVL(ior_work_rec.margin_total, 0)        + ir_kyoten_rec.margin;        -- �e���v�z�N�Ԍv
      ior_work_rec.sales_bf_disc_total := NVL(ior_work_rec.sales_bf_disc_total, 0) + ir_kyoten_rec.sales_bf_disc; -- �l���O����N�Ԍv
      ior_work_rec.sales_af_disc_total := NVL(ior_work_rec.sales_af_disc_total, 0) + ir_kyoten_rec.sales_af_disc; -- �l���㔄��N�Ԍv
    WHEN 8 THEN
      ior_work_rec.sales_bf_disc08     := ir_kyoten_rec.sales_bf_disc; -- �l���O����W��
      ior_work_rec.sales_disc08        := ir_kyoten_rec.sales_disc;    -- ����l���W��
      ior_work_rec.receipt_disc08      := ir_kyoten_rec.receipt_disc;  -- �����l���W��
      ior_work_rec.sales_af_disc08     := ir_kyoten_rec.sales_af_disc; -- �l���㔄��W��
      ior_work_rec.margin08            := ir_kyoten_rec.margin;        -- �e���v�z�W��
      ior_work_rec.margin_rate08       := ln_margin_rate;              -- �e���v���W��
      ior_work_rec.sales_disc_total    := NVL(ior_work_rec.sales_disc_total, 0)    + ir_kyoten_rec.sales_disc;    -- ����l���N�Ԍv
      ior_work_rec.receipt_disc_total  := NVL(ior_work_rec.receipt_disc_total, 0)  + ir_kyoten_rec.receipt_disc;  -- �����l���N�Ԍv
      ior_work_rec.margin_total        := NVL(ior_work_rec.margin_total, 0)        + ir_kyoten_rec.margin;        -- �e���v�z�N�Ԍv
      ior_work_rec.sales_bf_disc_total := NVL(ior_work_rec.sales_bf_disc_total, 0) + ir_kyoten_rec.sales_bf_disc; -- �l���O����N�Ԍv
      ior_work_rec.sales_af_disc_total := NVL(ior_work_rec.sales_af_disc_total, 0) + ir_kyoten_rec.sales_af_disc; -- �l���㔄��N�Ԍv
    WHEN 9 THEN
      ior_work_rec.sales_bf_disc09     := ir_kyoten_rec.sales_bf_disc; -- �l���O����X��
      ior_work_rec.sales_disc09        := ir_kyoten_rec.sales_disc;    -- ����l���X��
      ior_work_rec.receipt_disc09      := ir_kyoten_rec.receipt_disc;  -- �����l���X��
      ior_work_rec.sales_af_disc09     := ir_kyoten_rec.sales_af_disc; -- �l���㔄��X��
      ior_work_rec.margin09            := ir_kyoten_rec.margin;        -- �e���v�z�X��
      ior_work_rec.margin_rate09       := ln_margin_rate;              -- �e���v���X��
      ior_work_rec.sales_disc_total    := NVL(ior_work_rec.sales_disc_total, 0)    + ir_kyoten_rec.sales_disc;    -- ����l���N�Ԍv
      ior_work_rec.receipt_disc_total  := NVL(ior_work_rec.receipt_disc_total, 0)  + ir_kyoten_rec.receipt_disc;  -- �����l���N�Ԍv
      ior_work_rec.margin_total        := NVL(ior_work_rec.margin_total, 0)        + ir_kyoten_rec.margin;        -- �e���v�z�N�Ԍv
      ior_work_rec.sales_bf_disc_total := NVL(ior_work_rec.sales_bf_disc_total, 0) + ir_kyoten_rec.sales_bf_disc; -- �l���O����N�Ԍv
      ior_work_rec.sales_af_disc_total := NVL(ior_work_rec.sales_af_disc_total, 0) + ir_kyoten_rec.sales_af_disc; -- �l���㔄��N�Ԍv
    WHEN 10 THEN
      ior_work_rec.sales_bf_disc10     := ir_kyoten_rec.sales_bf_disc; -- �l���O����P�O��
      ior_work_rec.sales_disc10        := ir_kyoten_rec.sales_disc;    -- ����l���P�O��
      ior_work_rec.receipt_disc10      := ir_kyoten_rec.receipt_disc;  -- �����l���P�O��
      ior_work_rec.sales_af_disc10     := ir_kyoten_rec.sales_af_disc; -- �l���㔄��O��
      ior_work_rec.margin10            := ir_kyoten_rec.margin;        -- �e���v�z�P�O��
      ior_work_rec.margin_rate10       := ln_margin_rate;              -- �e���v���P�O��
      ior_work_rec.sales_disc_total    := NVL(ior_work_rec.sales_disc_total, 0)    + ir_kyoten_rec.sales_disc;    -- ����l���N�Ԍv
      ior_work_rec.receipt_disc_total  := NVL(ior_work_rec.receipt_disc_total, 0)  + ir_kyoten_rec.receipt_disc;  -- �����l���N�Ԍv
      ior_work_rec.margin_total        := NVL(ior_work_rec.margin_total, 0)        + ir_kyoten_rec.margin;        -- �e���v�z�N�Ԍv
      ior_work_rec.sales_bf_disc_total := NVL(ior_work_rec.sales_bf_disc_total, 0) + ir_kyoten_rec.sales_bf_disc; -- �l���O����N�Ԍv
      ior_work_rec.sales_af_disc_total := NVL(ior_work_rec.sales_af_disc_total, 0) + ir_kyoten_rec.sales_af_disc; -- �l���㔄��N�Ԍv
    WHEN 11 THEN
      ior_work_rec.sales_bf_disc11     := ir_kyoten_rec.sales_bf_disc; -- �l���O����P�P��
      ior_work_rec.sales_disc11        := ir_kyoten_rec.sales_disc;    -- ����l���P�P��
      ior_work_rec.receipt_disc11      := ir_kyoten_rec.receipt_disc;  -- �����l���P�P��
      ior_work_rec.sales_af_disc11     := ir_kyoten_rec.sales_af_disc; -- �l���㔄��P��
      ior_work_rec.margin11            := ir_kyoten_rec.margin;        -- �e���v�z�P�P��
      ior_work_rec.margin_rate11       := ln_margin_rate;              -- �e���v���P�P��
      ior_work_rec.sales_disc_total    := NVL(ior_work_rec.sales_disc_total, 0)    + ir_kyoten_rec.sales_disc;    -- ����l���N�Ԍv
      ior_work_rec.receipt_disc_total  := NVL(ior_work_rec.receipt_disc_total, 0)  + ir_kyoten_rec.receipt_disc;  -- �����l���N�Ԍv
      ior_work_rec.margin_total        := NVL(ior_work_rec.margin_total, 0)        + ir_kyoten_rec.margin;        -- �e���v�z�N�Ԍv
      ior_work_rec.sales_bf_disc_total := NVL(ior_work_rec.sales_bf_disc_total, 0) + ir_kyoten_rec.sales_bf_disc; -- �l���O����N�Ԍv
      ior_work_rec.sales_af_disc_total := NVL(ior_work_rec.sales_af_disc_total, 0) + ir_kyoten_rec.sales_af_disc; -- �l���㔄��N�Ԍv
    WHEN 12 THEN
      ior_work_rec.sales_bf_disc12     := ir_kyoten_rec.sales_bf_disc; -- �l���O����P�Q��
      ior_work_rec.sales_disc12        := ir_kyoten_rec.sales_disc;    -- ����l���P�Q��
      ior_work_rec.receipt_disc12      := ir_kyoten_rec.receipt_disc;  -- �����l���P�Q��
      ior_work_rec.sales_af_disc12     := ir_kyoten_rec.sales_af_disc; -- �l���㔄��P�Q��
      ior_work_rec.margin12            := ir_kyoten_rec.margin;        -- �e���v�z�P�Q��
      ior_work_rec.margin_rate12       := ln_margin_rate;              -- �e���v���P�Q��
      ior_work_rec.sales_disc_total    := NVL(ior_work_rec.sales_disc_total, 0)    + ir_kyoten_rec.sales_disc;    -- ����l���N�Ԍv
      ior_work_rec.receipt_disc_total  := NVL(ior_work_rec.receipt_disc_total, 0)  + ir_kyoten_rec.receipt_disc;  -- �����l���N�Ԍv
      ior_work_rec.margin_total        := NVL(ior_work_rec.margin_total, 0)        + ir_kyoten_rec.margin;        -- �e���v�z�N�Ԍv
      ior_work_rec.sales_bf_disc_total := NVL(ior_work_rec.sales_bf_disc_total, 0) + ir_kyoten_rec.sales_bf_disc; -- �l���O����N�Ԍv
      ior_work_rec.sales_af_disc_total := NVL(ior_work_rec.sales_af_disc_total, 0) + ir_kyoten_rec.sales_af_disc; -- �l���㔄��N�Ԍv
    WHEN 1 THEN
      ior_work_rec.sales_bf_disc01     := ir_kyoten_rec.sales_bf_disc; -- �l���O����P��
      ior_work_rec.sales_disc01        := ir_kyoten_rec.sales_disc;    -- ����l���P��
      ior_work_rec.receipt_disc01      := ir_kyoten_rec.receipt_disc;  -- �����l���P��
      ior_work_rec.sales_af_disc01     := ir_kyoten_rec.sales_af_disc; -- �l���㔄��P��
      ior_work_rec.margin01            := ir_kyoten_rec.margin;        -- �e���v�z�P��
      ior_work_rec.margin_rate01       := ln_margin_rate;              -- �e���v���P��
      ior_work_rec.sales_disc_total    := NVL(ior_work_rec.sales_disc_total, 0)    + ir_kyoten_rec.sales_disc;    -- ����l���N�Ԍv
      ior_work_rec.receipt_disc_total  := NVL(ior_work_rec.receipt_disc_total, 0)  + ir_kyoten_rec.receipt_disc;  -- �����l���N�Ԍv
      ior_work_rec.margin_total        := NVL(ior_work_rec.margin_total, 0)        + ir_kyoten_rec.margin;        -- �e���v�z�N�Ԍv
      ior_work_rec.sales_bf_disc_total := NVL(ior_work_rec.sales_bf_disc_total, 0) + ir_kyoten_rec.sales_bf_disc; -- �l���O����N�Ԍv
      ior_work_rec.sales_af_disc_total := NVL(ior_work_rec.sales_af_disc_total, 0) + ir_kyoten_rec.sales_af_disc; -- �l���㔄��N�Ԍv
    WHEN 2 THEN
      ior_work_rec.sales_bf_disc02     := ir_kyoten_rec.sales_bf_disc; -- �l���O����Q��
      ior_work_rec.sales_disc02        := ir_kyoten_rec.sales_disc;    -- ����l���Q��
      ior_work_rec.receipt_disc02      := ir_kyoten_rec.receipt_disc;  -- �����l���Q��
      ior_work_rec.sales_af_disc02     := ir_kyoten_rec.sales_af_disc; -- �l���㔄��Q��
      ior_work_rec.margin02            := ir_kyoten_rec.margin;        -- �e���v�z�Q��
      ior_work_rec.margin_rate02       := ln_margin_rate;              -- �e���v���Q��
      ior_work_rec.sales_disc_total    := NVL(ior_work_rec.sales_disc_total, 0)    + ir_kyoten_rec.sales_disc;    -- ����l���N�Ԍv
      ior_work_rec.receipt_disc_total  := NVL(ior_work_rec.receipt_disc_total, 0)  + ir_kyoten_rec.receipt_disc;  -- �����l���N�Ԍv
      ior_work_rec.margin_total        := NVL(ior_work_rec.margin_total, 0)        + ir_kyoten_rec.margin;        -- �e���v�z�N�Ԍv
      ior_work_rec.sales_bf_disc_total := NVL(ior_work_rec.sales_bf_disc_total, 0) + ir_kyoten_rec.sales_bf_disc; -- �l���O����N�Ԍv
      ior_work_rec.sales_af_disc_total := NVL(ior_work_rec.sales_af_disc_total, 0) + ir_kyoten_rec.sales_af_disc; -- �l���㔄��N�Ԍv
    WHEN 3 THEN
      ior_work_rec.sales_bf_disc03     := ir_kyoten_rec.sales_bf_disc; -- �l���O����R��
      ior_work_rec.sales_disc03        := ir_kyoten_rec.sales_disc;    -- ����l���R��
      ior_work_rec.receipt_disc03      := ir_kyoten_rec.receipt_disc;  -- �����l���R��
      ior_work_rec.sales_af_disc03     := ir_kyoten_rec.sales_af_disc; -- �l���㔄��R��
      ior_work_rec.margin03            := ir_kyoten_rec.margin;        -- �e���v�z�R��
      ior_work_rec.margin_rate03       := ln_margin_rate;              -- �e���v���R��
      ior_work_rec.sales_disc_total    := NVL(ior_work_rec.sales_disc_total, 0)    + ir_kyoten_rec.sales_disc;    -- ����l���N�Ԍv
      ior_work_rec.receipt_disc_total  := NVL(ior_work_rec.receipt_disc_total, 0)  + ir_kyoten_rec.receipt_disc;  -- �����l���N�Ԍv
      ior_work_rec.margin_total        := NVL(ior_work_rec.margin_total, 0)        + ir_kyoten_rec.margin;        -- �e���v�z�N�Ԍv
      ior_work_rec.sales_bf_disc_total := NVL(ior_work_rec.sales_bf_disc_total, 0) + ir_kyoten_rec.sales_bf_disc; -- �l���O����N�Ԍv
      ior_work_rec.sales_af_disc_total := NVL(ior_work_rec.sales_af_disc_total, 0) + ir_kyoten_rec.sales_af_disc; -- �l���㔄��N�Ԍv
    WHEN 4 THEN
      ior_work_rec.sales_bf_disc04     := ir_kyoten_rec.sales_bf_disc; -- �l���O����S��
      ior_work_rec.sales_disc04        := ir_kyoten_rec.sales_disc;    -- ����l���S��
      ior_work_rec.receipt_disc04      := ir_kyoten_rec.receipt_disc;  -- �����l���S��
      ior_work_rec.sales_af_disc04     := ir_kyoten_rec.sales_af_disc; -- �l���㔄��S��
      ior_work_rec.margin04            := ir_kyoten_rec.margin;        -- �e���v�z�S��
      ior_work_rec.margin_rate04       := ln_margin_rate;              -- �e���v���S��
      ior_work_rec.sales_disc_total    := NVL(ior_work_rec.sales_disc_total, 0)    + ir_kyoten_rec.sales_disc;    -- ����l���N�Ԍv
      ior_work_rec.receipt_disc_total  := NVL(ior_work_rec.receipt_disc_total, 0)  + ir_kyoten_rec.receipt_disc;  -- �����l���N�Ԍv
      ior_work_rec.margin_total        := NVL(ior_work_rec.margin_total, 0)        + ir_kyoten_rec.margin;        -- �e���v�z�N�Ԍv
      ior_work_rec.sales_bf_disc_total := NVL(ior_work_rec.sales_bf_disc_total, 0) + ir_kyoten_rec.sales_bf_disc; -- �l���O����N�Ԍv
      ior_work_rec.sales_af_disc_total := NVL(ior_work_rec.sales_af_disc_total, 0) + ir_kyoten_rec.sales_af_disc; -- �l���㔄��N�Ԍv
    ELSE
      NULL;
    END CASE;
--
    --==============================================================
    --���b�Z�[�W�o�́i�G���[�ȊO�j������K�v������ꍇ�͏������L�q
    --==============================================================
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
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END set_kyoten_data;
--
  /**********************************************************************************
   * Procedure Name   : output_check_list
   * Description      : �`�F�b�N���X�g�f�[�^�o��(A-15)
   ***********************************************************************************/
  PROCEDURE output_check_list(
    iv_yyyy         IN  VARCHAR2,            -- 1.�Ώ۔N�x
    iv_kyoten_cd    IN  VARCHAR2,            -- 2.���_�R�[�h
    iv_kyoten_nm    IN  VARCHAR2,            -- 3.���_��
    ov_errbuf       OUT NOCOPY VARCHAR2,     --   �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode      OUT NOCOPY VARCHAR2,     --   ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg       OUT NOCOPY VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'output_check_list'; -- �v���O������
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
    cv_sep_com           CONSTANT VARCHAR2(1)  := ',';
    cv_sep_wquot         CONSTANT VARCHAR2(1)  := '"';
--
    -- *** ���[�J���ϐ� ***
    ln_cnt               NUMBER;              -- ����
    lv_header            VARCHAR2(4000);      -- CSV�o�͗p�w�b�_���
    lv_csv_data          VARCHAR2(4000);      -- CSV�o�͗p�f�[�^�i�[
    lv_kyoten_nm         VARCHAR2(100);       -- ���_����

    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    -- CSV�o�͗p�S�f�[�^
    CURSOR output_all_cur
    IS
      SELECT
        -- toroku_no                  -- �o�͏�
           cv_sep_wquot || xti.code || cv_sep_wquot                       -- �R�[�h
        || cv_sep_com || cv_sep_wquot || xti.code_nm || cv_sep_wquot      -- �R�[�h����
        || cv_sep_com || cv_sep_wquot || xti.item_nm || cv_sep_wquot      -- ���ږ�
        || DECODE(xti.item_nm, gv_margin_rate_nm, (
                     cv_sep_com || TO_CHAR(xti.data_05)                  -- �T��
                  || cv_sep_com || TO_CHAR(xti.data_06)                  -- �U��
                  || cv_sep_com || TO_CHAR(xti.data_07)                  -- �V��
                  || cv_sep_com || TO_CHAR(xti.data_08)                  -- �W��
                  || cv_sep_com || TO_CHAR(xti.data_09)                  -- �X��
                  || cv_sep_com || TO_CHAR(xti.data_10)                  -- �P�O��
                  || cv_sep_com || TO_CHAR(xti.data_11)                  -- �P�P��
                  || cv_sep_com || TO_CHAR(xti.data_12)                  -- �P�Q��
                  || cv_sep_com || TO_CHAR(xti.data_01)                  -- �P��
                  || cv_sep_com || TO_CHAR(xti.data_02)                  -- �Q��
                  || cv_sep_com || TO_CHAR(xti.data_03)                  -- �R��
                  || cv_sep_com || TO_CHAR(xti.data_04)                  -- �S��
                  || cv_sep_com || TO_CHAR(xti.total)                    -- �N�Ԍv
                ),(
                     cv_sep_com || TO_CHAR(ROUND(xti.data_05/1000))      -- �T��
                  || cv_sep_com || TO_CHAR(ROUND(xti.data_06/1000))      -- �U��
                  || cv_sep_com || TO_CHAR(ROUND(xti.data_07/1000))      -- �V��
                  || cv_sep_com || TO_CHAR(ROUND(xti.data_08/1000))      -- �W��
                  || cv_sep_com || TO_CHAR(ROUND(xti.data_09/1000))      -- �X��
                  || cv_sep_com || TO_CHAR(ROUND(xti.data_10/1000))      -- �P�O��
                  || cv_sep_com || TO_CHAR(ROUND(xti.data_11/1000))      -- �P�P��
                  || cv_sep_com || TO_CHAR(ROUND(xti.data_12/1000))      -- �P�Q��
                  || cv_sep_com || TO_CHAR(ROUND(xti.data_01/1000))      -- �P��
                  || cv_sep_com || TO_CHAR(ROUND(xti.data_02/1000))      -- �Q��
                  || cv_sep_com || TO_CHAR(ROUND(xti.data_03/1000))      -- �R��
                  || cv_sep_com || TO_CHAR(ROUND(xti.data_04/1000))      -- �S��
                  || cv_sep_com || TO_CHAR(ROUND(xti.total/1000))        -- �N�Ԍv
                ))
        output_list
      FROM
        xxcsm_tmp_item_plan_gun   xti   -- ���i�v��Q�ʃ��[�N�e�[�u��
      ORDER BY
        xti.toroku_no                   -- �o�͏�
    ;

--

  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--

    -- �S���_�̏ꍇ
    IF (gb_all_kyoten = TRUE) THEN
      -- �u�S���_�v�擾
      SELECT
        xlav.location_nm   location_nm
      INTO
        lv_kyoten_nm
      FROM
        xxcsm_location_all_v    xlav
      WHERE
        xlav.location_cd = iv_kyoten_cd
      ;
    ELSE
      lv_kyoten_nm := iv_kyoten_nm;
    END IF;

    lv_header := xxccp_common_pkg.get_msg(
                    iv_application  => cv_xxcsm
                   ,iv_name         => cv_lst_head_msg
                   ,iv_token_name1  => cv_tkn_cd_kyoten
                   ,iv_token_value1 => iv_kyoten_cd
                   ,iv_token_name2  => cv_tkn_nm_kyoten
                   ,iv_token_value2 => lv_kyoten_nm
                   ,iv_token_name3  => cv_tkn_cd_tsym
                   ,iv_token_value3 => iv_yyyy
                   ,iv_token_name4  => cv_tkn_nichiji
                   ,iv_token_value4 => TO_CHAR(gd_sysdate, 'YYYY/MM/DD HH24:MI:SS')
                 );
    -- �f�[�^�o��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_header
    );

    OPEN output_all_cur();

    <<output_all_loop>>
    LOOP
      FETCH output_all_cur INTO lv_csv_data;
      EXIT WHEN output_all_cur%NOTFOUND;

      -- �f�[�^�o��
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_csv_data
      );
    END LOOP output_all_loop;
    CLOSE output_all_cur;

--
    --==============================================================
    --���b�Z�[�W�o�́i�G���[�ȊO�j������K�v������ꍇ�͏������L�q
    --==============================================================
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
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END output_check_list;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    iv_yyyy         IN  VARCHAR2,     -- 1.�Ώ۔N�x
    iv_kyoten_cd    IN  VARCHAR2,     -- 2.���_�R�[�h
    ov_errbuf       OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode      OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg       OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'submain'; -- �v���O������
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
    cv_appl_short_name CONSTANT VARCHAR2(10)  := 'XXCCP';            -- �A�h�I���F���ʁEIF�̈�
    cv_target_rec_msg  CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90000'; -- �Ώی������b�Z�[�W
    cv_success_rec_msg CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90001'; -- �����������b�Z�[�W
    cv_error_rec_msg   CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90002'; -- �G���[�������b�Z�[�W
    cv_skip_rec_msg    CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90003'; -- �X�L�b�v�������b�Z�[�W
    cv_cnt_token       CONSTANT VARCHAR2(10)  := 'COUNT';            -- �������b�Z�[�W�p�g�[�N����
--
    cv_exit_group_cd   CONSTANT VARCHAR2(10)  := '!';                -- �ŏI���i�Q�R�[�h
--
    -- *** ���[�J���ϐ� ***
    lt_group_cd            xxcsm_item_plan_lines.item_group_no%TYPE; -- ���i�Q�R�[�h
    lt_kyoten_cd           xxcsm_item_plan_headers.location_cd%TYPE; -- ���_�R�[�h
    lt_pre_group_cd        xxcsm_item_plan_lines.item_group_no%TYPE; -- ���i�Q�R�[�h�i�O���R�[�h�j
    lt_pre_kyoten_cd       xxcsm_item_plan_headers.location_cd%TYPE; -- ���_�R�[�h�i�O���R�[�h�j

    lv_kyoten_nm           VARCHAR2(100); -- ���_���ޔ�p
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================

    -- ���i�Q�ϐ����R�[�h�^
    lr_work_gun_rec         g_work_gun_rtype;
    -- �Q�v�ϐ����R�[�h�^
    lr_work_gun_sum_rec     g_work_gun_rtype;
    -- ���_�ϐ����R�[�h�^
    lr_work_kyoten_rec      g_work_gun_rtype;
--
--//+ADD START 2009/02/10   CT005 M.Ohtsuki
    no_data_expt            EXCEPTION;                                                              -- �f�[�^0���̏ꍇ
--//+ADD END   2009/02/10   CT005 M.Ohtsuki
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
    --*********************************************
    --***      MD.050�̃t���[�}��\��           ***
    --***      ����Ə������̌Ăяo�����s��     ***
    --*********************************************
--
    -- �O���[�o���ϐ��̏�����
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
    gn_warn_cnt   := 0;

    -- ===============================
    -- ��������(A-1)
    -- ===============================
    init(                                   -- init���R�[��
       iv_yyyy                              -- �Ώ۔N�x
      ,iv_kyoten_cd                         -- ���_�R�[�h
      ,lv_errbuf                            -- �G���[�E���b�Z�[�W
      ,lv_retcode                           -- ���^�[���E�R�[�h
      ,lv_errmsg                            -- ���[�U�[�E�G���[�E���b�Z�[�W
      );
    IF (lv_retcode = cv_status_error) THEN  -- �߂�l���ُ�̏ꍇ
      RAISE global_process_expt;
    END IF;
--
    -- =============================================
    -- �N�ԏ��i�v��f�[�^���݃`�F�b�N(A-2)
    -- =============================================
    chk_plandata(
              iv_yyyy              -- �Ώ۔N�x
             ,iv_kyoten_cd         -- ���_�R�[�h
             ,lv_errbuf            -- �G���[�E���b�Z�[�W
             ,lv_retcode           -- ���^�[���E�R�[�h
             ,lv_errmsg);
    -- ��O����
--//+UPD START 2009/02/10   CT005 M.Ohtsuki
--    IF (lv_retcode <> cv_status_normal) THEN
--      --(�G���[����)
--      gn_error_cnt := gn_error_cnt + 1;
--      RAISE global_process_expt;
--    END IF;
--
--    ��������������������������������������������������������
    IF (lv_retcode = cv_status_warn) THEN
      --(�G���[����)
      gn_error_cnt := gn_error_cnt + 1;
      RAISE no_data_expt;
    ELSIF (lv_retcode = cv_status_error) THEN
      gn_error_cnt := gn_error_cnt + 1;
      RAISE global_process_expt;
    END IF;
--//+UPD END   2009/02/10   CT005 M.Ohtsuki
    IF (gb_all_kyoten = FALSE) THEN--�B
      -- =============================================
      -- ���i�Q�f�[�^�̒��o(A-3)
      -- =============================================
      OPEN item_gun_cur(TO_NUMBER(iv_yyyy), iv_kyoten_cd);
      gn_target_cnt := gn_target_cnt + 1;

      <<loop1>>
      LOOP
        FETCH item_gun_cur INTO item_gun_rec;

        lt_pre_group_cd := lt_group_cd;
        IF item_gun_cur%NOTFOUND THEN
          lt_group_cd     := cv_exit_group_cd;
        ELSE
          lt_group_cd     := item_gun_rec.group_cd;
        END IF;

        -- ���i�Q���ς������
        IF (lt_group_cd <> lt_pre_group_cd) THEN

          -- =============================================
          -- ���i�Q���̂̎擾����єN�Ԍv�̑e�����Z�o(A-4)
          -- =============================================
          set_gun_name(
                  lr_work_gun_rec      -- ���i�Q�ϐ����R�[�h
                 ,lv_errbuf            -- �G���[�E���b�Z�[�W
                 ,lv_retcode           -- ���^�[���E�R�[�h
                 ,lv_errmsg);
          -- ��O����
          IF (lv_retcode = cv_status_error) THEN
            --(�G���[����)
            gn_error_cnt := gn_error_cnt + 1;
            RAISE global_process_expt;
          END IF;

          -- =============================================
          -- ���i�Q�����i�v��Q�ʃ��[�N�e�[�u���֓o�^(A-5)
          -- =============================================
          insert_data(
                  lr_work_gun_rec      -- ���i�Q�ϐ����R�[�h
                 ,lv_errbuf            -- �G���[�E���b�Z�[�W
                 ,lv_retcode           -- ���^�[���E�R�[�h
                 ,lv_errmsg);
          -- ��O����
          IF (lv_retcode = cv_status_error) THEN
            --(�G���[����)
            gn_error_cnt := gn_error_cnt + 1;
            RAISE global_process_expt;
          END IF;
          lr_work_gun_rec := NULL;
        END IF;

        EXIT WHEN item_gun_cur%NOTFOUND;

        -- =============================================
        -- ���i�Q�N�ԃf�[�^��ϐ��֐ݒ�(A-6)
        -- =============================================
        set_gun_data(
                item_gun_rec         -- �Ώۃ��R�[�h
               ,lr_work_gun_rec      -- ���i�Q�ϐ����R�[�h
               ,lv_errbuf            -- �G���[�E���b�Z�[�W
               ,lv_retcode           -- ���^�[���E�R�[�h
               ,lv_errmsg);
        -- ��O����
        IF (lv_retcode = cv_status_error) THEN
          --(�G���[����)
          gn_error_cnt := gn_error_cnt + 1;
          RAISE global_process_expt;
        END IF;


      END LOOP loop1;
      CLOSE item_gun_cur;
    END IF;

    -- �O���[�o���ϐ��̏�����
    gn_target_cnt := 0;

    -- =============================================
    -- ���_�f�[�^�̒��o(A-7)
    -- =============================================
    OPEN kyoten_cur(TO_NUMBER(iv_yyyy), iv_kyoten_cd, gt_allkyoten_cd);

    <<loop2>>
    LOOP
      FETCH kyoten_cur INTO kyoten_rec;

      lt_pre_kyoten_cd := lt_kyoten_cd;
      IF kyoten_cur%NOTFOUND THEN
        lt_kyoten_cd   := cv_exit_group_cd;
      ELSE
        lt_kyoten_cd   := kyoten_rec.location_cd;
      END IF;

      -- ���_�u���[�N
      IF (lt_kyoten_cd <> lt_pre_kyoten_cd) THEN
          gn_target_cnt := gn_target_cnt + 1;

        -- =============================================
        -- �Q�v�f�[�^�̒��o(A-8)
        -- =============================================
        OPEN item_gun_sum_cur(TO_NUMBER(iv_yyyy), lt_pre_kyoten_cd);

        <<loop3_1>>
        LOOP
          FETCH item_gun_sum_cur INTO item_gun_sum_rec;
          EXIT WHEN item_gun_sum_cur%NOTFOUND;

          -- =============================================
          -- �Q�v�̔N�ԃf�[�^��ϐ��֐ݒ�(A-9)
          -- =============================================
          set_gun_sum_data(
                  item_gun_sum_rec     -- �Ώۃ��R�[�h
                 ,lr_work_gun_sum_rec  -- �Q�v�ϐ����R�[�h
                 ,lv_errbuf            -- �G���[�E���b�Z�[�W
                 ,lv_retcode           -- ���^�[���E�R�[�h
                 ,lv_errmsg);
          -- ��O����
          IF (lv_retcode = cv_status_error) THEN
            --(�G���[����)
            gn_error_cnt := gn_error_cnt + 1;
            RAISE global_process_expt;
          END IF;
        END LOOP loop3_1;
        CLOSE item_gun_sum_cur;

        -- �e���_�̏ꍇ�͌Q�v���o��
        IF (gb_all_kyoten = FALSE) THEN
          -- =============================================
          -- �Q�v���̂̎擾����єN�Ԍv�̑e�����Z�o(A-10)
          -- =============================================
          set_gun_sum_name(
                  lr_work_gun_sum_rec  -- �Q�v�ϐ����R�[�h
                 ,lv_errbuf            -- �G���[�E���b�Z�[�W
                 ,lv_retcode           -- ���^�[���E�R�[�h
                 ,lv_errmsg);
          -- ��O����
          IF (lv_retcode = cv_status_error) THEN
            --(�G���[����)
            gn_error_cnt := gn_error_cnt + 1;
            RAISE global_process_expt;
          END IF;
          -- =============================================
          -- �Q�v�����i�v��Q�ʃ��[�N�e�[�u���֓o�^(A-11)
          -- =============================================
          insert_data(
                lr_work_gun_sum_rec  -- �Q�v�ϐ����R�[�h
               ,lv_errbuf            -- �G���[�E���b�Z�[�W
               ,lv_retcode           -- ���^�[���E�R�[�h
               ,lv_errmsg);
          -- ��O����
          IF (lv_retcode = cv_status_error) THEN
            --(�G���[����)
            gn_error_cnt := gn_error_cnt + 1;
            RAISE global_process_expt;
          END IF;
        END IF;

        -- =============================================
        -- ���_���̂̎擾����єN�Ԍv�̑e�����A���z�Z�o(A-12)
        -- =============================================
        set_kyoten_name(
                lr_work_gun_sum_rec  -- �Q�v�ϐ����R�[�h
               ,lr_work_kyoten_rec   -- ���_�ϐ����R�[�h
               ,lv_errbuf            -- �G���[�E���b�Z�[�W
               ,lv_retcode           -- ���^�[���E�R�[�h
               ,lv_errmsg);
        -- ��O����
        IF (lv_retcode = cv_status_error) THEN
          --(�G���[����)
          gn_error_cnt := gn_error_cnt + 1;
          RAISE global_process_expt;
        END IF;
        -- =============================================
        -- ���_�v�����i�v��Q�ʃ��[�N�e�[�u���֓o�^(A-13)
        -- =============================================
        insert_kyoten_data(
              lr_work_kyoten_rec   -- ���_�ϐ����R�[�h
             ,lv_errbuf            -- �G���[�E���b�Z�[�W
             ,lv_retcode           -- ���^�[���E�R�[�h
             ,lv_errmsg);
        -- ��O����
        IF (lv_retcode = cv_status_error) THEN
          --(�G���[����)
          gn_error_cnt := gn_error_cnt + 1;
          RAISE global_process_expt;
        END IF;
        lv_kyoten_nm  := lr_work_kyoten_rec.group_nm;       -- ���_���ޔ�
        lr_work_gun_sum_rec := NULL;
        lr_work_kyoten_rec  := NULL;
        gn_normal_cnt := gn_normal_cnt + 1;
      END IF;

      EXIT WHEN kyoten_cur%NOTFOUND;

      -- =============================================
      -- ���_�N�ԃf�[�^��ϐ��֐ݒ�(A-14)
      -- =============================================
      set_kyoten_data(
              kyoten_rec           -- ���_���R�[�h
             ,lr_work_kyoten_rec   -- ���_�ϐ����R�[�h
             ,lv_errbuf            -- �G���[�E���b�Z�[�W
             ,lv_retcode           -- ���^�[���E�R�[�h
             ,lv_errmsg);
      -- ��O����
      IF (lv_retcode = cv_status_error) THEN
        --(�G���[����)
        gn_error_cnt := gn_error_cnt + 1;
        RAISE global_process_expt;
      END IF;
    END LOOP loop2;
    CLOSE kyoten_cur;

    -- =============================================
    -- �`�F�b�N���X�g�f�[�^�o��(A-15)
    -- =============================================
    output_check_list(
                iv_yyyy              -- �Ώ۔N�x
               ,iv_kyoten_cd         -- ���_�R�[�h
               ,lv_kyoten_nm         -- ���_��
               ,lv_errbuf            -- �G���[�E���b�Z�[�W
               ,lv_retcode           -- ���^�[���E�R�[�h
               ,lv_errmsg);
    -- ��O����
    IF (lv_retcode = cv_status_error) THEN
      --(�G���[����)
      gn_error_cnt := gn_error_cnt + 1;
      RAISE global_process_expt;
    END IF;

--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
      -- *** �C�ӂŗ�O�������L�q���� ****
      -- �J�[�\���̃N���[�Y�������ɋL�q����
--//+ADD START 2009/02/10   CT005 M.Ohtsuki
    WHEN  no_data_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;
--//+ADD END 2009/02/10   CT005 M.Ohtsuki
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
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
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
    iv_yyyy       IN  VARCHAR2,      -- 1.�Ώ۔N�x
    iv_kyoten_cd  IN  VARCHAR2       -- 2.���_�R�[�h
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
    cv_which_log       CONSTANT VARCHAR2(10)  := 'LOG';              -- �o�͐�
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
    xxccp_common_pkg.put_log_header(
       iv_which   => cv_which_log
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
       iv_yyyy                                     -- �Ώ۔N�x
      ,iv_kyoten_cd                                -- ���_�R�[�h
      ,lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    --�G���[�o��
--*** UPD TEMPLETE Start****************************************
--    IF (lv_retcode = cv_status_error) THEN
--      FND_FILE.PUT_LINE(
--         which  => FND_FILE.OUTPUT
--        ,buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
--      );
--      FND_FILE.PUT_LINE(
--         which  => FND_FILE.LOG
--        ,buff   => lv_errbuf --�G���[���b�Z�[�W
--      );
--    END IF;
--    --��s�}��
--    FND_FILE.PUT_LINE(
--       which  => FND_FILE.OUTPUT
--      ,buff   => ''
--    );
/*����������������������������������������������������������*/
    IF (lv_retcode = cv_status_error) THEN
      IF (lv_errmsg IS NULL) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_xxcsm
                      ,iv_name         => cv_msg_00111
                     );
      END IF;
      --�G���[�o��
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff => lv_errbuf --�G���[���b�Z�[�W
      );
      --�����̐U��(�G���[�̏ꍇ�A�G���[������1���̂ݕ\��������B�j
      gn_target_cnt := 0;
      gn_normal_cnt := 0;
      gn_error_cnt  := 1;
      gn_warn_cnt   := 0;
    END IF;
--//+ADD START 2009/02/10   CT005 M.Ohtsuki
    IF (lv_retcode = cv_status_warn) THEN
      --�G���[�o��
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff => lv_errbuf --�G���[���b�Z�[�W
      );
    END IF;
--//+ADD START 2009/02/10   CT005 M.Ohtsuki
--*** UPD TEMPLETE End****************************************
    --��s�}��
    IF (lv_retcode <> cv_status_normal) THEN
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => ''
      );
    END IF;
    --�Ώی����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_target_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)
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
                    ,iv_token_value1 => TO_CHAR(gn_normal_cnt)
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
                    ,iv_token_value1 => TO_CHAR(gn_error_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --
    --�X�L�b�v�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_skip_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_warn_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
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
       which  => FND_FILE.LOG
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
END XXCSM002A07C;
/
