CREATE OR REPLACE PACKAGE BODY APPS.XXCCP005A05C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2016. All rights reserved.
 *
 * Package Name     : XXCCP005A05C(body)
 * Description      : �S���c�ƈ��d���`�F�b�N
 * MD.070           : �S���c�ƈ��d���`�F�b�N(MD070_IPO_CCP_005_A05)
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2016/12/01    1.0   S.Niki           [E_�{�ғ�_13896]�V�K�쐬
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
  cv_msg_part      CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont      CONSTANT VARCHAR2(3) := '.';
--
--################################  �Œ蕔 END   ##################################
--
--#######################  �Œ�O���[�o���ϐ��錾�� START   #######################
--
  gv_out_msg       VARCHAR2(2000);
  gn_target_cnt    NUMBER;                    -- �Ώی���
  gn_normal_cnt    NUMBER;                    -- ���팏��
  gn_error_cnt     NUMBER;                    -- �G���[����
  gn_warn_cnt      NUMBER;                    -- �x������
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
  cv_pkg_name        CONSTANT VARCHAR2(100)   := 'XXCCP005A05C'; -- �p�b�P�[�W��
  cv_appl_short_name CONSTANT VARCHAR2(10)    := 'XXCCP';        -- �A�h�I���F���ʁEIF�̈�
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
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    ov_errbuf             OUT VARCHAR2      --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode            OUT VARCHAR2      --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg             OUT VARCHAR2      --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
--
--#####################  �Œ胍�[�J���萔�ϐ��錾�� START   ####################
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100) := 'submain';           -- �v���O������
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
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    -- �S���c�ƈ��d�����R�[�h�擾
    CURSOR main_cur
    IS
      WITH
            --==================================================
            -- �{���X�V���ꂽ�ڋq�S��
            --==================================================
            update_resource  AS (
              SELECT /*+
                       LEADING(pd)
                       USE_NL(pd hopeb efdfce fa hop hp hca)
                     */
                     hca.cust_account_id     AS cust_account_id -- �ڋqID
                   , hopeb.extension_id      AS extension_id    -- ����ID
                   , hopeb.d_ext_attr1       AS start_date      -- �K�p�J�n��
                   , NVL( hopeb.d_ext_attr2 ,TO_DATE('9999/12/31','YYYY/MM/DD') )
                                             AS end_date        -- �K�p�I����
              FROM   hz_parties               hp
                   , hz_cust_accounts         hca
                   , hz_organization_profiles hop
                   , fnd_application          fa
                   , ego_fnd_dsc_flx_ctx_ext  efdfce
                   , hz_org_profiles_ext_b    hopeb
                   , ( SELECT xxccp_common_pkg2.get_process_date AS process_date
                       FROM   dual
                     )                        pd
              WHERE  hopeb.last_update_date               >= pd.process_date       -- �ŏI�X�V�����Ɩ����t�ȍ~
              AND    hopeb.last_update_date               <  pd.process_date + 1   -- �ŏI�X�V�����Ɩ����t+1�܂�
              AND    hopeb.attr_group_id                  =  efdfce.attr_group_id
              AND    efdfce.descriptive_flexfield_name    = 'HZ_ORG_PROFILES_GROUP'
              AND    efdfce.descriptive_flex_context_code = 'RESOURCE'
              AND    efdfce.application_id                =  fa.application_id
              AND    fa.application_short_name            =  'AR'
              AND    hopeb.organization_profile_id        =  hop.organization_profile_id
              AND    hop.effective_end_date               IS NULL
              AND    hop.party_id                         =  hp.party_id
              AND    hp.party_id                          =  hca.party_id
              AND    hca.customer_class_code              =  '10'                 -- �ڋq�敪�F�ڋq
            )
      SELECT    /*+
                  LEADING(ur)
                  USE_NL(ur hca2 hp2 hop2 hopeb2 efdfce2 fa2)
                */
                DISTINCT
                hca2.account_number                          AS account_number
              , hp2.party_name                               AS party_name
              , hp2.duns_number_c                            AS duns_number_c
              , hopeb2.c_ext_attr1                           AS c_ext_attr1
              , hopeb2.d_ext_attr1                           AS d_ext_attr1
              , hopeb2.d_ext_attr2                           AS d_ext_attr2
              , hopeb2.last_update_date                      AS last_update_date
              , ( SELECT fu.user_name  AS user_name
                  FROM   fnd_user fu
                  WHERE  fu.user_id = hopeb2.last_updated_by
                )                                            AS last_updated_by
      FROM      update_resource                  ur        -- �X�V���ꂽ�ڋq�S��
              , hz_cust_accounts            hca2      -- �ڋq�}�X�^
              , hz_parties                  hp2       -- �ڋq�p�[�e�B
              , hz_organization_profiles    hop2
              , hz_org_profiles_ext_b       hopeb2
              , ego_fnd_dsc_flx_ctx_ext     efdfce2
              , fnd_application             fa2
      WHERE     ur.cust_account_id                           =  hca2.cust_account_id
        AND     hca2.customer_class_code                     =  '10'                 -- �ڋq�敪�F�ڋq
        AND     hca2.party_id                                =  hp2.party_id
        AND     hp2.party_id                                 =  hop2.party_id
        AND     hop2.effective_end_date                      IS NULL
        AND     hop2.organization_profile_id                 =  hopeb2.organization_profile_id
        AND     hopeb2.attr_group_id                         =  efdfce2.attr_group_id
        AND     efdfce2.descriptive_flexfield_name           = 'HZ_ORG_PROFILES_GROUP'
        AND     efdfce2.descriptive_flex_context_code        = 'RESOURCE'
        AND     efdfce2.application_id                       =  fa2.application_id
        AND     fa2.application_short_name                   =  'AR'
        AND     hopeb2.extension_id                          <> ur.extension_id      -- �X�V���ꂽ���R�[�h�ȊO
        AND     (
                  ( ur.start_date BETWEEN hopeb2.d_ext_attr1 AND NVL( hopeb2.d_ext_attr2 ,TO_DATE('9999/12/31','YYYY/MM/DD') ) )
                  OR
                  ( ur.end_date   BETWEEN hopeb2.d_ext_attr1 AND NVL( hopeb2.d_ext_attr2 ,TO_DATE('9999/12/31','YYYY/MM/DD') ) )
                )                                                                    -- �K�p�J�n���E�I�����̂����ꂩ���d��
      ORDER BY
                hca2.account_number  -- �ڋqCD
              , hopeb2.d_ext_attr1   -- �K�p�J�n��
      ;
    -- ���C���J�[�\�����R�[�h�^
    main_rec  main_cur%ROWTYPE;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- �O���[�o���ϐ��̏�����
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
--
    -- ===============================
    -- init��
    -- ===============================
--
    -- ���̓p�����[�^�o��
    FND_FILE.PUT_LINE(
      which  => FND_FILE.LOG
     ,buff   => '�R���J�����g���̓p�����[�^�Ȃ�'
    );
--
    -- ===============================
    -- ������
    -- ===============================
--
    -- ���ږ��o��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   =>           '"' || '�ڋqCD'           || '"'
                 || ',' || '"' || '�ڋq��'           || '"'
                 || ',' || '"' || '�ڋq�X�e�[�^�X'   || '"'
                 || ',' || '"' || '�S���c��'         || '"'
                 || ',' || '"' || '�K�p�J�n��'       || '"'
                 || ',' || '"' || '�K�p�I����'       || '"'
                 || ',' || '"' || '�ŏI�X�V��'       || '"'
                 || ',' || '"' || '�ŏI�X�V��'       || '"'
    );
    -- �f�[�^���o��
    FOR main_rec IN main_cur LOOP
      --�����Z�b�g
      gn_error_cnt := gn_error_cnt + 1;
      --
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   =>         '"' || main_rec.account_number                            || '"' -- �ڋqCD
                 || ',' || '"' || main_rec.party_name                                || '"' -- �ڋq��
                 || ',' || '"' || main_rec.duns_number_c                             || '"' -- �ڋq�X�e�[�^�X
                 || ',' || '"' || main_rec.c_ext_attr1                               || '"' -- �S���c��
                 || ',' || '"' || TO_CHAR( main_rec.d_ext_attr1 ,'YYYY/MM/DD' )      || '"' -- �K�p�J�n��
                 || ',' || '"' || TO_CHAR( main_rec.d_ext_attr2 ,'YYYY/MM/DD' )      || '"' -- �K�p�I����
                 || ',' || '"' || TO_CHAR( main_rec.last_update_date ,'YYYY/MM/DD' ) || '"' -- �ŏI�X�V��
                 || ',' || '"' || main_rec.last_updated_by                           || '"' -- �ŏI�X�V��
      );
    END LOOP;
--
    -- �G���[���� > 0�̏ꍇ
    IF ( gn_error_cnt > 0 ) THEN
      ov_errbuf  := '�S���c�ƈ��d�����R�[�h���������Ă��܂��B';
      ov_retcode := cv_status_error;
    END IF;
--
  EXCEPTION
      -- *** �C�ӂŗ�O�������L�q���� ****
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
    errbuf                OUT VARCHAR2      --   �G���[�E���b�Z�[�W  --# �Œ� #
   ,retcode               OUT VARCHAR2      --   ���^�[���E�R�[�h    --# �Œ� #
  )
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
    cv_target_rec_msg  CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90000'; -- �Ώی������b�Z�[�W
    cv_success_rec_msg CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90001'; -- �����������b�Z�[�W
    cv_error_rec_msg   CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90002'; -- �G���[�������b�Z�[�W
    cv_skip_rec_msg    CONSTANT VARCHAR2(100) := 'APP-XXCCP1-00001'; -- �x���������b�Z�[�W
    cv_normal_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004'; -- ����I�����b�Z�[�W
    cv_error_msg       CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006'; -- �G���[�I���S���[���o�b�N
    cv_cnt_token       CONSTANT VARCHAR2(10)  := 'COUNT';            -- �������b�Z�[�W�p�g�[�N����
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
      --��s�}��
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => ''
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --�G���[���b�Z�[�W
      );
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
--
  EXCEPTION
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
  END main;
--
--###########################  �Œ蕔 END   #######################################################
--
END XXCCP005A05C;
/