CREATE OR REPLACE PACKAGE BODY XXCFF_COMMON1_PKG
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCFF_COMMON1_PKG(body)
 * Description      : ���[�X�EFA�̈拤�ʊ֐��P
 * MD.050           : �Ȃ�
 * Version          : 1.0
 *
 * Program List
 * ---------------------------- ---- ----- ----------------------------------------------
 *  Name                        Type  Ret   Description
 * ---------------------------- ---- ----- ----------------------------------------------
 *  init                         P    -     ��������
 *  put_log_param                P    -     �R���J�����g�p�����[�^�o�͏���
 *  chk_fa_location              P    -     ���Ə��}�X�^�`�F�b�N
 *  chk_discount_rate            P    -     ���݉��l�������擾�`�F�b�N
 *  chk_fa_category              P    -     ���Y�J�e�S���`�F�b�N
 *  chk_life                     P    -     �ϗp�N���`�F�b�N
 *  �쐬���ɋL�q���Ă�������
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/11/17    1.0   SCS�R�݌���      �V�K�쐬
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
  cv_msg_part      CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont      CONSTANT VARCHAR2(3) := '.';
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
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name        CONSTANT VARCHAR2(100) := 'XXCFF_COMMON1_PKG'; -- �p�b�P�[�W��
  cv_appl_short_name CONSTANT VARCHAR2(10)  := 'XXCFF';            -- �A�h�I���FFA�E���[�X�̈�
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������
   ***********************************************************************************/
  PROCEDURE init(
    or_init_rec   OUT NOCOPY init_rtype,   --   �߂�l
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT NOCOPY VARCHAR2      --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name      CONSTANT VARCHAR2(100) := 'init'; -- �v���O������
    cv_init_err_msg  CONSTANT VARCHAR2(100) := 'APP-XXCFF1-00152'; -- ���������G���[
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
--
    -- *** ���[�J���ϐ� ***
    ln_set_of_book_id         NUMBER(15);
    lv_currency_code          VARCHAR2(15);
    ln_chart_of_account_id    NUMBER(15);
    lv_application_short_name VARCHAR2(50);
    lv_id_flex_code           VARCHAR2(4);
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
    or_init_rec := NULL;
    -- ��v����ID
    ln_set_of_book_id := TO_NUMBER(fnd_profile.value('GL_SET_OF_BKS_ID'));
    -- �@�\�ʉ݁A�Ȗڑ̌n
    SELECT currency_code
          ,chart_of_accounts_id
      INTO lv_currency_code
          ,ln_chart_of_account_id
      FROM gl_sets_of_books
     WHERE set_of_books_id = ln_set_of_book_id;
    -- GL�A�v���P�[�V�����Z�k���A�L�[�t���b�N�X�R�[�h
    SELECT a.application_short_name
          ,s.id_flex_code
      INTO lv_application_short_name
          ,lv_id_flex_code
      FROM fnd_application a
          ,fnd_id_flex_structures_vl s
          ,fa_system_controls f
     WHERE a.application_id = f.gl_application_id
       AND s.application_id = f.gl_application_id
       AND s.id_flex_num = ln_chart_of_account_id;
--
    -- �Ɩ����t
    or_init_rec.process_date           := xxccp_common_pkg2.get_process_date;
    -- ��v����ID
    or_init_rec.set_of_books_id        := ln_set_of_book_id;
    -- �@�\�ʉ�
    or_init_rec.currency_code          := lv_currency_code;
    -- �c�ƒP��
    or_init_rec.org_id                 := fnd_profile.value('ORG_ID');
    -- GL�A�v���P�[�V�����Z�k��
    or_init_rec.gl_application_short_name := lv_application_short_name;
    -- �Ȗڑ̌nID
    or_init_rec.chart_of_accounts_id   := ln_chart_of_account_id;
    -- �L�[�t���b�N�X�R�[�h
    or_init_rec.id_flex_code           := lv_id_flex_code;
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--    WHEN global_api_expt THEN                           --*** �����G���[ ***
--      -- *** �C�ӂŗ�O�������L�q���� ****
--      ov_errmsg  := lv_errmsg;                                                  --# �C�� #
--      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
--      ov_retcode := cv_status_error;                                            --# �C�� #
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errmsg  := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_init_err_msg
                   );
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
  END init;
--
  /**********************************************************************************
   * Procedure Name   : put_log_param
   * Description      : �R���J�����g�p�����[�^�o�͏���
   ***********************************************************************************/
  PROCEDURE put_log_param(
    iv_which    IN  VARCHAR2 DEFAULT 'OUTPUT',  -- �o�͋敪
    ov_errbuf   OUT NOCOPY VARCHAR2,            --�G���[���b�Z�[�W
    ov_retcode  OUT NOCOPY VARCHAR2,            --���^�[���R�[�h
    ov_errmsg   OUT NOCOPY VARCHAR2             --���[�U�[�E�G���[���b�Z�[�W
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'put_log_param'; -- �v���O������
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
--
    -- *** ���[�J���ϐ� ***
    lv_request_id          VARCHAR2(100) := fnd_global.conc_request_id;        -- �v��ID
--
    -- *** ���[�J���E�J�[�\�� ***
    CURSOR concurrent_cur
    IS
      SELECT fcr.request_id
            ,fcr.argument1
            ,fcr.argument2
            ,fcr.argument3
            ,fcr.argument4
            ,fcr.argument5
            ,fcr.argument6
            ,fcr.argument7
            ,fcr.argument8
            ,fcr.argument9
            ,fcr.argument10
      FROM   fnd_concurrent_requests    fcr    --�v���Ǘ��}�X�^
            ,fnd_concurrent_programs_tl fcpt   --�v���}�X�^
      WHERE  fcr.request_id = TO_NUMBER(lv_request_id)
      AND    fcr.program_application_id = fcpt.application_id
      AND    fcr.concurrent_program_id = fcpt.concurrent_program_id
      AND    fcpt.language = 'JA'
      ;
--
    -- *** ���[�J���E���R�[�h ***
    concurrent_cur_v concurrent_cur%ROWTYPE;  --�J�[�\���ϐ����`
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
    -- �R���J�����g�p�����[�^�擾
    OPEN concurrent_cur;
    FETCH concurrent_cur INTO concurrent_cur_v;
    CLOSE concurrent_cur;
--
    -- ��v�`�[�����ʊ֐��Ńp�����[�^�o��
    xxcfr_common_pkg.put_log_param(
       iv_which       => iv_which                      -- �o�͋敪
      ,iv_conc_param1 => concurrent_cur_v.argument1    -- �R���J�����g�p�����[�^�P
      ,iv_conc_param2 => concurrent_cur_v.argument2    -- �R���J�����g�p�����[�^�Q
      ,iv_conc_param3 => concurrent_cur_v.argument3    -- �R���J�����g�p�����[�^�R
      ,iv_conc_param4 => concurrent_cur_v.argument4    -- �R���J�����g�p�����[�^�S
      ,iv_conc_param5 => concurrent_cur_v.argument5    -- �R���J�����g�p�����[�^�T
      ,iv_conc_param6 => concurrent_cur_v.argument6    -- �R���J�����g�p�����[�^�U
      ,iv_conc_param7 => concurrent_cur_v.argument7    -- �R���J�����g�p�����[�^�V
      ,iv_conc_param8 => concurrent_cur_v.argument8    -- �R���J�����g�p�����[�^�W
      ,iv_conc_param9 => concurrent_cur_v.argument9    -- �R���J�����g�p�����[�^�X
      ,iv_conc_param10=> concurrent_cur_v.argument10   -- �R���J�����g�p�����[�^�P�O
      ,ov_errbuf      => lv_errbuf           -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode     => lv_retcode          -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg      => lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF lv_retcode != cv_status_normal THEN
      RAISE global_api_expt;
    END IF;
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
  END put_log_param;
--
  /**********************************************************************************
   * Procedure Name   : chk_fa_location
   * Description      : ���Ə��}�X�^�`�F�b�N
   ***********************************************************************************/
  PROCEDURE chk_fa_location(
    iv_segment1    IN  VARCHAR2 DEFAULT NULL, -- �\���n
    iv_segment2    IN  VARCHAR2,              -- �Ǘ�����
    iv_segment3    IN  VARCHAR2 DEFAULT NULL, -- ���Ə�
    iv_segment4    IN  VARCHAR2 DEFAULT NULL, -- �ꏊ
    iv_segment5    IN  VARCHAR2,              -- �{�Ё^�H��
    on_location_id OUT NOCOPY NUMBER,         -- ���Ə�ID
    ov_errbuf      OUT NOCOPY VARCHAR2,       -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode     OUT NOCOPY VARCHAR2,       -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg      OUT NOCOPY VARCHAR2        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_fa_location'; -- �v���O������
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
--
    -- *** ���[�J���ϐ� ***
    lv_application_short_name    VARCHAR2(100);
    lv_key_flex_code             VARCHAR2(100) := 'LOC#';
    ln_structure_no              NUMBER(15);
    l_segments_tab               fnd_flex_ext.segmentarray;
    ln_combination_id            NUMBER(15);
    lb_ret                       BOOLEAN;
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
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
    -- ���ع���ݒZ�k���A��׸���ԍ��擾
    BEGIN
      SELECT a.application_short_name
            ,f.location_flex_structure
        INTO lv_application_short_name
            ,ln_structure_no
        FROM fnd_application a
            ,fa_system_controls f
      WHERE a.application_id = f.fa_application_id;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errbuf := SQLERRM;
        RAISE global_api_expt;
    END;
    -- ���Ə����i�[
    l_segments_tab(1) := NVL(iv_segment1,fnd_profile.value('XXCFF1_DCLR_PLACE_NO_REPORT'));
    l_segments_tab(2) := iv_segment2;
    l_segments_tab(3) := NVL(iv_segment3,fnd_profile.value('XXCFF1_MNG_PLACE_DAMMY'));
    l_segments_tab(4) := NVL(iv_segment4,fnd_profile.value('XXCFF1_PLACE_DAMMY'));
    l_segments_tab(5) := iv_segment5;
--
    lb_ret := fnd_flex_ext.get_combination_id(
                 application_short_name => lv_application_short_name
                ,key_flex_code          => lv_key_flex_code
                ,structure_number       => ln_structure_no
                ,validation_date        => SYSDATE
                ,n_segments             => 5
                ,segments               => l_segments_tab
                ,combination_id         => ln_combination_id
                );
    IF NOT lb_ret THEN
      lv_errbuf := fnd_flex_ext.get_message;
      lv_errmsg := lv_errbuf;
      RAISE global_api_expt;
    END IF;
    -- �߂�l�ݒ�
    on_location_id := ln_combination_id;
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    WHEN global_api_expt THEN                           --*** ���ʊ֐��G���[ ***
      -- *** �C�ӂŗ�O�������L�q���� ****
      ov_errmsg  := lv_errmsg;                                                  --# �C�� #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# �C�� #
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
  END chk_fa_location;
--
  /**********************************************************************************
   * Procedure Name   : chk_fa_category
   * Description      : ���Y�J�e�S���`�F�b�N
   ***********************************************************************************/
  PROCEDURE chk_fa_category(
    iv_segment1    IN  VARCHAR2,              -- ���
    iv_segment2    IN  VARCHAR2 DEFAULT NULL, -- �\�����p
    iv_segment3    IN  VARCHAR2 DEFAULT NULL, -- ���Y����
    iv_segment4    IN  VARCHAR2 DEFAULT NULL, -- ���p�Ȗ�
    iv_segment5    IN  VARCHAR2,              -- �ϗp�N��
    iv_segment6    IN  VARCHAR2 DEFAULT NULL, -- ���p���@
    iv_segment7    IN  VARCHAR2,              -- ���[�X���
    on_category_id OUT NOCOPY NUMBER,         -- ���Y�J�e�S��ID
    ov_errbuf      OUT NOCOPY VARCHAR2,       -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode     OUT NOCOPY VARCHAR2,       -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg      OUT NOCOPY VARCHAR2        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_fa_category'; -- �v���O������
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
    cv_param_err     CONSTANT VARCHAR2(100) := 'APP-XXCFF1-00101'; -- �G���[���b�Z�[�W��
    cv_tkn_name1     CONSTANT VARCHAR2(100) := 'TABLE_NAME';
    cv_tkn_name2     CONSTANT VARCHAR2(100) := 'INFO';
    cv_tkn_val1      CONSTANT VARCHAR2(100) := 'APP-XXCFF1-50071'; -- �t���b�N�X�t�B�[���h�̌n���
    cv_tkn_val2      CONSTANT VARCHAR2(100) := 'APP-XXCFF1-50041'; -- ���[�X���
    cv_itm_equal     CONSTANT VARCHAR2(100) := '=';                --
--
    -- *** ���[�J���ϐ� ***
    lv_application_short_name    VARCHAR2(100);
    lv_key_flex_code             VARCHAR2(100) := 'CAT#';
    ln_structure_no              NUMBER(15);
    l_segments_tab               fnd_flex_ext.segmentarray;
    ln_combination_id            NUMBER(15);
    lb_ret                       BOOLEAN;
    lv_les_asset_acct            xxcff_lease_class_v.les_asset_acct%TYPE;
    lv_deprn_acct                xxcff_lease_class_v.deprn_acct%TYPE;
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
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
    -- ���ع���ݒZ�k���A��׸���ԍ��擾
    BEGIN
      SELECT
             a.application_short_name
            ,f.location_flex_structure
        INTO
             lv_application_short_name
            ,ln_structure_no
        FROM
             fnd_application a
            ,fa_system_controls f
      WHERE
             a.application_id = f.fa_application_id;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(cv_appl_short_name, cv_param_err
                                             ,cv_tkn_name1,       cv_tkn_val1
                                             ,cv_tkn_name2,       SQLERRM);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;

    IF ((iv_segment3 IS NULL)
        OR (iv_segment4 IS NULL)) THEN
      BEGIN
        SELECT
          les_asset_acct
         ,deprn_acct
        INTO
          lv_les_asset_acct
         ,lv_deprn_acct
        FROM
          xxcff_lease_class_v
        WHERE
          lease_class_code = iv_segment7;
      EXCEPTION
        WHEN OTHERS THEN
          lv_errmsg := xxccp_common_pkg.get_msg(cv_appl_short_name, cv_tkn_val2);
          lv_errmsg := xxccp_common_pkg.get_msg(cv_appl_short_name, cv_param_err
                                               ,cv_tkn_name1,       cv_tkn_val2
                                               ,cv_tkn_name2,       lv_errmsg||cv_itm_equal||iv_segment7);
          RAISE global_api_expt;
      END;
    END IF;
    -- �J�e�S�����i�[
    l_segments_tab(1) := iv_segment1;
    l_segments_tab(2) := NVL(iv_segment2, fnd_profile.value('XXCFF1_DCLR_DPRN_NO_TGT'));
    l_segments_tab(3) := NVL(iv_segment3, lv_les_asset_acct);
    l_segments_tab(4) := NVL(iv_segment4, lv_deprn_acct);
    l_segments_tab(5) := iv_segment5;
    l_segments_tab(6) := NVL(iv_segment6, fnd_profile.value('XXCFF1_CAT_DPRN_LEASE'));
    l_segments_tab(7) := iv_segment7;
--
    lb_ret := fnd_flex_ext.get_combination_id(
                 application_short_name => lv_application_short_name
                ,key_flex_code          => lv_key_flex_code
                ,structure_number       => ln_structure_no
                ,validation_date        => SYSDATE
                ,n_segments             => 7
                ,segments               => l_segments_tab
                ,combination_id         => ln_combination_id
                );
    IF (NOT lb_ret) THEN
      lv_errbuf := fnd_flex_ext.get_message;
      lv_errmsg := lv_errbuf;
      RAISE global_api_expt;
    END IF;
    -- �߂�l�ݒ�
    on_category_id := ln_combination_id;
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    WHEN global_api_expt THEN                           --*** ���ʊ֐��G���[ ***
      -- *** �C�ӂŗ�O�������L�q���� ****
      ov_errmsg  := lv_errmsg;                                                  --# �C�� #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;                                            --# �C�� #
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
  END chk_fa_category;
--
  /**********************************************************************************
   * Procedure Name   : chk_life
   * Description      : �ϗp�N���`�F�b�N
   ***********************************************************************************/
  PROCEDURE chk_life(
    iv_category    IN  VARCHAR2,           --   ���Y���
    iv_life        IN  VARCHAR2,           --   �ϗp�N��
    ov_errbuf      OUT NOCOPY VARCHAR2,    --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode     OUT NOCOPY VARCHAR2,    --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg      OUT NOCOPY VARCHAR2     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_life'; -- �v���O������
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
--
    -- *** ���[�J���ϐ� ***
    ln_check_count   NUMBER(1);
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
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
    --==============================================================
    --��ނƑϗp�N���̑g�ݍ��킹�m�F�̂��߃f�[�^�擾
    --==============================================================
    SELECT
           COUNT(ffvv.flex_value_id)
    INTO
           ln_check_count
    FROM
           fnd_flex_values_vl  ffvv
          ,fnd_flex_value_sets ffvs
    WHERE
           ffvs.flex_value_set_name   = 'XXCFF_LIFE'
    AND    ffvv.flex_value_set_id     = ffvs.flex_value_set_id
    AND    ffvv.parent_flex_value_low = iv_category
    AND    ffvv.flex_value            = iv_life
    AND    ffvv.enabled_flag          = 'Y'
    AND    NVL(ffvv.start_date_active,SYSDATE) <= SYSDATE
    AND    NVL(ffvv.end_date_active,SYSDATE)   >= SYSDATE;
    --==============================================================
    --0���擾�ł̓`�F�b�N�G���[�Ƃ���
    --==============================================================
    IF (ln_check_count = 0) THEN
      ov_retcode := cv_status_warn;                                            --# �C�� #
    END IF;
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    WHEN global_api_expt THEN                           --*** ���ʊ֐��G���[ ***
      -- *** �C�ӂŗ�O�������L�q���� ****
      ov_errmsg  := lv_errmsg;                                                  --# �C�� #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# �C�� #
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
  END chk_life;
--
END XXCFF_COMMON1_PKG;
/
