CREATE OR REPLACE PACKAGE BODY xxpo940002c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxpo940002c(body)
 * Description      : �o�������ю捞����
 * MD.050           : �����I�����C�� T_MD050_BPO_940
 * MD.070           : �o�������ю捞���� T_MD070_BPO_94B
 * Version          : 1.8
 * Program List
 * ------------------------- ----------------------------------------------------------
 *  Name                      Description
 * ------------------------- ----------------------------------------------------------
 *  init_proc                 ��������(B-1)
 *  check_data                �擾�f�[�^�`�F�b�N����(B-3)
 *  get_other_data            �֘A�f�[�^�擾����(B-4)
 *  ins_ic_lot_mst            ���b�g�}�X�^�o�^����(B-5)
 *  ins_vendor_suppry_txns    �O���o��������(�A�h�I��)�o�^����(B-6)
 *  ins_inventory_data        �����݌Ɍv�㏈��(B-7)
 *  ins_po_data               ���������쐬����(B-8)
 *  ins_qt_inspection         �i�������˗����쐬����(B-9)
 *  import_standard_po        �W�������C���|�[�g�̌ďo����(B-10)
 *  del_vendor_supply_txns_if �f�[�^�폜����(B-11)
 *  put_dump_msg              �f�[�^�_���v�ꊇ�o�͏���(B-12)
 *  submain                   ���C�������v���V�[�W��
 *  main                      �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ------------------- -------------------------------------------------
 *  Date          Ver.  Editor              Description
 * ------------- ----- ------------------- -------------------------------------------------
 *  2008/06/06    1.0   Oracle �ɓ��ЂƂ�   ����쐬
 *  2008/07/08    1.1   Oracle �R����_     I_S_192�Ή�
 *  2008/07/22    1.2   Oracle �ɓ��ЂƂ�   �����ۑ�#32�Ή�
 *  2008/08/18    1.3   Oracle �ɓ��ЂƂ�   T_S_595 �i�ڏ��VIEW2�𐻑�����Œ��o����
 *  2008/12/02    1.4   SCS    �ɓ��ЂƂ�   �{�ԏ�Q#171
 *  2008/12/24    1.5   SCS    �R�{ ���v    �{�ԏ�Q#743
 *  2008/12/26    1.6   SCS    �ɓ� �ЂƂ�  �{�ԏ�Q#809
 *  2009/02/09    1.7   SCS    �g�c �Ď�    �{��#15�A#1178�Ή�
 *  2009/03/13    1.8   SCS    �ɓ� �ЂƂ�  �{��#32�Ή�
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
  gv_msg_cont      CONSTANT VARCHAR2(3) := '.';
  gv_msg_comma     CONSTANT VARCHAR2(3) := ',';
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
  lock_expt                  EXCEPTION;  -- ���b�N�擾��O
  proc_err_expt              EXCEPTION;  -- �v���V�[�W����O
--
  PRAGMA EXCEPTION_INIT(lock_expt, -54); -- ���b�N�擾��O
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  gv_pkg_name             CONSTANT VARCHAR2(100) := 'xxpo940002c'; -- �p�b�P�[�W��
--
  -- �A�v���P�[�V�����Z�k��
  gv_xxpo                 CONSTANT VARCHAR2(5) := 'XXPO';   -- ���W���[��������:XXPO
  gv_xxcmn                CONSTANT VARCHAR2(5) := 'XXCMN';  -- ���W���[��������:XXCMN
--
  -- ���b�Z�[�W
  gv_msg_xxcmn10002       CONSTANT VARCHAR2(100) := 'APP-XXCMN-10002'; -- ���b�Z�[�W:APP-XXCMN-10002 �v���t�@�C���擾�G���[
  gv_msg_xxcmn10019       CONSTANT VARCHAR2(100) := 'APP-XXCMN-10019'; -- ���b�Z�[�W:APP-XXCMN-10019 ���b�N�G���[
  gv_msg_xxcmn10001       CONSTANT VARCHAR2(100) := 'APP-XXCMN-10001'; -- ���b�Z�[�W:APP-XXCMN-10001 �Ώۃf�[�^�Ȃ�
  gv_msg_xxcmn00005       CONSTANT VARCHAR2(100) := 'APP-XXCMN-00005'; -- ���b�Z�[�W:APP-XXCMN-00005 �����f�[�^�i���o���j
  gv_msg_xxcmn00007       CONSTANT VARCHAR2(100) := 'APP-XXCMN-00007'; -- ���b�Z�[�W:APP-XXCMN-00007 �X�L�b�v�f�[�^�i���o���j
-- 2008/07/22 H.Itou Add Start
  gv_msg_xxcmn10603       CONSTANT VARCHAR2(100) := 'APP-XXCMN-10603'; -- ���b�Z�[�W:APP-XXCMN-10603 �P�[�X�����G���[
-- 2008/07/22 H.Itou Add End
  gv_msg_xxpo10005        CONSTANT VARCHAR2(100) := 'APP-XXPO-10005';  -- ���b�Z�[�W:APP-XXPO-10005 ���b�g�o�^�ς݃G���[
  gv_msg_xxpo10110        CONSTANT VARCHAR2(100) := 'APP-XXPO-10110';  -- ���b�Z�[�W:APP-XXPO-10110 ���b�g�̔ԃG���[
  gv_msg_xxpo10007        CONSTANT VARCHAR2(100) := 'APP-XXPO-10007';  -- ���b�Z�[�W:APP-XXPO-10007 �f�[�^�o�^�G���[
  gv_msg_xxpo10025        CONSTANT VARCHAR2(100) := 'APP-XXPO-10025';  -- ���b�Z�[�W:APP-XXPO-10025 �R���J�����g�o�^�G���[
  gv_msg_xxpo10226        CONSTANT VARCHAR2(100) := 'APP-XXPO-10226';  -- ���b�Z�[�W:APP-XXPO-10226 �����^�C�v�G���[
  gv_msg_xxpo10002        CONSTANT VARCHAR2(100) := 'APP-XXPO-10002';  -- ���b�Z�[�W:APP-XXPO-10002 �K�{�G���[
  gv_msg_xxpo10119        CONSTANT VARCHAR2(100) := 'APP-XXPO-10119';  -- ���b�Z�[�W:APP-XXPO-10119 �݌ɃN���[�Y�G���[3
  gv_msg_xxpo10255        CONSTANT VARCHAR2(100) := 'APP-XXPO-10255';  -- ���b�Z�[�W:APP-XXPO-10255 ���l0�ȉ��G���[2
  gv_msg_xxpo10256        CONSTANT VARCHAR2(100) := 'APP-XXPO-10256';  -- ���b�Z�[�W:APP-XXPO-10256 ���i�K�{�G���[
  gv_msg_xxpo10215        CONSTANT VARCHAR2(100) := 'APP-XXPO-10215';  -- ���b�Z�[�W:APP-XXPO-10215 �����֘A�`�F�b�N�G���[
  gv_msg_xxpo10257        CONSTANT VARCHAR2(100) := 'APP-XXPO-10257';  -- ���b�Z�[�W:APP-XXPO-10257 ���b�g�Ǘ��O�i�G���[
  gv_msg_xxpo30051        CONSTANT VARCHAR2(100) := 'APP-XXPO-30051';  -- ���b�Z�[�W:APP-XXPO-30051 ���̓p�����[�^(���o��)
--
  -- �g�[�N��
  gv_tkn_ng_profile       CONSTANT VARCHAR2(100) := 'NG_PROFILE';
  gv_tkn_table            CONSTANT VARCHAR2(100) := 'TABLE';
  gv_tkn_key              CONSTANT VARCHAR2(100) := 'KEY';
  gv_tkn_item_no          CONSTANT VARCHAR2(100) := 'ITEM_NO';
  gv_tkn_info_name        CONSTANT VARCHAR2(100) := 'INFO_NAME';
  gv_tkn_prg_name         CONSTANT VARCHAR2(100) := 'PRG_NAME';
  gv_tkn_item             CONSTANT VARCHAR2(100) := 'ITEM';
  gv_tkn_token            CONSTANT VARCHAR2(100) := 'TOKEN';
--
  -- �g�[�N������
  gv_tkn_ctpty_inv_rcv_rsn   CONSTANT VARCHAR2(100) := 'XXPO:�����݌Ɍv�㎖�R';
  gv_tkn_ctpty_cost_rsn      CONSTANT VARCHAR2(100) := 'XXPO:����挴���v�㎖�R';
  gv_tkn_purchase_emp_id     CONSTANT VARCHAR2(100) := 'XXPO:�w���S����ID';
  gv_tkn_bill_to_location_id CONSTANT VARCHAR2(100) := 'XXPO:�����掖�Ə�ID';
  gv_tkn_po_line_type_id     CONSTANT VARCHAR2(100) := 'XXPO:�������׃^�C�vID';
  gv_tkn_cost_cmpntcls_code  CONSTANT VARCHAR2(100) := 'XXPO:���b�g����-�R���|�[�l���g�敪';
  gv_tkn_cost_mthd_code      CONSTANT VARCHAR2(100) := 'XXPO:���b�g����-���b�g�������@';
  gv_tkn_cost_analysis_code  CONSTANT VARCHAR2(100) := 'XXPO:���b�g����-����';
  gv_tkn_org_id              CONSTANT VARCHAR2(100) := 'MO:�c�ƒP��';
  gv_tkn_vendor_sply_txns_if CONSTANT VARCHAR2(100) := '�o�������я��C���^�t�F�[�X';
  gv_tkn_vendors             CONSTANT VARCHAR2(100) := '�d������';
  gv_tkn_vendor_sites        CONSTANT VARCHAR2(100) := '�d����T�C�g���';
  gv_tkn_item_mst            CONSTANT VARCHAR2(100) := 'OPM�i�ڏ��';
  gv_tkn_ic_lot_mst          CONSTANT VARCHAR2(100) := 'OPM���b�g�}�X�^';
  gv_tkn_vendor_sply_txns    CONSTANT VARCHAR2(100) := '�O���o��������(�A�h�I��)';
  gv_tkn_xxpo_headers_all    CONSTANT VARCHAR2(100) := '�����w�b�_(�A�h�I��)';
  gv_tkn_po_headers_if       CONSTANT VARCHAR2(100) := '�����w�b�_�I�[�v���C���^�t�F�[�X';
  gv_tkn_po_lines_if         CONSTANT VARCHAR2(100) := '�������׃I�[�v���C���^�t�F�[�X';
  gv_tkn_po_distributions_if CONSTANT VARCHAR2(100) := '�������׃I�[�v���C���^�t�F�[�X';
  gv_tkn_lc_adjustment       CONSTANT VARCHAR2(100) := '���b�g����';
  gv_tkn_ic_tran_cmp         CONSTANT VARCHAR2(100) := '�݌Ɏ��';
  gv_tkn_qt_inspection       CONSTANT VARCHAR2(100) := '�i�������˗����';
  gv_tkn_vendor_code         CONSTANT VARCHAR2(100) := '�d����R�[�h:';
  gv_tkn_vendor_site_code    CONSTANT VARCHAR2(100) := '�d����T�C�g�R�[�h:';
  gv_tkn_item_code           CONSTANT VARCHAR2(100) := '�i�ڃR�[�h:';
  gv_tkn_conc_name           CONSTANT VARCHAR2(100) := '�W�������C���|�[�g';
  gv_tkn_producted_qty_name  CONSTANT VARCHAR2(100) := '�o��������';
  gv_tkn_koyu_code_name      CONSTANT VARCHAR2(100) := '�ŗL�L��';
  gv_tkn_factory_code_name   CONSTANT VARCHAR2(100) := '�H��';
-- 2008/12/02 H.Itou Add Start �{�ԏ�Q#171
  gv_tkn_koyu_code           CONSTANT VARCHAR2(100) := '�H��ŗL�L��:';
-- 2008/12/02 H.Itou Add End
--
  -- �Z�L�����e�B�敪
  gv_security_kbn_in         CONSTANT VARCHAR2(1) := '1'; -- �Z�L�����e�B�敪 �ɓ������[�U�[
  gv_security_kbn_out        CONSTANT VARCHAR2(1) := '2'; -- �Z�L�����e�B�敪 ����惆�[�U�[

  -- ���t����
  gv_yyyymm                  CONSTANT VARCHAR2(10) := 'YYYYMM';
  gv_yyyymmdd                CONSTANT VARCHAR2(10) := 'YYYY/MM/DD';
  gv_yyyymmddhh24miss        CONSTANT VARCHAR2(30) := 'YYYY/MM/DD HH24:MI:SS';
--
  -- �����^�C�v
  gv_product_result_type_inv CONSTANT VARCHAR2(1) := '1'; -- �����^�C�v:�����݌�
  gv_product_result_type_po  CONSTANT VARCHAR2(1) := '2'; -- �����^�C�v:�����d��
--
  -- �i�ڋ敪
  gv_item_class_code_prod    CONSTANT VARCHAR2(1) := '5'; -- �i�ڋ敪:���i
--
  -- ���i�敪
  gv_prod_class_code_drink   CONSTANT VARCHAR2(1) := '2'; -- ���i�敪:�h�����N
--
  -- �P��
  gv_um_cs                   CONSTANT VARCHAR2(2) := 'CS'; -- �P�[�X
--
  -- �����Ǘ��敪
  gv_cost_manage_code_j      CONSTANT VARCHAR2(1) := '0'; -- �����Ǘ��敪:���ی���
  gv_cost_manage_code_h      CONSTANT VARCHAR2(1) := '1'; -- �����Ǘ��敪:�W������
--
  -- �d���P���������^�C�v
  gv_unit_price_calc_code_prod  CONSTANT VARCHAR2(1) := '1'; -- �d���P���������^�C�v:������
  gv_unit_price_calc_code_loc   CONSTANT VARCHAR2(1) := '2'; -- �d���P���������^�C�v:�[����
--
  -- �t�уR�[�h
  gv_futai_code_0            CONSTANT VARCHAR2(1) := '0'; -- �t�уR�[�h:0
--
  -- �}�X�^�敪
  gv_price_type_po           CONSTANT VARCHAR2(1) := '1'; -- �}�X�^�敪:�d��
--
  -- �̔Ԋ֐��敪
  gv_seq_class_po            CONSTANT VARCHAR2(1) := '2'; -- �̔Ԋ֐��敪:�����ԍ�
--
  -- �����L���敪
  gv_test_code_y             CONSTANT VARCHAR2(1) := '1'; -- �����L���敪:�L
  gv_test_code_n             CONSTANT VARCHAR2(1) := '0'; -- �����L���敪:��
--
  -- ���b�g�X�e�[�^�X
  gv_lot_status_ok           CONSTANT VARCHAR2(2) := '50'; -- ���b�g�X�e�[�^�X:���i
  gv_lot_status_nochk        CONSTANT VARCHAR2(2) := '10'; -- ���b�g�X�e�[�^�X:������
--
  -- �쐬�敪
  insert_kbn_2               CONSTANT VARCHAR2(1) := '2';  -- �쐬�敪:2
  insert_kbn_3               CONSTANT VARCHAR2(1) := '3';  -- �쐬�敪:3
--
  -- API���^�[���E�R�[�h
  gv_api_ret_cd_normal       CONSTANT VARCHAR2(1) := 'S';  -- API���^�[���E�R�[�h:����I��
--
  -- �t���O
  gv_flg_y     CONSTANT VARCHAR2(1) := 'Y';  -- �t���O:Y
  gv_flg_n     CONSTANT VARCHAR2(1) := 'N';  -- �t���O:N
--
  -- ����^�C�v
  gv_trans_type_sok          CONSTANT NUMBER      := 2;    -- ����^�C�v:��������
--
  -- �����X�e�[�^�X
  gv_po_status_m             CONSTANT VARCHAR2(2) := '20';  -- �����X�e�[�^�X:�쐬��
--
  -- �����敪
  gv_direct_flg              CONSTANT VARCHAR2(1) := '1';  -- �����敪:�ʏ�
--
  -- �����敪
  gv_po_kbn                  CONSTANT VARCHAR2(1) := '1';  -- �����敪:�V�K
--
  -- ���K�敪
  gv_kosen_kbn_n             CONSTANT VARCHAR2(1) := '3';  -- ���K�敪:�Ȃ�
--
  -- ���ۋ��敪
  gv_fuka_kbn_n              CONSTANT VARCHAR2(1) := '3';  -- ���ۋ��敪:�Ȃ�
--
  -- ���b�g�Ǘ��敪
  gv_lot_ctl_y               CONSTANT VARCHAR2(1) := '1';  -- ���b�g�Ǘ��敪:���b�g�Ǘ��i
--
  -- �敪
  gt_division_gme     CONSTANT xxwip_qt_inspection.division%TYPE := '1';  -- �敪  1:���Y
  gt_division_po      CONSTANT xxwip_qt_inspection.division%TYPE := '2';  -- �敪  2:����
  gt_division_lot     CONSTANT xxwip_qt_inspection.division%TYPE := '3';  -- �敪  3:���b�g���
  gt_division_spl     CONSTANT xxwip_qt_inspection.division%TYPE := '4';  -- �敪  4:�O���o����
  gt_division_tea     CONSTANT xxwip_qt_inspection.division%TYPE := '5';  -- �敪  5:�r������
--
  -- �����敪
  gv_disposal_div_ins CONSTANT VARCHAR2(1) := '1'; -- �����敪  1:�ǉ�
  gv_disposal_div_upd CONSTANT VARCHAR2(1) := '2'; -- �����敪  2:�X�V
  gv_disposal_div_del CONSTANT VARCHAR2(1) := '3'; -- �����敪  3:�폜
--
-- 2008/08/18 H.Itou Add Start T_S_595
  -- �����t���O
  gv_inactive_ind_y   CONSTANT VARCHAR2(1) := '1'; -- �����t���O 1:����
--
  -- �p�~�敪
  gv_obsolete_class_y CONSTANT VARCHAR2(1) := '1'; -- �p�~�敪 1:�p�~
-- 2008/08/18 H.Itou Add End
--
-- 2008/12/02 H.Itou Add Start �{�ԏ�Q#171
  -- �N�C�b�N�R�[�h�^�C�v
  gv_plant_uniqe_sign CONSTANT VARCHAR2(100) := 'XXCMN_PLANT_UNIQE_SIGN'; -- �H��ŗL�L��
-- 2008/12/02 H.Itou Add End
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  -- ���b�Z�[�WPL/SQL�\�^
  TYPE msg_ttype         IS TABLE OF VARCHAR2(5000) INDEX BY BINARY_INTEGER;
--
  -- �o�������я��C���^�t�F�[�XID PL/SQL�\�^
  TYPE txns_if_id_ttype IS TABLE OF xxpo_vendor_supply_txns_if.txns_if_id%TYPE INDEX BY BINARY_INTEGER;
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  -- �f�[�^�_���v�pPL/SQL�\
  warn_dump_tab          msg_ttype; -- �x��
  normal_dump_tab        msg_ttype; -- ����
--
  -- �o�������я��C���^�t�F�[�XID PL/SQL�\
  txns_if_id_tab         txns_if_id_ttype;
--
  -- PL/SQL�\�J�E���g
  gn_warn_msg_cnt        NUMBER := 0; -- �x���G���[���b�Z�[�WPL/SQ�\ �J�E���g
  gn_po_cnt              NUMBER := 0; -- �o�b�`ID PL/SQL�\ �J�E���g
--
  -- �v���t�@�C���E�I�v�V����
  gv_ctpty_inv_rcv_rsn   VARCHAR2(100);          -- XXPO:�����݌Ɍv�㎖�R
  gv_ctpty_cost_rsn      VARCHAR2(100);          -- XXPO:����挴���v�㎖�R
  gv_purchase_emp_id     VARCHAR2(100);          -- XXPO:�w���S����ID
  gv_bill_to_location_id VARCHAR2(100);          -- XXPO:�����掖�Ə�ID
  gv_po_line_type_id     VARCHAR2(100);          -- XXPO:�������׃^�C�vID
  gv_cost_cmpntcls_code  VARCHAR2(100);          -- XXPO:���b�g����-�R���|�[�l���g�敪
  gv_cost_mthd_code      VARCHAR2(100);          -- XXPO:���b�g����-���b�g�������@
  gv_cost_analysis_code  VARCHAR2(100);          -- XXPO:���b�g����-����
  gv_org_id              VARCHAR2(100);          -- MO:�c�ƒP��
--
  -- ���̓p�����[�^
  gv_in_data_class             VARCHAR2(100);  -- �f�[�^���
  gv_in_vendor_code            VARCHAR2(100);  -- �����
  gv_in_factory_code           VARCHAR2(100);  -- �H��
  gv_in_manufactured_date_from VARCHAR2(100);  -- ���Y��FROM
  gv_in_manufactured_date_to   VARCHAR2(100);  -- ���Y��TO
  gv_in_security_kbn           VARCHAR2(100);  -- �Z�L�����e�B�敪
--
  gt_stock_value               xxpo_price_headers.total_amount%TYPE;              -- �݌ɒP��
  gt_unit_price                xxpo_price_headers.total_amount%TYPE;              -- �d���P��
  gt_po_number                 xxpo_headers_all.po_header_number%TYPE;            -- �����ԍ�
  gt_location_id               xxcmn_item_locations_v.inventory_location_id%TYPE; -- �[����ID(�ۊǏꏊID)
  gt_whse_code                 xxcmn_item_locations_v.whse_code%TYPE;             -- �q�ɃR�[�h
  gt_organization_id           xxcmn_item_locations_v.mtl_organization_id%TYPE;   -- �݌ɑg�DID
  gt_co_code                   sy_orgn_mst_b.co_code%TYPE;                        -- ��ЃR�[�h
  gt_orgn_code                 sy_orgn_mst_b.orgn_code%TYPE;                      -- �g�D�R�[�h
  gt_ship_to_location_id       hr_all_organization_units.location_id%TYPE;        -- �[���掖�Ə�ID(���Ə�ID)
  gt_lot_no                    xxpo_vendor_supply_txns.lot_number%TYPE;           -- ���b�gNo
  gt_lot_id                    xxpo_vendor_supply_txns.lot_id%TYPE;               -- ���b�gID
  gt_txns_id                   xxpo_vendor_supply_txns.txns_id%TYPE;              -- ����ID
  gt_batch_id                  po_headers_interface.batch_id%TYPE;                -- �o�b�`ID
--
  -- ===================================
  -- ���[�U�[��`�O���[�o���J�[�\��
  -- ===================================
  CURSOR main_cur IS
    SELECT xvsti.txns_if_id               txns_if_id          -- �o�������я��C���^�t�F�[�XID
          ,xvsti.manufactured_date        manufactured_date   -- ���Y��
          ,xvsti.vendor_code              vendor_code         -- �����R�[�h
          ,xvsti.factory_code             factory_code        -- �H��R�[�h
          ,xvsti.item_code                item_code           -- �i�ڃR�[�h
          ,xvsti.producted_date           producted_date      -- ������
          ,xvsti.koyu_code                koyu_code           -- �ŗL�L��
          ,xvsti.producted_quantity       producted_quantity  -- �o��������
          ,xvsti.description              description         -- �E�v
          ,xvv.product_result_type        product_result_type -- �����^�C�v
          ,xvv.vendor_id                  vendor_id           -- �����ID
          ,xvv.department                 department          -- ����
          ,xvsv.vendor_site_id            factory_id          -- �H��ID
          ,xvsv.vendor_id                 f_vendor_id         -- �H��R�[�h�̎����ID
          ,xicv.item_class_code           item_class_code     -- �i�ڋ敪
          ,ximv.item_id                   item_id             -- OPM�i��ID
          ,ximv.item_um                   uom                 -- �P�ʃR�[�h
          ,ximv.test_code                 test_code           -- �����L���敪
          ,ximv.cost_manage_code          cost_manage_code    -- �����Ǘ��敪
          ,ximv.lot_ctl                   lot_ctl             -- ���b�g�Ǘ��敪
          ,ximv.inventory_item_id         inventory_item_id   -- INV�i��ID
          ,xvsti.producted_date + TO_NUMBER(ximv.expiration_day)
                                          expiration_date     -- �ܖ�����
          ,ximv.unit_price_calc_code      unit_price_calc_code-- �d���P���������^�C�v
          ,CASE -- �[����R�[�h(�ۊǏꏊ�R�[�h)
                --   �����^�C�v1:�����݌Ɂ������݌ɓ��ɐ�
                --   �����^�C�v2:�����d���������[����
             WHEN (xvv.product_result_type = gv_product_result_type_inv) THEN
                  xvsv.vendor_stock_whse
             WHEN (xvv.product_result_type = gv_product_result_type_po) THEN
                  xvsv.delivery_whse
           END                            location_code
          ,CASE -- ���b�g�X�e�[�^�X
                --   �����L���敪1:�L��10:������
                --   �����L���敪0:����50:���i
             WHEN (ximv.test_code = gv_test_code_y) THEN
                  gv_lot_status_nochk
             WHEN (ximv.test_code = gv_test_code_n) THEN
                  gv_lot_status_ok
           END                            lot_status
          ,CASE -- �o�����P�ʃR�[�h
                --   ���i�敪2:�h�����N �i�ڋ敪5:���i ���o�Ɋ��Z�P�ʂ�NULL�łȂ������o�Ɋ��Z�P��
                --   ��L�ȊO���i�ڊ�P��
             WHEN ((xicv.prod_class_code = gv_prod_class_code_drink)
              AND  (xicv.item_class_code = gv_item_class_code_prod)
-- 2008/07/22 H.Itou Mod Start
--              AND  (ximv.conv_unit       = gv_um_cs)) THEN
              AND  (ximv.conv_unit       IS NOT NULL)) THEN
-- 2008/07/22 H.Itou Mod End
                  ximv.conv_unit
             ELSE ximv.item_um
           END                            producted_uom
          ,CASE -- �݌ɓ���
                --   �i�ڋ敪5:���i���P�[�X����
                --   ��L�ȊO����\����
             WHEN (xicv.item_class_code = gv_item_class_code_prod) THEN 
                  TO_NUMBER(ximv.num_of_cases) -- �P�[�X����
             ELSE TO_NUMBER(ximv.frequent_qty) -- ��\����
           END                            stock_qty
          ,CASE -- ���Z����
                --   ���i�敪2:�h�����N �i�ڋ敪5:���i ���o�Ɋ��Z�P�ʂ�NULL�łȂ����P�[�X����
                --   ��L�ȊO�����Z�s�v�Ȃ̂�1
             WHEN ((xicv.prod_class_code = gv_prod_class_code_drink)
              AND  (xicv.item_class_code = gv_item_class_code_prod)
-- 2008/07/22 H.Itou Mod Start
--              AND  (ximv.conv_unit       = gv_um_cs)) THEN
              AND  (ximv.conv_unit       IS NOT NULL)) THEN
-- 2008/07/22 H.Itou Mod End
                  TO_NUMBER(ximv.num_of_cases)
             ELSE 1
           END                            conversion_factor
-- 2008/08/18 H.Itou Add Start T_S_595
          ,ximv.inactive_ind              inactive_ind        -- �����t���O
          ,ximv.obsolete_class            obsolete_class      -- �p�~�敪
-- 2008/08/18 H.Itou Add End
          ,xvsti.corporation_name                         || gv_msg_comma ||
           xvsti.data_class                               || gv_msg_comma ||
           xvsti.transfer_branch_no                       || gv_msg_comma ||
           TO_CHAR(xvsti.manufactured_date, gv_yyyymmdd)  || gv_msg_comma ||
           xvsti.vendor_code                              || gv_msg_comma ||
           xvsti.factory_code                             || gv_msg_comma ||
           xvsti.item_code                                || gv_msg_comma ||
           TO_CHAR(xvsti.producted_date, gv_yyyymmdd)     || gv_msg_comma ||
           xvsti.koyu_code                                || gv_msg_comma ||
           TO_CHAR(xvsti.producted_quantity)              || gv_msg_comma ||
           TO_CHAR(xvsti.description)     data_dump           -- �f�[�^�_���v
    FROM   xxpo_vendor_supply_txns_if     xvsti               -- �o�������я��C���^�t�F�[�X
          ,xxcmn_vendors_v                xvv                 -- �d������VIEW
          ,xxcmn_vendor_sites_v           xvsv                -- �d����T�C�g���VIEW
-- 2008/08/18 H.Itou Mod Start T_S_595
--          ,xxcmn_item_mst_v              ximv                 -- OPM�i�ڏ��VIEW
          ,xxcmn_item_mst2_v              ximv                -- OPM�i�ڏ��VIEW2
-- 2008/08/18 H.Itou Mod End
          ,xxcmn_item_categories5_v       xicv                -- OPM�i�ڃJ�e�S���������VIEW5
    WHERE  -- ** ��������  �d������VIEW  ** --
           xvsti.vendor_code         = xvv.segment1(+)                 -- �����R�[�h
           -- ** ��������  �d������VIEW  ** --
    AND    xvsti.factory_code         = xvsv.vendor_site_code(+)       -- �H��R�[�h
           -- ** ��������  OPM�i�ڏ��VIEW  ** --
    AND    xvsti.item_code            = ximv.item_no(+)                -- �i�ڃR�[�h
-- 2008/08/18 H.Itou Add Start T_S_595
    AND    ximv.start_date_active(+) <= TRUNC(xvsti.producted_date)    -- �K�p�J�n�� <= ������
    AND    ximv.end_date_active(+)   >= TRUNC(xvsti.producted_date)    -- �K�p�I���� >= ������
-- 2008/08/18 H.Itou Add End
           -- ** ��������  OPM�i�ڃJ�e�S���������VIEW3  ** --
    AND    xvsti.item_code            = xicv.item_no(+)                -- �i�ڃR�[�h
           -- ** ���o���� ** --
    AND    xvsti.data_class           = gv_in_data_class               -- �f�[�^���
    AND    xvsti.vendor_code          = gv_in_vendor_code              -- �����
    AND    xvsti.factory_code         = NVL(gv_in_factory_code, xvsti.factory_code) -- �H��(���͂���̏ꍇ�A�����ɒǉ�)
    AND    xvsti.manufactured_date   >= FND_DATE.STRING_TO_DATE(gv_in_manufactured_date_from, gv_yyyymmddhh24miss) -- ���Y��FROM
    AND    xvsti.manufactured_date   <= FND_DATE.STRING_TO_DATE(gv_in_manufactured_date_to, gv_yyyymmddhh24miss)   -- ���Y��TO
    AND   ((gv_in_security_kbn        = gv_security_kbn_in)            -- �Z�L�����e�B�敪 1:�ɓ������[�U�[
      OR  (((gv_in_security_kbn       = gv_security_kbn_out)           -- �Z�L�����e�B�敪 2:����惆�[�U�[�̏ꍇ�A���O�C�����[�U�[�̎����R�[�h
        AND (xvsti.vendor_code IN (
              SELECT papf.attribute4    vendor_code                  -- �����R�[�h(�d����R�[�h)
              FROM   fnd_user           fu                           -- ���[�U�[�}�X�^
                    ,per_all_people_f   papf                         -- �]�ƈ��}�X�^
              WHERE  -- ** �������� ** --
                     fu.employee_id   = papf.person_id               -- �]�ƈ�ID
                     -- ** ���o���� ** --
              AND    papf.effective_start_date <= TRUNC(SYSDATE)     -- �K�p�J�n��
              AND    papf.effective_end_date   >= TRUNC(SYSDATE)     -- �K�p�I����
              AND    fu.start_date             <= TRUNC(SYSDATE)     -- �K�p�J�n��
              AND  ((fu.end_date               IS NULL)              -- �K�p�I����
                OR  (fu.end_date               >= TRUNC(SYSDATE)))
              AND    fu.user_id                 = FND_GLOBAL.USER_ID))))) -- ���[�U�[ID
  ;
--
  -- �J�[�\���p���R�[�h
  gr_main_data  main_cur%ROWTYPE;
--
  /**********************************************************************************
   * Procedure Name   : init_proc
   * Description      : ��������(B-1)
   ***********************************************************************************/
  PROCEDURE init_proc(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'init_proc'; -- �v���O������
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
    cv_ctpty_inv_rcv_rsn   VARCHAR2(100) := 'XXPO_CTPTY_INV_RCV_RSN';   -- XXPO:�����݌Ɍv�㎖�R
    cv_ctpty_cost_rsn      VARCHAR2(100) := 'XXPO_CTPTY_COST_RSN';      -- XXPO:����挴���v�㎖�R
    cv_purchase_emp_id     VARCHAR2(100) := 'XXPO_PURCHASE_EMP_ID';     -- XXPO:�w���S����ID
    cv_bill_to_location_id VARCHAR2(100) := 'XXPO_BILL_TO_LOCATION_ID'; -- XXPO:�����掖�Ə�ID
    cv_po_line_type_id     VARCHAR2(100) := 'XXPO_PO_LINE_TYPE_ID';     -- XXPO:�������׃^�C�vID
    cv_cost_cmpntcls_code  VARCHAR2(100) := 'XXPO_COST_CMPNTCLS_CODE';  -- XXPO:���b�g����-�R���|�[�l���g�敪
    cv_cost_mthd_code      VARCHAR2(100) := 'XXPO_COST_MTHD_CODE';      -- XXPO:���b�g����-���b�g�������@
    cv_cost_analysis_code  VARCHAR2(100) := 'XXPO_COST_ANALYSIS_CODE';  -- XXPO:���b�g����-����
    cv_org_id              VARCHAR2(100) := 'ORG_ID';                   -- MO:�c�ƒP��
--
    -- *** ���[�J���ϐ� ***
--
    -- *** ���[�J���E�J�[�\�� ***
    -- �o�������я��C���^�t�F�[�X�J�[�\��
    CURSOR xxpo_vendor_supply_txns_if_cur
    IS
      SELECT xvsti.txns_if_id            txns_if_id   -- �o�������я��C���^�t�F�[�XID
      FROM   xxpo_vendor_supply_txns_if  xvsti        -- �o�������я��C���^�t�F�[�X
      FOR UPDATE NOWAIT
    ;
--
    -- *** ���[�J���E���R�[�h ***
--
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ===========================
    -- �v���t�@�C���I�v�V�����擾
    -- ===========================
    gv_ctpty_inv_rcv_rsn   := FND_PROFILE.VALUE(cv_ctpty_inv_rcv_rsn);   -- XXPO:�����݌Ɍv�㎖�R
    gv_ctpty_cost_rsn      := FND_PROFILE.VALUE(cv_ctpty_cost_rsn);      -- XXPO:����挴���v�㎖�R
    gv_purchase_emp_id     := FND_PROFILE.VALUE(cv_purchase_emp_id);     -- XXPO:�w���S����ID
    gv_bill_to_location_id := FND_PROFILE.VALUE(cv_bill_to_location_id); -- XXPO:�����掖�Ə�ID
    gv_po_line_type_id     := FND_PROFILE.VALUE(cv_po_line_type_id);     -- XXPO:�������׃^�C�vID
    gv_cost_cmpntcls_code  := FND_PROFILE.VALUE(cv_cost_cmpntcls_code);  -- XXPO:���b�g����-�R���|�[�l���g�敪
    gv_cost_mthd_code      := FND_PROFILE.VALUE(cv_cost_mthd_code);      -- XXPO:���b�g����-���b�g�������@
    gv_cost_analysis_code  := FND_PROFILE.VALUE(cv_cost_analysis_code);  -- XXPO:���b�g����-����
    gv_org_id              := FND_PROFILE.VALUE(cv_org_id);              -- MO:�c�ƒP��
--
    -- =========================================
    -- �v���t�@�C���I�v�V�����擾�G���[�`�F�b�N
    -- =========================================
    IF (gv_ctpty_inv_rcv_rsn IS NULL) THEN -- XXPO:�����݌Ɍv�㎖�R�v���t�@�C���擾�G���[
      lv_errmsg  := SUBSTRB(
                      xxcmn_common_pkg.get_msg(
                        gv_xxcmn                   -- ���W���[��������:XXCMN
                       ,gv_msg_xxcmn10002          -- ���b�Z�[�W:APP-XXCMN-10002 �v���t�@�C���擾�G���[
                       ,gv_tkn_ng_profile          -- �g�[�N��:NG�v���t�@�C����
                       ,gv_tkn_ctpty_inv_rcv_rsn)  -- XXPO:�����݌Ɍv�㎖�R
                     ,1,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    IF (gv_ctpty_cost_rsn IS NULL) THEN -- XXPO:����挴���v�㎖�R�v���t�@�C���擾�G���[
      lv_errmsg  := SUBSTRB(
                      xxcmn_common_pkg.get_msg(
                        gv_xxcmn                   -- ���W���[��������:XXCMN
                       ,gv_msg_xxcmn10002          -- ���b�Z�[�W:APP-XXCMN-10002 �v���t�@�C���擾�G���[
                       ,gv_tkn_ng_profile          -- �g�[�N��:NG�v���t�@�C����
                       ,gv_tkn_ctpty_cost_rsn)     -- XXPO:����挴���v�㎖�R
                     ,1,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    IF (gv_purchase_emp_id IS NULL) THEN -- XXPO:�w���S����ID�v���t�@�C���擾�G���[
      lv_errmsg  := SUBSTRB(
                      xxcmn_common_pkg.get_msg(
                        gv_xxcmn                   -- ���W���[��������:XXCMN
                       ,gv_msg_xxcmn10002          -- ���b�Z�[�W:APP-XXCMN-10002 �v���t�@�C���擾�G���[
                       ,gv_tkn_ng_profile          -- �g�[�N��:NG�v���t�@�C����
                       ,gv_tkn_purchase_emp_id)    -- XXPO:�w���S����ID
                     ,1,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    IF (gv_bill_to_location_id IS NULL) THEN -- XXPO:�����掖�Ə�ID�v���t�@�C���擾�G���[
      lv_errmsg  := SUBSTRB(
                      xxcmn_common_pkg.get_msg(
                        gv_xxcmn                   -- ���W���[��������:XXCMN
                       ,gv_msg_xxcmn10002          -- ���b�Z�[�W:APP-XXCMN-10002 �v���t�@�C���擾�G���[
                       ,gv_tkn_ng_profile          -- �g�[�N��:NG�v���t�@�C����
                       ,gv_tkn_bill_to_location_id)-- XXPO:�����掖�Ə�ID
                     ,1,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    IF (gv_po_line_type_id IS NULL) THEN -- XXPO:�������׃^�C�vID�v���t�@�C���擾�G���[
      lv_errmsg  := SUBSTRB(
                      xxcmn_common_pkg.get_msg(
                        gv_xxcmn                   -- ���W���[��������:XXCMN
                       ,gv_msg_xxcmn10002          -- ���b�Z�[�W:APP-XXCMN-10002 �v���t�@�C���擾�G���[
                       ,gv_tkn_ng_profile          -- �g�[�N��:NG�v���t�@�C����
                       ,gv_tkn_po_line_type_id)    -- XXPO:�������׃^�C�vID
                     ,1,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    IF (gv_cost_cmpntcls_code IS NULL) THEN -- XXPO:���b�g����-�R���|�[�l���g�敪�v���t�@�C���擾�G���[
      lv_errmsg  := SUBSTRB(
                      xxcmn_common_pkg.get_msg(
                        gv_xxcmn                   -- ���W���[��������:XXCMN
                       ,gv_msg_xxcmn10002          -- ���b�Z�[�W:APP-XXCMN-10002 �v���t�@�C���擾�G���[
                       ,gv_tkn_ng_profile          -- �g�[�N��:NG�v���t�@�C����
                       ,gv_tkn_cost_cmpntcls_code) -- XXPO:���b�g����-�R���|�[�l���g�敪
                     ,1,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    IF (gv_cost_mthd_code IS NULL) THEN -- XXPO:���b�g����-���b�g�������@�v���t�@�C���擾�G���[
      lv_errmsg  := SUBSTRB(
                      xxcmn_common_pkg.get_msg(
                        gv_xxcmn                   -- ���W���[��������:XXCMN
                       ,gv_msg_xxcmn10002          -- ���b�Z�[�W:APP-XXCMN-10002 �v���t�@�C���擾�G���[
                       ,gv_tkn_ng_profile          -- �g�[�N��:NG�v���t�@�C����
                       ,gv_tkn_cost_mthd_code)     -- XXPO:���b�g����-���b�g�������@
                     ,1,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    IF (gv_cost_analysis_code IS NULL) THEN -- XXPO:���b�g����-���̓v���t�@�C���擾�G���[
      lv_errmsg  := SUBSTRB(
                      xxcmn_common_pkg.get_msg(
                        gv_xxcmn                   -- ���W���[��������:XXCMN
                       ,gv_msg_xxcmn10002          -- ���b�Z�[�W:APP-XXCMN-10002 �v���t�@�C���擾�G���[
                       ,gv_tkn_ng_profile          -- �g�[�N��:NG�v���t�@�C����
                       ,gv_tkn_cost_analysis_code) -- XXPO:���b�g����-����
                     ,1,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    IF (gv_org_id IS NULL) THEN --  MO:�c�ƒP��
      lv_errmsg  := SUBSTRB(
                      xxcmn_common_pkg.get_msg(
                        gv_xxcmn                   -- ���W���[��������:XXCMN
                       ,gv_msg_xxcmn10002          -- ���b�Z�[�W:APP-XXCMN-10002 �v���t�@�C���擾�G���[
                       ,gv_tkn_ng_profile          -- �g�[�N��:NG�v���t�@�C����
                       ,gv_tkn_org_id)             --  MO:�c�ƒP��
                     ,1,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- =========================================
    -- �o�������я��C���^�t�F�[�X���b�N�擾
    -- =========================================
    BEGIN
       <<lock_loop>>
      FOR lr_xxpo_vendor_supply_txns_if IN xxpo_vendor_supply_txns_if_cur
      LOOP
        EXIT;
      END LOOP lock_loop;
--
    EXCEPTION
      --*** ���b�N�擾�G���[ ***
      WHEN lock_expt THEN
        -- �G���[���b�Z�[�W�擾
        lv_errmsg  := SUBSTRB(
                        xxcmn_common_pkg.get_msg(
                          gv_xxcmn               -- ���W���[��������:XXCMN
                         ,gv_msg_xxcmn10019      -- ���b�Z�[�W:APP-XXCMN-10019 ���b�N�G���[
                         ,gv_tkn_table           -- �g�[�N��TABLE
                         ,gv_tkn_vendor_sply_txns_if)    -- �e�[�u����:�o�������я��C���^�t�F�[�X
                       ,1,5000);
        lv_errbuf := lv_errmsg;
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
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END init_proc;
--
  /**********************************************************************************
   * Procedure Name   : check_data
   * Description      : �擾�f�[�^�`�F�b�N����(B-3)
   ***********************************************************************************/
  PROCEDURE check_data(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'check_data'; -- �v���O������
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
--
    -- *** ���[�J���ϐ� ***
    ln_cnt NUMBER;
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
    -- ===========================
    -- �����R�[�h�`�F�b�N
    -- ===========================
    -- �����ID�𒊏o�ł��Ă��Ȃ��ꍇ�A�x��
    IF (gr_main_data.vendor_id IS NULL) THEN
      -- �x�����b�Z�[�W�o��
      lv_errmsg  := SUBSTRB(
                      xxcmn_common_pkg.get_msg(
                        gv_xxcmn               -- ���W���[��������:XXCMN ����
                       ,gv_msg_xxcmn10001      -- ���b�Z�[�W:APP-XXCMN-10001 �Ώۃf�[�^�Ȃ�
                       ,gv_tkn_table           -- �g�[�N��:TABLE
                       ,gv_tkn_vendors         -- �G���[�e�[�u����
                       ,gv_tkn_key             -- �g�[�N��:KEY
                       ,gv_tkn_vendor_code || gr_main_data.vendor_code)  -- �G���[�L�[����
                     ,1,5000);
--
      -- �x���_���vPL/SQL�\�Ƀ_���v���Z�b�g
      gn_warn_msg_cnt := gn_warn_msg_cnt + 1;
      warn_dump_tab(gn_warn_msg_cnt) := gr_main_data.data_dump;
--
      -- �x���_���vPL/SQL�\�Ɍx�����b�Z�[�W���Z�b�g
      gn_warn_msg_cnt := gn_warn_msg_cnt + 1;
      warn_dump_tab(gn_warn_msg_cnt) := lv_errmsg;
--
      -- ���^�[���E�R�[�h�Ɍx�����Z�b�g
      ov_retcode := gv_status_warn;
--
    END IF;
--
    -- ===========================
    -- �H��R�[�h�`�F�b�N
    -- ===========================
    -- �H��ID�𒊏o�ł��Ă��Ȃ��ꍇ�A�x��
    IF (gr_main_data.factory_id IS NULL) THEN
--
      -- �x�����b�Z�[�W�o��
      lv_errmsg  := SUBSTRB(
                      xxcmn_common_pkg.get_msg(
                        gv_xxcmn               -- ���W���[��������:XXCMN ����
                       ,gv_msg_xxcmn10001      -- ���b�Z�[�W:APP-XXCMN-10001 �Ώۃf�[�^�Ȃ�
                       ,gv_tkn_table           -- �g�[�N��:TABLE
                       ,gv_tkn_vendor_sites    -- �G���[�e�[�u����
                       ,gv_tkn_key             -- �g�[�N��:KEY
                       ,gv_tkn_vendor_site_code || gr_main_data.factory_code)  -- �G���[�L�[����
                     ,1,5000);
--
      -- ���łɌx���̏ꍇ�́A�_���v�s�v
      IF (ov_retcode <> gv_status_warn) THEN
        -- �x���_���vPL/SQL�\�Ƀ_���v���Z�b�g
        gn_warn_msg_cnt := gn_warn_msg_cnt + 1;
        warn_dump_tab(gn_warn_msg_cnt) := gr_main_data.data_dump;
      END IF;
--
      -- �x���_���vPL/SQL�\�Ɍx�����b�Z�[�W���Z�b�g
      gn_warn_msg_cnt := gn_warn_msg_cnt + 1;
      warn_dump_tab(gn_warn_msg_cnt) := lv_errmsg;
--
      -- ���^�[���E�R�[�h�Ɍx�����Z�b�g
      ov_retcode := gv_status_warn;
--
    END IF;
--
    -- ===========================
    -- �����R�[�h���H��R�[�h�Ó����`�F�b�N
    -- ===========================
    -- �����R�[�h�̎d����ID�ƁA�H��R�[�h�̎d����ID���قȂ�ꍇ�A�x��
    IF (gr_main_data.vendor_id <> gr_main_data.f_vendor_id) THEN
      -- �x�����b�Z�[�W�o��
      lv_errmsg  := SUBSTRB(
                      xxcmn_common_pkg.get_msg(
                        gv_xxpo                     -- ���W���[��������:XXPO
                       ,gv_msg_xxpo10215            -- ���b�Z�[�W:APP-XXPO-10215 �����֘A�`�F�b�N�G���[
                       ,gv_tkn_token                -- �g�[�N��:TOKEN
                       ,gv_tkn_factory_code_name)   -- �H��
                     ,1,5000);
--
      -- ���łɌx���̏ꍇ�́A�_���v�s�v
      IF (ov_retcode <> gv_status_warn) THEN
        -- �x���_���vPL/SQL�\�Ƀ_���v���Z�b�g
        gn_warn_msg_cnt := gn_warn_msg_cnt + 1;
        warn_dump_tab(gn_warn_msg_cnt) := gr_main_data.data_dump;
      END IF;
--
      -- �x���_���vPL/SQL�\�Ɍx�����b�Z�[�W���Z�b�g
      gn_warn_msg_cnt := gn_warn_msg_cnt + 1;
      warn_dump_tab(gn_warn_msg_cnt) := lv_errmsg;
--
      -- ���^�[���E�R�[�h�Ɍx�����Z�b�g
      ov_retcode := gv_status_warn;
    END IF;
--
    -- ===========================
    -- �i�ڃR�[�h�`�F�b�N
    -- ===========================
-- 2008/08/18 H.Itou Mod Start T_S_595
--    -- �i��ID�𒊏o�ł��Ă��Ȃ��ꍇ�A�x��
--    IF (gr_main_data.item_id IS NULL) THEN
    -- �i��ID�𒊏o�ł��Ă��Ȃ��ꍇ�A�܂��͖����̕i�ځA�܂��͔p�~�̕i�ڂ̏ꍇ�A�x��
    IF((gr_main_data.item_id IS NULL)
    OR (gr_main_data.inactive_ind   = gv_inactive_ind_y)            -- �����t���O
    OR (gr_main_data.obsolete_class = gv_obsolete_class_y)) THEN    -- �p�~�敪
-- 2008/08/18 H.Itou Add End
      -- �x�����b�Z�[�W�o��
      lv_errmsg  := SUBSTRB(
                      xxcmn_common_pkg.get_msg(
                        gv_xxcmn               -- ���W���[��������:XXCMN ����
                       ,gv_msg_xxcmn10001      -- ���b�Z�[�W:APP-XXCMN-10001 �Ώۃf�[�^�Ȃ�
                       ,gv_tkn_table           -- �g�[�N��:TABLE
                       ,gv_tkn_item_mst        -- �G���[�e�[�u����
                       ,gv_tkn_key             -- �g�[�N��:KEY
                       ,gv_tkn_item_code || gr_main_data.item_code)  -- �G���[�L�[����
                     ,1,5000);
--
      -- ���łɌx���̏ꍇ�́A�_���v�s�v
      IF (ov_retcode <> gv_status_warn) THEN
        -- �x���_���vPL/SQL�\�Ƀ_���v���Z�b�g
        gn_warn_msg_cnt := gn_warn_msg_cnt + 1;
        warn_dump_tab(gn_warn_msg_cnt) := gr_main_data.data_dump;
      END IF;
--
      -- �x���_���vPL/SQL�\�Ɍx�����b�Z�[�W���Z�b�g
      gn_warn_msg_cnt := gn_warn_msg_cnt + 1;
      warn_dump_tab(gn_warn_msg_cnt) := lv_errmsg;
--
      -- ���^�[���E�R�[�h�Ɍx�����Z�b�g
      ov_retcode := gv_status_warn;
--
-- 2008/07/22 H.Itou Add Start
    -- �i�ڂ����o�ł��āA���Z������NULL�܂��́A0�ȉ��̏ꍇ�A�x��
    ELSIF ((gr_main_data.conversion_factor IS NULL)
    OR     (gr_main_data.conversion_factor <= 0)) THEN
            -- �x�����b�Z�[�W�o��
      lv_errmsg  := SUBSTRB(
                      xxcmn_common_pkg.get_msg(
                        gv_xxcmn               -- ���W���[��������:XXCMN ����
                       ,gv_msg_xxcmn10603)     -- ���b�Z�[�W:APP-XXCMN-10603 �P�[�X�����G���[
                     ,1,5000);
--
      -- ���łɌx���̏ꍇ�́A�_���v�s�v
      IF (ov_retcode <> gv_status_warn) THEN
        -- �x���_���vPL/SQL�\�Ƀ_���v���Z�b�g
        gn_warn_msg_cnt := gn_warn_msg_cnt + 1;
        warn_dump_tab(gn_warn_msg_cnt) := gr_main_data.data_dump;
      END IF;
--
      -- �x���_���vPL/SQL�\�Ɍx�����b�Z�[�W���Z�b�g
      gn_warn_msg_cnt := gn_warn_msg_cnt + 1;
      warn_dump_tab(gn_warn_msg_cnt) := lv_errmsg;
--
      -- ���^�[���E�R�[�h�Ɍx�����Z�b�g
      ov_retcode := gv_status_warn;
-- 2008/07/22 H.Itou Add End
    END IF;
--
--
    -- ===========================
    -- ���b�g�Ǘ��i�`�F�b�N
    -- ===========================
    -- ���b�g�Ǘ��敪��1�ȊO�̏ꍇ�A�x��
    IF (gr_main_data.lot_ctl <> gv_lot_ctl_y) THEN
      -- �x�����b�Z�[�W�o��
      lv_errmsg  := SUBSTRB(
                      xxcmn_common_pkg.get_msg(
                        gv_xxpo                -- ���W���[��������:XXPO
                       ,gv_msg_xxpo10257)      -- ���b�Z�[�W:APP-XXPO-10257 ���b�g�Ǘ��O�i�G���[
                     ,1,5000);
--
      -- ���łɌx���̏ꍇ�́A�_���v�s�v
      IF (ov_retcode <> gv_status_warn) THEN
        -- �x���_���vPL/SQL�\�Ƀ_���v���Z�b�g
        gn_warn_msg_cnt := gn_warn_msg_cnt + 1;
        warn_dump_tab(gn_warn_msg_cnt) := gr_main_data.data_dump;
      END IF;
--
      -- �x���_���vPL/SQL�\�Ɍx�����b�Z�[�W���Z�b�g
      gn_warn_msg_cnt := gn_warn_msg_cnt + 1;
      warn_dump_tab(gn_warn_msg_cnt) := lv_errmsg;
--
      -- ���^�[���E�R�[�h�Ɍx�����Z�b�g
      ov_retcode := gv_status_warn;
--
    END IF;
--
    -- ===========================
    -- �����^�C�v�`�F�b�N
    -- ===========================
    -- �����^�C�v��1,2�ȊO�̏ꍇ�A�x��
    IF (gr_main_data.product_result_type NOT IN(gv_product_result_type_inv, gv_product_result_type_po)) THEN
      -- �x�����b�Z�[�W�o��
      lv_errmsg  := SUBSTRB(
                      xxcmn_common_pkg.get_msg(
                        gv_xxpo                -- ���W���[��������:XXPO
                       ,gv_msg_xxpo10226)      -- ���b�Z�[�W:APP-XXPO-10226 �����^�C�v�G���[
                     ,1,5000);
--
      -- ���łɌx���̏ꍇ�́A�_���v�s�v
      IF (ov_retcode <> gv_status_warn) THEN
        -- �x���_���vPL/SQL�\�Ƀ_���v���Z�b�g
        gn_warn_msg_cnt := gn_warn_msg_cnt + 1;
        warn_dump_tab(gn_warn_msg_cnt) := gr_main_data.data_dump;
      END IF;
--
      -- �x���_���vPL/SQL�\�Ɍx�����b�Z�[�W���Z�b�g
      gn_warn_msg_cnt := gn_warn_msg_cnt + 1;
      warn_dump_tab(gn_warn_msg_cnt) := lv_errmsg;
--
      -- ���^�[���E�R�[�h�Ɍx�����Z�b�g
      ov_retcode := gv_status_warn;
--
    END IF;
--
    -- ===========================
    -- �o�������ʃ`�F�b�N
    -- ===========================
    -- 0�ȉ��͌x��
    IF (gr_main_data.producted_quantity <= 0) THEN
      -- �x�����b�Z�[�W�o��
      lv_errmsg  := SUBSTRB(
                      xxcmn_common_pkg.get_msg(
                        gv_xxpo                    -- ���W���[��������:XXPO
                       ,gv_msg_xxpo10255           -- ���b�Z�[�W:APP-XXPO-10255 ���l0�ȉ��G���[2
                       ,gv_tkn_item                -- �g�[�N��ITEM
                       ,gv_tkn_producted_qty_name) -- �o��������
                     ,1,5000);
--
      -- ���łɌx���̏ꍇ�́A�_���v�s�v
      IF (ov_retcode <> gv_status_warn) THEN
        -- �x���_���vPL/SQL�\�Ƀ_���v���Z�b�g
        gn_warn_msg_cnt := gn_warn_msg_cnt + 1;
        warn_dump_tab(gn_warn_msg_cnt) := gr_main_data.data_dump;
      END IF;
--
      -- �x���_���vPL/SQL�\�Ɍx�����b�Z�[�W���Z�b�g
      gn_warn_msg_cnt := gn_warn_msg_cnt + 1;
      warn_dump_tab(gn_warn_msg_cnt) := lv_errmsg;
--
      -- ���^�[���E�R�[�h�Ɍx�����Z�b�g
      ov_retcode := gv_status_warn;
    END IF;
--
    -- �i�ڋ敪��5:���i�̏ꍇ
    IF (gr_main_data.item_class_code = gv_item_class_code_prod) THEN
      -- ===========================
      -- �ŗL�L���`�F�b�N�K�{�`�F�b�N
      -- ===========================
      IF (gr_main_data.koyu_code IS NULL) THEN
        -- �x�����b�Z�[�W�o��
        lv_errmsg  := SUBSTRB(
                        xxcmn_common_pkg.get_msg(
                          gv_xxpo                -- ���W���[��������:XXPO
                         ,gv_msg_xxpo10256       -- ���b�Z�[�W:APP-XXPO-10256 ���i�K�{�G���[
                         ,gv_tkn_item            -- �g�[�N��ITEM
                         ,gv_tkn_koyu_code_name) -- �ŗL�L��
                       ,1,5000);
--
        -- ���łɌx���̏ꍇ�́A�_���v�s�v
        IF (ov_retcode <> gv_status_warn) THEN
          -- �x���_���vPL/SQL�\�Ƀ_���v���Z�b�g
          gn_warn_msg_cnt := gn_warn_msg_cnt + 1;
          warn_dump_tab(gn_warn_msg_cnt) := gr_main_data.data_dump;
        END IF;
--
        -- �x���_���vPL/SQL�\�Ɍx�����b�Z�[�W���Z�b�g
        gn_warn_msg_cnt := gn_warn_msg_cnt + 1;
        warn_dump_tab(gn_warn_msg_cnt) := lv_errmsg;
--
        -- ���^�[���E�R�[�h�Ɍx�����Z�b�g
        ov_retcode := gv_status_warn;
-- 2008/12/02 H.Itou Add Start �{�ԏ�Q#171
      ELSE
        -- ===========================
        -- �ŗL�L���}�X�^���݃`�F�b�N
        -- ===========================
-- 2009/02/10 v1.7 N.Yoshida Mod Start
--        SELECT COUNT(1) cnt
--        INTO   ln_cnt
--        FROM   xxcmn_lookup_values_v  xlvv            -- �N�C�b�N�R�[�h���V
--        WHERE  xlvv.lookup_type = gv_plant_uniqe_sign -- �^�C�v�FXXCMN_PLANT_UNIQE_SIGN
--        AND    xlvv.lookup_code = gr_main_data.koyu_code
--        ;
        SELECT COUNT(1) cnt
        INTO   ln_cnt
        FROM   xxpo_price_headers  xph                           -- �d����W���P���w�b�_
        WHERE  xph.item_id             = gr_main_data.item_id    -- �i��ID
        AND    xph.vendor_id           = gr_main_data.vendor_id  -- �����ID
        AND    xph.factory_id          = gr_main_data.factory_id -- �H��ID
        AND    xph.koyu_code           = gr_main_data.koyu_code  -- �ŗL�L��
        AND    xph.futai_code          = gv_futai_code_0         -- �t�уR�[�h
        AND    xph.price_type          = gv_price_type_po        -- �}�X�^�敪1:�d��
        AND    xph.supply_to_code      IS NULL                   -- �x����R�[�h
        AND    (((gr_main_data.unit_price_calc_code = gv_unit_price_calc_code_prod)      -- �d���P���������^�C�v��1:�������̏ꍇ�A������������
          AND  (xph.start_date_active <= gr_main_data.producted_date)      -- �K�p�J�n�� <= ������
          AND  (xph.end_date_active   >= gr_main_data.producted_date))     -- �K�p�I���� >= ������
        OR     ((gr_main_data.unit_price_calc_code  = gv_unit_price_calc_code_loc)       -- �d���P���������^�C�v��2:�[�����̏ꍇ�A���������Y��
          AND  (xph.start_date_active <= gr_main_data.manufactured_date)   -- �K�p�J�n�� <= ���Y��
          AND  (xph.end_date_active   >= gr_main_data.manufactured_date))) -- �K�p�I���� >= ���Y��
        ;
-- 2009/02/10 v1.7 N.Yoshida Mod End
--
        -- �}�X�^�ɓo�^���Ȃ��ꍇ
        IF (ln_cnt = 0) THEN
          -- �x�����b�Z�[�W�o��
          lv_errmsg  := SUBSTRB(
                          xxcmn_common_pkg.get_msg(
                            gv_xxcmn               -- ���W���[��������:XXCMN ����
                           ,gv_msg_xxcmn10001      -- ���b�Z�[�W:APP-XXCMN-10001 �Ώۃf�[�^�Ȃ�
                           ,gv_tkn_table           -- �g�[�N��:TABLE
                           ,gv_tkn_koyu_code_name  -- �G���[�e�[�u����
                           ,gv_tkn_key             -- �g�[�N��:KEY
                           ,gv_tkn_koyu_code || gr_main_data.koyu_code)  -- �G���[�L�[����
                         ,1,5000);
--
          -- ���łɌx���̏ꍇ�́A�_���v�s�v
          IF (ov_retcode <> gv_status_warn) THEN
            -- �x���_���vPL/SQL�\�Ƀ_���v���Z�b�g
            gn_warn_msg_cnt := gn_warn_msg_cnt + 1;
            warn_dump_tab(gn_warn_msg_cnt) := gr_main_data.data_dump;
          END IF;
--
          -- �x���_���vPL/SQL�\�Ɍx�����b�Z�[�W���Z�b�g
          gn_warn_msg_cnt := gn_warn_msg_cnt + 1;
          warn_dump_tab(gn_warn_msg_cnt) := lv_errmsg;
--
          -- ���^�[���E�R�[�h�Ɍx�����Z�b�g
          ov_retcode := gv_status_warn;
        END IF;
-- 2008/12/02 H.Itou Add End
      END IF;
--
-- 2008/12/02 H.Itou Add Start �{�ԏ�Q#171
    -- �i�ڋ敪��5:���i�ȊO�̏ꍇ�ŁA�ŗL�L���ɓ��͂�����ꍇ
    ELSIF (gr_main_data.koyu_code IS NOT NULL) THEN
      -- ===========================
      -- �ŗL�L���}�X�^���݃`�F�b�N
      -- ===========================
-- 2009/02/10 v1.7 N.Yoshida Mod Start
--      SELECT COUNT(1) cnt
--      INTO   ln_cnt
--      FROM   xxcmn_lookup_values_v  xlvv            -- �N�C�b�N�R�[�h���V
--      WHERE  xlvv.lookup_type = gv_plant_uniqe_sign -- �^�C�v�FXXCMN_PLANT_UNIQE_SIGN
--      AND    xlvv.lookup_code = gr_main_data.koyu_code
--      ;
      SELECT COUNT(1) cnt
      INTO   ln_cnt
      FROM   xxpo_price_headers  xph                           -- �d����W���P���w�b�_
      WHERE  xph.item_id             = gr_main_data.item_id    -- �i��ID
      AND    xph.vendor_id           = gr_main_data.vendor_id  -- �����ID
      AND    xph.factory_id          = gr_main_data.factory_id -- �H��ID
      AND    xph.koyu_code           = gr_main_data.koyu_code  -- �ŗL�L��
      AND    xph.futai_code          = gv_futai_code_0         -- �t�уR�[�h
      AND    xph.price_type          = gv_price_type_po        -- �}�X�^�敪1:�d��
      AND    xph.supply_to_code      IS NULL                   -- �x����R�[�h
      AND    (((gr_main_data.unit_price_calc_code = gv_unit_price_calc_code_prod)      -- �d���P���������^�C�v��1:�������̏ꍇ�A������������
        AND  (xph.start_date_active <= gr_main_data.producted_date)      -- �K�p�J�n�� <= ������
        AND  (xph.end_date_active   >= gr_main_data.producted_date))     -- �K�p�I���� >= ������
      OR     ((gr_main_data.unit_price_calc_code  = gv_unit_price_calc_code_loc)       -- �d���P���������^�C�v��2:�[�����̏ꍇ�A���������Y��
        AND  (xph.start_date_active <= gr_main_data.manufactured_date)   -- �K�p�J�n�� <= ���Y��
        AND  (xph.end_date_active   >= gr_main_data.manufactured_date))) -- �K�p�I���� >= ���Y��
      ;
-- 2009/02/10 v1.7 N.Yoshida Mod End
--
      -- �}�X�^�ɓo�^���Ȃ��ꍇ
      IF (ln_cnt = 0) THEN
        -- �x�����b�Z�[�W�o��
        lv_errmsg  := SUBSTRB(
                        xxcmn_common_pkg.get_msg(
                          gv_xxcmn               -- ���W���[��������:XXCMN ����
                         ,gv_msg_xxcmn10001      -- ���b�Z�[�W:APP-XXCMN-10001 �Ώۃf�[�^�Ȃ�
                         ,gv_tkn_table           -- �g�[�N��:TABLE
                         ,gv_tkn_koyu_code_name  -- �G���[�e�[�u����
                         ,gv_tkn_key             -- �g�[�N��:KEY
                         ,gv_tkn_koyu_code || gr_main_data.koyu_code)  -- �G���[�L�[����
                       ,1,5000);
--
        -- ���łɌx���̏ꍇ�́A�_���v�s�v
        IF (ov_retcode <> gv_status_warn) THEN
          -- �x���_���vPL/SQL�\�Ƀ_���v���Z�b�g
          gn_warn_msg_cnt := gn_warn_msg_cnt + 1;
          warn_dump_tab(gn_warn_msg_cnt) := gr_main_data.data_dump;
        END IF;
--
        -- �x���_���vPL/SQL�\�Ɍx�����b�Z�[�W���Z�b�g
        gn_warn_msg_cnt := gn_warn_msg_cnt + 1;
        warn_dump_tab(gn_warn_msg_cnt) := lv_errmsg;
--
        -- ���^�[���E�R�[�h�Ɍx�����Z�b�g
        ov_retcode := gv_status_warn;
      END IF;
-- 2008/12/02 H.Itou Add End
    END IF;
--
    -- ===========================
    -- ���Y���N���[�Y�`�F�b�N
    -- ===========================
    -- ���Y���̔N�����A�݌ɃN���[�Y�N�������̏ꍇ�A�x��
    IF (TO_CHAR(gr_main_data.manufactured_date, gv_yyyymm) <= xxcmn_common_pkg.get_opminv_close_period) THEN
      -- �x�����b�Z�[�W�o��
      lv_errmsg  := SUBSTRB(
                      xxcmn_common_pkg.get_msg(
                        gv_xxpo                -- ���W���[��������:XXPO
                       ,gv_msg_xxpo10119)      -- ���b�Z�[�W:APP-XXPO-10119 �݌ɃN���[�Y�G���[3
                     ,1,5000);
--
      -- ���łɌx���̏ꍇ�́A�_���v�s�v
      IF (ov_retcode <> gv_status_warn) THEN
        -- �x���_���vPL/SQL�\�Ƀ_���v���Z�b�g
        gn_warn_msg_cnt := gn_warn_msg_cnt + 1;
        warn_dump_tab(gn_warn_msg_cnt) := gr_main_data.data_dump;
      END IF;
--
      -- �x���_���vPL/SQL�\�Ɍx�����b�Z�[�W���Z�b�g
      gn_warn_msg_cnt := gn_warn_msg_cnt + 1;
      warn_dump_tab(gn_warn_msg_cnt) := lv_errmsg;
--
      -- ���^�[���E�R�[�h�Ɍx�����Z�b�g
      ov_retcode := gv_status_warn;
    END IF;
--
    -- �i�ڋ敪��5:���i�̏ꍇ
    IF (gr_main_data.item_class_code = gv_item_class_code_prod) THEN
      -- ===========================
      --���b�g�}�X�^���݃`�F�b�N
      -- ===========================
      SELECT COUNT(1)
      INTO   ln_cnt
      FROM   ic_lots_mst ilm  -- OPM���b�g�}�X�^
      WHERE  ilm.attribute1 = TO_CHAR(gr_main_data.producted_date, gv_yyyymmdd)     -- ������
      AND    ilm.attribute2 = gr_main_data.koyu_code                                -- �ŗL�L��
      AND    ilm.item_id    = gr_main_data.item_id                                  -- �i��ID
      AND    ROWNUM         = 1
      ;
      -- 1���̏ꍇ�A�x��
      IF (ln_cnt = 1) THEN
        -- �x�����b�Z�[�W�o��
        lv_errmsg  := SUBSTRB(
                        xxcmn_common_pkg.get_msg(
                          gv_xxpo               -- ���W���[��������:XXPO
                         ,gv_msg_xxpo10005)     -- ���b�Z�[�W:APP-XXPO-10005 ���b�g�o�^�ς݃G���[
                       ,1,5000);
--
        -- ���łɌx���̏ꍇ�́A�_���v�s�v
        IF (ov_retcode <> gv_status_warn) THEN
          -- �x���_���vPL/SQL�\�Ƀ_���v���Z�b�g
          gn_warn_msg_cnt := gn_warn_msg_cnt + 1;
          warn_dump_tab(gn_warn_msg_cnt) := gr_main_data.data_dump;
        END IF;
--
        -- �x���_���vPL/SQL�\�Ɍx�����b�Z�[�W���Z�b�g
        gn_warn_msg_cnt := gn_warn_msg_cnt + 1;
        warn_dump_tab(gn_warn_msg_cnt) := lv_errmsg;
--
        -- ���^�[���E�R�[�h�Ɍx�����Z�b�g
        ov_retcode := gv_status_warn;
--
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
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END check_data;
--
  /**********************************************************************************
   * Procedure Name   : get_other_data
   * Description      : �֘A�f�[�^�擾����(B-4)
   ***********************************************************************************/
  PROCEDURE get_other_data(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_other_data'; -- �v���O������
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
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ===========================
    -- �݌ɒP���擾
    -- ===========================
    -- �����Ǘ��敪��1:�W�������̏ꍇ
    IF (gv_cost_manage_code_h = gr_main_data.cost_manage_code) THEN
      -- �݌ɒP����NULL
      gt_stock_value := null;
--
    -- �����Ǘ��敪��0:���ی����̏ꍇ
    ELSIF (gv_cost_manage_code_j = gr_main_data.cost_manage_code) THEN
      -- �����^�C�v��1:�����݌ɂ̏ꍇ
      IF (gv_product_result_type_inv = gr_main_data.product_result_type) THEN
        -- �݌ɒP����0
        gt_stock_value := 0;
--
      -- �����^�C�v��2:�����d���̏ꍇ
      ELSIF (gv_product_result_type_po = gr_main_data.product_result_type) THEN
        -- �d��/�W���P���w�b�_����擾
        BEGIN                                                    
          SELECT xph.total_amount    total_amount                  -- ���󍇌v
          INTO   gt_stock_value                                 
          FROM   xxpo_price_headers  xph                           -- �d����W���P���w�b�_
          WHERE  xph.item_id             = gr_main_data.item_id    -- �i��ID
          AND    xph.vendor_id           = gr_main_data.vendor_id  -- �����ID
          AND    xph.factory_id          = gr_main_data.factory_id -- �H��ID
          AND    xph.futai_code          = gv_futai_code_0         -- �t�уR�[�h
          AND    xph.price_type          = gv_price_type_po        -- �}�X�^�敪1:�d��
          AND    xph.supply_to_code      IS NULL                   -- �x����R�[�h
          AND    (((gr_main_data.unit_price_calc_code = gv_unit_price_calc_code_prod)      -- �d���P���������^�C�v��1:�������̏ꍇ�A������������
            AND  (xph.start_date_active <= gr_main_data.producted_date)      -- �K�p�J�n�� <= ������
            AND  (xph.end_date_active   >= gr_main_data.producted_date))     -- �K�p�I���� >= ������
          OR     ((gr_main_data.unit_price_calc_code  = gv_unit_price_calc_code_loc)       -- �d���P���������^�C�v��2:�[�����̏ꍇ�A���������Y��
            AND  (xph.start_date_active <= gr_main_data.manufactured_date)   -- �K�p�J�n�� <= ���Y��
            AND  (xph.end_date_active   >= gr_main_data.manufactured_date)));-- �K�p�I���� >= ���Y��
        EXCEPTION
          -- �f�[�^���Ȃ��ꍇ��0
          WHEN OTHERS THEN
            gt_stock_value := 0;
        END;
      END IF;
    END IF;
--
    -- �����^�C�v��2:�����d���̏ꍇ
    IF (gv_product_result_type_po = gr_main_data.product_result_type) THEN
      -- ===========================
      -- �d���P���擾
      -- ===========================
      BEGIN
        SELECT xph.total_amount    total_amount                  -- ���󍇌v
        INTO   gt_unit_price
        FROM   xxpo_price_headers  xph                           -- �d����W���P���w�b�_
        WHERE  xph.item_id             = gr_main_data.item_id    -- �i��ID
        AND    xph.vendor_id           = gr_main_data.vendor_id  -- �����ID
        AND    xph.factory_id          = gr_main_data.factory_id -- �H��ID
        AND    xph.futai_code          = gv_futai_code_0         -- �t�уR�[�h
        AND    xph.price_type          = gv_price_type_po        -- �}�X�^�敪1:�d��
        AND    xph.supply_to_code      IS NULL                   -- �x����R�[�h
        AND    (((gr_main_data.unit_price_calc_code = gv_unit_price_calc_code_prod)      -- �d���P���������^�C�v��1:�������̏ꍇ�A������������
          AND  (xph.start_date_active <= gr_main_data.producted_date)      -- �K�p�J�n�� <= ������
          AND  (xph.end_date_active   >= gr_main_data.producted_date))     -- �K�p�I���� >= ������
        OR     ((gr_main_data.unit_price_calc_code  = gv_unit_price_calc_code_loc)       -- �d���P���������^�C�v��2:�[�����̏ꍇ�A���������Y��
          AND  (xph.start_date_active <= gr_main_data.manufactured_date)   -- �K�p�J�n�� <= ���Y��
          AND  (xph.end_date_active   >= gr_main_data.manufactured_date)));-- �K�p�I���� >= ���Y��
      EXCEPTION
        -- �f�[�^���Ȃ��ꍇ��0
        WHEN OTHERS THEN
          gt_unit_price := 0;
      END;
--
      -- ===========================
      -- �����ԍ��擾
      -- ===========================
      xxcmn_common_pkg.get_seq_no(
        iv_seq_class  => gv_seq_class_po  -- �̔Ԃ���ԍ���\���敪 2:�����ԍ�
       ,ov_seq_no     => gt_po_number     -- �����ԍ�
       ,ov_errbuf     => lv_errbuf        -- �G���[���b�Z�[�W
       ,ov_retcode    => lv_retcode       -- ���^�[���R�[�h
       ,ov_errmsg     => lv_errmsg );     -- ���[�U�[�E�G���[�E���b�Z�[�W
--
      -- �G���[�̏ꍇ�A�����I��
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
    END IF;
--
    -- ===========================
    -- �[������擾�擾
    -- ===========================
    SELECT xilv.inventory_location_id location_id           -- �[����ID(�q��ID)
          ,xilv.whse_code             whse_code             -- �q�ɃR�[�h
          ,xilv.mtl_organization_id   organization_id       -- �݌ɑg�DID
          ,somb.co_code               co_code               -- ��ЃR�[�h
          ,somb.orgn_code             orgn_code             -- �g�D�R�[�h
          ,haou.location_id           ship_to_location_id   -- �[���掖�Ə�ID(���Ə�ID)
    INTO   gt_location_id
          ,gt_whse_code
          ,gt_organization_id
          ,gt_co_code
          ,gt_orgn_code
          ,gt_ship_to_location_id
    FROM   xxcmn_item_locations_v     xilv                  -- OPM�ۊǏꏊ���V
          ,ic_whse_mst                iwm                   -- OPM�q�Ƀ}�X�^
          ,sy_orgn_mst_b              somb                  -- OPM�v�����g�}�X�^
          ,hr_all_organization_units  haou                  -- �g�D�}�X�^
    WHERE  xilv.whse_code  = iwm.whse_code                  -- �q�ɃR�[�h
    AND    iwm.orgn_code   = somb.orgn_code                 -- �v�����g�R�[�h
    AND    xilv.mtl_organization_id  = haou.organization_id -- �g�DID
    AND    xilv.segment1   = gr_main_data.location_code     -- �[����R�[�h(�ۊǏꏊ�R�[�h)
    AND    haou.date_from <= TRUNC(SYSDATE)                 -- �K�p�� <= SYSDATE
    AND  ((haou.date_to   >= TRUNC(SYSDATE))                -- �K�p�� >= SYSDATE
      OR  (haou.date_to IS NULL));
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_other_data;
--
  /**********************************************************************************
   * Procedure Name   : ins_ic_lot_mst
   * Description      : ���b�g�}�X�^�o�^����(B-5)
   ***********************************************************************************/
  PROCEDURE ins_ic_lot_mst(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_ic_lot_mst'; -- �v���O������
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
    ln_api_version_number  CONSTANT NUMBER := 3.0; -- ���b�g�쐬API �o�[�W����No
--
    -- *** ���[�J���ϐ� ***
    lv_sublot_no         VARCHAR2(5000);
    lr_lot_in            gmigapi.lot_rec_typ;  -- IN���b�g���
    lr_lot_out           ic_lots_mst%ROWTYPE;  -- OUT���b�g���
    lr_lot_cpg_out       ic_lots_cpg%ROWTYPE;
    lb_setup_return_sts  BOOLEAN;
    ln_msg_count         NUMBER;
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
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ===========================
    -- ������
    -- ===========================
    lr_lot_in      := NULL;
    lr_lot_out     := NULL;
    lr_lot_cpg_out := NULL;
    FND_MSG_PUB.INITIALIZE(); -- API���b�Z�[�W
--
    -- ===========================
    -- ���b�gNo�擾
    -- ===========================
    GMI_AUTOLOT.GENERATE_LOT_NUMBER(  
      p_item_id        => gr_main_data.item_id  -- IN:�i��ID
     ,p_in_lot_no      => NULL
     ,p_orgn_code      => NULL
     ,p_doc_id         => NULL
     ,p_line_id        => NULL
     ,p_doc_type       => NULL
     ,p_out_lot_no     => gt_lot_no    -- OUT:���b�g�ԍ�
     ,p_sublot_no      => lv_sublot_no -- OUT:�T�u���b�g�ԍ�
     ,p_return_status  => lv_retcode); -- OUT:���^�[���R�[�h
--
    -- ���b�gNo���擾�ł��Ȃ������ꍇ�A�G���[
    IF (gt_lot_no IS NULL) THEN
      -- �G���[���b�Z�[�W�擾
      lv_errmsg  := SUBSTRB(
                      xxcmn_common_pkg.get_msg(
                        gv_xxpo                 -- ���W���[��������:XXPO
                       ,gv_msg_xxpo10110        -- ���b�Z�[�W:APP-XXPO-10110 ���b�g�̔ԃG���[
                       ,gv_tkn_item_no          -- �g�[�N��ITEM_NO
                       ,gr_main_data.item_code) -- �i�ڃR�[�h
                     ,1,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ===========================
    -- GMI�nAPI�O���[�o���萔�̐ݒ�
    -- ===========================
    lb_setup_return_sts  :=  GMIGUTL.SETUP(FND_GLOBAL.USER_NAME);
--
    -- ===========================
    -- ���b�g�쐬API���s
    -- ===========================
    BEGIN
      -- ���R�[�h�ɒl���Z�b�g
      lr_lot_in.item_no          := gr_main_data.item_code;        -- �i��
      lr_lot_in.lot_no           := gt_lot_no;                     -- ���b�g�ԍ�
      lr_lot_in.lot_created      := SYSDATE;                       -- �쐬��
      lr_lot_in.strength         := 100;                           -- ���x
      lr_lot_in.inactive_ind     := 0;                             -- �L��
      lr_lot_in.origination_type := '0';                           -- ���^�C�v
      lr_lot_in.attribute1       := TO_CHAR(gr_main_data.producted_date, gv_yyyymmdd);  -- �����N����
      lr_lot_in.attribute2       := gr_main_data.koyu_code;        -- �ŗL�L��
      lr_lot_in.attribute3       := TO_CHAR(gr_main_data.expiration_date, gv_yyyymmdd); -- �ܖ�����
      lr_lot_in.attribute7       := gt_stock_value;                -- �݌ɒP��
      lr_lot_in.attribute23      := gr_main_data.lot_status;       -- ���b�g�X�e�[�^�X
      lr_lot_in.attribute8       := gr_main_data.vendor_code;      -- �����R�[�h
--
      -- �����^�C�v��1:�����݌ɂ̏ꍇ
      IF (gv_product_result_type_inv = gr_main_data.product_result_type) THEN
        lr_lot_in.attribute24      := insert_kbn_2;                -- �쐬�敪:2
        lr_lot_in.attribute6       := NULL;                        -- �݌ɓ���
--
      -- �����^�C�v��2:�����d���̏ꍇ
      ELSIF (gv_product_result_type_po = gr_main_data.product_result_type) THEN
        lr_lot_in.attribute24      := insert_kbn_3;                -- �쐬�敪:3
        lr_lot_in.attribute6       := gr_main_data.stock_qty;      -- �݌ɓ���
      END IF;
--
-- 2008/12/24 v1.5 Y.Yamamoto add start
      lr_lot_in.expaction_date   := TO_DATE('2099/12/31', 'YYYY/MM/DD');
      lr_lot_in.expire_date      := TO_DATE('2099/12/31', 'YYYY/MM/DD');
-- 2008/12/24 v1.5 Y.Yamamoto add end
      -- API���s
      GMIPAPI.CREATE_LOT(
        p_api_version      => ln_api_version_number       -- IN:API�̃o�[�W�����ԍ�
       ,p_init_msg_list    => FND_API.G_FALSE             -- IN:���b�Z�[�W�������t���O
       ,p_commit           => FND_API.G_FALSE             -- IN:�����m��t���O
       ,p_validation_level => FND_API.G_VALID_LEVEL_FULL  -- IN:���؃��x��
       ,p_lot_rec          => lr_lot_in                   -- IN:�쐬���郍�b�g�����w��
       ,x_ic_lots_mst_row  => lr_lot_out                  -- OUT:�쐬���ꂽ���b�g��񂪕ԋp
       ,x_ic_lots_cpg_row  => lr_lot_cpg_out              -- OUT:�쐬���ꂽ���b�g��񂪕ԋp
       ,x_return_status    => lv_retcode                  -- OUT:�I���X�e�[�^�X( 'S'-����I��, 'E'-��O����, 'U'-�V�X�e����O����)
       ,x_msg_count        => ln_msg_count                -- OUT:���b�Z�[�W�E�X�^�b�N��
       ,x_msg_data         => lv_errmsg);                 -- OUT:���b�Z�[�W
--
      -- �߂�l������ȊO�̏ꍇ�A�G���[
      IF (lv_retcode <> gv_api_ret_cd_normal) THEN
        -- �G���[���O�o��
        xxcmn_common_pkg.put_api_log(
          ov_errbuf     => lv_errbuf     -- �G���[�E���b�Z�[�W
         ,ov_retcode    => lv_retcode    -- ���^�[���E�R�[�h
         ,ov_errmsg     => lv_errmsg);   -- ���[�U�[�E�G���[�E���b�Z�[�W
--
        -- �G���[���b�Z�[�W�擾
        lv_errmsg  := SUBSTRB(
                        xxcmn_common_pkg.get_msg(
                          gv_xxpo               -- ���W���[��������:XXPO
                         ,gv_msg_xxpo10007      -- ���b�Z�[�W:APP-XXPO-10007 �f�[�^�o�^�G���[
                         ,gv_tkn_info_name      -- �g�[�N��
                         ,gv_tkn_ic_lot_mst)    -- OPM���b�g�}�X�^
                       ,1,5000);
        RAISE global_api_expt;
      END IF;
--
    EXCEPTION
      WHEN OTHERS THEN
        -- �G���[���b�Z�[�W�擾
        lv_errmsg  := SUBSTRB(
                        xxcmn_common_pkg.get_msg(
                          gv_xxpo               -- ���W���[��������:XXPO
                         ,gv_msg_xxpo10007      -- ���b�Z�[�W:APP-XXPO-10007 �f�[�^�o�^�G���[
                         ,gv_tkn_info_name      -- �g�[�N��
                         ,gv_tkn_ic_lot_mst)    -- OPM���b�g�}�X�^
                       ,1,5000);
        lv_errbuf := SQLERRM;
        RAISE global_api_expt;
    END;
--
    -- ���b�gID�擾
    gt_lot_id := lr_lot_out.lot_id;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END ins_ic_lot_mst;
--
  /**********************************************************************************
   * Procedure Name   : ins_vendor_suppry_txns
   * Description      : �O���o��������(�A�h�I��)�o�^����(B-6)
   ***********************************************************************************/
  PROCEDURE ins_vendor_suppry_txns(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_vendor_suppry_txns'; -- �v���O������
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
    lr_vendor_supply_txns   xxpo_vendor_supply_txns%ROWTYPE;
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
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ===========================
    -- ������
    -- ===========================
    lr_vendor_supply_txns := NULL;
--
    -- ===========================
    -- �O���o�����ǉ�����
    -- ===========================
    BEGIN
      -- ���R�[�h�ɒl���Z�b�g
      SELECT xxpo_vendor_supply_txns_s1.NEXTVAL
      INTO   gt_txns_id                                                                   -- ����ID
      FROM   DUAL;
      lr_vendor_supply_txns.txns_id                := gt_txns_id;                         -- ����ID
      lr_vendor_supply_txns.txns_type              := gr_main_data.product_result_type;   -- �����^�C�v
      lr_vendor_supply_txns.manufactured_date      := gr_main_data.manufactured_date;     -- ���Y��
      lr_vendor_supply_txns.vendor_id              := gr_main_data.vendor_id;             -- �����ID
      lr_vendor_supply_txns.vendor_code            := gr_main_data.vendor_code;           -- �����R�[�h
      lr_vendor_supply_txns.factory_id             := gr_main_data.factory_id;            -- �H��ID
      lr_vendor_supply_txns.factory_code           := gr_main_data.factory_code;          -- �H��R�[�h
      lr_vendor_supply_txns.location_id            := gt_location_id;                     -- �[����ID
      lr_vendor_supply_txns.location_code          := gr_main_data.location_code;         -- �[����R�[�h
      lr_vendor_supply_txns.item_id                := gr_main_data.item_id;               -- �i��ID
      lr_vendor_supply_txns.item_code              := gr_main_data.item_code;             -- �i�ڃR�[�h
      lr_vendor_supply_txns.lot_id                 := gt_lot_id;                          -- ���b�gID
      lr_vendor_supply_txns.lot_number             := gt_lot_no;                          -- ���b�gNo
      lr_vendor_supply_txns.producted_date         := gr_main_data.producted_date;        -- ������
      lr_vendor_supply_txns.koyu_code              := gr_main_data.koyu_code;             -- �ŗL�L��
      lr_vendor_supply_txns.producted_quantity     := gr_main_data.producted_quantity;    -- �o��������
      lr_vendor_supply_txns.conversion_factor      := gr_main_data.conversion_factor;     -- ���Z����
      lr_vendor_supply_txns.quantity               := gr_main_data.producted_quantity * 
                                                      gr_main_data.conversion_factor;     -- ����
      lr_vendor_supply_txns.uom                    := gr_main_data.uom;                   -- �P�ʃR�[�h
      lr_vendor_supply_txns.producted_uom          := gr_main_data.producted_uom;         -- �o�����P�ʃR�[�h
      -- �����^�C�v��1:�����݌ɂ̏ꍇ
      IF (gv_product_result_type_inv = gr_main_data.product_result_type) THEN
        lr_vendor_supply_txns.order_created_flg    := gv_flg_n;                           -- �����쐬�t���O N
        lr_vendor_supply_txns.order_created_date   := NULL;                               -- �����쐬��
  --
      -- �����^�C�v��2:�����d���̏ꍇ
      ELSIF (gv_product_result_type_po = gr_main_data.product_result_type) THEN
        lr_vendor_supply_txns.order_created_flg    := gv_flg_y;                           -- �����쐬�t���O Y
        lr_vendor_supply_txns.order_created_date   := SYSDATE;                            -- �����쐬��
      END IF;
      lr_vendor_supply_txns.description            := gr_main_data.description;           -- �E�v
      lr_vendor_supply_txns.created_by             := FND_GLOBAL.USER_ID;                 -- �쐬��
      lr_vendor_supply_txns.creation_date          := SYSDATE;                            -- �쐬��
      lr_vendor_supply_txns.last_updated_by        := FND_GLOBAL.USER_ID;                 -- �ŏI�X�V��
      lr_vendor_supply_txns.last_update_date       := SYSDATE;                            -- �ŏI�X�V��
      lr_vendor_supply_txns.last_update_login      := FND_GLOBAL.LOGIN_ID;                -- �ŏI�X�V���O�C��
      lr_vendor_supply_txns.request_id             := FND_GLOBAL.CONC_REQUEST_ID;         -- �v��ID
      lr_vendor_supply_txns.program_application_id := FND_GLOBAL.PROG_APPL_ID;            -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
      lr_vendor_supply_txns.program_id             := FND_GLOBAL.CONC_PROGRAM_ID;         -- �R���J�����g�E�v���O����ID
      lr_vendor_supply_txns.program_update_date    := SYSDATE;                            -- �v���O�����X�V��
--
      -- �ǉ�����
      INSERT INTO xxpo_vendor_supply_txns VALUES lr_vendor_supply_txns;
--
    EXCEPTION
      WHEN OTHERS THEN
        -- �G���[���b�Z�[�W�擾
        lv_errmsg  := SUBSTRB(
                        xxcmn_common_pkg.get_msg(
                          gv_xxpo                 -- ���W���[��������:XXPO
                         ,gv_msg_xxpo10007        -- ���b�Z�[�W:APP-XXPO-10007 �f�[�^�o�^�G���[
                         ,gv_tkn_info_name        -- �g�[�N��
                         ,gv_tkn_vendor_sply_txns)-- �O���o�������уA�h�I��
                       ,1,5000);
        lv_errbuf := SQLERRM;
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
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END ins_vendor_suppry_txns;
--
  /**********************************************************************************
   * Procedure Name   : ins_inventory_data
   * Description      : �����݌Ɍv�㏈��(B-7)
   ***********************************************************************************/
  PROCEDURE ins_inventory_data(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_inventory_data'; -- �v���O������
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
    ln_api_version_number_adj  CONSTANT NUMBER := 1.0; -- ���b�g�����쐬API�p�o�[�W�����ԍ�
    ln_api_version_number_inv  CONSTANT NUMBER := 3.0; -- �����݌Ƀg�����U�N�V�����쐬API�p�o�[�W�����ԍ�
--
    -- *** ���[�J���ϐ� ***
    lr_lc_adjustment_header  GMF_LOTCOSTADJUSTMENT_PUB.LC_ADJUSTMENT_HEADER_REC_TYPE; -- ���b�g�����w�b�_
    lr_lc_adjustment_dtls    GMF_LOTCOSTADJUSTMENT_PUB.LC_ADJUSTMENT_DTLS_TBL_TYPE;   -- ���b�g��������
    lb_setup_return_sts      BOOLEAN;
    ln_msg_count             NUMBER;
--
    lr_qty_in                GMIGAPI.qty_rec_typ; -- �����݌Ƀg�����U�N�V����
    ic_jrnl_out              ic_jrnl_mst%ROWTYPE;
    ic_adjs_jnl_out1         ic_adjs_jnl%ROWTYPE;
    ic_adjs_jnl_out2         ic_adjs_jnl%ROWTYPE;
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
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ===========================
    -- ������
    -- ===========================
    lr_lc_adjustment_header  := NULL; -- ���b�g�����w�b�_
    lr_lc_adjustment_dtls(0) := NULL; -- ���b�g��������
    lr_qty_in                := NULL; -- �����݌Ƀg�����U�N�V����
    ic_jrnl_out              := NULL;
    ic_adjs_jnl_out1         := NULL;
    ic_adjs_jnl_out2         := NULL;
    FND_MSG_PUB.INITIALIZE(); -- API���b�Z�[�W
--
    -- ===========================
    -- GMI�nAPI�O���[�o���萔�̐ݒ�
    -- ===========================
    lb_setup_return_sts  :=  GMIGUTL.SETUP(FND_GLOBAL.USER_NAME);
--
    -- ===========================
    -- ���b�g�����쐬API���s
    -- ===========================
    BEGIN
      -- ���b�g�����w�b�_���R�[�h�ɒl���Z�b�g
      lr_lc_adjustment_header.co_code             := gt_co_code;             -- ��ЃR�[�h
      lr_lc_adjustment_header.whse_code           := gt_whse_code;           -- �q�ɃR�[�h
      lr_lc_adjustment_header.cost_mthd_code      := gv_cost_mthd_code;      -- ���b�g�������@
      lr_lc_adjustment_header.item_id             := gr_main_data.item_id;   -- �i��ID
      lr_lc_adjustment_header.lot_id              := gt_lot_id;              -- ���b�gID
      lr_lc_adjustment_header.reason_code         := gv_ctpty_cost_rsn;      -- ���R�R�[�h
      lr_lc_adjustment_header.adjustment_date     := SYSDATE;                -- ������
      lr_lc_adjustment_header.delete_mark         := 0;                      -- �폜�}�[�N
      lr_lc_adjustment_header.user_name           := FND_GLOBAL.USER_NAME;   -- ���[�U�[��
--
      -- ���b�g�������׃��R�[�h�ɒl���Z�b�g
      lr_lc_adjustment_dtls(0).cost_cmpntcls_code := gv_cost_cmpntcls_code;  -- �R���|�[�l���g�敪
      lr_lc_adjustment_dtls(0).cost_analysis_code := gv_cost_analysis_code;  -- ���͋敪
      lr_lc_adjustment_dtls(0).adjustment_cost    := 0;                      -- ����
--
      -- API���s
      GMF_LOTCOSTADJUSTMENT_PUB.CREATE_LOTCOST_ADJUSTMENT(
         p_api_version      => ln_api_version_number_adj -- IN:API�̃o�[�W�����ԍ�
        ,p_init_msg_list    => FND_API.G_FALSE           -- IN:���b�Z�[�W�������t���O
        ,p_commit           => FND_API.G_FALSE           -- IN:�����m��t���O
        ,x_return_status    => lv_retcode                -- OUT:�I���X�e�[�^�X( 'S'-����I��, 'E'-��O����, 'U'-�V�X�e����O����)
        ,x_msg_count        => ln_msg_count              -- OUT:���b�Z�[�W�E�X�^�b�N��
        ,x_msg_data         => lv_errmsg                 -- OUT:���b�Z�[�W
        ,p_header_rec       => lr_lc_adjustment_header   -- IN OUT:�o�^���郍�b�g�����w�b�_�����w��A�ԋp
        ,p_dtl_tbl          => lr_lc_adjustment_dtls);   -- IN OUT:�o�^���郍�b�g�������׏����w��A�ԋp
--
      -- �߂�l������ȊO�̏ꍇ�A�G���[
      IF (lv_retcode <> gv_api_ret_cd_normal) THEN
        -- �G���[���O�o��
        xxcmn_common_pkg.put_api_log(
          ov_errbuf     => lv_errbuf     -- �G���[�E���b�Z�[�W
         ,ov_retcode    => lv_retcode    -- ���^�[���E�R�[�h
         ,ov_errmsg     => lv_errmsg);   -- ���[�U�[�E�G���[�E���b�Z�[�W
--
        -- �G���[���b�Z�[�W�擾
        lv_errmsg  := SUBSTRB(
                        xxcmn_common_pkg.get_msg(
                          gv_xxpo               -- ���W���[��������:XXPO
                         ,gv_msg_xxpo10007      -- ���b�Z�[�W:APP-XXPO-10007 �f�[�^�o�^�G���[
                         ,gv_tkn_info_name      -- �g�[�N��
                         ,gv_tkn_lc_adjustment) -- ���b�g����
                       ,1,5000);
        RAISE global_api_expt;
      END IF;
--
    EXCEPTION
      WHEN OTHERS THEN
        -- �G���[���b�Z�[�W�擾
        lv_errmsg  := SUBSTRB(
                        xxcmn_common_pkg.get_msg(
                          gv_xxpo               -- ���W���[��������:XXPO
                         ,gv_msg_xxpo10007      -- ���b�Z�[�W:APP-XXPO-10007 �f�[�^�o�^�G���[
                         ,gv_tkn_info_name      -- �g�[�N��
                         ,gv_tkn_lc_adjustment) -- ���b�g����
                       ,1,5000);
        lv_errbuf := SQLERRM;
        RAISE global_api_expt;
    END;
--
    -- =====================================
    -- �����݌Ƀg�����U�N�V�����쐬API���s
    -- =====================================
    BEGIN
      -- �����݌Ƀg�����U�N�V�������R�[�h�ɒl���Z�b�g
      lr_qty_in.trans_type     := gv_trans_type_sok;                  -- ����^�C�v 2:��������
      lr_qty_in.item_no        := gr_main_data.item_code;             -- �i��
      lr_qty_in.from_whse_code := gt_whse_code;                       -- �q�ɃR�[�h
      lr_qty_in.item_um        := gr_main_data.uom;                   -- �P��
      lr_qty_in.lot_no         := gt_lot_no;                          -- ���b�g
      lr_qty_in.from_location  := gr_main_data.location_code;         -- �[����R�[�h(�ۊǏꏊ�R�[�h)
      lr_qty_in.trans_qty      := gr_main_data.producted_quantity * 
                                  gr_main_data.conversion_factor;     -- ����
      lr_qty_in.co_code        := gt_co_code;                         -- ��ЃR�[�h
      lr_qty_in.orgn_code      := gt_orgn_code;                       -- �g�D�R�[�h
      lr_qty_in.trans_date     := gr_main_data.manufactured_date;     -- �����
      lr_qty_in.reason_code    := gv_ctpty_inv_rcv_rsn;               -- ���R�R�[�h
      lr_qty_in.user_name      := FND_GLOBAL.USER_NAME;               -- ���[�U�[��
      lr_qty_in.attribute1     := TO_CHAR(gt_txns_id);                -- �\�[�X����ID
-- 2008/12/26 H.Itou Add Start ����(�����݌Ɏd��)�Ƌ�ʂ��邽�߁A�O���o�����̏ꍇ��DFF4��Y�𗧂Ă�B
      lr_qty_in.attribute4     := gv_flg_y;                           -- 
-- 2008/12/26 H.Itou Add End
--
      -- API���s
      GMIPAPI.INVENTORY_POSTING(
         p_api_version      => ln_api_version_number_inv   -- IN:API�̃o�[�W�����ԍ�
        ,p_init_msg_list    => FND_API.G_FALSE             -- IN:���b�Z�[�W�������t���O
        ,p_commit           => FND_API.G_FALSE             -- IN:�����m��t���O
        ,p_validation_level => FND_API.G_VALID_LEVEL_FULL  -- IN:���؃��x��
        ,p_qty_rec          => lr_qty_in                   -- IN:��������݌ɐ��ʏ����w��
        ,x_ic_jrnl_mst_row  => ic_jrnl_out                 -- OUT:�������ꂽ�݌ɐ��ʏ�񂪕ԋp
        ,x_ic_adjs_jnl_row1 => ic_adjs_jnl_out1            -- OUT:�������ꂽ�݌ɐ��ʏ�񂪕ԋp
        ,x_ic_adjs_jnl_row2 => ic_adjs_jnl_out2            -- OUT:
        ,x_return_status    => lv_retcode                  -- OUT:�I���X�e�[�^�X( 'S'-����I��, 'E'-��O����, 'U'-�V�X�e����O����)
        ,x_msg_count        => ln_msg_count                -- OUT:���b�Z�[�W�E�X�^�b�N��
        ,x_msg_data         => lv_errmsg);                 -- OUT:���b�Z�[�W
--
      -- �߂�l������ȊO�̏ꍇ�A�G���[
      IF (lv_retcode <> gv_api_ret_cd_normal) THEN
        -- �G���[���O�o��
        xxcmn_common_pkg.put_api_log(
          ov_errbuf     => lv_errbuf     -- �G���[�E���b�Z�[�W
         ,ov_retcode    => lv_retcode    -- ���^�[���E�R�[�h
         ,ov_errmsg     => lv_errmsg);   -- ���[�U�[�E�G���[�E���b�Z�[�W
--
        -- �G���[���b�Z�[�W�擾
        lv_errmsg  := SUBSTRB(
                        xxcmn_common_pkg.get_msg(
                          gv_xxpo               -- ���W���[��������:XXPO
                         ,gv_msg_xxpo10007      -- ���b�Z�[�W:APP-XXPO-10007 �f�[�^�o�^�G���[
                         ,gv_tkn_info_name      -- �g�[�N��
                         ,gv_tkn_ic_tran_cmp)   -- �݌Ɏ��
                       ,1,5000);
        RAISE global_api_expt;
      END IF;
--
    EXCEPTION
      WHEN OTHERS THEN
        -- �G���[���b�Z�[�W�擾
        lv_errmsg  := SUBSTRB(
                        xxcmn_common_pkg.get_msg(
                          gv_xxpo               -- ���W���[��������:XXPO
                         ,gv_msg_xxpo10007      -- ���b�Z�[�W:APP-XXPO-10007 �f�[�^�o�^�G���[
                         ,gv_tkn_info_name      -- �g�[�N��
                         ,gv_tkn_ic_tran_cmp)   -- �݌Ɏ��
                       ,1,5000);
        lv_errbuf := SQLERRM;
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
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END ins_inventory_data;
--
  /**********************************************************************************
   * Procedure Name   : ins_po_data
   * Description      : ���������쐬����(B-8)
   ***********************************************************************************/
  PROCEDURE ins_po_data(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_po_data'; -- �v���O������
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
    lr_xxpo_headers_all      xxpo_headers_all%ROWTYPE;           -- �����w�b�_(�A�h�I��)
    lr_po_headers_if         po_headers_interface%ROWTYPE;       -- �����w�b�_�I�[�v���C���^�t�F�[�X
    lr_po_lines_if           po_lines_interface%ROWTYPE;         -- �������׃I�[�v���C���^�t�F�[�X
    lr_po_distributions_if   po_distributions_interface%ROWTYPE; -- �������׃I�[�v���C���^�t�F�[�X
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
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ===========================
    -- ������
    -- ===========================
    lr_xxpo_headers_all    := NULL;
    lr_po_headers_if       := NULL;
    lr_po_lines_if         := NULL;
    lr_po_distributions_if := NULL;
--
    -- ===========================
    -- �����w�b�_(�A�h�I��)�ǉ�
    -- ===========================
    BEGIN
      -- ���R�[�h�ɒl���Z�b�g
      SELECT xxpo_headers_all_s1.NEXTVAL
      INTO   lr_xxpo_headers_all.xxpo_header_id                                     -- �����w�b�_(�A�h�I��ID)
      FROM   DUAL;
--
      SELECT papf.employee_number  employee_number
      INTO   lr_xxpo_headers_all.order_created_by_code                              -- �쐬�҃R�[�h
      FROM   per_all_people_f papf
      WHERE  papf.person_id  = TO_NUMBER(gv_purchase_emp_id)
      AND    papf.effective_start_date <= TRUNC(SYSDATE)
      AND    papf.effective_end_date   >= TRUNC(SYSDATE);
--
      lr_xxpo_headers_all.po_header_number       := gt_po_number;                   -- �����ԍ�
      lr_xxpo_headers_all.order_created_date     := gr_main_data.manufactured_date; -- �쐬��
      lr_xxpo_headers_all.order_approved_flg     := gv_flg_n;                       -- ���������t���O:N
      lr_xxpo_headers_all.purchase_approved_flg  := gv_flg_n;                       -- �d�������t���O:N
      lr_xxpo_headers_all.created_by             := FND_GLOBAL.USER_ID;             -- �쐬��
      lr_xxpo_headers_all.creation_date          := SYSDATE;                        -- �쐬��
      lr_xxpo_headers_all.last_updated_by        := FND_GLOBAL.USER_ID;             -- �ŏI�X�V��
      lr_xxpo_headers_all.last_update_date       := SYSDATE;                        -- �ŏI�X�V��
      lr_xxpo_headers_all.last_update_login      := FND_GLOBAL.LOGIN_ID;            -- �ŏI�X�V���O�C��
      lr_xxpo_headers_all.request_id             := FND_GLOBAL.CONC_REQUEST_ID;     -- �v��ID
      lr_xxpo_headers_all.program_application_id := FND_GLOBAL.PROG_APPL_ID;        -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
      lr_xxpo_headers_all.program_id             := FND_GLOBAL.CONC_PROGRAM_ID;     -- �R���J�����g�E�v���O����ID
      lr_xxpo_headers_all.program_update_date    := SYSDATE;                        -- �v���O�����X�V��
--
      -- �ǉ�����
      INSERT INTO xxpo_headers_all VALUES lr_xxpo_headers_all;
--
    EXCEPTION
      WHEN OTHERS THEN
        -- �G���[���b�Z�[�W�擾
        lv_errmsg  := SUBSTRB(
                        xxcmn_common_pkg.get_msg(
                          gv_xxpo                 -- ���W���[��������:XXPO
                         ,gv_msg_xxpo10007        -- ���b�Z�[�W:APP-XXPO-10007 �f�[�^�o�^�G���[
                         ,gv_tkn_info_name        -- �g�[�N��
                         ,gv_tkn_xxpo_headers_all)-- �����w�b�_(�A�h�I��)
                       ,1,5000);
        lv_errbuf := SQLERRM;
        RAISE global_api_expt;
    END;
--
    -- ======================================
    -- �����w�b�_�I�[�v���C���^�t�F�[�X�ǉ�
    -- ======================================
    BEGIN
      -- �����w�b�_�I�[�v���C���^�t�F�[�X
      SELECT po_headers_interface_s.NEXTVAL
      INTO   lr_po_headers_if.interface_header_id                                  -- IF�w�b�_ID
      FROM   DUAL;
      lr_po_headers_if.batch_id                 := TO_CHAR(lr_po_headers_if.interface_header_id) ||
                                                   gt_po_number;                   -- �o�b�`ID 
      lr_po_headers_if.process_code             := 'PENDING';                      -- �����R�[�h
      lr_po_headers_if.action                   := 'ORIGINAL';                     -- ����
      lr_po_headers_if.org_id                   := gv_org_id;                      -- �c�ƒP��ID
      lr_po_headers_if.document_type_code       := 'STANDARD';                     -- �����^�C�v
      lr_po_headers_if.document_num             := gt_po_number;                   -- �����ԍ�
      lr_po_headers_if.agent_id                 := gv_purchase_emp_id;             -- �w���S����ID
      lr_po_headers_if.vendor_id                := gr_main_data.vendor_id;         -- �d����ID
      lr_po_headers_if.vendor_site_id           := gr_main_data.factory_id;        -- �d����T�C�gID
      lr_po_headers_if.ship_to_location_id      := gt_ship_to_location_id;         -- �[���掖�Ə�ID
      lr_po_headers_if.bill_to_location_id      := gv_bill_to_location_id;         -- �����掖�Ə�ID
      lr_po_headers_if.approval_status          := 'APPROVED';                     -- ���F�X�e�[�^�X
      lr_po_headers_if.attribute1               := gv_po_status_m;                 -- �X�e�[�^�X 20:�쐬��
      lr_po_headers_if.attribute2               := gv_flg_n;                       -- �d���揳���v�t���O N
      lr_po_headers_if.attribute4               := TO_CHAR(gr_main_data.manufactured_date, gv_yyyymmdd);  -- �[����
      lr_po_headers_if.attribute5               := gr_main_data.location_code;     -- �[����R�[�h
      lr_po_headers_if.attribute6               := gv_direct_flg;                  -- �����敪 1:�ʏ�
      lr_po_headers_if.attribute10              := gr_main_data.department;        -- �����R�[�h
      lr_po_headers_if.attribute11              := gv_po_kbn;                      -- �����敪 1:�V�K
      lr_po_headers_if.load_sourcing_rules_flag := gv_flg_n;                       -- �\�[�X���[���쐬�t���O N
      lr_po_headers_if.creation_date            := SYSDATE;                        -- �쐬��
      lr_po_headers_if.last_updated_by          := FND_GLOBAL.USER_ID;             -- �ŏI�X�V��
      lr_po_headers_if.last_update_date         := SYSDATE;                        -- �ŏI�X�V��
      lr_po_headers_if.last_update_login        := FND_GLOBAL.LOGIN_ID;            -- �ŏI�X�V���O�C��
      lr_po_headers_if.request_id               := FND_GLOBAL.CONC_REQUEST_ID;     -- �v��ID
      lr_po_headers_if.program_application_id   := FND_GLOBAL.PROG_APPL_ID;        -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
      lr_po_headers_if.program_id               := FND_GLOBAL.CONC_PROGRAM_ID;     -- �R���J�����g�E�v���O����ID
      lr_po_headers_if.program_update_date      := SYSDATE;                        -- �v���O�����X�V��
--
      -- �ǉ�����
      INSERT INTO po_headers_interface VALUES lr_po_headers_if;
--
    EXCEPTION
      WHEN OTHERS THEN
        -- �G���[���b�Z�[�W�擾
        lv_errmsg  := SUBSTRB(
                        xxcmn_common_pkg.get_msg(
                          gv_xxpo                 -- ���W���[��������:XXPO
                         ,gv_msg_xxpo10007        -- ���b�Z�[�W:APP-XXPO-10007 �f�[�^�o�^�G���[
                         ,gv_tkn_info_name        -- �g�[�N��
                         ,gv_tkn_po_headers_if)   -- �����w�b�_�I�[�v���C���^�t�F�[�X
                       ,1,5000);
        lv_errbuf := SQLERRM;
        RAISE global_api_expt;
    END;
--
    -- ======================================
    -- �������׃I�[�v���C���^�t�F�[�X�ǉ�
    -- ======================================
    BEGIN
      -- ���R�[�h�ɒl���Z�b�g
      SELECT po_lines_interface_s.NEXTVAL
      INTO   lr_po_lines_if.interface_line_id                                         -- IF����ID
      FROM   DUAL;
      lr_po_lines_if.interface_header_id     := lr_po_headers_if.interface_header_id; -- IF�w�b�_ID
      lr_po_lines_if.line_num                := 1;                                    -- ���הԍ�
      lr_po_lines_if.shipment_num            := 1;                                    -- �[���ԍ�
      lr_po_lines_if.line_type_id            := gv_po_line_type_id;                   -- ���׃^�C�vID
      lr_po_lines_if.item_id                 := gr_main_data.inventory_item_id;       -- �i��ID
      lr_po_lines_if.uom_code                := gr_main_data.uom;                     -- �P�ʃR�[�h
      lr_po_lines_if.quantity                := gr_main_data.producted_quantity *
                                                gr_main_data.conversion_factor;       -- �o�������ʁ~ ���Z����
      lr_po_lines_if.unit_price              := gt_unit_price;                        -- ���i
      lr_po_lines_if.promised_date           := gr_main_data.manufactured_date;       -- �[����
      lr_po_lines_if.line_attribute1         := gt_lot_no;                            -- ���b�g�ԍ�
      lr_po_lines_if.line_attribute2         := gr_main_data.factory_code;            -- �H��R�[�h
      lr_po_lines_if.line_attribute3         := gv_futai_code_0;                      -- �t�уR�[�h
      lr_po_lines_if.line_attribute4         := gr_main_data.stock_qty;               -- �݌ɓ���
      lr_po_lines_if.line_attribute8         := gt_unit_price;                        -- �d���P��
      lr_po_lines_if.line_attribute10        := gr_main_data.producted_uom;           -- �����P��
      lr_po_lines_if.line_attribute11        := gr_main_data.producted_quantity;      -- �o��������
      lr_po_lines_if.line_attribute13        := gv_flg_n;                             -- ���ʊm��t���O
      lr_po_lines_if.line_attribute14        := gv_flg_n;                             -- ���z�m��t���O
      lr_po_lines_if.shipment_attribute3     := gv_kosen_kbn_n;                       -- ���K�敪
      lr_po_lines_if.shipment_attribute6     := gv_fuka_kbn_n;                        -- ���ۋ��敪
      lr_po_lines_if.ship_to_organization_id := gt_organization_id;                   -- �݌ɑg�DID(����)
      lr_po_lines_if.creation_date           := SYSDATE;                              -- �쐬��
      lr_po_lines_if.last_updated_by         := FND_GLOBAL.USER_ID;                   -- �ŏI�X�V��
      lr_po_lines_if.last_update_date        := SYSDATE;                              -- �ŏI�X�V��
      lr_po_lines_if.last_update_login       := FND_GLOBAL.LOGIN_ID;                  -- �ŏI�X�V���O�C��
      lr_po_lines_if.request_id              := FND_GLOBAL.CONC_REQUEST_ID;           -- �v��ID
      lr_po_lines_if.program_application_id  := FND_GLOBAL.PROG_APPL_ID;              -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
      lr_po_lines_if.program_id              := FND_GLOBAL.CONC_PROGRAM_ID;           -- �R���J�����g�E�v���O����ID
      lr_po_lines_if.program_update_date     := SYSDATE;                              -- �v���O�����X�V��
--
      -- �ǉ�����
      INSERT INTO po_lines_interface VALUES lr_po_lines_if;
--
    EXCEPTION
      WHEN OTHERS THEN
        -- �G���[���b�Z�[�W�擾
        lv_errmsg  := SUBSTRB(
                        xxcmn_common_pkg.get_msg(
                          gv_xxpo                 -- ���W���[��������:XXPO
                         ,gv_msg_xxpo10007        -- ���b�Z�[�W:APP-XXPO-10007 �f�[�^�o�^�G���[
                         ,gv_tkn_info_name        -- �g�[�N��
                         ,gv_tkn_po_lines_if)     -- �������׃I�[�v���C���^�t�F�[�X
                       ,1,5000);
        lv_errbuf := SQLERRM;
        RAISE global_api_expt;
    END;
--
    -- ======================================
    -- �������׃I�[�v���C���^�t�F�[�X�ǉ�
    -- ======================================
    BEGIN
      -- ���R�[�h�ɒl���Z�b�g
      SELECT po_distributions_interface_s.NEXTVAL
      INTO   lr_po_distributions_if.interface_distribution_id                                   -- IF��������ID
      FROM   DUAL;
      lr_po_distributions_if.interface_header_id       := lr_po_headers_if.interface_header_id; -- IF�w�b�_ID
      lr_po_distributions_if.interface_line_id         := lr_po_lines_if.interface_line_id;     -- IF����ID
      lr_po_distributions_if.distribution_num          := 1;                                    -- ���הԍ�
      lr_po_distributions_if.quantity_ordered          := gr_main_data.producted_quantity *
                                                          gr_main_data.conversion_factor;       -- �o�������ʁ~ ���Z����
      lr_po_distributions_if.recovery_rate             := 100;
      lr_po_distributions_if.creation_date             := SYSDATE;                              -- �쐬��
      lr_po_distributions_if.last_updated_by           := FND_GLOBAL.USER_ID;                   -- �ŏI�X�V��
      lr_po_distributions_if.last_update_date          := SYSDATE;                              -- �ŏI�X�V��
      lr_po_distributions_if.last_update_login         := FND_GLOBAL.LOGIN_ID;                  -- �ŏI�X�V���O�C��
      lr_po_distributions_if.request_id                := FND_GLOBAL.CONC_REQUEST_ID;           -- �v��ID
      lr_po_distributions_if.program_application_id    := FND_GLOBAL.PROG_APPL_ID;              -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
      lr_po_distributions_if.program_id                := FND_GLOBAL.CONC_PROGRAM_ID;           -- �R���J�����g�E�v���O����ID
      lr_po_distributions_if.program_update_date       := SYSDATE;                              -- �v���O�����X�V��
--
      -- �ǉ�����
      INSERT INTO po_distributions_interface VALUES lr_po_distributions_if;
--
    EXCEPTION
      WHEN OTHERS THEN
        -- �G���[���b�Z�[�W�擾
        lv_errmsg  := SUBSTRB(
                        xxcmn_common_pkg.get_msg(
                          gv_xxpo                     -- ���W���[��������:XXPO
                         ,gv_msg_xxpo10007            -- ���b�Z�[�W:APP-XXPO-10007 �f�[�^�o�^�G���[
                         ,gv_tkn_info_name            -- �g�[�N��
                         ,gv_tkn_po_distributions_if) -- �������׃I�[�v���C���^�t�F�[�X
                       ,1,5000);
        lv_errbuf := SQLERRM;
        RAISE global_api_expt;
    END;
--
    -- �o�b�`ID���Z�b�g
    gt_batch_id := lr_po_headers_if.batch_id;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END ins_po_data;
--
  /**********************************************************************************
   * Procedure Name   : ins_qt_inspection
   * Description      : �i�������˗����쐬����(B-9)
   ***********************************************************************************/
  PROCEDURE ins_qt_inspection(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_qt_inspection'; -- �v���O������
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
    lt_division            xxwip_qt_inspection.division%TYPE;         -- �敪
    lt_qty                 xxwip_qt_inspection.qty%TYPE;              -- ����
    lt_prod_dely_date      xxwip_qt_inspection.prod_dely_date%TYPE;   -- �[����
    lt_vendor_line         xxwip_qt_inspection.vendor_line%TYPE;      -- �d����R�[�h
    lt_qt_inspect_req_no   xxwip_qt_inspection.qt_inspect_req_no%TYPE;-- �����˗�No
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
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ===========================
    -- ���R�[�h�ɒl���Z�b�g
    -- ===========================
     -- �����^�C�v��1:�����݌ɂ̏ꍇ
    IF (gv_product_result_type_inv = gr_main_data.product_result_type) THEN
      lt_division       := gt_division_spl; -- �敪 4:�O���o����
-- 2009/03/13 H.Itou Mod Start �{�ԏ�Q#32 �O���o���������ʂ��p�����[�^�œn���悤�ɕύX
--      lt_qty            := NULL;            -- ���� NULL
      lt_qty            := gr_main_data.producted_quantity *
                           gr_main_data.conversion_factor;     -- ���� �o�������ʁ~ ���Z����
-- 2009/03/13 H.Itou Mod End
      lt_prod_dely_date := NULL;            -- ���Y�� NULL
      lt_vendor_line    := NULL;            -- �d����R�[�h NULL
--
    -- �����^�C�v��2:�����d���̏ꍇ
    ELSIF (gv_product_result_type_po = gr_main_data.product_result_type) THEN
      lt_division       := gt_division_po;                     -- �敪 2:����
      lt_qty            := gr_main_data.producted_quantity *
                           gr_main_data.conversion_factor;     -- ���� �o�������ʁ~ ���Z����
      lt_prod_dely_date := gr_main_data.manufactured_date;     -- �[���� ���Y��
      lt_vendor_line    := gr_main_data.vendor_code;           -- �d����R�[�h �����R�[�h
    END IF;
--
    -- ===========================
    -- �i�������˗����쐬API���s
    -- ===========================
    xxwip_common_pkg.make_qt_inspection(
      it_division          => lt_division           -- IN  �敪         �K�{�i1:���Y 2:���� 3:���b�g��� 4:�O���o���� 5:�r�������j
     ,iv_disposal_div      => gv_disposal_div_ins   -- IN  �����敪     �K�{�i1:�ǉ� 2:�X�V 3:�폜�j
     ,it_lot_id            => gt_lot_id             -- IN  ���b�gID     �K�{
     ,it_item_id           => gr_main_data.item_id  -- IN  �i��ID       �K�{
     ,iv_qt_object         => NULL                  -- IN  �Ώې�       �敪:5�̂ݕK�{�i1:�r���i�� 2:���Y���P 3:���Y���Q 4:���Y���R�j
     ,it_batch_id          => NULL                  -- IN  ���Y�o�b�`ID �����敪3�ȊO���敪:1�̂ݕK�{
     ,it_batch_po_id       => NULL                  -- IN  ���הԍ�     ���NULL
     ,it_qty               => lt_qty                -- IN  ����         �����敪3�ȊO���敪:2�̂ݕK�{
     ,it_prod_dely_date    => lt_prod_dely_date     -- IN  �[����       �����敪3�ȊO���敪:2�̂ݕK�{
     ,it_vendor_line       => lt_vendor_line        -- IN  �d����R�[�h �����敪3�ȊO���敪:2�̂ݕK�{
     ,it_qt_inspect_req_no => NULL                  -- IN  �����˗�No   �����敪:2�A3�̂ݕK�{
     ,ot_qt_inspect_req_no => lt_qt_inspect_req_no  -- OUT �����˗�No
     ,ov_errbuf            => lv_errbuf             -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode           => lv_retcode            -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg            => lv_errmsg);           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    -- �߂�l���G���[�I���̏ꍇ�A�G���[
    IF (lv_retcode = gv_status_error) THEN
      lv_errmsg  := SUBSTRB(
                      xxcmn_common_pkg.get_msg(
                        gv_xxpo                     -- ���W���[��������:XXPO
                       ,gv_msg_xxpo10007            -- ���b�Z�[�W:APP-XXPO-10007 �f�[�^�o�^�G���[
                       ,gv_tkn_info_name            -- �g�[�N��
                       ,gv_tkn_qt_inspection)       -- �i�������˗����
                     ,1,5000);
      RAISE global_api_expt;
    END IF;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END ins_qt_inspection;
--
  /**********************************************************************************
   * Procedure Name   : import_standard_po
   * Description      : �W�������C���|�[�g�̌ďo����(B-10)
   ***********************************************************************************/
  PROCEDURE import_standard_po(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'import_standard_po'; -- �v���O������
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
    ln_request_id NUMBER;
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
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ===========================
    -- �W�������C���|�[�g�̔��s
    -- ===========================
    -- �W�������C���|�[�g(�R���J�����g)�Ăяo��
    ln_request_id := FND_REQUEST.SUBMIT_REQUEST(
                       application  => 'PO'                           -- �A�v���P�[�V������
                      ,program      => 'POXPOPDOI'                    -- �v���O�����Z�k��
                      ,argument1    => NULL                           -- �w���S��ID
                      ,argument2    => 'STANDARD'                     -- �����^�C�v
                      ,argument3    => NULL                           -- �����T�u�^�C�v
                      ,argument4    => 'N'                            -- �i�ڂ̍쐬 N:�s��Ȃ�
                      ,argument5    => NULL                           -- �\�[�X�E���[���̍쐬
                      ,argument6    => 'APPROVED'                     -- ���F�X�e�[�^�X APPROVAL:���F
                      ,argument7    => NULL                           -- �����[�X�������@
                      ,argument8    => gt_batch_id                    -- �o�b�`ID = IF�w�b�_ID || �����ԍ�
                      ,argument9    => NULL                           -- �c�ƒP��
                      ,argument10   => NULL);                         -- �O���[�o���_��
--
    -- �v��ID���擾�ł��Ȃ��ꍇ�A�G���[
    IF (ln_request_id <= 0) THEN
      -- �G���[���b�Z�[�W�擾
      lv_errmsg  := SUBSTRB(
                      xxcmn_common_pkg.get_msg(
                        gv_xxpo               -- ���W���[��������:XXPO
                       ,gv_msg_xxpo10025      -- ���b�Z�[�W:APP-XXPO-10025 �R���J�����g�o�^�G���[
                       ,gv_tkn_prg_name       -- �g�[�N��
                       ,gv_tkn_conc_name)     -- �W�������C���|�[�g
                     ,1,5000);
      lv_errmsg := lv_errbuf;
      RAISE global_api_expt;
    END IF;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END import_standard_po;
--
  /**********************************************************************************
   * Procedure Name   : del_vendor_supply_txns_if
   * Description      : �f�[�^�폜����(B-11)
   ***********************************************************************************/
  PROCEDURE del_vendor_supply_txns_if(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'del_vendor_supply_txns_if'; -- �v���O������
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
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    FORALL ln_count IN 1..txns_if_id_tab.COUNT
      DELETE xxpo_vendor_supply_txns_if xvsti      -- �o�������я��C���^�t�F�[�X
      WHERE  xvsti.txns_if_id = txns_if_id_tab(ln_count);
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END del_vendor_supply_txns_if;
--
  /**********************************************************************************
   * Procedure Name   : put_dump_msg
   * Description      : �f�[�^�_���v�ꊇ�o�͏���(B-12)
   ***********************************************************************************/
  PROCEDURE put_dump_msg(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'put_dump_msg'; -- �v���O������
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
    lv_msg  VARCHAR2(5000);  -- ���b�Z�[�W
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
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ===============================
    -- �f�[�^�_���v�ꊇ�o��
    -- ===============================
    --��؂蕶����o��
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, gv_sep_msg);
--
    -- �����f�[�^�i���o���j
    lv_msg  := SUBSTRB(
                 xxcmn_common_pkg.get_msg(
                   gv_xxcmn               -- ���W���[�������́FXXCMN
                  ,gv_msg_xxcmn00005)     -- ���b�Z�[�W�FAPP-XXCMN-00005 �����f�[�^�i���o���j
                ,1,5000);
--
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, lv_msg);
--
    -- ����f�[�^�_���v
    <<normal_dump_loop>>
    FOR ln_cnt_loop IN 1 .. normal_dump_tab.COUNT
    LOOP
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, normal_dump_tab(ln_cnt_loop));
    END LOOP normal_dump_loop;
--
    --��؂蕶����o��
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, gv_sep_msg);
--
    -- �X�L�b�v�f�[�^�f�[�^�i���o���j
    lv_msg  := SUBSTRB(
                 xxcmn_common_pkg.get_msg(
                   gv_xxcmn               -- ���W���[�������́FXXCMN
                  ,gv_msg_xxcmn00007)     -- ���b�Z�[�W�FAPP-XXCMN-00007 �X�L�b�v�f�[�^�i���o���j
                ,1,5000);
--
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, lv_msg);
--
    -- �x���f�[�^�_���v
    <<warn_dump_loop>>
    FOR ln_cnt_loop IN 1 .. warn_dump_tab.COUNT
    LOOP
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, warn_dump_tab(ln_cnt_loop));
    END LOOP warn_dump_loop;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END put_dump_msg;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2,     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    iv_data_class             IN  VARCHAR2,  --   �f�[�^���(DEFAULT:�o��������)
    iv_vendor_code            IN  VARCHAR2,  --   �����
    iv_factory_code           IN  VARCHAR2,  --   �H��
    iv_manufactured_date_from IN  VARCHAR2,  --   ���Y��FROM
    iv_manufactured_date_to   IN  VARCHAR2,  --   ���Y��TO
    iv_security_kbn           IN  VARCHAR2)  --   �Z�L�����e�B�敪(DEFAULT�u1:�ɓ������[�U�[�^�C�v�v)
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
    lv_msg         VARCHAR2(5000); -- �p�����[�^�o�͗p
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
    gn_target_cnt          := 0;
    gn_normal_cnt          := 0;
    gn_error_cnt           := 0;
    gn_warn_cnt            := 0;
    gn_warn_msg_cnt        := 0;
    gn_po_cnt              := 0;
    gt_stock_value         := NULL;
    gt_unit_price          := NULL;
    gt_po_number           := NULL;
    gt_location_id         := NULL;
    gt_whse_code           := NULL;
    gt_organization_id     := NULL;
    gt_co_code             := NULL;
    gt_orgn_code           := NULL;
    gt_ship_to_location_id := NULL;
    gt_lot_no              := NULL;
    gt_lot_id              := NULL;
    gt_txns_id             := NULL;
    gt_batch_id            := NULL;
--
    -- ���̓p�����[�^�擾
    gv_in_data_class             := iv_data_class;              -- �f�[�^���
    gv_in_vendor_code            := iv_vendor_code;             -- �����
    gv_in_factory_code           := iv_factory_code;            -- �H��
    gv_in_manufactured_date_from := iv_manufactured_date_from;  -- ���Y��FROM
    gv_in_manufactured_date_to   := iv_manufactured_date_to;    -- ���Y��TO
    gv_in_security_kbn           := iv_security_kbn;            -- �Z�L�����e�B�敪
--
    -- ===============================
    -- ���̓p�����[�^�o��
    -- ===============================
    -- ��؂蕶����o��
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_sep_msg);
--
    -- ���̓p�����[�^(���o��)
    lv_msg  := SUBSTRB(
                 xxcmn_common_pkg.get_msg(
                   gv_xxpo              -- ���W���[�������́FXXPO
                  ,gv_msg_xxpo30051)    -- ���b�Z�[�W:APP-XXPO-30051 ���̓p�����[�^(���o��)
                ,1,5000);
--
    -- ���̓p�����[�^���o���o��
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_msg);
--
    -- ���̓p�����[�^(�J���}��؂�)
    lv_msg := gv_in_data_class             || gv_msg_comma || -- �f�[�^���
              gv_in_vendor_code            || gv_msg_comma || -- �����
              gv_in_factory_code           || gv_msg_comma || -- �H��
              gv_in_manufactured_date_from || gv_msg_comma || -- ���Y��FROM
              gv_in_manufactured_date_to   || gv_msg_comma || -- ���Y��TO
              gv_in_security_kbn;                             -- �Z�L�����e�B�敪
--
    -- ���̓p�����[�^�o��
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_msg);
--
    -- ��؂蕶����o��
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_sep_msg);
--
    -- =========================================
    -- ��������(B-1)
    -- =========================================
    init_proc(
      ov_errbuf     => lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode    => lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg     => lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    -- �G���[�̏ꍇ�A�����I��
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- =========================================
    -- �Ώۃf�[�^�擾����(B-2)
    -- =========================================
    OPEN main_cur;
    FETCH main_cur INTO gr_main_data;
--
    WHILE (main_cur%FOUND)
    LOOP
      -- ���������J�E���g
      gn_target_cnt := gn_target_cnt + 1 ;
      -- �o�������я��C���^�t�F�[�XID PL/SQL�\��ID���Z�b�g
      txns_if_id_tab(gn_target_cnt) := gr_main_data.txns_if_id;
--
      -- =========================================
      -- �擾�f�[�^�`�F�b�N����(B-3)
      -- =========================================
      check_data(
        ov_errbuf     => lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode    => lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg     => lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
      -- �G���[�̏ꍇ�A�o�������уC���^�t�F�[�X���폜���A�����I��
      IF (lv_retcode = gv_status_error) THEN
        RAISE proc_err_expt;
--
      -- �x���̏ꍇ
      ELSIF (lv_retcode = gv_status_warn) THEN
        -- ���^�[���E�R�[�h �x�����Z�b�g
        ov_retcode := gv_status_warn;
        -- �X�L�b�v�����J�E���g
        gn_warn_cnt   := gn_warn_cnt + 1;
--
      -- ����̏ꍇ
      ELSE
        -- =========================================
        -- �֘A�f�[�^�擾����(B-4)
        -- =========================================
        get_other_data(
          ov_errbuf     => lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
         ,ov_retcode    => lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
         ,ov_errmsg     => lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
        -- �G���[�̏ꍇ�A�o�������уC���^�t�F�[�X���폜���A�����I��
        IF (lv_retcode = gv_status_error) THEN
          RAISE proc_err_expt;
        END IF;
--
        -- =========================================
        -- ���b�g�}�X�^�o�^����(B-5)
        -- =========================================
        ins_ic_lot_mst(
          ov_errbuf     => lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
         ,ov_retcode    => lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
         ,ov_errmsg     => lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
        -- �G���[�̏ꍇ�A�o�������уC���^�t�F�[�X���폜���A�����I��
        IF (lv_retcode = gv_status_error) THEN
          RAISE proc_err_expt;
        END IF;
--
        -- =========================================
        -- �O���o����(�A�h�I��)�o�^����(B-6)
        -- =========================================
        ins_vendor_suppry_txns(
          ov_errbuf     => lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
         ,ov_retcode    => lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
         ,ov_errmsg     => lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
        -- �G���[�̏ꍇ�A�o�������уC���^�t�F�[�X���폜���A�����I��
        IF (lv_retcode = gv_status_error) THEN
          RAISE proc_err_expt;
        END IF;
--
        -- �����^�C�v��1:�����݌ɂ̏ꍇ
        IF (gv_product_result_type_inv = gr_main_data.product_result_type) THEN
          -- =========================================
          -- �����݌Ɍv�㏈��(B-7)
          -- =========================================
          ins_inventory_data(
            ov_errbuf     => lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
           ,ov_retcode    => lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
           ,ov_errmsg     => lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
          -- �G���[�̏ꍇ�A�o�������уC���^�t�F�[�X���폜���A�����I��
          IF (lv_retcode = gv_status_error) THEN
            RAISE proc_err_expt;
          END IF;
--
        -- �����^�C�v��2:�����d���̏ꍇ
        ELSIF (gv_product_result_type_po = gr_main_data.product_result_type) THEN
          -- =========================================
          -- ���������쐬����(B-8)
          -- =========================================
          ins_po_data(
            ov_errbuf     => lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
           ,ov_retcode    => lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
           ,ov_errmsg     => lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
          -- �G���[�̏ꍇ�A�o�������уC���^�t�F�[�X���폜���A�����I��
          IF (lv_retcode = gv_status_error) THEN
            RAISE proc_err_expt;
          END IF;
        END IF;
--
        -- �����L���敪��1:�L�̏ꍇ
        IF (gv_test_code_y = gr_main_data.test_code) THEN
          -- =========================================
          -- �i�������˗����쐬����(B-9)
          -- =========================================
          ins_qt_inspection(
            ov_errbuf     => lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
           ,ov_retcode    => lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
           ,ov_errmsg     => lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
          -- �G���[�̏ꍇ�A�o�������уC���^�t�F�[�X���폜���A�����I��
          IF (lv_retcode = gv_status_error) THEN
            RAISE proc_err_expt;
          END IF;
        END IF;
--
        -- �����^�C�v��2:�����d���̏ꍇ
        IF (gv_product_result_type_po = gr_main_data.product_result_type) THEN
          -- =========================================
          -- �W�������C���|�[�g�̌ďo����(B-10)
          -- =========================================
          import_standard_po(
            ov_errbuf     => lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
           ,ov_retcode    => lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
           ,ov_errmsg     => lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
          -- �G���[�̏ꍇ�A�o�������уC���^�t�F�[�X���폜���A�����I��
          IF (lv_retcode = gv_status_error) THEN
            RAISE proc_err_expt;
          END IF;
        END IF;
--
        -- ����f�[�^�_���vPL/SQL�\����
        gn_normal_cnt := gn_normal_cnt + 1;
        normal_dump_tab(gn_normal_cnt) := gr_main_data.data_dump;
--
      END IF;
--
      FETCH main_cur INTO gr_main_data;
--
    END LOOP;
--
    -- 2008/07/08 Add ��
    IF (gn_target_cnt = 0) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg('XXCMN',
                                            'APP-XXCMN-10036');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      ov_retcode := gv_status_warn;
      RETURN;
    END IF;
    -- 2008/07/08 Add ��
--
    -- =========================================
    -- �f�[�^�폜����(B-11)
    -- =========================================
    del_vendor_supply_txns_if(
      ov_errbuf     => lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode    => lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg     => lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    -- �G���[�̏ꍇ�A�����I��
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- =========================================
    -- �f�[�^�_���v�ꊇ�o�͏���(B-12)
    -- =========================================
    put_dump_msg(
      ov_errbuf     => lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode    => lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg     => lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    -- �G���[�̏ꍇ
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
  EXCEPTION
--
    -- �G���[���������A�C���^�t�F�[�X�f�[�^���폜����ꍇ
    WHEN proc_err_expt THEN
--
      ROLLBACK; -- ���[���o�b�N
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
--
      -- =========================================
      -- �f�[�^�폜����(B-11)
      -- =========================================
      del_vendor_supply_txns_if(
        ov_errbuf     => lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode    => lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg     => lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
      IF (lv_retcode <> gv_status_error) THEN
        COMMIT;
      END IF;
--
--#################################  �Œ��O������ START   ###################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
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
    errbuf        OUT VARCHAR2,      --   �G���[�E���b�Z�[�W  --# �Œ� #
    retcode       OUT VARCHAR2,      --   ���^�[���E�R�[�h    --# �Œ� #
    iv_data_class             IN  VARCHAR2,   --   �f�[�^���
    iv_vendor_code            IN  VARCHAR2,   --   �����
    iv_factory_code           IN  VARCHAR2,   --   �H��
    iv_manufactured_date_from IN  VARCHAR2,   --   ���Y��FROM
    iv_manufactured_date_to   IN  VARCHAR2,   --   ���Y��TO
    iv_security_kbn           IN  VARCHAR2    --   �Z�L�����e�B�敪
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
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-10118',
                                           'TIME', TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS'));
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
      lv_errbuf,   -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,  -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg,   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      iv_data_class,              --   �f�[�^���
      iv_vendor_code,             --   �����
      iv_factory_code,            --   �H��
      iv_manufactured_date_from,  --   ���Y��FROM
      iv_manufactured_date_to,    --   ���Y��TO
      iv_security_kbn             --   �Z�L�����e�B�敪
      );
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
    IF (retcode = gv_status_error) THEN
      ROLLBACK;
    END IF;
--
  EXCEPTION
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      retcode := gv_status_error;
  END main;
--
--###########################  �Œ蕔 END   #######################################################
--
END xxpo940002c;
/

