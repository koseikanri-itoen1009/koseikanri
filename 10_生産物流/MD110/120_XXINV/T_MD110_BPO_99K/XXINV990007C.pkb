CREATE OR REPLACE PACKAGE BODY xxinv990007c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxinv990007c(body)
 * Description      : �^�����捞�����̃A�b�v���[�h
 * MD.050           : �t�@�C���A�b�v���[�h            T_MD050_BPO_990
 * MD.070           : �^�����捞�����̃A�b�v���[�h  T_MD070_BPO_99K
 * Version          : 1.3
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  set_data_proc          �o�^�f�[�^�̐ݒ�
 *  parameter_check        �p�����[�^�`�F�b�N                              (K-1)
 *  relat_data_get         �֘A�f�[�^�擾                                  (K-2)
 *  get_upload_data_proc   �t�@�C���A�b�v���[�hIF�f�[�^�擾                (K-3)
 *  proper_check           �Ó����`�F�b�N                                  (K-4)
 *  insert_data            �f�[�^�o�^                                      (K-5)
 *  delete_tbl             �t�@�C���A�b�v���[�hIF�e�[�u���폜              (K-6)
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/04/10    1.0   Oracle �R�� ��_ ����쐬
 *  2008/04/25    1.1   Oracle �R�� ��_ �ύX�v��No68�Ή�
 *  2008/04/25    1.1   Oracle �R�� ��_ �ύX�v��No70�Ή�
 *  2008/04/28    1.2   Y.Kawano         �����ύX�v��No74�Ή�
 *  2008/05/28    1.3   Oracle �R�� ��_ �ύX�v��No124�Ή�
 *****************************************************************************************/
--
--#######################  �Œ�O���[�o���萔�錾�� START   #######################
--
  gv_status_normal CONSTANT VARCHAR2(1) := '0';
  gv_status_warn   CONSTANT VARCHAR2(1) := '1';
  gv_status_error  CONSTANT VARCHAR2(1) := '2';
  gv_sts_cd_normal CONSTANT VARCHAR2(1) := 'C';
  gv_sts_cd_warn   CONSTANT VARCHAR2(1) := 'G';
  gv_sts_cd_error  CONSTANT VARCHAR2(1) := 'E';
  gv_msg_part      CONSTANT VARCHAR2(3) := ' : ';
  gv_msg_dot       CONSTANT VARCHAR2(3) := '.';
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
  lock_expt                 EXCEPTION;     -- ���b�N�擾�G���[
--
  PRAGMA EXCEPTION_INIT(lock_expt, -54);
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  gv_pkg_name      CONSTANT VARCHAR2(100) := 'xxinv990007c';  -- �p�b�P�[�W��
  gv_c_msg_kbn     CONSTANT VARCHAR2(5)   := 'XXINV';         -- �A�v���P�[�V�����Z�k��
--
  -- �t�H�[�}�b�g�p�^�[�����ʃR�[�h
  gv_format_code_01      CONSTANT VARCHAR2(2) := '13';         -- �^��
  gv_format_code_02      CONSTANT VARCHAR2(2) := '14';         -- �x���^��
  gv_format_code_03      CONSTANT VARCHAR2(2) := '15';         -- �����^��
  gv_format_pat_01       CONSTANT VARCHAR2(1) := '1';          -- �O���p
  gv_format_pat_02       CONSTANT VARCHAR2(1) := '2';          -- �ɓ����Y�Ɨp
--
  -- ���b�Z�[�W�ԍ�
  gv_c_msg_99k_008       CONSTANT VARCHAR2(15) := 'APP-XXINV-10008'; -- �f�[�^�擾�G���[
  gv_c_msg_99k_016       CONSTANT VARCHAR2(15) := 'APP-XXINV-10015'; -- �p�����[�^�G���[
  gv_c_msg_99k_024       CONSTANT VARCHAR2(15) := 'APP-XXINV-10024'; -- �t�H�[�}�b�g�G���[
  gv_c_msg_99k_025       CONSTANT VARCHAR2(15) := 'APP-XXINV-10025'; -- �v���t�@�C���擾�G���[
  gv_c_msg_99k_032       CONSTANT VARCHAR2(15) := 'APP-XXINV-10032'; -- ���b�N�G���[
--
  gv_c_msg_99k_101       CONSTANT VARCHAR2(15) := 'APP-XXINV-00001'; -- �t�@�C����
  gv_c_msg_99k_103       CONSTANT VARCHAR2(15) := 'APP-XXINV-00003'; -- �A�b�v���[�h����
  gv_c_msg_99k_104       CONSTANT VARCHAR2(15) := 'APP-XXINV-00004'; -- �t�@�C���A�b�v���[�h����
  gv_c_msg_99k_106       CONSTANT VARCHAR2(15) := 'APP-XXINV-00006'; -- �t�H�[�}�b�g�p�^�[��
--
  -- �g�[�N��
  gv_c_tkn_param         CONSTANT VARCHAR2(15) := 'PARAMETER';
  gv_c_tkn_value         CONSTANT VARCHAR2(15) := 'VALUE';
  gv_c_tkn_name          CONSTANT VARCHAR2(15) := 'NAME';
  gv_c_tkn_item          CONSTANT VARCHAR2(15) := 'ITEM';
  gv_c_tkn_table         CONSTANT VARCHAR2(15) := 'TABLE';
--
  -- �v���t�@�C��
  gv_c_parge_term_009    CONSTANT VARCHAR2(20) := 'XXINV_PURGE_TERM_009';
  gv_c_parge_term_name   CONSTANT VARCHAR2(40) := '�p�[�W�Ώۊ��ԁF�^���A�h�I��';
--
  -- �N�C�b�N�R�[�h �^�C�v
  gv_c_lookup_type       CONSTANT VARCHAR2(30) := 'XXINV_FILE_OBJECT';
  gv_c_format_type       CONSTANT VARCHAR2(20) := '�t�H�[�}�b�g�p�^�[��';
--
  gv_user_id_name        CONSTANT VARCHAR2(10) := '���[�U�[ID';
  gv_file_id_name        CONSTANT VARCHAR2(24) := 'FILE_ID';
  gv_file_up_if_tbl      CONSTANT VARCHAR2(50) := '�t�@�C���A�b�v���[�h�C���^�t�F�[�X�e�[�u��';
--
  gv_period              CONSTANT VARCHAR2(1) := '.';      -- �s���I�h
  gv_comma               CONSTANT VARCHAR2(1) := ',';      -- �J���}
  gv_space               CONSTANT VARCHAR2(1) := ' ';      -- �X�y�[�X
  gv_err_msg_space       CONSTANT VARCHAR2(6) := '      '; -- �X�y�[�X�i6byte�j
  gv_classe_pay          CONSTANT VARCHAR2(1) := '1';      -- �x��
  gv_classe_ord          CONSTANT VARCHAR2(1) := '2';      -- ����
--
  -- �^���A�h�I���C���^�t�F�[�X�e�[�u���F���ږ�
  gv_delivery_code_n     CONSTANT VARCHAR2(50) := '�^���Ǝ�';
  gv_delivery_no_n       CONSTANT VARCHAR2(50) := '�z��No';
  gv_invoice_no_n        CONSTANT VARCHAR2(50) := '�����No';
  gv_delivery_classe_n   CONSTANT VARCHAR2(50) := '�z���敪';
  gv_charged_amount_n    CONSTANT VARCHAR2(50) := '�����^��';
  gv_qty_n               CONSTANT VARCHAR2(50) := '��';
  gv_weight_n            CONSTANT VARCHAR2(50) := '�d��';
  gv_distance_n          CONSTANT VARCHAR2(50) := '����';
  gv_many_rate_n         CONSTANT VARCHAR2(50) := '������';
  gv_congestion_n        CONSTANT VARCHAR2(50) := '�ʍs��';
  gv_picking_n           CONSTANT VARCHAR2(50) := '�s�b�L���O��';
  gv_consolid_n          CONSTANT VARCHAR2(50) := '���ڊ������z';
  gv_total_amount_n      CONSTANT VARCHAR2(50) := '���v';
--
  -- �^���A�h�I���C���^�t�F�[�X�e�[�u���F���ڌ���
  gv_delivery_code_l     CONSTANT NUMBER := 4;   -- �^���Ǝ�
  gv_delivery_no_l       CONSTANT NUMBER := 12;  -- �z��No
  gv_invoice_no_l        CONSTANT NUMBER := 20;  -- �����No
  gv_delivery_classe_l   CONSTANT NUMBER := 2;   -- �z���敪
  gv_charged_amount_l    CONSTANT NUMBER := 7;   -- �����^��
  gv_qty_l               CONSTANT NUMBER := 4;   -- ��
  gv_weight_l            CONSTANT NUMBER := 6;   -- �d��
  gv_distance_l          CONSTANT NUMBER := 4;   -- ����
  gv_many_rate_l         CONSTANT NUMBER := 7;   -- ������
  gv_congestion_l        CONSTANT NUMBER := 7;   -- �ʍs��
  gv_picking_l           CONSTANT NUMBER := 7;   -- �s�b�L���O��
  gv_consolid_l          CONSTANT NUMBER := 7;   -- ���ڊ������z
  gv_total_amount_l      CONSTANT NUMBER := 7;   -- ���v
--
  gv_decimal_len         CONSTANT NUMBER := 0;
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
--
  -- ***************************************
  -- ***    �擾���i�[���R�[�h�^��`   ***
  -- ***************************************
--
  -- CSV���i�[���郌�R�[�h
  TYPE file_data_rec IS RECORD(
    delivery_code     VARCHAR2(32767), -- �^���Ǝ�
    delivery_no       VARCHAR2(32767), -- �z��No
    invoice_no        VARCHAR2(32767), -- �����No
    delivery_classe   VARCHAR2(32767), -- �z���敪
    charged_amount    VARCHAR2(32767), -- �����^��
    qty               VARCHAR2(32767), -- ��
    weight            VARCHAR2(32767), -- �d��
    distance          VARCHAR2(32767), -- ����
    many_rate         VARCHAR2(32767), -- ������
    congestion        VARCHAR2(32767), -- �ʍs��
    picking           VARCHAR2(32767), -- �s�b�L���O��
    consolid          VARCHAR2(32767), -- ���ڊ������z
    total_amount      VARCHAR2(32767), -- ���v
--
    charged_amount_n  NUMBER, -- �����^��
    qty_n             NUMBER, -- ��
    many_rate_n       NUMBER, -- ������
    congestion_n      NUMBER, -- �ʍs��
    picking_n         NUMBER, -- �s�b�L���O��
    weight_n          NUMBER, -- �d��
    distance_n        NUMBER, -- ����
    consolid_n        NUMBER, -- ���ڊ������z
    total_amount_n    NUMBER, -- ���v
--
    line              VARCHAR2(32767), -- �s���e�S�āi��������p�j
    err_message       VARCHAR2(32767)  -- �G���[���b�Z�[�W�i��������p�j
  );
--
  -- CSV���i�[���錋���z��
  TYPE file_data_tbl IS TABLE OF file_data_rec INDEX BY BINARY_INTEGER;
--
  -- ***************************************
  -- ***      �o�^�p���ڃe�[�u���^       ***
  -- ***************************************
--
-- �p�^�[���敪
  TYPE reg_pattern_flag    IS TABLE OF xxwip_deliverys_if.pattern_flag          %TYPE INDEX BY BINARY_INTEGER;
-- �^���Ǝ�
  TYPE reg_delivery_code   IS TABLE OF xxwip_deliverys_if.delivery_company_code %TYPE INDEX BY BINARY_INTEGER;
-- �z��No
  TYPE reg_delivery_no     IS TABLE OF xxwip_deliverys_if.delivery_no           %TYPE INDEX BY BINARY_INTEGER;
-- �����No
  TYPE reg_invoice_no      IS TABLE OF xxwip_deliverys_if.invoice_no            %TYPE INDEX BY BINARY_INTEGER;
-- �x�������敪
  TYPE reg_p_b_classe      IS TABLE OF xxwip_deliverys_if.p_b_classe            %TYPE INDEX BY BINARY_INTEGER;
-- �z���敪
  TYPE reg_delivery_classe IS TABLE OF xxwip_deliverys_if.delivery_classe       %TYPE INDEX BY BINARY_INTEGER;
-- �����^��
  TYPE reg_charged_amount  IS TABLE OF xxwip_deliverys_if.charged_amount        %TYPE INDEX BY BINARY_INTEGER;
-- ���P
  TYPE reg_qty1            IS TABLE OF xxwip_deliverys_if.qty1                  %TYPE INDEX BY BINARY_INTEGER;
-- ���Q
  TYPE reg_qty2            IS TABLE OF xxwip_deliverys_if.qty2                  %TYPE INDEX BY BINARY_INTEGER;
-- �d�ʂP
  TYPE reg_weight1         IS TABLE OF xxwip_deliverys_if.delivery_weight1      %TYPE INDEX BY BINARY_INTEGER;
-- �d�ʂQ
  TYPE reg_weight2         IS TABLE OF xxwip_deliverys_if.delivery_weight2      %TYPE INDEX BY BINARY_INTEGER;
-- ����
  TYPE reg_distance        IS TABLE OF xxwip_deliverys_if.distance              %TYPE INDEX BY BINARY_INTEGER;
-- ������
  TYPE reg_many_rate       IS TABLE OF xxwip_deliverys_if.many_rate             %TYPE INDEX BY BINARY_INTEGER;
-- �ʍs��
  TYPE reg_congestion      IS TABLE OF xxwip_deliverys_if.congestion_charge     %TYPE INDEX BY BINARY_INTEGER;
-- �s�b�L���O��
  TYPE reg_picking         IS TABLE OF xxwip_deliverys_if.picking_charge        %TYPE INDEX BY BINARY_INTEGER;
-- ���ڊ������z
  TYPE reg_consolid        IS TABLE OF xxwip_deliverys_if.consolid_surcharge    %TYPE INDEX BY BINARY_INTEGER;
-- ���v
  TYPE reg_total           IS TABLE OF xxwip_deliverys_if.total_amount          %TYPE INDEX BY BINARY_INTEGER;
--
  -- ***************************************
  -- ***      ���ڊi�[�e�[�u���^��`     ***
  -- ***************************************
--
  gr_fdata_tbl                file_data_tbl;  -- CSV�t�@�C���i�[
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
--
  gv_purge_term               NUMBER;          -- �p�[�W�Ώۊ���
  gv_file_name                VARCHAR2(256);   -- �t�@�C����
  gv_file_up_name             VARCHAR2(256);   -- �t�@�C���A�b�v���[�h����
  gv_file_content_type        VARCHAR2(256);   -- �t�@�C�����������I�u�W�F�N�g�^�C�v�R�[�h
  gv_proper_check_retcode     VARCHAR2(1);     -- �Ó����`�F�b�N�X�e�[�^�X
  gv_delivery_code            VARCHAR2(100);   -- �^���Ǝ�
--
  -- �萔
  gn_created_by               NUMBER;          -- �쐬��
  gd_creation_date            DATE;            -- �쐬��
--
  gd_sysdate                  DATE;            -- �V�X�e�����t
  gn_user_id                  NUMBER;          -- ���[�UID
  gn_login_id                 NUMBER;          -- �ŏI�X�V���O�C��
  gn_conc_request_id          NUMBER;          -- �v��ID
  gn_prog_appl_id             NUMBER;          -- �R���J�����g�E�v���O�����̃A�v���P�[�V����ID
  gn_conc_program_id          NUMBER;          -- �R���J�����g�E�v���O����ID
--
  -- ���ڃe�[�u���^��`
  gt_pattern_flag          reg_pattern_flag;          -- �p�^�[���敪
  gt_delivery_code         reg_delivery_code;         -- �^���Ǝ�
  gt_delivery_no           reg_delivery_no;           -- �z��No
  gt_invoice_no            reg_invoice_no;            -- �����No
  gt_p_b_classe            reg_p_b_classe;            -- �x�������敪
  gt_delivery_classe       reg_delivery_classe;       -- �z���敪
  gt_charged_amount        reg_charged_amount;        -- �����^��
  gt_qty1                  reg_qty1;                  -- ���P
  gt_qty2                  reg_qty2;                  -- ���Q
  gt_weight1               reg_weight1;               -- �d�ʂP
  gt_weight2               reg_weight2;               -- �d�ʂQ
  gt_distance              reg_distance;              -- ����
  gt_many_rate             reg_many_rate;             -- ������
  gt_congestion            reg_congestion;            -- �ʍs��
  gt_picking               reg_picking;               -- �s�b�L���O��
  gt_consolid              reg_consolid;              -- ���ڊ������z
  gt_total                 reg_total;                 -- ���v
--
  /**********************************************************************************
   * Procedure Name   : set_data_proc
   * Description      : �o�^�f�[�^�̐ݒ�
   ***********************************************************************************/
  PROCEDURE set_data_proc(
    iv_file_format IN            VARCHAR2,   -- �t�H�[�}�b�g�p�^�[��
    ov_errbuf         OUT NOCOPY VARCHAR2,   -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode        OUT NOCOPY VARCHAR2,   -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg         OUT NOCOPY VARCHAR2)   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'set_data_proc'; -- �v���O������
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
    lr_file_rec         file_data_rec;
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    -- **************************************************
    -- *** �o�^�pPL/SQL�\�ҏW�i2�s�ڂ���j
    -- **************************************************
    <<data_set_loop>>
    FOR ln_index IN 1 .. gr_fdata_tbl.LAST LOOP
--
      lr_file_rec := gr_fdata_tbl(ln_index);
--
      gt_delivery_no(ln_index)    := lr_file_rec.delivery_no;           -- �z��No
      gt_invoice_no(ln_index)     := lr_file_rec.invoice_no;            -- �����No
      gt_charged_amount(ln_index) := lr_file_rec.charged_amount_n;      -- �����^��
      gt_congestion(ln_index)     := lr_file_rec.congestion_n;          -- �ʍs��
--
      -- �^���p
      IF (iv_file_format = gv_format_code_01) THEN
        gt_pattern_flag(ln_index)    := gv_format_pat_01;                -- �p�^�[���敪
        gt_delivery_code(ln_index)   := gv_delivery_code;                -- �^���Ǝ�
        gt_p_b_classe(ln_index)      := gv_classe_pay;                   -- �x�������敪
        gt_delivery_classe(ln_index) := NULL;                            -- �z���敪
        gt_qty1(ln_index)            := NULL;                            -- ���P
        gt_qty2(ln_index)            := lr_file_rec.qty_n;               -- ���Q
        gt_weight1(ln_index)         := NULL;                            -- �d�ʂP
        gt_weight2(ln_index)         := lr_file_rec.weight_n;            -- �d�ʂQ
        gt_distance(ln_index)        := NULL;                            -- ����
        gt_many_rate(ln_index)       := NULL;                            -- ������
        gt_picking(ln_index)         := NULL;                            -- �s�b�L���O��
        gt_consolid(ln_index)        := NULL;                            -- ���ڊ������z
        gt_total(ln_index)           := NULL;                            -- ���v
--
      -- �x���^���p
      ELSIF (iv_file_format = gv_format_code_02) THEN
        gt_pattern_flag(ln_index)    := gv_format_pat_02;                -- �p�^�[���敪
        gt_delivery_code(ln_index)   := lr_file_rec.delivery_code;       -- �^���Ǝ�
        gt_p_b_classe(ln_index)      := gv_classe_pay;                   -- �x�������敪
        gt_delivery_classe(ln_index) := lr_file_rec.delivery_classe;     -- �z���敪
        gt_qty1(ln_index)            := lr_file_rec.qty_n;               -- ���P
        gt_qty2(ln_index)            := NULL;                            -- ���Q
        gt_weight1(ln_index)         := lr_file_rec.weight_n;            -- �d�ʂP
        gt_weight2(ln_index)         := NULL;                            -- �d�ʂQ
        gt_distance(ln_index)        := lr_file_rec.distance_n;          -- ����
        gt_many_rate(ln_index)       := lr_file_rec.many_rate_n;         -- ������
        gt_picking(ln_index)         := lr_file_rec.picking_n;           -- �s�b�L���O��
        gt_consolid(ln_index)        := lr_file_rec.consolid;            -- ���ڊ������z
        gt_total(ln_index)           := lr_file_rec.total_amount_n;      -- ���v
--
      -- �����^���p
      ELSIF (iv_file_format = gv_format_code_03) THEN
        gt_pattern_flag(ln_index)    := gv_format_pat_02;                -- �p�^�[���敪
        gt_delivery_code(ln_index)   := lr_file_rec.delivery_code;       -- �^���Ǝ�
        gt_p_b_classe(ln_index)      := gv_classe_ord;                   -- �x�������敪
        gt_delivery_classe(ln_index) := NULL;                            -- �z���敪
        gt_qty1(ln_index)            := NULL;                            -- ���P
        gt_qty2(ln_index)            := NULL;                            -- ���Q
        gt_weight1(ln_index)         := NULL;                            -- �d�ʂP
        gt_weight2(ln_index)         := NULL;                            -- �d�ʂQ
        gt_distance(ln_index)        := NULL;                            -- ����
        gt_many_rate(ln_index)       := lr_file_rec.many_rate_n;         -- ������
        gt_picking(ln_index)         := lr_file_rec.picking_n;           -- �s�b�L���O��
        gt_consolid(ln_index)        := lr_file_rec.consolid;            -- ���ڊ������z
        gt_total(ln_index)           := lr_file_rec.total_amount_n;      -- ���v
      END IF;
--
    END LOOP data_set_loop;
--
    --==============================================================
    --���b�Z�[�W�o�́i�G���[�ȊO�j������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END set_data_proc;
--
  /***********************************************************************************
   * Procedure Name   : parameter_check
   * Description      : �p�����[�^�`�F�b�N(K-1)
   ***********************************************************************************/
  PROCEDURE parameter_check(
    iv_file_format IN            VARCHAR2,     -- 2.�t�H�[�}�b�g�p�^�[��
    ov_errbuf         OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode        OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg         OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'parameter_check'; -- �v���O������
--
--##############################  �Œ胍�[�J���ϐ��錾�� START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    ln_param_count   NUMBER;   -- �p�����[�^
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--################################  �Œ�X�e�[�^�X�������� START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  �Œ蕔 END   #############################################
--
    -- �t�H�[�}�b�g�p�^�[���`�F�b�N
    SELECT COUNT(xlvv.lookup_code)
    INTO   ln_param_count
    FROM   xxcmn_lookup_values_v xlvv          -- �N�C�b�N�R�[�hVIEW
    WHERE  xlvv.lookup_type = gv_c_lookup_type
    AND    xlvv.lookup_code = iv_file_format
    AND    ROWNUM           = 1;
--
    -- �t�H�[�}�b�g�p�^�[�����N�C�b�N�R�[�h�ɓo�^����Ă��Ȃ��ꍇ
    IF (ln_param_count < 1) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_c_msg_kbn,
                                            gv_c_msg_99k_016,
                                            gv_c_tkn_param,
                                            gv_c_format_type,
                                            gv_c_tkn_value,
                                            iv_file_format);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   #######################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   #############################################
--
  END parameter_check;
--
  /***********************************************************************************
   * Procedure Name   : relat_data_get
   * Description      : �֘A�f�[�^�擾(K-2)
   ***********************************************************************************/
  PROCEDURE relat_data_get(
    iv_file_format IN            VARCHAR2,     -- 2.�t�H�[�}�b�g�p�^�[��
    ov_errbuf         OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode        OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg         OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'relat_data_get'; -- �v���O������
--
--##############################  �Œ胍�[�J���ϐ��錾�� START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lv_purge_term               VARCHAR2(20);    -- �p�[�W�Ώۊ���
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--################################  �Œ�X�e�[�^�X�������� START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  �Œ蕔 END   #############################################
--
    -- WHO�J�������擾
    gn_user_id          := FND_GLOBAL.USER_ID;         -- ���[�UID
    gn_login_id         := FND_GLOBAL.LOGIN_ID;        -- �ŏI�X�V���O�C��
    gn_conc_request_id  := FND_GLOBAL.CONC_REQUEST_ID; -- �v��ID
    gn_prog_appl_id     := FND_GLOBAL.PROG_APPL_ID;    -- �ݶ��āE��۸��т̱��ع����ID
    gn_conc_program_id  := FND_GLOBAL.CONC_PROGRAM_ID; -- �R���J�����g�E�v���O����ID
--
    gd_sysdate                := SYSDATE;
--
    -- �p�[�W�Ώۊ��ԁF�^���A�h�I��
    lv_purge_term := FND_PROFILE.VALUE(gv_c_parge_term_009);
--
    -- �v���t�@�C�����擾�ł��Ȃ��ꍇ�̓G���[
    IF (lv_purge_term IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_c_msg_kbn,
                                            gv_c_msg_99k_025,
                                            gv_c_tkn_name,
                                            gv_c_parge_term_name);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- �v���t�@�C���l�`�F�b�N
    BEGIN
      gv_purge_term := TO_NUMBER(lv_purge_term);
--
    EXCEPTION
      WHEN INVALID_NUMBER OR VALUE_ERROR THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_c_msg_kbn,
                                              gv_c_msg_99k_025,
                                              gv_c_tkn_name,
                                              gv_c_parge_term_name);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
--
    -- �t�@�C���A�b�v���[�h���̎擾
    BEGIN
      SELECT  xlvv.meaning
      INTO    gv_file_up_name
      FROM    xxcmn_lookup_values_v xlvv                -- �N�C�b�N�R�[�hVIEW
      WHERE   xlvv.lookup_type = gv_c_lookup_type       -- �^�C�v
      AND     xlvv.lookup_code = iv_file_format         -- �R�[�h
      AND     ROWNUM           = 1;
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN   --*** �f�[�^�擾�G���[ ***
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_c_msg_kbn,
                                              gv_c_msg_99k_008,
                                              gv_c_tkn_item,
                                              gv_c_format_type,
                                              gv_c_tkn_value,
                                              iv_file_format);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
--
    -- �t�H�[�}�b�g�p�^�[�����u13�v�̏ꍇ
    IF (iv_file_format = gv_format_code_01) THEN
--
      -- �^���Ǝ҃R�[�h�擾
      BEGIN
        SELECT papf.attribute5
        INTO   gv_delivery_code
        FROM   fnd_user          fu
              ,per_all_people_f  papf
        WHERE  fu.employee_id = papf.person_id
        AND    TRUNC(SYSDATE) BETWEEN papf.effective_start_date AND papf.effective_end_date
        AND    fu.user_id     = gn_user_id;
--
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          gv_delivery_code := NULL;
--
        WHEN OTHERS THEN
          RAISE global_api_others_expt;
      END;
--
      -- ���Ə��R�[�h���擾�ł��Ȃ��ꍇ�̓G���[
      IF (gv_delivery_code IS NULL) THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_c_msg_kbn,
                                              gv_c_msg_99k_008,
                                              gv_c_tkn_item,
                                              gv_user_id_name,
                                              gv_c_tkn_value,
                                              gn_user_id);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
    END IF;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   #######################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   #############################################
--
  END relat_data_get;
--
  /***********************************************************************************
   * Procedure Name   : get_upload_data_proc
   * Description      : �t�@�C���A�b�v���[�hIF�f�[�^�擾(K-3)
   ***********************************************************************************/
  PROCEDURE get_upload_data_proc(
    iv_file_id      IN            VARCHAR2,   -- 1.FILE_ID
    iv_file_format  IN            VARCHAR2,   -- 2.�t�H�[�}�b�g�p�^�[��
    ov_errbuf          OUT NOCOPY VARCHAR2,   -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode         OUT NOCOPY VARCHAR2,   -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg          OUT NOCOPY VARCHAR2)   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(25) := 'get_upload_data_proc';  -- �v���O������
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
    lv_line       VARCHAR2(32767);   -- ���s�R�[�h���̏��
    ln_col        NUMBER;            -- �J����
    lb_col        BOOLEAN := TRUE;   -- �J�����쐬�p��
    ln_length     NUMBER;            -- �����ۊǗp
    ln_file_id    NUMBER;
--
    lt_file_line_data   xxcmn_common3_pkg.g_file_data_tbl;   -- �s�e�[�u���i�[�̈�
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    ln_file_id := TO_NUMBER(iv_file_id);
--
    -- ***************************************
    -- ***     �C���^�t�F�[�X���擾      ***
    -- ***************************************
    -- �t�@�C���A�b�v���[�h�C���^�t�F�[�X�f�[�^�擾
    -- �s���b�N����
    SELECT xmf.file_content_type,  -- �t�@�C�����������I�u�W�F�N�g�^�C�v�R�[�h
           xmf.file_name,          -- �t�@�C����
           xmf.created_by,         -- �쐬��
           xmf.creation_date       -- �쐬��
    INTO   gv_file_content_type,
           gv_file_name,
           gn_created_by,
           gd_creation_date
    FROM   xxinv_mrp_file_ul_interface xmf
    WHERE  xmf.file_id = ln_file_id
    FOR UPDATE OF xmf.file_id NOWAIT;
--
    -- ***************************************
    -- ***    �C���^�t�F�[�X�f�[�^�擾     ***
    -- ***************************************
    xxcmn_common3_pkg.blob_to_varchar2(
      ln_file_id,                              -- �t�@�C��ID
      lt_file_line_data,                       -- �ϊ���VARCHAR2�f�[�^
      lv_errbuf,                               -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,                              -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);                              -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF (lv_retcode = gv_status_error) THEN
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- �^�C�g���s�̂݁A���́A2�s�ڂ����s�݂̂̏ꍇ
    IF (lt_file_line_data.LAST < 2) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_c_msg_kbn,
                                            gv_c_msg_99k_008,
                                            gv_c_tkn_item,
                                            gv_file_id_name,
                                            gv_c_tkn_value,
                                            iv_file_id);
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- *********************************************
    -- ***  �擾�f�[�^���s�P�ʂŏ���(2�s�ڈȍ~)  ***
    -- *********************************************
    <<line_loop>>
    FOR ln_index IN 2 .. lt_file_line_data.LAST LOOP
--
      -- �Ώی����J�E���g
      gn_target_cnt := gn_target_cnt + 1;
--
      -- �s���ɍ�Ɨ̈�Ɋi�[
      lv_line := lt_file_line_data(ln_index);
--
      -- 1�s�̓��e��line�Ɋi�[
      gr_fdata_tbl(gn_target_cnt).line := lv_line;
--
      -- �J�����ԍ�������
      ln_col := 0;                                      -- �J����
      lb_col := TRUE;                                   -- �J�����쐬�p��
--
      -- ***************************************
      -- ***       1�s���J���}���ɕ���       ***
      -- ***************************************
      <<comma_loop>>
      LOOP
        -- lv_line�̒�����0�Ȃ�I��
        EXIT WHEN ((lb_col = FALSE) OR (lv_line IS NULL));
--
        -- �J�����ԍ����J�E���g
        ln_col := ln_col + 1;
--
        -- �J���}�̈ʒu���擾
        ln_length := INSTR(lv_line, gv_comma);
--
        -- �J���}���Ȃ�
        IF (ln_length = 0) THEN
          ln_length := LENGTH(lv_line);
          lb_col    := FALSE;
        -- �J���}������
        ELSE
          ln_length := ln_length -1;
          lb_col    := TRUE;
        END IF;
--
        -- ***************************************
        -- ** CSV�`�������ڂ��ƂɃ��R�[�h�Ɋi�[ **
        -- ***************************************
--
        -- �^���p
        IF (iv_file_format = gv_format_code_01) THEN
--
          -- �z��NO
          IF (ln_col = 1) THEN
            gr_fdata_tbl(gn_target_cnt).delivery_no    := SUBSTR(lv_line, 1, ln_length);
--
          -- �����NO
          ELSIF (ln_col = 2) THEN
            gr_fdata_tbl(gn_target_cnt).invoice_no     := SUBSTR(lv_line, 1, ln_length);
--
          -- �����^��
          ELSIF (ln_col = 3) THEN
            gr_fdata_tbl(gn_target_cnt).charged_amount := SUBSTR(lv_line, 1, ln_length);
--
          -- ��
          ELSIF (ln_col = 4) THEN
            gr_fdata_tbl(gn_target_cnt).qty            := SUBSTR(lv_line, 1, ln_length);
--
          -- �d��
          ELSIF (ln_col = 5) THEN
            gr_fdata_tbl(gn_target_cnt).weight         := SUBSTR(lv_line, 1, ln_length);
--
          -- �ʍs��
          ELSIF (ln_col = 6) THEN
            gr_fdata_tbl(gn_target_cnt).congestion     := SUBSTR(lv_line, 1, ln_length);
          END IF;
--
        -- �x���^���p
        ELSIF (iv_file_format = gv_format_code_02) THEN
--
          -- �^���Ǝ�
          IF (ln_col = 1) THEN
            gr_fdata_tbl(gn_target_cnt).delivery_code  := SUBSTR(lv_line, 1, ln_length);
--
          -- �z��NO
          ELSIF (ln_col = 2) THEN
            gr_fdata_tbl(gn_target_cnt).delivery_no    := SUBSTR(lv_line, 1, ln_length);
--
          -- �����NO
          ELSIF (ln_col = 3) THEN
            gr_fdata_tbl(gn_target_cnt).invoice_no     := SUBSTR(lv_line, 1, ln_length);
--
          -- �z���敪
          ELSIF (ln_col = 4) THEN
            gr_fdata_tbl(gn_target_cnt).delivery_classe := SUBSTR(lv_line, 1, ln_length);
--
          -- �����^��
          ELSIF (ln_col = 5) THEN
            gr_fdata_tbl(gn_target_cnt).charged_amount := SUBSTR(lv_line, 1, ln_length);
--
          -- ��
          ELSIF (ln_col = 6) THEN
            gr_fdata_tbl(gn_target_cnt).qty            := SUBSTR(lv_line, 1, ln_length);
--
          -- �d��
          ELSIF (ln_col = 7) THEN
            gr_fdata_tbl(gn_target_cnt).weight         := SUBSTR(lv_line, 1, ln_length);
--
          -- ����
          ELSIF (ln_col = 8) THEN
            gr_fdata_tbl(gn_target_cnt).distance       := SUBSTR(lv_line, 1, ln_length);
--
          -- ������
          ELSIF (ln_col = 9) THEN
            gr_fdata_tbl(gn_target_cnt).many_rate      := SUBSTR(lv_line, 1, ln_length);
--
          -- �ʍs��
          ELSIF (ln_col = 10) THEN
            gr_fdata_tbl(gn_target_cnt).congestion     := SUBSTR(lv_line, 1, ln_length);
--
          -- �s�b�L���O��
          ELSIF (ln_col = 11) THEN
            gr_fdata_tbl(gn_target_cnt).picking        := SUBSTR(lv_line, 1, ln_length);
--
          -- ���ڊ������z
          ELSIF (ln_col = 12) THEN
            gr_fdata_tbl(gn_target_cnt).consolid       := SUBSTR(lv_line, 1, ln_length);
--
          -- ���v
          ELSIF (ln_col = 13) THEN
            gr_fdata_tbl(gn_target_cnt).total_amount   := SUBSTR(lv_line, 1, ln_length);
          END IF;
--
        -- �����^���p
        ELSIF (iv_file_format = gv_format_code_03) THEN
--
          -- �^���Ǝ�
          IF (ln_col = 1) THEN
            gr_fdata_tbl(gn_target_cnt).delivery_code  := SUBSTR(lv_line, 1, ln_length);
--
          -- �z��NO
          ELSIF (ln_col = 2) THEN
            gr_fdata_tbl(gn_target_cnt).delivery_no    := SUBSTR(lv_line, 1, ln_length);
--
          -- �����NO
          ELSIF (ln_col = 3) THEN
            gr_fdata_tbl(gn_target_cnt).invoice_no     := SUBSTR(lv_line, 1, ln_length);
--
          -- �����^��
          ELSIF (ln_col = 4) THEN
            gr_fdata_tbl(gn_target_cnt).charged_amount := SUBSTR(lv_line, 1, ln_length);
--
          -- ������
          ELSIF (ln_col = 5) THEN
            gr_fdata_tbl(gn_target_cnt).many_rate      := SUBSTR(lv_line, 1, ln_length);
--
          -- �ʍs��
          ELSIF (ln_col = 6) THEN
            gr_fdata_tbl(gn_target_cnt).congestion     := SUBSTR(lv_line, 1, ln_length);
--
          -- �s�b�L���O��
          ELSIF (ln_col = 7) THEN
            gr_fdata_tbl(gn_target_cnt).picking        := SUBSTR(lv_line, 1, ln_length);
--
          -- ���ڊ������z
          ELSIF (ln_col = 8) THEN
            gr_fdata_tbl(gn_target_cnt).consolid       := SUBSTR(lv_line, 1, ln_length);
--
          -- ���v
          ELSIF (ln_col = 9) THEN
            gr_fdata_tbl(gn_target_cnt).total_amount   := SUBSTR(lv_line, 1, ln_length);
          END IF;
        END IF;
--
        -- str�͍���擾�����s�������i�J���}�͂̂������߁Aln_length + 2�j
        IF (lb_col = TRUE) THEN
          lv_line := SUBSTR(lv_line, ln_length + 2);
        ELSE
          lv_line := SUBSTR(lv_line, ln_length);
        END IF;
--
      END LOOP comma_loop;
    END LOOP line_loop;
--
  EXCEPTION
--
    WHEN lock_expt THEN   --*** ���b�N�擾�G���[ ***
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_c_msg_kbn,
                                            gv_c_msg_99k_032,
                                            gv_c_tkn_table,
                                            gv_file_up_if_tbl);
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
--
    WHEN NO_DATA_FOUND THEN   --*** �f�[�^�擾�G���[ ***
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_c_msg_kbn,
                                            gv_c_msg_99k_008,
                                            gv_c_tkn_item,
                                            gv_file_id_name,
                                            gv_c_tkn_value,
                                            iv_file_id);
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
--
--#################################  �Œ��O������ START   ####################################
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_upload_data_proc;
--
  /**********************************************************************************
   * Procedure Name   : proper_check
   * Description      : �Ó����`�F�b�N(K-4)
   ***********************************************************************************/
  PROCEDURE proper_check(
    iv_file_format IN            VARCHAR2,   -- �t�H�[�}�b�g�p�^�[��
    ov_errbuf         OUT NOCOPY VARCHAR2,   -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode        OUT NOCOPY VARCHAR2,   -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg         OUT NOCOPY VARCHAR2)   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proper_check'; -- �v���O������
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
    lv_line_feed        VARCHAR2(1);                  -- ���s�R�[�h
--
    -- *** ���[�J���ϐ� ***
    ln_c_col   NUMBER; -- �����ڐ�
--
    lv_log_data         VARCHAR2(32767);  -- LOG�f�[�^���ޔ�p
--
    lr_file_rec         file_data_rec;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        ���[�v�����̋L�q         ***
    -- ***       �������̌Ăяo��          ***
    -- ***************************************
--
    -- ������
    gv_proper_check_retcode := gv_status_normal; -- �Ó����`�F�b�N�X�e�[�^�X
    lv_line_feed := CHR(10);                     -- ���s�R�[�h
--
    -- �����ڐ��̐ݒ�
--
    -- �t�H�[�}�b�g�p�^�[�����u13�v�̏ꍇ
    IF (iv_file_format = gv_format_code_01) THEN
      ln_c_col := 6;
--
    -- �t�H�[�}�b�g�p�^�[�����u14�v�̏ꍇ
    ELSIF (iv_file_format = gv_format_code_02) THEN
      ln_c_col := 13;
--
    -- �t�H�[�}�b�g�p�^�[�����u15�v�̏ꍇ
    ELSIF (iv_file_format = gv_format_code_03) THEN
      ln_c_col := 9;
    END IF;
--
    -- **************************************************
    -- *** �擾�������R�[�h���ɍ��ڃ`�F�b�N���s���B
    -- **************************************************
    <<check_loop>>
    FOR ln_index IN 1 .. gr_fdata_tbl.LAST LOOP
--
      lr_file_rec := gr_fdata_tbl(ln_index);
--
      -- **************************************************
      -- *** ���ڐ��`�F�b�N
      -- **************************************************
      -- (�s�S�̂̒��� - �s����J���}�𔲂������� = �J���}�̐�)
      --   <> (�����ȍ��ڐ� - 1 = �����ȃJ���}�̐�)
      IF ((NVL(LENGTH(lr_file_rec.line) ,0)
        - NVL(LENGTH(REPLACE(lr_file_rec.line,gv_comma, NULL)),0))
          <> (ln_c_col - 1))
      THEN
--
        lr_file_rec.err_message := gv_err_msg_space || gv_err_msg_space
                                   || xxcmn_common_pkg.get_msg(gv_c_msg_kbn, gv_c_msg_99k_024)
                                   || lv_line_feed;
      -- ���ڐ��������ꍇ
      ELSE
        -- ���ʍ��ڃ`�F�b�N
--
        -- �z��No(�K�{)
        xxcmn_common3_pkg.upload_item_check(
                iv_item_name    => gv_delivery_no_n              -- ���ږ���
               ,iv_item_value   => lr_file_rec.delivery_no       -- ���ڂ̒l
               ,in_item_len     => gv_delivery_no_l              -- ���ڂ̒���
               ,in_item_decimal => NULL                          -- �����_�ȉ��̒���
               ,in_item_nullflg => xxcmn_common3_pkg.gv_null_ng  -- �K�{�t���O
               ,iv_item_attr    => xxcmn_common3_pkg.gv_attr_vc2 -- ���ڑ���
               ,ov_errbuf       => lv_errbuf                     -- �G���[�E���b�Z�[�W
               ,ov_retcode      => lv_retcode                    -- ���^�[���E�R�[�h
               ,ov_errmsg       => lv_errmsg                     -- ���[�U�[�E�G���[�E���b�Z�[�W
        );
--
        -- ���ڃ`�F�b�N�G���[
        IF (lv_retcode = gv_status_warn) THEN
          lr_file_rec.err_message := lr_file_rec.err_message || lv_errmsg || lv_line_feed;
--
        -- �v���V�[�W���[�ُ�I��
        ELSIF (lv_retcode = gv_status_error) THEN
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
        END IF;
--
        -- �����No
        xxcmn_common3_pkg.upload_item_check(
                iv_item_name    => gv_invoice_no_n               -- ���ږ���
               ,iv_item_value   => lr_file_rec.invoice_no        -- ���ڂ̒l
               ,in_item_len     => gv_invoice_no_l               -- ���ڂ̒���
               ,in_item_decimal => NULL                          -- �����_�ȉ��̒���
               ,in_item_nullflg => xxcmn_common3_pkg.gv_null_ok  -- �K�{�t���O
               ,iv_item_attr    => xxcmn_common3_pkg.gv_attr_vc2 -- ���ڑ���
               ,ov_errbuf       => lv_errbuf                     -- �G���[�E���b�Z�[�W
               ,ov_retcode      => lv_retcode                    -- ���^�[���E�R�[�h
               ,ov_errmsg       => lv_errmsg                     -- ���[�U�[�E�G���[�E���b�Z�[�W
        );
--
        -- ���ڃ`�F�b�N�G���[
        IF (lv_retcode = gv_status_warn) THEN
          lr_file_rec.err_message := lr_file_rec.err_message || lv_errmsg || lv_line_feed;
--
        -- �v���V�[�W���[�ُ�I��
        ELSIF (lv_retcode = gv_status_error) THEN
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
        END IF;
--
        -- �����^��(�K�{)
        xxcmn_common3_pkg.upload_item_check(
                iv_item_name    => gv_charged_amount_n           -- ���ږ���
               ,iv_item_value   => lr_file_rec.charged_amount    -- ���ڂ̒l
               ,in_item_len     => gv_charged_amount_l           -- ���ڂ̒���
               ,in_item_decimal => gv_decimal_len                -- �����_�ȉ��̒���
               ,in_item_nullflg => xxcmn_common3_pkg.gv_null_ng  -- �K�{�t���O
               ,iv_item_attr    => xxcmn_common3_pkg.gv_attr_num -- ���ڑ���
               ,ov_errbuf       => lv_errbuf                     -- �G���[�E���b�Z�[�W
               ,ov_retcode      => lv_retcode                    -- ���^�[���E�R�[�h
               ,ov_errmsg       => lv_errmsg                     -- ���[�U�[�E�G���[�E���b�Z�[�W
        );
--
        -- ���ڃ`�F�b�N�G���[
        IF (lv_retcode = gv_status_warn) THEN
          lr_file_rec.err_message := lr_file_rec.err_message || lv_errmsg || lv_line_feed;
--
        -- �v���V�[�W���[�ُ�I��
        ELSIF (lv_retcode = gv_status_error) THEN
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
        END IF;
--
        -- �ʍs��
        xxcmn_common3_pkg.upload_item_check(
                iv_item_name    => gv_congestion_n               -- ���ږ���
               ,iv_item_value   => lr_file_rec.congestion        -- ���ڂ̒l
               ,in_item_len     => gv_congestion_l               -- ���ڂ̒���
               ,in_item_decimal => gv_decimal_len                -- �����_�ȉ��̒���
               ,in_item_nullflg => xxcmn_common3_pkg.gv_null_ok  -- �K�{�t���O
               ,iv_item_attr    => xxcmn_common3_pkg.gv_attr_num -- ���ڑ���
               ,ov_errbuf       => lv_errbuf                     -- �G���[�E���b�Z�[�W
               ,ov_retcode      => lv_retcode                    -- ���^�[���E�R�[�h
               ,ov_errmsg       => lv_errmsg                     -- ���[�U�[�E�G���[�E���b�Z�[�W
        );
--
        -- ���ڃ`�F�b�N�G���[
        IF (lv_retcode = gv_status_warn) THEN
          lr_file_rec.err_message := lr_file_rec.err_message || lv_errmsg || lv_line_feed;
--
        -- �v���V�[�W���[�ُ�I��
        ELSIF (lv_retcode = gv_status_error) THEN
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
        END IF;
--
        -- �t�H�[�}�b�g�p�^�[���u�P�R�v OR �t�H�[�}�b�g�p�^�[���u�P�S�v
        IF ((iv_file_format = gv_format_code_01) OR (iv_file_format = gv_format_code_02)) THEN
--
          -- ��
          xxcmn_common3_pkg.upload_item_check(
                  iv_item_name    => gv_qty_n                      -- ���ږ���
                 ,iv_item_value   => lr_file_rec.qty               -- ���ڂ̒l
                 ,in_item_len     => gv_qty_l                      -- ���ڂ̒���
                 ,in_item_decimal => gv_decimal_len                -- �����_�ȉ��̒���
                 ,in_item_nullflg => xxcmn_common3_pkg.gv_null_ok  -- �K�{�t���O
                 ,iv_item_attr    => xxcmn_common3_pkg.gv_attr_num -- ���ڑ���
                 ,ov_errbuf       => lv_errbuf                     -- �G���[�E���b�Z�[�W
                 ,ov_retcode      => lv_retcode                    -- ���^�[���E�R�[�h
                 ,ov_errmsg       => lv_errmsg                     -- ���[�U�[�E�G���[�E���b�Z�[�W
          );
--
          -- ���ڃ`�F�b�N�G���[
          IF (lv_retcode = gv_status_warn) THEN
            lr_file_rec.err_message := lr_file_rec.err_message || lv_errmsg || lv_line_feed;
--
          -- �v���V�[�W���[�ُ�I��
          ELSIF (lv_retcode = gv_status_error) THEN
            lv_errbuf := lv_errmsg;
            RAISE global_api_expt;
          END IF;
--
          -- �d��
          xxcmn_common3_pkg.upload_item_check(
                  iv_item_name    => gv_weight_n                   -- ���ږ���
                 ,iv_item_value   => lr_file_rec.weight            -- ���ڂ̒l
                 ,in_item_len     => gv_weight_l                   -- ���ڂ̒���
                 ,in_item_decimal => gv_decimal_len                -- �����_�ȉ��̒���
                 ,in_item_nullflg => xxcmn_common3_pkg.gv_null_ok  -- �K�{�t���O
                 ,iv_item_attr    => xxcmn_common3_pkg.gv_attr_num -- ���ڑ���
                 ,ov_errbuf       => lv_errbuf                     -- �G���[�E���b�Z�[�W
                 ,ov_retcode      => lv_retcode                    -- ���^�[���E�R�[�h
                 ,ov_errmsg       => lv_errmsg                     -- ���[�U�[�E�G���[�E���b�Z�[�W
          );
--
          -- ���ڃ`�F�b�N�G���[
          IF (lv_retcode = gv_status_warn) THEN
            lr_file_rec.err_message := lr_file_rec.err_message || lv_errmsg || lv_line_feed;
--
          -- �v���V�[�W���[�ُ�I��
          ELSIF (lv_retcode = gv_status_error) THEN
            lv_errbuf := lv_errmsg;
            RAISE global_api_expt;
          END IF;
        END IF;
--
        -- �t�H�[�}�b�g�p�^�[���u�P�S�v OR �t�H�[�}�b�g�p�^�[���u�P�T�v
        IF ((iv_file_format = gv_format_code_02) OR (iv_file_format = gv_format_code_03)) THEN
--
          -- �^���Ǝ�(�K�{)
          xxcmn_common3_pkg.upload_item_check(
                  iv_item_name    => gv_delivery_code_n            -- ���ږ���
                 ,iv_item_value   => lr_file_rec.delivery_code     -- ���ڂ̒l
                 ,in_item_len     => gv_delivery_code_l            -- ���ڂ̒���
                 ,in_item_decimal => NULL                          -- �����_�ȉ��̒���
                 ,in_item_nullflg => xxcmn_common3_pkg.gv_null_ng  -- �K�{�t���O
                 ,iv_item_attr    => xxcmn_common3_pkg.gv_attr_vc2 -- ���ڑ���
                 ,ov_errbuf       => lv_errbuf                     -- �G���[�E���b�Z�[�W
                 ,ov_retcode      => lv_retcode                    -- ���^�[���E�R�[�h
                 ,ov_errmsg       => lv_errmsg                     -- ���[�U�[�E�G���[�E���b�Z�[�W
          );
--
          -- ���ڃ`�F�b�N�G���[
          IF (lv_retcode = gv_status_warn) THEN
            lr_file_rec.err_message := lr_file_rec.err_message || lv_errmsg || lv_line_feed;
--
          -- �v���V�[�W���[�ُ�I��
          ELSIF (lv_retcode = gv_status_error) THEN
            lv_errbuf := lv_errmsg;
            RAISE global_api_expt;
          END IF;
--
          -- ������
          xxcmn_common3_pkg.upload_item_check(
                  iv_item_name    => gv_many_rate_n                -- ���ږ���
                 ,iv_item_value   => lr_file_rec.many_rate         -- ���ڂ̒l
                 ,in_item_len     => gv_many_rate_l                -- ���ڂ̒���
                 ,in_item_decimal => gv_decimal_len                -- �����_�ȉ��̒���
                 ,in_item_nullflg => xxcmn_common3_pkg.gv_null_ok  -- �K�{�t���O
                 ,iv_item_attr    => xxcmn_common3_pkg.gv_attr_num -- ���ڑ���
                 ,ov_errbuf       => lv_errbuf                     -- �G���[�E���b�Z�[�W
                 ,ov_retcode      => lv_retcode                    -- ���^�[���E�R�[�h
                 ,ov_errmsg       => lv_errmsg                     -- ���[�U�[�E�G���[�E���b�Z�[�W
          );
--
          -- ���ڃ`�F�b�N�G���[
          IF (lv_retcode = gv_status_warn) THEN
            lr_file_rec.err_message := lr_file_rec.err_message || lv_errmsg || lv_line_feed;
--
          -- �v���V�[�W���[�ُ�I��
          ELSIF (lv_retcode = gv_status_error) THEN
            lv_errbuf := lv_errmsg;
            RAISE global_api_expt;
          END IF;
--
          -- �s�b�L���O��
          xxcmn_common3_pkg.upload_item_check(
                  iv_item_name    => gv_picking_n                  -- ���ږ���
                 ,iv_item_value   => lr_file_rec.picking           -- ���ڂ̒l
                 ,in_item_len     => gv_picking_l                  -- ���ڂ̒���
                 ,in_item_decimal => gv_decimal_len                -- �����_�ȉ��̒���
                 ,in_item_nullflg => xxcmn_common3_pkg.gv_null_ok  -- �K�{�t���O
                 ,iv_item_attr    => xxcmn_common3_pkg.gv_attr_num -- ���ڑ���
                 ,ov_errbuf       => lv_errbuf                     -- �G���[�E���b�Z�[�W
                 ,ov_retcode      => lv_retcode                    -- ���^�[���E�R�[�h
                 ,ov_errmsg       => lv_errmsg                     -- ���[�U�[�E�G���[�E���b�Z�[�W
          );
--
          -- ���ڃ`�F�b�N�G���[
          IF (lv_retcode = gv_status_warn) THEN
            lr_file_rec.err_message := lr_file_rec.err_message || lv_errmsg || lv_line_feed;
--
          -- �v���V�[�W���[�ُ�I��
          ELSIF (lv_retcode = gv_status_error) THEN
            lv_errbuf := lv_errmsg;
            RAISE global_api_expt;
          END IF;
--
          -- ���ڊ������z
          xxcmn_common3_pkg.upload_item_check(
                  iv_item_name    => gv_consolid_n                 -- ���ږ���
                 ,iv_item_value   => lr_file_rec.consolid          -- ���ڂ̒l
                 ,in_item_len     => gv_consolid_l                 -- ���ڂ̒���
                 ,in_item_decimal => gv_decimal_len                -- �����_�ȉ��̒���
                 ,in_item_nullflg => xxcmn_common3_pkg.gv_null_ok  -- �K�{�t���O
                 ,iv_item_attr    => xxcmn_common3_pkg.gv_attr_num -- ���ڑ���
                 ,ov_errbuf       => lv_errbuf                     -- �G���[�E���b�Z�[�W
                 ,ov_retcode      => lv_retcode                    -- ���^�[���E�R�[�h
                 ,ov_errmsg       => lv_errmsg                     -- ���[�U�[�E�G���[�E���b�Z�[�W
          );
--
          -- ���ڃ`�F�b�N�G���[
          IF (lv_retcode = gv_status_warn) THEN
            lr_file_rec.err_message := lr_file_rec.err_message || lv_errmsg || lv_line_feed;
--
          -- �v���V�[�W���[�ُ�I��
          ELSIF (lv_retcode = gv_status_error) THEN
            lv_errbuf := lv_errmsg;
            RAISE global_api_expt;
          END IF;
--
          -- ���v
          xxcmn_common3_pkg.upload_item_check(
                  iv_item_name    => gv_total_amount_n             -- ���ږ���
                 ,iv_item_value   => lr_file_rec.total_amount      -- ���ڂ̒l
                 ,in_item_len     => gv_total_amount_l             -- ���ڂ̒���
                 ,in_item_decimal => gv_decimal_len                -- �����_�ȉ��̒���
                 ,in_item_nullflg => xxcmn_common3_pkg.gv_null_ok  -- �K�{�t���O
                 ,iv_item_attr    => xxcmn_common3_pkg.gv_attr_num -- ���ڑ���
                 ,ov_errbuf       => lv_errbuf                     -- �G���[�E���b�Z�[�W
                 ,ov_retcode      => lv_retcode                    -- ���^�[���E�R�[�h
                 ,ov_errmsg       => lv_errmsg                     -- ���[�U�[�E�G���[�E���b�Z�[�W
          );
--
          -- ���ڃ`�F�b�N�G���[
          IF (lv_retcode = gv_status_warn) THEN
            lr_file_rec.err_message := lr_file_rec.err_message || lv_errmsg || lv_line_feed;
--
          -- �v���V�[�W���[�ُ�I��
          ELSIF (lv_retcode = gv_status_error) THEN
            lv_errbuf := lv_errmsg;
            RAISE global_api_expt;
          END IF;
        END IF;
--
        -- �t�H�[�}�b�g�p�^�[���u�P�S�v
        IF (iv_file_format = gv_format_code_02) THEN
--
          -- �z���敪
          xxcmn_common3_pkg.upload_item_check(
                  iv_item_name    => gv_delivery_classe_n          -- ���ږ���
                 ,iv_item_value   => lr_file_rec.delivery_classe   -- ���ڂ̒l
                 ,in_item_len     => gv_delivery_classe_l          -- ���ڂ̒���
                 ,in_item_decimal => NULL                          -- �����_�ȉ��̒���
                 ,in_item_nullflg => xxcmn_common3_pkg.gv_null_ok  -- �K�{�t���O
                 ,iv_item_attr    => xxcmn_common3_pkg.gv_attr_vc2 -- ���ڑ���
                 ,ov_errbuf       => lv_errbuf                     -- �G���[�E���b�Z�[�W
                 ,ov_retcode      => lv_retcode                    -- ���^�[���E�R�[�h
                 ,ov_errmsg       => lv_errmsg                     -- ���[�U�[�E�G���[�E���b�Z�[�W
          );
--
          -- ���ڃ`�F�b�N�G���[
          IF (lv_retcode = gv_status_warn) THEN
            lr_file_rec.err_message := lr_file_rec.err_message || lv_errmsg || lv_line_feed;
--
          -- �v���V�[�W���[�ُ�I��
          ELSIF (lv_retcode = gv_status_error) THEN
            lv_errbuf := lv_errmsg;
            RAISE global_api_expt;
          END IF;
--
          -- ����
          xxcmn_common3_pkg.upload_item_check(
                  iv_item_name    => gv_distance_n                 -- ���ږ���
                 ,iv_item_value   => lr_file_rec.distance          -- ���ڂ̒l
                 ,in_item_len     => gv_distance_l                 -- ���ڂ̒���
                 ,in_item_decimal => gv_decimal_len                -- �����_�ȉ��̒���
                 ,in_item_nullflg => xxcmn_common3_pkg.gv_null_ok  -- �K�{�t���O
                 ,iv_item_attr    => xxcmn_common3_pkg.gv_attr_num -- ���ڑ���
                 ,ov_errbuf       => lv_errbuf                     -- �G���[�E���b�Z�[�W
                 ,ov_retcode      => lv_retcode                    -- ���^�[���E�R�[�h
                 ,ov_errmsg       => lv_errmsg                     -- ���[�U�[�E�G���[�E���b�Z�[�W
          );
--
          -- ���ڃ`�F�b�N�G���[
          IF (lv_retcode = gv_status_warn) THEN
            lr_file_rec.err_message := lr_file_rec.err_message || lv_errmsg || lv_line_feed;
--
          -- �v���V�[�W���[�ُ�I��
          ELSIF (lv_retcode = gv_status_error) THEN
            lv_errbuf := lv_errmsg;
            RAISE global_api_expt;
          END IF;
        END IF;
      END IF;
--
      -- **************************************************
      -- *** �G���[����
      -- **************************************************
      -- �`�F�b�N�G���[����̏ꍇ
      IF (lr_file_rec.err_message IS NOT NULL) THEN
--
        -- **************************************************
        -- *** �f�[�^���o�͏����i�s�� + SPACE + �s�S�̂̃f�[�^�j
        -- **************************************************
        lv_log_data := NULL;
        lv_log_data := TO_CHAR(ln_index,'99999') || gv_space || lr_file_rec.line;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_log_data);
--
        -- �G���[���b�Z�[�W���o��
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, RTRIM(lr_file_rec.err_message, lv_line_feed));
--
        -- �Ó����`�F�b�N�X�e�[�^�X
        gv_proper_check_retcode := gv_status_error;
--
        -- �G���[�����J�E���g
        gn_error_cnt := gn_error_cnt + 1;
--
      -- �`�F�b�N�G���[�Ȃ��̏ꍇ
      ELSE
        -- ���������J�E���g
        gn_normal_cnt := gn_normal_cnt + 1;
--
        -- ���l�ɕϊ�
        lr_file_rec.charged_amount_n := TO_NUMBER(lr_file_rec.charged_amount);
        lr_file_rec.qty_n            := TO_NUMBER(lr_file_rec.qty);
        lr_file_rec.many_rate_n      := TO_NUMBER(lr_file_rec.many_rate);
        lr_file_rec.congestion_n     := TO_NUMBER(lr_file_rec.congestion);
        lr_file_rec.picking_n        := TO_NUMBER(lr_file_rec.picking);
        lr_file_rec.weight_n         := TO_NUMBER(lr_file_rec.weight);
        lr_file_rec.distance_n       := TO_NUMBER(lr_file_rec.distance);
        lr_file_rec.consolid_n       := TO_NUMBER(lr_file_rec.consolid);
        lr_file_rec.total_amount_n   := TO_NUMBER(lr_file_rec.total_amount);
      END IF;
--
      gr_fdata_tbl(ln_index) := lr_file_rec;
--
    END LOOP check_loop;
--
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'');
--
    --==============================================================
    --���b�Z�[�W�o�́i�G���[�ȊO�j������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END proper_check;
--
  /***********************************************************************************
   * Procedure Name   : insert_data
   * Description      : �f�[�^�o�^(K-5)
   ***********************************************************************************/
  PROCEDURE insert_data(
    ov_errbuf          OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode         OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg          OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'insert_data'; -- �v���O������
--
--##############################  �Œ胍�[�J���ϐ��錾�� START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################################  �Œ蕔 END   #############################################
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
--################################  �Œ�X�e�[�^�X�������� START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  �Œ蕔 END   #############################################
--
--    FORALL itp_cnt IN 0 .. gn_target_cnt-1
    FORALL itp_cnt IN 1 .. gr_fdata_tbl.LAST
      INSERT INTO xxwip_deliverys_if
      (
           delivery_id
          ,pattern_flag
          ,delivery_company_code
          ,delivery_no
          ,invoice_no
          ,p_b_classe
          ,delivery_classe
          ,charged_amount
          ,qty1
          ,qty2
          ,delivery_weight1
          ,delivery_weight2
          ,distance
          ,many_rate
          ,congestion_charge
          ,picking_charge
          ,consolid_surcharge
          ,total_amount
          ,created_by
          ,creation_date
          ,last_updated_by
          ,last_update_date
          ,last_update_login
          ,request_id
          ,program_application_id
          ,program_id
          ,program_update_date
      )
      VALUES
      (
           xxwip_deliverys_if_id_s1.NEXTVAL                -- delivery_id
          ,gt_pattern_flag(itp_cnt)                        -- pattern_flag
          ,gt_delivery_code(itp_cnt)                       -- delivery_company_code
          ,gt_delivery_no(itp_cnt)                         -- delivery_no
          ,gt_invoice_no(itp_cnt)                          -- invoice_no
          ,gt_p_b_classe(itp_cnt)                          -- p_b_classe
          ,gt_delivery_classe(itp_cnt)                     -- delivery_classe
          ,gt_charged_amount(itp_cnt)                      -- charged_amount
          ,gt_qty1(itp_cnt)                                -- qty1
          ,gt_qty2(itp_cnt)                                -- qty2
          ,gt_weight1(itp_cnt)                             -- delivery_weight1
          ,gt_weight2(itp_cnt)                             -- delivery_weight2
          ,gt_distance(itp_cnt)                            -- distance
          ,gt_many_rate(itp_cnt)                           -- many_rate
          ,gt_congestion(itp_cnt)                          -- congestion_charge
          ,gt_picking(itp_cnt)                             -- picking_charge
          ,gt_consolid(itp_cnt)                            -- consolid_surcharge
          ,gt_total(itp_cnt)                               -- total_amount
          ,gn_user_id                                      -- created_by
          ,gd_sysdate                                      -- creation_date
          ,gn_user_id                                      -- last_updated_by
          ,gd_sysdate                                      -- last_update_date
          ,gn_login_id                                     -- last_update_login
          ,gn_conc_request_id                              -- request_id
          ,gn_prog_appl_id                                 -- program_application_id
          ,gn_conc_program_id                              -- program_id
          ,gd_sysdate                                      -- program_update_date
      );
--
  EXCEPTION
--
--#################################  �Œ��O������ START   #######################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   #############################################
--
  END insert_data;
--
  /***********************************************************************************
   * Procedure Name   : delete_tbl
   * Description      : �t�@�C���A�b�v���[�hIF�e�[�u���폜(K-6)
   ***********************************************************************************/
  PROCEDURE delete_tbl(
    iv_file_format  IN            VARCHAR2,     -- 2.�t�H�[�}�b�g�p�^�[��
    ov_errbuf          OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode         OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg          OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'delete_tbl'; -- �v���O������
--
--##############################  �Œ胍�[�J���ϐ��錾�� START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################################  �Œ蕔 END   #############################################
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
--################################  �Œ�X�e�[�^�X�������� START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  �Œ蕔 END   #############################################
--
    -- �t�@�C���A�b�v���[�h�C���^�t�F�[�X�f�[�^�폜
    xxcmn_common3_pkg.delete_fileup_proc(iv_file_format => iv_file_format,
                                         id_now_date    => gd_sysdate,
                                         in_purge_days  => gv_purge_term,
                                         ov_errbuf      => lv_errbuf,
                                         ov_retcode     => lv_retcode,
                                         ov_errmsg      => lv_errmsg);
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_api_expt;
    END IF;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   #######################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   #############################################
--
  END delete_tbl;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    iv_file_id     IN            VARCHAR2,     -- 1.FILE_ID
    iv_file_format IN            VARCHAR2,     -- 2.�t�H�[�}�b�g�p�^�[��
    ov_errbuf         OUT NOCOPY VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode        OUT NOCOPY VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg         OUT NOCOPY VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    ln_count      NUMBER;
    lv_out_rep    VARCHAR2(5000);
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
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
    ln_count      := 0;
--
    -- �Ó����`�F�b�N�X�e�[�^�X�̏�����
    gv_proper_check_retcode := gv_status_normal;
--
    --*********************************************
    --***        K-1 �p�����[�^�`�F�b�N         ***
    --*********************************************
    parameter_check(
      iv_file_format,
      lv_errbuf,          -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,         -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    --*********************************************
    --***        K-2 �֘A�f�[�^�擾         ***
    --*********************************************
    relat_data_get(
      iv_file_format,
      lv_errbuf,          -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,         -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    --*********************************************
    --*** K-3 �t�@�C���A�b�v���[�hIF�f�[�^�擾  ***
    --*********************************************
    get_upload_data_proc(
      iv_file_id,
      iv_file_format,
      lv_errbuf,          -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,         -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
--##############################  �A�b�v���[�h�Œ胁�b�Z�[�W START  ##############################
    --�������ʃ��|�[�g�o�́i�㕔�j
    -- �t�@�C����
    lv_out_rep    := xxcmn_common_pkg.get_msg(gv_c_msg_kbn,
                                              gv_c_msg_99k_101,
                                              gv_c_tkn_value,
                                              gv_file_name);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_out_rep);
--
    -- �A�b�v���[�h����
    lv_out_rep    := xxcmn_common_pkg.get_msg(gv_c_msg_kbn,
                                              gv_c_msg_99k_103,
                                              gv_c_tkn_value,
                                              TO_CHAR(gd_creation_date,'YYYY/MM/DD HH24:MI'));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_out_rep);
--
    -- �t�@�C���A�b�v���[�h����
    lv_out_rep    := xxcmn_common_pkg.get_msg(gv_c_msg_kbn,
                                              gv_c_msg_99k_104,
                                              gv_c_tkn_value,
                                              gv_file_up_name);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_out_rep);
--
    -- �t�H�[�}�b�g�p�^�[��
    lv_out_rep    := xxcmn_common_pkg.get_msg(gv_c_msg_kbn,
                                              gv_c_msg_99k_106,
                                              gv_c_tkn_value,
                                              iv_file_format);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_out_rep);
--
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'');
--
--##############################  �A�b�v���[�h�Œ胁�b�Z�[�W END   ##############################
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    --*********************************************
    --***        K-4 �Ó����`�F�b�N             ***
    --*********************************************
    proper_check(
      iv_file_format,
      lv_errbuf,          -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,         -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
--
    -- �Ó����`�F�b�N�ŃG���[���Ȃ������ꍇ
    ELSIF (gv_proper_check_retcode = gv_status_normal) THEN
--
      --*********************************************
      --***        �o�^�f�[�^�̐ݒ�               ***
      --*********************************************
      set_data_proc(
        iv_file_format,
        lv_errbuf,          -- �G���[�E���b�Z�[�W           --# �Œ� #
        lv_retcode,         -- ���^�[���E�R�[�h             --# �Œ� #
        lv_errmsg);         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
      --*********************************************
      --***        K-5 �f�[�^�o�^                 ***
      --*********************************************
      insert_data(
        lv_errbuf,          -- �G���[�E���b�Z�[�W           --# �Œ� #
        lv_retcode,         -- ���^�[���E�R�[�h             --# �Œ� #
        lv_errmsg);         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
    END IF;
--
    --*********************************************
    --*** K-6 �t�@�C���A�b�v���[�hIF�f�[�^�폜  ***
    --*********************************************
    delete_tbl(
      iv_file_format,
      lv_errbuf,          -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,         -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
-- 2008.04.28 Y.Kawano modify start
--    IF (lv_retcode = gv_status_error) THEN
--      RAISE global_process_expt;
--    END IF;
--
    IF (lv_retcode = gv_status_error) THEN
      -- �폜�����G���[����RollBack������ׁA�Ó����`�F�b�N�X�e�[�^�X��������
      gv_proper_check_retcode := gv_status_normal;
      RAISE global_process_expt;
    END IF;
--
    -- �`�F�b�N�����G���[
    IF (gv_proper_check_retcode = gv_status_error) THEN
      -- �Œ�̃G���[���b�Z�[�W�̏o�͂����Ȃ��悤�ɂ���
      lv_errmsg := gv_space;
      RAISE global_process_expt;
    END IF;
-- 2008.04.28 Y.Kawano modify end
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ###################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
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
    errbuf            OUT NOCOPY VARCHAR2,      --   �G���[�E���b�Z�[�W  --# �Œ� #
    retcode           OUT NOCOPY VARCHAR2,      --   ���^�[���E�R�[�h    --# �Œ� #
    iv_file_id     IN            VARCHAR2,      -- 1.FILE_ID
    iv_file_format IN            VARCHAR2)      -- 2.�t�H�[�}�b�g�p�^�[��
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
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
  BEGIN
--
--###########################  �Œ蕔 START   #####################################################
--
    -- ======================
    -- �Œ�o�͗p�ϐ��Z�b�g
    -- ======================
    --���s���[�U���擾
    gv_exec_user := fnd_global.user_name;
--
    --���s�R���J�����g���擾
    SELECT fcp.concurrent_program_name
    INTO   gv_conc_name
    FROM   fnd_concurrent_programs fcp
    WHERE  fcp.application_id        = fnd_global.prog_appl_id
    AND    fcp.concurrent_program_id = fnd_global.conc_program_id
    AND    ROWNUM                    = 1;
--
    -- ======================
    -- �Œ�o��
    -- ======================
    --���s���[�U���o��
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00001','USER',gv_exec_user);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --���s�R���J�����g���o��
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00002','CONC',gv_conc_name);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --�N�����ԏo��
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-10118','TIME',
                                           TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS'));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, gv_out_msg);
--
    --��؂蕶���o��
    gv_sep_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00003');
--
--###########################  �Œ蕔 END   #############################
--
    -- ===============================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ===============================================
    submain(
      iv_file_id,      -- 1.FILE_ID
      iv_file_format,  -- 2.�t�H�[�}�b�g�p�^�[��
      lv_errbuf,       -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,      -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
--###########################  �Œ蕔 START   #####################################################
--
    -- ======================
    -- �G���[�E���b�Z�[�W�o��
    -- ======================
    IF (lv_retcode = gv_status_error) THEN
      IF (lv_errmsg IS NULL) THEN
        --��^���b�Z�[�W�E�Z�b�g
        lv_errmsg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-10030');
      END IF;
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
    END IF;
    -- ==================================
    -- ���^�[���E�R�[�h�̃Z�b�g�A�I������
    -- ==================================
    --��؂蕶����o��
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_sep_msg);
--
    --���������o��
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00008','CNT',TO_CHAR(gn_target_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --���������o��
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00009','CNT',TO_CHAR(gn_normal_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --�G���[�����o��
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00010','CNT',TO_CHAR(gn_error_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --�X�L�b�v�����o��
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00011','CNT',TO_CHAR(gn_warn_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --�X�e�[�^�X�o��
    SELECT flv.meaning
    INTO   gv_conc_status
    FROM   fnd_lookup_values flv
    WHERE  flv.language            = userenv('LANG')
    AND    flv.view_application_id = 0
    AND    flv.security_group_id   = fnd_global.lookup_security_group(flv.lookup_type,
                                                                      flv.view_application_id)
    AND    flv.lookup_type         = 'CP_STATUS_CODE'
    AND    flv.lookup_code         = DECODE(lv_retcode,
                                            gv_status_normal,gv_sts_cd_normal,
                                            gv_status_warn,gv_sts_cd_warn,
                                            gv_sts_cd_error)
    AND    ROWNUM                  = 1;
--
    --�����X�e�[�^�X�o��
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00012','STATUS',gv_conc_status);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --�X�e�[�^�X�Z�b�g
    retcode := lv_retcode;
    --�I���X�e�[�^�X���G���[�̏ꍇ��ROLLBACK����
--2008.4.28 Y.Kawano modify start
--    IF (retcode = gv_status_error) THEN
--      ROLLBACK;
--    END IF;
    IF (retcode = gv_status_error) AND (gv_proper_check_retcode = gv_status_normal) THEN
      ROLLBACK;
    ELSE
      COMMIT;
    END IF;
--2008.4.28 Y.Kawano modify end
--
  EXCEPTION
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      retcode := gv_status_error;
  END main;
--
--###########################  �Œ蕔 END   #######################################################
--
END xxinv990007c;
/
