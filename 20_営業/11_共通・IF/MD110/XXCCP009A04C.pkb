CREATE OR REPLACE PACKAGE BODY XXCCP009A04C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * Package Name     : XXCCP009A04C(body)
 * Description      : �������ۗ��X�e�[�^�X�X�V�A�b�v���[�h����
 * Version          : 1.0
 *
 * Program List
 * ------------------------- ------------------------------------------------------------
 *  Name                      Description
 * ------------------------- ------------------------------------------------------------
 *  output_warn_msg          �x�����b�Z�[�W�o�͏���
 *  submain                  ���C�������v���V�[�W��
 *  main                     �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2014/10/30    1.0   A.Takeshita      [E_�{�ғ�_11000]�V�K�쐬
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
  cn_last_updated_by        CONSTANT NUMBER      := fnd_global.user_id;                 --LAST_UPDATED_BY
  cd_last_update_date       CONSTANT DATE        := SYSDATE;                            --LAST_UPDATE_DATE
  cn_last_update_login      CONSTANT NUMBER      := fnd_global.login_id;                --LAST_UPDATE_LOGIN
  cn_request_id             CONSTANT NUMBER      := fnd_global.conc_request_id;         --REQUEST_ID
  cn_program_application_id CONSTANT NUMBER      := fnd_global.prog_appl_id;            --PROGRAM_APPLICATION_ID
  cn_program_id             CONSTANT NUMBER      := fnd_global.conc_program_id;         --PROGRAM_ID
  cd_program_update_date    CONSTANT DATE        := SYSDATE;                            --PROGRAM_UPDATE_DATE
  cv_msg_part      CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont      CONSTANT VARCHAR2(3) := '.';
  cv_msg_pnt       CONSTANT VARCHAR2(3) := ',';
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
--
  -- ===============================
  -- ���[�U�[��`��O
  -- ===============================
  --
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name               CONSTANT VARCHAR2(100) := 'XXCCP009A04C';                 -- �v���O������
  cn_org_id                 CONSTANT NUMBER        := fnd_global.org_id;              -- ���O�C�����[�UORG_ID
  cv_flag_y                 CONSTANT VARCHAR2(1)   := 'Y';                            -- Y
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gv_header_flg    VARCHAR2(1)  DEFAULT 'N';                    -- �x���w�b�_�m�F�p
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���E�J�[�\��
  -- ===============================
  --�������X�V�f�[�^�J�[�\��
  CURSOR data_cur( in_file_id NUMBER )
  IS
    SELECT    xdpw.execute_mode     execute_mode   --���s���[�h
             ,xdpw.condition_1      condition_1    --����1(�����ԍ�)
             ,xdpw.condition_2      condition_2    --����2(�ύX�O�X�e�[�^�X)
             ,xdpw.chr_column_1     chr_column_1   --�ύX�l1(�ύX��X�e�[�^�X)
    FROM     xxccp_data_patch_work xdpw
    WHERE    xdpw.file_id = in_file_id
    ORDER BY
               xdpw.data_sequence;
--
  data_rec data_cur%ROWTYPE;
--
--
  /**********************************************************************************
   * Procedure Name   : output_warn_msg
   * Description      : �x�����b�Z�[�W�o�͏���
   **********************************************************************************/
  PROCEDURE output_warn_msg(
    it_data_rec   IN  data_cur%ROWTYPE,     --   1.�f�[�^���R�[�h
    iv_message    IN  VARCHAR2,     --   2.���b�Z�[�W���e
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2      --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
--
  IS
--
--#####################  �Œ胍�[�J���萔�ϐ��錾�� START   ####################
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'output_warn_msg'; -- �v���O������
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
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
    IF ( gv_header_flg <> cv_flag_y ) THEN
      -- �x�����O�p�w�b�_�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   =>   '"'||  '���s���[�h'                ||'","'
                        ||  '�����ԍ�'                  ||'","'
                        ||  '�ύX�O�X�e�[�^�X'          ||'","'
                        ||  '�ύX��X�e�[�^�X'          ||'","'
                        ||  '�x�����b�Z�[�W'            ||'"'
      );
      gv_header_flg := cv_flag_y;
    END IF;
    -- �x�����O�o��
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   =>  '"'   || it_data_rec.execute_mode     || '","'  --���s���[�h
                        || it_data_rec.condition_1      || '","'  --�����ԍ�
                        || it_data_rec.condition_2      || '","'  --�ύX�O�X�e�[�^�X
                        || it_data_rec.chr_column_1     || '","'  --�ύX��X�e�[�^�X
                        || iv_message                   || '"'    --�x�����b�Z�[�W
    );
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
  END output_warn_msg;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    iv_file_id    IN  VARCHAR2,     --   1.�t�@�C��ID
    iv_fmt_ptn    IN  VARCHAR2,     --   2.�t�H�[�}�b�g�p�^�[��
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2      --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
--
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
    --�Q�ƃ^�C�v�p�ϐ�
    cv_lookup_fo              CONSTANT VARCHAR2(25) := 'XXCCP1_FILE_UPLOAD_OBJ';
    cv_lookup_type            CONSTANT VARCHAR2(25) := 'XX03_AR_INV_HOLD_STATUS';
    cv_lang                   CONSTANT VARCHAR2(2)  := USERENV('LANG');
    cv_exe_mode_0             CONSTANT VARCHAR2(1)  := '0';
    cv_exe_mode_1             CONSTANT VARCHAR2(1)  := '1';
    cn_app_status             CONSTANT VARCHAR2(3)  := 'APP';
    --CSV���ڐ�
    cn_csv_file_col_num       CONSTANT NUMBER       := 4;            -- CSV�t�@�C�����ڐ�
    -- ���t����
    cv_date_format            CONSTANT VARCHAR2(21) := 'RRRR/MM/DD HH24:MI:SS';
--
    -- *** ���[�J���ϐ� ***
    --�Ɩ����t
    ld_process_date           CONSTANT DATE         := xxccp_common_pkg2.get_process_date;
    --�A�b�v���[�h�p�ϐ�
    lv_file_ul_name  fnd_lookup_values.meaning%TYPE;              -- �t�@�C���A�b�v���[�h����
    lv_file_name     xxccp_mrp_file_ul_interface.file_name%TYPE;  -- CSV�t�@�C����
    l_file_data_tab  xxccp_common_pkg2.g_file_data_tbl;           -- �s�P�ʃf�[�^�i�[�p�z��
    ln_col_num       NUMBER;                                      -- ���ڐ��擾�p
    ln_line_cnt      NUMBER;                                      -- CSV�t�@�C���e�s�Q�Ɨp�J�E���^
    ln_column_cnt    NUMBER;                                      -- CSV�t�@�C���e��Q�Ɨp�J�E���^
    ln_file_id       NUMBER  := TO_NUMBER(iv_file_id);            -- �t�@�C��ID
    ln_seq           NUMBER  := 0;                                -- ���[�N�e�[�u���p�V�[�P���X�ԍ�
    ln_head_cnt      NUMBER  := 0;                                -- ���O�w�b�_�m�F�p
    ln_cnt           NUMBER  := 1;                                -- ���[�v�J�E���^
    ln_app_cnt       NUMBER  := 1;                                -- �����σ��R�[�h�J�E���^
    lv_exec_flag     VARCHAR2(1);                                 -- ���s���[�h
    lv_err_flg       VARCHAR2(1)  DEFAULT 'N';                    -- �G���[�t���O
    --�f�[�^�`�F�b�N�p�ϐ�
    lv_file_chk              xxccp_data_patch_work.file_id%TYPE;
    lv_lookup_chk            fnd_lookup_values.lookup_code%TYPE;
    lv_cust_trx_id           ar_receivable_applications_all.customer_trx_id%TYPE;
--
    lv_doc_seq_val           ra_customer_trx_all.doc_sequence_value%TYPE;
    lv_attribute7            ra_customer_trx_all.attribute7%TYPE;
    lv_trx_number            ra_customer_trx_all.trx_number%TYPE;
    lv_trx_date              ra_customer_trx_all.trx_date%TYPE;
    lv_name                  ra_cust_trx_types_all.name%TYPE;
    lv_attribute1            ra_customer_trx_all.attribute1%TYPE;
    lv_conc_name             fnd_concurrent_programs_tl.user_concurrent_program_name%TYPE;
    lv_request_id            ra_customer_trx_all.request_id%TYPE;
    lv_last_update_date      ra_customer_trx_all.last_update_date%TYPE;
    lv_account_number        hz_cust_accounts.account_number%TYPE;
    lv_party_name            hz_parties.party_name%TYPE;
    lv_amount_due_original   ar_payment_schedules_all.amount_due_original%TYPE;
    lv_amount_due_remaining  ar_payment_schedules_all.amount_due_remaining%TYPE;
    lv_amount_applied        ar_payment_schedules_all.amount_applied%TYPE;
    lv_amount_adjusted       ar_payment_schedules_all.amount_adjusted%TYPE;
    lv_amount_credited       ar_payment_schedules_all.amount_credited%TYPE;
    lv_hp_status             hz_parties.status%TYPE;
    lv_hca_status            hz_cust_accounts.status%TYPE;
    --
    lt_customer_trx_id       ra_customer_trx_all.customer_trx_id%TYPE;
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
--
    TYPE gt_col_data_ttype    IS TABLE OF VARCHAR2(5000) INDEX BY BINARY_INTEGER;    -- 1�����z��i���ځj
    TYPE gt_rec_data_ttype    IS TABLE OF gt_col_data_ttype INDEX BY BINARY_INTEGER; -- 2�����z��i���R�[�h�j�i���ځj
    lt_path_data_tab  gt_rec_data_ttype;
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
    -- �R���J�����g�p�����[�^�o��
    --==============================================================
    -- �t�@�C��ID�o��
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => '�t�@�C��ID                    �F' || iv_file_id
    );
    -- �t�H�[�}�b�g�p�^�[���o��
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => '�p�����[�^�t�H�[�}�b�g�p�^�[���F' || iv_fmt_ptn
    );
    --
    --==============================================================
    -- �t�@�C���A�b�v���[�h���̏o��
    --==============================================================
    SELECT flv.meaning meaning
    INTO   lv_file_ul_name
    FROM   fnd_lookup_values flv
    WHERE  flv.lookup_type  = cv_lookup_fo
    AND    flv.lookup_code  = iv_fmt_ptn
    AND    flv.language     = cv_lang
    AND    flv.enabled_flag = cv_flag_y
    AND    ld_process_date BETWEEN flv.start_date_active 
                           AND     NVL(flv.end_date_active, ld_process_date)
    ;
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => '�t�@�C���A�b�v���[�h����      �F'||lv_file_ul_name
    );
    --
    --==============================================================
    -- �t�@�C�����o��
    --==============================================================
    SELECT  xmfui.file_name file_name
    INTO    lv_file_name
    FROM    xxccp_mrp_file_ul_interface xmfui
    WHERE   xmfui.file_id = ln_file_id
    FOR UPDATE NOWAIT
    ;
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => '�t�@�C����                    �F'||lv_file_name
    );
    --
    --���s�̏o��
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
    --
    --==============================================================
    -- �A�b�v���[�h�f�[�^�擾
    --==============================================================
    -- BLOB�f�[�^�ϊ��֐��ɂ��s�P�ʃf�[�^�𒊏o
    xxccp_common_pkg2.blob_to_varchar2(
       in_file_id   => ln_file_id       -- �t�@�C��ID
      ,ov_file_data => l_file_data_tab  -- �t�@�C���f�[�^
      ,ov_errbuf    => lv_errbuf        -- �G���[�E���b�Z�[�W            -- # �Œ� #
      ,ov_retcode   => lv_retcode       -- ���^�[���E�R�[�h              -- # �Œ� #
      ,ov_errmsg    => lv_errmsg        -- ���[�U�[�E�G���[�E���b�Z�[�W  -- # �Œ� #
    );
    -- 0���G���[(�w�b�_�݂̂ł��G���[�Ƃ���)
    IF (l_file_data_tab.COUNT <= 1 ) THEN
      lv_errbuf := '�A�b�v���[�h�t�@�C���Ƀf�[�^������܂���B';
      RAISE global_api_others_expt;
    END IF;
--
    --�^�C�g���s�͏��O�A�f�[�^�s����擾����
    FOR ln_line_cnt IN 2 .. l_file_data_tab.COUNT LOOP
      --���ڐ��擾
      ln_col_num := NVL(LENGTH(l_file_data_tab(ln_line_cnt)), 0)
                      - NVL(LENGTH(REPLACE(l_file_data_tab(ln_line_cnt), ',', NULL)), 0) + 1;
      --���ڐ��`�F�b�N
      IF (ln_col_num <> cn_csv_file_col_num) THEN
         lv_errbuf := '['|| ln_line_cnt || '�s��] �A�b�v���[�h�t�@�C���̍��ڐ��ɉߕs��������܂��B';
         RAISE global_api_others_expt;
      ELSE
        <<column_loop>>
        FOR ln_column_cnt IN 1 .. cn_csv_file_col_num LOOP
          --���ڕ���
          lt_path_data_tab(ln_line_cnt - 1)(ln_column_cnt) := xxccp_common_pkg.char_delim_partition(
                                                               iv_char     => l_file_data_tab(ln_line_cnt)
                                                              ,iv_delim    => ','
                                                              ,in_part_num => ln_column_cnt
                                                          );
          --�_�u���N�H�[�e�[�V�����폜
          lt_path_data_tab(ln_line_cnt - 1)(ln_column_cnt) := SUBSTR(
                                                            lt_path_data_tab(ln_line_cnt - 1)(ln_column_cnt) 
                                                           ,2
                                                           ,LENGTH(lt_path_data_tab(ln_line_cnt - 1)(ln_column_cnt)) - 2
                                                          );
        END LOOP column_loop;
      END IF;
    END LOOP line_loop;
--
    --==============================================================
    -- �A�b�v���[�h�f�[�^���p�b�`�p�e�[�u���֓o�^
    --==============================================================
    <<ins_line_loop>>
    FOR ln_line_cnt IN 1 .. lt_path_data_tab.COUNT LOOP
      --�f�[�^�V�[�P���X�̔�
      ln_seq := ln_seq + 1;
      --�p�b�`�p�e�[�u���o�^
      INSERT INTO xxccp_data_patch_work (
         file_id
        ,data_sequence
        ,execute_mode
        ,condition_1
        ,condition_2
        ,chr_column_1
      ) VALUES (
         ln_file_id                                               -- �t�@�C��ID
        ,ln_seq                                                   -- �f�[�^�V�[�P���X
        ,lt_path_data_tab(ln_line_cnt)(1)                         -- ���s���[�h
        ,lt_path_data_tab(ln_line_cnt)(2)                         -- �����l1�i�����ԍ��j
        ,lt_path_data_tab(ln_line_cnt)(3)                         -- �����l2�i�ύX�O�X�e�[�^�X�j
        ,lt_path_data_tab(ln_line_cnt)(4)                         -- �ύX�l1�i�ύX��X�e�[�^�X�j
      );
--
      --�Ώی����J�E���g
      gn_target_cnt := gn_target_cnt + 1;
--
    END LOOP ins_line_loop;
--
    --==============================================================
    -- �t�@�C��IF�f�[�^�폜
    --==============================================================
    DELETE FROM xxccp_mrp_file_ul_interface xmfui
    WHERE  xmfui.file_id = ln_file_id;
--
    lt_path_data_tab.DELETE;
--
--
    --==============================================================
    -- �f�[�^�X�V����
    --==============================================================
    --�Ώۃf�[�^���o
    OPEN data_cur(
           in_file_id => ln_file_id
         );
   --
    LOOP
      FETCH data_cur INTO data_rec;
      EXIT WHEN data_cur%NOTFOUND;
--
      --�G���[�t���O������
      lv_err_flg := 'N';
--
      --�P�s�ڂ̎��s���[�h���擾
      IF ( ln_cnt = 1 ) THEN
      --
        -- ���s���[�h�`�F�b�N(0�A1�ȊO�̓G���[)
        IF ( data_rec.execute_mode IS NULL )
          OR( ( data_rec.execute_mode <> cv_exe_mode_0 )
            AND ( data_rec.execute_mode <> cv_exe_mode_1 ) ) THEN
           lv_errbuf := '���s���[�h�ɂ�0(�Ώۊm�F)�܂���1(�f�[�^�X�V)�̒l����͂��ĉ������B';
           RAISE global_api_others_expt;
        END IF;
        --
        lv_exec_flag := data_rec.execute_mode;
        --
      END IF;
--
      -- �����ԍ�NULL�`�F�b�N
      IF ( data_rec.condition_1 IS NULL ) THEN
        --�x������ �t���O��Y�ɐݒ�
        lv_err_flg := cv_flag_y;
        --
        --�x�����b�Z�[�W�o�͏���
        output_warn_msg(
           it_data_rec => data_rec
          ,iv_message  => '['|| ln_cnt || '�s��] �����ԍ������ݒ�ł��B'
          ,ov_errbuf   => lv_errbuf
          ,ov_retcode  => lv_retcode
          ,ov_errmsg   => lv_errmsg
        );
        IF (lv_retcode <> cv_status_normal) THEN
          RAISE global_api_others_expt;
        END IF;
        -- �x�������J�E���g
        gn_warn_cnt := gn_warn_cnt + 1;
        --
      ELSE
        --
        --�����ԍ���Ӄ`�F�b�N
        BEGIN
        --
          SELECT xdpw.condition_1 condition_1
          INTO   lv_file_chk
          FROM   xxccp_data_patch_work xdpw
          WHERE  xdpw.file_id      =  ln_file_id
          AND    xdpw.condition_1  =  data_rec.condition_1;
        --
        EXCEPTION
          --��Ӑ���G���[
          WHEN TOO_MANY_ROWS THEN
          lv_errbuf := '[' || ln_cnt || '�s��] �����ԍ��F' || data_rec.condition_1 || ' ���t�@�C�����ň�ӂł͂���܂���B';
          RAISE global_api_others_expt;
        END;
        --
        --�����ԍ����݃`�F�b�N
        BEGIN
        --
            SELECT rcta.customer_trx_id  customer_trx_id
            INTO   lt_customer_trx_id
            FROM   ra_customer_trx_all rcta
            WHERE  rcta.doc_sequence_value  =  data_rec.condition_1
              AND  rcta.attribute7          =  data_rec.condition_2
            FOR UPDATE NOWAIT;
        --
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
          --�t���O��Y�ɐݒ�
          lv_err_flg := cv_flag_y;
          --
          --�x�����b�Z�[�W�o�͏���
          output_warn_msg(
             it_data_rec => data_rec
            ,iv_message  => '�X�V�ΏۂƂȂ镶���ԍ������݂��܂���B' 
            ,ov_errbuf   => lv_errbuf
            ,ov_retcode  => lv_retcode
            ,ov_errmsg   => lv_errmsg
          );
          IF (lv_retcode <> cv_status_normal) THEN
            RAISE global_api_others_expt;
          END IF;
          -- �x�������J�E���g
          gn_warn_cnt := gn_warn_cnt + 1;
        --
        END;
      --
      END IF;
      --
      --�X�e�[�^�X���݃`�F�b�N(�ύX�O�X�e�[�^�X�j
      -- NULL�`�F�b�N
      IF ( data_rec.condition_2 IS NOT NULL ) THEN
        --
        BEGIN
        --
            SELECT flv.lookup_code lookup_code
            INTO   lv_lookup_chk
            FROM   fnd_lookup_values flv
            WHERE  flv.lookup_type   =  cv_lookup_type
            AND    flv.lookup_code   =  data_rec.condition_2
            AND    flv.language      =  cv_lang
            AND    flv.enabled_flag  =  cv_flag_y;
        --
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            --�t���O��Y�ɐݒ�
            lv_err_flg := cv_flag_y;
            --�x�����b�Z�[�W�o�͏���
            output_warn_msg(
               it_data_rec => data_rec
              ,iv_message  => '�ύX�O�X�e�[�^�X���s���ł��B'
              ,ov_errbuf   => lv_errbuf
              ,ov_retcode  => lv_retcode
              ,ov_errmsg   => lv_errmsg
            );
            IF (lv_retcode <> cv_status_normal) THEN
              RAISE global_api_others_expt;
            END IF;
            -- �x�������J�E���g
            gn_warn_cnt := gn_warn_cnt + 1;
        END;
--
      ELSE
        --�t���O��Y�ɐݒ�
        lv_err_flg := cv_flag_y;
        --�x�����b�Z�[�W�o�͏���
        output_warn_msg(
           it_data_rec => data_rec
          ,iv_message  => '�ύX�O�X�e�[�^�X�����ݒ�ł��B'
          ,ov_errbuf   => lv_errbuf
          ,ov_retcode  => lv_retcode
          ,ov_errmsg   => lv_errmsg
        );
        IF (lv_retcode <> cv_status_normal) THEN
          RAISE global_api_others_expt;
        END IF;
        -- �x�������J�E���g
        gn_warn_cnt := gn_warn_cnt + 1;
--
      END IF;
--
      --�X�e�[�^�X���݃`�F�b�N(�ύX��X�e�[�^�X�j
      -- NULL�`�F�b�N
      IF ( data_rec.chr_column_1 IS NOT NULL ) THEN
        BEGIN
          SELECT flv.lookup_code lookup_code
          INTO   lv_lookup_chk
          FROM   fnd_lookup_values flv
          WHERE  flv.lookup_type   =  cv_lookup_type
          AND    flv.lookup_code   =  data_rec.chr_column_1
          AND    flv.language      =  cv_lang
          AND    flv.enabled_flag  =  cv_flag_y;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
          --�t���O��Y�ɐݒ�
          lv_err_flg := cv_flag_y;
          --�x�����b�Z�[�W�o�͏���
          output_warn_msg(
             it_data_rec => data_rec
            ,iv_message  => '�ύX��X�e�[�^�X���s���ł��B'
            ,ov_errbuf   => lv_errbuf
            ,ov_retcode  => lv_retcode
            ,ov_errmsg   => lv_errmsg
          );
          IF (lv_retcode <> cv_status_normal) THEN
            RAISE global_api_others_expt;
          END IF;
          -- �x�������J�E���g
          gn_warn_cnt := gn_warn_cnt + 1;
--
        END;
--
      ELSIF ( data_rec.chr_column_1 IS NULL ) THEN
        --�t���O��Y�ɐݒ�
        lv_err_flg := cv_flag_y;
        --�x�����b�Z�[�W�o�͏���
        output_warn_msg(
           it_data_rec => data_rec
          ,iv_message  => '�ύX��X�e�[�^�X�����ݒ�ł��B'
          ,ov_errbuf   => lv_errbuf
          ,ov_retcode  => lv_retcode
          ,ov_errmsg   => lv_errmsg
        );
        IF (lv_retcode <> cv_status_normal) THEN
          RAISE global_api_others_expt;
        END IF;
        -- �x�������J�E���g
        gn_warn_cnt := gn_warn_cnt + 1;
      --
      END IF;
      --
      --���������σ`�F�b�N
      SELECT  COUNT(1)
      INTO    ln_app_cnt
      FROM    ra_customer_trx_all             rcta
             ,ar_receivable_applications_all  araa
      WHERE   rcta.customer_trx_id     = araa.applied_customer_trx_id
      AND     rcta.doc_sequence_value  = data_rec.condition_1
      AND     araa.status              = cn_app_status    --'������'
      AND     araa.display             = cv_flag_y        --'�\���v��'
      ;
      IF (ln_app_cnt <> 0) THEN
        --�t���O��Y�ɐݒ�
        lv_err_flg := cv_flag_y;
        --�x�����b�Z�[�W�o�͏���
        output_warn_msg(
           it_data_rec => data_rec
          ,iv_message  => '���̕����ԍ��͏����ςł��B'
          ,ov_errbuf   => lv_errbuf
          ,ov_retcode  => lv_retcode
          ,ov_errmsg   => lv_errmsg
        );
        IF (lv_retcode <> cv_status_normal) THEN
          RAISE global_api_others_expt;
        END IF;
        -- �x�������J�E���g
        gn_warn_cnt := gn_warn_cnt + 1;
      END IF;
--
      --�X�V��m�F�p�f�[�^�o��
      IF ( lv_err_flg <> cv_flag_y ) THEN
        -- ���O�p�w�b�_�o��
        output_warn_msg(
           it_data_rec => data_rec
          ,iv_message  => NULL
          ,ov_errbuf   => lv_errbuf
          ,ov_retcode  => lv_retcode
          ,ov_errmsg   => lv_errmsg
        );
        IF (lv_retcode <> cv_status_normal) THEN
          RAISE global_api_others_expt;
        END IF;
--
      END IF;
--
      --����f�[�^�Ŏ��s���[�h���X�V�̏ꍇ�̂ݍX�V���������{
      IF ( ( lv_err_flg <> cv_flag_y ) AND ( lv_exec_flag = cv_exe_mode_1 ) )  THEN
        --
        UPDATE ra_customer_trx_all rcta
        SET    rcta.attribute7       = data_rec.chr_column_1
        WHERE  rcta.customer_trx_id  = lt_customer_trx_id;
        --
        -- ���������J�E���g
        gn_normal_cnt := gn_normal_cnt + 1;
--
      END IF;
      --
      --�J�E���g�A�b�v
      ln_cnt := ln_cnt + 1;
    END LOOP;
--
    CLOSE data_cur;
--
    --���s�̏o��
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
--
    --==============================================================
    -- ���O�o�͏���
    --==============================================================
    --���O�o�͗p�ɃJ�[�\���I�[�v��
    OPEN data_cur(
           in_file_id => ln_file_id
         );
    LOOP
      FETCH data_cur INTO data_rec;
      EXIT WHEN data_cur%NOTFOUND;
--
      -- ���O�o�͗p
      BEGIN
        SELECT rcta.doc_sequence_value    doc_sequence_value            -- �����ԍ�
              ,rcta.attribute7            attribute7                    -- �������ۗ��X�e�[�^�X
              ,rcta.trx_number            trx_number                    -- ����ԍ�
              ,rcta.trx_date              trx_date                      -- �����
              ,rctta.name                 name                          -- ����^�C�v
              ,rctta.attribute1           attribute1                    -- �������o�͑Ώۋ敪(Y���Ώ�)
              ,(SELECT fcpt.user_concurrent_program_name user_concurrent_program_name
                FROM   fnd_concurrent_programs_tl  fcpt
                WHERE  1 = 1
                AND    fcpt.concurrent_program_id = rcta.program_id
                AND    fcpt.language              = cv_lang
               )                          user_concurrent_program_name  -- �ŏI�X�V�v���O������(�������׃f�[�^�쐬���Ώ�)
              ,rcta.request_id            request_id                    -- �ŏI�X�V�v��ID
              ,rcta.last_update_date      last_update_date              -- �ŏI�X�V��
              ,hca.account_number         account_number                -- �����ڋq�ԍ�
              ,hp.party_name              party_name                    -- �����ڋq��
              ,apsa.amount_due_original   amount_due_original           -- �������������z
              ,apsa.amount_due_remaining  amount_due_remaining          -- ������c��
              ,apsa.amount_applied        amount_applied                -- �����ώc��
              ,apsa.amount_adjusted       amount_adjusted               -- �C���ώc��
              ,apsa.amount_credited       amount_credited               -- �N���W�b�g�����c��
              ,hp.status                  hp_status                     -- �ڋq�p�[�e�B�X�e�[�^�X
              ,hca.status                 hca_status                    -- �ڋq�A�J�E���g�X�e�[�^�X
        INTO   lv_doc_seq_val
              ,lv_attribute7
              ,lv_trx_number
              ,lv_trx_date
              ,lv_name
              ,lv_attribute1
              ,lv_conc_name
              ,lv_request_id
              ,lv_last_update_date
              ,lv_account_number
              ,lv_party_name
              ,lv_amount_due_original
              ,lv_amount_due_remaining
              ,lv_amount_applied
              ,lv_amount_adjusted
              ,lv_amount_credited
              ,lv_hp_status
              ,lv_hca_status
        FROM   ra_customer_trx_all                                      rcta
              ,ra_cust_trx_types_all                                    rctta
              ,ar_payment_schedules_all                                 apsa
              ,hz_cust_accounts                                         hca
              ,hz_parties                                               hp
        WHERE  1 = 1
        AND    hp.party_id             = hca.party_id
        AND    hca.cust_account_id     = rcta.bill_to_customer_id
        AND    rctta.cust_trx_type_id  = rcta.cust_trx_type_id
        AND    apsa.customer_trx_id    = rcta.customer_trx_id
        AND    apsa.org_id             = rcta.org_id
        AND    rctta.org_id            = rcta.org_id
        AND    rcta.org_id             = cn_org_id                      -- ���O�C�����[�U�g�D
        AND    rcta.doc_sequence_value = data_rec.condition_1           -- �����ԍ�
        ;
      EXCEPTION
          WHEN NO_DATA_FOUND THEN
          CONTINUE;
      END;
--
      -- �X�V��̃f�[�^��\��
      IF ( ln_head_cnt = 0 ) THEN
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => 
                  '"�����ԍ�",'                       ||
                  '"�������ۗ��X�e�[�^�X",'           ||
                  '"����ԍ�",'                       ||
                  '"�����",'                         ||
                  '"����^�C�v",'                     ||
                  '"�������o�͑Ώۋ敪",'             ||
                  '"�ŏI�X�V�v���O������",'           ||
                  '"�ŏI�X�V�v��ID",'                 ||
                  '"�ŏI�X�V��",'                     ||
                  '"�����ڋq�ԍ�",'                   ||
                  '"�����ڋq��",'                     ||
                  '"�������������z",'                 ||
                  '"������c��",'                     ||
                  '"�����ώc��",'                     ||
                  '"�C���ώc��",'                     ||
                  '"�N���W�b�g�����c��",'             ||
                  '"�ڋq�p�[�e�B�X�e�[�^�X",'         ||
                  '"�ڋq�A�J�E���g�X�e�[�^�X"'
          );
          ln_head_cnt := 1;
      END IF;
--
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   =>'"' ||
                  lv_doc_seq_val                                         || '","' ||
                  lv_attribute7                                          || '","' ||
                  lv_trx_number                                          || '","' ||
                  TO_CHAR(lv_trx_date, cv_date_format)                   || '","' ||
                  lv_name                                                || '","' ||
                  lv_attribute1                                          || '","' ||
                  lv_conc_name                                           || '","' ||
                  lv_request_id                                          || '","' ||
                  TO_CHAR(lv_last_update_date, cv_date_format)           || '","' ||
                  lv_account_number                                      || '","' ||
                  lv_party_name                                          || '","' ||
                  lv_amount_due_original                                 || '","' ||
                  lv_amount_due_remaining                                || '","' ||
                  lv_amount_applied                                      || '","' ||
                  lv_amount_adjusted                                     || '","' ||
                  lv_amount_credited                                     || '","' ||
                  lv_hp_status                                           || '","' ||
                  lv_hca_status                                          || '"'
      );
    END LOOP;

--
    --���[�N�e�[�u���폜
    DELETE FROM xxccp_data_patch_work xdpw
    WHERE  xdpw.file_id = ln_file_id;
--
    --�x�����P���ȏ㑶�݂����ꍇ�A�X�e�[�^�X���x���ɂ���
    IF ( gn_warn_cnt > 0 ) THEN
      ov_retcode := cv_status_warn;
    END IF;
--
  EXCEPTION
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := lv_errbuf;
      ov_retcode := cv_status_error;
      ROLLBACK;  --�X�V�����[���o�b�N
      --
      --�t�@�C��IF�f�[�^�폜
      DELETE FROM xxccp_mrp_file_ul_interface xmfui
      WHERE  xmfui.file_id = ln_file_id;
      --
      --���[�N�e�[�u���폜
      DELETE FROM xxccp_data_patch_work xdpw
      WHERE  xdpw.file_id = ln_file_id;
      --
      --�f�[�^�폜�̃R�~�b�g
      COMMIT;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := SQLERRM;
      ov_retcode := cv_status_error;
      ROLLBACK;  --�X�V�����[���o�b�N
      --�t�@�C��IF�f�[�^�폜
      DELETE FROM xxccp_mrp_file_ul_interface xmfui
      WHERE  xmfui.file_id = ln_file_id;
--
      --���[�N�e�[�u���폜
      DELETE FROM xxccp_data_patch_work xdpw
      WHERE  xdpw.file_id = ln_file_id;
--
      IF ( data_cur%ISOPEN ) THEN
          CLOSE data_cur;
      END IF;
--
      COMMIT;    --�f�[�^�폜�̃R�~�b�g
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
    iv_file_id    IN  VARCHAR2,      -- 1.�t�@�C��ID
    iv_fmt_ptn    IN  VARCHAR2       -- 2.�t�H�[�}�b�g�p�^�[��
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
    cv_prg_name        CONSTANT VARCHAR2(100) := 'main'; -- �v���O������
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
       iv_which   => 'LOG'
      ,ov_retcode => lv_retcode
      ,ov_errbuf  => lv_errbuf
      ,ov_errmsg  => lv_errmsg
    );
    --
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_api_others_expt;
    END IF;
    --
--
--###########################  �Œ蕔 END   #############################
--
    -- �O���[�o���ϐ��̏�����
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
    gn_warn_cnt   := 0;
--
    -- ===============================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ===============================================
    submain(
       iv_file_id  -- 1.�t�@�C��ID
      ,iv_fmt_ptn  -- 2.�t�H�[�}�b�g�p�^�[��
      ,lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    --�G���[�o��
    IF (lv_retcode = cv_status_error) THEN
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --�G���[���b�Z�[�W
      );
      --���������N���A
      gn_normal_cnt := 0;
      --�X�L�b�v�����N���A
      gn_warn_cnt   := 0;
      --�G���[����
      gn_error_cnt  := 1;
    END IF;
    --��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
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
END XXCCP009A04C;
/