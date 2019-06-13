CREATE OR REPLACE PACKAGE BODY XXCOS_COMMON_PKG
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOS_COMMON_PKG(body)
 * Description      : ���ʊ֐��p�b�P�[�W(�̔�)
 * MD.070           : ���ʊ֐�    MD070_IPO_COS
 * Version          : 1.4
 *
 * Program List
 * --------------------------- ------ ---------- -----------------------------------------
 *  Name                        Type   Return     Description
 * --------------------------- ------ ---------- -----------------------------------------
 *  get_key_info                P                 �L�[���ҏW
 *  get_uom_cnv                 P                 �P�ʊ��Z�擾
 *  get_delivered_from          P                 �[�i�`�Ԏ擾
 *  get_sales_calendar_code     P                 �̔��p�J�����_�[�R�[�h�擾
 *  check_sales_operation_day   F      NUMBER     �̔��p�ғ����`�F�b�N
 *  get_period_year             P                 ���N�x��v���Ԏ擾
 *  get_account_period          P                 ��v���ԏ��擾
 *  get_specific_master         F      VARCHAR2   ����}�X�^�擾(�N�C�b�N�R�[�h)
 *  get_tax_rate_info           P                 �i�ڕʏ���ŗ��擾�֐�
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/11/21    1.0   SCS              �V�K�쐬
 *  2009/04/30    1.1   T.Kitajima       [T1_0710]get_delivered_from �o�׋��_�R�[�h�擾���@�ύX
 *  2009/05/14    1.2   N.Maeda          [T1_0997]�[�i�`�ԋ敪�̓��o���@�C��
 *  2009/08/03    1.3   N.Maeda          [0000433]get_account_period,get_specific_master��
 *                                                �Q�ƃ^�C�v�R�[�h�擾���̕s�v�ȃe�[�u�������̍폜
 *  2019/06/04    1.4   S.Kuwako         [E_�{�ғ�_15472]�y���ŗ��p�̏���ŗ��擾�֐��̒ǉ�
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
  global_get_profile_expt   EXCEPTION;     -- �v���t�@�C��
  global_nothing_expt       EXCEPTION;     -- ���͂Ȃ�
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name      CONSTANT VARCHAR2(100) := 'XXCOS_COMMON_PKG';                -- �p�b�P�[�W��
--
  --�A�v���P�[�V�����Z�k��
  ct_xxcos_appl_short_name        CONSTANT  fnd_application.application_short_name%TYPE
                                            := 'XXCOS';                         -- �̕��Z�k�A�v����
  ct_xxcoi_appl_short_name        CONSTANT  fnd_application.application_short_name%TYPE
                                            := 'XXCOI';                         -- �݌ɒZ�k�A�v����
  --�v���t�@�C��ID
  ct_prof_organization_code       CONSTANT  fnd_profile_options.profile_option_name%TYPE
                                            := 'XXCOI1_ORGANIZATION_CODE';      -- �g�D�R�[�h
  ct_prof_gl_set_of_bks_id        CONSTANT  fnd_profile_options.profile_option_name%TYPE
                                            := 'GL_SET_OF_BKS_ID';              -- GL��v����ID
  --�̕����b�Z�[�W
  ct_msg_get_profile_err          CONSTANT  fnd_new_messages.message_name%TYPE
                                            := 'APP-XXCOS1-00004';              -- �v���t�@�C���擾�G���[
  ct_msg_require_param_err        CONSTANT  fnd_new_messages.message_name%TYPE
                                            := 'APP-XXCOS1-00006';              -- �K�{���̓p�����[�^���ݒ�G���[
  ct_msg_select_err               CONSTANT  fnd_new_messages.message_name%TYPE
                                            := 'APP-XXCOS1-00013';              -- �f�[�^���o�G���[
  ct_msg_call_api_err             CONSTANT  fnd_new_messages.message_name%TYPE
                                            := 'APP-XXCOS1-00017';              -- API�ďo�G���[
  ct_msg_in_param_err             CONSTANT  fnd_new_messages.message_name%TYPE
                                            := 'APP-XXCOS1-00019';              -- ���̓p�����[�^�s���G���[
  ct_msg_prof_organization_code   CONSTANT  fnd_new_messages.message_name%TYPE
                                            := 'APP-XXCOS1-00048';              -- XXCOI:�݌ɑg�D�R�[�h
  ct_msg_mtl_system_items         CONSTANT  fnd_new_messages.message_name%TYPE
                                            := 'APP-XXCOS1-00050';              -- �i�ڃ}�X�^
  ct_msg_item_code                CONSTANT  fnd_new_messages.message_name%TYPE
                                            := 'APP-XXCOS1-00054';              -- �i�ڃR�[�h
  ct_msg_mtl_uom_class_conv       CONSTANT  fnd_new_messages.message_name%TYPE
                                            := 'APP-XXCOS1-00061';              -- �P�ʊ��Z�}�X�^
  ct_msg_uom_code                 CONSTANT  fnd_new_messages.message_name%TYPE
                                            := 'APP-XXCOS1-00062';              -- �P�ʃR�[�h
  --�g�[�N��
  cv_tkn_profile                  CONSTANT  VARCHAR2(100) := 'PROFILE';         -- �v���t�@�C��
  cv_tkn_in_param                 CONSTANT  VARCHAR2(100) := 'IN_PARAM';        -- ���̓p�����[�^
  cv_tkn_api_name                 CONSTANT  VARCHAR2(100) := 'API_NAME';        -- API��
  cv_tkn_table_name               CONSTANT  VARCHAR2(100) := 'TABLE_NAME';      -- �e�[�u����
  cv_tkn_key_data                 CONSTANT  VARCHAR2(100) := 'KEY_DATA';        -- �L�[�f�[�^
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  TYPE g_name_value_rtype
  IS
    RECORD(
      item_name                   VARCHAR2(5000),
      data_value                  VARCHAR2(5000)
    );
  --
  TYPE g_name_value_ttype
  IS
    TABLE OF
      g_name_value_rtype
    INDEX BY BINARY_INTEGER
    ;
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
--
  --==================================
  -- �v���C�x�[�g��t�@���N�V����
  --==================================
  -- �݌ɑg�D�R�[�h�̎擾
  FUNCTION get_organization_code(
    in_organization_id        IN            NUMBER
  ) RETURN mtl_parameters.organization_code%TYPE
  IS
    lv_organization_code                mtl_parameters.organization_code%TYPE;  -- �݌ɑg�D�R�[�h
  BEGIN
    lv_organization_code                := NULL;
    --
    SELECT
      mp.organization_code              organization_code
    INTO
      lv_organization_code
    FROM
      mtl_parameters                    mp
    WHERE
      mp.organization_id                = in_organization_id
    ;
    --
    RETURN lv_organization_code;
  EXCEPTION
    WHEN OTHERS THEN
      RETURN NULL;
  END;
--
  /**********************************************************************************
   * Procedure Name   : makeup_key_info
   * Description      : �L�[���ҏW
   ***********************************************************************************/
  PROCEDURE makeup_key_info(
    iv_item_name1             IN            VARCHAR2  DEFAULT NULL,         -- ���ږ��̂P
    iv_item_name2             IN            VARCHAR2  DEFAULT NULL,         -- ���ږ��̂Q
    iv_item_name3             IN            VARCHAR2  DEFAULT NULL,         -- ���ږ��̂R
    iv_item_name4             IN            VARCHAR2  DEFAULT NULL,         -- ���ږ��̂S
    iv_item_name5             IN            VARCHAR2  DEFAULT NULL,         -- ���ږ��̂T
    iv_item_name6             IN            VARCHAR2  DEFAULT NULL,         -- ���ږ��̂U
    iv_item_name7             IN            VARCHAR2  DEFAULT NULL,         -- ���ږ��̂V
    iv_item_name8             IN            VARCHAR2  DEFAULT NULL,         -- ���ږ��̂W
    iv_item_name9             IN            VARCHAR2  DEFAULT NULL,         -- ���ږ��̂X
    iv_item_name10            IN            VARCHAR2  DEFAULT NULL,         -- ���ږ��̂P�O
    iv_item_name11            IN            VARCHAR2  DEFAULT NULL,         -- ���ږ��̂P�P
    iv_item_name12            IN            VARCHAR2  DEFAULT NULL,         -- ���ږ��̂P�Q
    iv_item_name13            IN            VARCHAR2  DEFAULT NULL,         -- ���ږ��̂P�R
    iv_item_name14            IN            VARCHAR2  DEFAULT NULL,         -- ���ږ��̂P�S
    iv_item_name15            IN            VARCHAR2  DEFAULT NULL,         -- ���ږ��̂P�T
    iv_item_name16            IN            VARCHAR2  DEFAULT NULL,         -- ���ږ��̂P�U
    iv_item_name17            IN            VARCHAR2  DEFAULT NULL,         -- ���ږ��̂P�V
    iv_item_name18            IN            VARCHAR2  DEFAULT NULL,         -- ���ږ��̂P�W
    iv_item_name19            IN            VARCHAR2  DEFAULT NULL,         -- ���ږ��̂P�X
    iv_item_name20            IN            VARCHAR2  DEFAULT NULL,         -- ���ږ��̂Q�O
    iv_data_value1            IN            VARCHAR2  DEFAULT NULL,         -- �f�[�^�̒l�P
    iv_data_value2            IN            VARCHAR2  DEFAULT NULL,         -- �f�[�^�̒l�Q
    iv_data_value3            IN            VARCHAR2  DEFAULT NULL,         -- �f�[�^�̒l�R
    iv_data_value4            IN            VARCHAR2  DEFAULT NULL,         -- �f�[�^�̒l�S
    iv_data_value5            IN            VARCHAR2  DEFAULT NULL,         -- �f�[�^�̒l�T
    iv_data_value6            IN            VARCHAR2  DEFAULT NULL,         -- �f�[�^�̒l�U
    iv_data_value7            IN            VARCHAR2  DEFAULT NULL,         -- �f�[�^�̒l�V
    iv_data_value8            IN            VARCHAR2  DEFAULT NULL,         -- �f�[�^�̒l�W
    iv_data_value9            IN            VARCHAR2  DEFAULT NULL,         -- �f�[�^�̒l�X
    iv_data_value10           IN            VARCHAR2  DEFAULT NULL,         -- �f�[�^�̒l�P�O
    iv_data_value11           IN            VARCHAR2  DEFAULT NULL,         -- �f�[�^�̒l�P�P
    iv_data_value12           IN            VARCHAR2  DEFAULT NULL,         -- �f�[�^�̒l�P�Q
    iv_data_value13           IN            VARCHAR2  DEFAULT NULL,         -- �f�[�^�̒l�P�R
    iv_data_value14           IN            VARCHAR2  DEFAULT NULL,         -- �f�[�^�̒l�P�S
    iv_data_value15           IN            VARCHAR2  DEFAULT NULL,         -- �f�[�^�̒l�P�T
    iv_data_value16           IN            VARCHAR2  DEFAULT NULL,         -- �f�[�^�̒l�P�U
    iv_data_value17           IN            VARCHAR2  DEFAULT NULL,         -- �f�[�^�̒l�P�V
    iv_data_value18           IN            VARCHAR2  DEFAULT NULL,         -- �f�[�^�̒l�P�W
    iv_data_value19           IN            VARCHAR2  DEFAULT NULL,         -- �f�[�^�̒l�P�X
    iv_data_value20           IN            VARCHAR2  DEFAULT NULL,         -- �f�[�^�̒l�Q�O
    ov_key_info               OUT    NOCOPY VARCHAR2,                       -- �L�[���
    ov_errbuf                 OUT    NOCOPY VARCHAR2,                       -- �G���[�E���b�Z�[�W�G���[       #�Œ�#
    ov_retcode                OUT    NOCOPY VARCHAR2,                       -- ���^�[���E�R�[�h               #�Œ�#
    ov_errmsg                 OUT    NOCOPY VARCHAR2)                       -- ���[�U�[�E�G���[�E���b�Z�[�W   #�Œ�#
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'makeup_key_info'; -- �v���O������
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
    cn_param_count                  CONSTANT  NUMBER        := 20;              -- �p�����[�^���ڐ�
    --
    cv_separator                    CONSTANT  VARCHAR2(10)  := ' : ';           -- �Z�p���[�^
    cv_paragraph                    CONSTANT  VARCHAR2(10)  := CHR(10);         -- ���s
    ct_msg_item_name                CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-13566';            -- ���ږ���
--
    -- *** ���[�J���ϐ� ***
    l_name_value_tab                          g_name_value_ttype;
    lv_key_info                               VARCHAR2(5000);
    ln_idx1                                   PLS_INTEGER;
    --���b�Z�[�W�p������
    lt_str_item_name                          fnd_new_messages.message_text%TYPE;
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
    --==============================================================
    --1.�p�����[�^�Z�b�g
    --==============================================================
    ln_idx1 := 0;
    <<loop_set_param>>
    LOOP
      --
      ln_idx1 := ln_idx1 + 1;
      --
      EXIT WHEN ln_idx1 > cn_param_count;
      --
      IF ( ln_idx1 = 1 ) THEN
        IF ( iv_item_name1 IS NULL ) THEN
          ln_idx1 := cn_param_count;
        ELSE
          l_name_value_tab(ln_idx1).item_name     := iv_item_name1;
          l_name_value_tab(ln_idx1).data_value    := iv_data_value1;
        END IF;
      ELSIF ( ln_idx1 = 2 ) THEN
        IF ( iv_item_name2 IS NULL ) THEN
          ln_idx1 := cn_param_count;
        ELSE
          l_name_value_tab(ln_idx1).item_name     := iv_item_name2;
          l_name_value_tab(ln_idx1).data_value    := iv_data_value2;
        END IF;
      ELSIF ( ln_idx1 = 3 ) THEN
        IF ( iv_item_name3 IS NULL ) THEN
          ln_idx1 := cn_param_count;
        ELSE
          l_name_value_tab(ln_idx1).item_name     := iv_item_name3;
          l_name_value_tab(ln_idx1).data_value    := iv_data_value3;
        END IF;
      ELSIF ( ln_idx1 = 4 ) THEN
        IF ( iv_item_name4 IS NULL ) THEN
          ln_idx1 := cn_param_count;
        ELSE
          l_name_value_tab(ln_idx1).item_name     := iv_item_name4;
          l_name_value_tab(ln_idx1).data_value    := iv_data_value4;
        END IF;
      ELSIF ( ln_idx1 = 5 ) THEN
        IF ( iv_item_name5 IS NULL ) THEN
          ln_idx1 := cn_param_count;
        ELSE
          l_name_value_tab(ln_idx1).item_name     := iv_item_name5;
          l_name_value_tab(ln_idx1).data_value    := iv_data_value5;
        END IF;
      ELSIF ( ln_idx1 = 6 ) THEN
        IF ( iv_item_name6 IS NULL ) THEN
          ln_idx1 := cn_param_count;
        ELSE
          l_name_value_tab(ln_idx1).item_name     := iv_item_name6;
          l_name_value_tab(ln_idx1).data_value    := iv_data_value6;
        END IF;
      ELSIF ( ln_idx1 = 7 ) THEN
        IF ( iv_item_name7 IS NULL ) THEN
          ln_idx1 := cn_param_count;
        ELSE
          l_name_value_tab(ln_idx1).item_name     := iv_item_name7;
          l_name_value_tab(ln_idx1).data_value    := iv_data_value7;
        END IF;
      ELSIF ( ln_idx1 = 8 ) THEN
        IF ( iv_item_name8 IS NULL ) THEN
          ln_idx1 := cn_param_count;
        ELSE
          l_name_value_tab(ln_idx1).item_name     := iv_item_name8;
          l_name_value_tab(ln_idx1).data_value    := iv_data_value8;
        END IF;
      ELSIF ( ln_idx1 = 9 ) THEN
        IF ( iv_item_name9 IS NULL ) THEN
          ln_idx1 := cn_param_count;
        ELSE
          l_name_value_tab(ln_idx1).item_name     := iv_item_name9;
          l_name_value_tab(ln_idx1).data_value    := iv_data_value9;
        END IF;
      ELSIF ( ln_idx1 = 10 ) THEN
        IF ( iv_item_name10 IS NULL ) THEN
          ln_idx1 := cn_param_count;
        ELSE
          l_name_value_tab(ln_idx1).item_name     := iv_item_name10;
          l_name_value_tab(ln_idx1).data_value    := iv_data_value10;
        END IF;
      ELSIF ( ln_idx1 = 11 ) THEN
        IF ( iv_item_name11 IS NULL ) THEN
          ln_idx1 := cn_param_count;
        ELSE
          l_name_value_tab(ln_idx1).item_name     := iv_item_name11;
          l_name_value_tab(ln_idx1).data_value    := iv_data_value11;
        END IF;
      ELSIF ( ln_idx1 = 12 ) THEN
        IF ( iv_item_name12 IS NULL ) THEN
          ln_idx1 := cn_param_count;
        ELSE
          l_name_value_tab(ln_idx1).item_name     := iv_item_name12;
          l_name_value_tab(ln_idx1).data_value    := iv_data_value12;
        END IF;
      ELSIF ( ln_idx1 = 13 ) THEN
        IF ( iv_item_name13 IS NULL ) THEN
          ln_idx1 := cn_param_count;
        ELSE
          l_name_value_tab(ln_idx1).item_name     := iv_item_name13;
          l_name_value_tab(ln_idx1).data_value    := iv_data_value13;
        END IF;
      ELSIF ( ln_idx1 = 14 ) THEN
        IF ( iv_item_name14 IS NULL ) THEN
          ln_idx1 := cn_param_count;
        ELSE
          l_name_value_tab(ln_idx1).item_name     := iv_item_name14;
          l_name_value_tab(ln_idx1).data_value    := iv_data_value14;
        END IF;
      ELSIF ( ln_idx1 = 15 ) THEN
        IF ( iv_item_name15 IS NULL ) THEN
          ln_idx1 := cn_param_count;
        ELSE
          l_name_value_tab(ln_idx1).item_name     := iv_item_name15;
          l_name_value_tab(ln_idx1).data_value    := iv_data_value15;
        END IF;
      ELSIF ( ln_idx1 = 16 ) THEN
        IF ( iv_item_name16 IS NULL ) THEN
          ln_idx1 := cn_param_count;
        ELSE
          l_name_value_tab(ln_idx1).item_name     := iv_item_name16;
          l_name_value_tab(ln_idx1).data_value    := iv_data_value16;
        END IF;
      ELSIF ( ln_idx1 = 17 ) THEN
        IF ( iv_item_name17 IS NULL ) THEN
          ln_idx1 := cn_param_count;
        ELSE
          l_name_value_tab(ln_idx1).item_name     := iv_item_name17;
          l_name_value_tab(ln_idx1).data_value    := iv_data_value17;
        END IF;
      ELSIF ( ln_idx1 = 18 ) THEN
        IF ( iv_item_name18 IS NULL ) THEN
          ln_idx1 := cn_param_count;
        ELSE
          l_name_value_tab(ln_idx1).item_name     := iv_item_name18;
          l_name_value_tab(ln_idx1).data_value    := iv_data_value18;
        END IF;
      ELSIF ( ln_idx1 = 19 ) THEN
        IF ( iv_item_name19 IS NULL ) THEN
          ln_idx1 := cn_param_count;
        ELSE
          l_name_value_tab(ln_idx1).item_name     := iv_item_name19;
          l_name_value_tab(ln_idx1).data_value    := iv_data_value19;
        END IF;
      ELSIF ( ln_idx1 = 20 ) THEN
        IF ( iv_item_name20 IS NULL ) THEN
          ln_idx1 := cn_param_count;
        ELSE
          l_name_value_tab(ln_idx1).item_name     := iv_item_name20;
          l_name_value_tab(ln_idx1).data_value    := iv_data_value20;
        END IF;
      END IF;
--
    END LOOP loop_set_param;
--
    --==============================================================
    --2.�p�����[�^�`�F�b�N
    --==============================================================
    IF ( l_name_value_tab.COUNT = cn_param_count) THEN
      --
      ln_idx1 := l_name_value_tab.COUNT;
      --
      <<loop_check_param>>
      LOOP
        --
        ln_idx1 := ln_idx1 + 1;
        --
        EXIT WHEN ln_idx1 > cn_param_count;
        --
        IF ( ( ln_idx1 = 1 ) AND ( iv_item_name1 IS NOT NULL ) ) THEN
          lv_retcode := cv_status_error;
        ELSIF ( ( ln_idx1 = 2 ) AND ( iv_item_name2 IS NOT NULL ) ) THEN
          lv_retcode := cv_status_error;
        ELSIF ( ( ln_idx1 = 3 ) AND ( iv_item_name3 IS NOT NULL ) ) THEN
          lv_retcode := cv_status_error;
        ELSIF ( ( ln_idx1 = 4 ) AND ( iv_item_name4 IS NOT NULL ) ) THEN
          lv_retcode := cv_status_error;
        ELSIF ( ( ln_idx1 = 5 ) AND ( iv_item_name5 IS NOT NULL ) ) THEN
          lv_retcode := cv_status_error;
        ELSIF ( ( ln_idx1 = 6 ) AND ( iv_item_name6 IS NOT NULL ) ) THEN
          lv_retcode := cv_status_error;
        ELSIF ( ( ln_idx1 = 7 ) AND ( iv_item_name7 IS NOT NULL ) ) THEN
          lv_retcode := cv_status_error;
        ELSIF ( ( ln_idx1 = 8 ) AND ( iv_item_name8 IS NOT NULL ) ) THEN
          lv_retcode := cv_status_error;
        ELSIF ( ( ln_idx1 = 9 ) AND ( iv_item_name9 IS NOT NULL ) ) THEN
          lv_retcode := cv_status_error;
        ELSIF ( ( ln_idx1 = 10 ) AND ( iv_item_name10 IS NOT NULL ) ) THEN
          lv_retcode := cv_status_error;
        ELSIF ( ( ln_idx1 = 11 ) AND ( iv_item_name11 IS NOT NULL ) ) THEN
          lv_retcode := cv_status_error;
        ELSIF ( ( ln_idx1 = 12 ) AND ( iv_item_name12 IS NOT NULL ) ) THEN
          lv_retcode := cv_status_error;
        ELSIF ( ( ln_idx1 = 13 ) AND ( iv_item_name13 IS NOT NULL ) ) THEN
          lv_retcode := cv_status_error;
        ELSIF ( ( ln_idx1 = 14 ) AND ( iv_item_name14 IS NOT NULL ) ) THEN
          lv_retcode := cv_status_error;
        ELSIF ( ( ln_idx1 = 15 ) AND ( iv_item_name15 IS NOT NULL ) ) THEN
          lv_retcode := cv_status_error;
        ELSIF ( ( ln_idx1 = 16 ) AND ( iv_item_name16 IS NOT NULL ) ) THEN
          lv_retcode := cv_status_error;
        ELSIF ( ( ln_idx1 = 17 ) AND ( iv_item_name17 IS NOT NULL ) ) THEN
          lv_retcode := cv_status_error;
        ELSIF ( ( ln_idx1 = 18 ) AND ( iv_item_name18 IS NOT NULL ) ) THEN
          lv_retcode := cv_status_error;
        ELSIF ( ( ln_idx1 = 19 ) AND ( iv_item_name19 IS NOT NULL ) ) THEN
          lv_retcode := cv_status_error;
        ELSIF ( ( ln_idx1 = 20 ) AND ( iv_item_name20 IS NOT NULL ) ) THEN
          lv_retcode := cv_status_error;
        END IF;
        --����
        IF ( lv_retcode <> cv_status_normal ) THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application        => ct_xxcos_appl_short_name,
                         iv_name               => ct_msg_in_param_err,
                         iv_token_name1        => cv_tkn_in_param,
                         iv_token_value1       => lt_str_item_name ||
                                                  cv_separator ||
                                                  TO_CHAR( ln_idx1 )
                       );
          ln_idx1 := cn_param_count;
        END IF;
--
      END LOOP loop_check_param;
--
    END IF;
--
    --�G���[�̏ꍇ�A���f������B
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    --3.�L�[���ҏW
    --==============================================================
    lv_key_info := NULL;
    --�ҏW����
    <<loop_makeup_key_info>>
    FOR i IN 1..l_name_value_tab.COUNT
    LOOP
      --���s�̕t��
      IF ( lv_key_info IS NOT NULL ) THEN
        lv_key_info := lv_key_info || cv_paragraph;
      END IF;
      --�p�����[�^�ҏW
      lv_key_info := lv_key_info ||
                     l_name_value_tab(i).item_name ||
                     cv_separator ||
                     l_name_value_tab(i).data_value;
    END LOOP loop_makeup_key_info;
--
    --==============================================================
    --4.�I������
    --==============================================================
    --�L�[���ԋp
    ov_key_info := lv_key_info;
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
  END makeup_key_info;
--
--
  /************************************************************************
   * Procedure Name  : get_uom_cnv
   * Description     : �P�ʊ��Z�擾
   ************************************************************************/
  PROCEDURE get_uom_cnv(
    iv_before_uom_code        IN            VARCHAR2,                       -- ���Z�O�P�ʃR�[�h
    in_before_quantity        IN            NUMBER,                         -- ���Z�O����
    iov_item_code             IN OUT NOCOPY VARCHAR2,                       -- �i�ڃR�[�h
    iov_organization_code     IN OUT NOCOPY VARCHAR2,                       -- �݌ɑg�D�R�[�h
    ion_inventory_item_id     IN OUT        NUMBER,                         -- �i�ڂh�c
    ion_organization_id       IN OUT        NUMBER,                         -- �݌ɑg�D�h�c
    iov_after_uom_code        IN OUT NOCOPY VARCHAR2,                       -- ���Z��P�ʃR�[�h
    on_after_quantity         OUT    NOCOPY NUMBER,                         -- ���Z�㐔��
    on_content                OUT    NOCOPY NUMBER,                         -- ����
    ov_errbuf                 OUT    NOCOPY VARCHAR2,                       -- �G���[�E���b�Z�[�W�G���[       #�Œ�#
    ov_retcode                OUT    NOCOPY VARCHAR2,                       -- ���^�[���E�R�[�h               #�Œ�#
    ov_errmsg                 OUT    NOCOPY VARCHAR2)                       -- ���[�U�[�E�G���[�E���b�Z�[�W   #�Œ�#
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_uom_cnv'; -- �v���O������
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
    --�̕����b�Z�[�W
    ct_msg_get_organization_id      CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-13559';            -- �݌ɑg�DID�擾
    ct_msg_organization_id          CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-13560';            -- �݌ɑg�DID
    ct_msg_mtl_parameters           CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-13561';            -- �݌ɑg�D�p�����[�^
    ct_msg_organization_code        CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-13552';            -- �݌ɑg�D�R�[�h
    ct_msg_before_uom_code          CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-13562';            -- ���Z�O�P�ʃR�[�h
    ct_msg_item_cd_item_id          CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-13567';            -- �i�ڃR�[�h�܂��͕i�ڂh�c
    ct_msg_uom_mst_err              CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-13588';            -- �P�ʃ}�X�^���o�^
    --
    -- �g�[�N��
    cv_tkn_uom_code                 CONSTANT  VARCHAR2(100) := 'UOM_CODE';
    -- �萔
    cn_0                            CONSTANT  NUMBER        := 0;
--
    -- *** ���[�J���ϐ� ***
    lt_primary_uom_code                       mtl_system_items_b.primary_uom_code%TYPE;          -- ��P��
    lt_conversion_rate                        mtl_uom_class_conversions.conversion_rate%TYPE;    -- ���Z��
    lt_pre_conversion_rate                    mtl_uom_class_conversions.conversion_rate%TYPE;    -- ���Z��
    lt_aft_conversion_rate                    mtl_uom_class_conversions.conversion_rate%TYPE;    -- ���Z��
    lt_base_conversion_rate                   mtl_uom_class_conversions.conversion_rate%TYPE;    -- ���Z��(�i�ڒP��)
    lv_uom_class                              mtl_units_of_measure.uom_class%TYPE;
    lv_base_uom_flag                          mtl_units_of_measure.base_uom_flag%TYPE;
    lv_base_uom_code                          mtl_units_of_measure.uom_code%TYPE;
    lv_before_uom_class                       mtl_units_of_measure.uom_class%TYPE;
    lv_before_uom_code                        mtl_units_of_measure.uom_code%TYPE;
    lv_after_uom_class                        mtl_units_of_measure.uom_class%TYPE;
    lv_after_uom_code                         mtl_units_of_measure.uom_code%TYPE;
    ln_quantity                               NUMBER;
    ln_content                                NUMBER;
    lv_key_info                               VARCHAR2(5000);
    --
    lv_no_data_flag                           VARCHAR2(1);
    --���b�Z�[�W�p������
    lt_str_prof_organization_code             fnd_new_messages.message_text%TYPE;
    lt_str_get_organization_id                fnd_new_messages.message_text%TYPE;
    lt_str_organization_id                    fnd_new_messages.message_text%TYPE;
    lt_str_mtl_parameters                     fnd_new_messages.message_text%TYPE;
    lt_str_organization_code                  fnd_new_messages.message_text%TYPE;
    lt_str_before_uom_code                    fnd_new_messages.message_text%TYPE;
    lt_str_item_cd_item_id                    fnd_new_messages.message_text%TYPE;
    lt_str_mtl_system_items                   fnd_new_messages.message_text%TYPE;
    lt_str_item_code                          fnd_new_messages.message_text%TYPE;
    lt_str_mtl_uom_class_conv                 fnd_new_messages.message_text%TYPE;
    lt_str_uom_code                           fnd_new_messages.message_text%TYPE;
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
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
    --==============================================================
    --1.�����`�F�b�N
    --==============================================================
    --==================================
    --1-1.���Z�O�P�ʃR�[�h��
    --    NULL�̏ꍇ�G���[
    --==================================
    IF ( iv_before_uom_code IS NULL ) THEN
      lt_str_before_uom_code            := xxccp_common_pkg.get_msg(
                                             iv_application        => ct_xxcos_appl_short_name,
                                             iv_name               => ct_msg_before_uom_code
                                           );                      -- ���Z�O�P�ʃR�[�h
      lv_errmsg                         := xxccp_common_pkg.get_msg(
                                             iv_application        => ct_xxcos_appl_short_name,
                                             iv_name               => ct_msg_require_param_err,
                                             iv_token_name1        => cv_tkn_in_param,
                                             iv_token_value1       => lt_str_before_uom_code
                                           );
      lv_errbuf                         := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    --==================================
    --1-2.���Z�O���ʂ�NULL�̏ꍇ�u0�v�ɕϊ�
    --==================================
    ln_quantity := NVL( in_before_quantity, 0 );
    --==================================
    --1-3.�݌ɑg�D�R�[�h����э݌ɑg�D�h�c��
    --    NULL�̏ꍇ�A�݌ɑg�D�R�[�h���擾
    --==================================
    IF ( ( iov_organization_code IS NULL )
      AND ( ion_organization_id IS NULL ) )
    THEN
      --==================================
      -- 1-3-1. �݌ɑg�D�R�[�h�̎擾
      --==================================
      iov_organization_code             := FND_PROFILE.VALUE( ct_prof_organization_code );
      --
      IF ( iov_organization_code        IS NULL ) THEN
        lt_str_prof_organization_code   := xxccp_common_pkg.get_msg(
                                             iv_application        => ct_xxcos_appl_short_name,
                                             iv_name               => ct_msg_prof_organization_code
                                           );                      -- XXCOI:�݌ɑg�D�R�[�h
        lv_errmsg                       := xxccp_common_pkg.get_msg(
                                             iv_application        => ct_xxcos_appl_short_name,
                                             iv_name               => ct_msg_get_profile_err,
                                             iv_token_name1        => cv_tkn_profile,
                                             iv_token_value1       => lt_str_prof_organization_code
                                           );
        lv_errbuf                       := lv_errmsg;
        RAISE global_api_expt;
      END IF;
--
      --==================================
      -- 1-3-2. �݌ɑg�D�h�c�̎擾
      --==================================
      ion_organization_id               := xxcoi_common_pkg.get_organization_id(
                                             iov_organization_code
                                           );
      --
      IF ( ion_organization_id IS NULL ) THEN
        lt_str_get_organization_id      := xxccp_common_pkg.get_msg(
                                             iv_application        => ct_xxcos_appl_short_name,
                                             iv_name               => ct_msg_get_organization_id
                                           );                      -- �݌ɑg�DID�擾
        lv_errmsg                       := xxccp_common_pkg.get_msg(
                                             iv_application        => ct_xxcos_appl_short_name,
                                             iv_name               => ct_msg_call_api_err,
                                             iv_token_name1        => cv_tkn_api_name,
                                             iv_token_value1       => lt_str_get_organization_id
                                           );
          lv_errbuf                     := lv_errmsg;
        RAISE global_api_expt;
      END IF;
      --
    ELSE
      IF ( iov_organization_code IS NULL ) THEN
        --==================================
        -- 1-3-3. �݌ɑg�D�R�[�h�̎擾
        --==================================
        iov_organization_code           := get_organization_code(
                                              ion_organization_id
                                            );
        --
        IF ( iov_organization_code IS NULL ) THEN
          lt_str_organization_id        := xxccp_common_pkg.get_msg(
                                             iv_application        => ct_xxcos_appl_short_name,
                                             iv_name               => ct_msg_organization_id
                                           );                      -- �݌ɑg�DID
          --
          xxcos_common_pkg.makeup_key_info(
            ov_errbuf                   => lv_errbuf,             -- �G���[�E���b�Z�[�W
            ov_retcode                  => lv_retcode,            -- ���^�[���R�[�h
            ov_errmsg                   => lv_errmsg,             -- ���[�U�E�G���[�E���b�Z�[�W
            ov_key_info                 => lv_key_info,           -- �ҏW���ꂽ�L�[���
            iv_item_name1               => lt_str_organization_id,
            iv_data_value1              => TO_CHAR( ion_organization_id )
          );
          --
          lt_str_mtl_parameters         := xxccp_common_pkg.get_msg(
                                             iv_application        => ct_xxcos_appl_short_name,
                                             iv_name               => ct_msg_mtl_parameters
                                           );                      -- �݌ɑg�D�p�����[�^
          lv_errmsg                     := xxccp_common_pkg.get_msg(
                                             iv_application        => ct_xxcos_appl_short_name,
                                             iv_name               => ct_msg_select_err,
                                             iv_token_name1        => cv_tkn_table_name,
                                             iv_token_value1       => lt_str_mtl_parameters,
                                             iv_token_name2        => cv_tkn_key_data,
                                             iv_token_value2       => lv_key_info
                                           );
          lv_errbuf                     := lv_errmsg;
          RAISE global_api_expt;
        END IF;
        --
      ELSE
        --==================================
        -- 1-3-4. �݌ɑg�D�h�c�̎擾
        --==================================
        ion_organization_id             := xxcoi_common_pkg.get_organization_id(
                                             iov_organization_code
                                           );
        --
        IF ( ion_organization_id IS NULL ) THEN
          lt_str_get_organization_id    := xxccp_common_pkg.get_msg(
                                             iv_application        => ct_xxcos_appl_short_name,
                                             iv_name               => ct_msg_get_organization_id
                                           );                      -- �݌ɑg�DID�擾
          lv_errmsg                     := xxccp_common_pkg.get_msg(
                                             iv_application        => ct_xxcos_appl_short_name,
                                             iv_name               => ct_msg_call_api_err,
                                             iv_token_name1        => cv_tkn_api_name,
                                             iv_token_value1       => lt_str_get_organization_id
                                           );
          lv_errbuf                     := lv_errmsg;
          RAISE global_api_expt;
        END IF;
        --
      END IF;
    END IF;
    --==================================
    --1-4.�i�ڃR�[�h����ѕi�ڂh�c��
    --    NULL�̏ꍇ�G���[
    --==================================
    IF ( ( iov_item_code IS NULL )
      AND ( ion_inventory_item_id IS NULL ) )
    THEN
      lt_str_item_cd_item_id            := xxccp_common_pkg.get_msg(
                                             iv_application        => ct_xxcos_appl_short_name,
                                             iv_name               => ct_msg_item_cd_item_id
                                           );                      -- �i�ڃR�[�h�܂��͕i�ڂh�c
      lv_errmsg                         := xxccp_common_pkg.get_msg(
                                             iv_application        => ct_xxcos_appl_short_name,
                                             iv_name               => ct_msg_require_param_err,
                                             iv_token_name1        => cv_tkn_in_param,
                                             iv_token_value1       => lt_str_item_cd_item_id
                                           );
      lv_errbuf                         := lv_errmsg;
      RAISE global_api_expt;
    ELSE
      IF (iov_item_code IS NULL ) THEN
        --==================================
        -- 1-4-1. �i�ڃR�[�h�̎擾
        --==================================
        BEGIN
          SELECT
            msib.segment1               item_code,                   -- �i�ڃR�[�h
            msib.primary_uom_code       primary_uom_code,            -- �i�ڊ�P��
            muom.uom_class              uom_class,                   -- �P�ʋ敪
            muom.base_uom_flag          base_uom_flag                -- ��P�ʃt���O
          INTO
            iov_item_code,
            lt_primary_uom_code,
            lv_uom_class,
            lv_base_uom_flag
          FROM
            mtl_system_items_b          msib,
            mtl_units_of_measure_tl     muom
          WHERE  msib.organization_id      = ion_organization_id
          AND    msib.inventory_item_id    = ion_inventory_item_id
          AND    msib.primary_uom_code     = muom.uom_code
          AND    muom.language             = userenv('lang')
          ;
        EXCEPTION
          WHEN OTHERS THEN
            lt_str_organization_code    := xxccp_common_pkg.get_msg(
                                             iv_application        => ct_xxcos_appl_short_name,
                                             iv_name               => ct_msg_organization_code
                                           );                      -- �݌ɑg�D�R�[�h
            lt_str_item_code            := xxccp_common_pkg.get_msg(
                                             iv_application        => ct_xxcos_appl_short_name,
                                             iv_name               => ct_msg_item_code
                                           );                      -- �i�ڃR�[�h
            --
            xxcos_common_pkg.makeup_key_info(
              ov_errbuf                 => lv_errbuf,              -- �G���[�E���b�Z�[�W
              ov_retcode                => lv_retcode,             -- ���^�[���R�[�h
              ov_errmsg                 => lv_errmsg,              -- ���[�U�E�G���[�E���b�Z�[�W
              ov_key_info               => lv_key_info,            -- �ҏW���ꂽ�L�[���
              iv_item_name1             => lt_str_organization_code,
              iv_data_value1            => iov_organization_code,
              iv_item_name2             => lt_str_item_code,
              iv_data_value2            => iov_item_code
            );
            --
            lt_str_mtl_system_items     := xxccp_common_pkg.get_msg(
                                             iv_application        => ct_xxcos_appl_short_name,
                                             iv_name               => ct_msg_mtl_system_items
                                           );                      -- �i�ڃ}�X�^
            lv_errmsg                   := xxccp_common_pkg.get_msg(
                                             iv_application        => ct_xxcos_appl_short_name,
                                             iv_name               => ct_msg_select_err,
                                             iv_token_name1        => cv_tkn_table_name,
                                             iv_token_value1       => lt_str_mtl_system_items,
                                             iv_token_name2        => cv_tkn_key_data,
                                             iv_token_value2       => lv_key_info
                                           );
            lv_errbuf                   := lv_errmsg;
            RAISE global_api_expt;
        END;
      ELSE
        --==================================
        -- 1-4-2. �i�ڂh�c�̎擾
        --==================================
        BEGIN
          SELECT
            msib.inventory_item_id      inventory_item_id,
            msib.primary_uom_code       primary_uom_code,
            muom.uom_class              uom_class,                   -- �P�ʋ敪
            muom.base_uom_flag          base_uom_flag                -- ��P�ʃt���O
          INTO
            ion_inventory_item_id,
            lt_primary_uom_code,
            lv_uom_class,
            lv_base_uom_flag
          FROM
            mtl_system_items_b          msib,
            mtl_units_of_measure_tl     muom
          WHERE  msib.organization_id      = ion_organization_id
          AND    msib.segment1             = iov_item_code
          AND    msib.primary_uom_code     = muom.uom_code
          AND    muom.language             = userenv('lang')
          ;
        EXCEPTION
          WHEN OTHERS THEN
            lt_str_organization_code    := xxccp_common_pkg.get_msg(
                                             iv_application        => ct_xxcos_appl_short_name,
                                             iv_name               => ct_msg_organization_code
                                           );                      -- �݌ɑg�D�R�[�h
            lt_str_item_code            := xxccp_common_pkg.get_msg(
                                             iv_application        => ct_xxcos_appl_short_name,
                                             iv_name               => ct_msg_item_code
                                           );                      -- �i�ڃR�[�h
            --
            xxcos_common_pkg.makeup_key_info(
              ov_errbuf                 => lv_errbuf,              -- �G���[�E���b�Z�[�W
              ov_retcode                => lv_retcode,             -- ���^�[���R�[�h
              ov_errmsg                 => lv_errmsg,              -- ���[�U�E�G���[�E���b�Z�[�W
              ov_key_info               => lv_key_info,            -- �ҏW���ꂽ�L�[���
              iv_item_name1             => lt_str_organization_code,
              iv_data_value1            => iov_organization_code,
              iv_item_name2             => lt_str_item_code,
              iv_data_value2            => iov_item_code
            );
            --
            lt_str_mtl_system_items     := xxccp_common_pkg.get_msg(
                                             iv_application        => ct_xxcos_appl_short_name,
                                             iv_name               => ct_msg_mtl_system_items
                                           );                      -- �i�ڃ}�X�^
            lv_errmsg                   := xxccp_common_pkg.get_msg(
                                             iv_application        => ct_xxcos_appl_short_name,
                                             iv_name               => ct_msg_select_err,
                                             iv_token_name1        => cv_tkn_table_name,
                                             iv_token_value1       => lt_str_mtl_system_items,
                                             iv_token_name2        => cv_tkn_key_data,
                                             iv_token_value2       => lv_key_info
                                           );
            lv_errbuf                   := lv_errmsg;
            RAISE global_api_expt;
        END;
      END IF;
    END IF;
    --==============================================================
    --2.���Z����
    --==============================================================
    --==================================
    --2-1.��P�ʃR�[�h�Ɗ��Z�O�R�[�h�P�ʂ̔�r
    --==================================
    IF ( lt_primary_uom_code = iv_before_uom_code ) THEN
      --==================================
      --2-1-1.�����ꍇ
      --==================================
      ln_content := 1;
    ELSE
      --==================================
      --2-1-2.�قȂ�ꍇ
      --==================================
      lt_conversion_rate := NULL;
      --
      BEGIN
        SELECT
          mucc.conversion_rate          conversion_rate  -- ���Z���[�g
        INTO
          lt_conversion_rate
        FROM
          mtl_uom_class_conversions     mucc             -- �敪�ԒP�ʊ��Z
        WHERE
          mucc.inventory_item_id        = ion_inventory_item_id    -- �i��ID
        AND mucc.to_uom_code            = iv_before_uom_code       -- ���Z��P�ʃR�[�h(��P�ʂ���̊��Z��)
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          -- �敪�ԒP�ʊ��Z�e�[�u���ɂȂ��ꍇ
          lv_no_data_flag := 'Y';
        WHEN OTHERS THEN
          lt_str_item_code              := xxccp_common_pkg.get_msg(
                                             iv_application        => ct_xxcos_appl_short_name,
                                             iv_name               => ct_msg_item_code
                                           );                      -- �i�ڃR�[�h
          lt_str_uom_code               := xxccp_common_pkg.get_msg(
                                             iv_application        => ct_xxcos_appl_short_name,
                                             iv_name               => ct_msg_uom_code
                                           );                      -- �P�ʃR�[�h
          --
          xxcos_common_pkg.makeup_key_info(
            ov_errbuf                   => lv_errbuf,              -- �G���[�E���b�Z�[�W
            ov_retcode                  => lv_retcode,             -- ���^�[���R�[�h
            ov_errmsg                   => lv_errmsg,              -- ���[�U�E�G���[�E���b�Z�[�W
            ov_key_info                 => lv_key_info,            -- �ҏW���ꂽ�L�[���
            iv_item_name1               => lt_str_item_code,
            iv_data_value1              => iov_item_code,
            iv_item_name2               => lt_str_uom_code,
            iv_data_value2              => iv_before_uom_code
          );
          --
          lt_str_mtl_uom_class_conv     := xxccp_common_pkg.get_msg(
                                             iv_application        => ct_xxcos_appl_short_name,
                                             iv_name               => ct_msg_mtl_uom_class_conv
                                           );                      -- �P�ʊ��Z�}�X�^
          lv_errmsg                     := xxccp_common_pkg.get_msg(
                                             iv_application        => ct_xxcos_appl_short_name,
                                             iv_name               => ct_msg_select_err,
                                             iv_token_name1        => cv_tkn_table_name,
                                             iv_token_value1       => lt_str_mtl_uom_class_conv,
                                             iv_token_name2        => cv_tkn_key_data,
                                             iv_token_value2       => lv_key_info
                                           );
          lv_errbuf                     := lv_errmsg;
          RAISE global_api_expt;
      END;
      --
      -- �敪�ԒP�ʊ��Z�e�[�u���ɂȂ��ꍇ
      IF ( lv_no_data_flag = 'Y' ) THEN
        -- 2008/12/25 �敪�ԒP�ʊ��Z�e�[�u���̐U�蕪��
        -- ���Z�O�P�ʃR�[�h�̒P�ʋ敪
        BEGIN
          SELECT  muom.uom_class            uom_class          -- �P�ʋ敪
          INTO    lv_before_uom_class
          FROM    mtl_units_of_measure_tl  muom
          WHERE   muom.uom_code   =  iv_before_uom_code
          AND     muom.language   =  userenv('lang');
        EXCEPTION
          WHEN  NO_DATA_FOUND THEN
            lv_errmsg                     := xxccp_common_pkg.get_msg(
                                               iv_application        => ct_xxcos_appl_short_name,
                                               iv_name               => ct_msg_uom_mst_err,
                                               iv_token_name1        => cv_tkn_uom_code,
                                               iv_token_value1       => iv_before_uom_code
                                             );
            lv_errbuf                     := lv_errmsg;
            RAISE global_api_expt;
          WHEN  OTHERS THEN
            RAISE  global_api_others_expt;
        END;
        --
        -- �P�ʋ敪�̔�r
        IF ( lv_uom_class = lv_before_uom_class ) THEN
          -- ����P�ʋ敪�̏ꍇ�A���Z�O�P�ʂƕi�ڊ�P�ʂƂ̊��Z���[�g���Z�o����
          -- (1) ���Z�O�P�ʂƊ�P�ʂƂ̊��Z���[�g���擾����
          BEGIN
            SELECT  muc.conversion_rate          conversion_rate
            INTO    lt_pre_conversion_rate
            FROM    mtl_uom_conversions     muc
            WHERE   muc.uom_code          = iv_before_uom_code
              AND   muc.inventory_item_id = cn_0
            ;
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              lt_str_item_code              := xxccp_common_pkg.get_msg(
                                                 iv_application        => ct_xxcos_appl_short_name,
                                                 iv_name               => ct_msg_item_code
                                               );                      -- �i�ڃR�[�h
              lt_str_uom_code               := xxccp_common_pkg.get_msg(
                                                 iv_application        => ct_xxcos_appl_short_name,
                                                 iv_name               => ct_msg_uom_code
                                               );                      -- �P�ʃR�[�h
              --
              xxcos_common_pkg.makeup_key_info(
                ov_errbuf                   => lv_errbuf,              -- �G���[�E���b�Z�[�W
                ov_retcode                  => lv_retcode,             -- ���^�[���R�[�h
                ov_errmsg                   => lv_errmsg,              -- ���[�U�E�G���[�E���b�Z�[�W
                ov_key_info                 => lv_key_info,            -- �ҏW���ꂽ�L�[���
                iv_item_name1               => lt_str_item_code,
                iv_data_value1              => iov_item_code,
                iv_item_name2               => lt_str_uom_code,
                iv_data_value2              => iv_before_uom_code
              );
              --
              lt_str_mtl_uom_class_conv     := xxccp_common_pkg.get_msg(
                                                 iv_application        => ct_xxcos_appl_short_name,
                                                 iv_name               => ct_msg_mtl_uom_class_conv
                                               );                      -- �P�ʊ��Z�}�X�^
              lv_errmsg                     := xxccp_common_pkg.get_msg(
                                                 iv_application        => ct_xxcos_appl_short_name,
                                                 iv_name               => ct_msg_select_err,
                                                 iv_token_name1        => cv_tkn_table_name,
                                                 iv_token_value1       => lt_str_mtl_uom_class_conv,
                                                 iv_token_name2        => cv_tkn_key_data,
                                                 iv_token_value2       => lv_key_info
                                               );
              lv_errbuf                     := lv_errmsg;
              RAISE  global_api_expt;
            WHEN  OTHERS THEN
              RAISE  global_api_others_expt;
          END;
          --
          -- (2) �i�ڂ̎�P�ʂƊ�P�ʂƂ̊��Z���[�g���擾����
          BEGIN
            SELECT  muc.conversion_rate          conversion_rate
            INTO    lt_base_conversion_rate
            FROM    mtl_uom_conversions     muc
            WHERE   muc.uom_code          = lt_primary_uom_code
              AND   muc.inventory_item_id = cn_0
            ;
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              lt_str_item_code              := xxccp_common_pkg.get_msg(
                                                 iv_application        => ct_xxcos_appl_short_name,
                                                 iv_name               => ct_msg_item_code
                                               );                      -- �i�ڃR�[�h
              lt_str_uom_code               := xxccp_common_pkg.get_msg(
                                                 iv_application        => ct_xxcos_appl_short_name,
                                                 iv_name               => ct_msg_uom_code
                                               );                      -- �P�ʃR�[�h
              --
              xxcos_common_pkg.makeup_key_info(
                ov_errbuf                   => lv_errbuf,              -- �G���[�E���b�Z�[�W
                ov_retcode                  => lv_retcode,             -- ���^�[���R�[�h
                ov_errmsg                   => lv_errmsg,              -- ���[�U�E�G���[�E���b�Z�[�W
                ov_key_info                 => lv_key_info,            -- �ҏW���ꂽ�L�[���
                iv_item_name1               => lt_str_item_code,
                iv_data_value1              => iov_item_code,
                iv_item_name2               => lt_str_uom_code,
                iv_data_value2              => iv_before_uom_code
              );
              --
              lt_str_mtl_uom_class_conv     := xxccp_common_pkg.get_msg(
                                                 iv_application        => ct_xxcos_appl_short_name,
                                                 iv_name               => ct_msg_mtl_uom_class_conv
                                               );                      -- �P�ʊ��Z�}�X�^
              lv_errmsg                     := xxccp_common_pkg.get_msg(
                                                 iv_application        => ct_xxcos_appl_short_name,
                                                 iv_name               => ct_msg_select_err,
                                                 iv_token_name1        => cv_tkn_table_name,
                                                 iv_token_value1       => lt_str_mtl_uom_class_conv,
                                                 iv_token_name2        => cv_tkn_key_data,
                                                 iv_token_value2       => lv_key_info
                                               );
              lv_errbuf                     := lv_errmsg;
              RAISE  global_api_expt;
            WHEN  OTHERS THEN
              RAISE  global_api_others_expt;
          END;
          --
          -- (1)��(2)�̌��ʂ�����A���Z���[�g�����߂�
          lt_conversion_rate     := lt_pre_conversion_rate / lt_base_conversion_rate;
        ELSE
          lt_str_item_code              := xxccp_common_pkg.get_msg(
                                             iv_application        => ct_xxcos_appl_short_name,
                                             iv_name               => ct_msg_item_code
                                           );                      -- �i�ڃR�[�h
          lt_str_uom_code               := xxccp_common_pkg.get_msg(
                                             iv_application        => ct_xxcos_appl_short_name,
                                             iv_name               => ct_msg_uom_code
                                           );                      -- �P�ʃR�[�h
          --
          xxcos_common_pkg.makeup_key_info(
            ov_errbuf                   => lv_errbuf,              -- �G���[�E���b�Z�[�W
            ov_retcode                  => lv_retcode,             -- ���^�[���R�[�h
            ov_errmsg                   => lv_errmsg,              -- ���[�U�E�G���[�E���b�Z�[�W
            ov_key_info                 => lv_key_info,            -- �ҏW���ꂽ�L�[���
            iv_item_name1               => lt_str_item_code,
            iv_data_value1              => iov_item_code,
            iv_item_name2               => lt_str_uom_code,
            iv_data_value2              => iv_before_uom_code
          );
          --
          lt_str_mtl_uom_class_conv     := xxccp_common_pkg.get_msg(
                                             iv_application        => ct_xxcos_appl_short_name,
                                             iv_name               => ct_msg_mtl_uom_class_conv
                                           );                      -- �P�ʊ��Z�}�X�^
          lv_errmsg                     := xxccp_common_pkg.get_msg(
                                             iv_application        => ct_xxcos_appl_short_name,
                                             iv_name               => ct_msg_select_err,
                                             iv_token_name1        => cv_tkn_table_name,
                                             iv_token_value1       => lt_str_mtl_uom_class_conv,
                                             iv_token_name2        => cv_tkn_key_data,
                                             iv_token_value2       => lv_key_info
                                           );
          lv_errbuf                     := lv_errmsg;
          RAISE global_api_expt;
        END IF;
      END IF;
      --
      ln_quantity             := ln_quantity * lt_conversion_rate;
      ln_content              := lt_conversion_rate;
    END IF;
    --==================================
    --2-2.���Z��P�ʃR�[�h��NULL���ۂ�
    --==================================
    IF ( iov_after_uom_code IS NULL ) THEN
      --==================================
      --2-2-1.NULL�̏ꍇ
      --==================================
      -- ��P��(�o��)�֊��Z
      iov_after_uom_code      := lt_primary_uom_code;
      on_after_quantity       := ln_quantity;
      on_content              := ln_content;
    ELSE
      IF ( lt_primary_uom_code = iov_after_uom_code ) THEN
        --==================================
        --2-2-2-1.NULL�łȂ��A��P�ʂƓ����ꍇ
        --==================================
        iov_after_uom_code      := lt_primary_uom_code;
        on_after_quantity       := ln_quantity;
        on_content              := ln_content;
      ELSE
        --==================================
        --2-2-2-2.NULL�łȂ��A��P�ʂƈقȂ�ꍇ
        --==================================
        lt_conversion_rate      := NULL;
        --
        BEGIN
          SELECT
            mucc.conversion_rate        conversion_rate
          INTO
            lt_conversion_rate
          FROM
            mtl_uom_class_conversions   mucc
          WHERE
            mucc.inventory_item_id      = ion_inventory_item_id
          AND mucc.to_uom_code          = iov_after_uom_code
          ;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            -- �敪�ԒP�ʊ��Z�e�[�u���ɂȂ��ꍇ
            lv_no_data_flag := 'Y';
          WHEN OTHERS THEN
            lt_str_item_code            := xxccp_common_pkg.get_msg(
                                             iv_application        => ct_xxcos_appl_short_name,
                                             iv_name               => ct_msg_item_code
                                           );                      -- �i�ڃR�[�h
            lt_str_uom_code             := xxccp_common_pkg.get_msg(
                                             iv_application        => ct_xxcos_appl_short_name,
                                             iv_name               => ct_msg_uom_code
                                           );                      -- �P�ʃR�[�h
            --
            xxcos_common_pkg.makeup_key_info(
              ov_errbuf                 => lv_errbuf,              -- �G���[�E���b�Z�[�W
              ov_retcode                => lv_retcode,             -- ���^�[���R�[�h
              ov_errmsg                 => lv_errmsg,              -- ���[�U�E�G���[�E���b�Z�[�W
              ov_key_info               => lv_key_info,            -- �ҏW���ꂽ�L�[���
              iv_item_name1             => lt_str_item_code,
              iv_data_value1            => iov_item_code,
              iv_item_name2             => lt_str_uom_code,
              iv_data_value2            => iov_after_uom_code
            );
            --
            lt_str_mtl_uom_class_conv   := xxccp_common_pkg.get_msg(
                                             iv_application        => ct_xxcos_appl_short_name,
                                             iv_name               => ct_msg_mtl_uom_class_conv
                                           );                      -- �P�ʊ��Z�}�X�^
            lv_errmsg                   := xxccp_common_pkg.get_msg(
                                             iv_application        => ct_xxcos_appl_short_name,
                                             iv_name               => ct_msg_select_err,
                                             iv_token_name1        => cv_tkn_table_name,
                                             iv_token_value1       => lt_str_mtl_uom_class_conv,
                                             iv_token_name2        => cv_tkn_key_data,
                                             iv_token_value2       => lv_key_info
                                           );
            lv_errbuf                   := lv_errmsg;
            RAISE global_api_expt;
        END;
        --
        IF ( lv_no_data_flag = 'Y' ) THEN
          -- 2008/12/25 �P�ʊ��Z�e�[�u���̐U�蕪��
          -- ���Z�O�P�ʃR�[�h�̒P�ʋ敪
          BEGIN
            SELECT  muom.uom_class            uom_class          -- �P�ʋ敪
            INTO    lv_before_uom_class
            FROM    mtl_units_of_measure_tl  muom
            WHERE   muom.uom_code   =  iv_before_uom_code
            AND     muom.language   =  userenv('lang');
          EXCEPTION
          WHEN  NO_DATA_FOUND THEN
              lv_errmsg                     := xxccp_common_pkg.get_msg(
                                                 iv_application        => ct_xxcos_appl_short_name,
                                                 iv_name               => ct_msg_uom_mst_err,
                                                 iv_token_name1        => cv_tkn_uom_code,
                                                 iv_token_value1       => iv_before_uom_code
                                               );
              lv_errbuf                     := lv_errmsg;
            RAISE global_api_expt;
            WHEN  OTHERS THEN
              RAISE  global_api_others_expt;
          END;
          --
          -- ���Z��P�ʃR�[�h�̒P�ʋ敪
          BEGIN
            SELECT  muom.uom_class            uom_class          -- �P�ʋ敪
            INTO    lv_after_uom_class
            FROM    mtl_units_of_measure_tl  muom
            WHERE   muom.uom_code   =  iov_after_uom_code
            AND     muom.language   =  userenv('lang');
          EXCEPTION
          WHEN  NO_DATA_FOUND THEN
              lv_errmsg                     := xxccp_common_pkg.get_msg(
                                                 iv_application        => ct_xxcos_appl_short_name,
                                                 iv_name               => ct_msg_uom_mst_err,
                                                 iv_token_name1        => cv_tkn_uom_code,
                                                 iv_token_value1       => iov_after_uom_code
                                               );
              lv_errbuf                     := lv_errmsg;
            RAISE global_api_expt;
            WHEN  OTHERS THEN
              RAISE  global_api_others_expt;
          END;
          -- �P�ʋ敪�̔�r
          IF ( lv_before_uom_class = lv_after_uom_class ) THEN
            -- ����P�ʋ敪�̏ꍇ�A���Z�O�P�ʂƊ��Z��P�ʂƂ̊��Z���[�g���Z�o����
            -- (2) ���Z��P�ʂƊ�P�ʂƂ̊��Z���[�g���擾����
            BEGIN
              SELECT  muc.conversion_rate          conversion_rate
              INTO    lt_aft_conversion_rate
              FROM    mtl_uom_conversions     muc
              WHERE   muc.uom_code          = iov_after_uom_code
                AND   muc.inventory_item_id = cn_0
              ;
            EXCEPTION
              WHEN NO_DATA_FOUND THEN
                lt_str_item_code              := xxccp_common_pkg.get_msg(
                                                   iv_application        => ct_xxcos_appl_short_name,
                                                   iv_name               => ct_msg_item_code
                                                 );                      -- �i�ڃR�[�h
                lt_str_uom_code               := xxccp_common_pkg.get_msg(
                                                   iv_application        => ct_xxcos_appl_short_name,
                                                   iv_name               => ct_msg_uom_code
                                                 );                      -- �P�ʃR�[�h
                --
                xxcos_common_pkg.makeup_key_info(
                  ov_errbuf                   => lv_errbuf,              -- �G���[�E���b�Z�[�W
                  ov_retcode                  => lv_retcode,             -- ���^�[���R�[�h
                  ov_errmsg                   => lv_errmsg,              -- ���[�U�E�G���[�E���b�Z�[�W
                  ov_key_info                 => lv_key_info,            -- �ҏW���ꂽ�L�[���
                  iv_item_name1               => lt_str_item_code,
                  iv_data_value1              => iov_item_code,
                  iv_item_name2               => lt_str_uom_code,
                  iv_data_value2              => iov_after_uom_code
                );
                --
                lt_str_mtl_uom_class_conv     := xxccp_common_pkg.get_msg(
                                                   iv_application        => ct_xxcos_appl_short_name,
                                                   iv_name               => ct_msg_mtl_uom_class_conv
                                                 );                      -- �P�ʊ��Z�}�X�^
                lv_errmsg                     := xxccp_common_pkg.get_msg(
                                                   iv_application        => ct_xxcos_appl_short_name,
                                                   iv_name               => ct_msg_select_err,
                                                   iv_token_name1        => cv_tkn_table_name,
                                                   iv_token_value1       => lt_str_mtl_uom_class_conv,
                                                   iv_token_name2        => cv_tkn_key_data,
                                                   iv_token_value2       => lv_key_info
                                                 );
                lv_errbuf                     := lv_errmsg;
                RAISE  global_api_expt;
              WHEN  OTHERS THEN
                RAISE  global_api_others_expt;
            END;
            --
            --
            IF ( lt_base_conversion_rate IS NULL ) THEN
              -- �i�ڂ̎�P�ʂƊ�P�ʂƂ̊��Z���[�g��NULL�Ȃ�Ύ擾����
              BEGIN
                SELECT  muc.conversion_rate          conversion_rate
                INTO    lt_base_conversion_rate
                FROM    mtl_uom_conversions     muc
                WHERE   muc.uom_code          = lt_primary_uom_code
                  AND   muc.inventory_item_id = cn_0
                ;
              EXCEPTION
                WHEN NO_DATA_FOUND THEN
                  lt_str_item_code              := xxccp_common_pkg.get_msg(
                                                     iv_application        => ct_xxcos_appl_short_name,
                                                     iv_name               => ct_msg_item_code
                                                   );                      -- �i�ڃR�[�h
                  lt_str_uom_code               := xxccp_common_pkg.get_msg(
                                                     iv_application        => ct_xxcos_appl_short_name,
                                                     iv_name               => ct_msg_uom_code
                                                   );                      -- �P�ʃR�[�h
                  --
                  xxcos_common_pkg.makeup_key_info(
                    ov_errbuf                   => lv_errbuf,              -- �G���[�E���b�Z�[�W
                    ov_retcode                  => lv_retcode,             -- ���^�[���R�[�h
                    ov_errmsg                   => lv_errmsg,              -- ���[�U�E�G���[�E���b�Z�[�W
                    ov_key_info                 => lv_key_info,            -- �ҏW���ꂽ�L�[���
                    iv_item_name1               => lt_str_item_code,
                    iv_data_value1              => iov_item_code,
                    iv_item_name2               => lt_str_uom_code,
                    iv_data_value2              => iv_before_uom_code
                  );
                  --
                  lt_str_mtl_uom_class_conv     := xxccp_common_pkg.get_msg(
                                                     iv_application        => ct_xxcos_appl_short_name,
                                                     iv_name               => ct_msg_mtl_uom_class_conv
                                                   );                      -- �P�ʊ��Z�}�X�^
                  lv_errmsg                     := xxccp_common_pkg.get_msg(
                                                     iv_application        => ct_xxcos_appl_short_name,
                                                     iv_name               => ct_msg_select_err,
                                                     iv_token_name1        => cv_tkn_table_name,
                                                     iv_token_value1       => lt_str_mtl_uom_class_conv,
                                                     iv_token_name2        => cv_tkn_key_data,
                                                     iv_token_value2       => lv_key_info
                                                   );
                  lv_errbuf                     := lv_errmsg;
                  RAISE  global_api_expt;
                WHEN  OTHERS THEN
                  RAISE  global_api_others_expt;
              END;
            END IF;
            --
            -- (1)��(2)�̌��ʂ�����A���Z���[�g�����߂�
            lt_conversion_rate := lt_aft_conversion_rate / lt_base_conversion_rate;
            --
          ELSE
            lt_str_item_code              := xxccp_common_pkg.get_msg(
                                               iv_application        => ct_xxcos_appl_short_name,
                                               iv_name               => ct_msg_item_code
                                             );                      -- �i�ڃR�[�h
            lt_str_uom_code               := xxccp_common_pkg.get_msg(
                                               iv_application        => ct_xxcos_appl_short_name,
                                               iv_name               => ct_msg_uom_code
                                             );                      -- �P�ʃR�[�h
            --
            xxcos_common_pkg.makeup_key_info(
              ov_errbuf                   => lv_errbuf,              -- �G���[�E���b�Z�[�W
              ov_retcode                  => lv_retcode,             -- ���^�[���R�[�h
              ov_errmsg                   => lv_errmsg,              -- ���[�U�E�G���[�E���b�Z�[�W
              ov_key_info                 => lv_key_info,            -- �ҏW���ꂽ�L�[���
              iv_item_name1               => lt_str_item_code,
              iv_data_value1              => iov_item_code,
              iv_item_name2               => lt_str_uom_code,
              iv_data_value2              => iov_after_uom_code
            );
            --
            lt_str_mtl_uom_class_conv     := xxccp_common_pkg.get_msg(
                                               iv_application        => ct_xxcos_appl_short_name,
                                               iv_name               => ct_msg_mtl_uom_class_conv
                                             );                      -- �P�ʊ��Z�}�X�^
            lv_errmsg                     := xxccp_common_pkg.get_msg(
                                               iv_application        => ct_xxcos_appl_short_name,
                                               iv_name               => ct_msg_select_err,
                                               iv_token_name1        => cv_tkn_table_name,
                                               iv_token_value1       => lt_str_mtl_uom_class_conv,
                                               iv_token_name2        => cv_tkn_key_data,
                                               iv_token_value2       => lv_key_info
                                             );
            lv_errbuf                     := lv_errmsg;
            RAISE global_api_expt;
          END IF;
        END IF;
        --
        --
        on_after_quantity       := ln_quantity / lt_conversion_rate;
        on_content              := lt_conversion_rate;
      END IF;
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
  END get_uom_cnv;
--
  /************************************************************************
   * Procedure Name  : get_delivered_from
   * Description     : �[�i�`�Ԏ擾
   ************************************************************************/
  PROCEDURE get_delivered_from(
    iv_subinventory_code      IN            VARCHAR2,                       -- �ۊǏꏊ�R�[�h,
    iv_sales_base_code        IN            VARCHAR2,                       -- ���㋒�_�R�[�h,
    iv_ship_base_code         IN            VARCHAR2,                       -- �o�׋��_�R�[�h,
    iov_organization_code     IN OUT NOCOPY VARCHAR2,                       -- �݌ɑg�D�R�[�h
    ion_organization_id       IN OUT        NUMBER,                         -- �݌ɑg�D�h�c
    ov_delivered_from         OUT    NOCOPY VARCHAR2,                       -- �[�i�`��
    ov_errbuf                 OUT    NOCOPY VARCHAR2,                       -- �G���[�E���b�Z�[�W�G���[       #�Œ�#
    ov_retcode                OUT    NOCOPY VARCHAR2,                       -- ���^�[���E�R�[�h               #�Œ�#
    ov_errmsg                 OUT    NOCOPY VARCHAR2)                       -- ���[�U�[�E�G���[�E���b�Z�[�W   #�Œ�#
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_delivered_from'; -- �v���O������
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
  --�̕����b�Z�[�W
    cv_msg_mem13559_date        CONSTANT VARCHAR2(20) := 'APP-XXCOS1-13559';   -- �݌ɑg�DID�擾
    cv_msg_mem13560_date        CONSTANT VARCHAR2(20) := 'APP-XXCOS1-13560';   -- �݌ɑg�DID
    cv_msg_mem13561_date        CONSTANT VARCHAR2(20) := 'APP-XXCOS1-13561';   -- �݌ɑg�D�p�����[�^
    cv_msg_mem13562_date        CONSTANT VARCHAR2(20) := 'APP-XXCOS1-13562';   -- �݌ɑg�D�R�[�h
    cv_msg_mem13563_date        CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00052';   -- �ۊǏꏊ�}�X�^
    cv_msg_mem13564_date        CONSTANT VARCHAR2(20) := 'APP-XXCOS1-13563';   -- �ۊǏꏊ�R�[�h
    cv_msg_mem13565_date        CONSTANT VARCHAR2(20) := 'APP-XXCOS1-13564';   -- ���㋒�_
    cv_msg_mem13566_date        CONSTANT VARCHAR2(20) := 'APP-XXCOS1-13565';   -- �o�׋��_
  --���b�Z�[�W�p������
    cv_str_get_organization_id  CONSTANT VARCHAR2(50) := xxccp_common_pkg.get_msg(
                                                            iv_application        =>  ct_xxcos_appl_short_name
                                                           ,iv_name               =>  cv_msg_mem13559_date
                                                         );                    -- �݌ɑg�DID�擾
    cv_str_organization_id      CONSTANT VARCHAR2(50) := xxccp_common_pkg.get_msg(
                                                            iv_application        =>  ct_xxcos_appl_short_name
                                                           ,iv_name               =>  cv_msg_mem13560_date
                                                         );                    -- �݌ɑg�DID
    cv_str_mtl_parameters       CONSTANT VARCHAR2(50) := xxccp_common_pkg.get_msg(
                                                            iv_application        =>  ct_xxcos_appl_short_name
                                                           ,iv_name               =>  cv_msg_mem13561_date
                                                         );                    -- �݌ɑg�D�p�����[�^
    cv_str_organization_code    CONSTANT VARCHAR2(50) := xxccp_common_pkg.get_msg(
                                                            iv_application        =>  ct_xxcos_appl_short_name
                                                           ,iv_name               =>  cv_msg_mem13562_date
                                                         );                    -- �݌ɑg�D�R�[�h
    cv_str_mtl_secondary_inv    CONSTANT VARCHAR2(50) := xxccp_common_pkg.get_msg(
                                                            iv_application        =>  ct_xxcos_appl_short_name
                                                           ,iv_name               =>  cv_msg_mem13563_date
                                                         );                    -- �ۊǏꏊ�}�X�^
    cv_str_subinventory_code    CONSTANT VARCHAR2(50) := xxccp_common_pkg.get_msg(
                                                            iv_application        =>  ct_xxcos_appl_short_name
                                                           ,iv_name               =>  cv_msg_mem13564_date
                                                         );                    -- �ۊǏꏊ�R�[�h
    cv_str_sales_base           CONSTANT VARCHAR2(50) := xxccp_common_pkg.get_msg(
                                                            iv_application        =>  ct_xxcos_appl_short_name
                                                           ,iv_name               =>  cv_msg_mem13565_date
                                                         );                    -- ���㋒�_
    cv_str_ship_base            CONSTANT VARCHAR2(50) := xxccp_common_pkg.get_msg(
                                                            iv_application        =>  ct_xxcos_appl_short_name
                                                           ,iv_name               =>  cv_msg_mem13566_date
                                                         );                    -- �o�׋��_
    --�N�C�b�N�R�[�h�^�C�v
    ct_qct_delivered_type       CONSTANT  fnd_lookup_types.lookup_type%TYPE
                                          := 'XXCOS1_DELIVERED_MST';           -- �[�i�`�ԋ敪����}�X�^
    --�N�C�b�N�R�[�h
    ct_qcc_car                  CONSTANT  fnd_lookup_values.lookup_code%TYPE
                                          :=  'CAR';                           -- �c�Ǝ�
    ct_qcc_direct               CONSTANT  fnd_lookup_values.lookup_code%TYPE
                                          :=  'DIRECT';                        -- �H�꒼��
    ct_qcc_main                 CONSTANT  fnd_lookup_values.lookup_code%TYPE
                                          :=  'MAIN';                          -- ���C���q��
    ct_qcc_other                CONSTANT  fnd_lookup_values.lookup_code%TYPE
                                          :=  'OTHER';                         -- ���q��
    ct_qcc_sales                CONSTANT  fnd_lookup_values.lookup_code%TYPE
                                          :=  'SALES';                         -- �����_�q�ɔ���
    --���C���q�Ƀt���O
    ct_main_subinv_flag_yes   CONSTANT  mtl_secondary_inventories.attribute6%TYPE
                                        :=  'Y';                                           --���C���q�ɂł���
    --�ۊǏꏊ����
    ct_subinv_type_sales_car  CONSTANT  mtl_secondary_inventories.attribute13%TYPE
                                        :=  '5';                                           --�c�Ǝ�
    ct_subinv_type_direct     CONSTANT  mtl_secondary_inventories.attribute13%TYPE
                                        :=  '11';                                          --����
    --�[�i�`��
    cv_delivered_from_car     CONSTANT   VARCHAR2(1)  :=  xxcos_common_pkg.get_specific_master(
                                                             it_lookup_type        => ct_qct_delivered_type
                                                            ,it_lookup_code        => ct_qcc_car
                                                          );                               --�c�Ǝ�
    cv_delivered_from_direct  CONSTANT   VARCHAR2(1)  :=  xxcos_common_pkg.get_specific_master(
                                                             it_lookup_type        => ct_qct_delivered_type
                                                            ,it_lookup_code        => ct_qcc_direct
                                                          );                               --�H�꒼��
    cv_delivered_from_main    CONSTANT   VARCHAR2(1)  :=  xxcos_common_pkg.get_specific_master(
                                                             it_lookup_type        => ct_qct_delivered_type
                                                            ,it_lookup_code        => ct_qcc_main
                                                          );                               --���C���q��
    cv_delivered_from_other   CONSTANT   VARCHAR2(1)  :=  xxcos_common_pkg.get_specific_master(
                                                             it_lookup_type        => ct_qct_delivered_type
                                                            ,it_lookup_code        => ct_qcc_other
                                                          );                               --���q��
    cv_delivered_from_sales   CONSTANT   VARCHAR2(1)  :=  xxcos_common_pkg.get_specific_master(
                                                             it_lookup_type        => ct_qct_delivered_type
                                                            ,it_lookup_code        => ct_qcc_sales
                                                          );                               --�����_�q�ɔ���
--
    -- *** ���[�J���ϐ� ***
    lt_main_subinv_flag                 mtl_secondary_inventories.attribute6%TYPE;         -- ���C���q��
    lt_subinv_type                      mtl_secondary_inventories.attribute13%TYPE;        -- �ۊǏꏊ����
--****************************** 2009/04/30 1.1 T.Kitajima ADD START ******************************--
    lt_ship_base_code                   mtl_secondary_inventories.attribute7%TYPE;         -- �o�׋��_�R�[�h
--****************************** 2009/04/30 1.1 T.Kitajima ADD  END  ******************************--
    lv_key_info                         VARCHAR2(5000);
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
    --==============================================================
    --0.������
    --==============================================================
    ov_delivered_from         :=  NULL;
--
    --==============================================================
    --1.�����`�F�b�N
    --==============================================================
    --==================================
    --1-1.�p�����[�^�`�F�b�N
    --==================================
    --==================================
    --1-1-1.�ۊǏꏊ�R�[�h�`�F�b�N
    --==================================
    IF ( iv_subinventory_code IS NULL ) THEN
      lv_key_info := cv_str_subinventory_code;
      RAISE global_nothing_expt;
    END IF;
    --==================================
    --1-1-2.���㋒�_�`�F�b�N
    --==================================
    IF ( iv_sales_base_code IS NULL ) THEN
      lv_key_info := cv_str_sales_base;
      RAISE global_nothing_expt;
    END IF;
--****************************** 2009/04/30 1.1 T.Kitajima DEL START ******************************--
--    --==================================
--    --1-1-3.�o�׋��_�`�F�b�N
--    --==================================
--    IF ( iv_ship_base_code IS NULL ) THEN
--      lv_key_info := cv_str_ship_base;
--      RAISE global_nothing_expt;
--    END IF;
--****************************** 2009/04/30 1.1 T.Kitajima DEL  END  ******************************--
    --==================================
    --1-2.�݌ɑg�D�R�[�h����э݌ɑg�D�h�c��
    --    NULL�̏ꍇ�A�݌ɑg�D�R�[�h���擾
    --==================================
    IF ( ( iov_organization_code IS NULL )
      AND ( ion_organization_id  IS NULL ) ) THEN
        --==================================
        -- 1-2-1. �݌ɑg�D�R�[�h�̎擾
        --==================================
        iov_organization_code           :=  FND_PROFILE.VALUE( ct_prof_organization_code );
        --
        IF ( iov_organization_code IS NULL ) THEN
          lv_errmsg           :=  xxccp_common_pkg.get_msg(
                                    iv_application        =>  ct_xxcos_appl_short_name,
                                    iv_name               =>  ct_msg_get_profile_err,
                                    iv_token_name1        =>  cv_tkn_profile,
                                    iv_token_value1       =>  ct_prof_organization_code
                                  );
          RAISE global_api_expt;
        END IF;
        --==================================
        -- 1-2-2. �݌ɑg�D�h�c�̎擾
        --==================================
        ion_organization_id             :=  xxcoi_common_pkg.get_organization_id(
                                              iov_organization_code
                                            );
        --
        IF ( ion_organization_id IS NULL ) THEN
          lv_errmsg           :=  xxccp_common_pkg.get_msg(
                                    iv_application        =>  ct_xxcos_appl_short_name,
                                    iv_name               =>  ct_msg_call_api_err,
                                    iv_token_name1        =>  cv_tkn_api_name,
                                    iv_token_value1       =>  cv_str_get_organization_id
                                  );
          RAISE global_api_expt;
        END IF;
        --
    ELSE
      IF ( iov_organization_code IS NULL ) THEN
        --==================================
        -- 1-2-3. �݌ɑg�D�R�[�h�̎擾
        --==================================
        iov_organization_code           :=  get_organization_code(
                                              ion_organization_id
                                            );
        --
        IF ( iov_organization_code IS NULL ) THEN
          --
          xxcos_common_pkg.makeup_key_info(
            ov_errbuf         =>  lv_errbuf,         --�G���[�E���b�Z�[�W
            ov_retcode        =>  lv_retcode,        --���^�[���R�[�h
            ov_errmsg         =>  lv_errmsg,         --���[�U�E�G���[�E���b�Z�[�W
            ov_key_info       =>  lv_key_info,       --�ҏW���ꂽ�L�[���
            iv_item_name1     =>  cv_str_organization_id,
            iv_data_value1    =>  TO_CHAR( ion_organization_id )
          );
          --
          lv_errmsg           :=  xxccp_common_pkg.get_msg(
                                    iv_application        =>  ct_xxcos_appl_short_name,
                                    iv_name               =>  ct_msg_select_err,
                                    iv_token_name1        =>  cv_tkn_table_name,
                                    iv_token_value1       =>  cv_str_mtl_parameters,
                                    iv_token_name2        =>  cv_tkn_key_data,
                                    iv_token_value2       =>  lv_key_info
                                  );
          RAISE global_api_expt;
        END IF;
        --
      ELSE
        --==================================
        -- 1-2-4. �݌ɑg�D�h�c�̎擾
        --==================================
        ion_organization_id             :=  xxcoi_common_pkg.get_organization_id(
                                              iov_organization_code
                                            );
        --
        IF ( ion_organization_id IS NULL ) THEN
          lv_errmsg           :=  xxccp_common_pkg.get_msg(
                                    iv_application        =>  ct_xxcos_appl_short_name,
                                    iv_name               =>  ct_msg_call_api_err,
                                    iv_token_name1        =>  cv_tkn_api_name,
                                    iv_token_value1       =>  cv_str_get_organization_id
                                  );
          RAISE global_api_expt;
        END IF;
        --
      END IF;
    END IF;
--
    --==============================================================
    --2.�ۊǏꏊ���擾
    --==============================================================
    BEGIN
--****************************** 2009/04/30 1.1 T.Kitajima MOD START ******************************--
--      SELECT msi.attribute6                main_subinv_class,
--             msi.attribute13               subinv_type
--             msi.attribute13               subinv_type,
--      INTO   lt_main_subinv_flag,
--             lt_subinv_type
--      FROM   mtl_secondary_inventories     msi
--      WHERE  msi.secondary_inventory_name  =   iv_subinventory_code
--      AND    msi.organization_id           =   ion_organization_id
--
      SELECT msi.attribute6                main_subinv_class,
             msi.attribute13               subinv_type,
             msi.attribute7                ship_base_code
      INTO   lt_main_subinv_flag,
             lt_subinv_type,
             lt_ship_base_code
      FROM   mtl_secondary_inventories     msi
      WHERE  msi.secondary_inventory_name  =   iv_subinventory_code
      AND    msi.organization_id           =   ion_organization_id
--****************************** 2009/04/30 1.1 T.Kitajima MOD  END  ******************************--
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        --
        xxcos_common_pkg.makeup_key_info(
          ov_errbuf         =>  lv_errbuf,         --�G���[�E���b�Z�[�W
          ov_retcode        =>  lv_retcode,        --���^�[���R�[�h
          ov_errmsg         =>  lv_errmsg,         --���[�U�E�G���[�E���b�Z�[�W
          ov_key_info       =>  lv_key_info,       --�ҏW���ꂽ�L�[���
          iv_item_name1     =>  cv_str_subinventory_code,
          iv_data_value1    =>  iv_subinventory_code,
          iv_item_name2     =>  cv_str_organization_code,
          iv_data_value2    =>  iov_organization_code
        );
        --
        lv_errmsg           :=  xxccp_common_pkg.get_msg(
                                  iv_application        =>  ct_xxcos_appl_short_name,
                                  iv_name               =>  ct_msg_select_err,
                                  iv_token_name1        =>  cv_tkn_table_name,
                                  iv_token_value1       =>  cv_str_mtl_secondary_inv,
                                  iv_token_name2        =>  cv_tkn_key_data,
                                  iv_token_value2       =>  lv_key_info
                                );
        RAISE global_api_expt;
    END;
--
--****************************** 2009/05/14 1.2 N.Maeda MOD START ******************************--
--    --==============================================================
--    --3.�[�i�`�ԕԋp
--    --==============================================================
--    IF ( lt_main_subinv_flag = ct_main_subinv_flag_yes ) THEN
--        ov_delivered_from     :=  cv_delivered_from_main;             --���C���q��
--    ELSE
--      IF ( lt_subinv_type = ct_subinv_type_sales_car ) THEN
--        ov_delivered_from     :=  cv_delivered_from_car;              --�c�Ǝ�
--      ELSIF ( lt_subinv_type = ct_subinv_type_direct ) THEN
--        ov_delivered_from     :=  cv_delivered_from_direct;           --�H�꒼��
----****************************** 2009/04/30 1.1 T.Kitajima MOD START ******************************--
----      ELSIF ( iv_sales_base_code != iv_ship_base_code ) THEN
--      ELSIF ( iv_sales_base_code != lt_ship_base_code ) THEN
----****************************** 2009/04/30 1.1 T.Kitajima MOD  END  ******************************--
--        ov_delivered_from     :=  cv_delivered_from_sales;            --�����_�q�ɔ���
--      ELSE
--        ov_delivered_from     :=  cv_delivered_from_other;            --���q��
--      END IF;
--    END IF;
    --==============================================================
    --3.�[�i�`�ԕԋp
    --==============================================================
    -- ���㋒�_ = �ۊǏꏊ�̋��_�̏ꍇ
    IF ( iv_sales_base_code = lt_ship_base_code )  THEN
      --���C���q�ɂ̏ꍇ
      IF ( lt_main_subinv_flag = ct_main_subinv_flag_yes ) THEN
        ov_delivered_from  :=  cv_delivered_from_main;      --���C���q��
      --�c�ƎԂ̏ꍇ
      ELSIF ( lt_subinv_type = ct_subinv_type_sales_car ) THEN
        ov_delivered_from  :=  cv_delivered_from_car;       --�c�Ǝ�
      ELSE
        ov_delivered_from  :=  cv_delivered_from_other;     --���q��
      END IF;
    -- ���㋒�_ <> �ۊǏꏊ�̋��_�̏ꍇ
    ELSE
      --�����̏ꍇ
      IF ( lt_subinv_type = ct_subinv_type_direct ) THEN
        ov_delivered_from  :=  cv_delivered_from_direct;    --�H�꒼��
      ELSE
        ov_delivered_from  :=  cv_delivered_from_sales;    --�����_�q�ɔ���
      END IF;
    END IF;
--****************************** 2009/05/14 1.2 N.Maeda MOD  END  ******************************--
--
  EXCEPTION
    -- �K�{�G���[
    WHEN global_nothing_expt        THEN
      ov_errmsg               :=  xxccp_common_pkg.get_msg(
        iv_application        =>  ct_xxcos_appl_short_name,
        iv_name               =>  ct_msg_require_param_err,
        iv_token_name1        =>  cv_tkn_in_param,
        iv_token_value1       =>  lv_key_info
      );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
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
  END get_delivered_from;
--
  /************************************************************************
   * Procedure Name  : get_sales_calendar_code
   * Description     : �̔��p�J�����_�R�[�h�擾
   ************************************************************************/
  PROCEDURE get_sales_calendar_code(
    iov_organization_code     IN OUT NOCOPY VARCHAR2,                       -- �݌ɑg�D�R�[�h
    ion_organization_id       IN OUT        NUMBER,                         -- �݌ɑg�D�h�c
    ov_calendar_code          OUT    NOCOPY VARCHAR2,                       -- �J�����_�R�[�h
    ov_errbuf                 OUT    NOCOPY VARCHAR2,                       -- �G���[�E���b�Z�[�W�G���[       #�Œ�#
    ov_retcode                OUT    NOCOPY VARCHAR2,                       -- ���^�[���E�R�[�h               #�Œ�#
    ov_errmsg                 OUT    NOCOPY VARCHAR2)                       -- ���[�U�[�E�G���[�E���b�Z�[�W   #�Œ�#
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_sales_calendar_code';      -- �v���O������
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
    ct_msg_get_organization_id      CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-13559';        -- �݌ɑg�DID�擾
    ct_msg_organization_id          CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-13560';        -- �݌ɑg�DID
    ct_msg_mtl_parameters           CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-13561';        -- �݌ɑg�D�p�����[�^
    ct_msg_organization_code        CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-13552';        -- �݌ɑg�D�R�[�h
--
    -- *** ���[�J���ϐ� ***
    lv_key_info                               VARCHAR2(5000);
    --���b�Z�[�W�p������
    lt_str_prof_organization_code             fnd_new_messages.message_text%TYPE;
    lt_str_get_organization_id                fnd_new_messages.message_text%TYPE;
    lt_str_organization_id                    fnd_new_messages.message_text%TYPE;
    lt_str_mtl_parameters                     fnd_new_messages.message_text%TYPE;
    lt_str_organization_code                  fnd_new_messages.message_text%TYPE;
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
    --==============================================================
    --0.������
    --==============================================================
    ov_calendar_code          :=  NULL;
--
    --==============================================================
    --1.�����`�F�b�N
    --==============================================================
    --==================================
    --1-1.�݌ɑg�D�R�[�h����э݌ɑg�D�h�c��
    --    NULL�̏ꍇ�A�݌ɑg�D�R�[�h���擾
    --==================================
    IF ( ( iov_organization_code IS NULL )
      AND ( ion_organization_id  IS NULL ) ) THEN
        --==================================
        -- 1-1-1. �݌ɑg�D�R�[�h�̎擾
        --==================================
        iov_organization_code           :=  FND_PROFILE.VALUE( ct_prof_organization_code );
        --
        IF ( iov_organization_code IS NULL ) THEN
          lt_str_prof_organization_code := xxccp_common_pkg.get_msg(
                                             iv_application        => ct_xxcos_appl_short_name,
                                             iv_name               => ct_msg_prof_organization_code
                                           );                      -- XXCOI:�݌ɑg�D�R�[�h
          lv_errmsg                     := xxccp_common_pkg.get_msg(
                                             iv_application        => ct_xxcos_appl_short_name,
                                             iv_name               => ct_msg_get_profile_err,
                                             iv_token_name1        => cv_tkn_profile,
                                             iv_token_value1       => lt_str_prof_organization_code
                                           );
          lv_errbuf                     := lv_errmsg;
          RAISE global_api_expt;
        END IF;
        --==================================
        -- 1-1-2. �݌ɑg�D�h�c�̎擾
        --==================================
        ion_organization_id   := xxcoi_common_pkg.get_organization_id(
                                   iov_organization_code
                                 );
        --
        IF ( ion_organization_id IS NULL ) THEN
          lt_str_get_organization_id    := xxccp_common_pkg.get_msg(
                                             iv_application        => ct_xxcos_appl_short_name,
                                             iv_name               => ct_msg_get_organization_id
                                           );                      -- �݌ɑg�DID�擾
          lv_errmsg                     := xxccp_common_pkg.get_msg(
                                             iv_application        => ct_xxcos_appl_short_name,
                                             iv_name               => ct_msg_call_api_err,
                                             iv_token_name1        => cv_tkn_api_name,
                                             iv_token_value1       => lt_str_get_organization_id
                                           );
          lv_errbuf                     := lv_errmsg;
          RAISE global_api_expt;
        END IF;
        --
    ELSE
      IF ( iov_organization_code IS NULL ) THEN
        --==================================
        -- 1-1-3. �݌ɑg�D�R�[�h�̎擾
        --==================================
        iov_organization_code           := get_organization_code(
                                             ion_organization_id
                                           );
        --
        IF ( iov_organization_code IS NULL ) THEN
          lt_str_organization_id        := xxccp_common_pkg.get_msg(
                                             iv_application        => ct_xxcos_appl_short_name,
                                             iv_name               => ct_msg_organization_id
                                           );                      -- �݌ɑg�DID
          --
          xxcos_common_pkg.makeup_key_info(
            ov_errbuf                   => lv_errbuf,              -- �G���[�E���b�Z�[�W
            ov_retcode                  => lv_retcode,             -- ���^�[���R�[�h
            ov_errmsg                   => lv_errmsg,              -- ���[�U�E�G���[�E���b�Z�[�W
            ov_key_info                 => lv_key_info,            -- �ҏW���ꂽ�L�[���
            iv_item_name1               => lt_str_organization_id,
            iv_data_value1              => TO_CHAR( ion_organization_id )
          );
          --
          lt_str_mtl_parameters         := xxccp_common_pkg.get_msg(
                                             iv_application        => ct_xxcos_appl_short_name,
                                             iv_name               => ct_msg_mtl_parameters
                                           );                      -- �݌ɑg�D�p�����[�^
          lv_errmsg                     := xxccp_common_pkg.get_msg(
                                             iv_application        => ct_xxcos_appl_short_name,
                                             iv_name               => ct_msg_select_err,
                                             iv_token_name1        => cv_tkn_table_name,
                                             iv_token_value1       => lt_str_mtl_parameters,
                                             iv_token_name2        => cv_tkn_key_data,
                                             iv_token_value2       => lv_key_info
                                           );
          lv_errbuf                     := lv_errmsg;
          RAISE global_api_expt;
        END IF;
        --
      ELSE
        --==================================
        -- 1-1-4. �݌ɑg�D�h�c�̎擾
        --==================================
        ion_organization_id             := xxcoi_common_pkg.get_organization_id(
                                             iov_organization_code
                                           );
        --
        IF ( ion_organization_id IS NULL ) THEN
          lt_str_get_organization_id    := xxccp_common_pkg.get_msg(
                                             iv_application        => ct_xxcos_appl_short_name,
                                             iv_name               => ct_msg_get_organization_id
                                           );                      -- �݌ɑg�DID�擾
          lv_errmsg                     := xxccp_common_pkg.get_msg(
                                             iv_application        => ct_xxcos_appl_short_name,
                                             iv_name               => ct_msg_call_api_err,
                                             iv_token_name1        => cv_tkn_api_name,
                                             iv_token_value1       => lt_str_get_organization_id
                                           );
          lv_errbuf                     := lv_errmsg;
          RAISE global_api_expt;
        END IF;
        --
      END IF;
    END IF;
--
    --==============================================================
    --2.�J�����_�R�[�h�擾
    --==============================================================
    BEGIN
      SELECT
        mp.calendar_code                calendar_code
      INTO
        ov_calendar_code
      FROM
        mtl_parameters                  mp
      WHERE
        mp.organization_id              = ion_organization_id
      ;
    EXCEPTION
      WHEN OTHERS   THEN
        lt_str_organization_code        := xxccp_common_pkg.get_msg(
                                             iv_application        => ct_xxcos_appl_short_name,
                                             iv_name               => ct_msg_organization_code
                                           );                      -- �݌ɑg�D�R�[�h
        --
        xxcos_common_pkg.makeup_key_info(
          ov_errbuf                     => lv_errbuf,              -- �G���[�E���b�Z�[�W
          ov_retcode                    => lv_retcode,             -- ���^�[���R�[�h
          ov_errmsg                     => lv_errmsg,              -- ���[�U�E�G���[�E���b�Z�[�W
          ov_key_info                   => lv_key_info,            -- �ҏW���ꂽ�L�[���
          iv_item_name1                 => lt_str_organization_code,
          iv_data_value1                => iov_organization_code
        );
        --
        lt_str_mtl_parameters           := xxccp_common_pkg.get_msg(
                                             iv_application        => ct_xxcos_appl_short_name,
                                             iv_name               => ct_msg_mtl_parameters
                                           );                      -- �݌ɑg�D�p�����[�^
        lv_errmsg                       := xxccp_common_pkg.get_msg(
                                             iv_application        => ct_xxcos_appl_short_name,
                                             iv_name               => ct_msg_select_err,
                                             iv_token_name1        => cv_tkn_table_name,
                                             iv_token_value1       => lt_str_mtl_parameters,
                                             iv_token_name2        => cv_tkn_key_data,
                                             iv_token_value2       => lv_key_info
                                           );
        lv_errbuf                       := lv_errmsg;
        RAISE global_api_expt;
    END;
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
  END get_sales_calendar_code;
--
  /************************************************************************
   * Function Name   : check_sales_oprtn_day
   * Description     : �̔��p�ғ����`�F�b�N
   ************************************************************************/
  FUNCTION check_sales_oprtn_day(
    id_check_target_date      IN            DATE,                           -- �`�F�b�N�Ώۓ��t
    iv_calendar_code          IN            VARCHAR2                        -- �J�����_�R�[�h
  ) RETURN  NUMBER
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'check_sales_oprtn_day'; -- �v���O������
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
    --�ғ����敪
    cn_sales_oprtn_day_normal   CONSTANT NUMBER := 0;                 --�ғ���
    cn_sales_oprtn_day_non      CONSTANT NUMBER := 1;                 --��ғ���
    cn_sales_oprtn_day_error    CONSTANT NUMBER := 2;                 --�G���[
--
    -- *** ���[�J���ϐ� ***
    lt_seq_num                           bom_calendar_dates.seq_num%TYPE;                  --�A��
    lt_calendar_date                     bom_calendar_dates.calendar_date%TYPE;            --�J�����_���t
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
--
  BEGIN
--
    --==============================================================
    --0.������
    --==============================================================
    lt_calendar_date := TRUNC( id_check_target_date );
--
    --==============================================================
    --1.�ғ����J�����_�`�F�b�N
    --==============================================================
    SELECT
      bcd.seq_num                       seq_num
    INTO
      lt_seq_num
    FROM
      bom_calendar_dates                bcd
    WHERE
      bcd.calendar_code                 = iv_calendar_code
    AND bcd.calendar_date               = lt_calendar_date
    ;
--
    --==============================================================
    --2.�ԋp
    --==============================================================
    IF ( lt_seq_num IS NOT NULL ) THEN
      RETURN cn_sales_oprtn_day_normal;
    ELSE
      RETURN cn_sales_oprtn_day_non;
    END IF;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
    WHEN OTHERS THEN
     RETURN cn_sales_oprtn_day_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END check_sales_oprtn_day;
--
  /**********************************************************************************
   * Procedure Name   : get_period_year
   * Description      : ���N�x��v���Ԏ擾
   ***********************************************************************************/
  PROCEDURE get_period_year(
    id_base_date              IN         DATE,           -- ���
    od_start_date             OUT NOCOPY DATE,           -- ���N�x��v�J�n��
    od_end_date               OUT NOCOPY DATE,           -- ���N�x��v�I����
    ov_errbuf                 OUT NOCOPY VARCHAR2,       -- �G���[�E���b�Z�[�W�G���[       #�Œ�#
    ov_retcode                OUT NOCOPY VARCHAR2,       -- ���^�[���E�R�[�h               #�Œ�#
    ov_errmsg                 OUT NOCOPY VARCHAR2)       -- ���[�U�[�E�G���[�E���b�Z�[�W   #�Œ�#
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_period_year'; -- �v���O������
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
  --�̕����b�Z�[�W
    cv_msg_mem1_date    CONSTANT VARCHAR2(20) := 'APP-XXCOS1-13558';   -- ���
    cv_msg_mem2_date    CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00060';   -- GL��v����ID
  --���b�Z�[�W�p������
    cv_str_base_date    CONSTANT VARCHAR2(50) := xxccp_common_pkg.get_msg(
                                                    iv_application        =>  ct_xxcos_appl_short_name
                                                   ,iv_name               =>  cv_msg_mem1_date
                                                 );                    -- ���
    cv_str_gl_set_of_bks_id CONSTANT VARCHAR2(50)
                                              := xxccp_common_pkg.get_msg(
                                                    iv_application        =>  ct_xxcos_appl_short_name
                                                   ,iv_name               =>  cv_msg_mem2_date
                                                 );                    -- GL��v����ID
    cv_yes_no_flg_n     CONSTANT VARCHAR2(1)  := 'N';                  -- N
    -- *** ���[�J���ϐ� ***
--
    ln_id_key           NUMBER;          --�v���t�@�C���l
    ld_period_date      DATE;            --���N�x��v�J�n�N����
    lv_key_info         VARCHAR2(5000);  --key���
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
    --==============================================================
    --�����`�F�b�N
    --==============================================================
    IF ( id_base_date IS NULL ) THEN
      RAISE global_nothing_expt;
    END IF;
--
    --==============================================================
    --�v���t�@�C�������擾���܂�
    --==============================================================
    ln_id_key := FND_PROFILE.VALUE( ct_prof_gl_set_of_bks_id );
    --GL��v����ID
    IF ( ln_id_key IS NULL ) THEN
      lv_key_info      := cv_str_gl_set_of_bks_id;
      --���b�Z�[�W
      IF ( lv_retcode = cv_status_normal ) THEN
        RAISE global_get_profile_expt;
      ELSE
        RAISE global_api_expt;
      END IF;
    END IF;
--
    --==============================================================
    --GL:��v����}�X�^�AGL:�s���I�h�}�X�^�����v�J�n�N�x���擾���܂��B
    --==============================================================
    SELECT glp.year_start_date
    INTO   ld_period_date
    FROM   gl_sets_of_books glb,
           gl_periods       glp
    WHERE  glb.set_of_books_id         = ln_id_key
    AND    glb.period_set_name         = glp.period_set_name
    AND    glb.accounted_period_type   = glp.period_type
    AND    glp.adjustment_period_flag  = cv_yes_no_flg_n
    AND    glp.start_date             <= id_base_date
    AND    glp.end_date               >= id_base_date
    ;
--
    od_start_date :=ld_period_date;
    od_end_date   :=ADD_MONTHS( ld_period_date, 12 ) - 1;
--
  EXCEPTION
    -- �K�{�G���[
    WHEN global_nothing_expt        THEN
      ov_errmsg               :=  xxccp_common_pkg.get_msg(
        iv_application        =>  ct_xxcos_appl_short_name,
        iv_name               =>  ct_msg_require_param_err,
        iv_token_name1        =>  cv_tkn_in_param,
        iv_token_value1       =>  cv_str_base_date
      );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
    -- �v���t�@�C���擾�G���[
    WHEN global_get_profile_expt    THEN
      ov_errmsg               :=  xxccp_common_pkg.get_msg(
        iv_application        =>  ct_xxcos_appl_short_name,
        iv_name               =>  ct_msg_get_profile_err,
        iv_token_name1        =>  cv_tkn_profile,
        iv_token_value1       =>  lv_key_info
      );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
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
  END get_period_year;
--
  /************************************************************************
   * Procedure Name  : get_account_period
   * Description     : ��v���ԏ��擾
   ************************************************************************/
  PROCEDURE get_account_period(
    iv_account_period         IN            VARCHAR2,                       -- ��v�敪
    id_base_date              IN            DATE,                           -- ���
    ov_status                 OUT    NOCOPY VARCHAR2,                       -- �X�e�[�^�X
    od_start_date             OUT    NOCOPY DATE,                           -- ��v(FROM)
    od_end_date               OUT    NOCOPY DATE,                           -- ��v(TO)
    ov_errbuf                 OUT    NOCOPY VARCHAR2,                       -- �G���[�E���b�Z�[�W�G���[       #�Œ�#
    ov_retcode                OUT    NOCOPY VARCHAR2,                       -- ���^�[���E�R�[�h               #�Œ�#
    ov_errmsg                 OUT    NOCOPY VARCHAR2)                       -- ���[�U�[�E�G���[�E���b�Z�[�W   #�Œ�#
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_account_period'; -- �v���O������
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
    cv_acc_period_msg   CONSTANT VARCHAR2(20) := 'APP-XXCOS1-13551';         -- �g�[�N���l[��v���ԋ敪]
    cv_org_code_msg     CONSTANT VARCHAR2(20) := 'APP-XXCOS1-13552';         -- �g�[�N���l[�݌ɑg�D�R�[�h]
    cv_inv_prd_err1_msg CONSTANT VARCHAR2(20) := 'APP-XXCOS1-13553';         -- �݌ɉ�v���Ԏ擾�G���[(���t���w��)
    cv_inv_prd_err2_msg CONSTANT VARCHAR2(20) := 'APP-XXCOS1-13554';         -- �݌ɉ�v���Ԏ擾�G���[(���t�w��)
    cv_set_of_bks_msg   CONSTANT VARCHAR2(20) := 'APP-XXCOS1-13555';         -- �g�[�N���l[GL��v����]
    cv_ar_prd_err1_msg  CONSTANT VARCHAR2(20) := 'APP-XXCOS1-13556';         -- AR��v���Ԏ擾�G���[(���t���w��)
    cv_ar_prd_err2_msg  CONSTANT VARCHAR2(20) := 'APP-XXCOS1-13557';         -- AR��v���Ԏ擾�G���[(���t�w��)
    cv_org_id_err_msg   CONSTANT VARCHAR2(20) := 'APP-XXCOI1-00006';         -- �݌ɑg�DID�擾�G���[���b�Z�[�W
    cv_acc_lookup_type  CONSTANT VARCHAR2(30) := 'XXCOS1_ACCOUNT_PERIOD';    -- ��v���ԋ敪
    cv_tkn_ja           CONSTANT VARCHAR2(2)  := 'JA';                       -- JA
    cv_acc_period_inv   CONSTANT VARCHAR2(2)  := '01';                       -- INV��v����
    cv_acc_period_ar    CONSTANT VARCHAR2(2)  := '02';                       -- AR��v����
    cv_open_flag_y      CONSTANT VARCHAR2(1)  := 'Y';                        -- OPEN�t���O[Y]
    cv_status_close     CONSTANT VARCHAR2(5)  := 'CLOSE';                    -- �X�e�[�^�X[CLOSE]
    cv_status_open      CONSTANT VARCHAR2(5)  := 'OPEN';                     -- �X�e�[�^�X[OPEN]
    cv_app_short_nm_ar  CONSTANT VARCHAR2(2)  := 'AR';                       -- �A�v���P�[�V�����Z�k��(AR)
    cv_closing_sts_opn  CONSTANT VARCHAR2(1)  := 'O';                        -- AR��v���ԃN���[�Y�X�e�[�^�X(O)
    cv_ad_period_flag   CONSTANT VARCHAR2(1)  := 'N';                        -- AR��v���ԃt���O(N)
    cv_yyyymm_fmt       CONSTANT VARCHAR2(6)  := 'YYYYMM';                   -- �N���t�H�[�}�b�g
--
    cv_tkn_profile      CONSTANT VARCHAR2(20) := 'PROFILE';                  -- �v���t�@�C��
    cv_tkn_in_param     CONSTANT VARCHAR2(20) := 'IN_PARAM';                 -- ���̓p�����[�^
    cv_tkn_pro_tok      CONSTANT VARCHAR2(20) := 'ORG_CODE_TOK';             -- �݌ɑg�D�R�[�h
    cv_tkn_org_id       CONSTANT VARCHAR2(20) := 'ORG_ID';                   -- �݌ɑg�DID
    cv_tkn_open_flag    CONSTANT VARCHAR2(20) := 'OPEN_FLAG';                -- �I�[�v���t���O
    cv_tkn_close_flag   CONSTANT VARCHAR2(20) := 'CLOSE_FLAG';               -- �N���[�Y�t���O
    cv_tkn_base_date    CONSTANT VARCHAR2(20) := 'BASE_DATE';                -- ���
    cv_tkn_book_id      CONSTANT VARCHAR2(20) := 'BOOK_ID';                  -- GL��v����ID
--
    -- *** ���[�J���ϐ� ***
--
    ln_id_key           NUMBER;
    ld_period_date      DATE;
    ln_lookup_cnt       NUMBER;                                    -- ��v���ԋ敪�`�F�b�N���ʌ���
    lv_tkn1             VARCHAR2(50);                              -- �g�[�N���l
    lv_tkn2             VARCHAR2(50);                              -- �g�[�N���l
    lv_organization_cd  mtl_parameters.organization_code%TYPE;     -- �݌ɑg�D�R�[�h
    ln_organization_id  mtl_parameters.organization_id%TYPE;       -- �݌ɑg�DID
    lv_status           VARCHAR2(6);                               -- �X�e�[�^�X
    lv_open_flag        org_acct_periods.open_flag%TYPE;           -- �I�[�v���t���O
    lv_close_flag       gl_period_statuses.closing_status%TYPE;    -- �N���[�Y�t���O
    ld_start_date       org_acct_periods.period_start_date%TYPE;   -- ��v(FROM)
    ld_end_date         org_acct_periods.schedule_close_date%TYPE; -- ��v(TO)
    ld_set_of_books_id  gl_period_statuses.set_of_books_id%TYPE;   -- GL��v����ID
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
    --==============================================================
    -- �p�����[�^[��v�敪]�`�F�b�N
    --==============================================================
    -- ��v�敪 �ݒ�`�F�b�N
    IF ( iv_account_period IS NULL ) THEN
      lv_tkn1   := xxccp_common_pkg.get_msg( ct_xxcos_appl_short_name, cv_acc_period_msg );
      lv_errbuf := xxccp_common_pkg.get_msg( ct_xxcos_appl_short_name, ct_msg_require_param_err, cv_tkn_in_param, lv_tkn1 );
      lv_errmsg := lv_errbuf;
      RAISE global_api_expt;
    END IF;
--
    -- ��v�敪 �l�`�F�b�N
    BEGIN
-- ******************** 2009/08/03 1.3 N.Maeda MOD START ******************************--
--      SELECT  COUNT(1)
--      INTO    ln_lookup_cnt
--      FROM    fnd_lookup_values     look_val,
--              fnd_lookup_types_tl   types_tl,
--              fnd_lookup_types      types,
--              fnd_application_tl    appl,
--              fnd_application       app
--      WHERE   appl.application_id   = types.application_id
--      AND     app.application_id    = appl.application_id
--      AND     types_tl.lookup_type  = look_val.lookup_type
--      AND     types.lookup_type     = types_tl.lookup_type
--      AND     types.security_group_id   = types_tl.security_group_id
--      AND     types.view_application_id = types_tl.view_application_id
--      AND     types_tl.language = cv_tkn_ja
--      AND     look_val.language = cv_tkn_ja
--      AND     appl.language     = cv_tkn_ja
--      AND     app.application_short_name = ct_xxcos_appl_short_name
--      AND     look_val.lookup_type       = cv_acc_lookup_type
--      AND     look_val.meaning           = iv_account_period
--      AND     ROWNUM = 1
--      ;
--
      SELECT  COUNT(1)
      INTO    ln_lookup_cnt
      FROM    fnd_lookup_values     look_val
      WHERE   look_val.language     = cv_tkn_ja
      AND     look_val.lookup_type  = cv_acc_lookup_type
      AND     look_val.meaning      = iv_account_period
      ;
-- ******************** 2009/08/03 1.3 N.Maeda MOD  END  ******************************--
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- ��v�敪 �l�s���G���[
        lv_tkn1   := xxccp_common_pkg.get_msg( ct_xxcos_appl_short_name, cv_acc_period_msg );
        lv_errbuf := xxccp_common_pkg.get_msg( ct_xxcos_appl_short_name, ct_msg_in_param_err, cv_tkn_in_param, lv_tkn1 );
        lv_errmsg := lv_errbuf;
        RAISE global_api_expt;
    END;
--
    IF ( ln_lookup_cnt < 1 ) THEN
      -- ��v�敪 �l�s���G���[
      lv_tkn1   := xxccp_common_pkg.get_msg( ct_xxcos_appl_short_name, cv_acc_period_msg );
      lv_errbuf := xxccp_common_pkg.get_msg( ct_xxcos_appl_short_name, ct_msg_in_param_err, cv_tkn_in_param, lv_tkn1 );
      lv_errmsg := lv_errbuf;
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    -- �p�����[�^[��v���ԋ敪]�ɂ�鏈���U�蕪��
    --==============================================================
    --==============================================================
    -- AR��v���Ԃ̏ꍇ
    --==============================================================
    IF ( iv_account_period = cv_acc_period_ar ) THEN
--
      -- �v���t�@�C������GL��v����ID���擾
      ld_set_of_books_id := FND_PROFILE.VALUE( ct_prof_gl_set_of_bks_id );
      -- GL��v����ID�擾�G���[�̏ꍇ
      IF ( ld_set_of_books_id IS NULL ) THEN
        lv_tkn1   := xxccp_common_pkg.get_msg( ct_xxcos_appl_short_name, cv_set_of_bks_msg );
        lv_errmsg := xxccp_common_pkg.get_msg( ct_xxcos_appl_short_name, ct_msg_get_profile_err, cv_tkn_profile, lv_tkn1 );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
--
      -- �p�����[�^�̊�����ݒ肳��Ă��Ȃ��ꍇ
      IF ( id_base_date IS NULL ) THEN
--
        BEGIN
--
          -- �I�[�v�����Ă����ԌÂ�AR��v���Ԃ̉�v(FROM)�Ɖ�v(TO)���擾����
          SELECT  gps.start_date   start_date,
                  gps.end_date     close_date
          INTO    ld_start_date,
                  ld_end_date
          FROM    gl_period_statuses  gps,
                  fnd_application_vl  fav,
                  ( SELECT  MIN( gps.period_name ) min_period_name
                    FROM    gl_period_statuses  gps,
                            fnd_application_vl  fav
                    WHERE   gps.application_id  = fav.application_id
                    AND     gps.set_of_books_id = ld_set_of_books_id
                    AND     gps.closing_status  = cv_closing_sts_opn
                    AND     gps.adjustment_period_flag = cv_ad_period_flag
                    AND     fav.application_short_name = cv_app_short_nm_ar
                  ) min_ar_prd
          WHERE   gps.application_id  = fav.application_id
          AND     gps.set_of_books_id = ld_set_of_books_id
          AND     gps.closing_status  = cv_closing_sts_opn
          AND     gps.adjustment_period_flag = cv_ad_period_flag
          AND     fav.application_short_name = cv_app_short_nm_ar
          AND     gps.period_name = min_ar_prd.min_period_name
          ;
--
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            -- AR��v���Ԏ擾�G���[
            lv_tkn1   := ld_set_of_books_id;
            lv_tkn2   := cv_closing_sts_opn;
            lv_errmsg := xxccp_common_pkg.get_msg(
                             ct_xxcos_appl_short_name
                           , cv_ar_prd_err1_msg
                           , cv_tkn_book_id
                           , lv_tkn1
                           , cv_tkn_close_flag
                           , lv_tkn2
                         );
            lv_errbuf := lv_errmsg;
            RAISE global_api_expt;
        END;
--
        -- �X�e�[�^�X��[OPEN]��ݒ�
        lv_status := cv_status_open;  -- [OPEN]
--
      -- �p�����[�^�̊�����ݒ肳��Ă���ꍇ
      ELSE
--
        BEGIN
--
          -- �����AR��v���Ԃ̃I�[�v���t���O�Ɖ�v(FROM)�Ɖ�v(TO)���擾����
          SELECT  gps.closing_status,
                  gps.start_date,
                  gps.end_date
          INTO    lv_close_flag,
                  ld_start_date,
                  ld_end_date
          FROM    gl_period_statuses  gps,
                  fnd_application_vl  fav
          WHERE	  gps.application_id = fav.application_id
          AND     gps.set_of_books_id = ld_set_of_books_id
          AND     gps.adjustment_period_flag = cv_ad_period_flag
          AND     fav.application_short_name = cv_app_short_nm_ar
          AND     gps.start_date   <= id_base_date
          AND     gps.end_date     >= id_base_date
          ;
--
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            -- AR��v���Ԏ擾�G���[
            lv_tkn1   := ld_set_of_books_id;
            lv_tkn2   := id_base_date;
            lv_errmsg := xxccp_common_pkg.get_msg(
                             ct_xxcos_appl_short_name
                           , cv_ar_prd_err2_msg
                           , cv_tkn_book_id
                           , lv_tkn1
                           , cv_tkn_base_date
                           , lv_tkn2
                         );
            lv_errbuf := lv_errmsg;
            RAISE global_api_expt;
        END;
--
        -- �X�e�[�^�X��ݒ�
        IF ( lv_close_flag = cv_closing_sts_opn ) THEN
          lv_status := cv_status_open;  -- [OPEN]
        ELSE
          lv_status := cv_status_close; -- [CLOSE]
        END IF;
--
      END IF;
--
    --==============================================================
    -- INV��v���Ԃ̏ꍇ
    --==============================================================
    ELSIF ( iv_account_period = cv_acc_period_inv ) THEN
      -- �݌ɑg�D�R�[�h���v���t�@�C������擾
      lv_organization_cd := FND_PROFILE.VALUE( ct_prof_organization_code );
--
      -- �݌ɑg�D�R�[�h�擾�G���[�̏ꍇ
      IF ( lv_organization_cd IS NULL ) THEN
        lv_tkn1   := xxccp_common_pkg.get_msg( ct_xxcos_appl_short_name, cv_org_code_msg );
        lv_errmsg := xxccp_common_pkg.get_msg( ct_xxcos_appl_short_name, ct_msg_get_profile_err, cv_tkn_profile, lv_tkn1 );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      ELSE
        NULL;
      END IF;
--
      -- �݌ɑg�DID���擾
      ln_organization_id := XXCOI_COMMON_PKG.get_organization_id( lv_organization_cd );
      -- �݌ɑg�DID�擾�G���[�̏ꍇ
      IF ( ln_organization_id IS NULL ) THEN
        lv_tkn1   := lv_organization_cd;
        lv_errmsg := xxccp_common_pkg.get_msg( ct_xxcoi_appl_short_name, cv_org_id_err_msg, cv_tkn_pro_tok, lv_tkn1 );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      ELSE
        NULL;
      END IF;
--
      -- �p�����[�^�̊�����ݒ肳��Ă��Ȃ��ꍇ
      IF ( id_base_date IS NULL ) THEN
--
        BEGIN
--
          -- �I�[�v�����Ă����ԌÂ�INV��v���Ԃ̉�v(FROM)�Ɖ�v(TO)���擾����
          SELECT  inv_prd.period_start_date    period_start_date,
                  inv_prd.schedule_close_date  schedule_close_date
          INTO    ld_start_date,
                  ld_end_date
          FROM    org_acct_periods  inv_prd,
                  ( SELECT  min( inv_prd.period_name )  min_period_name
                    FROM    org_acct_periods  inv_prd
                    WHERE   inv_prd.organization_id = ln_organization_id
                    AND     inv_prd.open_flag = cv_open_flag_y
                  ) min_inv_prd
          WHERE   inv_prd.organization_id = ln_organization_id
          AND     inv_prd.open_flag = cv_open_flag_y
          AND     min_inv_prd.min_period_name = inv_prd.period_name
          ;
--
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            -- �݌ɉ�v���Ԏ擾�G���[
            lv_tkn1   := ln_organization_id;
            lv_tkn2   := cv_open_flag_y;
            lv_errmsg := xxccp_common_pkg.get_msg(
                             ct_xxcos_appl_short_name
                           , cv_inv_prd_err1_msg
                           , cv_tkn_org_id
                           , lv_tkn1
                           , cv_tkn_open_flag
                           , lv_tkn2
                         );
            lv_errbuf := lv_errmsg;
            RAISE global_api_expt;
        END;
--
        -- �X�e�[�^�X��[OPEN]��ݒ�
        lv_status := cv_status_open; -- [OPEN]
--
      -- �p�����[�^�̊�����ݒ肳��Ă���ꍇ
      ELSE
--
        BEGIN
--
          -- �����INV��v���Ԃ̃I�[�v���t���O�Ɖ�v(FROM)�Ɖ�v(TO)���擾����
          SELECT  inv_prd.open_flag            open_flag,
                  inv_prd.period_start_date    period_start_date,
                  inv_prd.schedule_close_date  schedule_close_date
          INTO    lv_open_flag,
                  ld_start_date,
                  ld_end_date
          FROM    org_acct_periods  inv_prd
          WHERE   inv_prd.organization_id = ln_organization_id
          AND     inv_prd.period_start_date   <= id_base_date
          AND     inv_prd.schedule_close_date >= id_base_date
          ;
--
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            -- �݌ɉ�v���Ԏ擾�G���[
            lv_tkn1   := ln_organization_id;
            lv_tkn2   := id_base_date;
            lv_errmsg := xxccp_common_pkg.get_msg(
                             ct_xxcos_appl_short_name
                           , cv_inv_prd_err2_msg
                           , cv_tkn_org_id
                           , lv_tkn1
                           , cv_tkn_base_date
                           , lv_tkn2
                         );
            lv_errbuf := lv_errmsg;
            RAISE global_api_expt;
        END;
--
        -- �X�e�[�^�X��ݒ�
        IF ( lv_open_flag = cv_open_flag_y ) THEN
          lv_status := cv_status_open;  -- [OPEN]
        ELSE
          lv_status := cv_status_close; -- [CLOSE]
        END IF;
--
      END IF;
--
    ELSE
      -- ��v�敪 �l�s���G���[
      lv_tkn1   := xxccp_common_pkg.get_msg( ct_xxcos_appl_short_name, cv_acc_period_msg );
      lv_errbuf := xxccp_common_pkg.get_msg( ct_xxcos_appl_short_name, ct_msg_in_param_err, cv_tkn_in_param, lv_tkn1 );
      lv_errmsg := lv_errbuf;
      RAISE global_api_expt;
    END IF;
--
    -- �߂�l�ɐݒ�
    ov_status     := lv_status;
    od_start_date := ld_start_date;
    od_end_date   := ld_end_date;
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
      -- �߂�l�ɐݒ�
      ov_status     := NULL;
      od_start_date := NULL;
      od_end_date   := NULL;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
      -- �߂�l�ɐݒ�
      ov_status     := NULL;
      od_start_date := NULL;
      od_end_date   := NULL;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
      -- �߂�l�ɐݒ�
      ov_status     := NULL;
      od_start_date := NULL;
      od_end_date   := NULL;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_account_period;
--
  /************************************************************************
   * Function Name   : get_specific_master
   * Description     : ����}�X�^�擾(�N�C�b�N�R�[�h)
   ************************************************************************/
  FUNCTION get_specific_master(
    it_lookup_type            IN            fnd_lookup_types.lookup_type%TYPE, -- ���b�N�A�b�v�^�C�v
    it_lookup_code            IN            fnd_lookup_values.lookup_code%TYPE -- ���b�N�A�b�v�R�[�h
  ) RETURN  VARCHAR2
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_specific_master'; -- �v���O������
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
    cv_japan   CONSTANT VARCHAR2(2) := 'JA';
--
    -- *** ���[�J���ϐ� ***
    lt_meaning                           fnd_lookup_values_vl.meaning%type;                  --���e
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
--
  BEGIN
--
    --==============================================================
    --0.������
    --==============================================================
    lt_meaning          :=  NULL;
--
    --==============================================================
    --1.����}�X�^�擾
    --==============================================================
-- *************** 2009/08/03 N.Maeda 1.3 MOD START ******************** --
--    SELECT flv.meaning
--    INTO   lt_meaning
--    FROM   fnd_lookup_values_vl  flv,
--           fnd_lookup_types_vl   flt,
--           fnd_application_tl    fat
--    WHERE  fat.application_id = flt.application_id
--    AND    fat.language       = cv_japan
--    AND    flt.lookup_type    = flv.lookup_type
--    AND    flv.lookup_type    = it_lookup_type
--    AND    flv.lookup_code    = it_lookup_code
--    ;
--
    SELECT flv.meaning
    INTO   lt_meaning
    FROM   fnd_lookup_values_vl  flv
    WHERE  flv.lookup_type    = it_lookup_type
    AND    flv.lookup_code    = it_lookup_code
    ;
--
-- *************** 2009/08/03 N.Maeda 1.3 MOD  END  ******************** --
--
    --==============================================================
    --2.�ԋp
    --==============================================================
    RETURN lt_meaning;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
    WHEN OTHERS THEN
     RETURN lt_meaning;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_specific_master;
--
  /************************************************************************
   * Procedure Name  : get_tax_rate_info
   * Description     : �i�ڕʏ���ŗ��擾�֐�
   ************************************************************************/
  PROCEDURE get_tax_rate_info(
    iv_item_code                   IN         VARCHAR2,                      -- �i�ڃR�[�h
    id_base_date                   IN         DATE,                          -- ���
    ov_class_for_variable_tax      OUT NOCOPY VARCHAR2,                      -- �y���ŗ��p�Ŏ��
    ov_tax_name                    OUT NOCOPY VARCHAR2,                      -- �ŗ��L�[����
    ov_tax_description             OUT NOCOPY VARCHAR2,                      -- �E�v
    ov_tax_histories_code          OUT NOCOPY VARCHAR2,                      -- ����ŗ����R�[�h
    ov_tax_histories_description   OUT NOCOPY VARCHAR2,                      -- ����ŗ��𖼏�
    od_start_date                  OUT NOCOPY DATE,                          -- �ŗ��L�[_�J�n��
    od_end_date                    OUT NOCOPY DATE,                          -- �ŗ��L�[_�I����
    od_start_date_histories        OUT NOCOPY DATE,                          -- ����ŗ���_�J�n��
    od_end_date_histories          OUT NOCOPY DATE,                          -- ����ŗ���_�I����
    on_tax_rate                    OUT NOCOPY NUMBER,                        -- �ŗ�
    ov_tax_class_suppliers_outside OUT NOCOPY VARCHAR2,                      -- �ŋ敪_�d���O��
    ov_tax_class_suppliers_inside  OUT NOCOPY VARCHAR2,                      -- �ŋ敪_�d������
    ov_tax_class_sales_outside     OUT NOCOPY VARCHAR2,                      -- �ŋ敪_����O��
    ov_tax_class_sales_inside      OUT NOCOPY VARCHAR2,                      -- �ŋ敪_�������
    ov_errbuf                      OUT NOCOPY VARCHAR2,                      -- �G���[�E���b�Z�[�W�G���[       #�Œ�#
    ov_retcode                     OUT NOCOPY VARCHAR2,                      -- ���^�[���E�R�[�h               #�Œ�#
    ov_errmsg                      OUT NOCOPY VARCHAR2                       -- ���[�U�[�E�G���[�E���b�Z�[�W   #�Œ�#
  )
  IS
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_tax_rate_info'; -- �v���O������
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
    cv_date_format                CONSTANT VARCHAR2(10)   := 'YYYY/MM/DD';
    cn_tax_rate_warn              CONSTANT NUMBER         := '0';
    cv_param_check_flag_err0      CONSTANT VARCHAR2(1)    := '0';                          -- �G���[�Ȃ�
    cv_param_check_flag_err1      CONSTANT VARCHAR2(1)    := '1';                          -- �i�ڃR�[�h�G���[
    cv_param_check_flag_err2      CONSTANT VARCHAR2(1)    := '2';                          -- ����G���[
    cv_param_check_flag_err3      CONSTANT VARCHAR2(1)    := '3';                          -- �o��(�i�ڃR�[�h/���)�G���[
--
    -- ���b�Z�[�W
    cv_msg_no_data_err            CONSTANT VARCHAR2(20)   := 'APP-XXCOS1-00003';           -- �Ώۃf�[�^�͂���܂���B
    cv_msg_many_data_err          CONSTANT VARCHAR2(20)   := 'APP-XXCOI1-00025';           -- �擾���������������݂��܂��B
    cv_msg_base_date              CONSTANT VARCHAR2(20)   := 'APP-XXCOS1-13558';           -- ���
--
    -- �g�[�N��
    cv_tkn_data                   CONSTANT VARCHAR2(100)  := 'DATA';
--
    -- ���b�Z�[�W�p������
      -- �i�ڃR�[�h
    cv_msgtxt_item_code           CONSTANT VARCHAR2(5000) := xxccp_common_pkg.get_msg(
                                                               iv_application    =>  ct_xxcos_appl_short_name
                                                              ,iv_name           =>  ct_msg_item_code
                                                             );
      -- ���
    cv_msgtxt_base_date           CONSTANT VARCHAR2(5000) := xxccp_common_pkg.get_msg(
                                                               iv_application    =>  ct_xxcos_appl_short_name
                                                              ,iv_name           =>  cv_msg_base_date
                                                             );
      -- �i�ڃR�[�h/���
    cv_msgtxt_two_err             CONSTANT VARCHAR2(5000) := cv_msgtxt_item_code || '/' || cv_msgtxt_base_date;
--
    -- *** ���[�J���ϐ� ***
    lv_class_for_variable_tax      VARCHAR2(4);                   -- �y���ŗ��p�Ŏ��
    lv_tax_name                    VARCHAR2(80);                  -- �ŗ��L����
    lv_tax_description             VARCHAR2(240);                 -- �E�v
    lv_tax_histories_code          VARCHAR2(80);                  -- ����ŗ����R�[�h
    lv_tax_histories_description   VARCHAR2(240);                 -- ����ŗ��𖼏�
    ld_start_date                  DATE;                          -- �ŗ��L�[_�J�n��
    ld_end_date                    DATE;                          -- �ŗ��L�[_�I����
    ld_start_date_histories        DATE;                          -- ����ŗ���_�J�n��
    ld_end_date_histories          DATE;                          -- ����ŗ���_�I����
    ln_tax_rate                    NUMBER;                        -- �ŗ�
    lv_tax_class_suppliers_outside VARCHAR2(150);                 -- �ŋ敪_�d���O��
    lv_tax_class_suppliers_inside  VARCHAR2(150);                 -- �ŋ敪_�d������
    lv_tax_class_sales_outside     VARCHAR2(150);                 -- �ŋ敪_����O��
    lv_tax_class_sales_inside      VARCHAR2(150);                 -- �ŋ敪_�������
    ln_param_check_flag            VARCHAR2(1);                   -- �����`�F�b�N�t���O
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
    --==============================================================
    -- ������
    --==============================================================
    ov_class_for_variable_tax       := NULL;
    ov_tax_name                     := NULL;
    ov_tax_description              := NULL;
    ov_tax_histories_code           := NULL;
    ov_tax_histories_description    := NULL;
    od_start_date                   := NULL;
    od_end_date                     := NULL;
    od_start_date_histories         := NULL;
    od_end_date_histories           := NULL;
    on_tax_rate                     := NULL;
    ov_tax_class_suppliers_outside  := NULL;
    ov_tax_class_suppliers_inside   := NULL;
    ov_tax_class_sales_outside      := NULL;
    ov_tax_class_sales_inside       := NULL;
    ln_param_check_flag             := cv_param_check_flag_err0;
--
    --==============================================================
    -- �����`�F�b�N
    --==============================================================
    -- �i�ڃR�[�h�`�F�b�N
    IF ( iv_item_code    IS NULL ) THEN
      ln_param_check_flag  := cv_param_check_flag_err1;            -- �i�ڃR�[�h�G���[
    END IF;
    
    -- ����`�F�b�N
    IF ( id_base_date    IS NULL ) THEN
      IF ( ln_param_check_flag = cv_param_check_flag_err1 ) THEN
        ln_param_check_flag   := cv_param_check_flag_err3;         -- �o��(�i�ڃR�[�h/���)�G���[
      ELSE
        ln_param_check_flag   := cv_param_check_flag_err2;         -- ����G���[
      END IF;
    END IF;
    
    -- �`�F�b�N���ʔ���
    CASE ln_param_check_flag WHEN cv_param_check_flag_err1 THEN
                               lv_errmsg := xxccp_common_pkg.get_msg(
                                              iv_application  => ct_xxcos_appl_short_name
                                             ,iv_name         => ct_msg_require_param_err
                                             ,iv_token_name1  => cv_tkn_in_param
                                             ,iv_token_value1 => cv_msgtxt_item_code
                                            );
                                            
                               lv_errbuf := lv_errmsg;
                               RAISE global_api_expt;
                               
                             WHEN cv_param_check_flag_err2 THEN
                               lv_errmsg := xxccp_common_pkg.get_msg(
                                              iv_application  => ct_xxcos_appl_short_name
                                             ,iv_name         => ct_msg_require_param_err
                                             ,iv_token_name1  => cv_tkn_in_param
                                             ,iv_token_value1 => cv_msgtxt_base_date
                                            );
                               lv_errbuf := lv_errmsg;
                               RAISE global_api_expt;
                               
                             WHEN cv_param_check_flag_err3 THEN
                               lv_errmsg := xxccp_common_pkg.get_msg(
                                              iv_application  => ct_xxcos_appl_short_name
                                             ,iv_name         => ct_msg_require_param_err
                                             ,iv_token_name1  => cv_tkn_in_param
                                             ,iv_token_value1 => cv_msgtxt_two_err
                                            );
                               lv_errbuf := lv_errmsg;
                               RAISE global_api_expt;
                               
                             ELSE NULL;
                             
    END CASE;
--
    --==============================================================
    -- ����ŗ��擾����
    --==============================================================
    BEGIN
      --����ŗ��擾SQL
      SELECT  xrtrv.class_for_variable_tax        class_for_variable_tax       -- �y���ŗ��p�Ŏ��
             ,xrtrv.tax_name                      tax_name                     -- �ŗ��L�[����
             ,xrtrv.tax_description               tax_description              -- �E�v
             ,xrtrv.tax_histories_code            tax_histories_code           -- ����ŗ����R�[�h
             ,xrtrv.tax_histories_description     tax_histories_description    -- ����ŗ��𖼏�
             ,xrtrv.start_date                    start_date                   -- �ŗ��L�[_�J�n��
             ,xrtrv.end_date                      end_date                     -- �ŗ��L�[_�I����
             ,xrtrv.start_date_histories          start_date_histories         -- ����ŗ���_�J�n��
             ,xrtrv.end_date_histories            end_date_histories           -- ����ŗ���_�I����
             ,xrtrv.tax_rate                      tax_rate                     -- �ŗ�
             ,xrtrv.tax_class_suppliers_outside   tax_class_suppliers_outside  -- �ŋ敪_�d���O��
             ,xrtrv.tax_class_suppliers_inside    tax_class_suppliers_inside   -- �ŋ敪_�d������
             ,xrtrv.tax_class_sales_outside       tax_class_sales_outside      -- �ŋ敪_����O��
             ,xrtrv.tax_class_sales_inside        tax_class_sales_inside       -- �ŋ敪_�������
      INTO    lv_class_for_variable_tax
             ,lv_tax_name
             ,lv_tax_description
             ,lv_tax_histories_code
             ,lv_tax_histories_description
             ,ld_start_date
             ,ld_end_date
             ,ld_start_date_histories
             ,ld_end_date_histories
             ,ln_tax_rate
             ,lv_tax_class_suppliers_outside
             ,lv_tax_class_suppliers_inside
             ,lv_tax_class_sales_outside
             ,lv_tax_class_sales_inside
      FROM    xxcos_reduced_tax_rate_v  xrtrv                     -- �i�ڕʏ���ŗ�view
      WHERE   xrtrv.item_code = iv_item_code
      AND     id_base_date   >= xrtrv.start_date
      AND    ( id_base_date  <= xrtrv.end_date
               OR      xrtrv.end_date  IS NULL
             )
      AND     id_base_date   >= xrtrv.start_date_histories
      AND    ( id_base_date  <= xrtrv.end_date_histories
               OR      xrtrv.end_date_histories IS NULL
             )
      ;
--
      --�߂�l�ݒ�
      ov_class_for_variable_tax       := lv_class_for_variable_tax;
      ov_tax_name                     := lv_tax_name;
      ov_tax_description              := lv_tax_description;
      ov_tax_histories_code           := lv_tax_histories_code;
      ov_tax_histories_description    := lv_tax_histories_description;
      od_start_date                   := ld_start_date;
      od_end_date                     := ld_end_date;
      od_start_date_histories         := ld_start_date_histories;
      od_end_date_histories           := ld_end_date_histories;
      on_tax_rate                     := ln_tax_rate;
      ov_tax_class_suppliers_outside  := lv_tax_class_suppliers_outside;
      ov_tax_class_suppliers_inside   := lv_tax_class_suppliers_inside;
      ov_tax_class_sales_outside      := lv_tax_class_sales_outside;
      ov_tax_class_sales_inside       := lv_tax_class_sales_inside;
--
    EXCEPTION
--
      WHEN NO_DATA_FOUND THEN
        -- ����ŗ��u0�v��ݒ�
        on_tax_rate := cn_tax_rate_warn;
        
        lv_errmsg   := xxccp_common_pkg.get_msg(
                         iv_application => ct_xxcos_appl_short_name
                        ,iv_name        => cv_msg_no_data_err
                       );
        ov_errmsg   := lv_errmsg;
        ov_errbuf   := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
        ov_retcode  := cv_status_warn;
--
      WHEN TOO_MANY_ROWS THEN
        lv_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application => ct_xxcoi_appl_short_name
                       ,iv_name        => cv_msg_many_data_err
                      );
        ov_errmsg  := lv_errmsg;
        ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
        ov_retcode := cv_status_error;
--
      WHEN OTHERS THEN
        ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
        ov_retcode := cv_status_error;
--
    END;
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
  END get_tax_rate_info;
--
END XXCOS_COMMON_PKG;
/

