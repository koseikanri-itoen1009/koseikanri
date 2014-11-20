CREATE OR REPLACE PACKAGE BODY XXCOI003A15C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOI003A15C(body)
 * Description      : �ۊǏꏊ�]������f�[�^OIF�X�V(��݌�)
 * MD.050           : �ۊǏꏊ�]������f�[�^OIF�X�V(��݌�) MD050_COI_003_A15
 * Version          : 1.2
 *
 * Program List
 * ---------------------------  ----------------------------------------------------------
 *  Name                         Description
 * ---------------------------  ----------------------------------------------------------
 *  init                         ��������                                    (A-1)
 *  chk_vd_column_mst_info       ��݌ɕύX�f�[�^�Ó����`�F�b�N            (A-3)
 *  ins_tmp_svd_tran_date        ��݌ɕύX���[�N�e�[�u���̒ǉ�            (A-4)
 *  upd_xxcoi_mst_vd_column      VD�R�����}�X�^�̍X�V                        (A-5)
 *  upd_hht_inv_transactions     HHT���o�Ɉꎞ�\�̏����X�e�[�^�X�X�V         (A-6)
 *  ins_standard_inv_err_list    ��݌ɕύX�f�[�^�̃G���[���X�g�\�ǉ�      (A-7)
 *  del_hht_inv_transactions     HHT���o�Ɉꎞ�\�̃G���[���R�[�h�폜         (A-8)
 *  ins_mtl_transactions_if      ��݌ɕύX�f�[�^�̎��ގ��OIF�ǉ�         (A-9)
 *  submain                      ���C�������v���V�[�W��                      (A-2)
 *  main                         �R���J�����g���s�t�@�C���o�^�v���V�[�W��    (A-10)
 *
 * Change Record
 * ------------- ----- ---------------- --------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- --------------------------------------------------
 *  2009/01/14    1.0   SCS H.Wada       main�V�K�쐬
 *  2009/02/19    1.1   SCS H.Wada       ��Q�ԍ� #015
 *  2009/04/06    1.2   SCS T.Nakamura   ��Q�ԍ� T1_0004
 *                                         VD�R�����}�X�^�̍X�V�����̏C��
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
  lock_expt            EXCEPTION;                           -- ���b�N�擾�G���[
  chk_err_expt         EXCEPTION;                           -- �Ó����`�F�b�N�G���[
  PRAGMA               EXCEPTION_INIT( lock_expt, -54 );    -- ���b�N�G���[��O
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name          CONSTANT VARCHAR2(100) := 'XXCOI003A15C'; -- �p�b�P�[�W��
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  -- �A�v���P�[�V�����Z�k��
  gv_msg_kbn_ccp       CONSTANT VARCHAR2(5)   := 'XXCCP';
  gv_msg_kbn_coi       CONSTANT VARCHAR2(5)   := 'XXCOI';
--
  -- ���b�Z�[�W�ԍ�
  gv_msg_ccp_90008     CONSTANT VARCHAR2(16)  := 'APP-XXCCP1-90008'; -- �R���J�����g���̓p�����[�^�Ȃ����b�Z�[�W
  gv_msg_coi_00005     CONSTANT VARCHAR2(16)  := 'APP-XXCOI1-00005'; -- �݌ɑg�D�R�[�h�擾�G���[���b�Z�[�W
  gv_msg_coi_00006     CONSTANT VARCHAR2(16)  := 'APP-XXCOI1-00006'; -- �݌ɑg�DID�擾�G���[���b�Z�[�W
  gv_msg_coi_00008     CONSTANT VARCHAR2(16)  := 'APP-XXCOI1-00008'; -- �Ώۃf�[�^�������b�Z�[�W
  gv_msg_coi_00011     CONSTANT VARCHAR2(16)  := 'APP-XXCOI1-00011'; -- �Ɩ����t�擾�G���[���b�Z�[�W
  gv_msg_coi_00012     CONSTANT VARCHAR2(16)  := 'APP-XXCOI1-00012'; -- ����^�C�vID�擾�G���[���b�Z�[�W
  gv_msg_coi_10027     CONSTANT VARCHAR2(16)  := 'APP-XXCOI1-10027'; -- �f�[�^���̎擾�G���[���b�Z�[�W
  gv_msg_coi_10055     CONSTANT VARCHAR2(16)  := 'APP-XXCOI1-10055'; -- ���b�N�G���[���b�Z�[�W(HHT���o�Ɉꎞ�\)
  gv_msg_coi_10056     CONSTANT VARCHAR2(16)  := 'APP-XXCOI1-10056'; -- ��݌ɍX�V�i�i�ڕs��v�j�G���[
  gv_msg_coi_10057     CONSTANT VARCHAR2(16)  := 'APP-XXCOI1-10057'; -- ��݌ɍX�V�i��݌ɕs�����j�G���[
  gv_msg_coi_10058     CONSTANT VARCHAR2(16)  := 'APP-XXCOI1-10058'; -- ��݌ɍX�V�i�i�ځE��݌ɍX�V�s�j�G���[
  gv_msg_coi_10059     CONSTANT VARCHAR2(16)  := 'APP-XXCOI1-10059'; -- ��݌ɍX�V�i�P���s�����j�G���[
  gv_msg_coi_10062     CONSTANT VARCHAR2(16)  := 'APP-XXCOI1-10062'; -- ��݌ɍX�V�i�O�������s��v�j�G���[
  gv_msg_coi_10241     CONSTANT VARCHAR2(16)  := 'APP-XXCOI1-10241'; -- ����^�C�v���擾�G���[���b�Z�[�W
  gv_msg_coi_10024     CONSTANT VARCHAR2(16)  := 'APP-XXCOI1-10024'; -- ���b�N�G���[���b�Z�[�W(VD�R�����}�X�^)
  gv_msg_coi_10335     CONSTANT VARCHAR2(16)  := 'APP-XXCOI1-10335'; -- ����쐬�������b�Z�[�W
  gv_msg_coi_10342     CONSTANT VARCHAR2(16)  := 'APP-XXCOI1-10342'; -- HHT���o�Ƀf�[�^�pKEY���
  gv_msg_coi_10353     CONSTANT VARCHAR2(16)  := 'APP-XXCOI1-10353'; -- ��݌ɍX�V�i�P�����ݒ�G���[�j�G���[
  gv_msg_coi_10354     CONSTANT VARCHAR2(16)  := 'APP-XXCOI1-10354'; -- ��݌ɍX�V�iH/C���ݒ�G���[�j�G���[
  gv_msg_coi_10359     CONSTANT VARCHAR2(16)  := 'APP-XXCOI1-10359'; -- �Ώۃf�[�^�������b�Z�[�W�iVD�R�����}�X�^�j
-- Add 2009/02/18 #015 ��
  gv_msg_coi_10371     CONSTANT VARCHAR2(16)  := 'APP-XXCOI1-10371'; -- ��݌ɍX�V�i��݌ɏ���l�j�G���[
  gv_mst_coi_10372     CONSTANT VARCHAR2(16)  := 'APP-XXCOI1-10372'; -- ��݌ɍX�V�i��݌ɏ����_�j�G���[
-- Add 2009/02/18 #015 ��
--
  -- �g�[�N��
  gv_tkn_pro_tok       CONSTANT VARCHAR2(7)   := 'PRO_TOK';              -- �v���t�@�C����
  gv_tkn_column_no     CONSTANT VARCHAR2(9)   := 'COLUMN_NO';            -- �R������
  gv_tkn_item_code     CONSTANT VARCHAR2(9)   := 'ITEM_CODE';            -- �i�ڃR�[�h
  gv_tkn_base_code     CONSTANT VARCHAR2(9)   := 'BASE_CODE';            -- ���_�R�[�h
  gv_tkn_dept_flag     CONSTANT VARCHAR2(9)   := 'DEPT_FLAG';            -- �S�ݓX�t���O
-- Add 2009/02/18 #015 ��
  gv_tkn_total_qnt     CONSTANT VARCHAR2(9)   := 'TOTAL_QNT';            -- ������
-- Add 2009/02/18 #015 ��
  gv_tkn_unit_price    CONSTANT VARCHAR2(10)  := 'UNIT_PRICE';           -- �P��
  gv_tkn_invoice_no    CONSTANT VARCHAR2(10)  := 'INVOICE_NO';           -- �`�[��
  gv_tkn_lookup_type   CONSTANT VARCHAR2(11)  := 'LOOKUP_TYPE';          -- �Q�ƃ^�C�v
  gv_tkn_lookup_code   CONSTANT VARCHAR2(11)  := 'LOOKUP_CODE';          -- �Q�ƃR�[�h
  gv_tkn_record_type   CONSTANT VARCHAR2(11)  := 'RECORD_TYPE';          -- ���R�[�h���
  gv_tkn_org_code_tok  CONSTANT VARCHAR2(12)  := 'ORG_CODE_TOK';         -- �݌ɑg�D�R�[�h
  gv_tkn_invoice_type  CONSTANT VARCHAR2(12)  := 'INVOICE_TYPE';         -- �`�[�敪
  gv_tkn_tran_type_tok CONSTANT VARCHAR2(20)  := 'TRANSACTION_TYPE_TOK'; -- ����^�C�v��
--
  gv_pro_div_chg_inv   CONSTANT VARCHAR2(1)   := '1';                    -- ���o�ɃW���[�i�������敪(��݌ɕύX)
  gn_xhit_status_0     CONSTANT NUMBER        := 0;                      -- HHT���o�Ɉꎞ�\�X�e�[�^�X 0(������)
  gv_vd_get_lock       CONSTANT VARCHAR2(1)   := 'Y';                    -- VD�R�����}�X�^���b�N�擾����
  gv_vd_miss_lock      CONSTANT VARCHAR2(1)   := 'N';                    -- VD�R�����}�X�^���b�N�擾���s
--
  -- VD�R�����}�X�^��񃌃R�[�h�^
  TYPE gr_mst_vd_column_type IS RECORD(
    row_id        ROWID                                                  -- 1.ROWID
   ,item_id       xxcoi_mst_vd_column.item_id%TYPE                       -- 2.�����i��ID
   ,inv_qnt       xxcoi_mst_vd_column.inventory_quantity%TYPE            -- 3.������݌ɐ�
   ,price         xxcoi_mst_vd_column.price%TYPE                         -- 4.�����P��
   ,hot_cold      xxcoi_mst_vd_column.hot_cold%TYPE                      -- 5.����H/C
   ,lm_item_id    xxcoi_mst_vd_column.last_month_item_id%TYPE            -- 6.�O���i��ID
   ,lm_inv_qnt    xxcoi_mst_vd_column.last_month_inventory_quantity%TYPE -- 7.�O����݌ɐ�
   ,lm_price      xxcoi_mst_vd_column.last_month_price%TYPE              -- 8.�O���P��
   ,lm_hot_cold   xxcoi_mst_vd_column.last_month_hot_cold%TYPE           -- 9.�O��H/C
  );
--
  -- VD�R�����}�X�^���J�[�\�����R�[�h�^
  gr_mst_vd_column_rec   gr_mst_vd_column_type;
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gn_cre_tran_cnt      NUMBER;                                         -- ����쐬����
  gt_inv_org_id        mtl_parameters.organization_id%TYPE;            -- �݌ɑg�DID
  gv_hht_err_date_name VARCHAR2(30);                                   -- HHT�G���[���X�g�f�[�^����
  gd_process_date      DATE;                                           -- �Ɩ����t
  gt_tran_type_id      mtl_transaction_types.transaction_type_id%TYPE; -- ����^�C�vID
  gv_vd_is_lock_flg    VARCHAR2(1);                                    -- VD�R�����}�X�^���b�N�擾�L���t���O(�擾:Y,���擾:N)
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���J�[�\��
  -- ===============================
  -- ��݌ɕύX���o�J�[�\��
  CURSOR hht_inv_tran_cur
  IS
    SELECT xhit.rowid               AS row_id            --  1.ROWID
          ,xhit.inventory_item_id   AS item_id           --  2.�i��ID
          ,xhit.item_code           AS item_code         --  3.�i�ڃR�[�h
          ,xhit.total_quantity      AS total_qnt         --  4.������
          ,xhit.primary_uom_code    AS prim_uom_code     --  5.��P��
          ,xhit.invoice_date        AS invoice_date      --  6.�`�[���t
          ,xhit.outside_subinv_code AS out_inv_code      --  7.�o�ɑ��ۊǏꏊ
          ,xhit.inside_subinv_code  AS in_inv_code       --  8.���ɑ��ۊǏꏊ
          ,xhit.outside_code        AS outside_code      --  9.�o�ɑ��R�[�h
          ,xhit.inside_code         AS customer_code     -- 10.�ڋq�R�[�h
          ,xhit.invoice_no          AS invoice_no        -- 11.�`�[��
          ,xhit.column_no           AS column_no         -- 12.�R������
          ,xhit.unit_price          AS unit_price        -- 13.�P��
          ,xhit.hot_cold_div        AS hot_cold_div      -- 14.H/C
          ,xhit.employee_num        AS employee_num      -- 15.�c�ƈ��R�[�h
          ,xhit.base_code           AS base_code         -- 16.���_�R�[�h
          ,xhit.record_type         AS record_type       -- 17.���R�[�h���
          ,xhit.invoice_type        AS invoice_type      -- 18.�`�[�敪
          ,xhit.department_flag     AS department_flag   -- 19.�S�ݓX�t���O
    FROM   xxcoi_hht_inv_transactions  xhit              -- HHT���o�Ɉꎞ�\
    WHERE  xhit.status          = gn_xhit_status_0
    AND    xhit.hht_program_div = gv_pro_div_chg_inv
    ORDER BY xhit.interface_id                           -- 1.�C���^�[�t�F�[�XID
    FOR UPDATE NOWAIT;
--
  -- ��݌ɕύX���o�J�[�\�����R�[�h�^
  hht_inv_tran_rec hht_inv_tran_cur%ROWTYPE;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    ov_errbuf     OUT VARCHAR2      --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode    OUT VARCHAR2      --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    cv_prf_org_code     CONSTANT VARCHAR2(24) := 'XXCOI1_ORGANIZATION_CODE';     -- XXCOI:�݌ɑg�D�R�[�h
    cv_prf_hht_err_dt   CONSTANT VARCHAR2(24) := 'XXCOI1_HHT_ERR_DATA_NAME';     -- XXCOI:HHT�G���[���X�g�p���o�Ƀf�[�^��
    cv_lookup_type_tran CONSTANT VARCHAR2(28) := 'XXCOI1_TRANSACTION_TYPE_NAME'; -- �Q�ƃ^�C�v
    cv_lookup_code_80   CONSTANT VARCHAR2(2)  := '80';                           -- �Q�ƃR�[�h(��݌ɕύX)
--
    -- *** ���[�J���ϐ� ***
    lv_message          VARCHAR2(5000);                                   -- ���b�Z�[�W�o�͗p
    lt_inv_org_code     mtl_parameters.organization_code%TYPE;            -- �݌ɑg�D�R�[�h
    lt_tra_type_name    mtl_transaction_types.transaction_type_name%TYPE; -- ����^�C�v�� ��݌ɕύX
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ===================================
    -- �R���J�����g�v���O�������͍��ڏo��
    -- ===================================
    -- ���̓p�����[�^�������b�Z�[�W
    lv_message := xxccp_common_pkg.get_msg(
                    iv_application  => gv_msg_kbn_ccp
                   ,iv_name         => gv_msg_ccp_90008
                  );
    -- �t�@�C���ɏo��
    FND_FILE.PUT_LINE(
      which => FND_FILE.OUTPUT
     ,buff  => lv_message
    );
    -- ��s���t�@�C���ɏo��
    FND_FILE.PUT_LINE(
      which => FND_FILE.OUTPUT
     ,buff  => ''
    );
--
    -- ===================================
    -- WHO�J�����擾
    -- ===================================
    -- �Œ�O���[�o���萔�錾���ɂĎ擾�ς�
--
    -- ===================================
    -- �݌ɑg�DID�擾
    -- ===================================
    -- �݌ɑg�D�R�[�h�̎擾
    lt_inv_org_code := FND_PROFILE.VALUE(cv_prf_org_code);
    -- �݌ɑg�D�R�[�h��NULL�̏ꍇ
    IF (lt_inv_org_code IS NULL) THEN
      -- �݌ɑg�D�R�[�h�擾�G���[���b�Z�[�W
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => gv_msg_kbn_coi
                    ,iv_name         => gv_msg_coi_00005
                    ,iv_token_name1  => gv_tkn_pro_tok
                    ,iv_token_value1 => cv_prf_org_code);
      RAISE global_api_expt;
    END IF;
    -- �݌ɑg�DID�̎擾
    gt_inv_org_id := xxcoi_common_pkg.get_organization_id(
                       iv_organization_code => lt_inv_org_code);
--
    IF (gt_inv_org_id IS NULL) THEN
      -- �݌ɑg�DID�擾�G���[���b�Z�[�W
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => gv_msg_kbn_coi
                    ,iv_name         => gv_msg_coi_00006
                    ,iv_token_name1  => gv_tkn_org_code_tok
                    ,iv_token_value1 => lt_inv_org_code);
      RAISE global_api_expt;
    END IF;
--
    -- ====================================
    -- HHT�G���[���X�g���[�p �f�[�^���̎擾
    -- ====================================
    gv_hht_err_date_name := FND_PROFILE.VALUE(cv_prf_hht_err_dt);
--
    IF (gv_hht_err_date_name IS NULL) THEN
      -- �f�[�^���̎擾�G���[���b�Z�[�W
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => gv_msg_kbn_coi
                    ,iv_name         => gv_msg_coi_10027
                    ,iv_token_name1  => gv_tkn_pro_tok
                    ,iv_token_value1 => cv_prf_hht_err_dt);
      RAISE global_api_expt;
    END IF;
--
    -- ====================================
    -- �Ɩ����t�擾
    -- ====================================
    gd_process_date := xxccp_common_pkg2.get_process_date;
--
    IF (gd_process_date IS NULL) THEN
      --�Ɩ����t�擾�G���[���b�Z�[�W
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => gv_msg_kbn_coi
                    ,iv_name         => gv_msg_coi_00011);
      RAISE global_api_expt;
    END IF;
--
    -- ====================================
    -- ����^�C�v�擾
    -- ====================================
    -- ����^�C�v���̎擾
    lt_tra_type_name := xxcoi_common_pkg.get_meaning(
                          iv_lookup_type => cv_lookup_type_tran
                         ,iv_lookup_code => cv_lookup_code_80);
--
    IF (lt_tra_type_name IS NULL) THEN
      --����^�C�v���擾�G���[���b�Z�[�W
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => gv_msg_kbn_coi
                    ,iv_name         => gv_msg_coi_10241
                    ,iv_token_name1  => gv_tkn_lookup_type
                    ,iv_token_value1 => cv_lookup_type_tran
                    ,iv_token_name2  => gv_tkn_lookup_code
                    ,iv_token_value2 => cv_lookup_code_80);
      RAISE global_api_expt;
    END IF;
--
    -- ����^�C�vID�̎擾
    gt_tran_type_id := xxcoi_common_pkg.get_transaction_type_id(
                         iv_transaction_type_name => lt_tra_type_name);
    IF (gt_tran_type_id IS NULL) THEN
      --����^�C�vID�擾�G���[���b�Z�[�W
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => gv_msg_kbn_coi
                    ,iv_name         => gv_msg_coi_00012
                    ,iv_token_name1  => gv_tkn_tran_type_tok
                    ,iv_token_value1 => lt_tra_type_name);
      RAISE global_api_expt;
    END IF;
--
  EXCEPTION
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
  END init;
--
  /**********************************************************************************
   * Procedure Name   : chk_vd_column_mst_info
   * Description      : ��݌ɕύX�f�[�^�Ó����`�F�b�N(A-3)
   ***********************************************************************************/
  PROCEDURE chk_vd_column_mst_info(
    ov_errbuf     OUT VARCHAR2     --   �G���[�E���b�Z�[�W                  --# �Œ� #
   ,ov_retcode    OUT VARCHAR2     --   ���^�[���E�R�[�h                    --# �Œ� #
   ,ov_errmsg     OUT VARCHAR2)    --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_vd_column_mst_info'; -- �v���O������
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
    cn_dummy_item_price      CONSTANT NUMBER := -1;   -- �i��ID��r���̃_�~�[�l
--
    -- *** ���[�J���ϐ� ***
    lv_key_msg            VARCHAR2(1000);          -- HHT���o�Ƀf�[�^�pKEY���
    ln_disagreement_count NUMBER;                  -- �s��v����
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ���^�[���E�R�[�h�̏�����
    lv_retcode := cv_status_normal;
--
    -- =========================================
    -- VD�R�����}�X�^���̎擾
    -- =========================================
--
    -- VD�R�����}�X�^���b�N�擾�L���t���O��VD�R�����}�X�^���b�N�擾�����ɏ�����
    gv_vd_is_lock_flg := gv_vd_get_lock;
--
    BEGIN
      SELECT xmvc.rowid                         AS row_id      --  1.ROWID
            ,xmvc.item_id                       AS item_id     --  2.�����i��ID
            ,xmvc.inventory_quantity            AS inv_qnt     --  3.������݌ɐ�
            ,xmvc.price                         AS price       --  4.�����P��
            ,xmvc.hot_cold                      AS hot_cold    --  5.����H/C
            ,xmvc.last_month_item_id            AS lm_item_id  --  6.�O���i��ID
            ,xmvc.last_month_inventory_quantity AS lm_inv_qnt  --  7.�O����݌ɐ�
            ,xmvc.last_month_price              AS lm_price    --  8.�O���P��
            ,xmvc.last_month_hot_cold           AS lm_hot_cold --  9.�O��H/C
      INTO   gr_mst_vd_column_rec
      FROM   xxcoi_mst_vd_column                xmvc           -- VD�R�����}�X�^
            ,hz_cust_accounts                   hca            -- �ڋq�A�J�E���g
      WHERE  xmvc.customer_id   = hca.cust_account_id 
      AND    hca.account_number = hht_inv_tran_rec.customer_code
      AND    xmvc.column_no     = hht_inv_tran_rec.column_no
      FOR UPDATE NOWAIT;
    EXCEPTION
      -- �Ώۃf�[�^����
      WHEN NO_DATA_FOUND THEN
        -- �Ώۃf�[�^�������b�Z�[�W�iVD�R�����}�X�^�j�̎擾
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => gv_msg_kbn_coi
                      ,iv_name         => gv_msg_coi_10359);
        -- �Ó����`�F�b�N�G���[
        RAISE chk_err_expt;
--
      -- ���b�N�擾�G���[
      WHEN lock_expt THEN
        -- VD�R�����}�X�^���b�N�擾�L���t���O�Ɏ��s��ݒ�
        gv_vd_is_lock_flg := gv_vd_miss_lock;
--
        -- ���b�N�G���[���b�Z�[�W(VD�R�����}�X�^)�擾
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => gv_msg_kbn_coi
                      ,iv_name         => gv_msg_coi_10024);
        -- �Ó����`�F�b�N�G���[
        RAISE chk_err_expt;
    END;
--
    -- =====================================
    -- VD�R�����}�X�^�X�V�̑Ó����`�F�b�N
    -- =====================================
    -- �擾�����`�[���t�ƋƖ����t���r
    -- �����̏ꍇ
    IF (TRUNC(hht_inv_tran_rec.invoice_date) >= TRUNC(gd_process_date, 'MM')) THEN
--
      -- �����ʂ�0���傫���ꍇ�Ŋ��A
      IF (hht_inv_tran_rec.total_qnt > 0) THEN
--
-- Add 2009/02/18 #015 ��
        -- �����ʂ��������܂ޏꍇ
        IF ((hht_inv_tran_rec.total_qnt - ROUND(hht_inv_tran_rec.total_qnt)) <> 0) THEN
          -- ��݌ɍX�V�i��݌ɏ����_�j�G���[
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => gv_msg_kbn_coi
                        ,iv_name         => gv_mst_coi_10372
                        ,iv_token_name1  => gv_tkn_total_qnt
                        ,iv_token_value1 => hht_inv_tran_rec.total_qnt);
          -- �Ó����`�F�b�N�G���[
          RAISE chk_err_expt;
--
        -- �����ʂ�4���ȏ�̏ꍇ
        ELSIF (LENGTH(hht_inv_tran_rec.total_qnt) > 3) THEN
          -- ��݌ɍX�V�i��݌ɏ���l�j�G���[
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => gv_msg_kbn_coi
                        ,iv_name         => gv_msg_coi_10371
                        ,iv_token_name1  => gv_tkn_total_qnt
                        ,iv_token_value1 => hht_inv_tran_rec.total_qnt);
          -- �Ó����`�F�b�N�G���[
          RAISE chk_err_expt;
        END IF;
-- Add 2009/02/18 #015 ��
        -- VD�R�����}�X�^�̓�����݌ɐ� <> 0�̏ꍇ
        IF (gr_mst_vd_column_rec.inv_qnt <> 0) THEN
          -- ��݌ɍX�V�i�i�ځE��݌ɍX�V�s�j�G���[
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => gv_msg_kbn_coi
                        ,iv_name         => gv_msg_coi_10058);
          -- �Ó����`�F�b�N�G���[
          RAISE chk_err_expt;
--
        -- �擾�����P����NULL�̏ꍇ
        ELSIF (hht_inv_tran_rec.unit_price IS NULL) THEN
          -- ��݌ɍX�V�i�P�����ݒ�G���[�j�G���[
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => gv_msg_kbn_coi
                        ,iv_name         => gv_msg_coi_10353);
          -- �Ó����`�F�b�N�G���[
          RAISE chk_err_expt;
--
        -- �擾�����P����0�����̏ꍇ
        ELSIF (hht_inv_tran_rec.unit_price < 0) THEN
          -- ��݌ɍX�V�i�P���s�����j�G���[
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => gv_msg_kbn_coi
                        ,iv_name         => gv_msg_coi_10059
                        ,iv_token_name1  => gv_tkn_unit_price
                        ,iv_token_value1 => hht_inv_tran_rec.unit_price);
          -- �Ó����`�F�b�N�G���[
          RAISE chk_err_expt;
--
        -- �擾����H/C��NULL�̏ꍇ
        ELSIF (hht_inv_tran_rec.hot_cold_div IS NULL) THEN
          -- ��݌ɍX�V�iH/C���ݒ�G���[�j�G���[
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => gv_msg_kbn_coi
                        ,iv_name         => gv_msg_coi_10354);
          -- �Ó����`�F�b�N�G���[
          RAISE chk_err_expt;
        END IF;
--
      -- �����ʂ�0�ȉ��̏ꍇ
      ELSE
--
        -- �擾�����i��ID <> VD�R�����}�X�^�̓����i��ID�̏ꍇ
        IF (hht_inv_tran_rec.item_id <> NVL(gr_mst_vd_column_rec.item_id, cn_dummy_item_price)) THEN
          -- ��݌ɍX�V�i�i�ڕs��v�j�G���[
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => gv_msg_kbn_coi
                        ,iv_name         => gv_msg_coi_10056);
          -- �Ó����`�F�b�N�G���[
          RAISE chk_err_expt;
        END IF;
--
        -- �����ʂ�0�̏ꍇ���A�擾�����P����0�����̏ꍇ
        IF (hht_inv_tran_rec.total_qnt = 0)
          AND (hht_inv_tran_rec.unit_price < 0) THEN
          -- ��݌ɍX�V�i�P���s�����j�G���[
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => gv_msg_kbn_coi
                        ,iv_name         => gv_msg_coi_10059
                        ,iv_token_name1  => gv_tkn_unit_price
                        ,iv_token_value1 => hht_inv_tran_rec.unit_price);
          -- �Ó����`�F�b�N�G���[
          RAISE chk_err_expt;
--
        -- �����ʂ��}�C�i�X�̏ꍇ���A
        -- (�擾���������� + VD�R�����}�X�^�̓�����݌ɐ�) <> 0�̏ꍇ
        ELSIF (hht_inv_tran_rec.total_qnt < 0)
          AND ((hht_inv_tran_rec.total_qnt + gr_mst_vd_column_rec.inv_qnt) <> 0) THEN
          -- ��݌ɍX�V�i��݌ɕs�����j�G���[
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => gv_msg_kbn_coi
                        ,iv_name         => gv_msg_coi_10057);
          -- �Ó����`�F�b�N�G���[
          RAISE chk_err_expt;
        END IF;
      END IF;
--
    -- �O���̏ꍇ
    ELSE
--
      -- =================================
      -- ����-�O�� �ڋq���x���s��v���
      -- =================================
      -- �s��v�����J�E���^�[�̏�����
      ln_disagreement_count := 0;
--
      BEGIN
        -- �s��v�����̎擾
        SELECT COUNT(xmvc1.rowid)     AS row_count  -- �s��v����
        INTO   ln_disagreement_count
        FROM   xxcoi_mst_vd_column   xmvc1  -- VD�R�����}�X�^(�������)
              ,hz_cust_accounts      hca    -- �ڋq�A�J�E���g
        WHERE  hca.account_number  = hht_inv_tran_rec.customer_code
        AND    hca.cust_account_id = xmvc1.customer_id
        AND    NOT EXISTS (
          SELECT ROWID
          FROM   xxcoi_mst_vd_column xmvc2   -- VD�R�����}�X�^(�O�����)
          WHERE  xmvc2.customer_id                                  = xmvc1.customer_id
          AND    xmvc2.column_no                                    = xmvc1.column_no
          AND    NVL(xmvc2.last_month_item_id, cn_dummy_item_price) = NVL(xmvc1.item_id, cn_dummy_item_price)
          AND    xmvc2.last_month_inventory_quantity                = xmvc1.inventory_quantity
          AND    NVL(xmvc2.last_month_price, cn_dummy_item_price)   = NVL(xmvc1.price, cn_dummy_item_price)
        )
        AND    ROWNUM <= 1;
      EXCEPTION
        -- �z��O�G���[�����������ꍇ
        WHEN OTHERS THEN
          RAISE global_api_others_expt;
      END;
--
      -- �s��v������1�ȏ�̏ꍇ
      IF (ln_disagreement_count >= 1) THEN
        -- ��݌ɍX�V�i�O�������s��v�j�G���[
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => gv_msg_kbn_coi
                      ,iv_name         => gv_msg_coi_10062);
        -- �Ó����`�F�b�N�G���[
        RAISE chk_err_expt;
--
      -- �����ʂ�0���傫���ꍇ
      ELSIF (hht_inv_tran_rec.total_qnt > 0) THEN
--
-- Add 2009/02/18 #015 ��
        -- �����ʂ��������܂ޏꍇ
        IF ((hht_inv_tran_rec.total_qnt - ROUND(hht_inv_tran_rec.total_qnt)) <> 0) THEN
          -- ��݌ɍX�V�i��݌ɏ����_�j�G���[
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => gv_msg_kbn_coi
                        ,iv_name         => gv_mst_coi_10372
                        ,iv_token_name1  => gv_tkn_total_qnt
                        ,iv_token_value1 => hht_inv_tran_rec.total_qnt);
          -- �Ó����`�F�b�N�G���[
          RAISE chk_err_expt;
--
        -- �����ʂ�4���ȏ�̏ꍇ
        ELSIF (LENGTH(hht_inv_tran_rec.total_qnt) > 3) THEN
          -- ��݌ɍX�V�i��݌ɏ���l�j�G���[
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => gv_msg_kbn_coi
                        ,iv_name         => gv_msg_coi_10371
                        ,iv_token_name1  => gv_tkn_total_qnt
                        ,iv_token_value1 => hht_inv_tran_rec.total_qnt);
          -- �Ó����`�F�b�N�G���[
          RAISE chk_err_expt;
        END IF;
-- Add 2009/02/18 #015 ��
        -- VD�R�����}�X�^�̑O����݌ɐ� <> 0�̏ꍇ
        IF (gr_mst_vd_column_rec.inv_qnt <> 0) THEN
          -- ��݌ɍX�V�i�i�ځE��݌ɍX�V�s�j�G���[
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => gv_msg_kbn_coi
                        ,iv_name         => gv_msg_coi_10058);
          -- �Ó����`�F�b�N�G���[
          RAISE chk_err_expt;
--
        -- �擾�����P����NULL�̏ꍇ
        ELSIF (hht_inv_tran_rec.unit_price IS NULL) THEN
          -- ��݌ɍX�V�i�P�����ݒ�G���[�j�G���[
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => gv_msg_kbn_coi
                        ,iv_name         => gv_msg_coi_10353);
          -- �Ó����`�F�b�N�G���[
          RAISE chk_err_expt;
--
        -- �擾�����P����0�����̏ꍇ
        ELSIF (hht_inv_tran_rec.unit_price < 0) THEN
          -- ��݌ɍX�V�i�P���s�����j�G���[
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => gv_msg_kbn_coi
                        ,iv_name         => gv_msg_coi_10059
                        ,iv_token_name1  => gv_tkn_unit_price
                        ,iv_token_value1 => hht_inv_tran_rec.unit_price);
          -- �Ó����`�F�b�N�G���[
          RAISE chk_err_expt;        -- �擾����H/C��NULL�̏ꍇ
--
        ELSIF (hht_inv_tran_rec.hot_cold_div IS NULL) THEN
          -- ��݌ɍX�V�iH/C���ݒ�G���[�j�G���[
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => gv_msg_kbn_coi
                        ,iv_name         => gv_msg_coi_10354);
          -- �Ó����`�F�b�N�G���[
          RAISE chk_err_expt;
        END IF;
--
      -- �����ʂ��}�C�i�X�܂���0�̏ꍇ
      ELSE
--
        -- �擾�����i��ID <> VD�R�����}�X�^�̑O���i��ID�̏ꍇ
        IF (hht_inv_tran_rec.item_id <> NVL(gr_mst_vd_column_rec.lm_item_id, cn_dummy_item_price)) THEN
          -- ��݌ɍX�V�i�i�ڕs��v�j�G���[
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => gv_msg_kbn_coi
                        ,iv_name         => gv_msg_coi_10056);
          -- �Ó����`�F�b�N�G���[
          RAISE chk_err_expt;
        END IF;
--
        -- �����ʂ�0�̏ꍇ�Ŋ��A�擾�����P����0�����̏ꍇ
        IF (hht_inv_tran_rec.total_qnt = 0)
          AND (hht_inv_tran_rec.unit_price < 0) THEN
          -- ��݌ɍX�V�i�P���s�����j�G���[
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => gv_msg_kbn_coi
                        ,iv_name         => gv_msg_coi_10059
                        ,iv_token_name1  => gv_tkn_unit_price
                        ,iv_token_value1 => hht_inv_tran_rec.unit_price);
          -- �Ó����`�F�b�N�G���[
          RAISE chk_err_expt;
--
        -- �����ʂ��}�C�i�X�l�̏ꍇ�Ŋ��A
        -- (�擾���������� + VD�R�����}�X�^�̑O����݌ɐ�) <> 0�̏ꍇ
        ELSIF (hht_inv_tran_rec.total_qnt < 0)
          AND ((hht_inv_tran_rec.total_qnt + gr_mst_vd_column_rec.lm_inv_qnt) <> 0) THEN
          -- ��݌ɍX�V�i��݌ɕs�����j�G���[
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => gv_msg_kbn_coi
                        ,iv_name         => gv_msg_coi_10057);
          -- �Ó����`�F�b�N�G���[
          RAISE chk_err_expt;
        END IF;
      END IF;
    END IF;
--
  EXCEPTION
    -- �Ó����`�F�b�N�G���[
    WHEN chk_err_expt THEN
      -- HHT���o�Ƀf�[�^�pKEY��񃁃b�Z�[�W�̎擾
      lv_key_msg := xxccp_common_pkg.get_msg(
                     iv_application  => gv_msg_kbn_coi
                    ,iv_name         => gv_msg_coi_10342
                    ,iv_token_name1  => gv_tkn_base_code                   -- ���_�R�[�h
                    ,iv_token_value1 => hht_inv_tran_rec.base_code
                    ,iv_token_name2  => gv_tkn_record_type                 -- ���R�[�h���
                    ,iv_token_value2 => hht_inv_tran_rec.record_type
                    ,iv_token_name3  => gv_tkn_invoice_type                -- �`�[�敪
                    ,iv_token_value3 => hht_inv_tran_rec.invoice_type
                    ,iv_token_name4  => gv_tkn_dept_flag                   -- �S�ݓX�t���O
                    ,iv_token_value4 => hht_inv_tran_rec.department_flag
                    ,iv_token_name5  => gv_tkn_invoice_no                  -- �`�[��
                    ,iv_token_value5 => hht_inv_tran_rec.invoice_no
                    ,iv_token_name6  => gv_tkn_column_no                   -- �R������
                    ,iv_token_value6 => hht_inv_tran_rec.column_no
                    ,iv_token_name7  => gv_tkn_item_code                   -- �i�ڃR�[�h
                    ,iv_token_value7 => hht_inv_tran_rec.item_code);
--
      -- VD�R�����}�X�^���b�N�擾�L���t���O�������̏ꍇ
      IF (gv_vd_is_lock_flg = gv_vd_get_lock) THEN
        -- �G���[�E�o�b�t�@��ݒ�
        lv_errbuf := lv_key_msg || lv_errmsg;
--
        -- HHT���o�Ƀf�[�^�pKEY��񃁃b�Z�[�W�̏o��
        FND_FILE.PUT_LINE(
          which  => FND_FILE.LOG
         ,buff   => lv_errbuf);
--
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_errbuf);
--
        -- �G���[�����̃J�E���g�A�b�v
        gn_error_cnt := gn_error_cnt + 1;
--
      -- VD�R�����}�X�^���b�N�擾�L���t���O�����s�̏ꍇ
      ELSE
        -- �G���[�E�o�b�t�@��ݒ�(���s�R�[�h�}��)
        lv_errbuf := lv_key_msg || chr(10) || lv_errmsg;
--
        -- HHT���o�Ƀf�[�^�pKEY��񃁃b�Z�[�W�̏o��
        FND_FILE.PUT_LINE(
          which  => FND_FILE.LOG
         ,buff   => lv_errbuf);
--
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_errbuf);
--
        -- �X�L�b�v�����̃J�E���g�A�b�v
        gn_warn_cnt := gn_warn_cnt + 1;
      END IF;
--
      -- ���^�[���E�R�[�h�Ɍx����ݒ�
      ov_retcode   := cv_status_warn;
      ov_errmsg    := lv_errmsg;
      ov_errbuf    := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
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
  END chk_vd_column_mst_info;
--
  /**********************************************************************************
   * Procedure Name   : ins_tmp_svd_tran_date
   * Description      : ��݌ɕύX���[�N�e�[�u���̒ǉ�(A-4)
   ***********************************************************************************/
  PROCEDURE ins_tmp_svd_tran_date(
    ov_errbuf     OUT VARCHAR2      --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode    OUT VARCHAR2      --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_tmp_svd_tran_date'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ��݌ɕύX�f�[�^�}������
    INSERT INTO xxcoi_tmp_standard_inv(
      item_id                         -- 1.�i��ID
     ,primary_uom_code                -- 2.��P��
     ,invoice_date                    -- 3.�`�[���t
     ,outside_subinv_code             -- 4.�o�ɑ��ۊǏꏊ
     ,inside_subinv_code              -- 5.���ɑ��ۊǏꏊ
     ,total_quantity                  -- 6.������
    )
    VALUES(
      hht_inv_tran_rec.item_id        -- 1.�i��ID
     ,hht_inv_tran_rec.prim_uom_code  -- 2.��P��
     ,hht_inv_tran_rec.invoice_date   -- 3.�`�[���t
     ,hht_inv_tran_rec.out_inv_code   -- 4.�o�ɑ��ۊǏꏊ
     ,hht_inv_tran_rec.in_inv_code    -- 5.���ɑ��ۊǏꏊ
     ,hht_inv_tran_rec.total_qnt      -- 6.������
    );
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
  END ins_tmp_svd_tran_date;
--
  /**********************************************************************************
   * Procedure Name   : upd_xxcoi_mst_vd_column
   * Description      : VD�R�����}�X�^�̍X�V(A-5)
   ***********************************************************************************/
  PROCEDURE upd_xxcoi_mst_vd_column(
    ov_errbuf     OUT VARCHAR2      --   �G���[�E���b�Z�[�W                  --# �Œ� #
   ,ov_retcode    OUT VARCHAR2      --   ���^�[���E�R�[�h                    --# �Œ� #
   ,ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_xxcoi_mst_vd_column'; -- �v���O������
--
--#######################  �Œ胍�[�J���ϐ��錾�� START   ######################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- �`�[���t�������̏ꍇ
    IF (TRUNC(hht_inv_tran_rec.invoice_date) >= TRUNC(gd_process_date, 'MM')) THEN
--
      -- ������ > 0�̏ꍇ
      IF (hht_inv_tran_rec.total_qnt > 0) THEN
        -- �����̕i��ID�A��݌ɐ����X�V
        UPDATE xxcoi_mst_vd_column xmvc
        SET    xmvc.item_id                = hht_inv_tran_rec.item_id                                    -- 1.�i��ID
              ,xmvc.inventory_quantity     = (gr_mst_vd_column_rec.inv_qnt + hht_inv_tran_rec.total_qnt) -- 2.��݌ɐ�
              ,xmvc.price                  = hht_inv_tran_rec.unit_price                                 -- 3.�P��
              ,xmvc.hot_cold               = hht_inv_tran_rec.hot_cold_div                               -- 4.H/C
              ,xmvc.last_updated_by        = cn_last_updated_by                              --  5.�ŏI�X�V��
              ,xmvc.last_update_date       = cd_last_update_date                             --  6.�ŏI�X�V��
              ,xmvc.last_update_login      = cn_last_update_login                            --  7.�ŏI�X�V���O�C��
              ,xmvc.request_id             = cn_request_id                                   --  8.�v��ID
              ,xmvc.program_id             = cn_program_id                                   --  9.�v���O����ID
              ,xmvc.program_application_id = cn_program_application_id                       -- 10.�v���O�����E�A�v���P�[�V����ID
              ,xmvc.program_update_date    = cd_program_update_date                          -- 11.�v���O�����X�V��
        WHERE  xmvc.rowid                  = gr_mst_vd_column_rec.row_id;
--
      -- ������ < 0�̏ꍇ
      ELSIF (hht_inv_tran_rec.total_qnt < 0) THEN
        -- �����̕i��ID�A��݌ɐ����X�V
        UPDATE xxcoi_mst_vd_column xmvc
        SET    xmvc.inventory_quantity     = (gr_mst_vd_column_rec.inv_qnt + hht_inv_tran_rec.total_qnt)       -- 1.��݌ɐ�
              ,xmvc.last_updated_by        = cn_last_updated_by                              -- 2.�ŏI�X�V��
              ,xmvc.last_update_date       = cd_last_update_date                             -- 3.�ŏI�X�V��
              ,xmvc.last_update_login      = cn_last_update_login                            -- 4.�ŏI�X�V���O�C��
              ,xmvc.request_id             = cn_request_id                                   -- 5.�v��ID
              ,xmvc.program_id             = cn_program_id                                   -- 6.�v���O����ID
              ,xmvc.program_application_id = cn_program_application_id                       -- 7.�v���O�����E�A�v���P�[�V����ID
              ,xmvc.program_update_date    = cd_program_update_date                          -- 8.�v���O�����X�V��
        WHERE  xmvc.rowid                  = gr_mst_vd_column_rec.row_id;
--
      -- ������ = 0�̏ꍇ
      ELSIF (hht_inv_tran_rec.total_qnt = 0) THEN
        -- �����̒P���AH/C���X�V
        UPDATE xxcoi_mst_vd_column xmvc
        SET    xmvc.price                  = NVL(hht_inv_tran_rec.unit_price, gr_mst_vd_column_rec.price)      -- 1.�P��
              ,xmvc.hot_cold               = NVL(hht_inv_tran_rec.hot_cold_div, gr_mst_vd_column_rec.hot_cold) -- 2.H/C
              ,xmvc.last_updated_by        = cn_last_updated_by                              -- 3.�ŏI�X�V��
              ,xmvc.last_update_date       = cd_last_update_date                             -- 4.�ŏI�X�V��
              ,xmvc.last_update_login      = cn_last_update_login                            -- 5.�ŏI�X�V���O�C��
              ,xmvc.request_id             = cn_request_id                                   -- 6.�v��ID
              ,xmvc.program_id             = cn_program_id                                   -- 7.�v���O����ID
              ,xmvc.program_application_id = cn_program_application_id                       -- 8.�v���O�����E�A�v���P�[�V����ID
              ,xmvc.program_update_date    = cd_program_update_date                          -- 9.�v���O�����X�V��
        WHERE  xmvc.rowid                  = gr_mst_vd_column_rec.row_id;
      END IF;
--
    -- �`�[���t���O���̏ꍇ
    ELSE
      -- ������ > 0 �̏ꍇ
      IF (hht_inv_tran_rec.total_qnt > 0) THEN
        -- �����̕i��ID�A��݌ɐ����X�V
        UPDATE xxcoi_mst_vd_column xmvc
        SET    xmvc.item_id                = hht_inv_tran_rec.item_id                                              -- 1.�i��ID
              ,xmvc.inventory_quantity     = (gr_mst_vd_column_rec.inv_qnt + hht_inv_tran_rec.total_qnt)           -- 2.��݌ɐ�
              ,xmvc.price                  = hht_inv_tran_rec.unit_price                                           -- 3.�P��
-- == 2009/04/06 V1.2 Moded START ===============================================================
--              ,xmvc.hot_cold               = hht_inv_tran_rec.hot_cold_div                                         -- 4.H/C
              ,xmvc.hot_cold               = DECODE( gr_mst_vd_column_rec.hot_cold
                                               ,gr_mst_vd_column_rec.lm_hot_cold
                                               ,hht_inv_tran_rec.hot_cold_div
                                               ,gr_mst_vd_column_rec.hot_cold )                                    -- 4.H/C
-- == 2009/04/06 V1.2 Moded END   ===============================================================
              ,xmvc.last_month_item_id     = hht_inv_tran_rec.item_id                                              -- 5.�O�����i��ID
              ,xmvc.last_month_inventory_quantity = (gr_mst_vd_column_rec.lm_inv_qnt + hht_inv_tran_rec.total_qnt) -- 6.�O������݌ɐ�
              ,xmvc.last_month_price       = hht_inv_tran_rec.unit_price                                           -- 7.�O�����P��
              ,xmvc.last_month_hot_cold    = hht_inv_tran_rec.hot_cold_div                                         -- 8.�O����H/C
              ,xmvc.last_updated_by        = cn_last_updated_by                              --  9.�ŏI�X�V��
              ,xmvc.last_update_date       = cd_last_update_date                             -- 10.�ŏI�X�V��
              ,xmvc.last_update_login      = cn_last_update_login                            -- 11.�ŏI�X�V���O�C��
              ,xmvc.request_id             = cn_request_id                                   -- 12.�v��ID
              ,xmvc.program_id             = cn_program_id                                   -- 13.�v���O����ID
              ,xmvc.program_application_id = cn_program_application_id                       -- 14.�v���O�����E�A�v���P�[�V����ID
              ,xmvc.program_update_date    = cd_program_update_date                          -- 15.�v���O�����X�V��
        WHERE  xmvc.rowid                  = gr_mst_vd_column_rec.row_id;--
--
      -- ������ < 0 �̏ꍇ
      ELSIF (hht_inv_tran_rec.total_qnt < 0) THEN
        -- �����̕i��ID�A��݌ɐ����X�V
        UPDATE xxcoi_mst_vd_column xmvc
        SET    xmvc.inventory_quantity     = (gr_mst_vd_column_rec.inv_qnt + hht_inv_tran_rec.total_qnt)           -- 1.��݌ɐ�
              ,xmvc.last_month_inventory_quantity = (gr_mst_vd_column_rec.lm_inv_qnt + hht_inv_tran_rec.total_qnt) -- 2.�O������݌ɐ�
              ,xmvc.last_updated_by        = cn_last_updated_by                              -- 3.�ŏI�X�V��
              ,xmvc.last_update_date       = cd_last_update_date                             -- 4.�ŏI�X�V��
              ,xmvc.last_update_login      = cn_last_update_login                            -- 5.�ŏI�X�V���O�C��
              ,xmvc.request_id             = cn_request_id                                   -- 6.�v��ID
              ,xmvc.program_id             = cn_program_id                                   -- 7.�v���O����ID
              ,xmvc.program_application_id = cn_program_application_id                       -- 8.�v���O�����E�A�v���P�[�V����ID
              ,xmvc.program_update_date    = cd_program_update_date                          -- 9.�v���O�����X�V��
        WHERE  xmvc.rowid                  = gr_mst_vd_column_rec.row_id;
--
      -- �����ʂ�0�̏ꍇ
      ELSIF (hht_inv_tran_rec.total_qnt = 0) THEN
        -- �����y�ёO���̒P���AH/C���X�V
        UPDATE xxcoi_mst_vd_column xmvc
        SET    xmvc.price                  = NVL(hht_inv_tran_rec.unit_price, gr_mst_vd_column_rec.price)          -- 1.�P��
-- == 2009/04/06 V1.2 Moded START ===============================================================
--              ,xmvc.hot_cold               = NVL(hht_inv_tran_rec.hot_cold_div, gr_mst_vd_column_rec.hot_cold)     -- 2.H/C
              ,xmvc.hot_cold               = DECODE( gr_mst_vd_column_rec.hot_cold
                                               ,gr_mst_vd_column_rec.lm_hot_cold
                                               ,NVL(hht_inv_tran_rec.hot_cold_div, gr_mst_vd_column_rec.hot_cold)
                                               ,gr_mst_vd_column_rec.hot_cold )                                    -- 2.H/C
-- == 2009/04/06 V1.2 Moded END   ===============================================================
              ,xmvc.last_month_price       = NVL(hht_inv_tran_rec.unit_price, gr_mst_vd_column_rec.lm_price)       -- 3.�O�����P��
              ,xmvc.last_month_hot_cold    = NVL(hht_inv_tran_rec.hot_cold_div, gr_mst_vd_column_rec.lm_hot_cold)  -- 4.�O����H/C
              ,xmvc.last_updated_by        = cn_last_updated_by                              --  5.�ŏI�X�V��
              ,xmvc.last_update_date       = cd_last_update_date                             --  6.�ŏI�X�V��
              ,xmvc.last_update_login      = cn_last_update_login                            --  7.�ŏI�X�V���O�C��
              ,xmvc.request_id             = cn_request_id                                   --  8.�v��ID
              ,xmvc.program_id             = cn_program_id                                   --  9.�v���O����ID
              ,xmvc.program_application_id = cn_program_application_id                       -- 10.�v���O�����E�A�v���P�[�V����ID
              ,xmvc.program_update_date    = cd_program_update_date                          -- 11.�v���O�����X�V��
        WHERE  xmvc.rowid                  = gr_mst_vd_column_rec.row_id;
      END IF;
    END IF;
--
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
  END upd_xxcoi_mst_vd_column;
--
  /**********************************************************************************
   * Procedure Name   : upd_hht_inv_transactions
   * Description      : HHT���o�Ɉꎞ�\�̏����X�e�[�^�X�X�V(A-6)
   ***********************************************************************************/
  PROCEDURE upd_hht_inv_transactions(
    ov_errbuf     OUT VARCHAR2      --   �G���[�E���b�Z�[�W                  --# �Œ� #
   ,ov_retcode    OUT VARCHAR2      --   ���^�[���E�R�[�h                    --# �Œ� #
   ,ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_hht_inv_transactions'; -- �v���O������
--
--#######################  �Œ胍�[�J���ϐ��錾�� START   ######################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    UPDATE xxcoi_hht_inv_transactions xhit
    SET    xhit.status                 = 1                          -- 1.�����X�e�[�^�X(1:�����ς�)
          ,xhit.last_updated_by        = cn_last_updated_by         -- 2.�ŏI�X�V��
          ,xhit.last_update_date       = cd_last_update_date        -- 3.�ŏI�X�V��
          ,xhit.last_update_login      = cn_last_update_login       -- 4.�ŏI�X�V���O�C��
          ,xhit.request_id             = cn_request_id              -- 5.�v��ID
          ,xhit.program_id             = cn_program_id              -- 6.�v���O����ID
          ,xhit.program_application_id = cn_program_application_id  -- 7.�v���O�����E�A�v���P�[�V����ID
          ,xhit.program_update_date    = cd_program_update_date     -- 8.�v���O�����X�V��
    WHERE  xhit.rowid = hht_inv_tran_rec.row_id;
--
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
  END upd_hht_inv_transactions;
--
  /**********************************************************************************
   * Procedure Name   : ins_standard_inv_err_list
   * Description      : ��݌ɕύX�f�[�^�̃G���[���X�g�\�ǉ�(A-7)
   ***********************************************************************************/
  PROCEDURE ins_standard_inv_err_list(
    ov_errbuf     OUT    VARCHAR2     --   �G���[�E���b�Z�[�W                  --# �Œ� #
   ,ov_retcode    OUT    VARCHAR2     --   ���^�[���E�R�[�h                    --# �Œ� #
   ,iov_errmsg    IN OUT VARCHAR2)    --   ���[�U�[�E�G���[�E���b�Z�[�W
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_standard_inv_err_list'; -- �v���O������
--
--#######################  �Œ胍�[�J���ϐ��錾�� START   ######################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- HHT���捞�G���[�o�͊֐�
    xxcoi_common_pkg.add_hht_err_list_data(
      ov_errbuf              => lv_errbuf                      --  1.�G���[�E���b�Z�[�W
     ,ov_retcode             => lv_retcode                     --  2.���^�[���E�R�[�h
     ,ov_errmsg              => lv_errmsg                      --  3.���[�U�[�E�G���[�E���b�Z�[�W
     ,iv_base_code           => hht_inv_tran_rec.base_code     --  4.���_�R�[�h
     ,iv_origin_shipment     => hht_inv_tran_rec.outside_code  --  5.�o�ɑ��R�[�h
     ,iv_data_name           => gv_hht_err_date_name           --  6.�f�[�^����
     ,id_transaction_date    => hht_inv_tran_rec.invoice_date  --  7.�����
     ,iv_entry_number        => hht_inv_tran_rec.invoice_no    --  8.�`�[NO
     ,iv_party_num           => hht_inv_tran_rec.customer_code --  9.���ɑ��R�[�h
     ,iv_performance_by_code => hht_inv_tran_rec.employee_num  -- 10.�c�ƈ��R�[�h
     ,iv_item_code           => hht_inv_tran_rec.item_code     -- 11.�i�ڃR�[�h
     ,iv_error_message       => iov_errmsg                     -- 12.�G���[���e
    );
--
    -- ���ʊ֐�:HHT���捞�G���[�o�͊֐�������ȊO�̏ꍇ
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    -- ���ʊ֐�:HHT���捞�G���[�o�͊֐�������ɏI�������ꍇ
    ELSE
      ov_errbuf  := lv_errbuf;   -- �G���[�E���b�Z�[�W�̐ݒ�
      ov_retcode := lv_retcode;  -- ���^�[���E�R�[�h�̐ݒ�
      iov_errmsg := lv_errmsg;   -- ���[�U�[�E�G���[�E���b�Z�[�W�̐ݒ�
    END IF;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      iov_errmsg := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      iov_errmsg := lv_errmsg;
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
  END ins_standard_inv_err_list;
--
  /**********************************************************************************
   * Procedure Name   : del_hht_inv_transactions
   * Description      : HHT���o�Ɉꎞ�\�̃G���[���R�[�h�폜(A-8)
   ***********************************************************************************/
  PROCEDURE del_hht_inv_transactions(
    ov_errbuf     OUT VARCHAR2      --   �G���[�E���b�Z�[�W                  --# �Œ� #
   ,ov_retcode    OUT VARCHAR2      --   ���^�[���E�R�[�h                    --# �Œ� #
   ,ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'del_hht_inv_transactions'; -- �v���O������
--
--#######################  �Œ胍�[�J���ϐ��錾�� START   ######################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- HHT���o�Ɉꎞ�\�̃G���[�f�[�^�폜
    DELETE FROM xxcoi_hht_inv_transactions xhit
    WHERE xhit.rowid = hht_inv_tran_rec.row_id;
--
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
  END del_hht_inv_transactions;
--
  /**********************************************************************************
   * Procedure Name   : ins_mtl_transactions_if
   * Description      : ��݌ɕύX�f�[�^�̎��ގ��OIF�ǉ�(A-9)
   ***********************************************************************************/
  PROCEDURE ins_mtl_transactions_if(
    ov_errbuf     OUT VARCHAR2      --   �G���[�E���b�Z�[�W                  --# �Œ� #
   ,ov_retcode    OUT VARCHAR2      --   ���^�[���E�R�[�h                    --# �Œ� #
   ,ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_mtl_transactions_if'; -- �v���O������
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
    cv_process_flag       CONSTANT VARCHAR2(1) := '1';   -- �v���Z�X�t���O
    cv_source_code        CONSTANT VARCHAR2(1) := '3';   -- ������[�h
    cn_source_header_id   CONSTANT NUMBER      := 1;     -- �\�[�X�w�b�_ID
    cn_source_line_id     CONSTANT NUMBER      := 1;     -- �\�[�X���C��ID
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ========================================
    -- ���ގ��OIF�̓o�^����
    -- ========================================
    INSERT INTO mtl_transactions_interface(
      process_flag                                                     --  1.�v���Z�X�t���O
     ,transaction_mode                                                 --  2.������[�h
     ,source_code                                                      --  3.�\�[�X�R�[�h
     ,source_header_id                                                 --  4.�\�[�X�w�b�_ID
     ,source_line_id                                                   --  5.�\�[�X���C��ID
     ,inventory_item_id                                                --  6.�i��ID
     ,organization_id                                                  --  7.�݌ɑg�DID
     ,transaction_quantity                                             --  8.�������
     ,primary_quantity                                                 --  9.��P�ʐ���
     ,transaction_uom                                                  -- 10.����P��
     ,transaction_date                                                 -- 11.�����
     ,subinventory_code                                                -- 12.�ۊǏꏊ
     ,transaction_type_id                                              -- 13.����^�C�vID
     ,transfer_subinventory                                            -- 14.�����ۊǏꏊ
     ,transfer_organization                                            -- 15.�����݌ɑg�D
     ,created_by                                                       -- 16.�쐬��
     ,creation_date                                                    -- 17.�쐬��
     ,last_updated_by                                                  -- 18.�ŏI�X�V��
     ,last_update_date                                                 -- 19.�ŏI�X�V��
     ,last_update_login                                                -- 20.�ŏI�X�V���[�U
     ,request_id                                                       -- 21.�v��ID
     ,program_application_id                                           -- 22.�v���O�����A�v���P�[�V����ID
     ,program_id                                                       -- 23.�v���O����ID
     ,program_update_date                                              -- 24.�v���O�����X�V��
    )
    SELECT cv_process_flag                                             --  1.�v���Z�X�t���O
          ,cv_source_code                                              --  2.������[�h
          ,cv_pkg_name                                                 --  3.�\�[�X�R�[�h
          ,cn_source_header_id                                         --  4.�\�[�X�w�b�_ID
          ,cn_source_line_id                                           --  5.�\�[�X���C��ID
          ,xtsi.item_id                                                --  6.�i��ID
          ,gt_inv_org_id                                               --  7.�݌ɑg�DID
          ,SIGN(SUM(xtsi.total_quantity)) * SUM(xtsi.total_quantity)   --  8.�������
          ,SIGN(SUM(xtsi.total_quantity)) * SUM(xtsi.total_quantity)   --  9.��P�ʐ���
          ,xtsi.primary_uom_code                                       -- 10.����P��
          ,xtsi.invoice_date                                           -- 11.�����
          ,DECODE(SIGN(SUM(xtsi.total_quantity))
            ,'1'  ,xtsi.outside_subinv_code
            ,'-1' ,xtsi.inside_subinv_code)                            -- 12.�ۊǏꏊ
          ,gt_tran_type_id                                             -- 13.����^�C�vID
          ,DECODE(SIGN(SUM(xtsi.total_quantity))
            ,'1'  ,xtsi.inside_subinv_code
            ,'-1' ,xtsi.outside_subinv_code)                            -- 14.�����ۊǏꏊ
          ,gt_inv_org_id                                                -- 15.�����݌ɑg�D
          ,cn_created_by                                                -- 16.�쐬��
          ,cd_creation_date                                             -- 17.�쐬��
          ,cn_last_updated_by                                           -- 18.�ŏI�X�V��
          ,cd_last_update_date                                          -- 19.�ŏI�X�V��
          ,cn_last_update_login                                         -- 20.�ŏI�X�V���[�U
          ,cn_request_id                                                -- 21.�v��ID
          ,cn_program_application_id                                    -- 22.�v���O�����A�v���P�[�V����ID
          ,cn_program_id                                                -- 23.�v���O����ID
          ,cd_program_update_date                                       -- 24.�v���O�����X�V��
    FROM   xxcoi_tmp_standard_inv   xtsi                                --  1.��݌ɕύX���[�N�e�[�u��
    HAVING SUM(xtsi.total_quantity) <> 0
    GROUP BY xtsi.item_id
            ,xtsi.primary_uom_code
            ,xtsi.invoice_date
            ,xtsi.outside_subinv_code
            ,xtsi.inside_subinv_code;
--
    -- ����쐬�����̎擾
    gn_cre_tran_cnt := sql%ROWCOUNT;
--
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
  END ins_mtl_transactions_if;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��(A-2)
   **********************************************************************************/
  PROCEDURE submain(
    ov_errbuf     OUT VARCHAR2      --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode    OUT VARCHAR2      --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    -- *** ���[�J���ϐ� ***
    lv_message          VARCHAR2(5000);                                   -- ���b�Z�[�W�o�͗p
    lt_item_code        mtl_system_items_b.segment1%TYPE;   -- �i�ڃR�[�h
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
    gn_warn_cnt   := 0;
    -- ����쐬�����̏�����
    gn_cre_tran_cnt := 0;
--
    -- ===============================
    -- ��������(A-1)
    -- ===============================
    init(
      lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
     ,lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- ��݌ɕύX�f�[�^���o(A-2)
    -- ===============================
    -- �J�[�\���I�[�v��
    OPEN hht_inv_tran_cur;
--
    -- ��݌ɕύX���o���[�v
    <<hht_inv_tran_loop>>
    LOOP
      FETCH hht_inv_tran_cur INTO hht_inv_tran_rec;
      EXIT hht_inv_tran_loop WHEN hht_inv_tran_cur%NOTFOUND;
--
      -- �Ώی����̃J�E���g�A�b�v
      gn_target_cnt := gn_target_cnt + 1;
--
      -- =====================================
      -- ��݌ɕύX�f�[�^�Ó����`�F�b�N(A-3)
      -- =====================================
      chk_vd_column_mst_info(
        lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
       ,lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
      -- ���^�[���E�R�[�h������̏ꍇ
      IF (lv_retcode = cv_status_normal) THEN
        -- =====================================
        -- ��݌ɕύX���[�N�e�[�u���̒ǉ�(A-4)
        -- =====================================
        ins_tmp_svd_tran_date(
          lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
         ,lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
         ,lv_errmsg);       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
        IF (lv_retcode <> cv_status_normal) THEN
          RAISE global_process_expt;
        END IF;
--
        -- =====================================
        -- VD�R�����}�X�^�̍X�V(A-5)
        -- =====================================
        upd_xxcoi_mst_vd_column(
          lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
         ,lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
         ,lv_errmsg);       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
        IF (lv_retcode <> cv_status_normal) THEN
          RAISE global_process_expt;
        END IF;
--
        -- ========================================
        -- HHT���o�Ɉꎞ�\�̏����X�e�[�^�X�X�V(A-6)
        -- ========================================
        upd_hht_inv_transactions(
          lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
         ,lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
         ,lv_errmsg);       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
        IF (lv_retcode <> cv_status_normal) THEN
          RAISE global_process_expt;
        END IF;
--
      -- ���^�[���E�R�[�h���x���Ŋ��AVD�R�����}�X�^�̃��b�N�擾�����̏ꍇ
      ELSIF (lv_retcode = cv_status_warn)
        AND (gv_vd_is_lock_flg = gv_vd_get_lock) THEN
        -- ===========================================
        -- ��݌ɕύX�f�[�^�̃G���[���X�g�\�ǉ�(A-7)
        -- ===========================================
        ins_standard_inv_err_list(
          lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
         ,lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
         ,lv_errmsg);       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
        IF (lv_retcode <> cv_status_normal) THEN
          RAISE global_process_expt;
        END IF;
--
        -- ===========================================
        -- HHT���o�Ɉꎞ�\�̃G���[���R�[�h�폜(A-8)
        -- ===========================================
        del_hht_inv_transactions(
          lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
         ,lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
         ,lv_errmsg);       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
        IF (lv_retcode <> cv_status_normal) THEN
          RAISE global_process_expt;
        END IF;
--
      -- ���^�[���E�R�[�h���G���[�̏ꍇ
      ELSIF (lv_retcode = cv_status_error) THEN
        RAISE global_process_expt;
      END IF;
    END LOOP hht_inv_tran_loop;
--
    -- �J�[�\���N���[�Y
    CLOSE hht_inv_tran_cur;
--
    -- �Ώی�����0���̏ꍇ
    IF (gn_target_cnt = 0) THEN
      -- �Ώۃf�[�^�������b�Z�[�W
      lv_message := xxccp_common_pkg.get_msg(
                      iv_application  => gv_msg_kbn_coi
                     ,iv_name         => gv_msg_coi_00008);
      -- �t�@�C���ɏo��
      FND_FILE.PUT_LINE(
        which => FND_FILE.OUTPUT
       ,buff  => lv_message);
--
    -- �Ώی�����1���ȏ㑶�݂���ꍇ
    ELSE
      -- ===========================================
      -- ��݌ɕύX�f�[�^�̎��ގ��OIF�ǉ�(A-9)
      -- ===========================================
      ins_mtl_transactions_if(
        lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
       ,lv_errmsg);       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
      IF (lv_retcode <> cv_status_normal) THEN
        RAISE global_process_expt;
      END IF;
    END IF;
--
    -- �x�������܂��̓X�L�b�v������1���ȏ㑶�݂���ꍇ
    IF (gn_error_cnt > 0)
      OR (gn_warn_cnt > 0) THEN
      -- ���^�[���E�R�[�h���x���ɍĐݒ肷��
      ov_retcode := cv_status_warn;
    END IF;
--
  EXCEPTION
    -- ���b�N�擾�G���[
    WHEN lock_expt THEN
       -- �Ώی����̃J�E���g�A�b�v
      gn_target_cnt := gn_target_cnt + 1;
--
      -- ���b�N�G���[���b�Z�[�W(HHT���o�Ɉꎞ�\)
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => gv_msg_kbn_coi
                    ,iv_name         => gv_msg_coi_10055);
      ov_errmsg := lv_errmsg;                                                   --# �C�� #
      ov_errbuf := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# �C�� #
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
   * Description      : �R���J�����g���s�t�@�C���o�^�v���V�[�W��(A-10)
   **********************************************************************************/
--
  PROCEDURE main(
    errbuf        OUT VARCHAR2      --   �G���[�E���b�Z�[�W  --# �Œ� #
   ,retcode       OUT VARCHAR2      --   ���^�[���E�R�[�h    --# �Œ� #
  )
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
    cv_skip_rec_msg    CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90003'; -- �X�L�b�v�������b�Z�[�W
    cv_cnt_token       CONSTANT VARCHAR2(10)  := 'COUNT';            -- �������b�Z�[�W�p�g�[�N����
    cv_normal_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004'; -- ����I�����b�Z�[�W
    cv_warn_msg        CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005'; -- �x���I�����b�Z�[�W
    cv_error_msg       CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006'; -- �G���[�I���S���[���o�b�N
--
    cv_err_cnt_1       CONSTANT NUMBER        := 1;                  -- �G���[���擾�����ݒ�p
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
      -- �G���[�����̐ݒ�
      gn_target_cnt := 0;
      gn_normal_cnt := 0;
      gn_warn_cnt   := 0;
      gn_error_cnt  := 1;
--
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --�G���[���b�Z�[�W
      );
--
    -- ���^�[���E�R�[�h���u�G���[�v�ȊO�̏ꍇ
    ELSE
      -- ���������̐ݒ�
      gn_normal_cnt := gn_target_cnt - gn_error_cnt - gn_warn_cnt;
    END IF;
    --��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
--
    -- ===========================================
    -- �I������(A-10)
    -- ===========================================
    --�Ώی����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => gv_msg_kbn_ccp
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
                     iv_application  => gv_msg_kbn_ccp
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
                     iv_application  => gv_msg_kbn_ccp
                    ,iv_name         => cv_error_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_error_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    -- �X�L�b�v�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => gv_msg_kbn_ccp
                    , iv_name         => cv_skip_rec_msg
                    , iv_token_name1  => cv_cnt_token
                    , iv_token_value1 => TO_CHAR(gn_warn_cnt)
                   );
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => gv_out_msg
    );
--
    --����쐬�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => gv_msg_kbn_coi
                    ,iv_name         => gv_msg_coi_10335
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_cre_tran_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    -- ��s�o��
    FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
      ,  buff   => ''
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
                     iv_application  => gv_msg_kbn_ccp
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
END XXCOI003A15C;
/
