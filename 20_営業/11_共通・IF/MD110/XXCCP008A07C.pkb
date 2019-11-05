create or replace
PACKAGE BODY XXCCP008A07C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * Package Name     : XXCCP008A07C(body)
 * Description      : ���Y�ڊǏC���A�b�v���[�h����
 * Version          : 1.0
 *
 * Program List
 * ------------------------- ------------------------------------------------------------
 * Name                      Description
 * ------------------------- ------------------------------------------------------------
 * chk_period                ��v���ԃ`�F�b�N
 * submain                   ���C�������v���V�[�W��
 * main                      �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 * Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 * 2019/10/17    1.0   Y.Ohishi         E_�{�ғ�_15982  �V�K�쐬
 *
 *****************************************************************************************/
--
--#######################  �Œ�O���[�o���萔�錾�� START   #######################
--
  --�X�e�[�^�X�E�R�[�h
  cv_status_normal            CONSTANT  VARCHAR2(1) := xxccp_common_pkg.set_status_normal;     --����:0
  cv_status_warn              CONSTANT  VARCHAR2(1) := xxccp_common_pkg.set_status_warn;       --�x��:1
  cv_status_error             CONSTANT  VARCHAR2(1) := xxccp_common_pkg.set_status_error;      --�ُ�:2
  --WHO�J����
  cn_created_by               CONSTANT  NUMBER      := fnd_global.user_id;                --CREATED_BY
  cd_creation_date            CONSTANT  DATE        := SYSDATE;                           --CREATION_DATE
  cn_last_updated_by          CONSTANT  NUMBER      := fnd_global.user_id;                --LAST_UPDATED_BY
  cd_last_update_date         CONSTANT  DATE        := SYSDATE;                           --LAST_UPDATE_DATE
  cn_last_update_login        CONSTANT  NUMBER      := fnd_global.login_id;               --LAST_UPDATE_LOGIN
  cn_request_id               CONSTANT  NUMBER      := fnd_global.conc_request_id;        --REQUEST_ID
  cn_program_application_id   CONSTANT  NUMBER      := fnd_global.prog_appl_id;           --PROGRAM_APPLICATION_ID
  cn_program_id               CONSTANT  NUMBER      := fnd_global.conc_program_id;        --PROGRAM_ID
  cd_program_update_date      CONSTANT  DATE        := SYSDATE;                           --PROGRAM_UPDATE_DATE
  cv_msg_part                 CONSTANT  VARCHAR2(3) := ' : ';
  cv_msg_cont                 CONSTANT  VARCHAR2(3) := '.';
--
--################################  �Œ蕔 END   ##################################
--
--#######################  �Œ�O���[�o���ϐ��錾�� START   #######################
--
  gv_out_msg                            VARCHAR2(2000);
  gn_target_cnt                         NUMBER;                                 -- �Ώی���
  gn_normal_cnt                         NUMBER;                                 -- ���팏��
  gn_error_cnt                          NUMBER;                                 -- �G���[����
  gn_warn_cnt                           NUMBER;                                 -- �X�L�b�v����
--
--################################  �Œ蕔 END   ##################################
--
--##########################  �Œ苤�ʗ�O�錾�� START  ###########################
--
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
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name                 CONSTANT  VARCHAR2(100) := 'XXCCP008A07C';        -- �v���O������
  cv_flag_y                   CONSTANT  VARCHAR2(1)   := 'Y';                   -- Y
  cv_flag_n                   CONSTANT  VARCHAR2(1)   := 'N';                   -- N
  -- ���t����
  cv_date_format_1            CONSTANT  VARCHAR2(8)   := 'YYYYMMDD';            -- ����
  cv_date_format_2            CONSTANT  VARCHAR2(7)   := 'YYYY-MM';             -- ��v����
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gd_process_date             DATE;                                             -- �Ɩ����t
  gt_chart_of_account_id      gl_sets_of_books.chart_of_accounts_id%TYPE;       -- �Ȗڑ̌nID
  gt_application_short_name   fnd_application.application_short_name%TYPE;      -- GL�A�v���P�[�V�����Z�k��
  gt_id_flex_code             fnd_id_flex_structures_vl.id_flex_code%TYPE;      -- �L�[�t���b�N�X�R�[�h
  -- �����l���
  g_init_rec                  xxcff_common1_pkg.init_rtype;
  -- �A�v���P�[�V�����Z�k��
  cv_msg_kbn_cff              CONSTANT  VARCHAR2(5)   := 'XXCFF';               -- �A�h�I���F���ʁEIF�̈�
  -- ���b�Z�[�W��
  cv_msg_name_00258           CONSTANT  VARCHAR2(20)  := 'APP-XXCFF1-00258';    -- ���ʊ֐��G���[
  cv_msg_name_50130           CONSTANT  VARCHAR2(20)  := 'APP-XXCFF1-50130';    -- ��������
  -- �g�[�N����
  cv_tkn_func_name            CONSTANT  VARCHAR2(100) := 'FUNC_NAME';           -- ���ʊ֐���
  cv_tkn_info                 CONSTANT  VARCHAR2(100) := 'INFO';                -- �ڍ׏��
  cv_tkn_line_no              CONSTANT  VARCHAR2(100) := 'LINE_NO';             -- �s�ԍ�
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���E�J�[�\��
  -- ===============================
  --�A�b�v���[�h�f�[�^�J�[�\��
  CURSOR data_cur( in_file_id NUMBER )
  IS
    SELECT    xdpw.file_id              file_id                                 -- �t�@�C��ID
             ,xdpw.data_sequence        data_sequence                           -- �f�[�^�V�[�P���X
             ,xdpw.condition_1          condition_1                             -- ����1(���Y�ԍ�)
             ,xdpw.condition_2          condition_2                             -- ����2(�䒠)
             ,xdpw.chr_column_1         chr_column_1                            -- �����l1(�U�֓�)
             ,xdpw.chr_column_2         chr_column_2                            -- �����l2(����R�[�h)
             ,xdpw.chr_column_3         chr_column_3                            -- �����l3(����Ȗ�)
             ,xdpw.chr_column_4         chr_column_4                            -- �����l4(�⏕�Ȗ�)
             ,xdpw.chr_column_5         chr_column_5                            -- �����l5(�\���n)
             ,xdpw.chr_column_6         chr_column_6                            -- �����l6(����)
             ,xdpw.chr_column_7         chr_column_7                            -- �����l7(���Ə�)
             ,xdpw.chr_column_8         chr_column_8                            -- �����l8(�ꏊ)
             ,xdpw.chr_column_9         chr_column_9                            -- �����l9(�{�ЍH��敪)
    FROM     xxccp_data_patch_work      xdpw
    WHERE    xdpw.file_id = in_file_id
    ORDER BY xdpw.data_sequence;
--
  data_rec data_cur%ROWTYPE;
--
  -- �Z�O�����g�l�z��(EBS�W���֐�fnd_flex_ext�p)
  g_segments_tab               fnd_flex_ext.segmentarray;
--
  /**********************************************************************************
   * Procedure Name   : chk_period
   * Description      : ��v���ԃ`�F�b�N
   ***********************************************************************************/
  PROCEDURE chk_period(
    iv_trans_date  IN  VARCHAR2,        -- �U�֓�
    in_record_cnt  IN  NUMBER,          -- ���R�[�h�ԍ�
    ov_errbuf      OUT VARCHAR2,        -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode     OUT VARCHAR2,        -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg      OUT VARCHAR2)        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name               CONSTANT  VARCHAR2(100) := 'chk_period';          -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf                           VARCHAR2(5000);                         -- �G���[�E���b�Z�[�W
    lv_retcode                          VARCHAR2(1);                            -- ���^�[���E�R�[�h
    lv_errmsg                           VARCHAR2(5000);                         -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_yes                    CONSTANT  VARCHAR2(1) := 'Y';
--
    -- *** ���[�J���ϐ� ***
    lv_deprn_run              fa_deprn_periods.deprn_run%TYPE := NULL;          -- �������p���s�t���O
    lv_period_name            fa_deprn_periods.period_name%TYPE;                -- ��v���Ԗ�
--
    -- *** ���[�J���E�J�[�\�� ***
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
    -- �U�֓��̃`�F�b�N����ь`���ϊ�
    BEGIN
      SELECT TO_CHAR( TO_DATE( iv_trans_date , cv_date_format_1 ) , cv_date_format_2 )   period_name
      INTO   lv_period_name
      FROM   DUAL
      ;
    EXCEPTION
      -- �ϊ��ŃG���[�����������ꍇ
      WHEN OTHERS THEN
        -- ���b�Z�[�W�ҏW
        lv_errmsg := '�s�ԍ��F' || in_record_cnt || ' ���Y�ԍ��F' || data_rec.condition_1 || ' �U�֓������݂��Ȃ����t�ł��B';
        RAISE chk_period_expt;
    END;
--
    -- ��v���ԃ`�F�b�N
    BEGIN
      SELECT  fdp.deprn_run         AS deprn_run                      -- �������p���s�t���O
      INTO    lv_deprn_run
      FROM    fa_deprn_periods         fdp                            -- �������p����
      WHERE   fdp.book_type_code    =  data_rec.condition_2
      AND     fdp.period_name       =  lv_period_name
      AND     fdp.period_close_date IS NULL
      ;
    EXCEPTION
      -- ��v���Ԃ̎擾�������[�����̏ꍇ
      WHEN NO_DATA_FOUND THEN
        -- ���b�Z�[�W�ҏW
        lv_errmsg := '�s�ԍ��F' || in_record_cnt || ' ���Y�ԍ��F' || data_rec.condition_1 || ' ��v���Ԃ����݂��Ȃ����N���[�Y�ςł��B';
        RAISE chk_period_expt;
    END;
--
    -- �������p�����s����Ă���ꍇ
    IF lv_deprn_run = cv_yes THEN
        -- ���b�Z�[�W�ҏW
        lv_errmsg := '�s�ԍ��F' || in_record_cnt || ' ���Y�ԍ��F' || data_rec.condition_1 || ' ��v���Ԃ��I�[�v����Ԃł͂���܂���B';
      RAISE chk_period_expt;
    END IF;
--
  EXCEPTION
    -- *** ��v���ԃ`�F�b�N�G���[�n���h�� ***
    WHEN chk_period_expt THEN
      -- �G���[���b�Z�[�W���Z�b�g
      lv_errbuf := lv_errmsg;
      ov_errmsg := lv_errmsg;
      ov_errbuf := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      -- �I���X�e�[�^�X�͌x���Ƃ���
      ov_retcode := cv_status_warn;
--
--#################################  �Œ��O������ START   ####################################
--
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
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    iv_file_id      IN  VARCHAR2,       -- �t�@�C��ID
    iv_fmt_ptn      IN  VARCHAR2,       -- �t�H�[�}�b�g�p�^�[��
    ov_errbuf       OUT VARCHAR2,       -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode      OUT VARCHAR2,       -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg       OUT VARCHAR2        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
--
  IS
--
--#####################  �Œ胍�[�J���萔�ϐ��錾�� START   ####################
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name               CONSTANT  VARCHAR2(100) := 'submain';   -- �v���O������
    cn_segment_cnt            CONSTANT  NUMBER        := 8;           -- �Z�O�����g��
    cn_one                    CONSTANT  NUMBER        := 1;           
    cv_flg_yes                CONSTANT  VARCHAR2(1)   := 'Y';         -- �t���OYes
    cv_pending                CONSTANT  VARCHAR2(7)   := 'PENDING';   -- �X�e�[�^�X(PENDING)
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf                           VARCHAR2(5000);               -- �G���[�E���b�Z�[�W
    lv_retcode                          VARCHAR2(1);                  -- ���^�[���E�R�[�h
    lv_errmsg                           VARCHAR2(5000);               -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    --�Q�ƃ^�C�v�p�ϐ�
    --CSV���ڐ�
    cn_csv_file_col_num       CONSTANT  NUMBER       := 11;                     -- CSV�t�@�C�����ڐ�
    cn_trans_date_length      CONSTANT  NUMBER       := 8;                      -- �U�֓�����
    -- �Z�O�����g�l
    cv_segment1               CONSTANT VARCHAR2(30)  := '001';                  -- ��ЃR�[�h
    cv_segment5               CONSTANT VARCHAR2(30)  := '000000000';            -- �ڋq�R�[�h
    cv_segment6               CONSTANT VARCHAR2(30)  := '000000';               -- ��ƃR�[�h
    cv_segment7               CONSTANT VARCHAR2(30)  := '0';                    -- �\���P
    cv_segment8               CONSTANT VARCHAR2(30)  := '0';                    -- �\���Q
--
    -- *** ���[�J���ϐ� ***
    --�Ɩ����t
    lt_exp_code_comb_id       gl_code_combinations.code_combination_id%TYPE;    -- �������p���CCID
    lt_location_id            gl_code_combinations.code_combination_id%TYPE;    -- ���Ə�CCID
    --�A�b�v���[�h�p�ϐ�
    lv_file_name              xxccp_mrp_file_ul_interface.file_name%TYPE;       -- CSV�t�@�C����
    l_file_data_tab           xxccp_common_pkg2.g_file_data_tbl;                -- �s�P�ʃf�[�^�i�[�p�z��
    ln_col_num                NUMBER;                                           -- ���ڐ��擾�p
    ln_line_cnt               NUMBER;                                           -- CSV�t�@�C���e�s�Q�Ɨp�J�E���^
    ln_line_cnt_2             NUMBER  := 0;                                     -- CSV�t�@�C���e�s�Q�Ɨp�J�E���^
    ln_column_cnt             NUMBER;                                           -- CSV�t�@�C���e��Q�Ɨp�J�E���^
    ln_file_id                NUMBER  := TO_NUMBER(iv_file_id);                 -- �t�@�C��ID
    ln_record_cnt             NUMBER  := 0;                                     -- ���������p�J�E���^
    ln_skip_cnt               NUMBER  := 0;                                     -- ���ډߕs�������p�J�E���^
    ln_current_units          fa_additions_b.current_units%TYPE;                -- �P�ʕύX
    lv_err_flg                VARCHAR2(1)  DEFAULT 'N';                         -- �G���[�t���O
    --�f�[�^�`�F�b�N�p�ϐ�
    lv_condition_1            xxccp_data_patch_work.condition_1%TYPE;
    lb_ret                    BOOLEAN;                                          -- �֐����^�[���R�[�h
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    TYPE gt_col_data_ttype    IS TABLE OF VARCHAR2(5000)    INDEX BY BINARY_INTEGER;      -- 1�����z��i���ځj
    TYPE gt_rec_data_ttype    IS TABLE OF gt_col_data_ttype INDEX BY BINARY_INTEGER;      -- 2�����z��i���R�[�h�j�i���ځj
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
    -- �t�@�C�����o��
    --==============================================================
    SELECT  xmfui.file_name             file_name
    INTO    lv_file_name
    FROM    xxccp_mrp_file_ul_interface xmfui
    WHERE   xmfui.file_id = ln_file_id
    FOR UPDATE NOWAIT
    ;
--
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => '�t�@�C������                  �F'||lv_file_name
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
--
    -- 0���G���[(�w�b�_�݂̂ł��G���[�Ƃ���)
    IF (l_file_data_tab.COUNT <= 1 ) THEN
      -- ���b�Z�[�W�ҏW
      lv_errmsg := '�A�b�v���[�h�t�@�C���Ƀf�[�^������܂���B';
      -- ���b�Z�[�W�o��
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errmsg
      );
      RAISE global_api_others_expt;
    END IF;
--
    --�^�C�g���s�͏��O�A�f�[�^�s����擾����
    <<line_loop>>
    FOR ln_line_cnt IN 2 .. l_file_data_tab.COUNT LOOP
      --���ڐ��擾
      ln_col_num := NVL(LENGTH(l_file_data_tab(ln_line_cnt)), 0)
                      - NVL(LENGTH(REPLACE(l_file_data_tab(ln_line_cnt), ',', NULL)), 0) + 1;
      --���ڐ��`�F�b�N
      IF (ln_col_num <> cn_csv_file_col_num) THEN
        -- �ߕs���������Z
        ln_skip_cnt := ln_skip_cnt + 1;
         -- ���b�Z�[�W�ҏW
         lv_errmsg := '['|| (ln_line_cnt - 1) || '�s��] �A�b�v���[�h�t�@�C���̍��ڐ��ɉߕs��������܂��B';
         -- ���b�Z�[�W�o��
         FND_FILE.PUT_LINE(
            which  => FND_FILE.LOG
           ,buff   => lv_errmsg
         );
      ELSE
        -- �s�ԍ���ݒ�
        ln_line_cnt_2 := ln_line_cnt_2 + 1;
        lt_path_data_tab(ln_line_cnt_2)(0) := ln_line_cnt - 1;
--
        <<column_loop>>
        FOR ln_column_cnt IN 1 .. cn_csv_file_col_num LOOP
          --���ڕ���
          lt_path_data_tab(ln_line_cnt_2)(ln_column_cnt) := xxccp_common_pkg.char_delim_partition(
                                                               iv_char     => l_file_data_tab(ln_line_cnt)
                                                              ,iv_delim    => ','
                                                              ,in_part_num => ln_column_cnt
                                                          );
          --�_�u���N�H�[�e�[�V�����폜
          lt_path_data_tab(ln_line_cnt_2)(ln_column_cnt) := SUBSTR(
                                                            lt_path_data_tab(ln_line_cnt_2)(ln_column_cnt) 
                                                           ,2
                                                           ,LENGTH(lt_path_data_tab(ln_line_cnt_2)(ln_column_cnt)) - 2
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
--
      --�p�b�`�p�e�[�u���o�^
      INSERT INTO xxccp_data_patch_work (
         file_id
        ,data_sequence
        ,condition_1
        ,condition_2
        ,chr_column_1
        ,chr_column_2
        ,chr_column_3
        ,chr_column_4
        ,chr_column_5
        ,chr_column_6
        ,chr_column_7
        ,chr_column_8
        ,chr_column_9
      ) VALUES (
         ln_file_id                                         -- �t�@�C��ID
        ,lt_path_data_tab(ln_line_cnt)( 0)                  -- �f�[�^�V�[�P���X
        ,lt_path_data_tab(ln_line_cnt)( 1)                  -- �����l1�i���Y�ԍ��j
        ,lt_path_data_tab(ln_line_cnt)( 2)                  -- �����l2�i�䒠�j
        ,lt_path_data_tab(ln_line_cnt)( 3)                  -- �����l1�i�U�֓��j
        ,lt_path_data_tab(ln_line_cnt)( 4)                  -- �����l2�i�������p���D����j
        ,lt_path_data_tab(ln_line_cnt)( 5)                  -- �����l3�i�������p���D����Ȗځj
        ,lt_path_data_tab(ln_line_cnt)( 6)                  -- �����l4�i�������p���D�⏕�Ȗځj
        ,lt_path_data_tab(ln_line_cnt)( 7)                  -- �����l5�i���Ə��D�\���n�j
        ,lt_path_data_tab(ln_line_cnt)( 8)                  -- �����l6�i���Ə��D�Ǘ�����j
        ,lt_path_data_tab(ln_line_cnt)( 9)                  -- �����l7�i���Ə��D���Ə��j
        ,lt_path_data_tab(ln_line_cnt)(10)                  -- �����l8�i���Ə��D�ꏊ�j
        ,lt_path_data_tab(ln_line_cnt)(11)                  -- �����l9�i���Ə��D�{��/�H��敪�j
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
    DELETE
    FROM   xxccp_mrp_file_ul_interface xmfui
    WHERE  xmfui.file_id = ln_file_id
    ;
--
    lt_path_data_tab.DELETE;
--
    --==============================================================
    -- �f�[�^�`�F�b�N����
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
      -- �G���[�t���O������
      lv_err_flg    := cv_flag_n;
      -- �s�ԍ����擾
      ln_record_cnt := data_rec.data_sequence;
--
      -- ���Y�ԍ��`�F�b�N
      IF ( data_rec.condition_1 IS NULL ) THEN
        -- �G���[�t���O��Y�ɐݒ�
        lv_err_flg := cv_flag_y;
        -- ���b�Z�[�W�ҏW
        lv_errmsg := '�s�ԍ��F' || ln_record_cnt || ' ���Y�ԍ������ݒ�ł��B';
        -- ���b�Z�[�W�o��
        FND_FILE.PUT_LINE(
           which  => FND_FILE.LOG
          ,buff   => lv_errmsg
        );
      END IF;
--
      -- �䒠�`�F�b�N
      IF ( data_rec.condition_2 IS NULL ) THEN
        -- �G���[�t���O��Y�ɐݒ�
        lv_err_flg := cv_flag_y;
        -- ���b�Z�[�W�ҏW
        lv_errmsg := '�s�ԍ��F' || ln_record_cnt || ' ���Y�ԍ��F' || data_rec.condition_1 || ' �䒠�����ݒ�ł��B';
        -- ���b�Z�[�W�o��
        FND_FILE.PUT_LINE(
           which  => FND_FILE.LOG
          ,buff   => lv_errmsg
        );
      END IF;
--
      -- �U�֓��`�F�b�N
      IF ( data_rec.chr_column_1 IS NULL ) THEN
        -- �G���[�t���O��Y�ɐݒ�
        lv_err_flg := cv_flag_y;
        -- ���b�Z�[�W�ҏW
        lv_errmsg := '�s�ԍ��F' || ln_record_cnt || ' ���Y�ԍ��F' || data_rec.chr_column_1 || ' �U�֓������ݒ�ł��B';
        -- ���b�Z�[�W�o�͏���
        FND_FILE.PUT_LINE(
           which  => FND_FILE.LOG
          ,buff   => lv_errmsg
        );
      -- �U�֓������`�F�b�N
      ELSIF ( LENGTH( data_rec.chr_column_1 ) <> cn_trans_date_length ) THEN
        -- �G���[�t���O��Y�ɐݒ�
        lv_err_flg := cv_flag_y;
        -- ���b�Z�[�W�ҏW
        lv_errmsg := '�s�ԍ��F' || ln_record_cnt || ' ���Y�ԍ��F' || data_rec.chr_column_1 || ' �U�֓����W���ł͂���܂���B';
        -- ���b�Z�[�W�o�͏���
        FND_FILE.PUT_LINE(
           which  => FND_FILE.LOG
          ,buff   => lv_errmsg
        );
      END IF;
--
      -- �������p���D����`�F�b�N
      IF ( data_rec.chr_column_2 IS NULL ) THEN
        -- �G���[�t���O��Y�ɐݒ�
        lv_err_flg := cv_flag_y;
        -- ���b�Z�[�W�ҏW
        lv_errmsg := '�s�ԍ��F' || ln_record_cnt || ' ���Y�ԍ��F' || data_rec.condition_1 || ' �������p���D���傪���ݒ�ł��B';
        -- ���b�Z�[�W�o��
        FND_FILE.PUT_LINE(
           which  => FND_FILE.LOG
          ,buff   => lv_errmsg
        );
      END IF;
--
      -- �������p���D����Ȗڃ`�F�b�N
      IF ( data_rec.chr_column_3 IS NULL ) THEN
        -- �G���[�t���O��Y�ɐݒ�
        lv_err_flg := cv_flag_y;
        -- ���b�Z�[�W�ҏW
        lv_errmsg := '�s�ԍ��F' || ln_record_cnt || ' ���Y�ԍ��F' || data_rec.condition_1 || ' �������p���D����Ȗڂ����ݒ�ł��B';
        -- ���b�Z�[�W�o��
        FND_FILE.PUT_LINE(
           which  => FND_FILE.LOG
          ,buff   => lv_errmsg
        );
      END IF;
--
      -- �������p���D�⏕�Ȗڃ`�F�b�N
      IF ( data_rec.chr_column_4 IS NULL ) THEN
        -- �G���[�t���O��Y�ɐݒ�
        lv_err_flg := cv_flag_y;
        -- ���b�Z�[�W�ҏW
        lv_errmsg := '�s�ԍ��F' || ln_record_cnt || ' ���Y�ԍ��F' || data_rec.condition_1 || ' �������p���D�⏕�Ȗڂ����ݒ�ł��B';
        -- ���b�Z�[�W�o��
        FND_FILE.PUT_LINE(
           which  => FND_FILE.LOG
          ,buff   => lv_errmsg
        );
      END IF;
--
      -- ���Ə��D�\���n�`�F�b�N
      IF ( data_rec.chr_column_5 IS NULL ) THEN
        -- �G���[�t���O��Y�ɐݒ�
        lv_err_flg := cv_flag_y;
        -- ���b�Z�[�W�ҏW
        lv_errmsg := '�s�ԍ��F' || ln_record_cnt || ' ���Y�ԍ��F' || data_rec.condition_1 || ' ���Ə��D�\���n�����ݒ�ł��B';
        -- ���b�Z�[�W�o��
        FND_FILE.PUT_LINE(
           which  => FND_FILE.LOG
          ,buff   => lv_errmsg
        );
      END IF;
--
      -- ���Ə��D�Ǘ�����`�F�b�N
      IF ( data_rec.chr_column_6 IS NULL ) THEN
        -- �G���[�t���O��Y�ɐݒ�
        lv_err_flg := cv_flag_y;
        -- ���b�Z�[�W�ҏW
        lv_errmsg := '�s�ԍ��F' || ln_record_cnt || ' ���Y�ԍ��F' || data_rec.condition_1 || ' ���Ə��D�Ǘ����傪���ݒ�ł��B';
        -- ���b�Z�[�W�o��
        FND_FILE.PUT_LINE(
           which  => FND_FILE.LOG
          ,buff   => lv_errmsg
        );
      END IF;
--
      -- ���Ə��D���Ə��`�F�b�N
      IF ( data_rec.chr_column_7 IS NULL ) THEN
        -- �G���[�t���O��Y�ɐݒ�
        lv_err_flg := cv_flag_y;
        -- ���b�Z�[�W�ҏW
        lv_errmsg := '�s�ԍ��F' || ln_record_cnt || ' ���Y�ԍ��F' || data_rec.condition_1 || ' ���Ə��D���Ə������ݒ�ł��B';
        -- ���b�Z�[�W�o��
        FND_FILE.PUT_LINE(
           which  => FND_FILE.LOG
          ,buff   => lv_errmsg
        );
      END IF;
--
      -- ���Ə��D�ꏊ�`�F�b�N
      IF ( data_rec.chr_column_8 IS NULL ) THEN
        -- �G���[�t���O��Y�ɐݒ�
        lv_err_flg := cv_flag_y;
        -- ���b�Z�[�W�ҏW
        lv_errmsg := '�s�ԍ��F' || ln_record_cnt || ' ���Y�ԍ��F' || data_rec.condition_1 || ' ���Ə��D�ꏊ�����ݒ�ł��B';
        -- ���b�Z�[�W�o��
        FND_FILE.PUT_LINE(
           which  => FND_FILE.LOG
          ,buff   => lv_errmsg
        );
      END IF;
--
      -- ���Ə��D�{��/�H��敪�`�F�b�N
      IF ( data_rec.chr_column_9 IS NULL ) THEN
        -- �G���[�t���O��Y�ɐݒ�
        lv_err_flg := cv_flag_y;
        -- ���b�Z�[�W�ҏW
        lv_errmsg := '�s�ԍ��F' || ln_record_cnt || ' ���Y�ԍ��F' || data_rec.condition_1 || ' ���Ə��D�{��/�H��敪�����ݒ�ł��B';
        -- ���b�Z�[�W�o��
        FND_FILE.PUT_LINE(
           which  => FND_FILE.LOG
          ,buff   => lv_errmsg
        );
      END IF;
--
      -- ���Y�ԍ���Ӄ`�F�b�N
      BEGIN
        IF ( data_rec.condition_1 IS NOT NULL ) AND
           ( data_rec.condition_2 IS NOT NULL ) THEN
          SELECT xdpw.condition_1         condition_1
          INTO   lv_condition_1
          FROM   xxccp_data_patch_work    xdpw
          WHERE  xdpw.file_id     = ln_file_id
          AND    xdpw.condition_1 = data_rec.condition_1
          AND    xdpw.condition_2 = data_rec.condition_2
          ;
        END IF;
      EXCEPTION
      --��Ӑ���G���[
        WHEN TOO_MANY_ROWS THEN
          -- �G���[�t���O��Y�ɐݒ�
          lv_err_flg := cv_flag_y;
          -- ���b�Z�[�W�ҏW
          lv_errmsg := '�s�ԍ��F' || ln_record_cnt || ' ���Y�ԍ��F' || data_rec.condition_1 || ' ���t�@�C�����ň�ӂł͂���܂���B';
          -- ���b�Z�[�W�o��
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => lv_errmsg
          );
      END;
--
      -- ���Y�ԍ��Ƒ䒠�̑g�ݍ��킹�`�F�b�N
      BEGIN
        IF ( data_rec.condition_1 IS NOT NULL ) AND
           ( data_rec.condition_2 IS NOT NULL ) THEN
          SELECT fab.current_units      current_units
          INTO   ln_current_units
          FROM   fa_additions_b         fab                   -- ���Y�ڍ׏��
                ,fa_books               fb                    -- ���Y�䒠���
          WHERE  fab.asset_number    =  data_rec.condition_1  -- ���Y�ԍ�
          AND    fab.asset_id        =  fb.asset_id
          AND    fb.book_type_code   =  data_rec.condition_2  -- �䒠��
          AND    fb.date_ineffective IS NULL                  -- �����ł͂Ȃ�
          ;
        END IF;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          -- �G���[�t���O��Y�ɐݒ�
          lv_err_flg := cv_flag_y;
          -- ���b�Z�[�W�ҏW
          lv_errmsg := '�s�ԍ��F' || ln_record_cnt || ' ���Y�ԍ��F' || data_rec.condition_1 || ' ���䒠�F' || data_rec.condition_2 || ' �ɑ��݂��܂���B';
          -- ���b�Z�[�W�o��
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => lv_errmsg
          );
      END;
--
      -- ��v���ԃ`�F�b�N
      chk_period(
         data_rec.chr_column_1          -- �U�֓�
        ,ln_record_cnt                  -- ���R�[�h�s��
        ,lv_errbuf                      -- �G���[�E���b�Z�[�W           --# �Œ� #
        ,lv_retcode                     -- ���^�[���E�R�[�h             --# �Œ� #
        ,lv_errmsg                      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
--
      IF (lv_retcode = cv_status_warn) THEN
        -- �G���[�t���O��Y�ɐݒ�
        lv_err_flg := cv_flag_y;
        -- �x�����b�Z�[�W�o��
        FND_FILE.PUT_LINE(
           which  => FND_FILE.LOG
          ,buff   => lv_errmsg
        );
      END IF;
--
      -- ===============================
      -- �������p���CCID�擾
      -- ===============================
      -- �Z�O�����g�l�z�񏉊���
      g_segments_tab.DELETE;
      -- �Z�O�����g�l�z��ݒ�(SEG1:���)
      g_segments_tab(1) := cv_segment1;
      -- �Z�O�����g�l�z��ݒ�(SEG2:����R�[�h)
      g_segments_tab(2) := data_rec.chr_column_2;
      -- �Z�O�����g�l�z��ݒ�(SEG3:���p�Ȗ�)
      g_segments_tab(3) := data_rec.chr_column_3;
      -- �Z�O�����g�l�z��ݒ�(SEG4:�⏕�Ȗ�)
      g_segments_tab(4) := data_rec.chr_column_4;
      -- �Z�O�����g�l�z��ݒ�(SEG5:�ڋq�R�[�h)
      g_segments_tab(5) := cv_segment5;
      -- �Z�O�����g�l�z��ݒ�(SEG6:��ƃR�[�h)
      g_segments_tab(6) := cv_segment6;
      -- �Z�O�����g�l�z��ݒ�(SEG7:�\���P)
      g_segments_tab(7) := cv_segment7;
      -- �Z�O�����g�l�z��ݒ�(SEG8:�\���Q)
      g_segments_tab(8) := cv_segment8;
--
      -- CCID�擾�֐��Ăяo��
      lb_ret := fnd_flex_ext.get_combination_id(
                   application_short_name  => gt_application_short_name         -- �A�v���P�[�V�����Z�k��(GL)
                  ,key_flex_code           => gt_id_flex_code                   -- �L�[�t���b�N�X�R�[�h
                  ,structure_number        => gt_chart_of_account_id            -- ����Ȗڑ̌n�ԍ�
                  ,validation_date         => gd_process_date                   -- ���t�`�F�b�N
                  ,n_segments              => cn_segment_cnt                    -- �Z�O�����g��
                  ,segments                => g_segments_tab                    -- �Z�O�����g�l�z��
                  ,combination_id          => lt_exp_code_comb_id               -- �������p���CCID
                );
--
      -- ���ʊ֐��G���[
      IF NOT lb_ret THEN
        -- �G���[�t���O��Y�ɐݒ�
        lv_err_flg := cv_flag_y;
        -- ���b�Z�[�W�ҏW
        lv_errmsg := '�s�ԍ��F' || ln_record_cnt || ' ���Y�ԍ��F' || data_rec.condition_1 || ' �������p��肪����������܂���B';
        -- ���b�Z�[�W�o��
        FND_FILE.PUT_LINE(
          which  => FND_FILE.LOG
         ,buff   => lv_errmsg
        );
      END IF;
--
      -- ===============================
      -- ���Ə�CCID�擾
      -- ===============================
      -- ���Ə��}�X�^�`�F�b�N
      xxcff_common1_pkg.chk_fa_location(
         iv_segment1      => data_rec.chr_column_5                -- �\���n
        ,iv_segment2      => data_rec.chr_column_6                -- ����
        ,iv_segment3      => data_rec.chr_column_7                -- ���Ə�
        ,iv_segment4      => data_rec.chr_column_8                -- �ꏊ
        ,iv_segment5      => data_rec.chr_column_9                -- �{�ЍH��敪
        ,on_location_id   => lt_location_id                       -- ���Ə�CCID
        ,ov_errbuf        => lv_errbuf                            -- �G���[�E���b�Z�[�W           --# �Œ� # 
        ,ov_retcode       => lv_retcode                           -- ���^�[���E�R�[�h             --# �Œ� #
        ,ov_errmsg        => lv_errmsg                            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
--
      -- ���ʊ֐��G���[
      IF ( lv_retcode <> cv_status_normal ) THEN
        -- �G���[�t���O��Y�ɐݒ�
        lv_err_flg := cv_flag_y;
        -- ���b�Z�[�W�ҏW
        lv_errmsg := '�s�ԍ��F' || ln_record_cnt || ' ���Y�ԍ��F' || data_rec.condition_1 || ' ���Ə�������������܂���B';
        -- ���b�Z�[�W�o��
        FND_FILE.PUT_LINE(
          which  => FND_FILE.LOG
         ,buff   => lv_errmsg
        );
      END IF;
--
      IF ( lv_err_flg = cv_flag_n ) THEN
      --==============================================================
      -- �U��OIF�o�^
      --==============================================================
--        BEGIN
          INSERT INTO xx01_transfer_oif(
             transfer_oif_id                                                -- �U��OIF����ID
            ,book_type_code                                                 -- �䒠
            ,asset_number                                                   -- ���Y�ԍ�
            ,created_by                                                     -- �쐬��ID
            ,creation_date                                                  -- �쐬��
            ,last_updated_by                                                -- �ŏI�X�V��
            ,last_update_date                                               -- �ŏI�X�V��
            ,last_update_login                                              -- �ŏI�X�V���O�C��ID
            ,request_id                                                     -- ���N�G�X�gID
            ,program_application_id                                         -- �A�v���P�[�V����ID
            ,program_id                                                     -- �v���O����ID
            ,program_update_date                                            -- �v���O�����ŏI�X�V��
            ,transaction_date_entered                                       -- �U�֓�
            ,transaction_units                                              -- �P�ʕύX
            ,posting_flag                                                   -- �]�L�`�F�b�N�t���O
            ,status                                                         -- �X�e�[�^�X
            ,segment1                                                       -- �������p���Z�O�����g1
            ,segment2                                                       -- �������p���Z�O�����g2
            ,segment3                                                       -- �������p���Z�O�����g3
            ,segment4                                                       -- �������p���Z�O�����g4
            ,segment5                                                       -- �������p���Z�O�����g5
            ,segment6                                                       -- �������p���Z�O�����g6
            ,segment7                                                       -- �������p���Z�O�����g7
            ,segment8                                                       -- �������p���Z�O�����g8
            ,loc_segment1                                                   -- ���Ə��t���b�N�X�t�B�[���h1
            ,loc_segment2                                                   -- ���Ə��t���b�N�X�t�B�[���h2
            ,loc_segment3                                                   -- ���Ə��t���b�N�X�t�B�[���h3
            ,loc_segment4                                                   -- ���Ə��t���b�N�X�t�B�[���h4
            ,loc_segment5                                                   -- ���Ə��t���b�N�X�t�B�[���h5
          ) VALUES (
             xx01_transfer_oif_s.NEXTVAL                                    -- �U��OIF����ID
            ,data_rec.condition_2                                           -- �䒠
            ,data_rec.condition_1                                           -- ���Y�ԍ�
            ,cn_created_by                                                  -- �쐬��ID
            ,cd_creation_date                                               -- �쐬��
            ,cn_last_updated_by                                             -- �ŏI�X�V��
            ,cd_last_update_date                                            -- �ŏI�X�V��
            ,cn_last_update_login                                           -- �ŏI�X�V���O�C��ID
            ,cn_request_id                                                  -- �v��ID
            ,cn_program_application_id                                      -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
            ,cn_program_id                                                  -- �R���J�����g�E�v���O����ID
            ,cd_program_update_date                                         -- �v���O�����X�V��
            ,TO_DATE( data_rec.chr_column_1 , cv_date_format_1 )            -- �U�֓�
            ,ln_current_units                                               -- �P�ʕύX
            ,cv_flg_yes                                                     -- �]�L�`�F�b�N�t���O(�Œ�lY)
            ,cv_pending                                                     -- �X�e�[�^�X(PENDING)
            ,cv_segment1                                                    -- �������p���Z�O�����g1
            ,data_rec.chr_column_2                                          -- �������p���Z�O�����g2
            ,data_rec.chr_column_3                                          -- �������p���Z�O�����g3
            ,data_rec.chr_column_4                                          -- �������p���Z�O�����g4
            ,cv_segment5                                                    -- �������p���Z�O�����g5
            ,cv_segment6                                                    -- �������p���Z�O�����g6
            ,cv_segment7                                                    -- �������p���Z�O�����g7
            ,cv_segment8                                                    -- �������p���Z�O�����g8
            ,data_rec.chr_column_5                                          -- ���Ə��t���b�N�X�t�B�[���h1
            ,data_rec.chr_column_6                                          -- ���Ə��t���b�N�X�t�B�[���h2
            ,data_rec.chr_column_7                                          -- ���Ə��t���b�N�X�t�B�[���h3
            ,data_rec.chr_column_8                                          -- ���Ə��t���b�N�X�t�B�[���h4
            ,data_rec.chr_column_9                                          -- ���Ə��t���b�N�X�t�B�[���h5
          );
          -- �����������Z
          gn_normal_cnt := gn_normal_cnt + 1;
--        END;
      ELSE
        -- �X�L�b�v�������Z
        gn_warn_cnt := gn_warn_cnt + 1;
      END IF;
--
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
    --���[�N�e�[�u���폜
    DELETE
    FROM   xxccp_data_patch_work xdpw
    WHERE  xdpw.file_id = ln_file_id
    ;
--
    -- �Ώی������Z
    gn_target_cnt := gn_target_cnt + ln_skip_cnt;
    -- �X�L�b�v�������Z
    gn_warn_cnt   := gn_warn_cnt   + ln_skip_cnt;
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
      -- ���b�Z�[�W�ҏW
      lv_errmsg := '�s�ԍ��F' || ln_record_cnt || ' ���Y�ԍ��F' || data_rec.condition_1 || ' ' || lv_errbuf;
      -- ���b�Z�[�W�o��
      FND_FILE.PUT_LINE(
        which  => FND_FILE.LOG
       ,buff   => lv_errmsg
      );
      ROLLBACK;  --�X�V�����[���o�b�N
--
      --�t�@�C��IF�f�[�^�폜
      DELETE
      FROM xxccp_mrp_file_ul_interface xmfui
      WHERE  xmfui.file_id = ln_file_id
      ;
--
      --���[�N�e�[�u���폜
      DELETE
      FROM xxccp_data_patch_work xdpw
      WHERE  xdpw.file_id = ln_file_id
      ;
--
      IF ( data_cur%ISOPEN ) THEN
          CLOSE data_cur;
      END IF;
--
      --�f�[�^�폜�̃R�~�b�g
      COMMIT;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := SQLERRM;
      ov_retcode := cv_status_error;
      -- ���b�Z�[�W�ҏW
      lv_errmsg := '�s�ԍ��F' || ln_record_cnt || ' ���Y�ԍ��F' || data_rec.condition_1 || ' ' || SQLERRM;
      -- ���b�Z�[�W�o��
      FND_FILE.PUT_LINE(
        which  => FND_FILE.LOG
       ,buff   => lv_errmsg
      );
      ROLLBACK;  --�X�V�����[���o�b�N
      --�t�@�C��IF�f�[�^�폜
      DELETE
      FROM xxccp_mrp_file_ul_interface xmfui
      WHERE  xmfui.file_id = ln_file_id
      ;
--
      --���[�N�e�[�u���폜
      DELETE
      FROM xxccp_data_patch_work xdpw
      WHERE  xdpw.file_id = ln_file_id
      ;
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
    errbuf          OUT VARCHAR2,       -- �G���[�E���b�Z�[�W  --# �Œ� #
    retcode         OUT VARCHAR2,       -- ���^�[���E�R�[�h    --# �Œ� #
    iv_file_id      IN  VARCHAR2,       -- �t�@�C��ID
    iv_fmt_ptn      IN  VARCHAR2        -- �t�H�[�}�b�g�p�^�[��
  )
--
  IS
--
--###########################  �Œ蕔 START   ###########################
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name               CONSTANT  VARCHAR2(100) := 'main';                -- �v���O������
    cv_appl_short_name        CONSTANT  VARCHAR2(10)  := 'XXCCP';               -- �A�h�I���F���ʁEIF�̈�
    cv_target_rec_msg         CONSTANT  VARCHAR2(100) := 'APP-XXCCP1-90000';    -- �Ώی������b�Z�[�W
    cv_success_rec_msg        CONSTANT  VARCHAR2(100) := 'APP-XXCCP1-90001';    -- �����������b�Z�[�W
    cv_error_rec_msg          CONSTANT  VARCHAR2(100) := 'APP-XXCCP1-90002';    -- �G���[�������b�Z�[�W
    cv_skip_rec_msg           CONSTANT  VARCHAR2(100) := 'APP-XXCCP1-90003';    -- �X�L�b�v�������b�Z�[�W
    cv_cnt_token              CONSTANT  VARCHAR2(10)  := 'COUNT';               -- �������b�Z�[�W�p�g�[�N����
    cv_normal_msg             CONSTANT  VARCHAR2(100) := 'APP-XXCCP1-90004';    -- ����I�����b�Z�[�W
    cv_warn_msg               CONSTANT  VARCHAR2(100) := 'APP-XXCCP1-90005';    -- �x���I�����b�Z�[�W
    cv_error_msg              CONSTANT  VARCHAR2(100) := 'APP-XXCCP1-90006';    -- �G���[�I���S���[���o�b�N
--
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf                           VARCHAR2(5000);                         -- �G���[�E���b�Z�[�W
    lv_retcode                          VARCHAR2(1);                            -- ���^�[���E�R�[�h
    lv_errmsg                           VARCHAR2(5000);                         -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_message_code                     VARCHAR2(100);                          -- �I�����b�Z�[�W�R�[�h
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
--###########################  �Œ蕔 END   #############################
--
    -- �O���[�o���ϐ��̏�����
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
    gn_warn_cnt   := 0;
--
    -- ===============================
    -- �����l���擾
    -- ===============================
    xxcff_common1_pkg.init(
       or_init_rec  => g_init_rec           -- �����l���
      ,ov_errbuf    => lv_errbuf            -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode   => lv_retcode           -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg    => lv_errmsg            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    -- ���ʊ֐����G���[�̏ꍇ
    IF ( lv_retcode <> cv_status_normal ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_cff         -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_msg_name_00258      -- ���b�Z�[�W
                     ,iv_token_name1  => cv_tkn_line_no         -- �g�[�N���R�[�h1
                     ,iv_token_value1 => 0                      -- �g�[�N���l1
                     ,iv_token_name2  => cv_tkn_func_name       -- �g�[�N���R�[�h2
                     ,iv_token_value2 => cv_msg_name_50130      -- �g�[�N���l2
                     ,iv_token_name3  => cv_tkn_info            -- �g�[�N���R�[�h3
                     ,iv_token_value3 => lv_errmsg              -- �g�[�N���l3
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- �����l���O���[�o���ϐ��Ɋi�[
    gd_process_date            := g_init_rec.process_date;               -- �Ɩ����t
    gt_chart_of_account_id     := g_init_rec.chart_of_accounts_id;       -- �Ȗڑ̌nID
    gt_application_short_name  := g_init_rec.gl_application_short_name;  -- GL�A�v���P�[�V�����Z�k��
    gt_id_flex_code            := g_init_rec.id_flex_code;               -- �L�[�t���b�N�X�R�[�h
--
    -- ===============================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ===============================================
    submain(
       iv_file_id   -- �t�@�C��ID
      ,iv_fmt_ptn   -- �t�H�[�}�b�g�p�^�[��
      ,lv_errbuf    -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode   -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    --�G���[�o��
    IF (lv_retcode = cv_status_error) THEN
      --���������N���A
      gn_normal_cnt := 0;
      --�X�L�b�v�����N���A
      gn_warn_cnt   := 0;
      --�G���[����
      gn_error_cnt  := gn_target_cnt;
    END IF;
--
    --��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
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
    IF   (lv_retcode = cv_status_normal) THEN
      lv_message_code := cv_normal_msg;
    ELSIF(lv_retcode = cv_status_warn)   THEN
      lv_message_code := cv_warn_msg;
    ELSIF(lv_retcode = cv_status_error)  THEN
      lv_message_code := cv_error_msg;
    END IF;
--
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => lv_message_code
                   );
--
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
--
    --�X�e�[�^�X�Z�b�g
    retcode := lv_retcode;
--
    --�I���X�e�[�^�X���G���[�̏ꍇ��ROLLBACK����
    IF (retcode = cv_status_error) THEN
      ROLLBACK;
    END IF;
--
  EXCEPTION
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
      -- ���b�Z�[�W�o��
      FND_FILE.PUT_LINE(
        which  => FND_FILE.LOG
       ,buff   => errbuf
      );
      ROLLBACK;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
      -- ���b�Z�[�W�o��
      FND_FILE.PUT_LINE(
        which  => FND_FILE.LOG
       ,buff   => errbuf
      );
      ROLLBACK;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
      -- ���b�Z�[�W�o��
      FND_FILE.PUT_LINE(
        which  => FND_FILE.LOG
       ,buff   => errbuf
      );
      ROLLBACK;
  END main;
--
END XXCCP008A07C;
/