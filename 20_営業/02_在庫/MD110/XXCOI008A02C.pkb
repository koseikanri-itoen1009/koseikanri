CREATE OR REPLACE PACKAGE BODY XXCOI008A02C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOI008A02C(body)
 * Description      : ���n�V�X�e���ւ̘A�g�ׁ̈AEBS�̎��ގ���i�W���j��CSV�t�@�C���ɏo��
 * MD.050           : ���o�ɏ��n�A�g <MD050_COI_008_A02>
 * Version          : 1.1
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   ��������(A-1)
 *  get_transaction_id     �f�[�^�A�g���䃏�[�N�e�[�u���̎��ID�擾(A-2)
 *  create_csv_p           ���o�Ƀg����CSV�̍쐬(A-5)
 *  material_tran_cur_p    ���ގ�����̒��o(A-4)
 *  upd_transaction_id     �f�[�^�A�g���䃏�[�N�e�[�u���̎��ID�X�V(A-6)
 *  submain                ���C�������v���V�[�W��
 *                           �E�t�@�C���̃I�[�v������(A-3)
 *                           �E�t�@�C���̃N���[�Y����(A-7)
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/01/15    1.0   S.Kanda          �V�K�쐬
 *  2009/04/02    1.1   T.Nakamura       [��QT1_0226]IF���ڂ̏������C��
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
  cv_pkg_name               CONSTANT VARCHAR2(100) := 'XXCOI008A02C';
  cv_appl_short_name_ccp    CONSTANT VARCHAR2(10)  := 'XXCCP';         -- �A�h�I���F���ʁEIF�̈�
  cv_appl_short_name        CONSTANT VARCHAR2(10)  := 'XXCOI';         -- �A�h�I���F���ʁEIF�̈�
  cv_file_slash             CONSTANT VARCHAR2(2)   := '/';             -- �t�@�C����؂�p
  cv_file_encloser          CONSTANT VARCHAR2(2)   := '"';             -- �����f�[�^����p
  --
  -- ���b�Z�[�W�萔
  cv_msg_xxcoi_00003        CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-00003';  -- �f�B���N�g�����擾�G���[
  cv_msg_xxcoi_00004        CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-00004';  -- �t�@�C�����擾�G���[
  cv_msg_xxcoi_00005        CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-00005';  -- �݌ɑg�D�R�[�h�擾�G���[
  cv_msg_xxcoi_00006        CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-00006';  -- �݌ɑg�DID�擾�G���[
  cv_msg_xxcoi_00007        CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-00007';  -- ��ЃR�[�h�擾�G���[
  cv_msg_xxcoi_00008        CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-00008';  -- �Ώۃf�[�^�������b�Z�[�W
  cv_msg_xxcoi_00023        CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-00023';  -- �R���J�����g���̓p�����[�^�Ȃ����b�Z�[�W
  cv_msg_xxcoi_00027        CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-00027';  -- �t�@�C�����݃`�F�b�N�G���[
  cv_msg_xxcoi_00028        CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-00028';  -- �t�@�C�����o�̓��b�Z�[�W
  cv_msg_xxcoi_00029        CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-00029';  -- �f�B���N�g���t���p�X�擾�G���[
  cv_msg_xxcoi_10001        CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10001';  -- ���b�N�擾�G���[
  cv_msg_xxcoi_10002        CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10002';  -- ���[�N�e�[�u�����ID�擾�G���[
  --
  --�g�[�N��
  cv_tkn_pro                CONSTANT VARCHAR2(10)  := 'PRO_TOK';       -- �v���t�@�C�����p
  cv_tkn_dir                CONSTANT VARCHAR2(10)  := 'DIR_TOK';       -- �v���t�@�C�����p
  cv_cnt_token              CONSTANT VARCHAR2(10)  := 'COUNT';         -- �������b�Z�[�W�p
  cv_tkn_file_name          CONSTANT VARCHAR2(10)  := 'FILE_NAME';     -- �t�@�C�����p
  cv_tkn_org_code           CONSTANT VARCHAR2(15)  := 'ORG_CODE_TOK';  -- �݌ɑg�D�R�[�h�p
  cv_tkn_program_id         CONSTANT VARCHAR2(20)  := 'PROGRAM_ID';    -- �v���O����ID
  --
  --�t�@�C���I�[�v�����[�h
  cv_file_mode              CONSTANT VARCHAR2(2)   := 'W';             -- �I�[�v�����[�h
  --
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gd_process_date         DATE;                                 -- ���t�擾�p
  gv_dire_pass            VARCHAR2(100);                        -- �f�B���N�g���p�X���p
  gv_file_stock_delivery  VARCHAR2(50);                         -- ���o�Ƀt�@�C�����p
  gv_organization_code    VARCHAR2(50);                         -- �݌ɑg�D�R�[�h�擾�p
  gn_organization_id      mtl_parameters.organization_id%TYPE;  -- �݌ɑg�DID�擾�p
  gv_company_code         VARCHAR2(50);                         -- ��ЃR�[�h�擾�p
  gv_file_name            VARCHAR2(150);                        -- �t�@�C���p�X���擾�p
  gv_activ_file_h         UTL_FILE.FILE_TYPE;                   -- �t�@�C���n���h���擾�p
  gn_transaction_id       NUMBER;                               -- ���ID�擾�p
  gn_max_tran             NUMBER;                               -- ���ID�ő�l�擾�p
--
  -- ==============================
  -- ���[�U�[��`�J�[�\��
  -- ==============================
  -- ���o�ɏ��擾
  CURSOR material_tran_cur
  IS
    SELECT mmt.transaction_id              -- ���ID
         , mmt.subinventory_code           -- �ۊǏꏊ�R�[�h
         , mmt.transaction_type_id         -- ����^�C�vID
         , mmt.transaction_source_type_id  -- �\�[�X�^�C�vID
         , mtt.attribute5                  -- ����^�C�v�R�[�h(DFF5)
         , mmt.primary_quantity            -- ����
         , mmt.transaction_uom             -- ����P��
         , mmt.transaction_quantity        -- �������
         , mmt.transaction_date            -- �����
         , mmt.transaction_set_id          -- ����w�b�_
         , mmt.transfer_subinventory       -- �ړ���ۊǏꏊ�R�[�h
         , msib.segment1                   -- �i�ڃR�[�h
         , msi.attribute7                  -- ���_�R�[�h
    FROM   mtl_material_transactions   mmt    -- ���ގ���e�[�u��
         , mtl_system_items_b          msib   -- �i�ڃ}�X�^
         , mtl_secondary_inventories   msi    -- �ۊǏꏊ�}�X�^
         , mtl_transaction_types       mtt    -- ����^�C�v�}�X�^
    WHERE mmt.transaction_id            >  gn_transaction_id        -- A-2.�Ŏ擾�������ID
    AND   msib.inventory_item_id        =  mmt.inventory_item_id    -- �i��ID
    AND   msib.organization_id          =  gn_organization_id       -- A-1.�Ŏ擾�����݌ɑg�DID
    AND   msi.secondary_inventory_name  =  mmt.subinventory_code    -- �ۊǏꏊ�R�[�h
    AND   mtt.transaction_type_id       =  mmt.transaction_type_id  -- ����^�C�vID
    ORDER BY mmt.transaction_id;                                    -- ���ID
    --
    -- material_tran���R�[�h�^
    material_tran_rec   material_tran_cur%ROWTYPE;
--
    -- ===============================
    -- ���[�U�[��`��O
    -- ===============================
    get_transaction_id_expt   EXCEPTION;      -- �ŏI�A�g�����擾�G���[
    lock_expt                 EXCEPTION;      -- ���b�N�擾�G���[
    --
    PRAGMA EXCEPTION_INIT( lock_expt, -54 );  -- ���b�N�擾��O
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
     ov_errbuf     OUT VARCHAR2      --   �G���[�E���b�Z�[�W           --# �Œ� #
   , ov_retcode    OUT VARCHAR2      --   ���^�[���E�R�[�h             --# �Œ� #
   , ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    --�v���t�@�C���擾�p�萔
    cv_pro_dire_out_info       CONSTANT VARCHAR2(30)  := 'XXCOI1_DIRE_OUT_INFO';        -- �f�B���N�g�����擾�p
    cv_pro_file_stock_deli     CONSTANT VARCHAR2(30)  := 'XXCOI1_FILE_STOCK_DELIVERY';  -- �t�@�C�����擾�p
    cv_pro_org_code            CONSTANT VARCHAR2(30)  := 'XXCOI1_ORGANIZATION_CODE';    -- �݌ɑg�D�R�[�h�擾�p
    cv_pro_company_code        CONSTANT VARCHAR2(30)  := 'XXCOI1_COMPANY_CODE';         -- ��ЃR�[�h�擾�p
--
    -- *** ���[�J���ϐ� ***
    lv_directory_path       VARCHAR2(100);     -- �f�B���N�g���p�X�擾�p
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
--
    -- ===============================
    --  ����������
    -- ===============================
    gd_process_date        :=  NULL;          -- �Ɩ����t
    gv_dire_pass           :=  NULL;          -- �f�B���N�g���p�X��
    gv_file_stock_delivery :=  NULL;          -- ���o�Ƀt�@�C����
    gv_organization_code   :=  NULL;          -- �݌ɑg�D�R�[�h��
    gn_organization_id     :=  NULL;          -- �݌ɑg�DID��
    gv_company_code        :=  NULL;          -- ��ЃR�[�h��
    gv_file_name           :=  NULL;          -- �t�@�C���p�X��
    lv_directory_path      :=  NULL;          -- �f�B���N�g���t���p�X
    --
    -- ===============================
    --  1.SYSDATE�擾
    -- ===============================
    gd_process_date   :=  sysdate;
    --
    -- =======================================================
    --  2�`6.�Œ�O���[�o���萔�錾���œ�����(WHO�J����)�擾
    -- =======================================================
    --
    -- ====================================================
    -- 7.���n_OUTBOUND�i�[�f�B���N�g���������擾
    -- ====================================================
    gv_dire_pass       := fnd_profile.value( cv_pro_dire_out_info );
--
    -- �f�B���N�g������񂪎擾�ł��Ȃ������ꍇ
    IF ( gv_dire_pass IS NULL ) THEN
      -- �f�B���N�g�����擾�G���[���b�Z�[�W
      -- �u�v���t�@�C��:�f�B���N�g���p�X( PRO_TOK )�̎擾�Ɏ��s���܂����B�v
      lv_errmsg   := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_short_name
                      , iv_name         => cv_msg_xxcoi_00003
                      , iv_token_name1  => cv_tkn_pro
                      , iv_token_value1 => cv_pro_dire_out_info
                     );
      lv_errbuf   := lv_errmsg;
      --
      RAISE global_process_expt;
    END IF;
--
    -- =======================================
    -- 8.���o�Ƀt�@�C�������擾
    -- =======================================
    gv_file_stock_delivery   := fnd_profile.value( cv_pro_file_stock_deli );
    --
    -- ���o�Ƀt�@�C�������擾�ł��Ȃ������ꍇ
    IF ( gv_file_stock_delivery IS NULL ) THEN
      -- �t�@�C�����擾�G���[���b�Z�[�W
      -- �u�v���t�@�C��:�t�@�C����( PRO_TOK )�̎擾�Ɏ��s���܂����B�v
      lv_errmsg    := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appl_short_name
                       , iv_name         => cv_msg_xxcoi_00004
                       , iv_token_name1  => cv_tkn_pro
                       , iv_token_value1 => cv_pro_file_stock_deli
                      );
      lv_errbuf    := lv_errmsg;
      --
      RAISE global_process_expt;
    END IF;
    --
    -- =====================================
    -- 9.�݌ɑg�D�R�[�h���擾
    -- =====================================
    gv_organization_code := fnd_profile.value( cv_pro_org_code );
    --
    -- �݌ɑg�D�R�[�h���擾�ł��Ȃ������ꍇ
    IF  ( gv_organization_code  IS NULL ) THEN
      -- �݌ɑg�D�R�[�h�擾�G���[���b�Z�[�W
      -- �u�v���t�@�C��:�݌ɑg�D�R�[�h( PRO_TOK )�̎擾�Ɏ��s���܂����B�v
      lv_errmsg   := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appl_short_name
                       , iv_name         => cv_msg_xxcoi_00005
                       , iv_token_name1  => cv_tkn_pro
                       , iv_token_value1 => cv_pro_org_code
                     );
      lv_errbuf   := lv_errmsg;
      --
      RAISE global_process_expt;
    END IF;
    --
    -- =====================================
    -- �݌ɑg�DID�擾
    -- =====================================
    gn_organization_id := xxcoi_common_pkg.get_organization_id( gv_organization_code );
    --
    -- ���ʊ֐��̃��^�[���R�[�h���擾�ł��Ȃ������ꍇ
    IF ( gn_organization_id IS NULL ) THEN
      -- �݌ɑg�DID�擾�G���[���b�Z�[�W
      -- �u�݌ɑg�D�R�[�h( ORG_CODE_TOK )�ɑ΂���݌ɑg�DID�̎擾�Ɏ��s���܂����B�v
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name
                     , iv_name         => cv_msg_xxcoi_00006
                     , iv_token_name1  => cv_tkn_org_code
                     , iv_token_value1 => gv_organization_code
                   );
      lv_errbuf := lv_errmsg;
      --
      RAISE global_api_expt;
    END IF;
    --
    -- =====================================
    -- 10.��ЃR�[�h���擾
    -- =====================================
    gv_company_code  := fnd_profile.value( cv_pro_company_code );
    --
    -- ��ЃR�[�h���擾�ł��Ȃ������ꍇ
    IF  ( gv_company_code  IS NULL ) THEN
      -- ��ЃR�[�h�擾�G���[���b�Z�[�W
      -- �u�v���t�@�C��:��ЃR�[�h( PRO_TOK )�̎擾�Ɏ��s���܂����B�v
      lv_errmsg   := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appl_short_name
                       , iv_name         => cv_msg_xxcoi_00007
                       , iv_token_name1  => cv_tkn_pro
                       , iv_token_value1 => cv_pro_company_code
                     );
      lv_errbuf   := lv_errmsg;
      --
      RAISE global_process_expt;
    END IF;
    --
    -- =====================================
    -- 11.���b�Z�[�W�̏o�͇@
    -- =====================================
    -- �R���J�����g���̓p�����[�^�Ȃ����b�Z�[�W���o��
    gv_out_msg  := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name
                     , iv_name         => cv_msg_xxcoi_00023
                    );
    --
    -- ���b�Z�[�W�o��
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => gv_out_msg
    );
    FND_FILE.PUT_LINE(
        which  => FND_FILE.LOG
      , buff   => gv_out_msg
    );
    --
    -- =====================================
    -- 12.���b�Z�[�W�̏o�͇A
    -- =====================================
    --
    -- 2.�Ŏ擾�����v���t�@�C���l���f�B���N�g���p�X���擾
    BEGIN
      SELECT directory_path
      INTO   lv_directory_path
      FROM   all_directories     -- �f�B���N�g�����
      WHERE  directory_name = gv_dire_pass;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- �f�B���N�g���t���p�X�擾�G���[���b�Z�[�W
        -- �u���̃f�B���N�g�����ł̓f�B���N�g���p�X�͎擾�ł��܂���B
        -- �i�f�B���N�g���� = DIR_TOK �j�v
        lv_errmsg   := xxccp_common_pkg.get_msg(
                          iv_application  => cv_appl_short_name
                        , iv_name         => cv_msg_xxcoi_00029
                        , iv_token_name1  => cv_tkn_dir
                        , iv_token_value1 => gv_dire_pass
                       );
        lv_errbuf   := lv_errmsg;
        --
        RAISE global_process_expt;
    END;
    --
    -- IF�t�@�C�����iIF�t�@�C���̃t���p�X���j���o��
    -- '�f�B���N�g���p�X'��'/'�Ɓe�t�@�C����'������
    gv_file_name  := lv_directory_path || cv_file_slash || gv_file_stock_delivery;
    --�u�t�@�C���F FILE_NAME �v
    --�t�@�C�����o�̓��b�Z�[�W
    gv_out_msg  := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name
                     , iv_name         => cv_msg_xxcoi_00028
                     , iv_token_name1  => cv_tkn_file_name
                     , iv_token_value1 => gv_file_name
                    );
    --
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => gv_out_msg
      );
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    WHEN global_process_expt THEN
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
--#####################################  �Œ蕔 END   ##########################################
--
  END init;
--
  /**********************************************************************************
   * Procedure Name   : get_transaction_id
   * Description      : �f�[�^�A�g���䃏�[�N�e�[�u���̑O����ID�擾(A-2)
   ***********************************************************************************/
  PROCEDURE get_transaction_id(
      ov_errbuf     OUT VARCHAR2      --   �G���[�E���b�Z�[�W           --# �Œ� #
    , ov_retcode    OUT VARCHAR2      --   ���^�[���E�R�[�h             --# �Œ� #
    , ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_transaction_id'; -- �v���O������
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
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ���ID�p�ϐ��̏���������
    gn_transaction_id   :=  NULL;
--
    -- =======================================================
    -- �f�[�^�A�g���䃏�[�N�e�[�u������O����ID���擾
    -- =======================================================
    BEGIN
--
      SELECT xcc.transaction_id AS transaction_id      -- �O����ID
      INTO   gn_transaction_id
      FROM   xxcoi_cooperation_control xcc             -- �f�[�^�A�g���䃏�[�N�e�[�u��
      WHERE  xcc.program_id         = cn_program_id;   -- �擾�����v���O����ID
--
    EXCEPTION
      -- �O��̎��ID���擾�ł��Ȃ��ꍇ
      WHEN NO_DATA_FOUND THEN
        RAISE get_transaction_id_expt;
--
      WHEN OTHERS THEN
        RAISE;
    END;
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    WHEN get_transaction_id_expt THEN
      -- �f�[�^�A�g���䃏�[�N�e�[�u�����ID�擾�G���[���b�Z�[�W
      -- �u�O��A�g���̎��ID�擾�Ɏ��s���܂����B�v
      lv_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_short_name
                      , iv_name         => cv_msg_xxcoi_10002
                    );
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000 );
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000 );
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
  END get_transaction_id;
--
  /**********************************************************************************
   * Procedure Name   : create_csv_p
   * Description      : ���o�Ƀg����CSV�̍쐬(A-5)
   ***********************************************************************************/
  PROCEDURE create_csv_p(
     ir_material_tran_cur  IN  material_tran_cur%ROWTYPE -- ���o�Ƀf�[�^
   , ov_errbuf             OUT VARCHAR2                  -- �G���[�E���b�Z�[�W           --# �Œ� #
   , ov_retcode            OUT VARCHAR2                  -- ���^�[���E�R�[�h             --# �Œ� #
   , ov_errmsg             OUT VARCHAR2)                 -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'create_csv_p'; -- �v���O������
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
    cv_csv_com       CONSTANT VARCHAR2(1)   := ',';
--
    -- *** ���[�J���ϐ� ***
    lv_material_tran    VARCHAR2(3000);  -- CSV�o�͗p�ϐ�
    lv_process_date     VARCHAR2(14);    -- �V�X�e�����t �i�[�p�ϐ�
    lv_transaction_date VARCHAR2(14);    -- �ŏI�X�V�� �i�[�p�ϐ�
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
    -- �ϐ��̏�����
    lv_material_tran    := NULL;
    lv_process_date     := NULL;
    lv_transaction_date := NULL;
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    lv_process_date     := TO_CHAR( gd_process_date , 'YYYYMMDDHH24MISS' );                -- �A�g����
    lv_transaction_date := TO_CHAR( ir_material_tran_cur.transaction_date , 'YYYYMMDD' );  -- �����
    --
    -- ���ID�̍ő�l���擾���邽�ߕϐ��Ɋi�[
    gn_max_tran         :=  ir_material_tran_cur.transaction_id;
--
    -- =================================
    -- CSV�t�@�C���쐬
    -- =================================
    --
    -- �J�[�\���Ŏ擾�����l��CSV�t�@�C���Ɋi�[
    lv_material_tran := 
      cv_file_encloser || gv_company_code                            || cv_file_encloser || cv_csv_com || -- ��ЃR�[�h
                          ir_material_tran_cur.transaction_id                            || cv_csv_com || -- ���ID
      cv_file_encloser || ir_material_tran_cur.subinventory_code     || cv_file_encloser || cv_csv_com || -- �ۊǏꏊ�R�[�h
                          ir_material_tran_cur.transaction_type_id                       || cv_csv_com || -- ����^�C�vID
                          ir_material_tran_cur.transaction_source_type_id                || cv_csv_com || -- �\�[�X�^�C�vID
      cv_file_encloser || ir_material_tran_cur.attribute5            || cv_file_encloser || cv_csv_com || -- ����^�C�v�R�[�h(DFF5)
                          ir_material_tran_cur.primary_quantity                          || cv_csv_com || -- ����
      cv_file_encloser || ir_material_tran_cur.transaction_uom       || cv_file_encloser || cv_csv_com || -- ����P��
                          ir_material_tran_cur.transaction_quantity                      || cv_csv_com || -- �������
                          lv_transaction_date                                            || cv_csv_com || -- �����
                          ir_material_tran_cur.transaction_set_id                        || cv_csv_com || -- ����w�b�_
      cv_file_encloser || ir_material_tran_cur.transfer_subinventory || cv_file_encloser || cv_csv_com || -- �ړ���ۊǏꏊ�R�[�h
-- == 2009/04/02 V1.1 Moded START ===============================================================
--      cv_file_encloser || ir_material_tran_cur.segment1              || cv_file_encloser || cv_csv_com || -- �i�ڃR�[�h
      cv_file_encloser || ir_material_tran_cur.attribute7            || cv_file_encloser || cv_csv_com || -- ���_�R�[�h
      cv_file_encloser || ir_material_tran_cur.segment1              || cv_file_encloser || cv_csv_com || -- �i�ڃR�[�h
-- == 2009/04/02 V1.1 Moded END   ===============================================================
                          lv_process_date;                                                                -- �A�g����
--
--
    UTL_FILE.PUT_LINE(
        gv_activ_file_h     -- A-3.�Ŏ擾�����t�@�C���n���h��
      , lv_material_tran        -- �f���~�^�{��LCSV�o�͍���
      );
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
  END create_csv_p;
--
  /**********************************************************************************
   * Procedure Name   : material_tran_cur_p
   * Description      : ���ގ�����̒��o(A-4)
   ***********************************************************************************/
  PROCEDURE material_tran_cur_p(
     ov_errbuf     OUT VARCHAR2     --   �G���[�E���b�Z�[�W                  --# �Œ� #
   , ov_retcode    OUT VARCHAR2     --   ���^�[���E�R�[�h                    --# �Œ� #
   , ov_errmsg     OUT VARCHAR2)    --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'material_tran_cur_p'; -- �v���O������
--
--#######################  �Œ胍�[�J���ϐ��錾�� START   ######################
--
    lv_errbuf  VARCHAR2(5000);   -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);      -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);   -- ���[�U�[�E�G���[�E���b�Z�[�W
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
    -- ***************************************
    -- ***        ���[�v�����̋L�q         ***
    -- ***       �������̌Ăяo��          ***
    -- ***************************************
    --���o�Ƀf�[�^�擾�J�[�\���I�[�v��
    OPEN material_tran_cur;
      --
      <<material_tran_loop>>
      LOOP
        FETCH material_tran_cur INTO material_tran_rec;
        --���f�[�^���Ȃ��Ȃ�����I��
        EXIT WHEN material_tran_cur%NOTFOUND;
        --�Ώی������Z
        gn_target_cnt := gn_target_cnt + 1;
--
        -- ===============================
        -- A-5�D���o��CSV�̍쐬
        -- ===============================
        create_csv_p(
            ir_material_tran_cur  => material_tran_rec       -- ���o�Ƀf�[�^���R�[�h
          , ov_errbuf             => lv_errbuf               -- �G���[�E���b�Z�[�W           --# �Œ� #
          , ov_retcode            => lv_retcode              -- ���^�[���E�R�[�h             --# �Œ� #
          , ov_errmsg             => lv_errmsg               -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );  
--
        IF (lv_retcode = cv_status_error) THEN
          -- �G���[����
          RAISE global_process_expt;
        END IF;
--
        -- ���팏���ɉ��Z
        gn_normal_cnt := gn_normal_cnt + 1;
      --
      --���[�v�̏I��
      END LOOP material_tran_loop;
      --
    --�J�[�\���̃N���[�Y
    CLOSE material_tran_cur;
    --
    -- �f�[�^���O���ŏI�������ꍇ
    IF ( gn_target_cnt = 0 ) THEN
      -- �Ώۃf�[�^�������b�Z�[�W
      -- �u�Ώۃf�[�^�͂���܂���B�v
      gv_out_msg   := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_short_name
                      , iv_name         => cv_msg_xxcoi_00008
                      );
      -- ���b�Z�[�W�o��
      FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
        , buff   => gv_out_msg
      );
      FND_FILE.PUT_LINE(
          which  => FND_FILE.LOG
        , buff   => gv_out_msg
      );
    END IF;
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      IF material_tran_cur%ISOPEN THEN
        CLOSE material_tran_cur;
      END IF;
      --
      -- �G���[���b�Z�[�W
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      -- �J�[�\�����I�[�v�����Ă���ꍇ�̓N���[�Y����
      IF material_tran_cur%ISOPEN THEN
        CLOSE material_tran_cur;
      END IF;
      --
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      -- �J�[�\�����I�[�v�����Ă���ꍇ�̓N���[�Y����
      IF material_tran_cur%ISOPEN THEN
        CLOSE material_tran_cur;
      END IF;
      --
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      -- �J�[�\�����I�[�v�����Ă���ꍇ�̓N���[�Y����
      IF material_tran_cur%ISOPEN THEN
        CLOSE material_tran_cur;
      END IF;
      --
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END material_tran_cur_p;
--
  /**********************************************************************************
   * Procedure Name   : upd_transaction_id
   * Description      : �f�[�^�A�g���䃏�[�N�e�[�u���̎��ID�X�V(A-6)
   ***********************************************************************************/
  PROCEDURE upd_transaction_id(
      ov_errbuf     OUT VARCHAR2      --   �G���[�E���b�Z�[�W           --# �Œ� #
    , ov_retcode    OUT VARCHAR2      --   ���^�[���E�R�[�h             --# �Œ� #
    , ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_transaction_id'; -- �v���O������
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
    CURSOR get_coop_wk_cur
    IS
      SELECT 'X'
      FROM   xxcoi_cooperation_control xcc         -- �f�[�^�A�g���䃏�[�N�e�[�u��
      WHERE  xcc.program_id     = cn_program_id    -- �擾�����v���O����ID
      FOR UPDATE NOWAIT;                           -- ���b�N�擾
--
    -- *** ���[�J���E���R�[�h ***
    get_coop_wk_rec  get_coop_wk_cur%ROWTYPE;
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
    --==============================================================
    -- �f�[�^�A�g���䃏�[�N�e�[�u�����b�N�擾
    --==============================================================
    -- �J�[�\���I�[�v��
    OPEN get_coop_wk_cur;
    FETCH get_coop_wk_cur INTO get_coop_wk_rec;
--
    -- ==============================================================
    -- �f�[�^�A�g���䃏�[�N�e�[�u���X�V����
    -- ==============================================================
    UPDATE   xxcoi_cooperation_control    xcc
    SET      xcc.last_cooperation_date  = gd_process_date            -- �ŏI�A�g����
           , xcc.transaction_id         = gn_max_tran                -- A-5.�Ŏ擾�������ID�̍ő�l
           , xcc.last_update_date       = cd_last_update_date        -- �ŏI�X�V��
           , xcc.last_updated_by        = cn_last_updated_by         -- �ŏI�X�V��
           , xcc.last_update_login      = cn_last_update_login       -- �ŏI�X�V�҃��O�C��
           , xcc.request_id             = cn_request_id              -- �v��ID
           , xcc.program_application_id = cn_program_application_id  -- �A�v���P�[�V����ID
           , xcc.program_id             = cn_program_id              -- �v���O����ID
           , xcc.program_update_date    = cd_program_update_date     -- �v���O�����X�V����
    WHERE    xcc.program_id             = cn_program_id;             -- �v���O����ID
--
    -- �J�[�\���N���[�Y
    CLOSE get_coop_wk_cur;
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
    -- ���b�N�擾�G���[
    WHEN lock_expt THEN
      -- �J�[�\�����I�[�v�����Ă���ꍇ�̓N���[�Y
      IF get_coop_wk_cur%ISOPEN THEN
        CLOSE get_coop_wk_cur;
      END IF;
      --
      -- �Ώی������O�ɃZ�b�g
      gn_target_cnt := 0;
      --
      -- ���b�N�G���[���b�Z�[�W(�f�[�^�A�g���䃏�[�N�e�[�u��)
      -- �u�f�[�^�A�g���䃏�[�N�e�[�u���̃��b�N�Ɏ��s���܂����B
      --   ���Ԃ������Ă���A�ēx�����������{���ĉ������B
      --   �i�v���O����ID�� PROGRAM_ID �j�v
      lv_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_short_name
                      , iv_name         => cv_msg_xxcoi_10001
                      , iv_token_name1  => cv_tkn_program_id
                      , iv_token_value1 => cn_program_id
                    );
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000 );
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      -- �J�[�\�����I�[�v�����Ă���ꍇ�̓N���[�Y
      IF get_coop_wk_cur%ISOPEN THEN
        CLOSE get_coop_wk_cur;
      END IF;
      --
      -- �Ώی������O�ɃZ�b�g
      gn_target_cnt := 0;
      --
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      -- �J�[�\�����I�[�v�����Ă���ꍇ�̓N���[�Y
      IF get_coop_wk_cur%ISOPEN THEN
        CLOSE get_coop_wk_cur;
      END IF;
      --
      -- �Ώی������O�ɃZ�b�g
      gn_target_cnt := 0;
      --
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      -- �J�[�\�����I�[�v�����Ă���ꍇ�̓N���[�Y
      IF get_coop_wk_cur%ISOPEN THEN
        CLOSE get_coop_wk_cur;
      END IF;
      --
      -- �Ώی������O�ɃZ�b�g
      gn_target_cnt := 0;
      --
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END upd_transaction_id;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
     ov_errbuf     OUT VARCHAR2    --   �G���[�E���b�Z�[�W           --# �Œ� #
   , ov_retcode    OUT VARCHAR2    --   ���^�[���E�R�[�h             --# �Œ� #
   , ov_errmsg     OUT VARCHAR2)   --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
--
--#####################  �Œ胍�[�J���萔�ϐ��錾�� START   ####################
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name       CONSTANT VARCHAR2(100)  := 'submain'; -- �v���O������
    cn_max_linesize   CONSTANT BINARY_INTEGER := 32767;
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf       VARCHAR2(5000);                -- �G���[�E���b�Z�[�W
    lv_retcode      VARCHAR2(1);                   -- ���^�[���E�R�[�h
    lv_errmsg       VARCHAR2(5000);                -- ���[�U�[�E�G���[�E���b�Z�[�W
    --
    -- �t�@�C���̑��݃`�F�b�N�p�ϐ�
    lb_exists       BOOLEAN         DEFAULT NULL;  -- �t�@�C�����ݔ���p�ϐ�
    ln_file_length  NUMBER          DEFAULT NULL;  -- �t�@�C���̒���
    ln_block_size   BINARY_INTEGER  DEFAULT NULL;  -- �u���b�N�T�C�Y
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
    -- *** ���[�J����O ***
    remain_file_expt           EXCEPTION;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ===============================
    -- ����������
    -- ===============================
    -- �O���[�o���ϐ��̏�����
    gn_target_cnt    := 0;
    gn_normal_cnt    := 0;
    gn_error_cnt     := 0;
    gv_activ_file_h  := NULL;            -- �t�@�C���n���h��
--
    --*********************************************
    --***      MD.050�̃t���[�}��\��           ***
    --***      ����Ə������̌Ăяo�����s��     ***
    --*********************************************
--
    -- ========================================
    --  A-1. ��������
    -- ========================================
    init(
        ov_errbuf    => lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
      , ov_retcode   => lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
      , ov_errmsg    => lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    --
    -- �I���p�����[�^����
    IF (lv_retcode = cv_status_error) THEN
      -- �G���[����
      RAISE global_process_expt;
    END IF;
--
    -- ====================================================
    -- A-2�D�f�[�^�A�g���䃏�[�N�e�[�u���̑O����ID�擾
    -- ====================================================
    get_transaction_id(
        ov_errbuf    => lv_errbuf      -- �G���[�E���b�Z�[�W           --# �Œ� #
      , ov_retcode   => lv_retcode     -- ���^�[���E�R�[�h             --# �Œ� #
      , ov_errmsg    => lv_errmsg      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    -- �I���p�����[�^����
    IF ( lv_retcode = cv_status_error ) THEN
      -- �G���[����
      RAISE global_process_expt;
    END IF;
--
    -- ========================================
    -- A-3�D�t�@�C���I�[�v������
    -- ========================================
    -- �t�@�C���̑��݃`�F�b�N
    UTL_FILE.FGETATTR( 
        location     =>  gv_dire_pass
      , filename     =>  gv_file_stock_delivery
      , fexists      =>  lb_exists
      , file_length  =>  ln_file_length
      , block_size   =>  ln_block_size
    );
--
    -- ����t�@�C�������݂����ꍇ�̓G���[
    IF( lb_exists = TRUE ) THEN
      RAISE remain_file_expt;
--
    ELSE
      -- �t�@�C���I�[�v���������s
      gv_activ_file_h := UTL_FILE.FOPEN(
                            location     => gv_dire_pass           -- �f�B���N�g���p�X
                          , filename     => gv_file_stock_delivery -- �t�@�C����
                          , open_mode    => cv_file_mode           -- �I�[�v�����[�h
                          , max_linesize => cn_max_linesize        -- �t�@�C���T�C�Y
                         );
    END IF;
    --
    -- ========================================
    -- A-4�D���o�ɏ��̒��o
    -- ========================================
    -- A-4�̏���������A-5������
    material_tran_cur_p(
        ov_errbuf    => lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
      , ov_retcode   => lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
      , ov_errmsg    => lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    --
    -- �I���p�����[�^����
    IF (lv_retcode = cv_status_error) THEN
      -- �G���[����
      RAISE global_process_expt;
    END IF;
--
    -- �Ώی�����1���ȏ�̏ꍇ
    IF ( gn_target_cnt > 0 ) THEN
--
      -- ==============================================================
      -- A-6.�f�[�^�A�g���䃏�[�N�e�[�u���̎��ID�X�V
      -- ==============================================================
      upd_transaction_id(
          ov_errbuf  => lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
        , ov_retcode => lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
        , ov_errmsg  => lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
--
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
--
    END IF;
--
    -- ===============================
    -- A-7�D�t�@�C���̃N���[�Y����
    -- ===============================
    UTL_FILE.FCLOSE(
      file => gv_activ_file_h
      );
--
  EXCEPTION
    -- �J�[�\���̃N���[�Y�������ɋL�q����
    -- *** �t�@�C�����݃`�F�b�N�G���[ ***
    -- �u�t�@�C���u FILE_NAME �v�͂��łɑ��݂��܂��B�v
    WHEN remain_file_expt THEN
      lv_errmsg    := xxccp_common_pkg.get_msg(
                          iv_application  => cv_appl_short_name
                        , iv_name         => cv_msg_xxcoi_00027
                        , iv_token_name1  => cv_tkn_file_name
                        , iv_token_value1 => gv_file_stock_delivery
                      );
      lv_errbuf    := lv_errmsg;
      --
      ov_errmsg    := lv_errmsg;
      ov_errbuf    := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode   := cv_status_error;
    -- *** ���ʊ֐���O�n���h�� ***
--
--#################################  �Œ��O������ START   ###################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      -- CSV�t�@�C�����I�[�v�����Ă���΃N���[�Y����
      IF( UTL_FILE.IS_OPEN( gv_activ_file_h ) ) THEN
        UTL_FILE.FCLOSE(
          file => gv_activ_file_h
          );
      END IF;
      --
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      -- CSV�t�@�C�����I�[�v�����Ă���΃N���[�Y����
      IF( UTL_FILE.IS_OPEN( gv_activ_file_h ) ) THEN
        UTL_FILE.FCLOSE(
          file => gv_activ_file_h
          );
      END IF;
      --
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    --
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      -- CSV�t�@�C�����I�[�v�����Ă���΃N���[�Y����
      IF( UTL_FILE.IS_OPEN( gv_activ_file_h ) ) THEN
        UTL_FILE.FCLOSE(
          file => gv_activ_file_h
          );
      END IF;
      --
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
    cv_appl_short_name CONSTANT VARCHAR2(10)  := 'XXCCP';            -- �A�h�I���F���ʁEIF�̈�
    cv_target_rec_msg  CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90000'; -- �Ώی������b�Z�[�W
    cv_success_rec_msg CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90001'; -- �����������b�Z�[�W
    cv_error_rec_msg   CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90002'; -- �G���[�������b�Z�[�W
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
        ov_retcode => lv_retcode
      , ov_errbuf  => lv_errbuf
      , ov_errmsg  => lv_errmsg
    );
    --
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_api_others_expt;
    END IF;
    --
--###########################  �Œ蕔 END   #############################
--
    -- ===============================
    -- �ϐ��̏�����
    -- ===============================
    lv_errbuf    := NULL;   -- �G���[�E���b�Z�[�W
    lv_retcode   := NULL;   -- ���^�[���E�R�[�h
    lv_errmsg    := NULL;   -- ���[�U�[�E�G���[�E���b�Z�[�W
    --
    -- ===============================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ===============================================
    submain(
        ov_retcode => lv_retcode  -- �G���[�E���b�Z�[�W           --# �Œ� #
      , ov_errbuf  => lv_errbuf   -- ���^�[���E�R�[�h             --# �Œ� #
      , ov_errmsg  => lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    --�G���[�o��
    IF (lv_retcode = cv_status_error) THEN
      FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
        , buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
      );
      FND_FILE.PUT_LINE(
          which  => FND_FILE.LOG
        , buff   => lv_errbuf --�G���[���b�Z�[�W
      );
    END IF;
    --
    --
    --==============================================================
    -- A-6�D�����\������
    --==============================================================
    -- �G���[���͐��������o�͂��O�ɃZ�b�g
    --           �G���[�����o�͂��P�ɃZ�b�g
    IF( lv_retcode = cv_status_error ) THEN
      gn_normal_cnt := 0;
      gn_error_cnt  := 1;
    END IF;
    --
    --
    --��s�}��
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => ''
    );
    --
    --�Ώی����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name_ccp
                    , iv_name         => cv_target_rec_msg
                    , iv_token_name1  => cv_cnt_token
                    , iv_token_value1 => TO_CHAR(gn_target_cnt)
                   );
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => gv_out_msg
    );
    --
    --���������o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name_ccp
                    , iv_name         => cv_success_rec_msg
                    , iv_token_name1  => cv_cnt_token
                    , iv_token_value1 => TO_CHAR(gn_normal_cnt)
                   );
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => gv_out_msg
    );
    --
    --�G���[�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name_ccp
                    , iv_name         => cv_error_rec_msg
                    , iv_token_name1  => cv_cnt_token
                    , iv_token_value1 => TO_CHAR(gn_error_cnt)
                   );
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => gv_out_msg
    );
    --
    --��s�}��
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => ''
    );
    --
    --�I�����b�Z�[�W
    IF (lv_retcode = cv_status_normal) THEN
      -- ����I�����b�Z�[�W
      -- �u����������I�����܂����B�v
      lv_message_code := cv_normal_msg;
    --
    ELSIF(lv_retcode = cv_status_error) THEN
      -- �G���[�I���S���[���o�b�N���b�Z�[�W
      -- �u�������G���[�I�����܂����B�f�[�^�͑S�������O�̏�Ԃɖ߂��܂����B�v
      lv_message_code := cv_error_msg;
    END IF;
    --
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name_ccp
                    , iv_name         => lv_message_code
                   );
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => gv_out_msg
    );
    --�X�e�[�^�X�Z�b�g
    retcode := lv_retcode;
    --�I���X�e�[�^�X���G���[�̏ꍇ��ROLLBACK����
    IF (retcode = cv_status_error) THEN
      --
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
END XXCOI008A02C;
/
