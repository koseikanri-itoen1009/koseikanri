CREATE OR REPLACE PACKAGE BODY XXCOI006A21C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOI006A21C(body)
 * Description      : �I�����ʍ쐬
 * MD.050           : HHT�I�����ʃf�[�^�捞 <MD050_COI_A21>
 * Version          : 1.5
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   ��������(B-1)
 *  chk_if_data            IF�f�[�^�`�F�b�N(B-3)
 *  ins_hht_err            HHT���捞�G���[����(B-4)
 *  ins_inv_control        �I���Ǘ��o��(B-5)
 *  ins_hht_result         HHT�I�����ʏo��(B-6)
 *  del_inv_result_file    �I�����ʃt�@�C��IF�폜(B-8)
 *  chk_file_data          �t�@�C���f�[�^�`�F�b�N(B-11)
 *  ins_result_file        �I�����ʃt�@�C��IF�o��(B-12)
 *  get_uplode_data        �t�@�C���A�b�v���[�hI/F�f�[�^�擾(B-10)
 *  del_uplode_data        �t�@�C���A�b�v���[�hI/F�f�[�^�폜(B-13)
 *  submain                ���C�������v���V�[�W��
 *                         �I�����ʃt�@�C��IF���o(B-2)
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *                         �I������(B-9�AB-14)
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009/01/27    1.0   N.Abe            �V�K�쐬
 *  2009/02/18    1.1   N.Abe            [��QCOI_014] ���O�o�͕s���Ή�
 *  2009/02/18    1.2   N.Abe            [��QCOI_018] �Ǖi�敪�l�̕s���Ή�
 *  2009/04/21    1.3   H.Sasaki         [T1_0654]�捞�f�[�^�̑O��X�y�[�X�폜
 *  2009/05/07    1.4   T.Nakamura       [T1_0556]�i�ڑ��݃`�F�b�N�G���[������ǉ�
 *  2009/06/02    1.5   H.Sasaki         [T1_1300]�I���ꏊ�̕ҏW������ǉ�
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
  process_date_expt        EXCEPTION;     -- �Ɩ����t�擾�G���[
  org_code_expt            EXCEPTION;     -- �݌ɑg�D�R�[�h�擾�G���[
  org_id_expt              EXCEPTION;     -- �݌ɑg�DID�擾�G���[
  lock_expt                EXCEPTION;     -- ���b�N�擾�G���[
  inventory_kbn_expt       EXCEPTION;     -- �I���敪�͈̓G���[
  warehouse_kbn_expt       EXCEPTION;     -- �q�ɋ敪�͈̓G���[
  quality_kbn_expt         EXCEPTION;     -- �Ǖi�敪�͈̓G���[
  inventory_date_expt      EXCEPTION;     -- �I�����Ó����G���[
  inventory_status_expt    EXCEPTION;     -- �I���X�e�[�^�X�G���[
  get_subinventory_expt    EXCEPTION;     -- �ۊǏꏊ�}�X�^�擾�G���[
  get_result_col_expt      EXCEPTION;     -- �I�����ʃt�@�C��IF���ڎ擾�G���[
  required_expt            EXCEPTION;     -- �K�{�`�F�b�N�G���[
  harf_number_expt         EXCEPTION;     -- ���p�����G���[
  hht_name_expt            EXCEPTION;     -- HHT�G���[�p�I���f�[�^���擾�G���[
  chk_item_expt            EXCEPTION;     -- �i�ڃX�e�[�^�X�L���`�F�b�N�G���[
  chk_sales_item_expt      EXCEPTION;     -- �i�ڔ���Ώۋ敪�L���`�F�b�N�G���[
  blob_expt                EXCEPTION;     -- BLOB�f�[�^�ϊ��G���[
  file_expt                EXCEPTION;     -- �t�@�C���G���[
  pre_month_expt           EXCEPTION;     -- �O���I���f�[�^�擾�G���[
  date_expt                EXCEPTION;     -- ���t�ϊ��G���[
  subinv_div_expt          EXCEPTION;     -- �ۊǏꏊ�I���ΏۊO�G���[
-- == 2009/05/07 V1.4 Added START ==================================================================
  chk_item_exist_expt      EXCEPTION;     -- �i�ڑ��݃`�F�b�N�G���[
-- == 2009/05/07 V1.4 Added END   ==================================================================
--
  PRAGMA EXCEPTION_INIT(lock_expt, -54);
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name         CONSTANT VARCHAR2(100)  := 'XXCOI006A21C'; -- �p�b�P�[�W��
--
  cv_xxcoi_short_name CONSTANT VARCHAR2(10)   := 'XXCOI';        -- �A�h�I���F���ʁEIF�̈�
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gd_process_date       DATE;                                     -- �Ɩ��������t
  gv_hht_err_data_name  VARCHAR2(20);                             -- HHT�G���[�p�I���f�[�^��
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(B-1)
   ***********************************************************************************/
  PROCEDURE init(
    in_file_id          IN  NUMBER,       --   1.�t�@�C��ID
    iv_format_pattern   IN  VARCHAR2,     --   2.�t�H�[�}�b�g�p�^�[��
    on_organization_id  OUT NUMBER,       --   3.�݌ɑg�DID
    ov_errbuf           OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name        CONSTANT VARCHAR2(100) := 'init';             -- �v���O������
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
    --���b�Z�[�W�ԍ�
    cv_xxcoi1_msg_10232   CONSTANT  VARCHAR2(16)  := 'APP-XXCOI1-10232';
    cv_xxcoi1_msg_00011   CONSTANT  VARCHAR2(16)  := 'APP-XXCOI1-00011';
    cv_xxcoi1_msg_00005   CONSTANT  VARCHAR2(16)  := 'APP-XXCOI1-00005';
    cv_xxcoi1_msg_00006   CONSTANT  VARCHAR2(16)  := 'APP-XXCOI1-00006';
    cv_xxcoi1_msg_10289   CONSTANT  VARCHAR2(16)  := 'APP-XXCOI1-10289';
    --�g�[�N��
    cv_tkn_file_id        CONSTANT  VARCHAR2(7)   := 'FILE_ID';
    cv_tkn_format_ptn     CONSTANT  VARCHAR2(10)  := 'FORMAT_PTN';
    cv_tkn_pro            CONSTANT  VARCHAR2(7)   := 'PRO_TOK';
    cv_tkn_org_code       CONSTANT  VARCHAR2(12)  := 'ORG_CODE_TOK';
    --�v���t�@�C��
    cv_prf_org_code       CONSTANT  VARCHAR2(24)  := 'XXCOI1_ORGANIZATION_CODE';
    cv_prf_err_name       CONSTANT  VARCHAR2(28)  := 'XXCOI1_HHT_ERR_DATA_NAME_INV';
--
    -- *** ���[�J���ϐ� ***
    lv_organization_code    VARCHAR2(4);    --�݌ɑg�D�R�[�h
    ln_organization_id      NUMBER;         --�݌ɑg�DID
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
    --====================
    --1.���̓p�����[�^�o��
    --====================
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxcoi_short_name
                    ,iv_name         => cv_xxcoi1_msg_10232
                    ,iv_token_name1  => cv_tkn_file_id
                    ,iv_token_value1 => in_file_id
                    ,iv_token_name2  => cv_tkn_format_ptn
                    ,iv_token_value2 => iv_format_pattern
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    --===============
    --2.�Ɩ����t�擾
    --===============
    gd_process_date := xxccp_common_pkg2.get_process_date;
    IF (gd_process_date IS NULL) THEN
      RAISE process_date_expt;
    END IF;
--
    --====================================
    --3.�v���t�@�C������݌ɑg�D�R�[�h���擾
    --====================================
    lv_organization_code := fnd_profile.value(cv_prf_org_code);
--
    IF (lv_organization_code IS NULL) THEN
      RAISE org_code_expt;
    END IF;
--
    --====================================
    --4.�݌ɑg�D�R�[�h����݌ɑg�DID���擾
    --====================================
    ln_organization_id := xxcoi_common_pkg.get_organization_id(lv_organization_code);
--
    IF (ln_organization_id IS NULL) THEN
      RAISE org_id_expt;
    END IF;
--
    --==================================================
    --�ǉ�.�v���t�@�C������HHT�G���[�p�I���f�[�^�����擾
    --==================================================
    gv_hht_err_data_name  := fnd_profile.value(cv_prf_err_name);
--
    IF (gv_hht_err_data_name IS NULL) THEN
      RAISE hht_name_expt;
    END IF;
--
    on_organization_id := ln_organization_id;
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    --*** �Ɩ����t�擾�G���[ ***
    WHEN process_date_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_xxcoi_short_name
                 ,iv_name         => cv_xxcoi1_msg_00011
                );
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# �C�� #
--
    --*** �݌ɑg�D�R�[�h�擾�G���[ ***
    WHEN org_code_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_xxcoi_short_name
                 ,iv_name         => cv_xxcoi1_msg_00005
                 ,iv_token_name1  => cv_tkn_pro
                 ,iv_token_value1 => cv_prf_org_code
                );
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# �C�� #
--
    --*** �݌ɑg�DID�擾�G���[ ***
    WHEN org_id_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_xxcoi_short_name
                 ,iv_name         => cv_xxcoi1_msg_00006
                 ,iv_token_name1  => cv_tkn_org_code
                 ,iv_token_value1 => lv_organization_code
                );
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# �C�� #
--
    --*** HT�G���[�p�I���f�[�^���擾�G���[ ***
    WHEN hht_name_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_xxcoi_short_name
                 ,iv_name         => cv_xxcoi1_msg_10289
                 ,iv_token_name1  => cv_tkn_pro
                 ,iv_token_value1 => cv_prf_err_name
                );
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# �C�� #
--
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
   * Procedure Name   : chk_if_data
   * Description      : IF�f�[�^�`�F�b�N(B-3)
   ***********************************************************************************/
  PROCEDURE chk_if_data(
    it_base_code          IN  xxcoi_in_inv_result_file_if.base_code%TYPE,         -- 1.���_�R�[�h
    it_inventory_kbn      IN  xxcoi_in_inv_result_file_if.inventory_kbn%TYPE,     -- 2.�I���敪
    it_inventory_date     IN  xxcoi_in_inv_result_file_if.inventory_date%TYPE,    -- 3.�I����
    it_warehouse_kbn      IN  xxcoi_in_inv_result_file_if.warehouse_kbn%TYPE,     -- 4.�q�ɋ敪
    it_inventory_place    IN  xxcoi_in_inv_result_file_if.inventory_place%TYPE,   -- 5.�I���ꏊ
    it_item_code          IN  xxcoi_in_inv_result_file_if.item_code%TYPE,         -- 6.�i�ڃR�[�h
    it_quality_goods_kbn  IN  xxcoi_in_inv_result_file_if.quality_goods_kbn%TYPE, -- 7.�Ǖi�敪  
    iv_inventory_status   IN  VARCHAR2,                                           -- 8.�I���X�e�[�^�X
    in_organization_id    IN  NUMBER,                                             -- 9.�݌ɑg�DID
    ov_subinventory_code  OUT VARCHAR2,                                           --10.�ۊǏꏊ
    ov_fiscal_date        OUT VARCHAR2,                                           --11.�݌ɉ�v����
    ov_errbuf             OUT VARCHAR2,     --   �G���[�E���b�Z�[�W               --# �Œ� #
    ov_retcode            OUT VARCHAR2,     --   ���^�[���E�R�[�h                 --# �Œ� #
    ov_errmsg             OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W     --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_if_data'; -- �v���O������
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
    cv_ym                 CONSTANT VARCHAR2(7)  := 'YYYY/MM';     --�N���ϊ��p
    cv_ym2                CONSTANT VARCHAR2(6)  := 'YYYYMM';      --�N���ϊ��p(��؂�Ȃ�)
    cv_slash              CONSTANT VARCHAR2(6)  := '/';           --��؂蕶��(�N���ϊ��p)
    --���b�Z�[�W
    cv_xxcoi1_msg_10133   CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10133';  --�I���敪�͈̓G���[
    cv_xxcoi1_msg_10134   CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10134';  --�q�ɋ敪�͈̓G���[
    cv_xxcoi1_msg_10135   CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10135';  --�Ǖi�敪�͈̓G���[
    cv_xxcoi1_msg_10291   CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10291';  --�i�ڃX�e�[�^�X�L���G���[
    cv_xxcoi1_msg_10229   CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10229';  --�i�ڔ���Ώۋ敪�G���[
    cv_xxcoi1_msg_10136   CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10136';  --�I�����Ó����G���[
    cv_xxcoi1_msg_10137   CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10137';  --�I���X�e�[�^�X�G���[
    cv_xxcoi1_msg_10129   CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10129';  --�ۊǏꏊ�}�X�^�擾�G���[
    cv_xxcoi1_msg_10299   CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10299';  --�O���I���f�[�^�擾�G���[
    cv_xxcoi1_msg_10356   CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10356';  --�ۊǏꏊ�I���ΏۊO�G���[
-- == 2009/05/07 V1.4 Added START ==================================================================
    cv_xxcoi1_msg_10227   CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10227';  -- �i�ڑ��݃`�F�b�N�G���[
-- == 2009/05/07 V1.4 Added END   ==================================================================
    --�g�[�N��
    cv_tkn_item_code      CONSTANT VARCHAR2(9)  := 'ITEM_CODE';
    cv_tkn_ivt_type       CONSTANT VARCHAR2(8)  := 'IVT_TYPE';
    cv_tkn_whse_type      CONSTANT VARCHAR2(9)  := 'WHSE_TYPE';
    cv_tkn_qlty_type      CONSTANT VARCHAR2(9)  := 'QLTY_TYPE';
    cv_tkn_status         CONSTANT VARCHAR2(6)  := 'STATUS';
    --�N�C�b�N�R�[�h
    cv_lk_inv_dv          CONSTANT VARCHAR2(20) := 'XXCOI1_INVENTORY_KBN';          --�I���敪
    cv_lk_ware_dv         CONSTANT VARCHAR2(25) := 'XXCOI1_WAREHOUSE_DIVISION';     --�q�ɋ敪
    cv_lk_qual_good_dv    CONSTANT VARCHAR2(29) := 'XXCOI1_QUALITY_GOODS_DIVISION'; --HHT�p�Ǖi�敪
    cv_lk_inv_stat        CONSTANT VARCHAR2(23) := 'XXCOI1_INVENTORY_STATUS';       --�I���X�e�[�^�X
    --�R�[�h���t���O
    cv_inactive           CONSTANT VARCHAR2(8)  := 'Inactive';
    cv_n                  CONSTANT VARCHAR2(1)  := 'N';
    cv_s                  CONSTANT VARCHAR2(1)  := 'S';
    cv_y                  CONSTANT VARCHAR2(1)  := 'Y';
    cv_1                  CONSTANT VARCHAR2(1)  := '1';
    cv_2                  CONSTANT VARCHAR2(1)  := '2';
    cv_3                  CONSTANT VARCHAR2(1)  := '3';
    cv_4                  CONSTANT VARCHAR2(1)  := '4';
    cv_9                  CONSTANT VARCHAR2(1)  := '9';
    cv_90                 CONSTANT VARCHAR2(2)  := '90';            --���R�[�h���
--
    -- *** ���[�J���ϐ� ***
    lt_lookup_meaning     fnd_lookup_values.meaning%TYPE;           --�敪�l�Ó����`�F�b�N�p
    lt_inv_status         xxcoi_inv_control.inventory_status%TYPE;  --�I���X�e�[�^�X
--
    --�i�ڏ��擾�p
    lv_item_status        VARCHAR2(5);                              --�i�ڃX�e�[�^�X
    lv_cust_order_flg     VARCHAR2(5);                              --�ڋq�󒍉\�t���O
    lv_transaction_enable VARCHAR2(5);                              --����\
    lv_stock_enabled_flg  VARCHAR2(5);                              --�݌ɕۗL�\�t���O
    lv_return_enable      VARCHAR2(5);                              --�ԕi�\
    lv_sales_class        VARCHAR2(5);                              --����Ώۋ敪
    lv_primary_unit       VARCHAR2(5);                              --��P��
--
    --�q�ɕۊǏꏊ�ϊ��p
    lt_subinv_code        mtl_secondary_inventories.secondary_inventory_name%TYPE;  --�ۊǏꏊ�R�[�h
    lt_base_code          mtl_secondary_inventories.attribute7%TYPE;                --���_�R�[�h
    lt_subinv_div         mtl_secondary_inventories.attribute5%TYPE;                --�I���敪
--
    lt_business_low_type  xxcmm_cust_accounts.business_low_type%TYPE;               --�Ƒԏ�����
    -- *** ���[�J���E�J�[�\�� ***
    CURSOR get_period_date_cur
    IS
      SELECT   TO_CHAR(gp.period_start_date, cv_ym) period_date --�J�n��
      FROM     org_acct_periods gp                              --�݌ɉ�v���ԃe�[�u��
      WHERE    gp.organization_id = in_organization_id
      AND      gp.open_flag       = cv_y                        --�I�[�v���t���O'Y'
      ORDER BY gp.period_start_date
      ;
--
    -- *** ���[�J���E���R�[�h ***
    get_period_date_rec get_period_date_cur%ROWTYPE;
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
    --=============================
    --1-1.�I���敪�̑Ó����`�F�b�N
    --=============================
    lt_lookup_meaning := xxcoi_common_pkg.get_meaning(
                         cv_lk_inv_dv
                        ,it_inventory_kbn
                      );
--
    --�I���敪�̓��e���擾�ł��Ȃ������ꍇ
    IF (lt_lookup_meaning IS NULL) THEN
      --�I���敪�͈̓G���[
      RAISE inventory_kbn_expt;
    END IF;
--
    --=============================
    --1-2.�q�ɋ敪�̑Ó����`�F�b�N
    --=============================
    lt_lookup_meaning := xxcoi_common_pkg.get_meaning(
                        cv_lk_ware_dv
                       ,it_warehouse_kbn
                      );
--
    --�q�ɋ敪�̓��e���擾�ł��Ȃ������ꍇ
    IF (lt_lookup_meaning IS NULL) THEN
      --�q�ɋ敪�͈̓G���[
      RAISE warehouse_kbn_expt;
    END IF;
--
    --============================
    --1-3�Ǖi�敪�̑Ó����`�F�b�N
    --============================
    IF NOT ((it_inventory_kbn = cv_1) 
       AND (it_quality_goods_kbn IS NULL))
    THEN
      lt_lookup_meaning := xxcoi_common_pkg.get_meaning(
                          cv_lk_qual_good_dv
                         ,it_quality_goods_kbn
                        );
--
      --�Ǖi�敪�̓��e���擾�ł��Ȃ������ꍇ
      IF (lt_lookup_meaning IS NULL) THEN
        --�Ǖi�敪�͈̓G���[
        RAISE quality_kbn_expt;
      END IF;
    END IF;
--
    --===========================
    --2-1.�i�ڃR�[�h�̃}�X�^�`�F�b�N
    --===========================
    xxcoi_common_pkg.get_item_info(
          iv_item_code            =>  it_item_code          -- 1 .�i�ڃR�[�h
         ,in_org_id               =>  in_organization_id    -- 2 .�݌ɑg�DID
         ,ov_item_status          =>  lv_item_status        -- 3 .�i�ڃX�e�[�^�X
         ,ov_cust_order_flg       =>  lv_cust_order_flg     -- 4 .�ڋq�󒍉\�t���O
         ,ov_transaction_enable   =>  lv_transaction_enable -- 5 .����\
         ,ov_stock_enabled_flg    =>  lv_stock_enabled_flg  -- 6 .�݌ɕۗL�\�t���O
         ,ov_return_enable        =>  lv_return_enable      -- 7 .�ԕi�\
         ,ov_sales_class          =>  lv_sales_class        -- 8 .����Ώۋ敪
         ,ov_primary_unit         =>  lv_primary_unit       -- 9 .��P��
         ,ov_errbuf               =>  lv_errbuf             -- 10.�G���[���b�Z�[�W
         ,ov_retcode              =>  lv_retcode            -- 11.���^�[���E�R�[�h
         ,ov_errmsg               =>  lv_errmsg             -- 12.���[�U�[�E�G���[���b�Z�[�W
        );
    IF (lv_retcode <> cv_status_normal) THEN
-- == 2009/05/07 V1.4 Modified START ===============================================================
--      RAISE global_api_others_expt;
      RAISE chk_item_exist_expt;
-- == 2009/05/07 V1.4 Modified END   ===============================================================
    END IF;
--
    --===========================
    --2-2.�i�ڃX�e�[�^�X�`�F�b�N
    --===========================
    --�i�ڃX�e�[�^�X��'Inactive'����
    --�ڋq�󒍉\�t���O�A����\�t���O�A�݌ɕۗL�\�t���O�A�ԕi�\�t���O
    --�����ꂩ������('N')�ɐݒ肳��Ă����ꍇ
    IF ((lv_item_status           = cv_inactive)
      OR  (lv_cust_order_flg     = cv_n)
      OR  (lv_transaction_enable = cv_n)
      OR  (lv_stock_enabled_flg  = cv_n)
      OR  (lv_return_enable      = cv_n))
    THEN
      --�i�ڃX�e�[�^�X�L���`�F�b�N�G���[
      RAISE chk_item_expt;
    END IF;
--
    --=============================
    --2-3.�i�ڔ���Ώۋ敪�`�F�b�N
    --=============================
    --NULL�̏ꍇ���G���[�Ƃ���B
    IF (NVL(lv_sales_class, cv_2) <> cv_1) THEN
      --�i�ڔ���Ώۋ敪�L���`�F�b�N�G���[
      RAISE chk_sales_item_expt;
    END IF;
--
    --============================
    --3.�I�[�v���݌ɉ�v���ԏ��
    --============================
    OPEN get_period_date_cur;
    FETCH get_period_date_cur INTO get_period_date_rec;
    CLOSE get_period_date_cur;
--
    --===========================
    --3-1.�I���敪�y�����z�̏ꍇ
    --===========================
    IF (it_inventory_kbn = cv_2) THEN
      --�擾������v�N���̔N����IF�̒I�����̔N�����r
      IF (get_period_date_rec.period_date <> TO_CHAR(it_inventory_date, cv_ym)) THEN
        --�I�����Ó����G���[
        RAISE inventory_date_expt;
      END IF;
--
    --==========================
    --3-2.�I���敪�y�����z�̏ꍇ
    --==========================
    ELSE
      --IF�̒I���N���ƋƖ��������t�̔N������v
      IF (TO_CHAR(it_inventory_date, cv_ym) = TO_CHAR(gd_process_date, cv_ym)) THEN
        --�I���Ǘ�����IF.�I�����̑O���Ɉ�v����I���X�e�[�^�X���擾����
        BEGIN
          SELECT xic.inventory_status
          INTO   lt_inv_status
          FROM   xxcoi_inv_control xic
          WHERE  xic.base_code            = it_base_code        --���_�R�[�h
          AND    xic.inventory_place      = it_inventory_place  --�I���ꏊ
          AND    xic.inventory_kbn        = cv_2                --�I���敪 = '2'(����)
          AND    xic.inventory_year_month = TO_CHAR(ADD_MONTHS(it_inventory_date, -1), cv_ym2)
                                                                --�I���N�� = �I���� - 1����
          AND    ROWNUM = 1
          ;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
          --�f�[�^�����݂��Ȃ��ꍇ�̓X�e�[�^�X�`�F�b�N�𖳎�����
            lt_inv_status := cv_9;
        END;
        --�I���X�e�[�^�X���m�肩���`�F�b�N����B
        IF (lt_inv_status <> cv_9) THEN
          --�O���I���f�[�^�擾�G���[
          RAISE pre_month_expt;
        END IF;
      --IF�̒I���N���ƋƖ��������t�̔N������v���Ȃ�
      ELSE
        --�I�����Ó����G���[
        RAISE inventory_date_expt;
      END IF;
    END IF;
--
    --==============================
    --4-1.�q�ɋ敪 = '1'(�q��)�̏ꍇ
    --==============================
    IF (it_warehouse_kbn = cv_1) THEN 
      --�q�ɕۊǏꏊ�R�[�h�ϊ�(���ʊ֐�)
      xxcoi_common_pkg.convert_whouse_subinv_code(
            iv_base_code        =>  it_base_code        -- 1.���_�R�[�h
           ,iv_warehouse_code   =>  it_inventory_place  -- 2.�q�ɃR�[�h
           ,in_organization_id  =>  in_organization_id  -- 3.�݌ɑg�DID
           ,ov_subinv_code      =>  lt_subinv_code      -- 4.�ۊǏꏊ�R�[�h
           ,ov_base_code        =>  lt_base_code        -- 5.���_�R�[�h
           ,ov_subinv_div       =>  lt_subinv_div       -- 6.�ۊǏꏊ�敪
           ,ov_errbuf           =>  lv_errbuf           -- 7.�G���[���b�Z�[�W
           ,ov_retcode          =>  lv_retcode          -- 8.���^�[���E�R�[�h(1:����A2:�G���[)
           ,ov_errmsg           =>  lv_errmsg           -- 9.���[�U�[�E�G���[���b�Z�[�W
          );
      IF (lv_retcode <> cv_status_normal) THEN
        RAISE get_subinventory_expt;
      END IF;
      --�ۊǏꏊ�ΏۊO�G���[
      IF (lt_subinv_div = cv_9) THEN
        RAISE subinv_div_expt;
      END IF;
--
    --================================
    --4-2.�q�ɋ敪 = '2'(�c�ƈ�)�̏ꍇ
    --================================
    ELSIF (it_warehouse_kbn = cv_2) THEN
      --�c�ƎҕۊǏꏊ�R�[�h�ϊ�(���ʊ֐�)
      xxcoi_common_pkg.convert_emp_subinv_code(
            iv_base_code        =>  it_base_code        -- 1.���_�R�[�h
           ,iv_employee_number  =>  it_inventory_place  -- 2.�]�ƈ��R�[�h
           ,id_transaction_date =>  it_inventory_date   -- 3.�`�[���t
           ,in_organization_id  =>  in_organization_id  -- 4.�݌ɑg�DID
           ,ov_subinv_code      =>  lt_subinv_code      -- 5.�ۊǏꏊ�R�[�h
           ,ov_base_code        =>  lt_base_code        -- 6.���_�R�[�h
           ,ov_subinv_div       =>  lt_subinv_div       -- 7.�ۊǏꏊ�敪
           ,ov_errbuf           =>  lv_errbuf           -- 8.�G���[���b�Z�[�W
           ,ov_retcode          =>  lv_retcode          -- 9.���^�[���E�R�[�h(1:����A2:�G���[)
           ,ov_errmsg           =>  lv_errmsg           --10.���[�U�[�E�G���[���b�Z�[�W
          );
      IF (lv_retcode <> cv_status_normal) THEN
        RAISE get_subinventory_expt;
      END IF;
      --�ۊǏꏊ�ΏۊO�G���[
      IF (lt_subinv_div = cv_9) THEN
        RAISE subinv_div_expt;
      END IF;
--
    --=========================================
    --4-3.�q�ɋ敪 = 3(�a����)�A4(���X)�̏ꍇ
    --=========================================
    ELSIF ((it_warehouse_kbn = cv_3)
      OR  (it_warehouse_kbn = cv_4))
    THEN
      --�a����ۊǏꏊ�R�[�h�ϊ�(���ʊ֐�)
      xxcoi_common_pkg.convert_cust_subinv_code(
            iv_base_code          =>  it_base_code          -- 1.���_�R�[�h
           ,iv_cust_code          =>  it_inventory_place    -- 2.�ڋq�R�[�h
           ,id_transaction_date   =>  it_inventory_date     -- 3.�`�[���t
           ,in_organization_id    =>  in_organization_id    -- 4.�݌ɑg�DID
           ,iv_record_type        =>  cv_90                 -- 5.���R�[�h���
           ,iv_hht_form_flag      =>  cv_n                  -- 6.HHT������͉�ʃt���O
           ,ov_subinv_code        =>  lt_subinv_code        -- 7.�ۊǏꏊ�R�[�h
           ,ov_base_code          =>  lt_base_code          -- 8.���_�R�[�h
           ,ov_subinv_div         =>  lt_subinv_div         -- 9.�ۊǏꏊ�敪
           ,ov_business_low_type  =>  lt_business_low_type  --10.�Ƒԏ�����
           ,ov_errbuf             =>  lv_errbuf             --11.�G���[���b�Z�[�W
           ,ov_retcode            =>  lv_retcode            --12.���^�[���E�R�[�h(1:����A2:�G���[)
           ,ov_errmsg             =>  lv_errmsg             --13.���[�U�[�E�G���[���b�Z�[�W
          );
      IF (lv_retcode <> cv_status_normal) THEN
        RAISE get_subinventory_expt;
      END IF;
      --�ۊǏꏊ�ΏۊO�G���[
      IF (lt_subinv_div = cv_9) THEN
        RAISE subinv_div_expt;
      END IF;
--
    END IF;
--
    --======================================
    --5.�ȉ��̏����Ɉ�v�����ꍇ�G���[�ƂȂ�
    --======================================
    --B-2�ŒI���Ǘ��̃f�[�^(�I���X�e�[�^�X)���擾�ł��Ȃ��ꍇ�̓`�F�b�N���Ȃ�
    IF  ((iv_inventory_status IS NOT NULL)              --�I���X�e�[�^�X��NULL�ł͂Ȃ�
      AND (SUBSTRB(lt_subinv_code, 1, 1) <> cv_s)       --�ۊǏꏊ�R�[�h�擪1����'S'
      AND (it_inventory_kbn     = cv_2)                 --�I���敪='2'(����)
      AND ((iv_inventory_status = cv_2)                 --�I���X�e�[�^�X='2'(�󕥍쐬��)
        OR (iv_inventory_status = cv_3)                 --�I���X�e�[�^�X='3'(�����v�Z��)
        OR (iv_inventory_status = cv_9)))               --�I���X�e�[�^�X='9'(�m��)
    THEN
      lt_lookup_meaning := xxcoi_common_pkg.get_meaning(
                          cv_lk_inv_stat
                         ,iv_inventory_status
                        );
      --�I���X�e�[�^�X�G���[
      RAISE inventory_status_expt;
    END IF;
--
    --�݌ɉ�v���Ԃ�߂�l�ɐݒ�
    ov_fiscal_date := REPLACE(get_period_date_rec.period_date, cv_slash);
    --�ۊǏꏊ��߂�l�ɐݒ�
    ov_subinventory_code := lt_subinv_code;
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    --*** �I���敪�͈̓G���[ ***
    WHEN inventory_kbn_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_xxcoi_short_name
                 ,iv_name         => cv_xxcoi1_msg_10133
                 ,iv_token_name1  => cv_tkn_ivt_type
                 ,iv_token_value1 => it_inventory_kbn
                );
      ov_errmsg  := lv_errmsg;
      ov_retcode := cv_status_warn;                     --# �C�� #
--
    --*** �q�ɋ敪�͈̓G���[ ***
    WHEN warehouse_kbn_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_xxcoi_short_name
                 ,iv_name         => cv_xxcoi1_msg_10134
                 ,iv_token_name1  => cv_tkn_whse_type
                 ,iv_token_value1 => it_warehouse_kbn
                );
      ov_errmsg  := lv_errmsg;
      ov_retcode := cv_status_warn;                     --# �C�� #
--
    --*** �Ǖi�敪�͈̓G���[ ***
    WHEN quality_kbn_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_xxcoi_short_name
                 ,iv_name         => cv_xxcoi1_msg_10135
                 ,iv_token_name1  => cv_tkn_qlty_type
                 ,iv_token_value1 => it_quality_goods_kbn
                );
      ov_errmsg  := lv_errmsg;
      ov_retcode := cv_status_warn;                     --# �C�� #
--
-- == 2009/05/07 V1.4 Added START ==================================================================
    --*** �i�ڑ��݃`�F�b�N�G���[ ***
    WHEN chk_item_exist_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_xxcoi_short_name
                 ,iv_name         => cv_xxcoi1_msg_10227
                 ,iv_token_name1  => cv_tkn_item_code
                 ,iv_token_value1 => it_item_code
                );
      ov_errmsg  := lv_errmsg;
      ov_retcode := cv_status_warn;                     --# �C�� #
--
-- == 2009/05/07 V1.4 Added END   ==================================================================
    --*** �i�ڃX�e�[�^�X�L���`�F�b�N�G���[ ***
    WHEN chk_item_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_xxcoi_short_name
                 ,iv_name         => cv_xxcoi1_msg_10291
                 ,iv_token_name1  => cv_tkn_item_code
                 ,iv_token_value1 => it_item_code
                );
      ov_errmsg  := lv_errmsg;
      ov_retcode := cv_status_warn;                     --# �C�� #
--
    --*** �i�ڔ���Ώۋ敪�L���`�F�b�N�G���[ ***
    WHEN chk_sales_item_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_xxcoi_short_name
                 ,iv_name         => cv_xxcoi1_msg_10229
                 ,iv_token_name1  => cv_tkn_item_code
                 ,iv_token_value1 => it_item_code
                );
      ov_errmsg  := lv_errmsg;
      ov_retcode := cv_status_warn;                     --# �C�� #
--
    --*** �I�����Ó����G���[ ***
    WHEN inventory_date_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_xxcoi_short_name
                 ,iv_name         => cv_xxcoi1_msg_10136
                );
      ov_errmsg  := lv_errmsg;
      ov_retcode := cv_status_warn;                     --# �C�� #
--
    --*** �I���X�e�[�^�X�G���[ ***
    WHEN inventory_status_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_xxcoi_short_name
                 ,iv_name         => cv_xxcoi1_msg_10137
                 ,iv_token_name1  => cv_tkn_status
                 ,iv_token_value1 => lt_lookup_meaning
                );
      ov_errmsg  := lv_errmsg;
      ov_retcode := cv_status_warn;                     --# �C�� #
--
    --*** �ۊǏꏊ�}�X�^�擾�G���[ ***
    WHEN get_subinventory_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_xxcoi_short_name
                 ,iv_name         => cv_xxcoi1_msg_10129
                );
      ov_errmsg  := lv_errmsg;
      ov_retcode := cv_status_warn;                     --# �C�� #
--
    --*** �O���I���f�[�^�擾�G���[ ***
    WHEN pre_month_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_xxcoi_short_name
                 ,iv_name         => cv_xxcoi1_msg_10299
                );
      ov_errmsg  := lv_errmsg;
      ov_retcode := cv_status_warn;                     --# �C�� #
--
    --*** �ۊǏꏊ�I���ΏۊO�G���[ ***
    WHEN subinv_div_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_xxcoi_short_name
                 ,iv_name         => cv_xxcoi1_msg_10356
                );
      ov_errmsg  := lv_errmsg;
      ov_retcode := cv_status_warn;                     --# �C�� #
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
  END chk_if_data;
--
  /**********************************************************************************
   * Procedure Name   : ins_inv_control
   * Description      : �I���Ǘ��o��(B-5)
   ***********************************************************************************/
  PROCEDURE ins_inv_control(
    it_inventory_seq      IN  xxcoi_inv_control.inventory_seq%TYPE,                     -- 1.�I��SEQ
    it_inventory_kbn      IN  xxcoi_in_inv_result_file_if.inventory_kbn%TYPE,           -- 2.�I���敪
    it_base_code          IN  xxcoi_in_inv_result_file_if.base_code%TYPE,               -- 3.���_�R�[�h
    it_warehouse_kbn      IN  xxcoi_in_inv_result_file_if.warehouse_kbn%TYPE,           -- 4.�q�ɋ敪
    it_inventory_place    IN  xxcoi_in_inv_result_file_if.inventory_place%TYPE,         -- 5.�I���ꏊ
    it_inventory_date     IN  xxcoi_in_inv_result_file_if.inventory_date%TYPE,          -- 6.�I����
    it_subinventory_code  IN  mtl_secondary_inventories.secondary_inventory_name%TYPE,  -- 7.�ۊǏꏊ
    iv_fiscal_date        IN  VARCHAR2,                                                 -- 8.��v����
    ov_errbuf             OUT VARCHAR2,     --   �G���[�E���b�Z�[�W             --# �Œ� #
    ov_retcode            OUT VARCHAR2,     --   ���^�[���E�R�[�h               --# �Œ� #
    ov_errmsg             OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W   --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_inv_control'; -- �v���O������
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
    cv_1    CONSTANT VARCHAR2(1)  := '1';
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
    --==================================
    --����1.2.3�͌Ăь�(submain)�ɂċL�q
    --==================================
--
    --�I���Ǘ��e�[�u���֓o�^
    INSERT INTO xxcoi_inv_control(
       inventory_seq              -- 1.�I��SEQ
      ,inventory_kbn              -- 2.�I���敪
      ,base_code                  -- 3.���_�R�[�h
      ,subinventory_code          -- 4.�ۊǏꏊ
      ,warehouse_kbn              -- 5.�q�ɋ敪
      ,inventory_place            -- 6.�I���ꏊ
      ,inventory_year_month       -- 7.�N��
      ,inventory_date             -- 8.�I����
      ,inventory_status           -- 9.�I���X�e�[�^�X
      ,created_by                 --10.�쐬��
      ,creation_date              --11.�쐬��
      ,last_updated_by            --12.�ŏI�X�V��
      ,last_update_date           --13.�ŏI�X�V��
      ,last_update_login          --14.�ŏI�X�V���[�U
      ,request_id                 --15.�v��ID
      ,program_application_id     --16.�v���O�����E�A�v���P�[�V����ID
      ,program_id                 --17.�v���O����ID
      ,program_update_date        --18.�v���O�����X�V��
    )VALUES(
       it_inventory_seq           -- 1.�I��SEQ
      ,it_inventory_kbn           -- 2.�I���敪
      ,it_base_code               -- 3.���_�R�[�h
      ,it_subinventory_code       -- 4.�ۊǏꏊ
      ,it_warehouse_kbn           -- 5.�q�ɋ敪
      ,it_inventory_place         -- 6.�I���ꏊ
      ,iv_fiscal_date             -- 7.�N��
      ,it_inventory_date          -- 8.�I����
      ,cv_1                       -- 9.�I���X�e�[�^�X
      ,cn_created_by              --10.�쐬��
      ,SYSDATE                    --11.�쐬��
      ,cn_last_updated_by         --12.�ŏI�X�V��
      ,SYSDATE                    --13.�ŏI�X�V��
      ,cn_last_update_login       --14.�ŏI�X�V���[�U
      ,cn_request_id              --15.�v��ID
      ,cn_program_application_id  --16.�v���O�����E�A�v���P�[�V����ID
      ,cn_program_id              --17.�v���O����ID
      ,SYSDATE                    --18.�v���O�����X�V��
     );
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
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
  END ins_inv_control;
--
  /**********************************************************************************
   * Procedure Name   : ins_hht_result
   * Description      : HHT�I�����ʏo��(B-6)
   ***********************************************************************************/
  PROCEDURE ins_hht_result(
    it_inventory_seq      IN  xxcoi_inv_result.inventory_seq%TYPE,     -- 1.�I��SEQ
    it_interface_id       IN  xxcoi_inv_result.interface_id%TYPE,      -- 2.�C���^�[�t�F�[�XID
    it_input_order        IN  xxcoi_inv_result.input_order%TYPE,       -- 3.�捞��
    it_base_code          IN  xxcoi_inv_result.base_code%TYPE,         -- 4.���_�R�[�h
    it_inventory_kbn      IN  xxcoi_inv_result.inventory_kbn%TYPE,     -- 5.�I���敪
    it_inventory_date     IN  xxcoi_inv_result.inventory_date%TYPE,    -- 6.�I����
    it_warehouse_kbn      IN  xxcoi_inv_result.warehouse_kbn%TYPE,     -- 7.�q�ɋ敪
    it_inventory_place    IN  xxcoi_inv_result.inventory_place%TYPE,   -- 8.�I���ꏊ
    it_item_code          IN  xxcoi_inv_result.item_code%TYPE,         -- 9.�i�ڃR�[�h
    it_case_qty           IN  xxcoi_inv_result.case_qty%TYPE,          --10.�P�[�X��
    it_case_in_qty        IN  xxcoi_inv_result.case_in_qty%TYPE,       --11.���萔
    it_quantity           IN  xxcoi_inv_result.quantity%TYPE,          --12.�{��
    it_slip_no            IN  xxcoi_inv_result.slip_no%TYPE,           --13.�`�[��
    it_quality_goods_kbn  IN  xxcoi_inv_result.quality_goods_kbn%TYPE, --14.�Ǖi�敪
    it_receive_date       IN  xxcoi_inv_result.receive_date%TYPE,      --15.��M����
    ov_errbuf             OUT VARCHAR2,     --   �G���[�E���b�Z�[�W            --# �Œ� #
    ov_retcode            OUT VARCHAR2,     --   ���^�[���E�R�[�h              --# �Œ� #
    ov_errmsg             OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_hht_result'; -- �v���O������
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
    cv_0    CONSTANT VARCHAR2(1)  := '0';
    cv_n    CONSTANT VARCHAR2(1)  := 'N';
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
    --HHT�I�����ʃe�[�u���֓o�^
    INSERT INTO xxcoi_inv_result(
       inventory_seq            -- 1.�I��SEQ
      ,interface_id             -- 2.�C���^�[�t�F�[�XID
      ,input_order              -- 3.�捞��
      ,base_code                -- 4.���_�R�[�h
      ,inventory_kbn            -- 5.�I���敪
      ,inventory_date           -- 6.�I����
      ,warehouse_kbn            -- 7.�q�ɋ敪
      ,inventory_place          -- 8.�I���ꏊ
      ,process_flag             -- 9.�����σt���O
      ,item_code                --10.�i�ڃR�[�h
      ,case_qty                 --11.�P�[�X��
      ,case_in_qty              --12.���萔
      ,quantity                 --13.�{��
      ,slip_no                  --14.�`�[��
      ,quality_goods_kbn        --15.�Ǖi�敪
      ,receive_date             --16.��M����
      ,created_by               --17.�쐬��
      ,creation_date            --18.�쐬��
      ,last_updated_by          --19.�ŏI�X�V��
      ,last_update_date         --20.�ŏI�X�V��
      ,last_update_login        --21.�ŏI�X�V���[�U
      ,request_id               --22.�v��ID
      ,program_application_id   --23.�v���O�����E�A�v���P�[�V����ID
      ,program_id               --24.�v���O����ID
      ,program_update_date      --25.�v���O�����X�V��
    )VALUES(
       it_inventory_seq                 -- 1.�I��SEQ
      ,it_interface_id                  -- 2.�C���^�[�t�F�[�XID
      ,it_input_order                   -- 3.�捞��
      ,it_base_code                     -- 4.���_�R�[�h
      ,it_inventory_kbn                 -- 5.�I���敪
      ,it_inventory_date                -- 6.�I����
      ,it_warehouse_kbn                 -- 7.�q�ɋ敪
      ,it_inventory_place               -- 8.�I���ꏊ
      ,cv_n                             -- 9.�����σt���O
      ,it_item_code                     --10.�i�ڃR�[�h
      ,it_case_qty                      --11.�P�[�X��
      ,it_case_in_qty                   --12.���萔
      ,it_quantity                      --13.�{��
      ,it_slip_no                       --14.�`�[��
      ,NVL(it_quality_goods_kbn, cv_0)  --15.�Ǖi�敪
      ,it_receive_date                  --16.��M����
      ,cn_created_by                    --17.�쐬��
      ,SYSDATE                          --18.�쐬��
      ,cn_last_updated_by               --19.�ŏI�X�V��
      ,SYSDATE                          --20.�ŏI�X�V��
      ,cn_last_update_login             --21.�ŏI�X�V���[�U
      ,cn_request_id                    --22.�v��ID
      ,cn_program_application_id        --23.�v���O�����E�A�v���P�[�V����ID
      ,cn_program_id                    --24.�v���O����ID
      ,SYSDATE                          --25.�v���O�����X�V��
     );
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
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
  END ins_hht_result;
--
  /**********************************************************************************
   * Procedure Name   : del_inv_result_file
   * Description      : �I�����ʃt�@�C��IF�폜(B-8)
   ***********************************************************************************/
  PROCEDURE del_inv_result_file(
    it_interface_id       IN  xxcoi_in_inv_result_file_if.interface_id%TYPE,   -- 1.�C���^�[�t�F�[�XID
    ov_errbuf             OUT VARCHAR2,     --   �G���[�E���b�Z�[�W            --# �Œ� #
    ov_retcode            OUT VARCHAR2,     --   ���^�[���E�R�[�h              --# �Œ� #
    ov_errmsg             OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'del_inv_result_file'; -- �v���O������
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
    --�I�����ʃt�@�C��IF����폜
    DELETE xxcoi_in_inv_result_file_if xirfi
    WHERE  xirfi.interface_id = it_interface_id
    ;
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
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
  END del_inv_result_file;
--
  /**********************************************************************************
   * Procedure Name   : get_uplode_data
   * Description      : �t�@�C���A�b�v���[�hI/F�f�[�^�擾(B-10)
   ***********************************************************************************/
  PROCEDURE get_uplode_data(
    in_file_id          IN  NUMBER,       -- 1.�t�@�C��ID
    ov_errbuf           OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_uplode_data'; -- �v���O������
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
    cv_xxcoi1_msg_10142 CONSTANT VARCHAR2(16)  := 'APP-XXCOI1-10142';   --�t�@�C���A�b�v���[�h���b�N�擾�G���[
    cv_xxcoi1_msg_10290 CONSTANT VARCHAR2(16)  := 'APP-XXCOI1-10290';   --BLOB�f�[�^�ϊ��G���[
    cv_xxcoi1_msg_00020 CONSTANT VARCHAR2(16)  := 'APP-XXCOI1-00020';   --��t�@�C���G���[
    cv_xxcoi1_msg_00028 CONSTANT VARCHAR2(16)  := 'APP-XXCOI1-00028';   --�t�@�C�����o��
--
    cv_tkn_file_id      CONSTANT VARCHAR2(30)  := 'FILE_ID';            --�g�[�N����(FILE_ID)
    cv_tkn_file_name    CONSTANT VARCHAR2(39)  := 'FILE_NAME';          --�g�[�N����(FILE_NAME)
--
    cv_comma            CONSTANT VARCHAR2(1)   := ',';                  --�J���}
    cn_line_num         CONSTANT NUMBER        := 2;                    --�s��
    cn_length_zero      CONSTANT NUMBER        := 0;                    --������̃J���}�Ȃ��̏ꍇ
    cn_first_char       CONSTANT NUMBER        := 1;                    --1������
    cn_add_value        CONSTANT NUMBER        := 2;                    --������ւ̉��Z�l
--
    -- *** ���[�J���ϐ� ***
--
    lb_retcode              BOOLEAN         DEFAULT NULL;   --���b�Z�[�W�o�̖͂߂�l
    lv_msg                  VARCHAR2(500)   DEFAULT NULL;   --���b�Z�[�W�擾�ϐ�
    lv_file_name            VARCHAR2(256)   DEFAULT NULL;   --�t�@�C����
--
    lv_base_code            VARCHAR2(4)     DEFAULT NULL;   --���_�R�[�h
    lv_inventory_kbn        VARCHAR2(1)     DEFAULT NULL;   --�I���敪
    lv_inventory_date       VARCHAR2(8)     DEFAULT NULL;   --�I����
    lv_warehouse_kbn        VARCHAR2(1)     DEFAULT NULL;   --�q�ɋ敪
    lv_inventory_place      VARCHAR2(9)     DEFAULT NULL;   --�I���ꏊ
    lv_item_code            VARCHAR2(7)     DEFAULT NULL;   --�i�ڃR�[�h(�i���R�[�h)
    lv_case_qty             VARCHAR2(7)     DEFAULT NULL;   --�P�[�X��
    lv_case_in_qty          VARCHAR2(5)     DEFAULT NULL;   --����
    lv_quantity             VARCHAR2(10)    DEFAULT NULL;   --�{��
    lv_slip_no              VARCHAR2(12)    DEFAULT NULL;   --�`�[��
    lv_quality_goods_kbn    VARCHAR2(1)     DEFAULT NULL;   --�Ǖi�敪
    lv_receive_date         VARCHAR2(19)    DEFAULT NULL;   --��M����
--
    lv_line                 VARCHAR2(32767) DEFAULT NULL;   --1�s�̃f�[�^
    lb_col                  BOOLEAN         DEFAULT TRUE;   --�J�����쐬�p��
    ln_col                  NUMBER          DEFAULT 0;      --�J����
    ln_loop_cnt             NUMBER          DEFAULT 0;      --LOOP�J�E���^
    ln_length               NUMBER;                         --�J���}�̈ʒu
    lb_file_data            BLOB;                           --�t�@�C���f�[�^
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
     -- �s�e�[�u���i�[�̈�
    l_file_data_tab   xxccp_common_pkg2.g_file_data_tbl;
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
    -- ===================================================
    -- 1.�t�@�C���A�b�v���[�hIF�\�̃f�[�^�E���b�N���擾
    -- ===================================================
    SELECT xmfui.file_name AS file_name
    INTO   lv_file_name
    FROM   xxccp_mrp_file_ul_interface xmfui
    WHERE  xmfui.file_id = in_file_id
    FOR UPDATE NOWAIT;
    -- =============================================================================
    -- 2.�t�@�C�������b�Z�[�W�o��
    -- =============================================================================
    lv_msg := xxccp_common_pkg.get_msg(
                iv_application  => cv_xxcoi_short_name
              , iv_name         => cv_xxcoi1_msg_00028
              , iv_token_name1  => cv_tkn_file_name
              , iv_token_value1 => lv_file_name
              );
    --��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_msg
    );
    --
    -- ======================
    -- 3.BLOB�f�[�^�ϊ�
    -- ======================
    xxccp_common_pkg2.blob_to_varchar2(
      in_file_id   => in_file_id
    , ov_file_data => l_file_data_tab
    , ov_errbuf    => lv_errbuf
    , ov_retcode   => lv_retcode
    , ov_errmsg    => lv_errmsg
    );
    --
    -- *** ���^�[���R�[�h��0(����)�ȊO�̏ꍇ�A��O���� ***
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE blob_expt;
    END IF;
--
    -- ======================================
    -- 4.�擾�����f�[�^�̌������`�F�b�N
    -- ======================================
    -- *** ������1��(�^�C�g���s�̂�)�̏ꍇ�A��O���� ***
    IF ( l_file_data_tab.LAST < cn_line_num ) THEN
      RAISE file_expt;
    END IF;
    --
    -- *** �擾���������A�s���Ƃɏ���(2�s�ڈȍ~) ***
    <<for_loop>>
    FOR ln_index IN 2 .. l_file_data_tab.LAST LOOP
      --LOOP�J�E���^
      ln_loop_cnt := ln_loop_cnt + 1;
      --1�s���̃f�[�^���i�[
      lv_line := l_file_data_tab(ln_index);
      --�ϐ���������
      lb_col := TRUE;
      ln_col := 0;
      --
      lv_base_code         := NULL;
      lv_inventory_kbn     := NULL;
      lv_inventory_date    := NULL;
      lv_warehouse_kbn     := NULL;
      lv_inventory_place   := NULL;
      lv_item_code         := NULL;
      lv_case_qty          := NULL;
      lv_case_in_qty       := NULL;
      lv_quantity          := NULL;
      lv_slip_no           := NULL;
      lv_quality_goods_kbn := NULL;
      lv_receive_date      := NULL;
      -- *** ��؂蕶���P��(�J���})�ŕ��� ***
      <<comma_loop>>
      LOOP
      --lv_line�̒�����0�Ȃ�I��
      EXIT WHEN( (lb_col = FALSE) OR (lv_line IS NULL) );
      --
        --�J�����ԍ����J�E���g
        ln_col := ln_col + 1;
        --
        --�J���}�̈ʒu���擾
        ln_length := INSTR(lv_line, cv_comma);
        --�J���}���Ȃ�
        IF ( ln_length = cn_length_zero ) THEN
          ln_length := LENGTH(lv_line);
          lb_col    := FALSE;
        --�J���}������
        ELSE
          ln_length := ln_length - 1;
          lb_col    := TRUE;
        END IF;
        --
        -- *** CSV�`�������ڂ��Ƃɕ������ϐ��Ɋi�[ ***
        --col = 1,6,14�͕s�g�p���ڂ̈׏��O
        --����1(���_�R�[�h)
        IF ( ln_col = 2 ) THEN
-- == 2009/04/21 V1.3 Modified START ===============================================================
--           lv_base_code        := SUBSTR(lv_line, cn_first_char, ln_length);
           lv_base_code        := TRIM(SUBSTR(lv_line, cn_first_char, ln_length));
-- == 2009/04/21 V1.3 Modified END   ===============================================================
        --����2(�I���敪)
        ELSIF ( ln_col = 3 ) THEN
-- == 2009/04/21 V1.3 Modified START ===============================================================
--          lv_inventory_kbn     := SUBSTR(lv_line, cn_first_char, ln_length);
          lv_inventory_kbn     := TRIM(SUBSTR(lv_line, cn_first_char, ln_length));
-- == 2009/04/21 V1.3 Modified END   ===============================================================
        --����3(�I����)
        ELSIF ( ln_col = 4 ) THEN
          lv_inventory_date    := SUBSTR (lv_line, cn_first_char, ln_length);
        --����4(�q�ɋ敪)
        ELSIF ( ln_col = 5 ) THEN
-- == 2009/04/21 V1.3 Modified START ===============================================================
--          lv_warehouse_kbn     := SUBSTR (lv_line, cn_first_char, ln_length);
          lv_warehouse_kbn     := TRIM(SUBSTR (lv_line, cn_first_char, ln_length));
-- == 2009/04/21 V1.3 Modified END   ===============================================================
        --����5(�I���ꏊ)
        ELSIF ( ln_col = 7) THEN
-- == 2009/04/21 V1.3 Modified START ===============================================================
--          lv_inventory_place   := SUBSTR (lv_line, cn_first_char, ln_length);
          lv_inventory_place   := TRIM(SUBSTR (lv_line, cn_first_char, ln_length));
-- == 2009/04/21 V1.3 Modified END   ===============================================================
        --����6(�i�ڃR�[�h)
        ELSIF ( ln_col = 8 ) THEN
-- == 2009/04/21 V1.3 Modified START ===============================================================
--          lv_item_code         := SUBSTR(lv_line, cn_first_char, ln_length);
          lv_item_code         := TRIM(SUBSTR(lv_line, cn_first_char, ln_length));
-- == 2009/04/21 V1.3 Modified END   ===============================================================
        --����7(�P�[�X��)
        ELSIF ( ln_col = 9 ) THEN
          lv_case_qty          := SUBSTR(lv_line, cn_first_char, ln_length);
        --����8(����)
        ELSIF ( ln_col = 10 ) THEN
          lv_case_in_qty       := SUBSTR(lv_line, cn_first_char, ln_length);
        --����9(�{��)
        ELSIF ( ln_col = 11 ) THEN
          lv_quantity          := SUBSTR(lv_line, cn_first_char, ln_length);
        --����10(�`�[��)
        ELSIF ( ln_col = 12 ) THEN
-- == 2009/04/21 V1.3 Modified START ===============================================================
--          lv_slip_no           := SUBSTR(lv_line, cn_first_char, ln_length);
          lv_slip_no           := TRIM(SUBSTR(lv_line, cn_first_char, ln_length));
-- == 2009/04/21 V1.3 Modified END   ===============================================================
        --����11(�Ǖi�敪)
        ELSIF ( ln_col = 13 ) THEN
-- == 2009/04/21 V1.3 Modified START ===============================================================
--          lv_quality_goods_kbn := SUBSTR(lv_line, cn_first_char, ln_length);
          lv_quality_goods_kbn := TRIM(SUBSTR(lv_line, cn_first_char, ln_length));
-- == 2009/04/21 V1.3 Modified END   ===============================================================
        --����12(��M����)
        ELSIF ( ln_col = 15 ) THEN
          lv_receive_date      := SUBSTR(lv_line, cn_first_char, ln_length);
        END IF;
        --
        -- *** �擾�������ڂ�����(�J���}�͂̂������߁Aln_length + 2) ***
        IF ( lb_col = TRUE ) THEN
          lv_line := SUBSTR(lv_line, ln_length + cn_add_value);
        ELSE
          lv_line := SUBSTR(lv_line, ln_length);
        END IF;
      --
      END LOOP comma_loop;
      --
      -- =======================
      -- 5.�ꎞ�\�֎�荞��
      -- =======================
      --
      INSERT INTO xxcoi_tmp_inv_result(
         sort_no              -- 1.�捞��
        ,base_code            -- 2.���_�R�[�h
        ,inventory_kbn        -- 3.�I���敪
        ,inventory_date       -- 4.�I����
        ,warehouse_kbn        -- 5.�q�ɋ敪
        ,inventory_place      -- 6.�I���ꏊ
        ,item_code            -- 7.�i�ڃR�[�h
        ,case_qty             -- 8.�P�[�X��
        ,case_in_qty          -- 9.����
        ,quantity             --10.�{��
        ,slip_no              --11.�`�[��
        ,quality_goods_kbn    --12.�Ǖi�敪
        ,receive_date         --13.��M����
        ,file_id              --14.�t�@�C��ID
      )VALUES(
         ln_loop_cnt          -- 1.�捞��(LOOP�J�E���^)
        ,lv_base_code         -- 2.���_�R�[�h
        ,lv_inventory_kbn     -- 3.�I���敪
        ,lv_inventory_date    -- 4.�I����
        ,lv_warehouse_kbn     -- 5.�q�ɋ敪
        ,lv_inventory_place   -- 6.�I���ꏊ
        ,lv_item_code         -- 7.�i�ڃR�[�h
        ,lv_case_qty          -- 8.�P�[�X��
        ,lv_case_in_qty       -- 9.����
        ,lv_quantity          --10.�{��
        ,lv_slip_no           --11.�`�[��
        ,lv_quality_goods_kbn --12.�Ǖi�敪
        ,lv_receive_date      --13.��M����
        ,in_file_id           --14.�t�@�C��ID
      );
    --
    END LOOP for_loop;
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
    --*** �t�@�C���A�b�v���[�h���b�N�擾�G���[ ***
    WHEN lock_expt THEN
      --���b�Z�[�W�擾
      lv_errmsg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_xxcoi_short_name
                 ,iv_name         => cv_xxcoi1_msg_10142
                );
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;                                                  --# �C�� #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# �C�� #
    -- *** BLOB�f�[�^�ϊ��G���[ ***
    WHEN blob_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_xxcoi_short_name
                , iv_name         => cv_xxcoi1_msg_10290
                , iv_token_name1  => cv_tkn_file_id
                , iv_token_value1 => in_file_id
                );
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ��t�@�C���G���[ ***
    WHEN file_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_xxcoi_short_name
                , iv_name         => cv_xxcoi1_msg_00020
                , iv_token_name1  => cv_tkn_file_id
                , iv_token_value1 => in_file_id
                );
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
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
  END get_uplode_data;
--
  /**********************************************************************************
   * Procedure Name   : chk_file_data
   * Description      : �t�@�C���f�[�^�`�F�b�N(B-11)
   ***********************************************************************************/
  PROCEDURE chk_file_data(
    it_order_no           IN  xxcoi_tmp_inv_result.sort_no%TYPE,               -- 1.�捞��
    it_base_code          IN  xxcoi_tmp_inv_result.base_code%TYPE,             -- 2.���_�R�[�h
    it_inventory_kbn      IN  xxcoi_tmp_inv_result.inventory_kbn%TYPE,         -- 3.�I���敪
    it_inventory_date     IN  xxcoi_tmp_inv_result.inventory_date%TYPE,        -- 4.�I����
    it_inventory_place    IN  xxcoi_tmp_inv_result.inventory_place%TYPE,       -- 5.�I���ꏊ
    it_warehouse_kbn      IN  xxcoi_tmp_inv_Result.warehouse_kbn%TYPE,         -- 6.�q�ɋ敪
    it_item_code          IN  xxcoi_tmp_inv_result.item_code%TYPE,             -- 7.�i�ڃR�[�h
    it_receive_date       IN  xxcoi_tmp_inv_result.receive_date%TYPE,          -- 8.��M����
    it_case_qty           IN  xxcoi_tmp_inv_result.case_qty%TYPE,              -- 9.�P�[�X��
    it_case_in_qty        IN  xxcoi_tmp_inv_result.case_in_qty%TYPE,           --10.����
    it_quantity           IN  xxcoi_tmp_inv_result.quantity%TYPE,              --11.�{��
    ov_errbuf             OUT VARCHAR2,     --   �G���[�E���b�Z�[�W            --# �Œ� #
    ov_retcode            OUT VARCHAR2,     --   ���^�[���E�R�[�h              --# �Œ� #
    ov_errmsg             OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_file_data'; -- �v���O������
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
    --���b�Z�[�W
    cv_xxcoi1_msg_10140 CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10140';
    cv_xxcoi1_msg_10186 CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10186';
    cv_xxcoi1_msg_10138 CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10138';
    cv_xxcoi1_msg_10139 CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10139';
    --�g�[�N��
    cv_tkn_ord_no       CONSTANT VARCHAR2(8)  := 'ORDER_NO';
    cv_tkn_col          CONSTANT VARCHAR2(6)  := 'COLUMN';
    cv_tkn_val          CONSTANT VARCHAR2(5)  := 'VALUE';
    cv_tkn_loc_cd       CONSTANT VARCHAR2(11) := 'LOCATION_CD';
    cv_tkn_ivt_cd       CONSTANT VARCHAR2(6)  := 'IVT_CD';
    --�N�C�b�N�R�[�h
    cv_lk_reslt_col     CONSTANT VARCHAR2(29) := 'XXCOI1_INV_RESULT_FILE_COLUMN'; --���_�R�[�h
    --���ږ���
    cv_input_order      CONSTANT VARCHAR2(11) := 'INPUT_ORDER';
    cv_base_code        CONSTANT VARCHAR2(9)  := 'BASE_CODE';
    cv_inv_kbn          CONSTANT VARCHAR2(13) := 'INVENTORY_KBN';
    cv_inv_place        CONSTANT VARCHAR2(15) := 'INVENTORY_PLACE';
    cv_item_code        CONSTANT VARCHAR2(9)  := 'ITEM_CODE';
    cv_receive_dt       CONSTANT VARCHAR2(12) := 'RECEIVE_DATE';
    cv_case_qty         CONSTANT VARCHAR2(8)  := 'CASE_QTY';
    cv_case_in_qty      CONSTANT VARCHAR2(11) := 'CASE_IN_QTY';
    cv_qty              CONSTANT VARCHAR2(8)  := 'QUANTITY';
    cv_inv_dt           CONSTANT VARCHAR2(14) := 'INVENTORY_DATE';
    cv_ware_kbn         CONSTANT VARCHAR2(13) := 'WAREHOUSE_KBN';
--
    cv_ymd              CONSTANT VARCHAR2(8)  := 'YYYYMMDD';
    cv_ymdhms           CONSTANT VARCHAR2(21) := 'YYYY/MM/DD HH24:MI:SS';
    -- *** ���[�J���ϐ� ***
    lt_column           fnd_lookup_values.meaning%TYPE;   --���ږ�
    lv_value            VARCHAR2(50);                     --���ڒl
    ld_chk_date         DATE;                             --���t�ϊ��p
--
    ln_num              NUMBER;                           --���l�ϊ��p
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
    --===============
    --�K�{�`�F�b�N
    --===============
    --�捞��
    IF (it_order_no IS NULL) THEN
      lt_column := xxcoi_common_pkg.get_meaning(
                   cv_lk_reslt_col
                  ,cv_input_order
                );
      --�擾�ł��Ȃ������ꍇ�G���[
      IF (lt_column IS NULL) THEN
        RAISE get_result_col_expt;
      END IF;
      --�K�{�`�F�b�N�G���[
      RAISE required_expt;
    --���_�R�[�h
    ELSIF (it_base_code IS NULL) THEN
      lt_column := xxcoi_common_pkg.get_meaning(
                   cv_lk_reslt_col
                  ,cv_base_code
                );
      --�擾�ł��Ȃ������ꍇ�G���[
      IF (lt_column IS NULL) THEN
        RAISE get_result_col_expt;
      END IF;
      --�K�{�`�F�b�N�G���[
      RAISE required_expt;
    --�I���敪
    ELSIF (it_inventory_kbn IS NULL) THEN
      lt_column := xxcoi_common_pkg.get_meaning(
                   cv_lk_reslt_col
                  ,cv_inv_kbn
                );
      --�擾�ł��Ȃ������ꍇ�G���[
      IF (lt_column IS NULL) THEN
        RAISE get_result_col_expt;
      END IF;
      --�K�{�`�F�b�N�G���[
      RAISE required_expt;
    --�I���ꏊ
    ELSIF (it_inventory_place IS NULL) THEN
      lt_column := xxcoi_common_pkg.get_meaning(
                   cv_lk_reslt_col
                  ,cv_inv_place
                );
      --�擾�ł��Ȃ������ꍇ�G���[
      IF (lt_column IS NULL) THEN
        RAISE get_result_col_expt;
      END IF;
      --�K�{�`�F�b�N�G���[
      RAISE required_expt;
    --�i�ڃR�[�h
    ELSIF (it_item_code IS NULL) THEN
      lt_column := xxcoi_common_pkg.get_meaning(
                   cv_lk_reslt_col
                  ,cv_item_code
                );
      --�擾�ł��Ȃ������ꍇ�G���[
      IF (lt_column IS NULL) THEN
        RAISE get_result_col_expt;
      END IF;
      --�K�{�`�F�b�N�G���[
      RAISE required_expt;
    --��M����
    ELSIF (it_receive_date IS NULL) THEN
      lt_column := xxcoi_common_pkg.get_meaning(
                   cv_lk_reslt_col
                  ,cv_receive_dt
                );
      --�擾�ł��Ȃ������ꍇ�G���[
      IF (lt_column IS NULL) THEN
        RAISE get_result_col_expt;
      END IF;
      --�K�{�`�F�b�N�G���[
      RAISE required_expt;
    --�q�ɋ敪
    ELSIF (it_warehouse_kbn IS NULL) THEN
      lt_column := xxcoi_common_pkg.get_meaning(
                   cv_lk_reslt_col
                  ,cv_ware_kbn
                );
      --�擾�ł��Ȃ������ꍇ�G���[
      IF (lt_column IS NULL) THEN
        RAISE get_result_col_expt;
      END IF;
      --�K�{�`�F�b�N�G���[
      RAISE required_expt;
    END IF;
--
    --================
    --���p�����`�F�b�N
    --================
    --�P�[�X��
    IF (xxccp_common_pkg.chk_number(it_case_qty) = FALSE) THEN
      lt_column := xxcoi_common_pkg.get_meaning(
                   cv_lk_reslt_col
                  ,cv_case_qty
                );
      --���̂��擾�ł��Ȃ������ꍇ�G���[
      IF (lt_column IS NULL) THEN
        RAISE get_result_col_expt;
      END IF;
--
      lv_value := TO_CHAR(it_case_qty);
      --���p�����`�F�b�N�G���[
      RAISE harf_number_expt;
    --����
    ELSIF (xxccp_common_pkg.chk_number(it_case_in_qty) = FALSE) THEN
      lt_column := xxcoi_common_pkg.get_meaning(
                   cv_lk_reslt_col
                  ,cv_case_in_qty
                );
      --���̂��擾�ł��Ȃ������ꍇ�G���[
      IF (lt_column IS NULL) THEN
        RAISE get_result_col_expt;
      END IF;
--
      lv_value := TO_CHAR(it_case_in_qty);
      --���p�����`�F�b�N�G���[
      RAISE harf_number_expt;
    END IF;
--
    --�{��
    --�����_���Ȃ̂ŋ��ʊ֐��ł̓`�F�b�N�s��
    BEGIN
      ln_num := TO_NUMBER(it_quantity);
    EXCEPTION
      WHEN OTHERS THEN
        lt_column := xxcoi_common_pkg.get_meaning(
                     cv_lk_reslt_col
                    ,cv_qty
                  );
        --���̂��擾�ł��Ȃ������ꍇ�G���[
        IF (lt_column IS NULL) THEN
          RAISE get_result_col_expt;
        END IF;
--
        lv_value := TO_CHAR(it_quantity);
        --���p�����`�F�b�N�G���[
        RAISE harf_number_expt;
    END;
--
    --===============
    --�����`�F�b�N
    --===============
    --�{��
    IF ((INSTRB(it_quantity, '.') > 8)
      OR  ((INSTRB(it_quantity, '.') > 0)
      AND (LENGTHB(SUBSTRB(it_quantity, INSTRB(it_quantity, '.') + 1)) > 2))
      OR  ((INSTRB(it_quantity, '.') = 0)
      AND (LENGTHB(it_quantity) > 7)))
    THEN
      lt_column := xxcoi_common_pkg.get_meaning(
                   cv_lk_reslt_col
                  ,cv_qty
                );
      --���̂��擾�ł��Ȃ������ꍇ�G���[
      IF (lt_column IS NULL) THEN
        RAISE get_result_col_expt;
      END IF;
--
      lv_value := it_quantity;
      --���p�����`�F�b�N�G���[
      RAISE harf_number_expt;
    END IF;
--
    --===============
    --���t�`�F�b�N
    --===============
    --�I����
    BEGIN
      SELECT TO_DATE(it_inventory_date, cv_ymd)
      INTO   ld_chk_date
      FROM   DUAL
      ;
    EXCEPTION
      WHEN OTHERS THEN
        lt_column := xxcoi_common_pkg.get_meaning(
                     cv_lk_reslt_col
                    ,cv_inv_dt
                  );
        --���̂��擾�ł��Ȃ������ꍇ�G���[
        IF (lt_column IS NULL) THEN
          RAISE get_result_col_expt;
        END IF;
--
        lv_value := it_inventory_date;
--
        --���t�`�F�b�N�G���[
        RAISE date_expt;
    END;
--
    --��M����
    BEGIN
      SELECT TO_DATE(it_receive_date, cv_ymdhms)
      INTO   ld_chk_date
      FROM   DUAL
      ;
    EXCEPTION
      WHEN OTHERS THEN
        lt_column := xxcoi_common_pkg.get_meaning(
                     cv_lk_reslt_col
                    ,cv_receive_dt
                  );
        --���̂��擾�ł��Ȃ������ꍇ�G���[
        IF (lt_column IS NULL) THEN
          RAISE get_result_col_expt;
        END IF;
--
        lv_value := it_receive_date;
--
        RAISE date_expt;
    END;
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    --*** �I�����ʃt�@�C��IF���ڎ擾�G���[ ***
    WHEN get_result_col_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_xxcoi_short_name
                 ,iv_name         => cv_xxcoi1_msg_10186);
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                     --# �C�� #
--
    --*** �K�{�`�F�b�N�G���[ ***
    WHEN required_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_xxcoi_short_name
                 ,iv_name         => cv_xxcoi1_msg_10138
                 ,iv_token_name1  => cv_tkn_ord_no
                 ,iv_token_value1 => TO_CHAR(it_order_no)
                 ,iv_token_name2  => cv_tkn_col
                 ,iv_token_value2 => lt_column
                 ,iv_token_name3  => cv_tkn_loc_cd
                 ,iv_token_value3 => it_base_code
                 ,iv_token_name4  => cv_tkn_ivt_cd
                 ,iv_token_value4 => it_inventory_place
                );
      IF (gn_warn_cnt = 0) THEN
        --��s�}��
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => ''
        );
      END IF;
      --���b�Z�[�W�o��
      FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg
      );
      ov_retcode := cv_status_warn;                     --# �C�� #
--
    --*** ���p�����`�F�b�N�G���[ ***
    WHEN harf_number_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_xxcoi_short_name
                 ,iv_name         => cv_xxcoi1_msg_10139
                 ,iv_token_name1  => cv_tkn_ord_no
                 ,iv_token_value1 => TO_CHAR(it_order_no)
                 ,iv_token_name2  => cv_tkn_col
                 ,iv_token_value2 => lt_column
                 ,iv_token_name3  => cv_tkn_val
                 ,iv_token_value3 => lv_value
                 ,iv_token_name4  => cv_tkn_loc_cd
                 ,iv_token_value4 => it_base_code
                 ,iv_token_name5  => cv_tkn_ivt_cd
                 ,iv_token_value5 => it_inventory_place
                );
      IF (gn_warn_cnt = 0) THEN
        --��s�}��
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => ''
        );
      END IF;
      --���b�Z�[�W�o��
      FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg
      );
      ov_retcode := cv_status_warn;                     --# �C�� #
--
    --*** ���t�`�F�b�N�G���[ ***
    WHEN date_expt THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_xxcoi_short_name
                   ,iv_name         => cv_xxcoi1_msg_10140
                   ,iv_token_name1  => cv_tkn_ord_no
                   ,iv_token_value1 => TO_CHAR(it_order_no)
                   ,iv_token_name2  => cv_tkn_col
                   ,iv_token_value2 => lt_column
                   ,iv_token_name3  => cv_tkn_val
                   ,iv_token_value3 => lv_value
                   ,iv_token_name4  => cv_tkn_loc_cd
                   ,iv_token_value4 => it_base_code
                   ,iv_token_name5  => cv_tkn_ivt_cd
                   ,iv_token_value5 => it_inventory_place
                  );
        IF (gn_warn_cnt = 0) THEN
          --��s�}��
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => ''
          );
        END IF;
        --���b�Z�[�W�o��
        FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_errmsg
        );
        ov_retcode := cv_status_warn;                     --# �C�� #
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
  END chk_file_data;
--
  /**********************************************************************************
   * Procedure Name   : ins_result_file
   * Description      : �I�����ʃt�@�C��IF�o��(B-12)
   ***********************************************************************************/
  PROCEDURE ins_result_file(
    it_order_no           IN  xxcoi_tmp_inv_result.sort_no%TYPE,               -- 1.�捞��
    it_base_code          IN  xxcoi_tmp_inv_result.base_code%TYPE,             -- 2.���_�R�[�h
    it_inventory_kbn      IN  xxcoi_tmp_inv_result.inventory_kbn%TYPE,         -- 3.�I���敪
    it_inventory_date     IN  xxcoi_tmp_inv_result.inventory_date%TYPE,        -- 4.�I����
    it_warehouse_kbn      IN  xxcoi_tmp_inv_result.warehouse_kbn%TYPE,         -- 5.�q�ɋ敪
    it_inventory_place    IN  xxcoi_tmp_inv_result.inventory_place%TYPE,       -- 6.�I���ꏊ
    it_item_code          IN  xxcoi_tmp_inv_result.item_code%TYPE,             -- 7.�i�ڃR�[�h
    it_case_qty           IN  xxcoi_tmp_inv_result.case_qty%TYPE,              -- 8.�P�[�X��
    it_case_in_qty        IN  xxcoi_tmp_inv_result.case_in_qty%TYPE,           -- 9.����
    it_quantity           IN  xxcoi_tmp_inv_result.quantity%TYPE,              --10.�{��
    it_slip_no            IN  xxcoi_tmp_inv_result.slip_no%TYPE,               --11.�`�[��
    it_quality_goods_kbn  IN  xxcoi_tmp_inv_result.quality_goods_kbn%TYPE,     --12.�Ǖi�敪
    it_receive_date       IN  xxcoi_tmp_inv_result.receive_date%TYPE,          --13.��M����
    ov_errbuf             OUT VARCHAR2,     --   �G���[�E���b�Z�[�W            --# �Œ� #
    ov_retcode            OUT VARCHAR2,     --   ���^�[���E�R�[�h              --# �Œ� #
    ov_errmsg             OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_result_file'; -- �v���O������
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
    cv_fmt_ymdhms     CONSTANT VARCHAR2(21) := 'YYYY/MM/DD HH24:MI:SS'; -- �N���������b�ϊ��p
    cv_fmt_ymd        CONSTANT VARCHAR2(8)  := 'YYYYMMDD';              -- �N�����ϊ��p
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
    --�I�����ʃt�@�C��IF�֓o�^
    INSERT INTO xxcoi_in_inv_result_file_if(
       interface_id               -- 1.�C���^�[�t�F�[�XID
      ,input_order                -- 2.�捞��
      ,base_code                  -- 3.���_�R�[�h
      ,inventory_kbn              -- 4.�I���敪
      ,inventory_date             -- 5.�I����
      ,warehouse_kbn              -- 6.�q�ɋ敪
      ,inventory_place            -- 7.�I���ꏊ
      ,item_code                  -- 8.�i�ڃR�[�h
      ,case_qty                   -- 9.�P�[�X��
      ,case_in_qty                --10.����
      ,quantity                   --11.�{��
      ,slip_no                    --12.�`�[��
      ,quality_goods_kbn          --13.�Ǖi�敪
      ,receive_date               --14.��M����
      ,created_by                 --15.�쐬��
      ,creation_date              --16.�쐬��
      ,last_updated_by            --17.�ŏI�X�V��
      ,last_update_date           --18.�ŏI�X�V��
      ,last_update_login          --19.�ŏI�X�V���[�U
      ,request_id                 --20.�v��ID
      ,program_application_id     --21.�v���O�����E�A�v���P�[�V����ID
      ,program_id                 --22.�v���O����ID
      ,program_update_date        --23.�v���O�����X�V��
    )VALUES(
       xxcoi_inv_result_s01.nextval             -- 1.�C���^�[�t�F�[�XID
      ,it_order_no                              -- 2.�捞��
      ,it_base_code                             -- 3.���_�R�[�h
      ,it_inventory_kbn                         -- 4.�I���敪
      ,TO_DATE(it_inventory_date, cv_fmt_ymd)   -- 5.�I����
      ,it_warehouse_kbn                         -- 6.�q�ɋ敪
      ,it_inventory_place                       -- 7.�I���ꏊ
      ,it_item_code                             -- 8.�i�ڃR�[�h
      ,TO_NUMBER(it_case_qty)                   -- 9.�P�[�X��
      ,TO_NUMBER(it_case_in_qty)                --10.����
      ,TO_NUMBER(it_quantity)                   --11.�{��
      ,it_slip_no                               --12.�`�[��
      ,it_quality_goods_kbn                     --13.�Ǖi�敪
      ,TO_DATE(it_receive_date, cv_fmt_ymdhms)  --14.��M����
      ,cn_created_by                            --15.�쐬��
      ,SYSDATE                                  --16.�쐬��
      ,cn_last_updated_by                       --17.�ŏI�X�V��
      ,SYSDATE                                  --18.�ŏI�X�V��
      ,cn_last_update_login                     --19.�ŏI�X�V���[�U
      ,cn_request_id                            --20.�v��ID
      ,cn_program_application_id                --21.�v���O�����E�A�v���P�[�V����ID
      ,cn_program_id                            --22.�v���O����ID
      ,SYSDATE                                  --23.�v���O�����X�V��
     );
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
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
  END ins_result_file;
--
  /**********************************************************************************
   * Procedure Name   : del_uplode_data
   * Description      : �t�@�C���A�b�v���[�hIF�f�[�^�폜(B-13)
   ***********************************************************************************/
  PROCEDURE del_uplode_data(
    in_file_id            IN  NUMBER,       -- 1.�t�@�C��ID
    ov_errbuf             OUT VARCHAR2,     --   �G���[�E���b�Z�[�W            --# �Œ� #
    ov_retcode            OUT VARCHAR2,     --   ���^�[���E�R�[�h              --# �Œ� #
    ov_errmsg             OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'del_uplode_data'; -- �v���O������
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
    -- ======================================
    -- �t�@�C���A�b�v���[�hIF�\�̍폜����
    -- ======================================
    DELETE xxccp_mrp_file_ul_interface xmfui
    WHERE  xmfui.file_id = in_file_id
    ;
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
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
  END del_uplode_data;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    in_file_id        IN  NUMBER,     -- 1.FILE_ID
    iv_format_pattern IN  VARCHAR2,   -- 2.�t�H�[�}�b�g�p�^�[��
    ov_errbuf         OUT VARCHAR2,   --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode        OUT VARCHAR2,   --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg         OUT VARCHAR2)   --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    --���b�Z�[�W
    cv_xxcoi1_msg_00008     CONSTANT  VARCHAR2(16)  := 'APP-XXCOI1-00008';            --0�����b�Z�[�W
    cv_xxcoi1_msg_10141     CONSTANT  VARCHAR2(16)  := 'APP-XXCOI1-10141';            --�I�����ʃt�@�C��IF���b�N�G���[
-- == 2009/06/02 V1.5 Added START ===============================================================
    cv_1                    CONSTANT  VARCHAR2(1)   := '1';
    cv_2                    CONSTANT  VARCHAR2(1)   := '2';
-- == 2009/06/02 V1.5 Added END   ===============================================================
--
    -- *** ���[�J���ϐ� ***
    ln_organization_id      NUMBER;                                                   --�݌ɑg�DID
--
    lt_old_base_code        xxcoi_in_inv_result_file_if.base_code%TYPE;               --OLD���_�R�[�h
    lt_old_inventory_place  xxcoi_in_inv_result_file_if.inventory_place%TYPE;         --OLD�I���ꏊ
    ld_old_inventory_date   xxcoi_in_inv_result_file_if.inventory_date%TYPE;          --OLD�I����
    lt_old_inventory_kbn    xxcoi_in_inv_result_file_if.inventory_kbn%TYPE;           --OLD�I���敪
    lt_subinventory_code    mtl_secondary_inventories.secondary_inventory_name%TYPE;  --�ۊǏꏊ
    lv_fiscal_date          VARCHAR2(6);                                              --�݌ɉ�v����
    lt_inventory_seq        xxcoi_inv_control.inventory_seq%TYPE;                     --�I��SEQ
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    -- <�J�[�\����>
    --�I�����ʃt�@�C��IF���o
    CURSOR get_inv_data_cur
    IS
-- == 2009/06/02 V1.5 Modified START ===============================================================
--      SELECT    xirfi.interface_id                  -- 1.�C���^�[�t�F�[�XID
--               ,xirfi.input_order                   -- 2.�捞��
--               ,xirfi.base_code                     -- 3.���_�R�[�h
--               ,xirfi.inventory_kbn                 -- 4.�I���敪
--               ,xirfi.inventory_date                -- 5.�I����
--               ,xirfi.warehouse_kbn                 -- 6.�q�ɋ敪
--               ,xirfi.inventory_place               -- 7.�I���ꏊ
--               ,xirfi.item_code                     -- 8.�i�ڃR�[�h
--               ,xirfi.case_qty                      -- 9.�P�[�X��
--               ,xirfi.case_in_qty                   --10.����
--               ,xirfi.quantity                      --11.�{��
--               ,xirfi.slip_no                       --12.�`�[��
--               ,xirfi.quality_goods_kbn             --13.�Ǖi�敪
--               ,xirfi.receive_date                  --14.��M����
--               ,xic.inventory_seq                   --15.�I��SEQ
--               ,xic.inventory_status                --16.�I���X�e�[�^�X
--      FROM      xxcoi_in_inv_result_file_if  xirfi  --�I�����ʃt�@�C��IF
--               ,xxcoi_inv_control         xic       --�I���Ǘ�
--      WHERE     xirfi.base_code       = xic.base_code(+)          --���_�R�[�h
--      AND       xirfi.inventory_place = xic.inventory_place(+)    --�I���ꏊ
--      AND       xirfi.inventory_date  = xic.inventory_date(+)     --�I����
--      AND       xirfi.inventory_kbn   = xic.inventory_kbn(+)      --�I���敪
--      ORDER BY  xirfi.base_code
--               ,xirfi.inventory_place
--               ,xirfi.inventory_date
--               ,xirfi.inventory_kbn
--      FOR UPDATE OF xirfi.interface_id NOWAIT
--      ;
--
      SELECT    ilv.interface_id                  --  1.�C���^�[�t�F�[�XID
               ,ilv.input_order                   --  2.�捞��
               ,ilv.base_code                     --  3.���_�R�[�h
               ,ilv.inventory_kbn                 --  4.�I���敪
               ,ilv.inventory_date                --  5.�I����
               ,ilv.warehouse_kbn                 --  6.�q�ɋ敪
               ,ilv.inventory_place               --  7.�I���ꏊ
               ,ilv.item_code                     --  8.�i�ڃR�[�h
               ,ilv.case_qty                      --  9.�P�[�X��
               ,ilv.case_in_qty                   -- 10.����
               ,ilv.quantity                      -- 11.�{��
               ,ilv.slip_no                       -- 12.�`�[��
               ,ilv.quality_goods_kbn             -- 13.�Ǖi�敪
               ,ilv.receive_date                  -- 14.��M����
               ,xic.inventory_seq                 -- 15.�I��SEQ
               ,xic.inventory_status              -- 16.�I���X�e�[�^�X
      FROM      (SELECT   xirfi.interface_id                    -- �C���^�[�t�F�[�XID
                         ,xirfi.input_order                     -- �捞��
                         ,xirfi.base_code                       -- ���_�R�[�h
                         ,xirfi.inventory_kbn                   -- �I���敪
                         ,xirfi.inventory_date                  -- �I����
                         ,xirfi.warehouse_kbn                   -- �q�ɋ敪
                         ,DECODE(xirfi.warehouse_kbn, cv_1, SUBSTRB(xirfi.inventory_place, -2, 2)
                                                    , cv_2, SUBSTRB(xirfi.inventory_place, -5, 5)
                                                         , xirfi.inventory_place
                          )               inventory_place       -- �I���ꏊ
                         ,xirfi.item_code                       -- �i�ڃR�[�h
                         ,xirfi.case_qty                        -- �P�[�X��
                         ,xirfi.case_in_qty                     -- ����
                         ,xirfi.quantity                        -- �{��
                         ,xirfi.slip_no                         -- �`�[��
                         ,xirfi.quality_goods_kbn               -- �Ǖi�敪
                         ,xirfi.receive_date                    -- ��M����
                 FROM     xxcoi_in_inv_result_file_if  xirfi    -- �I�����ʃt�@�C��IF
                )                         ilv                   -- �I�����ʃt�@�C��IF���
               ,xxcoi_inv_control         xic                   -- �I���Ǘ�
      WHERE     ilv.base_code       = xic.base_code(+)          -- ���_�R�[�h
      AND       ilv.inventory_place = xic.inventory_place(+)    -- �I���ꏊ
      AND       ilv.inventory_date  = xic.inventory_date(+)     -- �I����
      AND       ilv.inventory_kbn   = xic.inventory_kbn(+)      -- �I���敪
      ORDER BY  ilv.base_code
               ,ilv.inventory_place
               ,ilv.inventory_date
               ,ilv.inventory_kbn
      FOR UPDATE OF ilv.interface_id NOWAIT
      ;
-- == 2009/06/02 V1.5 Modified END   ===============================================================
--
    --�t�@�C���A�b�v���[�h�ꎞ�\�f�[�^���o
    CURSOR get_tmp_cur(in_file_id IN NUMBER)
    IS
      SELECT    xirt.sort_no            sort_no             -- 1.�捞��
               ,xirt.base_code          base_code           -- 2.���_�R�[�h
               ,xirt.inventory_kbn      inventory_kbn       -- 3.�I���敪
               ,xirt.inventory_date     inventory_date      -- 4.�I����
               ,xirt.warehouse_kbn      warehouse_kbn       -- 5.�q�ɋ敪
               ,xirt.inventory_place    inventory_place     -- 6.�I���ꏊ
               ,xirt.item_code          item_code           -- 7.�i�ڃR�[�h
               ,xirt.case_qty           case_qty            -- 8.�P�[�X��
               ,xirt.case_in_qty        case_in_qty         -- 9.����
               ,xirt.quantity           quantity            --10.�{��
               ,xirt.slip_no            slip_no             --11.�`�[��
               ,xirt.quality_goods_kbn  quality_goods_kbn   --12.�Ǖi�敪
               ,xirt.receive_date       receive_date        --13.��M����
      FROM      xxcoi_tmp_inv_result  xirt  --�t�@�C���A�b�v���[�h�ꎞ�\
      WHERE     xirt.file_id = in_file_id
      ORDER BY  xirt.sort_no
      ;
    -- <�J�[�\����>���R�[�h�^
    get_inv_data_rec get_inv_data_cur%ROWTYPE;
    get_tmp_rec      get_tmp_cur%ROWTYPE;
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
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
    gn_warn_cnt   := 0;
--
    --*********************************************
    --***      MD.050�̃t���[�}��\��           ***
    --***      ����Ə������̌Ăяo�����s��     ***
    --*********************************************
--
    -- ===============================
    -- <�������� B-1>
    -- ===============================
    init(
      in_file_id          =>  in_file_id          -- FILE_ID
     ,iv_format_pattern   =>  iv_format_pattern   -- �t�H�[�}�b�g�p�^�[��
     ,on_organization_id  =>  ln_organization_id  -- �݌ɑg�D�R�[�h
     ,ov_errbuf           =>  lv_errbuf           -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode          =>  lv_retcode          -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg           =>  lv_errmsg);         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
--
    --JP1����N��
    IF (in_file_id IS NULL) THEN
--
      -- ===============================
      -- <�I�����ʃt�@�C��IF���o B-2>
      -- ===============================
      --�I�����ʃf�[�^�擾�J�[�\���I�[�v��
      OPEN get_inv_data_cur;
      <<inv_data_loop>>
      LOOP
        FETCH get_inv_data_cur INTO get_inv_data_rec;
        --���f�[�^���Ȃ��Ȃ�����I��
        EXIT WHEN get_inv_data_cur%NOTFOUND;
        --�Ώی������Z
        gn_target_cnt := gn_target_cnt + 1;
--
        -- ===============================
        -- <IF�f�[�^�`�F�b�N B-3>
        -- ===============================
        chk_if_data(
           it_base_code         => get_inv_data_rec.base_code         -- 1.���_�R�[�h
          ,it_inventory_kbn     => get_inv_data_rec.inventory_kbn     -- 2.�I���敪
          ,it_inventory_date    => get_inv_data_rec.inventory_date    -- 3.�I����
          ,it_warehouse_kbn     => get_inv_data_rec.warehouse_kbn     -- 4.�q�ɋ敪
          ,it_inventory_place   => get_inv_data_rec.inventory_place   -- 5.�I���ꏊ
          ,it_item_code         => get_inv_data_rec.item_code         -- 6.�i�ڃR�[�h
          ,it_quality_goods_kbn => get_inv_data_rec.quality_goods_kbn -- 7.�Ǖi�敪
          ,iv_inventory_status  => get_inv_data_rec.inventory_status  -- 8.�I���X�e�[�^�X
          ,in_organization_id   => ln_organization_id                 -- 9.�݌ɑg�DID
          ,ov_subinventory_code => lt_subinventory_code               --10.�ۊǏꏊ
          ,ov_fiscal_date       => lv_fiscal_date                     --11.�݌ɉ�v����
          ,ov_errbuf            => lv_errbuf                          -- �G���[�E���b�Z�[�W           --# �Œ� #
          ,ov_retcode           => lv_retcode                         -- ���^�[���E�R�[�h             --# �Œ� #
          ,ov_errmsg            => lv_errmsg);                        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        --����I���̏ꍇ
        IF (lv_retcode = cv_status_normal) THEN
          --�I��SEQ��NULL���A���_�R�[�h�A�I���ꏊ�A�I�����A�I���敪��NULL�A����
          --�I��SEQ��NULL���A�O���R�[�h�̒l�ƈ�ł�����Ă�����B-5�̏������s��
          IF ((get_inv_data_rec.inventory_seq IS NULL)
            AND (((lt_old_base_code IS NULL)
              OR (get_inv_data_rec.base_code       <> lt_old_base_code))
            OR ((lt_old_inventory_place IS NULL)
              OR (get_inv_data_rec.inventory_place <> lt_old_inventory_place))
            OR ((ld_old_inventory_date IS NULL)
              OR (get_inv_data_rec.inventory_date  <> ld_old_inventory_date))
            OR ((lt_old_inventory_kbn IS NULL)
              OR (get_inv_data_rec.inventory_kbn   <> lt_old_inventory_kbn))))
          THEN
            --���R�[�h�̒l��OLD�ϐ��Ɋi�[
            lt_old_base_code       := get_inv_data_rec.base_code;
            lt_old_inventory_place := get_inv_data_rec.inventory_place;
            ld_old_inventory_date  := get_inv_data_rec.inventory_date;
            lt_old_inventory_kbn   := get_inv_data_rec.inventory_kbn;
--
            --�I��SEQ��NULL�̏ꍇ�̓V�[�P���X����擾
            IF (get_inv_data_rec.inventory_seq IS NULL) THEN
              SELECT  xxcoi_inv_control_s01.nextval
              INTO    lt_inventory_seq
              FROM    dual
              ;
            END IF;
            -- ===============================
            -- <�I���Ǘ��o�� B-5>
            -- ===============================
            ins_inv_control(
               it_inventory_seq     => lt_inventory_seq                 -- 1.�I��SEQ
              ,it_inventory_kbn     => get_inv_data_rec.inventory_kbn   -- 2.�I���敪
              ,it_base_code         => get_inv_data_rec.base_code       -- 3.���_�R�[�h
              ,it_warehouse_kbn     => get_inv_data_rec.warehouse_kbn   -- 4.�q�ɋ敪
              ,it_inventory_place   => get_inv_data_rec.inventory_place -- 5.�I���ꏊ
              ,it_inventory_date    => get_inv_data_rec.inventory_date  -- 6.�I����
              ,it_subinventory_code => lt_subinventory_code             -- 7.�ۊǏꏊ
              ,iv_fiscal_date       => lv_fiscal_date                   -- 8.��v����
              ,ov_errbuf            => lv_errbuf                        -- �G���[�E���b�Z�[�W           --# �Œ� #
              ,ov_retcode           => lv_retcode                       -- ���^�[���E�R�[�h             --# �Œ� #
              ,ov_errmsg            => lv_errmsg);                      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
            --����I���ȊO�̏ꍇ
            IF (lv_retcode <> cv_status_normal) THEN
              RAISE global_process_expt;
            END IF;
--
          END IF;
          --�I��SEQ�`�F�b�N(NULL�̏ꍇ������ĂȂ��̂ł����ōs�Ȃ��B)
          IF (get_inv_data_rec.inventory_seq IS NOT NULL) THEN
            lt_inventory_seq := get_inv_data_rec.inventory_seq;
          END IF;
--
          -- ===============================
          -- <HHT�I�����ʏo�� B-6>
          -- ===============================
          ins_hht_result(
             it_inventory_seq     => lt_inventory_seq                   -- 1.�I��SEQ
            ,it_interface_id      => get_inv_data_rec.interface_id      -- 2.�C���^�[�t�F�[�XID
            ,it_input_order       => get_inv_data_rec.input_order       -- 3.�捞��
            ,it_base_code         => get_inv_data_rec.base_code         -- 4.���_�R�[�h
            ,it_inventory_kbn     => get_inv_data_rec.inventory_kbn     -- 5.�I���敪
            ,it_inventory_date    => get_inv_data_rec.inventory_date    -- 6.�I����
            ,it_warehouse_kbn     => get_inv_data_rec.warehouse_kbn     -- 7.�q�ɋ敪
            ,it_inventory_place   => get_inv_data_rec.inventory_place   -- 8.�I���ꏊ
            ,it_item_code         => get_inv_data_rec.item_code         -- 9.�i�ڃR�[�h
            ,it_case_qty          => get_inv_data_rec.case_qty          --10.�P�[�X��
            ,it_case_in_qty       => get_inv_data_rec.case_in_qty       --11.���萔
            ,it_quantity          => get_inv_data_rec.quantity          --12.�{��
            ,it_slip_no           => get_inv_data_rec.slip_no           --13.�`�[��
            ,it_quality_goods_kbn => get_inv_data_rec.quality_goods_kbn --14.�Ǖi�敪
            ,it_receive_date      => get_inv_data_rec.receive_date      --15.��M����
            ,ov_errbuf            => lv_errbuf                          -- �G���[�E���b�Z�[�W           --# �Œ� #
            ,ov_retcode           => lv_retcode                         -- ���^�[���E�R�[�h             --# �Œ� #
            ,ov_errmsg            => lv_errmsg);                        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
          --����I���ȊO�̏ꍇ
          IF (lv_retcode <> cv_status_normal) THEN
            RAISE global_process_expt;
          END IF;
--
          --���팏���J�E���g
          gn_normal_cnt := gn_normal_cnt + 1;
--
        ELSIF (lv_retcode = cv_status_warn) THEN
          -- ===============================
          -- <HHT���捞�G���[�o�� B-4>(���ʊ֐�)
          -- ===============================
          xxcoi_common_pkg.add_hht_err_list_data(
            iv_base_code            =>  get_inv_data_rec.base_code        -- 1.���_�R�[�h
           ,iv_origin_shipment      =>  get_inv_data_rec.inventory_place  -- 2.�o�ɑ��f�[�^
           ,iv_data_name            =>  gv_hht_err_data_name              -- 3.�f�[�^����
           ,id_transaction_date     =>  get_inv_data_rec.inventory_date   -- 4.�����
           ,iv_entry_number         =>  get_inv_data_rec.slip_no          -- 5.�`�[��
           ,iv_party_num            =>  NULL                              -- 6.���ɑ��f�[�^
           ,iv_performance_by_code  =>  NULL                              -- 7.�c�ƈ��R�[�h
           ,iv_item_code            =>  get_inv_data_rec.item_code        -- 8.�i�ڃR�[�h
           ,iv_error_message        =>  lv_errmsg                         -- 9.�G���[���e
           ,ov_errbuf               =>  lv_errbuf                         -- �G���[�E���b�Z�[�W           --# �Œ� #
           ,ov_retcode              =>  lv_retcode                        -- ���^�[���E�R�[�h             --# �Œ� #
           ,ov_errmsg               =>  lv_errmsg);                       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
          --����I���ȊO�̏ꍇ
          IF (lv_retcode <> cv_status_normal) THEN
            RAISE global_process_expt;
          END IF;
          --�x��(�X�L�b�v)�����J�E���g
          gn_warn_cnt := gn_warn_cnt + 1;
        ELSE
          RAISE global_process_expt;
        END IF;
--
        -- ===============================
        -- <�I�����ʃt�@�C��IF�폜 B-8>
        -- ===============================
        del_inv_result_file(
           it_interface_id  => get_inv_data_rec.interface_id      --1.�C���^�[�t�F�[�XID
          ,ov_errbuf        => lv_errbuf                          -- �G���[�E���b�Z�[�W           --# �Œ� #
          ,ov_retcode       => lv_retcode                         -- ���^�[���E�R�[�h             --# �Œ� #
          ,ov_errmsg        => lv_errmsg);                        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        --����I���ȊO�̏ꍇ
        IF (lv_retcode <> cv_status_normal) THEN
          RAISE global_process_expt;
        END IF;
--
      END LOOP inv_data_loop;
      CLOSE get_inv_data_cur;
--
      --�Ώی�����0���̏ꍇ���b�Z�[�W�o��
      IF (gn_target_cnt = 0) THEN
        --���b�Z�[�W�擾
        lv_errmsg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_xxcoi_short_name
                   ,iv_name         => cv_xxcoi1_msg_00008
                  );
        --��s�}��
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => ''
        );
        --���b�Z�[�W�o��
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg
        );
      END IF;
--
      --�X�L�b�v�������P���ł�����ꍇ�́A���^�[���R�[�h���x���ŕԂ��B
      IF (gn_warn_cnt > 0) THEN
        ov_retcode := cv_status_warn;
      END IF;
      --==================
      --B-9��main�ɂċL�q
      --==================
--
    --�t�@�C���A�b�v���[�h��ʋN��
    ELSE
      -- =======================================
      -- <�t�@�C���A�b�v���[�hI/F�f�[�^�擾 B-10>
      -- =======================================
      get_uplode_data(
        in_file_id  =>  in_file_id          -- �t�@�C��ID
       ,ov_errbuf   =>  lv_errbuf           -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode  =>  lv_retcode          -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg   =>  lv_errmsg);         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      IF (lv_retcode <> cv_status_normal) THEN
        RAISE global_process_expt;
      END IF;
--
      --�t�@�C���A�b�v���[�h�ꎞ�\�擾�J�[�\���I�[�v��
      OPEN get_tmp_cur(in_file_id);
      <<tmp_data_loop>>
      LOOP
        FETCH get_tmp_cur INTO get_tmp_rec;
        --���f�[�^���Ȃ��Ȃ�����I��
        EXIT WHEN get_tmp_cur%NOTFOUND;
        --�Ώی������Z
        gn_target_cnt := gn_target_cnt + 1;
        -- ===============================
        -- <�t�@�C���f�[�^�`�F�b�N B-11>
        -- ===============================
        chk_file_data(
           it_order_no        => get_tmp_rec.sort_no                -- 1.�捞��
          ,it_base_code       => get_tmp_rec.base_code              -- 2.���_�R�[�h
          ,it_inventory_kbn   => get_tmp_rec.inventory_kbn          -- 3.�I���敪
          ,it_inventory_date  => get_tmp_rec.inventory_date         -- 4.�I����
          ,it_inventory_place => get_tmp_rec.inventory_place        -- 5.�I���ꏊ
          ,it_warehouse_kbn   => get_tmp_rec.warehouse_kbn          -- 6.�q�ɋ敪
          ,it_item_code       => get_tmp_rec.item_code              -- 7.�i�ڃR�[�h
          ,it_receive_date    => get_tmp_rec.receive_date           -- 8.��M����
          ,it_case_qty        => get_tmp_rec.case_qty               -- 9.�P�[�X��
          ,it_case_in_qty     => get_tmp_rec.case_in_qty            --10.����
          ,it_quantity        => get_tmp_rec.quantity               --11.�{��
          ,ov_errbuf          => lv_errbuf                          -- �G���[�E���b�Z�[�W           --# �Œ� #
          ,ov_retcode         => lv_retcode                         -- ���^�[���E�R�[�h             --# �Œ� #
          ,ov_errmsg          => lv_errmsg);                        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
        --����I��(�G���[�Ȃ�)�Ȃ���{
        IF (lv_retcode = cv_status_normal) THEN
          -- ===============================
          -- <�I�����ʃt�@�C��IF�o�� B-12>
          -- ===============================
          ins_result_file(
             it_order_no            => get_tmp_rec.sort_no            -- 1.�捞��
            ,it_base_code           => get_tmp_rec.base_code          -- 2.���_�R�[�h
            ,it_inventory_kbn       => get_tmp_rec.inventory_kbn      -- 3.�I���敪
            ,it_inventory_date      => get_tmp_rec.inventory_date     -- 4.�I����
            ,it_warehouse_kbn       => get_tmp_rec.warehouse_kbn      -- 5.�q�ɋ敪
            ,it_inventory_place     => get_tmp_rec.inventory_place    -- 6.�I���ꏊ
            ,it_item_code           => get_tmp_rec.item_code          -- 7.�i�ڃR�[�h
            ,it_case_qty            => get_tmp_rec.case_qty           -- 8.�P�[�X��
            ,it_case_in_qty         => get_tmp_rec.case_in_qty        -- 9.����
            ,it_quantity            => get_tmp_rec.quantity           --10.�{��
            ,it_slip_no             => get_tmp_rec.slip_no            --11.�`�[��
            ,it_quality_goods_kbn   => get_tmp_rec.quality_goods_kbn  --12.�Ǖi�敪
            ,it_receive_date        => get_tmp_rec.receive_date       --13.��M����
            ,ov_errbuf              => lv_errbuf                      -- �G���[�E���b�Z�[�W           --# �Œ� #
            ,ov_retcode             => lv_retcode                     -- ���^�[���E�R�[�h             --# �Œ� #
            ,ov_errmsg              => lv_errmsg);                    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
          IF (lv_retcode <> cv_status_normal) THEN
            RAISE global_process_expt;
          END IF;
--
          --���팏���J�E���g
          gn_normal_cnt := gn_normal_cnt + 1;
--
        ELSIF (lv_retcode = cv_status_warn) THEN
          --�x�������J�E���g
          gn_warn_cnt := gn_warn_cnt + 1;
        ELSIF (lv_retcode = cv_status_error) THEN
          RAISE global_process_expt;
        END IF;
--
      END LOOP tmp_data_loop;
      CLOSE get_tmp_cur;
--
      -- ========================================
      -- <�t�@�C���A�b�v���[�hI/F�f�[�^�폜 B-13>
      -- ========================================
      del_uplode_data(
        in_file_id  => in_file_id          -- �t�@�C��ID
       ,ov_errbuf   => lv_errbuf           -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode  => lv_retcode          -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg   => lv_errmsg);         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      IF (lv_retcode <> cv_status_normal) THEN
        RAISE global_process_expt;
      END IF;
--
      --�X�L�b�v�������P���ł�����ꍇ�́A���^�[���R�[�h���x���ŕԂ��B
      IF (gn_warn_cnt > 0) THEN
        ov_retcode := cv_status_warn;
      END IF;
      --==================
      --B-14��main�ɂċL�q
      --==================
    END IF;
--
  EXCEPTION
      -- *** �C�ӂŗ�O�������L�q���� ****
      -- �J�[�\���̃N���[�Y�������ɋL�q����
    --*** �I�����ʃt�@�C��IF���b�N�擾�G���[ ***
    WHEN lock_expt THEN
      IF (get_inv_data_cur%ISOPEN) THEN
        CLOSE get_inv_data_cur;
      END IF;
      --
      IF (get_tmp_cur%ISOPEN) THEN
        CLOSE get_tmp_cur;
      END IF;
      --�G���[�����J�E���g
      gn_error_cnt := gn_error_cnt + 1;
      --���b�Z�[�W�擾
      lv_errmsg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_xxcoi_short_name
                 ,iv_name         => cv_xxcoi1_msg_10141
                );
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;                                                  --# �C�� #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# �C�� #
--
--#################################  �Œ��O������ START   ###################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      IF (get_inv_data_cur%ISOPEN) THEN
        CLOSE get_inv_data_cur;
      END IF;
      --
      IF (get_tmp_cur%ISOPEN) THEN
        CLOSE get_tmp_cur;
      END IF;
      --�G���[�����J�E���g
      gn_error_cnt := gn_error_cnt + 1;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      IF (get_inv_data_cur%ISOPEN) THEN
        CLOSE get_inv_data_cur;
      END IF;
      --
      IF (get_tmp_cur%ISOPEN) THEN
        CLOSE get_tmp_cur;
      END IF;
      --�G���[�����J�E���g
      gn_error_cnt := gn_error_cnt + 1;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      IF (get_inv_data_cur%ISOPEN) THEN
        CLOSE get_inv_data_cur;
      END IF;
      --
      IF (get_tmp_cur%ISOPEN) THEN
        CLOSE get_tmp_cur;
      END IF;
      --�G���[�����J�E���g
      gn_error_cnt := gn_error_cnt + 1;
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
    errbuf            OUT   VARCHAR2,      --   �G���[�E���b�Z�[�W  --# �Œ� #
    retcode           OUT   VARCHAR2,      --   ���^�[���E�R�[�h    --# �Œ� #
    iv_file_id        IN    VARCHAR2,      -- 1.FILE_ID
    iv_format_pattern IN    VARCHAR2       -- 2.�t�H�[�}�b�g�p�^�[��
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
    cv_prg_name   CONSTANT VARCHAR2(100) := 'main';  -- �v���O������
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
    ln_file_id         NUMBER;
    --
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
    ln_file_id  := TO_NUMBER(iv_file_id);
    -- ===============================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ===============================================
    submain(
       in_file_id         =>  ln_file_id          -- 1.FILE_ID
      ,iv_format_pattern  =>  iv_format_pattern   -- 2.�t�H�[�}�b�g�p�^�[��
      ,ov_errbuf          =>  lv_errbuf           -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode         =>  lv_retcode          -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg          =>  lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    --�G���[�o��
    IF (lv_retcode = cv_status_error) THEN
      IF (lv_errmsg IS NOT NULL) THEN
        --��s�}��
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => ''
        );
      END IF;
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
    --�Ώی����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_target_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
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
       which  => FND_FILE.OUTPUT
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
       which  => FND_FILE.OUTPUT
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
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
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
--
--###########################  �Œ蕔 END   #######################################################
--
END XXCOI006A21C;
/
