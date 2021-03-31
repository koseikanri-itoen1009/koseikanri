CREATE OR REPLACE PACKAGE BODY XXCCP003A03C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * Package Name     : XXCCP003A03C(body)
 * Description      : �≮�������폜�A�b�v���[�h����
 * Version          : 1.0
 *
 * Program List
 * ------------------------- ------------------------------------------------------------
 *  Name                      Description
 * ------------------------- ------------------------------------------------------------
 *  submain                  ���C�������v���V�[�W��
 *  main                     �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2020/11/20    1.0   SCSK Y.Koh       [E_�{�ғ�_16026]�V�K�쐬
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
--
--################################  �Œ蕔 END   ##################################
--
  -- ===============================
  -- ���[�U�[��`��O
  -- ===============================
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name               CONSTANT VARCHAR2(100) := 'XXCCP003A03C';                 -- �v���O������
  cv_flag_y                 CONSTANT VARCHAR2(1)   := 'Y';                            -- Y
  --�v���t�@�C��
  cv_all_base_allowed       CONSTANT VARCHAR2(100) := 'XXCOK1_WHOLESALE_INVOICE_UPLOAD_ALL_BASE_ALLOWED';
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gv_user_dept_code         VARCHAR2(100) DEFAULT NULL;                               --���[�U�S�����_
  gv_all_base_allowed       VARCHAR2(1);                                              --�J�X�^����v���t�@�C���擾�ϐ�
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
  IS
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
    cv_lang                   CONSTANT VARCHAR2(2)  := USERENV('LANG');
    --CSV���ڐ�
    cn_csv_file_col_num       CONSTANT NUMBER       := 15;            -- CSV�t�@�C�����ڐ�
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
    ln_cnt           NUMBER  := 1;                                -- ���[�v�J�E���^
    ln_data_cnt      NUMBER;                                      -- �f�[�^�����p�J�E���^
    --�A�b�v���[�h�f�[�^�i�[�p�ϐ�
    TYPE gt_col_data_ttype    IS TABLE OF VARCHAR2(5000) INDEX BY BINARY_INTEGER;    -- 1�����z��i���ځj
    TYPE gt_rec_data_ttype    IS TABLE OF gt_col_data_ttype INDEX BY BINARY_INTEGER; -- 2�����z��i���R�[�h�j�i���ځj
    lt_delete_data_tab  gt_rec_data_ttype;
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
    -- =============================================================================
    -- �v���t�@�C�����擾(�S���_���t���O)
    -- =============================================================================
    gv_all_base_allowed := FND_PROFILE.VALUE( cv_all_base_allowed );
--
    IF ( gv_all_base_allowed IS NULL ) THEN
      lv_errbuf := '�v���t�@�C��(�S���_���t���O)���擾�ł��܂���ł����B';
      gn_error_cnt := gn_error_cnt + 1;
      RAISE global_process_expt;
    END IF;
    -- =============================================================================
    -- ���[�U�̏���������擾
    -- =============================================================================
    gv_user_dept_code := xxcok_common_pkg.get_department_code_f(
                           in_user_id => cn_last_updated_by
                         );
--
    IF ( gv_user_dept_code IS NULL ) THEN
      lv_errbuf := '���[�U�̏������傪�擾�ł��܂���ł����B';
      gn_error_cnt := gn_error_cnt + 1;
      RAISE global_process_expt;
    END IF;
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
--
    --�^�C�g���s�͏��O�A�f�[�^�s����擾����
    FOR ln_line_cnt IN 1 .. l_file_data_tab.COUNT LOOP
      --���ڐ��擾
      ln_col_num := NVL(LENGTH(l_file_data_tab(ln_line_cnt)), 0)
                      - NVL(LENGTH(REPLACE(l_file_data_tab(ln_line_cnt), ',', NULL)), 0) + 1;
      --���ڐ��`�F�b�N
      IF (ln_col_num <> cn_csv_file_col_num) THEN
        lv_errbuf := '['|| ln_line_cnt || '�s��] �A�b�v���[�h�t�@�C���̍��ڐ��ɉߕs��������܂��B';
        gn_error_cnt := gn_error_cnt + 1;
        RAISE global_process_expt;
      ELSE
        FOR ln_column_cnt IN 1 .. cn_csv_file_col_num LOOP
          --���ڕ���
          lt_delete_data_tab(ln_line_cnt)(ln_column_cnt)  := xxccp_common_pkg.char_delim_partition(
                                                                 iv_char     => l_file_data_tab(ln_line_cnt)
                                                                ,iv_delim    => ','
                                                                ,in_part_num => ln_column_cnt
                                                            );
          --�_�u���N�H�[�e�[�V�����폜
          lt_delete_data_tab(ln_line_cnt)(ln_column_cnt) := REPLACE(lt_delete_data_tab(ln_line_cnt)(ln_column_cnt),'"');
        END LOOP;
        --�폜�Ώی����J�E���g
        IF  ln_line_cnt > 1 AND lt_delete_data_tab(ln_line_cnt)(01) = '�폜'  THEN
          gn_target_cnt := gn_target_cnt + 1;
        END IF;
      END IF;
    END LOOP;
--
    --�폜�f�[�^�Ȃ�
    IF  gn_target_cnt = 0 THEN
      lv_errbuf := '�A�b�v���[�h�t�@�C���ɍ폜�f�[�^������܂���B';
      gn_error_cnt := gn_error_cnt + 1;
      RAISE global_process_expt;
    END IF;
--
    --���ڃ`�F�b�N
    FOR ln_line_cnt IN 2 .. lt_delete_data_tab.COUNT LOOP
--
      IF  lt_delete_data_tab(ln_line_cnt)(01) = '�폜'  THEN
        --���_�`�F�b�N
        IF  gv_all_base_allowed = 'N' AND lt_delete_data_tab(ln_line_cnt)(02) <>  gv_user_dept_code THEN
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => '['|| ln_line_cnt || '�s��] �w�肵�����_�̃f�[�^�͍폜�ł��܂���B'
          );
          gn_warn_cnt := gn_warn_cnt + 1;
          CONTINUE;
        END IF;
--
        --�폜�f�[�^���݃`�F�b�N
        SELECT  COUNT(*)
        INTO    ln_data_cnt
        FROM    xxcok_wholesale_bill_line xwbl
        WHERE   xwbl.wholesale_bill_header_id IN
                ( SELECT  xwbh.wholesale_bill_header_id
                  FROM    xxcok_wholesale_bill_head xwbh
                  WHERE   base_code           =   lt_delete_data_tab(ln_line_cnt)(02)
                  AND     cust_code           =   lt_delete_data_tab(ln_line_cnt)(08)
                  AND     supplier_code       =   lt_delete_data_tab(ln_line_cnt)(04)
                  AND     expect_payment_date =   TO_DATE(lt_delete_data_tab(ln_line_cnt)(06),'YYYY/MM/DD') )
        AND     xwbl.bill_no                  =   lt_delete_data_tab(ln_line_cnt)(10)
        AND     xwbl.status                   IS  NULL
        AND     xwbl.recon_slip_num           IS  NULL;
--
        IF  ln_data_cnt = 0 THEN
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => '['|| ln_line_cnt || '�s��] �w�肵���������͑��݂��Ȃ����x�������ςł��B'
          );
          gn_warn_cnt := gn_warn_cnt + 1;
        END IF;
      END IF;
--
    END LOOP;
--
    --==============================================================
    -- �������f�[�^�폜
    --==============================================================
    IF  gn_warn_cnt > 0 THEN
      --�x�����P���ȏ㑶�݂����ꍇ�A�X�e�[�^�X���x���ɂ���
      ov_retcode := cv_status_warn;
    ELSE
      --�x�����Ȃ��ꍇ�A�������f�[�^���폜����
      FOR ln_line_cnt IN 1 .. lt_delete_data_tab.COUNT LOOP
        IF  lt_delete_data_tab(ln_line_cnt)(01) = '�폜'  THEN
          UPDATE  xxcok_wholesale_bill_line xwbl
          SET     xwbl.status             = 'D'                       ,
                  last_updated_by         = cn_last_updated_by        ,
                  last_update_date        = cd_last_update_date       ,
                  last_update_login       = cn_last_update_login      ,
                  request_id              = cn_request_id             ,
                  program_application_id  = cn_program_application_id ,
                  program_id              = cn_program_id             ,
                  program_update_date     = cd_program_update_date
          WHERE   xwbl.wholesale_bill_header_id IN
                  ( SELECT  xwbh.wholesale_bill_header_id
                    FROM    xxcok_wholesale_bill_head xwbh
                    WHERE   base_code           =   lt_delete_data_tab(ln_line_cnt)(02)
                    AND     cust_code           =   lt_delete_data_tab(ln_line_cnt)(08)
                    AND     supplier_code       =   lt_delete_data_tab(ln_line_cnt)(04)
                    AND     expect_payment_date =   TO_DATE(lt_delete_data_tab(ln_line_cnt)(06),'YYYY/MM/DD') )
          AND     xwbl.bill_no                  =   lt_delete_data_tab(ln_line_cnt)(10)
          AND     xwbl.status                   IS  NULL
          AND     xwbl.recon_slip_num           IS  NULL;
          gn_normal_cnt := gn_normal_cnt + 1;
        END IF;
      END LOOP;
    END IF;
--
    --==============================================================
    -- �t�@�C��IF�f�[�^�폜
    --==============================================================
    DELETE FROM xxccp_mrp_file_ul_interface xmfui
    WHERE  xmfui.file_id = ln_file_id;
--
    lt_delete_data_tab.DELETE;
--
  EXCEPTION
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errbuf  := lv_errbuf;
      ov_retcode := cv_status_error;
      ROLLBACK;  --�X�V�����[���o�b�N
      --�t�@�C��IF�f�[�^�폜
      DELETE FROM xxccp_mrp_file_ul_interface xmfui
      WHERE  xmfui.file_id = ln_file_id;
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
      --�f�[�^�폜�̃R�~�b�g
      COMMIT;
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
  IS
--###########################  �Œ蕔 START   ###########################
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
      RAISE global_process_expt;
    END IF;
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

    IF (lv_retcode = cv_status_error) THEN
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --�G���[���b�Z�[�W
      );
    END IF;
--
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
    WHEN global_process_expt THEN
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
END XXCCP003A03C;
/
