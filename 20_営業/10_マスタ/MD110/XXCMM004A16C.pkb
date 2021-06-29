CREATE OR REPLACE PACKAGE BODY XXCMM004A16C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2021. All rights reserved.
 *
 * Package Name     : XXCMM004A16C(spec)
 * Description      : �P�ʊ��Z�����쐬
 * MD.050           : �P�ʊ��Z�����쐬 MD050_CMM_004_A16
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   ��������(A-1)
 *  ins_uom_convert        �P�ʊ��Z�o�^����(A-2)
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2021/05/27    1.0   SCSK ���� �O     ����쐬
 *
 *****************************************************************************************/
--
--#######################  �Œ�O���[�o���萔�錾�� START   #######################
--
  --�X�e�[�^�X�E�R�[�h
  cv_status_normal CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal; --����:0
  cv_status_warn   CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_warn;   --�x��:1
  cv_status_error  CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_error;  --�ُ�:2
  cv_msg_part      CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont      CONSTANT VARCHAR2(3) := '.';

--
--################################  �Œ蕔 END   ##################################
--
--#######################  �Œ�O���[�o���ϐ��錾�� START   #######################
--
  gv_out_msg       VARCHAR2(2000);
  gn_target_cnt    NUMBER;                    -- �Ώی���
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
  cv_appl_xxcmm        CONSTANT VARCHAR2(10) := 'XXCMM';             -- �A�h�I���F�}�X�^
  cv_appl_xxccp        CONSTANT VARCHAR2(10) := 'XXCCP';             -- �A�h�I���F�}�X�^
  cv_pkg_name          CONSTANT VARCHAR2(15) := 'XXCMM004A16C';      -- �p�b�P�[�W��
  cv_yes               CONSTANT VARCHAR2(1)  := 'Y';
--
  -- ���b�Z�[�W�ԍ�(�}�X�^)
  cv_msg_xxcmm_00002   CONSTANT VARCHAR2(20) := 'APP-XXCMM1-00002';  -- �v���t�@�C���擾�G���[
  cv_msg_xxcmm_00441   CONSTANT VARCHAR2(20) := 'APP-XXCMM1-00441';  -- �f�[�^�擾�G���[
  cv_msg_xxcmm_10502   CONSTANT VARCHAR2(20) := 'APP-XXCMM1-10502';  -- �P�ʊ��Z�o�^�G���[
--
  -- �v���t�@�C��
  cv_pro_org_code      CONSTANT VARCHAR2(30) := 'XXCOI1_ORGANIZATION_CODE';   -- �݌ɑg�D�R�[�h
  -- �Q�ƃ^�C�v
  cv_lookup_uom_code   CONSTANT VARCHAR2(30) := 'XXCMM_UOM_CODE';      -- �����쐬�ΏےP��
  -- �g�[�N��
  cv_tkn_val_org_code  CONSTANT VARCHAR2(30) := '�݌ɑg�D�R�[�h';      -- �݌ɑg�D�R�[�h
  cv_process_date      CONSTANT VARCHAR2(30) := '�Ɩ����t';            -- �Ɩ����t�擾���s��
  cv_tkn_val_uon_conv  CONSTANT VARCHAR2(30) := '�P�ʊ��Z';
  cv_tkn_ng_profile    CONSTANT VARCHAR2(20) := 'NG_PROFILE';          -- �v���t�@�C����
  cv_tkn_data_info     CONSTANT VARCHAR2(20) := 'DATA_INFO';
  cv_from_uom          CONSTANT VARCHAR2(20) := 'FROM_UOM_CODE';
  cv_tkn_item_code     CONSTANT VARCHAR2(20) := 'ITEM_CODE';
  cv_tkn_err_msg       CONSTANT VARCHAR2(20) := 'ERR_MSG';
--
  -- �Œ�l
  cn_itm_status_regist         CONSTANT NUMBER        := xxcmm_004common_pkg.cn_itm_status_regist;     -- �{�o�^
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
   gt_bus_org_code     mtl_parameters.organization_code%TYPE;        -- �݌ɑg�D�R�[�h
   gd_process_date     DATE;                                         -- �Ɩ����t
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'init'; -- �v���O������
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
--
    lv_msg_token               VARCHAR2(100);
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
    -- ===============================
    -- ���[�U�[��`��O
    -- ===============================
    get_profile_expt             EXCEPTION;             -- �v���t�@�C���擾�G���[
    get_info_err_expt            EXCEPTION;             -- �f�[�^�擾�G���[
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
    -- �Ɩ��������t�̎擾
    gd_process_date := xxccp_common_pkg2.get_process_date;
    --
    -- �擾�G���[��
    IF ( gd_process_date IS NULL ) THEN
      lv_msg_token := cv_process_date;
      RAISE get_info_err_expt;       -- �擾�G���[
    END IF;
--
    -- �݌ɑg�D�R�[�h�̎擾
    gt_bus_org_code := fnd_profile.value(cv_pro_org_code);
    IF (gt_bus_org_code IS NULL) THEN
      lv_msg_token := cv_tkn_val_org_code;
      RAISE get_profile_expt;
    END IF;
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    WHEN get_profile_expt THEN
      -- �G���[���b�Z�[�W�擾
      lv_errmsg  := SUBSTRB( xxcmn_common_pkg.get_msg( cv_appl_xxcmm         -- ���W���[��������:XXCMM
                                                      ,cv_msg_xxcmm_00002    -- ���b�Z�[�W:APP-XXCMM1-00002
                                                      ,cv_tkn_ng_profile     -- �g�[�N���R�[�h1
                                                      ,lv_msg_token )        -- �g�[�N���l1
                            ,1, 5000 );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errmsg, 1, 5000 );
      ov_retcode := cv_status_error;
--
    WHEN get_info_err_expt THEN
      -- �G���[���b�Z�[�W�擾
      lv_errmsg  := SUBSTRB( xxcmn_common_pkg.get_msg( cv_appl_xxcmm         -- ���W���[��������:XXCMN
                                                      ,cv_msg_xxcmm_00441    -- ���b�Z�[�W:APP-XXCMM1-00441
                                                      ,cv_tkn_data_info      -- �g�[�N���R�[�h1
                                                      ,lv_msg_token )        -- �g�[�N���l1
                            ,1, 5000 );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errmsg, 1, 5000 );
      ov_retcode := cv_status_error;
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
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
--#####################################  �Œ蕔 END   ##########################################
--
  END init;
--
  /**********************************************************************************
   * Procedure Name   : ins_uom_convert
   * Description      : �P�ʊ��Z�o�^����(A-2)
   ***********************************************************************************/
  PROCEDURE ins_uom_convert(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================0
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_uom_convert'; -- �v���O������
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
    cv_uom_class_conv_to         CONSTANT VARCHAR2(10) := '�{';
--
    -- *** ���[�J���ϐ� ***
--
    lv_err_msg                 VARCHAR2(5000);
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- �����Ώەi�ڃ}�X�^�擾�J�[�\��
    CURSOR get_item_cur
    IS
      SELECT /*+ 
                LEADING( mp flvv msib xsib )
                USE_NL( mp )
                USE_NL( msib )
                USE_NL( xsib )
             */
             msib.inventory_item_id
            ,msib.primary_uom_code
            ,msib.segment1                 AS item_no
      FROM   mtl_system_items_b            msib     -- �i�ڃ}�X�^
            ,mtl_parameters                mp       -- �݌ɑg�D�}�X�^
            ,xxcmm_system_items_b          xsib     -- �i�ڃA�h�I��
            ,fnd_lookup_values_vl          flvv     -- �Q�ƕ\
      WHERE  msib.organization_id          = mp.organization_id
      AND    mp.organization_code          = gt_bus_org_code
      AND    xsib.item_code                = msib.segment1
      AND    xsib.item_status              = cn_itm_status_regist   -- �i�ڃX�e�[�^�X���u�{�o�^�v
      AND    msib.primary_uom_code         = flvv.meaning           -- �����o�^�Ώۂ̒P��
      AND    flvv.lookup_type              = cv_lookup_uom_code
      AND    flvv.enabled_flag             = cv_yes
      AND    gd_process_date              >= NVL( flvv.start_date_active, gd_process_date )
      AND    gd_process_date              <= NVL( flvv.end_date_active, gd_process_date )
      AND    NOT EXISTS ( SELECT /*+ USE_NL( mucc ) */
                                 1
                          FROM   mtl_uom_class_conversions   mucc
                          WHERE  mucc.from_uom_code       = msib.primary_uom_code
                          AND    mucc.to_uom_code         = cv_uom_class_conv_to
                          AND    mucc.inventory_item_id   = msib.inventory_item_id
                        )
      ;
--
    -- *** ���[�J���E���R�[�h ***
    get_item_rec     get_item_cur%ROWTYPE;
    -- �P�ʊ��Z�p
    l_uom_class_conv_rec         xxcmm_004common_pkg.uom_class_conv_rtype;
--
    -- ===============================
    -- ���[�U�[��`��O
    -- ===============================
    ins_uom_class_expt           EXCEPTION;             -- �P�ʊ��Z�o�^�G���[
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
    OPEN get_item_cur;
--
    <<get_item_loop>>
    LOOP
      FETCH get_item_cur  INTO get_item_rec;
        EXIT WHEN get_item_cur%NOTFOUND;
--
        -- ���������J�E���g�A�b�v
        gn_target_cnt := gn_target_cnt + 1;
--
        l_uom_class_conv_rec.inventory_item_id := get_item_rec.inventory_item_id;
        l_uom_class_conv_rec.from_uom_code     := get_item_rec.primary_uom_code;
        l_uom_class_conv_rec.to_uom_code       := cv_uom_class_conv_to;                   -- �{
        l_uom_class_conv_rec.conversion_rate   := 1;
        --
        -- �P�ʊ��Z�o�^API
        xxcmm_004common_pkg.proc_uom_class_ref(
          i_uom_class_conv_rec  =>  l_uom_class_conv_rec  -- �敪�Ԋ��Z���f�p���R�[�h�^�C�v
         ,ov_errbuf             =>  lv_errbuf             -- �G���[�E���b�Z�[�W           --# �Œ� #
         ,ov_retcode            =>  lv_retcode            -- ���^�[���E�R�[�h             --# �Œ� #
         ,ov_errmsg             =>  lv_err_msg            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
        --
        IF ( lv_retcode <> cv_status_normal ) THEN
--
          RAISE ins_uom_class_expt;
--
        END IF;
--
    END LOOP get_item_cur;
--
    CLOSE get_item_cur;
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    WHEN ins_uom_class_expt THEN
      IF ( get_item_cur%ISOPEN ) THEN
        CLOSE get_item_cur;
      END IF;
--
      -- �G���[���b�Z�[�W�擾
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_xxcmm                   -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_msg_xxcmm_10502              -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_from_uom                     -- �g�[�N���R�[�h1
                     ,iv_token_value1 => get_item_rec.primary_uom_code   -- �g�[�N���l1
                     ,iv_token_name2  => cv_tkn_item_code                -- �g�[�N���R�[�h2
                     ,iv_token_value2 => get_item_rec.item_no            -- �g�[�N���l2
                     ,iv_token_name3  => cv_tkn_err_msg                  -- �g�[�N���R�[�h3
                     ,iv_token_value3 => lv_err_msg                      -- �g�[�N���l3
                    );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errmsg, 1, 5000 );
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
      IF ( get_item_cur%ISOPEN ) THEN
        CLOSE get_item_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END ins_uom_convert;
--
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
--
    -- *** ���[�J���ϐ� ***
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
--
    -- �O���[�o���ϐ��̏�����
    gn_target_cnt := 0;
--
    --*********************************************
    --***      MD.050�̃t���[�}��\��           ***
    --***      ����Ə������̌Ăяo�����s��     ***
    --*********************************************
--
    -- ===============================
    -- ��������(A-1)
    -- ===============================
    init(
      lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ====================================
    -- �P�ʊ��Z�o�^����(A-2)
    -- ====================================
    ins_uom_convert(
      lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
--
  EXCEPTION
      -- *** �C�ӂŗ�O�������L�q���� ****
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
--###########################  �Œ蕔 START   ###########################
--
  IS
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name        CONSTANT VARCHAR2(100) := 'main';             -- �v���O������
--
    -- ���b�Z�[�W�ԍ�(���ʁEIF)
    cv_target_rec_msg  CONSTANT VARCHAR2(30) := 'APP-XXCCP1-90000'; -- �Ώی������b�Z�[�W
    cv_cnt_token       CONSTANT VARCHAR2(30) := 'COUNT';            -- �������b�Z�[�W�p�g�[�N����
    cv_normal_msg      CONSTANT VARCHAR2(30) := 'APP-XXCCP1-90004'; -- ����I�����b�Z�[�W
    cv_error_msg       CONSTANT VARCHAR2(30) := 'APP-XXCCP1-90006'; -- �G���[�I���S���[���o�b�N
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
    --��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
--
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
    -- ======================
    -- �G���[�E���b�Z�[�W�o��
    -- ======================
    IF (lv_retcode = cv_status_error) THEN
      --�G���[�o��
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff => lv_errbuf --�G���[���b�Z�[�W
      );
      --��s�}��
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => ''
      );
    ELSE
      --�Ώی����o��
      gv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_appl_xxccp
                   ,iv_name         => cv_target_rec_msg
                   ,iv_token_name1  => cv_cnt_token
                   ,iv_token_value1 => TO_CHAR(gn_target_cnt)
                  );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => gv_out_msg
      );
      --
      --��s�}��
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => ''
      );
    END IF;
--
    --�I�����b�Z�[�W
    IF (lv_retcode = cv_status_normal) THEN
      lv_message_code := cv_normal_msg;
      --�������ł͌x���I���Ȃ�
--    ELSIF(lv_retcode = cv_status_warn) THEN
--      lv_message_code := cv_warn_msg;
    ELSIF(lv_retcode = cv_status_error) THEN
      lv_message_code := cv_error_msg;
    END IF;
    --
    gv_out_msg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_appl_xxccp
                 ,iv_name         => lv_message_code
                );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
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
--###########################  �Œ蕔 END   #######################################################
--
END XXCMM004A16C;
/
