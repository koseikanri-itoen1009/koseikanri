CREATE OR REPLACE PACKAGE BODY XXCSM002A05C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCSM002A05C(body)
 * Description      : ���i�v��P�i�ʈ�����
 * MD.050           : ���i�v��P�i�ʈ����� MD050_CSM_002_A05
 * Version          : 1.6
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                        ��������(A-1)
 *  assign_kyoten_check         ���Ώۃ`�F�b�N(���_�`�F�b�N)(A-2)
 *  assign_deal_check           ���Ώۃ`�F�b�N(����Q�`�F�b�N)(A-4)
 *  item_master_check           �i�ڃ}�X�^�`�F�b�N(A-5)
 *  item_month_data_select      ���i�ʑΏی��f�[�^�擾(A-5)
 *  cost_price_select           ���i�P�ʌv�Z(�c�ƌ����A�艿�A�������擾)(A-6)
 *  sales_before_last_year_cal  ���i�P�ʌv�Z(���i�ʑO�X�N�x������z�N�Ԍv�擾)(A-6)
 *  sales_last_year_cal         ���i�P�ʌv�Z(���i�ʑO�N�x�̔����уf�[�^�擾)(A-6)
 *  new_item_single_year        �V���i�P�N�x���є䗦�Z�o(A-8)
 *  deal_this_month_plan        ����Q�P�ʂł̖{�N�x�Ώی��v��l(A-10)
 *  new_item_no_select          �V���i�v��l�Z�o(�V���i�R�[�h�擾)(A-11)
 *  month_item_sales_sum        �V���i�v��l�Z�o(���ʒP�i������z���v�擾)(A-11)
 *  get_item_lines_lock         ���i�v�斾�׃e�[�u�������f�[�^���b�N(A-12)
 *  item_lines_delete           ���i�v�斾�׃e�[�u�������f�[�^�폜(A-12)
 *  insert_data                 �f�[�^�o�^(A-12)
 *  submain                     ���C�������v���V�[�W��
 *  main                        �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/11/18    1.0   S.Son            �V�K�쐬
 *  2008/02/06    1.1   M.Ohtsuki       �m��QCT_014�n �̔����і����̑Ή�
 *  2009/02/18    1.2   M.Ohtsuki       �m��QCT_033�n �\�Z�����`�F�b�N�s��̑Ή�
 *  2009/03/02    1.3   M.Ohtsuki       �m��QCT_073�n �l�����p�i�ڕs��̑Ή�
 *  2009/05/07    1.4   T.Tsukino       �m��QT1_0792�n�`�F�b�N���X�g�ɏo�͂����V���i�\�Z�̑e���v�z���s��
 *  2009/05/19    1.5   T.Tsukino       �m��QT1_1069�nT1_0792�Ή��s�ǂ̑Ή�
 *  2009/05/27    1.6   A.Sakawa         [��QT1_1173] T1_0069�Ή��s��(0���Z)�Ή�
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
  cn_created_by             CONSTANT NUMBER      := fnd_global.user_id;                 --CREATED_BY
  cd_creation_date          CONSTANT DATE        := SYSDATE;                            --CREATION_DATE
  cn_last_updated_by        CONSTANT NUMBER      := fnd_global.user_id;                 --LAST_UPDATED_BY
  cd_last_update_date       CONSTANT DATE        := SYSDATE;                            --LAST_UPDATE_DATE
  cn_last_update_login      CONSTANT NUMBER      := fnd_global.login_id;                --LAST_UPDATE_LOGIN
  cn_request_id             CONSTANT NUMBER      := fnd_global.conc_request_id;         --REQUEST_ID
  cn_program_application_id CONSTANT NUMBER      := fnd_global.prog_appl_id;            --PROGRAM_APPLICATION_ID
  cn_program_id             CONSTANT NUMBER      := fnd_global.conc_program_id;         --PROGRAM_ID
  cd_program_update_date    CONSTANT DATE        := SYSDATE;                            --PROGRAM_UPDATE_DATE
  cd_process_date           CONSTANT DATE        := xxccp_common_pkg2.get_process_date; --�^�p��
  --
  cv_msg_part               CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont               CONSTANT VARCHAR2(3) := '.';
  --
  cv_xxcsm                  CONSTANT VARCHAR2(100) := 'XXCSM'; 
  --���b�Z�[�W�[�R�[�h
  cv_chk_err_00048          CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00048';       --�R���J�����g���̓p�����[�^���b�Z�[�W(���_�R�[�h)
  cv_chk_err_00049          CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00049';       --�R���J�����g���̓p�����[�^���b�Z�[�W(����Q�R�[�h)
  cv_chk_err_00005          CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00005';       --�v���t�@�C���擾�G���[���b�Z�[�W
  cv_chk_err_00006          CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00006';       --�N�Ԕ̔��v��J�����_�[�����݃G���[���b�Z�[�W
  cv_chk_err_00004          CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00004';       --�\�Z�N�x�`�F�b�N�G���[���b�Z�[�W
  cv_chk_err_00024          CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00024';       --����}�X�^�`�F�b�N�G���[���b�Z�[�W
  cv_chk_err_00050          CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00050';       --�������Ώۃ`�F�b�N�G���[���b�Z�[�W
  cv_chk_err_00051          CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00051';       --����Q�\�Z�����G���[���b�Z�[�W
  cv_chk_err_00054          CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00054';       --�i�ڃJ�e�S���}�X�^�`�F�b�N�G���[���b�Z�[�W
  cv_chk_err_00053          CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00053';       --�i�ڃ}�X�^�`�F�b�N�G���[���b�Z�[�W
  cv_chk_err_00056          CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00056';       --�Ώۃf�[�^����
  cv_chk_err_00055          CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00055';       --�i�ڕύX�����e�[�u���`�F�b�N�G���[
  cv_chk_err_00067          CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00067';       --�V���i�R�[�h���o�G���[
  cv_chk_err_00073          CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00073';       --���i�v�斾�׃e�[�u�����b�N�擾�G���[���b�Z�[�W
  cv_chk_err_10001          CONSTANT VARCHAR2(100) := 'APP-XXCSM1-10001';       --�Ώۃf�[�^0�����b�Z�[�W
  cv_msg_00111              CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00111';       --�z��O�G���[���b�Z�[�W
  cv_chk_err_00110          CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00110';       --�������擾�G���[

  --�g�[�N��
  cv_tkn_cd_prof            CONSTANT VARCHAR2(100) := 'PROF_NAME';               --�J�X�^���E�v���t�@�C���E�I�v�V�����̉p��
  cv_tkn_cd_item            CONSTANT VARCHAR2(100) := 'ITEM';                    --�K�v�ɉ������e�L�X�g����
  cv_tkn_cd_kyoten          CONSTANT VARCHAR2(100) := 'KYOTEN_CD';               --���̓p�����[�^�̋��_�R�[�h
  cv_tkn_cd_deal            CONSTANT VARCHAR2(100) := 'DEAL_CD';                 --�N�Ԍv��f�[�^�̐���Q�R�[�h
  cv_tkn_cd_year            CONSTANT VARCHAR2(100) := 'YYYY';                    --�\�Z�N�x
  cv_tkn_cd_month           CONSTANT VARCHAR2(100) := 'MONTH';                   --�������݂��錎
  cv_tkn_cd_item_cd         CONSTANT VARCHAR2(100) := 'ITEM_CD';                 --�i�ڃR�[�h
  
  --
  cv_language_ja            CONSTANT VARCHAR2(2)   := USERENV('LANG');           --����(���{��)
  cv_flg_y                  CONSTANT VARCHAR2(1)   := 'Y';                       --�t���OY
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
  calendar_check_expt           EXCEPTION;     -- �N�Ԕ̔��v��J�����_�[���݃`�F�b�N
  department_check_expt         EXCEPTION;     -- ����}�X�^�`�F�b�N�G���[
  kyoten_check_expt             EXCEPTION;     -- ���Ώۃ`�F�b�N(���_�`�F�b�N)�G���[
  no_date_expt                  EXCEPTION;     -- �Ώۃf�[�^�Ȃ��G���[
  opm_master_check_expt         EXCEPTION;     -- �i�ڃ}�X�^�`�F�b�N�G���[
  item_categories_check_expt    EXCEPTION;     -- �i�ڃJ�e�S���}�X�^�`�F�b�N�G���[
  cost_price_check_expt         EXCEPTION;     -- �c�ƌ����A�艿���݃`�F�b�N�G���[
  check_lock_expt               EXCEPTION;     -- �̔��v��e�[�u�����b�N�擾�G���[
  deal_check_expt               EXCEPTION;     --���Ώۃ`�F�b�N(����Q�`�F�b�N)
  new_item_select_expt          EXCEPTION;     --�V���i�R�[�h���o�G���[
  deal_skip_expt                EXCEPTION;     --����Q�P�ʂŃX�L�b�v��O
  sale_start_day_expt           EXCEPTION;     --�������擾�G���[
  
  PRAGMA EXCEPTION_INIT(check_lock_expt,-54);   --���b�N�擾�ł��Ȃ��G���[

  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  gv_pkg_name          CONSTANT VARCHAR2(100) := 'XXCSM002A05C';             -- �p�b�P�[�W��
  gv_calendar_profile  CONSTANT VARCHAR2(100) := 'XXCSM1_YEARPLAN_CALENDER'; --�N�Ԕ̔��v��J�����_�[�v���t�@�C����
  gv_deal_profile      CONSTANT VARCHAR2(100) := 'XXCSM1_DEAL_CATEGORY';     --����Q�i�ڃJ�e�S���v���t�@�C����
  gv_bks_profile       CONSTANT VARCHAR2(100) := 'GL_SET_OF_BKS_ID';         --GL��v����ID�v���t�@�C����
--//ADD START 2009/03/02 CT_073 M.Ohtsuki
  gv_disc_group_cd     CONSTANT VARCHAR2(100) := 'XXCSM1_DISCOUNT_GROUP4_CD';--�l�����p�i�ڐ���Q�R�[�h�v���t�@�C����
--//ADD END   2009/03/02 CT_073 M.Ohtsuki

--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
--
  gv_calendar_name     VARCHAR2(100);        --�N�Ԕ̔��v��J�����_�[��
  gv_deal_name         VARCHAR2(50);         --����Q�R�[�h��
  gv_bks_id            NUMBER;               --��v����ID
--//ADD START 2009/03/02 CT_073 M.Ohtsuki
  gv_discount_cd       VARCHAR2(10);         --�l�����p�i�ڐ���Q�R�[�h�v���t�@�C����
--//ADD END   2009/03/02 CT_073 M.Ohtsuki
  gt_active_year       xxcsm_item_plan_headers.plan_year%TYPE;       --�Ώ۔N�x
  gt_start_date        gl_periods.start_date%TYPE;                   --�\�Z�N�x�J�n��

  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    it_kyoten_cd     IN  xxcsm_item_plan_headers.location_cd%TYPE,  -- ���_�R�[�h
    iv_deal_cd       IN  VARCHAR2,                                  --����Q�R�[�h
    ov_errbuf        OUT NOCOPY VARCHAR2,                           -- �G���[�E���b�Z�[�W
    ov_retcode       OUT NOCOPY VARCHAR2,                           -- ���^�[���E�R�[�h
    ov_errmsg        OUT NOCOPY VARCHAR2)                           -- ���[�U�[�E�G���[�E���b�Z�[�W 
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name         CONSTANT VARCHAR2(100) := 'init';            -- �v���O������
    cv_department_name  CONSTANT VARCHAR2(100) := 'XX03_DEPARTMENT'; -- ����}�X�^
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf         VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode        VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg         VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
    ln_carender_cnt   NUMBER;          --�N�Ԕ̔��v��J�����_�[�擾��
    lv_tkn_value      VARCHAR2(4000);  --�g�[�N���l
    ln_kyoten_cnt     NUMBER;          --���_�R�[�h�擾��

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
    ln_retcode        NUMBER;            -- �N�Ԕ̔��v��J�����_�[���^�[���R�[�h
    lv_result         VARCHAR2(100);     -- �N�Ԕ̔��v��J�����_�[�L���N�x��������(0:�L���N�x1�̏ꍇ�A1:�L���N�x�������܂���0�̏ꍇ)
    ln_cnt            NUMBER;            -- �J�E���^
    lv_pram_op_1      VARCHAR2(100);     -- �p�����[�^���b�Z�[�W�o��
    lv_pram_op_2      VARCHAR2(100);     -- �p�����[�^���b�Z�[�W�o�� 
    -- *** ���[�J���E�J�[�\�� ***
--
      /**      �N�x�J�n���擾       **/
    CURSOR startdate_cur1
    IS
      SELECT  gp.start_date
      FROM    gl_sets_of_books gsob
             ,gl_periods gp
      WHERE   gsob.set_of_books_id = gv_bks_id
      AND     gsob.period_set_name = gp.period_set_name
      AND     gp.period_year = gt_active_year
      AND     gp.period_num = 1
      ;
    startdate_cur1_rec startdate_cur1%ROWTYPE;
    
    CURSOR startdate_cur2
    IS
      SELECT  TO_DATE(gt_active_year||TO_CHAR(gp.start_date,'MMDD'),'YYYYMMDD') start_date
      FROM    gl_periods gp
             ,(SELECT  gp.period_year period_year
                      ,gp.period_set_name period_set_name
               FROM    gl_periods gp
                      ,gl_sets_of_books gsob
               WHERE   gsob.set_of_books_id = gv_bks_id
               AND     gsob.period_set_name = gp.period_set_name
               AND     gp.start_date <= cd_process_date
               AND     gp.end_date   >= cd_process_date
              ) year_view
      WHERE   gp.period_num = 1
      AND     gp.period_year = year_view.period_year
      AND     year_view.period_set_name = gp.period_set_name
      ;
      startdate_cur2_rec startdate_cur2%ROWTYPE;
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
--�@���̓p�����[�^�����b�Z�[�W�o��
    --���_�R�[�h
    lv_pram_op_1 := xxccp_common_pkg.get_msg(
                                             iv_application  => cv_xxcsm
                                            ,iv_name         => cv_chk_err_00048
                                            ,iv_token_name1  => cv_tkn_cd_kyoten
                                            ,iv_token_value1 => it_kyoten_cd
                                            );
    FND_FILE.PUT_LINE(FND_FILE.LOG,lv_pram_op_1);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_pram_op_1);
    --����Q�R�[�h
    lv_pram_op_2 := xxccp_common_pkg.get_msg(
                                            iv_application  => cv_xxcsm
                                           ,iv_name         => cv_chk_err_00049
                                           ,iv_token_name1  => cv_tkn_cd_deal
                                           ,iv_token_value1 => iv_deal_cd
                                           );
    FND_FILE.PUT_LINE(FND_FILE.LOG,lv_pram_op_2);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_pram_op_2);
--
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
--
--�A �v���t�@�C���l�擾
    --�N�Ԕ̔��v��J�����_�[���擾
    gv_calendar_name := FND_PROFILE.VALUE(gv_calendar_profile);
    IF gv_calendar_name IS NULL THEN
        lv_tkn_value := gv_calendar_profile;
        lv_errmsg := xxccp_common_pkg.get_msg(
                                              iv_application  => cv_xxcsm
                                             ,iv_name         => cv_chk_err_00005
                                             ,iv_token_name1  => cv_tkn_cd_prof
                                             ,iv_token_value1 => lv_tkn_value
                                             );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END IF;
    --����Q�R�[�h���擾
    gv_deal_name := FND_PROFILE.VALUE(gv_deal_profile);
                          
    IF gv_deal_name IS NULL THEN
        lv_tkn_value := gv_deal_profile;
        lv_errmsg := xxccp_common_pkg.get_msg(
                                              iv_application  => cv_xxcsm
                                             ,iv_name         => cv_chk_err_00005
                                             ,iv_token_name1  => cv_tkn_cd_prof
                                             ,iv_token_value1 => lv_tkn_value
                                             );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END IF;
    --��v����ID�擾
    gv_bks_id := FND_PROFILE.VALUE(gv_bks_profile);
    IF gv_bks_id IS NULL THEN
       lv_tkn_value := gv_bks_profile;
       lv_errmsg := xxccp_common_pkg.get_msg(
                                             iv_application  => cv_xxcsm
                                            ,iv_name         => cv_chk_err_00005
                                            ,iv_token_name1  => cv_tkn_cd_prof
                                            ,iv_token_value1 => lv_tkn_value
                                            );
       lv_errbuf := lv_errmsg;
       RAISE global_api_expt;
    END IF;
--//ADD START 2009/03/02 CT_073 M.Ohtsuki
    --�l�����p�i�ڐ���Q�R�[�h�擾
    gv_discount_cd := FND_PROFILE.VALUE(gv_disc_group_cd);
    IF (gv_discount_cd IS NULL) THEN
       lv_tkn_value := gv_disc_group_cd;
       lv_errmsg := xxccp_common_pkg.get_msg(
                                             iv_application  => cv_xxcsm
                                            ,iv_name         => cv_chk_err_00005
                                            ,iv_token_name1  => cv_tkn_cd_prof
                                            ,iv_token_value1 => lv_tkn_value
                                            );
       lv_errbuf := lv_errmsg;
       RAISE global_api_expt;
    END IF;
--//ADD END   2009/03/02 CT_073 M.Ohtsuki
--�B �N�Ԕ̔��v��J�����_�[���݃`�F�b�N
    BEGIN
      SELECT  COUNT(1)
      INTO    ln_carender_cnt
      FROM    fnd_flex_value_sets  ffv                                      -- �l�Z�b�g�w�b�_
      WHERE   ffv.flex_value_set_name = gv_calendar_name;                   -- �N�Ԕ̔��J�����_�[��
      IF (ln_carender_cnt = 0) THEN                                         -- �J�����_�[���݌�����0���̏ꍇ
        lv_errmsg := xxccp_common_pkg.get_msg(
                                              iv_application  => cv_xxcsm
                                             ,iv_name         => cv_chk_err_00006
                                             ,iv_token_name1  => cv_tkn_cd_item
                                             ,iv_token_value1 => gv_calendar_name
                                             );
        lv_errbuf := lv_errmsg;
        RAISE calendar_check_expt;
      END IF;  
    END;
--�C �N�Ԕ̔��v��J�����_�[�L���N�x�擾
    xxcsm_common_pkg.get_yearplan_calender(
                                           id_comparison_date  => cd_creation_date
                                          ,ov_status           => lv_result
                                          ,on_active_year      => gt_active_year
                                          ,ov_retcode          => ln_retcode
                                          ,ov_errbuf           => lv_errbuf
                                          ,ov_errmsg           => lv_errmsg
                                          );
    IF (ln_retcode <> cv_status_normal) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                                            iv_application  => cv_xxcsm
                                           ,iv_name         => cv_chk_err_00004
                                           ,iv_token_name1  => cv_tkn_cd_item
                                           ,iv_token_value1 => gv_calendar_name
                                           );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--�D ���_�R�[�h���݃`�F�b�N
    BEGIN
      SELECT  COUNT(1)
      INTO    ln_kyoten_cnt
      FROM    fnd_flex_value_sets  ffvs                                    -- �l�Z�b�g�w�b�_
             ,fnd_flex_values  ffv                                         -- �l�Z�b�g����
      WHERE   ffvs.flex_value_set_name =  cv_department_name               -- ����}�X�^
      AND     ffvs.flex_value_set_id = ffv.flex_value_set_id
      AND     ffv.flex_value = it_kyoten_cd;                               -- ���̓p�����[�^�D���_�R�[�h
      IF (ln_kyoten_cnt = 0) THEN                                          -- ���_�R�[�h���݌�����0���̏ꍇ
          lv_errmsg := xxccp_common_pkg.get_msg(
                                                iv_application  => cv_xxcsm
                                               ,iv_name         => cv_chk_err_00024
                                               ,iv_token_name1  => cv_tkn_cd_kyoten
                                               ,iv_token_value1 => it_kyoten_cd
                                               );
          lv_errbuf := lv_errmsg;
          RAISE department_check_expt;
      END IF;  
    END;
--�F �\�Z�쐬�N�x�̔N�x�J�n�����擾
    OPEN startdate_cur1;
      FETCH startdate_cur1 INTO startdate_cur1_rec;
      IF startdate_cur1%NOTFOUND THEN
        OPEN startdate_cur2;
          FETCH startdate_cur2 INTO startdate_cur2_rec;
          gt_start_date := startdate_cur2_rec.start_date;
        CLOSE startdate_cur2;
      ELSE
        gt_start_date := startdate_cur1_rec.start_date;
      END IF;
    CLOSE startdate_cur1;
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    --*** �N�Ԕ̔��v��J�����_�[�����ݗ�O���� ***
    WHEN calendar_check_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    --*** ����}�X�^�`�F�b�N��O���� ***
    WHEN department_check_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END init;
--
  /**********************************************************************************
   * Procedure Name   : assign_kyoten_check
   * Description      : ���Ώۃ`�F�b�N(���_�`�F�b�N)(A-2)
   ***********************************************************************************/
  PROCEDURE assign_kyoten_check(
    it_kyoten_cd     IN  xxcsm_item_plan_headers.location_cd%TYPE,       -- ���_�R�[�h
    ov_errbuf        OUT NOCOPY VARCHAR2,                                --   �G���[�E���b�Z�[�W
    ov_retcode       OUT NOCOPY VARCHAR2,                                --   ���^�[���E�R�[�h
    ov_errmsg        OUT NOCOPY VARCHAR2)                                --   ���[�U�[�E�G���[�E���b�Z�[�W 
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'assign_kyoten_check'; -- �v���O������
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
    month_count  NUMBER;
--
  lt_month    xxcsm_item_plan_loc_bdgt.month_no%TYPE;   --�������݌���

    -- *** ���[�J���E�J�[�\�� ***
--
  CURSOR kyoten_check_cur
  IS
      SELECT  count(xiplb.month_no) month_count                                          --��
      FROM    xxcsm_item_plan_loc_bdgt xiplb                          --���i�v�拒�_�ʗ\�Z�e�[�u��
              ,(SELECT xipl.item_plan_header_id item_plan_header_id    --���i�v��w�b�_ID
                      ,xipl.month_no month_no                         --��
                      ,SUM(xipl.sales_budget) sales_budget            --������z
                FROM   xxcsm_item_plan_headers xiph                    --���i�v��w�b�_�e�[�u��
                      ,xxcsm_item_plan_lines xipl                     --���i�v�斾�׃e�[�u��
                WHERE  xiph.plan_year = gt_active_year                 --�\�Z�N�x��A-1�Ŏ擾�����L���N�x
                AND    xiph.location_cd = it_kyoten_cd                 --���_�R�[�h�����̓p�����[�^���_�R�[�h
                AND    xiph.item_plan_header_id = xipl.item_plan_header_id   
                AND    xipl.year_bdgt_kbn = '0'                        --�N�ԌQ�\�Z�敪(0�F�e��)
                AND    xipl.item_kbn = '0'
                GROUP BY xipl.item_plan_header_id
                        ,xipl.month_no
               ) xipl_view                                             --���i�v�斾�׌��ʗ\�Z�C�����C���r���[
      WHERE   xipl_view.item_plan_header_id = xiplb.item_plan_header_id
      AND     xipl_view.month_no = xiplb.month_no
--//UPD START 2009/02/18 CT_033 M.Ohtsuki
--        AND     (xiplb.sales_budget + xiplb.receipt_discount + xiplb.sales_discount) <> xipl_view.sales_budget
      AND     (xiplb.sales_budget + (xiplb.receipt_discount * -1) + (xiplb.sales_discount * -1)) <> xipl_view.sales_budget
--//UPD END   2009/02/18 CT_033 M.Ohtsuki
      AND     ROWNUM = 1;
      
  kyoten_check_cur_rec kyoten_check_cur%ROWTYPE;
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
  lt_month := NULL;
  month_count := NULL;
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    BEGIN
      OPEN kyoten_check_cur;
      FETCH kyoten_check_cur INTO kyoten_check_cur_rec;
        month_count := kyoten_check_cur_rec.month_count;
      CLOSE kyoten_check_cur;
      IF month_count <> 0 THEN          -- �������݂���ꍇ  
        SELECT  xiplb.month_no                                          --��
        INTO    lt_month
        FROM    xxcsm_item_plan_loc_bdgt xiplb                          --���i�v�拒�_�ʗ\�Z�e�[�u��
              ,(SELECT xipl.item_plan_header_id item_plan_header_id    --���i�v��w�b�_ID
                      ,xipl.month_no month_no                         --��
                      ,SUM(xipl.sales_budget) sales_budget            --������z
                FROM   xxcsm_item_plan_headers xiph                    --���i�v��w�b�_�e�[�u��
                      ,xxcsm_item_plan_lines xipl                     --���i�v�斾�׃e�[�u��
                WHERE  xiph.plan_year = gt_active_year                 --�\�Z�N�x��A-1�Ŏ擾�����L���N�x
                AND    xiph.location_cd = it_kyoten_cd                 --���_�R�[�h�����̓p�����[�^���_�R�[�h
                AND    xiph.item_plan_header_id = xipl.item_plan_header_id   
                AND    xipl.year_bdgt_kbn = '0'                        --�N�ԌQ�\�Z�敪(0�F�e��)
                AND    xipl.item_kbn = '0'
                GROUP BY xipl.item_plan_header_id
                        ,xipl.month_no
               ) xipl_view                                             --���i�v�斾�׌��ʗ\�Z�C�����C���r���[
        WHERE   xipl_view.item_plan_header_id = xiplb.item_plan_header_id
        AND     xipl_view.month_no = xiplb.month_no
--//UPD START 2009/02/18 CT_033 M.Ohtsuki
--        AND     (xiplb.sales_budget + xiplb.receipt_discount + xiplb.sales_discount) <> xipl_view.sales_budget
        AND     (xiplb.sales_budget + (xiplb.receipt_discount * -1) + (xiplb.sales_discount * -1)) <> xipl_view.sales_budget
--//UPD END   2009/02/18 CT_033 M.Ohtsuki
        AND     ROWNUM = 1;
       
        lv_errmsg := xxccp_common_pkg.get_msg(
                                              iv_application  =>  cv_xxcsm
                                             ,iv_name         =>  cv_chk_err_00050
                                             ,iv_token_name1  =>  cv_tkn_cd_year
                                             ,iv_token_value1 =>  gt_active_year
                                             ,iv_token_name2  =>  cv_tkn_cd_month
                                             ,iv_token_value2 =>  lt_month
                                             );
        lv_errbuf := lv_errmsg;
        RAISE kyoten_check_expt;
      END IF;  
    END;
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    -- *** ���Ώۃ`�F�b�N(���_�`�F�b�N)�G���[ ***
    WHEN kyoten_check_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END assign_kyoten_check;
  
  /**********************************************************************************
   * Procedure Name   : assign_deal_check
   * Description      : ���Ώۃ`�F�b�N(����Q�`�F�b�N)(A-4)
   ***********************************************************************************/
  PROCEDURE assign_deal_check(
    it_kyoten_cd        IN  xxcsm_item_plan_headers.location_cd%TYPE  -- ���_�R�[�h
    ,it_item_group_cd   IN  xxcsm_item_plan_lines.item_group_no%TYPE  -- A-3�Ŏ擾��������Q�R�[�h
    ,ov_errbuf          OUT NOCOPY VARCHAR2                           -- �G���[�E���b�Z�[�W
    ,ov_retcode         OUT NOCOPY VARCHAR2                           -- ���^�[���E�R�[�h
    ,ov_errmsg          OUT NOCOPY VARCHAR2)                          -- ���[�U�[�E�G���[�E���b�Z�[�W
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'assign_deal_check'; -- �v���O������
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
    lt_month_deal_sales    xxcsm_item_plan_lines.sales_budget%TYPE;   --������z�N�ԌQ�v
    lt_year_deal_budget    xxcsm_item_plan_lines.sales_budget%TYPE;   --������z�N�ԌQ�\�Z
    -- *** ���[�J���E�J�[�\�� ***
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
    
    -- *** ���Ώۃ`�F�b�N(����Q�`�F�b�N)�N�ԌQ�\�Z�擾 ***
    BEGIN
      SELECT xipl.sales_budget                --������z
      INTO   lt_year_deal_budget
      FROM   xxcsm_item_plan_headers  xiph            --���i�v��w�b�_�e�[�u��
            ,xxcsm_item_plan_lines   xipl             --���i�v�斾�׃e�[�u��
      WHERE  xiph.plan_year = gt_active_year          --�Ώ۔N�x
      AND    xiph.location_cd = it_kyoten_cd          --���_�R�[�h
      AND    xiph.item_plan_header_id = xipl.item_plan_header_id
      AND    xipl.item_group_no = it_item_group_cd    --����Q�R�[�h
      AND    xipl.item_kbn = '0'                      --���i�敪(0�F���i�Q)
      AND    xipl.year_bdgt_kbn = '1'                 --�N�ԌQ�\�Z�敪(1�F�N�ԌQ�\�Z)
      ;
    EXCEPTION
      WHEN no_data_found THEN
      lt_year_deal_budget := NULL;
    END;
    -- *** ���Ώۃ`�F�b�N(����Q�`�F�b�N)���ʏ��i�Q�ʔ�����z�N�ԍ��v�擾 ***
    BEGIN
      SELECT SUM(xipl.sales_budget)                    --������z
      INTO   lt_month_deal_sales
      FROM   xxcsm_item_plan_headers  xiph             --���i�v��w�b�_�e�[�u��
            ,xxcsm_item_plan_lines   xipl              --���i�v�斾�׃e�[�u��
      WHERE  xiph.plan_year = gt_active_year           --�Ώ۔N�x
      AND    xiph.location_cd = it_kyoten_cd           --���_�R�[�h
      AND    xiph.item_plan_header_id = xipl.item_plan_header_id
      AND    xipl.item_group_no = it_item_group_cd     --����Q�R�[�h
      AND    xipl.item_kbn = '0'                       --���i�敪(0�F���i�Q)
      AND    xipl.year_bdgt_kbn = '0'                  --�N�ԌQ�\�Z�敪(0�F�e��)
      ;
    EXCEPTION
      WHEN no_data_found THEN
      lt_month_deal_sales := NULL;
    END;
    --���Ώۃ`�F�b�N(����Q�`�F�b�N)
    IF ((lt_year_deal_budget <> lt_month_deal_sales)
                    OR (lt_year_deal_budget IS NULL) 
                    OR (lt_month_deal_sales IS NULL))THEN
       lv_errmsg := xxccp_common_pkg.get_msg(
                                            iv_application  =>  cv_xxcsm
                                           ,iv_name         =>  cv_chk_err_00051
                                           ,iv_token_name1  =>  cv_tkn_cd_deal
                                           ,iv_token_value1 =>  it_item_group_cd
                                           );
       lv_errbuf := lv_errmsg;
       RAISE deal_check_expt;
    END IF;

    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    -- *** ���Ώۃ`�F�b�N(����Q�`�F�b�N)�G���[ ***
    WHEN deal_check_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END assign_deal_check;
  
  /**********************************************************************************
   * Procedure Name   : item_master_check
   * Description      : �i�ڃ}�X�^�`�F�b�N(A-5)
   ***********************************************************************************/
  PROCEDURE item_master_check(
    it_item_no       IN  ic_item_mst_b.item_no%TYPE,               -- �i�ڃR�[�h
    ov_errbuf        OUT NOCOPY VARCHAR2,                          -- �G���[�E���b�Z�[�W
    ov_retcode       OUT NOCOPY VARCHAR2,                          -- ���^�[���E�R�[�h
    ov_errmsg        OUT NOCOPY VARCHAR2)                          -- ���[�U�[�E�G���[�E���b�Z�[�W
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'item_master_check'; -- �v���O������
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
    lt_item_cd  ic_item_mst_b.item_no%TYPE;  --�i�ڃR�[�h
    lt_item_id  ic_item_mst_b.item_id%TYPE;  --�i��ID
    
    -- *** ���[�J���E�J�[�\�� ***
    -- *** �i�ڃ}�X�^�`�F�b�N ***
    CURSOR item_master_check_cur
    IS
      SELECT DISTINCT
             iimb.item_no                   --OPM�i�ڃR�[�h
             ,gic.item_id                   --�J�e�S���i��ID
      FROM   gmi_item_categories     gic    --�i�ڃJ�e�S�������e�[�u��
             ,ic_item_mst_b          iimb   --OPM�i�ڃ}�X�^
      WHERE  iimb.item_no = it_item_no
      AND    iimb.item_id = gic.item_id(+)
      ;
    item_master_check_cur_rec item_master_check_cur%ROWTYPE;
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
      OPEN item_master_check_cur;
        FETCH item_master_check_cur INTO item_master_check_cur_rec;
        lt_item_cd := item_master_check_cur_rec.item_no;
        lt_item_id := item_master_check_cur_rec.item_id;
        IF item_master_check_cur%NOTFOUND THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                                               iv_application  =>  cv_xxcsm
                                              ,iv_name         =>  cv_chk_err_00053
                                              ,iv_token_name1  =>  cv_tkn_cd_item_cd
                                              ,iv_token_value1 =>  it_item_no
                                              );
          lv_errbuf := lv_errmsg;
          RAISE opm_master_check_expt;
        END IF;
        IF lt_item_id IS NULL THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                                               iv_application  =>  cv_xxcsm
                                              ,iv_name         =>  cv_chk_err_00054
                                              ,iv_token_name1  =>  cv_tkn_cd_item_cd
                                              ,iv_token_value1 =>  it_item_no
                                              );
          lv_errbuf := lv_errmsg;
          RAISE item_categories_check_expt;
        END IF;
      CLOSE item_master_check_cur;
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    -- *** �i�ڃ}�X�^�`�F�b�N�G���[ ***
    WHEN opm_master_check_expt THEN
      IF item_master_check_cur%ISOPEN THEN
        CLOSE item_master_check_cur;
      END IF;
      ov_errmsg := lv_errmsg;                                                   --# �C�� #
      ov_errbuf := SUBSTRB(gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;  --�x��
    -- *** �i�ڃJ�e�S���}�X�^�`�F�b�N�G���[ ***
    WHEN item_categories_check_expt THEN
      IF item_master_check_cur%ISOPEN THEN
        CLOSE item_master_check_cur;
      END IF;
      ov_errmsg := lv_errmsg;                                                   --# �C�� #
      ov_errbuf := SUBSTRB(gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;  --�x��
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END item_master_check;
  
  /**********************************************************************************
   * Procedure Name   : item_month_data_select
   * Description      : ���i�ʑΏی��f�[�^�擾(A-6)
   ***********************************************************************************/
  PROCEDURE item_month_data_select(
    it_kyoten_cd     IN  xxcsm_item_plan_result.location_cd%TYPE,    --���_�R�[�h
    it_item_group_no IN  xxcsm_item_plan_result.item_group_no%TYPE,  --����Q�R�[�h
    it_item_no       IN  xxcsm_item_plan_result.item_no%TYPE,        --���i�R�[�h
    it_month_no      IN  xxcsm_item_plan_result.month_no%TYPE,       --��
    on_sales_budget  OUT NUMBER,                                     --����
    on_amount        OUT NUMBER,                                     --����
    ov_errbuf        OUT NOCOPY VARCHAR2,                                   -- �G���[�E���b�Z�[�W
    ov_retcode       OUT NOCOPY VARCHAR2,                                   -- ���^�[���E�R�[�h
    ov_errmsg        OUT NOCOPY VARCHAR2)                                   -- ���[�U�[�E�G���[�E���b�Z�[�W
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'item_month_data_select'; -- �v���O������
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
    -- *** �Ώی��f�[�^�擾 ***
    CURSOR item_month_data_select_cur
    IS
      SELECT xipr.sales_budget                          --������z
            ,xipr.amount                                --����
      FROM   xxcsm_item_plan_result xipr                --���i�v��p�̔�����
      WHERE  xipr.location_cd = it_kyoten_cd            --���_�R�[�h
      AND    xipr.subject_year = (gt_active_year - 1)   --�\�Z�N�x�̑O�N�x
      AND    xipr.item_group_no LIKE REPLACE (it_item_group_no,'*','_')
      AND    xipr.item_no = it_item_no                  --���i�R�[�h
      AND    xipr.month_no = it_month_no                --��
      ;
    item_month_data_select_cur_rec item_month_data_select_cur%ROWTYPE;
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
      OPEN item_month_data_select_cur;
          FETCH item_month_data_select_cur INTO item_month_data_select_cur_rec;
          on_sales_budget := item_month_data_select_cur_rec.sales_budget;
          on_amount       := item_month_data_select_cur_rec.amount;
      CLOSE item_month_data_select_cur;

    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END item_month_data_select;
  
  /**********************************************************************************
   * Procedure Name   : cost_price_select
   * Description      : ���i�P�ʌv�Z(�c�ƌ����A�艿�A�������A�P�ʎ擾)(A-6)
   ***********************************************************************************/
  PROCEDURE cost_price_select(
    it_item_group_cd  IN  xxcsm_item_plan_result.item_group_no%TYPE,         -- ����Q�R�[�h
    it_item_no        IN  xxcsm_item_plan_result.item_no%TYPE,               -- ���i�R�[�h
    on_discrete_cost  OUT NUMBER,                                            -- �c�ƌ���
    on_fixed_price    OUT NUMBER,                                            -- �艿
    ov_sale_start_day OUT VARCHAR2,                                          -- ������
    on_unit_flg       OUT NUMBER,                                            -- �P�ʃt���O
    ov_errbuf         OUT NOCOPY VARCHAR2,                                   -- �G���[�E���b�Z�[�W
    ov_retcode        OUT NOCOPY VARCHAR2,                                   -- ���^�[���E�R�[�h
    ov_errmsg         OUT NOCOPY VARCHAR2)                                   -- ���[�U�[�E�G���[�E���b�Z�[�W
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'cost_price_select'; -- �v���O������
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
    cv_unit_kg     CONSTANT VARCHAR2(50) := 'XXCSM1_UNIT_KG_G';   --�P��KG
    -- *** ���[�J���ϐ� ***
--

    -- *** ���[�J���E�J�[�\�� ***
    -- *** OPM�i�ڃ}�X�^���o ***
    CURSOR opm_item_select_cur
    IS
      SELECT iimb.attribute8    discrete_cost    --�c�ƌ���(�V)
            ,iimb.attribute5   fixed_price       --�艿(�V)
      FROM   ic_item_mst_b  iimb                 --OPM�i�ڃ}�X�^
      WHERE  iimb.item_no = it_item_no           --�i�ڃR�[�h
      ;
    opm_item_select_cur_rec opm_item_select_cur%ROWTYPE;
    -- *** �i�ڕύX�����c�ƌ������o ***
    CURSOR item_hst_cost_cur
    IS
      SELECT xsibh.discrete_cost                         --�c�ƌ���
      FROM   xxcmm_system_items_b_hst   xsibh            --�i�ڕύX�����e�[�u��
            ,(SELECT MAX(apply_date) apply_date          --�K�p��
              FROM   xxcmm_system_items_b_hst            --�i�ڕύX����
              WHERE  item_code = it_item_no              --�i�ڃR�[�h
              AND    apply_date <= gt_start_date         --�N�x�J�n���ȑO
              AND    discrete_cost IS NOT NULL           --�c�ƌ��� IS NOT NULL
             ) xsibh_view
      WHERE  xsibh.apply_date = xsibh_view.apply_date    --�K�p��
      AND    xsibh.item_code = it_item_no                --�i�ڃR�[�h
      AND    xsibh.discrete_cost IS NOT NULL
      ;
    item_hst_cost_cur_rec item_hst_cost_cur%ROWTYPE;
    
    -- *** �i�ڕύX����艿���o ***
    CURSOR item_hst_price_cur
    IS
      SELECT xsibh.fixed_price                           --�艿
      FROM   xxcmm_system_items_b_hst   xsibh            --�i�ڕύX�����e�[�u��
            ,(SELECT MAX(apply_date) apply_date          --�K�p��
              FROM   xxcmm_system_items_b_hst            --�i�ڕύX����
              WHERE  item_code = it_item_no              --�i�ڃR�[�h
              AND    apply_date <= gt_start_date         --�N�x�J�n���ȑO
              AND    fixed_price IS NOT NULL             --�艿 IS NOT NULL
                ) xsibh_view
      WHERE  xsibh.apply_date = xsibh_view.apply_date    --�K�p��
      AND    xsibh.item_code = it_item_no                --�i�ڃR�[�h
      AND    xsibh.fixed_price IS NOT NULL 
        ;
    item_hst_price_cur_rec item_hst_price_cur%ROWTYPE;
    --*** ������ ***
    CURSOR sale_start_day_cur
    IS
    SELECT iimb.attribute13  start_day               --������
      FROM   ic_item_mst_b    iimb          --OPM�i�ڃ}�X�^
      WHERE  iimb.item_no = it_item_no;     --�i��ID
    sale_start_day_cur_rec sale_start_day_cur%ROWTYPE;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################

--##################  �o�͕ϐ��������� START   ###################
--
    on_discrete_cost         := NULL;    -- �c�ƌ���
    on_fixed_price           := NULL;    -- �艿
    ov_sale_start_day        := NULL;    -- ������
    on_unit_flg              := 0;       -- �P�ʂ�kg�A���ȊO
--
--##################  �o�͕ϐ��������� END     ###################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    --*** �^�p�����N�x�J�n���̎��AOPM�i�ڃ}�X�^����c�ƌ����A�艿�擾 ***
    IF cd_process_date > gt_start_date THEN
      OPEN opm_item_select_cur;
        FETCH opm_item_select_cur INTO opm_item_select_cur_rec;
        on_discrete_cost := opm_item_select_cur_rec.discrete_cost; --�c�ƌ���
        on_fixed_price := opm_item_select_cur_rec.fixed_price;     --�艿
        IF (on_discrete_cost IS NULL) OR (on_fixed_price IS NULL) THEN
          RAISE cost_price_check_expt;
        END IF;
      CLOSE opm_item_select_cur;
    ELSE 
    --*** �^�p�����N�x�J�n���̎��A�i�ڕύX��������A�c�ƌ����A�艿���擾 ***
      --*** �i�ڕύX�����c�ƌ����擾 ***
      OPEN item_hst_cost_cur;
        FETCH item_hst_cost_cur INTO item_hst_cost_cur_rec;
        on_discrete_cost := item_hst_cost_cur_rec.discrete_cost;   --�c�ƌ���
        IF item_hst_cost_cur%NOTFOUND THEN
          RAISE cost_price_check_expt;
        END IF;
      CLOSE item_hst_cost_cur;
      --*** �i�ڕύX����艿�擾 ***
      OPEN item_hst_price_cur;
        FETCH item_hst_price_cur INTO item_hst_price_cur_rec;
        on_fixed_price := item_hst_price_cur_rec.fixed_price;     --�艿
        IF item_hst_price_cur%NOTFOUND THEN
          RAISE cost_price_check_expt;
        END IF;
      CLOSE item_hst_price_cur;
    END IF;
    ov_sale_start_day := NULL;
    -- *** �������擾 ***
    OPEN sale_start_day_cur;
      FETCH sale_start_day_cur INTO sale_start_day_cur_rec;
        ov_sale_start_day := sale_start_day_cur_rec.start_day;
      IF ov_sale_start_day IS NULL THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                                               iv_application  =>  cv_xxcsm
                                              ,iv_name         =>  cv_chk_err_00110
                                              ,iv_token_name1  =>  cv_tkn_cd_deal
                                              ,iv_token_value1 =>  it_item_group_cd
                                              ,iv_token_name2  =>  cv_tkn_cd_item_cd
                                              ,iv_token_value2 =>  it_item_no
                                              );
        lv_errbuf := lv_errmsg;
        RAISE sale_start_day_expt;
      END IF;
   CLOSE sale_start_day_cur;

    -- *** �P�ʃt���O���o ***
    BEGIN
      SELECT COUNT(msib.unit_of_issue)                    --�P��
      INTO   on_unit_flg                                  --�P�ʃt���O
      FROM    mtl_system_items_b  msib             --Disc�i�ڃ}�X�^
             ,fnd_lookup_values   flv              --�N�C�b�N�R�[�h
      WHERE   msib.segment1 = it_item_no           --�i�ڃR�[�h
      AND     flv.lookup_type = cv_unit_kg         --
      AND     NVL(flv.start_date_active,cd_process_date) <= cd_process_date          --�J�n��
      AND     NVL(flv.end_date_active,cd_process_date) >= cd_process_date            --�I����
      AND     flv.enabled_flag = cv_flg_y         --�L��
      AND     flv.meaning = msib.unit_of_issue
      AND     ROWNUM = 1;
    END;

    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    -- *** �i�ڕύX�����`�F�b�N�G���[ ***
    WHEN cost_price_check_expt THEN
      IF opm_item_select_cur%ISOPEN THEN
        CLOSE opm_item_select_cur;
      END IF;
      IF item_hst_cost_cur%ISOPEN THEN
        CLOSE item_hst_cost_cur;
      END IF;
      IF item_hst_price_cur%ISOPEN THEN
        CLOSE item_hst_price_cur;
      END IF;
      lv_errmsg := xxccp_common_pkg.get_msg(
                                               iv_application  =>  cv_xxcsm
                                              ,iv_name         =>  cv_chk_err_00055
                                              ,iv_token_name1  =>  cv_tkn_cd_deal
                                              ,iv_token_value1 =>  it_item_group_cd
                                              ,iv_token_name2  =>  cv_tkn_cd_item_cd
                                              ,iv_token_value2 =>  it_item_no
                                              );
      lv_errbuf := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;
    WHEN sale_start_day_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END cost_price_select;
  
  /**********************************************************************************
   * Procedure Name   : sales_before_last_year_cal
   * Description      : ���i�P�ʌv�Z(���i�ʑO�X�N�x������z�N�Ԍv�擾)(A-6)
   ***********************************************************************************/
  PROCEDURE sales_before_last_year_cal(
    it_kyoten_cd              IN     xxcsm_item_plan_headers.location_cd%TYPE,  -- ���_�R�[�h
    it_item_group_cd          IN     xxcsm_item_plan_lines.item_group_no%TYPE,  -- A-3�Ŏ擾��������Q�R�[�h
    it_item_no                IN     xxcsm_item_plan_lines.item_no%TYPE,        -- ���i�R�[�h
    id_sale_start_date        IN     DATE,                                      -- ������
    on_before_last_year_sale  OUT    NUMBER,                                    -- ���i�ʑO�X�N�x������z�N�Ԍv
    ov_errbuf                 OUT    NOCOPY VARCHAR2,                           -- �G���[�E���b�Z�[�W
    ov_retcode                OUT    NOCOPY VARCHAR2,                           -- ���^�[���E�R�[�h
    ov_errmsg                 OUT    NOCOPY VARCHAR2)                           -- ���[�U�[�E�G���[�E���b�Z�[�W
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'sales_before_last_year_cal'; -- �v���O������
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
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################

--##################  �o�͕ϐ��������� START   ###################
--
    on_before_last_year_sale := NULL;    -- ���i�ʑO�X�N�x������z���v
--
--##################  �o�͕ϐ��������� END     ###################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
    BEGIN
      SELECT  SUM(xipr.sales_budget)                        --������z
      INTO    on_before_last_year_sale                      --�O�X�N�x������z�N�Ԍv
      FROM    xxcsm_item_plan_result   xipr                 --���i�v��p�̔����уe�[�u��
      WHERE   xipr.location_cd = it_kyoten_cd               --���_�R�[�h
      AND     xipr.item_group_no LIKE REPLACE(it_item_group_cd,'*','_')         --���i�Q�R�[�h
      AND     xipr.item_no = it_item_no                     --���i�R�[�h
      AND     xipr.subject_year = (gt_active_year - 2)      --�O�X�N�x
      AND     xipr.year_month >= TO_NUMBER(TO_CHAR(ADD_MONTHS(id_sale_start_date,3),'YYYYMM')) --������3������̔N��
      ;
    END;

    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END sales_before_last_year_cal;
  
  /**********************************************************************************
   * Procedure Name   : sales_last_year_cal
   * Description      : ���i�P�ʌv�Z(���i�ʑO�N�x�̔����уf�[�^�擾)(A-6)
   ***********************************************************************************/
  PROCEDURE sales_last_year_cal(
    it_kyoten_cd              IN      xxcsm_item_plan_headers.location_cd%TYPE, -- ���_�R�[�h
    it_item_group_cd          IN      xxcsm_item_plan_lines.item_group_no%TYPE, -- A-3�Ŏ擾��������Q�R�[�h
    it_item_no                IN      xxcsm_item_plan_lines.item_no%TYPE,       -- ���i�R�[�h
    id_start_date             IN      DATE,                                     -- �v�Z�J�n��
    on_last_year_sale         OUT     NUMBER,                                   -- ���i�ʑO�N�x������z�N�Ԍv
    on_last_year_amount       OUT     NUMBER,                                   -- ���i�ʑO�N�x���ʔN�Ԍv
    ov_errbuf                 OUT     NOCOPY VARCHAR2,                          -- �G���[�E���b�Z�[�W
    ov_retcode                OUT     NOCOPY VARCHAR2,                          -- ���^�[���E�R�[�h
    ov_errmsg                 OUT     NOCOPY VARCHAR2)                          -- ���[�U�[�E�G���[�E���b�Z�[�W
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'sales_last_year_cal'; -- �v���O������
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
  CURSOR last_year_data_cur
  IS
    SELECT  SUM(xipr.sales_budget)  sales_budget         --������z
           ,SUM(xipr.amount)  amount                     --����
    FROM    xxcsm_item_plan_result   xipr                --���i�v��p�̔����уe�[�u��
    WHERE   xipr.location_cd = it_kyoten_cd              --���_�R�[�h
    AND     xipr.item_group_no LIKE REPLACE(it_item_group_cd,'*','_')        --���i�Q�R�[�h
    AND     xipr.item_no = it_item_no                    --���i�R�[�h
    AND     xipr.subject_year = (gt_active_year - 1)     --�O�N�x
    AND     xipr.year_month >= TO_NUMBER(TO_CHAR(id_start_date,'YYYYMM')) --�v�Z�J�n�̔N��
    ;
  last_year_data_cur_rec last_year_data_cur%ROWTYPE;
  
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################

--##################  �o�͕ϐ��������� START   ###################
--
    on_last_year_sale        := NULL;    -- ���i�ʑO�N�x������z���v
    on_last_year_amount      := NULL;    -- ���i�ʑO�N�x���ʍ��v
--
--##################  �o�͕ϐ��������� END     ###################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
    OPEN last_year_data_cur;
      FETCH last_year_data_cur INTO last_year_data_cur_rec;
      on_last_year_sale   := last_year_data_cur_rec.sales_budget;
      on_last_year_amount := last_year_data_cur_rec.amount;
    CLOSE last_year_data_cur;

    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END sales_last_year_cal;
  
  /**********************************************************************************
   * Procedure Name   : new_item_single_year
   * Description      : �V���i�P�N�x���є䗦�Z�o(A-8)
   ***********************************************************************************/
  PROCEDURE new_item_single_year(
    it_kyoten_cd           IN  xxcsm_item_plan_headers.location_cd%TYPE,  -- ���_�R�[�h
    it_item_group_cd       IN  xxcsm_item_plan_lines.item_group_no%TYPE,  -- A-3�Ŏ擾��������Q�R�[�h
    on_single_result_rate  OUT  NUMBER,                                   -- �V���i�P�N�x���є䗦
    on_this_year_deal_plan OUT  NUMBER,                                   -- ���i�Q�ʖ{�N�x�N�Ԍv��
    ov_errbuf              OUT NOCOPY VARCHAR2,                           -- �G���[�E���b�Z�[�W
    ov_retcode             OUT NOCOPY VARCHAR2,                           -- ���^�[���E�R�[�h
    ov_errmsg              OUT NOCOPY VARCHAR2)                           -- ���[�U�[�E�G���[�E���b�Z�[�W 
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'new_item_single_year'; -- �v���O������
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
    ln_last_year_deal_result            NUMBER;    --���i�Q�ʑO�N�x�������
    -- *** ���[�J���E�J�[�\�� ***
    
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
-- *** �{�N�x�N�Ԍv��l�擾 ***
    BEGIN
      SELECT SUM(xipl.sales_budget)                       --������z
      INTO   on_this_year_deal_plan                       --�{�N�x�N�Ԍv��l
      FROM   xxcsm_item_plan_headers  xiph                --���i�v��w�b�_�e�[�u��
            ,xxcsm_item_plan_lines   xipl                 --���i�v�斾�׃e�[�u��
      WHERE  xiph.location_cd = it_kyoten_cd              --���_�R�[�h
      AND    xiph.plan_year = gt_active_year              --�L���N�x
      AND    xiph.item_plan_header_id = xipl.item_plan_header_id
      AND    xipl.item_group_no = it_item_group_cd        --���i�Q�R�[�h
      AND    xipl.item_kbn = '0'                          --���i�敪(0�F���i�Q)
      AND    xipl.year_bdgt_kbn = '0';                    --�N�ԌQ�\�Z�敪(0�F�N�ԌQ�\�Z�擾�ł��Ȃ�)
    END;
    -- *** �O�N�x������ю擾 ***
    BEGIN
      SELECT  SUM(sales_budget)                      --������z
      INTO    ln_last_year_deal_result               --�O�N�x�̔�����
      FROM    xxcsm_item_plan_result                 --���i�v��p�̔�����
      WHERE   subject_year = (gt_active_year - 1)    --�Ώ۔N�x���O�N�x
      AND     location_cd = it_kyoten_cd             --���_�R�[�h
      AND     item_group_no  LIKE REPLACE(it_item_group_cd,'*','_') ;      --���i�Q�R�[�h
    END;
    -- *** �V���i�P�N�x���є䗦�Z�o ***
    IF (ln_last_year_deal_result = 0) THEN
      on_single_result_rate := 1;
    ELSE
      on_single_result_rate := on_this_year_deal_plan / ln_last_year_deal_result;
    END IF;

    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END new_item_single_year;
  
  /**********************************************************************************
   * Procedure Name   : deal_this_month_plan
   * Description      : ����Q�P�ʂł̖{�N�x�Ώی��v��l(A-10)
   ***********************************************************************************/
  PROCEDURE deal_this_month_plan(
    it_kyoten_cd           IN  xxcsm_item_plan_headers.location_cd%TYPE,  -- ���_�R�[�h
    it_item_group_cd       IN  xxcsm_item_plan_lines.item_group_no%TYPE,  -- A-3�Ŏ擾��������Q�R�[�h
    it_year_month          IN  xxcsm_item_plan_lines.year_month%TYPE,     -- �N��
    on_this_month_sale     OUT NUMBER,                                    -- ����Q�P�ʂł̖{�N�x�Ώی��v��l
    ov_errbuf              OUT NOCOPY VARCHAR2,                           -- �G���[�E���b�Z�[�W
    ov_retcode             OUT NOCOPY VARCHAR2,                           -- ���^�[���E�R�[�h
    ov_errmsg              OUT NOCOPY VARCHAR2)                           -- ���[�U�[�E�G���[�E���b�Z�[�W
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'deal_this_month_plan'; -- �v���O������
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
    
    -- *** ���[�J���E�J�[�\�� ***
    
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
  BEGIN
    SELECT  xipl.sales_budget                           --������z
    INTO    on_this_month_sale                          --����Q�P�ʂł̖{�N�x�Ώی��v��l
    FROM    xxcsm_item_plan_headers   xiph              --���i�v��w�b�_�e�[�u��
           ,xxcsm_item_plan_lines    xipl               --���i�v�斾�׃e�[�u��
    WHERE   xiph.plan_year = gt_active_year             --�L���N�x
    AND     xiph.location_cd = it_kyoten_cd             --���_�R�[�h
    AND     xiph.item_plan_header_id = xipl.item_plan_header_id
    AND     xipl.item_group_no = it_item_group_cd       --���i�Q�R�[�h
    AND     xipl.year_month = it_year_month             --A-5�Ŏ擾�����N��
    AND     xipl.item_kbn = '0'                         --���i�敪(0�F���i�Q)
    AND     xipl.year_bdgt_kbn = '0'                    --�N�ԌQ�\�Z�敪(0�F�N�ԌQ�\�Z�擾�ł��Ȃ�)
    ;
  END;

    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END deal_this_month_plan;
  
  /**********************************************************************************
   * Procedure Name   : new_item_no_select
   * Description      : �V���i�v��l�Z�o(�V���i�R�[�h�擾)(A-11)
   ***********************************************************************************/
  PROCEDURE new_item_no_select(
    it_item_group_cd     IN  xxcsm_item_plan_lines.item_group_no%TYPE,         -- A-3�Ŏ擾��������Q�R�[�h
    ov_new_item_no       OUT NOCOPY VARCHAR2,                                  -- �V���i�R�[�h
--//ADD START 2009/05/19 T1_1069 T.Tsukino
    ov_new_item_cost     OUT NOCOPY VARCHAR2,                                  -- �c�ƌ���
    ov_new_item_price    OUT NOCOPY VARCHAR2,                                  -- �艿
--//ADD END 2009/05/19 T1_1069 T.Tsukino
    ov_errbuf            OUT NOCOPY VARCHAR2,                                  -- �G���[�E���b�Z�[�W
    ov_retcode           OUT NOCOPY VARCHAR2,                                  -- ���^�[���E�R�[�h
    ov_errmsg            OUT NOCOPY VARCHAR2)                                  -- ���[�U�[�E�G���[�E���b�Z�[�W
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'new_item_no_select'; -- �v���O������
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
  ln_new_item_count     NUMBER;                                      --�V���i�R�[�h���ݐ�
    -- *** ���[�J���E�J�[�\�� ***
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
  BEGIN
    SELECT   COUNT(DISTINCT xicv.attribute3)                          --�V���i�R�[�h���ݐ�
    INTO     ln_new_item_count                                        --�V���i�R�[�h���ݐ�
    FROM     xxcsm_item_category_v        xicv                        --�i�ڃJ�e�S���r���[
    WHERE    xicv.segment1 LIKE REPLACE(it_item_group_cd,'*','_')     --���i�Q�R�[�h
    AND      xicv.attribute3 IS NOT NULL                              --�V���i�R�[�h
    ;
    IF ln_new_item_count <> 1 THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                                            iv_application  =>  cv_xxcsm
                                           ,iv_name         =>  cv_chk_err_00067
                                           ,iv_token_name1  =>  cv_tkn_cd_deal
                                           ,iv_token_value1 =>  it_item_group_cd
                                           );
      lv_errbuf := lv_errmsg;
      RAISE new_item_select_expt;
    ELSE
      SELECT   DISTINCT xicv.attribute3                                 --�V���i�R�[�h
      INTO     ov_new_item_no                                           --�V���i�R�[�h
      FROM     xxcsm_item_category_v        xicv                        --�i�ڃJ�e�S���r���[
      WHERE    xicv.segment1 LIKE REPLACE(it_item_group_cd,'*','_')     --���i�Q�R�[�h
      AND      xicv.attribute3 IS NOT NULL                              --�V���i�R�[�h
      ;
--//ADD START 2009/05/19 T1_1069 T.Tsukino
      SELECT xxcg3v.now_business_cost   -- �c�ƌ���
            ,xxcg3v.now_unit_price      -- �艿
      INTO  ov_new_item_cost            -- �c�ƌ���
           ,ov_new_item_price           -- �艿
      FROM  xxcsm_commodity_group3_v  xxcg3v
      WHERE xxcg3v.item_cd = ov_new_item_no
      AND   xxcg3v.group3_cd = it_item_group_cd
      ;
--//ADD END 2009/05/19 T1_1069 T.Tsukino
    END IF;
  END;
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    --
    WHEN new_item_select_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END new_item_no_select;
  
  /**********************************************************************************
   * Procedure Name   : month_item_sales_sum
   * Description      : �V���i�v��l�Z�o(���ʒP�i������z���v�擾)(A-11)
   ***********************************************************************************/
  PROCEDURE month_item_sales_sum(
    it_header_id         IN  xxcsm_item_plan_lines.item_plan_header_id%TYPE,  -- �w�b�_ID
    it_item_group_cd     IN  xxcsm_item_plan_lines.item_group_no%TYPE,        -- A-3�Ŏ擾��������Q�R�[�h
    it_year_month        IN  xxcsm_item_plan_lines.year_month%TYPE,           -- �N��
    on_sales_sum         OUT NUMBER,                                          -- ���ʒP�i�ʔ�����z���v
    on_gross_sum         OUT NUMBER,                                          -- ���ʒP�i�ʑe���v�z���v
    ov_errbuf            OUT NOCOPY VARCHAR2,                                 -- �G���[�E���b�Z�[�W
    ov_retcode           OUT NOCOPY VARCHAR2,                                 -- ���^�[���E�R�[�h
    ov_errmsg            OUT NOCOPY VARCHAR2)                                 -- ���[�U�[�E�G���[�E���b�Z�[�W
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'month_item_sales_sum'; -- �v���O������
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
  BEGIN
    SELECT   SUM(xipl.sales_budget)                    --������z���v
            ,SUM(xipl.amount_gross_margin)             --�e���v�z���v
    INTO     on_sales_sum                              --���ʒP�i������z���v
            ,on_gross_sum                              --���ʒP�i�e���v�z���v
    FROM     xxcsm_item_plan_lines   xipl              --���i�v�斾�׃e�[�u��
    WHERE    xipl.item_plan_header_id = it_header_id    --�w�b�_ID
    AND      xipl.item_group_no = it_item_group_cd  --���i�Q�R�[�h
    AND      xipl.year_month = it_year_month        --�N��
    AND      xipl.item_kbn = '1'                    --���i�敪(1�F���i�P�i)
    ;
  END;

    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END month_item_sales_sum;
  
  /***********************************************************************************
   * Procedure Name   : get_item_lines_lock
   * Description      : ���i�v�斾�׃e�[�u�������f�[�^���b�N(A-12)
   ***********************************************************************************/
  PROCEDURE get_item_lines_lock(
    it_kyoten_cd      IN   xxcsm_item_plan_headers.location_cd%TYPE,            -- ���_�R�[�h
    it_header_id      IN   xxcsm_item_plan_headers.item_plan_header_id%TYPE,    -- ���i�v��w�b�_ID
    it_item_group_cd  IN   xxcsm_item_plan_lines.item_group_no%TYPE,            -- A-3�Ŏ擾��������Q�R�[�h
    ov_errbuf         OUT  NOCOPY VARCHAR2,                                     -- �G���[�E���b�Z�[�W
    ov_retcode        OUT  NOCOPY VARCHAR2,                                     -- ���^�[���E�R�[�h
    ov_errmsg         OUT  NOCOPY VARCHAR2)                                     -- ���[�U�[�E�G���[�E���b�Z�[�W
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_item_lines_lock'; -- �v���O������
--
--##############################  �Œ胍�[�J���ϐ��錾�� START   #################################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################################  �Œ蕔 END   ############################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
--
    -- *** ���[�J���E�J�[�\�� ***
    CURSOR get_item_lines_cur IS
      SELECT xipl.item_plan_header_id                   --���i�v��w�b�_ID
            ,xipl.item_group_no                         --���i�Q�R�[�h
      FROM   xxcsm_item_plan_lines xipl                 --���i�v�斾�׃e�[�u��
      WHERE  xipl.item_plan_header_id = it_header_id    --�w�b�_ID
      AND    xipl.item_group_no = it_item_group_cd      --���i�Q�R�[�h
      FOR UPDATE NOWAIT;
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--################################  �Œ�X�e�[�^�X�������� START   ################################
--
    ov_retcode := cv_status_normal;
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    -- ���b�N�擾����
    OPEN get_item_lines_cur;
    CLOSE get_item_lines_cur;
--
  EXCEPTION
    -- *** ���b�N�G���[ ***
    WHEN check_lock_expt THEN
      IF get_item_lines_cur%ISOPEN THEN
        CLOSE get_item_lines_cur;
      END IF;
      lv_errmsg := xxccp_common_pkg.get_msg(
                                    iv_application  =>  cv_xxcsm
                                   ,iv_name         =>  cv_chk_err_00073
                                   ,iv_token_name1  =>  cv_tkn_cd_kyoten
                                   ,iv_token_value1 =>  it_kyoten_cd
                                   ,iv_token_name2  =>  cv_tkn_cd_deal
                                   ,iv_token_value2 =>  it_item_group_cd
                                    );
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;
      
--
--#################################  �Œ��O������ START   ######################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ############################################
--
  END get_item_lines_lock;
  
  /***********************************************************************************
   * Procedure Name   : delete_item_lines
   * Description      : ���i�v�斾�׃e�[�u�������f�[�^�폜(A-12)
   ***********************************************************************************/
  PROCEDURE delete_item_lines(
    it_header_id      IN   xxcsm_item_plan_headers.item_plan_header_id%TYPE,    -- ���i�v��w�b�_ID
    it_item_group_cd  IN   xxcsm_item_plan_lines.item_group_no%TYPE,            -- A-3�Ŏ擾��������Q�R�[�h
    ov_errbuf         OUT  NOCOPY VARCHAR2,                                     -- �G���[�E���b�Z�[�W
    ov_retcode        OUT  NOCOPY VARCHAR2,                                     -- ���^�[���E�R�[�h
    ov_errmsg         OUT  NOCOPY VARCHAR2)                                     -- ���[�U�[�E�G���[�E���b�Z�[�W
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'delete_item_lines'; -- �v���O������
--
--##############################  �Œ胍�[�J���ϐ��錾�� START   #################################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################################  �Œ蕔 END   ############################################
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
--################################  �Œ�X�e�[�^�X�������� START   ################################
--
    ov_retcode := cv_status_normal;
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    -- �폜����
    DELETE xxcsm_item_plan_lines xipl                 -- ���i�v�斾�׃e�[�u��
    WHERE  xipl.item_plan_header_id = it_header_id    --�w�b�_ID
    AND    xipl.item_group_no = it_item_group_cd      --���i�Q�R�[�h
    AND    xipl.item_kbn <> '0';                       --���i�敪(1�F���i�R�[�h)
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ######################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ############################################
--
  END delete_item_lines;
  
  /**********************************************************************************
   * Procedure Name   : insert_data
   * Description      : �f�[�^�o�^(A-12)
   ***********************************************************************************/
  PROCEDURE insert_data(
    ir_plan_rec        IN  xxcsm_item_plan_lines%ROWTYPE       -- �Ώۃ��R�[�h
    ,ov_errbuf          OUT NOCOPY VARCHAR2                    -- �G���[�E���b�Z�[�W
    ,ov_retcode         OUT NOCOPY VARCHAR2                    -- ���^�[���E�R�[�h
    ,ov_errmsg          OUT NOCOPY VARCHAR2)                   -- ���[�U�[�E�G���[�E���b�Z�[�W
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
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    -- �o�^����
      INSERT INTO xxcsm_item_plan_lines xxipl(     -- ���i�v�斾�׃e�[�u��
         xxipl.item_plan_header_id                  -- ���i�v��w�b�_ID
        ,xxipl.item_plan_lines_id                  -- ���i�v�斾��ID
        ,xxipl.year_month                          -- �N��
        ,xxipl.month_no                            -- ��
        ,xxipl.year_bdgt_kbn                       -- �N�ԌQ�\�Z�敪
        ,xxipl.item_kbn                            -- ���i�敪
        ,xxipl.item_no                             -- ���i�R�[�h
        ,xxipl.item_group_no                       -- ���i�Q�R�[�h
        ,xxipl.amount                              -- ����
        ,xxipl.sales_budget                        -- ������z
        ,xxipl.amount_gross_margin                 -- �e���v(�V)
        ,xxipl.credit_rate                         -- �|��
        ,xxipl.margin_rate                         -- �e���v��(�V)
        ,xxipl.created_by                          -- �쐬��
        ,xxipl.creation_date                       -- �쐬��
        ,xxipl.last_updated_by                     -- �ŏI�X�V��
        ,xxipl.last_update_date                    -- �ŏI�X�V��
        ,xxipl.last_update_login                   -- �ŏI�X�V���O�C��
        ,xxipl.request_id                          -- �v��ID
        ,xxipl.program_application_id              -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
        ,xxipl.program_id                          -- �R���J�����g�E�v���O����ID
        ,xxipl.program_update_date)                -- �v���O�����X�V��
      VALUES(
         ir_plan_rec.item_plan_header_id
        ,xxcsm_item_plan_lines_s01.NEXTVAL
        ,ir_plan_rec.year_month
        ,ir_plan_rec.month_no
        ,ir_plan_rec.year_bdgt_kbn
        ,ir_plan_rec.item_kbn
        ,ir_plan_rec.item_no
        ,ir_plan_rec.item_group_no
        ,NVL(ir_plan_rec.amount,0)
        ,NVL(ir_plan_rec.sales_budget,0)
        ,NVL(ir_plan_rec.amount_gross_margin,0)
        ,NVL(ir_plan_rec.credit_rate,0)
        ,NVL(ir_plan_rec.margin_rate,0)
        ,ir_plan_rec.created_by
        ,ir_plan_rec.creation_date
        ,ir_plan_rec.last_updated_by
        ,ir_plan_rec.last_update_date
        ,ir_plan_rec.last_update_login
        ,ir_plan_rec.request_id
        ,ir_plan_rec.program_application_id
        ,ir_plan_rec.program_id
        ,ir_plan_rec.program_update_date);
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
      ov_errbuf  := SUBSTRB(gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END insert_data;
  
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    iv_kyoten_cd     IN  VARCHAR2,            --   ���_�R�[�h
    iv_deal_cd       IN  VARCHAR2,            --   ����Q�R�[�h
    ov_errbuf        OUT NOCOPY VARCHAR2,     --   �G���[�E���b�Z�[�W
    ov_retcode       OUT NOCOPY VARCHAR2,     --   ���^�[���E�R�[�h
    ov_errmsg        OUT NOCOPY VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W 
  IS
--
--#####################  �Œ胍�[�J���萔�ϐ��錾�� START   ####################
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name       CONSTANT VARCHAR2(100) := 'submain';          -- �v���O������
    cv_item_status    CONSTANT VARCHAR2(100) := 'XXCMM_ITM_STATUS'; -- �i�ڃX�e�[�^�X
    
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf                     VARCHAR2(5000);                                 --�G���[�E���b�Z�[�W
    lv_retcode                    VARCHAR2(1);                                    --���^�[���E�R�[�h
    lv_errmsg                     VARCHAR2(5000);                                 --���[�U�[�E�G���[�E���b�Z�[�W
    lt_item_group_no              xxcsm_item_plan_lines.item_group_no%TYPE;       --���i�Q�R�[�h
    lt_year_month                 xxcsm_item_plan_result.year_month%TYPE;         --�N��
    lt_month_no                   xxcsm_item_plan_result.month_no%TYPE;           --��
    lt_item_no                    xxcsm_item_plan_result.item_no%TYPE;            --���i�R�[�h
    ln_amount                     NUMBER;                                         --����
    ln_sales_budget               NUMBER;                                         --������z
    lt_pre_item_group_no          xxcsm_item_plan_lines.item_group_no%TYPE;       --�ۑ��p���i�Q�R�[�h
    ln_discrete_cost              NUMBER;                                         --�c�ƌ���
    ln_fixed_price                NUMBER;                                         --�艿
    ln_before_last_year_sale      NUMBER;                                         --���i�ʑO�X�N�x������z���v
    ln_last_year_sale             NUMBER;                                         --���i�ʑO�N�x������z���v
    ln_last_year_amount           NUMBER;                                         --���i�ʑO�N�x���ʍ��v
    lv_sale_start_day             VARCHAR2(100);                                  --������
    ln_months                     NUMBER;                                         --����������N�x�J�n���܂ł̌���
    ln_entity_result_rate         NUMBER;                                         --�������i�̎��є䗦
    ln_new_two_result_rate        NUMBER;                                         --�V���i2���N�x���є䗦
    ln_single_result_rate         NUMBER;                                         --�V���i�P�N�x���є䗦
    ln_month_average_sale         NUMBER;                                         --���㌎���ώ���
    ln_month_average_amount       NUMBER;                                         --���ʌ����ώ���
    ln_this_year_deal_plan        NUMBER;                                         --����Q�P�ʂł̖{�N�x�v��l
    ln_this_month_sale            NUMBER;                                         --����Q�P�ʂł̖{�N�x�Ώی��v��l
    ln_deal_composition_rate      NUMBER;                                         --�V���i�P�N�x����Q�\����
    ld_start_day                  DATE;                                           --�v�Z�J�n��
    ln_plan_sales_budget          NUMBER;                                         --�v��f�[�^������z
    ln_plan_gross_budget          NUMBER;                                         --�v��f�[�^�e���v�z
    ln_plan_amount                NUMBER;                                         --�v��f�[�^����
    ln_plan_amount_gross_margin   NUMBER;                                         --�v��f�[�^�e���v
    ln_plan_credit_rate           NUMBER;                                         --�v��f�[�^�|��
    ln_margin_rate                NUMBER;                                         --�v��e���v��
    ln_new_sales_budget           NUMBER;                                         --�V���i������z
    ln_new_gross_budget           NUMBER;                                         --�V���i�e���v�z
    lv_new_item_no                VARCHAR2(10);                                   --�V���i�R�[�h
    lt_new_year_month             xxcsm_item_plan_result.year_month%TYPE;         --�V���i�N��
    lt_new_month_no               xxcsm_item_plan_result.month_no%TYPE;           --�V���i��
    lt_item_plan_header_id        xxcsm_item_plan_lines.item_plan_header_id%TYPE; --���i�v��w�b�_ID
    lr_plan_rec                   xxcsm_item_plan_lines%ROWTYPE;                  --�e�[�u���^�ϐ�
    lr_new_plan_rec               xxcsm_item_plan_lines%ROWTYPE;                  --�V���i�o�^�p�e�[�u���^�ϐ�
    ln_month_sales_sum            NUMBER;                                         --���ʒP�i������z���v
    ln_month_gross_sum            NUMBER;                                         --���ʒP�i�e���v�z���v
    ln_new_plan_sales             NUMBER;                                         --�V���i�v��l
    ln_new_plan_gross             NUMBER;                                         --�V���i�v��l
    ln_unit_flg                   NUMBER;                                         --�P��
    lt_kyoten_cd                  xxcsm_item_plan_headers.location_cd%TYPE;       --���_�R�[�h    
    ld_sale_start_day             DATE;                                           --������(���t)
    lv_no_data_msg                VARCHAR2(100);                                  --���уf�[�^�������b�Z�[�W
--//ADD START 2009/05/07 T1_0792 T.Tsukino
    ln_new_plan_amount            NUMBER;                                         --�V���i����
    ln_new_plan_credit            NUMBER;                                         --�V���i�|��
--//ADD END 2009/05/07 T1_0792 T.Tsukino
--//ADD START 2009/05/19 T1_1069 T.Tsukino
    lv_new_item_cost              VARCHAR2(240);                                  --�c�ƌ���
    lv_new_item_price             VARCHAR2(240);                                  --�艿
--//ADD END 2009/05/19 T1_1069 T.Tsukino
              
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    -- *** A-3 ���i�Q�R�[�h���o ***
    --���i�v�斾�׃e�[�u���ɓo�^����Ă��鏤�i�Q�R�[�h��3��(AAA*)�𒊏o����B
    CURSOR deal_select_cur
    IS
      SELECT DISTINCT xipl.item_group_no          --���i�Q�R�[�h
                     ,xipl.item_plan_header_id    --�w�b�_ID
      FROM   xxcsm_item_plan_headers  xiph        --���i�v��w�b�_�e�[�u��
            ,xxcsm_item_plan_lines   xipl         --���i�v�斾�׃e�[�u��
      WHERE  xiph.plan_year = gt_active_year      --�\�Z�N�x��A-1�Ŏ擾�����L���N�x
      AND    xiph.location_cd = iv_kyoten_cd      --���_�R�[�h���p�����[�^�D���_�R�[�h
      AND    xiph.item_plan_header_id = xipl.item_plan_header_id
      AND    xipl.item_group_no LIKE DECODE(iv_deal_cd,'1',xipl.item_group_no,REPLACE(iv_deal_cd,'*','_'))
      AND    xipl.item_kbn = '0'                  --���i�敪(0�F���i�Q)
                                 --���̓p�����[�^�D����Q�R�[�h�͑S����Q�̏ꍇ�A�S����Q�R�[�h�𒊏o
      ORDER BY xipl.item_plan_header_id           --�w�b�_ID
              ,xipl.item_group_no                 --���i�Q�R�[�h
      ;
    deal_select_cur_rec deal_select_cur%ROWTYPE;
    
    -- *** A-5 ���я��i�R�[�h�擾 ***
    CURSOR  sale_result_cur(
                           it_item_group_no  xxcsm_item_plan_lines.item_group_no%TYPE
                           )
    IS
      SELECT   xsib.item_code                                                     --���i�R�[�h
      FROM     xxcmm_system_items_b    xsib                                     --Disc�i�ڃA�h�I��
              ,fnd_lookup_values       flv                                      --�N�C�b�N�R�[�h�l
      WHERE    NVL(xsib.item_status_apply_date,cd_process_date) <= cd_process_date             --�^�p��
      AND      flv.lookup_code = xsib.item_status                               --�i�ڃX�e�[�^�X�R�t��
      AND      flv.lookup_type = cv_item_status                                 --�i�ڃX�e�[�^�X
      AND      flv.language = cv_language_ja                                    --����(���{��)
      AND      flv.attribute3 = cv_flg_y                                        --���i�v��敪(Y�F�L��)
      AND      flv.enabled_flag = cv_flg_y                                      --�L���t���O(Y�F�L��)
      AND      NVL(flv.start_date_active,cd_process_date) <= cd_process_date    --�J�n��
      AND      NVL(flv.end_date_active,cd_process_date) >= cd_process_date      --�I����
      AND      EXISTS ( SELECT xipr.item_no
                        FROM   xxcsm_item_plan_result  xipr                     --���i�v��p�̔����уe�[�u��
                        WHERE  xipr.location_cd    = iv_kyoten_cd                               --���_�R�[�h
                        AND    xipr.item_group_no LIKE REPLACE(it_item_group_no,'*','_')        --����Q�R�[�h
                        AND    xipr.subject_year = (gt_active_year - 1)                         --�O�N�x
                        AND    xipr.item_no    = xsib.item_code                                 --�i�ڃR�[�h�R�t��
--//ADD START 2009/03/02 CT_073 M.Ohtsuki
                        AND    xipr.item_group_no <> gv_discount_cd                             --�l�����p�i��(DAAE)�ȊO
--//ADD END   2009/03/02 CT_073 M.Ohtsuki
                      )
      ORDER BY xsib.item_code
      ;
    sale_result_cur_rec sale_result_cur%ROWTYPE;
    -- *** A-5 ���N���擾 ***
    CURSOR  year_month_select_cur(
                                 it_item_group_no xxcsm_item_plan_lines.item_group_no%TYPE
                                 )
    IS
      SELECT   xipl.year_month                                       --�N��
               ,xipl.month_no                                        --��
      FROM     xxcsm_item_plan_headers  xiph                         --���i�v��w�b�_�e�[�u��
              ,xxcsm_item_plan_lines   xipl                          --���i�v�斾�׃e�[�u��
      WHERE    xiph.plan_year = gt_active_year                       --�L���N�x
      AND      xiph.location_cd = iv_kyoten_cd                       --���_�R�[�h
      AND      xiph.item_plan_header_id = xipl.item_plan_header_id   --�w�b�_ID(�R�t��)
      AND      xipl.item_group_no = it_item_group_no                 --���i�Q�R�[�h
      AND      xipl.item_kbn = '0'
      AND      xipl.year_bdgt_kbn       = '0'  
      ORDER BY xipl.year_month
      ;
    year_month_select_cur_rec year_month_select_cur%ROWTYPE;
    
    -- *** A-11 ���ʋ��_�ʏ��i�Q�ʂ̌v��f�[�^���o ***
    CURSOR  kyoten_month_deal_plan_cur(
                                      it_item_group_no xxcsm_item_plan_lines.item_group_no%TYPE
                                      )
    IS
      SELECT   xipl.year_month                                       --�N��
               ,xipl.month_no                                        --��
               ,xipl.sales_budget                                    --������z
               ,xipl.amount_gross_margin                             --�e���v
      FROM     xxcsm_item_plan_headers  xiph                         --���i�v��w�b�_�e�[�u��
               ,xxcsm_item_plan_lines   xipl                         --���i�v�斾�׃e�[�u��
      WHERE    xiph.plan_year           = gt_active_year             --�\�Z�N�x
      AND      xiph.location_cd         = iv_kyoten_cd               --���_�R�[�h
      AND      xiph.item_plan_header_id = xipl.item_plan_header_id   --���i�v��w�b�_ID(�R�t��)
      AND      xipl.item_group_no       = it_item_group_no           --����Q�R�[�h
      AND      xipl.item_kbn            = '0'                        --���i�敪(0�F���i�Q)
      AND      xipl.year_bdgt_kbn       = '0'                        --�N�ԌQ�\�Z�敪(0�F�N�ԌQ�\�Z�擾�ł��Ȃ�)
      ORDER BY xipl.year_month
      ;
    kyoten_month_deal_plan_cur_rec kyoten_month_deal_plan_cur%ROWTYPE;
--
--###########################  �Œ蕔 END   ####################################
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
    gn_warn_cnt   := 0;
    
    -- ���[�J���ϐ�������
    lt_pre_item_group_no := NULL;
    lt_item_no           := NULL;
    lt_kyoten_cd         := iv_kyoten_cd;
--
    --*********************************************
    --***      MD.050�̃t���[�}��\��           ***
    --***      ����Ə������̌Ăяo�����s��     ***
    --*********************************************
--
    -- ===============================
    -- ��������(A-1)
    -- ===============================
    init(
         lt_kyoten_cd       -- ���_�R�[�h
         ,iv_deal_cd         --����Q�R�[�h
         ,lv_errbuf         -- �G���[�E���b�Z�[�W
         ,lv_retcode        -- ���^�[���E�R�[�h
         ,lv_errmsg );
    -- ��O����
    IF (lv_retcode <> cv_status_normal) THEN
      --(�G���[����)
      gn_error_cnt := gn_error_cnt +1;
      RAISE global_process_expt;
    END IF;
    
    -- ===================================
    -- ���Ώۃ`�F�b�N(���_�`�F�b�N)(A-2)
    -- ===================================
    assign_kyoten_check(
                        lt_kyoten_cd     -- ���_�R�[�h
                       ,lv_errbuf        -- �G���[�E���b�Z�[�W
                       ,lv_retcode       -- ���^�[���E�R�[�h
                       ,lv_errmsg );     -- ���[�U�[�E�G���[�E���b�Z�[�W
    -- ��O����
    IF (lv_retcode <> cv_status_normal) THEN
      --(�G���[����)
      gn_error_cnt := gn_error_cnt +1;
      RAISE global_process_expt;
    END IF;
--
    -- ===================================
    -- �����Ώې���Q�̒��o(A-3)
    -- ===================================
    BEGIN
      OPEN deal_select_cur;
      <<deal_check_loop>>
      LOOP
        FETCH deal_select_cur INTO deal_select_cur_rec;
        EXIT WHEN deal_select_cur%NOTFOUND;
        lt_item_group_no := deal_select_cur_rec.item_group_no;                  --���i�Q�R�[�h
        lt_item_plan_header_id := deal_select_cur_rec.item_plan_header_id;      --�w�b�_ID
        -- ===================================
        -- ���Ώۃ`�F�b�N(����Q�R�[�h)(A-4)
        -- ===================================
        assign_deal_check(
                          lt_kyoten_cd        -- ���̓p�����[�^�D���_�R�[�h
                         ,lt_item_group_no    -- A-3�Œ��o�������i�Q�R�[�h
                         ,lv_errbuf           -- �G���[�E���b�Z�[�W
                         ,lv_retcode          -- ���^�[���E�R�[�h
                         ,lv_errmsg);         -- ���[�U�[�E�G���[�E���b�Z�[�W
        -- ��O����
        IF (lv_retcode <> cv_status_normal) THEN
          --(�G���[����)
          gn_error_cnt := gn_error_cnt +1;
          RAISE global_process_expt;
        END IF;
      END LOOP deal_check_loop;
      CLOSE deal_select_cur;
    END;
--
    --����Q�R�[�h�P�ʂŔ���\�Z���������݂��Ȃ��ƁA������񒊏o��������Q��LOOP���܂��B
    OPEN deal_select_cur;
      <<deal_loop>>
      LOOP
      BEGIN
        FETCH deal_select_cur INTO deal_select_cur_rec;
        EXIT WHEN deal_select_cur%NOTFOUND;
        lt_item_no           := NULL;
        SAVEPOINT item_group_point;
        lt_item_group_no := deal_select_cur_rec.item_group_no;                  --���i�Q�R�[�h
        lt_item_plan_header_id := deal_select_cur_rec.item_plan_header_id;      --�w�b�_ID
        gn_target_cnt := gn_target_cnt + 1;                                     --��������
        -- ===================================
        -- �̔��v��e�[�u�����b�N�擾(A-12)
        -- ===================================
        get_item_lines_lock(
                            lt_kyoten_cd               -- ���_�R�[�h
                           ,lt_item_plan_header_id     -- ���i�v��w�b�_ID
                           ,lt_item_group_no           -- A-3�Ŏ擾��������Q�R�[�h
                           ,lv_errbuf                  -- �G���[�E���b�Z�[�W
                           ,lv_retcode                 -- ���^�[���E�R�[�h
                           ,lv_errmsg);                -- ���[�U�[�E�G���[�E���b�Z�[�W
        -- ��O����
        IF (lv_retcode = cv_status_error) THEN
          --(�G���[����)
          gn_error_cnt := gn_error_cnt +1;
          RAISE global_process_expt;
        ELSIF (lv_retcode = cv_status_warn) THEN
          --�x������
          gn_error_cnt := gn_error_cnt + 1;
          RAISE deal_skip_expt;
        END IF;
        
        -- ===================================
        -- �̔��v��e�[�u���폜����(A-12)
        -- ===================================
        delete_item_lines(
                          lt_item_plan_header_id     -- ���i�v��w�b�_ID
                         ,lt_item_group_no           -- A-3�Ŏ擾��������Q�R�[�h
                         ,lv_errbuf                  -- �G���[�E���b�Z�[�W
                         ,lv_retcode                 -- ���^�[���E�R�[�h
                         ,lv_errmsg);                -- ���[�U�[�E�G���[�E���b�Z�[�W
                      
        --��O����
        IF (lv_retcode = cv_status_error) THEN
          --(�G���[����)
          gn_error_cnt := gn_error_cnt +1;
          RAISE global_process_expt;
        ELSIF (lv_retcode = cv_status_warn) THEN
          --�x������
          gn_error_cnt := gn_error_cnt + 1;
          RAISE deal_skip_expt;
        END IF;
--
        -- *** ���i�Q�R�[�h�ς��ƁA���L�̃f�[�^���擾 ***
        IF (lt_pre_item_group_no IS NULL) OR (lt_pre_item_group_no <> lt_item_group_no) THEN
          -- ===================================
          -- �V���i�P�N�x���є䗦�Z�o(A-8)
          -- ===================================
          new_item_single_year(
                             lt_kyoten_cd            -- ���̓p�����[�^�D���_�R�[�h
                             ,lt_item_group_no       -- A-3�Œ��o�������i�Q�R�[�h
                             ,ln_single_result_rate  -- �V���i�P�N�x���є䗦
                             ,ln_this_year_deal_plan -- �{�N�x�N�Ԍv��l
                             ,lv_errbuf              -- �G���[�E���b�Z�[�W
                             ,lv_retcode             -- ���^�[���E�R�[�h
                             ,lv_errmsg);            -- ���[�U�[�E�G���[�E���b�Z�[�W
          -- ��O����
          IF (lv_retcode = cv_status_error) THEN
            --(�G���[����)
            gn_error_cnt := gn_error_cnt +1;
            RAISE global_process_expt;
          ELSIF (lv_retcode = cv_status_warn) THEN
            --�x������
            gn_error_cnt := gn_error_cnt + 1;
            RAISE deal_skip_expt;
          END IF;
        END IF;
--
        -- ===================================
        -- �W�v���я��i�R�[�h�擾(A-5)
        -- ===================================
        OPEN sale_result_cur(lt_item_group_no);
          <<item_loop>>
          LOOP
            FETCH sale_result_cur INTO sale_result_cur_rec;
            EXIT WHEN sale_result_cur%NOTFOUND;
            lt_item_no      :=  sale_result_cur_rec.item_code;
--
            -- =============================================
            -- �i�ڃ}�X�^�`�F�b�N(A-5)
            -- =============================================
            item_master_check(
                              lt_item_no            -- �i�ڃR�[�h
                             ,lv_errbuf             -- �G���[�E���b�Z�[�W
                             ,lv_retcode            -- ���^�[���E�R�[�h
                             ,lv_errmsg );          -- ���[�U�[�E�G���[�E���b�Z�[�W
            -- ��O����
            IF (lv_retcode = cv_status_error) THEN
              --(�G���[����)
              gn_error_cnt := gn_error_cnt +1;
              RAISE global_process_expt;
            ELSIF (lv_retcode = cv_status_warn) THEN
              --�x������
              gn_error_cnt := gn_error_cnt + 1;
              RAISE deal_skip_expt;
            END IF;
            
            -- ===================================================
            -- ���i�P�ʌv�Z(�c�ƌ����A�艿�A�������A�P�ʎ擾)(A-6)
            -- ===================================================
            cost_price_select(
                            lt_item_group_no    --���i�Q�R�[�h
                           ,lt_item_no          --���i�R�[�h
                           ,ln_discrete_cost    -- �c�ƌ���
                           ,ln_fixed_price      -- �艿
                           ,lv_sale_start_day   -- ������
                           ,ln_unit_flg         -- �P�ʃt���O(0�FKG�AG�ȊO�C1�FKG�AG)
                           ,lv_errbuf           -- �G���[�E���b�Z�[�W
                           ,lv_retcode          -- ���^�[���E�R�[�h
                           ,lv_errmsg );        -- ���[�U�[�E�G���[�E���b�Z�[�W

            -- ��O����
            IF (lv_retcode = cv_status_error) THEN
              --(�G���[����)
              gn_error_cnt := gn_error_cnt +1;
              RAISE global_process_expt;
            ELSIF (lv_retcode = cv_status_warn) THEN
              --�x������
              gn_error_cnt := gn_error_cnt + 1;
              RAISE deal_skip_expt;
            END IF;
--
            -- *** ����������A�N�x�J�n���܂ł̌����Z�o ***
            ld_sale_start_day:=TO_DATE(lv_sale_start_day,'YYYY-MM-DD');        
            
            ln_months := MONTHS_BETWEEN(TO_DATE(TO_CHAR(gt_start_date,'YYYYMM')||'01','YYYY-MM-DD'),
                                        TO_DATE(TO_CHAR(ld_sale_start_day,'YYYYMM')||'01','YYYY-MM-DD'));
            
            -- *** �������i���͐V���i2���N�̏ꍇ�A�O�X�N�x������z�N�Ԍv�擾 ***
            IF (ln_months > 15)  THEN
              -- =====================================================
              -- ���i�P�ʌv�Z(���i�ʑO�X�N�x������z�N�Ԍv�擾)(A-6)
              -- =====================================================
              sales_before_last_year_cal(
                                       lt_kyoten_cd               -- ���_�R�[�h
                                       ,lt_item_group_no          -- ���i�Q�R�[�h
                                       ,lt_item_no                -- ���i�R�[�h
                                       ,ld_sale_start_day         -- ������
                                       ,ln_before_last_year_sale  -- �O�X�N�x������z�N�Ԍv
                                       ,lv_errbuf                 -- �G���[�E���b�Z�[�W
                                       ,lv_retcode                -- ���^�[���E�R�[�h
                                       ,lv_errmsg);               -- ���[�U�[�E�G���[�E���b�Z�[�W
              -- ��O����
              IF (lv_retcode = cv_status_error) THEN
                --(�G���[����)
                gn_error_cnt := gn_error_cnt +1;
                RAISE global_process_expt;
              ELSIF (lv_retcode = cv_status_warn) THEN
                --�x������
                gn_error_cnt := gn_error_cnt + 1;
                RAISE deal_skip_expt;
              END IF;
            END IF;
--
            -- *** �������ɂ���āA�O�N�x������z�N�Ԍv�擾 ***
            IF (ln_months > 3)  THEN
              --�V���i2���N�x���т̏ꍇ
              IF (ln_months > 15) AND (ln_months < 27) THEN
                ld_start_day := ADD_MONTHS(ld_sale_start_day,15);
              --�������i���͐V���i�P�N�x�̏ꍇ
              ELSE 
                ld_start_day := ADD_MONTHS(ld_sale_start_day,3);
              END IF;
              -- =====================================================
              -- ���i�P�ʌv�Z(���i�ʑO�N�x������z�N�Ԍv�擾)(A-6)
              -- =====================================================
              sales_last_year_cal(
                                lt_kyoten_cd        -- ���_�R�[�h
                               ,lt_item_group_no    -- ���i�Q�R�[�h
                               ,lt_item_no          -- ���i�R�[�h
                               ,ld_start_day        -- �v�Z�J�n��
                               ,ln_last_year_sale   -- �O�N�x������z�N�Ԍv
                               ,ln_last_year_amount -- �O�N�x���ʔN�Ԍv
                               ,lv_errbuf           -- �G���[�E���b�Z�[�W
                               ,lv_retcode          -- ���^�[���E�R�[�h
                               ,lv_errmsg);         -- ���[�U�[�E�G���[�E���b�Z�[�W
              -- ��O����
              IF (lv_retcode = cv_status_error) THEN
                --(�G���[����)
                gn_error_cnt := gn_error_cnt +1;
                RAISE global_process_expt;
              ELSIF (lv_retcode = cv_status_warn) THEN
                --�x������
                gn_error_cnt := gn_error_cnt + 1;
                RAISE deal_skip_expt;
              END IF;
            END IF;
--
            -- =============================================
            -- ���N���擾(A-5)
            -- =============================================
            OPEN year_month_select_cur(lt_item_group_no);
              <<month_loop>>
              LOOP
                FETCH year_month_select_cur INTO year_month_select_cur_rec;
                EXIT WHEN year_month_select_cur%NOTFOUND;
                lt_year_month          := year_month_select_cur_rec.year_month;
                lt_month_no            := year_month_select_cur_rec.month_no;
                -- =====================================================
                -- ���v�Z(A-10)
                -- =====================================================
                IF (ln_months >= 27) THEN
                  -- =====================================================
                  -- �Ώی��f�[�^�擾(A-6)
                  -- =====================================================
                  item_month_data_select(
                                        lt_kyoten_cd       --���_�R�[�h
                                       ,lt_item_group_no   --����Q�R�[�h
                                       ,lt_item_no         --���i�R�[�h
                                       ,lt_month_no        --��
                                       ,ln_sales_budget    --����
                                       ,ln_amount          --����
                                       ,lv_errbuf          --�G���[�E���b�Z�[�W
                                       ,lv_retcode         --���^�[���E�R�[�h
                                       ,lv_errmsg);        --���[�U�[�E�G���[�E���b�Z�[�W
                  -- ��O����
                  IF (lv_retcode = cv_status_error) THEN
                    --(�G���[����)
                    gn_error_cnt := gn_error_cnt +1;
                    RAISE global_process_expt;
                  ELSIF (lv_retcode = cv_status_warn) THEN
                    --�x������
                    gn_error_cnt := gn_error_cnt + 1;
                    RAISE deal_skip_expt;
                  END IF;
                  
                  --�@�������i�̌v��f�[�^�쐬
                  --�������i���є䗦�Z�o
                  
                  IF (ln_before_last_year_sale = 0) THEN
                    ln_entity_result_rate := 1;
                  ELSE
                    ln_entity_result_rate := ln_last_year_sale / ln_before_last_year_sale;
                  END IF;
                  IF (ln_entity_result_rate <= 0.5) 
                    OR (ln_entity_result_rate >= 2)
                    OR (ln_entity_result_rate IS NULL)
                  THEN
                      ln_entity_result_rate := 1;
                  END IF;
                  
                  --������z
                  ln_plan_sales_budget        := ROUND((ln_sales_budget * ln_entity_result_rate),-3);
                  
                  --����
                  IF ln_unit_flg = 0 THEN
                    ln_plan_amount              := ROUND((ln_amount * ln_entity_result_rate),0);
                  ELSE
                    ln_plan_amount              := ROUND((ln_amount * ln_entity_result_rate),1);
                  END IF;                 
                  --�e���v
                  ln_plan_amount_gross_margin := ROUND((ln_plan_sales_budget - (ln_plan_amount * ln_discrete_cost)),-3);                 
                  --�|��                         
--//UPD START 2009/02/18 CT_033 M.Ohtsuki
--                  IF (ln_plan_amount = 0) THEN
                  IF ((ln_plan_amount * ln_fixed_price) = 0) THEN
--//UPD END   2009/02/18 CT_033 M.Ohtsuki
                    ln_plan_credit_rate := 0;
                  ELSE
                    ln_plan_credit_rate         := ROUND(((ln_plan_sales_budget / (ln_plan_amount * ln_fixed_price)) * 100),2);
                  END IF;
                  
                  --�e���v��                     
                  IF (ln_plan_sales_budget = 0) THEN
                    ln_margin_rate := 0;
                  ELSE
                    ln_margin_rate              := ROUND(((ln_plan_amount_gross_margin / ln_plan_sales_budget) * 100),2);
                  END IF;
                  
--
                ELSIF (ln_months > 3) and (ln_months <= 15) THEN
                  --�A�V���i�P�N�x���т̌v��f�[�^�쐬
                  --���㌎���ώ��т̎Z�o
                  ln_month_average_sale := ln_last_year_sale / (ln_months - 3);
                  --���ʌ����ώ��т̎Z�o
                  ln_month_average_amount := ln_last_year_amount / (ln_months - 3);
                  --�V���i�P�N�x���є䗦
                  IF (ln_single_result_rate <= 0.5)
                    OR (ln_single_result_rate >= 2) 
                    OR (ln_single_result_rate IS NULL) 
                  THEN
                    ln_single_result_rate := 1;
                  END IF;
                  
                  -- =====================================================
                  -- ����Q�P�ʂł̖{�N�x�Ώی��v��l�擾(A-10)
                  -- =====================================================
                  deal_this_month_plan(
                                     lt_kyoten_cd        -- ���_�R�[�h
                                    ,lt_item_group_no    -- ���i�Q�R�[�h
                                    ,lt_year_month       -- �N��
                                    ,ln_this_month_sale  -- ����Q�P�ʂł̖{�N�x�Ώی��v��l
                                    ,lv_errbuf           -- �G���[�E���b�Z�[�W
                                    ,lv_retcode          -- ���^�[���E�R�[�h
                                    ,lv_errmsg);         -- ���[�U�[�E�G���[�E���b�Z�[�W
                  -- ��O����
                  IF (lv_retcode = cv_status_error) THEN
                    --(�G���[����)
                    gn_error_cnt := gn_error_cnt +1;
                    RAISE global_process_expt;
                  ELSIF (lv_retcode = cv_status_warn) THEN
                    --�x������
                    gn_error_cnt := gn_error_cnt + 1;
                    RAISE deal_skip_expt;
                  END IF;
                  
                  --�V���i�P�N�x����Q�\����̎Z�o
                  IF (ln_this_year_deal_plan = 0) THEN
                    ln_deal_composition_rate := 1;
                  ELSE
                    ln_deal_composition_rate := ln_this_month_sale / ln_this_year_deal_plan;
                  END IF;
                  --�V���i�P�N�x���т̌v��f�[�^�쐬
                  --������z
                  ln_plan_sales_budget        := ROUND((ln_month_average_sale * ln_single_result_rate * ln_deal_composition_rate * 12),-3);
                  --����
                  IF ln_unit_flg = 0 THEN
                    ln_plan_amount              := ROUND((ln_month_average_amount * ln_single_result_rate * ln_deal_composition_rate * 12),0);
                  ELSE 
                    ln_plan_amount              := ROUND((ln_month_average_amount * ln_single_result_rate * ln_deal_composition_rate * 12),1);
                  END IF;
                  --�e���v
                  ln_plan_amount_gross_margin := ROUND((ln_plan_sales_budget - (ln_plan_amount * ln_discrete_cost)),-3);
                  --�|��                         
--//UPD START 2009/02/18 CT_033 M.Ohtsuki
--                  IF (ln_plan_amount = 0) THEN
                  IF ((ln_plan_amount * ln_fixed_price) = 0) THEN
--//UPD END   2009/02/18 CT_033 M.Ohtsuki
                    ln_plan_credit_rate := 0;
                  ELSE
                    ln_plan_credit_rate         := ROUND(((ln_plan_sales_budget / (ln_plan_amount * ln_fixed_price)) * 100),2);
                  END IF;
                  --�e���v��                     
                  IF (ln_plan_sales_budget = 0) THEN
                    ln_margin_rate := 0;
                  ELSE
                    ln_margin_rate              := ROUND(((ln_plan_amount_gross_margin / ln_plan_sales_budget) * 100),2);
                  END IF;
--
                ELSIF (ln_months <= 3) THEN
                --�B�V���i�̔����тȂ��̌v��f�[�^�쐬
                  --������z
                  ln_plan_sales_budget        := 0;
                  --����
                  ln_plan_amount              := 0;
                  --�e���v
                  ln_plan_amount_gross_margin := 0;
                  --�|��
                  ln_plan_credit_rate         := 0;
                  --�e���v��
                  ln_margin_rate              := 0;
--
                ELSIF (ln_months > 15) AND (ln_months < 27) THEN
                  --�C�V���i2���N�x���т̌v��f�[�^�쐬
                  -- =====================================================
                  -- �Ώی��f�[�^�擾(A-5)
                  -- =====================================================
                  item_month_data_select(
                                        lt_kyoten_cd       --���_�R�[�h
                                       ,lt_item_group_no   --����Q�R�[�h
                                       ,lt_item_no         --���i�R�[�h
                                       ,lt_month_no        --��
                                       ,ln_sales_budget    --����
                                       ,ln_amount          --����
                                       ,lv_errbuf          --�G���[�E���b�Z�[�W
                                       ,lv_retcode         --���^�[���E�R�[�h
                                       ,lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W
                   
                  -- ��O����
                  IF (lv_retcode = cv_status_error) THEN
                    --(�G���[����)
                    gn_error_cnt := gn_error_cnt +1;
                    RAISE global_process_expt;
                  ELSIF (lv_retcode = cv_status_warn) THEN
                    --�x������
                    gn_error_cnt := gn_error_cnt + 1;
                    RAISE deal_skip_expt;
                  END IF;
                  
                  --�V���i2���N�x���є䗦�Z�o
                  IF (ln_before_last_year_sale = 0) THEN
                    ln_new_two_result_rate := 1;
                  ELSE
                    ln_new_two_result_rate := ln_last_year_sale / ln_before_last_year_sale;
                  END IF;
                  IF (ln_new_two_result_rate <= 0.5) 
                    OR (ln_new_two_result_rate >= 2) 
                    OR (ln_new_two_result_rate IS NULL) 
                  THEN
                    ln_new_two_result_rate := 1;
                  END IF;
                  --������z
                  ln_plan_sales_budget        := ROUND((ln_sales_budget * ln_new_two_result_rate),-3);
                  --����
                  IF ln_unit_flg = 0 THEN
                  ln_plan_amount              := ROUND((ln_amount * ln_new_two_result_rate),0);
                  ELSE 
                  ln_plan_amount              := ROUND((ln_amount * ln_new_two_result_rate),1);
                  END IF;
                  --�e���v
                  ln_plan_amount_gross_margin := ROUND((ln_plan_sales_budget - (ln_plan_amount * ln_discrete_cost)),-3);
                  --�|��                         
--//UPD START 2009/02/18 CT_033 M.Ohtsuki
--                  IF (ln_plan_amount = 0) THEN
                  IF ((ln_plan_amount * ln_fixed_price) = 0) THEN
--//UPD END   2009/02/18 CT_033 M.Ohtsuki
                    ln_plan_credit_rate := 0;
                  ELSE
                    ln_plan_credit_rate         := ROUND(((ln_plan_sales_budget / (ln_plan_amount * ln_fixed_price)) * 100),2);
                  END IF;
                  --�e���v��                     
                  IF (ln_plan_sales_budget = 0) THEN
                    ln_margin_rate := 0;
                  ELSE
                    ln_margin_rate              := ROUND(((ln_plan_amount_gross_margin / ln_plan_sales_budget) * 100),2);
                  END IF;
                END IF;
--
                --�Z�o�f�[�^�ۑ�
                lr_plan_rec.item_plan_header_id    := lt_item_plan_header_id;      --���i�v��w�b�_ID
                lr_plan_rec.item_plan_lines_id     := NULL;
                lr_plan_rec.year_month             := lt_year_month;               --�N��
                lr_plan_rec.month_no               := lt_month_no;                 --��
                lr_plan_rec.year_bdgt_kbn          := '0';                         --�N�ԌQ�\�Z�敪(0�F�e��)
                lr_plan_rec.item_kbn               := '1';                         --���i�敪(1�F���i�P�i)
                lr_plan_rec.item_no                := lt_item_no;                  --���i�R�[�h
                lr_plan_rec.item_group_no          := lt_item_group_no;            --���i�Q�R�[�h
                lr_plan_rec.amount                 := ln_plan_amount;              --����
                lr_plan_rec.sales_budget           := ln_plan_sales_budget;        --������z
                lr_plan_rec.amount_gross_margin    := ln_plan_amount_gross_margin; --�e���v(�V)
                lr_plan_rec.credit_rate            := ln_plan_credit_rate;         --�|��
                lr_plan_rec.margin_rate            := ln_margin_rate;              --�e���v��(�V)
                lr_plan_rec.created_by             := cn_created_by;               --�쐬��
                lr_plan_rec.creation_date          := cd_creation_date;            --�쐬��
                lr_plan_rec.last_updated_by        := cn_last_updated_by;          --�ŐV�X�V��
                lr_plan_rec.last_update_date       := cd_last_update_date;         --�ŐV�X�V��
                lr_plan_rec.last_update_login      := cn_last_update_login;        --�ŏI�X�V���O�C��ID
                lr_plan_rec.request_id             := cn_request_id;               --�v��ID
                lr_plan_rec.program_application_id := cn_program_application_id;   --�v���O�����A�v���P�[�V����ID
                lr_plan_rec.program_id             := cn_program_id;               --�v���O����ID
                lr_plan_rec.program_update_date    := cd_program_update_date;      --�v���O�����X�V��
--
                -- =====================================================
                -- �f�[�^�o�^(A-12)
                -- =====================================================
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
                ELSIF (lv_retcode = cv_status_warn) THEN
                  --�x������
                  gn_error_cnt := gn_error_cnt + 1;
                  RAISE deal_skip_expt;
                END IF;
              END LOOP month_loop;
            CLOSE year_month_select_cur;
          END LOOP item_loop;
        CLOSE sale_result_cur;
        -- *** A-5���i�R�[�h�擾�ł��Ȃ��ꍇ�A�Ώۃf�[�^�����G���[�ɂȂ�܂� ***
        IF lt_item_no IS NULL THEN
            lv_no_data_msg := xxccp_common_pkg.get_msg(
                                                  iv_application  =>  cv_xxcsm
                                                 ,iv_name         =>  cv_chk_err_00056
                                                 ,iv_token_name1  =>  cv_tkn_cd_deal
                                                 ,iv_token_value1 =>  lt_item_group_no
                                                 );
            fnd_file.put_line(
                            which  => FND_FILE.LOG
                           ,buff   => lv_no_data_msg
                           );
            fnd_file.put_line(
                            which  => FND_FILE.OUTPUT
                           ,buff   => lv_no_data_msg
                           );
        END IF;
--
        -- =====================================================
        -- �V���i�v��l�Z�o(�V���i�R�[�h�擾)(A-11)
        -- =====================================================
        new_item_no_select(
                           lt_item_group_no       -- A-3�Ŏ擾��������Q�R�[�h
                          ,lv_new_item_no         -- �V���i�R�[�h
--//ADD START 2009/05/19 T1_1069 T.Tsukino
                          ,lv_new_item_cost       -- �c�ƌ���
                          ,lv_new_item_price      -- �艿
--//ADD END 2009/05/19 T1_1069 T.Tsukino                          
                          ,lv_errbuf              -- �G���[�E���b�Z�[�W
                          ,lv_retcode             -- ���^�[���E�R�[�h
                          ,lv_errmsg);            -- ���[�U�[�E�G���[�E���b�Z�[�W
        
        -- ��O����
        IF (lv_retcode = cv_status_error) THEN
          --(�G���[����)
          gn_error_cnt := gn_error_cnt +1;
          RAISE global_process_expt;
        ELSIF (lv_retcode = cv_status_warn) THEN
          --�x������
          gn_error_cnt := gn_error_cnt + 1;
          RAISE deal_skip_expt;
        END IF;
--
        -- =====================================================
        -- �V���i�v��l�Z�o(A-11)
        -- =====================================================
        OPEN kyoten_month_deal_plan_cur(lt_item_group_no);
          <<new_month_loop>>
          LOOP
            FETCH kyoten_month_deal_plan_cur INTO kyoten_month_deal_plan_cur_rec;
            EXIT WHEN kyoten_month_deal_plan_cur%NOTFOUND;
            lt_new_year_month   := kyoten_month_deal_plan_cur_rec.year_month;
            lt_new_month_no     := kyoten_month_deal_plan_cur_rec.month_no;
            ln_new_sales_budget := kyoten_month_deal_plan_cur_rec.sales_budget;
            ln_new_gross_budget := kyoten_month_deal_plan_cur_rec.amount_gross_margin;
            
            -- =====================================================
            -- �V���i�v��l�Z�o(���ʒP�i������z���v�擾)(A-11)
            -- =====================================================
            month_item_sales_sum(
                                 lt_item_plan_header_id     -- �w�b�_ID
                                ,lt_item_group_no           -- A-3�Ŏ擾��������Q�R�[�h
                                ,lt_new_year_month          -- �N��
                                ,ln_month_sales_sum         -- ���ʒP�i������z���v
                                ,ln_month_gross_sum         -- ���ʒP�i�e���v�z���v
                                ,lv_errbuf                  -- �G���[�E���b�Z�[�W
                                ,lv_retcode                 -- ���^�[���E�R�[�h
                                ,lv_errmsg);                -- ���[�U�[�E�G���[�E���b�Z�[�W 
            
            -- ��O����
            IF (lv_retcode = cv_status_error) THEN
              --(�G���[����)
              gn_error_cnt := gn_error_cnt +1;
              RAISE global_process_expt;
            ELSIF (lv_retcode = cv_status_warn) THEN
              --�x������
              gn_error_cnt := gn_error_cnt + 1;
              RAISE deal_skip_expt;
            END IF;
--
            --�B�V���i�v��l�Z�o
            ln_new_plan_sales := ln_new_sales_budget - NVL(ln_month_sales_sum,0);
            ln_new_plan_gross := ln_new_gross_budget - NVL(ln_month_gross_sum,0);
            --//ADD START 2009/05/27 T1_1173 A.Sakawa
            IF ( lv_new_item_cost = 0 ) THEN
              -- ���ʂ�0���Z�b�g
              ln_new_plan_amount := 0;
            ELSE
            --//ADD END 2009/05/27 T1_1173 A.Sakawa
              --//UPD START 2009/05/19 T1_1069 T.Tsukino
              -- ���� = ( ( ���� - �e���v�z ) / ����(1������) )
              ln_new_plan_amount :=  ROUND(((ln_new_plan_sales - ln_new_plan_gross) / lv_new_item_cost),0);
              --//UPD END 2009/05/19 T1_1069 T.Tsukino
            --//ADD START 2009/05/27 T1_1173 A.Sakawa
            END IF;
            IF ( ln_new_plan_amount * lv_new_item_price = 0 ) THEN
              -- �|����0���Z�b�g
              ln_new_plan_credit := 0;
            ELSE
            --//ADD END 2009/05/27 T1_1173 A.Sakawa
              --//UPD START 2009/05/19 T1_1069 T.Tsukino
              -- �|�� = ( ���� / ( ���� * �艿) ) * 100        
              ln_new_plan_credit :=  ROUND((ln_new_plan_sales / (ln_new_plan_amount * lv_new_item_price)) * 100,2);
              --//UPD END 2009/05/19 T1_1069 T.Tsukino
            --//ADD START 2009/05/27 T1_1173 A.Sakawa
            END IF;
            --//ADD END 2009/05/27 T1_1173 A.Sakawa
            --�V���i�o�^�l�ۑ�
            lr_new_plan_rec.item_plan_header_id    := lt_item_plan_header_id;         --���i�v��w�b�_ID
            lr_new_plan_rec.item_plan_lines_id     := NULL;
            lr_new_plan_rec.year_month             := lt_new_year_month;              --�N��
            lr_new_plan_rec.month_no               := lt_new_month_no;                --��
            lr_new_plan_rec.year_bdgt_kbn          := '0';                            --�N�ԌQ�\�Z�敪(0�F�e��)
            lr_new_plan_rec.item_kbn               := '2';                            --���i�敪(2�F�V���i)
            lr_new_plan_rec.item_no                := lv_new_item_no;                 --���i�R�[�h
            lr_new_plan_rec.item_group_no          := lt_item_group_no;               --���i�Q�R�[�h
            --//UPD START 2009/05/07 T1_0792 T.Tsukino
            --lr_new_plan_rec.amount                 := 0;                              --����
            lr_new_plan_rec.amount                 := ln_new_plan_amount;               --����
            --//UPD END 2009/05/07 T1_0792 T.Tsukino
            lr_new_plan_rec.sales_budget           := ln_new_plan_sales;              --������z
            lr_new_plan_rec.amount_gross_margin    := ln_new_plan_gross;              --�e���v(�V)
            --//UPD START 2009/05/07 T1_0792 T.Tsukino
            --lr_new_plan_rec.credit_rate            := 0;                              --�|��
            lr_new_plan_rec.credit_rate            := ln_new_plan_credit;             --�|��
            --//UPD END 2009/05/07 T1_0792 T.Tsukino
            lr_new_plan_rec.margin_rate            := 0;                              --�e���v��(�V)
            lr_new_plan_rec.created_by             := cn_created_by;                  --�쐬��
            lr_new_plan_rec.creation_date          := cd_creation_date;               --�쐬��
            lr_new_plan_rec.last_updated_by        := cn_last_updated_by;             --�ŐV�X�V��
            lr_new_plan_rec.last_update_date       := cd_last_update_date;            --�ŐV�X�V��
            lr_new_plan_rec.last_update_login      := cn_last_update_login;           --�ŏI�X�V���O�C��ID
            lr_new_plan_rec.request_id             := cn_request_id;                  --�v��ID
            lr_new_plan_rec.program_application_id := cn_program_application_id;      --�v���O�����A�v���P�[�V����ID
            lr_new_plan_rec.program_id             := cn_program_id;                  --�v���O����ID
            lr_new_plan_rec.program_update_date    := cd_program_update_date;         --�v���O�����X�V��
--
            -- =====================================================
            -- �f�[�^�o�^(A-12)
            -- =====================================================
            insert_data(
                        lr_new_plan_rec          -- �Ώۃ��R�[�h
                       ,lv_errbuf            -- �G���[�E���b�Z�[�W
                       ,lv_retcode           -- ���^�[���E�R�[�h
                       ,lv_errmsg);
            -- ��O����
            IF (lv_retcode = cv_status_error) THEN
              --(�G���[����)
              gn_error_cnt := gn_error_cnt +1;
              RAISE global_process_expt;
            ELSIF (lv_retcode = cv_status_warn) THEN
              --�x������
              gn_error_cnt := gn_error_cnt + 1;
              RAISE deal_skip_expt;
            END IF;
--
          END LOOP new_month_loop;
        CLOSE kyoten_month_deal_plan_cur;
--
        --���f�p���i�Q�R�[�h�ۑ�
        lt_pre_item_group_no := lt_item_group_no;
        gn_normal_cnt := gn_normal_cnt + 1;
      EXCEPTION
        WHEN deal_skip_expt THEN
        IF year_month_select_cur%ISOPEN THEN
          CLOSE year_month_select_cur;
        END IF;
        IF sale_result_cur%ISOPEN THEN
          CLOSE sale_result_cur;
        END IF;
        IF kyoten_month_deal_plan_cur%ISOPEN THEN
          CLOSE kyoten_month_deal_plan_cur;
        END IF;
        fnd_file.put_line(
                        which  => FND_FILE.LOG
                       ,buff   => lv_errbuf
                       );
        fnd_file.put_line(
                        which  => FND_FILE.OUTPUT
                       ,buff   => lv_errmsg
                       );
        ov_retcode := cv_status_warn;  --�x��
        ROLLBACK TO item_group_point;
      END;
      END LOOP deal_loop;
      IF (deal_select_cur%ROWCOUNT = 0) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                                        iv_application  =>  cv_xxcsm
                                       ,iv_name         =>  cv_chk_err_10001
                                       );
        lv_errbuf := lv_errmsg;
        fnd_file.put_line(
                        which  => FND_FILE.LOG
                       ,buff   => lv_errbuf
                       );
        fnd_file.put_line(
                        which  => FND_FILE.OUTPUT
                       ,buff   => lv_errmsg
                       );
      END IF;
    CLOSE deal_select_cur;
--
--
  EXCEPTION
      -- *** �C�ӂŗ�O�������L�q���� ****
--
--#################################  �Œ��O������ START   ###################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
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
    errbuf        OUT NOCOPY VARCHAR2,      --   �G���[�E���b�Z�[�W
    retcode       OUT NOCOPY VARCHAR2,      --   ���^�[���E�R�[�h
    iv_kyoten_cd     IN  VARCHAR2,          --   ���_�R�[�h
    iv_deal_cd       IN  VARCHAR2           --   ����Q�R�[�h
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
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );

    -- ===============================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ===============================================
    submain(
       iv_kyoten_cd   --���_�R�[�h
      ,iv_deal_cd     --����Q�R�[�h
      ,lv_errbuf   -- �G���[�E���b�Z�[�W 
      ,lv_retcode  -- ���^�[���E�R�[�h  
      ,lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W 
    );
--
    IF lv_retcode = cv_status_error THEN
      IF lv_errmsg IS NULL THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                                                 iv_application  => cv_xxcsm
                                                ,iv_name         => cv_msg_00111
                                               );
      END IF;
      
    --�G���[�o��
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
      );
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff => lv_errbuf --�G���[���b�Z�[�W
      );
      gn_target_cnt := 0;
      gn_normal_cnt := 0;
      gn_error_cnt := 1;
      gn_warn_cnt := 0;
    END IF;
--
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
--
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
    --�X�L�b�v�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_skip_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_warn_cnt)
                   );
    fnd_file.put_line(
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
    fnd_file.put_line(
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
      errbuf  := gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
      ROLLBACK;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      errbuf  := gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
      ROLLBACK;
  END main;
--
--###########################  �Œ蕔 END   #######################################################
--
END XXCSM002A05C;
/