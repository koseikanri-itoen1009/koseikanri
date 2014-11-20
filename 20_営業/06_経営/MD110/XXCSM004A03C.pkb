CREATE OR REPLACE PACKAGE BODY XXCSM004A03C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCSM004A03C(body)
 * Description      : �]�ƈ��}�X�^�Ǝ��i�|�C���g�}�X�^����e�c�ƈ��̎��i�|�C���g���Z�o���A
 *                  : �V�K�l���|�C���g�ڋq�ʗ����e�[�u���ɓo�^���܂��B
 * MD.050           : MD050_CSM_004_A03_�V�K�l���|�C���g�W�v�i���i�|�C���g�W�v�����j
 * Version          : 1.6
 *
 * Program List
 * -------------------- ------------------------------------------------------------
 *  Name                 Description
 * -------------------- ------------------------------------------------------------
 *  init                   �������� (A-1)
 *  get_dept_data          �����f�[�^�̒��o (A-3)
 *  get_point_data         ���i�|�C���g�Z�o���� (A-4)
 *  del_rireki_tbl_data    �����Ώۃf�[�^�̃��R�[�h�폜(A-5)
 *  insert_rireki_tbl_data �����x���i�|�C���g�f�[�^�̓o�^(A-6)
 *  submain                ���C�������v���V�[�W��
 *                           �c�ƈ��f�[�^�̒��o (A-2)
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *                           �I������ (A-7)
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008-12-12    1.0   T.Tsukino        �V�K�쐬
 *  2009-04-15    1.1   M.Ohtsuki       �mT1_0568�n�V�E���E���R�[�hNULL�l�̑Ή�
 *  2009-07-01    1.2   M.Ohtsuki       �mSCS��Q�Ǘ��ԍ�0000253�n�Ή�
 *  2009/07/07    1.3   M.Ohtsuki       �mSCS��Q�Ǘ��ԍ�0000254�n�����R�[�h�擾�����̕s�
 *  2009/07/14    1.4   M.Ohtsuki       �mSCS��Q�Ǘ��ԍ�0000663�n�z��O�G���[�������̕s�
 *  2009/07/27    1.5   T.Tsukino       �mSCS��Q�Ǘ��ԍ�0000786�n�p�t�H�[�}���X��Q
 *  2009/08/24    1.6   T.Tsukino       �mSCS��Q�Ǘ��ԍ�0001150�n��Q��0001150�Ή�(���ߓ��̔�����@�̕s���j
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
  cv_pkg_name             CONSTANT VARCHAR2(100) := 'XXCSM004A03C';                                 -- �p�b�P�[�W��
  cv_app_name             CONSTANT VARCHAR2(5)   := 'XXCSM';                                        -- �A�v���P�[�V�����Z�k��
  -- ���b�Z�[�W�R�[�h
  cv_xxcsm_msg_005        CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00005';                             -- �v���t�@�C���擾�G���[���b�Z�[�W
  cv_xxcsm_msg_102        CONSTANT VARCHAR2(100) := 'APP-XXCSM1-10002';                             -- �N�x�擾�G���[���b�Z�[�W
  cv_xxcsm_msg_042        CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00042';                             -- ���̓p�����[�^�`�F�b�N�G���[���b�Z�[�W�i�����N���j
  cv_xxcsm_msg_047        CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00047';                             -- ���i�|�C���g�����݃G���[���b�Z�[�W
  cv_xxccp_msg_052        CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00052';                             -- �R���J�����g���̓p�����[�^���b�Z�[�W�i�����N���j
  cv_xxcsm_msg_069        CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00069';                             -- �V�K�l���|�C���g�ڋq�ʗ����e�[�u�����b�N�G���[���b�Z�[�W�i�]�ƈ��ʁj
  cv_xxcsm_msg_070        CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00070';                             -- �����R�[�h�擾�G���[���b�Z�[�W�i�]�ƈ��ʁj
  cv_xxcsm_msg_120        CONSTANT VARCHAR2(100) := 'APP-XXCSM1-10020';                             -- �c�ƈ��f�[�^�擾�G���[���b�Z�[�W
  cv_xxcsm_msg_125        CONSTANT VARCHAR2(100) := 'APP-XXCSM1-10125';                             -- �Ώۏ]�ƈ��R�[�h�̔��ߓ��擾�G���[���b�Z�[�W
  cv_xxcsm_msg_126        CONSTANT VARCHAR2(100) := 'APP-XXCSM1-10126';                             -- �Ώۏ]�ƈ��R�[�h�̎��i�R�[�h�E�E���R�[�h�擾�G���[���b�Z�[�W
  --�v���t�@�C����
--//+DEL START 2009/07/07 0000254 M.Ohtsuki
--  cv_calc_point           CONSTANT VARCHAR2(100) := 'XXCSM1_CALC_POINT_POST_LEVEL';                 --  �v���t�@�C��:XXCSM:�|�C���g�Z�o�p�����K�w�i�[�p
--//+DEL END   2009/07/07 0000254 M.Ohtsuki
  -- �g�[�N���R�[�h
  cv_tkn_prf_name         CONSTANT VARCHAR2(20) := 'PROF_NAME';
  cv_tkn_data             CONSTANT VARCHAR2(20) := 'DATA';
  cv_tkn_date             CONSTANT VARCHAR2(20) := 'DATE';
  cv_tkn_yyyy             CONSTANT VARCHAR2(20) := 'YYYY';
  cv_tkn_month            CONSTANT VARCHAR2(20) := 'MONTH';
  cv_tkn_data_kbn         CONSTANT VARCHAR2(20) := 'DATA_KBN';
  cv_tkn_jugyoin_cd       CONSTANT VARCHAR2(20) := 'JUGYOIN_CD';
  cv_tkn_kyoten_cd        CONSTANT VARCHAR2(20) := 'KYOTEN_CD';
  cv_tkn_input_busyo      CONSTANT VARCHAR2(20) := 'INPUT_BUSYO';
  cv_tkn_input_shikaku    CONSTANT VARCHAR2(20) := 'INPUT_SHIKAKU';
  cv_tkn_input_shokumu    CONSTANT VARCHAR2(20) := 'INPUT_SYOKUMU';
  cv_tkn_pgm              CONSTANT VARCHAR2(20) := 'PGM';
  cv_tkn_err_msg          CONSTANT VARCHAR2(20) := 'ERR_MSG';
  cv_tkn_count            CONSTANT VARCHAR2(20) := 'COUNT';
  cv_tkn_process          CONSTANT VARCHAR2(20) := 'PROCESS_DATE';
--
--//+ADD START   2009/07/07 0000254 M.Ohtsuki
  TYPE gt_loc_lv_ttype IS TABLE OF VARCHAR2(10)                                                     -- �e�[�u���^�̐錾
    INDEX BY BINARY_INTEGER;
--//+ADD END     2009/07/07 0000254 M.Ohtsuki
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gd_process_date         DATE;                                                 -- �Ɩ����t�i�[�p
--//DEL START   2009/07/07 0000254 M.Ohtsuki
--  gv_prf_point            VARCHAR2(100);                                        -- �v���t�@�C��:XXCSM:�|�C���g�Z�o�p�����K�w�i�[�p
--//DEL END     2009/07/07 0000254 M.Ohtsuki
  gv_inprocess_date       VARCHAR2(100);                                        -- ���̓p�����[�^�i�[�p�p�����[�^
  gv_year                 VARCHAR2(4);                                          -- �Ώ۔N�x�i�[�p:�N
  gv_month                VARCHAR2(2);                                          -- �Ώ۔N�x�i�[�p:��
  gv_process_date         VARCHAR2(10);                                         -- �����Ώ۔N�x��
--//+ADD START   2009/07/07 0000254 M.Ohtsuki
  gt_loc_lv_tab             gt_loc_lv_ttype;                                                        -- �e�[�u���^�ϐ��̐錾
  ln_loc_lv_cnt             NUMBER;                                                                 -- �J�E���^
--//+ADD END     2009/07/07 0000254 M.Ohtsuki
--
  /**********************************************************************************
   * Procedure Name   : init
   * Argument         : iv_process_date [�R���J�����gIN�p�����[�^�F�������t/YYYYMM�`��]
   * Description      : �������� (A-1)
   ***********************************************************************************/
  PROCEDURE init(
     iv_process_date     IN  VARCHAR2                                           -- �������t
    ,ov_errbuf           OUT NOCOPY VARCHAR2                                    -- �G���[�E���b�Z�[�W
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
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_appl_short_name  CONSTANT VARCHAR2(10)    := 'XXCCP';                      -- �A�v���P�[�V�����Z�k��
    cv_tkn_value        CONSTANT VARCHAR2(100)   := 'XXCSM_COMMON_PKG';         -- ���ʊ֐���
--//+ADD START   2009/07/07 0000254 M.Ohtsuki
    cv_location_level   CONSTANT VARCHAR2(100) := 'XXCSM1_CALC_POINT_LEVEL';                        -- �|�C���g�Z�o�p�����K�w
    cv_flg_y            CONSTANT VARCHAR2(1) := 'Y';                                                -- �t���O'Y'
--//+ADD END     2009/07/07 0000254 M.Ohtsuki
    -- *** ���[�J���ϐ� ***
    lv_prm_msg          VARCHAR2(4000);                                         -- �R���J�����g���̓p�����[�^���b�Z�[�W�i�[�p
    lv_msg              VARCHAR2(100);                                          --
    lv_tkn_value        VARCHAR2(100);                                          -- ���̓p�����[�^�o�̓g�[�N���l
    lv_year             VARCHAR2(4);                                            -- �N�x�Z�o�֐�:GET_YEAR_MONTH/�N�x
    lv_month            VARCHAR2(2);                                            -- �N�x�Z�o�֐�:GET_YEAR_MONTH/��
    ld_chk_date         DATE;                                                   -- ���̓p�����[�^���t�`�F�b�N
    -- *** ���[�J����O ***
    prm_err_expt        EXCEPTION;                                              -- ���̓p�����[�^�`�F�b�N�G���[
--//+DEL START   2009/07/07 0000254 M.Ohtsuki
--    getprofile_err_expt EXCEPTION;                                              -- �v���t�@�C���擾�G���[���b�Z�[�W
--//+DEL END   2009/07/07 0000254 M.Ohtsuki
    get_year_expt       EXCEPTION;                                              -- �N�x�擾�G���[���b�Z�[�W
--//+ADD START   2009/07/07 0000254 M.Ohtsuki
    CURSOR get_loc_lv_cur
    IS
          SELECT   flv.lookup_code        lookup_code
          FROM     fnd_lookup_values      flv                                                       -- �N�C�b�N�R�[�h�l
          WHERE    flv.lookup_type        = cv_location_level                                       -- �|�C���g�Z�o�p�����K�w
            AND    flv.language           = USERENV('LANG')                                         -- ����('JA')
            AND    flv.enabled_flag       = cv_flg_y                                                -- �g�p�\�t���O
            AND    NVL(flv.start_date_active,gd_process_date) <= gd_process_date                    -- �K�p�J�n��
            AND    NVL(flv.end_date_active,gd_process_date)   >= gd_process_date                    -- �K�p�I����
          ORDER BY flv.lookup_code   DESC;                                                          -- ���b�N�A�b�v�R�[�h
--//+ADD END     2009/07/07 0000254 M.Ohtsuki
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
--  �Ɩ����t�̎擾
    gd_process_date := xxccp_common_pkg2.get_process_date;
    --�p�����[�^�ւ̓��͒l�̊i�[
    gv_inprocess_date := iv_process_date;
    -- =====================================
    -- A-1: �@ ���̓p�����[�^���b�Z�[�W�o��
    -- =====================================
    lv_tkn_value := gv_inprocess_date;
    lv_prm_msg   := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                          --�A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_xxccp_msg_052                     --���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_data                          --�g�[�N���R�[�h1
                       ,iv_token_value1 => lv_tkn_value                         --�g�[�N���l1
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
    -- =======================================
    -- A-1: �A ���̓p�����[�^�̊i�[/�`�F�b�N
    -- =======================================
    --NULL�`�F�b�N
    IF (iv_process_date IS NULL) THEN
      gv_inprocess_date := TO_CHAR(gd_process_date,'YYYYMM');
    END IF;
    IF (LENGTH(gv_inprocess_date) != 6) THEN
      RAISE prm_err_expt;
    END IF;
    --���̓p�����[�^�̌��̃`�F�b�N
    BEGIN
      ld_chk_date := TO_DATE(gv_inprocess_date, 'YYYYMM');
    EXCEPTION
      WHEN OTHERS THEN
        RAISE prm_err_expt;
    END;
--//+DEL START   2009/07/07 0000254 M.Ohtsuki
    -- ================================
    -- A-1: �B �v���t�@�C���l�擾����
    -- ================================
--    gv_prf_point := FND_PROFILE.VALUE(cv_calc_point);
--
    -- �v���t�@�C���l�擾�Ɏ��s�����ꍇ
--    IF (gv_prf_point IS NULL) THEN
--      RAISE getprofile_err_expt;
--    END IF;
--//+DEL END   2009/07/07 0000254 M.Ohtsuki
    -- =========================
    -- A-1: �B  �N�x�E���̎Z�o
    -- =========================
    -- ���ʊ֐�XXCSM_COMMON_PKG(XXCSM:�N�x�Z�o�֐�)
    xxcsm_common_pkg.get_year_month(
       iv_process_years => gv_inprocess_date                                    --�N��
      ,ov_year          => lv_year                                              --�Ώ۔N�x
      ,ov_month         => lv_month                                             --��
      ,ov_retcode       => lv_retcode                                           --���^�[���R�[�h�i0:����A1:�x���A2:�ُ�j
      ,ov_errbuf        => lv_errbuf                                            --�G���[���b�Z�[�W(�V�X�e���Ǘ��҂������ɕK�v�ȓ��e)
      ,ov_errmsg        => lv_errmsg                                            --���[�U�[�E�G���[���b�Z�[�W(���[�U�[�ɕ\������G���[���b�Z�[�W)
    );
    --���^�[���R�[�h��0:����ȊO�̏ꍇ�A�G���[
    IF (lv_retcode <> 0) THEN
      RAISE get_year_expt;
    END IF;
    gv_year    := lv_year;
    gv_month   := lv_month;
--//+ADD START   2009/07/07 0000254 M.Ohtsuki
--  --==============================================================
    --A-1: �C ���_�K�w�̎擾
    --==============================================================
    ln_loc_lv_cnt := 0;                                                                             -- �ϐ��̏�����
    <<get_loc_lv_cur_loop>>                                                                         -- ���_�K�w�擾LOOP
    FOR rec IN get_loc_lv_cur LOOP
      ln_loc_lv_cnt := ln_loc_lv_cnt + 1;
      gt_loc_lv_tab(ln_loc_lv_cnt)   := rec.lookup_code;                                            -- ���_�K�w
    END LOOP get_loc_lv_cur_loop;
--//+ADD END     2009/07/07 0000254 M.Ohtsuki
--
  EXCEPTION
    WHEN prm_err_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                            --�A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_xxcsm_msg_042                       --���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_date                            --�g�[�N���R�[�h1
                     ,iv_token_value1 => gv_inprocess_date                      --�g�[�N���l1
                     );
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      ov_retcode := cv_status_error;
--//+DEL START   2009/07/07 0000254 M.Ohtsuki
--    WHEN getprofile_err_expt THEN
--      lv_errmsg := xxccp_common_pkg.get_msg(
--                      iv_application  => cv_app_name                            --�A�v���P�[�V�����Z�k��
--                     ,iv_name         => cv_xxcsm_msg_005                       --���b�Z�[�W�R�[�h
--                     ,iv_token_name1  => cv_tkn_prf_name                        --�g�[�N���R�[�h1
--                     ,iv_token_value1 => cv_calc_point                          --�g�[�N���l1
--                   );
--      lv_errbuf  := lv_errmsg;
--      ov_errmsg  := lv_errmsg;
--      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
--      ov_retcode := cv_status_error;
--//+DEL END   2009/07/07 0000254 M.Ohtsuki
    WHEN get_year_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                            --�A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_xxcsm_msg_102                       --���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_pgm                             --�g�[�N���R�[�h1
                     ,iv_token_value1 => cv_tkn_value                           --�g�[�N���l1
                     ,iv_token_name2  => cv_tkn_err_msg                         --�g�[�N���R�[�h2
                     ,iv_token_value2 => lv_errmsg                              --�g�[�N���l2
                   );
      lv_errbuf  := lv_errmsg;
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
  END init;
--
  /**********************************************************************************
   * Procedure Name   : get_dept_data
   * Description      : �����f�[�^�̒��o�iA-3�j
   ***********************************************************************************/
  PROCEDURE get_dept_data(
     iv_employee_cd      IN  VARCHAR2                                           -- �]�ƈ��R�[�h
    ,iv_kyoten_cd        IN  VARCHAR2                                           -- ���_�R�[�h
    ,ov_busyo_cd         OUT NOCOPY VARCHAR2                                    -- �����R�[�h
    ,ov_errbuf           OUT NOCOPY VARCHAR2                                    -- �G���[�E���b�Z�[�W
    ,ov_retcode          OUT NOCOPY VARCHAR2                                    -- ���^�[���E�R�[�h
    ,ov_errmsg           OUT NOCOPY VARCHAR2                                    -- ���[�U�[�E�G���[�E���b�Z�[�W
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name          CONSTANT VARCHAR2(100)   := 'get_dept_data';           -- �v���O������
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
--
    -- *** ���[�J���ϐ� ***
    lv_busyo_cd          VARCHAR2(15);                                           -- �����R�[�h
    lv_shikaku_cd        VARCHAR2(100);                                         -- ���i�R�[�h
    lv_syokumu_cd        VARCHAR2(100);                                         -- �E���R�[�h
    ln_shikaku_point     NUMBER;                                                -- ���i�|�C���g
--//+ADD START   2009/07/07 0000254 M.Ohtsuki
    ln_check_cnt         NUMBER;                                                                    -- �����`�F�b�N�p�J�E���^
--//+ADD END     2009/07/07 0000254 M.Ohtsuki
    -- *** ���[�J����O ***
    get_busyo_cd_expt    EXCEPTION;                                             -- �����R�[�h�擾�G���[���b�Z�[�W
--
--
  BEGIN
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
--
  -- �����R�[�h���o����
--//+ADD START  2009/07/07 0000254 M.Ohtsuki
      ln_check_cnt := 0;                                                                            -- �ϐ��̏�����
      lv_busyo_cd  := NULL;                                                                         -- �ϐ��̏�����
      LOOP
        EXIT WHEN ln_check_cnt >= ln_loc_lv_cnt                                                      -- �|�C���g�Z�o�p�����K�w�̌�����
              OR  lv_busyo_cd IS NOT NULL;                                                          -- �����R�[�h���擾�ł���܂�
        ln_check_cnt := ln_check_cnt + 1;
--//+ADD END    2009/07/07 0000254 M.Ohtsuki
--//+UPD START  2009/07/07 0000254 M.Ohtsuki
--    SELECT DECODE(gv_prf_point, 'L6',xxlllv.cd_level6,
--��������������������������������������������������������������������������������������������������
    SELECT DECODE(gt_loc_lv_tab(ln_check_cnt), 'L6',xxlllv.cd_level6,
--//+UPD END    2009/07/07 0000254 M.Ohtsuki
                                'L5',xxlllv.cd_level5,
                                'L4',xxlllv.cd_level4,
                                'L3',xxlllv.cd_level3,
                                'L2',xxlllv.cd_level2,
                                'L1',xxlllv.cd_level1
                 )
    INTO   lv_busyo_cd
    FROM   xxcsm_loc_level_list_v   xxlllv
    WHERE  iv_kyoten_cd = DECODE(xxlllv.location_level,'L6',xxlllv.cd_level6,
                                                           'L5',xxlllv.cd_level5,
                                                           'L4',xxlllv.cd_level4,
                                                           'L3',xxlllv.cd_level3,
                                                           'L2',xxlllv.cd_level2,
                                                           'L1',xxlllv.cd_level1
                                    )
    ;
--//+ADD START  2009/07/07 0000254 M.Ohtsuki
      END LOOP;
--//+ADD END    2009/07/07 0000254 M.Ohtsuki
--
  -- �擾���ʃ`�F�b�N
    IF (lv_busyo_cd IS NULL) THEN
      RAISE get_busyo_cd_expt;
    END IF;
  -- �o�̓p�����[�^���͏���
    ov_busyo_cd         := lv_busyo_cd;
--
  EXCEPTION
    -- *** �����f�[�^���o��O�n���h�� ***
    WHEN get_busyo_cd_expt THEN
      -- �G���[���b�Z�[�W�擾
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                            --�A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_xxcsm_msg_070                       --���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_jugyoin_cd                      --�g�[�N���R�[�h1
                     ,iv_token_value1 => iv_employee_cd                         --�g�[�N���l1
                     ,iv_token_name2  => cv_tkn_kyoten_cd                       --�g�[�N���R�[�h2
                     ,iv_token_value2 => iv_kyoten_cd                           --�g�[�N���l2
                   );
      lv_errbuf := lv_errmsg;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
--//+UPD  START  2009/07/14 0000663 M.Ohtsuki
--      ov_retcode := cv_status_error;   -- �X�e�[�^�X:�G���[
--��������������������������������������������������������������������������������������������������
      ov_retcode := cv_status_warn;   -- �X�e�[�^�X:�x��
--//+UPD  END    2009/07/14 0000663 M.Ohtsuki
    -- *** �����f�[�^���o��O�n���h�� ***
    WHEN NO_DATA_FOUND THEN
      -- �G���[���b�Z�[�W�擾
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                            --�A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_xxcsm_msg_070                       --���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_jugyoin_cd                      --�g�[�N���R�[�h1
                     ,iv_token_value1 => iv_employee_cd                         --�g�[�N���l1
                     ,iv_token_name2  => cv_tkn_kyoten_cd                       --�g�[�N���R�[�h2
                     ,iv_token_value2 => iv_kyoten_cd                           --�g�[�N���l2
                   );
      lv_errbuf := lv_errmsg;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
--//+UPD  START  2009/07/14 0000663 M.Ohtsuki
--      ov_retcode := cv_status_error;   -- �X�e�[�^�X:�G���[
--��������������������������������������������������������������������������������������������������
      ov_retcode := cv_status_warn;   -- �X�e�[�^�X:�x��
--//+UPD  END    2009/07/14 0000663 M.Ohtsuki
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
  END get_dept_data;
  /**********************************************************************************
   * Procedure Name   : get_point_data
   * Description      : ���i�|�C���g�Z�o���� �iA-4�j
   **********************************************************************************/
  PROCEDURE get_point_data(
     iv_employee_cd      IN  VARCHAR2                                           -- �]�ƈ��R�[�h
    ,iv_busyo_cd         IN  VARCHAR2                                           -- �����R�[�h
    ,iv_shikaku_cd       IN  VARCHAR2                                           -- ���i�R�[�h
    ,iv_syokumu_cd       IN  VARCHAR2                                           -- �E���R�[�h
    ,on_shikaku_point    OUT NUMBER                                             -- ���i�|�C���g
    ,ov_errbuf           OUT NOCOPY VARCHAR2                                    -- �G���[�E���b�Z�[�W
    ,ov_retcode          OUT NOCOPY VARCHAR2                                    -- ���^�[���E�R�[�h
    ,ov_errmsg           OUT NOCOPY VARCHAR2                                    -- ���[�U�[�E�G���[�E���b�Z�[�W
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name          CONSTANT VARCHAR2(100)   := 'get_point_data';                              -- �v���O������
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
--
    -- *** ���[�J���ϐ� ***
    lv_employee_cd       VARCHAR2(30);                                          -- �]�ƈ��R�[�h
    lv_busyo_cd          VARCHAR2(15);                                          -- �����R�[�h
    lv_shikaku_cd        VARCHAR2(100);                                         -- ���i�R�[�h
    lv_syokumu_cd        VARCHAR2(100);                                         -- �E���R�[�h
    ln_shikaku_point     NUMBER;                                                -- ���i�|�C���g
    -- *** ���[�J����O ***
    no_data_shikaku_expt    EXCEPTION;                                          -- ���i�|�C���g�����݃G���[���b�Z�[�W
  BEGIN
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
  -- ���i�|�C���g�Z�o����
    SELECT xxmqp.qualificate_point      shikaku_point
    INTO   ln_shikaku_point
    FROM   xxcsm_mst_qualificate_pnt    xxmqp
    WHERE  xxmqp.subject_year    = gv_year
    AND    xxmqp.post_cd         = iv_busyo_cd
    AND    xxmqp.qualificate_cd  = iv_shikaku_cd
    AND    xxmqp.duties_cd       = iv_syokumu_cd
    ;

  -- �擾���ʃ`�F�b�N
    IF (ln_shikaku_point IS NULL) THEN
      RAISE no_data_shikaku_expt;
    END IF;
  -- �o�̓p�����[�^���͏���
    on_shikaku_point    := ln_shikaku_point;
--
  EXCEPTION
    -- *** ���i�|�C���g�����ݗ�O�n���h�� ***
    WHEN no_data_shikaku_expt THEN
      -- �G���[���b�Z�[�W�擾
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                            --�A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_xxcsm_msg_047                       --���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_jugyoin_cd                      --�g�[�N���R�[�h1
                     ,iv_token_value1 => iv_employee_cd                         --�g�[�N���l1
                     ,iv_token_name2  => cv_tkn_input_busyo                     --�g�[�N���R�[�h2
                     ,iv_token_value2 => iv_busyo_cd                            --�g�[�N���l2
                     ,iv_token_name3  => cv_tkn_input_shikaku                   --�g�[�N���R�[�h3
                     ,iv_token_value3 => iv_shikaku_cd                          --�g�[�N���l3
                     ,iv_token_name4  => cv_tkn_input_shokumu                   --�g�[�N���R�[�h4
                     ,iv_token_value4 => iv_syokumu_cd                          --�g�[�N���l4
                   );
      lv_errbuf := lv_errmsg;
--
      on_shikaku_point := NULL;
      ov_errmsg        := lv_errmsg;
      ov_errbuf        := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
--//+UPD  START  2009/07/14 0000663 M.Ohtsuki
--      ov_retcode := cv_status_error;   -- �X�e�[�^�X:�G���[
--��������������������������������������������������������������������������������������������������
      ov_retcode := cv_status_warn;   -- �X�e�[�^�X:�x��
--//\UPD  END    2009/07/14 0000663 M.Ohtsuki
    -- *** ���i�|�C���g�����ݗ�O�n���h�� ***
    WHEN NO_DATA_FOUND THEN
      -- �G���[���b�Z�[�W�擾
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                            --�A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_xxcsm_msg_047                       --���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_jugyoin_cd                      --�g�[�N���R�[�h1
                     ,iv_token_value1 => iv_employee_cd                         --�g�[�N���l1
                     ,iv_token_name2  => cv_tkn_input_busyo                     --�g�[�N���R�[�h2
                     ,iv_token_value2 => iv_busyo_cd                            --�g�[�N���l2
                     ,iv_token_name3  => cv_tkn_input_shikaku                   --�g�[�N���R�[�h3
                     ,iv_token_value3 => iv_shikaku_cd                          --�g�[�N���l3
                     ,iv_token_name4  => cv_tkn_input_shokumu                   --�g�[�N���R�[�h4
                     ,iv_token_value4 => iv_syokumu_cd                          --�g�[�N���l4
                   );
      lv_errbuf := lv_errmsg;
--
      on_shikaku_point := NULL;
      ov_errmsg        := lv_errmsg;
      ov_errbuf        := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
--//+UPD  START  2009/07/14 0000663 M.Ohtsuki
--      ov_retcode := cv_status_error;   -- �X�e�[�^�X:�G���[
--��������������������������������������������������������������������������������������������������
      ov_retcode := cv_status_warn;   -- �X�e�[�^�X:�x��
--//\UPD  END    2009/07/14 0000663 M.Ohtsuki
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      on_shikaku_point := NULL;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,4000);
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_point_data;
  /**********************************************************************************
   * Procedure Name   : del_rireki_tbl_data
   * Description      : �����Ώۃf�[�^�̃��R�[�h�폜�iA-5�j
   ***********************************************************************************/
  PROCEDURE del_rireki_tbl_data(
     iv_employee_num     IN  VARCHAR2
    ,ov_errbuf           OUT NOCOPY VARCHAR2                                    -- �G���[�E���b�Z�[�W
    ,ov_retcode          OUT NOCOPY VARCHAR2                                    -- ���^�[���E�R�[�h
    ,ov_errmsg           OUT NOCOPY VARCHAR2                                    -- ���[�U�[�E�G���[�E���b�Z�[�W
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name          CONSTANT VARCHAR2(100)   := 'del_rireki_tbl_data';     -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf            VARCHAR2(4000);                                        -- �G���[�E���b�Z�[�W
    lv_retcode           VARCHAR2(1);                                           -- ���^�[���E�R�[�h
    lv_errmsg            VARCHAR2(4000);                                        -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cn_tkn_kbn           CONSTANT NUMBER   := 0;                                -- �f�[�^�敪�Œ�l
    -- *** ���[�J���ϐ� ***
    lv_employee_number  XXCSM_NEW_CUST_POINT_HST.EMPLOYEE_NUMBER%TYPE;
--
    -- *** ���[�J���E�J�[�\�� ***
    CURSOR del_rireki_tbl_cur(
      lv_employee_number VARCHAR2
      )
    IS
      SELECT ROWID
      FROM   xxcsm_new_cust_point_hst      xxncph
      WHERE  xxncph.subject_year      =    gv_year
      AND    xxncph.month_no          =    gv_month
      AND    xxncph.data_kbn          =    '0'
      AND    xxncph.employee_number   =    lv_employee_number
      FOR UPDATE NOWAIT
      ;
    -- *** ���[�J����O ***
    rock_err_expt        EXCEPTION;                                              -- �V�K�l���|�C���g�ڋq�ʗ����e�[�u�����b�N�G���[���b�Z�[�W
--
    PRAGMA EXCEPTION_INIT(rock_err_expt,-54);
--
  BEGIN
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
    --���̓p�����[�^�̕ϐ��ւ̑��
    lv_employee_number    :=   iv_employee_num;
    --�Ώۃf�[�^�폜����
    << del_rireki_tbl_loop >>
    FOR del_rireki_tbl_rec IN  del_rireki_tbl_cur(lv_employee_number) LOOP
      DELETE
      FROM    xxcsm_new_cust_point_hst    xxncph
      WHERE   ROWID = del_rireki_tbl_rec.rowid
      ;
    END LOOP  del_rireki_tbl_loop;
--
  EXCEPTION
    -- *** �V�K�l���|�C���g�ڋq�ʗ����e�[�u�����b�N��O�n���h�� ***
    WHEN rock_err_expt THEN
      -- �G���[���b�Z�[�W�擾
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                            --�A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_xxcsm_msg_069                       --���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_yyyy                            --�g�[�N���R�[�h1
                     ,iv_token_value1 => gv_year                                --�g�[�N���l1
                     ,iv_token_name2  => cv_tkn_month                           --�g�[�N���R�[�h2
                     ,iv_token_value2 => gv_month                               --�g�[�N���l2
                     ,iv_token_name3  => cv_tkn_data_kbn                        --�g�[�N���R�[�h3
                     ,iv_token_value3 => cn_tkn_kbn                             --�g�[�N���l3
                     ,iv_token_name4  => cv_tkn_jugyoin_cd                      --�g�[�N���R�[�h4
                     ,iv_token_value4 => lv_employee_number                     --�g�[�N���l4
                   );
      lv_errbuf := lv_errmsg;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
--//+UPD  START  2009/07/14 0000663 M.Ohtsuki
--      ov_retcode := cv_status_error;   -- �X�e�[�^�X:�G���[
--��������������������������������������������������������������������������������������������������
      ov_retcode := cv_status_warn;   -- �X�e�[�^�X:�x��
--//+UPD  END    2009/07/14 0000663 M.Ohtsuki
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
  END del_rireki_tbl_data;
--
  /**********************************************************************************
   * Procedure Name   : insert_rireki_tbl_data
   * Description      : �����x���i�|�C���g�f�[�^�̓o�^�iA-6�j
   ***********************************************************************************/
  PROCEDURE insert_rireki_tbl_data(
     iv_employee_num     IN  VARCHAR2                                           -- �]�ƈ���
    ,in_shikaku_point    IN  NUMBER
    ,iv_busyo_cd         IN  VARCHAR2
    ,iv_syokumu_cd       IN  VARCHAR2
    ,iv_shikaku_cd       IN  VARCHAR2
    ,iv_kyoten_cd        IN  VARCHAR2
    ,ov_errbuf           OUT NOCOPY VARCHAR2                                    -- �G���[�E���b�Z�[�W
    ,ov_retcode          OUT NOCOPY VARCHAR2                                    -- ���^�[���E�R�[�h
    ,ov_errmsg           OUT NOCOPY VARCHAR2                                    -- ���[�U�[�E�G���[�E���b�Z�[�W
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name          CONSTANT VARCHAR2(100)   := 'insert_rireki_tbl_data';                              -- �v���O������

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
    cv_acc_num           CONSTANT VARCHAR2(1)     := '0';                       -- �Œ�l:'0'�i�ڋq�R�[�h�Ȃ��j
    cv_date_kbn          CONSTANT VARCHAR2(1)     := '0';                       -- �Œ�l:'0'�i���i�|�C���g�j
    -- *** ���[�J���ϐ� ***
    lv_employee_num      VARCHAR2(100);                                         -- �]�ƈ���
    ln_shikaku_point     NUMBER;                                                -- ���i�|�C���g
    lv_busyo_cd          VARCHAR2(15);                                          -- �����R�[�h
    lv_syokumu_cd        VARCHAR2(100);                                         -- �E���R�[�h
    lv_shikaku_cd        VARCHAR2(100);                                         -- ���i�R�[�h
    lv_kyoten_cd         VARCHAR2(100);                                         -- ���_�R�[�h
    -- *** ���[�J����O ***    
    no_data_inprm        EXCEPTION;                                             -- ���̓p�����[�^NULL�`�F�b�N
--
  BEGIN
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
  --���̓p�����[�^NULL�`�F�b�N
  IF (in_shikaku_point IS NULL OR
      iv_busyo_cd      IS NULL OR
      iv_syokumu_cd    IS NULL OR
      iv_shikaku_cd    IS NULL OR
      iv_kyoten_cd     IS NULL)
  THEN RAISE no_data_inprm;
  END IF;  
  --�����x���i�|�C���g�f�[�^�o�^����
    INSERT INTO xxcsm_new_cust_point_hst(
       employee_number
      ,subject_year
      ,month_no
      ,account_number
      ,data_kbn
      ,year_month
      ,point
      ,post_cd
      ,duties_cd
      ,qualificate_cd
      ,location_cd
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
       iv_employee_num
      ,gv_year
      ,gv_month
      ,cv_acc_num
      ,cv_date_kbn
      ,TO_NUMBER(gv_inprocess_date)
      ,in_shikaku_point
      ,iv_busyo_cd
      ,iv_syokumu_cd
      ,iv_shikaku_cd
      ,iv_kyoten_cd
      ,cn_created_by
      ,cd_creation_date
      ,cn_last_updated_by
      ,cd_last_update_date
      ,cn_last_update_login
      ,cn_request_id
      ,cn_program_application_id
      ,cn_program_id
      ,cd_program_update_date
      )
      ;
--
  EXCEPTION
    -- *** ���̓p�����[�^NULL�`�F�b�N***
    WHEN no_data_inprm THEN
      -- �G���[���b�Z�[�W�擾
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                            --�A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_xxcsm_msg_126                       --���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_jugyoin_cd                      --�g�[�N���R�[�h1
                     ,iv_token_value1 => iv_employee_num                        --�g�[�N���l1
                   );
      lv_errbuf := lv_errmsg;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
--//+UPD  START  2009/07/14 0000663 M.Ohtsuki
--      ov_retcode := cv_status_error;   -- �X�e�[�^�X:�G���[
--��������������������������������������������������������������������������������������������������
      ov_retcode := cv_status_warn;   -- �X�e�[�^�X:�x��
--//+UPD  END    2009/07/14 0000663 M.Ohtsuki
--
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
  END insert_rireki_tbl_data;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   *                    �c�ƈ��f�[�^�̒��o (A-2)
   ***********************************************************************************/
  PROCEDURE submain(
     iv_process_date   IN  VARCHAR2
    ,ov_errbuf         OUT NOCOPY VARCHAR2                                      -- �G���[�E���b�Z�[�W
    ,ov_retcode        OUT NOCOPY VARCHAR2                                      -- ���^�[���E�R�[�h
    ,ov_errmsg         OUT NOCOPY VARCHAR2                                      -- ���[�U�[�E�G���[�E���b�Z�[�W
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name       CONSTANT VARCHAR2(100) := 'submain';                      -- �v���O������
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
    -- *** ���[�J���萔 ***
    cn_shikaku_point           CONSTANT NUMBER      := 0;                             -- ���i�|�C���g:�|�C���g0
--//+ADD START 2009/08/24 0001150 T.Tsukino
    cv_tougetsu_date           CONSTANT VARCHAR2(2) := '01';                          -- ������r�p������t
--//ADD END 2009/08/24 0001150 T.Tsukino   
--
    -- *** ���[�J���ϐ� ***
    lv_kyoten_cd               PER_ALL_ASSIGNMENTS_F.ASS_ATTRIBUTE5%TYPE;              --  ���_�R�[�h
    lv_new_kyoten_cd           PER_ALL_ASSIGNMENTS_F.ASS_ATTRIBUTE5%TYPE;              -- �i�V�j���_�R�[�h
    lv_old_kyoten_cd           PER_ALL_ASSIGNMENTS_F.ASS_ATTRIBUTE6%TYPE;              -- �i���j���_�R�[�h
    lv_busyo_cd                XXCSM_MST_QUALIFICATE_PNT.POST_CD%TYPE;                 --  �����R�[�h
    lv_new_busyo_cd            XXCSM_MST_QUALIFICATE_PNT.POST_CD%TYPE;                 -- �i�V�j�����R�[�h
    lv_old_busyo_cd            XXCSM_MST_QUALIFICATE_PNT.POST_CD%TYPE;                 -- �i���j�����R�[�h
    lv_shikaku_cd              PER_PEOPLE_F.ATTRIBUTE7%TYPE;                           --  ���i�R�[�h
    lv_new_shikaku_cd          PER_PEOPLE_F.ATTRIBUTE7%TYPE;                           -- �i�V�j���i�R�[�h
    lv_old_shikaku_cd          PER_PEOPLE_F.ATTRIBUTE9%TYPE;                           -- �i���j���i�R�[�h
    lv_syokumu_cd              PER_PEOPLE_F.ATTRIBUTE15%TYPE;                          --  �E���R�[�h
    lv_new_syokumu_cd          PER_PEOPLE_F.ATTRIBUTE15%TYPE;                          -- �i�V�j�E���R�[�h
    lv_old_syokumu_cd          PER_PEOPLE_F.ATTRIBUTE17%TYPE;                          -- �i���j�E���R�[�h
    ln_shikaku_point           NUMBER;                                                --  ���i�|�C���g
    ln_new_shikaku_point       NUMBER;                                                -- �i�V�j���i�|�C���g
    ln_old_shikaku_point       NUMBER;                                                -- �i���j���i�|�C���g
    -- *** ���[�J���E�J�[�\�� ***
    CURSOR get_eigyo_date_cur(
      gd_process_date  DATE
     )
    IS
      --�]�ƈ��̐E�킪�������݂̂ŉc�ƈ��̃P�[�X
--//+DEL  START  2009/07/27 0000786 T.Tsukino
--      SELECT
--//+DEL  END  2009/07/27 0000786 T.Tsukino
--//+ADD  START  2009/07/27 0000786 T.Tsukino
        SELECT /*+ LEADING(ippf.ippf.pap) INDEX(ppf.pap PER_PEOPLE_F_PK) */
--//+ADD  END  2009/07/27 0000786 T.Tsukino
               ppf.employee_number                            employee_number     --�]�ƈ��R�[�h
              ,SUBSTRB(paaf.ass_attribute2,1,6)               hatsureibi          --���ߓ�(YYYYMMDD��YYYYMM�j
              ,ppf.attribute7                                 new_shikaku_cd      --���i�R�[�h�i�V�j
              ,ppf.attribute9                                 old_shikaku_cd      --���i�R�[�h�i���j
              ,ppf.attribute15                                new_syokumu_cd      --�E���R�[�h�i�V�j
              ,ppf.attribute17                                old_syokumu_cd      --�E���R�[�h�i���j
              ,NULL                                           new_syokusyu_cd     --�E��R�[�h�i�V�j
              ,ppf.attribute21                                old_syokusyu_cd     --�E��R�[�h�i���j
              ,paaf.ass_attribute5                            new_kyoten_cd       --���_�R�[�h�i�V�j
              ,paaf.ass_attribute6                            old_kyoten_cd       --���_�R�[�h�i���j
      FROM
               per_people_f                ppf                                    --�]�ƈ��}�X�^
              ,per_periods_of_service      ppos                                   --�]�ƈ��T�[�r�X�}�X�^
              ,per_all_assignments_f       paaf                                   --�]�ƈ��A�T�C�����g�}�X�^
--//+ADD START 2009/07/01 0000253 M.Ohtsuki
              ,(SELECT   ippf.person_id                  person_id                                  -- �]�ƈ�ID
                        ,MAX(ippf.effective_start_date)  effective_start_date                       -- �ŐV(�K�p�J�n��)
                FROM     per_people_f      ippf                                                     -- �]�ƈ��}�X�^
                WHERE    ippf.current_emp_or_apl_flag = 'Y'                                         -- �L���t���O
                GROUP BY ippf.person_id)   ippf                                                     -- �]�ƈ�ID
--//+ADD END   2009/07/01 0000253 M.Ohtsuki
--//+UPD START 2009/07/01 0000253 M.Ohtsuki
--      WHERE    ppf.person_id = ppos.person_id                                     -- (�R�t��) �]�ƈ��}�X�^�D�]�ƈ�ID = �]�ƈ��T�[�r�X�}�X�^�D�]�ƈ�ID
--������������������������������������������������������������������������������������������������
      WHERE    ippf.person_id = ppf.person_id                                                       -- �]�ƈ�ID�R�t��
      AND      ippf.effective_start_date = ppf.effective_start_date                                 -- �K�p�J�n���R�t��
      AND      paaf.effective_start_date = ppf.effective_start_date                                 -- �K�p�J�n���R�t��
      AND      paaf.period_of_service_id = ppos.period_of_service_id                                -- �T�[�r�XID�R�t��
--//+UPD END   2009/07/01 0000253 M.Ohtsuki
      AND      ppf.person_id = paaf.person_id                                     --�i�R�t���j�]�ƈ��}�X�^�D�]�ƈ�ID = �]�ƈ��A�T�C�������g�}�X�^�D�]�ƈ�ID
      AND      ppos.date_start <= gd_process_date                                 --�i���o�����j���ДN�������Ɩ����t�ȉ�
      AND     (ppos.actual_termination_date > gd_process_date
                  OR ppos.actual_termination_date IS NULL)                         --�i���o�����j�ސE�N�������Ɩ����t����OR�f�[�^�Ȃ�
      AND     EXISTS (SELECT 'X'
                      FROM   fnd_lookup_values  flv                      --�N�C�b�N�R�[�h�l
                      WHERE  flv.lookup_type = 'XXCSM1_BUSINESS_INFO'    --�R�[�h�^�C�v:�c�ƈ���`���w��������i�hXXCSM1_BUSINESS_INFO�h�j
                      AND    flv.language    = 'JA'                      --����
                      AND    NVL(flv.start_date_active,gd_process_date) <= gd_process_date    --�L���J�n��<=�Ɩ����t
                      AND    NVL(flv.end_date_active,gd_process_date) >= gd_process_date      --�L���I����>=�Ɩ����t
                      AND    flv.enabled_flag = 'Y'
                      AND    flv.lookup_code =  ppf.attribute21          --�E��R�[�h�i���j���c�ƈ�
--//+UPD START 2009/04/15 T1_0568 M.Ohtsuki
--                      AND    flv.lookup_code <> ppf.attribute19          --�E��R�[�h�i�V�j���c�ƈ��ȊO
--��������������������������������������������������������������������������������������������������
                      AND    (flv.lookup_code <> ppf.attribute19          --�E��R�[�h�i�V�j���c�ƈ��ȊO
                              OR ppf.attribute19 IS NULL)                 --�E��R�[�h�i�V�j��NULL
--//+UPD END   2009/04/15 T1_0568 M.Ohtsuki
                      AND    SUBSTRB(paaf.ass_attribute2,1,6) >= TO_CHAR(gd_process_date,'YYYYMM')) --�O���ȑO�ɉc�ƈ��łȂ��Ȃ����]�ƈ������O
      UNION ALL
      --�]�ƈ��̐E�킪�V�����݂̂ŉc�ƈ��̃P�[�X
--//+DEL  START  2009/07/27 0000786 T.Tsukino
--      SELECT
--//+DEL  END  2009/07/27 0000786 T.Tsukino
--//+ADD  START  2009/07/27 0000786 T.Tsukino
        SELECT /*+ LEADING(ippf.ippf.pap) INDEX(ppf.pap PER_PEOPLE_F_PK) */
--//+ADD  END  2009/07/27 0000786 T.Tsukino
               ppf.employee_number                            employee_number     --�]�ƈ��R�[�h
              ,SUBSTRB(paaf.ass_attribute2,1,6)               hatsureibi          --���ߓ�(YYYYMMDD��YYYYMM�j
              ,ppf.attribute7                                 new_shikaku_cd      --���i�R�[�h�i�V�j
              ,ppf.attribute9                                 old_shikaku_cd      --���i�R�[�h�i���j
              ,ppf.attribute15                                new_syokumu_cd      --�E���R�[�h�i�V�j
              ,ppf.attribute17                                old_syokumu_cd      --�E���R�[�h�i���j
              ,ppf.attribute19                                new_syokusyu_cd     --�E��R�[�h�i�V�j
              ,NULL                                           old_syokusyu_cd     --�E��R�[�h�i���j
              ,paaf.ass_attribute5                            new_kyoten_cd       --���_�R�[�h�i�V�j
              ,paaf.ass_attribute6                            old_kyoten_cd       --���_�R�[�h�i���j
      FROM
               per_people_f                ppf                                    --�]�ƈ��}�X�^
              ,per_periods_of_service      ppos                                   --�]�ƈ��T�[�r�X�}�X�^
              ,per_all_assignments_f       paaf                                   --�]�ƈ��A�T�C�����g�}�X�^
--//+ADD START 2009/07/01 0000253 M.Ohtsuki
              ,(SELECT   ippf.person_id                  person_id                                  -- �]�ƈ�ID
                        ,MAX(ippf.effective_start_date)  effective_start_date                       -- �ŐV(�K�p�J�n��)
                FROM     per_people_f      ippf                                                     -- �]�ƈ��}�X�^
                WHERE    ippf.current_emp_or_apl_flag = 'Y'                                         -- �L���t���O
                GROUP BY ippf.person_id)   ippf                                                     -- �]�ƈ�ID
--//+ADD END   2009/07/01 0000253 M.Ohtsuki
--//+UPD START 2009/07/01 0000253 M.Ohtsuki
--      WHERE    ppf.person_id = ppos.person_id                                     -- (�R�t��) �]�ƈ��}�X�^�D�]�ƈ�ID = �]�ƈ��T�[�r�X�}�X�^�D�]�ƈ�ID
--������������������������������������������������������������������������������������������������
      WHERE    ippf.person_id = ppf.person_id                                                       -- �]�ƈ�ID�R�t��
      AND      ippf.effective_start_date = ppf.effective_start_date                                 -- �K�p�J�n���R�t��
      AND      paaf.effective_start_date = ppf.effective_start_date                                 -- �K�p�J�n���R�t��
      AND      paaf.period_of_service_id = ppos.period_of_service_id                                -- �T�[�r�XID�R�t��
--//+UPD END   2009/07/01 0000253 M.Ohtsuki
      AND      ppf.person_id = paaf.person_id                                     --�i�R�t���j�]�ƈ��}�X�^�D�]�ƈ�ID = �]�ƈ��A�T�C�������g�}�X�^�D�]�ƈ�ID
      AND      ppos.date_start <= gd_process_date                                 --�i���o�����j���ДN�������Ɩ����t�ȉ�
      AND     (ppos.actual_termination_date > gd_process_date
                  OR ppos.actual_termination_date IS NULL)                         --�i���o�����j�ސE�N�������Ɩ����t����OR�f�[�^�Ȃ�
      AND     EXISTS (SELECT 'X'
                      FROM   fnd_lookup_values  flv                      --�N�C�b�N�R�[�h�l
                      WHERE  flv.lookup_type = 'XXCSM1_BUSINESS_INFO'    --�R�[�h�^�C�v:�c�ƈ���`���w��������i�hXXCSM1_BUSINESS_INFO�h�j
                      AND    flv.language    = 'JA'                      --����
                      AND    NVL(flv.start_date_active,gd_process_date) <= gd_process_date    --�L���J�n��<=�Ɩ����t
                      AND    NVL(flv.end_date_active,gd_process_date) >= gd_process_date      --�L���I����>=�Ɩ����t
                      AND    flv.enabled_flag = 'Y'
--//+UPD START 2009/04/15 T1_0568 M.Ohtsuki
--                      AND    flv.lookup_code <> ppf.attribute21          --�E��R�[�h�i���j���c�ƈ��ȊO
--��������������������������������������������������������������������������������������������������
                      AND    (flv.lookup_code <> ppf.attribute21          --�E��R�[�h�i���j���c�ƈ��ȊO
                             OR ppf.attribute21 IS NULL)                  --�E��R�[�h�i���j��NULL
--//+UPD END   2009/04/15 T1_0568 M.Ohtsuki
                      AND    flv.lookup_code =  ppf.attribute19          --�E��R�[�h�i�V�j���c�ƈ�
                      AND    SUBSTRB(paaf.ass_attribute2,1,6) <= TO_CHAR(gd_process_date,'YYYYMM')) --�����ȍ~�ɉc�ƈ��łƂȂ�]�ƈ������O
      UNION ALL
      --�]�ƈ��̐E�킪�V�E�������Ƃ��ɉc�ƈ��̃P�[�X
      SELECT
               ppf.employee_number                            employee_number     --�]�ƈ��R�[�h
--//+ADD START 2009/08/24 0001150 T.Tsukino
--��������������������������������������������������������������������������������������������������������������������������
--              ,SUBSTRB(paaf.ass_attribute2,1,6)               hatsureibi          --���ߓ�(YYYYMMDD��YYYYMM�j
              ,paaf.ass_attribute2                            hatsureibi          --���ߓ�(YYYYMMDD�j
--//+ADD END 2009/08/24 0001150 T.Tsukino
              ,ppf.attribute7                                 new_shikaku_cd      --���i�R�[�h�i�V�j
              ,ppf.attribute9                                 old_shikaku_cd      --���i�R�[�h�i���j
              ,ppf.attribute15                                new_syokumu_cd      --�E���R�[�h�i�V�j
              ,ppf.attribute17                                old_syokumu_cd      --�E���R�[�h�i���j
              ,ppf.attribute19                                new_syokusyu_cd     --�E��R�[�h�i�V�j
              ,ppf.attribute21                                old_syokusyu_cd     --�E��R�[�h�i���j
              ,paaf.ass_attribute5                            new_kyoten_cd       --���_�R�[�h�i�V�j
              ,paaf.ass_attribute6                            old_kyoten_cd       --���_�R�[�h�i���j
      FROM
               per_people_f                ppf                                    --�]�ƈ��}�X�^
              ,per_periods_of_service      ppos                                   --�]�ƈ��T�[�r�X�}�X�^
              ,per_all_assignments_f       paaf                                   --�]�ƈ��A�T�C�����g�}�X�^
--//+ADD START 2009/07/01 0000253 M.Ohtsuki
              ,(SELECT   ippf.person_id                  person_id                                  -- �]�ƈ�ID
                        ,MAX(ippf.effective_start_date)  effective_start_date                       -- �ŐV(�K�p�J�n��)
                FROM     per_people_f      ippf                                                     -- �]�ƈ��}�X�^
                WHERE    ippf.current_emp_or_apl_flag = 'Y'                                         -- �L���t���O
                GROUP BY ippf.person_id)   ippf                                                     -- �]�ƈ�ID
--//+ADD END   2009/07/01 0000253 M.Ohtsuki
--//+UPD START 2009/07/01 0000253 M.Ohtsuki
--      WHERE    ppf.person_id = ppos.person_id                                     -- (�R�t��) �]�ƈ��}�X�^�D�]�ƈ�ID = �]�ƈ��T�[�r�X�}�X�^�D�]�ƈ�ID
--������������������������������������������������������������������������������������������������
      WHERE    ippf.person_id = ppf.person_id                                                       -- �]�ƈ�ID�R�t��
      AND      ippf.effective_start_date = ppf.effective_start_date                                 -- �K�p�J�n���R�t��
      AND      paaf.effective_start_date = ppf.effective_start_date                                 -- �K�p�J�n���R�t��
      AND      paaf.period_of_service_id = ppos.period_of_service_id                                -- �T�[�r�XID�R�t��
--//+UPD END   2009/07/01 0000253 M.Ohtsuki
      AND      ppf.person_id = paaf.person_id                                     --�i�R�t���j�]�ƈ��}�X�^�D�]�ƈ�ID = �]�ƈ��A�T�C�������g�}�X�^�D�]�ƈ�ID
      AND      ppos.date_start <= gd_process_date                                 --�i���o�����j���ДN�������Ɩ����t�ȉ�
      AND     (ppos.actual_termination_date > gd_process_date
                  OR ppos.actual_termination_date IS NULL)                         --�i���o�����j�ސE�N�������Ɩ����t����OR�f�[�^�Ȃ�
      AND     EXISTS (SELECT 'X'
                      FROM   fnd_lookup_values  flv                      --�N�C�b�N�R�[�h�l
                      WHERE  flv.lookup_type = 'XXCSM1_BUSINESS_INFO'    --�R�[�h�^�C�v:�c�ƈ���`���w��������i�hXXCSM1_BUSINESS_INFO�h�j
                      AND    flv.language    = 'JA'                      --����
                      AND    NVL(flv.start_date_active,gd_process_date) <= gd_process_date    --�L���J�n��<=�Ɩ����t
                      AND    NVL(flv.end_date_active,gd_process_date) >= gd_process_date      --�L���I����>=�Ɩ����t
                      AND    flv.enabled_flag = 'Y'
                      AND    flv.lookup_code =  ppf.attribute21          --�E��R�[�h�i���j���c�ƈ�
                      AND    flv.lookup_code =  ppf.attribute19)         --�E��R�[�h�i�V�j���c�ƈ�
    ;
    -- *** ���[�J���E���R�[�h ***
    get_eigyo_date_rec    get_eigyo_date_cur%ROWTYPE;
    -- *** ���[�J����O ***
    no_data_expt      EXCEPTION;                                                  -- �c�ƈ��f�[�^�擾�G���[���b�Z�[�W
    global_skip_expt  EXCEPTION;                                                  -- ��O����
    no_data_hatsurei  EXCEPTION;                                                  -- ���ߓ��擾�G���[���b�Z�[�W
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
--
    -- ======================================
    -- A-1.��������
    -- ======================================
    init(
       iv_process_date => iv_process_date
      ,ov_errbuf       => lv_errbuf                                             -- �G���[�E���b�Z�[�W
      ,ov_retcode      => lv_retcode                                            -- ���^�[���E�R�[�h
      ,ov_errmsg       => lv_errmsg                                             -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
--
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
    -- ======================================
    -- ���[�J���E�J�[�\���I�[�v��
    -- ======================================
    OPEN get_eigyo_date_cur(gd_process_date);
    <<get_eigyo_date_loop>>
    LOOP
      FETCH get_eigyo_date_cur INTO get_eigyo_date_rec;
    -- �����Ώی����i�[
          gn_target_cnt := get_eigyo_date_cur%ROWCOUNT;
--
      EXIT WHEN get_eigyo_date_cur%NOTFOUND
             OR get_eigyo_date_cur%ROWCOUNT = 0;
      BEGIN
        --�Z�[�u�|�C���g
        SAVEPOINT eigyo_date_sv;
        IF (get_eigyo_date_rec.hatsureibi IS NULL) THEN
          RAISE no_data_hatsurei;
        END IF;
--//+UPD START 2009/08/24 0001150 T.Tsukino        
--������������������������������������������������������������������������������������������������������������������������
--        IF (get_eigyo_date_rec.hatsureibi = gv_inprocess_date) THEN               --���ߓ�=���͓��t'YYYYMM
          IF (SUBSTRB(get_eigyo_date_rec.hatsureibi,1,6) = gv_inprocess_date) THEN               --���ߓ�=���͓��t'YYYYMM
--//+UPD END 2009/08/24 0001150 T.Tsukino 
           IF(get_eigyo_date_rec.new_syokusyu_cd IS NOT NULL
            AND get_eigyo_date_rec.old_syokusyu_cd IS NOT NULL)
          THEN
--//+ADD START 2009/08/24 0001150 T.Tsukino
            IF (SUBSTRB(get_eigyo_date_rec.hatsureibi,7,2) = cv_tougetsu_date) THEN
            --�V�f�[�^�Ńf�[�^����鏈��
        -- ��================================��
        --  �V�̏����ɂāA
        --  �@�����R�[�h���o/���i�|�C���g�̎Z�o
        --  �A���R�[�h�̍폜
        --  �B���R�[�h�̐V�K�ǉ����s��
        -- ��================================��
            --�V�f�[�^�̑��
         -- ================================================
         -- �i�V�f�[�^)�����f�[�^�̒��o����
         -- ================================================
              get_dept_data(
                 iv_employee_cd      =>   get_eigyo_date_rec.employee_number
                ,iv_kyoten_cd        =>   get_eigyo_date_rec.new_kyoten_cd
                ,ov_busyo_cd         =>   lv_busyo_cd
                ,ov_errbuf           =>   lv_errbuf
                ,ov_retcode          =>   lv_retcode
                ,ov_errmsg           =>   lv_errmsg
                );
                -- �G���[�Ȃ�΁A�������X�L�b�v����B
                IF (lv_retcode = cv_status_error) THEN
                  RAISE global_process_expt;
                END IF;
                IF (lv_retcode = cv_status_warn) THEN
                  RAISE global_skip_expt;
                END IF;
         -- ================================================
         -- (�V�f�[�^)���i�|�C���g�Z�o����
         -- ================================================
              get_point_data(
                 iv_employee_cd      =>   get_eigyo_date_rec.employee_number
                ,iv_busyo_cd         =>   lv_busyo_cd
                ,iv_shikaku_cd       =>   get_eigyo_date_rec.new_shikaku_cd
                ,iv_syokumu_cd       =>   get_eigyo_date_rec.new_syokumu_cd
                ,on_shikaku_point    =>   ln_shikaku_point
                ,ov_errbuf           =>   lv_errbuf
                ,ov_retcode          =>   lv_retcode
                ,ov_errmsg           =>   lv_errmsg
                );
                -- �G���[�Ȃ�΁A�������X�L�b�v����B
                IF (lv_retcode = cv_status_error) THEN
                  RAISE global_process_expt;
                END IF;
                IF (lv_retcode = cv_status_warn) THEN
                  RAISE global_skip_expt;
                END IF;
        -- ======================================
        -- ���R�[�h�폜����
        -- ======================================
              del_rireki_tbl_data(
                 iv_employee_num      => get_eigyo_date_rec.employee_number              -- �]�ƈ���
                ,ov_errbuf            => lv_errbuf                                       -- �G���[�E���b�Z�[�W
                ,ov_retcode           => lv_retcode                                      -- ���^�[���E�R�[�h
                ,ov_errmsg            => lv_errmsg                                       -- ���[�U�[�E�G���[�E���b�Z�[�W
                );
                -- �G���[�Ȃ�΁A�������X�L�b�v����B
                IF (lv_retcode = cv_status_error) THEN
                  RAISE global_process_expt;
                END IF;
                IF (lv_retcode = cv_status_warn) THEN
                  RAISE global_skip_expt;
                END IF;
        -- ======================================
        -- ���R�[�h�V�K�ǉ�����
        -- ======================================
              insert_rireki_tbl_data (
                 iv_employee_num      => get_eigyo_date_rec.employee_number              -- �]�ƈ���
                ,in_shikaku_point     => ln_shikaku_point                                -- ���i�|�C���g
                ,iv_busyo_cd          => lv_busyo_cd                                     -- �����R�[�h
                ,iv_syokumu_cd        => get_eigyo_date_rec.new_syokumu_cd               -- �E���R�[�h
                ,iv_shikaku_cd        => get_eigyo_date_rec.new_shikaku_cd               -- ���i�R�[�h
                ,iv_kyoten_cd         => get_eigyo_date_rec.new_kyoten_cd                -- ���_�R�[�h
                ,ov_errbuf            => lv_errbuf                                       -- �G���[�E���b�Z�[�W
                ,ov_retcode           => lv_retcode                                      -- ���^�[���E�R�[�h
                ,ov_errmsg            => lv_errmsg                                       -- ���[�U�[�E�G���[�E���b�Z�[�W
                );
                -- �G���[�Ȃ�΁A�������X�L�b�v����B
                IF (lv_retcode = cv_status_error) THEN
                  RAISE global_process_expt;
                END IF;
                IF (lv_retcode = cv_status_warn) THEN
                  RAISE global_skip_expt;
                END IF;
            ELSE
--//+ADD END 2009/08/24 0001150 T.Tsukino
            -- ================================================
            -- (�V�f�[�^)�����f�[�^�̒��o����
            -- ================================================
            get_dept_data(
              iv_employee_cd      =>   get_eigyo_date_rec.employee_number
             ,iv_kyoten_cd        =>   get_eigyo_date_rec.new_kyoten_cd
             ,ov_busyo_cd         =>   lv_new_busyo_cd
             ,ov_errbuf           =>   lv_errbuf
             ,ov_retcode          =>   lv_retcode
             ,ov_errmsg           =>   lv_errmsg
             );
            -- �G���[�Ȃ�΁A�������X�L�b�v����B
--//+ADD START 2009/07/14 0000663 M.Ohtsuki
            IF (lv_retcode = cv_status_error) THEN
              RAISE global_process_expt;
            END IF;
--//+ADD END   2009/07/14 0000663 M.Ohtsuki            
--//+UPD START 2009/07/14 0000663 M.Ohtsuki
--            IF (lv_retcode <> cv_status_normal) THEN
--��������������������������������������������������������������������������������������������������
            IF (lv_retcode = cv_status_warn) THEN
--//+UPD END   2009/07/14 0000663 M.Ohtsuki
              RAISE global_skip_expt;
            END IF;
            -- ================================================
            -- (�V�f�[�^)���i�|�C���g�Z�o����
            -- ================================================
            get_point_data(
               iv_employee_cd      =>   get_eigyo_date_rec.employee_number
              ,iv_busyo_cd         =>   lv_new_busyo_cd
              ,iv_shikaku_cd       =>   get_eigyo_date_rec.new_shikaku_cd
              ,iv_syokumu_cd       =>   get_eigyo_date_rec.new_syokumu_cd
              ,on_shikaku_point    =>   ln_new_shikaku_point
              ,ov_errbuf           =>   lv_errbuf
              ,ov_retcode          =>   lv_retcode
              ,ov_errmsg           =>   lv_errmsg
              );
            -- �G���[�Ȃ�΁A�������X�L�b�v����B
--//+ADD START 2009/07/14 0000663 M.Ohtsuki
            IF (lv_retcode = cv_status_error) THEN
              RAISE global_process_expt;
            END IF;
--//+ADD END   2009/07/14 0000663 M.Ohtsuki            
--//+UPD START 2009/07/14 0000663 M.Ohtsuki
--            IF (lv_retcode <> cv_status_normal) THEN
--��������������������������������������������������������������������������������������������������
            IF (lv_retcode = cv_status_warn) THEN
--//+UPD END   2009/07/14 0000663 M.Ohtsuki
              RAISE global_skip_expt;
            END IF;
            --���̃f�[�^�擾
            -- ================================================
            -- (���f�[�^)�����f�[�^�̒��o����
            -- ================================================
            get_dept_data(
               iv_employee_cd      =>   get_eigyo_date_rec.employee_number
              ,iv_kyoten_cd        =>   get_eigyo_date_rec.old_kyoten_cd
              ,ov_busyo_cd         =>   lv_old_busyo_cd
              ,ov_errbuf           =>   lv_errbuf
              ,ov_retcode          =>   lv_retcode
              ,ov_errmsg           =>   lv_errmsg
              );
            -- �G���[�Ȃ�΁A�������X�L�b�v����B
--//+ADD START 2009/07/14 0000663 M.Ohtsuki
            IF (lv_retcode = cv_status_error) THEN
              RAISE global_process_expt;
            END IF;
--//+ADD END   2009/07/14 0000663 M.Ohtsuki            
--//+UPD START 2009/07/14 0000663 M.Ohtsuki
--            IF (lv_retcode <> cv_status_normal) THEN
--��������������������������������������������������������������������������������������������������
            IF (lv_retcode = cv_status_warn) THEN
--//+UPD END   2009/07/14 0000663 M.Ohtsuki
              RAISE global_skip_expt;
            END IF;
            -- ================================================
            -- (���f�[�^)���i�|�C���g�Z�o����
            -- ================================================
            get_point_data(
               iv_employee_cd      =>   get_eigyo_date_rec.employee_number
              ,iv_busyo_cd         =>   lv_old_busyo_cd
              ,iv_shikaku_cd       =>   get_eigyo_date_rec.old_shikaku_cd
              ,iv_syokumu_cd       =>   get_eigyo_date_rec.old_syokumu_cd
              ,on_shikaku_point    =>   ln_old_shikaku_point
              ,ov_errbuf           =>   lv_errbuf
              ,ov_retcode          =>   lv_retcode
              ,ov_errmsg           =>   lv_errmsg
              );
            -- �G���[�Ȃ�΁A�������X�L�b�v����B
--//+ADD START 2009/07/14 0000663 M.Ohtsuki
            IF (lv_retcode = cv_status_error) THEN
              RAISE global_process_expt;
            END IF;
--//+ADD END   2009/07/14 0000663 M.Ohtsuki            
--//+UPD START 2009/07/14 0000663 M.Ohtsuki
--            IF (lv_retcode <> cv_status_normal) THEN
--��������������������������������������������������������������������������������������������������
            IF (lv_retcode = cv_status_warn) THEN
--//+UPD END   2009/07/14 0000663 M.Ohtsuki
              RAISE global_skip_expt;
            END IF;
            --<<�V/���f�[�^�̎��i�|�C���g�̔�r>>---------------------------------------------------
            --�V�f�[�^�̎��i�|�C���g�����f�[�^�̎��i�|�C���g�ȉ��̏ꍇ�A�V�f�[�^�̒l����
            IF (ln_new_shikaku_point <= ln_old_shikaku_point) THEN
                ln_shikaku_point  :=  ln_new_shikaku_point;                     -- ���i�|�C���g
                lv_busyo_cd       :=  lv_new_busyo_cd;                          -- �����R�[�h
                lv_syokumu_cd     :=  get_eigyo_date_rec.new_syokumu_cd;        -- �E���R�[�h
                lv_shikaku_cd     :=  get_eigyo_date_rec.new_shikaku_cd;        -- ���i�R�[�h
                lv_kyoten_cd      :=  get_eigyo_date_rec.new_kyoten_cd;         -- ���_�R�[�h
            --�V�f�[�^�̎��i�|�C���g��苌�f�[�^�̎��i�|�C���g���Ⴂ�ꍇ�A���f�[�^�̒l����
            ELSE
                ln_shikaku_point  :=  ln_old_shikaku_point;                     -- ���i�|�C���g
                lv_busyo_cd       :=  lv_old_busyo_cd;                          -- �����R�[�h
                lv_syokumu_cd     :=  get_eigyo_date_rec.old_syokumu_cd;        -- �E���R�[�h
                lv_shikaku_cd     :=  get_eigyo_date_rec.old_shikaku_cd;        -- ���i�R�[�h
                lv_kyoten_cd      :=  get_eigyo_date_rec.old_kyoten_cd;         -- ���_�R�[�h
            END IF;
           --<<�V/���f�[�^�̎��i�|�C���g�̔�r/�I���>>---------------------------------------------------
            -- ======================================
            -- ���R�[�h�폜����
            -- ======================================
            del_rireki_tbl_data(
               iv_employee_num      => get_eigyo_date_rec.employee_number              -- �]�ƈ���
              ,ov_errbuf            => lv_errbuf                                       -- �G���[�E���b�Z�[�W
              ,ov_retcode           => lv_retcode                                      -- ���^�[���E�R�[�h
              ,ov_errmsg            => lv_errmsg                                       -- ���[�U�[�E�G���[�E���b�Z�[�W
              );
            -- �G���[�Ȃ�΁A�������X�L�b�v����B
--//+ADD START 2009/07/14 0000663 M.Ohtsuki
            IF (lv_retcode = cv_status_error) THEN
              RAISE global_process_expt;
            END IF;
--//+ADD END   2009/07/14 0000663 M.Ohtsuki            
--//+UPD START 2009/07/14 0000663 M.Ohtsuki
--            IF (lv_retcode <> cv_status_normal) THEN
--��������������������������������������������������������������������������������������������������
            IF (lv_retcode = cv_status_warn) THEN
--//+UPD END   2009/07/14 0000663 M.Ohtsuki
              RAISE global_skip_expt;
            END IF;
            -- ======================================
            -- ���R�[�h�V�K�ǉ�����
            -- ======================================
            insert_rireki_tbl_data (
               iv_employee_num      => get_eigyo_date_rec.employee_number              -- �]�ƈ���
              ,in_shikaku_point     => ln_shikaku_point                                -- ���i�|�C���g
              ,iv_busyo_cd          => lv_busyo_cd                                     -- �����R�[�h
              ,iv_syokumu_cd        => lv_syokumu_cd                                   -- �E���R�[�h
              ,iv_shikaku_cd        => lv_shikaku_cd                                   -- ���i�R�[�h
              ,iv_kyoten_cd         => lv_kyoten_cd                                    -- ���_�R�[�h
              ,ov_errbuf            => lv_errbuf                                       -- �G���[�E���b�Z�[�W
              ,ov_retcode           => lv_retcode                                      -- ���^�[���E�R�[�h
              ,ov_errmsg            => lv_errmsg                                       -- ���[�U�[�E�G���[�E���b�Z�[�W
              );
            -- �G���[�Ȃ�΁A�������X�L�b�v����B
--//+ADD START 2009/07/14 0000663 M.Ohtsuki
            IF (lv_retcode = cv_status_error) THEN
              RAISE global_process_expt;
            END IF;
--//+ADD END   2009/07/14 0000663 M.Ohtsuki            
--//+UPD START 2009/07/14 0000663 M.Ohtsuki
--            IF (lv_retcode <> cv_status_normal) THEN
--��������������������������������������������������������������������������������������������������
            IF (lv_retcode = cv_status_warn) THEN
--//+UPD END   2009/07/14 0000663 M.Ohtsuki
              RAISE global_skip_expt;
            END IF;
--//+ADD START 2009/08/24 0001150 T.Tsukino
            END IF;
--//+ADD END 2009/08/24 0001150 T.Tsukino
          --���i�|�C���g���o    �����s�v�̏ꍇ�@
          --�V�f�[�^�̂ݎ擾
          ELSIF (get_eigyo_date_rec.new_syokusyu_cd IS NOT NULL
            AND get_eigyo_date_rec.old_syokusyu_cd IS NULL) THEN
        -- ��================================��
        --  �V�̏����ɂāA
        --  �@�����R�[�h���o
        --  �A���R�[�h�̍폜
        --  �B���R�[�h�̐V�K�ǉ����s��
        -- ��================================��
            --�V�f�[�^�̑��
            -- ================================================
            -- (�V�f�[�^)�����f�[�^�̒��o����
            -- ================================================
            get_dept_data(
               iv_employee_cd      =>   get_eigyo_date_rec.employee_number
              ,iv_kyoten_cd        =>   get_eigyo_date_rec.new_kyoten_cd
              ,ov_busyo_cd         =>   lv_busyo_cd
              ,ov_errbuf           =>   lv_errbuf
              ,ov_retcode          =>   lv_retcode
              ,ov_errmsg           =>   lv_errmsg
              );
            -- �G���[�Ȃ�΁A�������X�L�b�v����B
--//+ADD START 2009/07/14 0000663 M.Ohtsuki
            IF (lv_retcode = cv_status_error) THEN
              RAISE global_process_expt;
            END IF;
--//+ADD END   2009/07/14 0000663 M.Ohtsuki            
--//+UPD START 2009/07/14 0000663 M.Ohtsuki
--            IF (lv_retcode <> cv_status_normal) THEN
--��������������������������������������������������������������������������������������������������
            IF (lv_retcode = cv_status_warn) THEN
--//+UPD END   2009/07/14 0000663 M.Ohtsuki
              RAISE global_skip_expt;
            END IF;
            -- ======================================
            -- ���R�[�h�폜����
            -- ======================================
            del_rireki_tbl_data(
               iv_employee_num      => get_eigyo_date_rec.employee_number              -- �]�ƈ���
              ,ov_errbuf            => lv_errbuf                                       -- �G���[�E���b�Z�[�W
              ,ov_retcode           => lv_retcode                                      -- ���^�[���E�R�[�h
              ,ov_errmsg            => lv_errmsg                                       -- ���[�U�[�E�G���[�E���b�Z�[�W
              );
            -- �G���[�Ȃ�΁A�������X�L�b�v����B
--//+ADD START 2009/07/14 0000663 M.Ohtsuki
            IF (lv_retcode = cv_status_error) THEN
              RAISE global_process_expt;
            END IF;
--//+ADD END   2009/07/14 0000663 M.Ohtsuki            
--//+UPD START 2009/07/14 0000663 M.Ohtsuki
--            IF (lv_retcode <> cv_status_normal) THEN
--��������������������������������������������������������������������������������������������������
            IF (lv_retcode = cv_status_warn) THEN
--//+UPD END   2009/07/14 0000663 M.Ohtsuki
              RAISE global_skip_expt;
            END IF;
            -- ======================================
            -- ���R�[�h�V�K�ǉ�����
            -- ======================================
            insert_rireki_tbl_data (
               iv_employee_num      => get_eigyo_date_rec.employee_number              -- �]�ƈ���
              ,in_shikaku_point     => cn_shikaku_point                                -- ���i�|�C���g
              ,iv_busyo_cd          => lv_busyo_cd                                     -- �����R�[�h
              ,iv_syokumu_cd        => get_eigyo_date_rec.new_syokumu_cd               -- �E���R�[�h
              ,iv_shikaku_cd        => get_eigyo_date_rec.new_shikaku_cd               -- ���i�R�[�h
              ,iv_kyoten_cd         => get_eigyo_date_rec.new_kyoten_cd                -- ���_�R�[�h
              ,ov_errbuf            => lv_errbuf                                       -- �G���[�E���b�Z�[�W
              ,ov_retcode           => lv_retcode                                      -- ���^�[���E�R�[�h
              ,ov_errmsg            => lv_errmsg                                       -- ���[�U�[�E�G���[�E���b�Z�[�W
              );
            -- �G���[�Ȃ�΁A�������X�L�b�v����B
--//+ADD START 2009/07/14 0000663 M.Ohtsuki
            IF (lv_retcode = cv_status_error) THEN
              RAISE global_process_expt;
            END IF;
--//+ADD END   2009/07/14 0000663 M.Ohtsuki            
--//+UPD START 2009/07/14 0000663 M.Ohtsuki
--            IF (lv_retcode <> cv_status_normal) THEN
--��������������������������������������������������������������������������������������������������
            IF (lv_retcode = cv_status_warn) THEN
--//+UPD END   2009/07/14 0000663 M.Ohtsuki
              RAISE global_skip_expt;
            END IF;
          --���i�|�C���g���o�����s�v�̏ꍇ�A
          --���f�[�^�̂ݎ擾
          ELSIF (get_eigyo_date_rec.old_syokusyu_cd IS NOT NULL
            AND get_eigyo_date_rec.new_syokusyu_cd IS NULL) THEN
        -- ��================================��
        --  ���̏����ɂāA
        --  �@�����R�[�h���o
        --  �A���R�[�h�̍폜
        --  �B���R�[�h�̐V�K�ǉ����s��
        -- ��================================��
        --���̃f�[�^�擾
            -- ================================================
            -- (���f�[�^)�����f�[�^�̒��o����
            -- ================================================
            get_dept_data(
               iv_employee_cd      =>   get_eigyo_date_rec.employee_number
              ,iv_kyoten_cd        =>   get_eigyo_date_rec.old_kyoten_cd
              ,ov_busyo_cd         =>   lv_busyo_cd
              ,ov_errbuf           =>   lv_errbuf
              ,ov_retcode          =>   lv_retcode
              ,ov_errmsg           =>   lv_errmsg
              );
            -- �G���[�Ȃ�΁A�������X�L�b�v����B
--//+ADD START 2009/07/14 0000663 M.Ohtsuki
            IF (lv_retcode = cv_status_error) THEN
              RAISE global_process_expt;
            END IF;
--//+ADD END   2009/07/14 0000663 M.Ohtsuki            
--//+UPD START 2009/07/14 0000663 M.Ohtsuki
--            IF (lv_retcode <> cv_status_normal) THEN
--��������������������������������������������������������������������������������������������������
            IF (lv_retcode = cv_status_warn) THEN
--//+UPD END   2009/07/14 0000663 M.Ohtsuki
              RAISE global_skip_expt;
            END IF;
            -- ======================================
            -- ���R�[�h�폜����
            -- ======================================
            del_rireki_tbl_data(
               iv_employee_num      => get_eigyo_date_rec.employee_number              -- �]�ƈ���
              ,ov_errbuf            => lv_errbuf                                       -- �G���[�E���b�Z�[�W
              ,ov_retcode           => lv_retcode                                      -- ���^�[���E�R�[�h
              ,ov_errmsg            => lv_errmsg                                       -- ���[�U�[�E�G���[�E���b�Z�[�W
              );
            -- �G���[�Ȃ�΁A�������X�L�b�v����B
--//+ADD START 2009/07/14 0000663 M.Ohtsuki
            IF (lv_retcode = cv_status_error) THEN
              RAISE global_process_expt;
            END IF;
--//+ADD END   2009/07/14 0000663 M.Ohtsuki            
--//+UPD START 2009/07/14 0000663 M.Ohtsuki
--            IF (lv_retcode <> cv_status_normal) THEN
--��������������������������������������������������������������������������������������������������
            IF (lv_retcode = cv_status_warn) THEN
--//+UPD END   2009/07/14 0000663 M.Ohtsuki
              RAISE global_skip_expt;
            END IF;
            -- ======================================
            -- ���R�[�h�V�K�ǉ�����
            -- ======================================
            insert_rireki_tbl_data (
               iv_employee_num      => get_eigyo_date_rec.employee_number              -- �]�ƈ���
              ,in_shikaku_point     => cn_shikaku_point                                -- ���i�|�C���g
              ,iv_busyo_cd          => lv_busyo_cd                                     -- �����R�[�h
              ,iv_syokumu_cd        => get_eigyo_date_rec.old_syokumu_cd               -- �E���R�[�h
              ,iv_shikaku_cd        => get_eigyo_date_rec.old_shikaku_cd               -- ���i�R�[�h
              ,iv_kyoten_cd         => get_eigyo_date_rec.old_kyoten_cd                -- ���_�R�[�h
              ,ov_errbuf            => lv_errbuf                                       -- �G���[�E���b�Z�[�W
              ,ov_retcode           => lv_retcode                                      -- ���^�[���E�R�[�h
              ,ov_errmsg            => lv_errmsg                                       -- ���[�U�[�E�G���[�E���b�Z�[�W
              );
            -- �G���[�Ȃ�΁A�������X�L�b�v����B
--//+ADD START 2009/07/14 0000663 M.Ohtsuki
            IF (lv_retcode = cv_status_error) THEN
              RAISE global_process_expt;
            END IF;
--//+ADD END   2009/07/14 0000663 M.Ohtsuki            
--//+UPD START 2009/07/14 0000663 M.Ohtsuki
--            IF (lv_retcode <> cv_status_normal) THEN
--��������������������������������������������������������������������������������������������������
            IF (lv_retcode = cv_status_warn) THEN
--//+UPD END   2009/07/14 0000663 M.Ohtsuki
              RAISE global_skip_expt;
            END IF;
          END IF;
--//+UPD START 2009/08/24 0001150 T.Tsukino        
--������������������������������������������������������������������������������������������������������������������������
--        ELSIF (get_eigyo_date_rec.hatsureibi > gv_inprocess_date) THEN            -- ���ߓ������͓��t'YYYYMM'
        ELSIF (SUBSTRB(get_eigyo_date_rec.hatsureibi,1,6) > gv_inprocess_date) THEN            -- ���ߓ������͓��t'YYYYMM'
--//+UPD END 2009/08/24 0001150 T.Tsukino          
        -- ��================================��
        --  ���̏����ɂāA
        --  �@�����R�[�h���o/���i�|�C���g�̎Z�o
        --  �A���R�[�h�̍폜
        --  �B���R�[�h�̐V�K�ǉ����s��
        -- ��================================��
         --���f�[�^�̑��
         -- ================================================
         -- (���f�[�^)�����f�[�^�̒��o����
         -- ================================================
          get_dept_data(
             iv_employee_cd      =>   get_eigyo_date_rec.employee_number
            ,iv_kyoten_cd        =>   get_eigyo_date_rec.old_kyoten_cd
            ,ov_busyo_cd         =>   lv_busyo_cd
            ,ov_errbuf           =>   lv_errbuf
            ,ov_retcode          =>   lv_retcode
            ,ov_errmsg           =>   lv_errmsg
            );
            -- �G���[�Ȃ�΁A�������X�L�b�v����B
--//+ADD START 2009/07/14 0000663 M.Ohtsuki
            IF (lv_retcode = cv_status_error) THEN
              RAISE global_process_expt;
            END IF;
--//+ADD END   2009/07/14 0000663 M.Ohtsuki            
--//+UPD START 2009/07/14 0000663 M.Ohtsuki
--            IF (lv_retcode <> cv_status_normal) THEN
--��������������������������������������������������������������������������������������������������
            IF (lv_retcode = cv_status_warn) THEN
--//+UPD END   2009/07/14 0000663 M.Ohtsuki
              RAISE global_skip_expt;
            END IF;
         -- ================================================
         -- (���f�[�^)���i�|�C���g�Z�o����
         -- ================================================
          get_point_data(
             iv_employee_cd      =>   get_eigyo_date_rec.employee_number
            ,iv_busyo_cd         =>   lv_busyo_cd
            ,iv_shikaku_cd       =>   get_eigyo_date_rec.old_shikaku_cd
            ,iv_syokumu_cd       =>   get_eigyo_date_rec.old_syokumu_cd
            ,on_shikaku_point    =>   ln_shikaku_point
            ,ov_errbuf           =>   lv_errbuf
            ,ov_retcode          =>   lv_retcode
            ,ov_errmsg           =>   lv_errmsg
            );
            -- �G���[�Ȃ�΁A�������X�L�b�v����B
--//+ADD START 2009/07/14 0000663 M.Ohtsuki
            IF (lv_retcode = cv_status_error) THEN
              RAISE global_process_expt;
            END IF;
--//+ADD END   2009/07/14 0000663 M.Ohtsuki            
--//+UPD START 2009/07/14 0000663 M.Ohtsuki
--            IF (lv_retcode <> cv_status_normal) THEN
--��������������������������������������������������������������������������������������������������
            IF (lv_retcode = cv_status_warn) THEN
--//+UPD END   2009/07/14 0000663 M.Ohtsuki
              RAISE global_skip_expt;
            END IF;
        -- ======================================
        -- ���R�[�h�폜����
        -- ======================================
          del_rireki_tbl_data(
             iv_employee_num      => get_eigyo_date_rec.employee_number                                  -- �]�ƈ���
            ,ov_errbuf            => lv_errbuf                                       -- �G���[�E���b�Z�[�W
            ,ov_retcode           => lv_retcode                                      -- ���^�[���E�R�[�h
            ,ov_errmsg            => lv_errmsg                                       -- ���[�U�[�E�G���[�E���b�Z�[�W
            );
            -- �G���[�Ȃ�΁A�������X�L�b�v����B
--//+ADD START 2009/07/14 0000663 M.Ohtsuki
            IF (lv_retcode = cv_status_error) THEN
              RAISE global_process_expt;
            END IF;
--//+ADD END   2009/07/14 0000663 M.Ohtsuki            
--//+UPD START 2009/07/14 0000663 M.Ohtsuki
--            IF (lv_retcode <> cv_status_normal) THEN
--��������������������������������������������������������������������������������������������������
            IF (lv_retcode = cv_status_warn) THEN
--//+UPD END   2009/07/14 0000663 M.Ohtsuki
              RAISE global_skip_expt;
            END IF;
        -- ======================================
        -- ���R�[�h�V�K�ǉ�����
        -- ======================================
          insert_rireki_tbl_data (
             iv_employee_num      => get_eigyo_date_rec.employee_number                                  -- �]�ƈ���
            ,in_shikaku_point     => ln_shikaku_point                                -- ���i�|�C���g
            ,iv_busyo_cd          => lv_busyo_cd                                     -- �����R�[�h
            ,iv_syokumu_cd        => get_eigyo_date_rec.old_syokumu_cd               -- �E���R�[�h
            ,iv_shikaku_cd        => get_eigyo_date_rec.old_shikaku_cd               -- ���i�R�[�h
            ,iv_kyoten_cd         => get_eigyo_date_rec.old_kyoten_cd                -- ���_�R�[�h
            ,ov_errbuf            => lv_errbuf                                       -- �G���[�E���b�Z�[�W
            ,ov_retcode           => lv_retcode                                      -- ���^�[���E�R�[�h
            ,ov_errmsg            => lv_errmsg                                       -- ���[�U�[�E�G���[�E���b�Z�[�W
            );
            -- �G���[�Ȃ�΁A�������X�L�b�v����B
--//+ADD START 2009/07/14 0000663 M.Ohtsuki
            IF (lv_retcode = cv_status_error) THEN
              RAISE global_process_expt;
            END IF;
--//+ADD END   2009/07/14 0000663 M.Ohtsuki            
--//+UPD START 2009/07/14 0000663 M.Ohtsuki
--            IF (lv_retcode <> cv_status_normal) THEN
--��������������������������������������������������������������������������������������������������
            IF (lv_retcode = cv_status_warn) THEN
--//+UPD END   2009/07/14 0000663 M.Ohtsuki
              RAISE global_skip_expt;
            END IF;
--//+UPD START 2009/08/24 0001150 T.Tsukino        
--������������������������������������������������������������������������������������������������������������������������
--        ELSIF (get_eigyo_date_rec.hatsureibi < gv_inprocess_date) THEN            -- ���ߓ������͓��t'YYYYMM'
        ELSIF (SUBSTRB(get_eigyo_date_rec.hatsureibi,1,6) < gv_inprocess_date) THEN            -- ���ߓ������͓��t'YYYYMM'
--//+UPD END 2009/08/24 0001150 T.Tsukino
        -- ��================================��
        --  �V�̏����ɂāA
        --  �@�����R�[�h���o/���i�|�C���g�̎Z�o
        --  �A���R�[�h�̍폜
        --  �B���R�[�h�̐V�K�ǉ����s��
        -- ��================================��
            --�V�f�[�^�̑��
         -- ================================================
         -- �i�V�f�[�^)�����f�[�^�̒��o����
         -- ================================================
          get_dept_data(
             iv_employee_cd      =>   get_eigyo_date_rec.employee_number
            ,iv_kyoten_cd        =>   get_eigyo_date_rec.new_kyoten_cd
            ,ov_busyo_cd         =>   lv_busyo_cd
            ,ov_errbuf           =>   lv_errbuf
            ,ov_retcode          =>   lv_retcode
            ,ov_errmsg           =>   lv_errmsg
            );
            -- �G���[�Ȃ�΁A�������X�L�b�v����B
--//+ADD START 2009/07/14 0000663 M.Ohtsuki
            IF (lv_retcode = cv_status_error) THEN
              RAISE global_process_expt;
            END IF;
--//+ADD END   2009/07/14 0000663 M.Ohtsuki            
--//+UPD START 2009/07/14 0000663 M.Ohtsuki
--            IF (lv_retcode <> cv_status_normal) THEN
--��������������������������������������������������������������������������������������������������
            IF (lv_retcode = cv_status_warn) THEN
--//+UPD END   2009/07/14 0000663 M.Ohtsuki
              RAISE global_skip_expt;
            END IF;
         -- ================================================
         -- (�V�f�[�^)���i�|�C���g�Z�o����
         -- ================================================
          get_point_data(
             iv_employee_cd      =>   get_eigyo_date_rec.employee_number
            ,iv_busyo_cd         =>   lv_busyo_cd
            ,iv_shikaku_cd       =>   get_eigyo_date_rec.new_shikaku_cd
            ,iv_syokumu_cd       =>   get_eigyo_date_rec.new_syokumu_cd
            ,on_shikaku_point    =>   ln_shikaku_point
            ,ov_errbuf           =>   lv_errbuf
            ,ov_retcode          =>   lv_retcode
            ,ov_errmsg           =>   lv_errmsg
            );
            -- �G���[�Ȃ�΁A�������X�L�b�v����B
--//+ADD START 2009/07/14 0000663 M.Ohtsuki
            IF (lv_retcode = cv_status_error) THEN
              RAISE global_process_expt;
            END IF;
--//+ADD END   2009/07/14 0000663 M.Ohtsuki            
--//+UPD START 2009/07/14 0000663 M.Ohtsuki
--            IF (lv_retcode <> cv_status_normal) THEN
--��������������������������������������������������������������������������������������������������
            IF (lv_retcode = cv_status_warn) THEN
--//+UPD END   2009/07/14 0000663 M.Ohtsuki
              RAISE global_skip_expt;
            END IF;
        -- ======================================
        -- ���R�[�h�폜����
        -- ======================================
          del_rireki_tbl_data(
             iv_employee_num      => get_eigyo_date_rec.employee_number                                  -- �]�ƈ���
            ,ov_errbuf            => lv_errbuf                                       -- �G���[�E���b�Z�[�W
            ,ov_retcode           => lv_retcode                                      -- ���^�[���E�R�[�h
            ,ov_errmsg            => lv_errmsg                                       -- ���[�U�[�E�G���[�E���b�Z�[�W
            );
            -- �G���[�Ȃ�΁A�������X�L�b�v����B
--//+ADD START 2009/07/14 0000663 M.Ohtsuki
            IF (lv_retcode = cv_status_error) THEN
              RAISE global_process_expt;
            END IF;
--//+ADD END   2009/07/14 0000663 M.Ohtsuki            
--//+UPD START 2009/07/14 0000663 M.Ohtsuki
--            IF (lv_retcode <> cv_status_normal) THEN
--��������������������������������������������������������������������������������������������������
            IF (lv_retcode = cv_status_warn) THEN
--//+UPD END   2009/07/14 0000663 M.Ohtsuki
              RAISE global_skip_expt;
            END IF;
        -- ======================================
        -- ���R�[�h�V�K�ǉ�����
        -- ======================================
          insert_rireki_tbl_data (
             iv_employee_num      => get_eigyo_date_rec.employee_number              -- �]�ƈ���
            ,in_shikaku_point     => ln_shikaku_point                                -- ���i�|�C���g
            ,iv_busyo_cd          => lv_busyo_cd                                     -- �����R�[�h
            ,iv_syokumu_cd        => get_eigyo_date_rec.new_syokumu_cd               -- �E���R�[�h
            ,iv_shikaku_cd        => get_eigyo_date_rec.new_shikaku_cd               -- ���i�R�[�h
            ,iv_kyoten_cd         => get_eigyo_date_rec.new_kyoten_cd                -- ���_�R�[�h
            ,ov_errbuf            => lv_errbuf                                       -- �G���[�E���b�Z�[�W
            ,ov_retcode           => lv_retcode                                      -- ���^�[���E�R�[�h
            ,ov_errmsg            => lv_errmsg                                       -- ���[�U�[�E�G���[�E���b�Z�[�W
            );
            -- �G���[�Ȃ�΁A�������X�L�b�v����B
--//+ADD START 2009/07/14 0000663 M.Ohtsuki
            IF (lv_retcode = cv_status_error) THEN
              RAISE global_process_expt;
            END IF;
--//+ADD END   2009/07/14 0000663 M.Ohtsuki            
--//+UPD START 2009/07/14 0000663 M.Ohtsuki
--            IF (lv_retcode <> cv_status_normal) THEN
--��������������������������������������������������������������������������������������������������
            IF (lv_retcode = cv_status_warn) THEN
--//+UPD END   2009/07/14 0000663 M.Ohtsuki
              RAISE global_skip_expt;
            END IF;
        END IF;
        -- ���팏���J�E���g�A�b�v
        gn_normal_cnt := gn_normal_cnt + 1;
      EXCEPTION
        WHEN global_skip_expt THEN
          ov_retcode := cv_status_warn;
          --�G���[�o��
          fnd_file.put_line(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_errmsg                                                    -- ���[�U�[�E�G���[���b�Z�[�W
          );
          fnd_file.put_line(
             which  => FND_FILE.LOG
            ,buff   => lv_errbuf                                                    -- �G���[���b�Z�[�W
          );
          --�G���[�����̃J�E���g
          gn_error_cnt := gn_error_cnt + 1;
          -- ���[���o�b�N
          ROLLBACK TO eigyo_date_sv;
        WHEN no_data_hatsurei THEN
          ov_retcode := cv_status_warn;
          -- �G���[���b�Z�[�W�擾
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_app_name                            --�A�v���P�[�V�����Z�k��
                         ,iv_name         => cv_xxcsm_msg_125                       --���b�Z�[�W�R�[�h
                         ,iv_token_name1  => cv_tkn_jugyoin_cd                      --�g�[�N���R�[�h1
                         ,iv_token_value1 => get_eigyo_date_rec.employee_number     --�g�[�N���l1
                       );
          ov_errmsg  := lv_errmsg;
          ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,4000);
          --�G���[�o��
          fnd_file.put_line(
             which  => FND_FILE.OUTPUT
            ,buff   => ov_errmsg                                                    -- ���[�U�[�E�G���[���b�Z�[�W
          );
          fnd_file.put_line(
             which  => FND_FILE.LOG
            ,buff   => ov_errbuf                                                    -- �G���[���b�Z�[�W
          );
          --�G���[�����̃J�E���g
          gn_error_cnt := gn_error_cnt + 1;
          -- ���[���o�b�N
          ROLLBACK TO eigyo_date_sv; 
      END;
    END LOOP get_eigyo_date_loop;
--
    -- �J�[�\���N���[�Y
    CLOSE get_eigyo_date_cur;
    -- �����Ώی�����0���̏ꍇ
    IF (gn_target_cnt = 0) THEN
      RAISE no_data_expt;
    END IF;
  EXCEPTION
    -- *** �����Ώۃf�[�^0����O�n���h�� ***
    WHEN no_data_expt THEN
      -- �G���[���b�Z�[�W�擾
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                            --�A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_xxcsm_msg_120                       --���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_process                         --�g�[�N���R�[�h1
                     ,iv_token_value1 => gv_inprocess_date                      --�g�[�N���l1
                   );
      lv_errbuf := lv_errmsg;
      -- �G���[�����J�E���g
      gn_error_cnt := gn_error_cnt + 1;
      -- �J�[�\�����N���[�Y����Ă��Ȃ��ꍇ
      IF (get_eigyo_date_cur%ISOPEN) THEN
        -- �J�[�\���N���[�Y
        CLOSE get_eigyo_date_cur;
      END IF;
      --�G���[�o��
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg                                                    -- ���[�U�[�E�G���[���b�Z�[�W
      );
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
    ,iv_process_date  IN  VARCHAR2)                                                                   -- �������t
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
       iv_process_date  => iv_process_date
      ,ov_errbuf        => lv_errbuf                                            -- �G���[�E���b�Z�[�W
      ,ov_retcode       => lv_retcode                                           -- ���^�[���E�R�[�h
      ,ov_errmsg        => lv_errmsg                                            -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
--
    IF (lv_retcode = cv_status_error) THEN
      IF lv_errmsg IS NULL THEN
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
      gn_error_cnt := 1;
      gn_warn_cnt := 0;
    END IF;
--
    -- =======================
    -- A-6.�I������
    -- =======================
    --��s�̏o��
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
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
END XXCSM004A03C;
/
