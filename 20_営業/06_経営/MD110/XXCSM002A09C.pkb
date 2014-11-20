CREATE OR REPLACE PACKAGE BODY XXCSM002A09C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCSM002A09C(body)
 * Description      : �N�ԏ��i�v��i�c�ƌ����j�`�F�b�N���X�g�o��
 * MD.050           : �N�ԏ��i�v��i�c�ƌ����j�`�F�b�N���X�g�o�� MD050_CSM_002_A09
 * Version          : 1.6
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   ��������(A-1)
 *  chk_plandata           �N�ԏ��i�v��f�[�^���݃`�F�b�N(A-3)
 *  chk_propdata           �������σf�[�^���݃`�F�b�N(A-4)
 *  select_grp3_total_data �f�[�^�̒��o�i���i�Q�j(A-8)
 *  select_grp1_total_data �f�[�^�̒��o�i���i�敪�j(A-11)
 *  select_com_total_data  �f�[�^�̒��o�i���i���v�j(A-14)
 *  select_discount_data   �f�[�^�̒��o�i����l���^�����l���j(A-17)
 *  select_kyot_total_data �f�[�^�̒��o�i���_���v�^�g��j(A-19)
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
 *  2008-12-11    1.0   K.Yamada         �V�K�쐬
 *  2009-02-10    1.1   M.Ohtsuki       �m��QCT_006�n�ގ��@�\���쓝��C��
 *  2009-02-20    1.2   M.Ohtsuki       �m��QCT_053�n�}�C�i�X���i�̕s��̑Ή�
 *  2009-05-12    1.3   M.Ohtsuki       �m��QT1_0858�n���_�R�[�h���o�����̕s���̑Ή�
 *  2009-07-15    1.4   M.Ohtsuki       �m0000678�n�Ώۃf�[�^0�����̃X�e�[�^�X�s��̑Ή�
 *  2010-02-25    1.5   T.Nakano        �mE_�{�ғ�_01681�nH��Z�o�����ύX
 *  2011-01-05    1.6   SCS OuKou        [E_�{�ғ�_05803]
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
  cv_pkg_name      CONSTANT VARCHAR2(100) := 'XXCSM002A09C';                 -- �p�b�P�[�W��
  cv_flg_y         CONSTANT VARCHAR2(1)   := 'Y';                            -- �t���OY

  --���b�Z�[�W�[�R�[�h
  cv_prof_err_msg  CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00005';             -- �v���t�@�C���擾�G���[
  cv_noplandt_msg  CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00087';             -- ���i�v�斢�ݒ�
  cv_nopropdt_msg  CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00088';             -- ���i�v��P�i�ʈ�����������
  cv_lst_head_msg  CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00089';             -- �N�ԏ��i�v��i�c�ƌ����j�`�F�b�N���X�g�w�b�_�p
  cv_par_yyyy_msg  CONSTANT VARCHAR2(100) := 'APP-XXCSM1-10003';             -- �R���J�����g���̓p�����[�^(�Ώ۔N�x)
  cv_par_kyotn_msg CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00048';             -- �R���J�����g���̓p�����[�^(���_�R�[�h)
  cv_par_level_msg CONSTANT VARCHAR2(100) := 'APP-XXCSM1-10004';             -- �R���J�����g���̓p�����[�^(�K�w)
--//+ADD START 2009/02/12   CT006 M.Ohtsuki
  cv_nodata_msg    CONSTANT VARCHAR2(100) := 'APP-XXCSM1-10001';             -- �Ώۃf�[�^0���G���[���b�Z�[�W 
--//+ADD END   2009/02/12   CT006 M.Ohtsuki
  --�g�[�N��
  cv_tkn_cd_prof   CONSTANT VARCHAR2(100) := 'PROF_NAME';                    -- �J�X�^���E�v���t�@�C���E�I�v�V�����̉p��
  cv_tkn_cd_yyyy   CONSTANT VARCHAR2(100) := 'YYYY';                         -- �Ώ۔N�x
  cv_tkn_cd_tsym   CONSTANT VARCHAR2(100) := 'TAISYOU_YM';                   -- �Ώ۔N�x
  cv_tkn_cd_kyoten CONSTANT VARCHAR2(100) := 'KYOTEN_CD';                    -- ���_�R�[�h
  cv_tkn_nm_kyoten CONSTANT VARCHAR2(100) := 'KYOTEN_NM';                    -- ���_��
  cv_tkn_cd_level  CONSTANT VARCHAR2(100) := 'HIERARCHY_LEVEL';              -- �K�w
  cv_tkn_nichiji   CONSTANT VARCHAR2(100) := 'SAKUSEI_NICHIJI';              -- �쐬����
  cv_chk1_profile  CONSTANT VARCHAR2(100) := 'XXCSM1_CHECKLIST_ITEM_1';      -- �`�F�b�N���X�g���ږ��i���i���v�j�v���t�@�C����
  cv_chk2_profile  CONSTANT VARCHAR2(100) := 'XXCSM1_CHECKLIST_ITEM_2';      -- �`�F�b�N���X�g���ږ��i����l���j�v���t�@�C����
  cv_chk3_profile  CONSTANT VARCHAR2(100) := 'XXCSM1_CHECKLIST_ITEM_3';      -- �`�F�b�N���X�g���ږ��i�����l���j�v���t�@�C����
  cv_chk4_profile  CONSTANT VARCHAR2(100) := 'XXCSM1_CHECKLIST_ITEM_4';      -- �`�F�b�N���X�g���ږ��i�g��j�v���t�@�C����

  cv_lookup_type   CONSTANT VARCHAR2(100) := 'XXCSM1_FORM_PARAMETER_VALUE';  -- �S���_�R�[�h�擾�p

  cv_item_kbn      CONSTANT VARCHAR2(1)   := '0';                            -- ���i�敪�i���i�Q�j�����Ă������

  -- ���i�敪
  cv_leaf          CONSTANT VARCHAR2(1)   := 'A';                            -- ���i�敪�iLEAF�j
  cv_drink         CONSTANT VARCHAR2(1)   := 'C';                            -- ���i�敪�iDRINK�j
  cv_sonota        CONSTANT VARCHAR2(1)   := 'D';                            -- ���i�敪�i���̑��j
  cv_nebiki        CONSTANT VARCHAR2(1)   := 'N';                            -- ���i�敪�i�l���j
  cv_kyoten_kei    CONSTANT VARCHAR2(1)   := 'K';                            -- ���i�敪�i���_�v���j

--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  TYPE g_sum_data_rtype IS RECORD(
       group_cd                xxcsm_tmp_item_plan_sales.group3_cd%TYPE     -- ���i�Q�R�[�h
      ,group_nm                xxcsm_tmp_item_plan_sales.group3_nm%TYPE     -- ���i�Q����
      ,con_price               xxcsm_tmp_item_plan_sales.con_price%TYPE     -- �艿
      ,amount                  xxcsm_tmp_item_plan_sales.amount%TYPE        -- ����
      ,price_multi_amount      xxcsm_tmp_item_plan_sales.sales_budget%TYPE  -- �艿 * ����
      ,sales_budget            xxcsm_tmp_item_plan_sales.sales_budget%TYPE  -- ����
      ,cost                    xxcsm_tmp_item_plan_sales.cost%TYPE          -- ����
      ,margin                  xxcsm_tmp_item_plan_sales.margin%TYPE        -- �e���v�z
      ,base_margin             xxcsm_tmp_item_plan_sales.base_margin%TYPE   -- �W�������e���v�z
   );
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gd_sysdate           DATE;
  gt_allkyoten_cd      fnd_lookup_values.lookup_code%TYPE;       -- �S���_�R�[�h
  gv_total_com_nm      xxcsm_tmp_item_plan_sales.item_nm%TYPE;   -- �`�F�b�N���X�g���ږ��i���i���v�j
  gv_sales_disc_nm     xxcsm_tmp_item_plan_sales.item_nm%TYPE;   -- �`�F�b�N���X�g���ږ��i����l���j
  gv_receipt_disc_nm   xxcsm_tmp_item_plan_sales.item_nm%TYPE;   -- �`�F�b�N���X�g���ږ��i�����l���j
  gv_h_base_nm         xxcsm_tmp_item_plan_sales.item_nm%TYPE;   -- �`�F�b�N���X�g���ږ��i�g��j
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    iv_yyyy       IN  VARCHAR2,            -- 1.�Ώ۔N�x
    iv_kyoten_cd  IN  VARCHAR2,            -- 2.���_�R�[�h
    iv_level      IN  VARCHAR2,            -- 3.�K�w
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
    --�K�w
    lv_pram_op := xxccp_common_pkg.get_msg(
                                            iv_application  => cv_xxcsm
                                           ,iv_name         => cv_par_level_msg
                                           ,iv_token_name1  => cv_tkn_cd_level
                                           ,iv_token_value1 => iv_level
                                           );
    FND_FILE.PUT_LINE(FND_FILE.LOG, lv_pram_op);
    FND_FILE.PUT_LINE(FND_FILE.LOG, '');
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

    --�`�F�b�N���X�g���ږ��i���i���v�j�擾
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

    --�`�F�b�N���X�g���ږ��i����l���j�擾
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

    --�`�F�b�N���X�g���ږ��i�����l���j�擾
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

    --�`�F�b�N���X�g���ږ��i�g��j�擾
    gv_h_base_nm := FND_PROFILE.VALUE(cv_chk4_profile);
    IF (gv_h_base_nm IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                                            iv_application  => cv_xxcsm
                                           ,iv_name         => cv_prof_err_msg
                                           ,iv_token_name1  => cv_tkn_cd_prof
                                           ,iv_token_value1 => cv_chk4_profile
                                           );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;

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
  PROCEDURE select_grp3_total_data(
    it_group_cd    IN  xxcsm_tmp_item_plan_sales.group3_cd%TYPE,  -- ���i�Q�R�[�h�R
    or_sum_rec     OUT NOCOPY g_sum_data_rtype,                   -- ���o���R�[�h
    ov_errbuf      OUT NOCOPY VARCHAR2,                    -- �G���[�E���b�Z�[�W
    ov_retcode     OUT NOCOPY VARCHAR2,                    -- ���^�[���E�R�[�h
    ov_errmsg      OUT NOCOPY VARCHAR2)                    -- ���[�U�[�E�G���[�E���b�Z�[�W
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'select_grp3_total_data'; -- �v���O������
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
       xti.group3_cd                   group3_cd                 -- ���i�Q�R�[�h�R
      ,xti.group3_nm                   group3_nm                 -- ���i�Q���̂R
      ,SUM(xti.con_price)              con_price                 -- �艿
      ,SUM(xti.amount)                 amount                    -- ����
      ,SUM(xti.con_price * xti.amount)     price_multi_amount        -- �艿 * ����
      ,SUM(xti.sales_budget)           sales_budget              -- ����
      ,SUM(xti.cost)                   cost                      -- ����
      ,SUM(xti.margin)                 margin                    -- �e���v�z
      ,SUM(xti.base_margin)            base_margin               -- �W�������e���v�z
    INTO
       or_sum_rec.group_cd
      ,or_sum_rec.group_nm
      ,or_sum_rec.con_price
      ,or_sum_rec.amount
      ,or_sum_rec.price_multi_amount
      ,or_sum_rec.sales_budget
      ,or_sum_rec.cost
      ,or_sum_rec.margin
      ,or_sum_rec.base_margin
    FROM
      xxcsm_tmp_item_plan_sales  xti  -- ���i�v��c�ƌ������[�N�e�[�u��
    WHERE
      xti.group3_cd  = it_group_cd    -- ���i�Q�R�[�h�R
    GROUP BY
       xti.group3_cd                  -- ���i�Q�R�[�h�R
      ,xti.group3_nm                  -- ���i�Q���̂R
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
      or_sum_rec.base_margin        := 0;
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
  END select_grp3_total_data;
--
  /**********************************************************************************
   * Procedure Name   : select_grp1_total_data
   * Description      : �f�[�^�̒��o�i���i�敪�j(A-11)
   ***********************************************************************************/
  PROCEDURE select_grp1_total_data(
    it_group_cd    IN  xxcsm_tmp_item_plan_sales.group1_cd%TYPE,  -- ���i�Q�R�[�h�P
    or_sum_rec     OUT NOCOPY g_sum_data_rtype,                   -- ���o���R�[�h
    ov_errbuf      OUT NOCOPY VARCHAR2,                    -- �G���[�E���b�Z�[�W
    ov_retcode     OUT NOCOPY VARCHAR2,                    -- ���^�[���E�R�[�h
    ov_errmsg      OUT NOCOPY VARCHAR2)                    -- ���[�U�[�E�G���[�E���b�Z�[�W
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
       xti.group1_cd                   group1_cd                 -- ���i�Q�R�[�h�P
      ,xti.group1_nm                   group1_nm                 -- ���i�Q���̂P
      ,SUM(xti.con_price)              con_price                 -- �艿
      ,SUM(xti.amount)                 amount                    -- ����
      ,SUM(xti.con_price * xti.amount)     price_multi_amount        -- �艿 * ����
      ,SUM(xti.sales_budget)           sales_budget              -- ����
      ,SUM(xti.cost)                   cost                      -- ����
      ,SUM(xti.margin)                 margin                    -- �e���v�z
      ,SUM(xti.base_margin)            base_margin               -- �W�������e���v�z
    INTO
       or_sum_rec.group_cd
      ,or_sum_rec.group_nm
      ,or_sum_rec.con_price
      ,or_sum_rec.amount
      ,or_sum_rec.price_multi_amount
      ,or_sum_rec.sales_budget
      ,or_sum_rec.cost
      ,or_sum_rec.margin
      ,or_sum_rec.base_margin
    FROM
      xxcsm_tmp_item_plan_sales  xti  -- ���i�v��c�ƌ������[�N�e�[�u��
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
        xxcsm_commodity_group3_v  cgv   --���i�Q�R�r���[
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
      or_sum_rec.base_margin        := 0;
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
      ,NVL(SUM(xti.base_margin), 0)            base_margin               -- �W�������e���v�z
    INTO
       or_sum_rec.con_price
      ,or_sum_rec.amount
      ,or_sum_rec.price_multi_amount
      ,or_sum_rec.sales_budget
      ,or_sum_rec.cost
      ,or_sum_rec.margin
      ,or_sum_rec.base_margin
    FROM
      xxcsm_tmp_item_plan_sales  xti   -- ���i�v��c�ƌ������[�N�e�[�u��
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
      or_sum_rec.base_margin        := 0;
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
       SUM(ipb.sales_discount)         sales_discount            -- ����l��
      ,SUM(ipb.receipt_discount)       receipt_discount          -- �����l��
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
   * Description      : �f�[�^�̒��o�i���_���v�^�g��j(A-19)
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
       SUM(xti.con_price)              con_price                 -- �艿
      ,SUM(xti.amount)                 amount                    -- ����
      ,SUM(xti.con_price * xti.amount) price_multi_amount        -- �艿 * ����
      ,SUM(xti.sales_budget)           sales_budget              -- ����
      ,SUM(xti.cost)                   cost                      -- ����
      ,SUM(xti.margin)                 margin                    -- �e���v�z
      ,SUM(xti.base_margin)            base_margin               -- �W�������e���v�z
    INTO
       or_sum_rec.con_price
      ,or_sum_rec.amount
      ,or_sum_rec.price_multi_amount
      ,or_sum_rec.sales_budget
      ,or_sum_rec.cost
      ,or_sum_rec.margin
      ,or_sum_rec.base_margin
    FROM
      xxcsm_tmp_item_plan_sales   xti  -- ���i�v��c�ƌ������[�N�e�[�u��
    WHERE
      xti.group1_cd  IN (cv_leaf, cv_drink, cv_sonota, cv_nebiki)   -- ���i�Q�R�[�h�P
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
  END select_kyot_total_data;
--
  /**********************************************************************************
   * Procedure Name   : insert_data
   * Description      : �f�[�^�o�^(A-7,10,13,16,18,21)
   ***********************************************************************************/
  PROCEDURE insert_data(
    ir_plan_rec    IN  xxcsm_tmp_item_plan_sales%ROWTYPE,  -- �Ώۃ��R�[�h
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
    INSERT INTO xxcsm_tmp_item_plan_sales(     -- ���i�v��c�ƌ������[�N�e�[�u��
       toroku_no                  -- �o�͏�
      ,group1_cd                  -- ���i�Q�R�[�h�P
      ,group1_nm                  -- ���i�Q���̂P
      ,group3_cd                  -- ���i�Q�R�[�h�R
      ,group3_nm                  -- ���i�Q���̂R
      ,item_cd                    -- ���i�R�[�h
      ,item_nm                    -- ���i����
      ,con_price                  -- �艿
      ,amount                     -- ����
      ,sales_budget               -- ����
      ,cost                       -- ����
      ,margin                     -- �e���v�z
      ,margin_rate                -- �e���v��
      ,credit_rate                -- �|��
      ,base_margin                -- �W�������e���v�z
    )VALUES(
       xxcsm_tmp_item_plan_sales_s01.NEXTVAL
      ,ir_plan_rec.group1_cd
      ,ir_plan_rec.group1_nm
      ,ir_plan_rec.group3_cd
      ,ir_plan_rec.group3_nm
      ,ir_plan_rec.item_cd
      ,ir_plan_rec.item_nm
      ,ir_plan_rec.con_price
      ,ir_plan_rec.amount
      ,ir_plan_rec.sales_budget
      ,ir_plan_rec.cost
      ,ir_plan_rec.margin
      ,ir_plan_rec.margin_rate
      ,ir_plan_rec.credit_rate
      ,ir_plan_rec.base_margin
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
    lv_kyoten_nm         VARCHAR2(100);       -- �S���_

    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    -- CSV�o�͗p���_�v�f�[�^
    CURSOR output_kei_cur
    IS
      SELECT
        -- toroku_no                  -- �o�͏�
           cv_sep_wquot || xti.item_cd || cv_sep_wquot                    -- ���i�R�[�h
        || cv_sep_com || cv_sep_wquot || xti.item_nm || cv_sep_wquot      -- ���i����
        || cv_sep_com || TO_CHAR(xti.amount)                              -- ����
        || cv_sep_com || TO_CHAR(ROUND(xti.sales_budget/1000))            -- ����
        || cv_sep_com || TO_CHAR(ROUND(xti.cost/1000))                    -- ����
        || cv_sep_com || TO_CHAR(ROUND(xti.margin/1000))                  -- �e���v�z
        || cv_sep_com || TO_CHAR(xti.margin_rate)                         -- �e���v��
        || cv_sep_com || TO_CHAR(xti.credit_rate)                         -- �|��
        output_list
      FROM
        xxcsm_tmp_item_plan_sales  xti  --���i�v��c�ƌ������[�N�e�[�u��
      WHERE
        xti.group1_cd  = cv_kyoten_kei  -- ���i�Q�R�[�h�P
      ORDER BY
        xti.toroku_no                   -- �o�͏�
    ;

    -- CSV�o�͗p�S�f�[�^
    CURSOR output_all_cur
    IS
      SELECT
        -- toroku_no                  -- �o�͏�
           cv_sep_wquot || xti.item_cd || cv_sep_wquot                    -- ���i�R�[�h
        || cv_sep_com || cv_sep_wquot || xti.item_nm || cv_sep_wquot      -- ���i����
        || cv_sep_com || TO_CHAR(xti.amount)                              -- ����
        || cv_sep_com || TO_CHAR(ROUND(xti.sales_budget/1000))            -- ����
        || cv_sep_com || TO_CHAR(ROUND(xti.cost/1000))                    -- ����
        || cv_sep_com || TO_CHAR(ROUND(xti.margin/1000))                  -- �e���v�z
        || cv_sep_com || TO_CHAR(xti.margin_rate)                         -- �e���v��
        || cv_sep_com || TO_CHAR(xti.credit_rate)                         -- �|��
        output_list
      FROM
        xxcsm_tmp_item_plan_sales  xti  --���i�v��c�ƌ������[�N�e�[�u��
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

    SELECT
      COUNT(*)    cnt
    INTO
      ln_cnt
    FROM
      fnd_lookup_values  flv  --�N�C�b�N�R�[�h�l
    WHERE
      flv.lookup_type = cv_lookup_type
    AND
      flv.lookup_code = iv_p_kyoten_cd
    AND
      ROWNUM = 1
    ;

    IF (ln_cnt = 1) THEN
      -- �c�Ɗ�敔�u�S���_�v�̏ꍇ
      IF (gn_normal_cnt = 1) THEN
        -- ����̂݃w�b�_�o��
        SELECT
          xlv.location_nm location_nm
        INTO
          lv_kyoten_nm
        FROM
          xxcsm_location_all_v  xlv
        WHERE
          xlv.location_cd = iv_p_kyoten_cd
        ;

        lv_header := xxccp_common_pkg.get_msg(
                        iv_application  => cv_xxcsm
                       ,iv_name         => cv_lst_head_msg
                       ,iv_token_name1  => cv_tkn_cd_kyoten
                       ,iv_token_value1 => iv_p_kyoten_cd
                       ,iv_token_name2  => cv_tkn_nm_kyoten
                       ,iv_token_value2 => lv_kyoten_nm
                       ,iv_token_name3  => cv_tkn_cd_yyyy
                       ,iv_token_value3 => iv_yyyy
                       ,iv_token_name4  => cv_tkn_nichiji
                       ,iv_token_value4 => TO_CHAR(gd_sysdate, 'YYYY/MM/DD HH24:MI:SS')
                     );
        -- �f�[�^�o��
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_header
        );
      END IF;

      OPEN output_kei_cur();
      <<output_kei_loop>>
      LOOP
        FETCH output_kei_cur INTO lv_csv_data;
        EXIT WHEN output_kei_cur%NOTFOUND;

        -- �f�[�^�o��
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_csv_data
        );
      END LOOP output_kei_loop;
      CLOSE output_kei_cur;

    ELSE
      OPEN output_all_cur();
      lv_header := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcsm
                     ,iv_name         => cv_lst_head_msg
                     ,iv_token_name1  => cv_tkn_cd_kyoten
                     ,iv_token_value1 => iv_kyoten_cd
                     ,iv_token_name2  => cv_tkn_nm_kyoten
                     ,iv_token_value2 => iv_kyoten_nm
                     ,iv_token_name3  => cv_tkn_cd_yyyy
                     ,iv_token_value3 => iv_yyyy
                     ,iv_token_name4  => cv_tkn_nichiji
                     ,iv_token_value4 => TO_CHAR(gd_sysdate, 'YYYY/MM/DD HH24:MI:SS')
                   );
      -- �f�[�^�o��
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_header
      );

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
  END output_check_list;
--
  /**********************************************************************************
   * Procedure Name   : loop_kyoten
   * Description      : ���_���[�v������
   ***********************************************************************************/
  PROCEDURE loop_kyoten(
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
    cv_exit_group3_cd  CONSTANT VARCHAR2(10)  := '!!!';          -- �ŏI���i�Q�R�[�h�R
--
    cv_max_margin_rate CONSTANT NUMBER(7,2)  := 99999.99;        -- �i�[�ł���ő�e���v��
    cv_max_credit_rate CONSTANT NUMBER(7,2)  := 99999.99;        -- �i�[�ł���ő�|��
    cv_max_rate        CONSTANT NUMBER(7,2)  := NULL;            -- ���x�𒴂���ꍇ�̗�
--
    -- *** ���[�J���ϐ� ***
    lt_group1_cd           xxcsm_tmp_item_plan_sales.group1_cd%TYPE;    --���i�Q�R�[�h�P
    lt_group3_cd           xxcsm_tmp_item_plan_sales.group3_cd%TYPE;    --���i�Q�R�[�h�R
    lt_pre_group1_cd       xxcsm_tmp_item_plan_sales.group1_cd%TYPE;    --���i�Q�R�[�h�P�i�O���R�[�h�j
    lt_pre_group3_cd       xxcsm_tmp_item_plan_sales.group3_cd%TYPE;    --���i�Q�R�[�h�R�i�O���R�[�h�j
    ln_cost                NUMBER;    --����
    ln_margin              NUMBER;    --�e���v�z
    ln_base_margin         NUMBER;    --�W�������e���v�z
    ln_margin_rate         NUMBER;    --�e���v��
    ln_credit_rate         NUMBER;    --�|��
    ln_sales_discount      NUMBER;    --����l��
    ln_receipt_discount    NUMBER;    --�����l��

    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    -- �N�ԏ��i�v��f�[�^
    CURSOR item_plan_cur(
      in_yyyy         IN  NUMBER,       -- 1.�Ώ۔N�x
      iv_kyoten_cd    IN  VARCHAR2)     -- 2.���_�R�[�h
    IS
      SELECT
         cgv.group1_cd                  group1_cd      --���i�Q�R�[�h�P
        ,cgv.group1_nm                  group1_nm      --���i�Q���̂P
        ,SUBSTRB(cgv.group3_cd, 1, 3)   group3_cd      --���i�Q�R�[�h�R
        ,cgv.group3_nm                  group3_nm      --���i�Q���̂R
        ,cgv.item_cd                    item_cd        --�i�ڃR�[�h
        ,cgv.item_nm                    item_nm        --�i�ږ���
        ,NVL(cgv.now_item_cost, 0)      base_price     --�W������
        ,NVL(cgv.now_business_cost, 0)  bus_price      --�c�ƌ���
        ,NVL(cgv.now_unit_price, 0)     con_price      --�艿
        ,NVL(SUM(ipl.amount), 0)        amount         --����
        ,NVL(SUM(ipl.sales_budget), 0)  sales_budget   --����
      FROM
         xxcsm_item_plan_headers   iph   --���i�v��w�b�_�e�[�u��
        ,xxcsm_item_plan_lines     ipl   --���i�v�斾�׃e�[�u��
        ,xxcsm_commodity_group3_v  cgv   --���i�Q�R�r���[
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
      GROUP BY
         cgv.group1_cd                         --���i�Q�R�[�h�P
        ,cgv.group1_nm                         --���i�Q���̂P
        ,cgv.group3_cd                         --���i�Q�R�[�h�R
        ,cgv.group3_nm                         --���i�Q���̂R
        ,cgv.item_cd                           --�i�ڃR�[�h
        ,cgv.item_nm                           --�i�ږ���
        ,cgv.now_item_cost                     --�W������
        ,cgv.now_business_cost                 --�c�ƌ���
        ,cgv.now_unit_price                    --�艿
      ORDER BY
         cgv.group1_cd                         --���i�Q�R�[�h�P
        ,cgv.group3_cd                         --���i�Q�R�[�h�R
        ,cgv.item_cd                           --�i�ڃR�[�h
      ;
    -- �N�ԏ��i�v��f�[�^���R�[�h�^
    item_plan_rec item_plan_cur%ROWTYPE;

    -- ���i�v��c�ƌ������[�N�e�[�u�����R�[�h�^
    lr_plan_rec    xxcsm_tmp_item_plan_sales%ROWTYPE;

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
        OPEN item_plan_cur(TO_NUMBER(iv_yyyy), iv_kyoten_cd);
        <<item_plan_loop>>
        LOOP
          FETCH item_plan_cur INTO item_plan_rec;

          lt_pre_group1_cd := lt_group1_cd;
          lt_pre_group3_cd := lt_group3_cd;
          IF item_plan_cur%NOTFOUND THEN
            lt_group1_cd     := cv_exit_group1_cd;
            lt_group3_cd     := cv_exit_group3_cd;
          ELSE
            lt_group1_cd     := item_plan_rec.group1_cd;
            lt_group3_cd     := item_plan_rec.group3_cd;
          END IF;

          -- ���i�Q���ς�����珤�i�Q�v��o�^
          IF (lt_group3_cd <> lt_pre_group3_cd) THEN
            -- �P���ڂ�lt_pre_group3_cd��NULL�̂��߂����ɓ���Ȃ��iNULL�̔�r��FALSE�j
            -- =============================================
            -- �f�[�^�̒��o�i���i�Q�j(A-8)
            -- =============================================
            select_grp3_total_data(
                        lt_pre_group3_cd     -- ���i�Q�R�[�h�R
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
                ln_margin_rate := CASE WHEN ABS(ln_margin_rate) > cv_max_margin_rate THEN cv_max_rate ELSE ln_margin_rate END;
              END IF;
              --�|��
              IF (lr_sum_rec.price_multi_amount = 0) THEN
                ln_credit_rate := 0;
              ELSE
                ln_credit_rate := ROUND(lr_sum_rec.sales_budget / lr_sum_rec.price_multi_amount * 100, 2);
                ln_credit_rate := CASE WHEN ABS(ln_credit_rate) > cv_max_credit_rate THEN cv_max_rate ELSE ln_credit_rate END;
              END IF;

              -- =============================================
              -- �f�[�^�̓o�^�i���i�Q�j(A-10)
              -- =============================================
              lr_plan_rec.group1_cd              := NULL;                       -- ���i�Q�R�[�h�P
              lr_plan_rec.group1_nm              := NULL;                       -- ���i�Q���̂P
              lr_plan_rec.group3_cd              := NULL;                       -- ���i�Q�R�[�h�R
              lr_plan_rec.group3_nm              := NULL;                       -- ���i�Q���̂R
              lr_plan_rec.item_cd                := lr_sum_rec.group_cd;        -- ���i�R�[�h
              lr_plan_rec.item_nm                := lr_sum_rec.group_nm;        -- ���i����
              lr_plan_rec.con_price              := lr_sum_rec.con_price;       -- �艿
              lr_plan_rec.amount                 := lr_sum_rec.amount;          -- ����
              lr_plan_rec.sales_budget           := lr_sum_rec.sales_budget;    -- ����
              lr_plan_rec.cost                   := lr_sum_rec.cost;            -- ����
              lr_plan_rec.margin                 := lr_sum_rec.margin;          -- �e���v�z
              lr_plan_rec.margin_rate            := ln_margin_rate;             -- �e���v��
              lr_plan_rec.credit_rate            := ln_credit_rate;             -- �|��
              lr_plan_rec.base_margin            := lr_sum_rec.base_margin;     -- �W�������e���v�z

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

            --lt_pre_group3_cd := lt_group3_cd;

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
              ln_margin_rate := CASE WHEN ABS(ln_margin_rate) > cv_max_margin_rate THEN cv_max_rate ELSE ln_margin_rate END;
            END IF;
            --�|��
            IF (lr_sum_rec.price_multi_amount = 0) THEN
              ln_credit_rate := 0;
            ELSE
              ln_credit_rate := ROUND(lr_sum_rec.sales_budget / lr_sum_rec.price_multi_amount * 100, 2);
              ln_credit_rate := CASE WHEN ABS(ln_credit_rate) > cv_max_credit_rate THEN cv_max_rate ELSE ln_credit_rate END;
            END IF;

            -- =============================================
            -- �f�[�^�̓o�^�i���i�敪�j(A-13)
            -- =============================================
            lr_plan_rec.group1_cd              := NULL;                       -- ���i�Q�R�[�h�P
            lr_plan_rec.group1_nm              := NULL;                       -- ���i�Q���̂P
            lr_plan_rec.group3_cd              := NULL;                       -- ���i�Q�R�[�h�R
            lr_plan_rec.group3_nm              := NULL;                       -- ���i�Q���̂R
            lr_plan_rec.item_cd                := lr_sum_rec.group_cd;        -- ���i�R�[�h
            lr_plan_rec.item_nm                := lr_sum_rec.group_nm;        -- ���i����
            lr_plan_rec.con_price              := lr_sum_rec.con_price;       -- �艿
            lr_plan_rec.amount                 := lr_sum_rec.amount;          -- ����
            lr_plan_rec.sales_budget           := lr_sum_rec.sales_budget;    -- ����
            lr_plan_rec.cost                   := lr_sum_rec.cost;            -- ����
            lr_plan_rec.margin                 := lr_sum_rec.margin;          -- �e���v�z
            lr_plan_rec.margin_rate            := ln_margin_rate;             -- �e���v��
            lr_plan_rec.credit_rate            := ln_credit_rate;             -- �|��
            lr_plan_rec.base_margin            := lr_sum_rec.base_margin;     -- �W�������e���v�z

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
                ln_margin_rate := CASE WHEN ABS(ln_margin_rate) > cv_max_margin_rate THEN cv_max_rate ELSE ln_margin_rate END;
              END IF;
              --�|��
              IF (lr_sum_rec.price_multi_amount = 0) THEN
                ln_credit_rate := 0;
              ELSE
                ln_credit_rate := ROUND(lr_sum_rec.sales_budget / lr_sum_rec.price_multi_amount * 100, 2);
                ln_credit_rate := CASE WHEN ABS(ln_credit_rate) > cv_max_credit_rate THEN cv_max_rate ELSE ln_credit_rate END;
              END IF;

              -- =============================================
              -- �f�[�^�̓o�^�i���i���v�j(A-16)
              -- =============================================
              lr_plan_rec.group1_cd              := NULL;                       -- ���i�Q�R�[�h�P
              lr_plan_rec.group1_nm              := NULL;                       -- ���i�Q���̂P
              lr_plan_rec.group3_cd              := NULL;                       -- ���i�Q�R�[�h�R
              lr_plan_rec.group3_nm              := NULL;                       -- ���i�Q���̂R
              lr_plan_rec.item_cd                := NULL;                       -- ���i�R�[�h
              lr_plan_rec.item_nm                := gv_total_com_nm;            -- ���i����
              lr_plan_rec.con_price              := NULL;                       -- �艿
              lr_plan_rec.amount                 := lr_sum_rec.amount;          -- ����
              lr_plan_rec.sales_budget           := lr_sum_rec.sales_budget;    -- ����
              lr_plan_rec.cost                   := lr_sum_rec.cost;            -- ����
              lr_plan_rec.margin                 := lr_sum_rec.margin;          -- �e���v�z
              lr_plan_rec.margin_rate            := ln_margin_rate;             -- �e���v��
              lr_plan_rec.credit_rate            := ln_credit_rate;             -- �|��
              lr_plan_rec.base_margin            := NULL;                       -- �W�������e���v�z

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
            ln_cost := item_plan_rec.bus_price * item_plan_rec.amount;
            --�e���v�z
            ln_margin := item_plan_rec.sales_budget - (item_plan_rec.bus_price * item_plan_rec.amount);
            --�W�������e���v�z
            ln_base_margin := item_plan_rec.sales_budget - (item_plan_rec.base_price * item_plan_rec.amount);
            --�e���v��
            IF (item_plan_rec.sales_budget = 0) THEN
              ln_margin_rate := 0;
            ELSE
              ln_margin_rate := ROUND(ln_margin / item_plan_rec.sales_budget * 100, 2);
              ln_margin_rate := CASE WHEN ABS(ln_margin_rate) > cv_max_margin_rate THEN cv_max_rate ELSE ln_margin_rate END;
            END IF;
            --�|��
            IF ((item_plan_rec.con_price = 0) OR (item_plan_rec.amount = 0)) THEN
              ln_credit_rate := 0;
            ELSE
              ln_credit_rate := ROUND(item_plan_rec.sales_budget / (item_plan_rec.con_price * item_plan_rec.amount) * 100, 2);
              ln_credit_rate := CASE WHEN ABS(ln_credit_rate) > cv_max_credit_rate THEN cv_max_rate ELSE ln_credit_rate END;
            END IF;

            -- =============================================
            -- �f�[�^�̓o�^�i���i�j(A-7)
            -- =============================================
            lr_plan_rec.group1_cd              := item_plan_rec.group1_cd;    -- ���i�Q�R�[�h�P
            lr_plan_rec.group1_nm              := item_plan_rec.group1_nm;    -- ���i�Q���̂P
            lr_plan_rec.group3_cd              := item_plan_rec.group3_cd;    -- ���i�Q�R�[�h�R
            lr_plan_rec.group3_nm              := item_plan_rec.group3_nm;    -- ���i�Q���̂R
            lr_plan_rec.item_cd                := item_plan_rec.item_cd;      -- ���i�R�[�h
            lr_plan_rec.item_nm                := item_plan_rec.item_nm;      -- ���i����
            lr_plan_rec.con_price              := item_plan_rec.con_price;    -- �艿
            lr_plan_rec.amount                 := item_plan_rec.amount;       -- ����
            lr_plan_rec.sales_budget           := item_plan_rec.sales_budget; -- ����
            lr_plan_rec.cost                   := ln_cost;                    -- ����
            lr_plan_rec.margin                 := ln_margin;                  -- �e���v�z
            lr_plan_rec.margin_rate            := ln_margin_rate;             -- �e���v��
            lr_plan_rec.credit_rate            := ln_credit_rate;             -- �|��
            lr_plan_rec.base_margin            := ln_base_margin;             -- �W�������e���v�z

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
        lr_plan_rec.group1_cd              := cv_nebiki;                  -- ���i�Q�R�[�h�P
        lr_plan_rec.group1_nm              := NULL;                       -- ���i�Q���̂P
        lr_plan_rec.group3_cd              := NULL;                       -- ���i�Q�R�[�h�R
        lr_plan_rec.group3_nm              := NULL;                       -- ���i�Q���̂R
        lr_plan_rec.item_cd                := NULL;                       -- ���i�R�[�h
        lr_plan_rec.item_nm                := gv_sales_disc_nm;           -- ���i����
        lr_plan_rec.con_price              := NULL;                       -- �艿
        lr_plan_rec.amount                 := 0;                          -- ����
        lr_plan_rec.sales_budget           := ln_sales_discount;          -- ����l��
        lr_plan_rec.cost                   := 0;                          -- ����
        lr_plan_rec.margin                 := ln_sales_discount;          -- �e���v�z
        lr_plan_rec.margin_rate            := 0;                          -- �e���v��
        lr_plan_rec.credit_rate            := 0;                          -- �|��
--//+UPD START 2010/02/25 E_�{�ғ�_01681 T.Nakano
--        lr_plan_rec.base_margin            := NULL;                       -- �W�������e���v�z
        lr_plan_rec.base_margin            := ln_sales_discount;          -- �W�������e���v�z
--//+UPD END 2010/02/25 E_�{�ғ�_01681 T.Nakano

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

        lr_plan_rec.group1_cd              := cv_nebiki;                  -- ���i�Q�R�[�h�P
        lr_plan_rec.group1_nm              := NULL;                       -- ���i�Q���̂P
        lr_plan_rec.group3_cd              := NULL;                       -- ���i�Q�R�[�h�R
        lr_plan_rec.group3_nm              := NULL;                       -- ���i�Q���̂R
        lr_plan_rec.item_cd                := NULL;                       -- ���i�R�[�h
        lr_plan_rec.item_nm                := gv_receipt_disc_nm;         -- ���i����
        lr_plan_rec.con_price              := NULL;                       -- �艿
        lr_plan_rec.amount                 := 0;                          -- ����
        lr_plan_rec.sales_budget           := ln_receipt_discount;        -- ����l��
        lr_plan_rec.cost                   := 0;                          -- ����
        lr_plan_rec.margin                 := ln_receipt_discount;        -- �e���v�z
        lr_plan_rec.margin_rate            := 0;                          -- �e���v��
        lr_plan_rec.credit_rate            := 0;                          -- �|��
--//+UPD START 2010/02/25 E_�{�ғ�_01681 T.Nakano
--        lr_plan_rec.base_margin            := NULL;                       -- �W�������e���v�z
        lr_plan_rec.base_margin            := ln_receipt_discount;        -- �W�������e���v�z
--//+UPD END 2010/02/25 E_�{�ғ�_01681 T.Nakano

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
        -- �f�[�^�̒��o�i���_���v�^�g��j(A-19)
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
          ln_margin_rate := CASE WHEN ABS(ln_margin_rate) > cv_max_margin_rate THEN cv_max_rate ELSE ln_margin_rate END;
        END IF;
        --�|��
        IF (lr_sum_rec.price_multi_amount = 0) THEN
          ln_credit_rate := 0;
        ELSE
          ln_credit_rate := ROUND(lr_sum_rec.sales_budget / lr_sum_rec.price_multi_amount * 100, 2);
          ln_credit_rate := CASE WHEN ABS(ln_credit_rate) > cv_max_credit_rate THEN cv_max_rate ELSE ln_credit_rate END;
        END IF;

        -- =============================================
        -- �f�[�^�̓o�^�i���_���v�^�g��j(A-21)
        -- =============================================
        lr_plan_rec.group1_cd              := cv_kyoten_kei;              -- ���i�Q�R�[�h�P
        lr_plan_rec.group1_nm              := NULL;                       -- ���i�Q���̂P
        lr_plan_rec.group3_cd              := NULL;                       -- ���i�Q�R�[�h�R
        lr_plan_rec.group3_nm              := NULL;                       -- ���i�Q���̂R
        lr_plan_rec.item_cd                := iv_kyoten_cd;               -- ���i�R�[�h
        lr_plan_rec.item_nm                := iv_kyoten_nm;               -- ���i����
        lr_plan_rec.con_price              := NULL;                       -- �艿
        lr_plan_rec.amount                 := lr_sum_rec.amount;          -- ����
        lr_plan_rec.sales_budget           := lr_sum_rec.sales_budget;    -- ����
        lr_plan_rec.cost                   := lr_sum_rec.cost;            -- ����
        lr_plan_rec.margin                 := lr_sum_rec.margin;          -- �e���v�z
        lr_plan_rec.margin_rate            := ln_margin_rate;             -- �e���v��
        lr_plan_rec.credit_rate            := ln_credit_rate;             -- �|��
        lr_plan_rec.base_margin            := NULL;                       -- �W�������e���v�z

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

        lr_plan_rec.group1_cd              := cv_kyoten_kei;              -- ���i�Q�R�[�h�P
        lr_plan_rec.group1_nm              := NULL;                       -- ���i�Q���̂P
        lr_plan_rec.group3_cd              := NULL;                       -- ���i�Q�R�[�h�R
        lr_plan_rec.group3_nm              := NULL;                       -- ���i�Q���̂R
        lr_plan_rec.item_cd                := NULL;                       -- ���i�R�[�h
        lr_plan_rec.item_nm                := gv_h_base_nm;               -- ���i����
        lr_plan_rec.con_price              := NULL;                       -- �艿
        lr_plan_rec.amount                 := NULL;                       -- ����
        lr_plan_rec.sales_budget           := NULL;                       -- ����
        lr_plan_rec.cost                   := NULL;                       -- ����
        lr_plan_rec.margin                 := lr_sum_rec.base_margin;     -- �e���v�z
        lr_plan_rec.margin_rate            := NULL;                       -- �e���v��
        lr_plan_rec.credit_rate            := NULL;                       -- �|��
        lr_plan_rec.base_margin            := NULL;                       -- �W�������e���v�z

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
    DELETE FROM xxcsm_tmp_item_plan_sales;
--
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
    iv_p_level      IN  VARCHAR2,            -- 3.�K�w
--//+ADD START 2009/02/12   CT006 M.Ohtsuki
    ov_kyoten_nm    OUT NOCOPY VARCHAR2,
--//+ADD END   2009/02/12   CT006 M.Ohtsuki
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
--//+ADD START 2009/02/12   CT006 M.Ohtsuki
          ov_kyoten_nm := kyoten_rec.base_name;
--//+ADD END   2009/02/12   CT006 M.Ohtsuki
          -- ===============================
          -- ���_���[�v������
          -- ===============================
          loop_kyoten(
            iv_p_yyyy,                                         -- �Ώ۔N�x
            iv_p_kyoten_cd,                                    -- ���_�R�[�h�i�p�����[�^�j
            kyoten_rec.base_code,                              -- ���_�R�[�h
            kyoten_rec.base_name,                              -- ���_��
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
--//+ADD START 2009/02/12   CT006 M.Ohtsuki
          ov_kyoten_nm := kyoten_rec.base_name;
--//+ADD END   2009/02/12   CT006 M.Ohtsuki
          -- ===============================
          -- ���_���[�v������
          -- ===============================
          loop_kyoten(
            iv_p_yyyy,                                         -- �Ώ۔N�x
            iv_p_kyoten_cd,                                    -- ���_�R�[�h�i�p�����[�^�j
            kyoten_rec.base_code,                              -- ���_�R�[�h
            kyoten_rec.base_name,                              -- ���_��
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
--//+ADD START 2009/02/12   CT006 M.Ohtsuki
          ov_kyoten_nm := kyoten_rec.base_name;
--//+ADD END   2009/02/12   CT006 M.Ohtsuki
          -- ===============================
          -- ���_���[�v������
          -- ===============================
          loop_kyoten(
            iv_p_yyyy,                                         -- �Ώ۔N�x
            iv_p_kyoten_cd,                                    -- ���_�R�[�h�i�p�����[�^�j
            kyoten_rec.base_code,                              -- ���_�R�[�h
            kyoten_rec.base_name,                              -- ���_��
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
--//+ADD START 2009/02/12   CT006 M.Ohtsuki
          ov_kyoten_nm := kyoten_rec.base_name;
--//+ADD END   2009/02/12   CT006 M.Ohtsuki
          -- ===============================
          -- ���_���[�v������
          -- ===============================
          loop_kyoten(
            iv_p_yyyy,                                         -- �Ώ۔N�x
            iv_p_kyoten_cd,                                    -- ���_�R�[�h�i�p�����[�^�j
            kyoten_rec.base_code,                              -- ���_�R�[�h
            kyoten_rec.base_name,                              -- ���_��
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
--//+ADD START 2009/02/12   CT006 M.Ohtsuki
          ov_kyoten_nm := kyoten_rec.base_name;
--//+ADD END   2009/02/12   CT006 M.Ohtsuki
          -- ===============================
          -- ���_���[�v������
          -- ===============================
          loop_kyoten(
            iv_p_yyyy,                                         -- �Ώ۔N�x
            iv_p_kyoten_cd,                                    -- ���_�R�[�h�i�p�����[�^�j
            kyoten_rec.base_code,                              -- ���_�R�[�h
            kyoten_rec.base_name,                              -- ���_��
            lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
            lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
            lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
          IF (lv_retcode = cv_status_error) THEN
            RAISE global_process_expt;
          END IF;
        END LOOP kyoten_l5_loop;
        CLOSE kyoten_l5_cur;
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
    iv_p_level      IN  VARCHAR2,     -- 3.�K�w
    ov_errbuf       OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode      OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg       OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
--//+ADD START 2009/02/12   CT006 M.Ohtsuki
    lv_nodata_msg          VARCHAR2(100);
    lv_header              VARCHAR2(4000);
    lv_kyoten_nm           VARCHAR2(100);
    cv_all_kyoten          CONSTANT VARCHAR2(20) := '�S���_';
--//+ADD END   2009/02/12   CT006 M.Ohtsuki
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
      ,iv_p_level                           -- �K�w
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
      ,iv_p_level                           -- �K�w
--//+ADD START 2009/02/12   CT006 M.Ohtsuki
      ,lv_kyoten_nm
--//+ADD START 2009/02/12   CT006 M.Ohtsuki
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
--
--//+ADD START 2009/02/12   CT006 M.Ohtsuki
    IF (iv_p_kyoten_cd = 1) THEN
      lv_kyoten_nm := cv_all_kyoten;
    END IF;
    IF (gn_normal_cnt = 0) THEN
      lv_header := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcsm
                     ,iv_name         => cv_lst_head_msg
                     ,iv_token_name1  => cv_tkn_cd_kyoten
                     ,iv_token_value1 => iv_p_kyoten_cd
                     ,iv_token_name2  => cv_tkn_nm_kyoten
                     ,iv_token_value2 => lv_kyoten_nm
                     ,iv_token_name3  => cv_tkn_cd_yyyy
                     ,iv_token_value3 => iv_p_yyyy
                     ,iv_token_name4  => cv_tkn_nichiji
                     ,iv_token_value4 => TO_CHAR(gd_sysdate, 'YYYY/MM/DD HH24:MI:SS')
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
--//+ADD END   2009/02/12   CT006 M.Ohtsuki

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
    errbuf          OUT VARCHAR2,      --   �G���[�E���b�Z�[�W  --# �Œ� #
    retcode         OUT VARCHAR2,      --   ���^�[���E�R�[�h    --# �Œ� #
    iv_p_yyyy       IN  VARCHAR2,      -- 1.�Ώ۔N�x
    iv_p_kyoten_cd  IN  VARCHAR2,      -- 2.���_�R�[�h
    iv_p_level      IN  VARCHAR2       -- 3.�K�w
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
      ,iv_p_level                                  -- �K�w
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
END XXCSM002A09C;
/
