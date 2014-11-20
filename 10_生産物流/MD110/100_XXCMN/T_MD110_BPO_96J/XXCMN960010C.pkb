CREATE OR REPLACE PACKAGE BODY xxcmn960010c
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2012. All rights reserved.
 *
 * Package Name     : XXCMN960010C(body)
 * Description      : �󒍃p�[�W���s
 * MD.050           : T_MD050_BPO_96J_�󒍃p�[�W���s
 * Version          : 1.00
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                    Description
 * ---------------------- ----------------------------------------------------------
 *  genpurgeset             �p�[�W�Z�b�g�o�͏���
 *  updpurgeorder           �p�[�W�Z�b�g�X�V����
 *  purgerorder             �p�[�W���s
 *  submain                 ���C�������v���V�[�W��
 *  main                    �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2012/10/25    1.00  SCSK �{�{����    �V�K�쐬
 *  2013/03/06    1.00  SCSK �������    �ۑ�23�Ή��i�ۗ�/�����݌Ƀg�����iPORC�j���݊m�F�ǉ��j
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
  gv_out_msg                VARCHAR2(2000);
  gv_sep_msg                VARCHAR2(2000);
  gv_exec_user              VARCHAR2(100);
  gv_conc_name              VARCHAR2(30);
  gv_conc_status            VARCHAR2(30);
  gn_purgeset_cnt           NUMBER;        -- �p�[�W�Z�b�g�o�͌���
  gn_target_cnt             NUMBER;        -- �Ώی���
  gn_normal_cnt             NUMBER;        -- ���팏��
  gn_warning_cnt            NUMBER;        -- �W�����p�[�W�Ɏ��s��������
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
  -- ���[�U�[��`��O
  -- ===============================
  local_process_expt        EXCEPTION;
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name               CONSTANT VARCHAR2(100) := 'XXCMN960010C'; -- �p�b�P�[�W��
  cv_appl_short_name        CONSTANT VARCHAR2(10)  := 'XXCMN';            -- �A�h�I���F���ʁEIF�̈�
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  cv_conc_p_c               CONSTANT VARCHAR2(100) := 'COMPLETE';
  cv_conc_s_n               CONSTANT VARCHAR2(100) := 'NORMAL';
  cv_conc_s_w               CONSTANT VARCHAR2(100) := 'WARNING';
  cv_conc_s_e               CONSTANT VARCHAR2(100) := 'ERROR';
  cv_conc_s_c               CONSTANT VARCHAR2(100) := 'CANCELLED';
  cv_conc_s_t               CONSTANT VARCHAR2(100) := 'TERMINATED';
  cv_param_0                CONSTANT VARCHAR2(100) := '0';
  cv_param_1                CONSTANT VARCHAR2(100) := '1';
  cv_is_purgable_y          CONSTANT  VARCHAR2(1)  := 'Y';
  cv_is_purgable_n          CONSTANT  VARCHAR2(1)  := 'N';
  cv_is_purged_y            CONSTANT  VARCHAR2(1)  := 'Y';
  cv_is_purged_n            CONSTANT  VARCHAR2(1)  := 'N';
--
  cv_child_app_short_name   CONSTANT VARCHAR2(100) := 'ONT';
  cv_child_pgm_genpset      CONSTANT VARCHAR2(100) := 'GENPSETWHERE';
  cv_child_pgm_ordpur       CONSTANT VARCHAR2(100) := 'ORDPUR';
--
  cv_mst_normal             CONSTANT VARCHAR2(10)  := '����I��';
  cv_mst_warn               CONSTANT VARCHAR2(10)  := '�x���I��';
  cv_mst_error              CONSTANT VARCHAR2(10)  := '�ُ�I��';
  cv_msg_xxcmn10135         CONSTANT VARCHAR2(100) := 'APP-XXCMN-10135';  -- �v���̔��s���s�G���[
  cv_local_others_msg       CONSTANT VARCHAR2(100) := 'APP-XXCMN-11017';  -- �����Ɏ��s���܂����B�p�[�W�Z�b�gID: ��KEY
  cv_request_err_msg        CONSTANT VARCHAR2(100) := 'APP-XXCMN-11020';  -- �v��[ ��REQUEST ]������ɏI�����܂���ł����B
  cv_token_key              CONSTANT VARCHAR2(10)  := 'KEY';
  cv_request_err_token      CONSTANT VARCHAR2(10)  := 'REQUEST';
--
  cv_min_date               CONSTANT VARCHAR2(100) := '1900/01/01 00:00:00';
  cv_yyyymmdd_literal       CONSTANT VARCHAR2(10)  := 'YYYY/MM/DD';
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gd_syori_date             DATE;   --������
  gn_purge_range            NUMBER; --�p�[�W����(������-���̊��Ԃ̓��t����o�ɓ�)
  gn_purge_range_fix        NUMBER; --�p�[�W���ԕ␳(��o�ɓ�-���̕␳�l�̓��t���Â����̂��p�[�W�����)
  gn_purge_range_day        NUMBER; --�p�[�W�����W����(From��o�ɓ�-���̓��� To��o�ɓ��@�̃f�[�^���p�[�W�����)
  gn_purgeset_del_period    NUMBER; --�p�[�W�Z�b�g�폜����(������-���̓������Â��X�V���̃p�[�W�Z�b�g�͍폜�����)
  gn_org_id                 NUMBER; --�c�ƒP��
  gn_purgeset_from_day      NUMBER; --�p�[�W�Z�b�g�����ΏۊJ�n����
  gn_commit_range           NUMBER; --�R�~�b�g�����W
  gn_purge_set_count        NUMBER;
  gv_pre_purge_set_name     VARCHAR2(100);           -- �p�[�W�Z�b�g���̃v���t�B�b�N�X
--
  /**********************************************************************************
   * Procedure Name   : genpurgeset
   * Description      : �p�[�W�Z�b�g�o�͏���
   **********************************************************************************/
  PROCEDURE genpurgeset(
    on_purge_set_id OUT NUMBER,       -- 1.�p�[�W�Z�b�gID(�{PROCEDURE�Ŏ擾�����)
    ov_errbuf       OUT VARCHAR2,     --   �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode      OUT VARCHAR2,     --   ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg       OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
--
  IS
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT  VARCHAR2(100) := 'genpurgeset';     -- �v���O������
    cv_xxcmn_purgeset_exist CONSTANT  VARCHAR2(100) := 'APP-XXCMN-11016'; -- �p�[�W�Z�b�g��[ ��PURGE_SET_NAME ]�����ɑ��݂��܂��B
    cv_token_purgeset_exist CONSTANT  VARCHAR2(100) := 'PURGE_SET_NAME';
    cv_min_time             CONSTANT  VARCHAR2(10)  := ' 00:00:00';
    cv_max_time             CONSTANT  VARCHAR2(10)  := ' 23:59:59';
--
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf                         VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode                        VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg                         VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
    --FND_REQUEST.SUBMIT_REQUEST�Ŏg�p����ϐ�
    lv_phase                          VARCHAR2(100);
    lv_status                         VARCHAR2(100);
    lv_dev_phase                      VARCHAR2(100);
    lv_dev_status                     VARCHAR2(100);
    ln_request_id                     NUMBER;          -- �q�R���J�����g�̗v��ID
--
    lt_purge_set_name                 oe_purge_sets.purge_set_name%TYPE;        --�p�[�W�Z�b�g��  
    lt_purge_set_description          oe_purge_sets.purge_set_description%TYPE; --�p�[�W�Z�b�g�K�p
    lt_purge_set_name_exist           oe_purge_sets.purge_set_name%TYPE;        --����Z�b�g�����݃`�F�b�N�p
    ln_purge_set_count                NUMBER;                                   --�p�[�W�Z�b�g�e�[�u���ɏ����o���ꂽ����
    lv_ordered_date_low               VARCHAR2(100);                            --�R���J�����g�ɓn���󒍓�(From)
    lv_ordered_date_high              VARCHAR2(100);                            --�R���J�����g�ɓn���󒍓�(To)
    ld_std_syukko_date                DATE;                                     --��o�ɓ�
--
  BEGIN
--
    ov_retcode := cv_status_normal;
    --*********************************************************************************
    --�p�[�W�Z�b�g���A�p�[�W�Z�b�g�K�p�𓱏o
    --*********************************************************************************
    /*
    --a)�p�[�W�E�Z�b�g���F�p�[�W�E�Z�b�g�����ʂ��邽�߂́A��ӂ̖��̂���͂���B�i��F�^�C�g��+�p�[�W���{��(yyyymmdd)�j
    --b)�p�[�W�E�Z�b�g�K�p�F�p�[�W�E�Z�b�g�̓E�v����͂���B�i��F�^�C�g��+�p�[�W���{��(yyyymmdd)�j
    lt_�p�[�W�Z�b�g��   := gv_�p�[�W�Z�b�g���ړ��� || TO_CHAR(gd_������,'YYYYMMDD';
    lt_�p�[�W�Z�b�g�K�p := gv_�p�[�W�Z�b�g���ړ��� || TO_CHAR(gd_������,'YYYYMMDD';
    */
    lt_purge_set_name         := gv_pre_purge_set_name || TO_CHAR(gd_syori_date,cv_yyyymmdd_literal);
    lt_purge_set_description  := gv_pre_purge_set_name || TO_CHAR(gd_syori_date,cv_yyyymmdd_literal);
--
    --*********************************************************************************
    --�p�����[�^�ɃZ�b�g����󒍓�FROM�ATO�̒l�𓱏o
    --*********************************************************************************
    /*
    --c)�󒍓��F���F�������|(2)�Ŏ擾�����p�[�W���� - (2)�Ŏ擾�����p�[�W�Z�b�g�쐬�J�n����
    --             ���F�������|(2)�Ŏ擾�����p�[�W���� + (2)�Ŏ擾�����p�[�W���ԕ␳�i���o�ד��Ǝ󒍓��̃Y�����l���j
    lv_ordered_date_low  :=  TO_CHAR(gd_������ - gn_�p�[�W���� - gn_�p�[�W�Z�b�g�쐬�J�n����,'YYYY/MM/DD') || cv_�����ŏ��l;
    lv_ordered_date_high :=  TO_CHAR(gd_������ - gn_�p�[�W���� + gn_�p�[�W���ԕ␳,'YYYY/MM/DD') || cv_�����ő�l;
    */
    lv_ordered_date_low   := TO_CHAR(gd_syori_date - gn_purge_range - gn_purgeset_from_day, cv_yyyymmdd_literal) || cv_min_time;
    lv_ordered_date_high  := TO_CHAR(gd_syori_date - gn_purge_range + gn_purge_range_fix, cv_yyyymmdd_literal) || cv_max_time;
--
    --*********************************************************************************
    --����p�[�W�Z�b�g���̂̑��݃`�F�b�N
    --*********************************************************************************
    /*
    purge_set_name�ŕW���p�[�W�Z�b�g�e�[�u�����������A
    ����purge_set_name�̃��R�[�h�L�����擾����B
    SELECT PURGE_SET_NAME
    INTO lt_�p�[�W�Z�b�g������
    FROM OE_PURGE_SETS
    WHERE PURGE_SET_NAME = lt_�p�[�W�Z�b�g��
    AND ROWNUM = 1;
    */
    BEGIN
      SELECT
        ops.purge_set_name    AS purge_set_name
      INTO
        lt_purge_set_name_exist
      FROM
        oe_purge_sets ops 
      WHERE
        ops.purge_set_name = lt_purge_set_name
        AND ROWNUM = 1;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        NULL;
    END;
--
    --����p�[�W�Z�b�g�������݂�����A���b�Z�[�W���o�͂��A�X�e�[�^�X���x���ɂ���B
    --�i���̌�̓���ɉe���͂Ȃ��̂ŁA�����͑��s����B�j
    IF ( lt_purge_set_name_exist IS NOT NULL )  THEN
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_xxcmn_purgeset_exist -- �p�[�W�Z�b�g��[ ��PURGE_SET_NAME ]�����ɑ��݂��܂��B
                    ,iv_token_name1  => cv_token_purgeset_exist
                    ,iv_token_value1 => lt_purge_set_name
                   );
    --�o�͂Ƀ��b�Z�[�W���o�͂���
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
      --�X�e�[�^�X���x���ɂ���
      ov_retcode := cv_status_warn;
    END IF;
--
    --*********************************************************************************
    --���o���ꂽ�l�����ɁA�v���̔��s�u�󒍃p�[�W�I��(GENPSETWHERE)�v�����{����B
    --*********************************************************************************
    /*
    ln_request_id := FND_REQUEST.SUBMIT_REQUEST(.
                       application       => cv_child_app_short_name           .--�A�v���P�[�V�����Z�k��
                     , program           => cv_child_pgm_genpset              .--�v���O������
                     , argument1         => lt_purge_set_name                 .--�p�[�W�E�Z�b�g��
                     , argument2         => lt_purge_set_description          .--�p�[�W�E�Z�b�g�E�v
                     , argument8         => lv_ordered_date_low               .--�󒍓�(FROM)
                     , argument9         => lv_ordered_date_high              .--�󒍓�(TO)
                       );.
    */
    ln_request_id := FND_REQUEST.SUBMIT_REQUEST(
                       application       => cv_child_app_short_name     --�A�v���P�[�V�����Z�k��
                     , program           => cv_child_pgm_genpset        --�v���O������
                     , argument1         => lt_purge_set_name           --�p�[�W�E�Z�b�g��
                     , argument2         => lt_purge_set_description    --�p�[�W�E�Z�b�g�E�v
                     , argument3         => ''
                     , argument4         => ''
                     , argument5         => ''
                     , argument6         => ''
                     , argument7         => ''
                     , argument8         => lv_ordered_date_low         --�󒍓�(FROM)
                     , argument9         => lv_ordered_date_high        --�󒍓�(TO)
                     , argument10        => ''
                     , argument11        => ''
                     , argument12        => ''
                       );
--
    -- �R���J�����g�N�����s�̏ꍇ�̓G���[����
    /*
    IF ( ln_request_id = 0 ) THEN.
      lv_errmsg := xxcmn_common_pkg.get_msg(
                     iv_application   =>gv_cons_msg_kbn_cmn
                    ,iv_name          => gv_msg_xxcmn10135);
      RAISE global_api_others_expt;
    ELSE
      COMMIT;
    END IF;
    */
    IF ( NVL(ln_request_id, 0) = 0 ) THEN
      ov_errmsg := xxcmn_common_pkg.get_msg(
                     iv_application   => cv_appl_short_name
                    ,iv_name          => cv_msg_xxcmn10135);
      RAISE global_api_others_expt;
    ELSE
      COMMIT;
    END IF;
--
    --*********************************************************************************
    --���s���ꂽ�R���J�����g�̏I���`�F�b�N
    --*********************************************************************************
    --�R���J�����g���s���ʂ��擾
    /*
    IF ( FND_CONCURRENT.WAIT_FOR_REQUEST(.
           request_id => ln_request_id.
          ,interval   => 1.
          ,max_wait   => 0.
          ,phase      => lv_phase.
          ,status     => lv_status.
          ,dev_phase  => lv_dev_phase.
          ,dev_status => lv_dev_status.
          ,message    => lv_errbuf.
          ) ) THEN
    */
    IF ( FND_CONCURRENT.WAIT_FOR_REQUEST(
           request_id => ln_request_id
          ,interval   => 1
          ,max_wait   => 0
          ,phase      => lv_phase
          ,status     => lv_status
          ,dev_phase  => lv_dev_phase
          ,dev_status => lv_dev_status
          ,message    => ov_errbuf
          ) ) THEN
--
      -- �X�e�[�^�X���f
      -- �t�F�[�Y:����
      IF ( lv_dev_phase = cv_conc_p_c ) THEN
--
        /*
          lv_dev_status��'ERROR','CANCELLED','TERMINATED'�̏ꍇ�̓G���[�I��
        �@�@�@�@�X�e�[�^�X���G���[�ɂ��ďI��
          lv_dev_status��'WARNING'�̏ꍇ�͌x���I��
        �@�@�@�@�X�e�[�^�X���x���ɂ���

          lv_dev_status��'NORMAL'�̏ꍇ�͐��폈�����s

          lv_dev_status����L�ȊO�̏ꍇ�̓G���[�I��
        �@�@�@�@�X�e�[�^�X���G���[�ɂ��ďI��
        */
        --�X�e�[�^�X�R�[�h�ɂ��󋵔���
        CASE lv_dev_status
          --�G���[
          WHEN cv_conc_s_e THEN
            ov_errmsg := xxcmn_common_pkg.get_msg(
                           iv_application  => cv_appl_short_name
                          ,iv_name         => cv_request_err_msg
                          ,iv_token_name1  => cv_request_err_token
                          ,iv_token_value1 => cv_child_pgm_genpset
                         );
            RAISE global_api_others_expt;

          --�L�����Z��
          WHEN cv_conc_s_c THEN
            ov_errmsg := xxcmn_common_pkg.get_msg(
                           iv_application  => cv_appl_short_name
                          ,iv_name         => cv_request_err_msg
                          ,iv_token_name1  => cv_request_err_token
                          ,iv_token_value1 => cv_child_pgm_genpset
                         );
            RAISE global_api_others_expt;

          --�����I��
          WHEN cv_conc_s_t THEN
            ov_errmsg := xxcmn_common_pkg.get_msg(
                           iv_application  => cv_appl_short_name
                          ,iv_name         => cv_request_err_msg
                          ,iv_token_name1  => cv_request_err_token
                          ,iv_token_value1 => cv_child_pgm_genpset
                         );
            RAISE global_api_others_expt;

          --�x���I��
          WHEN cv_conc_s_w THEN
            --���܂Ő���̏ꍇ�̂݌x���X�e�[�^�X
            IF ( ov_retcode < 1 ) THEN
              ov_retcode := cv_status_warn;
            END IF;
 
          --����I��
          WHEN cv_conc_s_n THEN
              NULL;

          --���̒l�͗�O����
          ELSE
            ov_errmsg := xxcmn_common_pkg.get_msg(
                           iv_application  => cv_appl_short_name
                          ,iv_name         => cv_request_err_msg
                          ,iv_token_name1  => cv_request_err_token
                          ,iv_token_value1 => cv_child_pgm_genpset
                         );
            RAISE global_api_others_expt;
        END CASE;

      --�����܂ŏ�����҂��A�����X�e�[�^�X�ł͂Ȃ������ꍇ�̗�O�n���h��
      ELSE
        ov_errmsg := xxcmn_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name
                      ,iv_name         => cv_request_err_msg
                      ,iv_token_name1  => cv_request_err_token
                      ,iv_token_value1 => cv_child_pgm_genpset
                     );
        RAISE global_api_others_expt;
      END IF;
--
    --WAIT_FOR_REQUEST���ُ킾�����ꍇ�̗�O�n���h��
    ELSE
        ov_errmsg := xxcmn_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name
                      ,iv_name         => cv_request_err_msg
                      ,iv_token_name1  => cv_request_err_token
                      ,iv_token_value1 => cv_child_pgm_genpset
                     );
        RAISE global_api_others_expt;
    END IF;
--
    --*********************************************************************************
    --�p�[�W�Z�b�gID�̎擾
    --*********************************************************************************
    --lt_purge_set_name���L�[�ɕW���p�[�W�Z�b�g�e�[�u�����������A
    --�쐬���ꂽ�p�[�W�Z�b�gID���擾�i�p�[�W�Z�b�gID�̍ő�l�j
    /*
    SELECT MAX(�p�[�W�Z�b�gID)
    INTO on_�p�[�W�Z�b�gID
    FROM �󒍃p�[�W�Z�b�g�e�[�u��
    WHERE �p�[�W�Z�b�g�� = lt_�p�[�W�Z�b�g��;
    */
    SELECT
      MAX(ops.purge_set_id)  AS max_purge_set_id
    INTO
      on_purge_set_id
    FROM
      oe_purge_sets ops
    WHERE
      ops.purge_set_name = lt_purge_set_name;
--
    --�l���擾�ł��Ȃ������ꍇ�̓G���[�I��
    IF ( on_purge_set_id IS NULL ) THEN
        --�G���[����
        ov_retcode := cv_status_error;
        RAISE local_process_expt;
    END IF;
--
  EXCEPTION
    WHEN local_process_expt THEN
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
      ROLLBACK;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errmsg := xxcmn_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_local_others_msg
                    ,iv_token_name1  => cv_token_key
                    ,iv_token_value1 => TO_CHAR(on_purge_set_id)
                   );
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
  END genpurgeset;
--
  /**********************************************************************************
   * Procedure Name   : updpurgeorder
   * Description      : �p�[�W�Z�b�g�X�V����
   **********************************************************************************/
  PROCEDURE updpurgeorder(
    in_purge_set_id         IN  NUMBER,       -- 1.�p�[�W�Z�b�gID(�w�肵��ID���ΏۂƂȂ�)
    on_purge_target_count   OUT NUMBER,       -- 2.�p�[�W�Ώی���(�{�����œK�i='Y'�ɂ����������߂�)
    ov_errbuf               OUT VARCHAR2,     --   �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode              OUT VARCHAR2,     --   ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg               OUT VARCHAR2      --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  )
  IS
--
    cv_prg_name                 CONSTANT  VARCHAR2(100) := 'updpurgeorder';    -- �v���O������

    cv_status_wsh_keijozumi     CONSTANT  VARCHAR2(2)   :=  '04';--04:�o�׎��ьv���
    cv_status_po_keijozumi      CONSTANT  VARCHAR2(2)   :=  '08';--08:�o�׎��ьv���
--Add 20130306 V1.00 SCSK D.Sugahara Start
    cv_doc_type_porc            CONSTANT  VARCHAR2(10)   :=  'PORC'; --�����^�C�v�F���
    cv_doc_source_rma           CONSTANT  VARCHAR2(10)   :=  'RMA';  --�\�[�X�����^�C�v�F�ԕi��
--Add 20130306 V1.00 SCSK D.Sugahara End
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf                           VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode                          VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg                           VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
    ln_purge_set_count                  NUMBER DEFAULT 0; --�p�[�W���e�[�u���ɏ����o���ꂽ����
    ln_purge_target_count               NUMBER DEFAULT 0; --�ΏۂƂȂ郌�R�[�h����
    ln_purge_update_count               NUMBER DEFAULT 0; --�ΏۂƂȂ郌�R�[�h����
    ld_std_syukko_date                  DATE;   --��o�ɓ�
    ld_purge_set_del_std_date           DATE;   --�p�[�W�Z�b�g�폜���
    ln_purge_set_upd_yet                NUMBER DEFAULT 0; --���X�V�w�b�_ID����

    TYPE l_header_id_ttype IS TABLE OF xxcmn_order_headers_all_arc.header_id%TYPE;
    l_header_id_tab l_header_id_ttype;

    TYPE l_purge_set_header_id_ttype IS TABLE OF oe_purge_orders.header_id%TYPE  INDEX BY BINARY_INTEGER;
    l_purge_set_header_id_tab l_purge_set_header_id_ttype;

    l_purge_set_lock_id_tab l_purge_set_header_id_ttype;

    TYPE l_del_purge_set_id_ttype IS TABLE OF oe_purge_sets.purge_set_id%TYPE;
    l_del_purge_set_id_tab l_del_purge_set_id_ttype;

  BEGIN
    ov_retcode := cv_status_normal;
    --*********************************************************************************
    --�p�[�W�Z�b�g�e�[�u���A�p�[�W���e�[�u����̌Â����R�[�h���폜
    --*********************************************************************************
    --���R�[�h�폜������t�i�폜����j�����߂�
    --ld_�p�[�W�Z�b�g�폜��� := gd_������ - gn_�p�[�W�Z�b�g�폜����;
    ld_purge_set_del_std_date := gd_syori_date - gn_purgeset_del_period;
--
    --�폜�ΏۂƂ���p�[�W�Z�b�gID���擾
    /*
    SELECT
        purge_set_id
    BULK COLLECT
    INTO
        l_del_purge_set_id_tab
    FROM
        �p�[�W�Z�b�g�e�[�u��,
        �p�[�W���e�[�u��
    WHERE
        �p�[�W���e�[�u���D�p�[�W�Z�b�gID = �p�[�W�Z�b�g�e�[�u���D�p�[�W�Z�b�gID
        �p�[�W���e�[�u���D�ŏI�X�V�� < ln_�p�[�W�Z�b�g�폜���;
    FOR UPDATE NOWAIT;
    */
    SELECT
        ops.purge_set_id AS purge_set_id
    BULK COLLECT
    INTO
        l_del_purge_set_id_tab
    FROM
        oe_purge_sets   ops,
        oe_purge_orders opo   --�p�[�W���e�[�u�����폜���邽�߃��b�N�ΏۂɊ܂߂�
    WHERE
          ops.purge_set_id = opo.purge_set_id
      AND ops.last_update_date < ld_purge_set_del_std_date
    FOR UPDATE NOWAIT;
--
    --�p�[�W���e�[�u���폜
    /*
    FORALL i IN 1 .. v_purge_set_id.count 
      DELETE FROM
          oe_purge_orders
      WHERE
          purge_set_id = l_del_purge_set_id_tab(i);
    */
    FORALL i IN 1 .. l_del_purge_set_id_tab.COUNT 
      DELETE
      FROM
          oe_purge_orders
      WHERE
          purge_set_id = l_del_purge_set_id_tab(i);
--
    --�p�[�W�Z�b�g�e�[�u���폜
    /*
    FORALL i IN 1 .. v_purge_set_id.count 
      DELETE FROM
          oe_purge_sets
      WHERE
          purge_set_id = l_del_purge_set_id_tab(i);
    */
    FORALL i IN 1 .. l_del_purge_set_id_tab.COUNT 
      DELETE
      FROM
          oe_purge_sets
      WHERE
          purge_set_id = l_del_purge_set_id_tab(i);
--
    --*********************************************************************************
    --�󒍃p�[�W�e�[�u���ɏo�͂��ꂽ�f�[�^�̓K�i����x"N"�ɍX�V����
    --*********************************************************************************
--
    /*
    �p�[�W���e�[�u���ŏ����ΏۂƂȂ�p�[�W�Z�b�gID�̃��R�[�h�����b�N
    SELECT
      �w�b�_ID
    BULK COLLECT
    INTO
        l_purge_set_header_id_tab
    FROM
      �󒍃p�[�W���e�[�u��
    WHERE
      �p�[�W�Z�b�gID = in_�p�[�W�Z�b�gID
    FOR UPDATE NOWAIT;
    */
    SELECT
      opo.header_id       AS header_id
    BULK COLLECT
    INTO
        l_purge_set_lock_id_tab
    FROM
      oe_purge_orders        opo
    WHERE
      opo.purge_set_id = in_purge_set_id
    FOR UPDATE NOWAIT;
--
    /*
    UPDATE �p�[�W���e�[�u��
    SET    �K�i='Y'
    WHERE  �p�[�W�Z�b�gID = �p�[�W�Z�b�g�쐬�ō쐬���ꂽ�p�[�W�Z�b�gID
    */
    UPDATE
      oe_purge_orders --�p�[�W���e�[�u��
    SET
       is_purgable            = cv_is_purgable_n          --�K�i
      ,last_update_date       = cd_last_update_date       --WHO�J����
      ,last_updated_by        = cn_last_updated_by        --WHO�J���� 
      ,last_update_logon      = cn_last_update_login      --WHO�J����
      ,program_application_id = cn_program_application_id --WHO�J����
      ,program_id             = cn_program_id             --WHO�J����
      ,program_update_date    = cd_program_update_date    --WHO�J����
    WHERE
        purge_set_id = in_purge_set_id; --�쐬���ꂽ�p�[�W�Z�b�gID�őS�����X�V
--
    --�X�V�������擾�i���o�͌����Ɠ����j
    gn_purgeset_cnt := SQL%ROWCOUNT;

    /*
    ������0���̏ꍇ�͏����I��
    IF gn_�Ώی��� = 0 THEN
      �I������
    END IF;
    */
    IF ( gn_purgeset_cnt = 0 ) THEN
      on_purge_target_count := 0;
      RETURN;
    END IF;
--
    --��o�ɓ������߂�
    --ld_��o�ɓ� := gd_������ - gn_�p�[�W����;
    ld_std_syukko_date := gd_syori_date - gn_purge_range;
--
    --*********************************************************************************
    --�󒍃w�b�_�A�h�I���e�[�u���Ǝ󒍃p�[�W�e�[�u������A�Ώۂ̎󒍃w�b�_ID�𓱏o
    --*********************************************************************************
    /*
    SELECT.
          HEADER_ID
    BULK COLLECT
    INTO   l_header_id_tab
    FROM (
    SELECT
          OHAB.HEADER_ID
    FROM
          �󒍃w�b�_�A�h�I���e�[�u��(BK) OHAB,
          OE_ORDER_HEADERS_ALL OOHA,
          OE_PURGE_ORDERS OPO
    WHERE
          OOHA.�c�ƒP�� = ln_�c�ƒP��
      AND OHAB.���ד�< id_��o�ɓ�
      AND OHAB.���ד� >= id_��o�ɓ� - ln_�p�[�W�����W����
      AND OHAB.�X�e�[�^�X IN ('04','08')
      AND OOHA.HEADER_ID = OPO.HEADER_ID
      AND OHAB.HEADER_ID = OOHA.HEADER_ID
--Add 20130306 V1.00 SCSK D.Sugahara Start
      AND  NOT EXISTS (
                SELECT  1 
                FROM     �ۗ��݌Ƀg����  itp  
                        ,�������    rsl
                        ,����w�b�_  rsh
                WHERE  itp.doc_type             = 'PORC'
                AND    rsh.shipment_header_id   = itp.doc_id
                AND    rsl.shipment_header_id   = rsh.shipment_header_id
                AND    rsl.line_num             = itp.doc_line
                AND    rsl.source_document_code = 'RMA'
                AND    rsl.oe_order_header_id   = xoohaa.header_id
                AND    ROWNUM                   = 1
              )
      AND  NOT EXISTS (
                SELECT  1
                FROM     �����݌Ƀg����  itc  
                        ,�������    rsl
                        ,����w�b�_  rsh
                WHERE  itc.doc_type             = 'PORC'
                AND    rsh.shipment_header_id   = itc.doc_id
                AND    rsl.shipment_header_id   = rsh.shipment_header_id
                AND    rsl.line_num             = itc.doc_line
                AND    rsl.source_document_code = 'RMA'
                AND    rsl.oe_order_header_id   = xoohaa.header_id
                AND    ROWNUM                   = 1
              )
--Add 20130306 V1.00 SCSK D.Sugahara End
    );
    */
    SELECT
          header_id AS header_id
    BULK COLLECT
    INTO  l_header_id_tab
    FROM (
--Mod 20130306 V1.00 SCSK D.Sugahara Start   
--�ۑ�23�Ή� �q���g��C��
      SELECT /*+ LEADING( xohaa xoohaa opo ) 
              USE_NL( xohaa xoohaa opo ) 
              INDEX( xohaa XXCMN_OHAA_N15 ) 
              INDEX( xoohaa XXCMN_OE_ORDER_H_ALL_ARC_PK ) 
              */
--Mod 20130306 V1.00 SCSK D.Sugahara End
            xohaa.header_id AS header_id
      FROM
            xxcmn_order_headers_all_arc xohaa,                --�󒍃w�b�_�i�A�h�I���j�o�b�N�A�b�v
            xxcmn_oe_order_headers_all_arc xoohaa,            --�󒍃w�b�_�i�W���j�o�b�N�A�b�v
            oe_purge_orders opo                               --�p�[�W���
      WHERE
            opo.purge_set_id = in_purge_set_id
        AND xoohaa.org_id = gn_org_id                         --�󒍃w�b�_�i�W���j�o�b�N�A�b�v�̉c�ƒP��=�v���t�@�C���l
        AND xohaa.arrival_date <  ld_std_syukko_date          --�󒍃w�b�_�i�A�h�I���j�o�b�N�A�b�v�̒��ד��𔻒�
        AND xohaa.arrival_date >= ld_std_syukko_date - gn_purge_range_day
        AND xohaa.req_status IN (
                                cv_status_wsh_keijozumi,      --04:�o�׎��ьv���
                                cv_status_po_keijozumi )      --08:�o�׎��ьv���
        AND xoohaa.header_id = opo.header_id                  --�󒍃w�b�_�i�W���j�o�b�N�A�b�v�Ƀf�[�^�����݂���
        AND xohaa.header_id = xoohaa.header_id                --�󒍃w�b�_�i�A�h�I���j�o�b�N�A�b�v�Ƀf�[�^�����݂���
--Add 20130306 V1.00 SCSK D.Sugahara Start   
--�ۗ��݌Ƀg�����A�����݌Ƀg������PROC(RMA)�����݂���ꍇ�͑ΏۊO�Ƃ��������ǉ�
--�ۑ�23�Ή�
        AND  NOT EXISTS (
                  SELECT  1 
                            /*+ LEADING(rsl rsh itp) USE_NL(rsl rsh itp) 
                                INDEX( rsl RCV_SHIPMENT_LINES_U2 )
                                INDEX( itp IC_TRAN_PNDI2 ) 
                            */
                  FROM     ic_tran_pnd  itp  --OPM�ۗ��݌Ƀg�����U�N�V����(�W��)
                          ,rcv_shipment_lines    rsl
                          ,rcv_shipment_headers  rsh
                  WHERE  itp.doc_type             = cv_doc_type_porc
                  AND    rsh.shipment_header_id   = itp.doc_id
                  AND    rsl.shipment_header_id   = rsh.shipment_header_id
                  AND    rsl.line_num             = itp.doc_line
                  AND    rsl.source_document_code = cv_doc_source_rma
                  AND    rsl.oe_order_header_id   = xoohaa.header_id
                  AND    ROWNUM                   = 1
                )
        AND  NOT EXISTS (
                  SELECT  1
                            /*+ LEADING(rsl rsh itc) USE_NL(rsl rsh itc) 
                                INDEX( rsl RCV_SHIPMENT_LINES_U2 )
                                INDEX( itc IC_TRAN_CMPI2 ) 
                            */
                  FROM     ic_tran_cmp  itc  --OPM�����݌Ƀg�����U�N�V����(�W��)
                          ,rcv_shipment_lines    rsl
                          ,rcv_shipment_headers  rsh
                  WHERE  itc.doc_type             = cv_doc_type_porc
                  AND    rsh.shipment_header_id   = itc.doc_id
                  AND    rsl.shipment_header_id   = rsh.shipment_header_id
                  AND    rsl.line_num             = itc.doc_line
                  AND    rsl.source_document_code = cv_doc_source_rma
                  AND    rsl.oe_order_header_id   = xoohaa.header_id
                  AND    ROWNUM                   = 1
                )
--Add 20130306 V1.00 SCSK D.Sugahara End
    );
    --*********************************************************************************
    --���o���ʂ̌������擾
    --*********************************************************************************
    --ln_purge_target_count :=l_�����ΏۃJ�[�\���w�b�_ID_tab.count;
    ln_purge_target_count := l_header_id_tab.COUNT;
    /*
    �p�[�W�Ώۃf�[�^�����݂����ꍇ(ln_purge_target_count > 0 ) �́A
    ���̑Ώۃf�[�^�ɑ΂��āu�K�i�v='Y'�̍X�V�����s����B
    */
    IF ( ln_purge_target_count ) > 0 THEN
      << purge_set_update_loop >>
      /*
      << purge_set_update_loop >>
      FOR ln_main_idx in 1 .. l_�����ΏۃJ�[�\���w�b�_ID_tab.COUNT
      LOOP
      */
      FOR ln_main_idx in 1 .. l_header_id_tab.COUNT
      LOOP
        -- ===============================================
        -- �����R�~�b�g
        -- ===============================================
        /*
          NVL(gn_�����R�~�b�g��, 0) <> 0�̏ꍇ
        */
        IF ( NVL(gn_commit_range, 0) <> 0 ) THEN
          /*
            ln_���R�~�b�g�X�V�����i�p�[�W�Z�b�g�j > 0
            ���� MOD(ln_���X�V�p�[�W��񌏐�, gn_�����R�~�b�g��) = 0�̏ꍇ
          */
          IF (  (ln_purge_set_upd_yet > 0)
            AND (MOD(ln_purge_set_upd_yet, gn_commit_range) = 0)
             )
          THEN
            /*
            �R�~�b�g�����W�ɒB�����̂�l_�����Ώۃw�b�_ID_tab�̓��e�ňꊇUPDATE����
            FORALL ln_idx IN 1..ln_���X�V�p�[�W��񌏐�
              UPDATE
                �p�[�W���e�[�u�� 
              SET
                �K�i = 'Y'
                �eWHO�J�����X�V
              WHERE
                    �p�[�W�Z�b�gID = �D�Ŏ擾�����������̃p�[�W�Z�b�gID
                AND �p�[�W�� = 'N'
                AND header_id = l_�����Ώۃw�b�_ID_tab(ln_idx);
            */
            BEGIN
              FORALL ln_idx IN 1..ln_purge_set_upd_yet
                UPDATE
                  oe_purge_orders 
                SET
                   is_purgable            = cv_is_purgable_y          --�u�K�i�v��'Y'�ɍX�V
                  ,last_update_date       = cd_last_update_date       --WHO�J����
                  ,last_updated_by        = cn_last_updated_by        --WHO�J����
                  ,last_update_logon      = cn_last_update_login      --WHO�J����
                  ,program_application_id = cn_program_application_id --WHO�J����
                  ,program_id             = cn_program_id             --WHO�J����
                  ,program_update_date    = cd_program_update_date    --WHO�J����
                WHERE
                      purge_set_id = in_purge_set_id                  --�Ώۂɂ��Ă���p�[�W�Z�b�gID�ł���
                  AND NVL(is_purged,cv_is_purged_n) = cv_is_purged_n  --�p�[�W����Ă��Ȃ�
                  AND header_id = l_purge_set_header_id_tab(ln_idx);            --�ΏۂƂȂ����󒍃w�b�_ID�ł���
            EXCEPTION
              WHEN OTHERS THEN
                RAISE local_process_expt;
            END;
--
            /*
            ���팏����UPDATE�ōX�V�������������Z
            gn_�Ώی��� := gn_�Ώی��� + SQL%ROWCOUNT;
            ln_���X�V�p�[�W��񌏐� := 0;
            COMMIT;
            */
            gn_target_cnt := gn_target_cnt + SQL%ROWCOUNT;
            ln_purge_set_upd_yet := 0;
            COMMIT;
            /*
            �R�~�b�g�����W����UPDATE�����������̂ŁA�R���N�V������������
            l_�����Ώۃw�b�_ID.DELETE;
            */
            l_purge_set_header_id_tab.DELETE;
--
            /*
            �R�~�b�g�������ƂŃ��b�N���O��邽�߁A�p�[�W�Z�b�gID�P�ʂōēx���b�N��������
            l_�����Ώۃw�b�_ID.DELETE;
            SELECT
              �w�b�_ID
            BULK COLLECT
            INTO
              l_���b�N���p�[�W�Z�b�gID_tab
            FROM
              �p�[�W���e�[�u��
            WHERE
              �p�[�W�Z�b�gID = �D�Ŏ擾�����������̃p�[�W�Z�b�gID
            FOR UPDATE NOWAIT;
            */
            l_purge_set_lock_id_tab.DELETE;
 
            SELECT
              opo.header_id AS header_id
            BULK COLLECT
            INTO
              l_purge_set_lock_id_tab
            FROM
              oe_purge_orders opo
            WHERE
              opo.purge_set_id = in_purge_set_id
            FOR UPDATE NOWAIT;
          END IF;
        END IF;
        
        /*
        ln_���X�V�p�[�W��񌏐���1���Z����B
        --
        l_�����Ώۃw�b�_ID(ln_���X�V�p�[�W��񌏐�) := l_�����ΏۃJ�[�\���w�b�_ID(ln_main_idx);
        END LOOP purge_set_update_loop;
        */
        ln_purge_set_upd_yet := ln_purge_set_upd_yet + 1;
        l_purge_set_header_id_tab(ln_purge_set_upd_yet) := l_header_id_tab(ln_main_idx);
      END LOOP purge_set_update_loop;
--
      /*
      �R�~�b�g����Ă��Ȃ��c��̏����Ώۃw�b�_ID���X�V����
      FORALL ln_idx IN 1..ln_���X�V�p�[�W��񌏐�
        UPDATE
          �p�[�W���e�[�u�� 
        SET
          �K�i = 'Y'
          �eWHO�J�����X�V
        WHERE
              �p�[�W�Z�b�gID = �D�Ŏ擾�����������̃p�[�W�Z�b�gID
          AND �p�[�W�� = 'N'
          AND header_id = l_�����Ώۃw�b�_ID_tab(ln_idx);
      */
      BEGIN
        FORALL ln_idx IN 1..ln_purge_set_upd_yet
          UPDATE
            oe_purge_orders 
          SET
             is_purgable            = cv_is_purgable_y          --�u�K�i�v��'Y'�ɍX�V
            ,last_update_date       = cd_last_update_date       --WHO�J����
            ,last_updated_by        = cn_last_updated_by        --WHO�J����
            ,last_update_logon      = cn_last_update_login      --WHO�J����
            ,program_application_id = cn_program_application_id --WHO�J����
            ,program_id             = cn_program_id             --WHO�J����
            ,program_update_date    = cd_program_update_date    --WHO�J����
          WHERE
                purge_set_id = in_purge_set_id                  --�Ώۂɂ��Ă���p�[�W�Z�b�gID�ł���
            AND NVL(is_purged,cv_is_purged_n) = cv_is_purged_n  --�p�[�W����Ă��Ȃ�
            AND header_id = l_purge_set_header_id_tab(ln_idx);            --�ΏۂƂȂ����󒍃w�b�_ID�ł���
      EXCEPTION
        WHEN OTHERS THEN
          RAISE local_process_expt;
      END;
      /*
      ���팏����UPDATE�ōX�V�������������Z
      gn_�Ώی��� := gn_�Ώی��� + SQL%ROWCOUNT;
      */
      gn_target_cnt := gn_target_cnt + SQL%ROWCOUNT;
    END IF;
    on_purge_target_count := gn_target_cnt;
--
  EXCEPTION
    WHEN local_process_expt THEN
      ov_errmsg := xxcmn_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_local_others_msg
                    ,iv_token_name1  => cv_token_key
                    ,iv_token_value1 => TO_CHAR(in_purge_set_id) || ':' ||
                                                l_purge_set_header_id_tab(SQL%BULK_EXCEPTIONS(1).ERROR_INDEX)
                   );
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_pkg_name||cv_msg_part||SQLERRM;
      gn_warning_cnt := gn_warning_cnt + 1;
      ov_retcode := cv_status_error;
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
      ROLLBACK;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errmsg := xxcmn_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_local_others_msg
                    ,iv_token_name1  => cv_token_key
                    ,iv_token_value1 => TO_CHAR(in_purge_set_id)
                   );
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_pkg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
  END updpurgeorder;
--
  /**********************************************************************************
   * Procedure Name   : purgerorder
   * Description      : �p�[�W���s
   **********************************************************************************/
  PROCEDURE purgerorder(
    in_purge_set_id IN  NUMBER,       -- 1.�p�[�W�Z�b�gID(���̒l�������ΏۂƂȂ�)
    ov_errbuf       OUT VARCHAR2,     --   �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode      OUT VARCHAR2,     --   ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg       OUT VARCHAR2      --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  )
--
--
--###########################  �Œ蕔 START   ###########################
--
  IS
    cv_prg_name                 CONSTANT VARCHAR2(100) := 'purgerorder';             -- �v���O������

    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf                   VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode                  VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg                   VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_purge_err_cnt            NUMBER;
--
    --FND_REQUEST.SUBMIT_REQUEST�Ŏg�p����ϐ�
    lv_phase                    VARCHAR2(100);
    lv_status                   VARCHAR2(100);
    lv_dev_phase                VARCHAR2(100);
    lv_dev_status               VARCHAR2(100);
    ln_request_id               NUMBER;          -- �q�R���J�����g�̗v��ID

    --*********************************************************************************
    --�p�[�W���ʃ��R�[�h�擾�p�J�[�\��
    --*********************************************************************************
    /*
    CURSOR �p�[�W���G���[_cur(
      �p�[�W�Z�b�gID            NUMBER
    )
    IS
    SELECT
    �@�@�w�b�_ID
    �@�@�󒍔ԍ�
    �@�@�G���[�e�L�X�g
    FROM
      �p�[�W���e�[�u��
    WHERE
          �p�[�W�Z�b�gID = in_purge_set_id
      AND �p�[�W�K�i = 'Y'
      AND �p�[�W�� = 'N';
    */
    CURSOR purge_order_error_cur(
      in_purge_set_id            NUMBER
    )
    IS
      SELECT
        opo.header_id     AS header_id,
        opo.order_number  AS order_number,
        opo.error_text    AS error_text
      FROM
        oe_purge_orders   opo
      WHERE
            opo.purge_set_id = in_purge_set_id
        AND NVL(opo.is_purgable,cv_is_purgable_n) = cv_is_purgable_y  --�p�[�W�K�i�iY=�p�[�W�Ώہj
        AND NVL(opo.is_purged,cv_is_purged_n)     = cv_is_purged_n    --�p�[�W�σt���O(Y=�p�[�W��)
    ;
  BEGIN
    ov_retcode := cv_status_normal;
    lv_purge_err_cnt := 0;
    FND_FILE.PUT_LINE (FND_FILE.LOG, '�p�[�W�E�Z�b�gID:' || TO_CHAR(in_purge_set_id));
    --*********************************************************************************
    --�p�[�W�Z�b�gID����ɁA�v���̔��s�@�u�󒍃p�[�W(ORDPUR)�v�@�����{����B
    --*********************************************************************************
    ln_request_id := FND_REQUEST.SUBMIT_REQUEST(
                       application       => cv_child_app_short_name   --�A�v���P�[�V�����Z�k��
                     , program           => cv_child_pgm_ordpur       --�v���O������
                     , argument1         => in_purge_set_id           --�p�[�W�E�Z�b�gID
                       );
    -- �R���J�����g�N�����s�̏ꍇ�̓G���[����
    IF ( NVL(ln_request_id, 0) = 0 ) THEN
      ov_errmsg := xxcmn_common_pkg.get_msg(
                     iv_application   => cv_appl_short_name
                    ,iv_name          => cv_msg_xxcmn10135);
      RAISE global_api_others_expt;
    ELSE
      COMMIT;
    END IF;

    --*********************************************************************************
    --���s���ꂽ�R���J�����g�̏I���`�F�b�N
    --*********************************************************************************
    IF ( FND_CONCURRENT.WAIT_FOR_REQUEST(
           request_id => ln_request_id
          ,interval   => 1
          ,max_wait   => 0
          ,phase      => lv_phase
          ,status     => lv_status
          ,dev_phase  => lv_dev_phase
          ,dev_status => lv_dev_status
          ,message    => ov_errbuf
          ) ) THEN
      -- �X�e�[�^�X���f
--
      -- �t�F�[�Y:����
      IF ( lv_dev_phase = cv_conc_p_c ) THEN
--
        /*
            -- �X�e�[�^�X:�ُ�
          lv_dev_status��'ERROR','CANCELLED','TERMINATED'�̏ꍇ�̓G���[�I��
        �@�@�@�@�X�e�[�^�X���G���[�ɂ��ďI��
          lv_dev_status��'WARNING'�̏ꍇ�͌x���I��
        �@�@�@�@�X�e�[�^�X���x���ɂ���

          lv_dev_status��'NORMAL'�̏ꍇ�͐��폈�����s

          lv_dev_status����L�ȊO�̏ꍇ�̓G���[�I��
        �@�@�@�@�X�e�[�^�X���G���[�ɂ��ďI��
        */
        --�X�e�[�^�X�R�[�h�ɂ��󋵔���
        CASE lv_dev_status
          --�G���[
          WHEN cv_conc_s_e THEN
            ov_errmsg := xxcmn_common_pkg.get_msg(
                           iv_application  => cv_appl_short_name
                          ,iv_name         => cv_request_err_msg
                          ,iv_token_name1  => cv_request_err_token
                          ,iv_token_value1 => cv_child_pgm_ordpur
                         );
            RAISE global_api_others_expt;

          --�L�����Z��
          WHEN cv_conc_s_c THEN
            ov_errmsg := xxcmn_common_pkg.get_msg(
                           iv_application  => cv_appl_short_name
                          ,iv_name         => cv_request_err_msg
                          ,iv_token_name1  => cv_request_err_token
                          ,iv_token_value1 => cv_child_pgm_ordpur
                         );
            RAISE global_api_others_expt;

          --�����I��
          WHEN cv_conc_s_t THEN
            ov_errmsg := xxcmn_common_pkg.get_msg(
                           iv_application  => cv_appl_short_name
                          ,iv_name         => cv_request_err_msg
                          ,iv_token_name1  => cv_request_err_token
                          ,iv_token_value1 => cv_child_pgm_ordpur
                         );
            RAISE global_api_others_expt;

          --�x���I��
          WHEN cv_conc_s_w THEN
            --���܂Ő���̏ꍇ�̂݌x���X�e�[�^�X
            IF ( ov_retcode < 1 ) THEN
              ov_retcode := cv_status_warn;
            END IF;
 
          --����I��
          WHEN cv_conc_s_n THEN
              NULL;

          --���̒l�͗�O����
          ELSE
            ov_errmsg := xxcmn_common_pkg.get_msg(
                           iv_application  => cv_appl_short_name
                          ,iv_name         => cv_request_err_msg
                          ,iv_token_name1  => cv_request_err_token
                          ,iv_token_value1 => cv_child_pgm_ordpur
                         );
            RAISE global_api_others_expt;
        END CASE;

      --�����܂ŏ�����҂��A�����X�e�[�^�X�ł͂Ȃ������ꍇ�̗�O�n���h��
      ELSE
        ov_errmsg := xxcmn_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name
                      ,iv_name         => cv_request_err_msg
                      ,iv_token_name1  => cv_request_err_token
                      ,iv_token_value1 => cv_child_pgm_ordpur
                     );
        RAISE global_api_others_expt;
      END IF;
--
    --WAIT_FOR_REQUEST���ُ킾�����ꍇ�̗�O�n���h��
    ELSE
        ov_errmsg := xxcmn_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name
                      ,iv_name         => cv_request_err_msg
                      ,iv_token_name1  => cv_request_err_token
                      ,iv_token_value1 => cv_child_pgm_ordpur
                     );
        RAISE global_api_others_expt;
    END IF;

    --*********************************************************************************
    --�p�[�W���e�[�u������A�G���[�e�L�X�g���擾�����b�Z�[�W�ɏo��
    --*********************************************************************************
    /*
    << �p�[�W���G���[_loop >>
    FOR �p�[�W���G���[_rec IN �p�[�W���G���[_cur(
                          �������̃p�[�W�Z�b�gID
                         )
    LOOP
      �p�[�W���G���[���� := �p�[�W���G���[���� + 1;
      FND_FILE.PUT_LINE (FND_FILE.OUTPUT, '�󒍔ԍ�[' || �J�[�\���̎󒍔ԍ� || 
                                         ']:' || �J�[�\���̃G���[�e�L�X�g );
    END LOOP �p�[�W���G���[_loop;
    */
    << purge_order_error_loop >>
    FOR lr_purge_order_error_rec IN purge_order_error_cur(
                           in_purge_set_id
                         )
    LOOP
      lv_purge_err_cnt := lv_purge_err_cnt + 1;
      FND_FILE.PUT_LINE (FND_FILE.OUTPUT, '�󒍔ԍ�[' || TO_CHAR(lr_purge_order_error_rec.order_number) || 
                                          ']:'        || TO_CHAR(lr_purge_order_error_rec.error_text));
    END LOOP purge_order_error_loop;
    /*
    --�G���[�e�L�X�g���P�ȏ゠������X�e�[�^�X���x���ɂ���
    IF �p�[�W���G���[���� >0 THEN
      IF ( ov_retcode < 1 ) THEN
        ov_retcode := cv_status_warn;
      END IF;
    END IF;
    */
    IF ( lv_purge_err_cnt > 0 ) THEN
      IF ( ov_retcode < 1 ) THEN
        ov_retcode := cv_status_warn;
      END IF;
    END IF;

    /*
    --���������̎擾
        gn_�x������ := lv_�p�[�W�G���[����;
        gn_���팏�� := gn_�Ώی��� - gn_�x������;
    */
    gn_warning_cnt := lv_purge_err_cnt;
    gn_normal_cnt := gn_target_cnt - gn_warning_cnt;
--
  EXCEPTION
    WHEN local_process_expt THEN
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
      ROLLBACK;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errmsg := xxcmn_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_local_others_msg
                    ,iv_token_name1  => cv_token_key
                    ,iv_token_value1 => TO_CHAR(in_purge_set_id)
                   );
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;

  END purgerorder;

  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
--
--#####################  �Œ胍�[�J���萔�ϐ��錾�� START   ####################
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name                   CONSTANT VARCHAR2(100) := 'submain'; -- �v���O������
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf                     VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode                    VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg                     VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    --�v���t�@�C���l�擾�p�L�[
    cv_xxcmn_purge_range_fix      CONSTANT VARCHAR2(100) := 'XXCMN_PURGE_RANGE_FIX';      --�p�[�W���ԕ␳
    cv_xxcmn_purge_range          CONSTANT VARCHAR2(100) := 'XXCMN_PURGE_RANGE';          --�p�[�W�����W
    cv_xxcmn_purgeset_del_period  CONSTANT VARCHAR2(100) := 'XXCMN_PURGESET_DEL_PERIOD';  --�p�[�W�Z�b�g�폜����
    cv_xxcmn_pre_purge_set_name   CONSTANT VARCHAR2(100) := 'XXCMN_PURGESET_NAME_PREFIX'; --�p�[�W�Z�b�g���̐擪������
    cv_xxcmn_purgeset_from_day    CONSTANT VARCHAR2(100) := 'XXCMN_PURGESET_FROM_DAY';    --�p�[�W�Z�b�g�쐬��From������-�p�[�W�����W�܂ł̓���
    cv_xxcmn_commit_range         CONSTANT VARCHAR2(100) := 'XXCMN_COMMIT_RANGE';         --XXCMN:�����R�~�b�g��
    cv_xxcmn_org_id               CONSTANT VARCHAR2(100) := 'ORG_ID';                     --�c�ƒP��
    cv_purge_type                 CONSTANT VARCHAR2(1)   := '0';                          --�p�[�W�^�C�v�i0:�p�[�W�������ԁj
    cv_purge_code                 CONSTANT VARCHAR2(30)  := '9601';                       --�p�[�W��`�R�[�h
--
    --���b�Z�[�W
    cv_get_profile_msg            CONSTANT VARCHAR2(100) := 'APP-XXCMN-10002';  -- �v���t�@�C��[ ��NG_PROFILE ]�̎擾�Ɏ��s���܂����B
    cv_token_profile              CONSTANT VARCHAR2(100) := 'NG_PROFILE';
    cv_get_period_msg             CONSTANT VARCHAR2(100) := 'APP-XXCMN-11011';  -- �p�[�W���Ԃ̎擾�Ɏ��s���܂����B
--
    -- *** ���[�J���ϐ� ***
    ln_purge_set_id               NUMBER;          --�p�[�W�Z�b�gID
    ln_purge_target_count         NUMBER;           --�����Ώی���
--
  BEGIN
--
    -- �O���[�o���ϐ��̏�����
    gn_purgeset_cnt := 0;
    gn_target_cnt   := 0;
    gn_normal_cnt   := 0;
    gn_warning_cnt  := 0;
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
--
    --*********************************************
    --***      MD.050�̃t���[�}��\��           ***
    --***      ����Ə������̌Ăяo�����s��     ***
    --*********************************************
--
    --*********************************************************************************
    --�l�̎擾�A��`
    --*********************************************************************************
    --(1)���������擾����B
    --ld_������ := �������擾���ʊ֐�;
    gd_syori_date := xxcmn_common4_pkg.get_syori_date;
    IF ( gd_syori_date IS NULL ) THEN
      ov_retcode := cv_status_error;
      RAISE local_process_expt;
    END IF;
--
    --(2)�p�[�W���Ԃ����b�N�A�b�v���擾����B
    --gn_�p�[�W���� := �p�[�W���Ԏ擾���ʊ֐�(cv_�p�[�W��`�R�[�h);
    gn_purge_range          := xxcmn_common4_pkg.get_purge_period(cv_purge_type, cv_purge_code);
    IF ( gn_purge_range IS NULL ) THEN
      ov_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name
                      ,iv_name         => cv_get_period_msg
                     );
      ov_retcode := cv_status_error;
      RAISE local_process_expt;
    END IF;
--
    --gn_�R�~�b�g�����W := �v���t�@�C�����擾;
    BEGIN
      gn_commit_range  := TO_NUMBER(fnd_profile.value(cv_xxcmn_commit_range));
      IF ( gn_commit_range IS NULL ) THEN
--
        ov_errmsg := xxcmn_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name
                      ,iv_name         => cv_get_profile_msg
                      ,iv_token_name1  => cv_token_profile
                      ,iv_token_value1 => cv_xxcmn_commit_range
                     );
        ov_retcode := cv_status_error;
        RAISE local_process_expt;
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        ov_errmsg := xxcmn_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name
                      ,iv_name         => cv_get_profile_msg
                      ,iv_token_name1  => cv_token_profile
                      ,iv_token_value1 => cv_xxcmn_commit_range
                     );
        ov_retcode := cv_status_error;
        RAISE local_process_expt;
    END;
    FND_FILE.PUT_LINE (FND_FILE.LOG, '�����R�~�b�g��:' || TO_CHAR(gn_commit_range));
--
    --ln_�p�[�W���ԕ␳ := �v���t�@�C�����擾;
    BEGIN
      gn_purge_range_fix      := TO_NUMBER(fnd_profile.value(cv_xxcmn_purge_range_fix));
      IF ( gn_purge_range_fix IS NULL ) THEN
        ov_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appl_short_name
                        ,iv_name         => cv_get_profile_msg
                        ,iv_token_name1  => cv_token_profile
                        ,iv_token_value1 => cv_xxcmn_purge_range_fix
                       );
        ov_retcode := cv_status_error;
        RAISE local_process_expt;
      END IF;
    EXCEPTION
      --���l�łȂ������ꍇ�ATO_NUMBER�̃G���[���L���b�`���ăG���[���b�Z�[�W�ݒ�
      WHEN OTHERS THEN
        ov_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appl_short_name
                        ,iv_name         => cv_get_profile_msg
                        ,iv_token_name1  => cv_token_profile
                        ,iv_token_value1 => cv_xxcmn_purge_range_fix
                       );
        ov_retcode := cv_status_error;
        RAISE local_process_expt;
    END;
    FND_FILE.PUT_LINE (FND_FILE.LOG, '�p�[�W���ԕ␳:' || TO_CHAR(gn_purge_range_fix));
--
    --ln_�p�[�W�����W := �v���t�@�C�����擾;
    BEGIN
      gn_purge_range_day      := TO_NUMBER(fnd_profile.value(cv_xxcmn_purge_range));
      IF ( gn_purge_range_day IS NULL ) THEN
        ov_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appl_short_name
                        ,iv_name         => cv_get_profile_msg
                        ,iv_token_name1  => cv_token_profile
                        ,iv_token_value1 => cv_xxcmn_purge_range
                       );
        ov_retcode := cv_status_error;
        RAISE local_process_expt;
      END IF;
    EXCEPTION
      --���l�łȂ������ꍇ�ATO_NUMBER�̃G���[���L���b�`���ăG���[���b�Z�[�W�ݒ�
      WHEN OTHERS THEN
        ov_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appl_short_name
                        ,iv_name         => cv_get_profile_msg
                        ,iv_token_name1  => cv_token_profile
                        ,iv_token_value1 => cv_xxcmn_purge_range
                       );
        ov_retcode := cv_status_error;
        RAISE local_process_expt;
    END;
    FND_FILE.PUT_LINE (FND_FILE.LOG, '�p�[�W�����W:' || TO_CHAR(gn_purge_range_day));
--
    --ln_�p�[�W�Z�b�g�폜���� := �v���t�@�C�����擾;
    BEGIN
      gn_purgeset_del_period  := TO_NUMBER(fnd_profile.value(cv_xxcmn_purgeset_del_period));
      IF ( gn_purgeset_del_period IS NULL ) THEN
        ov_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appl_short_name
                        ,iv_name         => cv_get_profile_msg
                        ,iv_token_name1  => cv_token_profile
                        ,iv_token_value1 => cv_xxcmn_purgeset_del_period
                       );
        ov_retcode := cv_status_error;
        RAISE local_process_expt;
      END IF;
    EXCEPTION
      --���l�łȂ������ꍇ�ATO_NUMBER�̃G���[���L���b�`���ăG���[���b�Z�[�W�ݒ�
      WHEN OTHERS THEN
        ov_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appl_short_name
                        ,iv_name         => cv_get_profile_msg
                        ,iv_token_name1  => cv_token_profile
                        ,iv_token_value1 => cv_xxcmn_purgeset_del_period
                       );
        ov_retcode := cv_status_error;
        RAISE local_process_expt;
    END;
    FND_FILE.PUT_LINE (FND_FILE.LOG, '�p�[�W�Z�b�g�폜����:' || TO_CHAR(gn_purgeset_del_period));
--
    --gn_�p�[�W�Z�b�g�����J�n����       := TO_NUMBER(�v���t�@�C�����擾);
    BEGIN
      gn_purgeset_from_day  := TO_NUMBER(fnd_profile.value(cv_xxcmn_purgeset_from_day));
      IF ( gn_purgeset_from_day IS NULL ) THEN
        ov_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appl_short_name
                        ,iv_name         => cv_get_profile_msg
                        ,iv_token_name1  => cv_token_profile
                        ,iv_token_value1 => cv_xxcmn_purgeset_from_day
                       );
        ov_retcode := cv_status_error;
        RAISE local_process_expt;
      END IF;
    EXCEPTION
      --���l�łȂ������ꍇ�ATO_NUMBER�̃G���[���L���b�`���ăG���[���b�Z�[�W�ݒ�
      WHEN OTHERS THEN
        ov_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appl_short_name
                        ,iv_name         => cv_get_profile_msg
                        ,iv_token_name1  => cv_token_profile
                        ,iv_token_value1 => cv_xxcmn_purgeset_from_day
                       );
        ov_retcode := cv_status_error;
        RAISE local_process_expt;
    END;
    FND_FILE.PUT_LINE (FND_FILE.LOG, '�p�[�W�Z�b�g�쐬�J�n����:' || TO_CHAR(gn_purgeset_from_day));

    --ln_�c�ƒP�� := �v���t�@�C�����擾;
    gn_org_id               := TO_NUMBER(fnd_profile.value(cv_xxcmn_org_id));
--
    --gv_�p�[�W�Z�b�g���ړ��� := �v���t�@�C�����擾;
    gv_pre_purge_set_name               := fnd_profile.value(cv_xxcmn_pre_purge_set_name);
    IF ( gv_pre_purge_set_name IS NULL ) THEN
      ov_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name
                      ,iv_name         => cv_get_profile_msg
                      ,iv_token_name1  => cv_token_profile
                      ,iv_token_value1 => cv_xxcmn_pre_purge_set_name
                     );
      ov_retcode := cv_status_error;
      RAISE local_process_expt;
    END IF;
--
    ln_purge_target_count := 0;
--
    -- ===============================
    -- <�p�[�W�Z�b�g�o�͏���>���Ăяo��
    -- ===============================
    genpurgeset(
      ln_purge_set_id,    --�p�[�W�Z�b�gID(�{�����ŃZ�b�g�����)
      lv_errbuf,          -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,         -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF ( lv_retcode = cv_status_error ) THEN
      --(�G���[����)
      ov_errmsg := lv_errmsg;
      ov_retcode := cv_status_error;
      RAISE local_process_expt;
    ELSIF ( lv_retcode = cv_status_warn ) THEN
      --�x������
      --submain�̏I���X�e�[�^�X(ov_retcode)�̃Z�b�g��
      --�G���[���b�Z�[�W���Z�b�g���郍�W�b�N�Ȃǂ��L�q���ĉ������B
      ov_errmsg := lv_errmsg;
      ov_retcode := cv_status_warn;
    ELSIF ( lv_retcode = cv_status_normal ) THEN
      --����I��
      NULL;
    ELSE
      --�ُ�Ȗ߂�l�̏ꍇ�̓G���[
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- <�p�[�W�Z�b�g�X�V����>���Ăяo��
    -- ===============================
    updpurgeorder(
      ln_purge_set_id,        --�p�[�W�Z�b�gID(�{�����Ŏg�p�����)
      ln_purge_target_count,  --�p�[�W�Ώی���(�{�����œK�i='Y'�ɂ����������߂�)
      lv_errbuf,              -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,             -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);             -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF ( lv_retcode = cv_status_error ) THEN
      --(�G���[����)
      ov_errmsg := lv_errmsg;
      ov_retcode := cv_status_error;
      RAISE local_process_expt;
    ELSIF ( lv_retcode = cv_status_warn ) THEN
      --�{�����Ɍx���X�e�[�^�X�͖����̂ŏ�������
      NULL;
    ELSIF ( lv_retcode = cv_status_normal ) THEN
      --����I��
      NULL;
    ELSE
      --�ُ�Ȗ߂�l�̏ꍇ�̓G���[
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- �u�K�i�v��'Y'�ɍX�V�����J�E���g���O�̏ꍇ��
    --  <�p�[�W���s����>���Ăяo��
    -- ===============================
    --�K�i='Y'�ɂ������R�[�h�����݂���ꍇ�̂ݖ{���������s����
    IF ( ln_purge_target_count > 0 ) THEN
      purgerorder(
        ln_purge_set_id,   --�p�[�W�Z�b�gID(�{�����ŃZ�b�g�����)
        lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
        lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
        lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
      IF ( lv_retcode = cv_status_error ) THEN
        --(�G���[����)
        ov_errmsg := lv_errmsg;
        ov_retcode := cv_status_error;
        RAISE local_process_expt;
      ELSIF ( lv_retcode = cv_status_warn ) THEN
        --�x���I����
        ov_retcode := cv_status_warn;
      ELSIF ( lv_retcode = cv_status_normal ) THEN
        --����I��
        NULL;
      ELSE
        --�ُ�Ȗ߂�l�̏ꍇ�̓G���[
        RAISE global_process_expt;
      END IF;
    END IF;
  EXCEPTION
      -- *** �C�ӂŗ�O�������L�q���� ****
    WHEN local_process_expt THEN
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      -- �J�[�\���̃N���[�Y�������ɋL�q����
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
    errbuf        OUT VARCHAR2,      --   �G���[�E���b�Z�[�W  --# �Œ� #
    retcode       OUT VARCHAR2       --   ���^�[���E�R�[�h    --# �Œ� #
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
    cv_normal_msg      CONSTANT VARCHAR2(100) := '����I��'; -- ����I�����b�Z�[�W
    cv_warn_msg        CONSTANT VARCHAR2(100) := '�x���I��'; -- �x���I�����b�Z�[�W
    cv_error_msg       CONSTANT VARCHAR2(100) := '�G���[�I��'; -- �G���[�I���S���[���o�b�N
--
    cv_cnt_msg          CONSTANT VARCHAR2(100) := 'APP-XXCMN-11040';             -- ��TBL_NAME ��SHORI �����F ��CNT ��
    cv_token_cnt        CONSTANT VARCHAR2(100) := 'CNT';                         -- �������b�Z�[�W�p�g�[�N�����i�����j
    cv_token_cnt_table  CONSTANT VARCHAR2(100) := 'TBL_NAME';                    -- �������b�Z�[�W�p�g�[�N�����i�e�[�u�����j
    cv_token_cnt_shori  CONSTANT VARCHAR2(100) := 'SHORI';                       -- �������b�Z�[�W�p�g�[�N�����i�������j
    cv_table_cnt_ooha   CONSTANT VARCHAR2(100) := '�󒍃w�b�_�i�W���j';                -- �������b�Z�[�W�p�e�[�u����
    cv_shori_cnt_del    CONSTANT VARCHAR2(100) := '�폜';                -- �������b�Z�[�W�p������
    cv_shori_cnt_target CONSTANT VARCHAR2(100) := '�Ώ�';                -- �������b�Z�[�W�p������
    cv_shori_cnt_normal CONSTANT VARCHAR2(100) := '����';                -- �������b�Z�[�W�p������
    cv_shori_cnt_error  CONSTANT VARCHAR2(100) := '���s';                -- �������b�Z�[�W�p������
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
    -- ===============================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ===============================================
    submain(
       lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    END IF;
    --��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    
    /*
    --�Ώی����o�́Fgn_�Ώی���
    --���������o�́Fgn_���팏��
    --�G���[�����o�́Fgn_�x������
    */
    --�Ώی����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_cnt_msg
                    ,iv_token_name1  => cv_token_cnt_table
                    ,iv_token_value1 => cv_table_cnt_ooha
                    ,iv_token_name2  => cv_token_cnt_shori
                    ,iv_token_value2 => cv_shori_cnt_del || cv_shori_cnt_target
                    ,iv_token_name3  => cv_token_cnt
                    ,iv_token_value3 => TO_CHAR(gn_target_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --���������o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_cnt_msg
                    ,iv_token_name1  => cv_token_cnt_table
                    ,iv_token_value1 => cv_table_cnt_ooha
                    ,iv_token_name2  => cv_token_cnt_shori
                    ,iv_token_value2 => cv_shori_cnt_del || cv_shori_cnt_normal
                    ,iv_token_name3  => cv_token_cnt
                    ,iv_token_value3 => TO_CHAR(gn_normal_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --�G���[�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_cnt_msg
                    ,iv_token_name1  => cv_token_cnt_table
                    ,iv_token_value1 => cv_table_cnt_ooha
                    ,iv_token_name2  => cv_token_cnt_shori
                    ,iv_token_value2 => cv_shori_cnt_del || cv_shori_cnt_error
                    ,iv_token_name3  => cv_token_cnt
                    ,iv_token_value3 => TO_CHAR(gn_warning_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    --�I�����b�Z�[�W
    IF (lv_retcode = cv_status_normal) THEN
      gv_out_msg := cv_normal_msg;
    ELSIF(lv_retcode = cv_status_warn) THEN
      gv_out_msg := cv_warn_msg;
    ELSIF(lv_retcode = cv_status_error) THEN
      gv_out_msg := cv_error_msg;
    END IF;
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
END xxcmn960010c;
/
