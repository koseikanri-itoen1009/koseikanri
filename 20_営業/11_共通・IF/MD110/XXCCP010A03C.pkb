CREATE OR REPLACE PACKAGE BODY APPS.XXCCP010A03C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2016. All rights reserved.
 *
 * Package Name     : XXCCP010A03C(body)
 * Description      : �⍇���S�����_�X�V�A�b�v���[�h
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
 *  2016/04/27    1.0   Y.Shoji          [E_�{�ғ�_08373]�V�K�쐬
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
  cn_created_by             CONSTANT NUMBER      := fnd_global.user_id;           --CREATED_BY
  cd_creation_date          CONSTANT DATE        := SYSDATE;                      --CREATION_DATE
  cn_last_updated_by        CONSTANT NUMBER      := fnd_global.user_id;           --LAST_UPDATED_BY
  cd_last_update_date       CONSTANT DATE        := SYSDATE;                      --LAST_UPDATE_DATE
  cn_last_update_login      CONSTANT NUMBER      := fnd_global.login_id;          --LAST_UPDATE_LOGIN
  cn_request_id             CONSTANT NUMBER      := fnd_global.conc_request_id;   --REQUEST_ID
  cn_program_application_id CONSTANT NUMBER      := fnd_global.prog_appl_id;      --PROGRAM_APPLICATION_ID
  cn_program_id             CONSTANT NUMBER      := fnd_global.conc_program_id;   --PROGRAM_ID
  cd_program_update_date    CONSTANT DATE        := SYSDATE;                      --PROGRAM_UPDATE_DATE
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
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name      CONSTANT VARCHAR2(100) := 'XXCCP010A03C';                 -- �v���O������
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gv_header_flg             VARCHAR2(1)      DEFAULT 'N';                    -- �x���w�b�_�m�F�p
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���E�J�[�\��
  -- ===============================
  -- �d����X�V�f�[�^�J�[�\��
  CURSOR data_cur( in_file_id NUMBER )
  IS
    SELECT   xdpw.execute_mode  AS execute_mode   --���s���[�h
            ,xdpw.condition_1   AS condition_1    --�d����ԍ�
            ,xdpw.chr_column_1  AS chr_column_1   --�⍇���S�����_
    FROM     xxccp_data_patch_work xdpw
    WHERE    xdpw.file_id = in_file_id
    ORDER BY xdpw.data_sequence
    ;
--
  data_rec data_cur%ROWTYPE;
--
--
  /**********************************************************************************
   * Procedure Name   : output_warn_msg
   * Description      : �x�����b�Z�[�W�o�͏���
   **********************************************************************************/
  PROCEDURE output_warn_msg(
    it_data_rec   IN  data_cur%ROWTYPE    --   1.�f�[�^���R�[�h
   ,iv_message    IN  VARCHAR2            --   2.���b�Z�[�W���e
   ,ov_errbuf     OUT VARCHAR2     --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode    OUT VARCHAR2     --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg     OUT VARCHAR2     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    IF ( gv_header_flg <> 'Y' ) THEN
      -- �x�����O�p�w�b�_�o��
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   =>   '"'||  '���s���[�h'            ||'","'
                        ||  '�d����ԍ�'            ||'","'
                        ||  '�⍇���S�����_'        ||'","'
                        ||  '�x�����b�Z�[�W'        ||'"'
      );
      --�w�b�_�o�̓t���OON
      gv_header_flg := 'Y';
    END IF;
    -- �x�����O�o��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   =>  '"'   || it_data_rec.execute_mode || '","'  --���s���[�h
                        || it_data_rec.condition_1  || '","'  --�d����ԍ�
                        || it_data_rec.chr_column_1 || '","'  --�⍇���S�����_
                        || iv_message               || '"'    --�x�����b�Z�[�W
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
    iv_file_id    IN  VARCHAR2     --   1.�t�@�C��ID
   ,iv_fmt_ptn    IN  VARCHAR2     --   2.�t�H�[�}�b�g�p�^�[��
   ,ov_errbuf     OUT VARCHAR2     --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode    OUT VARCHAR2     --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg     OUT VARCHAR2     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    cv_lang                   CONSTANT VARCHAR2(2)  := USERENV('LANG');
    cv_exe_mode_0             CONSTANT VARCHAR2(1)  := '0';
    cv_exe_mode_1             CONSTANT VARCHAR2(1)  := '1';
    --CSV���ڐ�
    cn_csv_file_col_num       CONSTANT NUMBER       := 3;             -- CSV�t�@�C�����ڐ�
--
    -- *** ���[�J���ϐ� ***
    --�A�b�v���[�h�p�ϐ�
    lt_file_ul_name   fnd_lookup_values.meaning%TYPE;                 -- �t�@�C���A�b�v���[�h����
    lt_file_name      xxccp_mrp_file_ul_interface.file_name%TYPE;     -- CSV�t�@�C����
    l_file_data_tab   xxccp_common_pkg2.g_file_data_tbl;              -- �s�P�ʃf�[�^�i�[�p�z��
    ln_col_num        NUMBER;                                         -- ���ڐ��擾�p
    ln_line_cnt       NUMBER;                                         -- CSV�t�@�C���e�s�Q�Ɨp�J�E���^
    ln_column_cnt     NUMBER;                                         -- CSV�t�@�C���e��Q�Ɨp�J�E���^
    ln_file_id        NUMBER  := TO_NUMBER(iv_file_id);               -- �t�@�C��ID
    ln_seq            NUMBER  := 0;                                   -- ���[�N�e�[�u���p�V�[�P���X�ԍ�
    ln_head_cnt       NUMBER  := 0;                                   -- ���O�w�b�_�m�F�p
    ln_cnt            NUMBER  := 1;                                   -- ���[�v�J�E���^
    lv_exec_flg       VARCHAR2(1);                                    -- ���s���[�h
    lv_err_flg        VARCHAR2(1)  DEFAULT 'N';                       -- �G���[�t���O
--
    TYPE gt_col_data_ttype       IS TABLE OF VARCHAR2(5000) INDEX BY BINARY_INTEGER;                   -- 1�����z��i���ځj
    TYPE gt_rec_data_ttype       IS TABLE OF gt_col_data_ttype INDEX BY BINARY_INTEGER;                -- 2�����z��i���R�[�h�j�i���ځj
    lt_path_data_tab   gt_rec_data_ttype;
    TYPE lt_vendor_site_id_ttype IS TABLE OF po_vendor_sites.vendor_site_id%TYPE INDEX BY PLS_INTEGER; -- �d����T�C�gID
    lt_vendor_site_id  lt_vendor_site_id_ttype;
    TYPE lt_attribute5_ttype     IS TABLE OF po_vendor_sites.attribute5%TYPE INDEX BY PLS_INTEGER;     -- �⍇���S�����_
    lt_attribute5      lt_attribute5_ttype;
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
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => '�t�@�C��ID                    �F' || iv_file_id
    );
    -- �t�H�[�}�b�g�p�^�[���o��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => '�p�����[�^�t�H�[�}�b�g�p�^�[���F' || iv_fmt_ptn
    );
    --
    --==============================================================
    -- �t�@�C���A�b�v���[�h���̏o��
    --==============================================================
    SELECT flv.meaning  AS meaning
    INTO   lt_file_ul_name
    FROM   fnd_lookup_values flv
    WHERE  flv.lookup_type  = cv_lookup_fo
    AND    flv.lookup_code  = iv_fmt_ptn
    AND    flv.language     = cv_lang
    AND    flv.enabled_flag = 'Y'
    AND    TRUNC(SYSDATE) BETWEEN flv.start_date_active
                          AND     NVL(flv.end_date_active, TRUNC(SYSDATE))
    ;
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => '�t�@�C���A�b�v���[�h����      �F'||lt_file_ul_name
    );
    --
    --==============================================================
    -- �t�@�C�����o��
    --==============================================================
    SELECT  xmfui.file_name  AS file_name
    INTO    lt_file_name
    FROM    xxccp_mrp_file_ul_interface xmfui
    WHERE   xmfui.file_id = ln_file_id
    FOR UPDATE NOWAIT
    ;
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => '�t�@�C����                    �F'||lt_file_name
    );
    --
    --���s�̏o��
    FND_FILE.PUT_LINE(
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
        ,chr_column_1
      ) VALUES (
         ln_file_id                         -- �t�@�C��ID
        ,ln_seq                             -- �f�[�^�V�[�P���X
        ,lt_path_data_tab(ln_line_cnt)(1)   -- ���s���[�h
        ,lt_path_data_tab(ln_line_cnt)(2)   -- �d����ԍ�
        ,lt_path_data_tab(ln_line_cnt)(3)   -- �⍇���S�����_
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
    WHERE xmfui.file_id = ln_file_id
    ;
--
    lt_path_data_tab.DELETE;
--
    --==============================================================
    -- �f�[�^�m�F����
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
      --������
      lv_err_flg     := 'N';    --�G���[�t���O
--
      --�P�s�ڂ̎��s���[�h���擾
      IF ( ln_cnt = 1 ) THEN
        -- ���s���[�h�`�F�b�N(0�A1�ȊO�̓G���[)
        IF ( data_rec.execute_mode IS NULL )
          OR( ( data_rec.execute_mode <> cv_exe_mode_0 )
            AND ( data_rec.execute_mode <> cv_exe_mode_1 ) ) THEN
           lv_errbuf := '���s���[�h�ɂ�0(�Ώۊm�F)�܂���1(�f�[�^�X�V)�̒l����͂��ĉ������B'||data_rec.execute_mode;
           RAISE global_api_others_expt;
        END IF;
        -- ���s���[�h��ϐ��Ɋi�[
        lv_exec_flg := data_rec.execute_mode;
        --
      END IF;
--
      -- �d����ԍ�NULL�`�F�b�N
      IF ( data_rec.condition_1 IS NULL ) THEN
        --�G���[�t���O��Y�ɐݒ�
        lv_err_flg := 'Y';
        --�x�����b�Z�[�W�o�͏���
        output_warn_msg(
           it_data_rec => data_rec
          ,iv_message  => '['|| ln_cnt || '�s��] �d����ԍ������ݒ�ł��B'
          ,ov_errbuf   => lv_errbuf
          ,ov_retcode  => lv_retcode
          ,ov_errmsg   => lv_errmsg
        );
        IF (lv_retcode <> cv_status_normal) THEN
          RAISE global_api_others_expt;
        END IF;
        -- �G���[�����J�E���g
        gn_error_cnt := gn_error_cnt + 1;
        --
      ELSE
        --�d����ԍ��`�F�b�N
        BEGIN
          SELECT pvs.vendor_site_id AS vd_site_id
          INTO   lt_vendor_site_id(ln_cnt)
          FROM   po_vendors      pv   -- �d����}�X�^
                ,po_vendor_sites pvs  -- �d����T�C�g�}�X�^
          WHERE  pv.vendor_id               = pvs.vendor_id
            AND  TRUNC(SYSDATE)            >= pv.start_date_active
            AND  TRUNC(SYSDATE)            <= NVL( pv.end_date_active ,TRUNC(SYSDATE) )
            AND  TRUNC(SYSDATE)            <  NVL( pvs.inactive_date  ,TRUNC(SYSDATE) + 1 )
            AND  pv.segment1                = data_rec.condition_1
          ;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            --�G���[�t���O��Y�ɐݒ�
            lv_err_flg := 'Y';
            --�G���[���b�Z�[�W�o�͏���
            output_warn_msg(
               it_data_rec => data_rec
              ,iv_message  => '[' || ln_cnt || '�s��] �d����ԍ��F' || data_rec.condition_1 || ' ���s���ł��B'
              ,ov_errbuf   => lv_errbuf
              ,ov_retcode  => lv_retcode
              ,ov_errmsg   => lv_errmsg
            );
            IF (lv_retcode <> cv_status_normal) THEN
              RAISE global_api_others_expt;
            END IF;
            -- �G���[�����J�E���g
            gn_error_cnt := gn_error_cnt + 1;
        END;
      END IF;
--
      -- �⍇���S�����_NULL�`�F�b�N
      IF ( data_rec.chr_column_1 IS NULL ) THEN
        --�G���[�t���O��Y�ɐݒ�
        lv_err_flg := 'Y';
        --�G���[���b�Z�[�W�o�͏���
        output_warn_msg(
           it_data_rec => data_rec
          ,iv_message  => '['|| ln_cnt || '�s��] �⍇���S�����_�����ݒ�ł��B'
          ,ov_errbuf   => lv_errbuf
          ,ov_retcode  => lv_retcode
          ,ov_errmsg   => lv_errmsg
        );
        IF (lv_retcode <> cv_status_normal) THEN
          RAISE global_api_others_expt;
        END IF;
        -- �G���[�����J�E���g
        gn_error_cnt := gn_error_cnt + 1;
      ELSE
        --
        --���݃`�F�b�N(�⍇���S�����_)
        --��hz_parties�͕s�v�����l�Z�b�g�Ə����𓯈�ɂ���
        BEGIN
          SELECT hca.account_number AS attribute5
          INTO   lt_attribute5(ln_cnt)
          FROM   hz_cust_accounts hca
                ,hz_parties       hp
          WHERE  hca.party_id            = hp.party_id
            AND  hca.customer_class_code = '1'
            AND  hca.account_number      = data_rec.chr_column_1
          ;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            --�G���[�t���O��Y�ɐݒ�
            lv_err_flg := 'Y';
            --�G���[���b�Z�[�W�o�͏���
            output_warn_msg(
               it_data_rec => data_rec
              ,iv_message  => '[' || ln_cnt || '�s��] �⍇���S�����_�F' || data_rec.chr_column_1 || ' ���s���ł��B'
              ,ov_errbuf   => lv_errbuf
              ,ov_retcode  => lv_retcode
              ,ov_errmsg   => lv_errmsg
            );
            IF (lv_retcode <> cv_status_normal) THEN
              RAISE global_api_others_expt;
            END IF;
            -- �G���[�����J�E���g
            gn_error_cnt := gn_error_cnt + 1;
        END;
      END IF;
--
      --�X�V��m�F�p�f�[�^�o��
      IF ( lv_err_flg <> 'Y' ) THEN
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
      END IF;
--;
      --�J�E���g�A�b�v
      ln_cnt := ln_cnt + 1;
    END LOOP;
--
    --�J�[�\���N���[�Y
    CLOSE data_cur;
--
    --==============================================================
    -- �f�[�^�X�V����
    --==============================================================
    --�`�F�b�N�G���[���Ȃ��A���s���[�h���X�V�̏ꍇ�̂ݍX�V���������{
    IF ( ( gn_error_cnt = 0 ) AND ( lv_exec_flg = cv_exe_mode_1 ) )  THEN
      BEGIN
        FORALL i IN 1..ln_cnt - 1
          UPDATE po_vendor_sites pvs
          SET    pvs.attribute5     = lt_attribute5(i)
          WHERE  pvs.vendor_site_id = lt_vendor_site_id(i)
          ;
      EXCEPTION
        WHEN OTHERS THEN
          lv_errbuf := '�X�V�����Ɏ��s���܂����B';
          RAISE global_api_others_expt;
      END;
--
      -- ���������J�E���g
      gn_normal_cnt := ln_cnt - 1;
    END IF;
--
    --���s�̏o��
    FND_FILE.PUT_LINE(
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
      -- �X�V��̃f�[�^��\��
      IF ( ln_head_cnt = 0 ) THEN
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => 
                  '"�d����ԍ�",'        ||
                  '"�⍇���S�����_"'
          );
          --�w�b�_�o�͂���
          ln_head_cnt := 1;
      END IF;
--
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   =>'"' ||
                  data_rec.condition_1   || '","' ||
                  data_rec.chr_column_1  || '"'
      );
    END LOOP;
--
    --���[�N�e�[�u���폜
    DELETE FROM xxccp_data_patch_work xdpw
    WHERE xdpw.file_id = ln_file_id
    ;
--
    --�`�F�b�N�G���[���P���ȏ㑶�݂����ꍇ�A�X�e�[�^�X���G���[�ɂ���
    IF ( gn_error_cnt > 0 ) THEN
      ov_retcode := cv_status_error;
    END IF;
--
  EXCEPTION
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      gn_error_cnt := 1;
      ov_errbuf  := lv_errbuf;
      ov_retcode := cv_status_error;
      ROLLBACK;  --�X�V�����[���o�b�N
      --�t�@�C��IF�f�[�^�폜
      DELETE FROM xxccp_mrp_file_ul_interface xmfui
      WHERE xmfui.file_id = ln_file_id
      ;
      --���[�N�e�[�u���폜
      DELETE FROM xxccp_data_patch_work xdpw
      WHERE xdpw.file_id = ln_file_id
      ;
      --�f�[�^�폜�̃R�~�b�g
      COMMIT;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      gn_error_cnt := 1;
      ov_errbuf  := SQLERRM;
      ov_retcode := cv_status_error;
      ROLLBACK;  --�X�V�����[���o�b�N
      --�t�@�C��IF�f�[�^�폜
      DELETE FROM xxccp_mrp_file_ul_interface xmfui
      WHERE xmfui.file_id = ln_file_id
      ;
      --���[�N�e�[�u���폜
      DELETE FROM xxccp_data_patch_work xdpw
      WHERE xdpw.file_id = ln_file_id
      ;
      --�J�[�\���N���[�Y
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
    errbuf        OUT VARCHAR2      --   �G���[�E���b�Z�[�W  --# �Œ� #
   ,retcode       OUT VARCHAR2      --   ���^�[���E�R�[�h    --# �Œ� #
   ,iv_file_id    IN  VARCHAR2      -- 1.�t�@�C��ID
   ,iv_fmt_ptn    IN  VARCHAR2      -- 2.�t�H�[�}�b�g�p�^�[��
  )
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
      --�����N���A
      gn_normal_cnt := 0;
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
END XXCCP010A03C;
/