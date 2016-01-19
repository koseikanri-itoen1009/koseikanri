CREATE OR REPLACE PACKAGE BODY XXCCP008A06C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * Package Name     : XXCCP008A06C(body)
 * Description      : �x���_�[�w�������폜�@�\
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
 *  2015/12/24    1.0   S.Yamashita      �V�K�쐬
 *
 *****************************************************************************************/
--
--#######################  �Œ�O���[�o���萔�錾�� START   #######################
--
  --�X�e�[�^�X�E�R�[�h
  cv_status_normal          CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal; --����:0
  cv_status_warn            CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_warn;   --�x��:1
  cv_status_error           CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_error;  --�ُ�:2
--
  cv_msg_part               CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont               CONSTANT VARCHAR2(3) := '.';
--
  gn_target_cnt             NUMBER;                    -- �Ώی���
  gn_normal_cnt             NUMBER;                    -- ���팏��
  gn_error_cnt              NUMBER;                    -- �G���[����
  gn_warn_cnt               NUMBER;                    -- �X�L�b�v����
  gv_out_msg                VARCHAR2(2000);
  --��O
  global_api_others_expt    EXCEPTION;
--
  cv_pkg_name               CONSTANT VARCHAR2(100) := 'XXCCP008A06C';   -- �v���O������
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
--
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
    --CSV���ڐ�
    cn_csv_file_col_num       CONSTANT NUMBER      := 2; -- CSV�t�@�C�����ڐ�
    --�Ɩ����t
    ld_process_date           CONSTANT DATE        := xxccp_common_pkg2.get_process_date;
    --�Œ�ϐ�
    lv_errbuf                 VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode                VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg                 VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
    --�A�b�v���[�h�p�ϐ�
    lv_file_ul_name  fnd_lookup_values.meaning%TYPE;              -- �t�@�C���A�b�v���[�h����
    lv_file_name     xxccp_mrp_file_ul_interface.file_name%TYPE;  -- CSV�t�@�C����
    l_file_data_tab  xxccp_common_pkg2.g_file_data_tbl;           -- �s�P�ʃf�[�^�i�[�p�z��
    ln_file_id       NUMBER  := TO_NUMBER(iv_file_id);
    ln_seq           NUMBER  := 0;
    TYPE gt_col_data_ttype    IS TABLE OF VARCHAR2(5000) INDEX BY BINARY_INTEGER;    --1�����z��i���ځj
    TYPE gt_rec_data_ttype    IS TABLE OF gt_col_data_ttype INDEX BY BINARY_INTEGER; --2�����z��i���R�[�h�j�i���ځj
    lt_patch_data_tab  gt_rec_data_ttype;
    -- ���ڃ`�F�b�N�p
    ln_col_num       NUMBER;
    ln_line_cnt      NUMBER;
    ln_column_cnt    NUMBER;
    --�����ŗL�̕ϐ�
    lv_err_flg           VARCHAR2(1)  := 'N';  --�x���`�F�b�N�p
    ln_cnt               NUMBER       := 1;    --���[�v��
    lv_exec_flag         VARCHAR2(1)  := NULL; --1�s�ڂ̎��s���[�h
    lv_after_value       VARCHAR2(1)  := NULL; --�A�g�σt���O(�X�V��)
    -- �����ϊm�F�p
    TYPE g_rec_checked_data IS RECORD(
      data_sequence              NUMBER   -- �V�[�P���X�ԍ�
    );
    -- �e�[�u���^
    TYPE g_tab_checked_data      IS TABLE OF g_rec_checked_data INDEX BY VARCHAR2(5000);
    -- �e�[�u��
    gt_checked_data              g_tab_checked_data;
--
    --�x���_�[�w�������擾�J�[�\��
    CURSOR data_cur
    IS
      SELECT   xdpw.execute_mode     AS execute_mode       -- ���s���[�h
              ,xdpw.data_sequence    AS data_sequence      -- �V�[�P���X�ԍ�
              ,xdpw.condition_1      AS condition_1        -- ����1(�����R�[�h)
              ,xvoh.object_code      AS object_code        -- �����R�[�h(���̋@�����Ǘ�)
              ,xvoh.object_status    AS object_status      -- �����X�e�[�^�X(���̋@�����Ǘ�)
              ,xiih.interface_flag   AS interface_flag     -- �A�g�σt���O(�X�V�O)
              ,xibv.lease_kbn        AS lease_kbn          -- ���[�X�敪
              ,xvohi.object_code     AS object_code_hist   -- ���O�o�͗p�F�����R�[�h(���̋@��������)
              ,xvohi.object_status   AS object_status_hist -- ���O�o�͗p�F�����X�e�[�^�X(���̋@��������)
      FROM     xxccp_data_patch_work     xdpw  -- �p�b�`���[�N�e�[�u��
              ,xxcff_vd_object_headers   xvoh  -- ���̋@�����Ǘ��e�[�u��
              ,xxcff_vd_object_histories xvohi -- ���̋@���������e�[�u��
              ,xxcso_ib_info_h           xiih  -- ���������e�[�u��(�c��)
              ,xxcso_install_base_v      xibv  -- �����}�X�^(�c��)
      WHERE    xdpw.file_id         = ln_file_id                 -- �t�@�C��ID
      AND      xdpw.condition_1     = xvoh.object_code(+)        -- ����1(�����R�[�h)
      AND      xvoh.object_code     = xvohi.object_code(+)       -- �����R�[�h
      AND      xvoh.object_code     = xiih.install_code(+)       -- �����R�[�h
      AND      xvoh.object_code     = xibv.install_code(+)       -- �����R�[�h
      ORDER BY
               xdpw.data_sequence -- �V�[�P���X�ԍ�
              ,xvohi.history_num  -- ����ԍ�
    ;
--
    data_rec data_cur%ROWTYPE;
--
  BEGIN
--
    -- �t�@�C��ID�o��
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => '�t�@�C��ID                    �F'||iv_file_id
    );
    -- �t�H�[�}�b�g�p�^�[���o��
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => '�p�����[�^�t�H�[�}�b�g�p�^�[���F'||iv_fmt_ptn
    );
    -- �t�@�C���A�b�v���[�h���̏o��
    SELECT flv.meaning meaning
    INTO   lv_file_ul_name
    FROM   fnd_lookup_values flv
    WHERE  flv.lookup_type  = 'XXCCP1_FILE_UPLOAD_OBJ'
    AND    flv.lookup_code  = iv_fmt_ptn
    AND    flv.language     = 'JA'
    AND    flv.enabled_flag = 'Y'
    AND    ld_process_date BETWEEN TRUNC( flv.start_date_active)  
                           AND     NVL( flv.end_date_active, ld_process_date )
    ;
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => '�t�@�C���A�b�v���[�h����      �F'||lv_file_ul_name
    );
    -- �t�@�C�����o��
    SELECT  xmfui.file_name file_name
    INTO    lv_file_name
    FROM    xxccp_mrp_file_ul_interface xmfui -- �t�@�C���A�b�v���[�hIF
    WHERE   xmfui.file_id = ln_file_id
    FOR UPDATE NOWAIT
    ;
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => '�t�@�C����                    �F'||lv_file_name
    );
    -- ��s�o��
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
--
    /************************************/
    /*       �A�b�v���[�h�f�[�^�擾     */
    /************************************/
    -- BLOB�f�[�^�ϊ��֐��ɂ��s�P�ʃf�[�^�𒊏o
    xxccp_common_pkg2.blob_to_varchar2(
       in_file_id   => ln_file_id       -- �t�@�C��ID
      ,ov_file_data => l_file_data_tab  -- �t�@�C���f�[�^
      ,ov_errbuf    => lv_errbuf        -- �G���[�E���b�Z�[�W            -- # �Œ� #
      ,ov_retcode   => lv_retcode       -- ���^�[���E�R�[�h              -- # �Œ� #
      ,ov_errmsg    => lv_errmsg        -- ���[�U�[�E�G���[�E���b�Z�[�W  -- # �Œ� #
    );
    IF (l_file_data_tab.COUNT <= 1 ) THEN
      lv_errbuf := '�Ώ�0���G���[';
      RAISE global_api_others_expt;
    END IF;
--
    FOR ln_line_cnt IN 1 .. l_file_data_tab.COUNT LOOP
      --���ڐ��擾
      ln_col_num := NVL(LENGTH(l_file_data_tab(ln_line_cnt)), 0)
                      - NVL(LENGTH(REPLACE(l_file_data_tab(ln_line_cnt), ',', NULL)), 0) + 1;
--
      --���ڐ��`�F�b�N
      IF (ln_col_num <> cn_csv_file_col_num) THEN
         lv_errbuf := '���ڐ��s���G���[';
         RAISE global_api_others_expt;
      ELSE
        <<column_loop>>
        FOR ln_column_cnt IN 1 .. cn_csv_file_col_num LOOP
          --���ڕ���
          lt_patch_data_tab(ln_line_cnt)(ln_column_cnt) := xxccp_common_pkg.char_delim_partition(
                                                             iv_char     => l_file_data_tab(ln_line_cnt)
                                                            ,iv_delim    => ','
                                                            ,in_part_num => ln_column_cnt
                                                          );
        END LOOP column_loop;
      END IF;
    END LOOP line_loop;
--
    <<ins_line_loop>>
    FOR ln_line_cnt IN 2 .. lt_patch_data_tab.COUNT LOOP
      --�f�[�^�V�[�P���X�̔�
      ln_seq := ln_seq + 1;
      --�p�b�`�p�e�[�u���o�^
      INSERT INTO xxccp_data_patch_work (
         file_id
        ,data_sequence
        ,execute_mode
        ,condition_1
      ) VALUES (
         ln_file_id                                               -- �t�@�C��ID
        ,ln_seq                                                   -- �f�[�^�V�[�P���X
        ,lt_patch_data_tab(ln_line_cnt)(1)                        -- ���s���[�h
        ,lt_patch_data_tab(ln_line_cnt)(2)                        -- �����l1�i�����R�[�h)
      )
      ;
      --�Ώی����J�E���g
      gn_target_cnt := gn_target_cnt + 1;
--
    END LOOP ins_line_loop;
--
    --�t�@�C���A�b�v���[�hIF�f�[�^�폜
    DELETE
    FROM  xxccp_mrp_file_ul_interface xmfui
    WHERE xmfui.file_id = ln_file_id
    ;
--
    lt_patch_data_tab.DELETE;
--
    /************************************/
    /*         �f�[�^�X�V����           */
    /************************************/
    -- �w�b�_�o��
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   =>   '"'||  'object_code'                ||'","'||
                          'object_status'              ||'","'||
                          'object_code'                ||'","'||
                          'object_status'              ||'","'||
                          'lease_kbn'                  ||'","'||
                          'interface_flag'             ||'","'||
                          'after_value'                ||'"'
    );
--
    -- �Ώۃf�[�^���o
    OPEN data_cur;
    LOOP
      FETCH data_cur INTO data_rec;
      EXIT WHEN data_cur%NOTFOUND;
--
      -- 1�s�ڂ̏ꍇ
      IF ( ln_cnt = 1 ) THEN
        -- ���s���[�h�`�F�b�N
        IF ( data_rec.execute_mode IS NULL )
          OR( ( data_rec.execute_mode <> '0' )
            AND ( data_rec.execute_mode <> '1' ) ) THEN
           lv_errbuf := '���s���[�h�ɂ�0(�Ώۊm�F)�܂���1(�f�[�^�X�V)�̒l����͂��ĉ�����';
           RAISE global_api_others_expt;
        END IF;
--
        -- ���s���[�h��ێ�
        lv_exec_flag := data_rec.execute_mode;
      END IF;
--
      -- �����������ςłȂ��ꍇ�i�������������݂���ꍇ�͍ŏ��̃��R�[�h�̂ݏ����ΏۂƂ���j
      IF ( NOT(gt_checked_data.EXISTS(data_rec.data_sequence)) ) THEN
        -- ������
        lv_err_flg     := 'N';  -- �G���[�t���O
        lv_after_value := data_rec.interface_flag; -- �A�g�σt���O�i�X�V��j
--
        -- �������݃`�F�b�N
        IF ( data_rec.object_code IS NULL ) THEN
          fnd_file.put_line(
            which  => FND_FILE.LOG
           ,buff   => '[' || ln_cnt || '�s��] �Y���̕����R�[�h�͑��݂��܂���'
          );
          lv_err_flg := 'Y';
        END IF;
--
        -- ���������݂���ꍇ
        IF ( data_rec.object_code IS NOT NULL ) THEN
          -- �����X�e�[�^�X�`�F�b�N
          IF ( data_rec.object_status <> '101' ) THEN
            fnd_file.put_line(
              which  => FND_FILE.LOG
             ,buff   => '[' || ln_cnt || '�s��] �Y���̕����X�e�[�^�X�͍폜�ł��܂���'
            );
            lv_err_flg := 'Y';
          END IF;
        END IF;
--
        -- �x�������������ꍇ
        IF ( lv_err_flg = 'Y' ) THEN
          -- �x�������J�E���g
          gn_warn_cnt := gn_warn_cnt + 1;
        END IF;
--
        --����f�[�^�Ŏ��s���[�h���X�V�̏ꍇ�̂�
        IF ( ( lv_err_flg <> 'Y' ) AND ( lv_exec_flag = '1' ) )  THEN
          -- ���̋@�����Ǘ��e�[�u���폜
          DELETE
          FROM  xxcff_vd_object_headers xvoh
          WHERE xvoh.object_code = data_rec.condition_1  -- ����1(�����R�[�h)
          ;
--
          -- ���̋@���������e�[�u���폜
          DELETE
          FROM  xxcff_vd_object_histories xvohi
          WHERE xvohi.object_code = data_rec.condition_1  -- ����1(�����R�[�h)
          ;
--
          -- ���������e�[�u��(�c��)�X�V
          UPDATE xxcso_ib_info_h xiih
          SET    xiih.interface_flag   = 'N'
                ,xiih.last_update_date = SYSDATE
                ,xiih.last_updated_by  = fnd_global.user_id
          WHERE  xiih.install_code     = data_rec.condition_1 -- ����1(�����R�[�h)
          RETURNING xiih.interface_flag
          INTO lv_after_value -- �A�g�σt���O(�X�V��)
          ;
--
          -- ���������J�E���g
          gn_normal_cnt := gn_normal_cnt + 1;
--
        END IF;
--
      -- ���[�v�񐔃J�E���g
      ln_cnt       := ln_cnt + 1;
--
      END IF;
--
      -- �m�F�p�f�[�^�o��
      fnd_file.put_line(
        which  => FND_FILE.OUTPUT
       ,buff   =>  '"'|| data_rec.object_code         || '","'  -- object_code
                      || data_rec.object_status       || '","'  -- object_status
                      || data_rec.object_code_hist    || '","'  -- object_code
                      || data_rec.object_status_hist  || '","'  -- object_status
                      || data_rec.lease_kbn           || '","'  -- lease_kbn
                      || data_rec.interface_flag      || '","'  -- interface_flag
                      || lv_after_value               || '"'    -- after_value
      );
--
      -- �����σe�[�u���ɕێ�
      gt_checked_data(data_rec.data_sequence).data_sequence := data_rec.data_sequence;
--
    END LOOP;
--
    CLOSE data_cur;
--
    --���[�N�e�[�u���폜
    DELETE
    FROM  xxccp_data_patch_work xdpw
    WHERE xdpw.file_id = ln_file_id
    ;
--
    --�x�����P���ȏ㑶�݂����ꍇ�A�X�e�[�^�X���x���ɂ���
    IF ( gn_warn_cnt > 0 ) THEN
      ov_retcode := cv_status_warn;
    END IF;
--
  EXCEPTION
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf    := lv_errbuf;
      ov_retcode   := cv_status_error;
      ROLLBACK;  --�X�V�����[���o�b�N
      --�t�@�C��IF�f�[�^�폜
      DELETE
      FROM  xxccp_mrp_file_ul_interface xmfui
      WHERE xmfui.file_id = ln_file_id
      ;
      COMMIT;    --�f�[�^�폜�̃R�~�b�g
--
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      IF (data_cur %ISOPEN)THEN
        CLOSE data_cur;
      END IF;
      ov_errbuf    := SQLERRM;
      ov_retcode   := cv_status_error;
      ROLLBACK;  --�X�V�����[���o�b�N
      --�t�@�C��IF�f�[�^�폜
      DELETE
      FROM  xxccp_mrp_file_ul_interface xmfui
      WHERE xmfui.file_id = ln_file_id
      ;
      --���[�N�e�[�u���폜
      DELETE
      FROM  xxccp_data_patch_work xdpw
      WHERE xdpw.file_id = ln_file_id
      ;
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
END XXCCP008A06C;
/
