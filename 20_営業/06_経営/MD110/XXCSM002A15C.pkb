CREATE OR REPLACE PACKAGE BODY XXCSM002A15C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCSM002A15C(body)
 * Description      : ���i�v��w�b�_�e�[�u���A�y�я��i�v�斾�׃e�[�u�����Ώۗ\�Z�N�x��
 *                  : ���i�v��f�[�^�𒊏o���A���Y�V�X�e���ɘA�g���邽�߂�IF�e�[�u���Ƀf�[�^��
 *                  : �o�^���܂��B
 * MD.050           : MD050_CSM_002_A15_�N�ԏ��i�v�搶�Y�V�X�e��IF
 * Version          : 1.2
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   �������� (A-1)
 *  del_forecast_firstif   �̔��v��/����v��I/F�e�[�u�����O�폜����(A-3)
 *  get_compute_count      �P�ʊ��Z���� (A-4)
 *  insert_forecast_if     �N�ԏ��i�v��f�[�^�o�^ (A-5)
 *  submain                ���C�������v���V�[�W��
 *                           �N�ԏ��i�v��f�[�^�擾 (A-2)
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *                           �I������ (A-6)
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009-01-08    1.0   T.Tsukino        �V�K�쐬
 *  2009-02-24    1.1   M.Ohtsuki        [CT_063]  ����0�̃��R�[�h�̕s��̑Ή�
 *  2009-03-24    1.2   M.Ohtsuki        [T1_0117] �o�������Y�A�g�s��̑Ή�
 *  2009-03-24    1.2   M.Ohtsuki        [T1_0097] �p�[�W�����s��̑Ή�
 *
 *****************************************************************************************/
--
--#######################  �Œ�O���[�o���萔�錾�� START   #######################
--
  --�X�e�[�^�X�E�R�[�h
  cv_status_normal          CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal;             -- ����:0
  cv_status_warn            CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_warn;               -- �x��:1
  cv_status_error           CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_error;              -- �ُ�:2
  --WHO�J����
  cn_created_by             CONSTANT NUMBER      := fnd_global.user_id;                             -- CREATED_BY
  cd_creation_date          CONSTANT DATE        := SYSDATE;                                        -- CREATION_DATE
  cn_last_updated_by        CONSTANT NUMBER      := fnd_global.user_id;                             -- LAST_UPDATED_BY
  cd_last_update_date       CONSTANT DATE        := SYSDATE;                                        -- LAST_UPDATE_DATE
  cn_last_update_login      CONSTANT NUMBER      := fnd_global.login_id;                            -- LAST_UPDATE_LOGIN
  cn_request_id             CONSTANT NUMBER      := fnd_global.conc_request_id;                     -- REQUEST_ID
  cn_program_application_id CONSTANT NUMBER      := fnd_global.prog_appl_id;                        -- PROGRAM_APPLICATION_ID
  cn_program_id             CONSTANT NUMBER      := fnd_global.conc_program_id;                     -- PROGRAM_ID
  cd_program_update_date    CONSTANT DATE        := SYSDATE;                                        -- PROGRAM_UPDATE_DATE
--
  cv_msg_part               CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont               CONSTANT VARCHAR2(3) := '.';
--
  cv_msg_00111              CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00111';                           -- �z��O�G���[���b�Z�[�W
--
--################################  �Œ蕔 END   ##################################
--
--#######################  �Œ�O���[�o���ϐ��錾�� START   #######################
--
  gv_out_msg                VARCHAR2(2000);
  gv_sep_msg                VARCHAR2(2000);
  gv_exec_user              VARCHAR2(100);
  gv_conc_name              VARCHAR2(30);
  gv_conc_status            VARCHAR2(30);
  gn_target_cnt             NUMBER;                                                                 -- �Ώی���
  gn_normal_cnt             NUMBER;                                                                 -- ���팏��
  gn_error_cnt              NUMBER;                                                                 -- �G���[����
  gn_warn_cnt               NUMBER;                                                                 -- �X�L�b�v����
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
  cv_pkg_name             CONSTANT VARCHAR2(100)  := 'XXCSM002A15C';                                -- �p�b�P�[�W��
  cv_app_name             CONSTANT VARCHAR2(5)    := 'XXCSM';                                       -- �A�v���P�[�V�����Z�k��
  -- ���b�Z�[�W�R�[�h
  cv_xxccp_msg_90008      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90008';                             -- �R���J�����g���̓p�����[�^�Ȃ�
  cv_xxcsm_msg_00005      CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00005';                             -- �v���t�@�C���擾�G���[���b�Z�[�W
  cv_xxcsm_msg_00006      CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00006';                             -- �N�Ԕ̔��v��J�����_�[�����݃G���[���b�Z�[�W
  cv_xxcsm_msg_00004      CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00004';                             -- �\�Z�N�x�`�F�b�N�G���[
  cv_xxcsm_msg_10001      CONSTANT VARCHAR2(100) := 'APP-XXCSM1-10001';                             -- �擾�f�[�^0���G���[���b�Z�[�W
  cv_xxcsm_msg_10134      CONSTANT VARCHAR2(100) := 'APP-XXCSM1-10134';                             -- �̔��v��/����v��I/F�e�[�u�����b�N�G���[���b�Z�[�W
  cv_xxcsm_msg_10137      CONSTANT VARCHAR2(100) := 'APP-XXCSM1-10137';                             -- ���i�v�搔�ʎ擾�G���[���b�Z�[�W
--//+ADD END        2009/03/24   T1_0097 M.Ohtsuki
  cv_xxcsm_msg_10154      CONSTANT VARCHAR2(100) := 'APP-XXCSM1-10154';                             -- �̔��v��/����v��I/F�e�[�u�����b�N�G���[���b�Z�[�W(����)
--//+ADD END        2009/03/24   T1_0097 M.Ohtsuki
  --�v���t�@�C����
  cv_yearplan_calender    CONSTANT VARCHAR2(100) := 'XXCSM1_YEARPLAN_CALENDER';                     -- XXCSM:�N�Ԕ̔��v��J�����_�[��
  -- �g�[�N���R�[�h
  cv_tkn_prf_name         CONSTANT VARCHAR2(20) := 'PROF_NAME';                                     -- �v���t�@�C�����Z�b�g
  cv_tkn_item             CONSTANT VARCHAR2(20) := 'ITEM';                                          -- ���ږ��̃Z�b�g
  cv_tkn_count            CONSTANT VARCHAR2(20) := 'COUNT';                                         -- ��������
  cv_tkn_itemcd           CONSTANT VARCHAR2(20) := 'ITEM_CD';                                       -- ���i�R�[�h
  cv_tkn_kyotencd         CONSTANT VARCHAR2(20) := 'KYOTEN_CD';                                     -- ���_�R�[�h
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================  
  gd_process_date         DATE;                                                 -- �Ɩ����t�i�[�p
  gv_prf_calender         VARCHAR2(100);                                        -- �v���t�@�C��XXCSM:�N�Ԕ̔��v��J�����_�[��
  gn_active_year          NUMBER;                                               -- �Ώ۔N�x
--   
  /**********************************************************************************
   * Procedure Name   : init
   * Argument         : �Ȃ�
   * Description      : �������� (A-1)
   ***********************************************************************************/
  PROCEDURE init(
     ov_errbuf           OUT NOCOPY VARCHAR2                                    -- �G���[�E���b�Z�[�W
    ,ov_retcode          OUT NOCOPY VARCHAR2                                    -- ���^�[���E�R�[�h
    ,ov_errmsg           OUT NOCOPY VARCHAR2                                    -- ���[�U�[�E�G���[�E���b�Z�[�W
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name         CONSTANT VARCHAR2(100)   := 'init';                                         -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf           VARCHAR2(4000);                                                             -- �G���[�E���b�Z�[�W
    lv_retcode          VARCHAR2(1);                                                                -- ���^�[���E�R�[�h
    lv_errmsg           VARCHAR2(4000);                                                             -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_appl_short_name  CONSTANT VARCHAR2(10)  := 'XXCCP';                      -- �A�v���P�[�V�����Z�k��
    -- *** ���[�J���ϐ� ***
    lv_prm_msg          VARCHAR2(4000);                                         -- �R���J�����g���̓p�����[�^���b�Z�[�W�i�[�p
    ln_carender_cnt     NUMBER;                                                 -- �N�Ԕ̔��v��`�F�b�N�p
    ln_retcode          NUMBER;                                                 -- �N�Ԕ̔��v��J�����_�[�擾�֐�:STATUS
    lv_result           VARCHAR2(1);                                            -- �N�Ԕ̔��v��J�����_�[�擾�֐�:��������
    lv_msg              VARCHAR2(100);                                          -- 
    -- *** ���[�J����O ***
    getprofile_err_expt EXCEPTION;                                              -- �v���t�@�C���擾�G���[���b�Z�[�W
    calendar_check_expt EXCEPTION;                                              -- �N�Ԕ̔��v��J�����_�[�����݃G���[���b�Z�[�W
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
-- �Ɩ��^�p���̎擾
    gd_process_date := xxccp_common_pkg2.get_process_date;
--
    -- =====================================
    -- A-1: �@ ���̓p�����[�^���b�Z�[�W�o��
    -- =====================================
    -- �R���J�����g���̓p�����[�^���b�Z�[�W
    lv_prm_msg   := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_short_name                   --�A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_xxccp_msg_90008                     --���b�Z�[�W�R�[�h
                    );
    --���b�Z�[�W�o��
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => ''           || CHR(10) ||                                     -- ��s�̑}��
                 lv_prm_msg   || CHR(10) ||
                 ''                                                             -- ��s�̑}��
    );
    --���O�o��
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => ''           || CHR(10) ||                                     -- ��s�̑}��
                 lv_prm_msg   || CHR(10) ||
                 ''                                                             -- ��s�̑}��
    );
    -- ===========================
    -- A-1: �A �v���t�@�C���l�擾
    -- ===========================
    -- XXCSM:�N�Ԕ̔��v��J�����_�[��
    gv_prf_calender :=  FND_PROFILE.VALUE(cv_yearplan_calender);
    -- �v���t�@�C���l�擾�Ɏ��s�����ꍇ
    IF (gv_prf_calender IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                            --�A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_xxcsm_msg_00005                       --���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_prf_name                        --�g�[�N���R�[�h1
                     ,iv_token_value1 => cv_yearplan_calender                   --�g�[�N���l1
                   );
      lv_errbuf := lv_errmsg;
      RAISE getprofile_err_expt;
    END IF;
    -- ===========================================
    -- A-1: �C �N�Ԕ̔��v��J�����_�[���݃`�F�b�N
    -- ===========================================
    BEGIN
      SELECT  COUNT(1)
      INTO    ln_carender_cnt
      FROM    fnd_flex_value_sets  ffv                                      -- �l�Z�b�g�w�b�_
      WHERE   ffv.flex_value_set_name = gv_prf_calender;                    -- �N�Ԕ̔��J�����_�[��
      IF (ln_carender_cnt = 0) THEN                                         -- �J�����_�[���݌�����0���̏ꍇ
        lv_errmsg := xxccp_common_pkg.get_msg(
                                              iv_application  => cv_app_name
                                             ,iv_name         => cv_xxcsm_msg_00006
                                             ,iv_token_name1  => cv_tkn_item
                                             ,iv_token_value1 => gv_prf_calender
                     );
        lv_errbuf := lv_errmsg;
        RAISE calendar_check_expt;
      END IF;  
    END;
    -- ===========================================
    -- A-1: �D �N�Ԕ̔��v��J�����_�[�L���N�x�擾
    -- ===========================================
    -- ���ʊ֐�:�N�Ԕ̔��v��J�����_�[�擾�֐��FGET_YEARPLAN_CALENDER
    xxcsm_common_pkg.get_yearplan_calender(
                                           id_comparison_date  => cd_creation_date  -- ���t
                                          ,ov_status           => lv_result         -- ��������(0�F�L���N�x��1�̏ꍇ(����)
                                                                                    --          1�F�L���N�x�������܂���0�̏ꍇ(�ُ�)
                                          ,on_active_year      => gn_active_year    -- �Ώ۔N�x�i�������ʂ�0�̏ꍇ�̂݃Z�b�g�j
                                          ,ov_retcode          => ln_retcode
                                          ,ov_errbuf           => lv_errbuf
                                          ,ov_errmsg           => lv_errmsg
    );
    IF (ln_retcode <> cv_status_normal) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                                            iv_application  => cv_app_name
                                           ,iv_name         => cv_xxcsm_msg_00004
                                           ,iv_token_name1  => cv_tkn_item
                                           ,iv_token_value1 => gv_prf_calender
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
      END IF; 
--
  EXCEPTION
    -- *** �v���t�@�C���擾��O�n���h�� ***
    WHEN getprofile_err_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      ov_retcode := cv_status_error;
    -- *** �N�Ԕ̔��v��J�����_�[�����ݗ�O�n���h�� ***
    WHEN calendar_check_expt THEN
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
--//+ADD START     2009/03/24   T1_0097 M.Ohtsuki
  /**********************************************************************************
   * Procedure Name   : del_existing_data
   * Description      : �����f�[�^�폜����
   ***********************************************************************************/
  PROCEDURE del_existing_data(           
     ov_errbuf           OUT NOCOPY VARCHAR2                                                        -- �G���[�E���b�Z�[�W
    ,ov_retcode          OUT NOCOPY VARCHAR2                                                        -- ���^�[���E�R�[�h
    ,ov_errmsg           OUT NOCOPY VARCHAR2                                                        -- ���[�U�[�E�G���[�E���b�Z�[�W
    )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name          CONSTANT VARCHAR2(100)   := 'del_existing_data';                           -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf            VARCHAR2(4000);                                                            -- �G���[�E���b�Z�[�W
    lv_retcode           VARCHAR2(1);                                                               -- ���^�[���E�R�[�h
    lv_errmsg            VARCHAR2(4000);                                                            -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_forecast_designator  CONSTANT VARCHAR2(2)   := '05';                                         -- Forecast���� �Œ�l�F'05�f (�̔��v��)
    cv_item_kbn             CONSTANT VARCHAR2(1)   := '1';                                          -- ���i�敪:'1'
    -- *** ���[�J���E�J�[�\�� ***
    CURSOR del_existing_data_cur
    IS
      SELECT ROWID
      FROM   xxinv_mrp_forecast_interface xxmfi
      WHERE  xxmfi.forecast_designator = cv_forecast_designator                                     -- �Œ�l:'5'�i�̔��v��j
      AND    NOT EXISTS 
              (SELECT 'X'
               FROM   xxcsm_item_plan_headers  xxiph
                     ,xxcsm_item_plan_lines    xxipl
               WHERE  xxiph.item_plan_header_id = xxipl.item_plan_header_id
               AND    xxiph.plan_year           = gn_active_year                                    -- �Ώ۔N�x
               AND    xxipl.item_kbn            = cv_item_kbn                                       -- �Œ�l:'1'�i���i�P�i�j
               AND    xxipl.item_no             = xxmfi.item_code                                   -- ���i�R�[�h
               AND    xxiph.location_cd         = xxmfi.base_code                                   -- ���_�R�[�h
               AND    TRUNC(TO_DATE(xxipl.year_month,'YYYYMM'), 'MONTH') = xxmfi.forecast_date      -- �J�n���t
               AND    TRUNC(TO_DATE(xxipl.year_month,'YYYYMM'), 'MONTH') = xxmfi.forecast_end_date  -- �I�����t
               )
      FOR UPDATE NOWAIT
      ;
    -- *** ���[�J����O ***
    rock_err_expt        EXCEPTION; 
--
  BEGIN
--
--
    -- ���b�N�̎擾
    BEGIN
      OPEN  del_existing_data_cur;
      CLOSE del_existing_data_cur;
    EXCEPTION
      WHEN OTHERS THEN
        RAISE rock_err_expt;
    END;
--
    --�Ώۃf�[�^�폜����
    DELETE FROM xxinv_mrp_forecast_interface  xxmfi                                                 -- �̔��v��/����v��I/F�e�[�u��
    WHERE  xxmfi.forecast_designator    = cv_forecast_designator                                    -- �Œ�l:'5'�i�̔��v��j
    AND    xxmfi.program_application_id = cn_program_application_id                                 -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
    AND    xxmfi.program_id             = cn_program_id                                             -- �R���J�����g�E�v���O����ID
    AND    NOT  EXISTS
               (SELECT 'X'
                FROM   xxcsm_item_plan_headers  xxiph                                               -- ���i�v��p�̔����уw�b�_
                      ,xxcsm_item_plan_lines    xxipl                                               -- ���i�v��p�̔����і���
                WHERE  xxiph.item_plan_header_id = xxipl.item_plan_header_id                        -- �w�b�_ID�R�t��
                AND    xxiph.plan_year           = gn_active_year                                   -- �Ώ۔N�x
                AND    xxipl.item_kbn            = cv_item_kbn                                      -- �Œ�l:'1'�i���i�P�i�j
                AND    xxipl.item_no             = xxmfi.item_code                                  -- ���i�R�[�h
                AND    xxiph.location_cd         = xxmfi.base_code                                  -- ���_�R�[�h
                AND    TRUNC(TO_DATE(xxipl.year_month,'YYYYMM'), 'MONTH') = xxmfi.forecast_date     -- �J�n���t
                AND    TRUNC(TO_DATE(xxipl.year_month,'YYYYMM'), 'MONTH') = xxmfi.forecast_end_date -- �I�����t
               );
  EXCEPTION
    -- *** �̔��v��/����v��I/F�e�[�u�����b�N��O�n���h�� ***
    WHEN rock_err_expt THEN
      -- �G���[���b�Z�[�W�擾
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                                                -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_xxcsm_msg_10154                                         -- ���b�Z�[�W�R�[�h
                   );
      lv_errbuf := lv_errmsg;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      ov_retcode := cv_status_error;                                                                -- �X�e�[�^�X:�G���[
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,4000);
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END del_existing_data;
--
--//+ADD END        2009/03/24   T1_0097 M.Ohtsuki
  /**********************************************************************************
   * Procedure Name   : del_forecast_firstif
   * Argument         : iv_kyoten_cd   [���_�R�[�h]
   * Description      : �̔��v��/����v��I/F�e�[�u�����O�폜����(A-3)
   ***********************************************************************************/
  PROCEDURE del_forecast_firstif(           
     iv_kyoten_cd        IN  VARCHAR2                                           -- ���_�R�[�h
    ,ov_errbuf           OUT NOCOPY VARCHAR2                                    -- �G���[�E���b�Z�[�W
    ,ov_retcode          OUT NOCOPY VARCHAR2                                    -- ���^�[���E�R�[�h
    ,ov_errmsg           OUT NOCOPY VARCHAR2                                    -- ���[�U�[�E�G���[�E���b�Z�[�W
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name          CONSTANT VARCHAR2(100)   := 'del_forecast_firstif';    -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf            VARCHAR2(4000);                                        -- �G���[�E���b�Z�[�W
    lv_retcode           VARCHAR2(1);                                           -- ���^�[���E�R�[�h
    lv_errmsg            VARCHAR2(4000);                                        -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--//+UPD START 2009/02/24   CT063 M.Ohtsuki
--    cv_forecast_designator  CONSTANT VARCHAR2(1)   := '5';                      -- Forecast���� �Œ�l�F�f5�f (�̔��v��)
    cv_forecast_designator  CONSTANT VARCHAR2(2)   := '05';                      -- Forecast���� �Œ�l�F'05�f (�̔��v��)
--//+UPD END   2009/02/24   CT063 M.Ohtsuki
    cv_item_kbn             CONSTANT VARCHAR2(1)   := '1';                      -- ���i�敪:'1'
    -- *** ���[�J���E�J�[�\�� ***
    CURSOR del_forecast_firstif_cur
    IS    
      SELECT ROWID
      FROM   xxinv_mrp_forecast_interface xxmfi
      WHERE  xxmfi.forecast_designator = cv_forecast_designator     -- �Œ�l:'5'�i�̔��v��j
      AND EXISTS (SELECT 'X'
                  FROM   xxcsm_item_plan_headers  xxiph
                        ,xxcsm_item_plan_lines    xxipl
                  WHERE  xxiph.item_plan_header_id = xxipl.item_plan_header_id
                  AND    xxipl.item_kbn = cv_item_kbn                               -- �Œ�l:'1'�i���i�P�i�j
                  AND    TRUNC(TO_DATE(xxipl.year_month,'YYYYMM'), 'MONTH') = xxmfi.forecast_date        --�J�n���t
                  AND    TRUNC(TO_DATE(xxipl.year_month,'YYYYMM'), 'MONTH') = xxmfi.forecast_end_date    --�I�����t
                  AND    xxipl.item_no = xxmfi.item_code                            -- ���i�R�[�h
                  AND    xxiph.location_cd = iv_kyoten_cd                           -- ���_�R�[�h
                  AND    xxiph.location_cd = xxmfi.base_code                        -- ���_�R�[�h
                 )
      FOR UPDATE NOWAIT
      ;
    -- *** ���[�J����O ***
    rock_err_expt        EXCEPTION; 
--
    PRAGMA EXCEPTION_INIT(rock_err_expt,-54);
--
  BEGIN
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ���b�N�̎擾
    OPEN del_forecast_firstif_cur;
    CLOSE del_forecast_firstif_cur;
    --�Ώۃf�[�^�폜����
    DELETE FROM xxinv_mrp_forecast_interface  xxmfi               -- �̔��v��/����v��I/F�e�[�u��
    WHERE  xxmfi.forecast_designator = cv_forecast_designator     -- �Œ�l:'5'�i�̔��v��j
--//+ADD START 2009/02/24   CT063 M.Ohtsuki
    AND    xxmfi.program_application_id = cn_program_application_id  -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
    AND    xxmfi.program_id             = cn_program_id              -- �R���J�����g�E�v���O����ID
--//+ADD END   2009/02/24   CT063 M.Ohtsuki                                                            
    AND EXISTS (SELECT 'X'
                FROM   xxcsm_item_plan_headers  xxiph
                      ,xxcsm_item_plan_lines    xxipl
                WHERE  xxiph.item_plan_header_id = xxipl.item_plan_header_id
                AND    xxipl.item_kbn = cv_item_kbn                               -- �Œ�l:'1'�i���i�P�i�j
                AND    TRUNC(TO_DATE(xxipl.year_month,'YYYYMM'), 'MONTH') = xxmfi.forecast_date        --�J�n���t
                AND    TRUNC(TO_DATE(xxipl.year_month,'YYYYMM'), 'MONTH') = xxmfi.forecast_end_date    --�I�����t
                AND    xxipl.item_no = xxmfi.item_code                            -- ���i�R�[�h
                AND    xxiph.location_cd = iv_kyoten_cd                           -- ���_�R�[�h
                AND    xxiph.location_cd = xxmfi.base_code                        -- ���_�R�[�h
               )
    ;
  EXCEPTION
    -- *** �̔��v��/����v��I/F�e�[�u�����b�N��O�n���h�� ***
    WHEN rock_err_expt THEN
      -- �G���[���b�Z�[�W�擾
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                            -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_xxcsm_msg_10134                     -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_kyotencd                        -- �g�[�N���R�[�h1
                     ,iv_token_value1 => iv_kyoten_cd                           -- �g�[�N���l1
                   );
      lv_errbuf := lv_errmsg;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      ov_retcode := cv_status_warn;   -- �X�e�[�^�X:�x��
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,4000);
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END del_forecast_firstif;
--
  /**********************************************************************************
   * Procedure Name   : get_compute_count
   * Argument         : iv_item_cd   [���i�R�[�h]
   *                  : in_amount    [����]
   * Description      : �P�ʊ��Z�����iA-4�j
   ***********************************************************************************/
--//+DEL START 2009/03/24   T1_0117 M.Ohtsuki
/*
  PROCEDURE get_compute_count(
     iv_item_cd          IN  VARCHAR2                                           -- ���i�R�[�h
    ,in_amount           IN  NUMBER                                             -- ����
    ,on_case_count       OUT NUMBER                                             -- �P�[�X����
    ,on_bara_count       OUT NUMBER                                             -- �o������ 
    ,ov_errbuf           OUT NOCOPY VARCHAR2                                    -- �G���[�E���b�Z�[�W
    ,ov_retcode          OUT NOCOPY VARCHAR2                                    -- ���^�[���E�R�[�h
    ,ov_errmsg           OUT NOCOPY VARCHAR2                                    -- ���[�U�[�E�G���[�E���b�Z�[�W
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name          CONSTANT VARCHAR2(100)   := 'get_compute_count';                           -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf            VARCHAR2(4000);                                                            -- �G���[�E���b�Z�[�W
    lv_retcode           VARCHAR2(1);                                                               -- ���^�[���E�R�[�h
    lv_errmsg            VARCHAR2(4000);                                                            -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
--
    -- *** ���[�J���ϐ� ***
    lv_insert_count      VARCHAR2(100);                                          -- �����i�[�p
    -- *** ���[�J���E�J�[�\�� ***
    CURSOR get_compute_cur(
      iv_item_cd       VARCHAR2
    )
    IS    
      SELECT iimb.attribute11          insert_count   -- ����
      FROM   ic_item_mst_b             iimb           -- OPM�i�ڃ}�X�^
            ,mtl_system_items_b        msib           -- �i�ڃ}�X�^
      WHERE  iimb.item_no = iv_item_cd                -- A-2�Ŏ擾�������i�R�[�h
      AND    iimb.item_no = msib.segment1             -- OPM�i�ڃ}�X�^�D�i�ڃR�[�h �� �i�ڃ}�X�^�D�i�ڃR�[�h
      AND    ROWNUM <= 1
      ;
    -- *** ���[�J���E���R�[�h ***
    get_compute_rec    get_compute_cur%ROWTYPE;    
--
--
  BEGIN
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- �J�[�\���I�[�v��
    OPEN get_compute_cur(iv_item_cd);
      FETCH get_compute_cur INTO get_compute_rec;
    -- �J�[�\���N���[�Y
    CLOSE get_compute_cur;    
    -- =============================
    -- A-3: �A�o�̓p�����[�^�ݒ�
    -- =============================
    -- �@�P�[�X�������擾�ł����ꍇ
    IF (in_amount IS NOT NULL) AND
       (get_compute_rec.insert_count IS NOT NULL) AND
       (get_compute_rec.insert_count <> 0)
    THEN
      on_case_count := TRUNC(in_amount/TO_NUMBER(get_compute_rec.insert_count));
      on_bara_count := MOD(in_amount,TO_NUMBER(get_compute_rec.insert_count));
    -- �A�P�[�X�������擾�ł��Ȃ������ꍇ
    ELSE
      on_case_count := 0;
      on_bara_count := in_amount;   -- ���ʂ�S�ăo�����Ƃ���
    END IF;   
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,4000);
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_compute_count;
*/
--//+DEL END   2009/03/24   T1_0117 M.Ohtsuki
  /**********************************************************************************
   * Procedure Name   : insert_forecast_if
   * Argument         : iv_kyoten_cd    [���_�R�[�h]
   *                  : iv_item_cd      [���i�R�[�h]
   *                  : in_year_month   [�N��]
   *                  : in_case_count   [�P�[�X����]
   *                  : in_bara_count   [�o������]
   *                  : in_sales_budget [������z]
   * Description      : �N�ԏ��i�v��f�[�^�o�^�iA-5�j
   ***********************************************************************************/
  PROCEDURE insert_forecast_if(
     iv_kyoten_cd        IN  VARCHAR2                                           -- ���_�R�[�h
    ,iv_item_cd          IN  VARCHAR2                                           -- ���i�R�[�h
    ,in_year_month       IN  NUMBER                                             -- �N��
--//+DEL START 2009/03/24  T1_0117 M.Ohtsuki
--    ,in_case_count       IN  NUMBER                                             -- �P�[�X����
--//+DEL END   2009/03/24  T1_0117 M.Ohtsuki
    ,in_bara_count       IN  NUMBER                                             -- �o������
    ,in_sales_budget     IN  NUMBER                                             -- ������z
    ,ov_errbuf           OUT NOCOPY VARCHAR2                                    -- �G���[�E���b�Z�[�W
    ,ov_retcode          OUT NOCOPY VARCHAR2                                    -- ���^�[���E�R�[�h
    ,ov_errmsg           OUT NOCOPY VARCHAR2                                    -- ���[�U�[�E�G���[�E���b�Z�[�W
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name          CONSTANT VARCHAR2(100)   := 'insert_forecast_if';                              -- �v���O������

--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf            VARCHAR2(4000);                                                            -- �G���[�E���b�Z�[�W
    lv_retcode           VARCHAR2(1);                                                               -- ���^�[���E�R�[�h
    lv_errmsg            VARCHAR2(4000);                                                            -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--//+ADD START 2009/02/24   CT063 M.Ohtsuki
--    cn_forecast          CONSTANT VARCHAR2(1)     := '5';                       -- �Œ�l:'5'�i�̔��v��j
      cn_forecast          CONSTANT VARCHAR2(2)     := '05';                       -- �Œ�l:'5'�i�̔��v��j
--//+ADD START 2009/02/24   CT063 M.Ohtsuki
--
  BEGIN
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
  --�̔��v��/����v��I/F�e�[�u���o�^����
    INSERT INTO xxinv_mrp_forecast_interface(
       forecast_if_id
      ,forecast_designator
      ,base_code
      ,item_code
      ,forecast_date
      ,forecast_end_date
      ,case_quantity
      ,indivi_quantity
      ,amount
      ,created_by
      ,creation_date
      ,last_updated_by
      ,last_update_date
      ,last_update_login
      ,request_id
      ,program_application_id
      ,program_id
      ,program_update_date
    )VALUES(
       XXINV_MRP_FRCST_IF_S1.NEXTVAL
      ,cn_forecast
      ,iv_kyoten_cd
      ,iv_item_cd
      ,TRUNC(TO_DATE(in_year_month,'YYYYMM'), 'MONTH')
      ,TRUNC(TO_DATE(in_year_month,'YYYYMM'), 'MONTH')
--//+UPD  START 2009/03/24  T1_0117 M.Ohtsuki
--      ,in_case_count
--��������������������������������������������������
      ,0
--//+UPD  END   2009/03/24  T1_0117  M.Ohtsuki
      ,in_bara_count
      ,in_sales_budget
      ,cn_created_by
      ,cd_creation_date
      ,cn_last_updated_by
      ,cd_last_update_date
      ,cn_last_update_login
      ,cn_request_id
      ,cn_program_application_id
      ,cn_program_id
      ,cd_program_update_date
    );
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,4000);
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END insert_forecast_if;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   *                    �N�ԏ��i�v��f�[�^�擾 (A-2)
   ***********************************************************************************/
  PROCEDURE submain(
     ov_errbuf         OUT NOCOPY VARCHAR2                                      -- �G���[�E���b�Z�[�W
    ,ov_retcode        OUT NOCOPY VARCHAR2                                      -- ���^�[���E�R�[�h
    ,ov_errmsg         OUT NOCOPY VARCHAR2                                      -- ���[�U�[�E�G���[�E���b�Z�[�W
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name       CONSTANT VARCHAR2(100) := 'submain';                      -- �v���O������
    cv_year_bdgt_kbn  CONSTANT VARCHAR2(1)   := '0';                            -- �N�ԌQ�\�Z�敪�e0�f(�e���P�ʗ\�Z)
    cv_item_kbn       CONSTANT VARCHAR2(1)   := '1';                            -- ���i�敪 �� �e1�f(���i�P�i)
    cn_sts_normal     CONSTANT  NUMBER       :=  1;                              -- ��
    cn_sts_error      CONSTANT  NUMBER       :=  2;                              -- �L
--
--#######################  �Œ胍�[�J���ϐ��錾�� START   ######################
--
    lv_errbuf         VARCHAR2(4000);                                           -- �G���[�E���b�Z�[�W
    lv_retcode        VARCHAR2(1);                                              -- ���^�[���E�R�[�h
    lv_errmsg         VARCHAR2(4000);                                           -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���ϐ� ***
--//+DEL START 2009/03/24  T1_0117 M.Ohtsuki
--    ln_case_count     NUMBER;
--    ln_bara_count     NUMBER;
--//+DEL END   2009/03/24  T1_0117 M.Ohtsuki
    lt_kyoten_cd      XXCSM_ITEM_PLAN_HEADERS.LOCATION_CD%TYPE;
    ln_sts_flg        NUMBER;
    ln_location_count NUMBER;

    -- *** ���[�J���E�J�[�\�� ***  �N�ԏ��i�v��f�[�^�擾
    CURSOR year_item_date_cur
    IS
      SELECT xipl.year_month       nengetsu                                     -- �N��
            ,xiph.location_cd      kyoten_cd                                    -- ���_�R�[�h
            ,xipl.item_no          syouhin_cd                                   -- ���i�R�[�h
            ,xipl.amount           suryo                                        -- ����
            ,xipl.sales_budget     urikin                                       -- ������z
      FROM   xxcsm_item_plan_headers xiph                                       -- ���i�v��w�b�_�e�[�u��
            ,xxcsm_item_plan_lines xipl                                         -- ���i�v�斾�׃e�[�u��
      WHERE  xiph.item_plan_header_id = xipl.item_plan_header_id                 -- �w�b�_ID�Ŋ֘A�t��
        AND  xiph.plan_year = gn_active_year                                     -- ���i�v��w�b�_�e�[�u���D�\�Z�N�x �� A-1�Ŏ擾�����N�x
        AND  xipl.year_bdgt_kbn = cv_year_bdgt_kbn                               -- ���i�v�斾�׃e�[�u���D�N�ԌQ�\�Z�敪 ���e0�f(�e���P�ʗ\�Z)
        AND  xipl.item_kbn = cv_item_kbn                                         -- ���i�v�斾�׃e�[�u���D���i�敪 �� �e1�f(���i�P�i)
--//+ADD START 2009/02/24   CT063 M.Ohtsuki
        AND  xipl.amount <> 0                                                    -- ���i�v�斾�׃e�[�u��. ���� <> 0
--//+ADD END   2009/02/24   CT063 M.Ohtsuki
        AND  NOT EXISTS (SELECT 'X'
                         FROM   fnd_lookup_values         flv                      --�N�C�b�N�R�[�h�l
                               ,mtl_categories_b          mcb                      --�i�ڃJ�e�S��
                               ,mtl_category_sets_b       mcsb                     --�i�ڃJ�e�S��
                               ,fnd_id_flex_structures    fifs                     --�L�[�t���b�N�X�t�B�[���h
                               ,gmi_item_categories       gic                      --�i�ڃJ�e�S������
                               ,ic_item_mst_b             iimb                     --OPM�i�ڃ}�X�^
                         WHERE  flv.lookup_type = 'XXCSM1_ITEM_KBN'                --�R�[�h�^�C�v:�i�ڋ敪�i"XXCSM1_ITEM_KBN�h�j
                         AND    flv.language = USERENV('LANG')                     --����
                         AND    NVL(flv.start_date_active,gd_process_date) <= gd_process_date    --�L���J�n��<=�Ɩ����t
                         AND    NVL(flv.end_date_active,gd_process_date) >= gd_process_date      --�L���I����>=�Ɩ����t
                         AND    NVL(flv.enabled_flag,'Y') = 'Y'
                         AND    flv.lookup_code = mcb.segment1                     --�i�ڋ敪�̒l
                         AND    mcsb.structure_id = mcb.structure_id
                         AND    mcb.enabled_flag = 'Y'
                         AND    NVL(mcb.disable_date,gd_process_date) <= gd_process_date
                         AND    fifs.id_flex_structure_code = 'XXCA_ITEM_CLASS'    -- �L�[�t���b�N�X�t�B�[���h�F�i�ڋ敪
                         AND    fifs.application_id = 401                          -- Inventory
                         AND    fifs.id_flex_code = 'MCAT'                         -- �i�ڃJ�e�S���̃R�[�h
                         AND    fifs.id_flex_num = mcsb.structure_id
                         AND    iimb.item_id = gic.item_id
                         AND    gic.category_id = mcb.category_id
                         AND    gic.category_set_id = mcsb.category_set_id
                         AND    iimb.item_no = xipl.item_no                        -- �i�ڃ}�X�^�Ə��i�v�斾�׃e�[�u���̏��i�R�[�h���֘A�t��
                         )
      ORDER BY xiph.location_cd
              ,xipl.year_month
              ,xipl.item_no
      ;
    -- *** ���[�J���E���R�[�h ***
    year_item_date_rec    year_item_date_cur%ROWTYPE;
    -- *** ���[�J����O ***
    global_skip_expt    EXCEPTION;
--
  BEGIN
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    --�O���[�o���ϐ��̏�����
    gn_target_cnt  := 0;
    gn_normal_cnt  := 0;
    gn_error_cnt   := 0;
    gn_warn_cnt    := 0;
    ln_location_count := 0;
--
    -- ======================================
    -- A-1.��������
    -- ======================================
    init(
       ov_errbuf       => lv_errbuf                                             -- �G���[�E���b�Z�[�W
      ,ov_retcode      => lv_retcode                                            -- ���^�[���E�R�[�h
      ,ov_errmsg       => lv_errmsg                                             -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
--
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
--//+ADD START  2009/03/24  T1_0097 M.Ohtsuki
    -- ======================================
    -- �����f�[�^�폜����
    -- ======================================
    del_existing_data(
       ov_errbuf       => lv_errbuf                                             -- �G���[�E���b�Z�[�W
      ,ov_retcode      => lv_retcode                                            -- ���^�[���E�R�[�h
      ,ov_errmsg       => lv_errmsg                                             -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
--
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
--//+ADD END    2009/03/24  T1_0097 M.Ohtsuki
    -- ======================================
    -- ���[�J���E�J�[�\���I�[�v��
    -- ======================================
    OPEN year_item_date_cur;
    <<year_item_date_loop>>
    LOOP
      FETCH year_item_date_cur INTO year_item_date_rec;
      EXIT WHEN year_item_date_cur%NOTFOUND;
      BEGIN
        -- ==========================
        -- �L�[�u���C�N
        -- ==========================
        IF (year_item_date_rec.kyoten_cd = lt_kyoten_cd) THEN
          NULL;
        ELSE
          -- �L�[�u���C�N���̋��_������Z�߂ăJ�E���g�A�b�v����B
          IF (ln_sts_flg = cn_sts_normal) THEN
            gn_normal_cnt := gn_normal_cnt + ln_location_count;
          ELSIF (ln_sts_flg = cn_sts_error) THEN
            --�G���[�����̃J�E���g
            gn_error_cnt := gn_error_cnt + ln_location_count;
          ELSE 
            NULL;
          END IF;
          --���_�����̃N���A�G
          ln_location_count := 0;
          --�X�L�b�v�t���O�̃N���A
          ln_sts_flg       :=  cn_sts_normal;
          --���_�P�ʂŃZ�[�u�|�C���g
          SAVEPOINT item_date_sv;
          -- ==========================================
          -- �̔��v��/����v��I/F�e�[�u�����O�폜����
          -- ==========================================
          del_forecast_firstif(
             iv_kyoten_cd    =>   year_item_date_rec.kyoten_cd
            ,ov_errbuf       =>   lv_errbuf                                          -- �G���[�E���b�Z�[�W
            ,ov_retcode      =>   lv_retcode                                         -- ���^�[���E�R�[�h
            ,ov_errmsg       =>   lv_errmsg                                          -- ���[�U�[�E�G���[�E���b�Z�[�W
          );
          -- Oracle�G���[�Ȃ�΁A�����𒆎~����B�i�X�e�[�^�X�̓G���[�j
          IF (lv_retcode = cv_status_error) THEN
            RAISE global_api_expt;
          -- �x��(���b�N�擾�G���[)�Ȃ�΁A���_�P�ʂŏ������X�L�b�v����B�i�X�e�[�^�X�͌x���j
          ELSIF (lv_retcode = cv_status_warn) THEN
            RAISE global_skip_expt;
          END IF;
        END IF;
--
        --���_�ŃG���[���������Ă���ꍇ�A���̋��_�f�[�^�̓X�L�b�v������B
        IF (ln_sts_flg = cn_sts_error) THEN
          RAISE global_skip_expt;
        END IF;
--
        -- ���ʂ�NULL�������ꍇ�A����0�̏ꍇ�A
        -- ��̒P�ʊ��Z�����̃P�[�X���̏��Z�ɂāANULL����0�ŏ��Z���s�����ƂɂȂ�B
        -- ���̃G���[��h�����߁Aglobal_skip_expt�Ƃ��Čx�����グ��B
        IF (year_item_date_rec.suryo IS NULL)
          OR (year_item_date_rec.suryo = 0)
        THEN
          lv_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                              --�A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_xxcsm_msg_10137                       --���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_itemcd                            --�g�[�N���R�[�h1
                       ,iv_token_value1 => year_item_date_rec.syouhin_cd            --�g�[�N���l1
                       ,iv_token_name2  => cv_tkn_kyotencd                          --�g�[�N���R�[�h2
                       ,iv_token_value2 => year_item_date_rec.kyoten_cd             --�g�[�N���l2                       
                       );
          lv_errbuf := lv_errmsg;
          RAISE global_skip_expt;
        END IF;
        -- ======================================
        -- A-3.�P�ʊ��Z����
        -- ======================================
--//+DEL START 2009/03/24  T1_0117 M.Ohtsuki
/*
        get_compute_count(
           iv_item_cd      => year_item_date_rec.syouhin_cd                        -- ���i�R�[�h
          ,in_amount       => year_item_date_rec.suryo                             -- ����(���ʂ͏����_��1�܂Ŏ���)
          ,on_case_count   => ln_case_count
          ,on_bara_count   => ln_bara_count
          ,ov_errbuf       => lv_errbuf                                            -- �G���[�E���b�Z�[�W
          ,ov_retcode      => lv_retcode                                           -- ���^�[���E�R�[�h
          ,ov_errmsg       => lv_errmsg                                            -- ���[�U�[�E�G���[�E���b�Z�[�W
        );
        -- �G���[�Ȃ�΁A�������X�L�b�v����B
        IF (lv_retcode <> cv_status_normal) THEN
          RAISE global_api_expt;
        END IF;
*/
--//+DEL END     2009/03/24  T1_0117 M.Ohtsuki
        -- ======================================
        -- A-5.�N�ԏ��i�v��f�[�^�o�^
        -- ======================================
        insert_forecast_if(
           iv_kyoten_cd    => year_item_date_rec.kyoten_cd                        -- ���_�R�[�h
          ,iv_item_cd      => year_item_date_rec.syouhin_cd                       -- ���i�R�[�h
          ,in_year_month   => year_item_date_rec.nengetsu                         -- �Ώ۔N��
--//+UPD START 2009/03/24   T1_0117 M.Ohtsuki
--          ,in_case_count   => ln_case_count                                       -- �P�[�X����
--          ,in_bara_count   => ln_bara_count                                       -- �o������
--��������������������������������������������������������������������������������������������������
          ,in_bara_count   => year_item_date_rec.suryo                            -- �o������          
--//+UPD END   2009/03/24   T1_0117 M.Ohtsuki
          ,in_sales_budget => year_item_date_rec.urikin                           -- ������z
          ,ov_errbuf       => lv_errbuf                                           -- �G���[�E���b�Z�[�W
          ,ov_retcode      => lv_retcode                                          -- ���^�[���E�R�[�h
          ,ov_errmsg       => lv_errmsg                                           -- ���[�U�[�E�G���[�E���b�Z�[�W
        );
        -- �G���[�Ȃ�΁A�������X�L�b�v����B
        IF (lv_retcode <> cv_status_normal) THEN
          RAISE global_api_expt;
        END IF;
        -- ���_�R�[�h�̊i�[
        lt_kyoten_cd := year_item_date_rec.kyoten_cd;
      EXCEPTION
        WHEN global_skip_expt THEN
          --���_�P�ʂŃG���[��������������̃f�[�^�̂݃��b�Z�[�W�o��
          IF (ln_sts_flg = cn_sts_normal) THEN
            -- ���_�R�[�h�̊i�[
            lt_kyoten_cd := year_item_date_rec.kyoten_cd;
            ln_sts_flg       :=  cn_sts_error;
            -- ���[���o�b�N
            ROLLBACK TO item_date_sv;
            lv_errbuf := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
            --�G���[�o��
            fnd_file.put_line(
               which  => FND_FILE.OUTPUT
              ,buff   => lv_errmsg                                                    -- ���[�U�[�E�G���[���b�Z�[�W
            );
            fnd_file.put_line(
               which  => FND_FILE.LOG
              ,buff   => lv_errbuf                                                    -- �G���[���b�Z�[�W
            );
            ov_retcode := cv_status_warn;
          END IF;
      END;
      ln_location_count := ln_location_count + 1;
    END LOOP year_item_date_loop;
--
    -- �����Ώی����i�[
    gn_target_cnt := year_item_date_cur%ROWCOUNT;
--
    -- �ŏI���_������Z�߂ăJ�E���g�A�b�v����B
    IF (ln_sts_flg = cn_sts_normal) THEN
      gn_normal_cnt := gn_normal_cnt +  ln_location_count;
    ELSE
      gn_error_cnt := gn_error_cnt + ln_location_count;
    END IF;
--
    -- �J�[�\���N���[�Y
    CLOSE year_item_date_cur;
    -- �����Ώی�����0���̏ꍇ
    IF (gn_target_cnt = 0) THEN
      -- 0�����b�Z�[�W�擾
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name                                                 --�A�v���P�[�V�����Z�k��
                    ,iv_name         => cv_xxcsm_msg_10001                                            --���b�Z�[�W�R�[�h
                   );
      lv_errbuf := lv_errmsg;
      --���b�Z�[�W�o��
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg                                                    -- ���[�U�[�E�G���[���b�Z�[�W
      );
    END IF;
  EXCEPTION
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,4000);
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,4000);
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END submain;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : �R���J�����g���s�t�@�C���o�^�v���V�[�W��
   *                    �I������ �iA-7�j
   **********************************************************************************/
--
  PROCEDURE main(
     errbuf           OUT NOCOPY VARCHAR2                                                              -- �G���[�E���b�Z�[�W
    ,retcode          OUT NOCOPY VARCHAR2                                                              -- ���^�[���E�R�[�h
    )                                                                   
    --
--###########################  �Œ蕔 START   ###########################
--
  IS
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name        CONSTANT VARCHAR2(100) := 'main';                                            -- �v���O������
--
    cv_appl_short_name CONSTANT VARCHAR2(10)  := 'XXCCP';                                           -- �A�h�I���F���ʁEIF�̈�
    cv_target_rec_msg  CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90000';                                -- �Ώی������b�Z�[�W
    cv_success_rec_msg CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90001';                                -- �����������b�Z�[�W
    cv_error_rec_msg   CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90002';                                -- �G���[�������b�Z�[�W
    cv_skip_rec_msg    CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90003';                                -- �X�L�b�v�������b�Z�[�W
    cv_cnt_token       CONSTANT VARCHAR2(10)  := 'COUNT';                                           -- �������b�Z�[�W�p�g�[�N����
    cv_normal_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004';                                -- ����I�����b�Z�[�W
    cv_warn_msg        CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005';                                -- �x���I�����b�Z�[�W
    cv_error_msg       CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006';                                -- �G���[�I���S���[���o�b�N
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf          VARCHAR2(4000);                                                              -- �G���[�E���b�Z�[�W
    lv_retcode         VARCHAR2(1);                                                                 -- ���^�[���E�R�[�h
    lv_errmsg          VARCHAR2(4000);                                                              -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_message_code    VARCHAR2(100);                                                               -- �I�����b�Z�[�W�R�[�h
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
    -- ===============================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ===============================================
    submain(
       ov_errbuf        => lv_errbuf                                            -- �G���[�E���b�Z�[�W
      ,ov_retcode       => lv_retcode                                           -- ���^�[���E�R�[�h
      ,ov_errmsg        => lv_errmsg                                            -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
--
    IF (lv_retcode = cv_status_error) THEN
      IF (lv_errmsg IS NULL) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name
                      ,iv_name         => cv_msg_00111                          -- �z��O�G���[���b�Z�[�W
                     );
      END IF;
      --�G���[�o��
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg                                                    -- ���[�U�[�E�G���[���b�Z�[�W
      );
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf                                                    -- �G���[���b�Z�[�W
      );
      --�����̐U��(�G���[�̏ꍇ�A�G���[������1���̂ݕ\��������B�j
      gn_target_cnt := 0;
      gn_normal_cnt := 0;
      gn_error_cnt  := 1;
      gn_warn_cnt   := 0;
    END IF;
--
    -- =======================
    -- A-6.�I������
    -- =======================
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
    --�I�����b�Z�[�W
    IF (lv_retcode = cv_status_normal) THEN
      lv_message_code := cv_normal_msg;
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
--
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
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM||lv_errbuf;
      retcode := cv_status_error;
      ROLLBACK;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
      ROLLBACK;
  END main;
END XXCSM002A15C;
/