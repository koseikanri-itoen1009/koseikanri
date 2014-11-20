CREATE OR REPLACE PACKAGE BODY XXCSM002A10C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCSM002A10C(body)
 * Description      : ���i�v�惊�X�g�i�݌v�j�o��
 * MD.050           : ���i�v�惊�X�g�i�݌v�j�o�� MD050_CSM_002_A10
 * Version          : 1.8
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   ��������(A-1)
 *  chk_plandata           �N�ԏ��i�v��f�[�^���݃`�F�b�N(A-3)
 *  chk_propdata           �������σf�[�^���݃`�F�b�N(A-4)
 *  select_grp4_total_data �f�[�^�̒��o�i���i�Q�j(A-8)
 *  select_grp1_total_data �f�[�^�̒��o�i���i�敪�j(A-11)
 *  select_com_total_data  �f�[�^�̒��o�i���i���v�j(A-14)
 *  select_discount_data   �f�[�^�̒��o�i����l���^�����l���j(A-17)
 *  select_kyot_total_data �f�[�^�̒��o�i���_���v�j(A-19)
 *  insert_data            �f�[�^�o�^(A-7,10,13,16,18,21)
 *  output_check_list      �`�F�b�N���X�g�f�[�^�o��(A-22)
 *  loop_kyoten            ���_���[�v������
 *  loop_main              ���C�����[�v
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009-1-15      1.0   n.izumi         �V�K�쐬
 *  2009-02-09     1.1   M.Ohtsuki      �m��QCT_007�n�ގ��@�\���쓝��C��
 *  2009-02-20     1.2   M.Ohtsuki      �m��QCT_051�nCSV�o�̓t�H�[�}�b�g�̏C��
 *  2009-02-20     1.3   M.Ohtsuki      �m��QCT_053�n�}�C�i�X���i�̕s��̑Ή�
 *  2009-03-09     1.4   M.Ohtsuki      �m��QCT_078�n�s�v��SQL�̍폜�Ή�
 *  2009-05-07     1.5   M.Ohtsuki      �m��QT1_0858�n���_�R�[�h���o�����̕s���̑Ή�
 *  2009-07-15     1.6   M.Ohtsuki      �m0000678�n�Ώۃf�[�^0�����̃X�e�[�^�X�s��̑Ή�
 *  2011-01-05     1.7   SCS OuKou       [E_�{�ғ�_05803]
 *  2012-12-10     1.8   SCSK K.Taniguchi[E_�{�ғ�_09949] �V�������I���\�Ή�
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
  cv_pkg_name      CONSTANT VARCHAR2(100) := 'XXCSM002A10C';                    -- �p�b�P�[�W��
  cv_flg_y         CONSTANT VARCHAR2(1)   := 'Y';                               -- �t���OY
--//+ADD START E_�{�ғ�_09949 K.Taniguchi
  cv_flg_n         CONSTANT VARCHAR2(1)   := 'N';                               -- �t���ON
--//+ADD END E_�{�ғ�_09949 K.Taniguchi
  --���b�Z�[�W�[�R�[�h
  cv_prof_err_msg  CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00005';                -- �v���t�@�C���擾�G���[
--//+ADD START E_�{�ғ�_09949 K.Taniguchi
  cv_start_date_err_msg
                   CONSTANT VARCHAR2(100) := 'APP-XXCSM1-10168';                -- �N�x�J�n���擾�G���[
--//+ADD END E_�{�ғ�_09949 K.Taniguchi
  cv_noplandt_msg  CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00087';                -- ���i�v�斢�ݒ�
  cv_nopropdt_msg  CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00088';                -- ���i�v��P�i�ʈ�����������
  cv_lst_head_msg  CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00077';                -- �N�ԏ��i�v�惊�X�g�i�݌v�j�w�b�_�p
  cv_par_yyyy_msg  CONSTANT VARCHAR2(100) := 'APP-XXCSM1-10003';                -- �R���J�����g���̓p�����[�^(�Ώ۔N�x)
  cv_par_kyotn_msg CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00048';                -- �R���J�����g���̓p�����[�^(���_�R�[�h)
  cv_par_cost_kind_msg  CONSTANT VARCHAR2(100) := 'APP-XXCSM1-10017';           -- �R���J�����g���̓p�����[�^(�������)
  cv_par_level_msg CONSTANT VARCHAR2(100) := 'APP-XXCSM1-10004';                -- �R���J�����g���̓p�����[�^(�K�w)
--//+ADD START E_�{�ғ�_09949 K.Taniguchi
  cv_par_new_old_cost_cls_msg
                   CONSTANT VARCHAR2(100) := 'APP-XXCSM1-10167';                -- �R���J�����g���̓p�����[�^(�V�������敪)
--//+ADD END E_�{�ғ�_09949 K.Taniguchi
--//+ADD START 2009/02/12   CT007 M.Ohtsuki
  cv_nodata_msg    CONSTANT VARCHAR2(100) := 'APP-XXCSM1-10001';                -- �Ώۃf�[�^0���G���[���b�Z�[�W 
--//+ADD END   2009/02/12   CT007 M.Ohtsuki
  --�g�[�N��
  cv_tkn_cd_prof   CONSTANT VARCHAR2(100) := 'PROF_NAME';                       -- �J�X�^���E�v���t�@�C���E�I�v�V�����̉p��
  cv_tkn_cd_yyyy   CONSTANT VARCHAR2(100) := 'YYYY';                            -- �Ώ۔N�x
  cv_tkn_cd_tsym   CONSTANT VARCHAR2(100) := 'TAISYOU_YM';                      -- �Ώ۔N�x
  cv_tkn_cd_kyoten CONSTANT VARCHAR2(100) := 'KYOTEN_CD';                       -- ���_�R�[�h
  cv_tkn_nm_kyoten CONSTANT VARCHAR2(100) := 'KYOTEN_NM';                       -- ���_��
  cv_tkn_cost_kind CONSTANT VARCHAR2(100) := 'GENKA_CD';                        -- �������
  cv_tkn_cost_kind_nm CONSTANT VARCHAR2(100) := 'GENKA_NM';                     -- ������ʖ�
  cv_tkn_cd_level  CONSTANT VARCHAR2(100) := 'HIERARCHY_LEVEL';                 -- �K�w
  cv_tkn_nichiji   CONSTANT VARCHAR2(100) := 'SAKUSEI_NICHIJI';                 -- �쐬����
--//+ADD START E_�{�ғ�_09949 K.Taniguchi
  cv_tkn_new_old_cost_cls
                   CONSTANT VARCHAR2(100) := 'NEW_OLD_COST_CLASS';              -- �V�������敪
  cv_tkn_sobid     CONSTANT VARCHAR2(100) := 'SET_OF_BOOKS_ID';                 -- ��v����ID
  cv_tkn_process_date
                   CONSTANT VARCHAR2(100) := 'PROCESS_DATE';                    -- �Ɩ����t
--//+ADD END E_�{�ғ�_09949 K.Taniguchi
  cv_chk1_profile  CONSTANT VARCHAR2(100) := 'XXCSM1_CHECKLIST_ITEM_1';         -- �`�F�b�N���X�g���ږ��i���i���v�j�v���t�@�C����
  cv_chk2_profile  CONSTANT VARCHAR2(100) := 'XXCSM1_CHECKLIST_ITEM_2';         -- �`�F�b�N���X�g���ږ��i����l���j�v���t�@�C����
  cv_chk3_profile  CONSTANT VARCHAR2(100) := 'XXCSM1_CHECKLIST_ITEM_3';         -- �`�F�b�N���X�g���ږ��i�����l���j�v���t�@�C����
  cv_chk4_profile  CONSTANT VARCHAR2(100) := 'XXCSM1_PLANLIST_ITEM_5';          -- �v�惊�X�g���ږ��i���_�v�j�v���t�@�C����
--//+ADD START E_�{�ғ�_09949 K.Taniguchi
  cv_gl_set_of_bks_id_profile
                   CONSTANT VARCHAR2(100) := 'GL_SET_OF_BKS_ID';                -- ��v����ID�v���t�@�C����
--//+ADD END E_�{�ғ�_09949 K.Taniguchi
--���̑�
  cv_kind_of_cost  CONSTANT VARCHAR2(100) := 'XXCSM1_KIND_OF_COST';             -- ������ʖ��擾�p
  cv_lookup_type   CONSTANT VARCHAR2(100) := 'XXCSM1_FORM_PARAMETER_VALUE';     -- �S���_�R�[�h�擾�p
  cv_item_kbn      CONSTANT VARCHAR2(1)   := '0';                               -- ���i�敪�i���i�Q�j�����Ă������
  cv_leaf          CONSTANT VARCHAR2(1)   := 'A';                               -- ���i�敪�iLEAF�j
  cv_drink         CONSTANT VARCHAR2(1)   := 'C';                               -- ���i�敪�iDRINK�j
  cv_sonota        CONSTANT VARCHAR2(1)   := 'D';                               -- ���i�敪�i���̑��j
  cv_nebiki        CONSTANT VARCHAR2(1)   := 'N';                               -- ���i�敪�i�l���j
  cv_kyoten_kei    CONSTANT VARCHAR2(1)   := 'K';                               -- ���i�敪�i���_�v���j
  cv_cost_base     CONSTANT VARCHAR2(2)   := '10';                              -- ������ʁi�W���j
  cv_cost_bus      CONSTANT VARCHAR2(2)   := '20';                              -- ������ʁi�c�Ɓj
--//+ADD START E_�{�ғ�_09949 K.Taniguchi
  cv_whse_code     CONSTANT VARCHAR2(3)   := '000';                             -- �����q��
  cv_new_cost      CONSTANT VARCHAR2(10)  := '10';                              -- �p�����[�^�F�V�������敪�i�V�����j
  cv_old_cost      CONSTANT VARCHAR2(10)  := '20';                              -- �p�����[�^�F�V�������敪�i�������j
--//+ADD END E_�{�ғ�_09949 K.Taniguchi

--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  TYPE g_sum_data_rtype IS RECORD(
       group_cd                xxcsm_tmp_item_plan_sales_sum.group4_cd%TYPE     -- ���i�Q�R�[�h
      ,group_nm                xxcsm_tmp_item_plan_sales_sum.group4_nm%TYPE     -- ���i�Q����
      ,con_price               xxcsm_tmp_item_plan_sales_sum.con_price%TYPE     -- �艿
      ,amount                  xxcsm_tmp_item_plan_sales_sum.amount%TYPE        -- ����
      ,price_multi_amount      xxcsm_tmp_item_plan_sales_sum.sales_budget%TYPE  -- �艿 * ����
      ,sales_budget            xxcsm_tmp_item_plan_sales_sum.sales_budget%TYPE  -- ����
      ,cost                    xxcsm_tmp_item_plan_sales_sum.cost%TYPE          -- ����
      ,margin                  xxcsm_tmp_item_plan_sales_sum.margin%TYPE        -- �e���v�z
   );
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gd_sysdate           DATE;
--//+ADD START E_�{�ғ�_09949 K.Taniguchi
  gd_process_date      DATE;                                                    -- �Ɩ��������t
  gn_gl_set_of_bks_id  NUMBER;                                                  -- ��v����ID
  gd_gl_start_date     DATE;                                                    -- �N�����̔N�x�J�n��
--//+ADD END E_�{�ғ�_09949 K.Taniguchi
  gt_allkyoten_cd      fnd_lookup_values.lookup_code%TYPE;                      -- �S���_�R�[�h
  gv_total_com_nm      xxcsm_tmp_item_plan_sales_sum.item_nm%TYPE;              -- �v�惊�X�g���ږ��i���i���v�j
  gv_sales_disc_nm     xxcsm_tmp_item_plan_sales_sum.item_nm%TYPE;              -- �v�惊�X�g���ږ��i����l���j
  gv_receipt_disc_nm   xxcsm_tmp_item_plan_sales_sum.item_nm%TYPE;              -- �v�惊�X�g���ږ��i�����l���j
  gv_kyoten_kei_nm     xxcsm_tmp_item_plan_sales_sum.item_nm%TYPE;              -- �v�惊�X�g���ږ��i���_�v�j
  gv_cost_kind_nm      VARCHAR2(100);                                           -- ������ʖ�
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    iv_yyyy       IN  VARCHAR2,            -- 1.�Ώ۔N�x
    iv_kyoten_cd  IN  VARCHAR2,            -- 2.���_�R�[�h
    iv_cost_kind  IN  VARCHAR2,            -- 3.�������
    iv_level      IN  VARCHAR2,            -- 4.�K�w
--//+ADD START E_�{�ғ�_09949 K.Taniguchi
    iv_p_new_old_cost_class
                  IN  VARCHAR2,            -- 5.�V�������敪
--//+ADD END E_�{�ғ�_09949 K.Taniguchi
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   �G���[�E���b�Z�[�W              --# �Œ� #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   ���^�[���E�R�[�h                --# �Œ� #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W    --# �Œ� #
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
    -- ===========================
    -- ������ʖ��擾
    -- ===========================
    BEGIN
      SELECT ffvv.description                                                   --�l�Z�b�g����.�K�p 
        INTO gv_cost_kind_nm
        FROM fnd_flex_values_vl  ffvv,                                          --�l�Z�b�g����
             fnd_flex_values ffv,                                               --�l�Z�b�g����
             fnd_flex_value_sets ffvs                                           --�l�Z�b�g�w�b�_
       WHERE ffv.flex_value_set_id = ffvs.flex_value_set_id
         AND ffv.flex_value_set_id = ffvv.flex_value_set_id
         AND ffv.flex_value_id = ffvv.flex_value_id
         AND ffvs.flex_value_set_name = cv_kind_of_cost
         AND ffv.flex_value = iv_cost_kind                                      --�p�����[�^�������
      ;
    EXCEPTION
      WHEN OTHERS THEN
        gv_cost_kind_nm := NULL;
    END;
    IF gv_cost_kind_nm IS NULL THEN                                             -- ������ʖ����擾�ł��Ȃ������ꍇ�A�z��O�G���[�Ƃ���B  
      RAISE global_api_expt;
    END IF;    
    -- ===========================
    -- ���̓p�����[�^���b�Z�[�W�o��
    -- ===========================
    --�Ώ۔N�x
    lv_pram_op := xxccp_common_pkg.get_msg(
                                             iv_application  => cv_xxcsm
                                            ,iv_name         => cv_par_yyyy_msg
                                            ,iv_token_name1  => cv_tkn_cd_yyyy
                                            ,iv_token_value1 => iv_yyyy
                                            );
    FND_FILE.PUT_LINE(FND_FILE.LOG, lv_pram_op);
    --���_�R�[�h
    lv_pram_op := xxccp_common_pkg.get_msg(
                                             iv_application  => cv_xxcsm
                                            ,iv_name         => cv_par_kyotn_msg
                                            ,iv_token_name1  => cv_tkn_cd_kyoten
                                            ,iv_token_value1 => iv_kyoten_cd
                                            );
    FND_FILE.PUT_LINE(FND_FILE.LOG, lv_pram_op);
    --�������
    lv_pram_op := xxccp_common_pkg.get_msg(
                                            iv_application  => cv_xxcsm
                                           ,iv_name         => cv_par_cost_kind_msg
                                           ,iv_token_name1  => cv_tkn_cost_kind
                                           ,iv_token_value1 => iv_cost_kind
                                           );
    FND_FILE.PUT_LINE(FND_FILE.LOG, lv_pram_op);
    --�K�w
    lv_pram_op := xxccp_common_pkg.get_msg(
                                            iv_application  => cv_xxcsm
                                           ,iv_name         => cv_par_level_msg
                                           ,iv_token_name1  => cv_tkn_cd_level
                                           ,iv_token_value1 => iv_level
                                           );
    FND_FILE.PUT_LINE(FND_FILE.LOG, lv_pram_op);
--//+ADD START E_�{�ғ�_09949 K.Taniguchi
    --�V�������敪
    lv_pram_op := xxccp_common_pkg.get_msg(
                                            iv_application  => cv_xxcsm
                                           ,iv_name         => cv_par_new_old_cost_cls_msg
                                           ,iv_token_name1  => cv_tkn_new_old_cost_cls
                                           ,iv_token_value1 => iv_p_new_old_cost_class
                                           );
    FND_FILE.PUT_LINE(FND_FILE.LOG, lv_pram_op);
--//+ADD END E_�{�ғ�_09949 K.Taniguchi
    FND_FILE.PUT_LINE(FND_FILE.LOG, '');
    -- ===========================
    -- �V�X�e�����t�擾���� 
    -- ===========================
    gd_sysdate := SYSDATE;
    -- =====================
    -- �Ɩ��������t�擾���� 
    -- =====================
    ld_process_date := xxccp_common_pkg2.get_process_date;
--//+ADD START E_�{�ғ�_09949 K.Taniguchi
    gd_process_date := ld_process_date; -- �O���[�o���ϐ��Ɋi�[
--//+ADD END E_�{�ғ�_09949 K.Taniguchi
--
    -- =====================
    -- �v���t�@�C���擾���� 
    -- =====================
    --�v�惊�X�g���ږ��i���i���v�j�擾
    gv_total_com_nm := FND_PROFILE.VALUE(cv_chk1_profile);
    IF (gv_total_com_nm IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                                            iv_application  => cv_xxcsm
                                           ,iv_name         => cv_prof_err_msg
                                           ,iv_token_name1  => cv_tkn_cd_prof
                                           ,iv_token_value1 => cv_chk1_profile
                                           );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    --�v�惊�X�g���ږ��i����l���j�擾
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
    --�v�惊�X�g���ږ��i�����l���j�擾
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
    --�v�惊�X�g���ږ��i���_�v�j�擾
    gv_kyoten_kei_nm := FND_PROFILE.VALUE(cv_chk4_profile);
    IF (gv_kyoten_kei_nm IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                                            iv_application  => cv_xxcsm
                                           ,iv_name         => cv_prof_err_msg
                                           ,iv_token_name1  => cv_tkn_cd_prof
                                           ,iv_token_value1 => cv_chk4_profile
                                           );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--//+ADD START E_�{�ғ�_09949 K.Taniguchi
    -- ��v����ID
    gn_gl_set_of_bks_id := TO_NUMBER(FND_PROFILE.VALUE(cv_gl_set_of_bks_id_profile));
    IF (gn_gl_set_of_bks_id) IS NULL THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                                            iv_application  => cv_xxcsm
                                           ,iv_name         => cv_prof_err_msg
                                           ,iv_token_name1  => cv_tkn_cd_prof
                                           ,iv_token_value1 => cv_gl_set_of_bks_id_profile
                                           );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
--
    -- =====================
    -- �N�����̔N�x�J�n���擾
    -- =====================
    BEGIN
      -- �N�x�J�n��
      SELECT  gp.start_date             AS start_date           -- �N�x�J�n��
      INTO    gd_gl_start_date                                  -- �N�����̔N�x�J�n��
      FROM    gl_sets_of_books          gsob                    -- ��v����}�X�^
             ,gl_periods                gp                      -- ��v�J�����_
      WHERE   gsob.set_of_books_id      = gn_gl_set_of_bks_id   -- ��v����ID
      AND     gp.period_set_name        = gsob.period_set_name  -- �J�����_��
      AND     gp.period_year            = (
                                            -- �N�����̔N�x
                                            SELECT  gp2.period_year           AS period_year          -- �N�x
                                            FROM    gl_sets_of_books          gsob2                   -- ��v����}�X�^
                                                   ,gl_periods                gp2                     -- ��v�J�����_
                                            WHERE   gsob2.set_of_books_id     = gn_gl_set_of_bks_id   -- ��v����ID
                                            AND     gp2.period_set_name       = gsob2.period_set_name -- �J�����_��
                                            AND     gd_process_date           BETWEEN gp2.start_date  -- �Ɩ����t���_
                                                                              AND     gp2.end_date
                                          )
      AND     gp.adjustment_period_flag = cv_flg_n              -- ������v���ԊO
      AND     gp.period_num             = 1                     -- �N�x�J�n��
      ;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                                              iv_application  => cv_xxcsm
                                             ,iv_name         => cv_start_date_err_msg
                                             ,iv_token_name1  => cv_tkn_sobid
                                             ,iv_token_value1 => TO_CHAR(gn_gl_set_of_bks_id)     --��v����ID
                                             ,iv_token_name2  => cv_tkn_process_date
                                             ,iv_token_value2 => TO_CHAR(gd_process_date, 'YYYY/MM/DD') --�Ɩ����t
                                             );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
--//+ADD END E_�{�ғ�_09949 K.Taniguchi
    -- =====================
    -- �S���_�R�[�h�擾���� 
    -- =====================
    SELECT
      flv.lookup_code     lookup_code
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
   * Description      : �N�ԏ��i�v��f�[�^���݃`�F�b�N(A-3)
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
      xxcsm_item_plan_headers    iph,   --���i�v��w�b�_�e�[�u��
      xxcsm_item_plan_lines      ipl    --���i�v�斾�׃e�[�u��
    WHERE
        iph.item_plan_header_id = ipl.item_plan_header_id
    AND iph.plan_year           = TO_NUMBER(iv_yyyy)
    AND iph.location_cd         = iv_kyoten_cd
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
      FND_FILE.PUT_LINE(FND_FILE.LOG, lv_errmsg);
      RAISE global_data_check_expt;
    END IF;

--
  EXCEPTION
    -- *** �f�[�^���݃`�F�b�N�G���[ ***
    WHEN global_data_check_expt THEN
      gn_warn_cnt := gn_warn_cnt +1;
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
   * Procedure Name   : chk_propdata
   * Description      : �������σf�[�^���݃`�F�b�N(A-4)
   ***********************************************************************************/
  PROCEDURE chk_propdata(
    iv_yyyy       IN  VARCHAR2,            -- 1.�Ώ۔N�x
    iv_kyoten_cd  IN  VARCHAR2,            -- 2.���_�R�[�h
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_propdata'; -- �v���O������
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
      xxcsm_item_plan_headers    iph,   --���i�v��w�b�_�e�[�u��
      xxcsm_item_plan_lines      ipl    --���i�v�斾�׃e�[�u��
    WHERE
        iph.item_plan_header_id = ipl.item_plan_header_id
    AND iph.plan_year           = TO_NUMBER(iv_yyyy)
    AND iph.location_cd         = iv_kyoten_cd
    AND ipl.item_kbn           <> cv_item_kbn
    AND ROWNUM = 1;

    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
    IF (ln_cnt = 0) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                                            iv_application  => cv_xxcsm
                                           ,iv_name         => cv_nopropdt_msg
                                           ,iv_token_name1  => cv_tkn_cd_tsym
                                           ,iv_token_value1 => iv_yyyy
                                           ,iv_token_name2  => cv_tkn_cd_kyoten
                                           ,iv_token_value2 => iv_kyoten_cd
                                           );
      FND_FILE.PUT_LINE(FND_FILE.LOG, lv_errmsg);
      RAISE global_data_check_expt;
    END IF;

--
  EXCEPTION
    -- *** �f�[�^���݃`�F�b�N�G���[ ***
    WHEN global_data_check_expt THEN
      gn_warn_cnt := gn_warn_cnt +1;
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
  END chk_propdata;
--
  /**********************************************************************************
   * Procedure Name   : select_grp3_total_data
   * Description      : �f�[�^�̒��o�i���i�Q�j(A-8)
   ***********************************************************************************/
  PROCEDURE select_grp4_total_data(
    it_group_cd    IN  xxcsm_tmp_item_plan_sales_sum.group4_cd%TYPE,  -- ���i�Q�R�[�h�S
    or_sum_rec     OUT NOCOPY g_sum_data_rtype,                   -- ���o���R�[�h
    ov_errbuf      OUT NOCOPY VARCHAR2,                    -- �G���[�E���b�Z�[�W
    ov_retcode     OUT NOCOPY VARCHAR2,                    -- ���^�[���E�R�[�h
    ov_errmsg      OUT NOCOPY VARCHAR2)                    -- ���[�U�[�E�G���[�E���b�Z�[�W
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'select_grp4_total_data'; -- �v���O������
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
    -- ���o����
    SELECT
       xti.group4_cd                          group4_cd                 -- ���i�Q�R�[�h�S
      ,xti.group4_nm                          group4_nm                 -- ���i�Q���̂S
      ,NVL(SUM(xti.con_price),0)              con_price                 -- �艿
      ,NVL(SUM(xti.amount),0)                 amount                    -- ����
      ,NVL(SUM(xti.con_price * xti.amount),0) price_multi_amount        -- �艿 * ����
      ,NVL(SUM(xti.sales_budget),0)           sales_budget              -- ����
      ,NVL(SUM(xti.cost),0)                   cost                      -- ����
      ,NVL(SUM(xti.margin),0)                 margin                    -- �e���v�z
    INTO
       or_sum_rec.group_cd
      ,or_sum_rec.group_nm
      ,or_sum_rec.con_price
      ,or_sum_rec.amount
      ,or_sum_rec.price_multi_amount
      ,or_sum_rec.sales_budget
      ,or_sum_rec.cost
      ,or_sum_rec.margin
--      ,or_sum_rec.base_margin
    FROM
      xxcsm_tmp_item_plan_sales_sum   xti  -- ���i�v��݌v�c�ƌ������[�N�e�[�u��
    WHERE
      xti.group4_cd  = it_group_cd    -- ���i�Q�R�[�h�S
    GROUP BY
       xti.group4_cd                  -- ���i�Q�R�[�h�S
      ,xti.group4_nm                  -- ���i�Q���̂S
    ;
--
    --==============================================================
    --���b�Z�[�W�o�́i�G���[�ȊO�j������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      -- ���ぃ�O�̏ꍇ�ɓo�^����Ă��Ȃ����Ƃ����邽��
      or_sum_rec.group_cd           := it_group_cd;
      or_sum_rec.group_nm           := NULL;
      or_sum_rec.con_price          := 0;
      or_sum_rec.amount             := 0;
      or_sum_rec.price_multi_amount := 0;
      or_sum_rec.sales_budget       := 0;
      or_sum_rec.cost               := 0;
      or_sum_rec.margin             := 0;
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
  END select_grp4_total_data;
--
  /**********************************************************************************
   * Procedure Name   : select_grp1_total_data
   * Description      : �f�[�^�̒��o�i���i�敪�j(A-11)
   ***********************************************************************************/
  PROCEDURE select_grp1_total_data(
    it_group_cd    IN  xxcsm_tmp_item_plan_sales_sum.group1_cd%TYPE,            -- ���i�Q�R�[�h�P
    or_sum_rec     OUT NOCOPY g_sum_data_rtype,                                 -- ���o���R�[�h
    ov_errbuf      OUT NOCOPY VARCHAR2,                                         -- �G���[�E���b�Z�[�W
    ov_retcode     OUT NOCOPY VARCHAR2,                                         -- ���^�[���E�R�[�h
    ov_errmsg      OUT NOCOPY VARCHAR2)                                         -- ���[�U�[�E�G���[�E���b�Z�[�W
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'select_grp1_total_data'; -- �v���O������
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
    -- ���o����
    SELECT
       xti.group1_cd                          group1_cd                 -- ���i�Q�R�[�h�P
      ,xti.group1_nm                          group1_nm                 -- ���i�Q���̂P
      ,NVL(SUM(xti.con_price),0)              con_price                 -- �艿
      ,NVL(SUM(xti.amount),0)                 amount                    -- ����
      ,NVL(SUM(xti.con_price * xti.amount),0) price_multi_amount        -- �艿 * ����
      ,NVL(SUM(xti.sales_budget),0)           sales_budget              -- ����
      ,NVL(SUM(xti.cost),0)                   cost                      -- ����
      ,NVL(SUM(xti.margin),0)                 margin                    -- �e���v�z
    INTO
       or_sum_rec.group_cd
      ,or_sum_rec.group_nm
      ,or_sum_rec.con_price
      ,or_sum_rec.amount
      ,or_sum_rec.price_multi_amount
      ,or_sum_rec.sales_budget
      ,or_sum_rec.cost
      ,or_sum_rec.margin
    FROM
      xxcsm_tmp_item_plan_sales_sum   xti  -- ���i�v��݌v�c�ƌ������[�N�e�[�u��
    WHERE
      xti.group1_cd  = it_group_cd    -- ���i�Q�R�[�h�P
    GROUP BY
       xti.group1_cd                  -- ���i�Q�R�[�h�P
      ,xti.group1_nm                  -- ���i�Q���̂P
    ;
--
    --==============================================================
    --���b�Z�[�W�o�́i�G���[�ȊO�j������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      -- ���ぃ�O�̏ꍇ�ɓo�^����Ă��Ȃ����Ƃ����邽��
      SELECT
        cgv.group1_nm    group1_nm      --���i�Q���̂P
      INTO
        or_sum_rec.group_nm
      FROM
        xxcsm_commodity_group4_v  cgv   --���i�Q�S�r���[
      WHERE
        cgv.group1_cd  = it_group_cd    --���i�Q�R�[�h�P
      AND
        ROWNUM = 1
      ;

      or_sum_rec.group_cd           := it_group_cd;
      or_sum_rec.con_price          := 0;
      or_sum_rec.amount             := 0;
      or_sum_rec.price_multi_amount := 0;
      or_sum_rec.sales_budget       := 0;
      or_sum_rec.cost               := 0;
      or_sum_rec.margin             := 0;
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
  END select_grp1_total_data;
--
  /**********************************************************************************
   * Procedure Name   : select_com_total_data
   * Description      : �f�[�^�̒��o�i���i���v�j(A-14)
   ***********************************************************************************/
  PROCEDURE select_com_total_data(
    or_sum_rec     OUT NOCOPY g_sum_data_rtype,            -- ���o���R�[�h
    ov_errbuf      OUT NOCOPY VARCHAR2,                    -- �G���[�E���b�Z�[�W
    ov_retcode     OUT NOCOPY VARCHAR2,                    -- ���^�[���E�R�[�h
    ov_errmsg      OUT NOCOPY VARCHAR2)                    -- ���[�U�[�E�G���[�E���b�Z�[�W
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'select_com_total_data'; -- �v���O������
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
    -- ���o����
    SELECT
       NVL(SUM(xti.con_price), 0)              con_price                 -- �艿
      ,NVL(SUM(xti.amount), 0)                 amount                    -- ����
      ,NVL(SUM(xti.con_price * xti.amount), 0) price_multi_amount        -- �艿 * ����
      ,NVL(SUM(xti.sales_budget), 0)           sales_budget              -- ����
      ,NVL(SUM(xti.cost), 0)                   cost                      -- ����
      ,NVL(SUM(xti.margin), 0)                 margin                    -- �e���v�z
    INTO
       or_sum_rec.con_price
      ,or_sum_rec.amount
      ,or_sum_rec.price_multi_amount
      ,or_sum_rec.sales_budget
      ,or_sum_rec.cost
      ,or_sum_rec.margin
    FROM
      xxcsm_tmp_item_plan_sales_sum   xti   -- ���i�v��݌v�c�ƌ������[�N�e�[�u��
    WHERE
      xti.group1_cd  IN (cv_leaf, cv_drink)   -- ���i�Q�R�[�h�P
    ;
--
    --==============================================================
    --���b�Z�[�W�o�́i�G���[�ȊO�j������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      -- ���ぃ�O�̏ꍇ�ɓo�^����Ă��Ȃ����Ƃ����邽��
      or_sum_rec.con_price          := 0;
      or_sum_rec.amount             := 0;
      or_sum_rec.price_multi_amount := 0;
      or_sum_rec.sales_budget       := 0;
      or_sum_rec.cost               := 0;
      or_sum_rec.margin             := 0;
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
  END select_com_total_data;
--
  /**********************************************************************************
   * Procedure Name   : select_discount_data
   * Description      : �f�[�^�̒��o�i����l���^�����l���j(A-17)
   ***********************************************************************************/
  PROCEDURE select_discount_data(
    iv_yyyy             IN  VARCHAR2,     -- �Ώ۔N�x
    iv_kyoten_cd        IN  VARCHAR2,     -- ���_�R�[�h
    ot_sales_discount   OUT xxcsm_item_plan_loc_bdgt.sales_discount%TYPE,     -- ����l��
    ot_receipt_discount OUT xxcsm_item_plan_loc_bdgt.receipt_discount%TYPE,   -- �����l��
    ov_errbuf           OUT NOCOPY VARCHAR2,                    -- �G���[�E���b�Z�[
    ov_retcode          OUT NOCOPY VARCHAR2,                    -- ���^�[���E�R�[�h
    ov_errmsg           OUT NOCOPY VARCHAR2)                    -- ���[�U�[�E�G���[�E���b�Z�[�W
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'select_discount_data'; -- �v���O������
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
    -- ���o����
    SELECT
       NVL(SUM(ipb.sales_discount),0)         sales_discount            -- ����l��
      ,NVL(SUM(ipb.receipt_discount),0)       receipt_discount          -- �����l��
    INTO
       ot_sales_discount
      ,ot_receipt_discount
    FROM
       xxcsm_item_plan_headers   iph    --���i�v��w�b�_�e�[�u��
      ,xxcsm_item_plan_loc_bdgt  ipb    --���i�v�拒�_�ʗ\�Z�e�[�u��
    WHERE
      iph.item_plan_header_id = ipb.item_plan_header_id
    AND
      iph.plan_year = TO_NUMBER(iv_yyyy)
    AND
      iph.location_cd = iv_kyoten_cd
    AND
      EXISTS(
        SELECT 'X'   x
        FROM
          xxcsm_item_plan_lines  ipl    --���i�v�斾�׃e�[�u��
        WHERE
          iph.item_plan_header_id = ipl.item_plan_header_id
        AND
          ipl.item_kbn <> cv_item_kbn
      )
    ;
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
  END select_discount_data;
--
  /**********************************************************************************
   * Procedure Name   : select_kyot_total_data
   * Description      : �f�[�^�̒��o�i���_���v�j(A-19)
   ***********************************************************************************/
  PROCEDURE select_kyot_total_data(
    or_sum_rec     OUT NOCOPY g_sum_data_rtype,            -- ���o���R�[�h
    ov_errbuf      OUT NOCOPY VARCHAR2,                    -- �G���[�E���b�Z�[�W
    ov_retcode     OUT NOCOPY VARCHAR2,                    -- ���^�[���E�R�[�h
    ov_errmsg      OUT NOCOPY VARCHAR2)                    -- ���[�U�[�E�G���[�E���b�Z�[�W
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'select_kyot_total_data'; -- �v���O������
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
    -- ���o����
    SELECT
       NVL(SUM(xti.con_price),0)              con_price                 -- �艿
      ,NVL(SUM(xti.amount),0)                 amount                    -- ����
      ,NVL(SUM(xti.con_price * xti.amount),0) price_multi_amount        -- �艿 * ����
      ,NVL(SUM(xti.sales_budget),0)           sales_budget              -- ����
      ,NVL(SUM(xti.cost),0)                   cost                      -- ����
      ,NVL(SUM(xti.margin),0)                 margin                    -- �e���v�z
    INTO
       or_sum_rec.con_price
      ,or_sum_rec.amount
      ,or_sum_rec.price_multi_amount
      ,or_sum_rec.sales_budget
      ,or_sum_rec.cost
      ,or_sum_rec.margin
    FROM
      xxcsm_tmp_item_plan_sales_sum    xti  -- ���i�v��݌v�c�ƌ������[�N�e�[�u��
    WHERE
      xti.group1_cd  IN (cv_leaf, cv_drink, cv_sonota, cv_nebiki)   -- ���i�Q�R�[�h�P
    ;
--
    --==============================================================
    --���b�Z�[�W�o�́i�G���[�ȊO�j������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      -- ���ぃ�O�̏ꍇ�ɓo�^����Ă��Ȃ����Ƃ����邽��
      or_sum_rec.con_price          := 0;
      or_sum_rec.amount             := 0;
      or_sum_rec.price_multi_amount := 0;
      or_sum_rec.sales_budget       := 0;
      or_sum_rec.cost               := 0;
      or_sum_rec.margin             := 0;
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
  END select_kyot_total_data;
--
  /**********************************************************************************
   * Procedure Name   : insert_data
   * Description      : �f�[�^�o�^(A-7,10,13,16,18,21)
   ***********************************************************************************/
  PROCEDURE insert_data(
    ir_plan_rec    IN  xxcsm_tmp_item_plan_sales_sum%ROWTYPE,  -- �Ώۃ��R�[�h
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
    -- �o�^����
    INSERT INTO xxcsm_tmp_item_plan_sales_sum(     -- ���i�v��݌v�c�ƌ������[�N�e�[�u��
       toroku_no                  -- �o�͏�
      ,location_cd                -- ���_�R�[�h
      ,location_nm                -- ���_��
      ,group1_cd                  -- ���i�Q�R�[�h�P
      ,group1_nm                  -- ���i�Q���̂P
      ,group4_cd                  -- ���i�Q�R�[�h�S
      ,group4_nm                  -- ���i�Q���̂S
      ,item_cd                    -- ���i�R�[�h
      ,item_nm                    -- ���i����
      ,con_price                  -- �艿
      ,amount                     -- ����
      ,sales_budget               -- ����
      ,cost                       -- ����
      ,margin                     -- �e���v�z
      ,margin_rate                -- �e���v��
      ,credit_rate                -- �|��
    )VALUES(
       xxcsm_tmp_item_plan_salsum_s01.NEXTVAL
      ,ir_plan_rec.location_cd
      ,ir_plan_rec.location_nm
      ,ir_plan_rec.group1_cd
      ,ir_plan_rec.group1_nm
      ,ir_plan_rec.group4_cd
      ,ir_plan_rec.group4_nm
      ,ir_plan_rec.item_cd
      ,ir_plan_rec.item_nm
      ,ir_plan_rec.con_price
      ,ir_plan_rec.amount
      ,ir_plan_rec.sales_budget
      ,ir_plan_rec.cost
      ,ir_plan_rec.margin
      ,ir_plan_rec.margin_rate
      ,ir_plan_rec.credit_rate
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
   * Procedure Name   : output_check_list
   * Description      : �`�F�b�N���X�g�f�[�^�o��(A-22)
   ***********************************************************************************/
  PROCEDURE output_check_list(
    iv_yyyy         IN  VARCHAR2,            -- 1.�Ώ۔N�x
    iv_p_kyoten_cd  IN  VARCHAR2,            -- 2.���_�R�[�h�i�p�����[�^�j
    iv_kyoten_cd    IN  VARCHAR2,            -- 3.���_�R�[�h
    iv_kyoten_nm    IN  VARCHAR2,            -- 4.���_��
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
--//+DEL START 2009/03/09   CT078 M.Ohtsuki
--    lv_kyoten_nm         VARCHAR2(100);       -- �S���_
--//+DEL END   2009/03/09   CT078 M.Ohtsuki
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    -- CSV�o�͗p�S�f�[�^
    CURSOR output_all_cur
    IS
      SELECT
        -- toroku_no                  -- �o�͏�
           cv_sep_wquot || xti.location_cd || cv_sep_wquot                -- ���_�R�[�h
        || cv_sep_com || cv_sep_wquot || xti.location_nm || cv_sep_wquot  -- ���_����
        || cv_sep_com || cv_sep_wquot || xti.item_cd || cv_sep_wquot      -- ���i�R�[�h
        || cv_sep_com || cv_sep_wquot || xti.item_nm || cv_sep_wquot      -- ���i����
        || cv_sep_com || TO_CHAR(xti.amount)                              -- ����
        || cv_sep_com || TO_CHAR(ROUND(xti.sales_budget/1000))            -- ����
        || cv_sep_com || TO_CHAR(ROUND(xti.cost/1000))                    -- ����
        || cv_sep_com || TO_CHAR(ROUND(xti.margin/1000))                  -- �e���v�z
        || cv_sep_com || TO_CHAR(xti.margin_rate)                         -- �e���v��
        || cv_sep_com || TO_CHAR(xti.credit_rate)                         -- �|��
        output_list
      FROM
        xxcsm_tmp_item_plan_sales_sum   xti  --���i�v��݌v�c�ƌ������[�N�e�[�u��
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
    -- �w�b�_�o��
    IF (gn_normal_cnt = 1) THEN
      -- ����̂݃w�b�_�o��
--//+DEL START 2009/03/09   CT078 M.Ohtsuki
--      SELECT
--        xlv.location_nm location_nm
--      INTO
--        lv_kyoten_nm
--      FROM
--        xxcsm_location_all_v  xlv
--      WHERE
--        xlv.location_cd = iv_p_kyoten_cd
--      ;
--//+DEL END   2009/03/09   CT078 M.Ohtsuki
      lv_header := xxccp_common_pkg.get_msg(
                    iv_application  => cv_xxcsm
                   ,iv_name         => cv_lst_head_msg
                   ,iv_token_name1  => cv_tkn_cd_yyyy
                   ,iv_token_value1 => iv_yyyy
                   ,iv_token_name2  => cv_tkn_nichiji
                   ,iv_token_value2 => TO_CHAR(gd_sysdate, 'YYYY/MM/DD HH24:MI:SS')
                   ,iv_token_name3  => cv_tkn_cost_kind_nm
                   ,iv_token_value3 => gv_cost_kind_nm
                 );      -- �f�[�^�o��
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_header
      );
    END IF;
--
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
    -- ��s�o��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
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
      IF (output_all_cur%ISOPEN) THEN
        CLOSE output_all_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
     IF (output_all_cur%ISOPEN) THEN
        CLOSE output_all_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END output_check_list;
--
  /**********************************************************************************
   * Procedure Name   : loop_kyoten
   * Description      : ���_���[�v������
   ***********************************************************************************/
  PROCEDURE loop_kyoten(
    iv_yyyy         IN  VARCHAR2,            -- 1.�Ώ۔N�x
    iv_p_kyoten_cd  IN  VARCHAR2,            -- 2.���_�R�[�h�i�p�����[�^�j
    iv_p_cost_kind  IN  VARCHAR2,            -- 3.�������
    iv_kyoten_cd    IN  VARCHAR2,            -- 4.���_�R�[�h
    iv_kyoten_nm    IN  VARCHAR2,            -- 5.���_��
--//+ADD START E_�{�ғ�_09949 K.Taniguchi
    iv_p_new_old_cost_class
                    IN  VARCHAR2,            -- 6.�V�������敪
--//+ADD END E_�{�ғ�_09949 K.Taniguchi
    ov_errbuf       OUT NOCOPY VARCHAR2,     --   �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode      OUT NOCOPY VARCHAR2,     --   ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg       OUT NOCOPY VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'loop_kyoten'; -- �v���O������
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
    cv_exit_group1_cd  CONSTANT VARCHAR2(10)  := '!';            -- �ŏI���i�Q�R�[�h�P
    cv_exit_group4_cd  CONSTANT VARCHAR2(10)  := '!!!!';         -- �ŏI���i�Q�R�[�h�S
--
    cv_margin_rate_dis CONSTANT NUMBER := 100.00;                -- �l���̏ꍇ�̑e���v��
--
    -- *** ���[�J���ϐ� ***
    lt_group1_cd           xxcsm_tmp_item_plan_sales_sum.group1_cd%TYPE;    --���i�Q�R�[�h�P
    lt_group4_cd           xxcsm_tmp_item_plan_sales_sum.group4_cd%TYPE;    --���i�Q�R�[�h�S
    lt_pre_group1_cd       xxcsm_tmp_item_plan_sales_sum.group1_cd%TYPE;    --���i�Q�R�[�h�P�i�O���R�[�h�j
    lt_pre_group4_cd       xxcsm_tmp_item_plan_sales_sum.group4_cd%TYPE;    --���i�Q�R�[�h�S�i�O���R�[�h�j
    lv_kyoten_cd           VARCHAR2(32);                                    --�P�s�ڐݒ�p���_�R�[�h
    lv_kyoten_nm           VARCHAR2(240);                                   --�P�s�ڐݒ�p���_��
    ln_cost                NUMBER;    --����
    ln_margin              NUMBER;    --�e���v�z
    ln_margin_rate         NUMBER;    --�e���v��
    ln_credit_rate         NUMBER;    --�|��
    ln_sales_discount      NUMBER;    --����l��
    ln_receipt_discount    NUMBER;    --�����l��

    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
--//+UPD START E_�{�ғ�_09949 K.Taniguchi
--// SELECT���CASE�����g�p��GROUP BY��ł�2�d�̋L�q�������邽��
--// FROM��ł̃C�����C���r���[�����s���܂��B
--    -- �N�ԏ��i�v��f�[�^
--    CURSOR item_plan_cur(
--      in_yyyy         IN  NUMBER,       -- 1.�Ώ۔N�x
--      iv_kyoten_cd    IN  VARCHAR2)     -- 2.���_�R�[�h
--    IS
--      SELECT
--         cgv.group1_cd                  group1_cd      --���i�Q�R�[�h�P
--        ,cgv.group1_nm                  group1_nm      --���i�Q���̂P
--        ,cgv.group4_cd                  group4_cd      --���i�Q�R�[�h�S
--        ,cgv.group4_nm                  group4_nm      --���i�Q���̂S
--        ,cgv.item_cd                    item_cd        --�i�ڃR�[�h
--        ,cgv.item_nm                    item_nm        --�i�ږ���
--        ,NVL(cgv.now_item_cost, 0)      base_price     --�W������
--        ,NVL(cgv.now_business_cost, 0)  bus_price      --�c�ƌ���
--        ,NVL(cgv.now_unit_price, 0)     con_price      --�艿
--        ,NVL(SUM(ipl.amount), 0)        amount         --����
--        ,NVL(SUM(ipl.sales_budget), 0)  sales_budget   --����
--      FROM
--         xxcsm_item_plan_headers   iph   --���i�v��w�b�_�e�[�u��
--        ,xxcsm_item_plan_lines     ipl   --���i�v�斾�׃e�[�u��
--        ,xxcsm_commodity_group4_v  cgv   --���i�Q�S�r���[
--      WHERE
--         iph.item_plan_header_id = ipl.item_plan_header_id
--      AND
--         ipl.item_no = cgv.item_cd
--      AND
--         iph.plan_year = in_yyyy
--      AND
--         iph.location_cd = iv_kyoten_cd
--      AND
--         ipl.item_kbn <> cv_item_kbn
--      GROUP BY
--         cgv.group1_cd                         --���i�Q�R�[�h�P
--        ,cgv.group1_nm                         --���i�Q���̂P
--        ,cgv.group4_cd                         --���i�Q�R�[�h�S
--        ,cgv.group4_nm                         --���i�Q���̂S
--        ,cgv.item_cd                           --�i�ڃR�[�h
--        ,cgv.item_nm                           --�i�ږ���
--        ,cgv.now_item_cost                     --�W������
--        ,cgv.now_business_cost                 --�c�ƌ���
--        ,cgv.now_unit_price                    --�艿
--      ORDER BY
--         cgv.group1_cd                         --���i�Q�R�[�h�P
--        ,cgv.group4_cd                         --���i�Q�R�[�h�S
--        ,cgv.item_cd                           --�i�ڃR�[�h
--      ;
--
--
    -- �N�ԏ��i�v��f�[�^
    CURSOR item_plan_cur(
      in_yyyy                   IN  NUMBER,       -- 1.�Ώ۔N�x
      iv_kyoten_cd              IN  VARCHAR2,     -- 2.���_�R�[�h
      iv_p_new_old_cost_class   IN  VARCHAR2)     -- 3.�V�������敪
    IS
      SELECT
         sub.group1_cd                  group1_cd      --���i�Q�R�[�h�P
        ,sub.group1_nm                  group1_nm      --���i�Q���̂P
        ,sub.group4_cd                  group4_cd      --���i�Q�R�[�h�S
        ,sub.group4_nm                  group4_nm      --���i�Q���̂S
        ,sub.item_cd                    item_cd        --�i�ڃR�[�h
        ,sub.item_nm                    item_nm        --�i�ږ���
        ,NVL(sub.now_item_cost, 0)      base_price     --�W������
        ,NVL(sub.now_business_cost, 0)  bus_price      --�c�ƌ���
        ,NVL(sub.now_unit_price, 0)     con_price      --�艿
        ,NVL(SUM(sub.amount), 0)        amount         --����
        ,NVL(SUM(sub.sales_budget), 0)  sales_budget   --����
      FROM
      (
          SELECT
             cgv.group1_cd                  group1_cd      --���i�Q�R�[�h�P
            ,cgv.group1_nm                  group1_nm      --���i�Q���̂P
            ,cgv.group4_cd                  group4_cd      --���i�Q�R�[�h�S
            ,cgv.group4_nm                  group4_nm      --���i�Q���̂S
            ,cgv.item_cd                    item_cd        --�i�ڃR�[�h
            ,cgv.item_nm                    item_nm        --�i�ږ���
             --
             -- �W������
             -- �p�����[�^�F�V�������敪
            ,CASE iv_p_new_old_cost_class
               --
               -- 10�F�V���� �I����
               WHEN cv_new_cost THEN
                 NVL(cgv.now_item_cost, 0)
               --
               -- 20�F������ �I����
               WHEN cv_old_cost THEN
                 NVL(
                       (
                         -- �W�������}�X�^���O�N�x�̕W���������擾
                         SELECT SUM(ccmd.cmpnt_cost) AS cmpnt_cost                    -- �W������
                         FROM   cm_cmpt_dtl     ccmd                                  -- OPM�W�������}�X�^
                               ,cm_cldr_dtl     ccld                                  -- �����J�����_����
                         WHERE  ccmd.calendar_code = ccld.calendar_code               -- �����J�����_�R�[�h
                         AND    ccmd.period_code   = ccld.period_code                 -- ���ԃR�[�h
                         AND    ccmd.item_id       = cgv.opm_item_id                  -- �i��ID
                         AND    ccmd.whse_code     = cv_whse_code                     -- �����q��
                         AND    ccld.start_date   <= ADD_MONTHS(gd_process_date, -12) -- �O�N�x���_
                         AND    ccld.end_date     >= ADD_MONTHS(gd_process_date, -12) -- �O�N�x���_
                       )
                   , 0
                 )
             END                            now_item_cost       --�W������
             --
             -- �c�ƌ���
             -- �p�����[�^�F�V�������敪
            ,CASE iv_p_new_old_cost_class
               --
               -- 10�F�V���� �I����
               WHEN cv_new_cost THEN
                 NVL(cgv.now_business_cost, 0)
               --
               -- 20�F������ �I����
               WHEN cv_old_cost THEN
                 NVL(
                       (
                         -- �O�N�x�̉c�ƌ�����i�ڕύX��������擾
                         SELECT  TO_CHAR(xsibh.discrete_cost)  AS  discrete_cost   -- �c�ƌ���
                         FROM    xxcmm_system_items_b_hst      xsibh               -- �i�ڕύX����
                         WHERE   xsibh.item_hst_id   =
                           (
                             -- �O�N�x�̕i�ڕύX����ID
                             SELECT  MAX(item_hst_id)      AS item_hst_id          -- �i�ڕύX����ID
                             FROM    xxcmm_system_items_b_hst xsibh2               -- �i�ڕύX����
                             WHERE   xsibh2.item_code      =  cgv.item_cd          -- �i�ڃR�[�h
                             AND     xsibh2.apply_date     <  gd_gl_start_date     -- �N�����̔N�x�J�n��
                             AND     xsibh2.apply_flag     =  cv_flg_y             -- �K�p�ς�
                             AND     xsibh2.discrete_cost  IS NOT NULL             -- �c�ƌ��� IS NOT NULL
                           )
                       )
                   , 0
                 )
             END                            now_business_cost   --�c�ƌ���
             --
             -- �艿
             -- �p�����[�^�F�V�������敪
            ,CASE iv_p_new_old_cost_class
               --
               -- 10�F�V���� �I����
               WHEN cv_new_cost THEN
                 NVL(cgv.now_unit_price, 0)
               --
               -- 20�F������ �I����
               WHEN cv_old_cost THEN
                 NVL(
                       (
                         -- �O�N�x�̒艿��i�ڕύX��������擾
                         SELECT  TO_CHAR(xsibh.fixed_price)    AS  fixed_price     -- �艿
                         FROM    xxcmm_system_items_b_hst      xsibh               -- �i�ڕύX����
                         WHERE   xsibh.item_hst_id   =
                           (
                             -- �O�N�x�̕i�ڕύX����ID
                             SELECT  MAX(item_hst_id)      AS item_hst_id          -- �i�ڕύX����ID
                             FROM    xxcmm_system_items_b_hst xsibh2               -- �i�ڕύX����
                             WHERE   xsibh2.item_code      =  cgv.item_cd          -- �i�ڃR�[�h
                             AND     xsibh2.apply_date     <  gd_gl_start_date     -- �N�����̔N�x�J�n��
                             AND     xsibh2.apply_flag     =  cv_flg_y             -- �K�p�ς�
                             AND     xsibh2.fixed_price    IS NOT NULL             -- �艿 IS NOT NULL
                           )
                       )
                   , 0
                 )
             END                            now_unit_price      --�艿
            ,ipl.amount                     amount              --����
            ,ipl.sales_budget               sales_budget        --����
          FROM
             xxcsm_item_plan_headers   iph   --���i�v��w�b�_�e�[�u��
            ,xxcsm_item_plan_lines     ipl   --���i�v�斾�׃e�[�u��
            ,xxcsm_commodity_group4_v  cgv   --���i�Q�S�r���[
          WHERE
             iph.item_plan_header_id = ipl.item_plan_header_id
          AND
             ipl.item_no = cgv.item_cd
          AND
             iph.plan_year = in_yyyy
          AND
             iph.location_cd = iv_kyoten_cd
          AND
             ipl.item_kbn <> cv_item_kbn
      ) sub
      GROUP BY
         sub.group1_cd                         --���i�Q�R�[�h�P
        ,sub.group1_nm                         --���i�Q���̂P
        ,sub.group4_cd                         --���i�Q�R�[�h�S
        ,sub.group4_nm                         --���i�Q���̂S
        ,sub.item_cd                           --�i�ڃR�[�h
        ,sub.item_nm                           --�i�ږ���
        ,sub.now_item_cost                     --�W������
        ,sub.now_business_cost                 --�c�ƌ���
        ,sub.now_unit_price                    --�艿
      ORDER BY
         sub.group1_cd                         --���i�Q�R�[�h�P
        ,sub.group4_cd                         --���i�Q�R�[�h�S
        ,sub.item_cd                           --�i�ڃR�[�h
      ;
--//+UPD END E_�{�ғ�_09949 K.Taniguchi
    -- �N�ԏ��i�v��f�[�^���R�[�h�^
    item_plan_rec item_plan_cur%ROWTYPE;
    -- ���i�v��݌v�c�ƌ������[�N�e�[�u�����R�[�h�^
    lr_plan_rec    xxcsm_tmp_item_plan_sales_sum%ROWTYPE;
    -- �f�[�^���o�p���R�[�h�^
    lr_sum_rec     g_sum_data_rtype;
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
    -- ***        ���[�v�����̋L�q         ***
    -- ***       �������̌Ăяo��          ***
    -- ***************************************

    gn_target_cnt := gn_target_cnt + 1;

    -- =============================================
    -- �N�ԏ��i�v��f�[�^���݃`�F�b�N(A-3)
    -- =============================================
    chk_plandata(
              iv_yyyy              -- �Ώ۔N�x
             ,iv_kyoten_cd         -- ���_�R�[�h
             ,lv_errbuf            -- �G���[�E���b�Z�[�W
             ,lv_retcode           -- ���^�[���E�R�[�h
             ,lv_errmsg);
    -- ��O����
    IF (lv_retcode = cv_status_error) THEN
      --(�G���[����)
      gn_error_cnt := gn_error_cnt +1;
      RAISE global_process_expt;
    ELSIF (lv_retcode = cv_status_normal) THEN
      -- =============================================
      -- �������σf�[�^���݃`�F�b�N(A-4)
      -- =============================================
      chk_propdata(
                iv_yyyy              -- �Ώ۔N�x
               ,iv_kyoten_cd         -- ���_�R�[�h
               ,lv_errbuf            -- �G���[�E���b�Z�[�W
               ,lv_retcode           -- ���^�[���E�R�[�h
               ,lv_errmsg);
      -- ��O����
      IF (lv_retcode = cv_status_error) THEN
        --(�G���[����)
        gn_error_cnt := gn_error_cnt + 1;
        RAISE global_process_expt;
      ELSIF (lv_retcode = cv_status_normal) THEN
        -- =============================================
        -- �N�ԏ��i�v��f�[�^�̒��o(A-5)
        -- =============================================
        -- �P�s�ڂ̂݋��_�R�[�h�A���̂��o�͂��邽�߂̕ϐ��ݒ�
        lv_kyoten_cd := iv_kyoten_cd;
        lv_kyoten_nm := iv_kyoten_nm;
--//+UPD START E_�{�ғ�_09949 K.Taniguchi
--      OPEN item_plan_cur(TO_NUMBER(iv_yyyy), iv_kyoten_cd);
        OPEN item_plan_cur(TO_NUMBER(iv_yyyy), iv_kyoten_cd, iv_p_new_old_cost_class);
--//+UPD END E_�{�ғ�_09949 K.Taniguchi
        <<item_plan_loop>>
        LOOP
          FETCH item_plan_cur INTO item_plan_rec;

          lt_pre_group1_cd := lt_group1_cd;
          lt_pre_group4_cd := lt_group4_cd;
          IF item_plan_cur%NOTFOUND THEN
            lt_group1_cd     := cv_exit_group1_cd;
            lt_group4_cd     := cv_exit_group4_cd;
          ELSE
            lt_group1_cd     := item_plan_rec.group1_cd;
            lt_group4_cd     := item_plan_rec.group4_cd;
          END IF;

          -- ���i�Q���ς�����珤�i�Q�v��o�^
          IF (lt_group4_cd <> lt_pre_group4_cd) THEN
            -- �P���ڂ�lt_pre_group4_cd��NULL�̂��߂����ɓ���Ȃ��iNULL�̔�r��FALSE�j
            -- =============================================
            -- �f�[�^�̒��o�i���i�Q�j(A-8)
            -- =============================================
            select_grp4_total_data(
                        lt_pre_group4_cd     -- ���i�Q�R�[�h�S
                       ,lr_sum_rec           -- ���o���R�[�h
                       ,lv_errbuf            -- �G���[�E���b�Z�[�W
                       ,lv_retcode           -- ���^�[���E�R�[�h
                       ,lv_errmsg);
            -- ��O����
            IF (lv_retcode = cv_status_error) THEN
              --(�G���[����)
              gn_error_cnt := gn_error_cnt + 1;
              RAISE global_process_expt;
            END IF;

            -- ������z���O�̏ꍇ�ɓo�^
--//+UPD START 2009/02/20   CT053 M.Ohtsuki
--            IF (lr_sum_rec.sales_budget > 0) THEN
-- MODIFY  START  DATE:2011/01/05  AUTHOR:OUKOU  CONTENT:E-�{�ғ�_05803
--            IF (lr_sum_rec.sales_budget <> 0) THEN
            IF lr_sum_rec.sales_budget <> 0 OR lr_sum_rec.amount <> 0 THEN
-- MODIFY  END  DATE:2011/01/05  AUTHOR:OUKOU  CONTENT:E-�{�ғ�_05803
--//+UPD END   2009/02/20   CT053 M.Ohtsuki
              -- =============================================
              -- �f�[�^�̎Z�o�i���i�Q�j(A-9)
              -- =============================================
              --�e���v��
              IF (lr_sum_rec.sales_budget = 0) THEN
                ln_margin_rate := 0;
              ELSE
                ln_margin_rate := ROUND(lr_sum_rec.margin / lr_sum_rec.sales_budget * 100, 2);
              END IF;
              --�|��
              IF (lr_sum_rec.price_multi_amount = 0) THEN
                ln_credit_rate := 0;
              ELSE
                ln_credit_rate := ROUND(lr_sum_rec.sales_budget / lr_sum_rec.price_multi_amount * 100, 2);
              END IF;

              -- =============================================
              -- �f�[�^�̓o�^�i���i�Q�j(A-10)
              -- =============================================
              lr_plan_rec.location_cd            := NULL;                       -- ���_�R�[�h
              lr_plan_rec.location_nm            := NULL;                       -- ���_����
              lr_plan_rec.group1_cd              := NULL;                       -- ���i�Q�R�[�h�P
              lr_plan_rec.group1_nm              := NULL;                       -- ���i�Q���̂P
              lr_plan_rec.group4_cd              := NULL;                       -- ���i�Q�R�[�h�S
              lr_plan_rec.group4_nm              := NULL;                       -- ���i�Q���̂S
              lr_plan_rec.item_cd                := lr_sum_rec.group_cd;        -- ���i�R�[�h
              lr_plan_rec.item_nm                := lr_sum_rec.group_nm;        -- ���i����
              lr_plan_rec.con_price              := lr_sum_rec.con_price;       -- �艿
              lr_plan_rec.amount                 := lr_sum_rec.amount;          -- ����
              lr_plan_rec.sales_budget           := lr_sum_rec.sales_budget;    -- ����
              lr_plan_rec.cost                   := lr_sum_rec.cost;            -- ����
              lr_plan_rec.margin                 := lr_sum_rec.margin;          -- �e���v�z
              lr_plan_rec.margin_rate            := ln_margin_rate;             -- �e���v��
              lr_plan_rec.credit_rate            := ln_credit_rate;             -- �|��

              insert_data(
                      lr_plan_rec          -- �Ώۃ��R�[�h
                     ,lv_errbuf            -- �G���[�E���b�Z�[�W
                     ,lv_retcode           -- ���^�[���E�R�[�h
                     ,lv_errmsg);
              -- ��O����
              IF (lv_retcode = cv_status_error) THEN
                --(�G���[����)
                gn_error_cnt := gn_error_cnt +1;
                RAISE global_process_expt;
              END IF;
            END IF;
          END IF;
          -- ���i�敪���ς�����珤�i�敪�v��o�^
          IF (lt_group1_cd <> lt_pre_group1_cd) THEN
            -- �P���ڂ�lt_pre_group1_cd��NULL�̂��߂����ɓ���Ȃ��iNULL�̔�r��FALSE�j
            -- =============================================
            -- �f�[�^�̒��o�i���i�敪�j(A-11)
            -- =============================================
            select_grp1_total_data(
                      lt_pre_group1_cd     -- ���i�Q�R�[�h�P
                     ,lr_sum_rec           -- ���o���R�[�h
                     ,lv_errbuf            -- �G���[�E���b�Z�[�W
                     ,lv_retcode           -- ���^�[���E�R�[�h
                     ,lv_errmsg);
            -- ��O����
            IF (lv_retcode = cv_status_error) THEN
              --(�G���[����)
              gn_error_cnt := gn_error_cnt +1;
              RAISE global_process_expt;
            END IF;

            -- =============================================
            -- �f�[�^�̎Z�o�i���i�敪�j(A-12)
            -- =============================================
            --�e���v��
            IF (lr_sum_rec.sales_budget = 0) THEN
              ln_margin_rate := 0;
            ELSE
              ln_margin_rate := ROUND(lr_sum_rec.margin / lr_sum_rec.sales_budget * 100, 2);
            END IF;
            --�|��
            IF (lr_sum_rec.price_multi_amount = 0) THEN
              ln_credit_rate := 0;
            ELSE
              ln_credit_rate := ROUND(lr_sum_rec.sales_budget / lr_sum_rec.price_multi_amount * 100, 2);
            END IF;

            -- =============================================
            -- �f�[�^�̓o�^�i���i�敪�j(A-13)
            -- =============================================
--//+UPD START 2009/02/20   CT051 M.Ohtsuki
--            lr_plan_rec.location_cd            := NULL;                       -- ���_�R�[�h
--            lr_plan_rec.location_nm            := NULL;                       -- ���_����
            lr_plan_rec.location_cd            := lv_kyoten_cd;               -- ���_�R�[�h
            lr_plan_rec.location_nm            := lv_kyoten_nm;               -- ���_����
--//+UPD END   2009/02/20   CT051 M.Ohtsuki
            lr_plan_rec.group1_cd              := NULL;                       -- ���i�Q�R�[�h�P
            lr_plan_rec.group1_nm              := NULL;                       -- ���i�Q���̂P
            lr_plan_rec.group4_cd              := NULL;                       -- ���i�Q�R�[�h�S
            lr_plan_rec.group4_nm              := NULL;                       -- ���i�Q���̂S
            lr_plan_rec.item_cd                := lr_sum_rec.group_cd;        -- ���i�R�[�h
            lr_plan_rec.item_nm                := lr_sum_rec.group_nm;        -- ���i����
            lr_plan_rec.con_price              := lr_sum_rec.con_price;       -- �艿
            lr_plan_rec.amount                 := lr_sum_rec.amount;          -- ����
            lr_plan_rec.sales_budget           := lr_sum_rec.sales_budget;    -- ����
            lr_plan_rec.cost                   := lr_sum_rec.cost;            -- ����
            lr_plan_rec.margin                 := lr_sum_rec.margin;          -- �e���v�z
            lr_plan_rec.margin_rate            := ln_margin_rate;             -- �e���v��
            lr_plan_rec.credit_rate            := ln_credit_rate;             -- �|��

            insert_data(
                  lr_plan_rec          -- �Ώۃ��R�[�h
                 ,lv_errbuf            -- �G���[�E���b�Z�[�W
                 ,lv_retcode           -- ���^�[���E�R�[�h
                 ,lv_errmsg);
            -- ��O����
            IF (lv_retcode = cv_status_error) THEN
              --(�G���[����)
              gn_error_cnt := gn_error_cnt +1;
              RAISE global_process_expt;
            END IF;
--//+ADD START 2009/02/12   CT051 M.Ohtsuki
            lv_kyoten_cd := NULL;
            lv_kyoten_nm := NULL;
--//+ADD END   2009/02/12   CT051 M.Ohtsuki
            -- ���i�敪�iDRINK�j���I��������
            IF (lt_pre_group1_cd = cv_drink) THEN
              -- =============================================
              -- �f�[�^�̒��o�i���i���v�j(A-14)
              -- =============================================
              select_com_total_data(
                      lr_sum_rec           -- ���o���R�[�h
                     ,lv_errbuf            -- �G���[�E���b�Z�[�W
                     ,lv_retcode           -- ���^�[���E�R�[�h
                     ,lv_errmsg);
              -- ��O����
              IF (lv_retcode = cv_status_error) THEN
                --(�G���[����)
                gn_error_cnt := gn_error_cnt +1;
                RAISE global_process_expt;
              END IF;

              -- =============================================
              -- �f�[�^�̎Z�o�i���i���v�j(A-15)
              -- =============================================
              --�e���v��
              IF (lr_sum_rec.sales_budget = 0) THEN
                ln_margin_rate := 0;
              ELSE
                ln_margin_rate := ROUND(lr_sum_rec.margin / lr_sum_rec.sales_budget * 100, 2);
              END IF;
              --�|��
              IF (lr_sum_rec.price_multi_amount = 0) THEN
                ln_credit_rate := 0;
              ELSE
                ln_credit_rate := ROUND(lr_sum_rec.sales_budget / lr_sum_rec.price_multi_amount * 100, 2);
              END IF;

              -- =============================================
              -- �f�[�^�̓o�^�i���i���v�j(A-16)
              -- =============================================
              lr_plan_rec.location_cd            := NULL;                       -- ���_�R�[�h
              lr_plan_rec.location_nm            := NULL;                       -- ���_����
              lr_plan_rec.group1_cd              := NULL;                       -- ���i�Q�R�[�h�P
              lr_plan_rec.group1_nm              := NULL;                       -- ���i�Q���̂P
              lr_plan_rec.group4_cd              := NULL;                       -- ���i�Q�R�[�h�S
              lr_plan_rec.group4_nm              := NULL;                       -- ���i�Q���̂S
              lr_plan_rec.item_cd                := NULL;                       -- ���i�R�[�h
              lr_plan_rec.item_nm                := gv_total_com_nm;            -- ���i����
              lr_plan_rec.con_price              := NULL;                       -- �艿
              lr_plan_rec.amount                 := lr_sum_rec.amount;          -- ����
              lr_plan_rec.sales_budget           := lr_sum_rec.sales_budget;    -- ����
              lr_plan_rec.cost                   := lr_sum_rec.cost;            -- ����
              lr_plan_rec.margin                 := lr_sum_rec.margin;          -- �e���v�z
              lr_plan_rec.margin_rate            := ln_margin_rate;             -- �e���v��
              lr_plan_rec.credit_rate            := ln_credit_rate;             -- �|��

              insert_data(
                    lr_plan_rec          -- �Ώۃ��R�[�h
                   ,lv_errbuf            -- �G���[�E���b�Z�[�W
                   ,lv_retcode           -- ���^�[���E�R�[�h
                   ,lv_errmsg);
              -- ��O����
              IF (lv_retcode = cv_status_error) THEN
                --(�G���[����)
                gn_error_cnt := gn_error_cnt +1;
                RAISE global_process_expt;
              END IF;
            END IF;

            --lt_pre_group1_cd := lt_group1_cd;

          END IF;

          EXIT WHEN item_plan_cur%NOTFOUND;

          -- ������z���O�̏ꍇ�ɏ��i���ׂ�o�^
--//+UPD START 2009/02/20   CT053 M.Ohtsuki
--          IF (item_plan_rec.sales_budget > 0) THEN
-- MODIFY  START  DATE:2011/01/05  AUTHOR:OUKOU  CONTENT:E-�{�ғ�_05803
--          IF (item_plan_rec.sales_budget <> 0) THEN
          IF item_plan_rec.sales_budget <> 0 OR item_plan_rec.amount <> 0 THEN
-- MODIFY  END  DATE:2011/01/05  AUTHOR:OUKOU  CONTENT:E-�{�ғ�_05803
--//+UPD END   2009/02/20   CT053 M.Ohtsuki
            -- =============================================
            -- �f�[�^�̎Z�o�i���i�j(A-6)
            -- =============================================
            --����
            IF (iv_p_cost_kind = cv_cost_base) THEN
              ln_cost := item_plan_rec.base_price * item_plan_rec.amount;       --�W������
            ELSIF (iv_p_cost_kind = cv_cost_bus) THEN
              ln_cost := item_plan_rec.bus_price * item_plan_rec.amount;        --�c�ƌ���
            END IF;
            --�e���v�z
            ln_margin := item_plan_rec.sales_budget - ln_cost;
            --�e���v��
            IF (item_plan_rec.sales_budget = 0) THEN
              ln_margin_rate := 0;
            ELSE
              ln_margin_rate := ROUND(ln_margin / item_plan_rec.sales_budget * 100, 2);
            END IF;
            --�|��
            IF ((item_plan_rec.con_price = 0) OR (item_plan_rec.amount = 0)) THEN
              ln_credit_rate := 0;
            ELSE
              ln_credit_rate := ROUND(item_plan_rec.sales_budget / (item_plan_rec.con_price * item_plan_rec.amount) * 100, 2);
            END IF;

            -- =============================================
            -- �f�[�^�̓o�^�i���i�j(A-7)
            -- =============================================
            lr_plan_rec.location_cd            := lv_kyoten_cd;               -- ���_�R�[�h
            lr_plan_rec.location_nm            := lv_kyoten_nm;               -- ���_����
            lr_plan_rec.group1_cd              := item_plan_rec.group1_cd;    -- ���i�Q�R�[�h�P
            lr_plan_rec.group1_nm              := item_plan_rec.group1_nm;    -- ���i�Q���̂P
            lr_plan_rec.group4_cd              := item_plan_rec.group4_cd;    -- ���i�Q�R�[�h�S
            lr_plan_rec.group4_nm              := item_plan_rec.group4_nm;    -- ���i�Q���̂S
            lr_plan_rec.item_cd                := item_plan_rec.item_cd;      -- ���i�R�[�h
            lr_plan_rec.item_nm                := item_plan_rec.item_nm;      -- ���i����
            lr_plan_rec.con_price              := item_plan_rec.con_price;    -- �艿
            lr_plan_rec.amount                 := item_plan_rec.amount;       -- ����
            lr_plan_rec.sales_budget           := item_plan_rec.sales_budget; -- ����
            lr_plan_rec.cost                   := ln_cost;                    -- ����
            lr_plan_rec.margin                 := ln_margin;                  -- �e���v�z
            lr_plan_rec.margin_rate            := ln_margin_rate;             -- �e���v��
            lr_plan_rec.credit_rate            := ln_credit_rate;             -- �|��

            insert_data(
                      lr_plan_rec          -- �Ώۃ��R�[�h
                     ,lv_errbuf            -- �G���[�E���b�Z�[�W
                     ,lv_retcode           -- ���^�[���E�R�[�h
                     ,lv_errmsg);
            -- ��O����
            IF (lv_retcode = cv_status_error) THEN
              --(�G���[����)
              gn_error_cnt := gn_error_cnt +1;
              RAISE global_process_expt;
            END IF;
            -- �P�s�ڂ̂݋��_�R�[�h�A���̂��o�͂��邽�߃N���A
            lv_kyoten_cd := NULL;
            lv_kyoten_nm := NULL;

          END IF;

        END LOOP item_plan_loop;
        CLOSE item_plan_cur;

        -- =============================================
        -- �f�[�^�̒��o�i����l���^�����l���j(A-17)
        -- =============================================
        select_discount_data(
                    iv_yyyy              -- �Ώ۔N�x
                   ,iv_kyoten_cd         -- ���_�R�[�h
                   ,ln_sales_discount    -- ����l��
                   ,ln_receipt_discount  -- �����l��
                   ,lv_errbuf            -- �G���[�E���b�Z�[�W
                   ,lv_retcode           -- ���^�[���E�R�[�h
                   ,lv_errmsg);
        -- ��O����
        IF (lv_retcode = cv_status_error) THEN
          --(�G���[����)
          gn_error_cnt := gn_error_cnt +1;
          RAISE global_process_expt;
        END IF;
        -- =============================================
        -- �f�[�^�̓o�^�i����l���^�����l���j(A-18)
        -- =============================================
        lr_plan_rec.location_cd            := NULL;                       -- ���_�R�[�h
        lr_plan_rec.location_nm            := NULL;                       -- ���_����
        lr_plan_rec.group1_cd              := cv_nebiki;                  -- ���i�Q�R�[�h�P
        lr_plan_rec.group1_nm              := NULL;                       -- ���i�Q���̂P
        lr_plan_rec.group4_cd              := NULL;                       -- ���i�Q�R�[�h�S
        lr_plan_rec.group4_nm              := NULL;                       -- ���i�Q���̂S
        lr_plan_rec.item_cd                := NULL;                       -- ���i�R�[�h
        lr_plan_rec.item_nm                := gv_sales_disc_nm;           -- ���i����
        lr_plan_rec.con_price              := NULL;                       -- �艿
        lr_plan_rec.amount                 := 0;                          -- ����
        lr_plan_rec.sales_budget           := ln_sales_discount;          -- ����l��
        lr_plan_rec.cost                   := 0;                          -- ����
        lr_plan_rec.margin                 := ln_sales_discount;          -- �e���v�z
        lr_plan_rec.margin_rate            := cv_margin_rate_dis;         -- �e���v��
        lr_plan_rec.credit_rate            := 0;                          -- �|��
--
        insert_data(
                  lr_plan_rec          -- �Ώۃ��R�[�h
                 ,lv_errbuf            -- �G���[�E���b�Z�[�W
                 ,lv_retcode           -- ���^�[���E�R�[�h
                 ,lv_errmsg);
        -- ��O����
        IF (lv_retcode = cv_status_error) THEN
          --(�G���[����)
          gn_error_cnt := gn_error_cnt +1;
          RAISE global_process_expt;
        END IF;
--
        lr_plan_rec.location_cd            := NULL;                       -- ���_�R�[�h
        lr_plan_rec.location_nm            := NULL;                       -- ���_����
        lr_plan_rec.group1_cd              := cv_nebiki;                  -- ���i�Q�R�[�h�P
        lr_plan_rec.group1_nm              := NULL;                       -- ���i�Q���̂P
        lr_plan_rec.group4_cd              := NULL;                       -- ���i�Q�R�[�h�S
        lr_plan_rec.group4_nm              := NULL;                       -- ���i�Q���̂S
        lr_plan_rec.item_cd                := NULL;                       -- ���i�R�[�h
        lr_plan_rec.item_nm                := gv_receipt_disc_nm;         -- ���i����
        lr_plan_rec.con_price              := NULL;                       -- �艿
        lr_plan_rec.amount                 := 0;                          -- ����
        lr_plan_rec.sales_budget           := ln_receipt_discount;        -- �����l��
        lr_plan_rec.cost                   := 0;                          -- ����
        lr_plan_rec.margin                 := ln_receipt_discount;        -- �e���v�z
        lr_plan_rec.margin_rate            := cv_margin_rate_dis;         -- �e���v��
        lr_plan_rec.credit_rate            := 0;                          -- �|��
--
        insert_data(
                  lr_plan_rec          -- �Ώۃ��R�[�h
                 ,lv_errbuf            -- �G���[�E���b�Z�[�W
                 ,lv_retcode           -- ���^�[���E�R�[�h
                 ,lv_errmsg);
        -- ��O����
        IF (lv_retcode = cv_status_error) THEN
          --(�G���[����)
          gn_error_cnt := gn_error_cnt +1;
          RAISE global_process_expt;
        END IF;
        -- =============================================
        -- �f�[�^�̒��o�i���_���v�j(A-19)
        -- =============================================
        select_kyot_total_data(
                    lr_sum_rec           -- ���o���R�[�h
                   ,lv_errbuf            -- �G���[�E���b�Z�[�W
                   ,lv_retcode           -- ���^�[���E�R�[�h
                   ,lv_errmsg);
        -- ��O����
        IF (lv_retcode = cv_status_error) THEN
          --(�G���[����)
          gn_error_cnt := gn_error_cnt +1;
          RAISE global_process_expt;
        END IF;
        -- =============================================
        -- �f�[�^�̎Z�o�i���_���v�j(A-20)
        -- =============================================
        --�e���v��
        IF (lr_sum_rec.sales_budget = 0) THEN
          ln_margin_rate := 0;
        ELSE
          ln_margin_rate := ROUND(lr_sum_rec.margin / lr_sum_rec.sales_budget * 100, 2);
        END IF;
        --�|��
        IF (lr_sum_rec.price_multi_amount = 0) THEN
          ln_credit_rate := 0;
        ELSE
          ln_credit_rate := ROUND(lr_sum_rec.sales_budget / lr_sum_rec.price_multi_amount * 100, 2);
        END IF;
        -- =============================================
        -- �f�[�^�̓o�^�i���_���v�j(A-21)
        -- =============================================
        lr_plan_rec.location_cd            := NULL;                       -- ���_�R�[�h
        lr_plan_rec.location_nm            := NULL;                       -- ���_����
        lr_plan_rec.group1_cd              := cv_kyoten_kei;              -- ���i�Q�R�[�h�P
        lr_plan_rec.group1_nm              := NULL;                       -- ���i�Q���̂P
        lr_plan_rec.group4_cd              := NULL;                       -- ���i�Q�R�[�h�S
        lr_plan_rec.group4_nm              := NULL;                       -- ���i�Q���̂S
        lr_plan_rec.item_cd                := NULL;                       -- ���i�R�[�h
        lr_plan_rec.item_nm                := gv_kyoten_kei_nm;           -- ���i����
        lr_plan_rec.con_price              := NULL;                       -- �艿
        lr_plan_rec.amount                 := lr_sum_rec.amount;          -- ����
        lr_plan_rec.sales_budget           := lr_sum_rec.sales_budget;    -- ����
        lr_plan_rec.cost                   := lr_sum_rec.cost;            -- ����
        lr_plan_rec.margin                 := lr_sum_rec.margin;          -- �e���v�z
        lr_plan_rec.margin_rate            := ln_margin_rate;             -- �e���v��
        lr_plan_rec.credit_rate            := ln_credit_rate;             -- �|��

        insert_data(
                  lr_plan_rec          -- �Ώۃ��R�[�h
                 ,lv_errbuf            -- �G���[�E���b�Z�[�W
                 ,lv_retcode           -- ���^�[���E�R�[�h
                 ,lv_errmsg);
        -- ��O����
        IF (lv_retcode = cv_status_error) THEN
          --(�G���[����)
          gn_error_cnt := gn_error_cnt +1;
          RAISE global_process_expt;
        END IF;
        gn_normal_cnt := gn_normal_cnt + 1;
        -- =============================================
        -- �`�F�b�N���X�g�f�[�^�o��(A-22)
        -- =============================================
        output_check_list(
                    iv_yyyy              -- �Ώ۔N�x
                   ,iv_p_kyoten_cd       -- ���_�R�[�h�i�p�����[�^�j
                   ,iv_kyoten_cd         -- ���_�R�[�h
                   ,iv_kyoten_nm         -- ���_��
                   ,lv_errbuf            -- �G���[�E���b�Z�[�W
                   ,lv_retcode           -- ���^�[���E�R�[�h
                   ,lv_errmsg);
        -- ��O����
        IF (lv_retcode = cv_status_error) THEN
          --(�G���[����)
          gn_error_cnt := gn_error_cnt +1;
          RAISE global_process_expt;
        END IF;

      END IF;
    END IF;
    -- =============================================
    -- �f�[�^�폜
    -- =============================================
    DELETE FROM xxcsm_tmp_item_plan_sales_sum;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
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
  END loop_kyoten;
--
  /**********************************************************************************
   * Procedure Name   : loop_main
   * Description      : ���C�����[�v
   ***********************************************************************************/
  PROCEDURE loop_main(
    iv_p_yyyy       IN  VARCHAR2,            -- 1.�Ώ۔N�x
    iv_p_kyoten_cd  IN  VARCHAR2,            -- 2.���_�R�[�h
    iv_p_cost_kind  IN  VARCHAR2,            -- 3.�������
    iv_p_level      IN  VARCHAR2,            -- 4.�K�w
--//+ADD START E_�{�ғ�_09949 K.Taniguchi
    iv_p_new_old_cost_class
                    IN  VARCHAR2,            -- 5.�V�������敪
--//+ADD END E_�{�ғ�_09949 K.Taniguchi
    ov_errbuf       OUT NOCOPY VARCHAR2,     --   �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode      OUT NOCOPY VARCHAR2,     --   ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg       OUT NOCOPY VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'loop_main'; -- �v���O������
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
    cv_lvl6   CONSTANT VARCHAR2(2) := 'L6'; -- ���_�K�w
    cv_lvl2   CONSTANT VARCHAR2(2) := 'L2'; -- ���_�K�w
    cv_lvl3   CONSTANT VARCHAR2(2) := 'L3'; -- ���_�K�w
    cv_lvl4   CONSTANT VARCHAR2(2) := 'L4'; -- ���_�K�w
    cv_lvl5   CONSTANT VARCHAR2(2) := 'L5'; -- ���_�K�w
--
    -- *** ���[�J���ϐ� ***
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    -- ���_�f�[�^L6
    CURSOR kyoten_l6_cur(
      iv_p_kyoten_cd  IN  VARCHAR2,                                 -- ���_�R�[�h�i�p�����[�^�j
      it_allkyoten_cd IN  fnd_lookup_values.lookup_code%TYPE)       -- �S���_�R�[�h
    IS
      SELECT
         nmv.base_code    base_code   --����R�[�h
        ,nmv.base_name    base_name   --���喼
      FROM
         xxcsm_loc_level_list_v  lvv  --����ꗗ�r���[
        ,xxcsm_loc_name_list_v   nmv  --���喼�̃r���[
      WHERE
         DECODE(lvv.location_level
                  ,cv_lvl6, lvv.cd_level6
                  ,cv_lvl5, lvv.cd_level5
                  ,cv_lvl4, lvv.cd_level4
                  ,cv_lvl3, lvv.cd_level3
                  ,cv_lvl2, lvv.cd_level2) = nmv.base_code
      AND
         nmv.base_code = DECODE(iv_p_kyoten_cd, it_allkyoten_cd, nmv.base_code, iv_p_kyoten_cd)
--// ADD START 2009/05/07 T1_0858 M.Ohtsuki
-- DEL  START  DATE:2011/01/06  AUTHOR:OUKOU  CONTENT:E-�{�ғ�_05803
--      AND EXISTS
--          (SELECT 'X'
--           FROM   xxcsm_item_plan_result   xipr                                                     -- ���i�v��p�̔�����
--           WHERE  (xipr.subject_year = (TO_NUMBER(iv_p_yyyy) - 1)                                   -- ���̓p�����[�^��1�N�O�̃f�[�^
--                OR xipr.subject_year = (TO_NUMBER(iv_p_yyyy) - 2))                                  -- ���̓p�����[�^��2�N�O�̃f�[�^
--           AND     xipr.location_cd  = nmv.base_code)
-- DEL  END  DATE:2010/01/06  AUTHOR:OUKOU  CONTENT:E-�{�ғ�_05803
--// ADD END   2009/05/07 T1_0858 M.Ohtsuki
      ORDER BY
         nmv.base_code    --����R�[�h
      ;
    -- ���_�f�[�^L6���R�[�h�^
    kyoten_rec kyoten_l6_cur%ROWTYPE;

    -- ���_�f�[�^L2
    CURSOR kyoten_l2_cur(
      iv_p_kyoten_cd  IN  VARCHAR2)     -- ���_�R�[�h�i�p�����[�^�j
    IS
      SELECT
         nmv.base_code    base_code   --����R�[�h
        ,nmv.base_name    base_name   --���喼
      FROM
         xxcsm_loc_level_list_v  lvv  --����ꗗ�r���[
        ,xxcsm_loc_name_list_v   nmv  --���喼�̃r���[
      WHERE
         DECODE(lvv.location_level
                  ,cv_lvl6, lvv.cd_level6
                  ,cv_lvl5, lvv.cd_level5
                  ,cv_lvl4, lvv.cd_level4
                  ,cv_lvl3, lvv.cd_level3
                  ,NULL) = nmv.base_code
      AND
         lvv.cd_level2 = iv_p_kyoten_cd
      ORDER BY
         nmv.base_code    --����R�[�h
      ;

    -- ���_�f�[�^L3
    CURSOR kyoten_l3_cur(
      iv_p_kyoten_cd  IN  VARCHAR2)     -- ���_�R�[�h�i�p�����[�^�j
    IS
      SELECT
         nmv.base_code    base_code   --����R�[�h
        ,nmv.base_name    base_name   --���喼
      FROM
         xxcsm_loc_level_list_v  lvv  --����ꗗ�r���[
        ,xxcsm_loc_name_list_v   nmv  --���喼�̃r���[
      WHERE
         DECODE(lvv.location_level
                  ,cv_lvl6, lvv.cd_level6
                  ,cv_lvl5, lvv.cd_level5
                  ,cv_lvl4, lvv.cd_level4
                  ,NULL) = nmv.base_code
      AND
         lvv.cd_level3 = iv_p_kyoten_cd
      ORDER BY
         nmv.base_code    --����R�[�h
      ;

    -- ���_�f�[�^L4
    CURSOR kyoten_l4_cur(
      iv_p_kyoten_cd  IN  VARCHAR2)     -- ���_�R�[�h�i�p�����[�^�j
    IS
      SELECT
         nmv.base_code    base_code   --����R�[�h
        ,nmv.base_name    base_name   --���喼
      FROM
         xxcsm_loc_level_list_v  lvv  --����ꗗ�r���[
        ,xxcsm_loc_name_list_v   nmv  --���喼�̃r���[
      WHERE
         DECODE(lvv.location_level
                  ,cv_lvl6, lvv.cd_level6
                  ,cv_lvl5, lvv.cd_level5
                  ,NULL) = nmv.base_code
      AND
         lvv.cd_level4 = iv_p_kyoten_cd
      ORDER BY
         nmv.base_code    --����R�[�h
      ;

    -- ���_�f�[�^L5
    CURSOR kyoten_l5_cur(
      iv_p_kyoten_cd  IN  VARCHAR2)     -- ���_�R�[�h�i�p�����[�^�j
    IS
      SELECT
         nmv.base_code    base_code   --����R�[�h
        ,nmv.base_name    base_name   --���喼
      FROM
         xxcsm_loc_level_list_v  lvv  --����ꗗ�r���[
        ,xxcsm_loc_name_list_v   nmv  --���喼�̃r���[
      WHERE
         DECODE(lvv.location_level
                  ,cv_lvl6, lvv.cd_level6
                  ,NULL) = nmv.base_code
      AND
         lvv.cd_level5 = iv_p_kyoten_cd
      ORDER BY
         nmv.base_code    --����R�[�h
      ;

  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- =============================================
    -- �f�[�^�̒��o�i���_�f�[�^�j�擾(A-2)
    -- =============================================
    CASE iv_p_level
      WHEN cv_lvl6 THEN
        OPEN kyoten_l6_cur(iv_p_kyoten_cd, gt_allkyoten_cd);
        <<kyoten_l6_loop>>
        LOOP
          FETCH kyoten_l6_cur INTO kyoten_rec;
          EXIT WHEN kyoten_l6_cur%NOTFOUND;
          -- ===============================
          -- ���_���[�v������
          -- ===============================
          loop_kyoten(
            iv_p_yyyy,                                         -- �Ώ۔N�x
            iv_p_kyoten_cd,                                    -- ���_�R�[�h�i�p�����[�^�j
            iv_p_cost_kind,                                    -- �������
            kyoten_rec.base_code,                              -- ���_�R�[�h
            kyoten_rec.base_name,                              -- ���_��
--//+ADD START E_�{�ғ�_09949 K.Taniguchi
            iv_p_new_old_cost_class,                           -- �V�������敪
--//+ADD END E_�{�ғ�_09949 K.Taniguchi
            lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
            lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
            lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
          IF (lv_retcode = cv_status_error) THEN
            RAISE global_process_expt;
          END IF;
        END LOOP kyoten_l6_loop;
        CLOSE kyoten_l6_cur;
      WHEN cv_lvl2 THEN
        OPEN kyoten_l2_cur(iv_p_kyoten_cd);
        <<kyoten_l2_loop>>
        LOOP
          FETCH kyoten_l2_cur INTO kyoten_rec;
          EXIT WHEN kyoten_l2_cur%NOTFOUND;
          -- ===============================
          -- ���_���[�v������
          -- ===============================
          loop_kyoten(
            iv_p_yyyy,                                         -- �Ώ۔N�x
            iv_p_kyoten_cd,                                    -- ���_�R�[�h�i�p�����[�^�j
            iv_p_cost_kind,                                    -- �������
            kyoten_rec.base_code,                              -- ���_�R�[�h
            kyoten_rec.base_name,                              -- ���_��
--//+ADD START E_�{�ғ�_09949 K.Taniguchi
            iv_p_new_old_cost_class,                           -- �V�������敪
--//+ADD END E_�{�ғ�_09949 K.Taniguchi
            lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
            lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
            lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
          IF (lv_retcode = cv_status_error) THEN
            RAISE global_process_expt;
          END IF;
        END LOOP kyoten_l2_loop;
        CLOSE kyoten_l2_cur;
      WHEN cv_lvl3 THEN
        OPEN kyoten_l3_cur(iv_p_kyoten_cd);
        <<kyoten_l3_loop>>
        LOOP
          FETCH kyoten_l3_cur INTO kyoten_rec;
          EXIT WHEN kyoten_l3_cur%NOTFOUND;
          -- ===============================
          -- ���_���[�v������
          -- ===============================
          loop_kyoten(
            iv_p_yyyy,                                         -- �Ώ۔N�x
            iv_p_kyoten_cd,                                    -- ���_�R�[�h�i�p�����[�^�j
            iv_p_cost_kind,                                    -- �������
            kyoten_rec.base_code,                              -- ���_�R�[�h
            kyoten_rec.base_name,                              -- ���_��
--//+ADD START E_�{�ғ�_09949 K.Taniguchi
            iv_p_new_old_cost_class,                           -- �V�������敪
--//+ADD END E_�{�ғ�_09949 K.Taniguchi
            lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
            lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
            lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
          IF (lv_retcode = cv_status_error) THEN
            RAISE global_process_expt;
          END IF;
        END LOOP kyoten_l3_loop;
        CLOSE kyoten_l3_cur;
      WHEN cv_lvl4 THEN
        OPEN kyoten_l4_cur(iv_p_kyoten_cd);
        <<kyoten_l4_loop>>
        LOOP
          FETCH kyoten_l4_cur INTO kyoten_rec;
          EXIT WHEN kyoten_l4_cur%NOTFOUND;
          -- ===============================
          -- ���_���[�v������
          -- ===============================
          loop_kyoten(
            iv_p_yyyy,                                         -- �Ώ۔N�x
            iv_p_kyoten_cd,                                    -- ���_�R�[�h�i�p�����[�^�j
            iv_p_cost_kind,                                    -- �������
            kyoten_rec.base_code,                              -- ���_�R�[�h
            kyoten_rec.base_name,                              -- ���_��
--//+ADD START E_�{�ғ�_09949 K.Taniguchi
            iv_p_new_old_cost_class,                           -- �V�������敪
--//+ADD END E_�{�ғ�_09949 K.Taniguchi
            lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
            lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
            lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
          IF (lv_retcode = cv_status_error) THEN
            RAISE global_process_expt;
          END IF;
        END LOOP kyoten_l4_loop;
        CLOSE kyoten_l4_cur;
      WHEN cv_lvl5 THEN
        OPEN kyoten_l5_cur(iv_p_kyoten_cd);
        <<kyoten_l5_loop>>
        LOOP
          FETCH kyoten_l5_cur INTO kyoten_rec;
          EXIT WHEN kyoten_l5_cur%NOTFOUND;
          -- ===============================
          -- ���_���[�v������
          -- ===============================
          loop_kyoten(
            iv_p_yyyy,                                         -- �Ώ۔N�x
            iv_p_kyoten_cd,                                    -- ���_�R�[�h�i�p�����[�^�j
            iv_p_cost_kind,                                    -- �������
            kyoten_rec.base_code,                              -- ���_�R�[�h
            kyoten_rec.base_name,                              -- ���_��
--//+ADD START E_�{�ғ�_09949 K.Taniguchi
            iv_p_new_old_cost_class,                           -- �V�������敪
--//+ADD END E_�{�ғ�_09949 K.Taniguchi
            lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
            lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
            lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
          IF (lv_retcode = cv_status_error) THEN
            RAISE global_process_expt;
          END IF;
        END LOOP kyoten_l5_loop;
        CLOSE kyoten_l5_cur;
--
      ELSE
        NULL;
    END CASE;

--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      IF (kyoten_l6_cur%ISOPEN) THEN
        CLOSE kyoten_l6_cur;
      END IF;
      IF (kyoten_l2_cur%ISOPEN) THEN
        CLOSE kyoten_l2_cur;
      END IF;
      IF (kyoten_l3_cur%ISOPEN) THEN
        CLOSE kyoten_l3_cur;
      END IF;
      IF (kyoten_l4_cur%ISOPEN) THEN
        CLOSE kyoten_l4_cur;
      END IF;
      IF (kyoten_l5_cur%ISOPEN) THEN
        CLOSE kyoten_l5_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
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
  END loop_main;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    iv_p_yyyy       IN  VARCHAR2,     -- 1.�Ώ۔N�x
    iv_p_kyoten_cd  IN  VARCHAR2,     -- 2.���_�R�[�h
    iv_p_cost_kind  IN  VARCHAR2,     -- 3.�������
    iv_p_level      IN  VARCHAR2,     -- 4.�K�w
--//+ADD START E_�{�ғ�_09949 K.Taniguchi
    iv_p_new_old_cost_class
                    IN  VARCHAR2,     -- 5.�V�������敪
--//+ADD END E_�{�ғ�_09949 K.Taniguchi
    ov_errbuf       OUT NOCOPY VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode      OUT NOCOPY VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg       OUT NOCOPY VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
--//+ADD START 2009/02/12   CT007 M.Ohtsuki
    lv_nodata_msg          VARCHAR2(100);
    lv_header              VARCHAR2(4000);
--//+ADD END   2009/02/12   CT007 M.Ohtsuki
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
       iv_p_yyyy                            -- �Ώ۔N�x
      ,iv_p_kyoten_cd                       -- ���_�R�[�h
      ,iv_p_cost_kind                       -- �������
      ,iv_p_level                           -- �K�w
--//+ADD START E_�{�ғ�_09949 K.Taniguchi
      ,iv_p_new_old_cost_class              -- �V�������敪
--//+ADD END E_�{�ғ�_09949 K.Taniguchi
      ,lv_errbuf                            -- �G���[�E���b�Z�[�W
      ,lv_retcode                           -- ���^�[���E�R�[�h
      ,lv_errmsg                            -- ���[�U�[�E�G���[�E���b�Z�[�W
      );
    IF (lv_retcode = cv_status_error) THEN  -- �߂�l���ȏ�̏ꍇ
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- ���C�����[�v
    -- ===============================
    loop_main(                              -- loop_main���R�[��
       iv_p_yyyy                            -- �Ώ۔N�x
      ,iv_p_kyoten_cd                       -- ���_�R�[�h
      ,iv_p_cost_kind                       -- �������
      ,iv_p_level                           -- �K�w
--//+ADD START E_�{�ғ�_09949 K.Taniguchi
      ,iv_p_new_old_cost_class              -- �V�������敪
--//+ADD END E_�{�ғ�_09949 K.Taniguchi
      ,lv_errbuf                            -- �G���[�E���b�Z�[�W
      ,lv_retcode                           -- ���^�[���E�R�[�h
      ,lv_errmsg                            -- ���[�U�[�E�G���[�E���b�Z�[�W
      );
    IF (lv_retcode = cv_status_error) THEN  -- �߂�l���ȏ�̏ꍇ
      RAISE global_process_expt;
    END IF;
    -- �o�͂ł��Ȃ��������̂��������ꍇ�͌x���I��
    IF (gn_warn_cnt > 0) THEN
      ov_retcode := cv_status_warn;
    END IF;
--//+ADD START 2009/02/12   CT007 M.Ohtsuki
    IF (gn_normal_cnt = 0) THEN
      lv_header := xxccp_common_pkg.get_msg(
                    iv_application  => cv_xxcsm
                   ,iv_name         => cv_lst_head_msg
                   ,iv_token_name1  => cv_tkn_cd_yyyy
                   ,iv_token_value1 => iv_p_yyyy
                   ,iv_token_name2  => cv_tkn_nichiji
                   ,iv_token_value2 => TO_CHAR(gd_sysdate, 'YYYY/MM/DD HH24:MI:SS')
                   ,iv_token_name3  => cv_tkn_cost_kind_nm
                   ,iv_token_value3 => gv_cost_kind_nm
                 );
      lv_nodata_msg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_xxcsm
                         ,iv_name         => cv_nodata_msg
                        );
      -- �f�[�^�o��
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_header || CHR(10) ||
                   lv_nodata_msg
         );
--//+ADD START 2009/07/15   0000678 M.Ohtsuki
      ov_retcode := cv_status_warn;
--//+ADD END   2009/07/15   0000678 M.Ohtsuki
    END IF;
--//+ADD END   2009/02/12   CT007 M.Ohtsuki
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
    errbuf          OUT NOCOPY VARCHAR2,      --   �G���[�E���b�Z�[�W  --# �Œ� #
    retcode         OUT NOCOPY VARCHAR2,      --   ���^�[���E�R�[�h    --# �Œ� #
    iv_p_yyyy       IN  VARCHAR2,      -- 1.�Ώ۔N�x
    iv_p_kyoten_cd  IN  VARCHAR2,      -- 2.���_�R�[�h
    iv_p_cost_kind  IN  VARCHAR2,      -- 3.�������
    iv_p_level      IN  VARCHAR2,      -- 4.�K�w
--//+ADD START E_�{�ғ�_09949 K.Taniguchi
    iv_p_new_old_cost_class
                    IN  VARCHAR2       -- 5.�V�������敪
--//+ADD END E_�{�ғ�_09949 K.Taniguchi
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
       iv_p_yyyy                                   -- �Ώ۔N�x
      ,iv_p_kyoten_cd                              -- ���_�R�[�h
      ,iv_p_cost_kind                              -- �������
      ,iv_p_level                                  -- �K�w
--//+ADD START E_�{�ғ�_09949 K.Taniguchi
      ,iv_p_new_old_cost_class                     -- �V�������敪
--//+ADD END E_�{�ғ�_09949 K.Taniguchi
      ,lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    --�G���[�o��
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
END XXCSM002A10C;
/
