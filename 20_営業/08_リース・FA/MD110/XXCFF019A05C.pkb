CREATE OR REPLACE PACKAGE BODY XXCFF019A05C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2017. All rights reserved.
 *
 * Package Name     : XXCFF019A05C(body)
 * Description      : IFRS�䒠�����p
 * MD.050           : MD050_CFF_019_A05_IFRS�䒠�����p
 * Version          : 1.0
 *
 * Program List
 * ----------------------------- ----------------------------------------------------------
 *  Name                          Description
 * ----------------------------- ----------------------------------------------------------
 *  init                          ��������                                  (A-1)
 *  get_profile_values            �v���t�@�C���l�擾                        (A-2)
 *  chk_period                    ��v���ԃ`�F�b�N                          (A-3)
 *  get_exec_date                 ���s�����擾                              (A-4)
 *  get_ifrs_fa_retire_data       IFRS�䒠�����p�f�[�^���o                  (A-5)
 *  upd_ifrs_sets                 IFRS�䒠�A�g�Z�b�g�X�V                    (A-6)
 *  submain                       ���C�������v���V�[�W��
 *  main                          �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2017/11/07    1.0   SCSK���         �V�K�쐬
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
  gv_sep_msg       VARCHAR2(2000);
  gv_exec_user     VARCHAR2(100);
  gv_conc_name     VARCHAR2(30);
  gv_conc_status   VARCHAR2(30);
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
  --*** ��v���ԃ`�F�b�N�G���[
  chk_period_expt           EXCEPTION;
--
  PRAGMA EXCEPTION_INIT(global_api_others_expt,-20000);
--
--################################  �Œ蕔 END   ##################################
--
  -- ===============================
  -- ���[�U�[��`��O
  -- ===============================
  data_lock_expt            EXCEPTION;        -- ���R�[�h���b�N�G���[
  PRAGMA EXCEPTION_INIT(data_lock_expt, -54);
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name         CONSTANT VARCHAR2(100):= 'XXCFF019A05C'; -- �p�b�P�[�W��
--
  -- ***�A�v���P�[�V�����Z�k��
  cv_msg_kbn_cff      CONSTANT VARCHAR2(5)  := 'XXCFF';
--
  -- ***���b�Z�[�W��(�{��)
  cv_msg_019a05_m_010 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00020'; -- �v���t�@�C���擾�G���[
  cv_msg_019a05_m_011 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00037'; -- ��v���ԃ`�F�b�N�G���[
  cv_msg_019a05_m_013 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00278'; -- �����pOIF�o�^���b�Z�[�W
  cv_msg_019a05_m_014 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00280'; -- IFRS�䒠�����p�G���[
  cv_msg_019a05_m_017 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00165'; -- �擾�Ώۃf�[�^�������b�Z�[�W
  cv_msg_019a05_m_019 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00007'; -- ���b�N�G���[
  -- ***���b�Z�[�W��(�g�[�N��)
  cv_msg_019a05_t_010 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50228'; -- XXCFF:�䒠���_�Œ莑�Y�䒠
  cv_msg_019a05_t_011 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50314'; -- XXCFF:�䒠���_IFRS�䒠
  cv_msg_019a05_t_012 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50315'; -- �Œ莑�Y�䒠���
  cv_msg_019a05_t_013 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50316'; -- IFRS�䒠�A�g�Z�b�g
  cv_msg_019a05_t_015 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50093'; -- XXCFF:�����@
--
  -- ***�g�[�N����
  cv_tkn_prof         CONSTANT VARCHAR2(20) := 'PROF_NAME';
  cv_tkn_asset_number CONSTANT VARCHAR2(20) := 'ASSET_NUMBER';
  cv_tkn_bk_type      CONSTANT VARCHAR2(20) := 'BOOK_TYPE_CODE';
  cv_tkn_period       CONSTANT VARCHAR2(20) := 'PERIOD_NAME';
  cv_tkn_get_data     CONSTANT VARCHAR2(20) := 'GET_DATA';
  cv_tkn_table_name   CONSTANT VARCHAR2(20) := 'TABLE_NAME';
--
  -- ***�v���t�@�C��
  cv_fixed_asset_register   CONSTANT VARCHAR2(30) := 'XXCFF1_FIXED_ASSET_REGISTER';       -- �䒠���_�Œ莑�Y�䒠
  cv_fixed_ifrs_asset_regi  CONSTANT VARCHAR2(35) := 'XXCFF1_FIXED_IFRS_ASSET_REGISTER';  -- �䒠���_IFRS�䒠
  cv_prt_conv_cd_ed         CONSTANT VARCHAR2(30) := 'XXCFF1_PRT_CONV_CD_ED';             -- �����@_����
--
  -- ***�t�@�C���o��
  cv_file_type_out   CONSTANT VARCHAR2(10) := 'OUTPUT'; -- ���b�Z�[�W�o��
  cv_file_type_log   CONSTANT VARCHAR2(10) := 'LOG';    -- ���O�o��
--
  cn_zero_0          CONSTANT NUMBER       := 0;        -- ���l�[��
  cv_yes             CONSTANT VARCHAR2(1)  := 'Y';
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  -- ***�o���N�t�F�b�`�p��`
  -- IFRS�䒠�����p�Ώۃf�[�^���R�[�h�^
  TYPE g_ifrs_fa_retire_rtype IS RECORD(
    asset_id                       fa_additions_b.asset_id%TYPE,                       -- ���YID
    asset_number                   fa_additions_b.asset_number%TYPE,                   -- ���Y�ԍ�
    date_retired                   fa_retirements.date_retired%TYPE,                   -- �����p��
    cost                           fa_books.cost%TYPE,                                 -- ���E���p�擾���i
    retirement_type_code           fa_retirements.retirement_type_code%TYPE,           -- �����p�^�C�v
    proceeds_of_sale               fa_retirements.proceeds_of_sale%TYPE,               -- ���p���i
    cost_of_removal                fa_retirements.cost_of_removal%TYPE,                -- �P����p
    retirement_prorate_convention  fa_retirements.retirement_prorate_convention%TYPE   -- ������p�N�x���p
  );
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  -- ***�o���N�t�F�b�`�p��`
  -- IFRS�䒠�����p�Ώۃf�[�^���R�[�h�z��
  TYPE g_ifrs_fa_retire_ttype IS TABLE OF g_ifrs_fa_retire_rtype
  INDEX BY BINARY_INTEGER;
--
  g_ifrs_fa_retire_tab         g_ifrs_fa_retire_ttype;  -- IFRS�䒠�����p�Ώۃf�[�^
--
  -- �p�����[�^��v���Ԗ�
  gv_period_name            VARCHAR2(100);
--
  -- ���s����
  gt_exec_date  xxcff_ifrs_sets.exec_date%TYPE;
--
  -- ***�v���t�@�C���l
  gv_fixed_asset_register   VARCHAR2(100);  -- �䒠���_�Œ莑�Y�䒠
  gv_fixed_ifrs_asset_regi  VARCHAR2(100);  -- �䒠���_IFRS�䒠
  gv_prt_conv_cd_ed         VARCHAR2(100);  -- XXCFF:�����@
--
  -- ***��������
  -- IFRS�䒠�����p�����ɂ����錏��
  gn_ifrs_fa_retire_target_cnt NUMBER;     -- �Ώی���
  gn_loop_cnt                  NUMBER;     -- LOOP��
  gn_ifrs_fa_retire_normal_cnt NUMBER;     -- ���팏��
  gn_ifrs_fa_retire_err_cnt    NUMBER;     -- �G���[����
--
  /**********************************************************************************
   * Procedure Name   : upd_ifrs_sets
   * Description      : IFRS�䒠�A�g�Z�b�g�X�V (A-6)
   ***********************************************************************************/
  PROCEDURE upd_ifrs_sets(
    ov_errbuf      OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode     OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg      OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_ifrs_sets'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
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
    UPDATE xxcff_ifrs_sets  xis       -- IFRS�䒠�A�g�Z�b�g
    SET    xis.exec_date              = cd_last_update_date         -- ���s����
          ,xis.last_updated_by        = cn_last_updated_by          -- �ŏI�X�V��
          ,xis.last_update_date       = cd_last_update_date         -- �ŏI�X�V��
          ,xis.last_update_login      = cn_last_update_login        -- �ŏI�X�V���O�C��ID
          ,xis.request_id             = cn_request_id               -- �v��ID
          ,xis.program_application_id = cn_program_application_id   -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
          ,xis.program_id             = cn_program_id               -- �R���J�����g�E�v���O����ID
          ,xis.program_update_date    = cd_program_update_date      -- �v���O�����X�V��
    WHERE  xis.exec_id                = cv_pkg_name                 -- ����ID
    ;
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
  END upd_ifrs_sets;
--
  /**********************************************************************************
   * Procedure Name   : get_ifrs_fa_retire_data
   * Description      : IFRS�䒠�����p�f�[�^���o(A-5)
   ***********************************************************************************/
  PROCEDURE get_ifrs_fa_retire_data(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name           CONSTANT VARCHAR2(100) := 'get_ifrs_fa_retire_data'; -- �v���O������
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
    cv_tran_type_retire   CONSTANT VARCHAR2(16)   := 'FULL RETIREMENT';      -- ����^�C�v�R�[�h(�����p)
    cv_status_pending     CONSTANT VARCHAR2(7)   := 'PENDING';              -- �X�e�[�^�X�FPENDING
--
    -- *** ���[�J���ϐ� ***
    lv_warnmsg            VARCHAR2(5000);                                         -- �x�����b�Z�[�W
    lb_ret                BOOLEAN;                                                -- �֐����^�[���R�[�h
--
    -- *** ���[�J���E�J�[�\�� ***
    -- �Œ莑�Y�䒠�J�[�\��
    CURSOR ifrs_fa_retire_cur
    IS
      SELECT  
      -- �����pOIF�o�^�p
        ifrs_fab.asset_id                AS asset_id                       -- ���YID
       ,ifrs_fab.asset_number            AS asset_number                   -- ���Y�ԍ�
       ,fr.date_retired                  AS date_retired                   -- �����p��
       ,ifrs_fb.cost                     AS cost_retired                   -- ������p�擾���i
       ,fr.retirement_type_code          AS retirement_type_code           -- �����p�^�C�v
       ,fr.proceeds_of_sale              AS proceeds_of_sale               -- ���p���i
       ,fr.cost_of_removal               AS cost_of_removal                -- �P����p
       ,fr.retirement_prorate_convention AS retirement_prorate_convention  -- ������p�N�x���p
      FROM    fa_books                  fb        -- ���Y�䒠���
             ,fa_additions_b            fab       -- ���Y�ڍ׏��
             ,fa_retirements            fr        -- �����p���
             ,fa_additions_b            ifrs_fab  -- ���Y�ڍ׏��iIFRS�䒠�j
             ,fa_books                  ifrs_fb   -- ���Y�䒠���
      WHERE   fb.asset_id                   = fab.asset_id
      AND     fb.book_type_code             = gv_fixed_asset_register   -- ���Y�䒠��(�Œ莑�Y)
      AND     fb.transaction_header_id_in   IN (
                                                SELECT  fth.transaction_header_id   AS trans_header_id  -- �L������w�b�_ID
                                                FROM    fa_transaction_headers fth
                                                WHERE   fth.transaction_type_code = cv_tran_type_retire    -- ����^�C�v�R�[�h('FULL RETIREMENT')
                                                AND     fth.book_type_code        = fb.book_type_code   -- ���Y�䒠��
                                                AND     fth.asset_id              = fab.asset_id        -- ���YID
                                                AND     fth.date_effective        > gt_exec_date
                                               )
      AND fab.asset_id                      = fr.asset_id
      AND fb.book_type_code                 = fr.book_type_code
      AND fb.transaction_header_id_in       = fr.transaction_header_id_in
      AND fab.asset_number                  = ifrs_fab.attribute22
      AND ifrs_fb.asset_id                  = ifrs_fab.asset_id
      AND ifrs_fb.book_type_code            = gv_fixed_ifrs_asset_regi
      AND ifrs_fb.date_ineffective          IS NULL
      AND ifrs_fb.period_counter_fully_retired   IS NULL
      AND NOT EXISTS ( -- ����OIF���ɏ����p�f�[�^���o�^����Ă���ꍇ�����O
                      SELECT 1
                       FROM  xx01_retire_oif xro
                      WHERE  xro.book_type_code = gv_fixed_ifrs_asset_regi
                        AND  ifrs_fab.asset_number  = xro.asset_number
                     )
      ;
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
    --==============================================================
    --���C���f�[�^���o
    --==============================================================
    -- �J�[�\���I�[�v��
    OPEN ifrs_fa_retire_cur;
    -- �f�[�^�̈ꊇ�擾
    FETCH ifrs_fa_retire_cur BULK COLLECT INTO  g_ifrs_fa_retire_tab;
    -- �J�[�\���N���[�Y
    CLOSE ifrs_fa_retire_cur;
    -- �Ώی����̎擾
    gn_ifrs_fa_retire_target_cnt := g_ifrs_fa_retire_tab.COUNT;
--
    -- �V�K�o�^�Ώی�����0���̏ꍇ
    IF ( gn_ifrs_fa_retire_target_cnt = cn_zero_0 ) THEN
      --���b�Z�[�W�̐ݒ�
      lv_warnmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                     ,cv_msg_019a05_m_017  -- �擾�Ώۃf�[�^����
                                                     ,cv_tkn_get_data      -- �g�[�N��'GET_DATA'
                                                     ,cv_msg_019a05_t_012) -- �Œ莑�Y�䒠���
                                                     ,1
                                                     ,5000);
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG  --���O(�V�X�e���Ǘ��җp���b�Z�[�W)�o��
        ,buff   => lv_warnmsg
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT  --���b�Z�[�W(���[�U�p���b�Z�[�W)�o��
        ,buff   => lv_warnmsg
      );
    END IF;
--
    -- LOOP��������
    gn_loop_cnt := 0;
--
    -- ***************************************
    -- ***        ���[�v�����̋L�q         ***
    -- ***       �������̌Ăяo��          ***
    -- ***************************************
    --==============================================================
    --���C�����[�v����
    --==============================================================
    <<ifrs_fa_retire_loop>>
    FOR ln_loop_cnt IN 1 .. gn_ifrs_fa_retire_target_cnt LOOP
--
      -- LOOP���擾
      gn_loop_cnt := ln_loop_cnt;
--
      -- ����IFRS�䒠�ɏ����p�f�[�^�����݂���ꍇ�͏������X�L�b�v����
      -- ������if����2�d�o�^���������
      -- BOOK_TYPE_CODE+ASSET_NUMBER�̑g�ݍ��킹������̂��̂�����΃X�L�b�v
--
      --==============================================================
      -- �����pOIF�o�^ (A-6)
      --==============================================================
          INSERT INTO xx01_retire_oif(
             retire_oif_id                  -- ID
            ,book_type_code                 -- �䒠��
            ,asset_number                   -- ���Y�ԍ�
            ,date_retired                   -- ������p��
            ,posting_flag                   -- �]�L�����׸�
            ,status                         -- �ð��
            ,cost_retired                   -- ������p�擾���i
            ,retirement_type_code           -- �����p�^�C�v
            ,proceeds_of_sale               -- ���p���z
            ,cost_of_removal                -- �P����p
            ,retirement_prorate_convention  -- ������p�N�x���p
            ,created_by                     -- �쐬��
            ,creation_date                  -- �쐬��
            ,last_updated_by                -- �ŏI�X�V��
            ,last_update_date               -- �ŏI�X�V��
            ,last_update_login              -- �ŏI�X�V۸޲�
            ,request_id                     -- ظ���ID
            ,program_application_id         -- ���ع����ID
            ,program_id                     -- ��۸���ID
            ,program_update_date            -- ��۸��эŏI�X�V
          ) VALUES (
             xx01_retire_oif_s.NEXTVAL                               -- ID
            ,gv_fixed_ifrs_asset_regi                                -- �䒠��
            ,g_ifrs_fa_retire_tab(ln_loop_cnt).asset_number          -- ���Y�ԍ�
            ,g_ifrs_fa_retire_tab(ln_loop_cnt).date_retired          -- ������p��
            ,cv_yes                                                  -- �]�L�����׸�
            ,cv_status_pending                                       -- �ð��(PENDING)
            ,g_ifrs_fa_retire_tab(ln_loop_cnt).cost                  -- ������p�擾���i
            ,g_ifrs_fa_retire_tab(ln_loop_cnt).retirement_type_code  -- �����p�^�C�v
            ,g_ifrs_fa_retire_tab(ln_loop_cnt).proceeds_of_sale      -- ���p���z
            ,g_ifrs_fa_retire_tab(ln_loop_cnt).cost_of_removal       -- �P����p
            ,gv_prt_conv_cd_ed                                       -- ������p�N�x���p
            ,cn_created_by                                           -- �쐬��
            ,cd_creation_date                                        -- �쐬��
            ,cn_last_updated_by                                      -- �ŏI�X�V��
            ,cd_last_update_date                                     -- �ŏI�X�V��
            ,cn_last_update_login                                    -- �ŏI�X�V���O�C��ID
            ,cn_request_id                                           -- ���N�G�X�gID
            ,cn_program_application_id                               -- �A�v���P�[�V����ID
            ,cn_program_id                                           -- �v���O����ID
            ,cd_program_update_date                                  -- �v���O�����ŏI�X�V��
          )
          ;
--
      -- IFRS�䒠�����p���팏���J�E���g
      gn_ifrs_fa_retire_normal_cnt := gn_ifrs_fa_retire_normal_cnt + 1;
--
    END LOOP ifrs_fa_retire_loop;
--
  EXCEPTION
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      -- �J�[�\���N���[�Y
      IF (ifrs_fa_retire_cur%ISOPEN) THEN
        CLOSE ifrs_fa_retire_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      -- �J�[�\���N���[�Y
      IF (ifrs_fa_retire_cur%ISOPEN) THEN
        CLOSE ifrs_fa_retire_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      -- �J�[�\���N���[�Y
      IF (ifrs_fa_retire_cur%ISOPEN) THEN
        CLOSE ifrs_fa_retire_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_ifrs_fa_retire_data;
--
  /**********************************************************************************
   * Procedure Name   : get_exec_date
   * Description      : ���s�����擾 (A-4)
   ***********************************************************************************/
  PROCEDURE get_exec_date(
    ov_errbuf      OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode     OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg      OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_exec_date'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
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
    BEGIN
      SELECT  xis.exec_date AS exec_date  -- ���s����
      INTO    gt_exec_date
      FROM    xxcff_ifrs_sets  xis        -- IFRS�䒠�A�g�Z�b�g
      WHERE   xis.exec_id = cv_pkg_name
      FOR UPDATE NOWAIT
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                      ,cv_msg_019a05_m_017  -- �擾�Ώۃf�[�^����
                                                      ,cv_tkn_get_data      -- �g�[�N��'GET_DATA'
                                                      ,cv_msg_019a05_t_013) -- IFRS�䒠�A�g�Z�b�g
                                                      ,1
                                                      ,5000);
        lv_errbuf := lv_errmsg;
        --
        ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
        ov_errmsg  := lv_errmsg;
        ov_retcode := cv_status_error;
      --
      WHEN data_lock_expt THEN
        lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                      ,cv_msg_019a05_m_019  -- ���b�N�G���[
                                                      ,cv_tkn_table_name    -- �g�[�N��'TABLE_NAME'
                                                      ,cv_msg_019a05_t_013) -- IFRS�䒠�A�g�Z�b�g
                                                      ,1
                                                      ,5000);
        lv_errbuf := lv_errmsg ||cv_msg_part|| SQLERRM;
        --
        ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
        ov_errmsg  := lv_errmsg;
        ov_retcode := cv_status_error;
    END;
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
  END get_exec_date;
--
  /**********************************************************************************
   * Procedure Name   : chk_period
   * Description      : ��v���ԃ`�F�b�N(A-3)
   ***********************************************************************************/
  PROCEDURE chk_period(
    ov_errbuf      OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode     OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg      OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_period'; -- �v���O������
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
    lt_deprn_run          fa_deprn_periods.deprn_run%TYPE := NULL;  -- �������p���s�t���O
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
    BEGIN
      -- ��v���ԃ`�F�b�N
      SELECT  fdp.deprn_run        AS deprn_run   -- �������p���s�t���O
      INTO    lt_deprn_run
      FROM    fa_deprn_periods  fdp               -- �������p����
      WHERE   fdp.book_type_code    = gv_fixed_ifrs_asset_regi
      AND     fdp.period_name       = gv_period_name
      AND     fdp.period_close_date IS NULL
      ;
    EXCEPTION
      -- ��v���Ԃ̎擾�������[�����̏ꍇ
      WHEN NO_DATA_FOUND THEN
        RAISE chk_period_expt;
    END;
--
    -- �������p�����s����Ă���ꍇ
    IF lt_deprn_run = cv_yes THEN
      RAISE chk_period_expt;
    END IF;
--
  EXCEPTION
    -- *** ��v���ԃ`�F�b�N�G���[�n���h�� ***
    WHEN chk_period_expt THEN	
      -- �G���[���b�Z�[�W���Z�b�g
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff            -- XXCFF
                                                    ,cv_msg_019a05_m_011       -- ��v���ԃ`�F�b�N�G���[
                                                    ,cv_tkn_bk_type            -- �g�[�N��'BOOK_TYPE_CODE'
                                                    ,gv_fixed_ifrs_asset_regi  -- ���Y�䒠��
                                                    ,cv_tkn_period             -- �g�[�N��'PERIOD_NAME'
                                                    ,gv_period_name)           -- ��v���Ԗ�
                                                    ,1
                                                    ,5000);
      lv_errbuf := lv_errmsg;
      --
      ov_errbuf := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_errmsg := lv_errmsg;
      -- �I���X�e�[�^�X�̓G���[�Ƃ���
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
  END chk_period;
--
  /**********************************************************************************
   * Procedure Name   : get_profile_values
   * Description      : �v���t�@�C���擾����(A-2)
   ***********************************************************************************/
  PROCEDURE get_profile_values(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_profile_values'; -- �v���O������
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
    -- XXCFF:�䒠���_�Œ莑�Y�䒠
    gv_fixed_asset_register := FND_PROFILE.VALUE(cv_fixed_asset_register);
    IF (gv_fixed_asset_register IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                    ,cv_msg_019a05_m_010  -- �v���t�@�C���擾�G���[
                                                    ,cv_tkn_prof          -- �g�[�N��'PROF_NAME'
                                                    ,cv_msg_019a05_t_010) -- XXCFF:�䒠���_�Œ莑�Y�䒠
                                                    ,1
                                                    ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- XXCFF:�䒠���_IFRS�䒠
    gv_fixed_ifrs_asset_regi := FND_PROFILE.VALUE(cv_fixed_ifrs_asset_regi);
    IF (gv_fixed_ifrs_asset_regi IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                    ,cv_msg_019a05_m_010  -- �v���t�@�C���擾�G���[
                                                    ,cv_tkn_prof          -- �g�[�N��'PROF_NAME'
                                                    ,cv_msg_019a05_t_011) -- XXCFF:�䒠���_IFRS�䒠
                                                    ,1
                                                    ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- XXCFF:�����@
    gv_prt_conv_cd_ed := FND_PROFILE.VALUE(cv_prt_conv_cd_ed);
    IF (gv_prt_conv_cd_ed IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                    ,cv_msg_019a05_m_010  -- �v���t�@�C���擾�G���[
                                                    ,cv_tkn_prof          -- �g�[�N��'PROF_NAME'
                                                    ,cv_msg_019a05_t_015) -- XXCFF:�����@
                                                    ,1
                                                    ,5000);
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
  END get_profile_values;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    -- �R���J�����g�p�����[�^�l�o��(�o�͂̕\��)
    xxcff_common1_pkg.put_log_param(
       iv_which         => cv_file_type_out    -- �o�͋敪
      ,ov_errbuf        => lv_errbuf           -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode       => lv_retcode          -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg        => lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode <> ov_retcode) THEN
      RAISE global_api_expt;
    END IF;
--
    -- �R���J�����g�p�����[�^�l�o��(���O)
    xxcff_common1_pkg.put_log_param(
       iv_which         => cv_file_type_log    -- �o�͋敪
      ,ov_errbuf        => lv_errbuf           -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode       => lv_retcode          -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg        => lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode <> ov_retcode) THEN
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    WHEN global_api_expt THEN                           --*** ���ʊ֐��R�����g ***
      -- *** �C�ӂŗ�O�������L�q���� ****
      ov_errmsg  := lv_errmsg;                                                  --# �C�� #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# �C�� #
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
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    iv_period_name  IN  VARCHAR2,     -- 1.��v���Ԗ�
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
    cv_prg_name   CONSTANT VARCHAR2(100) := 'submain';      -- �v���O������
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
    --*********************************************
    --***      MD.050�̃t���[�}��\��           ***
    --***      ����Ə������̌Ăяo�����s��     ***
    --*********************************************
--
    -- IN�p�����[�^(��v���Ԗ�)���O���[�o���ϐ��ɐݒ�
    gv_period_name := iv_period_name;
--
    -- ===============================
    -- �������� (A-1)
    -- ===============================
    init(
       lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- �v���t�@�C���l�擾 (A-2)
    -- ===============================
    get_profile_values(
       lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- ��v���ԃ`�F�b�N (A-3)
    -- ===============================
    chk_period(
       lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- =========================================
    -- ���s�����擾 (A-4)
    -- =========================================
    get_exec_date(
       lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- =========================================
    -- IFRS�䒠�o�^�f�[�^���o (A-5)
    -- =========================================
    get_ifrs_fa_retire_data(
       lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- =========================================
    -- IFRS�䒠�A�g�Z�b�g�X�V(A-6)
    -- =========================================
    upd_ifrs_sets(
       lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
  EXCEPTION
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
    errbuf         OUT VARCHAR2,      --   �G���[�E���b�Z�[�W  --# �Œ� #
    retcode        OUT VARCHAR2,      --   ���^�[���E�R�[�h    --# �Œ� #
    iv_period_name IN  VARCHAR2       --   1.��v���Ԗ�
  )
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
    cv_normal_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004'; -- ����I�����b�Z�[�W
    cv_warn_msg        CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005'; -- �x���I�����b�Z�[�W
    cv_error_msg       CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006'; -- �G���[�I���S���[���o�b�N
    cv_cnt_token       CONSTANT VARCHAR2(10)  := 'COUNT';            -- �������b�Z�[�W�p�g�[�N����
--
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
    -- �O���[�o���ϐ��̏�����
    gn_ifrs_fa_retire_target_cnt := 0;
    gn_ifrs_fa_retire_normal_cnt := 0;
    gn_ifrs_fa_retire_err_cnt    := 0;
    --
    -- ===============================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ===============================================
    submain(
       iv_period_name -- ��v���Ԗ�
      ,lv_errbuf      -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode     -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
  /**********************************************************************************
   * Description      : �I������(A-7)
   ***********************************************************************************/
    --�G���[�o��
    IF (lv_retcode = cv_status_error) THEN
      -- ���팏����0�ɐݒ�
      gn_ifrs_fa_retire_normal_cnt := cn_zero_0;
      -- �G���[������+1�X�V
      gn_ifrs_fa_retire_err_cnt := gn_ifrs_fa_retire_err_cnt + 1;
      --
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --�G���[���b�Z�[�W
      );
      -- �Ώی������J�E���g����Ă���ꍇ
      IF ( gn_ifrs_fa_retire_target_cnt > 0 ) THEN
        -- IFRS�䒠�����p�G���[�̌Œ莑�Y�䒠�����o�͂���
        gv_out_msg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff         -- XXCFF
                                                       ,cv_msg_019a05_m_014    -- IFRS�䒠�����p�G���[
                                                       ,cv_tkn_asset_number    -- �g�[�N��'ASSET_NUMBER'
                                                       ,g_ifrs_fa_retire_tab(gn_loop_cnt).asset_number)
                                                                               -- ���Y�ԍ�
                                                       ,1
                                                       ,2000);
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => gv_out_msg
        );
      END IF;
    -- �Ώی�����0���������ꍇ
    ELSIF ( gn_ifrs_fa_retire_target_cnt = cn_zero_0 ) THEN
      -- �X�e�[�^�X���x���ɂ���
      lv_retcode := cv_status_warn;
    END IF;
    --��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
--
    --===============================================================
    --IFRS�䒠�����p�����ɂ����錏���o��
    --===============================================================
    --IFRS�䒠�����p���b�Z�[�W�o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_cff
                    ,iv_name         => cv_msg_019a05_m_013
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --�Ώی����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_target_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_ifrs_fa_retire_target_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --���������o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_success_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_ifrs_fa_retire_normal_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --�G���[�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_error_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_ifrs_fa_retire_err_cnt)
                   );
    FND_FILE.PUT_LINE(
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
    FND_FILE.PUT_LINE(
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
END XXCFF019A05C;
/
