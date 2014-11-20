CREATE OR REPLACE PACKAGE BODY XXCOS003A03C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOS003A03C(body)
 * Description      : �x���_�[�i���я��쐬
 * MD.050           : �x���_�[�i���я��쐬 MD050_COS_003_A03
 * Version          : 1.1
 *
 * Program List     
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                      A-1�D��������
 *  proc_vd_deli_h_dataset    A-4�D�x���_�[�i���я��w�b�_�e�[�u���f�[�^�ݒ�
 *  proc_inv_item_select      A-6�D�i�ڃ}�X�^�f�[�^���o
 *  proc_vd_deli_l_dataset    A-7�D�x���_�[�i���я�񖾍׃e�[�u���f�[�^�ݒ�
 *  proc_status_update        A-8�DVD�R�����ʎ���w�b�_�e�[�u�����R�[�h���b�N
 *                            A-9�DVD�R�����ʎ���w�b�_�e�[�u���X�e�[�^�X�X�V
 *  proc_main_loop            A-2�DVD�R�����ʎ���w�b�_�e�[�u���f�[�^���o
 *  submain                   ���C�������v���V�[�W��
 *  main                      �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009/01/05   1.0    K.Okaguchi       �V�K�쐬
 *  2009/02/24   1.1    T.Nakamura       [��QCOS_130] ���b�Z�[�W�o�́A���O�o�͂ւ̏o�͓��e�̒ǉ��E�C��
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
  gv_out_msg       VARCHAR2(2000);
  gv_sep_msg       VARCHAR2(2000);
  gv_exec_user     VARCHAR2(100);
  gv_conc_name     VARCHAR2(30);
  gv_conc_status   VARCHAR2(30);
  gn_target_cnt    NUMBER DEFAULT 0;                    -- �Ώی���
  gn_normal_cnt    NUMBER DEFAULT 0;                    -- ���팏��
  gn_error_cnt     NUMBER DEFAULT 0;                    -- �G���[����
  gn_warn_cnt      NUMBER DEFAULT 0;                    -- �X�L�b�v����
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
  global_data_check_expt    EXCEPTION;     -- �f�[�^�`�F�b�N���̃G���[
  update_error_expt         EXCEPTION;
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name             CONSTANT VARCHAR2(100):= 'XXCOS003A03C'; -- �p�b�P�[�W��
  cv_application          CONSTANT VARCHAR2(5)  := 'XXCOS';        -- �A�v���P�[�V������(�̔�)
  cv_application_coi      CONSTANT VARCHAR2(5)  := 'XXCOI';        -- �A�v���P�[�V������(�݌�)
  cv_appl_short_name      CONSTANT VARCHAR2(10) := 'XXCCP';        -- �A�h�I���F���ʁEIF�̈�
  cv_tkn_table_name       CONSTANT VARCHAR2(20) := 'TABLE_NAME';
  cv_tkn_key_data         CONSTANT VARCHAR2(20) := 'KEY_DATA';
  cv_flag_off             CONSTANT VARCHAR2(1)  := 'N';
  cv_flag_on              CONSTANT VARCHAR2(1)  := 'Y';
  cv_tkn_lock             CONSTANT VARCHAR2(20) := 'TABLE';               -- ���b�N�G���[
  cn_lock_error_code      CONSTANT NUMBER       := -54;
  cv_msg_lock             CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00001';    -- ���b�N�擾�G���[
  cv_msg_pro              CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00004';    -- �v���t�@�C���擾�G���[
  cv_msg_organization_id  CONSTANT VARCHAR2(20) := 'APP-XXCOI1-00006';    -- �݌ɑg�DID�擾�G���[
  cv_msg_insert_err       CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00010';    -- �f�[�^�o�^�G���[���b�Z�[�W
  cv_msg_update_err       CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00011';    -- �f�[�^�X�V�G���[���b�Z�[�W
  cv_msg_select_err       CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00013';    -- �f�[�^���o�G���[���b�Z�[�W
  cv_no_parameter         CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90008';    -- �p�����[�^�Ȃ�
  
  cv_tkn_cust_code        CONSTANT VARCHAR2(20) := 'APP-XXCOS1-10853';    -- �ڋq�R�[�h
  cv_tkn_item_code        CONSTANT VARCHAR2(20) := 'APP-XXCOS1-10854';    -- �i���R�[�h
  cv_tkn_organization_cd  CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00048';    -- XXCOI:�݌ɑg�D�R�[�h
  cv_tkn_vd_deliv_h       CONSTANT VARCHAR2(20) := 'APP-XXCOS1-10751';    -- �x���_�[�i���я��w�b�_�e�[�u��
  cv_tkn_dlv_date         CONSTANT VARCHAR2(20) := 'APP-XXCOS1-10752';    -- �[�i��
  cv_tkn_item_id          CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00139';    -- �i��ID
  cv_tkn_inventory_id     CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00063';    -- �݌ɑg�DID
  cv_tkn_system_item      CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00050';    -- �i�ڃ}�X�^
  cv_tkn_vd_deliv_l       CONSTANT VARCHAR2(20) := 'APP-XXCOS1-10753';    -- �x���_�[�i���я�񖾍׃e�[�u��
  cv_tkn_column_no        CONSTANT VARCHAR2(20) := 'APP-XXCOS1-10754';    -- �R����No
  cv_tkn_vd_column_l      CONSTANT VARCHAR2(20) := 'APP-XXCOS1-10755';    -- VD�R�����ʎ���w�b�_�e�[�u��
  cv_tkn_order_no_hht     CONSTANT VARCHAR2(20) := 'APP-XXCOS1-10756';    -- ��No.�iHHT)
  cv_tkn_digestion_ln_no  CONSTANT VARCHAR2(20) := 'APP-XXCOS1-10757';    -- �}��
  cv_tkn_sub_main_cur     CONSTANT VARCHAR2(20) := 'APP-XXCOS1-10758';    --�ڋq�}�X�^����сAVD�R�����}�X�^

  cv_tkn_profile          CONSTANT VARCHAR2(20) := 'PROFILE';             -- �v���t�@�C����
  cv_tkn_org_code_tok     CONSTANT VARCHAR2(20) := 'ORG_CODE_TOK';        -- �݌ɑg�D�R�[�h

  cv_lookup_type_gyotai   CONSTANT VARCHAR2(30) := 'XXCOS1_GYOTAI_SHO_MST_003_A03'; -- �Q�ƃ^�C�v�@�Ƒԏ�����
  cv_organization_code    CONSTANT VARCHAR2(30) := 'XXCOI1_ORGANIZATION_CODE';      -- �݌ɑg�D�R�[�h
  
  cv_blank_column_code    CONSTANT VARCHAR2(7)  := 'BLANK_C'; 
   --�u�����N�R�����p�_�~�[�i�ځi�x���_�[�i���я������݂̂Ŏg�p����B�g�g�s�t�@�C���ɂ͏o�͂���Ȃ��j
   
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gv_key_info                 fnd_new_messages.message_text%TYPE   ; --���b�Z�[�W�o�͗p�L�[���
  gv_msg_tkn_cust_code        fnd_new_messages.message_text%TYPE   ; --�ڋq�R�[�h
  gv_msg_tkn_item_code        fnd_new_messages.message_text%TYPE   ; --�i���R�[�h
  gv_msg_tkn_organization_cd  fnd_new_messages.message_text%TYPE   ; --�݌ɑg�D�R�[�h
  gv_msg_tkn_vd_deliv_h       fnd_new_messages.message_text%TYPE   ; --�x���_�[�i���я��w�b�_�e�[�u��
  gv_msg_tkn_dlv_date         fnd_new_messages.message_text%TYPE   ; --�[�i��
  gv_msg_tkn_item_id          fnd_new_messages.message_text%TYPE   ; --�i��ID
  gv_msg_tkn_inventory_id     fnd_new_messages.message_text%TYPE   ; --�݌ɑg�DID
  gv_msg_tkn_system_item      fnd_new_messages.message_text%TYPE   ; --�i�ڃ}�X�^
  gv_msg_tkn_vd_deliv_l       fnd_new_messages.message_text%TYPE   ; --�x���_�[�i���я�񖾍׃e�[�u��
  gv_msg_tkn_column_no        fnd_new_messages.message_text%TYPE   ; --�R����No
  gv_msg_tkn_vd_column_h      fnd_new_messages.message_text%TYPE   ; --VD�R�����ʎ���w�b�_�e�[�u��
  gv_msg_tkn_order_no_hht     fnd_new_messages.message_text%TYPE   ; --��No.�iHHT)
  gv_msg_tkn_digestion_ln_no  fnd_new_messages.message_text%TYPE   ; --�}��
  gv_msg_tkn_sub_main_cur     fnd_new_messages.message_text%TYPE   ; --�ڋq�}�X�^����сAVD�R�����}�X�^
  
  gv_bf_customer_number       xxcos_vd_column_headers.customer_number%TYPE   ;
  
  gv_customer_number          xxcos_unit_price_mst_work.customer_number%TYPE;
  gv_tkn_lock_table           fnd_new_messages.message_text%TYPE   ;

  gv_organization_code        mtl_parameters.organization_code%TYPE; --�݌ɑg�D�R�[�h
  gv_organization_id          mtl_parameters.organization_id%TYPE;   --�݌ɑg�DID


  gv_search_item_code         mtl_system_items_b.segment1%TYPE;      --�����p�@�i�ڃR�[�h
  
  gn_warn_tran_count          NUMBER DEFAULT 0;
  gn_tran_count               NUMBER DEFAULT 0;
  gn_unit_price               NUMBER;
  gn_skip_cnt                 NUMBER DEFAULT 0;                      -- �P���}�X�^�X�V�ΏۊO����
  gn_main_loop_cnt            NUMBER DEFAULT 0;
  gn_sub_main_count           NUMBER;
--
--�J�[�\��
  CURSOR main_cur
  IS
    SELECT xvch.customer_number     customer_number       --�ڋq�R�[�h
          ,xvch.dlv_date            dlv_date              --�[�i��
          ,xvch.dlv_time            dlv_time              --����
          ,xvch.total_amount        total_amount          --���v���z
          ,xvch.order_no_hht        order_no_hht          --��No.�iHHT�j
          ,xvch.digestion_ln_number digestion_ln_number   --�}��
          ,xvch.base_code           base_code             --���_�R�[�h
    FROM   xxcos_vd_column_headers xvch
          ,fnd_lookup_values       flvl
    WHERE  xvch.vd_results_forward_flag = cv_flag_off
    AND    xvch.system_class            = flvl.meaning
    AND    flvl.lookup_type             = cv_lookup_type_gyotai
    AND    flvl.security_group_id       = FND_GLOBAL.LOOKUP_SECURITY_GROUP(flvl.lookup_type,flvl.view_application_id)
    AND    flvl.language                = USERENV('LANG')
    AND    TRUNC(SYSDATE)               BETWEEN flvl.start_date_active
                                          AND NVL(flvl.end_date_active, TRUNC(SYSDATE))
    AND    flvl.enabled_flag            = cv_flag_on
    ORDER BY xvch.customer_number
    ;
    
  main_rec main_cur%ROWTYPE;

  CURSOR sub_main_cur
  IS
    SELECT xmvc.column_no            column_no           --VD�R�����}�X�^	�R����No
          ,xvcl.item_code_self       item_code_self      --VD�R�����ʎ�����׃e�[�u��	�i���R�[�h�i���Ёj
          ,xmvc.item_id              item_id             --VD�R�����}�X�^	�i��ID
          ,xvcl.replenish_number     replenish_number    --VD�R�����ʎ�����׃e�[�u��	��[��
          ,xmvc.inventory_quantity   inventory_quantity  --VD�R�����}�X�^	��݌ɐ�
          ,xvcl.h_and_c              h_and_c             --VD�R�����ʎ�����׃e�[�u��	H/C
          ,xmvc.hot_cold             hot_cold            --VD�R�����}�X�^	H/C
    FROM   xxcoi_mst_vd_column   xmvc
          ,xxcos_vd_column_lines xvcl
          ,hz_cust_accounts      hzca
    WHERE  hzca.account_number          = main_rec.customer_number
    AND    hzca.cust_account_id         = xmvc.customer_id
    AND    xmvc.column_no               = xvcl.column_no(+)
    AND    main_rec.order_no_hht        = xvcl.order_no_hht(+)
    AND    main_rec.digestion_ln_number = xvcl.digestion_ln_number(+)
    ;
  sub_main_rec sub_main_cur%ROWTYPE;
  
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
    
    TYPE g_rec_key_rtype IS RECORD
    (
      order_no_hht         main_rec.order_no_hht%TYPE,        -- ��No.�iHHT)
      digestion_ln_number  main_rec.digestion_ln_number%TYPE  -- �}��
    );
    
    TYPE g_tab_key_ttype IS TABLE OF g_rec_key_rtype INDEX BY PLS_INTEGER;

    gt_key         g_tab_key_ttype; 

--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    ov_errbuf     OUT NOCOPY VARCHAR2 ,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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

-- 2009/02/24 T.Nakamura Ver.1.1 add start
    --��s
    FND_FILE.PUT_LINE(which  => FND_FILE.OUTPUT
                     ,buff   => ''
                     );
-- 2009/02/24 T.Nakamura Ver.1.1 add end
    --==============================================================
    -- �u�R���J�����g���̓p�����[�^�Ȃ��v���b�Z�[�W���o��
    --==============================================================
    gv_out_msg := xxccp_common_pkg.get_msg(iv_application  => cv_appl_short_name
                                          ,iv_name         => cv_no_parameter
                                          );
    FND_FILE.PUT_LINE(
                      which  => FND_FILE.OUTPUT
                     ,buff   => gv_out_msg
                     );
-- 2009/02/24 T.Nakamura Ver.1.1 add start
    FND_FILE.PUT_LINE(
                      which  => FND_FILE.LOG
                     ,buff   => gv_out_msg
                     );
-- 2009/02/24 T.Nakamura Ver.1.1 add end
    --��s
    FND_FILE.PUT_LINE(
                      which  => FND_FILE.OUTPUT
                     ,buff   => ''
                     );
-- 2009/02/24 T.Nakamura Ver.1.1 add start
    FND_FILE.PUT_LINE(
                      which  => FND_FILE.LOG
                     ,buff   => ''
                     );
-- 2009/02/24 T.Nakamura Ver.1.1 add end
    --==============================================================
    -- �}���`�o�C�g�̌Œ�l�����b�Z�[�W���擾
    --==============================================================
    gv_msg_tkn_cust_code        := xxccp_common_pkg.get_msg(iv_application  => cv_application
                                                           ,iv_name         => cv_tkn_cust_code
                                                           );
    gv_msg_tkn_item_code        := xxccp_common_pkg.get_msg(iv_application  => cv_application
                                                           ,iv_name         => cv_tkn_item_code
                                                           );
    gv_msg_tkn_organization_cd  := xxccp_common_pkg.get_msg(iv_application  => cv_appl_short_name
                                                           ,iv_name         => cv_tkn_organization_cd
                                                           );
    gv_msg_tkn_vd_deliv_h      := xxccp_common_pkg.get_msg(iv_application  => cv_application
                                                           ,iv_name         => cv_tkn_vd_deliv_h
                                                           );
    gv_msg_tkn_dlv_date        := xxccp_common_pkg.get_msg(iv_application  => cv_application
                                                           ,iv_name         => cv_tkn_dlv_date
                                                           );
    gv_msg_tkn_item_id         := xxccp_common_pkg.get_msg(iv_application  => cv_application
                                                           ,iv_name         => cv_tkn_item_id
                                                           );
    gv_msg_tkn_inventory_id    := xxccp_common_pkg.get_msg(iv_application  => cv_application
                                                           ,iv_name         => cv_tkn_inventory_id
                                                           );
    gv_msg_tkn_system_item     := xxccp_common_pkg.get_msg(iv_application  => cv_application
                                                           ,iv_name         => cv_tkn_system_item
                                                           );
    gv_msg_tkn_vd_deliv_l      := xxccp_common_pkg.get_msg(iv_application  => cv_application
                                                           ,iv_name         => cv_tkn_vd_deliv_l
                                                           );
    gv_msg_tkn_column_no       := xxccp_common_pkg.get_msg(iv_application  => cv_application
                                                           ,iv_name         => cv_tkn_column_no
                                                           );
    gv_msg_tkn_vd_column_h     := xxccp_common_pkg.get_msg(iv_application  => cv_application
                                                           ,iv_name         => cv_tkn_vd_column_l
                                                           );
    gv_msg_tkn_order_no_hht    := xxccp_common_pkg.get_msg(iv_application  => cv_application
                                                           ,iv_name         => cv_tkn_order_no_hht
                                                           );
    gv_msg_tkn_digestion_ln_no := xxccp_common_pkg.get_msg(iv_application  => cv_application
                                                           ,iv_name         => cv_tkn_digestion_ln_no
                                                           );
    gv_msg_tkn_sub_main_cur := xxccp_common_pkg.get_msg(iv_application  => cv_application
                                                           ,iv_name         => cv_tkn_sub_main_cur
                                                           );                                                           
    --==============================================================
    -- �v���t�@�C���̎擾(�݌ɑg�D�R�[�h)
    --==============================================================
    gv_organization_code := FND_PROFILE.VALUE(cv_organization_code);
--
    -- �v���t�@�C���擾�G���[�̏ꍇ
    IF (gv_organization_code IS NULL) THEN
      ov_errmsg := xxccp_common_pkg.get_msg(cv_application
                                          , cv_msg_pro
                                          , cv_tkn_profile
                                          , gv_msg_tkn_organization_cd);
      RAISE global_api_others_expt;
    END IF;

    --==============================================================
    -- �݌ɑg�D�R�[�h���݌ɑg�DID�𓱏o
    --==============================================================
    gv_organization_id := xxcoi_common_pkg.get_organization_id(gv_organization_code);
--
    -- �݌ɑg�DID�擾�G���[�̏ꍇ
    IF (gv_organization_id IS NULL) THEN
      ov_errmsg := xxccp_common_pkg.get_msg(cv_application_coi
                                          , cv_msg_organization_id
                                          , cv_tkn_org_code_tok
                                          , gv_organization_code);
      RAISE global_api_others_expt;
    END IF;
                                                         
--
--
  EXCEPTION
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg;
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
--
  /**********************************************************************************
   * Procedure Name   : proc_vd_deli_h_dataset
   * Description      : A-4�D�x���_�[�i���я��w�b�_�e�[�u���f�[�^�ݒ�
   ***********************************************************************************/
  PROCEDURE proc_vd_deli_h_dataset(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_vd_deli_h_dataset'; -- �v���O������
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
    lv_visit_time     xxcos_vd_deliv_headers.visit_time%TYPE;
    lv_set_visit_time xxcos_vd_deliv_headers.visit_time%TYPE;
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
    BEGIN
      SELECT  visit_time
      INTO    lv_visit_time
      FROM    xxcos_vd_deliv_headers xvdh
      WHERE   xvdh.customer_number = main_rec.customer_number
      AND     xvdh.dlv_date        = main_rec.dlv_date       
      FOR UPDATE NOWAIT
      ;
      
      -- ===============================
      --�x���_�[�i���я��w�b�_�e�[�u���X�V
      -- ===============================
      --�K�⎞������
      IF lv_visit_time > main_rec.dlv_time THEN
        lv_set_visit_time := lv_visit_time;
      ELSE
        lv_set_visit_time := main_rec.dlv_time;
      END IF;
    
      BEGIN
        UPDATE xxcos_vd_deliv_headers
        SET    visit_time                 = lv_set_visit_time                    --�K�⎞��
              ,total_amount               = total_amount + main_rec.total_amount --���v���z
              ,last_updated_by            = cn_last_updated_by       
              ,last_update_date           = cd_last_update_date      
              ,last_update_login          = cn_last_update_login     
              ,request_id                 = cn_request_id            
              ,program_application_id     = cn_program_application_id
              ,program_id                 = cn_program_id            
              ,program_update_date        = cd_program_update_date   
        WHERE  customer_number = main_rec.customer_number
        AND    dlv_date        = main_rec.dlv_date       
        ;
      EXCEPTION
        WHEN OTHERS THEN
          ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
          
          xxcos_common_pkg.makeup_key_info(ov_errbuf      => lv_errbuf                  --�G���[�E���b�Z�[�W
                                          ,ov_retcode     => lv_retcode                 --���^�[���E�R�[�h
                                          ,ov_errmsg      => lv_errmsg                  --���[�U�[�E�G���[�E���b�Z�[�W
                                          ,ov_key_info    => gv_key_info                --�L�[���
                                          ,iv_item_name1  => gv_msg_tkn_cust_code       --���ږ���1
                                          ,iv_data_value1 => main_rec.customer_number   --�f�[�^�̒l1
                                          ,iv_item_name2  => gv_msg_tkn_dlv_date        --���ږ���2
                                          ,iv_data_value2 => main_rec.dlv_date          --�f�[�^�̒l2
                                          );
          
          ov_errmsg := xxccp_common_pkg.get_msg(cv_application
                                              , cv_msg_update_err
                                              , cv_tkn_table_name
                                              , gv_msg_tkn_vd_deliv_h
                                              , cv_tkn_key_data
                                              , gv_key_info
                                              );
          FND_FILE.PUT_LINE(
                            which  => FND_FILE.LOG
                           ,buff   => ov_errbuf --�G���[���b�Z�[�W
                           );
          FND_FILE.PUT_LINE(
                            which  => FND_FILE.OUTPUT
                           ,buff   => ov_errmsg --�G���[���b�Z�[�W
                           );
          ov_retcode := cv_status_error;
          RAISE update_error_expt;

      END;
      
    EXCEPTION
      WHEN NO_DATA_FOUND THEN

    -- ===============================
    --�x���_�[�i���я��w�b�_�e�[�u���o�^
    -- ===============================
        BEGIN
          INSERT INTO xxcos_vd_deliv_headers(
             customer_number          --�ڋq�R�[�h
            ,dlv_date                 --�[�i��
            ,visit_time               --�K�⎞��
            ,total_amount             --���v���z
            ,base_code                --���_�R�[�h
            ,created_by
            ,creation_date
            ,last_updated_by
            ,last_update_date
            ,last_update_login
            ,request_id
            ,program_application_id
            ,program_id
            ,program_update_date
          )VALUES(
             main_rec.customer_number --�ڋq�R�[�h
            ,main_rec.dlv_date        --�[�i��
            ,main_rec.dlv_time        --�K�⎞��
            ,main_rec.total_amount    --���v���z
            ,main_rec.base_code       --���_�R�[�h
            ,cn_created_by
            ,cd_creation_date
            ,cn_last_updated_by
            ,cd_last_update_date
            ,cn_last_update_login
            ,cn_request_id
            ,cn_program_application_id
            ,cn_program_id
            ,cd_program_update_date
           );
        EXCEPTION
          WHEN OTHERS THEN
            ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
            
            xxcos_common_pkg.makeup_key_info(ov_errbuf      => lv_errbuf                  --�G���[�E���b�Z�[�W
                                            ,ov_retcode     => lv_retcode                 --���^�[���E�R�[�h
                                            ,ov_errmsg      => lv_errmsg                  --���[�U�[�E�G���[�E���b�Z�[�W
                                            ,ov_key_info    => gv_key_info                --�L�[���
                                            ,iv_item_name1  => gv_msg_tkn_cust_code       --���ږ���1
                                            ,iv_data_value1 => main_rec.customer_number   --�f�[�^�̒l1
                                            ,iv_item_name2  => gv_msg_tkn_dlv_date        --���ږ���2
                                            ,iv_data_value2 => main_rec.dlv_date          --�f�[�^�̒l2
                                            );
            
            ov_errmsg := xxccp_common_pkg.get_msg(cv_application
                                                , cv_msg_insert_err
                                                , cv_tkn_table_name
                                                , gv_msg_tkn_vd_deliv_h
                                                , cv_tkn_key_data
                                                , gv_key_info
                                                );
            FND_FILE.PUT_LINE(
                              which  => FND_FILE.LOG
                             ,buff   => ov_errbuf --�G���[���b�Z�[�W
                             );
            FND_FILE.PUT_LINE(
                              which  => FND_FILE.OUTPUT
                             ,buff   => ov_errmsg --�G���[���b�Z�[�W
                             );
            ov_retcode := cv_status_error;
            RAISE global_api_others_expt;
        END;
      WHEN update_error_expt THEN
        RAISE global_api_others_expt;
      WHEN OTHERS THEN
        ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
        IF (SQLCODE = cn_lock_error_code) THEN
          ov_errmsg := xxccp_common_pkg.get_msg(cv_application
                                              , cv_msg_lock
                                              , cv_tkn_lock
                                              , gv_msg_tkn_vd_deliv_h
                                               );
        ELSE
          xxcos_common_pkg.makeup_key_info(ov_errbuf      => lv_errbuf                  --�G���[�E���b�Z�[�W
                                          ,ov_retcode     => lv_retcode                 --���^�[���E�R�[�h
                                          ,ov_errmsg      => lv_errmsg                  --���[�U�[�E�G���[�E���b�Z�[�W
                                          ,ov_key_info    => gv_key_info                --�L�[���
                                          ,iv_item_name1  => gv_msg_tkn_cust_code       --���ږ���1
                                          ,iv_data_value1 => main_rec.customer_number   --�f�[�^�̒l1
                                          ,iv_item_name2  => gv_msg_tkn_dlv_date        --���ږ���2
                                          ,iv_data_value2 => main_rec.dlv_date          --�f�[�^�̒l2
                                          );
          
          ov_errmsg := xxccp_common_pkg.get_msg(cv_application
                                              , cv_msg_select_err
                                              , cv_tkn_table_name
                                              , gv_msg_tkn_vd_deliv_h
                                              , cv_tkn_key_data
                                              , gv_key_info
                                              );

        END IF;
        
        FND_FILE.PUT_LINE(
                          which  => FND_FILE.LOG
                         ,buff   => ov_errbuf --�G���[���b�Z�[�W
                         );
        FND_FILE.PUT_LINE(
                          which  => FND_FILE.OUTPUT
                         ,buff   => ov_errmsg --�G���[���b�Z�[�W
                         );
        ov_retcode := cv_status_warn;
    END;
    
--
  EXCEPTION
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
  END proc_vd_deli_h_dataset;


  /**********************************************************************************
   * Procedure Name   : proc_inv_item_select
   * Description      : A-6�D�i�ڃ}�X�^�f�[�^���o
   ***********************************************************************************/
  PROCEDURE proc_inv_item_select(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_inv_item_select'; -- �v���O������
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
--
    SELECT msib.segment1 segment1             --VD�R�����}�X�^	H/C
    INTO   gv_search_item_code
    FROM   mtl_system_items_b  msib
    WHERE  msib.inventory_item_id       = sub_main_rec.item_id
    AND    msib.organization_id         = gv_organization_id
    ;
    
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
      xxcos_common_pkg.makeup_key_info(ov_errbuf      => lv_errbuf                  --�G���[�E���b�Z�[�W
                                      ,ov_retcode     => lv_retcode                 --���^�[���E�R�[�h
                                      ,ov_errmsg      => lv_errmsg                  --���[�U�[�E�G���[�E���b�Z�[�W
                                      ,ov_key_info    => gv_key_info                --�L�[���
                                      ,iv_item_name1  => gv_msg_tkn_item_id         --���ږ���1
                                      ,iv_data_value1 => sub_main_rec.item_id       --�f�[�^�̒l1
                                      ,iv_item_name2  => gv_msg_tkn_inventory_id    --���ږ���2
                                      ,iv_data_value2 => gv_organization_id         --�f�[�^�̒l2
                                      );
      
      ov_errmsg := xxccp_common_pkg.get_msg(cv_application
                                          , cv_msg_select_err
                                          , cv_tkn_table_name
                                          , gv_msg_tkn_system_item
                                          , cv_tkn_key_data
                                          , gv_key_info
                                          );
      FND_FILE.PUT_LINE(
                        which  => FND_FILE.LOG
                       ,buff   => ov_errbuf --�G���[���b�Z�[�W
                       );
      FND_FILE.PUT_LINE(
                        which  => FND_FILE.OUTPUT
                       ,buff   => ov_errmsg --�G���[���b�Z�[�W
                       );
      ov_retcode := cv_status_warn;
      
--
--#####################################  �Œ蕔 END   ##########################################
--
  END proc_inv_item_select;


  /**********************************************************************************
   * Procedure Name   : proc_vd_deli_l_dataset
   * Description      : A-7�D�x���_�[�i���я�񖾍׃e�[�u���f�[�^�ݒ�
   ***********************************************************************************/
  PROCEDURE proc_vd_deli_l_dataset(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_vd_deli_l_dataset'; -- �v���O������
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
    lv_dlv_date_time     xxcos_vd_deliv_lines.dlv_date_time%TYPE;
    lv_set_dlv_date_time xxcos_vd_deliv_lines.dlv_date_time%TYPE;
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
    BEGIN
    
      SELECT  dlv_date_time
      INTO    lv_dlv_date_time
      FROM    xxcos_vd_deliv_lines xvdl
      WHERE   xvdl.customer_number = main_rec.customer_number
      AND     xvdl.dlv_date        = main_rec.dlv_date       
      AND     xvdl.column_num      = sub_main_rec.column_no
      AND     xvdl.item_code       = gv_search_item_code
      FOR UPDATE NOWAIT
      ;
      -- ===============================
      --�x���_�[�i���я�񖾍׃e�[�u���X�V
      -- ===============================
      --�K�⎞������
      IF lv_dlv_date_time > TO_DATE(TO_CHAR(main_rec.dlv_date,'YYYYMMDD') || NVL(main_rec.dlv_time,'0000') , 'YYYYMMDDHH24MI') THEN
        lv_set_dlv_date_time := lv_dlv_date_time;
      ELSE
        lv_set_dlv_date_time := TO_DATE(TO_CHAR(main_rec.dlv_date,'YYYYMMDD') || NVL(main_rec.dlv_time,'0000') , 'YYYYMMDDHH24MI');
      END IF;
    
      -- ===============================
      --�x���_�[�i���я�񖾍׃e�[�u���X�V
      -- ===============================
      BEGIN
        UPDATE xxcos_vd_deliv_lines
        SET    sales_qty                  = sales_qty + NVL(sub_main_rec.replenish_number,0) --���㐔
              ,dlv_date_time              = lv_set_dlv_date_time                      --�[�i����
              ,last_updated_by            = cn_last_updated_by       
              ,last_update_date           = cd_last_update_date      
              ,last_update_login          = cn_last_update_login     
              ,request_id                 = cn_request_id            
              ,program_application_id     = cn_program_application_id
              ,program_id                 = cn_program_id            
              ,program_update_date        = cd_program_update_date   
        WHERE  customer_number            = main_rec.customer_number
        AND    dlv_date                   = main_rec.dlv_date       
        AND    column_num                 = sub_main_rec.column_no
        AND    item_code                  = gv_search_item_code
        ;
      EXCEPTION
        WHEN OTHERS THEN
          ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
          
          xxcos_common_pkg.makeup_key_info(ov_errbuf      => lv_errbuf                  --�G���[�E���b�Z�[�W
                                          ,ov_retcode     => lv_retcode                 --���^�[���E�R�[�h
                                          ,ov_errmsg      => lv_errmsg                  --���[�U�[�E�G���[�E���b�Z�[�W
                                          ,ov_key_info    => gv_key_info                --�L�[���
                                          ,iv_item_name1  => gv_msg_tkn_cust_code       --���ږ���1
                                          ,iv_data_value1 => main_rec.customer_number   --�f�[�^�̒l1
                                          ,iv_item_name2  => gv_msg_tkn_dlv_date        --���ږ���2
                                          ,iv_data_value2 => main_rec.dlv_date          --�f�[�^�̒l2
                                          ,iv_item_name3  => gv_msg_tkn_column_no       --���ږ���3
                                          ,iv_data_value3 => sub_main_rec.column_no     --�f�[�^�̒l3
                                          ,iv_item_name4  => gv_msg_tkn_item_code       --���ږ���4
                                          ,iv_data_value4 => gv_search_item_code        --�f�[�^�̒l4                                          
                                          );
          
          ov_errmsg := xxccp_common_pkg.get_msg(cv_application
                                              , cv_msg_update_err
                                              , cv_tkn_table_name
                                              , gv_msg_tkn_vd_deliv_l
                                              , cv_tkn_key_data
                                              , gv_key_info
                                              );
          FND_FILE.PUT_LINE(
                            which  => FND_FILE.LOG
                           ,buff   => ov_errbuf --�G���[���b�Z�[�W
                           );
          FND_FILE.PUT_LINE(
                            which  => FND_FILE.OUTPUT
                           ,buff   => ov_errmsg --�G���[���b�Z�[�W
                           );
          RAISE update_error_expt;
      END;
      
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
      -- ===============================
      --�x���_�[�i���я�񖾍׃e�[�u���o�^
      -- ===============================
        BEGIN
          lv_set_dlv_date_time := TO_DATE(TO_CHAR(main_rec.dlv_date,'YYYYMMDD') || NVL(main_rec.dlv_time,'0000') , 'YYYYMMDDHH24MI');
          
          INSERT INTO xxcos_vd_deliv_lines(
             customer_number          --�ڋq�R�[�h
            ,dlv_date                 --�[�i��
            ,column_num               --�R������
            ,item_code                --�i�ڃR�[�h
            ,standard_inv_qty         --��݌ɐ�
            ,hot_cold_type            --H/C
            ,sales_qty                --���㐔
            ,dlv_date_time            --�[�i����
            ,created_by
            ,creation_date
            ,last_updated_by
            ,last_update_date
            ,last_update_login
            ,request_id
            ,program_application_id
            ,program_id
            ,program_update_date
          )VALUES(
             main_rec.customer_number        --�ڋq�R�[�h
            ,main_rec.dlv_date               --�[�i��
            ,sub_main_rec.column_no          --�R������
            ,gv_search_item_code             --�i�ڃR�[�h
            ,sub_main_rec.inventory_quantity --��݌ɐ�
            ,NVL(sub_main_rec.h_and_c,sub_main_rec.hot_cold) --H/C
            ,NVL(sub_main_rec.replenish_number,0)            --���㐔
            ,lv_set_dlv_date_time   --�[�i����
            ,cn_created_by
            ,cd_creation_date
            ,cn_last_updated_by
            ,cd_last_update_date
            ,cn_last_update_login
            ,cn_request_id
            ,cn_program_application_id
            ,cn_program_id
            ,cd_program_update_date
           );
        EXCEPTION
          WHEN OTHERS THEN
            ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
            
            xxcos_common_pkg.makeup_key_info(ov_errbuf      => lv_errbuf                  --�G���[�E���b�Z�[�W
                                            ,ov_retcode     => lv_retcode                 --���^�[���E�R�[�h
                                            ,ov_errmsg      => lv_errmsg                  --���[�U�[�E�G���[�E���b�Z�[�W
                                            ,ov_key_info    => gv_key_info                --�L�[���
                                            ,iv_item_name1  => gv_msg_tkn_cust_code       --���ږ���1
                                            ,iv_data_value1 => main_rec.customer_number   --�f�[�^�̒l1
                                            ,iv_item_name2  => gv_msg_tkn_dlv_date        --���ږ���2
                                            ,iv_data_value2 => main_rec.dlv_date          --�f�[�^�̒l2
                                            ,iv_item_name3  => gv_msg_tkn_column_no       --���ږ���3
                                            ,iv_data_value3 => sub_main_rec.column_no     --�f�[�^�̒l3
                                            ,iv_item_name4  => gv_msg_tkn_item_code       --���ږ���4
                                            ,iv_data_value4 => gv_search_item_code        --�f�[�^�̒l4                                          
                                            );
            
            ov_errmsg := xxccp_common_pkg.get_msg(cv_application
                                                , cv_msg_insert_err
                                                , cv_tkn_table_name
                                                , gv_msg_tkn_vd_deliv_l
                                                , cv_tkn_key_data
                                                , gv_key_info
                                                );
            FND_FILE.PUT_LINE(
                              which  => FND_FILE.LOG
                             ,buff   => ov_errbuf --�G���[���b�Z�[�W
                             );
            FND_FILE.PUT_LINE(
                              which  => FND_FILE.OUTPUT
                             ,buff   => ov_errmsg --�G���[���b�Z�[�W
                             );
            RAISE global_api_others_expt;
        END;
      WHEN update_error_expt THEN
        RAISE global_api_others_expt;
        
      WHEN OTHERS THEN
        ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
        IF (SQLCODE = cn_lock_error_code) THEN
          ov_errmsg := xxccp_common_pkg.get_msg(cv_application
                                              , cv_msg_lock
                                              , cv_tkn_lock
                                              , gv_msg_tkn_vd_deliv_l
                                               );
        ELSE
          xxcos_common_pkg.makeup_key_info(ov_errbuf      => lv_errbuf                  --�G���[�E���b�Z�[�W
                                          ,ov_retcode     => lv_retcode                 --���^�[���E�R�[�h
                                          ,ov_errmsg      => lv_errmsg                  --���[�U�[�E�G���[�E���b�Z�[�W
                                          ,ov_key_info    => gv_key_info                --�L�[���
                                          ,iv_item_name1  => gv_msg_tkn_cust_code       --���ږ���1
                                          ,iv_data_value1 => main_rec.customer_number   --�f�[�^�̒l1
                                          ,iv_item_name2  => gv_msg_tkn_dlv_date        --���ږ���2
                                          ,iv_data_value2 => main_rec.dlv_date          --�f�[�^�̒l2
                                          ,iv_item_name3  => gv_msg_tkn_column_no       --���ږ���3
                                          ,iv_data_value3 => sub_main_rec.column_no     --�f�[�^�̒l3
                                          ,iv_item_name4  => gv_msg_tkn_item_code       --���ږ���4
                                          ,iv_data_value4 => gv_search_item_code        --�f�[�^�̒l4                                            
                                          );
          
          ov_errmsg := xxccp_common_pkg.get_msg(cv_application
                                              , cv_msg_select_err
                                              , cv_tkn_table_name
                                              , gv_msg_tkn_vd_deliv_l
                                              , cv_tkn_key_data
                                              , gv_key_info
                                              );
        END IF;
        
        FND_FILE.PUT_LINE(
                          which  => FND_FILE.LOG
                         ,buff   => ov_errbuf --�G���[���b�Z�[�W
                         );
        FND_FILE.PUT_LINE(
                          which  => FND_FILE.OUTPUT
                         ,buff   => ov_errmsg --�G���[���b�Z�[�W
                         );
        ov_retcode := cv_status_warn;
    END;
--
  EXCEPTION
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
  END proc_vd_deli_l_dataset;


  /**********************************************************************************
   * Procedure Name   : proc_status_update
   * Description      : A-8�DVD�R�����ʎ���w�b�_�e�[�u�����R�[�h���b�N
   *                    A-9�DVD�R�����ʎ���w�b�_�e�[�u���X�e�[�^�X�X�V
   *
   ***********************************************************************************/
  PROCEDURE proc_status_update(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_status_update'; -- ���C�����[�v����
--
--#######################  �Œ胍�[�J���ϐ��錾�� START   ######################
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
    lv_rowid VARCHAR2(100);
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################

  
    <<lins_status_update>>
    FOR i IN 1..gn_main_loop_cnt LOOP
      -- ================================================
      -- A-8�DVD�R�����ʎ���w�b�_�e�[�u�����R�[�h���b�N
      -- ================================================    
      BEGIN
      
        SELECT ROWID
        INTO   lv_rowid
        FROM   xxcos_vd_column_headers xvch
        WHERE  xvch.order_no_hht        = gt_key(i).order_no_hht
        AND    xvch.digestion_ln_number = gt_key(i).digestion_ln_number
        FOR UPDATE NOWAIT;
        
        -- ================================================
        -- A-9�DVD�R�����ʎ���w�b�_�e�[�u���X�e�[�^�X�X�V
        -- ================================================
        BEGIN
          UPDATE xxcos_vd_column_headers
          SET    vd_results_forward_flag    = cv_flag_on
                ,last_updated_by            = cn_last_updated_by       
                ,last_update_date           = cd_last_update_date      
                ,last_update_login          = cn_last_update_login     
                ,request_id                 = cn_request_id            
                ,program_application_id     = cn_program_application_id
                ,program_id                 = cn_program_id            
                ,program_update_date        = cd_program_update_date   
          WHERE  order_no_hht        = gt_key(i).order_no_hht
          AND    digestion_ln_number = gt_key(i).digestion_ln_number
          ;
        EXCEPTION
          WHEN OTHERS THEN
            ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
            xxcos_common_pkg.makeup_key_info(ov_errbuf      => lv_errbuf                  --�G���[�E���b�Z�[�W
                                            ,ov_retcode     => lv_retcode                 --���^�[���E�R�[�h
                                            ,ov_errmsg      => lv_errmsg                  --���[�U�[�E�G���[�E���b�Z�[�W
                                            ,ov_key_info    => gv_key_info                --�L�[���
                                            ,iv_item_name1  => gv_msg_tkn_order_no_hht    --���ږ���1
                                            ,iv_data_value1 => gt_key(i).order_no_hht     --�f�[�^�̒l1
                                            ,iv_item_name2  => gv_msg_tkn_digestion_ln_no --���ږ���2
                                            ,iv_data_value2 => gt_key(i).digestion_ln_number --�f�[�^�̒l2
                                            );

            ov_errmsg := xxccp_common_pkg.get_msg(cv_application
                                                , cv_msg_update_err
                                                , cv_tkn_table_name
                                                , gv_msg_tkn_vd_column_h
                                                , cv_tkn_key_data
                                                , gv_key_info
                                                );
                                                
            FND_FILE.PUT_LINE(
                              which  => FND_FILE.LOG
                             ,buff   => ov_errbuf --�G���[���b�Z�[�W
                             );
            FND_FILE.PUT_LINE(
                              which  => FND_FILE.OUTPUT
                             ,buff   => ov_errmsg --�G���[���b�Z�[�W
                             );
            gn_warn_tran_count := gn_warn_tran_count + 1;
            RAISE update_error_expt;
        END;

      EXCEPTION
        WHEN update_error_expt THEN
          RAISE global_api_others_expt;
        WHEN OTHERS THEN
          ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
          IF (SQLCODE = cn_lock_error_code) THEN
            ov_errmsg := xxccp_common_pkg.get_msg(cv_application
                                                , cv_msg_lock
                                                , cv_tkn_lock
                                                , gv_msg_tkn_vd_column_h
                                                 );
          ELSE
            xxcos_common_pkg.makeup_key_info(ov_errbuf      => lv_errbuf                  --�G���[�E���b�Z�[�W
                                            ,ov_retcode     => lv_retcode                 --���^�[���E�R�[�h
                                            ,ov_errmsg      => lv_errmsg                  --���[�U�[�E�G���[�E���b�Z�[�W
                                            ,ov_key_info    => gv_key_info                --�L�[���
                                            ,iv_item_name1  => gv_msg_tkn_order_no_hht    --���ږ���1
                                            ,iv_data_value1 => gt_key(i).order_no_hht     --�f�[�^�̒l1
                                            ,iv_item_name2  => gv_msg_tkn_digestion_ln_no --���ږ���2
                                            ,iv_data_value2 => gt_key(i).digestion_ln_number --�f�[�^�̒l2
                                            );
            
            ov_errmsg := xxccp_common_pkg.get_msg(cv_application
                                                , cv_msg_select_err
                                                , cv_tkn_table_name
                                                , gv_msg_tkn_vd_column_h
                                                , cv_tkn_key_data
                                                , gv_key_info
                                                );
          END IF;
          
          FND_FILE.PUT_LINE(
                            which  => FND_FILE.LOG
                           ,buff   => ov_errbuf --�G���[���b�Z�[�W
                           );
          FND_FILE.PUT_LINE(
                            which  => FND_FILE.OUTPUT
                           ,buff   => ov_errmsg --�G���[���b�Z�[�W
                           );
          ov_retcode := cv_status_warn;
          gn_warn_tran_count := gn_warn_tran_count + 1;
      END;
      
    END LOOP lins_status_update;

    

  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
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
  END proc_status_update;

  /**********************************************************************************
   * Procedure Name   : proc_main_loop�i���[�v���j
   * Description      : A-2�DVD�R�����ʎ���w�b�_�e�[�u���f�[�^���o
   ***********************************************************************************/
  PROCEDURE proc_main_loop(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_main_loop'; -- ���C�����[�v����
--
--#######################  �Œ胍�[�J���ϐ��錾�� START   ######################
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
    tran_in_exp      EXCEPTION;
    sub_tran_in_exp  EXCEPTION;
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lv_message_code          VARCHAR2(20);
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    <<main_loop>>
    FOR l_main_rec IN main_cur LOOP 
      main_rec := l_main_rec;
      gn_target_cnt := gn_target_cnt + 1;
      
      BEGIN
      -- ==================================================
      --A-9�DVD�R�����ʎ���w�b�_�e�[�u���X�e�[�^�X�X�V
      -- ==================================================
        IF (main_rec.customer_number <> gv_bf_customer_number) THEN
          proc_status_update(
                               lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
                              ,lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
                              ,lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
                              );

          IF (lv_retcode = cv_status_error) THEN
            RAISE global_process_expt;
          END IF;
          -- ================================================
          -- �g�����U�N�V��������
          -- ================================================
          --�G���[�J�E���g
          
          IF (gn_warn_tran_count > 0) THEN
            ROLLBACK;
            gn_warn_cnt := gn_warn_cnt + gn_tran_count;
            ov_errmsg := NULL;
            ov_errbuf := NULL;
          ELSE
            COMMIT;
            gn_normal_cnt := gn_normal_cnt + gn_tran_count;
          END IF;
          gn_warn_tran_count := 0;
          gn_tran_count      := 0;
          --PL/SQL�\�̏�����
          gt_key.DELETE;
          gn_main_loop_cnt := 0;
        END IF;

        -- ==================================================
        --A-3�D�x���_�[�i���я��w�b�_�e�[�u���L�[���ێ�
        -- ==================================================
        gn_main_loop_cnt := gn_main_loop_cnt + 1;
        gt_key(gn_main_loop_cnt).order_no_hht        := main_rec.order_no_hht;       
        gt_key(gn_main_loop_cnt).digestion_ln_number := main_rec.digestion_ln_number;

        -- ===============================
        --�ڋq�R�[�h�u���C�N����
        -- ===============================
        --�u���C�N����L�[����ւ�
        gv_bf_customer_number := main_rec.customer_number;
        
        gn_tran_count := gn_tran_count + 1;
        
        -- ===============================
        --A-4�D�x���_�[�i���я��w�b�_�e�[�u���f�[�^�ݒ�
        -- ===============================
        proc_vd_deli_h_dataset(
                             lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
                            ,lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
                            ,lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
                            );
        IF (lv_retcode = cv_status_warn) THEN
          RAISE tran_in_exp;
        ELSIF (lv_retcode = cv_status_error) THEN
          RAISE global_api_others_expt;
        END IF;
                  
        -- ===============================
        --A-5�DVD�R�����ʎ�����׃e�[�u���f�[�^���o
        -- ===============================
        gn_sub_main_count := 0;
        <<sub_main_loop>>
        FOR l_sub_main_rec IN sub_main_cur LOOP
          sub_main_rec := l_sub_main_rec;
          gn_sub_main_count := gn_sub_main_count + 1;
          IF sub_main_rec.item_code_self IS NULL AND sub_main_rec.item_id IS NOT NULL THEN
          -- ===============================
          --A-6�D�i�ڃ}�X�^�f�[�^���o
          -- ===============================
            proc_inv_item_select(
                                 lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
                                ,lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
                                ,lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
                                );
            IF (lv_retcode <> cv_status_normal) THEN
              RAISE tran_in_exp;
            END IF;
          ELSIF sub_main_rec.item_code_self IS NULL AND sub_main_rec.item_id IS NULL THEN
            gv_search_item_code := cv_blank_column_code;
          ELSE
            gv_search_item_code := sub_main_rec.item_code_self;
          END IF;
          -- ===============================
          --A-7�D�x���_�[�i���я�񖾍׃e�[�u���f�[�^�ݒ�
          -- ===============================
          proc_vd_deli_l_dataset(
                               lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
                              ,lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
                              ,lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
                              );
          IF (lv_retcode = cv_status_warn) THEN
            RAISE tran_in_exp;
          ELSIF (lv_retcode = cv_status_error) THEN
            RAISE global_api_others_expt;
          END IF;
        END LOOP sub_main_loop;
        
        IF gn_sub_main_count = 0 THEN
        
          xxcos_common_pkg.makeup_key_info(ov_errbuf      => lv_errbuf                  --�G���[�E���b�Z�[�W
                                          ,ov_retcode     => lv_retcode                 --���^�[���E�R�[�h
                                          ,ov_errmsg      => lv_errmsg                  --���[�U�[�E�G���[�E���b�Z�[�W
                                          ,ov_key_info    => gv_key_info                --�L�[���
                                          ,iv_item_name1  => gv_msg_tkn_cust_code       --���ږ���1
                                          ,iv_data_value1 => main_rec.customer_number   --�f�[�^�̒l1
                                          );
          
          ov_errmsg := xxccp_common_pkg.get_msg(cv_application
                                              , cv_msg_select_err
                                              , cv_tkn_table_name
                                              , gv_msg_tkn_sub_main_cur
                                              , cv_tkn_key_data
                                              , gv_key_info
                                              );
          FND_FILE.PUT_LINE(
                            which  => FND_FILE.OUTPUT
                           ,buff   => ov_errmsg --�G���[���b�Z�[�W
                           );
          FND_FILE.PUT_LINE(
                            which  => FND_FILE.LOG
                           ,buff   => ov_errmsg --�G���[���b�Z�[�W
                           );                           
          RAISE tran_in_exp;
        END IF;
        
      EXCEPTION
        WHEN tran_in_exp THEN
        --�X�L�b�v�����̉��Z
          gn_warn_tran_count := gn_warn_tran_count + 1;
          ov_retcode := cv_status_warn;
      END;
    END LOOP main_loop;
    IF gn_tran_count > 0 THEN
      proc_status_update(
                           lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
                          ,lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
                          ,lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
                          );
      IF (lv_retcode = cv_status_error) THEN
        RAISE global_process_expt;
      END IF;                    

      -- ================================================
      -- �g�����U�N�V��������
      -- ================================================
      --�G���[�J�E���g
      
      IF (gn_warn_tran_count > 0) THEN
        ROLLBACK;
        gn_warn_cnt := gn_warn_cnt + gn_tran_count;
        ov_errmsg := NULL;
        ov_errbuf := NULL;
      ELSE
        COMMIT;
        gn_normal_cnt := gn_normal_cnt + gn_tran_count;
      END IF;
    END IF;

  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
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
  END proc_main_loop;
--

  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    -- <�J�[�\����>
--
    -- <�J�[�\����>���R�[�h�^
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
    -- ===============================
    -- Loop1 ���C���@A-1�f�[�^���o
    -- ===============================
    proc_main_loop(
       lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );

    IF (lv_retcode = cv_status_error) THEN
      --(�G���[����)
      RAISE global_api_others_expt;
    ELSE
      ov_errbuf  := lv_errbuf;
      ov_retcode := lv_retcode;
      ov_errmsg  := lv_errmsg;
    END IF;
--
  EXCEPTION
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
    cv_appl_short_name CONSTANT VARCHAR2(10)  := 'XXCCP';            -- �A�h�I���F���ʁEIF�̈�
    cv_target_rec_msg  CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90000'; -- �Ώی������b�Z�[�W
    cv_success_rec_msg CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90001'; -- �����������b�Z�[�W
    cv_error_rec_msg   CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90002'; -- �G���[�������b�Z�[�W
    cv_skip_rec_msg    CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90003'; -- �X�L�b�v�������b�Z�[�W
    cv_cnt_token       CONSTANT VARCHAR2(10)  := 'COUNT';            -- �������b�Z�[�W�p�g�[�N����
    cv_normal_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004'; -- ����I�����b�Z�[�W
    cv_warn_msg        CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005'; -- �x���I�����b�Z�[�W
    cv_error_msg       CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006'; -- �G���[�I���S���[���o�b�N
    cv_log_header_out  CONSTANT VARCHAR2(6)   := 'OUTPUT';           -- �R���J�����g�w�b�_���b�Z�[�W�o�͐�F�o��
    cv_log_header_log  CONSTANT VARCHAR2(6)   := 'LOG';              -- �R���J�����g�w�b�_���b�Z�[�W�o�͐�F���O(���[�̂�)

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
       iv_which   => cv_log_header_out    
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
    -- A-0�D��������
    -- ===============================================
    init(
       lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode = cv_status_normal) THEN
      -- ===============================================
      -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
      -- ===============================================
      submain(
         lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
        ,lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
        ,lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
    END IF;

--
    -- ===============================================
    -- A-7�D�I������
    -- ===============================================
    --�G���[�o��
    IF (lv_retcode != cv_status_normal) THEN
-- 2009/02/24 T.Nakamura Ver.1.1 mod start
--      FND_FILE.PUT_LINE(
--         which  => FND_FILE.OUTPUT
--        ,buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
--      );
      IF ( lv_errmsg IS NOT NULL ) THEN
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
        );
      END IF;
-- 2009/02/24 T.Nakamura Ver.1.1 mod end
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --�G���[���b�Z�[�W
      );
-- 2009/02/24 T.Nakamura Ver.1.1 mod start
--    END IF;
--    --��s�}��
--    FND_FILE.PUT_LINE(
--       which  => FND_FILE.OUTPUT
--      ,buff   => ''
--    );
      --��s�}��
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => ''
      );
    END IF;
-- 2009/02/24 T.Nakamura Ver.1.1 mod end
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
END XXCOS003A03C;
/
