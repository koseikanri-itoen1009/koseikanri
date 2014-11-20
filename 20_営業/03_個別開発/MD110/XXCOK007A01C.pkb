CREATE OR REPLACE PACKAGE BODY XXCOK007A01C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOK007A01C(body)
 * Description      : ������ѐU�֏��쐬(EDI)
 * MD.050           : ������ѐU�֏��쐬(EDI) MD050_COK_007_A01
 * Version          : 1.7
 *
 * Program List
 * -------------------------------- ---------------------------------------------------------
 *  Name                             Description
 * -------------------------------- ---------------------------------------------------------
 *  init                             ��������(B-1)
 *  get_edi_wk_tab                   EDI���[�N�e�[�u�����o(B-2)
 *  chk_data                         �f�[�^�`�F�b�N(B-3)
 *  ins_tmp_tbl                      �ꎞ�\�쐬(B-4)
 *  get_qty_amt_total                ���ʁE������z�̏W�v(B-5)
 *  ins_selling_trns_info            ������ѐU�֏��쐬(B-6)
 *  upd_edi_tbl_error                EDI���[�N�e�[�u���X�V(�G���[)(B-7)
 *  upd_edi_tbl_normal               EDI���[�N�e�[�u���X�V(����)(B-8)
 *  del_wk_tbl                       EDI���[�N�e�[�u���폜(B-9)
 *  get_cust_code                    �ڋq�R�[�h�̕ϊ�(B-10)
 *  submain                          ���C�������v���V�[�W��
 *  main                             �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 * 
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/11/25    1.0   S.Sasaki         �V�K�쐬
 *  2009/02/03    1.1   S.Sasaki         [��QCOK_007]�ꎞ�\���C�A�E�g�ύX�̑Ή�
 *  2009/02/12    1.2   S.Sasaki         [��QCOK_031]�ڋq�󒍉\�t���O�A����Ώۋ敪�`�F�b�N�ǉ�
 *  2009/05/14    1.3   M.Hiruta         [��QT1_1003]������o�b�t�@�C��
 *  2009/05/19    1.4   M.Hiruta         [��QT1_1043]�ꎞ�\�쐬�� ������z�E������z�i�Ŕ����j�����_�ȉ��؎̂�
 *  2009/06/08    1.5   M.Hiruta         [��QT1_1354]EDI�Ŏ擾�����l�̂����A�}�X�^�[�Ɠ˂����킹���镶����l��
 *                                                    �O�X�y�[�X����������悤�C��
 *  2009/07/13    1.6   M.Hiruta         [��Q0000514]�����ΏۂɌڋq�X�e�[�^�X�u30:���F�ρv�u50:�x�~�v�̃f�[�^��ǉ�
 *                                                    AP�ł͂Ȃ��AAR�̐ŃR�[�h�}�X�^���g�p����悤�C��
 *  2009/08/13    1.7   M.Hiruta         [��Q0000997]EDI���[�N�e�[�u������[�i�P���ƌ������z���擾����ۂ�
 *                                                    �擾�ӏ����C��
 *                                                    �ڋq���̎擾�����p�[�e�B�}�X�^�֏C��
 *
 *****************************************************************************************/
  -- =========================
  -- �O���[�o���萔
  -- =========================
  --�p�b�P�[�W��
  cv_pkg_name            CONSTANT VARCHAR2(30)  := 'XXCOK007A01C';
  --�A�v���P�[�V�����Z�k��
  cv_xxcok_appl_name     CONSTANT VARCHAR2(10)  := 'XXCOK';
  cv_xxccp_appl_name     CONSTANT VARCHAR2(10)  := 'XXCCP';
  --�X�e�[�^�X�E�R�[�h
  cv_status_normal       CONSTANT VARCHAR2(1)   := xxccp_common_pkg.set_status_normal;  --����:0
  cv_status_warn         CONSTANT VARCHAR2(1)   := xxccp_common_pkg.set_status_warn;    --�x��:1
  cv_status_error        CONSTANT VARCHAR2(1)   := xxccp_common_pkg.set_status_error;   --�ُ�:2
  --���b�Z�[�W����
  cv_message_00044       CONSTANT VARCHAR2(500) := 'APP-XXCOK1-00044';   --���̓p�����[�^(���s�敪)
  cv_message_00006       CONSTANT VARCHAR2(500) := 'APP-XXCOK1-00006';   --���̓p�����[�^(�t�@�C����)
  cv_message_10072       CONSTANT VARCHAR2(500) := 'APP-XXCOK1-10072';   --�p�����[�^�`�F�b�N�G���[���b�Z�[�W
  cv_message_00003       CONSTANT VARCHAR2(500) := 'APP-XXCOK1-00003';   --�v���t�@�C���l�擾�G���[���b�Z�[�W
  cv_message_00013       CONSTANT VARCHAR2(500) := 'APP-XXCOK1-00013';   --�݌ɑg�DID�擾�G���[���b�Z�[�W
  cv_message_00028       CONSTANT VARCHAR2(500) := 'APP-XXCOK1-00028';   --�Ɩ����t�擾�G���[���b�Z�[�W
  cv_message_10074       CONSTANT VARCHAR2(500) := 'APP-XXCOK1-10074';   --EDI������ѐU�֏�񒊏o�G���[���b�Z�[�W
  cv_message_10373       CONSTANT VARCHAR2(500) := 'APP-XXCOK1-10373';   --�K�{���ځF�X�ܔ[�i���Ȃ�
  cv_message_10374       CONSTANT VARCHAR2(500) := 'APP-XXCOK1-10374';   --�K�{���ځF�`�[�ԍ��Ȃ�
  cv_message_10375       CONSTANT VARCHAR2(500) := 'APP-XXCOK1-10375';   --�K�{���ځF�s�ԍ��Ȃ�
  cv_message_10376       CONSTANT VARCHAR2(500) := 'APP-XXCOK1-10376';   --�K�{���ځFEDI�`�F�[���X�R�[�h�Ȃ�
  cv_message_10377       CONSTANT VARCHAR2(500) := 'APP-XXCOK1-10377';   --�K�{���ځF�[����Z���^�[�R�[�h�Ȃ�
  cv_message_10378       CONSTANT VARCHAR2(500) := 'APP-XXCOK1-10378';   --�K�{���ځF�X�R�[�h�Ȃ�
  cv_message_10379       CONSTANT VARCHAR2(500) := 'APP-XXCOK1-10379';   --�K�{���ځF���ʂȂ�
  cv_message_10076       CONSTANT VARCHAR2(500) := 'APP-XXCOK1-10076';   --����U�֌��ڋq�R�[�h�ϊ��G���[
  cv_message_00045       CONSTANT VARCHAR2(500) := 'APP-XXCOK1-00045';   --����S���ݒ�Ȃ��G���[���b�Z�[�W
  cv_message_10095       CONSTANT VARCHAR2(500) := 'APP-XXCOK1-10095';   --���i�\�ݒ�Ȃ��G���[���b�Z�[�W
  cv_message_10077       CONSTANT VARCHAR2(500) := 'APP-XXCOK1-10077';   --����U�֐�ڋq�R�[�h�ϊ��G���[
  cv_message_10082       CONSTANT VARCHAR2(500) := 'APP-XXCOK1-10082';   --�P�ʐݒ�Ȃ��G���[���b�Z�[�W
  cv_message_10085       CONSTANT VARCHAR2(500) := 'APP-XXCOK1-10085';   --�[�i�P���ݒ�Ȃ��G���[���b�Z�[�W
  cv_message_10086       CONSTANT VARCHAR2(500) := 'APP-XXCOK1-10086';   --�c�ƌ����ݒ�Ȃ��G���[���b�Z�[�W
  cv_message_10013       CONSTANT VARCHAR2(500) := 'APP-XXCOK1-10013';   --����ŋ敪�A����ŗ��ݒ�Ȃ��G���[���b�Z�[�W
  cv_message_10073       CONSTANT VARCHAR2(500) := 'APP-XXCOK1-10073';   --EDI�A�g�i�ڃR�[�h�敪�擾�G���[���b�Z�[�W
  cv_message_10079       CONSTANT VARCHAR2(500) := 'APP-XXCOK1-10079';   --���i�R�[�h�ϊ��G���[���b�Z�[�W
  cv_message_10380       CONSTANT VARCHAR2(500) := 'APP-XXCOK1-10380';   --�i�ڗL�����G���[���b�Z�[�W(�ڋq�󒍉\�ȊO)
  cv_message_10083       CONSTANT VARCHAR2(500) := 'APP-XXCOK1-10083';   --�i�ڗL�����G���[���b�Z�[�W(����ΏۈȊO)
  cv_message_10087       CONSTANT VARCHAR2(500) := 'APP-XXCOK1-10087';   --������ѐU�֏��}���G���[
  cv_message_10088       CONSTANT VARCHAR2(500) := 'APP-XXCOK1-10088';   --EDI������ѐU�֏�񃍃b�N�G���[���b�Z�[�W
  cv_message_10089       CONSTANT VARCHAR2(500) := 'APP-XXCOK1-10089';   --EDI������ѐU�֏��X�V�G���[���b�Z�[�W
  cv_message_10091       CONSTANT VARCHAR2(500) := 'APP-XXCOK1-10091';   --EDI������ѐU�֏��폜�G���[
  cv_message_10090       CONSTANT VARCHAR2(500) := 'APP-XXCOK1-10090';   --EDI������ѐU�֏�񃍃b�N�G���[(�폜)
  cv_message_10414       CONSTANT VARCHAR2(500) := 'APP-XXCOK1-10414';   --EDI������ѐU�֏�񃍃b�N�G���[(�G���[�X�V)
  cv_message_10415       CONSTANT VARCHAR2(500) := 'APP-XXCOK1-10415';   --EDI������ѐU�֏��X�V�G���[(�G���[�X�V)
  cv_message_90000       CONSTANT VARCHAR2(500) := 'APP-XXCCP1-90000';   --�Ώی������b�Z�[�W
  cv_message_90001       CONSTANT VARCHAR2(500) := 'APP-XXCCP1-90001';   --�����������b�Z�[�W
  cv_message_90002       CONSTANT VARCHAR2(500) := 'APP-XXCCP1-90002';   --�G���[�������b�Z�[�W
  cv_message_90003       CONSTANT VARCHAR2(500) := 'APP-XXCCP1-90003';   --�X�L�b�v�������b�Z�[�W
  cv_message_90004       CONSTANT VARCHAR2(500) := 'APP-XXCCP1-90004';   --����I�����b�Z�[�W
  cv_message_90005       CONSTANT VARCHAR2(500) := 'APP-XXCCP1-90005';   --�x���I�����b�Z�[�W
  cv_message_90006       CONSTANT VARCHAR2(500) := 'APP-XXCCP1-90006';   --�G���[�I���S���[���o�b�N���b�Z�[�W
  --�v���t�@�C��
  cv_purge_term_profile  CONSTANT VARCHAR2(100) := 'XXCOS1_EDI_PURGE_TERM';       --EDI���폜����
  cv_org_id_profile      CONSTANT VARCHAR2(100) := 'ORG_ID';                      --�g�DID
  cv_case_uom_profile    CONSTANT VARCHAR2(100) := 'XXCOS1_CASE_UOM_CODE';        --�P�[�X�P��
  cv_org_code_profile    CONSTANT VARCHAR2(100) := 'XXCOI1_ORGANIZATION_CODE';    --�݌ɑg�D�R�[�h
-- Start 2009/07/29 Ver_1.6 0000514 M.Hiruta
  cv_set_of_books_id     CONSTANT VARCHAR2(100) := 'GL_SET_OF_BKS_ID';            -- ��v����ID
-- End   2009/07/29 Ver_1.6 0000514 M.Hiruta
  --�g�[�N��
  cv_token_proc_type          CONSTANT VARCHAR2(10) := 'PROC_TYPE';               --�g�[�N����(PROC_TYPE)
  cv_token_file_name          CONSTANT VARCHAR2(10) := 'FILE_NAME';               --�g�[�N����(FILE_NAME)
  cv_token_profile            CONSTANT VARCHAR2(10) := 'PROFILE';                 --�g�[�N����(PROFILE)
  cv_token_org_code           CONSTANT VARCHAR2(10) := 'ORG_CODE';                --�g�[�N����(ORG_CODE)
  cv_token_type               CONSTANT VARCHAR2(5)  := 'TYPE';                    --�g�[�N����(TYPE)
  cv_token_delivery_date      CONSTANT VARCHAR2(20) := 'STORE_DELIVERY_DATE';     --�g�[�N����(STORE_DELIVERY_DATE)
  cv_token_slip_no            CONSTANT VARCHAR2(10) := 'SLIP_NO';                 --�g�[�N����(SLIP_NO)
  cv_token_line_no            CONSTANT VARCHAR2(10) := 'LINE_NO';                 --�g�[�N����(LINE_NO)
  cv_token_edi_chain_code     CONSTANT VARCHAR2(20) := 'EDI_CHAIN_CODE';          --�g�[�N����(EDI_CHAIN_CODE)
  cv_token_center_code        CONSTANT VARCHAR2(20) := 'DELIVERY_CENTER_CODE';    --�g�[�N����(DELIVERY_CENTER_CODE)
  cv_token_store_code         CONSTANT VARCHAR2(10) := 'STORE_CODE';              --�g�[�N����(STORE_CODE)
  cv_token_qty                CONSTANT VARCHAR2(5)  := 'QTY';                     --�g�[�N����(QTY)
  cv_token_customer_code      CONSTANT VARCHAR2(15) := 'CUSTOMER_CODE';           --�g�[�N����(CUSTOMER_CODE)
  cv_token_customer_name      CONSTANT VARCHAR2(15) := 'CUSTOMER_NAME';           --�g�[�N����(CUSTOMER_NAME)
  cv_token_tanto_loc_code     CONSTANT VARCHAR2(15) := 'TANTO_LOC_CODE';          --�g�[�N����(TANTO_LOC_CODE)
  cv_token_tanto_code         CONSTANT VARCHAR2(10) := 'TANTO_CODE';              --�g�[�N����(TANTO_CODE)
  cv_token_shohin_code        CONSTANT VARCHAR2(15) := 'SHOHIN_CODE';             --�g�[�N����(SHOHIN_CODE)
  cv_token_item_code          CONSTANT VARCHAR2(10) := 'ITEM_CODE';               --�g�[�N����(ITEM_CODE)
  cv_token_price_list_name    CONSTANT VARCHAR2(15) := 'PRICE_LIST_NAME';         --�g�[�N����(PRICE_LIST_NAME)
  cv_token_unit_price_code    CONSTANT VARCHAR2(15) := 'UNIT_PRICE_CODE';         --�g�[�N����(UNIT_TYPE_CODE)
  cv_token_tax_type           CONSTANT VARCHAR2(10) := 'TAX_TYPE';                --�g�[�N����(TAX_TYPE)
  cv_token_edi_item_code_type CONSTANT VARCHAR2(20) := 'EDI_ITEM_CODE_TYPE';      --�g�[�N����(EDI_ITEM_CODE_TYPE)
  cv_token_cust_order_e_flag  CONSTANT VARCHAR2(25) := 'CUST_ORDER_ENABLED_FLAG'; --�g�[�N����(CUST_ORDER_ENABLED_FLAG)
  cv_token_selling_type       CONSTANT VARCHAR2(15) := 'SELLING_TYPE';            --�g�[�N����(SELLING_TYPE)
  cv_token_org_id             CONSTANT VARCHAR2(10) := 'ORG_ID';                  --�g�[�N����(ORG_ID)
  cv_token_delivery_price     CONSTANT VARCHAR2(15) := 'DELIVERY_PRICE';          --�g�[�N����(DELIVERY_PRICE)
  cv_token_create_date        CONSTANT VARCHAR2(15) := 'CREATE_DATE';             --�g�[�N����(CREATE_DATE)
  cv_token_count              CONSTANT VARCHAR2(5)  := 'COUNT';                   --�g�[�N����(COUNT)
  --������
  cv_lookup_type              CONSTANT VARCHAR2(50) := 'XXCOK1_CONSUMPTION_TAX_CLASS';   --�l�Z�b�g��
  cv_00                       CONSTANT VARCHAR2(2)  := '00';                             --������:00
  cv_0                        CONSTANT VARCHAR2(1)  := '0';                              --������:0
  cv_1                        CONSTANT VARCHAR2(1)  := '1';                              --������:1
  cv_2                        CONSTANT VARCHAR2(1)  := '2';                              --������:2
  cv_3                        CONSTANT VARCHAR2(1)  := '3';                              --������:3
  cv_4                        CONSTANT VARCHAR2(1)  := '4';                              --������:4
  cv_6                        CONSTANT VARCHAR2(1)  := '6';                              --������:6
  cv_10                       CONSTANT VARCHAR2(2)  := '10';                             --�ڋq�敪(10:�ڋq)
  cv_18                       CONSTANT VARCHAR2(2)  := '18';                             --�ڋq�敪(18:�`�F�[���X)
  cv_40                       CONSTANT VARCHAR2(2)  := '40';                             --�ڋq�X�e�[�^�X(40:�ڋq)
-- Start 2009/07/13 Ver_1.6 0000514 M.Hiruta ADD
  cv_30                       CONSTANT VARCHAR2(2)  := '30';                             --�ڋq�X�e�[�^�X(30:���F��)
  cv_50                       CONSTANT VARCHAR2(2)  := '50';                             --�ڋq�X�e�[�^�X(50:�x�~)
-- End   2009/07/13 Ver_1.6 0000514 M.Hiruta ADD
  cv_99                       CONSTANT VARCHAR2(2)  := '99';                             --������:99
  cv_ship_to                  CONSTANT VARCHAR2(10) := 'SHIP_TO';                        --�g�p�ړI(�o�א�)
  cv_flag_y                   CONSTANT VARCHAR2(1)  := 'Y';                              --�t���O(Y)
  cv_flag_n                   CONSTANT VARCHAR2(1)  := 'N';                              --�t���O(N)
  cv_J                        CONSTANT VARCHAR2(1)  := 'J';                              --������:J
  cv_article_code             CONSTANT VARCHAR2(10) := '0000000000';                     --�����R�[�h(�Œ�l)
  --���l
  cn_0                        CONSTANT NUMBER       := 0;                                --���l:0
  cn_1                        CONSTANT NUMBER       := 1;                                --���l:1
  cn_100                      CONSTANT NUMBER       := 100;                              --���l:100
  --�t�H�[�}�b�g
  cv_slip_no_format           CONSTANT VARCHAR2(9)  := '00000000';                       --�`�[�ԍ��t�H�[�}�b�g
  cv_date_format              CONSTANT VARCHAR2(10) := 'YYYY/MM/DD';                     --���t�t�H�[�}�b�g
  --WHO�J����
  cn_created_by               CONSTANT NUMBER       := fnd_global.user_id;               --CREATED_BY
  cn_last_updated_by          CONSTANT NUMBER       := fnd_global.user_id;               --LAST_UPDATED_BY
  cn_last_update_login        CONSTANT NUMBER       := fnd_global.login_id;              --LAST_UPDATE_LOGIN
  cn_request_id               CONSTANT NUMBER       := fnd_global.conc_request_id;       --REQUEST_ID
  cn_program_application_id   CONSTANT NUMBER       := fnd_global.prog_appl_id;          --PROGRAM_APPLICATION_ID
  cn_program_id               CONSTANT NUMBER       := fnd_global.conc_program_id;       --PROGRAM_ID
  cv_msg_part                 CONSTANT VARCHAR2(3)  := ' : ';                            --�R����
  cv_msg_cont                 CONSTANT VARCHAR2(3)  := '.';                              --�s���I�h
  -- =========================
  -- �O���[�o���ϐ�
  -- =========================
  gn_target_cnt           NUMBER        DEFAULT 0;      --�Ώی���
  gn_normal_cnt           NUMBER        DEFAULT 0;      --��������
  gn_warn_cnt             NUMBER        DEFAULT 0;      --�x������
  gn_error_cnt            NUMBER        DEFAULT 0;      --�G���[����
  gn_organization_id      NUMBER;                       --�݌ɑg�DID
  gn_org_id               NUMBER;                       --�v���t�@�C��(�g�DID)
  gn_line_no              NUMBER(3)     DEFAULT 0;      --���הԍ�
  gn_delivery_unit_price  NUMBER        DEFAULT 0;      --�[�i�P��
  gv_case_uom             VARCHAR2(100) DEFAULT NULL;   --�J�X�^���v���t�@�C��(�P�[�X�P��)
  gv_purge_term           VARCHAR2(100) DEFAULT NULL;   --�J�X�^���v���t�@�C��(EDI���폜����)
  gv_keep_slip_no         VARCHAR2(9)   DEFAULT '0';    --�`�[�ԍ�(�ێ��p)
  gv_base_code            VARCHAR2(4)   DEFAULT '0';    --���_�R�[�h
  gv_cust_code            VARCHAR2(9)   DEFAULT '0';    --�ڋq�R�[�h
  gv_item_code            VARCHAR2(7)   DEFAULT '0';    --�i�ڃR�[�h
  gd_prdate               DATE;                         --�Ɩ����t
-- Start 2009/07/29 Ver_1.6 0000514 M.Hiruta ADD
  gn_set_of_books_id      NUMBER        DEFAULT NULL;   -- ��v����ID
-- End   2009/07/29 Ver_1.6 0000514 M.Hiruta ADD
  -- =======================
  -- �O���[�o��RECODE�^
  -- =======================
  g_from_cust_rec xxcok_tmp_edi_selling_trns%ROWTYPE;
  g_to_cust_rec   xxcok_tmp_edi_selling_trns%ROWTYPE;
  -- =========================
  -- �O���[�o����O
  -- =========================
  -- *** ���b�N�G���[�n���h�� ***
  global_lock_fail          EXCEPTION;
  -- *** ���������ʗ�O ***
  global_process_expt       EXCEPTION;
  -- *** ���ʊ֐���O ***
  global_api_expt           EXCEPTION;
  -- *** ���ʊ֐�OTHERS��O ***
  global_api_others_expt    EXCEPTION;
--
  PRAGMA EXCEPTION_INIT(global_lock_fail, -54);
  PRAGMA EXCEPTION_INIT(global_api_others_expt, -20000);
--
  /**********************************************************************************
   * Procedure Name   : del_wk_tbl
   * Description      : EDI���[�N�e�[�u���폜(B-9)
   ***********************************************************************************/
  PROCEDURE del_wk_tbl(
    ov_errbuf  OUT VARCHAR2    --�G���[�E���b�Z�[�W
  , ov_retcode OUT VARCHAR2    --���^�[���E�R�[�h
  , ov_errmsg  OUT VARCHAR2)   --���[�U�[�E�G���[�E���b�Z�[�W
  IS
    -- =======================
    -- ���[�J���萔
    -- =======================
    cv_prg_name  CONSTANT VARCHAR2(15) := 'del_wk_tbl';   --�v���O������
    -- =======================
    -- ���[�J���ϐ�
    -- =======================
    lv_errbuf              VARCHAR2(5000) DEFAULT NULL;   --�G���[�E���b�Z�[�W
    lv_retcode             VARCHAR2(1)    DEFAULT NULL;   --���^�[���E�R�[�h
    lv_errmsg              VARCHAR2(5000) DEFAULT NULL;   --���[�U�[�E�G���[�E���b�Z�[�W
    lv_msg                 VARCHAR2(5000) DEFAULT NULL;   --���b�Z�[�W�擾�ϐ�
    ln_edi_selling_trns_id NUMBER;                        --EDI������ѐU�֏�񃏁[�NID
    ld_creation_date       DATE;                          --�쐬��
    lv_creation_date       VARCHAR2(10)   DEFAULT NULL;   --�쐬��(YYYY/MM/DD))
    lb_retcode             BOOLEAN        DEFAULT NULL;   --���b�Z�[�W�o�̖͂߂�l
    -- =======================
    -- ���[�J���J�[�\��
    -- =======================
    -- =============================================================================
    -- 1.EDI������ѐU�֏�񃏁[�N�e�[�u���̃��b�N���擾
    -- =============================================================================
    CURSOR edi_tbl_cur
    IS
      SELECT  xwest.creation_date AS creation_date
      FROM    xxcok_wk_edi_selling_trns xwest
      WHERE   xwest.creation_date <= gd_prdate - gv_purge_term
      FOR UPDATE NOWAIT;
    -- =======================
    -- ���[�J�����R�[�h
    -- =======================
    edi_tbl_rec  edi_tbl_cur%ROWTYPE;
--
  BEGIN
    ov_retcode := cv_status_normal;
    -- *** �J�[�\���I�[�v�� ***
    OPEN  edi_tbl_cur;
    <<del_loop>>
    LOOP
      FETCH edi_tbl_cur INTO edi_tbl_rec;
      EXIT WHEN edi_tbl_cur%NOTFOUND;
      FETCH edi_tbl_cur INTO edi_tbl_rec;
      ld_creation_date := edi_tbl_rec.creation_date;
      -- =============================================================================
      -- EDI������ѐU�֏�񃏁[�N�e�[�u����背�R�[�h���폜
      -- =============================================================================
      BEGIN
        DELETE FROM xxcok_wk_edi_selling_trns xwest
        WHERE  xwest.creation_date <= gd_prdate - gv_purge_term;
      EXCEPTION
        -- *** �폜�Ɏ��s�����ꍇ ***
        WHEN OTHERS THEN
        lv_creation_date := TO_CHAR ( ld_creation_date, cv_date_format );
        lv_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_xxcok_appl_name
                  , iv_name         => cv_message_10091
                  , iv_token_name1  => cv_token_create_date
                  , iv_token_value1 => lv_creation_date
                  );
        lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which    => FND_FILE.OUTPUT     --�o�͋敪
                      , iv_message  => lv_msg              --���b�Z�[�W
                      , in_new_line => 0                   --���s
                      );
        ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_msg, 1, 5000 );
        ov_retcode := cv_status_error;
      END;
    END LOOP del_loop;
    CLOSE edi_tbl_cur;
  EXCEPTION
    -- ***���b�N�Ɏ��s�����ꍇ ***
    WHEN global_lock_fail THEN
      lv_msg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_xxcok_appl_name
                , iv_name         => cv_message_10090
                );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.OUTPUT     --�o�͋敪
                    , iv_message  => lv_msg              --���b�Z�[�W
                    , in_new_line => 0                   --���s
                    );
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_msg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END del_wk_tbl;
--
  /**********************************************************************************
   * Procedure Name   : upd_edi_tbl_normal
   * Description      : EDI���[�N�e�[�u���X�V(����)(B-8)
   ***********************************************************************************/
  PROCEDURE upd_edi_tbl_normal(
    ov_errbuf                  OUT VARCHAR2    --�G���[�E���b�Z�[�W
  , ov_retcode                 OUT VARCHAR2    --���^�[���E�R�[�h
  , ov_errmsg                  OUT VARCHAR2    --���[�U�[�E�G���[�E���b�Z�[�W
  , in_edi_selling_info_wk_id  IN  NUMBER      --����ID
  , iv_edi_chain_store_code    IN  VARCHAR2    --EDI�`�F�[���X�R�[�h
  , iv_delivery_to_center_code IN  VARCHAR2    --�[����Z���^�[�R�[�h
  , iv_store_code              IN  VARCHAR2    --�X�R�[�h
  , iv_goods_code              IN  VARCHAR2    --���i�R�[�h
  , in_delivery_unit_price     IN  NUMBER)     --�[�i�P��
  IS
    -- =======================
    -- ���[�J���萔
    -- =======================
    cv_prg_name  CONSTANT VARCHAR2(20) := 'upd_edi_tbl_normal';   --�v���O������
    -- =======================
    -- ���[�J���ϐ�
    -- =======================
    lv_errbuf              VARCHAR2(5000) DEFAULT NULL;   --�G���[�E���b�Z�[�W
    lv_retcode             VARCHAR2(1)    DEFAULT NULL;   --���^�[���E�R�[�h
    lv_errmsg              VARCHAR2(5000) DEFAULT NULL;   --���[�U�[�E�G���[�E���b�Z�[�W
    lv_msg                 VARCHAR2(5000) DEFAULT NULL;   --���b�Z�[�W�擾�ϐ�
    ln_edi_selling_trns_id NUMBER;                        --EDI������ѐU�֏�񃏁[�NID
    lb_retcode             BOOLEAN        DEFAULT NULL;   --���b�Z�[�W�o�̖͂߂�l
    -- =======================
    -- ���[�J���J�[�\��
    -- =======================
    -- =============================================================================
    -- 1.EDI������ѐU�֏�񃏁[�N�e�[�u���̃��b�N���擾
    -- =============================================================================
    CURSOR edi_tbl_cur
    IS
      SELECT xwest.edi_selling_trns_id AS edi_selling_trns_id
      FROM   xxcok_wk_edi_selling_trns xwest
      WHERE  xwest.edi_selling_trns_id = in_edi_selling_info_wk_id
      FOR UPDATE NOWAIT;
    -- =======================
    -- ���[�J�����R�[�h
    -- =======================
    edi_tbl_rec  edi_tbl_cur%ROWTYPE;
--
  BEGIN
    ov_retcode := cv_status_normal;
    -- *** �J�[�\���I�[�v�� ***
    OPEN edi_tbl_cur;
    <<upd_loop>>
    LOOP
      FETCH edi_tbl_cur INTO edi_tbl_rec;
      EXIT WHEN edi_tbl_cur%NOTFOUND;
      ln_edi_selling_trns_id := edi_tbl_rec.edi_selling_trns_id;
      -- =============================================================================
      -- 2.�X�e�[�^�X���X�V
      -- =============================================================================
      BEGIN
        UPDATE  xxcok_wk_edi_selling_trns xwest
        SET     xwest.status                 = cv_1
              , xwest.last_updated_by        = cn_last_updated_by
              , xwest.last_update_date       = SYSDATE
              , xwest.last_update_login      = cn_last_update_login
              , xwest.request_id             = cn_request_id
              , xwest.program_application_id = cn_program_application_id
              , xwest.program_id             = cn_program_id
              , xwest.program_update_date    = SYSDATE
        WHERE   xwest.edi_selling_trns_id    = ln_edi_selling_trns_id;
        -- *** ���������J�E���g ***
        gn_normal_cnt := gn_normal_cnt + 1;
      EXCEPTION
        -- *** �X�V�Ɏ��s�����ꍇ ***
        WHEN OTHERS THEN
          lv_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcok_appl_name
                    , iv_name         => cv_message_10089
                    , iv_token_name1  => cv_token_edi_chain_code
                    , iv_token_value1 => iv_edi_chain_store_code
                    , iv_token_name2  => cv_token_center_code
                    , iv_token_value2 => iv_delivery_to_center_code
                    , iv_token_name3  => cv_token_store_code
                    , iv_token_value3 => iv_store_code
                    , iv_token_name4  => cv_token_shohin_code
                    , iv_token_value4 => iv_goods_code
                    , iv_token_name5  => cv_token_delivery_price
                    , iv_token_value5 => in_delivery_unit_price
                    );
          lb_retcode := xxcok_common_pkg.put_message_f(
                          in_which    => FND_FILE.OUTPUT     --�o�͋敪
                        , iv_message  => lv_msg              --���b�Z�[�W
                        , in_new_line => 0                   --���s
                        );
          ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_msg, 1, 5000 );
          ov_retcode := cv_status_error;
      END;
    END LOOP upd_loop;
    CLOSE edi_tbl_cur;
  EXCEPTION
    -- *** ���b�N�Ɏ��s�����ꍇ ***
    WHEN global_lock_fail THEN
      lv_msg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_xxcok_appl_name
                , iv_name         => cv_message_10088
                , iv_token_name1  => cv_token_edi_chain_code
                , iv_token_value1 => iv_edi_chain_store_code
                , iv_token_name2  => cv_token_center_code
                , iv_token_value2 => iv_delivery_to_center_code
                , iv_token_name3  => cv_token_store_code
                , iv_token_value3 => iv_store_code
                , iv_token_name4  => cv_token_shohin_code
                , iv_token_value4 => iv_goods_code
                , iv_token_name5  => cv_token_delivery_price
                , iv_token_value5 => in_delivery_unit_price
                );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.OUTPUT     --�o�͋敪
                    , iv_message  => lv_msg              --���b�Z�[�W
                    , in_new_line => 0                   --���s
                    );
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_msg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END upd_edi_tbl_normal;
--
  /**********************************************************************************
   * Procedure Name   : upd_edi_tbl_error
   * Description      : EDI���[�N�e�[�u���X�V(�G���[)(B-7)
   ***********************************************************************************/
  PROCEDURE upd_edi_tbl_error(
    ov_errbuf                 OUT VARCHAR2    --�G���[���b�Z�[�W
  , ov_retcode                OUT VARCHAR2    --���^�[���R�[�h
  , ov_errmsg                 OUT VARCHAR2    --���[�U�[�G���[���b�Z�[�W
  , in_edi_selling_info_wk_id IN  NUMBER      --����ID
  , iv_slip_no                IN  VARCHAR2    --�`�[�ԍ�
  , in_line_no                IN  NUMBER)     --�sNo
  IS
    -- =======================
    -- ���[�J���萔
    -- =======================
    cv_prg_name  CONSTANT VARCHAR2(20) := 'upd_edi_tbl_error';   --�v���O������
    -- =======================
    -- ���[�J���ϐ�
    -- =======================
    lv_errbuf              VARCHAR2(5000) DEFAULT NULL;   --�G���[�E���b�Z�[�W
    lv_retcode             VARCHAR2(1)    DEFAULT NULL;   --���^�[���E�R�[�h
    lv_errmsg              VARCHAR2(5000) DEFAULT NULL;   --���[�U�[�E�G���[�E���b�Z�[�W
    lv_msg                 VARCHAR2(5000) DEFAULT NULL;   --���b�Z�[�W�擾�ϐ�
    ln_edi_selling_trns_id NUMBER;                        --EDI������ѐU�֏�񃏁[�NID
    lb_retcode             BOOLEAN        DEFAULT NULL;   --���b�Z�[�W�o�̖͂߂�l
    -- =======================
    -- ���[�J���J�[�\��
    -- =======================
    -- =============================================================================
    -- 1.EDI������ѐU�֏�񃏁[�N�e�[�u���̃��b�N���擾
    -- =============================================================================
    CURSOR edi_tbl_cur
    IS
      SELECT xwest.edi_selling_trns_id AS edi_selling_trns_id
      FROM   xxcok_wk_edi_selling_trns xwest
      WHERE  xwest.edi_selling_trns_id = in_edi_selling_info_wk_id
      FOR UPDATE NOWAIT;
    -- =======================
    -- ���[�J�����R�[�h
    -- =======================
    edi_tbl_rec  edi_tbl_cur%ROWTYPE;
--
  BEGIN
    ov_retcode := cv_status_normal;
    -- *** �J�[�\���I�[�v�� ***
    OPEN edi_tbl_cur;
    <<upd_loop>>
    LOOP
      FETCH edi_tbl_cur INTO edi_tbl_rec;
      EXIT WHEN edi_tbl_cur%NOTFOUND;
      ln_edi_selling_trns_id := edi_tbl_rec.edi_selling_trns_id;
      -- =============================================================================
      -- 2.�X�e�[�^�X���X�V
      -- =============================================================================
      BEGIN
        UPDATE  xxcok_wk_edi_selling_trns xwest
        SET     xwest.status                 = cv_2
              , xwest.last_updated_by        = cn_last_updated_by
              , xwest.last_update_date       = SYSDATE
              , xwest.last_update_login      = cn_last_update_login
              , xwest.request_id             = cn_request_id
              , xwest.program_application_id = cn_program_application_id
              , xwest.program_id             = cn_program_id
              , xwest.program_update_date    = SYSDATE
        WHERE   xwest.edi_selling_trns_id    = ln_edi_selling_trns_id;
        -- *** �X�L�b�v�����J�E���g ***
        gn_warn_cnt := gn_warn_cnt + 1;
      EXCEPTION
        -- *** �X�V�Ɏ��s�����ꍇ ***
        WHEN OTHERS THEN
          lv_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcok_appl_name
                    , iv_name         => cv_message_10415
                    , iv_token_name1  => cv_token_slip_no
                    , iv_token_value1 => iv_slip_no
                    , iv_token_name2  => cv_token_line_no
                    , iv_token_value2 => in_line_no
                    );
          lb_retcode := xxcok_common_pkg.put_message_f(
                          in_which    => FND_FILE.OUTPUT     --�o�͋敪
                        , iv_message  => lv_msg              --���b�Z�[�W
                        , in_new_line => 0                   --���s
                        );
          ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_msg, 1, 5000 );
          ov_retcode := cv_status_error;
      END;
    END LOOP upd_loop;
    CLOSE edi_tbl_cur;
  EXCEPTION
    -- *** ���b�N�Ɏ��s�����ꍇ ***
    WHEN global_lock_fail THEN
      lv_msg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_xxcok_appl_name
                , iv_name         => cv_message_10414
                , iv_token_name1  => cv_token_slip_no
                , iv_token_value1 => iv_slip_no
                , iv_token_name2  => cv_token_line_no
                , iv_token_value2 => in_line_no
                );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.OUTPUT     --�o�͋敪
                    , iv_message  => lv_msg              --���b�Z�[�W
                    , in_new_line => 0                   --���s
                    );
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_msg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END upd_edi_tbl_error;
--
  /**********************************************************************************
   * Procedure Name   : ins_selling_trns_info
   * Description      : ������ѐU�֏��쐬(B-6)
   ***********************************************************************************/
  PROCEDURE ins_selling_trns_info(
    ov_errbuf                  OUT VARCHAR2    --�G���[�E���b�Z�[�W
  , ov_retcode                 OUT VARCHAR2    --���^�[���E�R�[�h
  , ov_errmsg                  OUT VARCHAR2    --���[�U�[�E�G���[�E���b�Z�[�W
  , id_selling_date            IN  DATE        --����v���
  , iv_base_code               IN  VARCHAR2    --���_�R�[�h
  , iv_cust_code               IN  VARCHAR2    --�ڋq�R�[�h
  , iv_selling_emp_code        IN  VARCHAR2    --�S���c�ƃR�[�h
  , iv_cust_state_type         IN  VARCHAR2    --�ڋq�Ƒԋ敪
  , iv_selling_from_cust_code  IN  VARCHAR2    --����U�֌��ڋq�R�[�h
  , iv_item_code               IN  VARCHAR2    --�i�ڃR�[�h
  , in_sum_qty                 IN  NUMBER      --����
  , iv_unit_type               IN  VARCHAR2    --�P��
  , in_delivery_unit_price     IN  NUMBER      --�[�i�P��
  , in_sum_selling_amt         IN  NUMBER      --������z
  , in_sum_selling_amt_no_tax  IN  NUMBER      --������z�i�Ŕ����j
  , in_sum_trading_cost        IN  NUMBER      --�c�ƌ���
-- Start 2009/08/13 Ver.1.7 0000997 M.Hiruta REPAIR
--  , in_shipment_cost_amt       IN  NUMBER      --�������z�i�o�ׁj
  , in_order_cost_amt          IN  NUMBER      --�������z�i�����j
-- End   2009/08/13 Ver.1.7 0000997 M.Hiruta REPAIR
  , iv_tax_type                IN  VARCHAR2    --����ŋ敪
  , in_tax_rate                IN  NUMBER      --����ŗ�
  , iv_selling_from_base_code  IN  VARCHAR2    --����U�֌����_�R�[�h
  , iv_edi_chain_store_code    IN  VARCHAR2    --EDI�`�F�[���X�R�[�h
  , iv_delivery_to_center_code IN  VARCHAR2    --�[����Z���^�[�R�[�h
  , iv_store_code              IN  VARCHAR2    --�X�R�[�h
  , iv_goods_code              IN  VARCHAR2)   --���i�R�[�h
  IS
    -- =======================
    -- ���[�J���萔
    -- =======================
    cv_prg_name  CONSTANT VARCHAR2(25) := 'ins_selling_trns_info';   --�v���O������
    -- =======================
    -- ���[�J���ϐ�
    -- =======================
    lv_errbuf                VARCHAR2(5000) DEFAULT NULL;   --�G���[�E���b�Z�[�W
    lv_retcode               VARCHAR2(1)    DEFAULT NULL;   --���^�[���E�R�[�h
    lv_errmsg                VARCHAR2(5000) DEFAULT NULL;   --���[�U�[�E�G���[�E���b�Z�[�W
    lv_msg                   VARCHAR2(5000) DEFAULT NULL;   --���b�Z�[�W�擾�ϐ�
    lv_slip_no               VARCHAR2(9)    DEFAULT NULL;   --�`�[�ԍ�
    lv_tax_code              VARCHAR2(4)    DEFAULT NULL;   --����ŃR�[�h
    ln_selling_trns_info_s02 NUMBER;                        --�`�[�ԍ�
    lb_retcode               BOOLEAN        DEFAULT NULL;   --���b�Z�[�W�o�̖͂߂�l
--
  BEGIN
    ov_retcode := cv_status_normal;
    lv_slip_no := gv_keep_slip_no;
    -- =============================================================================
    -- �`�[�ԍ���ݒ�(���_�R�[�h�A�ڋq�R�[�h�A�i�ڃR�[�h���ɍ̔�)
    -- =============================================================================
    IF NOT (    ( gv_base_code = iv_base_code )
            AND ( gv_cust_code = iv_cust_code )
            AND ( gv_item_code = iv_item_code )
           ) THEN
      SELECT xxcok_selling_trns_info_s02.NEXTVAL AS xxcok_selling_trns_info_s02
      INTO   ln_selling_trns_info_s02
      FROM   DUAL;
      -- *** �`�[�ԍ���ݒ� ***
      lv_slip_no := cv_J || LTRIM( TO_CHAR( ln_selling_trns_info_s02, cv_slip_no_format ) );
      -- *** ���הԍ��A�[�i�P���������� ***
      gn_line_no             := cn_0;
      gn_delivery_unit_price := cn_0;
      -- *** �e�l��ێ� ***
      gv_keep_slip_no := lv_slip_no;
      gv_base_code    := iv_base_code;
      gv_cust_code    := iv_cust_code;
      gv_item_code    := iv_item_code;
    END IF;
    -- =============================================================================
    -- ���הԍ���ݒ�(�`�[�ԍ����ɁA�[�i�P�����ɍ̔�)
    -- =============================================================================
    IF (    ( gv_keep_slip_no         = lv_slip_no             )
        AND ( gn_delivery_unit_price <> in_delivery_unit_price )
       ) THEN
      gn_line_no := gn_line_no + 1;
      -- *** �[�i�P����ێ� ***
      gn_delivery_unit_price := in_delivery_unit_price;
    END IF;
    -- =============================================================================
    -- ����ŋ敪������ŃR�[�h�ɕϊ�
    -- =============================================================================
    SELECT flv.attribute1 AS tax_code
    INTO   lv_tax_code
    FROM   fnd_lookup_values flv
    WHERE  flv.lookup_type   = cv_lookup_type
    AND    flv.lookup_code   = iv_tax_type
    AND    flv.enabled_flag  = cv_flag_y
    AND    gd_prdate BETWEEN flv.start_date_active
                         AND NVL( flv.end_date_active, gd_prdate )
    AND    flv.language      = USERENV('LANG');
    -- =============================================================================
    -- ������ѐU�֏����쐬
    -- =============================================================================
    BEGIN
      INSERT INTO xxcok_selling_trns_info(
        selling_trns_info_id                  --������ѐU�֏��ID
      , selling_trns_type                     --���ѐU�֋敪
      , slip_no                               --�`�[�ԍ�
      , detail_no                             --���הԍ�
      , selling_date                          --����v���
      , selling_type                          --����敪
      , selling_return_type                   --����ԕi�敪
      , delivery_slip_type                    --�[�i�`�[�敪
      , base_code                             --���_�R�[�h
      , cust_code                             --�ڋq�R�[�h
      , selling_emp_code                      --�S���c�ƃR�[�h
      , cust_state_type                       --�ڋq�Ƒԋ敪
      , delivery_form_type                    --�[�i�`�ԋ敪
      , article_code                          --�����R�[�h
      , card_selling_type                     --�J�[�h����敪
      , checking_date                         --������
      , demand_to_cust_code                   --������ڋq�R�[�h
      , h_c                                   --H and C
      , column_no                             --�R����No.
      , item_code                             --�i�ڃR�[�h
      , qty                                   --����
      , unit_type                             --�P��
      , delivery_unit_price                   --�[�i�P��
      , selling_amt                           --������z
      , selling_amt_no_tax                    --������z�i�Ŕ����j
      , trading_cost                          --�c�ƌ���
      , selling_cost_amt                      --���㌴�����z
      , tax_code                              --����ŃR�[�h
      , tax_rate                              --����ŗ�
      , delivery_base_code                    --�[�i���_�R�[�h
      , registration_date                     --�Ɩ��o�^���t
      , correction_flag                       --�U�߃t���O
      , report_decision_flag                  --����m��t���O
      , info_interface_flag                   --���nI/F�t���O
      , gl_interface_flag                     --�d��쐬�t���O
      , org_slip_number                       --���`�[�ԍ�
      , created_by                            --�쐬��
      , creation_date                         --�쐬��
      , last_updated_by                       --�ŏI�X�V��
      , last_update_date                      --�ŏI�X�V��
      , last_update_login                     --�ŏI�X�V���O�C��
      , request_id                            --�v��ID
      , program_application_id                --�R���J�����g�E�v���O�����E�A�v���P�[�V����ID
      , program_id                            --�R���J�����g�E�v���O����ID
      , program_update_date                   --�v���O�����X�V��
      ) VALUES (
        XXCOK_SELLING_TRNS_INFO_S01.NEXTVAL   --selling_trns_info_id
      , cv_1                                  --selling_trns_type
      , gv_keep_slip_no                       --slip_no
      , gn_line_no                            --detail_no
      , id_selling_date                       --selling_date
      , cv_1                                  --selling_type
      , cv_1                                  --selling_return_type
      , cv_1                                  --delivery_slip_type
      , iv_base_code                          --base_code
      , iv_cust_code                          --cust_code
      , iv_selling_emp_code                   --selling_emp_code
      , iv_cust_state_type                    --cust_state_type
      , cv_6                                  --delivery_form_type
      , cv_article_code                       --article_code
      , cv_0                                  --card_selling_type
      , NULL                                  --checking_date
      , iv_selling_from_cust_code             --demand_to_cust_code
      , cv_1                                  --h_c
      , cv_00                                 --column_no
      , iv_item_code                          --item_code
      , in_sum_qty                            --qty
      , iv_unit_type                          --unit_type
      , in_delivery_unit_price                --delivery_unit_price
      , in_sum_selling_amt                    --selling_amt
      , in_sum_selling_amt_no_tax             --selling_amt_no_tax
      , in_sum_trading_cost                   --trading_cost
-- Start 2009/08/13 Ver.1.7 0000997 M.Hiruta REPAIR
--      , in_shipment_cost_amt                  --selling_cost_amt
      , in_order_cost_amt                     --selling_cost_amt
-- End   2009/08/13 Ver.1.7 0000997 M.Hiruta REPAIR
      , lv_tax_code                           --tax_code
      , in_tax_rate                           --tax_rate
      , iv_selling_from_base_code             --delivery_base_code
      , gd_prdate                             --registration_date
      , cv_1                                  --correction_flag
      , cv_1                                  --report_decision_flag
      , cv_0                                  --info_interface_flag
      , cv_0                                  --gl_interface_flag
      , NULL                                  --org_slip_number
      , cn_created_by                         --created_by
      , SYSDATE                               --creation_date
      , cn_last_updated_by                    --last_updated_by
      , SYSDATE                               --last_update_date
      , cn_last_update_login                  --last_update_login
      , cn_request_id                         --request_id
      , cn_program_application_id             --program_application_id
      , cn_program_id                         --program_id
      , SYSDATE                               --program_update_date
      );
    EXCEPTION
      -- *** �e�[�u���̑}���Ɏ��s ***
      WHEN OTHERS THEN
        lv_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_xxcok_appl_name
                  , iv_name         => cv_message_10087
                  , iv_token_name1  => cv_token_edi_chain_code
                  , iv_token_value1 => iv_edi_chain_store_code
                  , iv_token_name2  => cv_token_center_code
                  , iv_token_value2 => iv_delivery_to_center_code
                  , iv_token_name3  => cv_token_store_code
                  , iv_token_value3 => iv_store_code
                  , iv_token_name4  => cv_token_shohin_code
                  , iv_token_value4 => iv_goods_code
                  , iv_token_name5  => cv_token_delivery_price
                  , iv_token_value5 => in_delivery_unit_price
                  );
        lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which    => FND_FILE.OUTPUT     --�o�͋敪
                      , iv_message  => lv_msg              --���b�Z�[�W
                      , in_new_line => 0                   --���s
                      );
        ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_msg, 1, 5000 );
        ov_retcode := cv_status_error;
    END;
  EXCEPTION
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END ins_selling_trns_info;
--
  /**********************************************************************************
   * Procedure Name   : get_qty_amt_total
   * Description      : ���ʁE������z�̏W�v(B-5)
   ***********************************************************************************/
  PROCEDURE get_qty_amt_total(
    ov_errbuf          OUT VARCHAR2    --�G���[�E���b�Z�[�W
  , ov_retcode         OUT VARCHAR2    --���^�[���E�R�[�h
  , ov_errmsg          OUT VARCHAR2)   --���[�U�[�E�G���[�E���b�Z�[�W
  IS
    -- =======================
    -- ���[�J���萔
    -- =======================
    cv_prg_name  CONSTANT VARCHAR2(20) := 'get_qty_amt_total';   --�v���O������
    -- =======================
    -- ���[�J���ϐ�
    -- =======================
    lv_errbuf       VARCHAR2(5000) DEFAULT NULL;   --�G���[�E���b�Z�[�W
    lv_retcode      VARCHAR2(1)    DEFAULT NULL;   --���^�[���E�R�[�h
    lv_errmsg       VARCHAR2(5000) DEFAULT NULL;   --���[�U�[�E�G���[�E���b�Z�[�W
    lv_msg          VARCHAR2(5000) DEFAULT NULL;   --���b�Z�[�W�擾�ϐ�
    lb_retcode      BOOLEAN        DEFAULT NULL;   --���b�Z�[�W�o�̖͂߂�l
    -- =======================
    -- ���[�J���J�[�\��
    -- =======================
    -- =======================================================================================
    -- �ڋq�R�[�h�A���_�R�[�h�A�i�ڃR�[�h�A�[�i�P�����ɐ��ʁA������z�A������z(�Ŕ���)���W�v
    -- =======================================================================================
    CURSOR tmp_edi_cur
    IS
      SELECT    xtest.selling_date             AS selling_date              --����v���
              , xtest.base_code                AS base_code                 --���_�R�[�h
              , xtest.cust_code                AS cust_code                 --�ڋq�R�[�h
              , xtest.selling_emp_code         AS selling_emp_code          --�S���c�ƃR�[�h
              , xtest.cust_state_type          AS cust_state_type           --�ڋq�Ƒԋ敪
              , xtest.item_code                AS item_code                 --�i�ڃR�[�h
              , SUM(xtest.qty)                 AS sum_qty                   --����
              , xtest.unit_type                AS unit_type                 --�P��
              , xtest.delivery_unit_price      AS delivery_unit_price       --�[�i�P��
              , SUM(xtest.selling_amt)         AS sum_selling_amt           --������z
              , SUM(xtest.selling_amt_no_tax)  AS sum_selling_amt_no_tax    --������z�i�Ŕ����j
              , xtest.tax_type                 AS tax_type                  --����ŋ敪
              , xtest.tax_rate                 AS tax_rate                  --����ŗ�
              , SUM(xtest.trading_cost)        AS sum_trading_cost          --�c�ƌ���
-- Start 2009/08/13 Ver.1.7 0000997 M.Hiruta REPAIR
--              , xtest.shipment_cost_amt        AS shipment_cost_amt         --�������z�i�o�ׁj
              , xtest.order_cost_amt           AS order_cost_amt            --�������z�i�����j
-- End   2009/08/13 Ver.1.7 0000997 M.Hiruta REPAIR
              , xtest.selling_from_base_code   AS selling_from_base_code    --����U�֌����_�R�[�h
              , xtest.selling_from_cust_code   AS selling_from_cust_code    --����U�֌��ڋq�R�[�h
              , xtest.edi_chain_store_code     AS edi_chain_store_code      --EDI�`�F�[���X�R�[�h
              , xtest.delivery_to_center_code  AS delivery_to_center_code   --�[����Z���^�[�R�[�h
              , xtest.store_code               AS store_code                --�X�R�[�h
              , xtest.goods_code               AS goods_code                --���i�R�[�h
      FROM      xxcok_tmp_edi_selling_trns xtest
      GROUP BY  selling_date
              , base_code
              , cust_code
              , selling_emp_code
              , cust_state_type
              , item_code
              , unit_type
              , delivery_unit_price
              , tax_type
              , tax_rate
-- Start 2009/08/13 Ver.1.7 0000997 M.Hiruta REPAIR
--              , shipment_cost_amt
              , order_cost_amt
-- End   2009/08/13 Ver.1.7 0000997 M.Hiruta REPAIR
              , selling_from_base_code
              , selling_from_cust_code
              , edi_chain_store_code
              , delivery_to_center_code
              , store_code
              , goods_code
      ORDER BY  base_code
              , cust_code
              , item_code
              , delivery_unit_price;
    -- =======================
    -- ���[�J��TABLE�^
    -- =======================
    TYPE tab_type IS TABLE OF tmp_edi_cur%ROWTYPE INDEX BY BINARY_INTEGER;
    l_tmp_edi_cur_tab  tab_type;
--
  BEGIN
    ov_retcode := cv_status_normal;
    -- *** �J�[�\���I�[�v�� ***
    OPEN  tmp_edi_cur;
    FETCH tmp_edi_cur BULK COLLECT INTO l_tmp_edi_cur_tab;
    CLOSE tmp_edi_cur;
--
    <<loop_2>>
    FOR ln_idx IN 1 .. l_tmp_edi_cur_tab.COUNT LOOP
      -- =============================================================================
      -- ������ѐU�֏��쐬(B-6)�̌ďo��
      -- =============================================================================
      ins_selling_trns_info(
        ov_errbuf                  => lv_errbuf                                             --�G���[���b�Z�[�W
      , ov_retcode                 => lv_retcode                                            --���^�[���R�[�h
      , ov_errmsg                  => lv_errmsg                                             --���[�U�[�G���[���b�Z�[�W
      , id_selling_date            => l_tmp_edi_cur_tab( ln_idx ).selling_date              --����v���
      , iv_base_code               => l_tmp_edi_cur_tab( ln_idx ).base_code                 --���_�R�[�h
      , iv_cust_code               => l_tmp_edi_cur_tab( ln_idx ).cust_code                 --�ڋq�R�[�h
      , iv_selling_emp_code        => l_tmp_edi_cur_tab( ln_idx ).selling_emp_code          --�S���c�ƃR�[�h
      , iv_cust_state_type         => l_tmp_edi_cur_tab( ln_idx ).cust_state_type           --�ڋq�Ƒԋ敪
      , iv_selling_from_cust_code  => l_tmp_edi_cur_tab( ln_idx ).selling_from_cust_code    --����U�֌��ڋq�R�[�h
      , iv_item_code               => l_tmp_edi_cur_tab( ln_idx ).item_code                 --�i�ڃR�[�h
      , in_sum_qty                 => l_tmp_edi_cur_tab( ln_idx ).sum_qty                   --����
      , iv_unit_type               => l_tmp_edi_cur_tab( ln_idx ).unit_type                 --�P��
      , in_delivery_unit_price     => l_tmp_edi_cur_tab( ln_idx ).delivery_unit_price       --�[�i�P��
      , in_sum_selling_amt         => l_tmp_edi_cur_tab( ln_idx ).sum_selling_amt           --������z
      , in_sum_selling_amt_no_tax  => l_tmp_edi_cur_tab( ln_idx ).sum_selling_amt_no_tax    --������z�i�Ŕ����j
      , in_sum_trading_cost        => l_tmp_edi_cur_tab( ln_idx ).sum_trading_cost          --�c�ƌ���
-- Start 2009/08/13 Ver.1.7 0000997 M.Hiruta REPAIR
--      , in_shipment_cost_amt       => l_tmp_edi_cur_tab( ln_idx ).shipment_cost_amt         --�������z�i�o�ׁj
      , in_order_cost_amt          => l_tmp_edi_cur_tab( ln_idx ).order_cost_amt            --�������z�i�����j
-- End   2009/08/13 Ver.1.7 0000997 M.Hiruta REPAIR
      , iv_tax_type                => l_tmp_edi_cur_tab( ln_idx ).tax_type                  --����ŋ敪
      , in_tax_rate                => l_tmp_edi_cur_tab( ln_idx ).tax_rate                  --����ŗ�
      , iv_selling_from_base_code  => l_tmp_edi_cur_tab( ln_idx ).selling_from_base_code    --����U�֌����_�R�[�h
      , iv_edi_chain_store_code    => l_tmp_edi_cur_tab( ln_idx ).edi_chain_store_code      --EDI�`�F�[���X�R�[�h
      , iv_delivery_to_center_code => l_tmp_edi_cur_tab( ln_idx ).delivery_to_center_code   --�[����Z���^�[�R�[�h
      , iv_store_code              => l_tmp_edi_cur_tab( ln_idx ).store_code                --�X�R�[�h
      , iv_goods_code              => l_tmp_edi_cur_tab( ln_idx ).goods_code                --���i�R�[�h
      );
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
    END LOOP loop_2;
  EXCEPTION
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END get_qty_amt_total;
--
  /**********************************************************************************
   * Procedure Name   : ins_tmp_tbl
   * Description      : �ꎞ�\�쐬(B-4)
   ***********************************************************************************/
  PROCEDURE ins_tmp_tbl(
    ov_errbuf          OUT VARCHAR2                               --�G���[�E���b�Z�[�W
  , ov_retcode         OUT VARCHAR2                               --���^�[���E�R�[�h
  , ov_errmsg          OUT VARCHAR2                               --���[�U�[�E�G���[�E���b�Z�[�W
  , it_from_cust_rec   IN  xxcok_tmp_edi_selling_trns%ROWTYPE     --�e�[�u���^(�U�֌��ڋq�R�[�h)
  , it_to_cust_rec     IN  xxcok_tmp_edi_selling_trns%ROWTYPE)    --�e�[�u���^(�U�֐�ڋq�R�[�h)
  IS
    -- =======================
    -- ���[�J���萔
    -- =======================
    cv_prg_name  CONSTANT VARCHAR2(15) := 'ins_tmp_tbl';   --�v���O������
    -- =======================
    -- ���[�J���ϐ�
    -- =======================
    lv_errbuf       VARCHAR2(5000) DEFAULT NULL;   --�G���[�E���b�Z�[�W
    lv_retcode      VARCHAR2(1)    DEFAULT NULL;   --���^�[���E�R�[�h
    lv_errmsg       VARCHAR2(5000) DEFAULT NULL;   --���[�U�[�E�G���[�E���b�Z�[�W
    lv_msg          VARCHAR2(5000) DEFAULT NULL;   --���b�Z�[�W�擾�ϐ�
    lb_retcode      BOOLEAN        DEFAULT NULL;   --���b�Z�[�W�o�̖͂߂�l
--
  BEGIN
    ov_retcode := cv_status_normal;
    -- =============================================================================
    -- ����U�֌��ڋq�R�[�h���L�[�Ƃ��A�ꎞ�\���쐬
    -- =============================================================================
    INSERT INTO xxcok_tmp_edi_selling_trns(
      selling_date                               --����v���
    , base_code                                  --���_�R�[�h
    , cust_code                                  --�ڋq�R�[�h
    , selling_emp_code                           --�S���c�ƃR�[�h
    , cust_state_type                            --�ڋq�Ƒԋ敪
    , item_code                                  --�i�ڃR�[�h
    , qty                                        --����
    , unit_type                                  --�P��
    , delivery_unit_price                        --�[�i�P��
    , selling_amt                                --������z
    , selling_amt_no_tax                         --������z�i�Ŕ����j
    , tax_type                                   --����ŋ敪
    , tax_rate                                   --����ŗ�
    , trading_cost                               --�c�ƌ���
-- Start 2009/08/13 Ver.1.7 0000997 M.Hiruta REPAIR
--    , shipment_cost_amt                          --�������z�i�o�ׁj
    , order_cost_amt                             --�������z�i�����j
-- End   2009/08/13 Ver.1.7 0000997 M.Hiruta REPAIR
    , selling_from_base_code                     --����U�֌����_�R�[�h
    , selling_from_cust_code                     --����U�֌��ڋq�R�[�h
    , edi_chain_store_code                       --EDI�`�F�[���X�R�[�h
    , delivery_to_center_code                    --�[����Z���^�[�R�[�h
    , store_code                                 --�X�R�[�h
    , goods_code                                 --���i�R�[�h
    ) VALUES (
      it_from_cust_rec.selling_date              --selling_date
    , it_from_cust_rec.base_code                 --base_code
    , it_from_cust_rec.cust_code                 --cust_code
    , it_from_cust_rec.selling_emp_code          --selling_emp_code
    , it_from_cust_rec.cust_state_type           --cust_state_type
    , it_from_cust_rec.item_code                 --item_code
    , it_from_cust_rec.qty                       --qty
    , it_from_cust_rec.unit_type                 --unit_type
    , it_from_cust_rec.delivery_unit_price       --delivery_unit_price
-- Start 2009/05/19 Ver_1.4 T1_1043 M.Hiruta
--    , it_from_cust_rec.selling_amt               --selling_amt
--    , it_from_cust_rec.selling_amt_no_tax        --selling_amt_no_tax
    , TRUNC(it_from_cust_rec.selling_amt)        --selling_amt
    , TRUNC(it_from_cust_rec.selling_amt_no_tax) --selling_amt_no_tax
-- End   2009/05/19 Ver_1.4 T1_1043 M.Hiruta
    , it_from_cust_rec.tax_type                  --tax_type
    , it_from_cust_rec.tax_rate                  --tax_rate
    , it_from_cust_rec.trading_cost              --trading_cost
-- Start 2009/08/13 Ver.1.7 0000997 M.Hiruta REPAIR
--    , it_from_cust_rec.shipment_cost_amt         --shipment_cost_amt
    , it_from_cust_rec.order_cost_amt            --order_cost_amt
-- End   2009/08/13 Ver.1.7 0000997 M.Hiruta REPAIR
    , it_from_cust_rec.selling_from_base_code    --selling_from_base_code
    , it_from_cust_rec.selling_from_cust_code    --selling_from_cust_code
    , it_from_cust_rec.edi_chain_store_code      --edi_chain_store_code
    , it_from_cust_rec.delivery_to_center_code   --delivery_to_center_code
    , it_from_cust_rec.store_code                --store_code
    , it_from_cust_rec.goods_code                --goods_code
    );
    -- =============================================================================
    -- ����U�֐�ڋq�R�[�h���L�[�Ƃ��A�ꎞ�\���쐬
    -- =============================================================================
    INSERT INTO xxcok_tmp_edi_selling_trns(
      selling_date                             --����v���
    , base_code                                --���_�R�[�h
    , cust_code                                --�ڋq�R�[�h
    , selling_emp_code                         --�S���c�ƃR�[�h
    , cust_state_type                          --�ڋq�Ƒԋ敪
    , item_code                                --�i�ڃR�[�h
    , qty                                      --����
    , unit_type                                --�P��
    , delivery_unit_price                      --�[�i�P��
    , selling_amt                              --������z
    , selling_amt_no_tax                       --������z�i�Ŕ����j
    , tax_type                                 --����ŋ敪
    , tax_rate                                 --����ŗ�
    , trading_cost                             --�c�ƌ���
-- Start 2009/08/13 Ver.1.7 0000997 M.Hiruta REPAIR
--    , shipment_cost_amt                        --�������z�i�o�ׁj
    , order_cost_amt                           --�������z�i�����j
-- End   2009/08/13 Ver.1.7 0000997 M.Hiruta REPAIR
    , selling_from_base_code                   --����U�֌����_�R�[�h
    , selling_from_cust_code                   --����U�֌��ڋq�R�[�h
    , edi_chain_store_code                     --EDI�`�F�[���X�R�[�h
    , delivery_to_center_code                  --�[����Z���^�[�R�[�h
    , store_code                               --�X�R�[�h
    , goods_code                               --���i�R�[�h
    ) VALUES (
      it_to_cust_rec.selling_date              --selling_date
    , it_to_cust_rec.base_code                 --base_code
    , it_to_cust_rec.cust_code                 --cust_code
    , it_to_cust_rec.selling_emp_code          --selling_emp_code
    , it_to_cust_rec.cust_state_type           --cust_state_type
    , it_to_cust_rec.item_code                 --item_code
    , it_to_cust_rec.qty                       --qty
    , it_to_cust_rec.unit_type                 --unit_type
    , it_to_cust_rec.delivery_unit_price       --delivery_unit_price
-- Start 2009/05/19 Ver_1.4 T1_1043 M.Hiruta
--    , it_to_cust_rec.selling_amt               --selling_amt
--    , it_to_cust_rec.selling_amt_no_tax        --selling_amt_no_tax
    , TRUNC(it_to_cust_rec.selling_amt)        --selling_amt
    , TRUNC(it_to_cust_rec.selling_amt_no_tax) --selling_amt_no_tax
-- End   2009/05/19 Ver_1.4 T1_1043 M.Hiruta
    , it_to_cust_rec.tax_type                  --tax_type
    , it_to_cust_rec.tax_rate                  --tax_rate
    , it_to_cust_rec.trading_cost              --trading_cost
-- Start 2009/08/13 Ver.1.7 0000997 M.Hiruta REPAIR
--    , it_to_cust_rec.shipment_cost_amt         --shipment_cost_amt
    , it_to_cust_rec.order_cost_amt            --order_cost_amt
-- End   2009/08/13 Ver.1.7 0000997 M.Hiruta REPAIR
    , it_to_cust_rec.selling_from_base_code    --selling_from_base_code
    , it_to_cust_rec.selling_from_cust_code    --selling_from_cust_code
    , it_to_cust_rec.edi_chain_store_code      --edi_chain_store_code
    , it_to_cust_rec.delivery_to_center_code   --delivery_to_center_code
    , it_to_cust_rec.store_code                --store_code
    , it_to_cust_rec.goods_code                --goods_code
    );
  EXCEPTION
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END ins_tmp_tbl;
--
  /**********************************************************************************
   * Procedure Name   : get_cust_code
   * Description      : �ڋq�R�[�h�̕ϊ�(B-10)
   ***********************************************************************************/
  PROCEDURE get_cust_code(
    ov_errbuf               OUT VARCHAR2    --�G���[���b�Z�[�W
  , ov_retcode              OUT VARCHAR2    --���^�[���R�[�h
  , ov_errmsg               OUT VARCHAR2    --���[�U�[�G���[���b�Z�[�W
  , iv_message_code         IN  VARCHAR2    --���b�Z�[�W�R�[�h
  , iv_edi_chain_store_code IN  VARCHAR2    --EDI�`�F�[���X�R�[�h
  , iv_code                 IN  VARCHAR2    --�[����Z���^�[�R�[�h�E�X�R�[�h
-- Start 2009/08/13 Ver.1.7 0000997 M.Hiruta REPAIR
--  , in_shipment_unit_price  IN  NUMBER      --�[�i�P��
  , in_order_unit_price     IN  NUMBER      --�[�i�P��
-- End   2009/08/13 Ver.1.7 0000997 M.Hiruta REPAIR
  , iv_token                IN  VARCHAR2    --�g�[�N����
  , ov_sale_base_code       OUT VARCHAR2    --���_�R�[�h
  , ov_account_number       OUT VARCHAR2    --�ڋq�R�[�h
  , ov_sales_stuff_code     OUT VARCHAR2    --�S���c�ƃR�[�h
  , ov_business_low_type    OUT VARCHAR2    --�ڋq�Ƒԋ敪
  , on_price_list_id        OUT NUMBER)     --���i�\ID
  IS
    -- =======================
    -- ���[�J���萔
    -- =======================
    cv_prg_name  CONSTANT VARCHAR2(15) := 'get_cust_code';   --�v���O������
    -- =======================
    -- ���[�J���ϐ�
    -- =======================
    lv_errbuf        VARCHAR2(5000) DEFAULT NULL;   --�G���[�E���b�Z�[�W
    lv_retcode       VARCHAR2(1)    DEFAULT NULL;   --���^�[���E�R�[�h
    lv_errmsg        VARCHAR2(5000) DEFAULT NULL;   --���[�U�[�E�G���[�E���b�Z�[�W
    lv_msg           VARCHAR2(5000) DEFAULT NULL;   --���b�Z�[�W�擾�ϐ�
-- Start 2009/05/15 Ver_1.3 T1_1003 M.Hiruta
--    lv_account_name  VARCHAR2(30)   DEFAULT NULL;   --�ڋq��
-- Start 2009/08/13 Ver.1.7 0000997 M.Hiruta REPAIR
--    lv_account_name  hz_cust_accounts.account_name%TYPE  DEFAULT NULL; --�ڋq��
    lv_account_name  hz_parties.party_name%TYPE  DEFAULT NULL; --�ڋq��
-- End   2009/08/13 Ver.1.7 0000997 M.Hiruta REPAIR
-- End   2009/05/15 Ver_1.3 T1_1003 M.Hiruta
    lb_retcode       BOOLEAN        DEFAULT NULL;   --���b�Z�[�W�o�̖͂߂�l
    -- =======================
    -- ���[�J����O
    -- =======================
    skip_expt  EXCEPTION;   --�ڋq�R�[�h�̕ϊ��v���V�[�W�����G���[
--
  BEGIN
    ov_retcode := cv_status_normal;
    -- =============================================================================
    -- 2.�ڋq�R�[�h�̕ϊ�
    -- =============================================================================
    BEGIN
      SELECT  hca.account_number    AS account_number      --�ڋq�R�[�h
-- Start 2009/08/13 Ver.1.7 0000997 M.Hiruta REPAIR
--            , hca.account_name      AS account_name        --�ڋq��
            , hp.party_name         AS account_name        --�ڋq��
-- End   2009/08/13 Ver.1.7 0000997 M.Hiruta REPAIR
            , xca.sale_base_code    AS sale_base_code      --����S�����_�R�[�h
            , xca.business_low_type AS business_low_type   --�Ƒ�(������)
            , hcsua.price_list_id   AS price_list_id       --���i�\ID
      INTO    ov_account_number
            , lv_account_name
            , ov_sale_base_code
            , ov_business_low_type
            , on_price_list_id
      FROM    hz_cust_accounts       hca     --�ڋq�}�X�^
            , xxcmm_cust_accounts    xca     --�ڋq�ǉ����
            , hz_cust_acct_sites_all hcasa   --�ڋq���ݒn
            , hz_cust_site_uses_all  hcsua   --�ڋq�g�p�ړI
            , hz_parties             hp      --�p�[�e�B�}�X�^
      WHERE   hca.cust_account_id      = hcasa.cust_account_id
      AND     hca.cust_account_id      = xca.customer_id
      AND     hcasa.cust_acct_site_id  = hcsua.cust_acct_site_id
      AND     hp.party_id              = hca.party_id
      AND     hca.customer_class_code  = cv_10
-- Start 2009/07/13 Ver_1.6 0000514 M.Hiruta REPAIR
--      AND     hp.duns_number_c         = cv_40
      AND     hp.duns_number_c        IN( cv_30 , cv_40 , cv_50 )
-- End   2009/07/13 Ver_1.6 0000514 M.Hiruta REPAIR
      AND     xca.selling_transfer_div = cv_1
      AND     xca.chain_store_code     = iv_edi_chain_store_code
      AND     xca.store_code           = iv_code
      AND     hcsua.site_use_code      = cv_ship_to
-- Start 2009/05/19 Ver_1.4 T1_1043 M.Hiruta
      AND     hcasa.org_id             = gn_org_id
-- End   2009/05/19 Ver_1.4 T1_1043 M.Hiruta
      AND     hcsua.org_id             = gn_org_id;
    EXCEPTION
    -- *** �ڋq�R�[�h���擾�ł��Ȃ��ꍇ(�ڋq�R�[�h�̕ϊ��Ɏ��s�����ꍇ) ***
      WHEN NO_DATA_FOUND THEN
        lv_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_xxcok_appl_name
                  , iv_name         => iv_message_code
                  , iv_token_name1  => cv_token_edi_chain_code
                  , iv_token_value1 => iv_edi_chain_store_code
                  , iv_token_name2  => iv_token
                  , iv_token_value2 => iv_code
                  );
        lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which    => FND_FILE.OUTPUT   --�o�͋敪
                      , iv_message  => lv_msg            --���b�Z�[�W
                      , in_new_line => 0                 --���s
                      );
        RAISE skip_expt;
    END;
    -- =============================================================================
    -- �S���c�ƃR�[�h���擾
    -- =============================================================================
    ov_sales_stuff_code := xxcok_common_pkg.get_sales_staff_code_f(
                             iv_customer_code => ov_account_number   --�ڋq�R�[�h
                           , id_proc_date     => gd_prdate           --������
                           );
    -- =============================================================================
    -- ����S�����_�R�[�h�A�S���c�ƃR�[�h�̂ǂ��炩�A�܂��͗����ɒl��
    -- �ݒ肳��Ă��Ȃ��ꍇ�A��O����
    -- =============================================================================
    IF (   ( ov_sale_base_code   IS NULL )
        OR ( ov_sales_stuff_code IS NULL )
       ) THEN
      lv_msg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_xxcok_appl_name
                , iv_name         => cv_message_00045
                , iv_token_name1  => cv_token_customer_code
                , iv_token_value1 => ov_account_number
                , iv_token_name2  => cv_token_customer_name
                , iv_token_value2 => lv_account_name
                , iv_token_name3  => cv_token_tanto_loc_code
                , iv_token_value3 => ov_sale_base_code
                , iv_token_name4  => cv_token_tanto_code
                , iv_token_value4 => ov_sales_stuff_code
                );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.OUTPUT   --�o�͋敪
                    , iv_message  => lv_msg            --���b�Z�[�W
                    , in_new_line => 0                 --���s
                    );
      RAISE skip_expt;
    END IF;
    -- =============================================================================
    -- B-2.�Ŏ擾�����[�i�P����NULL�A�܂��́A0�̏ꍇ�A����
    -- ��L�Ŏ擾�������i�\ID�ɒl���ݒ肳��Ă��Ȃ��ꍇ�A��O����
    -- =============================================================================
-- Start 2009/08/13 Ver.1.7 0000997 M.Hiruta REPAIR
--    IF ( (   ( in_shipment_unit_price IS NULL )
--          OR ( in_shipment_unit_price = cn_0  )
--         )
--         AND ( on_price_list_id IS NULL )
--       ) THEN
    IF ( (   ( in_order_unit_price IS NULL )
          OR ( in_order_unit_price = cn_0  )
         )
         AND ( on_price_list_id IS NULL )
       ) THEN
-- End   2009/08/13 Ver.1.7 0000997 M.Hiruta REPAIR
      lv_msg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_xxcok_appl_name
                , iv_name         => cv_message_10095
                , iv_token_name1  => cv_token_customer_code
                , iv_token_value1 => ov_account_number
                , iv_token_name2  => cv_token_customer_name
                , iv_token_value2 => lv_account_name
                , iv_token_name3  => cv_token_tanto_loc_code
                , iv_token_value3 => ov_sale_base_code
                , iv_token_name4  => cv_token_tanto_code
                , iv_token_value4 => ov_sales_stuff_code
                );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.OUTPUT   --�o�͋敪
                    , iv_message  => lv_msg            --���b�Z�[�W
                    , in_new_line => 0                 --���s
                    );
      RAISE skip_expt;
    END IF;
  EXCEPTION
    -- *** 
    WHEN skip_expt THEN
      ov_retcode := cv_status_warn;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END get_cust_code;
--
  /**********************************************************************************
   * Procedure Name   : chk_data
   * Description      : �f�[�^�`�F�b�N(B-3)
   ***********************************************************************************/
  PROCEDURE chk_data(
    ov_errbuf                  OUT VARCHAR2                             --�G���[�E���b�Z�[�W
  , ov_retcode                 OUT VARCHAR2                             --���^�[���E�R�[�h
  , ov_errmsg                  OUT VARCHAR2                             --���[�U�[�E�G���[�E���b�Z�[�W
  , ot_from_cust_rec           OUT xxcok_tmp_edi_selling_trns%ROWTYPE   --�e�[�u���^(�U�֌��ڋq�R�[�h)
  , ot_to_cust_rec             OUT xxcok_tmp_edi_selling_trns%ROWTYPE   --�e�[�u���^(�U�֐�ڋq�R�[�h)
  , id_store_delivery_date     IN  DATE                                 --�X�ܔ[�i��
  , iv_slip_no                 IN  VARCHAR2                             --�`�[�ԍ�
  , in_line_no                 IN  NUMBER                               --�sNo
  , iv_edi_chain_store_code    IN  VARCHAR2                             --EDI�`�F�[���X�R�[�h
  , iv_delivery_to_center_code IN  VARCHAR2                             --�[����Z���^�[�R�[�h
  , iv_store_code              IN  VARCHAR2                             --�X�R�[�h
  , in_order_qty_sum           IN  NUMBER                               --����
-- Start 2009/08/13 Ver.1.7 0000997 M.Hiruta REPAIR
--  , in_shipment_unit_price     IN  NUMBER                               --�[�i�P��
  , in_order_unit_price        IN  NUMBER                               --�[�i�P��
-- End   2009/08/13 Ver.1.7 0000997 M.Hiruta REPAIR
  , iv_goods_code_2            IN  VARCHAR2                             --���i�R�[�h2
-- Start 2009/08/13 Ver.1.7 0000997 M.Hiruta REPAIR
--  , in_shipment_cost_amt       IN  NUMBER)                              --�������z(�o��)
  , in_order_cost_amt          IN  NUMBER)                              --�������z(����)
-- End   2009/08/13 Ver.1.7 0000997 M.Hiruta REPAIR
  IS
    -- =======================
    -- ���[�J���萔
    -- =======================
    cv_prg_name  CONSTANT VARCHAR2(10) := 'chk_data';   --�v���O������
    -- =======================
    -- ���[�J���ϐ�
    -- =======================
    lv_errbuf                       VARCHAR2(5000) DEFAULT NULL;   --�G���[�E���b�Z�[�W
    lv_retcode                      VARCHAR2(1)    DEFAULT NULL;   --���^�[���E�R�[�h
    lv_errmsg                       VARCHAR2(5000) DEFAULT NULL;   --���[�U�[�E�G���[�E���b�Z�[�W
    lv_msg                          VARCHAR2(5000) DEFAULT NULL;   --���b�Z�[�W�擾�ϐ�
    lv_parameter                    VARCHAR2(1)    DEFAULT NULL;   --�p�����[�^ 1:�G���[
    lv_from_account_number          VARCHAR2(9)    DEFAULT NULL;   --����U�֌��ڋq�R�[�h
    lv_to_account_number            VARCHAR2(9)    DEFAULT NULL;   --����U�֐�ڋq�R�[�h
    lv_sale_base_code               VARCHAR2(4)    DEFAULT NULL;   --���㋒�_�R�[�h
    lv_sales_stuff_code             VARCHAR2(30)   DEFAULT NULL;   --�S���c�ƈ��R�[�h
    lv_business_low_type            VARCHAR2(2)    DEFAULT NULL;   --�Ƒ�(������)
    lv_price_list_name              VARCHAR2(240)  DEFAULT NULL;   --���i�\��
    lv_edi_item_code_div            VARCHAR2(1)    DEFAULT NULL;   --EDI�A�g�i�ڃR�[�h�敪
    lv_item_code                    VARCHAR2(7)    DEFAULT NULL;   --�i�ڃR�[�h
    lv_customer_order_enabled_flag  VARCHAR2(1)    DEFAULT NULL;   --�ڋq�󒍉\�t���O
    lv_selling_type                 VARCHAR2(1)    DEFAULT NULL;   --����Ώۋ敪
    lv_unit_type                    VARCHAR2(25)   DEFAULT NULL;   --�P��
    lv_cost_item_unit_type          VARCHAR2(240)  DEFAULT NULL;   --�c�ƌ���(�i�ڒP��)
    lv_tax_type                     VARCHAR2(1)    DEFAULT NULL;   --����ŋ敪
    ln_price_list_id                NUMBER;                        --���i�\ID
    ln_item_id                      NUMBER;                        --�i��ID
    ln_case_qty                     NUMBER(5);                     --�P�[�X����
    ln_qty                          NUMBER         DEFAULT 0;      --����
    ln_unit_price                   NUMBER         DEFAULT 0;      --�P��(���ʊ֐��Ŏ擾��������)
    ln_trading_cost                 NUMBER         DEFAULT 0;      --�Z�o�����c�ƌ���
    ln_tax_rate                     NUMBER;                        --����ŗ�
    ln_selling_amt                  NUMBER         DEFAULT 0;      --�Z�o����������z
    ln_selling_amt_no_tax           NUMBER         DEFAULT 0;      --�Z�o����������z(�Ŕ���)
    lv_store_delivery_date          VARCHAR2(10)   DEFAULT NULL;   --�X�ܔ[�i��(YYYY/MM/DD�ϊ���)
    lb_retcode                      BOOLEAN        DEFAULT NULL;   --���b�Z�[�W�o�̖͂߂�l
    -- =======================
    -- ���[�J���J�[�\��
    -- =======================
    -- ==================================================================================
    -- ���i�R�[�h��i�ڃR�[�h�ɕϊ�
    -- ==================================================================================
    CURSOR get_item_code_cur
    IS
      SELECT  msib.inventory_item_id           AS inventory_item_id             --�i��ID
            , msib.segment1                    AS item_code                     --�i�ڃR�[�h
            , msib.customer_order_enabled_flag AS customer_order_enabled_flag   --�ڋq�󒍉\�t���O
            , iimb.attribute26                 AS selling_type                  --����Ώۋ敪
            , iimb.attribute11                 AS case_qty                      --�P�[�X����
      FROM    mtl_system_items_b   msib   --�i�ڃ}�X�^
            , ic_item_mst_b        iimb   --OPM�i�ڃ}�X�^
            , xxcmm_system_items_b xsib   --�i�ڃ}�X�^�A�h�I��
      WHERE   msib.segment1         = xsib.item_code
      AND     msib.segment1         = iimb.item_no
      AND     xsib.case_jan_code    = iv_goods_code_2
      AND     msib.organization_id  = gn_organization_id;
    -- =======================
    -- ���[�J�����R�[�h
    -- =======================
    get_item_code_rec  get_item_code_cur%ROWTYPE;
    -- =======================
    -- ���[�J����O
    -- =======================
    chk_data_expt  EXCEPTION;   --�f�[�^�`�F�b�N�G���[
--
  BEGIN
    ov_retcode := cv_status_normal;
    -- *** ���R�[�h�^�ɒl���Z�b�g(�������z(�o��)) ***
-- Start 2009/08/13 Ver.1.7 0000997 M.Hiruta REPAIR
--    ot_from_cust_rec.shipment_cost_amt := in_shipment_cost_amt;
--    ot_to_cust_rec.shipment_cost_amt   := in_shipment_cost_amt;
    ot_from_cust_rec.order_cost_amt := in_order_cost_amt;
    ot_to_cust_rec.order_cost_amt   := in_order_cost_amt;
-- End   2009/08/13 Ver.1.7 0000997 M.Hiruta REPAIR
    -- *** ���R�[�h�^�ɒl���Z�b�g(���i�R�[�h) ***
    ot_from_cust_rec.goods_code := iv_goods_code_2;
    ot_to_cust_rec.goods_code   := iv_goods_code_2;
    -- =============================================================================
    -- 1.�K�{���͍��ڂ̃`�F�b�N(�@�X�ܔ[�i��)
    -- =============================================================================
    IF ( id_store_delivery_date IS NULL ) THEN
      lv_msg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_xxcok_appl_name
                , iv_name         => cv_message_10373
                , iv_token_name1  => cv_token_delivery_date
                , iv_token_value1 => id_store_delivery_date
                , iv_token_name2  => cv_token_slip_no
                , iv_token_value2 => iv_slip_no
                , iv_token_name3  => cv_token_line_no
                , iv_token_value3 => in_line_no
                , iv_token_name4  => cv_token_edi_chain_code
                , iv_token_value4 => iv_edi_chain_store_code
                , iv_token_name5  => cv_token_center_code
                , iv_token_value5 => iv_delivery_to_center_code
                , iv_token_name6  => cv_token_store_code
                , iv_token_value6 => iv_store_code
                , iv_token_name7  => cv_token_qty
                , iv_token_value7 => in_order_qty_sum
                );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.OUTPUT   --�o�͋敪
                    , iv_message  => lv_msg            --���b�Z�[�W
                    , in_new_line => 0                 --���s
                    );
      RAISE chk_data_expt;
    END IF;
    -- *** ���R�[�h�^�ɒl���Z�b�g(����v���) ***
    ot_from_cust_rec.selling_date := id_store_delivery_date;
    ot_to_cust_rec.selling_date   := id_store_delivery_date;
    -- *** YYYY/MM/DD�^�ɕϊ� ***
    lv_store_delivery_date := TO_CHAR ( id_store_delivery_date, cv_date_format );
    -- =============================================================================
    -- 1.�K�{���͍��ڂ̃`�F�b�N(�A�`�[�ԍ�)
    -- =============================================================================
    IF (   ( iv_slip_no IS NULL )
        OR ( iv_slip_no = cv_0  )
       ) THEN
      lv_msg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_xxcok_appl_name
                , iv_name         => cv_message_10374
                , iv_token_name1  => cv_token_delivery_date
                , iv_token_value1 => lv_store_delivery_date
                , iv_token_name2  => cv_token_slip_no
                , iv_token_value2 => iv_slip_no
                , iv_token_name3  => cv_token_line_no
                , iv_token_value3 => in_line_no
                , iv_token_name4  => cv_token_edi_chain_code
                , iv_token_value4 => iv_edi_chain_store_code
                , iv_token_name5  => cv_token_center_code
                , iv_token_value5 => iv_delivery_to_center_code
                , iv_token_name6  => cv_token_store_code
                , iv_token_value6 => iv_store_code
                , iv_token_name7  => cv_token_qty
                , iv_token_value7 => in_order_qty_sum
                );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.OUTPUT   --�o�͋敪
                    , iv_message  => lv_msg            --���b�Z�[�W
                    , in_new_line => 0                 --���s
                    );
      RAISE chk_data_expt;
    END IF;
    -- =============================================================================
    -- 1.�K�{���͍��ڂ̃`�F�b�N(�B�sNo)
    -- =============================================================================
    IF (   ( in_line_no IS NULL )
        OR ( in_line_no = cn_0  )
       ) THEN
      lv_msg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_xxcok_appl_name
                , iv_name         => cv_message_10375
                , iv_token_name1  => cv_token_delivery_date
                , iv_token_value1 => lv_store_delivery_date
                , iv_token_name2  => cv_token_slip_no
                , iv_token_value2 => iv_slip_no
                , iv_token_name3  => cv_token_line_no
                , iv_token_value3 => in_line_no
                , iv_token_name4  => cv_token_edi_chain_code
                , iv_token_value4 => iv_edi_chain_store_code
                , iv_token_name5  => cv_token_center_code
                , iv_token_value5 => iv_delivery_to_center_code
                , iv_token_name6  => cv_token_store_code
                , iv_token_value6 => iv_store_code
                , iv_token_name7  => cv_token_qty
                , iv_token_value7 => in_order_qty_sum
                );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.OUTPUT   --�o�͋敪
                    , iv_message  => lv_msg            --���b�Z�[�W
                    , in_new_line => 0                 --���s
                    );
      RAISE chk_data_expt;
    END IF;
    -- =============================================================================
    -- 1.�K�{���͍��ڂ̃`�F�b�N(�CEDI�`�F�[���X�R�[�h)
    -- =============================================================================
    IF ( iv_edi_chain_store_code IS NULL ) THEN
      lv_msg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_xxcok_appl_name
                , iv_name         => cv_message_10376
                , iv_token_name1  => cv_token_delivery_date
                , iv_token_value1 => lv_store_delivery_date
                , iv_token_name2  => cv_token_slip_no
                , iv_token_value2 => iv_slip_no
                , iv_token_name3  => cv_token_line_no
                , iv_token_value3 => in_line_no 
                , iv_token_name4  => cv_token_edi_chain_code
                , iv_token_value4 => iv_edi_chain_store_code
                , iv_token_name5  => cv_token_center_code
                , iv_token_value5 => iv_delivery_to_center_code
                , iv_token_name6  => cv_token_store_code
                , iv_token_value6 => iv_store_code
                , iv_token_name7  => cv_token_qty
                , iv_token_value7 => in_order_qty_sum
                );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.OUTPUT   --�o�͋敪
                    , iv_message  => lv_msg            --���b�Z�[�W
                    , in_new_line => 0                 --���s
                    );
      RAISE chk_data_expt;
    END IF;
    -- *** ���R�[�h�^�ɒl���Z�b�g(EDI�`�F�[���X�R�[�h) ***
    ot_from_cust_rec.edi_chain_store_code := iv_edi_chain_store_code;
    ot_to_cust_rec.edi_chain_store_code   := iv_edi_chain_store_code;
    -- =============================================================================
    -- 1.�K�{���͍��ڂ̃`�F�b�N(�D�[����Z���^�[�R�[�h)
    -- =============================================================================
    IF ( iv_delivery_to_center_code IS NULL ) THEN
      lv_msg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_xxcok_appl_name
                , iv_name         => cv_message_10377
                , iv_token_name1  => cv_token_delivery_date
                , iv_token_value1 => lv_store_delivery_date
                , iv_token_name2  => cv_token_slip_no
                , iv_token_value2 => iv_slip_no
                , iv_token_name3  => cv_token_line_no
                , iv_token_value3 => in_line_no 
                , iv_token_name4  => cv_token_edi_chain_code
                , iv_token_value4 => iv_edi_chain_store_code
                , iv_token_name5  => cv_token_center_code
                , iv_token_value5 => iv_delivery_to_center_code
                , iv_token_name6  => cv_token_store_code
                , iv_token_value6 => iv_store_code
                , iv_token_name7  => cv_token_qty
                , iv_token_value7 => in_order_qty_sum
                );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.OUTPUT   --�o�͋敪
                    , iv_message  => lv_msg            --���b�Z�[�W
                    , in_new_line => 0                 --���s
                    );
      RAISE chk_data_expt;
    END IF;
     -- *** ���R�[�h�^�ɒl���Z�b�g(�[����Z���^�[�R�[�h) ***
    ot_from_cust_rec.delivery_to_center_code := iv_delivery_to_center_code;
    ot_to_cust_rec.delivery_to_center_code   := iv_delivery_to_center_code;
     -- =============================================================================
    -- 1.�K�{���͍��ڂ̃`�F�b�N(�E�X�R�[�h)
    -- =============================================================================
    IF ( iv_store_code IS NULL ) THEN
      lv_msg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_xxcok_appl_name
                , iv_name         => cv_message_10378
                , iv_token_name1  => cv_token_delivery_date
                , iv_token_value1 => lv_store_delivery_date
                , iv_token_name2  => cv_token_slip_no
                , iv_token_value2 => iv_slip_no
                , iv_token_name3  => cv_token_line_no
                , iv_token_value3 => in_line_no 
                , iv_token_name4  => cv_token_edi_chain_code
                , iv_token_value4 => iv_edi_chain_store_code
                , iv_token_name5  => cv_token_center_code
                , iv_token_value5 => iv_delivery_to_center_code
                , iv_token_name6  => cv_token_store_code
                , iv_token_value6 => iv_store_code
                , iv_token_name7  => cv_token_qty
                , iv_token_value7 => in_order_qty_sum
                );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.OUTPUT   --�o�͋敪
                    , iv_message  => lv_msg            --���b�Z�[�W
                    , in_new_line => 0                 --���s
                    );
      RAISE chk_data_expt;
    END IF;
     -- *** ���R�[�h�^�ɒl���Z�b�g(�X�R�[�h) ***
    ot_from_cust_rec.store_code := iv_store_code;
    ot_to_cust_rec.store_code   := iv_store_code;
    -- =============================================================================
    -- 1.�K�{���͍��ڂ̃`�F�b�N(�F����)
    -- =============================================================================
    IF (   ( in_order_qty_sum IS NULL )
        OR ( in_order_qty_sum = cn_0  )
       ) THEN
      lv_msg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_xxcok_appl_name
                , iv_name         => cv_message_10379
                , iv_token_name1  => cv_token_delivery_date
                , iv_token_value1 => lv_store_delivery_date
                , iv_token_name2  => cv_token_slip_no
                , iv_token_value2 => iv_slip_no
                , iv_token_name3  => cv_token_line_no
                , iv_token_value3 => in_line_no 
                , iv_token_name4  => cv_token_edi_chain_code
                , iv_token_value4 => iv_edi_chain_store_code
                , iv_token_name5  => cv_token_center_code
                , iv_token_value5 => iv_delivery_to_center_code
                , iv_token_name6  => cv_token_store_code
                , iv_token_value6 => iv_store_code
                , iv_token_name7  => cv_token_qty
                , iv_token_value7 => in_order_qty_sum
                );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.OUTPUT   --�o�͋敪
                    , iv_message  => lv_msg            --���b�Z�[�W
                    , in_new_line => 0                 --���s
                    );
      RAISE chk_data_expt;
    END IF;
    -- =============================================================================
    -- 2.B-2�Ŏ擾�����[����Z���^�[�R�[�h���g�p���A ����U�֌��ڋq�R�[�h�̕ϊ�
    -- =============================================================================
    get_cust_code(
      ov_errbuf               => lv_errbuf                    --�G���[���b�Z�[�W
    , ov_retcode              => lv_retcode                   --���^�[���R�[�h
    , ov_errmsg               => lv_errmsg                    --���[�U�[�G���[���b�Z�[�W
    , iv_message_code         => cv_message_10076             --���b�Z�[�W�R�[�h
    , iv_edi_chain_store_code => iv_edi_chain_store_code      --EDI�`�F�[���X�R�[�h
    , iv_code                 => iv_delivery_to_center_code   --�[����Z���^�[�R�[�h
-- Start 2009/08/13 Ver.1.7 0000997 M.Hiruta REPAIR
--    , in_shipment_unit_price  => in_shipment_unit_price       --�[�i�P��
    , in_order_unit_price     => in_order_unit_price          --�[�i�P��
-- End   2009/08/13 Ver.1.7 0000997 M.Hiruta REPAIR
    , iv_token                => cv_token_center_code         --�g�[�N����
    , ov_sale_base_code       => lv_sale_base_code            --���_�R�[�h
    , ov_account_number       => lv_from_account_number       --�ڋq�R�[�h
    , ov_sales_stuff_code     => lv_sales_stuff_code          --�S���c�ƃR�[�h
    , ov_business_low_type    => lv_business_low_type         --�ڋq�Ƒԋ敪
    , on_price_list_id        => ln_price_list_id             --���i�\ID
    );
    IF ( lv_retcode = cv_status_warn ) THEN
      RAISE chk_data_expt;
    ELSIF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
    -- *** ���R�[�h�^�ɒl���Z�b�g ***
    ot_from_cust_rec.base_code              := lv_sale_base_code;         --���_�R�[�h
    ot_from_cust_rec.cust_code              := lv_from_account_number;    --�ڋq�R�[�h
    ot_from_cust_rec.selling_emp_code       := lv_sales_stuff_code;       --�S���c�ƃR�[�h
    ot_from_cust_rec.cust_state_type        := lv_business_low_type;      --�ڋq�Ƒԋ敪
    ot_from_cust_rec.selling_from_base_code := lv_sale_base_code;         --����U�֌����_�R�[�h
    ot_from_cust_rec.selling_from_cust_code := lv_from_account_number;    --����U�֌��ڋq�R�[�h
    ot_to_cust_rec.selling_from_base_code   := lv_sale_base_code;         --����U�֌����_�R�[�h
    ot_to_cust_rec.selling_from_cust_code   := lv_from_account_number;    --����U�֌��ڋq�R�[�h
    -- =============================================================================
    -- 3.B-2�Ŏ擾�����X�R�[�h���g�p���āA����U�֐�ڋq�R�[�h�̕ϊ�
    -- =============================================================================
    get_cust_code(
      ov_errbuf               => lv_errbuf                    --�G���[���b�Z�[�W
    , ov_retcode              => lv_retcode                   --���^�[���R�[�h
    , ov_errmsg               => lv_errmsg                    --���[�U�[�G���[���b�Z�[�W
    , iv_message_code         => cv_message_10077             --���b�Z�[�W�R�[�h
    , iv_edi_chain_store_code => iv_edi_chain_store_code      --EDI�`�F�[���X�R�[�h
    , iv_code                 => iv_store_code                --�X�R�[�h
-- Start 2009/08/13 Ver.1.7 0000997 M.Hiruta REPAIR
--    , in_shipment_unit_price  => in_shipment_unit_price       --�[�i�P��
    , in_order_unit_price     => in_order_unit_price          --�[�i�P��
-- End   2009/08/13 Ver.1.7 0000997 M.Hiruta REPAIR
    , iv_token                => cv_token_store_code          --�g�[�N����
    , ov_sale_base_code       => lv_sale_base_code            --���_�R�[�h
    , ov_account_number       => lv_to_account_number         --�ڋq�R�[�h
    , ov_sales_stuff_code     => lv_sales_stuff_code          --�S���c�ƃR�[�h
    , ov_business_low_type    => lv_business_low_type         --�ڋq�Ƒԋ敪
    , on_price_list_id        => ln_price_list_id             --���i�\ID
    );
    IF ( lv_retcode = cv_status_warn ) THEN
      RAISE chk_data_expt;
    ELSIF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
    -- *** ���R�[�h�^�ɒl���Z�b�g ***
    ot_to_cust_rec.base_code        := lv_sale_base_code;        --���_�R�[�h
    ot_to_cust_rec.cust_code        := lv_to_account_number;     --�ڋq�R�[�h
    ot_to_cust_rec.selling_emp_code := lv_sales_stuff_code;      --�S���c�ƃR�[�h
    ot_to_cust_rec.cust_state_type  := lv_business_low_type;     --�ڋq�Ƒԋ敪
    -- =============================================================================
    -- 4.���i�R�[�h�̕ϊ�
    -- =============================================================================
    -- ===========================================
    -- (1)EDI�A�g�i�ڃR�[�h�敪�擾
    -- ===========================================
    BEGIN
      SELECT  xca2.edi_item_code_div AS edi_item_code_div
      INTO    lv_edi_item_code_div
      FROM    hz_cust_accounts    hca1       --�ڋq�}�X�^
            , xxcmm_cust_accounts xca1       --�ڋq�ǉ����
            , hz_cust_accounts    hca2       --EDI�`�F�[���X�}�X�^(�ڋq�}�X�^)
            , xxcmm_cust_accounts xca2       --EDI�`�F�[���X�}�X�^�ǉ����(�ڋq�ǉ����)
            , hz_parties          hp         --�p�[�e�B�}�X�^
      WHERE   hca1.account_number       = lv_to_account_number
      AND     hp.party_id               = hca1.party_id
      AND     hca1.customer_class_code  = cv_10
      AND     hca1.cust_account_id      = xca1.customer_id
-- Start 2009/07/13 Ver_1.6 0000514 M.Hiruta REPAIR
--      AND     hp.duns_number_c          = cv_40
      AND     hp.duns_number_c         IN( cv_30 , cv_40 , cv_50 )
-- End   2009/07/13 Ver_1.6 0000514 M.Hiruta REPAIR
      AND     xca1.selling_transfer_div = cv_1
      AND     xca1.chain_store_code     = xca2.edi_chain_code
      AND     hca2.cust_account_id      = xca2.customer_id
      AND     hca2.customer_class_code  = cv_18;
    EXCEPTION
      -- ==================================================================================
      -- EDI�A�g�i�ڃR�[�h�敪���擾�ł��Ȃ������ꍇ�A��O����
      -- ==================================================================================
      WHEN NO_DATA_FOUND THEN
        lv_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_xxcok_appl_name
                  , iv_name         => cv_message_10073
                  , iv_token_name1  => cv_token_edi_chain_code
                  , iv_token_value1 => iv_edi_chain_store_code
                  , iv_token_name2  => cv_token_customer_code
                  , iv_token_value2 => lv_to_account_number
                  );
        lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which    => FND_FILE.OUTPUT   --�o�͋敪
                      , iv_message  => lv_msg            --���b�Z�[�W
                      , in_new_line => 0                 --���s
                      );
        RAISE chk_data_expt;
    END;
    -- ==================================================================================
    -- EDI�A�g�i�ڃR�[�h�敪��'1'(�ڋq�i��)�܂��́A'2'(JAN�R�[�h)�ȊO�̏ꍇ�A��O����
    -- ==================================================================================
    IF NOT(   ( lv_edi_item_code_div = cv_1 )
           OR ( lv_edi_item_code_div = cv_2 )
          ) THEN
      lv_msg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_xxcok_appl_name
                , iv_name         => cv_message_10073
                , iv_token_name1  => cv_token_edi_chain_code
                , iv_token_value1 => iv_edi_chain_store_code
                , iv_token_name2  => cv_token_customer_code
                , iv_token_value2 => lv_to_account_number
                );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.OUTPUT   --�o�͋敪
                    , iv_message  => lv_msg            --���b�Z�[�W
                    , in_new_line => 0                 --���s
                    );
      RAISE chk_data_expt;
    END IF;
    -- ==================================================================================
    -- (2)��L�Ŏ擾����EDI�A�g�i�ڃR�[�h�敪 = '2'(JAN�R�[�h)�̏ꍇ�A
    --    ���i�R�[�h��i�ڃR�[�h�ɕϊ�
    -- ==================================================================================
    IF ( lv_edi_item_code_div = cv_2 ) THEN
      BEGIN
        SELECT  msib.inventory_item_id           AS inventory_item_id             --�i��ID
              , msib.segment1                    AS item_code                     --�i�ڃR�[�h
              , msib.customer_order_enabled_flag AS customer_order_enabled_flag   --�ڋq�󒍉\�t���O
              , iimb.attribute26                 AS selling_type                  --����Ώۋ敪
              , msib.primary_unit_of_measure     AS primary_unit_of_measure       --�P��
        INTO    ln_item_id
              , lv_item_code
              , lv_customer_order_enabled_flag
              , lv_selling_type
              , lv_unit_type
        FROM    mtl_system_items_b msib    --�i�ڃ}�X�^
              , ic_item_mst_b      iimb    --OPM�i�ڃ}�X�^
        WHERE   msib.segment1         = iimb.item_no
        AND     iimb.attribute21      = iv_goods_code_2
        AND     msib.organization_id  = gn_organization_id;
        -- ==================================================================================
        -- �P�ʁA���ʂ�ݒ�
        -- ==================================================================================
        lv_unit_type := lv_unit_type;
        ln_qty       := in_order_qty_sum;
      EXCEPTION
        -- ==================================================================================
        -- (3)��L�Ŏ擾����EDI�A�g�i�ڃR�[�h�敪 = '2'(JAN�R�[�h) �̂Ƃ��A����
        --    ��L�ŕi�ڃR�[�h���ϊ��ł��Ȃ������ꍇ�A���i�R�[�h��i�ڃR�[�h�ɕϊ�
        -- ==================================================================================
        WHEN NO_DATA_FOUND THEN
          OPEN get_item_code_cur;
          <<cur_loop>>
          LOOP
            FETCH get_item_code_cur INTO get_item_code_rec;
            EXIT WHEN get_item_code_cur%NOTFOUND;
            -- *** �擾�����l�����[�J���ϐ��Ɋi�[ ***
            ln_item_id                     := get_item_code_rec.inventory_item_id;             --�i��ID
            lv_item_code                   := get_item_code_rec.item_code;                     --�i�ڃR�[�h
            lv_customer_order_enabled_flag := get_item_code_rec.customer_order_enabled_flag;   --�ڋq�󒍉\�t���O
            lv_selling_type                := get_item_code_rec.selling_type;                  --����Ώۋ敪
            ln_case_qty                    := get_item_code_rec.case_qty;                      --�P�[�X����
            -- ==================================================================================
            -- �P�ʁA���ʂ�ݒ�
            -- ==================================================================================
            lv_unit_type := gv_case_uom;
            ln_qty       := in_order_qty_sum * ln_case_qty;
          END LOOP cur_loop;
          CLOSE get_item_code_cur;
          -- ==================================================================================
          -- ���i�R�[�h�̕ϊ��Ɏ��s�����ꍇ�A��O����
          -- ==================================================================================
          IF ( lv_item_code IS NULL ) THEN
            lv_msg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_xxcok_appl_name
                      , iv_name         => cv_message_10079
                      , iv_token_name1  => cv_token_edi_item_code_type
                      , iv_token_value1 => lv_edi_item_code_div
                      , iv_token_name2  => cv_token_customer_code
                      , iv_token_value2 => lv_to_account_number
                      , iv_token_name3  => cv_token_shohin_code
                      , iv_token_value3 => iv_goods_code_2
                      , iv_token_name4  => cv_token_org_id
                      , iv_token_value4 => gn_organization_id
                      );
            lb_retcode := xxcok_common_pkg.put_message_f(
                            in_which    => FND_FILE.OUTPUT   --�o�͋敪
                          , iv_message  => lv_msg            --���b�Z�[�W
                          , in_new_line => 0                 --���s
                          );
            RAISE chk_data_expt;
          END IF;
      END;
    END IF;
    -- ==================================================================================
    -- ��L�Ŏ擾�����ڋq�󒍉\�t���O��'Y'(�󒍉\)�ȊO�̏ꍇ�A��O����
    -- ==================================================================================
    IF NOT( lv_customer_order_enabled_flag = cv_flag_y ) THEN
      lv_msg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_xxcok_appl_name
                , iv_name         => cv_message_10380
                , iv_token_name1  => cv_token_item_code
                , iv_token_value1 => lv_item_code
                , iv_token_name2  => cv_token_cust_order_e_flag
                , iv_token_value2 => lv_customer_order_enabled_flag
                );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.OUTPUT   --�o�͋敪
                    , iv_message  => lv_msg            --���b�Z�[�W
                    , in_new_line => 0                 --���s
                    );
      RAISE chk_data_expt;
    END IF;
    -- ==================================================================================
    -- ��L�Ŏ擾��������Ώۋ敪��'1'�ȊO�̏ꍇ�A��O����
    -- ==================================================================================
    IF NOT( lv_selling_type = cv_1 ) THEN
      lv_msg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_xxcok_appl_name
                , iv_name         => cv_message_10083
                , iv_token_name1  => cv_token_item_code
                , iv_token_value1 => lv_item_code
                , iv_token_name2  => cv_token_selling_type
                , iv_token_value2 => lv_selling_type
                );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.OUTPUT   --�o�͋敪
                    , iv_message  => lv_msg            --���b�Z�[�W
                    , in_new_line => 0                 --���s
                    );
      RAISE chk_data_expt;
    END IF;
    -- ==================================================================================
    -- (4)��L�Ŏ擾����EDI�A�g�i�ڃR�[�h�敪 = '1'(�ڋq�i��)�̏ꍇ
    --    ���i�R�[�h��i�ڃR�[�h�ɕϊ�
    -- ==================================================================================
    IF ( lv_edi_item_code_div = cv_1 ) THEN
      BEGIN
        SELECT  mcix.inventory_item_id           AS inventory_item_id             --�i��ID
              , msib.segment1                    AS item_code                     --�i�ڃR�[�h
              , mci.attribute1                   AS attribute1                    --�P��
              , msib.customer_order_enabled_flag AS customer_order_enabled_flag   --�ڋq�󒍉\�t���O
              , iimb.attribute26                 AS selling_type                  --����Ώۋ敪
        INTO    ln_item_id
              , lv_item_code
              , lv_unit_type
              , lv_customer_order_enabled_flag
              , lv_selling_type
        FROM    mtl_customer_items      mci    --�ڋq�i��
              , mtl_customer_item_xrefs mcix   --�ڋq�i�ڑ��ݎQ��
              , hz_cust_accounts        hca    --EDI�`�F�[���X�}�X�^(�ڋq�}�X�^)
              , xxcmm_cust_accounts     xca    --EDI�`�F�[���X�}�X�^�ǉ����(�ڋq�}�X�^�ǉ����)
              , mtl_system_items_b      msib   --�i�ڃ}�X�^
              , hz_parties              hp     --�p�[�e�B�}�X�^
              , ic_item_mst_b           iimb   --OPM�i�ڃ}�X�^
        WHERE   mci.customer_item_id     = mcix.customer_item_id
        AND     mci.customer_id          = hca.cust_account_id
        AND     hca.cust_account_id      = xca.customer_id
        AND     hp.party_id              = hca.party_id
        AND     xca.edi_chain_code       = iv_edi_chain_store_code
        AND     hp.duns_number_c         = cv_99
        AND     hca.customer_class_code  = cv_18
        AND     mci.inactive_flag        = cv_flag_n
        AND     mcix.inactive_flag       = cv_flag_n
        AND     mcix.inventory_item_id   = msib.inventory_item_id
        AND     mci.customer_item_number = iv_goods_code_2
        AND     msib.segment1            = iimb.item_no
        AND     msib.organization_id     = gn_organization_id;
        -- =============================================================================
        -- �P�ʁA���ʂ�ݒ�
        -- =============================================================================
        lv_unit_type := lv_unit_type;
        ln_qty       := in_order_qty_sum;
      EXCEPTION
        -- *** ��L�ŏ��i�R�[�h�̕ϊ��Ɏ��s�����ꍇ�A��O���� ***
        WHEN NO_DATA_FOUND THEN
          lv_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcok_appl_name
                    , iv_name         => cv_message_10079
                    , iv_token_name1  => cv_token_edi_item_code_type
                    , iv_token_value1 => lv_edi_item_code_div
                    , iv_token_name2  => cv_token_customer_code
                    , iv_token_value2 => lv_to_account_number
                    , iv_token_name3  => cv_token_shohin_code
                    , iv_token_value3 => iv_goods_code_2
                    , iv_token_name4  => cv_token_org_id
                    , iv_token_value4 => gn_organization_id
                    );
          lb_retcode := xxcok_common_pkg.put_message_f(
                          in_which    => FND_FILE.OUTPUT   --�o�͋敪
                        , iv_message  => lv_msg            --���b�Z�[�W
                        , in_new_line => 0                 --���s
                        );
          RAISE chk_data_expt;
      END;
      -- ==================================================================================
      -- ��L�Ŏ擾�����ڋq�󒍉\�t���O��'Y'(�󒍉\)�ȊO�̏ꍇ�A��O����
      -- ==================================================================================
      IF NOT( lv_customer_order_enabled_flag = cv_flag_y ) THEN
        lv_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_xxcok_appl_name
                  , iv_name         => cv_message_10380
                  , iv_token_name1  => cv_token_item_code
                  , iv_token_value1 => lv_item_code
                  , iv_token_name2  => cv_token_cust_order_e_flag
                  , iv_token_value2 => lv_customer_order_enabled_flag
                  );
        lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which    => FND_FILE.OUTPUT   --�o�͋敪
                      , iv_message  => lv_msg            --���b�Z�[�W
                      , in_new_line => 0                 --���s
                      );
        RAISE chk_data_expt;
      END IF;
      -- ==================================================================================
      -- ��L�Ŏ擾��������Ώۋ敪��'1'�ȊO�̏ꍇ�A��O����
      -- ==================================================================================
      IF NOT( lv_selling_type = cv_1 ) THEN
        lv_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_xxcok_appl_name
                  , iv_name         => cv_message_10083
                  , iv_token_name1  => cv_token_item_code
                  , iv_token_value1 => lv_item_code
                  , iv_token_name2  => cv_token_selling_type
                  , iv_token_value2 => lv_selling_type
                  );
        lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which    => FND_FILE.OUTPUT   --�o�͋敪
                      , iv_message  => lv_msg            --���b�Z�[�W
                      , in_new_line => 0                 --���s
                      );
        RAISE chk_data_expt;
      END IF;
    END IF;
    -- *** ���R�[�h�^�ɒl���Z�b�g(�i�ڃR�[�h) ***
    ot_from_cust_rec.item_code := lv_item_code;
    ot_to_cust_rec.item_code   := lv_item_code;
    -- *** ���R�[�h�^�ɒl���Z�b�g(����) ***
    ot_from_cust_rec.qty := ln_qty * -1;
    ot_to_cust_rec.qty   := ln_qty;
    -- =============================================================================
    -- 5.�P�ʂ̃`�F�b�N
    -- =============================================================================
    IF ( lv_unit_type IS NULL ) THEN
      lv_msg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_xxcok_appl_name
                , iv_name         => cv_message_10082
                , iv_token_name1  => cv_token_edi_chain_code
                , iv_token_value1 => iv_edi_chain_store_code
                , iv_token_name2  => cv_token_store_code
                , iv_token_value2 => iv_store_code
                , iv_token_name3  => cv_token_delivery_date
                , iv_token_value3 => lv_store_delivery_date
                , iv_token_name4  => cv_token_shohin_code
                , iv_token_value4 => iv_goods_code_2
                );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.OUTPUT   --�o�͋敪
                    , iv_message  => lv_msg            --���b�Z�[�W
                    , in_new_line => 0                 --���s
                    );
      RAISE chk_data_expt;
    END IF;
    -- *** ���R�[�h�^�ɒl���Z�b�g(�P��) ***
    ot_from_cust_rec.unit_type := lv_unit_type;
    ot_to_cust_rec.unit_type   := lv_unit_type;
    -- =============================================================================
    -- 6.�[�i�P���̎擾
    -- =============================================================================
    -- *** B-2�Ŏ擾�����[�i�P����ݒ� ***
-- Start 2009/08/13 Ver.1.7 0000997 M.Hiruta REPAIR
--    ln_unit_price := in_shipment_unit_price;
    ln_unit_price := in_order_unit_price;
-- End   2009/08/13 Ver.1.7 0000997 M.Hiruta REPAIR
    -- =============================================================================
    -- (1)B-2�Ŏ擾�����[�i�P����NULL�A�܂��́A0�̏ꍇ�A���ʊ֐����P�����擾
    -- =============================================================================
    IF (   ( ln_unit_price IS NULL )
        OR ( ln_unit_price = cn_0  )
       ) THEN
      ln_unit_price := xxcos_common2_pkg.get_unit_price(
                         in_inventory_item_id    => ln_item_id
                       , in_price_list_header_id => ln_price_list_id
                       , iv_uom_code             => lv_unit_type
                       );
      -- *** �P�����擾���擾�ł��Ȃ������ꍇ ***
      IF ( ln_unit_price < cn_0 ) THEN
        -- *** ���i�\���̎擾 ***
        SELECT qlht.name AS price_list_name  --���i�\��
        INTO   lv_price_list_name
        FROM   qp_list_headers_tl  qlht      --���i�\�w�b�_
        WHERE  qlht.list_header_id = ln_price_list_id
        AND    qlht.language       = USERENV('LANG');
--
        lv_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_xxcok_appl_name
                  , iv_name         => cv_message_10085
                  , iv_token_name1  => cv_token_edi_chain_code
                  , iv_token_value1 => iv_edi_chain_store_code
                  , iv_token_name2  => cv_token_item_code
                  , iv_token_value2 => lv_item_code
                  , iv_token_name3  => cv_token_price_list_name
                  , iv_token_value3 => lv_price_list_name
                  , iv_token_name4  => cv_token_unit_price_code
                  , iv_token_value4 => lv_unit_type
                  );
        lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which    => FND_FILE.OUTPUT   --�o�͋敪
                      , iv_message  => lv_msg            --���b�Z�[�W
                      , in_new_line => 0                 --���s
                      );
        RAISE chk_data_expt;
      END IF;
    END IF;
    -- *** ���R�[�h�^�ɒl���Z�b�g(�[�i�P��) ***
    ot_from_cust_rec.delivery_unit_price := ln_unit_price;
    ot_to_cust_rec.delivery_unit_price   := ln_unit_price;
    -- =============================================================================
    -- 7.�c�ƌ���(�i�ڒP��)�̎擾
    -- =============================================================================
    BEGIN
      SELECT iimb.attribute8 AS cost_item_unit_type
      INTO   lv_cost_item_unit_type
      FROM   ic_item_mst_b iimb     --OPM�i�ڃ}�X�^
      WHERE  iimb.item_no     = lv_item_code
      AND    iimb.attribute9 <= TO_CHAR( gd_prdate, cv_date_format );
      -- =============================================================================
      -- �c�ƌ������Z�o
      -- =============================================================================
      ln_trading_cost := TO_NUMBER( lv_cost_item_unit_type ) * ln_qty;
    EXCEPTION
      -- *** ��L�ŉc�ƌ���(�i�ڒP��)���擾�ł��Ȃ������ꍇ�A��O���� ***
      WHEN NO_DATA_FOUND THEN
        lv_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_xxcok_appl_name
                  , iv_name         => cv_message_10086
                  , iv_token_name1  => cv_token_item_code
                  , iv_token_value1 => lv_item_code
                  );
        lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which    => FND_FILE.OUTPUT   --�o�͋敪
                      , iv_message  => lv_msg            --���b�Z�[�W
                      , in_new_line => 0                 --���s
                      );
        RAISE chk_data_expt;
    END;
    -- *** ���R�[�h�^�ɒl���Z�b�g(�c�ƌ���) ***
    ot_from_cust_rec.trading_cost := ln_trading_cost * -1;
    ot_to_cust_rec.trading_cost   := ln_trading_cost;
    -- =============================================================================
    -- 8.����ł̌v�Z
    -- =============================================================================
    -- =========================================
    -- (1)����ŋ敪���擾
    -- =========================================
    BEGIN
      SELECT  xca.tax_div AS tax_div
      INTO    lv_tax_type
      FROM    hz_cust_accounts    hca    --�ڋq�}�X�^
            , xxcmm_cust_accounts xca    --�ڋq�ǉ����
      WHERE   hca.account_number  = lv_to_account_number
      AND     hca.cust_account_id = xca.customer_id;
--
      IF ( lv_tax_type IS NULL ) THEN
        RAISE NO_DATA_FOUND;
      END IF;
--
      IF NOT(   ( lv_tax_type = cv_1 )
             OR ( lv_tax_type = cv_2 )
             OR ( lv_tax_type = cv_3 )
             OR ( lv_tax_type = cv_4 )
            ) THEN
        RAISE NO_DATA_FOUND;
      END IF;
      -- ==================================================================================
      -- (2)����ŋ敪 = '2'(����(�`�[�ې�))�A'3'(����(�P������))�̏ꍇ�A����ŗ����擾
      -- ==================================================================================
      IF (   ( lv_tax_type = cv_2 )
          OR ( lv_tax_type = cv_3 )
         ) THEN
-- Start 2009/07/29 Ver_1.6 0000514 M.Hiruta REPAIR
--        SELECT  atca.tax_rate AS tax_rate
--        INTO    ln_tax_rate
--        FROM    ap_tax_codes_all  atca     --�ŃR�[�h�}�X�^
--              , fnd_lookup_values flv      --�Q�ƃ^�C�v
--        WHERE   flv.lookup_type  = cv_lookup_type
--        AND     flv.lookup_code  = lv_tax_type
--        AND     flv.enabled_flag = cv_flag_y
--        AND     gd_prdate BETWEEN flv.start_date_active
--                          AND     NVL( flv.end_date_active, gd_prdate )
--        AND     flv.language     = USERENV('LANG')
---- Start 2009/05/19 Ver_1.4 T1_1043 M.Hiruta
--        AND     atca.org_id      = gn_org_id
---- End   2009/05/19 Ver_1.4 T1_1043 M.Hiruta
--        AND     atca.name        = flv.attribute1;
        SELECT  avtab.tax_rate AS tax_rate
        INTO    ln_tax_rate
        FROM    ar_vat_tax_all_b  avtab    --�ŃR�[�h�}�X�^
              , fnd_lookup_values flv      --�Q�ƃ^�C�v
        WHERE   flv.lookup_type       = cv_lookup_type
        AND     flv.lookup_code       = lv_tax_type
        AND     flv.enabled_flag      = cv_flag_y
        AND     gd_prdate      BETWEEN flv.start_date_active
                               AND     NVL( flv.end_date_active, gd_prdate )
        AND     flv.language          = USERENV('LANG')
        AND     avtab.enabled_flag    = cv_flag_y
        AND     gd_prdate      BETWEEN avtab.start_date
                               AND     NVL( avtab.end_date, gd_prdate )
        AND     avtab.set_of_books_id = gn_set_of_books_id
        AND     avtab.org_id          = gn_org_id
        AND     avtab.tax_code        = flv.attribute1;
-- End   2009/07/29 Ver_1.6 0000514 M.Hiruta REPAIR
      END IF;
    EXCEPTION
      -- *** ��L�ŏ���ŋ敪�A�܂��́A����ŗ����擾�ł��Ȃ������ꍇ�A��O���� ***
      WHEN NO_DATA_FOUND THEN
        lv_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_xxcok_appl_name
                  , iv_name         => cv_message_10013
                  , iv_token_name1  => cv_token_customer_code
                  , iv_token_value1 => lv_to_account_number
                  , iv_token_name2  => cv_token_tax_type
                  , iv_token_value2 => lv_tax_type
                  );
        lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which    => FND_FILE.OUTPUT   --�o�͋敪
                      , iv_message  => lv_msg            --���b�Z�[�W
                      , in_new_line => 0                 --���s
                      );
        RAISE chk_data_expt;
    END;
    -- =============================================================================
    -- (3)����ł��v�Z
    -- =============================================================================
    -- =========================================================
    -- ����ŋ敪��'1'(�O��)�A'4'(�ΏۊO)�̏ꍇ
    -- =========================================================
    IF (   ( lv_tax_type = cv_1 )
        OR ( lv_tax_type = cv_4 )
       ) THEN
      ln_selling_amt        := ( ln_qty * ln_unit_price );   --������z
      ln_selling_amt_no_tax := ln_selling_amt;               --������z(�Ŕ���)
    -- =========================================================
    -- ����ŋ敪��'2'(����(�`�[))�A'3'(����(�P��)) �̏ꍇ
    -- =========================================================
    ELSIF (   ( lv_tax_type = cv_2 )
           OR ( lv_tax_type = cv_3 )
          ) THEN
      ln_selling_amt        := ( ln_qty * ln_unit_price );                                     --������z
      ln_selling_amt_no_tax := ROUND( ln_selling_amt / ( cn_1 + ln_tax_rate / cn_100 ), 0 );   --������z(�Ŕ���)
    END IF;
    -- *** ���R�[�h�^�ɒl���Z�b�g(������z) ***
    ot_from_cust_rec.selling_amt := ln_selling_amt * -1;
    ot_to_cust_rec.selling_amt   := ln_selling_amt;
    -- *** ���R�[�h�^�ɒl���Z�b�g(������z(�Ŕ�)) ***
    ot_from_cust_rec.selling_amt_no_tax := ln_selling_amt_no_tax * -1;
    ot_to_cust_rec.selling_amt_no_tax   := ln_selling_amt_no_tax;
    -- *** ���R�[�h�^�ɒl���Z�b�g(������z(����ŋ敪)) ***
    ot_from_cust_rec.tax_type := lv_tax_type;
    ot_to_cust_rec.tax_type   := lv_tax_type;
    -- *** ���R�[�h�^�ɒl���Z�b�g(������z(����ŗ�)) ***
    ot_from_cust_rec.tax_rate := ln_tax_rate;
    ot_to_cust_rec.tax_rate   := ln_tax_rate;
  EXCEPTION
    -- *** �f�[�^�`�F�b�N�G���[ ***
    WHEN chk_data_expt THEN
      ov_retcode  := cv_status_warn;
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END chk_data;
--
  /**********************************************************************************
   * Procedure Name   : get_edi_wk_tab
   * Description      : EDI���[�N�e�[�u�����o(B-2)
   ***********************************************************************************/
  PROCEDURE get_edi_wk_tab(
    ov_errbuf         OUT VARCHAR2    --�G���[�E���b�Z�[�W
  , ov_retcode        OUT VARCHAR2    --���^�[���E�R�[�h
  , ov_errmsg         OUT VARCHAR2    --���[�U�[�E�G���[�E���b�Z�[�W
  , iv_file_name      IN  VARCHAR2    --�t�@�C����
  , iv_execution_type IN  VARCHAR2)   --���s�敪
  IS
    -- =======================
    -- ���[�J���萔
    -- =======================
    cv_prg_name  CONSTANT VARCHAR2(15) := 'get_edi_wk_tab';    --�v���O������
    -- =======================
    -- ���[�J���ϐ�
    -- =======================
    lv_errbuf   VARCHAR2(5000) DEFAULT NULL;    --�G���[�E���b�Z�[�W
    lv_retcode  VARCHAR2(1)    DEFAULT NULL;    --���^�[���E�R�[�h
    lv_errmsg   VARCHAR2(5000) DEFAULT NULL;    --���[�U�[�E�G���[�E���b�Z�[�W
    lv_msg      VARCHAR2(5000) DEFAULT NULL;    --���b�Z�[�W�擾�ϐ�
    lb_retcode  BOOLEAN        DEFAULT NULL;    --���b�Z�[�W�o�̖͂߂�l
    -- =======================
    -- ���[�J����J�[�\��
    -- =======================
    CURSOR get_wk_edi_cur
    IS
      SELECT    xwest.edi_selling_trns_id     AS edi_selling_trns_id       --����ID
              , xwest.slip_no                 AS slip_no                   --�`�[�ԍ�
              , xwest.line_no                 AS line_no                   --�sNo
              , xwest.store_delivery_date     AS store_delivery_date       --�X�ܔ[�i��
-- Start 2009/06/08 Ver_1.5 T1_1354 M.Hiruta
--              , xwest.edi_chain_store_code    AS edi_chain_store_code      --EDI�`�F�[���X�R�[�h
--              , xwest.delivery_to_center_code AS delivery_to_center_code   --�[����Z���^�[�R�[�h
--              , xwest.store_code              AS store_code                --�X�R�[�h
--              , xwest.goods_code_2            AS goods_code_2              --���i�R�[�h2
              , LTRIM( xwest.edi_chain_store_code )    AS edi_chain_store_code      --EDI�`�F�[���X�R�[�h
              , LTRIM( xwest.delivery_to_center_code ) AS delivery_to_center_code   --�[����Z���^�[�R�[�h
              , LTRIM( xwest.store_code )              AS store_code                --�X�R�[�h
              , LTRIM( xwest.goods_code_2 )            AS goods_code_2              --���i�R�[�h2
-- End   2009/06/08 Ver_1.5 T1_1354 M.Hiruta
              , xwest.order_qty_sum           AS order_qty_sum             --����(��������(���v�A�o��))
-- Start 2009/08/13 Ver.1.7 0000997 M.Hiruta REPAIR
--              , xwest.shipment_unit_price     AS shipment_unit_price       --�[�i�P��(���P��(�o��))
--              , xwest.shipment_cost_amt       AS shipment_cost_amt         --�������z(�o��)
              , xwest.order_unit_price        AS order_unit_price          --�[�i�P��(���P��(����))
              , xwest.order_cost_amt          AS order_cost_amt            --�������z(����)
-- End   2009/08/13 Ver.1.7 0000997 M.Hiruta REPAIR
      FROM      xxcok_wk_edi_selling_trns xwest
      WHERE     xwest.status = DECODE( iv_execution_type,
                                       cv_1, cv_0,
                                       cv_2 )
      AND       iv_file_name = xwest.if_file_name
      ORDER BY  store_delivery_date     ASC
              , slip_no                 ASC
              , line_no                 ASC
              , edi_chain_store_code    ASC
              , delivery_to_center_code ASC
              , store_code              ASC;
    -- =======================
    -- ���[�J��TABLE�^
    -- =======================
    TYPE tab_type IS TABLE OF get_wk_edi_cur%ROWTYPE INDEX BY BINARY_INTEGER;
    l_get_wk_edi_cur_tab  tab_type;
    -- =======================
    -- ���[�J����O
    -- =======================
    get_edi_tbl_expt   EXCEPTION;   --EDI������ѐU�֏�񒊏o�G���[
--
  BEGIN
    ov_retcode := cv_status_normal;
    -- *** �J�[�\���I�[�v�� ***
    OPEN  get_wk_edi_cur;
    FETCH get_wk_edi_cur BULK COLLECT INTO l_get_wk_edi_cur_tab;
    CLOSE get_wk_edi_cur;
    -- *** �Ώی����J�E���g ***
    gn_target_cnt := l_get_wk_edi_cur_tab.COUNT;
    -- *** �f�[�^�����o�ł������m�F ***
    IF ( gn_target_cnt = cn_0 ) THEN
      RAISE get_edi_tbl_expt;
    END IF;
--
    <<loop_1>>
    FOR ln_idx IN 1 .. l_get_wk_edi_cur_tab.COUNT LOOP
      -- =============================================================================
      -- �f�[�^�`�F�b�N(B-3)�̌ďo��
      -- =============================================================================
      chk_data(
        ov_errbuf                  => lv_errbuf                                          --�G���[���b�Z�[�W
      , ov_retcode                 => lv_retcode                                         --���^�[���R�[�h
      , ov_errmsg                  => lv_errmsg                                          --���[�U�[�G���[���b�Z�[�W
      , ot_from_cust_rec           => g_from_cust_rec                                    --���R�[�h�^(�U�֌��ڋq�R�[�h)
      , ot_to_cust_rec             => g_to_cust_rec                                      --���R�[�h�^(�U�֐�ڋq�R�[�h)
      , id_store_delivery_date     => l_get_wk_edi_cur_tab( ln_idx ).store_delivery_date       --�X�ܔ[�i��
      , iv_slip_no                 => l_get_wk_edi_cur_tab( ln_idx ).slip_no                   --�`�[�ԍ�
      , in_line_no                 => l_get_wk_edi_cur_tab( ln_idx ).line_no                   --�s�ԍ�
      , iv_edi_chain_store_code    => l_get_wk_edi_cur_tab( ln_idx ).edi_chain_store_code      --EDI�`�F�[���X�R�[�h
      , iv_delivery_to_center_code => l_get_wk_edi_cur_tab( ln_idx ).delivery_to_center_code   --�[����Z���^�[�R�[�h
      , iv_store_code              => l_get_wk_edi_cur_tab( ln_idx ).store_code                --�X�R�[�h
      , in_order_qty_sum           => l_get_wk_edi_cur_tab( ln_idx ).order_qty_sum             --����
-- Start 2009/08/13 Ver.1.7 0000997 M.Hiruta REPAIR
--      , in_shipment_unit_price     => l_get_wk_edi_cur_tab( ln_idx ).shipment_unit_price       --�[�i�P��
      , in_order_unit_price        => l_get_wk_edi_cur_tab( ln_idx ).order_unit_price          --�[�i�P��
-- End   2009/08/13 Ver.1.7 0000997 M.Hiruta REPAIR
      , iv_goods_code_2            => l_get_wk_edi_cur_tab( ln_idx ).goods_code_2              --���i�R�[�h2
-- Start 2009/08/13 Ver.1.7 0000997 M.Hiruta REPAIR
--      , in_shipment_cost_amt       => l_get_wk_edi_cur_tab( ln_idx ).shipment_cost_amt         --�������z(�o��)
      , in_order_cost_amt          => l_get_wk_edi_cur_tab( ln_idx ).order_cost_amt            --�������z(����)
-- End   2009/08/13 Ver.1.7 0000997 M.Hiruta REPAIR
      );
      IF ( lv_retcode = cv_status_warn ) THEN
        ov_retcode := cv_status_warn;
      ELSIF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
      -- =============================================================================
      -- �ꎞ�\�쐬(B-4)�̌ďo��
      -- =============================================================================
      IF ( lv_retcode = cv_status_normal ) THEN
        ins_tmp_tbl(
          ov_errbuf        => lv_errbuf         --�G���[���b�Z�[�W
        , ov_retcode       => lv_retcode        --���^�[���R�[�h
        , ov_errmsg        => lv_errmsg         --���[�U�[�G���[���b�Z�[�W
        , it_from_cust_rec => g_from_cust_rec   --���R�[�h�^(�U�֌��ڋq�R�[�h)
        , it_to_cust_rec   => g_to_cust_rec     --���R�[�h�^(�U�֐�ڋq�R�[�h)
        );
        IF ( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        END IF;
        -- =============================================================================
        -- EDI���[�N�e�[�u���X�V(����)(B-8)�̌ďo��
        -- =============================================================================
        upd_edi_tbl_normal(
          ov_errbuf                  => lv_errbuf                                           --�G���[���b�Z�[�W
        , ov_retcode                 => lv_retcode                                          --���^�[���R�[�h
        , ov_errmsg                  => lv_errmsg                                           --���[�U�[�G���[���b�Z�[�W
        , in_edi_selling_info_wk_id  => l_get_wk_edi_cur_tab( ln_idx ).edi_selling_trns_id     --����ID
        , iv_edi_chain_store_code    => l_get_wk_edi_cur_tab( ln_idx ).edi_chain_store_code    --EDI�`�F�[���X�R�[�h
        , iv_delivery_to_center_code => l_get_wk_edi_cur_tab( ln_idx ).delivery_to_center_code --�[����Z���^�[�R�[�h
        , iv_store_code              => l_get_wk_edi_cur_tab( ln_idx ).store_code              --�X�R�[�h
        , iv_goods_code              => l_get_wk_edi_cur_tab( ln_idx ).goods_code_2            --���i�R�[�h
-- Start 2009/08/13 Ver.1.7 0000997 M.Hiruta REPAIR
--        , in_delivery_unit_price     => l_get_wk_edi_cur_tab( ln_idx ).shipment_unit_price     --�[�i�P��
        , in_delivery_unit_price     => l_get_wk_edi_cur_tab( ln_idx ).order_unit_price        --�[�i�P��
-- End   2009/08/13 Ver.1.7 0000997 M.Hiruta REPAIR
        );
        IF ( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        END IF;
      -- =============================================================================
      --  EDI���[�N�e�[�u���X�V(�G���[)(B-7)�֑J��
      -- =============================================================================
      ELSIF ( lv_retcode = cv_status_warn ) THEN
        upd_edi_tbl_error(
          ov_errbuf                 => lv_errbuf                                            --�G���[���b�Z�[�W
        , ov_retcode                => lv_retcode                                           --���^�[���R�[�h
        , ov_errmsg                 => lv_errmsg                                            --���[�U�[�G���[���b�Z�[�W
        , in_edi_selling_info_wk_id => l_get_wk_edi_cur_tab( ln_idx ).edi_selling_trns_id   --����ID
        , iv_slip_no                => l_get_wk_edi_cur_tab( ln_idx ).slip_no               --�`�[�ԍ�
        , in_line_no                => l_get_wk_edi_cur_tab( ln_idx ).line_no               --�sNo
        );
        IF ( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        END IF;
      END IF;
    END LOOP loop_1;
  EXCEPTION
    -- *** �擾�Ɏ��s�����ꍇ�A��O���� ***
    WHEN get_edi_tbl_expt THEN
      lv_msg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_xxcok_appl_name
                , iv_name         => cv_message_10074
                , iv_token_name1  => cv_token_type
                , iv_token_value1 => iv_execution_type
                );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.OUTPUT   --�o�͋敪
                    , iv_message  => lv_msg            --���b�Z�[�W
                    , in_new_line => 0                 --���s
                    );
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_msg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END get_edi_wk_tab;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(B-1)
   ***********************************************************************************/
  PROCEDURE init(
    ov_errbuf         OUT VARCHAR2    --�G���[�E���b�Z�[�W
  , ov_retcode        OUT VARCHAR2    --���^�[���E�R�[�h
  , ov_errmsg         OUT VARCHAR2    --���[�U�[�E�G���[�E���b�Z�[�W
  , iv_file_name      IN  VARCHAR2    --�t�@�C����
  , iv_execution_type IN  VARCHAR2)   --���s�敪
  IS
    -- =======================
    -- ���[�J���萔
    -- =======================
    cv_prg_name  CONSTANT VARCHAR2(5) := 'init';    --�v���O������
    -- =======================
    -- ���[�J���ϐ�
    -- =======================
    lv_errbuf        VARCHAR2(5000) DEFAULT NULL;   --�G���[�E���b�Z�[�W
    lv_retcode       VARCHAR2(1)    DEFAULT NULL;   --���^�[���E�R�[�h
    lv_errmsg        VARCHAR2(5000) DEFAULT NULL;   --���[�U�[�E�G���[�E���b�Z�[�W
    lv_msg           VARCHAR2(5000) DEFAULT NULL;   --���b�Z�[�W�擾�ϐ�
    lv_tax_type      VARCHAR2(100)  DEFAULT NULL;   --�J�X�^���v���t�@�C��(�ېŔ�����ŏ���ŋ敪)
    lv_org_code      VARCHAR2(100)  DEFAULT NULL;   --�J�X�^���v���t�@�C��(�݌ɑg�D�R�[�h)
    lv_profile_code  VARCHAR2(100)  DEFAULT NULL;   --�v���t�@�C���l
    lb_retcode       BOOLEAN        DEFAULT NULL;   --���b�Z�[�W�o�̖͂߂�l
    -- =======================
    -- ���[�J����O
    -- =======================
    init_err_expt     EXCEPTION;   --init���G���[
    get_profile_expt  EXCEPTION;   --�v���t�@�C���l�擾�G���[
    get_process_expt  EXCEPTION;   --�Ɩ����t�擾�G���[
--
  BEGIN
    ov_retcode := cv_status_normal;
    -- =============================================================================
    -- 1.�R���J�����g�v���O�������͍��ڂ����b�Z�[�W�o��
    -- =============================================================================
        lv_msg := xxccp_common_pkg.get_msg(
                iv_application  => cv_xxcok_appl_name
              , iv_name         => cv_message_00006
              , iv_token_name1  => cv_token_file_name
              , iv_token_value1 => iv_file_name
              );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.OUTPUT   --�o�͋敪
                  , iv_message  => lv_msg            --���b�Z�[�W
                  , in_new_line => 0                 --���s
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.LOG      --�o�͋敪
                  , iv_message  => lv_msg            --���b�Z�[�W
                  , in_new_line => 0                 --���s
                  );
--
    lv_msg := xxccp_common_pkg.get_msg(
                iv_application  => cv_xxcok_appl_name
              , iv_name         => cv_message_00044
              , iv_token_name1  => cv_token_proc_type
              , iv_token_value1 => iv_execution_type
              );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.OUTPUT   --�o�͋敪
                  , iv_message  => lv_msg            --���b�Z�[�W
                  , in_new_line => 1                 --���s
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.LOG      --�o�͋敪
                  , iv_message  => lv_msg            --���b�Z�[�W
                  , in_new_line => 2                 --���s
                  );
    -- =============================================================================
    -- 2.�R���J�����g�v���O�������͍��ځA���s�敪�̃`�F�b�N
    -- =============================================================================
    IF NOT (   ( iv_execution_type = cv_1 )
            OR ( iv_execution_type = cv_2 )
           ) THEN
      lv_msg := xxccp_common_pkg.get_msg(
                 iv_application  => cv_xxcok_appl_name
                ,iv_name         => cv_message_10072
                ,iv_token_name1  => cv_token_type
                ,iv_token_value1 => iv_execution_type
              );
      lb_retcode := xxcok_common_pkg.put_message_f(
                       in_which    => FND_FILE.OUTPUT   --�o�͋敪
                      ,iv_message  => lv_msg            --���b�Z�[�W
                      ,in_new_line => 0                 --���s
      );
      RAISE init_err_expt;
    END IF;
    -- =============================================================================
    -- 3.�J�X�^���E�v���t�@�C���AEDI���폜���Ԃ̎擾
    -- =============================================================================
    gv_purge_term := FND_PROFILE.VALUE( cv_purge_term_profile );
--
    IF ( gv_purge_term IS NULL ) THEN
      lv_profile_code := cv_purge_term_profile;
      RAISE get_profile_expt;
    END IF;
    -- =============================================================================
    -- 4.�v���t�@�C���A�g�DID�̎擾
    -- =============================================================================
    gn_org_id := FND_PROFILE.VALUE( cv_org_id_profile );
--
    IF ( gn_org_id IS NULL ) THEN
      lv_profile_code := cv_org_id_profile;
      RAISE get_profile_expt;
    END IF;
    -- =============================================================================
    -- 5.�J�X�^���E�v���t�@�C���A�P�[�X�P�ʂ̎擾
    -- =============================================================================
    gv_case_uom := FND_PROFILE.VALUE( cv_case_uom_profile );
--
    IF ( gv_case_uom IS NULL ) THEN
      lv_profile_code := cv_case_uom_profile;
      RAISE get_profile_expt;
    END IF;
    -- =============================================================================
    -- 6.�J�X�^���E�v���t�@�C���A�݌ɑg�D�R�[�h�̎擾
    -- =============================================================================
    lv_org_code := FND_PROFILE.VALUE( cv_org_code_profile );
--
    IF ( lv_org_code IS NULL ) THEN
      lv_profile_code := cv_org_code_profile;
      RAISE get_profile_expt;
    END IF;
    -- =============================================================================
    -- 7.�݌ɑg�DID���擾
    -- =============================================================================
    gn_organization_id := xxcoi_common_pkg.get_organization_id(
                            iv_organization_code => lv_org_code
                          );
--
    IF ( gn_organization_id IS NULL ) THEN
      lv_msg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_xxcok_appl_name
                , iv_name         => cv_message_00013
                , iv_token_name1  => cv_token_org_code
                , iv_token_value1 => lv_org_code
                );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.OUTPUT   --�o�͋敪
                    , iv_message  => lv_msg            --���b�Z�[�W
                    , in_new_line => 0                 --���s
                    );
      RAISE init_err_expt;
    END IF;
    -- =============================================================================
    -- 8.�Ɩ����t���擾
    -- =============================================================================
    gd_prdate := xxccp_common_pkg2.get_process_date;
--
    IF ( gd_prdate IS NULL ) THEN
      RAISE get_process_expt;
    END IF;
-- Start 2009/07/29 Ver_1.6 0000514 M.Hiruta ADD
    -- =============================================================================
    -- 9.�v���t�@�C���A��v����ID�̎擾
    -- =============================================================================
    gn_set_of_books_id := FND_PROFILE.VALUE( cv_set_of_books_id );
--
    IF ( gn_set_of_books_id IS NULL ) THEN
      lv_profile_code := cv_set_of_books_id;
      RAISE get_profile_expt;
    END IF;
-- End   2009/07/29 Ver_1.6 0000514 M.Hiruta ADD
  EXCEPTION
    -- *** init���G���[ ***
    WHEN init_err_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_msg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** �v���t�@�C���l�擾�G���[ ***
    WHEN get_profile_expt THEN
      lv_msg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_xxcok_appl_name
                , iv_name         => cv_message_00003
                , iv_token_name1  => cv_token_profile
                , iv_token_value1 => lv_profile_code
                );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.OUTPUT   --�o�͋敪
                    , iv_message  => lv_msg            --���b�Z�[�W
                    , in_new_line => 0                 --���s
                    );
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_msg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** �Ɩ����t�擾�G���[ ***
    WHEN get_process_expt THEN
      lv_msg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_xxcok_appl_name
                , iv_name         => cv_message_00028
                );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.OUTPUT   --�o�͋敪
                    , iv_message  => lv_msg            --���b�Z�[�W
                    , in_new_line => 0                 --���s
                    );
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_msg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END init;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   ***********************************************************************************/
  PROCEDURE submain(
    ov_errbuf         OUT VARCHAR2    --�G���[�E���b�Z�[�W
  , ov_retcode        OUT VARCHAR2    --���^�[���E�R�[�h
  , ov_errmsg         OUT VARCHAR2    --���[�U�[�E�G���[�E���b�Z�[�W
  , iv_file_name      IN  VARCHAR2    --�t�@�C����
  , iv_execution_type IN  VARCHAR2)   --���s�敪
  IS
    -- =======================
    -- ���[�J���萔
    -- =======================
    cv_prg_name  CONSTANT VARCHAR2(10) := 'submain';   --�v���O������
    -- =======================
    -- ���[�J���ϐ�
    -- =======================
    lv_errbuf   VARCHAR2(5000) DEFAULT NULL;   --�G���[�E���b�Z�[�W
    lv_retcode  VARCHAR2(1)    DEFAULT NULL;   --���^�[���E�R�[�h
    lv_errmsg   VARCHAR2(5000) DEFAULT NULL;   --���[�U�[�E�G���[�E���b�Z�[�W
    lv_msg      VARCHAR2(5000) DEFAULT NULL;   --���b�Z�[�W�擾�ϐ�
    lb_retcode  BOOLEAN        DEFAULT NULL;   --���b�Z�[�W�o�̖͂߂�l
--
  BEGIN
    ov_retcode := cv_status_normal;
    -- =============================================================================
    -- ��������(B-1)�̌ďo��
    -- =============================================================================
    init(
      ov_errbuf         => lv_errbuf           --�G���[�E���b�Z�[�W
    , ov_retcode        => lv_retcode          --���^�[���E�R�[�h
    , ov_errmsg         => lv_errmsg           --���[�U�[�E�G���[�E���b�Z�[�W
    , iv_file_name      => iv_file_name        --�t�@�C����
    , iv_execution_type => iv_execution_type   --���s�敪
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
    -- =============================================================================
    -- EDI���[�N�e�[�u�����o(B-2)
    -- =============================================================================
    get_edi_wk_tab(
      ov_errbuf         => lv_errbuf           --�G���[�E���b�Z�[�W
    , ov_retcode        => lv_retcode          --���^�[���E�R�[�h
    , ov_errmsg         => lv_errmsg           --���[�U�[�E�G���[�E���b�Z�[�W
    , iv_file_name      => iv_file_name        --�t�@�C����
    , iv_execution_type => iv_execution_type   --���s�敪
    );
    IF ( lv_retcode = cv_status_warn ) THEN
      ov_retcode := cv_status_warn;
    ELSIF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
    -- =============================================================================
    -- ���ʁE������z�̏W�v(B-5)�̌ďo��
    -- =============================================================================
    IF ( gn_target_cnt > gn_warn_cnt ) THEN
      get_qty_amt_total(
        ov_errbuf  => lv_errbuf           --�G���[�E���b�Z�[�W
      , ov_retcode => lv_retcode          --���^�[���E�R�[�h
      , ov_errmsg  => lv_errmsg           --���[�U�[�E�G���[�E���b�Z�[�W
      );
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
    END IF;
    -- =============================================================================
    -- EDI���[�N�e�[�u���폜(B-9)�̌ďo��
    -- =============================================================================
    del_wk_tbl(
      ov_errbuf  => lv_errbuf    --�G���[�E���b�Z�[�W
    , ov_retcode => lv_retcode   --���^�[���E�R�[�h
    , ov_errmsg  => lv_errmsg    --���[�U�[�E�G���[�E���b�Z�[�W
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
  EXCEPTION
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END submain;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : �R���J�����g���s�t�@�C���o�^�v���V�[�W��
   ***********************************************************************************/
  PROCEDURE main(
    errbuf            OUT VARCHAR2    --�G���[�E���b�Z�[�W
  , retcode           OUT VARCHAR2    --���^�[���E�R�[�h
  , iv_file_name      IN  VARCHAR2    --�t�@�C����
  , iv_execution_type IN  VARCHAR2)   --���s�敪
  IS
    -- =======================
    -- ���[�J���萔
    -- =======================
    cv_prg_name  CONSTANT VARCHAR2(5) := 'main';   --�v���O������
    -- =======================
    -- ���[�J���ϐ�
    -- =======================
    lv_errbuf       VARCHAR2(5000) DEFAULT NULL;   --�G���[�E���b�Z�[�W
    lv_retcode      VARCHAR2(1)    DEFAULT NULL;   --���^�[���E�R�[�h
    lv_errmsg       VARCHAR2(5000) DEFAULT NULL;   --���[�U�[�E�G���[�E���b�Z�[�W
    lv_msg          VARCHAR2(5000) DEFAULT NULL;   --���b�Z�[�W�擾�ϐ�
    lv_message_code VARCHAR2(5000) DEFAULT NULL;   --���b�Z�[�W�R�[�h
    lb_retcode      BOOLEAN        DEFAULT NULL;   --���b�Z�[�W�o�̖͂߂�l
--
  BEGIN
    -- =============================================================================
    -- �R���J�����g�w�b�_���b�Z�[�W�o�͊֐��̌Ăяo��
    -- =============================================================================
    xxccp_common_pkg.put_log_header(
      ov_retcode => lv_retcode
    , ov_errbuf  => lv_errbuf
    , ov_errmsg  => lv_errmsg
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_expt;
    END IF;
    -- =============================================================================
    -- submain�̌ďo��
    -- =============================================================================
    submain(
      ov_errbuf         => lv_errbuf           --�G���[�E���b�Z�[�W
    , ov_retcode        => lv_retcode          --���^�[���E�R�[�h
    , ov_errmsg         => lv_errmsg           --���[�U�[�E�G���[�E���b�Z�[�W
    , iv_execution_type => iv_execution_type   --���s�敪
    , iv_file_name      => iv_file_name        --�t�@�C����
    );
    -- =============================================================================
    -- �G���[�o��
    -- =============================================================================
    IF ( lv_retcode = cv_status_error ) THEN
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.OUTPUT   --�o�͋敪
                    , iv_message  => lv_errmsg         --���b�Z�[�W
                    , in_new_line => 1                 --���s
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.LOG      --�o�͋敪
                    , iv_message  => lv_errbuf         --���b�Z�[�W
                    , in_new_line => 0                 --���s
                    );
    END IF;
    -- =============================================================================
    -- �G���[�I���̏ꍇ�A���������A�X�L�b�v������0���ɂ��A�G���[������1���ɂ���B
    -- =============================================================================
    IF ( lv_retcode = cv_status_error ) THEN
      gn_normal_cnt := cn_0;
      gn_warn_cnt   := cn_0;
      gn_error_cnt  := cn_1;
    END IF;
    -- =============================================================================
    -- �x���I���̏ꍇ�A��s���o��
    -- =============================================================================
    IF ( lv_retcode = cv_status_warn ) THEN
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.OUTPUT   --�o�͋敪
                    , iv_message  => NULL              --���b�Z�[�W
                    , in_new_line => 1                 --���s
                    );
    END IF;
    -- =============================================================================
    -- �Ώی����o��
    -- =============================================================================
    lv_msg := xxccp_common_pkg.get_msg(
                iv_application  => cv_xxccp_appl_name
              , iv_name         => cv_message_90000
              , iv_token_name1  => cv_token_count
              , iv_token_value1 => TO_CHAR( gn_target_cnt )
              );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.OUTPUT     --�o�͋敪
                  , iv_message  => lv_msg              --���b�Z�[�W
                  , in_new_line => 0                   --���s
                  );
    -- =============================================================================
    -- ���������o��
    -- =============================================================================
    lv_msg := xxccp_common_pkg.get_msg(
                iv_application  => cv_xxccp_appl_name
              , iv_name         => cv_message_90001
              , iv_token_name1  => cv_token_count
              , iv_token_value1 => TO_CHAR( gn_normal_cnt )
              );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.OUTPUT     --�o�͋敪
                  , iv_message  => lv_msg              --���b�Z�[�W
                  , in_new_line => 0                   --���s
                  );
    -- =============================================================================
    -- �X�L�b�v�����o��
    -- =============================================================================
    IF ( lv_retcode = cv_status_normal ) THEN
      gn_warn_cnt := cn_0;
    END IF;
    lv_msg := xxccp_common_pkg.get_msg(
                iv_application  => cv_xxccp_appl_name
              , iv_name         => cv_message_90003
              , iv_token_name1  => cv_token_count
              , iv_token_value1 => TO_CHAR( gn_warn_cnt )
              );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.OUTPUT     --�o�͋敪
                  , iv_message  => lv_msg              --���b�Z�[�W
                  , in_new_line => 0                   --���s
                  );
    -- =============================================================================
    -- �G���[�����o��
    -- =============================================================================
    IF (   ( lv_retcode = cv_status_normal )
        OR ( lv_retcode = cv_status_warn   )
       ) THEN
      gn_error_cnt := cn_0;
    END IF;
    lv_msg := xxccp_common_pkg.get_msg(
                iv_application  => cv_xxccp_appl_name
              , iv_name         => cv_message_90002
              , iv_token_name1  => cv_token_count
              , iv_token_value1 => TO_CHAR( gn_error_cnt )
              );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.OUTPUT     --�o�͋敪
                  , iv_message  => lv_msg              --���b�Z�[�W
                  , in_new_line => 1                   --���s
                  );
    -- =============================================================================
    -- �����I�����b�Z�[�W���o��
    -- =============================================================================
    IF ( lv_retcode = cv_status_normal ) THEN
      lv_message_code := cv_message_90004;
    ELSIF ( lv_retcode = cv_status_warn ) THEN
      lv_message_code := cv_message_90005;
    ELSIF ( lv_retcode = cv_status_error ) THEN
      lv_message_code := cv_message_90006;
    END IF;
--
    lv_msg := xxccp_common_pkg.get_msg(
                iv_application => cv_xxccp_appl_name
              , iv_name        => lv_message_code
              );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.OUTPUT     --�o�͋敪
                  , iv_message  => lv_msg              --���b�Z�[�W
                  , in_new_line => 0                   --���s
                  );
    -- *** �X�e�[�^�X�Z�b�g ***
    retcode := lv_retcode;
    -- *** �I���X�e�[�^�X���G���[�̏ꍇ��ROLLBACK ***
    IF ( retcode = cv_status_error ) THEN
      ROLLBACK;
    END IF;
  EXCEPTION
    WHEN global_api_expt THEN
      errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      retcode := cv_status_error;
      ROLLBACK;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      retcode := cv_status_error;
      ROLLBACK;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      retcode := cv_status_error;
      ROLLBACK;
  END main;
END XXCOK007A01C;
/
