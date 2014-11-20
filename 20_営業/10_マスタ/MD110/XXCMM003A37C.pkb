CREATE OR REPLACE PACKAGE BODY xxcmm003a37c
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2009. All rights reserved.
 *
 * Package Name     : XXCMM003A37C(body)
 * Description      : �`�F�[���}�X�^�A�gIF�f�[�^�쐬
 * MD.050           : MD050_CMM_003_A37_�`�F�[���}�X�^�A�gIF�f�[�^�쐬
 * Version          : 1.2
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   ��������(A-1)
 *  file_open              �t�@�C���I�[�v������(A-2)
 *  output_chain_data      �����Ώۃf�[�^���o����(A-3)�ECSV�t�@�C���o�͏���(A-4)
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��(A-5 �I������)
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009/02/18    1.0   Yutaka.Kuboshima �V�K�쐬
 *  2009-03-09    1.1   Yutaka.Kuboshima �t�@�C���o�͐�̃v���t�@�C���̕ύX
 *  2011/10/31    1.2   Yasuhiro.Horikawa E_�{�ғ�_08649 �`�F�[���X���̍ő咷�𕶎����J�E���g�ɕύX
 *
 *****************************************************************************************/
--
--#######################  �Œ�O���[�o���萔�錾�� START   #######################
--
  --�X�e�[�^�X�E�R�[�h
  cv_status_normal          CONSTANT VARCHAR2(1)  := xxccp_common_pkg.set_status_normal; --����:0
  cv_status_warn            CONSTANT VARCHAR2(1)  := xxccp_common_pkg.set_status_warn;   --�x��:1
  cv_status_error           CONSTANT VARCHAR2(1)  := xxccp_common_pkg.set_status_error;  --�ُ�:2
  --WHO�J����
  cn_created_by             CONSTANT NUMBER       := fnd_global.user_id;         --CREATED_BY
  cd_creation_date          CONSTANT DATE         := SYSDATE;                    --CREATION_DATE
  cn_last_updated_by        CONSTANT NUMBER       := fnd_global.user_id;         --LAST_UPDATED_BY
  cd_last_update_date       CONSTANT DATE         := SYSDATE;                    --LAST_UPDATE_DATE
  cn_last_update_login      CONSTANT NUMBER       := fnd_global.login_id;        --LAST_UPDATE_LOGIN
  cn_request_id             CONSTANT NUMBER       := fnd_global.conc_request_id; --REQUEST_ID
  cn_program_application_id CONSTANT NUMBER       := fnd_global.prog_appl_id;    --PROGRAM_APPLICATION_ID
  cn_program_id             CONSTANT NUMBER       := fnd_global.conc_program_id; --PROGRAM_ID
  cd_program_update_date    CONSTANT DATE         := SYSDATE;                    --PROGRAM_UPDATE_DATE
--
  gv_xxcmm_msg_kbn          CONSTANT VARCHAR2(5)  := 'XXCMM'; --���b�Z�[�W�敪
  gv_xxccp_msg_kbn          CONSTANT VARCHAR2(5)  := 'XXCCP'; --���b�Z�[�W�敪
--
  cv_msg_part               CONSTANT VARCHAR2(3)  := ' : ';
  cv_msg_cont               CONSTANT VARCHAR2(3)  := '.';
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
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gv_out_file_dir  VARCHAR2(100);
  gv_out_file_name VARCHAR2(100);
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
  init_err_expt                  EXCEPTION; --���������G���[
  fopen_err_expt                 EXCEPTION; --�t�@�C���I�[�v���G���[
  no_data_err_expt               EXCEPTION; --�Ώۃf�[�^0��
  write_failure_expt             EXCEPTION; --CSV�f�[�^�o�̓G���[
  fclose_err_expt                EXCEPTION; --�t�@�C���N���[�Y�G���[
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name                CONSTANT VARCHAR2(12)  := 'XXCMM003A37C';      -- �p�b�P�[�W��
  cv_comma                   CONSTANT VARCHAR2(1)   := ',';                 -- �J���}
  cv_dqu                     CONSTANT VARCHAR2(1)   := '"';                 -- �����񊇂�
--
  cv_trans_date              CONSTANT VARCHAR2(20)  := 'YYYYMMDDHH24MISS';  -- �A�g���t����
--
  --���b�Z�[�W
  cv_file_name_msg           CONSTANT VARCHAR2(16)  := 'APP-XXCCP1-05102';  -- �t�@�C�����m�[�g
  --�G���[���b�Z�[�W
  cv_profile_err_msg         CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00002';  -- �v���t�@�C���擾�G���[
  cv_file_path_invalid_msg   CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00003';  -- �t�@�C���p�X�s���G���[
  cv_exist_err_msg           CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00010';  -- CSV�t�@�C�����݃`�F�b�N
  cv_write_err_msg           CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00009';  -- CSV�f�[�^�o�̓G���[
  cv_no_data_err_msg         CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00001';  -- �Ώۃf�[�^����
  cv_file_close_err_msg      CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00489';  -- �t�@�C���N���[�Y�G���[
  cv_no_parameter            CONSTANT VARCHAR2(16)  := 'APP-XXCCP1-90008';  -- �R���J�����g���̓p�����[�^�Ȃ�
  --�g�[�N��
  cv_ng_profile              CONSTANT VARCHAR2(10)  := 'NG_PROFILE';        -- �v���t�@�C���擾���s�g�[�N��
  cv_sqlerrm                 CONSTANT VARCHAR2(10)  := 'SQLERRM';           -- �t�@�C���N���[�Y�G���[�g�[�N��
  cv_ng_word                 CONSTANT VARCHAR2(10)  := 'NG_WORD';           -- CSV�o�̓G���[���ږ��̃g�[�N��
  cv_ng_data                 CONSTANT VARCHAR2(10)  := 'NG_DATA';           -- CSV�o�̓G���[���ڒl�g�[�N��
  cv_tkn_filename            CONSTANT VARCHAR2(10)  := 'FILE_NAME';         -- �t�@�C����
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
-- 2009/03/09 modify start
--    cv_out_file_dir  CONSTANT VARCHAR2(30) := 'XXCMM1_003A37_OUT_FILE_DIR';   -- �`�F�[���}�X�^�A�gIF�f�[�^�쐬�pCSV�t�@�C���o�͐�
    cv_out_file_dir  CONSTANT VARCHAR2(30) := 'XXCMM1_JYOHO_OUT_DIR';         --XXCMM:���n(OUTBOUND)�A�g�pCSV�t�@�C���o�͐�
-- 2009/03/09 modify end
    cv_out_file_file CONSTANT VARCHAR2(30) := 'XXCMM1_003A37_OUT_FILE_FIL';   -- �`�F�[���}�X�^�A�gIF�f�[�^�쐬�pCSV�t�@�C����
    cv_invalid_path  CONSTANT VARCHAR2(25) := 'CSV�o�̓f�B���N�g��';          -- �v���t�@�C���擾���s(�f�B���N�g��)
    cv_invalid_name  CONSTANT VARCHAR2(20) := 'CSV�o�̓t�@�C����';            -- �v���t�@�C���擾���s(�t�@�C����)
--
    -- *** ���[�J���ϐ� ***
    lv_file_chk     BOOLEAN;
    ln_file_size    NUMBER;
    ln_block_size   NUMBER;
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
    -- CSV�o�̓f�B���N�g�����v���t�@�C�����擾�B���s���̓G���[
    gv_out_file_dir := FND_PROFILE.VALUE(cv_out_file_dir);
    IF (gv_out_file_dir IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                            cv_profile_err_msg,
                                            cv_ng_profile,
                                            cv_invalid_path);
      lv_errbuf := lv_errmsg;
      RAISE init_err_expt;
    END IF;
--
    -- CSV�o�̓t�@�C�������v���t�@�C�����擾�B���s���̓G���[
    gv_out_file_name := FND_PROFILE.VALUE(cv_out_file_file);
    IF (gv_out_file_name IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                            cv_profile_err_msg,
                                            cv_ng_profile,
                                            cv_invalid_name);
      lv_errbuf := lv_errmsg;
      RAISE init_err_expt;
    END IF;
--
    -- �t�@�C�����݃`�F�b�N
    UTL_FILE.FGETATTR(gv_out_file_dir, gv_out_file_name, lv_file_chk, ln_file_size, ln_block_size);
    IF (lv_file_chk) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                            cv_exist_err_msg);
      lv_errbuf := lv_errmsg;
      RAISE init_err_expt;
    END IF;
--
  EXCEPTION
    WHEN init_err_expt THEN                           --*** ����������O ***
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   ####################################
--
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
  END init;
--
  /**********************************************************************************
   * Procedure Name   : file_open
   * Description      : �t�@�C���I�[�v������(A-2)
   ***********************************************************************************/
  PROCEDURE file_open(
    of_file_handler OUT UTL_FILE.FILE_TYPE,  --   �t�@�C���n���h��
    ov_errbuf       OUT VARCHAR2,            --   �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode      OUT VARCHAR2,            --   ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg       OUT VARCHAR2)            --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'file_open'; -- �v���O������
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
    cn_record_byte CONSTANT NUMBER      := 4095;  --�t�@�C���ǂݍ��ݕ�����
    cv_file_mode   CONSTANT VARCHAR2(1) := 'W';   --�������݃��[�h�ŊJ��
--
    -- *** ���[�J���ϐ� ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    BEGIN
      --�t�@�C���I�[�v��
      of_file_handler := UTL_FILE.FOPEN(gv_out_file_dir,
                                        gv_out_file_name,
                                        cv_file_mode,
                                        cn_record_byte);
    EXCEPTION
      --�t�@�C���p�X�G���[
      WHEN UTL_FILE.INVALID_PATH THEN
        lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                              cv_file_path_invalid_msg);
        lv_errbuf := lv_errmsg;
        RAISE fopen_err_expt;
      WHEN OTHERS THEN
        RAISE;
    END;
--
  EXCEPTION
    WHEN fopen_err_expt THEN                           --*** �t�@�C���I�[�v���G���[ ***
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
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
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END file_open;
--
  /**********************************************************************************
   * Procedure Name   : output_cust_data
   * Description      : �����Ώۃf�[�^���o����(A-3)�ECSV�t�@�C���o�͏���(A-4)
   ***********************************************************************************/
  PROCEDURE output_chain_data(
    if_file_handler         IN  UTL_FILE.FILE_TYPE,  --   �t�@�C���n���h��
    ov_errbuf               OUT VARCHAR2,            --   �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode              OUT VARCHAR2,            --   ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg               OUT VARCHAR2)            --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'output_chain_data'; -- �v���O������
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
    cv_y_flag             CONSTANT VARCHAR2(1)     := 'Y';                      -- �L���t���OY
    cv_n_flag             CONSTANT VARCHAR2(1)     := 'N';                      -- �����t���ON
    cv_language_ja        CONSTANT VARCHAR2(2)     := 'JA';                     -- ����(���{��)
    cv_chain_code         CONSTANT VARCHAR2(30)    := 'XXCMM_CHAIN_CODE';       -- �`�F�[���X�R�[�h
    cv_kigyo_gcode        CONSTANT VARCHAR2(30)    := 'XXCMM_KIGYO_GROUP_CODE'; -- ���G�R�[�h
    cv_kigyo_code         CONSTANT VARCHAR2(30)    := 'XX03_BUSINESS_TYPE';     -- ��ƃR�[�h
--
    cv_comp_code          CONSTANT VARCHAR2(3)     := '001';                    -- ��ЃR�[�h
    cv_tkn_chain_code     CONSTANT VARCHAR2(20)    := '�`�F�[���R�[�h';         -- CSV�o�̓G���[������
--
    -- *** ���[�J���ϐ� ***
    lv_collaboration_date VARCHAR2(14);     -- �A�g����(YYYYMMDDHH24MISS)
    lv_output_str         VARCHAR2(4095);   -- CSV�o�͕�����i�[�ϐ�
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    -- �`�F�[���}�X�^�A�gIF�f�[�^�쐬�J�[�\��
    CURSOR chain_data_cur
    IS
      SELECT flvc.chain_code      chain_code,
             flvc.chain_name      chain_name,
             flvc.chain_kana      chain_kana,
             flvc.kigyo_code      kigyo_code,
             ffvk.kigyo_name      kigyo_name,
             ffvk.kigyo_base_code kigyo_base_code,
             ffvk.kigyo_gcode     kigyo_gcode,
             flvk.kigyo_gname     kigyo_gname,
             flvc.base_code       base_code
      FROM (SELECT flv.lookup_code  chain_code,
                   flv.description  chain_name,
                   flv.attribute1   kigyo_code,
                   flv.attribute2   chain_kana,
                   flv.attribute3   base_code
            FROM fnd_lookup_values flv
            WHERE flv.language     = cv_language_ja
              AND flv.lookup_type  = cv_chain_code
              AND flv.enabled_flag = cv_y_flag) flvc,
           (SELECT ffv.flex_value   kigyo_code,
                   ffvt.description kigyo_name,
                   ffv.attribute1   kigyo_gcode,
                   ffv.attribute2   kigyo_base_code
            FROM fnd_flex_value_sets ffvs,
                 fnd_flex_values     ffv,
                 fnd_flex_values_tl  ffvt
            WHERE ffv.flex_value_set_id    = ffvs.flex_value_set_id
              AND ffv.flex_value_id        = ffvt.flex_value_id
              AND ffv.enabled_flag         = cv_y_flag
              AND ffvs.flex_value_set_name = cv_kigyo_code
              AND ffvt.language            = cv_language_ja
              AND ffv.summary_flag         = cv_n_flag) ffvk,
           (SELECT flv.lookup_code  kigyo_gcode,
                   flv.description  kigyo_gname
            FROM fnd_lookup_values flv
            WHERE flv.language     = cv_language_ja
              AND flv.lookup_type  = cv_kigyo_gcode
              AND flv.enabled_flag = cv_y_flag) flvk
      WHERE flvc.kigyo_code   = ffvk.kigyo_code(+)
        AND ffvk.kigyo_gcode  = flvk.kigyo_gcode(+)
      ORDER BY ffvk.kigyo_gcode, flvc.kigyo_code, flvc.chain_code;
--
    -- �`�F�[���}�X�^�A�gIF�f�[�^�쐬�J�[�\�����R�[�h�^
    chain_data_rec chain_data_cur%ROWTYPE;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- �A�g�����擾
    lv_collaboration_date := TO_CHAR(SYSDATE, cv_trans_date);
    -- CSV�t�@�C���o�͏���
    << out_loop >>
    FOR chain_data_rec IN chain_data_cur
    LOOP
      -- �Ώی����J�E���g
      gn_target_cnt := gn_target_cnt + 1;
      -- �o�͕�����쐬
      -- ��ЃR�[�h
      lv_output_str := cv_dqu        || cv_comp_code || cv_dqu;
      -- �`�F�[���R�[�h
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(chain_data_rec.chain_code, 1, 9)      || cv_dqu;
      -- �`�F�[���X��(����)
-- 2011/10/31 Ver.1.2 Mod Start
--      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(chain_data_rec.chain_name, 1, 50)     || cv_dqu;
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTR(chain_data_rec.chain_name, 1, 25)      || cv_dqu;
-- 2011/10/31 Ver.1.2 Mod End
      -- �`�F�[���X��(�J�i)
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(chain_data_rec.chain_kana, 1, 25)     || cv_dqu;
      -- ��ƃR�[�h
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(chain_data_rec.kigyo_code, 1, 6)      || cv_dqu;
      -- ��Ɩ�
-- 2011/10/31 Ver.1.2 Mod Start
--      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(chain_data_rec.kigyo_name, 1, 50)     || cv_dqu;
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTR(chain_data_rec.kigyo_name, 1, 25)      || cv_dqu;
-- 2011/10/31 Ver.1.2 Mod End
      -- �{���S�����_�R�[�h(���)
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(chain_data_rec.kigyo_base_code, 1, 4) || cv_dqu;
      -- ���G�R�[�h
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(chain_data_rec.kigyo_gcode, 1, 6)     || cv_dqu;
      -- ���G��
-- 2011/10/31 Ver.1.2 Mod Start
--      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(chain_data_rec.kigyo_gname, 1, 50)    || cv_dqu;
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTR(chain_data_rec.kigyo_gname, 1, 25)     || cv_dqu;
-- 2011/10/31 Ver.1.2 Mod End
      -- �{���S�����_�R�[�h
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(chain_data_rec.base_code, 1, 4)       || cv_dqu;
      -- �A�g����
      lv_output_str := lv_output_str || cv_comma || lv_collaboration_date;
      BEGIN
        -- CSV�t�@�C���o��
        UTL_FILE.PUT_LINE(if_file_handler,lv_output_str);
      EXCEPTION
        WHEN UTL_FILE.WRITE_ERROR THEN   --*** �t�@�C���������݃G���[ ***
          lv_errmsg     := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                                    cv_write_err_msg,
                                                    cv_ng_word,
                                                    cv_tkn_chain_code,
                                                    cv_ng_data,
                                                    chain_data_rec.chain_code);
          lv_errbuf     := lv_errmsg;
          -- �G���[�����J�E���g
          gn_error_cnt  := gn_error_cnt + 1;
        RAISE write_failure_expt;
      END;
      -- ���������J�E���g
      gn_normal_cnt := gn_normal_cnt + 1;
      -- �ϐ�������
      lv_output_str := NULL;
    END LOOP out_loop;
    -- �Ώۃf�[�^�Ȃ�
    IF (gn_target_cnt = 0) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                            cv_no_data_err_msg);
      lv_errbuf := lv_errmsg;
      RAISE no_data_err_expt;
    END IF;
--
  EXCEPTION
    WHEN no_data_err_expt THEN                         --*** �Ώۃf�[�^�Ȃ��G���[ ***
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    WHEN write_failure_expt THEN                       --*** CSV�f�[�^�o�̓G���[ ***
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
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
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END output_chain_data;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    ov_errbuf                 OUT VARCHAR2,     --�G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode                OUT VARCHAR2,     --���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                 OUT VARCHAR2)     --���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    lf_file_handler   UTL_FILE.FILE_TYPE;  --�t�@�C���n���h��
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
--
    -- ===============================
    -- ��������(A-1)
    -- ===============================
    init(
       lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    -- ���������G���[���͏����𒆒f
    IF (lv_retcode = cv_status_error) THEN
      -- �G���[����
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- �R���J�����g���b�Z�[�W�o��
    -- ===============================
    --IF�t�@�C�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                  iv_application  => gv_xxccp_msg_kbn
                 ,iv_name         => cv_file_name_msg
                 ,iv_token_name1  => cv_tkn_filename
                 ,iv_token_value1 => gv_out_file_name
                );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    -- ===============================
    -- �t�@�C���I�[�v������(A-2)
    -- ===============================
    file_open(
       lf_file_handler    -- �t�@�C���n���h��
      ,lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    IF (lv_retcode = cv_status_error) THEN
      --�G���[����
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- �����Ώۃf�[�^���o����(A-3)�E���o���o�͏���(A-4)
    -- ===============================
    output_chain_data(
       lf_file_handler         -- �t�@�C���n���h��
      ,lv_errbuf               -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode              -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg);             -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    -- ===============================
    -- �I������(A-5)
    -- ===============================
    BEGIN
      -- �t�@�C���N���[�Y����
      IF (UTL_FILE.IS_OPEN(lf_file_handler)) THEN
        -- �t�@�C���N���[�Y
        UTL_FILE.FCLOSE(lf_file_handler);
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        IF (lv_retcode = cv_status_error) THEN
          -- �R���J�����g���b�Z�[�W�o��
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
            ,buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
          );
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => lv_errbuf --�G���[���b�Z�[�W
          );
        END IF;
        lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                              cv_file_close_err_msg,
                                              cv_sqlerrm,
                                              SQLERRM);
        lv_errbuf := lv_errmsg;
        RAISE fclose_err_expt;
    END;
    IF (lv_retcode = cv_status_error) THEN
      -- �Ώۃf�[�^�Ȃ��G���[�̏ꍇ�A�t�@�C�����폜���܂�
      IF (gn_target_cnt = 0) THEN
        -- �t�@�C���폜
        UTL_FILE.FREMOVE(gv_out_file_dir, gv_out_file_name);
      END IF;
      -- �G���[����
      RAISE global_process_expt;
    END IF;
--
  EXCEPTION
    WHEN fclose_err_expt THEN                         --*** �t�@�C���N���[�Y�G���[ ***
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
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
    errbuf                    OUT VARCHAR2,     --�G���[�E���b�Z�[�W  --# �Œ� #
    retcode                   OUT VARCHAR2      --���^�[���E�R�[�h    --# �Œ� #
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
    -- ���̓p�����[�^�Ȃ����b�Z�[�W�o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                  iv_application  => gv_xxccp_msg_kbn
                 ,iv_name         => cv_no_parameter
                 );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    -- ��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    --
--###########################  �Œ蕔 END   #############################
--
    -- ===============================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ===============================================
    submain(
       lv_errbuf                 --�G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode                --���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg                 --���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    --�G���[�o��
    IF (lv_retcode = cv_status_error) THEN
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --�G���[���b�Z�[�W
      );
      --��s�}��
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
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
    FND_FILE.PUT_LINE(
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
END xxcmm003a37c;
/
