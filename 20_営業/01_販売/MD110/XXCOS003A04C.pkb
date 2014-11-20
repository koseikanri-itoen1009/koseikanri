CREATE OR REPLACE PACKAGE BODY XXCOS003A04C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOS003A04C(body)
 * Description      : �x���_�[�i����IF�o��
 * MD.050           : �x���_�[�i����IF�o�� MD050_COS_003_A04
 * Version          : 1.6
 *
 * Program List     
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                       A-1�D��������
 *  proc_threshold             A-4�D 臒l���o
 *  proc_new_item_select       A-7�D�R�����̍ŐV�i�ڒ��o
 *  proc_month_qty             A-9�D���̐��A��݌ɐ����o
 *  proc_sales_days           A-10�D�̔��������o
 *  proc_hot_warn             A-11�D�z�b�g�x���c�����o
 *  proc_deli_l_file_out      A-13�D�[�i���я�񖾍׃t�@�C���o��
 *  proc_deli_h_file_out      A-15�D�[�i���я��w�b�_�t�@�C���o��
 *  proc_main_loop             A-2�D�ڋq�}�X�^�f�[�^���o
 *  submain                   ���C�������v���V�[�W��
 *  main                      �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009/01/07   1.0    K.Okaguchi       �V�K�쐬
 *  2009/02/24   1.1    T.Nakamura       [��QCOS_130] ���b�Z�[�W�o�́A���O�o�͂ւ̏o�͓��e�̒ǉ��E�C��
 *  2009/04/15   1.2    N.Maeda          [ST��QNo.T1_0067�Ή�] �t�@�C���o�͎���CHAR�^VARCHAR�^�ȊO�ւ̢"��t���̍폜
 *  2009/04/16   1.3    K.Kiriu          [ST��QNo.T1_0075�Ή�] �������ߑΉ�
 *                                       [ST��QNo.T1_0079�Ή�] �z�b�g�x���c���̌v�Z���W�b�N�C��
 *  2009/04/22   1.4    N.Maeda          [ST��QNo.T1_0754�Ή�]�t�@�C���o�͎��̢"��t���C��
 *  2009/07/15   1.5    M.Sano           [SCS��QNo.0000652�Ή�]���׃f�[�^�̃t�@�C���o�͕��@�ύX
 *                                       [SCS��QNo.0000653�Ή�]�z�b�g�x���c���o�͕s���Ή�
 *                                       [SCS��QNo.0000690�Ή�]�o�͊֘A�ϐ��������s�ǑΉ�
 *  2009/07/24   1.6    M.Sano           [SCS��QNo.0000691�Ή�]�R�����ύX�AH/C�敪�ύX���̃z�b�g�x���c���ύX
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
  gn_target_cnt    NUMBER DEFAULT 0 ;                    -- �Ώی���
  gn_normal_cnt    NUMBER DEFAULT 0 ;                    -- ���팏��
  gn_error_cnt     NUMBER DEFAULT 0 ;                    -- �G���[����
  gn_warn_cnt      NUMBER DEFAULT 0 ;                    -- �X�L�b�v����
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
  column_no_data_expt       EXCEPTION;     --�x���_�R�����}�X�^�Ƀf�[�^�����݂��Ȃ��ꍇ
  line_no_data_expt         EXCEPTION;     --�x���_�[�i���я��e�[�u���Ƀf�[�^�����݂��Ȃ��ꍇ
  file_open_expt            EXCEPTION;     --�t�@�C���I�[�v���G���[
-- 2009/07/24 Add Ver.1.6 Start
  column_change_data_expt   EXCEPTION;     --�R�����ύX�����{���ꂽ�ꍇ
  hctype_change_data_expt   EXCEPTION;     --H/C�敪�ύX�����{���ꂽ�ꍇ
-- 2009/07/24 Add Ver.1.6 End
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name             CONSTANT VARCHAR2(100):= 'XXCOS003A04C'; -- �p�b�P�[�W��
  cv_application          CONSTANT VARCHAR2(5)  := 'XXCOS';        -- �A�v���P�[�V������(�̔�)
  cv_application_coi      CONSTANT VARCHAR2(5)  := 'XXCOI';        -- �A�v���P�[�V������(�݌�)
  cv_appl_short_name      CONSTANT VARCHAR2(10) := 'XXCCP';        -- �A�h�I���F���ʁEIF�̈�
  cv_tkn_table_name       CONSTANT VARCHAR2(20) := 'TABLE_NAME';
  cv_tkn_key_data         CONSTANT VARCHAR2(20) := 'KEY_DATA';
  cv_flag_off             CONSTANT VARCHAR2(1)  := 'N';
  cv_flag_on              CONSTANT VARCHAR2(1)  := 'Y';
  cv_tkn_filename         CONSTANT VARCHAR2(20) := 'FILE_NAME';  
  cv_delimit              CONSTANT VARCHAR2(1)  := ',';            -- ��؂蕶��
  cv_quot                 CONSTANT VARCHAR2(1)  := '"';            -- �R�[�e�[�V����
  cv_hot_type             CONSTANT VARCHAR2(1)  := '3';            -- �z�b�g�R�[���h�敪���g�n�s
  cv_warehouse            CONSTANT VARCHAR2(20) := '1';
  
  cn_lock_error_code      CONSTANT NUMBER       := -54;
  cv_msg_no_data_tran     CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00003';    --�Ώۃf�[�^�����G���[
  cv_msg_pro              CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00004';    --�v���t�@�C���擾�G���[
  cv_msg_file_open        CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00009';    --�t�@�C���I�[�v���G���[���b�Z�[�W
  cv_msg_select_err       CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00013';    -- �f�[�^���o�G���[���b�Z�[�W
  cv_msg_process_dt_err   CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00014';    -- �Ɩ����t�擾�G���[
  cv_no_parameter         CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90008';    -- �p�����[�^�Ȃ�
  
  cv_msg_filename         CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00044';    --�t�@�C�����i�^�C�g���j

  cv_tkn_dir_path         CONSTANT VARCHAR2(20) := 'APP-XXCOS1-10662';    -- HHT�A�E�g�o�E���h�p�f�B���N�g���p�X
  cv_tkn_vend_h_filename  CONSTANT VARCHAR2(20) := 'APP-XXCOS1-10801';    -- �x���_�[�i���уw�b�_�t�@�C����
  cv_tkn_vend_l_filename  CONSTANT VARCHAR2(20) := 'APP-XXCOS1-10802';    -- �x���_�[�i���і��׃t�@�C����

  cv_tkn_cust_code        CONSTANT VARCHAR2(20) := 'APP-XXCOS1-10853';    -- �ڋq�R�[�h
  cv_tkn_item_code        CONSTANT VARCHAR2(20) := 'APP-XXCOS1-10803';    -- �i�ڃR�[�h
  cv_tkn_dlv_date         CONSTANT VARCHAR2(20) := 'APP-XXCOS1-10752';    -- �[�i��
  cv_tkn_vd_deliv_l       CONSTANT VARCHAR2(20) := 'APP-XXCOS1-10753';    -- �x���_�[�i���я�񖾍׃e�[�u��
  cv_tkn_column_no        CONSTANT VARCHAR2(20) := 'APP-XXCOS1-10754';    -- �R����No
  cv_tkn_warehouse_cl     CONSTANT VARCHAR2(20) := 'APP-XXCOS1-10804';    -- �ۊǏꏊ�敪
  cv_tkn_base_code        CONSTANT VARCHAR2(20) := 'APP-XXCOS1-10805';    -- ���_�R�[�h
  cv_tkn_main_warehouse_c CONSTANT VARCHAR2(20) := 'APP-XXCOS1-10806';    -- ���C���q�ɋ敪
  cv_tkn_mtl_second_inv   CONSTANT VARCHAR2(20) := 'APP-XXCOS1-10807';    -- �ۊǏꏊ�}�X�^
  cv_tkn_cust_account_id  CONSTANT VARCHAR2(20) := 'APP-XXCOS1-10808';    -- �ڋqID
  cv_tkn_vd_column_mst    CONSTANT VARCHAR2(20) := 'APP-XXCOS1-10809';    -- �׃��_�R�����}�X�^


  cv_tkn_profile          CONSTANT VARCHAR2(20) := 'PROFILE';             -- �v���t�@�C����
  cv_tkn_file_name        CONSTANT VARCHAR2(20) := 'FILE_NAME';           -- �t�@�C����

  cv_prf_dir_path         CONSTANT VARCHAR2(50) := 'XXCOS1_OUTBOUND_HHT_DIR';      -- HHT�A�E�g�o�E���h�p�f�B���N�g���p�X
  cv_prf_vend_h_filename  CONSTANT VARCHAR2(50) := 'XXCOS1_VENDER_DELI_H_FILE_NAME';    -- �x���_�[�i���уw�b�_�t�@�C��
  cv_prf_vend_l_filename  CONSTANT VARCHAR2(50) := 'XXCOS1_VENDER_DELI_L_FILE_NAME';    -- �x���_�[�i���і��׃t�@�C�� 

  cv_lookup_type_gyotai   CONSTANT VARCHAR2(30) := 'XXCOS1_GYOTAI_SHO_MST_003_A03'; -- �Q�ƃ^�C�v�@�Ƒԏ�����
  cv_organization_code    CONSTANT VARCHAR2(30) := 'XXCOI1_ORGANIZATION_CODE';      -- �݌ɑg�D�R�[�h
  
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gv_key_info                 fnd_new_messages.message_text%TYPE   ; --���b�Z�[�W�o�͗p�L�[���
  gv_msg_tkn_cust_code        fnd_new_messages.message_text%TYPE   ; --�ڋq�R�[�h
  gv_msg_tkn_item_code        fnd_new_messages.message_text%TYPE   ; --�i�ڃR�[�h
  gv_msg_tkn_dlv_date         fnd_new_messages.message_text%TYPE   ; --�[�i��
  gv_msg_tkn_vd_deliv_l       fnd_new_messages.message_text%TYPE   ; --�x���_�[�i���я�񖾍׃e�[�u��
  gv_msg_tkn_column_no        fnd_new_messages.message_text%TYPE   ; --�R����No
  gv_msg_tkn_warehouse_cl     fnd_new_messages.message_text%TYPE   ; --�ۊǏꏊ�敪
  gv_msg_tkn_base_code        fnd_new_messages.message_text%TYPE   ; --���_�R�[�h
  gv_msg_tkn_main_warehouse_c fnd_new_messages.message_text%TYPE   ; --���C���q�ɋ敪
  gv_msg_tkn_mtl_second_inv   fnd_new_messages.message_text%TYPE   ; --�ۊǏꏊ�}�X�^
  gv_msg_tkn_cust_account_id  fnd_new_messages.message_text%TYPE   ; --�ڋqID
  gv_msg_tkn_vd_column_mst    fnd_new_messages.message_text%TYPE   ; --�׃��_�R�����}�X�^
  gv_msg_no_data_tran         fnd_new_messages.message_text%TYPE   ; --�Ώۃf�[�^�����G���[


  gv_msg_tkn_dir_path         fnd_new_messages.message_text%TYPE   ;--HHT�A�E�g�o�E���h�p�f�B���N�g���p�X
  gv_msg_tkn_vend_h_filename  fnd_new_messages.message_text%TYPE   ;--�x���_�[�i���уw�b�_�t�@�C��
  gv_msg_tkn_vend_l_filename  fnd_new_messages.message_text%TYPE   ;--�x���_�[�i���і��׃t�@�C�� 
  
  gv_customer_number          xxcos_unit_price_mst_work.customer_number%TYPE;
  gv_tkn_lock_table           fnd_new_messages.message_text%TYPE   ;

  gv_item_code                xxcos_vd_deliv_lines.item_code%TYPE;        --�i�ڃR�[�h
  gv_hot_cold_type            xxcos_vd_deliv_lines.hot_cold_type%TYPE;    --H/C
  gt_dlv_date_time            xxcos_vd_deliv_lines.dlv_date_time%TYPE;    --�[�i����
  gv_hot_stock_days           mtl_secondary_inventories.attribute10%TYPE; --�z�b�g�݌ɓ���
  gd_standard_date            DATE;                                       --���
  gv_column_no                xxcoi_mst_vd_column.column_no%TYPE;
  --�w�b�_�t�@�C���ݒ�ϐ�
  gn_sales_qty_sum_1          NUMBER DEFAULT 0;                           --���㐔1
  gn_sales_qty_sum_2          NUMBER DEFAULT 0;                           --���㐔2
  gn_sales_qty_sum_3          NUMBER DEFAULT 0;                           --���㐔3
  gd_dlv_date_1               DATE;                                       --1���ڂ̔[�i��
  gd_dlv_date_2               DATE;                                       --2���ڂ̔[�i��
  gd_dlv_date_3               DATE;                                       --3���ڂ̔[�i��
  gn_total_amount_1           NUMBER;                                     --1���ڂ̍��v���z
  gn_total_amount_2           NUMBER;                                     --2���ڂ̍��v���z
  gn_total_amount_3           NUMBER;                                     --3���ڂ̍��v���z
  gv_visit_time               xxcos_vd_deliv_headers.visit_time%TYPE;     --�O��K�⎞��
  gn_last_visit_days          NUMBER;                                     --�O��K�����
  
  --���׃t�@�C���ݒ�ϐ�
  gn_monthly_sales            NUMBER;                                     --���̐�
  gn_sales_days               NUMBER;                                     --�̔�����
  gn_inventory_quantity_sum   NUMBER;                                     --��݌ɐ��i���v�j
  gn_hot_warn_qty             NUMBER;                                     --�z�b�g�x���c��
  gn_sales_qty_1              NUMBER;                                     --1���ڂ̔��㐔
  gn_sales_qty_2              NUMBER;                                     --2���ڂ̔��㐔
  gn_sales_qty_3              NUMBER;                                     --3���ڂ̔��㐔
  gn_replacement_rate         NUMBER;                                     --��[��

  --�t�@�C���o�͕ϐ�
  gv_deli_h_file_data         VARCHAR2(1000) ;                            --�x���_�[�i���уw�b�_�t�@�C���o�͗p
  gv_deli_l_file_data         VARCHAR2(1000) ;                            --�x���_�[�i���і��׃t�@�C���o�͗p
  
  --�����J�E���^
  gn_warn_tran_count          NUMBER DEFAULT 0;
  gn_tran_count               NUMBER DEFAULT 0;
  gn_unit_price               NUMBER;
  gn_skip_cnt                 NUMBER DEFAULT 0;                      -- �ΏۊO����
  gn_main_loop_cnt            NUMBER DEFAULT 0;
  
-- 2009/07/15 Add Ver.1.5 Start
  gn_deli_l_cnt               NUMBER DEFAULT 0;                      -- �o�͑Ώۂ̔[�i���я�񖾍חp����
-- 2009/07/15 Add Ver.1.5 End
  
--
--�J�[�\��
  CURSOR main_cur
  IS
    SELECT hzca.cust_account_id   cust_account_id        --�ڋqID
          ,hzca.account_number    account_number         --�ڋq�R�[�h
    FROM   hz_cust_accounts       hzca                   --�ڋq�}�X�^
          ,xxcmm_cust_accounts    xxca                   --�ڋq�ǉ����
          ,fnd_lookup_values      flvl
    WHERE  hzca.cust_account_id   = xxca.customer_id
    AND    xxca.business_low_type = flvl.meaning
    AND    flvl.lookup_type       = cv_lookup_type_gyotai
    AND    flvl.security_group_id = FND_GLOBAL.LOOKUP_SECURITY_GROUP(flvl.lookup_type,flvl.view_application_id)
    AND    flvl.language          = USERENV('LANG')
    AND    TRUNC(SYSDATE)         BETWEEN flvl.start_date_active
                                    AND NVL(flvl.end_date_active, TRUNC(SYSDATE))
    AND    flvl.enabled_flag      = cv_flag_on
    ORDER BY
           hzca.account_number
    ;
    
  main_rec main_cur%ROWTYPE;
      
  CURSOR header_cur
  IS
    SELECT dlv_date    
          ,visit_time  
          ,total_amount
          ,base_code   
    FROM(
      SELECT xvdh.dlv_date           dlv_date              --�[�i��
            ,xvdh.visit_time         visit_time            --�K�⎞��
            ,xvdh.total_amount       total_amount          --���v���z
            ,xvdh.base_code          base_code             --���_�R�[�h
      FROM   xxcos_vd_deliv_headers  xvdh
      WHERE  xvdh.customer_number = main_rec.account_number
      AND    xvdh.total_amount    > 0
      ORDER BY
             xvdh.dlv_date DESC
        )
    WHERE ROWNUM < 4
    ;

  header_rec  header_cur%ROWTYPE;

  CURSOR column_cur
  IS
    SELECT xmvc.column_no            column_no             --�R����No
          ,xmvc.inventory_quantity   inventory_quantity    --��݌ɐ�
    FROM   xxcoi_mst_vd_column       xmvc                  --�x���_�R�����}�X�^
    WHERE  xmvc.customer_id = main_rec.cust_account_id
    ORDER BY
           xmvc.column_no
    ;
  
  column_rec column_cur%ROWTYPE;
  
  CURSOR line_cur
  IS
    SELECT dlv_date    
          ,sum_sales_qty
    FROM(
      SELECT xvdl.dlv_date        dlv_date                   --�[�i��
            ,SUM(xvdl.sales_qty)  sum_sales_qty              --���㐔�̃T�}��
      FROM   xxcos_vd_deliv_lines xvdl                       --�x���_�[�i���я�񖾍׃e�[�u��
      WHERE  xvdl.customer_number = main_rec.account_number
      AND    xvdl.column_num      = column_rec.column_no
      AND    xvdl.dlv_date        IN(gd_dlv_date_1,gd_dlv_date_2,gd_dlv_date_3)
      GROUP BY xvdl.dlv_date
      ORDER BY xvdl.dlv_date DESC
      )
    WHERE ROWNUM < 4
    ;

  line_rec line_cur%ROWTYPE;
  
-- 2009/07/15 Add Ver.1.5 Start
  -- ===============================
  -- ���[�U�[��`�O���[�o��RECORD�^�錾
  -- ===============================
  -- �[�i���я�񖾍׃��R�[�h
  TYPE g_deli_line_rtype  IS RECORD
    (
      account_number                hz_cust_accounts.account_number%TYPE,  -- �ڋq�R�[�h 
      column_no                     xxcoi_mst_vd_column.column_no%TYPE,    -- �R����No 
      monthly_sales                 NUMBER,                                -- ���̐�
      sales_days                    NUMBER,                                -- �̔�����
      inventory_quantity_sum        NUMBER,                                -- ��݌ɐ�
      hot_warn_qty                  NUMBER,                                -- �z�b�g�x���c��
      sales_qty_1                   NUMBER,                                -- �O�񔄏㐔
      sales_qty_2                   NUMBER,                                -- �O�X�񔄏㐔
      sales_qty_3                   NUMBER,                                -- �O�X�O�񔄏㐔
      replacement_rate              NUMBER                                 -- ��[��
    );
    
--
  -- ===============================
  -- ���[�U�[��`�O���[�o��TABLE�^�錾
  -- ===============================
  -- �[�i���я�񖾍׃e�[�u���^
  TYPE g_deli_line_ttype  IS TABLE OF g_deli_line_rtype  INDEX BY BINARY_INTEGER;
--
-- 2009/07/15 Add Ver.1.5 End
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
    
    gt_deli_h_handle       UTL_FILE.FILE_TYPE; --�[�i���я��w�b�_�t�@�C���n���h��
    gt_deli_l_handle       UTL_FILE.FILE_TYPE; --�[�i���я�񖾍׃t�@�C���n���h��
-- 2009/07/15 Add Ver.1.5 Start
    gt_deli_l_tab          g_deli_line_ttype;  --�o�͑Ώۂ̔[�i���я�񖾍׃f�[�^
-- 2009/07/15 Add Ver.1.5 End

--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
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
    lv_dir_path                 VARCHAR2(100);                -- HHT�A�E�g�o�E���h�p�f�B���N�g���p�X
    lv_vend_h_filename          VARCHAR2(100);                -- �x���_�[�i���уw�b�_�t�@�C����
    lv_vend_l_filename          VARCHAR2(100);                -- �x���_�[�i���і��׃t�@�C����
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
    gv_msg_tkn_dlv_date        := xxccp_common_pkg.get_msg(iv_application   => cv_application
                                                           ,iv_name         => cv_tkn_dlv_date
                                                           );
    gv_msg_tkn_vd_deliv_l      := xxccp_common_pkg.get_msg(iv_application   => cv_application
                                                           ,iv_name         => cv_tkn_vd_deliv_l
                                                           );
    gv_msg_tkn_column_no       := xxccp_common_pkg.get_msg(iv_application   => cv_application
                                                           ,iv_name         => cv_tkn_column_no
                                                           );
    gv_msg_tkn_warehouse_cl    := xxccp_common_pkg.get_msg(iv_application   => cv_application
                                                           ,iv_name         => cv_tkn_warehouse_cl
                                                           );
    gv_msg_tkn_base_code       := xxccp_common_pkg.get_msg(iv_application   => cv_application
                                                           ,iv_name         => cv_tkn_base_code
                                                           );
    gv_msg_tkn_main_warehouse_c := xxccp_common_pkg.get_msg(iv_application  => cv_application
                                                           ,iv_name         => cv_tkn_main_warehouse_c
                                                           );
    gv_msg_tkn_mtl_second_inv  := xxccp_common_pkg.get_msg(iv_application   => cv_application
                                                           ,iv_name         => cv_tkn_mtl_second_inv
                                                           );
    gv_msg_tkn_cust_account_id := xxccp_common_pkg.get_msg(iv_application   => cv_application
                                                           ,iv_name         => cv_tkn_cust_account_id
                                                           );
    gv_msg_tkn_vd_column_mst   := xxccp_common_pkg.get_msg(iv_application  => cv_application
                                                           ,iv_name         => cv_tkn_vd_column_mst
                                                           );
    gv_msg_tkn_vend_h_filename := xxccp_common_pkg.get_msg(iv_application   => cv_application
                                                           ,iv_name         => cv_tkn_vend_h_filename
                                                           );                                                           
    gv_msg_tkn_vend_l_filename := xxccp_common_pkg.get_msg(iv_application   => cv_application
                                                           ,iv_name         => cv_tkn_vend_l_filename
                                                           );                                                               
    gv_msg_tkn_dir_path        := xxccp_common_pkg.get_msg(iv_application   => cv_application
                                                           ,iv_name         => cv_tkn_dir_path
                                                           );     
    gv_msg_no_data_tran        := xxccp_common_pkg.get_msg(iv_application   => cv_application
                                                           ,iv_name         => cv_msg_no_data_tran
                                                           );     
                                                                                                                      
    
    --==============================================================
    -- �v���t�@�C���̎擾(XXCOS:HHT�A�E�g�o�E���h�p�f�B���N�g���p�X)
    --==============================================================
    lv_dir_path := FND_PROFILE.VALUE(cv_prf_dir_path);
    
--
    -- �v���t�@�C���擾�G���[�̏ꍇ
    IF (lv_dir_path IS NULL) THEN
      ov_errmsg := xxccp_common_pkg.get_msg(cv_application
                                          , cv_msg_pro
                                          , cv_tkn_profile
                                          , gv_msg_tkn_dir_path
                                           );
      RAISE global_api_others_expt;
    END IF;
--

    --==============================================================
    -- �v���t�@�C���̎擾(XXCOS:�x���_�[�i���уw�b�_�t�@�C����)
    --==============================================================
    lv_vend_h_filename := FND_PROFILE.VALUE(cv_prf_vend_h_filename);
--
    -- �v���t�@�C���擾�G���[�̏ꍇ
    IF (lv_vend_h_filename IS NULL) THEN
      ov_errmsg := xxccp_common_pkg.get_msg(cv_application
                                          , cv_msg_pro
                                          , cv_tkn_profile
                                          , gv_msg_tkn_vend_h_filename
                                           );
      RAISE global_api_others_expt;
    END IF;

    --==============================================================
    -- �v���t�@�C���̎擾(XXCOS:�x���_�[�i���і��׃t�@�C����)
    --==============================================================
    lv_vend_l_filename := FND_PROFILE.VALUE(cv_prf_vend_l_filename);
--
    -- �v���t�@�C���擾�G���[�̏ꍇ
    IF (lv_vend_l_filename IS NULL) THEN
      ov_errmsg := xxccp_common_pkg.get_msg(cv_application
                                          , cv_msg_pro
                                          , cv_tkn_profile
                                          , gv_msg_tkn_vend_l_filename
                                           );
      RAISE global_api_others_expt;
    END IF;

    --==============================================================
    -- �t�@�C�����̃��O�o��
    --==============================================================
    --�x���_�[�i���уw�b�_�t�@�C����
    gv_out_msg := xxccp_common_pkg.get_msg(iv_application  => cv_application
                                          ,iv_name         => cv_msg_filename
                                          ,iv_token_name1  => cv_tkn_filename
                                          ,iv_token_value1 => lv_vend_h_filename
                                          );
    FND_FILE.PUT_LINE(
                      which  => FND_FILE.OUTPUT
                     ,buff   => gv_out_msg
                     );
                     
    
    --�x���_�[�i���і��׃t�@�C����
    gv_out_msg := xxccp_common_pkg.get_msg(iv_application  => cv_application
                                          ,iv_name         => cv_msg_filename
                                          ,iv_token_name1  => cv_tkn_filename
                                          ,iv_token_value1 => lv_vend_l_filename
                                          );
    FND_FILE.PUT_LINE(
                      which  => FND_FILE.OUTPUT
                     ,buff   => gv_out_msg
                     );
                     
    --��s
    FND_FILE.PUT_LINE(
                      which  => FND_FILE.OUTPUT
                     ,buff   => ''
                     );
--
    --==============================================================
    -- �x���_�[�i���уw�b�_�t�@�C���@�t�@�C���I�[�v��
    --==============================================================
    BEGIN
      gt_deli_h_handle := UTL_FILE.FOPEN(lv_dir_path
                                  , lv_vend_h_filename
                                  , 'w');
    EXCEPTION
      WHEN OTHERS THEN
        ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
        ov_errmsg := xxccp_common_pkg.get_msg(cv_application
                                            , cv_msg_file_open
                                            , cv_tkn_file_name
                                            , lv_vend_h_filename);
        RAISE file_open_expt;
    END;

    --==============================================================
    -- �x���_�[�i���і��׃t�@�C���@�t�@�C���I�[�v��
    --==============================================================
    BEGIN
      gt_deli_l_handle := UTL_FILE.FOPEN(lv_dir_path
                                  , lv_vend_l_filename
                                  , 'w');
    EXCEPTION
      WHEN OTHERS THEN
        ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
        ov_errmsg := xxccp_common_pkg.get_msg(cv_application
                                            , cv_msg_file_open
                                            , cv_tkn_file_name
                                            , lv_vend_l_filename);
      RAISE file_open_expt;
    END;

    --==============================================================
    -- ������擾
    --==============================================================
    gd_standard_date := xxccp_common_pkg2.get_process_date + 1;
    
    IF (gd_standard_date IS NULL) THEN
      ov_errmsg := xxccp_common_pkg.get_msg(cv_application
                                          , cv_msg_process_dt_err
                                           );
      RAISE global_api_others_expt;
    END IF;

--
  EXCEPTION
    WHEN file_open_expt THEN
      ov_errbuf := ov_errbuf || ov_errmsg;
      ov_retcode := cv_status_error;
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
   * Procedure Name   : proc_threshold
   * Description      : A-4�D 臒l���o
   ***********************************************************************************/
  PROCEDURE proc_threshold(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_threshold'; -- �v���O������
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
    SELECT mtsi.attribute10          hot_stock_days
    INTO   gv_hot_stock_days
    FROM   mtl_secondary_inventories mtsi
    WHERE  mtsi.attribute1 = cv_warehouse
    AND    mtsi.attribute7 = header_rec.base_code
    AND    mtsi.attribute6 = cv_flag_on
    ;
--
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
      lv_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      
      xxcos_common_pkg.makeup_key_info(ov_errbuf      => lv_errbuf                  --�G���[�E���b�Z�[�W
                                      ,ov_retcode     => lv_retcode                 --���^�[���E�R�[�h
                                      ,ov_errmsg      => lv_errmsg                  --���[�U�[�E�G���[�E���b�Z�[�W
                                      ,ov_key_info    => gv_key_info                --�L�[���
                                      ,iv_item_name1  => gv_msg_tkn_warehouse_cl    --���ږ���1
                                      ,iv_data_value1 => cv_warehouse               --�f�[�^�̒l1
                                      ,iv_item_name2  => gv_msg_tkn_base_code       --���ږ���2
                                      ,iv_data_value2 => header_rec.base_code       --�f�[�^�̒l2
                                      ,iv_item_name3  => gv_msg_tkn_main_warehouse_c --���ږ���3
                                      ,iv_data_value3 => cv_flag_on                  --�f�[�^�̒l3
                                      );
      
      ov_errmsg := xxccp_common_pkg.get_msg(cv_application
                                          , cv_msg_select_err
                                          , cv_tkn_table_name
                                          , gv_msg_tkn_mtl_second_inv
                                          , cv_tkn_key_data
                                          , gv_key_info
                                          );
      FND_FILE.PUT_LINE(
                        which  => FND_FILE.OUTPUT
                       ,buff   => ov_errmsg --�G���[���b�Z�[�W
                       );                                          
                       
      FND_FILE.PUT_LINE(
                        which  => FND_FILE.LOG
                       ,buff   => lv_errbuf --�G���[���b�Z�[�W
                       );
      ov_errmsg := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg;                       
      
      FND_FILE.PUT_LINE(
                        which  => FND_FILE.LOG
                       ,buff   => ov_errmsg --�G���[���b�Z�[�W
                       );
      ov_retcode := cv_status_warn;

--
--#####################################  �Œ蕔 END   ##########################################
--
  END proc_threshold;
--

  /**********************************************************************************
   * Procedure Name   : proc_new_item_select
   * Description      : A-7�D�R�����̍ŐV�i�ڒ��o
   ***********************************************************************************/
  PROCEDURE proc_new_item_select(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_new_item_select'; -- �v���O������
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
    SELECT xvdl.item_code      item_code
          ,xvdl.hot_cold_type  hot_cold_type
          ,a.dlv_date_time     dlv_date_time
    INTO   gv_item_code
          ,gv_hot_cold_type
          ,gt_dlv_date_time
    FROM   xxcos_vd_deliv_lines xvdl
          ,(SELECT MAX(dlv_date_time) dlv_date_time
                  ,customer_number
                  ,dlv_date
                  ,column_num
            FROM   xxcos_vd_deliv_lines
            WHERE  customer_number = main_rec.account_number
            AND    dlv_date        = header_rec.dlv_date
            AND    column_num      = column_rec.column_no
            GROUP BY customer_number
                    ,dlv_date
                    ,column_num
           ) a
    WHERE  xvdl.customer_number = a.customer_number
    AND    xvdl.column_num      = a.column_num
    AND    xvdl.dlv_date        = a.dlv_date
    AND    xvdl.dlv_date_time   = a.dlv_date_time
    ;
--
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
                                      ,iv_item_name1  => gv_msg_tkn_cust_code       --���ږ���1
                                      ,iv_data_value1 => main_rec.account_number    --�f�[�^�̒l1
                                      ,iv_item_name2  => gv_msg_tkn_column_no       --���ږ���2
                                      ,iv_data_value2 => column_rec.column_no       --�f�[�^�̒l2
                                      ,iv_item_name3  => gv_msg_tkn_dlv_date        --���ږ���3
                                      ,iv_data_value3 => header_rec.dlv_date  --�f�[�^�̒l3                                                                                                                      
                                      );
      
      ov_errmsg := xxccp_common_pkg.get_msg(cv_application
                                          , cv_msg_select_err
                                          , cv_tkn_table_name
                                          , gv_msg_tkn_vd_deliv_l
                                          , cv_tkn_key_data
                                          , gv_key_info
                                          );
      FND_FILE.PUT_LINE(
                        which  => FND_FILE.OUTPUT
                       ,buff   => ov_errmsg --�G���[���b�Z�[�W
                       );                                          
                       
      FND_FILE.PUT_LINE(
                        which  => FND_FILE.LOG
                       ,buff   => lv_errbuf --�G���[���b�Z�[�W
                       );
      ov_errmsg := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg;
      FND_FILE.PUT_LINE(
                        which  => FND_FILE.LOG
                       ,buff   => ov_errmsg --�G���[���b�Z�[�W
                       );
      ov_retcode := cv_status_warn;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END proc_new_item_select;
--
--
  /**********************************************************************************
   * Procedure Name   : proc_month_qty
   * Description      : A-9�D���̐��A��݌ɐ����o
   ***********************************************************************************/
  PROCEDURE proc_month_qty(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_month_qty'; -- �v���O������
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
    SELECT NVL(SUM(xvdl.sales_qty),0)        sum_sales_qty
          ,NVL(SUM(xvdl.standard_inv_qty),0) sum_standard_inv_qty
    INTO   gn_monthly_sales                                --���̐�
          ,gn_inventory_quantity_sum                       --��݌ɐ��i���v�j
    FROM   xxcos_vd_deliv_lines xvdl                       --�x���_�[�i���я�񖾍׃e�[�u��
    WHERE  xvdl.customer_number = main_rec.account_number
    AND    xvdl.column_num      = column_rec.column_no
    AND    xvdl.dlv_date        > ADD_MONTHS(gd_standard_date, -1)
    AND    xvdl.item_code       = gv_item_code
    ;
--
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
  END proc_month_qty;
--
  /**********************************************************************************
   * Procedure Name   : proc_sales_days
   * Description      : A-10�D�̔��������o
   ***********************************************************************************/
  PROCEDURE proc_sales_days(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_sales_days'; -- �v���O������
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
    ld_min_dlv_date DATE;
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
    SELECT MIN(xvdl.dlv_date)
    INTO   ld_min_dlv_date
    FROM   xxcos_vd_deliv_lines xvdl                       --�x���_�[�i���я�񖾍׃e�[�u��
    WHERE  xvdl.customer_number = main_rec.account_number
    AND    xvdl.column_num      = column_rec.column_no
    AND    xvdl.item_code       = gv_item_code
    ;
    
    IF ld_min_dlv_date > ADD_MONTHS(gd_standard_date ,-1) THEN
      gn_sales_days := gd_standard_date - ld_min_dlv_date; 
    ELSE
      gn_sales_days := gd_standard_date - ADD_MONTHS(gd_standard_date ,-1);
    END IF;

--
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
      lv_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      
      xxcos_common_pkg.makeup_key_info(ov_errbuf      => lv_errbuf                  --�G���[�E���b�Z�[�W
                                      ,ov_retcode     => lv_retcode                 --���^�[���E�R�[�h
                                      ,ov_errmsg      => lv_errmsg                  --���[�U�[�E�G���[�E���b�Z�[�W
                                      ,ov_key_info    => gv_key_info                --�L�[���
                                      ,iv_item_name1  => gv_msg_tkn_cust_code       --���ږ���1
                                      ,iv_data_value1 => main_rec.account_number    --�f�[�^�̒l1
                                      ,iv_item_name2  => gv_msg_tkn_column_no       --���ږ���2
                                      ,iv_data_value2 => column_rec.column_no       --�f�[�^�̒l2
                                      ,iv_item_name3  => gv_msg_tkn_item_code       --���ږ���3
                                      ,iv_data_value3 => gv_item_code               --�f�[�^�̒l3
                                      );
      
      ov_errmsg := xxccp_common_pkg.get_msg(cv_application
                                          , cv_msg_select_err
                                          , cv_tkn_table_name
                                          , gv_msg_tkn_vd_deliv_l
                                          , cv_tkn_key_data
                                          , gv_key_info
                                          );
      FND_FILE.PUT_LINE(
                        which  => FND_FILE.OUTPUT
                       ,buff   => ov_errmsg --�G���[���b�Z�[�W
                       ); 
      FND_FILE.PUT_LINE(
                        which  => FND_FILE.LOG
                       ,buff   => lv_errbuf --�G���[���b�Z�[�W
                       );
      ov_errmsg := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg;                 
      FND_FILE.PUT_LINE(
                        which  => FND_FILE.LOG
                       ,buff   => ov_errmsg --�G���[���b�Z�[�W
                       );
                       
      ov_retcode := cv_status_warn;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END proc_sales_days;
--
  /**********************************************************************************
   * Procedure Name   : proc_hot_warn
   * Description      : A-11�D�z�b�g�x���c�����o
   ***********************************************************************************/
  PROCEDURE proc_hot_warn(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_hot_warn'; -- �v���O������
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
    ln_sales_total_qty NUMBER;
-- 2009/07/24 Add Ver.1.6 Start
    lt_change_column_date  xxcos_vd_deliv_lines.dlv_date%TYPE;
    lt_change_hctype_date  xxcos_vd_deliv_lines.dlv_date%TYPE;
-- 2009/07/24 Add Ver.1.6 End
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
-- 2009/07/24 Add Ver.1.6 Start
    -- �� �R�����ύX�̍ŏI�X�V�[�i�����擾����B
    BEGIN
      SELECT MIN(xvdl.dlv_date)                                           -- �R�������Ō�ɕύX��������
      INTO   lt_change_column_date
      FROM   xxcos_vd_deliv_lines xvdl                                    -- (TABLE)�x���_�[�i����
            ,( SELECT MAX(xvdl_m.dlv_date_time) dlv_date_time             -- �Ō�ɃR�����ύX�����{����O�̓���
               FROM   xxcos_vd_deliv_lines xvdl_m                         -- (TABLE)�x���_�[�i����
               WHERE  xvdl_m.customer_number = main_rec.account_number
               AND    xvdl_m.column_num      = column_rec.column_no
               AND    xvdl_m.item_code      <> gv_item_code
             ) xvdl_v
      WHERE  xvdl.customer_number = main_rec.account_number
      AND    xvdl.column_num      = column_rec.column_no
      AND    xvdl_v.dlv_date_time IS NOT NULL
      AND    xvdl.dlv_date_time   > xvdl_v.dlv_date_time
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lt_change_column_date := NULL;
    END;
--
    -- �� �R�����ύX��臒l���Ŏ��{���ꂽ�ꍇ�A�㑱�̏��������{���Ȃ��B
    IF (   lt_change_column_date IS NOT NULL
       AND header_rec.dlv_date < lt_change_column_date + TO_NUMBER(gv_hot_stock_days)
       ) THEN
      RAISE column_change_data_expt;
    END IF;
--
    -- �� H/C�敪�ύX�̍ŏI�X�V�[�i�����擾����B
    BEGIN
      SELECT MIN(xvdl.dlv_date)
      INTO   lt_change_hctype_date
      FROM   xxcos_vd_deliv_lines xvdl
            ,( SELECT MAX(xvdl_m.dlv_date_time) dlv_date_time
               FROM   xxcos_vd_deliv_lines xvdl_m
               WHERE  xvdl_m.customer_number = main_rec.account_number
               AND    xvdl_m.column_num      = column_rec.column_no
               AND    xvdl_m.item_code       = gv_item_code
               AND    xvdl_m.hot_cold_type  <> gv_hot_cold_type
             ) xvdl_v
      WHERE  xvdl.customer_number = main_rec.account_number
      AND    xvdl.column_num      = column_rec.column_no
      AND    xvdl_v.dlv_date_time IS NOT NULL
      AND    xvdl.dlv_date_time   > xvdl_v.dlv_date_time
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lt_change_hctype_date := NULL;
    END;
--
    -- �� �R�����ύX��臒l���Ŏ��{���ꂽ�ꍇ�A�㑱�̏��������{���Ȃ��B
    IF (   lt_change_hctype_date IS NOT NULL
       AND header_rec.dlv_date < lt_change_hctype_date + TO_NUMBER(gv_hot_stock_days)
       ) THEN
      RAISE hctype_change_data_expt;
    END IF;
--
    -- �� ��L�̏����𖞂����Ȃ��ꍇ�A�z�b�g�x���c�����擾����B
-- 2009/07/24 Add Ver.1.6 End
    BEGIN
      SELECT NVL(SUM(xvdl.sales_qty),0)
      INTO   ln_sales_total_qty
      FROM   xxcos_vd_deliv_lines xvdl  
      WHERE  xvdl.customer_number = main_rec.account_number
      AND    xvdl.column_num      = column_rec.column_no
      AND    xvdl.dlv_date        > (gd_standard_date - gv_hot_stock_days)
      AND    xvdl.item_code       = gv_item_code
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        ln_sales_total_qty := 0;
    END;
-- 2009/04/16 K.Kiriu Ver.1.3 Mod start
--    gn_hot_warn_qty := gn_inventory_quantity_sum - ln_sales_total_qty;
    gn_hot_warn_qty := column_rec.inventory_quantity - ln_sales_total_qty;
-- 2009/04/16 K.Kiriu Ver.1.3 Mod end
--
-- 2009/07/15 Ver.1.5 Mod Start
    IF ( gn_hot_warn_qty < 0 ) THEN
      gn_hot_warn_qty := 0;
    END IF;
-- 2009/07/15 Ver.1.5 Mod End
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN column_change_data_expt THEN
      gn_hot_warn_qty := 0;
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN hctype_change_data_expt THEN
      gn_hot_warn_qty := 0;
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
  END proc_hot_warn;
--
  /**********************************************************************************
   * Procedure Name   : proc_deli_l_file_out
   * Description      : A-13�D�[�i���я�񖾍׃t�@�C���o��
   ***********************************************************************************/
  PROCEDURE proc_deli_l_file_out(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_deli_l_file_out'; -- �v���O������
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
  --�ҏW
-- 2009/07/15 Ver.1.5 Mod Start
--    SELECT                  cv_quot || main_rec.account_number             || cv_quot --�ڋq�R�[�h 
--           || cv_delimit || cv_quot || column_rec.column_no                || cv_quot --�R����No        A-5�Œ��o�����R����No
--           || cv_delimit || TO_CHAR(gn_monthly_sales)                                 --���̐��i�\���p�jA-9�Œ��o�������̐�
--           || cv_delimit || TO_CHAR(gn_monthly_sales)                                 --���̐�          A-9�Œ��o�������̐�
--           || cv_delimit || TO_CHAR(gn_sales_days)                                    --�̔�����        A-10�Œ��o�����̔�����
--           || cv_delimit || TO_CHAR(gn_sales_days)                                    --�����        A-10�Œ��o�����̔�����
---- 2009/04/16 K.Kiriu Ver.1.3 Mod start
----           || cv_delimit || TO_CHAR(NVL(gn_inventory_quantity_sum,0))                 --��݌ɐ�      A-9�Œ��o������݌ɐ�
----           || cv_delimit || TO_CHAR(NVL(gn_hot_warn_qty,0))                           --�z�b�g�x���c��  A-11�Œ��o�����z�b�g�x���c����ݒ�B
--           || cv_delimit || SUBSTRB(TO_CHAR(NVL(gn_inventory_quantity_sum,0)), 1, 3)  --��݌ɐ�      A-9�Œ��o������݌ɐ�(3���ȏ�̏ꍇ�͐擪3��)
--           || cv_delimit || SUBSTRB(TO_CHAR(NVL(gn_hot_warn_qty,0)), 1, 2)            --�z�b�g�x���c��  A-11�Œ��o�����z�b�g�x���c����ݒ�B(2���ȏ�̏ꍇ�͐擪2��)
--                                                                                                        --H/C��C�i�R�[���h�j�̏ꍇ��0��ݒ�
---- 2009/04/16 K.Kiriu Ver.1.3 Mod end
--           || cv_delimit || TO_CHAR(NVL(gn_sales_qty_1 ,0))                           --�O�񔄏㐔      A-6�Œ��o����1���ڂ̔��㐔
--           || cv_delimit || TO_CHAR(NVL(gn_sales_qty_2 ,0))                           --�O�X�񔄏㐔    A-6�Œ��o����2���ڂ̔��㐔
--           || cv_delimit || TO_CHAR(NVL(gn_sales_qty_3 ,0))                           --�O�X�O�񔄏㐔  A-6�Œ��o����3���ڂ̔��㐔
--           || cv_delimit || TO_CHAR(NVL(gn_replacement_rate,0))                       --��[��          A-12�Œ��o������[��
--    INTO gv_deli_l_file_data
--    FROM DUAL
--    ;
    SELECT             cv_quot || gt_deli_l_tab(gn_deli_l_cnt).account_number || cv_quot --�ڋq�R�[�h      A-13�̌ڋq�R�[�h
      || cv_delimit || cv_quot || gt_deli_l_tab(gn_deli_l_cnt).column_no      || cv_quot --�R����No        A-13�̃R����No
      || cv_delimit || TO_CHAR(gt_deli_l_tab(gn_deli_l_cnt).monthly_sales)               --���̐��i�\���p�jA-13�̌��̐�
      || cv_delimit || TO_CHAR(gt_deli_l_tab(gn_deli_l_cnt).monthly_sales)               --���̐�          A-13�̌��̐�
      || cv_delimit || TO_CHAR(gt_deli_l_tab(gn_deli_l_cnt).sales_days)                  --�̔�����        A-13�̔̔�����
      || cv_delimit || TO_CHAR(gt_deli_l_tab(gn_deli_l_cnt).sales_days)                  --�����        A-13�̔̔�����
      || cv_delimit || SUBSTRB(TO_CHAR(NVL(gt_deli_l_tab(gn_deli_l_cnt).inventory_quantity_sum,0)), 1, 3)
                                                                                         --��݌ɐ�      A-13�̊�݌ɐ�
                                                                                         --                �E3���ȏ�̏ꍇ�͐擪3��
      || cv_delimit || SUBSTRB(TO_CHAR(NVL(gt_deli_l_tab(gn_deli_l_cnt).hot_warn_qty,0)), 1, 2)
                                                                                         --�z�b�g�x���c��  A-13�̃z�b�g�x���c��
                                                                                         --                �E2���ȏ�̏ꍇ�͐擪2��
                                                                                         --                �EH/C��C�i�R�[���h�j�̏ꍇ��0��ݒ�
      || cv_delimit || TO_CHAR(NVL(gt_deli_l_tab(gn_deli_l_cnt).sales_qty_1 ,0))         --�O�񔄏㐔      A-13��1���ڂ̔��㐔
      || cv_delimit || TO_CHAR(NVL(gt_deli_l_tab(gn_deli_l_cnt).sales_qty_2 ,0))         --�O�X�񔄏㐔    A-13��2���ڂ̔��㐔
      || cv_delimit || TO_CHAR(NVL(gt_deli_l_tab(gn_deli_l_cnt).sales_qty_3 ,0))         --�O�X�O�񔄏㐔  A-13��3���ڂ̔��㐔
      || cv_delimit || TO_CHAR(NVL(gt_deli_l_tab(gn_deli_l_cnt).replacement_rate,0))     --��[��          A-13�̕�[��
    INTO gv_deli_l_file_data
    FROM DUAL
    ;
-- 2009/07/15 Ver.1.5 Mod End

  --�t�@�C���o��
    UTL_FILE.PUT_LINE(gt_deli_l_handle
                     ,gv_deli_l_file_data
                     );
 
  
  --�ϐ�������
  gn_monthly_sales           := NULL;
  gn_sales_days              := NULL;
  gn_inventory_quantity_sum  := NULL;
  gn_hot_warn_qty            := NULL;
  gn_sales_qty_1             := NULL;
  gn_sales_qty_2             := NULL;
  gn_sales_qty_3             := NULL;
  gn_replacement_rate        := NULL;
--
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
  END proc_deli_l_file_out;
--
  /**********************************************************************************
   * Procedure Name   : proc_deli_h_file_out
   * Description      : A-15�D�[�i���я��w�b�_�t�@�C���o��
   ***********************************************************************************/
  PROCEDURE proc_deli_h_file_out(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_deli_h_file_out'; -- �v���O������
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

  --�ҏW
    SELECT                  cv_quot || main_rec.account_number || cv_quot --�ڋq�R�[�h
           || cv_delimit ||  TO_CHAR(gd_dlv_date_1,'MMDD')               --�O��[�i���i�l�l�c�c�j
           || cv_delimit ||  TO_CHAR(gd_dlv_date_2,'MMDD')               --�O�X��[�i��
           || cv_delimit ||  TO_CHAR(gd_dlv_date_3,'MMDD')               --�O�X�O��[�i��
           || cv_delimit ||  gv_visit_time                               --�O��K�⎞��
           || cv_delimit ||  TO_CHAR(gn_last_visit_days)                 --�O��K�����
           || cv_delimit ||  TO_CHAR(NVL(gn_sales_qty_sum_1,0))          --�O��[�i����
           || cv_delimit ||  TO_CHAR(NVL(gn_sales_qty_sum_2,0))          --�O�X��[�i����
           || cv_delimit ||  TO_CHAR(NVL(gn_sales_qty_sum_3,0))          --�O�X�O��[�i����
           || cv_delimit ||  TO_CHAR(NVL(gn_total_amount_1 ,0))          --�O��[�i���z
           || cv_delimit ||  TO_CHAR(NVL(gn_total_amount_2 ,0))          --�O�X��[�i���z
           || cv_delimit ||  TO_CHAR(NVL(gn_total_amount_3 ,0))          --�O�X�O��[�i���z
           || cv_delimit || cv_quot ||TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS') || cv_quot    --�X�V����
    INTO gv_deli_h_file_data
    FROM DUAL
    ;

  --�t�@�C���o��
    UTL_FILE.PUT_LINE(gt_deli_h_handle
                     ,gv_deli_h_file_data
                     );

  --�ϐ�������
    --���㐔
  gd_dlv_date_1      := NULL;
  gd_dlv_date_2      := NULL;
  gd_dlv_date_3      := NULL;
  gv_visit_time      := NULL;
  gn_last_visit_days := 0;
  gn_sales_qty_sum_1 := 0;
  gn_sales_qty_sum_2 := 0;
  gn_sales_qty_sum_3 := 0;
  gn_total_amount_1  := 0;
  gn_total_amount_2  := 0;
  gn_total_amount_3  := 0;
  
--
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
  END proc_deli_h_file_out;
--

  /**********************************************************************************
   * Procedure Name   : proc_main_loop�i���[�v���j
   * Description      : A-2�D�ڋq�}�X�^�f�[�^���o
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
    tran_in_expt      EXCEPTION;
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lv_message_code          VARCHAR2(20);
    ln_header_cnt            NUMBER;
    ln_column_cnt            NUMBER;
    ln_line_count            NUMBER;
-- 2009/07/15 Ver.1.5 Add Start
    ln_deli_l_cnt            NUMBER;
-- 2009/07/15 Ver.1.5 Add End
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
    FOR main_rec_d IN main_cur LOOP 
      BEGIN
        main_rec := main_rec_d;
        gn_main_loop_cnt := gn_main_loop_cnt + 1;
        
        
-- 2009/07/15 Ver.1.5 Add Start
        --�ϐ�������
          --���㐔
        gv_visit_time      := NULL;
        gn_last_visit_days := 0;
        gn_sales_qty_sum_1 := 0;
        gn_sales_qty_sum_2 := 0;
        gn_sales_qty_sum_3 := 0;
        gn_total_amount_1  := 0;
        gn_total_amount_2  := 0;
        gn_total_amount_3  := 0;
-- 2009/07/15 Ver.1.5 Add End
        ln_header_cnt := 0;
        gd_dlv_date_1 := NULL;
        gd_dlv_date_2 := NULL;
        gd_dlv_date_3 := NULL;
        <<loop_5>>
        FOR header_rec2 IN header_cur LOOP
          ln_header_cnt := ln_header_cnt + 1;
          IF    ln_header_cnt = 1 THEN
            gd_dlv_date_1 := header_rec2.dlv_date;
          ELSIF ln_header_cnt = 2 THEN
            gd_dlv_date_2 := header_rec2.dlv_date;
          ELSIF ln_header_cnt = 3 THEN
            gd_dlv_date_3 := header_rec2.dlv_date;
          END IF;
        END LOOP loop_5;

        -- ==================================================
        --A-3�D�x���_�[�i���я��w�b�_�e�[�u���f�[�^���o
        -- ==================================================
        ln_header_cnt := 0;
-- 2009/07/15 Ver.1.5 Add Start
        ln_deli_l_cnt := 0;
-- 2009/07/15 Ver.1.5 Add End
        <<loop_2>>
        FOR header_rec_d IN header_cur LOOP
          header_rec := header_rec_d;
          ln_header_cnt := ln_header_cnt + 1;
          IF ln_header_cnt = 1 THEN
          gn_target_cnt := gn_target_cnt + 1;
            -- ==================================================
            --A-4�D 臒l���o
            -- ==================================================
            proc_threshold(
                                 lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
                                ,lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
                                ,lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
                                );
            IF (lv_retcode <> cv_status_normal) THEN
              RAISE tran_in_expt;
            END IF;
-- 2009/07/24 Add Ver.1.6 Start
            -- 臒l��NULL�̏ꍇ�A�Y�����R�[�h���X�L�b�v
            IF ( gv_hot_stock_days IS NULL ) THEN
              RAISE tran_in_expt;
            END IF;
-- 2009/07/24 Add Ver.1.6 End
            -- ==================================================
            --A-5�D�x���_�R�����}�X�^�f�[�^���o
            -- ==================================================
            ln_column_cnt := 0;
            <<loop_3>>
            FOR column_rec_d IN column_cur LOOP
-- 2009/07/15 Ver.1.5 Mod End
              --�[�i���я�񖾍׊֘A�̕ϐ��̏�����
              gn_monthly_sales           := NULL;
              gn_sales_days              := NULL;
              gn_inventory_quantity_sum  := NULL;
              gn_hot_warn_qty            := NULL;
              gn_sales_qty_1             := NULL;
              gn_sales_qty_2             := NULL;
              gn_sales_qty_3             := NULL;
              gn_replacement_rate        := NULL;
-- 2009/07/15 Ver.1.5 Mod End
              column_rec := column_rec_d;
              ln_column_cnt := ln_column_cnt + 1;
              -- ==================================================
              --A-6�D�x���_�[�i���я�񖾍׃e�[�u���f�[�^���o
              -- ==================================================
              ln_line_count := 0;                   --A-8�D���㐔�T�}�������p�@������
              <<loop_4>>
              FOR line_rec_d IN line_cur LOOP
                line_rec := line_rec_d;
                
                gn_tran_count := gn_tran_count + 1;
                ln_line_count := ln_line_count + 1; --A-8�D���㐔�T�}�������p�@�J�E���g
                -- ==================================================
                --A-7�D�R�����̍ŐV�i�ڒ��o
                -- ==================================================
                proc_new_item_select(
                                     lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
                                    ,lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
                                    ,lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
                                    );
                IF (lv_retcode <> cv_status_normal) THEN
                  RAISE tran_in_expt;
                END IF;
        
                -- ==================================================
                --A-8�D���㐔�T�}�� (�Ɩ��ה��㐔�̐ݒ�)
                -- ==================================================
                IF    ln_line_count = 1 THEN
                  gn_sales_qty_sum_1 := gn_sales_qty_sum_1 + line_rec.sum_sales_qty;
                  gn_sales_qty_1     := line_rec.sum_sales_qty;
                ELSIF ln_line_count = 2 THEN
                  gn_sales_qty_sum_2 := gn_sales_qty_sum_2 + line_rec.sum_sales_qty;
                  gn_sales_qty_2     := line_rec.sum_sales_qty;                  
                ELSIF ln_line_count = 3 THEN
                  gn_sales_qty_sum_3 := gn_sales_qty_sum_3 + line_rec.sum_sales_qty;
                  gn_sales_qty_3     := line_rec.sum_sales_qty;                  
                END IF;
                
              END LOOP loop_4;
              
              IF ln_line_count = 0 THEN
                gv_column_no := column_rec.column_no;
                RAISE line_no_data_expt;
              END IF;
              
        -- ==================================================
        --A-9�D���̐��A��݌ɐ����o
        -- ==================================================
              proc_month_qty(
                                   lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
                                  ,lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
                                  ,lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
                                  );
              IF (lv_retcode <> cv_status_normal) THEN
                RAISE tran_in_expt;
              END IF;
               
        -- ==================================================
        --A-10�D�̔��������o
        -- ==================================================
              proc_sales_days(
                                   lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
                                  ,lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
                                  ,lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
                                  );
              IF (lv_retcode <> cv_status_normal) THEN
                RAISE tran_in_expt;
              END IF;
              
        -- ==================================================
        --A-11�D�z�b�g�x���c�����o
        -- ==================================================
              IF gv_hot_cold_type = cv_hot_type THEN
                proc_hot_warn(
                                     lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
                                    ,lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
                                    ,lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
                                    );
                IF (lv_retcode <> cv_status_normal) THEN
                  RAISE tran_in_expt;
                END IF;
-- 2009/07/15 Ver.1.5 Mod Start
              ELSE
                gn_hot_warn_qty := 0;
-- 2009/07/15 Ver.1.5 Mod End
              END IF;
              
        -- ==================================================
        --A-12�D��[�����o
        -- ==================================================
        --��[���@���@A-9�Œ��o�������̐��@���@A-9�Œ��o������݌ɐ��@�~�@100(�[���؎́j
              IF gn_inventory_quantity_sum > 0 THEN
                gn_replacement_rate := TRUNC(gn_monthly_sales / gn_inventory_quantity_sum * 100);
              END IF;
        
-- 2009/07/15 Ver.1.5 Mod Start
--        -- ==================================================
--        --A-13.  �[�i���я�񖾍׃t�@�C���o��
--        -- ==================================================
--              proc_deli_l_file_out(
--                                   lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
--                                  ,lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
--                                  ,lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--                                  );
--              IF (lv_retcode <> cv_status_normal) THEN
--                RAISE tran_in_expt;
--              END IF;
        -- ==================================================
        --���׏o�͗p�ϐ��̊i�[
        -- ==================================================
              ln_deli_l_cnt := ln_deli_l_cnt + 1;
              gt_deli_l_tab(ln_deli_l_cnt).account_number         := main_rec.account_number;   -- �ڋq�R�[�h
              gt_deli_l_tab(ln_deli_l_cnt).column_no              := column_rec.column_no;      -- A-5�Œ��o�����R����No
              gt_deli_l_tab(ln_deli_l_cnt).monthly_sales          := gn_monthly_sales;          -- A-9�Œ��o�������̐�
              gt_deli_l_tab(ln_deli_l_cnt).sales_days             := gn_sales_days;             -- A-10�Œ��o�����̔�����
              gt_deli_l_tab(ln_deli_l_cnt).inventory_quantity_sum := gn_inventory_quantity_sum; -- A-9�Œ��o������݌ɐ�
              gt_deli_l_tab(ln_deli_l_cnt).hot_warn_qty           := gn_hot_warn_qty;           -- A-11�Œ��o�����z�b�g�x���c��
              gt_deli_l_tab(ln_deli_l_cnt).sales_qty_1            := gn_sales_qty_1;            -- A-6�Œ��o����1���ڂ̔��㐔
              gt_deli_l_tab(ln_deli_l_cnt).sales_qty_2            := gn_sales_qty_2;            -- A-6�Œ��o����2���ڂ̔��㐔
              gt_deli_l_tab(ln_deli_l_cnt).sales_qty_3            := gn_sales_qty_3;            -- A-6�Œ��o����3���ڂ̔��㐔
              gt_deli_l_tab(ln_deli_l_cnt).replacement_rate       := gn_replacement_rate;       -- A-12�Œ��o������[��
-- 2009/07/15 Ver.1.5 Mod End

            END LOOP loop_3;
            
            IF ln_column_cnt = 0 THEN
              RAISE column_no_data_expt;
            END IF;
            
        -- ==================================================
        --�w�b�_�o�͗p�ϐ��̊i�[
        -- ==================================================
            gd_dlv_date_1     := header_rec.dlv_date;     --A-3�Œ��o����1���ڂ̔[�i��
            gn_total_amount_1 := header_rec.total_amount; --A-3�Œ��o����1���ڂ̍��v���z
            gv_visit_time     := header_rec.visit_time;   --�O��K�⎞��
          ELSIF ln_header_cnt = 2 THEN --�w�b�_2����
            gd_dlv_date_2     := header_rec.dlv_date;         --A-3�Œ��o����2���ڂ̔[�i��
            gn_total_amount_2 := header_rec.total_amount; --A-3�Œ��o����2���ڂ̍��v���z
          ELSIF ln_header_cnt = 3 THEN --�w�b�_3����
            gd_dlv_date_3     := header_rec.dlv_date;         --A-3�Œ��o����3���ڂ̔[�i��
            gn_total_amount_3 := header_rec.total_amount; --A-3�Œ��o����3���ڂ̍��v���z
          END IF;
          
        END LOOP loop_2;
        IF ln_header_cnt > 0 THEN
-- 2009/07/15 Ver.1.5 Add Start
--
          -- ==================================================
          --A-13.  �[�i���я�񖾍׃t�@�C���o��
          -- ==================================================
          << output_deli_l_loop >>
          FOR ln_deli_l_idx in 1..ln_deli_l_cnt LOOP
            gn_deli_l_cnt := ln_deli_l_idx;
            proc_deli_l_file_out(
                                 lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
                                ,lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
                                ,lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
                                );
            IF (lv_retcode <> cv_status_normal) THEN
              RAISE tran_in_expt;
            END IF;
          END LOOP output_deli_l_loop;
-- 2009/07/15 Ver.1.5 Add End
        
          -- ==================================================
          --A-14�D�O��K��������o
          -- ==================================================
          --���������Ŏ擾��������@�\�@A-3�Œ��o�����i�ڋq���Łj1���̔[�i��
          gn_last_visit_days := gd_standard_date - gd_dlv_date_1;
          
          -- ==================================================
          --A-15�D �[�i���я��w�b�_�t�@�C���o��
          -- ==================================================
          proc_deli_h_file_out(
                               lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
                              ,lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
                              ,lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
                              );
          IF (lv_retcode <> cv_status_normal) THEN
            RAISE tran_in_expt;
          ELSE
            gn_normal_cnt := gn_normal_cnt + 1;
          END IF;
        END IF;
        
      EXCEPTION
        WHEN column_no_data_expt THEN
          lv_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;

          xxcos_common_pkg.makeup_key_info(ov_errbuf      => lv_errbuf                  --�G���[�E���b�Z�[�W
                                          ,ov_retcode     => lv_retcode                 --���^�[���E�R�[�h
                                          ,ov_errmsg      => lv_errmsg                  --���[�U�[�E�G���[�E���b�Z�[�W
                                          ,ov_key_info    => gv_key_info                --�L�[���
                                          ,iv_item_name1  => gv_msg_tkn_cust_account_id --���ږ���1
                                          ,iv_data_value1 => main_rec.cust_account_id   --�f�[�^�̒l1
                                          );
          
          ov_errmsg := xxccp_common_pkg.get_msg(cv_application
                                              , cv_msg_select_err
                                              , cv_tkn_table_name
                                              , gv_msg_tkn_vd_column_mst
                                              , cv_tkn_key_data
                                              , gv_key_info
                                              );
          FND_FILE.PUT_LINE(
                            which  => FND_FILE.OUTPUT
                           ,buff   => ov_errmsg --�G���[���b�Z�[�W
                           ); 
          FND_FILE.PUT_LINE(
                            which  => FND_FILE.LOG
                           ,buff   => lv_errbuf --�G���[���b�Z�[�W
                           );
          ov_errmsg := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg;
          FND_FILE.PUT_LINE(
                            which  => FND_FILE.LOG
                           ,buff   => ov_errmsg --�G���[���b�Z�[�W
                           );
          ov_retcode := cv_status_warn;
          gn_warn_cnt := gn_warn_cnt + 1;
        WHEN line_no_data_expt THEN
          lv_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;

          xxcos_common_pkg.makeup_key_info(ov_errbuf      => lv_errbuf                  --�G���[�E���b�Z�[�W
                                          ,ov_retcode     => lv_retcode                 --���^�[���E�R�[�h
                                          ,ov_errmsg      => lv_errmsg                  --���[�U�[�E�G���[�E���b�Z�[�W
                                          ,ov_key_info    => gv_key_info                --�L�[���
                                          ,iv_item_name1  => gv_msg_tkn_cust_code       --���ږ���1
                                          ,iv_data_value1 => main_rec.account_number    --�f�[�^�̒l1
                                          ,iv_item_name2  => gv_msg_tkn_column_no       --���ږ���2
                                          ,iv_data_value2 => gv_column_no               --�f�[�^�̒l2
                                          ,iv_item_name3  => gv_msg_tkn_dlv_date        --���ږ���3
                                          ,iv_data_value3 => TO_CHAR(gd_dlv_date_1,'YYYYMMDD')  || ',' ||
                                                             TO_CHAR(gd_dlv_date_2,'YYYYMMDD')  || ',' ||
                                                             TO_CHAR(gd_dlv_date_3,'YYYYMMDD')     --�f�[�^�̒l3                                                                                    
                                          );
          
          ov_errmsg := xxccp_common_pkg.get_msg(cv_application
                                              , cv_msg_select_err
                                              , cv_tkn_table_name
                                              , gv_msg_tkn_vd_deliv_l
                                              , cv_tkn_key_data
                                              , gv_key_info
                                              );
          FND_FILE.PUT_LINE(
                            which  => FND_FILE.OUTPUT
                           ,buff   => ov_errmsg --�G���[���b�Z�[�W
                           ); 
          FND_FILE.PUT_LINE(
                            which  => FND_FILE.LOG
                           ,buff   => lv_errbuf --�G���[���b�Z�[�W
                           );
          ov_errmsg := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg;
          FND_FILE.PUT_LINE(
                            which  => FND_FILE.LOG
                           ,buff   => ov_errmsg --�G���[���b�Z�[�W
                           );
          ov_retcode := cv_status_warn;
          gn_warn_cnt := gn_warn_cnt + 1;
        WHEN tran_in_expt THEN
          ov_retcode := cv_status_warn;
          gn_warn_cnt := gn_warn_cnt + 1;
      END;
    END LOOP main_loop;

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
    -- A-2�D�ڋq�}�X�^�f�[�^���o
    -- ===============================
    proc_main_loop(
       lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    ov_retcode := lv_retcode;
    IF (lv_retcode = cv_status_error) THEN
      --(�G���[����)
      gn_error_cnt := gn_error_cnt + 1;
      RAISE global_process_expt;
    END IF;
    
    --�o�͌�����0���̏ꍇ�͌x���Ƃ���B
    IF gn_normal_cnt = 0 THEN
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => gv_msg_no_data_tran
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => gv_msg_no_data_tran
      );      
      ov_retcode := cv_status_warn;
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
    IF lv_retcode = cv_status_normal THEN
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
    -- A-15�D�I������
    -- ===============================================
    --�t�@�C���̃N���[�Y
    UTL_FILE.FCLOSE(gt_deli_h_handle);
    UTL_FILE.FCLOSE(gt_deli_l_handle);
    
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
END XXCOS003A04C;
/
