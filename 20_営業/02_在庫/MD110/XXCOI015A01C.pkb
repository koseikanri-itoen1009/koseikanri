create or replace
PACKAGE BODY XXCOI015A01C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2009. All rights reserved.
 *
 * Package Name     : XXCOI015A01C(body)
 * Description      : ����C���^�t�F�[�X�̏���
 * MD.050           : 
 * Version          : 1.0
 *
 * Program List
 * ------------------------- ------------------------------------------------------------
 *  Name                      Description
 * ------------------------- ------------------------------------------------------------
 *  chk_trans_worker          6)������[�J�[�I���`�F�b�N
 *  start_trans_worker        5)������[�J�[�N������
 *  set_trans_oif_header_id   4)���ގ��OIF�w�b�_ID�X�V����
 *  get_trans_oif_data        2)���ގ��OIF�e�[�u����񒊏o����
 *                            3)���ގ��OIF�w�b�_ID�擾����
 *  init                      1)��������
 *  submain                     ���C�������v���V�[�W��
 *  main                        �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *                            7)�I������
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009/07/07    1.0   H.Sasaki         �V�K�쐬
 *
 *****************************************************************************************/
  -- ===============================================
  -- �O���[�o���萔
  -- ===============================================
  -- �p�b�P�[�W��
  cv_pkg_name                 CONSTANT VARCHAR2(20)   :=  'XXCOI015A01C';
--
  -- �A�v���P�[�V�����Z�k��
  cv_appli_short_name_xxcoi   CONSTANT VARCHAR2(10)   :=  'XXCOI';
  cv_appli_short_name_xxccp   CONSTANT VARCHAR2(10)   :=  'XXCCP';
  cv_appli_short_name_inv     CONSTANT VARCHAR2(10)   :=  'INV';
--
  -- �X�e�[�^�X
  cv_status_normal            CONSTANT VARCHAR2(1)    :=  xxccp_common_pkg.set_status_normal; -- ����:0
  cv_status_warn              CONSTANT VARCHAR2(1)    :=  xxccp_common_pkg.set_status_warn;   -- �x��:1
  cv_status_error             CONSTANT VARCHAR2(1)    :=  xxccp_common_pkg.set_status_error;  -- �ُ�:2
--
  -- WHO�J����
  cn_created_by               CONSTANT NUMBER         :=  fnd_global.user_id;          -- CREATED_BY
  cn_last_updated_by          CONSTANT NUMBER         :=  fnd_global.user_id;          -- LAST_UPDATED_BY
  cn_last_update_login        CONSTANT NUMBER         :=  fnd_global.login_id;         -- LAST_UPDATE_LOGIN
  cn_request_id               CONSTANT NUMBER         :=  fnd_global.conc_request_id;  -- REQUEST_ID
  cn_program_application_id   CONSTANT NUMBER         :=  fnd_global.prog_appl_id;     -- PROGRAM_APPLICATION_ID
  cn_program_id               CONSTANT NUMBER         :=  fnd_global.conc_program_id;  -- PROGRAM_ID
--
  -- ���b�Z�[�W
  cv_msg_xxccp1_90000         CONSTANT VARCHAR2(30)   :=  'APP-XXCCP1-90000';  -- �Ώی���
  cv_msg_xxccp1_90001         CONSTANT VARCHAR2(30)   :=  'APP-XXCCP1-90001';  -- ��������
  cv_msg_xxccp1_90002         CONSTANT VARCHAR2(30)   :=  'APP-XXCCP1-90002';  -- �G���[����
  cv_msg_xxccp1_90003         CONSTANT VARCHAR2(30)   :=  'APP-XXCCP1-90003';  -- �x������
  cv_msg_xxccp1_90004         CONSTANT VARCHAR2(30)   :=  'APP-XXCCP1-90004';  -- ����I��
  cv_msg_xxccp1_90005         CONSTANT VARCHAR2(30)   :=  'APP-XXCCP1-90005';  -- �x���I��
  cv_msg_xxccp1_90006         CONSTANT VARCHAR2(30)   :=  'APP-XXCCP1-90006';  -- �G���[�I���S���[���o�b�N
  cv_msg_xxccp1_90008         CONSTANT VARCHAR2(30)   :=  'APP-XXCCP1-90008';  -- �R���J�����g���̓p�����[�^�Ȃ�

  cv_msg_xxcoi_10387          CONSTANT VARCHAR2(30)   :=  'APP-XXCOI1-10387';  -- �R���J�����g���̓p�����[�^�Ȃ����b�Z�[�W
  cv_msg_xxcoi_10388          CONSTANT VARCHAR2(30)   :=  'APP-XXCOI1-10388';  -- ���OIF�X�V�G���[
  cv_msg_xxcoi_10389          CONSTANT VARCHAR2(30)   :=  'APP-XXCOI1-10389';  -- ������[�J�[�N�����b�Z�[�W
  cv_msg_xxcoi_10390          CONSTANT VARCHAR2(30)   :=  'APP-XXCOI1-10390';  -- ������[�J�[�N���G���[���b�Z�[�W
  cv_msg_xxcoi_10391          CONSTANT VARCHAR2(30)   :=  'APP-XXCOI1-10391';  -- ���OIF�X�V����
  cv_msg_xxcoi_10392          CONSTANT VARCHAR2(30)   :=  'APP-XXCOI1-10392';  -- ������[�J�[�N������
  cv_msg_xxcoi_10393          CONSTANT VARCHAR2(30)   :=  'APP-XXCOI1-10393';  -- ������[�J�[�I�����b�Z�[�W
  cv_msg_xxcoi_10394          CONSTANT VARCHAR2(30)   :=  'APP-XXCOI1-10394';  -- ������[�J�[�G���[����
  cv_msg_xxcoi_10395          CONSTANT VARCHAR2(30)   :=  'APP-XXCOI1-10395';  -- ���OIF�Ώی���
  cv_msg_xxcoi_10396          CONSTANT VARCHAR2(30)   :=  'APP-XXCOI1-10396';  -- ���OIF�X�L�b�v����
--
  -- �g�[�N��
  cv_token_count              CONSTANT VARCHAR2(20)   :=  'COUNT';
  cv_token_error_msg          CONSTANT VARCHAR2(20)   :=  'ERR_MSG';
  cv_token_request_id         CONSTANT VARCHAR2(20)   :=  'REQUEST_ID';
  cv_token_base_code          CONSTANT VARCHAR2(20)   :=  'BASE_CODE';
  cv_token_header_id          CONSTANT VARCHAR2(20)   :=  'HEADER_ID';
--
  -- �Z�p���[�^
  cv_msg_part                 CONSTANT VARCHAR2(3)    := ' : ';
  cv_msg_cont                 CONSTANT VARCHAR2(1)    := '.';
  cv_empty                    CONSTANT VARCHAR2(1)    := '';
--
  -- ���̑��萔
  cv_space                    CONSTANT VARCHAR2(1)    :=  ' ';                          -- ���p�X�y�[�X
  cn_target_1                 CONSTANT VARCHAR2(1)    :=  1;                            -- ������[�h�P�F�����Ώ�
  cn_lock_flag_1              CONSTANT VARCHAR2(1)    :=  1;                            -- ���b�N�t���O�P
  cv_prf_check_wait_second    CONSTANT VARCHAR2(30)   :=  'XXCOI1_CHECK_WAIT_SECOND';   -- �v���t�@�C���i�����`�F�b�N�ҋ@���ԁi�b�j�j
  --
  -- ===============================================
  -- �O���[�o���ϐ�
  -- ===============================================
  gn_target_cnt               NUMBER  DEFAULT 0;     -- �Ώی���
  gn_normal_cnt               NUMBER  DEFAULT 0;     -- �X�V����
  gn_error_cnt                NUMBER  DEFAULT 0;     -- �G���[����
  gn_warn_cnt                 NUMBER  DEFAULT 0;     -- �x������
  gn_conc_start_cnt           NUMBER  DEFAULT 0;     -- ������[�J�[�N����
  gn_sub_conc_err_cnt         NUMBER  DEFAULT 0;     -- ������[�J�[�G���[����
  gd_start_date               DATE    DEFAULT NULL;  -- �N������
  gn_check_wait_second        NUMBER  DEFAULT NULL;  -- �����`�F�b�N�ҋ@���ԁi�b�j
--
  -- ���ގ��OIF�e�[�u�����擾�f�[�^�i�[�p���R�[�h�ϐ�
  TYPE rec_mtl_trans_oif IS RECORD
    (
      row_id          ROWID                                                 -- ROWID
     ,base_code       mtl_secondary_inventories.attribute7%TYPE             -- ���_�R�[�h
    );
  TYPE tab_data_mtl_trans_oif IS TABLE OF rec_mtl_trans_oif INDEX BY PLS_INTEGER;
  gt_mtl_trans_oif    tab_data_mtl_trans_oif;   -- ���ގ��OIF�e�[�u�����擾�f�[�^
  --
  TYPE row_id_tbl     IS TABLE OF ROWID INDEX BY BINARY_INTEGER;
  gt_rowid_tbl        row_id_tbl;               -- ���ގ��OIF_ROWID
  TYPE base_code_tbl  IS TABLE OF mtl_secondary_inventories.attribute7%TYPE INDEX BY BINARY_INTEGER;
  gt_base_code_tbl    base_code_tbl;            -- ���_�R�[�h
  TYPE header_id_tbl  IS TABLE OF NUMBER INDEX BY BINARY_INTEGER;
  gt_header_id_tbl    header_id_tbl;            -- ���ގ��OIF�w�b�_ID
  TYPE request_id_tbl IS TABLE OF NUMBER INDEX BY BINARY_INTEGER;
  gt_request_id_tbl   request_id_tbl;           -- ������[�J�[�v��ID
  --
--
  -- ===============================================
  -- �O���[�o���J�[�\��
  -- ===============================================
--
  -- ===============================================
  -- ���ʗ�O
  -- ===============================================
  --*** ���b�N�G���[ ***
  global_lock_fail                EXCEPTION;
  --*** ���������ʗ�O ***
  global_process_expt             EXCEPTION;
  --*** ���ʊ֐���O ***
  global_api_expt                 EXCEPTION;
  --*** ���ʊ֐�OTHERS��O ***
  global_api_others_expt          EXCEPTION;
  --*** �o���N�A�b�v�f�[�g��O **
  global_bulk_upd_expt            EXCEPTION;
  --
  PRAGMA EXCEPTION_INIT(global_api_others_expt,-20000);
  PRAGMA EXCEPTION_INIT(global_lock_fail,-54);
  PRAGMA EXCEPTION_INIT(global_bulk_upd_expt, -24381);
--
  /**********************************************************************************
   * Procedure Name   : chk_trans_worker
   * Description      : �U�j������[�J�[�I���`�F�b�N
   ***********************************************************************************/
  PROCEDURE chk_trans_worker(
    ov_errbuf   OUT VARCHAR2
  , ov_retcode  OUT VARCHAR2
  , ov_errmsg   OUT VARCHAR2
  )
  IS
    -- ===============================================
    -- ���[�J���萔
    -- ===============================================
    cv_prg_name           CONSTANT VARCHAR2(30) := 'chk_trans_worker';              -- �v���O������
    cv_success_c          CONSTANT VARCHAR2(1)  := 'C';                             -- �R���J�����g.�t�F�[�Y�F����
    cv_success_i          CONSTANT VARCHAR2(1)  := 'I';                             -- �R���J�����g.�t�F�[�Y�F����
    cv_success_r          CONSTANT VARCHAR2(1)  := 'R';                             -- �R���J�����g.�t�F�[�Y�F����
--
    -- ===============================================
    -- ���[�J���ϐ�
    -- ===============================================
    lv_errbuf             VARCHAR2(5000) DEFAULT NULL;                              -- �G���[�E���b�Z�[�W
    lv_retcode            VARCHAR2(1)    DEFAULT cv_status_normal;                  -- ���^�[���E�R�[�h
    lv_errmsg             VARCHAR2(5000) DEFAULT NULL;                              -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_outmsg             VARCHAR2(5000) DEFAULT NULL;                              -- �o�͗p���b�Z�[�W
    --
    ln_cnt                NUMBER;                                                   -- ���[�v�J�E���^
    ln_request_cnt        NUMBER;                                                   -- �v�����s����
    ln_comp_cnt           NUMBER;                                                   -- �v����������
    lt_phase_code         fnd_concurrent_requests.phase_code%TYPE;                  -- �t�F�[�Y
    lt_status_code        fnd_concurrent_requests.status_code%TYPE;                 -- �X�e�[�^�X
--
  BEGIN
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ===============================================
    -- ������[�J�[�I���`�F�b�N
    -- ===============================================
    -- ������
    ln_cnt          :=  0;                          -- ���[�v�J�E���^
    ln_request_cnt  :=  gt_request_id_tbl.COUNT;    -- �v�����s����
    ln_comp_cnt     :=  0;                          -- �v����������
    --
    <<wait_loop>>
    LOOP
      <<chk_end_loop>>
      FOR ln_cnt IN 1 .. ln_request_cnt LOOP
        --
        IF (gt_request_id_tbl(ln_cnt) IS NOT NULL) THEN
          -- �R���J�����g�v���̃t�F�[�Y�A�X�e�[�^�X���擾
          SELECT  fcr.phase_code                        -- �t�F�[�Y
                 ,fcr.status_code                       -- �X�e�[�^�X
          INTO    lt_phase_code
                 ,lt_status_code
          FROM    fnd_concurrent_requests     fcr       -- �R���J�����g�v���ꗗ
          WHERE   fcr.request_id    =   gt_request_id_tbl(ln_cnt)
          AND     ROWNUM = 1;
          --
          -- �R���J�����g�I���`�F�b�N
          IF (lt_phase_code = 'C') THEN
            IF (lt_status_code IN(cv_success_c, cv_success_i, cv_success_r)) THEN
              -- �t�F�[�Y�uC:����v�A�X�e�[�^�XC, I, R �i�����������j
              -- �����������J�E���g�A�b�v
              ln_comp_cnt :=  ln_comp_cnt + 1;
              -- �I������������[�J�[�̗v��ID��������
              gt_request_id_tbl(ln_cnt) :=  NULL;
            ELSE
              -- �t�F�[�Y�uC:����v�A�X�e�[�^�XC, I, R �i�����������j�ȊO
              --
              -- ������[�J�[�G���[�����J�E���g�A�b�v
              gn_sub_conc_err_cnt :=  gn_sub_conc_err_cnt + 1;
              --
              -- ������[�J�[�I�����b�Z�[�W�i����ȊO�j
              lv_outmsg :=  xxccp_common_pkg.get_msg(
                              iv_application  => cv_appli_short_name_xxcoi
                             ,iv_name         => cv_msg_xxcoi_10393
                             ,iv_token_name1  => cv_token_request_id
                             ,iv_token_value1 => TO_CHAR(gt_request_id_tbl(ln_cnt))
                            );
              --
              fnd_file.put_line(
                 which  => FND_FILE.OUTPUT
                ,buff   => lv_outmsg
              );
              --
              -- �I���X�e�[�^�X�x��
              ov_retcode  :=  cv_status_warn;
              -- �����������J�E���g�A�b�v
              ln_comp_cnt :=  ln_comp_cnt + 1;
              -- �I������������[�J�[�̗v��ID��������
              gt_request_id_tbl(ln_cnt) :=  NULL;
            END IF;
          END IF;
        END IF;
        --
      END LOOP chk_end_loop;
      --
      -- �v�����s�����ƁA�v��������������v�����ꍇ�A�������I��
      EXIT WHEN ln_request_cnt = ln_comp_cnt;
      --
      -- �ҋ@����
      dbms_lock.sleep(gn_check_wait_second);
      --
    END LOOP wait_loop;
    -- ��s�o��
    IF (ov_retcode = cv_status_warn) THEN
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => cv_space
      );
    END IF;
--
  EXCEPTION
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_outmsg,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS��O ***
    WHEN OTHERS THEN
      ov_errmsg  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END chk_trans_worker;
--
  /**********************************************************************************
   * Procedure Name   : start_trans_worker
   * Description      : �T�j������[�J�[�N������
   ***********************************************************************************/
  PROCEDURE start_trans_worker(
    ov_errbuf   OUT VARCHAR2
  , ov_retcode  OUT VARCHAR2
  , ov_errmsg   OUT VARCHAR2
  )
  IS
    -- ===============================================
    -- ���[�J���萔
    -- ===============================================
    cv_prg_name           CONSTANT VARCHAR2(30) := 'start_trans_worker';            -- �v���O������
    cv_prg_name_inctcw    CONSTANT VARCHAR2(30) := 'INCTCW';                        -- ������[�J�[�v���O������
--
    -- ===============================================
    -- ���[�J���ϐ�
    -- ===============================================
    lv_errbuf             VARCHAR2(5000) DEFAULT NULL;                              -- �G���[�E���b�Z�[�W
    lv_retcode            VARCHAR2(1)    DEFAULT cv_status_normal;                  -- ���^�[���E�R�[�h
    lv_errmsg             VARCHAR2(5000) DEFAULT NULL;                              -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_outmsg             VARCHAR2(5000) DEFAULT NULL;                              -- �o�͗p���b�Z�[�W
    lv_compare_base_code  mtl_secondary_inventories.attribute7%TYPE;                -- �ύX��r�p���_�R�[�h
    ln_success_cnt        NUMBER;                                                   -- ���[�J�[�N����
    ln_error_cnt          NUMBER;                                                   -- ���[�J�[�N�����s��
    ln_request_id         NUMBER;                                                   -- ���[�J�[�N���v��ID
    --
    -- �N�����ʃ��b�Z�[�W
    TYPE out_msg_tbl IS TABLE OF
      VARCHAR2(5000) INDEX BY BINARY_INTEGER;
    lt_start_success      out_msg_tbl;      -- �N���������b�Z�[�W
    lt_start_error        out_msg_tbl;      -- �N�����s���b�Z�[�W
--
  BEGIN
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ===============================================
    -- �C�j�V�����C�Y
    -- ===============================================
    fnd_global.apps_initialize(
      user_id         =>  cn_created_by               -- ���[�UID
     ,resp_id         =>  fnd_global.resp_id          -- �E��ID
     ,resp_appl_id    =>  fnd_global.resp_appl_id     -- �E�ӃA�v���P�[�V����ID
    );
    -- ���R�[�h����ϐ��̏�����
    ln_success_cnt  :=  0;
    ln_error_cnt    :=  0;
    --
    -- ===============================================
    -- ������[�J�[�N��
    -- ===============================================
    <<start_subconc_loop>>
    FOR ln_cnt IN 1 .. gn_target_cnt LOOP
      IF (   (ln_cnt = 1)
          OR (lv_compare_base_code <> gt_base_code_tbl(ln_cnt))
         )
      THEN
        -- ���_�R�[�h���ɁA������[�J�[���N��
        ln_request_id :=  fnd_request.submit_request(
                            application     =>  cv_appli_short_name_inv     -- INV
                           ,program         =>  cv_prg_name_inctcw          -- INCTCW
                           ,description     =>  NULL
                           ,start_time      =>  NULL
                           ,sub_request     =>  FALSE
                           ,argument1       =>  gt_header_id_tbl(ln_cnt)    -- ���ގ��OIF�w�b�_ID
                           ,argument2       =>  3
                           ,argument3       =>  0
                           ,argument4       =>  0
                          );
        --
        IF (ln_request_id > 0) THEN
          COMMIT;
          -- ���R�[�h�^����ϐ��J�E���g�A�b�v
          ln_success_cnt  :=  ln_success_cnt + 1;
          -- �N������������[�J�[�̗v��ID��ێ�
          gt_request_id_tbl(ln_success_cnt)  :=  ln_request_id;
          --
          -- ������[�J�[�N���������b�Z�[�W��ێ�
          lt_start_success(ln_success_cnt)  :=  xxccp_common_pkg.get_msg(
                                                  iv_application  => cv_appli_short_name_xxcoi
                                                 ,iv_name         => cv_msg_xxcoi_10389
                                                 ,iv_token_name1  => cv_token_request_id
                                                 ,iv_token_value1 => TO_CHAR(ln_request_id)
                                                 ,iv_token_name2  => cv_token_base_code
                                                 ,iv_token_value2 => gt_base_code_tbl(ln_cnt)
                                                );
        ELSE
          ROLLBACK;
          -- �I���X�e�[�^�X�Ɍx����ݒ�
          ov_retcode  :=  cv_status_warn;
          -- ���R�[�h�^����ϐ��J�E���g�A�b�v
          ln_error_cnt  :=  ln_error_cnt + 1;
          --
          -- ������[�J�[�N�����s���b�Z�[�W��ێ�
          lt_start_error(ln_error_cnt)      :=  xxccp_common_pkg.get_msg(
                                                  iv_application  => cv_appli_short_name_xxcoi
                                                 ,iv_name         => cv_msg_xxcoi_10390
                                                 ,iv_token_name1  => cv_token_header_id
                                                 ,iv_token_value1 => TO_CHAR(gt_header_id_tbl(ln_cnt))
                                                 ,iv_token_name2  => cv_token_base_code
                                                 ,iv_token_value2 => gt_base_code_tbl(ln_cnt)
                                                );
        END IF;
        --
        -- �ύX��r�p���_�R�[�h�̐ݒ�
        lv_compare_base_code  :=  gt_base_code_tbl(ln_cnt);
      END IF;
      --
    END LOOP start_subconc_loop;
    --
    -- ������[�J�[�N���񐔂��J�E���g�A�b�v
    gn_conc_start_cnt :=  ln_success_cnt;
    --
    -- ===============================================
    -- ������[�J�[�N���󋵂̏o��
    -- ===============================================
    <<success_loop>>
    FOR ln_cnt IN 1 .. ln_success_cnt LOOP
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => lt_start_success(ln_cnt)
      );
    END LOOP success_loop;
    -- ��s�o��
    IF (ln_success_cnt <> 0) THEN
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => cv_space
      );
    END IF;
    --
    <<error_loop>>
    FOR ln_cnt IN 1 .. ln_error_cnt LOOP
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => lt_start_error(ln_error_cnt)
      );
    END LOOP error_loop;
    -- ��s�o��
    IF (ln_error_cnt <> 0) THEN
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => cv_space
      );
    END IF;
--
  EXCEPTION
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_outmsg,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS��O ***
    WHEN OTHERS THEN
      ov_errmsg  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END start_trans_worker;
--
  /**********************************************************************************
   * Procedure Name   : set_trans_oif_header_id
   * Description      : �S�j���ގ��OIF�w�b�_ID�X�V����
   ***********************************************************************************/
  PROCEDURE set_trans_oif_header_id(
    ov_errbuf   OUT VARCHAR2
  , ov_retcode  OUT VARCHAR2
  , ov_errmsg   OUT VARCHAR2
  )
  IS
    -- ===============================================
    -- ���[�J���萔
    -- ===============================================
    cv_prg_name    CONSTANT VARCHAR2(30) := 'set_trans_oif_header_id';  -- �v���O������
--
    -- ===============================================
    -- ���[�J���ϐ�
    -- ===============================================
    lv_errbuf      VARCHAR2(5000) DEFAULT NULL;              -- �G���[�E���b�Z�[�W
    lv_retcode     VARCHAR2(1)    DEFAULT cv_status_normal;  -- ���^�[���E�R�[�h
    lv_errmsg      VARCHAR2(5000) DEFAULT NULL;              -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_outmsg      VARCHAR2(5000) DEFAULT NULL;              -- �o�͗p���b�Z�[�W
--
  BEGIN
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ===============================================
    -- ���ގ��OIF�e�[�u���o�^����
    -- ===============================================
    FORALL ln_cnt IN gt_mtl_trans_oif.FIRST .. gt_mtl_trans_oif.LAST SAVE EXCEPTIONS
      UPDATE  mtl_transactions_interface
      SET     transaction_header_id     =   gt_header_id_tbl(ln_cnt)
             ,lock_flag                 =   cn_lock_flag_1
             ,last_update_date          =   SYSDATE
             ,last_updated_by           =   cn_last_updated_by
             ,last_update_login         =   cn_last_update_login
             ,request_id                =   cn_request_id
             ,program_id                =   cn_program_id
             ,program_application_id    =   cn_program_application_id
             ,program_update_date       =   SYSDATE
      WHERE   ROWID   =   gt_rowid_tbl(ln_cnt);
    --
    -- �X�V������ݒ�
    gn_normal_cnt :=  gn_target_cnt;
    -- �x��������ݒ�
    gn_warn_cnt   :=  0;
--
  EXCEPTION
    -- *** �o���N�A�b�v�f�[�g��O���� ***
    WHEN global_bulk_upd_expt THEN
      gn_warn_cnt   :=  SQL%BULK_EXCEPTIONS.COUNT;      -- �x������
      gn_normal_cnt :=  gn_target_cnt - gn_warn_cnt;    -- �X�V����
      --
      ov_retcode    := cv_status_warn;                  -- �X�e�[�^�X�i�x���j
      --
      <<output_error_loop>>
      FOR ln_cnt IN 1 .. gn_warn_cnt LOOP
        -- �G���[���b�Z�[�W����
        lv_outmsg :=  xxccp_common_pkg.get_msg(
                        iv_application  => cv_appli_short_name_xxcoi
                       ,iv_name         => cv_msg_xxcoi_10388
                       ,iv_token_name1  => cv_token_base_code
                       ,iv_token_value1 => gt_base_code_tbl(SQL%BULK_EXCEPTIONS(ln_cnt).ERROR_INDEX)
                       ,iv_token_name2  => cv_token_error_msg
                       ,iv_token_value2 => SQLERRM(-SQL%BULK_EXCEPTIONS(ln_cnt).ERROR_CODE)
                      );
        -- �G���[���b�Z�[�W�o��
        fnd_file.put_line(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_outmsg
        );
      END LOOP output_error_loop;
      -- ��s�o��
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => cv_space
      );
      --
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_outmsg,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS��O ***
    WHEN OTHERS THEN
      ov_errmsg  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END set_trans_oif_header_id;
--
  /**********************************************************************************
   * Procedure Name   : get_trans_oif_data
   * Description      : �Q�j���ގ��OIF�e�[�u����񒊏o����
   *                    �R�j���ގ��OIF�w�b�_ID�擾����
   ***********************************************************************************/
  PROCEDURE get_trans_oif_data(
    ov_errbuf   OUT VARCHAR2
  , ov_retcode  OUT VARCHAR2
  , ov_errmsg   OUT VARCHAR2
  )
  IS
    -- ===============================================
    -- ���[�J���萔
    -- ===============================================
    cv_prg_name    CONSTANT VARCHAR2(30) := 'get_trans_oif_data';  -- �v���O������
--
    -- ===============================================
    -- ���[�J���ϐ�
    -- ===============================================
    lv_errbuf      VARCHAR2(5000) DEFAULT NULL;              -- �G���[�E���b�Z�[�W
    lv_retcode     VARCHAR2(1)    DEFAULT cv_status_normal;  -- ���^�[���E�R�[�h
    lv_errmsg      VARCHAR2(5000) DEFAULT NULL;              -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_outmsg      VARCHAR2(5000) DEFAULT NULL;              -- �o�͗p���b�Z�[�W
    --
    lt_trans_header_id    mtl_transactions_interface.transaction_header_id%TYPE;    -- ���ގ��OIF�w�b�_ID
    lv_compare_base_code  mtl_secondary_inventories.attribute7%TYPE;                -- �ύX��r�p���_�R�[�h
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    -- ���ގ��OIF�e�[�u�����
    CURSOR  cur_trans_oif_data
    IS
      SELECT    mti.ROWID         row_id                -- ROWID
               ,msi.attribute7    base_code             -- ���_�R�[�h
      FROM      mtl_transactions_interface    mti       -- ���ގ��OIF
               ,mtl_secondary_inventories     msi       -- �ۊǏꏊ�}�X�^
      WHERE     mti.process_flag        =   cn_target_1
      AND       mti.creation_date      <=   gd_start_date
      AND       mti.subinventory_code   =   msi.secondary_inventory_name
      AND       mti.organization_id     =   msi.organization_id
      ORDER BY  msi.attribute7 ASC
      FOR UPDATE OF mti.transaction_header_id;          -- ���ގ��OIF�����b�N
--
  BEGIN
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ===============================================
    -- ���ގ��OIF�e�[�u�����擾
    -- ===============================================
    OPEN cur_trans_oif_data;
    -- �o���N�t�F�b�`
    FETCH cur_trans_oif_data BULK COLLECT INTO gt_mtl_trans_oif;
    -- �J�[�\���N���[�Y
    CLOSE cur_trans_oif_data;
    --
    -- �Ώی���
    gn_target_cnt :=  gt_mtl_trans_oif.COUNT;
--
    -- ===============================================
    -- ���ގ��OIF�w�b�_ID�擾
    -- ===============================================
    <<get_header_id_loop>>
    FOR ln_cnt IN 1 .. gn_target_cnt LOOP
      -- ���R�[�h�^�Ƀf�[�^��ݒ�
      gt_rowid_tbl(ln_cnt)      :=  gt_mtl_trans_oif(ln_cnt).row_id;
      gt_base_code_tbl(ln_cnt)  :=  gt_mtl_trans_oif(ln_cnt).base_code;
      
      -- ���_�R�[�h���ɁA���ގ��OIF�w�b�_ID��ݒ�
      IF (   (ln_cnt = 1)
          OR (lv_compare_base_code <> gt_mtl_trans_oif(ln_cnt).base_code)
         )
      THEN
        -- ���ގ��OIF�w�b�_ID���擾
        SELECT  mtl_material_transactions_s.NEXTVAL
        INTO    lt_trans_header_id
        FROM    dual;
        --
        gt_header_id_tbl(ln_cnt)  :=  lt_trans_header_id;
        --
      ELSE
        -- 
        gt_header_id_tbl(ln_cnt)  :=  lt_trans_header_id;
      END IF;
      --
      -- �ύX��r�p���_�R�[�h��ێ�
      lv_compare_base_code  :=  gt_mtl_trans_oif(ln_cnt).base_code;
      --
    END LOOP get_header_id_loop;
    --
  EXCEPTION
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_outmsg,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS��O ***
    WHEN OTHERS THEN
      ov_errmsg  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_trans_oif_data;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : �P�j��������
   ***********************************************************************************/
  PROCEDURE init(
    ov_errbuf   OUT VARCHAR2
  , ov_retcode  OUT VARCHAR2
  , ov_errmsg   OUT VARCHAR2
  )
  IS
    -- ===============================================
    -- ���[�J���萔
    -- ===============================================
    cv_prg_name    CONSTANT VARCHAR2(30) := 'init';  -- �v���O������
--
    -- ===============================================
    -- ���[�J���ϐ�
    -- ===============================================
    lv_errbuf      VARCHAR2(5000) DEFAULT NULL;              -- �G���[�E���b�Z�[�W
    lv_retcode     VARCHAR2(1)    DEFAULT cv_status_normal;  -- ���^�[���E�R�[�h
    lv_errmsg      VARCHAR2(5000) DEFAULT NULL;              -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_outmsg      VARCHAR2(5000) DEFAULT NULL;              -- �o�͗p���b�Z�[�W
--
  BEGIN
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ===============================================
    -- ���̓p�����[�^�̏o��
    -- ===============================================
    lv_outmsg    := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appli_short_name_xxcoi
                    ,iv_name         => cv_msg_xxcoi_10387
                   );
    --
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_outmsg
    );
    -- ��s���o��
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => cv_space
    );
    --
    -- ===============================================
    -- �N�������̐ݒ�
    -- ===============================================
    gd_start_date   :=  SYSDATE;
    --
    -- ===============================================
    -- �����`�F�b�N�ҋ@���Ԃ̎擾
    -- ===============================================
    gn_check_wait_second  :=  fnd_profile.value(cv_prf_check_wait_second);
--
  EXCEPTION
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_outmsg,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS��O ***
    WHEN OTHERS THEN
      ov_errmsg  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
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
    ov_errbuf       OUT VARCHAR2
  , ov_retcode      OUT VARCHAR2
  , ov_errmsg       OUT VARCHAR2
  )
  IS
    -- ===============================================
    -- �Œ胍�[�J���萔
    -- ===============================================
    cv_prg_name  CONSTANT VARCHAR2(30) := 'submain';
--
    -- ===============================================
    -- ���[�J���ϐ�
    -- ===============================================
    lv_errbuf       VARCHAR2(5000) DEFAULT NULL;
    lv_retcode      VARCHAR2(1)    DEFAULT cv_status_normal;
    lv_errmsg       VARCHAR2(5000) DEFAULT NULL;
    lv_outmsg       VARCHAR2(5000) DEFAULT NULL;  -- �o�͗p���b�Z�[�W
    ln_warn_flg     NUMBER         DEFAULT 0;     -- �x���t���O(�x���Ȃ�:0 �x�������F1)
--
    -- ===============================================
    -- ���[�J����O
    -- ===============================================
    --*** �Ώۃf�[�^�Ȃ���O ***
    target_no_data_expt  EXCEPTION;
--
  BEGIN
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ===============================================
    -- �P�j��������
    -- ===============================================
    init(
      ov_errbuf   => lv_errbuf
    , ov_retcode  => lv_retcode
    , ov_errmsg   => lv_errmsg
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================================
    -- �Q�j���ގ��OIF�e�[�u����񒊏o����
    -- �R�j���ގ��OIF�w�b�_ID�擾����
    -- ===============================================
	get_trans_oif_data(
      ov_errbuf   => lv_errbuf
    , ov_retcode  => lv_retcode
    , ov_errmsg   => lv_errmsg
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    IF (gt_mtl_trans_oif.COUNT <> 0) THEN
      -- ���ގ��OIF�f�[�^���擾���ꂽ�ꍇ�A�ȉ������s
      --
      -- ===============================================
      -- �S�j���ގ��OIF�w�b�_ID�X�V����
      -- ===============================================
      set_trans_oif_header_id(
        ov_errbuf   => lv_errbuf
      , ov_retcode  => lv_retcode
      , ov_errmsg   => lv_errmsg
      );
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      ELSIF ( lv_retcode = cv_status_warn ) THEN
        ov_retcode  :=  lv_retcode;
      END IF;
      --
      COMMIT;
      --
  --
      -- ===============================================
      -- �T�j������[�J�[�N������
      -- ===============================================
      start_trans_worker(
        ov_errbuf   => lv_errbuf
      , ov_retcode  => lv_retcode
      , ov_errmsg   => lv_errmsg
      );
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      ELSIF ( lv_retcode = cv_status_warn ) THEN
        ov_retcode  :=  lv_retcode;
      END IF;
  --
      -- ===============================================
      -- �U�j������[�J�[�I���`�F�b�N
      -- ===============================================
      IF (gt_request_id_tbl.COUNT <> 0) THEN
        -- ������[�J�[���P��ȏ�N������Ă���ꍇ
        chk_trans_worker(
          ov_errbuf   => lv_errbuf
        , ov_retcode  => lv_retcode
        , ov_errmsg   => lv_errmsg
        );
        IF ( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        ELSIF ( lv_retcode = cv_status_warn ) THEN
          ov_retcode  :=  lv_retcode;
        END IF;
      END IF;
    END IF;
--
  EXCEPTION
    -- *** ���������ʗ�O ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS��O ***
    WHEN OTHERS THEN
      ov_errmsg  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END submain;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : �R���J�����g���s�t�@�C���o�^�v���V�[�W��
   **********************************************************************************/
  PROCEDURE main(
    errbuf          OUT VARCHAR2
  , retcode         OUT VARCHAR2
  )
  IS
--
    -- ===============================================
    -- ���[�J���萔
    -- ===============================================
    cv_prg_name      CONSTANT VARCHAR2(30)  := 'main';  -- �v���O������
--
    -- ===============================================
    -- ���[�J���ϐ�
    -- ===============================================
    lv_errbuf        VARCHAR2(5000) DEFAULT NULL;              -- �G���[���b�Z�[�W
    lv_retcode       VARCHAR2(1)    DEFAULT cv_status_normal;  -- ���^�[���R�[�h
    lv_errmsg        VARCHAR2(5000) DEFAULT NULL;              -- ���[�U�[�G���[���b�Z�[�W
    lv_outmsg        VARCHAR2(5000) DEFAULT NULL;              -- ���b�Z�[�W�ϐ�
    lv_message_code  VARCHAR2(100)  DEFAULT NULL;              -- ���b�Z�[�W�R�[�h
    
--
  BEGIN
    -- ===============================================
    -- �R���J�����g�w�b�_���b�Z�[�W�o�͊֐��̌Ăяo��
    -- ===============================================
    xxccp_common_pkg.put_log_header(
      ov_retcode => lv_retcode
    , ov_errbuf  => lv_errbuf
    , ov_errmsg  => lv_errmsg
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_expt;
    END IF;
--
    -- ===============================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ===============================================
    submain(
      ov_errbuf       => lv_errbuf
    , ov_retcode      => lv_retcode
    , ov_errmsg       => lv_errmsg
    );
--
    -- ===============================================
    -- �V�j�I������
    -- ===============================================
    -- ============================
    --  �G���[�o��
    -- ============================
    IF ( lv_retcode = cv_status_error ) THEN
      FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => lv_errmsg
      );
      FND_FILE.PUT_LINE(
        which  => FND_FILE.LOG
      , buff   => lv_errbuf
      );
      -- ��s���o��
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => cv_space
      );
    END IF;
--
    -- ============================
    --  �Ώی����o��
    -- ============================
    lv_outmsg    := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appli_short_name_xxcoi
                    , iv_name         => cv_msg_xxcoi_10395
                    , iv_token_name1  => cv_token_count
                    , iv_token_value1 => TO_CHAR( gn_target_cnt )
                    );
    FND_FILE.PUT_LINE(
      which  => FND_FILE.OUTPUT
    , buff   => lv_outmsg
    );
--
    -- ============================
    --  �X�V�����o��
    -- ============================
    lv_outmsg    := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appli_short_name_xxcoi
                    , iv_name         => cv_msg_xxcoi_10391
                    , iv_token_name1  => cv_token_count
                    , iv_token_value1 => TO_CHAR( gn_normal_cnt )
                    );
    FND_FILE.PUT_LINE(
      which  => FND_FILE.OUTPUT
    , buff   => lv_outmsg
    );
--
    -- ============================
    --  �x�������o��
    -- ============================
    lv_outmsg    := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appli_short_name_xxcoi
                    , iv_name         => cv_msg_xxcoi_10396
                    , iv_token_name1  => cv_token_count
                    , iv_token_value1 => TO_CHAR( gn_warn_cnt )
                    );
    FND_FILE.PUT_LINE(
      which  => FND_FILE.OUTPUT
    , buff   => lv_outmsg
    );
--
    -- ============================
    --  ���[�J�[�N����
    -- ============================
    lv_outmsg    := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appli_short_name_xxcoi
                    , iv_name         => cv_msg_xxcoi_10392
                    , iv_token_name1  => cv_token_count
                    , iv_token_value1 => TO_CHAR( gn_conc_start_cnt )
                    );
    FND_FILE.PUT_LINE(
      which  => FND_FILE.OUTPUT
    , buff   => lv_outmsg
    );
--
    -- ============================
    --  ���[�J�[�G���[����
    -- ============================
    lv_outmsg    := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appli_short_name_xxcoi
                    , iv_name         => cv_msg_xxcoi_10394
                    , iv_token_name1  => cv_token_count
                    , iv_token_value1 => TO_CHAR( gn_sub_conc_err_cnt )
                    );
    FND_FILE.PUT_LINE(
      which  => FND_FILE.OUTPUT
    , buff   => lv_outmsg
    );
--
    -- ============================
    --  �G���[�����o��
    -- ============================
    IF ( lv_retcode = cv_status_error ) THEN
      gn_error_cnt := 1;
    END IF;
    lv_outmsg    := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appli_short_name_xxccp
                    , iv_name         => cv_msg_xxccp1_90002
                    , iv_token_name1  => cv_token_count
                    , iv_token_value1 => TO_CHAR( gn_error_cnt )
                    );
    FND_FILE.PUT_LINE(
      which  => FND_FILE.OUTPUT
    , buff   => lv_outmsg
    );
--
    -- ============================
    --  ��s�o��  
    -- ============================
    FND_FILE.PUT_LINE(
      which  => FND_FILE.OUTPUT
    , buff   => ''
    );
--
    -- ============================
    -- �����I�����b�Z�[�W�o��
    -- ============================
    IF ( lv_retcode    = cv_status_normal ) THEN
      lv_message_code := cv_msg_xxccp1_90004;
    ELSIF ( lv_retcode = cv_status_warn ) THEN
      lv_message_code := cv_msg_xxccp1_90005;
    ELSE
      lv_message_code := cv_msg_xxccp1_90006;
    END IF;
    lv_outmsg    := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appli_short_name_xxccp
                    , iv_name         => lv_message_code
                    );
    FND_FILE.PUT_LINE(
      which  => FND_FILE.OUTPUT
    , buff   => lv_outmsg
    );
--
    -- ===============================================
    -- �X�e�[�^�X�Z�b�g
    -- ===============================================
    retcode := lv_retcode;
--
    -- ===============================================
    -- �I���X�e�[�^�X�G���[���A���[���o�b�N
    -- ===============================================
    IF ( retcode = cv_status_error ) THEN
      ROLLBACK;
    END IF;
--
  EXCEPTION
    -- *** ���ʊ֐���O ***
    WHEN global_api_expt THEN
      errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      retcode := cv_status_error;
      ROLLBACK;
    -- *** ���ʊ֐�OTHERS��O ***
    WHEN global_api_others_expt THEN
      errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      retcode := cv_status_error;
      ROLLBACK;
    -- *** OTHERS��O ***
    WHEN OTHERS THEN
      errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      retcode := cv_status_error;
      ROLLBACK;
  END main;
END XXCOI015A01C;
/
