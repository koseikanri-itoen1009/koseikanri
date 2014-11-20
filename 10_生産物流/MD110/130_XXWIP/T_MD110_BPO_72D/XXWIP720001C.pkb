CREATE OR REPLACE PACKAGE BODY xxwip720001c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxwip720001c(body)
 * Description      : �z�������A�h�I���}�X�^�捞����
 * MD.050           : �^���v�Z�i�}�X�^�j T_MD050_BPO_720
 * MD.070           : �z�������A�h�I���}�X�^�捞����(72D) T_MD070_BPO_72D
 * Version          : 1.1
 *
 * Program List
 * --------------------------- ----------------------------------------------------------
 *  Name                       Description
 * --------------------------- ----------------------------------------------------------
 *  get_lock                    ���b�N�擾����(D-2)
 *  get_data_dump               �f�[�^�_���v�擾����(D-4)
 *  del_duplication_data        �d���f�[�^���O����(D-3)
 *  master_data_chk             �}�X�^�f�[�^�`�F�b�N����(D-6)
 *  set_ins_tab                 �o�^�pPL/SQL�\����(D-7)
 *  set_upd_tab                 �X�V�pPL/SQL�\����(D-9)
 *  get_ins_data                �o�^�f�[�^�擾����(D-5)
 *  get_upd_data                �X�V�f�[�^�擾����(D-8)
 *  ins_table_batch             �ꊇ�o�^����(D-10)
 *  upd_table_batch             �ꊇ�X�V����(D-11)
 *  update_end_date_active_all  �K�p�I�����X�V����(D-12)
 *  del_table_data              �f�[�^�폜����(D-13)
 *  put_dump_msg                �f�[�^�_���v�ꊇ�o�͏���(D-14)
 *  submain                     ���C�������v���V�[�W��
 *  main                        �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2007/12/12    1.0   H.Itou           �V�K�쐬
 *  2008/09/02    1.1   A.Shiina         �����ύX�v��#204�Ή�
 *
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
  lock_expt              EXCEPTION;        -- ���b�N�擾��O
--
  PRAGMA EXCEPTION_INIT(lock_expt, -54);   -- ���b�N�擾��O
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  gv_pkg_name      CONSTANT VARCHAR2(100) := 'xxwip720001c'; -- �p�b�P�[�W��
  -- ���W���[��������
  gv_xxcmn           CONSTANT VARCHAR2(100) := 'XXCMN';        -- ���W���[�������́FXXCMN ����
  gv_xxwip           CONSTANT VARCHAR2(100) := 'XXWIP';        -- ���W���[�������́FXXWIP ���Y�E�i���Ǘ��E�^���v�Z
--
  -- ���b�Z�[�W
  gv_msg_xxwip10004  CONSTANT VARCHAR2(100) := 'APP-XXWIP-10004'; -- ���b�Z�[�W�FAPP-XXWIP-10004 ���b�N�G���[�ڍ׃��b�Z�[�W
  gv_msg_xxwip10023  CONSTANT VARCHAR2(100) := 'APP-XXWIP-10023'; -- ���b�Z�[�W�FAPP-XXWIP-10023 �f�[�^�d���G���[���b�Z�[�W
  gv_msg_xxcmn10001  CONSTANT VARCHAR2(100) := 'APP-XXCMN-10001'; -- ���b�Z�[�W�FAPP-XXCMN-10001 �Ώۃf�[�^�Ȃ�
  gv_msg_xxxip10059  CONSTANT VARCHAR2(100) := 'APP-XXWIP-10059'; -- ���b�Z�[�W�FAPP-XXWIP-10059 �o�׊Ǘ����敪�G���[
  gv_msg_xxxip10060  CONSTANT VARCHAR2(100) := 'APP-XXWIP-10060'; -- ���b�Z�[�W�FAPP-XXWIP-10060 �o�׊Ǘ����敪�G���[(�z����)
  gv_msg_xxcmn10002  CONSTANT VARCHAR2(100) := 'APP-XXCMN-10002'; -- ���b�Z�[�W�FAPP-XXCMN-10002 �v���t�@�C���擾�G���[
  gv_msg_xxcmn00005  CONSTANT VARCHAR2(100) := 'APP-XXCMN-00005'; -- ���b�Z�[�W�FAPP-XXCMN-00005 �����f�[�^�i���o���j
  gv_msg_xxcmn00007  CONSTANT VARCHAR2(100) := 'APP-XXCMN-00007'; -- ���b�Z�[�W�FAPP-XXCMN-00007 �X�L�b�v�f�[�^�i���o���j
--
  -- �g�[�N��
  gv_tkn_value              CONSTANT VARCHAR2(100) := 'VALUE';            -- �g�[�N���FVALUE
  gv_tkn_item               CONSTANT VARCHAR2(100) := 'ITEM';             -- �g�[�N���FITEM
  gv_tkn_table              CONSTANT VARCHAR2(100) := 'TABLE';            -- �g�[�N���FTABLE
  gv_tkn_key                CONSTANT VARCHAR2(100) := 'KEY';              -- �g�[�N���FKEY
  gv_tkn_goods_classe       CONSTANT VARCHAR2(100) := 'GOODS_CLASSE';     -- �g�[�N���FGOODS_CLASSE
  gv_tkn_location_id        CONSTANT VARCHAR2(100) := 'LOCATION_ID';      -- �g�[�N���FLOCATION_ID
  gv_tkn_party_site_number  CONSTANT VARCHAR2(100) := 'PARTY_SITE_NUMBER';-- �g�[�N���FPARTY_SITE_NUMBER
  gv_tkn_ng_profile         CONSTANT VARCHAR2(100) := 'NG_PROFILE';       -- �g�[�N���FNG_PROFILE
--
  -- YES/NO
  gv_y               CONSTANT VARCHAR2(1) := 'Y';
  gv_n               CONSTANT VARCHAR2(1) := 'N';
--
  -- ���i�敪
  gv_goods_classe_reaf  CONSTANT VARCHAR2(1) := '1';   -- ���i�敪�F1(���[�t)
  gv_goods_classe_drink CONSTANT VARCHAR2(1) := '2';   -- ���i�敪�F2(�h�����N)
--
  -- �o�׊Ǘ����敪
  gv_shipment_management_sales  CONSTANT VARCHAR2(1) := '0';  -- �o�׊Ǘ����敪�F0(�̔����_)
  gv_shipment_management_reaf   CONSTANT VARCHAR2(1) := '1';  -- �o�׊Ǘ����敪�F1(�o�׊Ǘ������[�t)
  gv_shipment_management_drink  CONSTANT VARCHAR2(1) := '2';  -- �o�׊Ǘ����敪�F2(�o�׊Ǘ����h�����N)
  gv_shipment_management_both   CONSTANT VARCHAR2(1) := '3';  -- �o�׊Ǘ����敪�F3(�o�׊Ǘ����E����)
--
  -- �R�[�h�敪
  gv_code_type_location         CONSTANT VARCHAR2(1) := '1';  -- �R�[�h�敪�F1(�q��)
  gv_code_type_customer         CONSTANT VARCHAR2(1) := '2';  -- �R�[�h�敪�F2(�����)
  gv_code_type_delivery         CONSTANT VARCHAR2(1) := '3';  -- �R�[�h�敪�F3(�z����)
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  -- ���b�Z�[�WPL/SQL�\�^
  TYPE msg_ttype                    IS TABLE OF VARCHAR2(5000) INDEX BY BINARY_INTEGER;
--
  -- �o�^�E�X�V�pPL/SQL�\�^
  TYPE delivery_distance_id_ttype   IS TABLE OF  xxwip_delivery_distance.delivery_distance_id     %TYPE INDEX BY BINARY_INTEGER;  -- �z������ID
  TYPE goods_classe_ttype           IS TABLE OF  xxwip_delivery_distance.goods_classe             %TYPE INDEX BY BINARY_INTEGER;  -- ���i�敪
  TYPE delivery_company_code_ttype  IS TABLE OF  xxwip_delivery_distance.delivery_company_code    %TYPE INDEX BY BINARY_INTEGER;  -- �^���Ǝ҃R�[�h
  TYPE origin_shipment_ttype        IS TABLE OF  xxwip_delivery_distance.origin_shipment          %TYPE INDEX BY BINARY_INTEGER;  -- �o�Ɍ�
  TYPE code_division_ttype          IS TABLE OF  xxwip_delivery_distance.code_division            %TYPE INDEX BY BINARY_INTEGER;  -- �R�[�h�敪
  TYPE shipping_address_code_ttype  IS TABLE OF  xxwip_delivery_distance.shipping_address_code    %TYPE INDEX BY BINARY_INTEGER;  -- �z����R�[�h
  TYPE start_date_active_ttype      IS TABLE OF  xxwip_delivery_distance.start_date_active        %TYPE INDEX BY BINARY_INTEGER;  -- �K�p�J�n��
  TYPE end_date_active_ttype        IS TABLE OF  xxwip_delivery_distance.end_date_active          %TYPE INDEX BY BINARY_INTEGER;  -- �K�p�I����
  TYPE post_distance_ttype          IS TABLE OF  xxwip_delivery_distance.post_distance            %TYPE INDEX BY BINARY_INTEGER;  -- �ԗ�����
  TYPE small_distance_ttype         IS TABLE OF  xxwip_delivery_distance.small_distance           %TYPE INDEX BY BINARY_INTEGER;  -- ��������
  TYPE consolid_add_dist_ttype      IS TABLE OF  xxwip_delivery_distance.consolid_add_distance    %TYPE INDEX BY BINARY_INTEGER;  -- ���ڊ�������
  TYPE actual_distance_ttype        IS TABLE OF  xxwip_delivery_distance.actual_distance          %TYPE INDEX BY BINARY_INTEGER;  -- ���ۋ���
  TYPE area_a_ttype                 IS TABLE OF  xxwip_delivery_distance.area_a                   %TYPE INDEX BY BINARY_INTEGER;  -- �G���AA
  TYPE area_b_ttype                 IS TABLE OF  xxwip_delivery_distance.area_b                   %TYPE INDEX BY BINARY_INTEGER;  -- �G���AB
  TYPE area_c_ttype                 IS TABLE OF  xxwip_delivery_distance.area_c                   %TYPE INDEX BY BINARY_INTEGER;  -- �G���AC
--
  -- �v��ID�pPL/SQL�\�^
  TYPE request_id_ttype             IS TABLE OF  fnd_concurrent_requests.request_id               %TYPE INDEX BY BINARY_INTEGER;  -- �v��ID
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  -- �x���f�[�^�_���vPL/SQL�\
  warn_dump_tab         msg_ttype;
--
  -- ����f�[�^�_���vPL/SQL�\
  normal_dump_tab      msg_ttype; 
--
  -- �o�^�pPL/SQL�\
  delivery_distance_id_ins_tab      delivery_distance_id_ttype;   -- �z������ID
  goods_classe_ins_tab              goods_classe_ttype;           -- ���i�敪
  delivery_company_code_ins_tab    delivery_company_code_ttype;  -- �^���Ǝ҃R�[�h
  origin_shipment_ins_tab           origin_shipment_ttype;        -- �o�Ɍ�
  code_division_ins_tab             code_division_ttype;          -- �R�[�h�敪
  shipping_address_code_ins_tab     shipping_address_code_ttype;  -- �z����R�[�h
  start_date_active_ins_tab         start_date_active_ttype;      -- �K�p�J�n��
  end_date_active_ins_tab           end_date_active_ttype;        -- �K�p�I����
  post_distance_ins_tab             post_distance_ttype;          -- �ԗ�����
  small_distance_ins_tab            small_distance_ttype;         -- ��������
  consolid_add_dist_ins_tab         consolid_add_dist_ttype;      -- ���ڊ�������
  actual_distance_ins_tab           actual_distance_ttype;        -- ���ۋ���
  area_a_ins_tab                    area_a_ttype;                 -- �G���AA
  area_b_ins_tab                    area_b_ttype;                 -- �G���AB
  area_c_ins_tab                    area_c_ttype;                 -- �G���AC
--
  -- �X�V�pPL/SQL�\
  delivery_distance_id_upd_tab      delivery_distance_id_ttype;   -- �z������ID
  goods_classe_upd_tab              goods_classe_ttype;           -- ���i�敪
  delivery_company_code_upd_tab    delivery_company_code_ttype;  -- �^���Ǝ҃R�[�h
  origin_shipment_upd_tab           origin_shipment_ttype;        -- �o�Ɍ�
  code_division_upd_tab             code_division_ttype;          -- �R�[�h�敪
  shipping_address_code_upd_tab     shipping_address_code_ttype;  -- �z����R�[�h
  start_date_active_upd_tab         start_date_active_ttype;      -- �K�p�J�n��
  end_date_active_upd_tab           end_date_active_ttype;        -- �K�p�I����
  post_distance_upd_tab             post_distance_ttype;          -- �ԗ�����
  small_distance_upd_tab            small_distance_ttype;         -- ��������
  consolid_add_dist_upd_tab         consolid_add_dist_ttype;      -- ���ڊ�������
  actual_distance_upd_tab           actual_distance_ttype;        -- ���ۋ���
  area_a_upd_tab                    area_a_ttype;                 -- �G���AA
  area_b_upd_tab                    area_b_ttype;                 -- �G���AB
  area_c_upd_tab                    area_c_ttype;                 -- �G���AC
--
-- �v��ID�pPL/SQL�\
  request_id_tab                    request_id_ttype;             -- �v��ID
--
  -- �J�E���g
  gn_err_msg_cnt      NUMBER := 0;   -- �x���G���[���b�Z�[�W�\�J�E���g
  gn_ins_tab_cnt      NUMBER := 0;   -- �o�^�pPL/SQL�\�J�E���g
  gn_upd_tab_cnt      NUMBER := 0;   -- �X�V�pPL/SQL�\�J�E���g
  gn_request_id_cnt   NUMBER := 0;   -- �v��ID�J�E���g
--
--
  /**********************************************************************************
   * Procedure Name   : get_lock
   * Description      : ���b�N�擾����(D-2)
   ***********************************************************************************/
  PROCEDURE get_lock(
    ov_errbuf     OUT VARCHAR2,         --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,         --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)         --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_lock'; -- �v���O������
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
    cv_xxwip_delivery_distance     VARCHAR2(50) := '�z�������A�h�I���}�X�^';
    cv_xxwip_delivery_distance_if  VARCHAR2(50) := '�z�������A�h�I���}�X�^�C���^�t�F�[�X';
--
    -- *** ���[�J���ϐ� ***
--
    -- *** ���[�J���E�J�[�\�� ***
    -- �z�������A�h�I���}�X�^�C���^�t�F�[�X�J�[�\��
    CURSOR xxwip_delivery_charges_if_cur(lt_request_id xxwip_delivery_distance_if.request_id%TYPE)
    IS
      SELECT xddi.delivery_distance_if_id  delivery_distance_if_id   -- �z�������A�h�I���}�X�^�C���^�t�F�[�XID
      FROM   xxwip_delivery_distance_if    xddi                      -- �z�������A�h�I���}�X�^�C���^�t�F�[�X
      WHERE  xddi.request_id = lt_request_id                         -- �v��ID
      FOR UPDATE NOWAIT
    ;
--
    -- �z�������A�h�I���}�X�^�J�[�\��
    CURSOR xxwip_delivery_charges_cur
    IS
      SELECT xdd.delivery_distance_id  delivery_distance_id          -- �z�������A�h�I���}�X�^ID
      FROM   xxwip_delivery_distance    xdd                          -- �z�������A�h�I���}�X�^
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
    -- ==============================
    -- ���b�N�擾
    -- ==============================
    -- �z�������A�h�I���}�X�^�C���^�t�F�[�X�̃��b�N���擾
    BEGIN
      <<request_id_loop>>
      FOR ln_count IN 1..request_id_tab.COUNT
      LOOP
        <<look_if_loop>>
        FOR lr_xxwip_delivery_charges_if IN xxwip_delivery_charges_if_cur(request_id_tab(ln_count))
        LOOP
          EXIT;
        END LOOP xxwip_deli_distance_if_loop;
      END LOOP request_id_loop;

--
    EXCEPTION
      WHEN lock_expt THEN                           --*** ���b�N�擾�G���[ ***
        -- �G���[���b�Z�[�W�擾
        lv_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg(
                      gv_xxwip               -- ���W���[�������́FXXWIP ���Y�E�i���Ǘ��E�^���v�Z
                     ,gv_msg_xxwip10004      -- ���b�Z�[�W�FAPP-XXWIP-10004 ���b�N�G���[�ڍ׃��b�Z�[�W
                     ,gv_tkn_table           -- �g�[�N��TABLE
                     ,cv_xxwip_delivery_distance_if    -- �e�[�u�����F�z�������A�h�I���}�X�^�C���^�t�F�[�X
                     ),1,5000);
        RAISE global_api_expt;
    END;
--
    -- �z�������A�h�I���}�X�^�̃��b�N���擾
    BEGIN
       <<look_loop>>
      FOR lr_xxwip_delivery_charges IN xxwip_delivery_charges_cur LOOP
        EXIT;
      END LOOP xxwip_delivery_distance_loop;
--
    EXCEPTION
      WHEN lock_expt THEN                           --*** ���b�N�擾�G���[ ***
        -- �G���[���b�Z�[�W�擾
        lv_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg(
                      gv_xxwip               -- ���W���[�������́FXXWIP ���Y�E�i���Ǘ��E�^���v�Z
                     ,gv_msg_xxwip10004      -- ���b�Z�[�W�FAPP-XXWIP-10004 ���b�N�G���[�ڍ׃��b�Z�[�W
                     ,gv_tkn_table           -- �g�[�N��TABLE
                     ,cv_xxwip_delivery_distance    -- �e�[�u�����F�z�������A�h�I���}�X�^
                     ),1,5000);
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
  END get_lock;
--
  /**********************************************************************************
   * Procedure Name   : get_data_dump
   * Description      : �f�[�^�_���v�擾����(D-4)
   ***********************************************************************************/
  PROCEDURE get_data_dump(
    ir_xxwip_delivery_distance_if xxwip_delivery_distance_if%ROWTYPE, -- 1.xxwip_delivery_distance_if���R�[�h�^
    ov_dump       OUT VARCHAR2,     -- 1.�f�[�^�_���v������
    ov_errbuf     OUT VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_data_dump'; -- �v���O������
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
    -- ===============================
    -- �f�[�^�_���v�쐬
    -- ===============================
    ov_dump := ir_xxwip_delivery_distance_if.goods_classe                            || gv_msg_comma ||  -- ���i�敪
               ir_xxwip_delivery_distance_if.delivery_company_code                   || gv_msg_comma ||  -- �^���Ǝ҃R�[�h
               ir_xxwip_delivery_distance_if.origin_shipment                         || gv_msg_comma ||  -- �o�Ɍ�
               ir_xxwip_delivery_distance_if.area_a                                  || gv_msg_comma ||  -- �G���AA
               ir_xxwip_delivery_distance_if.area_b                                  || gv_msg_comma ||  -- �G���AB
               ir_xxwip_delivery_distance_if.area_c                                  || gv_msg_comma ||  -- �G���AC
               ir_xxwip_delivery_distance_if.code_division                           || gv_msg_comma ||  -- �R�[�h�敪
               ir_xxwip_delivery_distance_if.shipping_address_code                   || gv_msg_comma ||  -- �z����R�[�h
               TO_CHAR(ir_xxwip_delivery_distance_if.start_date_active,'YYYY/MM/DD') || gv_msg_comma ||  -- �K�p�J�n��
               TO_CHAR(ir_xxwip_delivery_distance_if.post_distance)                  || gv_msg_comma ||  -- �ԗ�����
               TO_CHAR(ir_xxwip_delivery_distance_if.small_distance)                 || gv_msg_comma ||  -- ��������
               TO_CHAR(ir_xxwip_delivery_distance_if.consolid_add_distance)          || gv_msg_comma ||  -- ���ڊ�������
               TO_CHAR(ir_xxwip_delivery_distance_if.actual_distance)                                    -- ���ۋ���
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
  END get_data_dump;
--
  /**********************************************************************************
   * Procedure Name   : del_duplication_data
   * Description      : �d���f�[�^���O����(D-3)
   ***********************************************************************************/
  PROCEDURE del_duplication_data(
    it_request_id IN  xxwip_delivery_distance_if.request_id%TYPE,     -- 1.�v��ID
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'del_duplication_data'; -- �v���O������
    cv_item       CONSTANT VARCHAR2(100) := '�f�[�^';
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
    lv_dump VARCHAR2(5000);  -- �f�[�^�_���v
    lr_xxwip_delivery_distance_if xxwip_delivery_distance_if%ROWTYPE;  -- xxwip_delivery_distance_if���R�[�h�^
--
    -- *** ���[�J���E�J�[�\�� ***
    -- �d���`�F�b�N�J�[�\��
    CURSOR xddi_duplication_chk_cur
    IS
      SELECT COUNT(xddi.delivery_distance_if_id) cnt -- �J�E���g
            ,xddi.goods_classe                       -- ���i�敪
            ,xddi.delivery_company_code              -- �^���Ǝ҃R�[�h
            ,xddi.origin_shipment                    -- �o�Ɍ�
            ,xddi.start_date_active                  -- �K�p�J�n��
            ,xddi.code_division                      -- �R�[�h�敪
            ,xddi.shipping_address_code              -- �z����R�[�h
      FROM   xxwip_delivery_distance_if  xddi        -- �z�������A�h�I���}�X�^�C���^�t�F�[�X
      WHERE  xddi.request_id = it_request_id         -- �v��ID
      GROUP BY 
             xddi.goods_classe          -- ���i�敪
            ,xddi.delivery_company_code -- �^���Ǝ҃R�[�h
            ,xddi.origin_shipment       -- �o�Ɍ�
            ,xddi.start_date_active     -- �K�p�J�n��
            ,xddi.code_division         -- �R�[�h�敪
            ,xddi.shipping_address_code -- �z����R�[�h
    ;
--
    -- �G���[�f�[�^�J�[�\��
    CURSOR xddi_err_data_cur(
      lt_goods_classe          xxwip_delivery_distance_if.goods_classe%TYPE            -- ���i�敪
     ,lt_delivery_company_code xxwip_delivery_distance_if.delivery_company_code%TYPE   -- �^���Ǝ҃R�[�h
     ,lt_origin_shipment       xxwip_delivery_distance_if.origin_shipment%TYPE         -- �o�Ɍ�
     ,lt_start_date_active     xxwip_delivery_distance_if.start_date_active%TYPE       -- �K�p�J�n��
     ,lt_code_division         xxwip_delivery_distance_if.code_division%TYPE           -- �R�[�h�敪
     ,lt_shipping_address_code xxwip_delivery_distance_if.shipping_address_code%TYPE   -- �z����R�[�h
    )
    IS
      SELECT xddi.goods_classe                goods_classe                 -- ���i�敪
            ,xddi.delivery_company_code       delivery_company_code        -- �^���Ǝ҃R�[�h
            ,xddi.origin_shipment             origin_shipment              -- �o�Ɍ�
            ,xddi.area_a                      area_a                       -- �G���AA
            ,xddi.area_b                      area_b                       -- �G���AB
            ,xddi.area_c                      area_c                       -- �G���AC
            ,xddi.code_division               code_division                -- �R�[�h�敪
            ,xddi.shipping_address_code       shipping_address_code        -- �z����R�[�h
            ,xddi.start_date_active           start_date_active            -- �K�p�J�n��
            ,xddi.post_distance               post_distance                -- �ԗ�����
            ,xddi.small_distance              small_distance               -- ��������
            ,xddi.consolid_add_distance       consolid_add_distance        -- ���ڊ�������
            ,xddi.actual_distance             actual_distance              -- ���ۋ���
      FROM   xxwip_delivery_distance_if  xddi        -- �z�������A�h�I���}�X�^�C���^�t�F�[�X
      WHERE  xddi.goods_classe           = lt_goods_classe                 -- ���i�敪
      AND    xddi.delivery_company_code  = lt_delivery_company_code        -- �^���Ǝ҃R�[�h
      AND    xddi.origin_shipment        = lt_origin_shipment              -- �o�Ɍ�
      AND    xddi.start_date_active      = lt_start_date_active            -- �K�p�J�n��
      AND    xddi.code_division          = lt_code_division                -- �R�[�h�敪
      AND    xddi.shipping_address_code  = lt_shipping_address_code        -- �z����R�[�h
      ORDER BY xddi.delivery_distance_if_id
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
    -- ===============================
    -- �d���`�F�b�N�J�[�\��
    -- ===============================
    <<xddi_duplication_chk_loop>>
    FOR lr_xddi_duplication_chk IN xddi_duplication_chk_cur LOOP
      -- �J�E���g��2���ȏ゠��ꍇ�A�d�����Ă���̂ŃG���[
      IF (lr_xddi_duplication_chk.cnt > 1) THEN
        -- ===============================
        -- �G���[�f�[�^�J�[�\��
        -- ===============================
        <<xddi_xddi_err_data_loop>>
        FOR lr_xddi_err_data IN  
          xddi_err_data_cur(
            lr_xddi_duplication_chk.goods_classe           -- ���i�敪
           ,lr_xddi_duplication_chk.delivery_company_code  -- �^���Ǝ҃R�[�h
           ,lr_xddi_duplication_chk.origin_shipment        -- �o�Ɍ�
           ,lr_xddi_duplication_chk.start_date_active      -- �K�p�J�n��
           ,lr_xddi_duplication_chk.code_division          -- �R�[�h�敪
           ,lr_xddi_duplication_chk.shipping_address_code  -- �z����R�[�h
          ) LOOP
--
          -- ���R�[�h�Ƀf�[�^�Z�b�g
          lr_xxwip_delivery_distance_if.goods_classe           := lr_xddi_err_data.goods_classe;                 -- ���i�敪
          lr_xxwip_delivery_distance_if.delivery_company_code  := lr_xddi_err_data.delivery_company_code;        -- �^���Ǝ҃R�[�h
          lr_xxwip_delivery_distance_if.origin_shipment        := lr_xddi_err_data.origin_shipment;              -- �o�Ɍ�
          lr_xxwip_delivery_distance_if.area_a                 := lr_xddi_err_data.area_a;                       -- �G���AA
          lr_xxwip_delivery_distance_if.area_b                 := lr_xddi_err_data.area_b;                       -- �G���AB
          lr_xxwip_delivery_distance_if.area_c                 := lr_xddi_err_data.area_c;                       -- �G���AC
          lr_xxwip_delivery_distance_if.code_division          := lr_xddi_err_data.code_division;                -- �R�[�h�敪
          lr_xxwip_delivery_distance_if.shipping_address_code  := lr_xddi_err_data.shipping_address_code;        -- �z����R�[�h
          lr_xxwip_delivery_distance_if.start_date_active      := lr_xddi_err_data.start_date_active;            -- �K�p�J�n��
          lr_xxwip_delivery_distance_if.post_distance          := lr_xddi_err_data.post_distance;                -- �ԗ�����
          lr_xxwip_delivery_distance_if.small_distance         := lr_xddi_err_data.small_distance;               -- ��������
          lr_xxwip_delivery_distance_if.consolid_add_distance  := lr_xddi_err_data.consolid_add_distance;        -- ���ڊ�������
          lr_xxwip_delivery_distance_if.actual_distance        := lr_xddi_err_data.actual_distance;              -- ���ۋ���
--
          -- ===============================
          -- D-4.�f�[�^�_���v�擾����
          -- ===============================
          get_data_dump(
            ir_xxwip_delivery_distance_if => lr_xxwip_delivery_distance_if -- 1.xxwip_delivery_distance_if���R�[�h�^
           ,ov_dump    => lv_dump            -- 1.�f�[�^�_���v������
           ,ov_errbuf  => lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
           ,ov_retcode => lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
           ,ov_errmsg  => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
          );
--
          -- �G���[�̏ꍇ
          IF (lv_retcode = gv_status_error) THEN
            RAISE global_process_expt;
          END IF;
--
          -- ===============================
          -- �x���G���[���b�Z�[�W�擾
          -- ===============================
          IF (lv_errmsg IS NULL) THEN
               -- �G���[���b�Z�[�W�擾
              lv_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg(
                              gv_xxwip               -- ���W���[�������́FXXWIP ���Y�E�i���Ǘ��E�^���v�Z
                             ,gv_msg_xxwip10023      -- ���b�Z�[�W�FAPP-XXWIP-10023 �f�[�^�d���G���[���b�Z�[�W
                             ,gv_tkn_item            -- �g�[�N��item
                             ,cv_item                -- item��
                              ),1,5000);
--
          END IF;
--
          -- ===============================
          -- �x���f�[�^�_���vPL/SQL�\����
          -- ===============================
          -- �f�[�^�_���v
          gn_err_msg_cnt := gn_err_msg_cnt + 1;
          warn_dump_tab(gn_err_msg_cnt) := lv_dump;
          
--
          -- �x�����b�Z�[�W
          gn_err_msg_cnt := gn_err_msg_cnt + 1;
          warn_dump_tab(gn_err_msg_cnt) := lv_errmsg;
--
          -- �X�L�b�v�����J�E���g
          gn_warn_cnt   := gn_warn_cnt + 1;
--
        END LOOP xddi_xddi_err_data_loop;
--
        -- ===============================
        -- �G���[�f�[�^�폜
        -- ===============================
        DELETE xxwip_delivery_distance_if xddi   -- �z�������A�h�I���}�X�^�C���^�t�F�[�X
        WHERE  xddi.goods_classe           = lr_xddi_duplication_chk.goods_classe                 -- ���i�敪
        AND    xddi.delivery_company_code  = lr_xddi_duplication_chk.delivery_company_code        -- �^���Ǝ҃R�[�h
        AND    xddi.origin_shipment        = lr_xddi_duplication_chk.origin_shipment              -- �o�Ɍ�
        AND    xddi.start_date_active      = lr_xddi_duplication_chk.start_date_active            -- �K�p�J�n��
        AND    xddi.code_division          = lr_xddi_duplication_chk.code_division                -- �R�[�h�敪
        AND    xddi.shipping_address_code  = lr_xddi_duplication_chk.shipping_address_code        -- �z����R�[�h
        ;
--
       -- ===============================
       --  OUT�p�����[�^�Z�b�g
       -- ===============================
       ov_retcode := gv_status_warn;
--
      END IF;
--
    END LOOP xddi_duplication_chk_loop;
--
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      IF (xddi_duplication_chk_cur%ISOPEN) THEN
        CLOSE xddi_duplication_chk_cur;
      END IF;
      IF (xddi_err_data_cur%ISOPEN) THEN
        CLOSE xddi_duplication_chk_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      IF (xddi_duplication_chk_cur%ISOPEN) THEN
        CLOSE xddi_duplication_chk_cur;
      END IF;
      IF (xddi_err_data_cur%ISOPEN) THEN
        CLOSE xddi_duplication_chk_cur;
      END IF;
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      IF (xddi_duplication_chk_cur%ISOPEN) THEN
        CLOSE xddi_duplication_chk_cur;
      END IF;
      IF (xddi_err_data_cur%ISOPEN) THEN
        CLOSE xddi_duplication_chk_cur;
      END IF;
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END del_duplication_data;
--
--
  /**********************************************************************************
   * Procedure Name   : master_data_chk
   * Description      : �}�X�^�f�[�^�`�F�b�N����(D-6)
   ***********************************************************************************/
  PROCEDURE master_data_chk(
    ir_xxwip_delivery_distance_if IN  xxwip_delivery_distance_if%ROWTYPE, -- 1.xxwip_delivery_distance_if���R�[�h�^
    iv_dump                       IN VARCHAR2,                            -- 2.�f�[�^�_���v
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'master_data_chk'; -- �v���O������
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
    -- �G���[�L�[����
    cv_category_set          VARCHAR2(50) := '�J�e�S���Z�b�g��';     -- �G���[�L�[���ځF�J�e�S���Z�b�g��
    cv_category_set_name     VARCHAR2(50) := '���i�敪';             -- �G���[�L�[���ځF���i�敪
    cv_delivery_company_code VARCHAR2(50) := '�^���Ǝ҃R�[�h';       -- �G���[�L�[���ځF�^���Ǝ҃R�[�h
    cv_item_location_code    VARCHAR2(50) := '�ۊǑq�ɃR�[�h';       -- �G���[�L�[���ځF�ۊǑq�ɃR�[�h
    cv_vendor_site_code      VARCHAR2(50) := '�d����T�C�g��';       -- �G���[�L�[���ځF�d����T�C�g��
    cv_party_site_number     VARCHAR2(50) := '�T�C�g�ԍ�';           -- �G���[�L�[���ځF�T�C�g�ԍ�
    cv_lookup_type           VARCHAR2(50) := '�N�C�b�N�R�[�h�^�C�v'; -- �G���[�L�[���ځF�N�C�b�N�R�[�h�^�C�v
    cv_lookup_code           VARCHAR2(50) := '�N�C�b�N�R�[�h';       -- �G���[�L�[���ځF�N�C�b�N�R�[�h
    cv_location_id           VARCHAR2(50) := '���Ə�ID';             -- �G���[�L�[���ځF���Ə�ID
--
    cv_xxcmn_categories_v     VARCHAR2(50) := '�i�ڃJ�e�S�����VIEW';         -- �G���[�e�[�u�����F�i�ڃJ�e�S�����VIEW
    cv_xxwip_delivery_company VARCHAR2(50) := '�^���p�^���Ǝ҃A�h�I���}�X�^'; -- �G���[�e�[�u�����F�^���p�^���Ǝ҃A�h�I���}�X�^
    cv_xxcmn_item_locations_v VARCHAR2(50) := 'OPM�ۊǏꏊ���VIEW';          -- �G���[�e�[�u�����FOPM�ۊǏꏊ���VIEW
    cv_xxcmn_locations_v      VARCHAR2(50) := '���Ə����VIEW';               -- �G���[�e�[�u�����F���Ə����VIEW
    cv_xxcmn_lookup_values_v  VARCHAR2(50) := '�N�C�b�N�R�[�h���VIEW';       -- �G���[�e�[�u�����F�N�C�b�N�R�[�h���VIEW
    cv_xxcmn_vendor_sites_v   VARCHAR2(50) := '�d����T�C�g���VIEW';         -- �G���[�e�[�u�����F�d����T�C�g���VIEW
    cv_xxcmn_party_sites_v    VARCHAR2(50) := '�p�[�e�B�T�C�g���VIEW';       -- �G���[�e�[�u�����F�p�[�e�B�T�C�g���VIEW
    cv_xxcmn_parties_v        VARCHAR2(50) := '�p�[�e�B���VIEW';             -- �G���[�e�[�u�����F�p�[�e�B���VIEW
--
    -- �N�C�b�N�R�[�h
    cv_xxwip_code_type       VARCHAR2(50) := 'XXWIP_CODE_TYPE';  -- �N�C�b�N�R�[�h�^�C�v�F�R�[�h�敪
    cv_xxwip_area_a          VARCHAR2(50) := 'XXWIP_AREA_A';     -- �N�C�b�N�R�[�h�^�C�v�F�G���AA
    cv_xxwip_area_b          VARCHAR2(50) := 'XXWIP_AREA_B';     -- �N�C�b�N�R�[�h�^�C�v�F�G���AB
    cv_xxwip_area_c          VARCHAR2(50) := 'XXWIP_AREA_C';     -- �N�C�b�N�R�[�h�^�C�v�F�G���AC
    cv_xxwip_code_type_name  VARCHAR2(50) := 'XXWIP:�R�[�h�敪'; -- �N�C�b�N�R�[�h�^�C�v�F�R�[�h�敪
    cv_xxwip_area_a_name     VARCHAR2(50) := 'XXWIP:�G���AA';    -- �N�C�b�N�R�[�h�^�C�v�F�G���AA
    cv_xxwip_area_b_name     VARCHAR2(50) := 'XXWIP:�G���AB';    -- �N�C�b�N�R�[�h�^�C�v�F�G���AB
    cv_xxwip_area_c_name     VARCHAR2(50) := 'XXWIP:�G���AC';    -- �N�C�b�N�R�[�h�^�C�v�F�G���AC
--
    -- *** ���[�J���ϐ� ***
    ln_temp                 NUMBER;
    lv_err_tbl              VARCHAR2(50);  -- �G���[�e�[�u����
    lv_err_key              VARCHAR2(2000);-- �G���[�L�[����
    lt_shipment_management  xxcmn_locations_v.ship_mng_code%TYPE;     -- �o�׊Ǘ����敪
    lt_location_id          xxcmn_item_locations_v.location_id%TYPE;  -- ���Ə�ID
    lt_party_id             hz_party_sites.party_id      %TYPE; -- �p�[�e�BID
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
    -- ===============================
    -- �����֐�
    -- ===============================
    -- *** �x���G���[���b�Z�[�W�\���� ***
    PROCEDURE set_err_msg
    IS
    BEGIN
      -- �x���f�[�^�_���vPL/SQL�\����
      -- 1���ڂ̌x���̏ꍇ�̂݁A�_���v�𓊓�
      IF (lv_retcode = gv_status_normal) THEN
        gn_err_msg_cnt := gn_err_msg_cnt + 1;
        warn_dump_tab(gn_err_msg_cnt) := iv_dump;
      END IF;
--
      -- �x�����b�Z�[�W�𓊓�
      gn_err_msg_cnt := gn_err_msg_cnt + 1;
      warn_dump_tab(gn_err_msg_cnt) := lv_errmsg;
--
      -- �x���ɃZ�b�g
      lv_retcode := gv_status_warn;
--
    END set_err_msg;
--
    -- *** �Ώۃf�[�^�Ȃ����b�Z�[�W�擾 *** --
    PROCEDURE get_no_data_msg
    IS
    BEGIN
      -- �Ώۃf�[�^�Ȃ����b�Z�[�W�擾
      lv_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg(
                    gv_xxcmn               -- ���W���[�������́FXXCMN ����
                   ,gv_msg_xxcmn10001      -- ���b�Z�[�W�FAPP-XXCMN-10001 �Ώۃf�[�^�Ȃ�
                   ,gv_tkn_table           -- �g�[�N���FTABLE
                   ,lv_err_tbl             -- �G���[�e�[�u����
                   ,gv_tkn_key             -- �g�[�N���FKEY
                   ,lv_err_key             -- �G���[�L�[����
                  ),1,5000);
--
      -- �x���G���[���b�Z�[�W�\����
      set_err_msg;
    END;
--
    -- *** �o�׊Ǘ����敪�`�F�b�N *** --
    PROCEDURE shipment_management_chk(
      iv_msg     IN VARCHAR2
     ,iv_tkn     IN VARCHAR2  -- �g�[�N��
     ,it_value   IN xxcmn_locations_v.location_id%TYPE  -- �l
    )
    IS
    BEGIN
      -- ���i�敪��1�F���[�t���A�o�׊Ǘ����敪��1(�o�׊Ǘ������[�t)�܂��́A3(�o�׊Ǘ����E����)�ȊO�̓G���[
      IF ((ir_xxwip_delivery_distance_if.goods_classe = gv_goods_classe_reaf)
      AND((lt_shipment_management NOT IN (gv_shipment_management_reaf,gv_shipment_management_both))
      OR  (lt_shipment_management IS NULL)))
      -- ���i�敪��2�F�h�����N���A�o�׊Ǘ����敪��2(�o�׊Ǘ����h�����N)�܂��́A3(�o�׊Ǘ����E����)�ȊO�̓G���[
      OR ((ir_xxwip_delivery_distance_if.goods_classe = gv_goods_classe_drink)
      AND((lt_shipment_management NOT IN (gv_shipment_management_drink,gv_shipment_management_both))
      OR  (lt_shipment_management IS NULL)))
      THEN
        -- �o�׊Ǘ����敪�G���[���b�Z�[�W�擾
        lv_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg(
                      gv_xxwip               -- ���W���[�������́FXXWIP 
                     ,iv_msg                 -- ���b�Z�[�W�FAPP-XXWIP-10059 �o�׊Ǘ����敪�G���[
                     ,gv_tkn_goods_classe    -- �g�[�N���FGOODS_CLASSE
                     ,ir_xxwip_delivery_distance_if.goods_classe             -- ���i�敪
                     ,iv_tkn                 -- �g�[�N��
                     ,it_value               -- �l
                    ),1,5000);
--
        -- �x���G���[���b�Z�[�W�\����
        set_err_msg;
      END IF;
    END shipment_management_chk;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    lv_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ===============================
    -- ���i�敪�`�F�b�N
    -- ===============================
    -- �i�ڃJ�e�S�����VIEW���`�F�b�N
    SELECT COUNT(1) cnt
    INTO   ln_temp
    FROM   xxcmn_categories_v xcv  -- �i�ڃJ�e�S�����VIEW
    WHERE  xcv.category_set_name = cv_category_set_name -- �J�e�S���Z�b�g��
    AND    xcv.segment1          = ir_xxwip_delivery_distance_if.goods_classe      -- ���i�敪
    ;
--
    -- �f�[�^���Ȃ��ꍇ�̓G���[
    IF (ln_temp = 0) THEN
       -- �G���[�e�[�u�����A�G���[�L�[���ڃZ�b�g
      lv_err_tbl := cv_xxcmn_categories_v; -- �G���[�e�[�u�����F���i�敪
      lv_err_key := cv_category_set_name || 
                    gv_msg_part          || 
                    ir_xxwip_delivery_distance_if.goods_classe;     -- �G���[�L�[���� ���i�敪�Fgoods_classe
--
      -- �Ώۃf�[�^�Ȃ����b�Z�[�W�擾
      get_no_data_msg;
    END IF;
--
    -- ===============================
    -- �^���Ǝ҃`�F�b�N
    -- ===============================
    -- �^���p�^���Ǝ҃}�X�^���`�F�b�N
    SELECT COUNT(1) cnt
    INTO   ln_temp
    FROM   xxwip_delivery_company xdc  -- �^���p�^���Ǝ҃}�X�^
    WHERE  xdc.goods_classe          = ir_xxwip_delivery_distance_if.goods_classe          -- ���i�敪
    AND    xdc.delivery_company_code = ir_xxwip_delivery_distance_if.delivery_company_code -- �^���Ǝ�
    AND    xdc.start_date_active    <= TRUNC(SYSDATE)           -- �K�p�J�n��
    AND    xdc.end_date_active      >= TRUNC(SYSDATE)           -- �K�p�I����
    ;
--
    -- �f�[�^���Ȃ��ꍇ�̓G���[
    IF (ln_temp = 0) THEN
      -- �G���[�e�[�u�����A�G���[�L�[���ڃZ�b�g
      lv_err_tbl := cv_xxwip_delivery_company; -- �G���[�e�[�u�����F�^���p�^���Ǝ҃A�h�I���}�X�^
      lv_err_key := cv_category_set_name                       ||
                    gv_msg_part                                ||
                    ir_xxwip_delivery_distance_if.goods_classe ||
                    gv_msg_comma                               ||
                    cv_delivery_company_code                   ||
                    gv_msg_part                                ||
                    ir_xxwip_delivery_distance_if.delivery_company_code ;
                                               -- �G���[�L�[���� ���i�敪�Fgoods_classe,�^���Ǝ҃R�[�h�Fdelivery_company_code
--
      -- �Ώۃf�[�^�Ȃ����b�Z�[�W�擾
      get_no_data_msg;
    END IF;
--
    -- ===============================
    -- �o�Ɍ��`�F�b�N
    -- ===============================
    BEGIN
      -- OPM�ۊǏꏊ�}�X�^���`�F�b�N
      SELECT xmilv.location_id  -- ���Ə�ID
      INTO   lt_location_id
      FROM   xxcmn_item_locations_v xmilv                     -- OPM�ۊǏꏊ���VIEW
      WHERE  xmilv.segment1 = ir_xxwip_delivery_distance_if.origin_shipment -- �o�Ɍ�
      ;
--
    EXCEPTION
      -- �f�[�^���Ȃ��ꍇ�̓G���[
      WHEN NO_DATA_FOUND THEN
         -- �G���[�e�[�u�����A�G���[�L�[���ڃZ�b�g
        lv_err_tbl := cv_xxcmn_item_locations_v; -- �G���[�e�[�u�����FOPM�ۊǏꏊ���VIEW
        lv_err_key := cv_item_location_code      ||
                      gv_msg_part                ||
                      ir_xxwip_delivery_distance_if.origin_shipment;
                                             -- �G���[�L�[���� �ۊǏꏊ�R�[�h�Forigin_shipment
--
      -- �Ώۃf�[�^�Ȃ����b�Z�[�W�擾
      get_no_data_msg;
    END;
--
    -- ===============================
    -- �o�׊Ǘ����敪�`�F�b�N
    -- ===============================
    BEGIN
      -- ���Ə��}�X�^����o�׊Ǘ����敪���擾
      SELECT xlv.ship_mng_code shipment_management  -- �o�׊Ǘ����敪
      INTO   lt_shipment_management
      FROM   xxcmn_locations_v   xlv                -- ���Ə����VIEW
      WHERE  xlv.location_id = lt_location_id       -- ���Ə�ID
      ;
--
      -- �o�׊Ǘ����敪�`�F�b�N
      shipment_management_chk(
        iv_msg   => gv_msg_xxxip10059       -- ���b�Z�[�W�FAPP-XXWIP-10059 �o�׊Ǘ����敪�G���[
       ,iv_tkn   => gv_tkn_location_id      -- �g�[�N���FLOCATION_ID
       ,it_value => lt_location_id          -- �l
      );
    EXCEPTION
      WHEN NO_DATA_FOUND THEN  -- *** �f�[�^���Ȃ��ꍇ ***--
        -- �G���[�e�[�u�����A�G���[�L�[���ڃZ�b�g
        lv_err_tbl := cv_xxcmn_locations_v; -- �G���[�e�[�u�����F���Ə����VIEW
        lv_err_key := cv_location_id    ||
                      gv_msg_part       ||
                      lt_location_id;
                                           -- �G���[�L�[���� ���Ə�ID�Flt_location_id
--
      -- �Ώۃf�[�^�Ȃ����b�Z�[�W�擾
      get_no_data_msg;
    END;
--
    -- ===============================
    -- �R�[�h�敪�`�F�b�N
    -- ===============================
    -- �N�C�b�N�R�[�h���VIEW���`�F�b�N
    SELECT COUNT(1) cnt
    INTO   ln_temp
    FROM   xxcmn_lookup_values_v xlvv                                -- �N�C�b�N�R�[�h���VIEW
    WHERE  lookup_type = cv_xxwip_code_type                          -- �N�C�b�N�R�[�h�^�C�v�F�R�[�h�敪
    AND    lookup_code = ir_xxwip_delivery_distance_if.code_division -- �N�C�b�N�R�[�h
    ;
--
    -- �f�[�^���Ȃ��ꍇ�̓G���[
    IF (ln_temp = 0) THEN
       -- �G���[�e�[�u�����A�G���[�L�[���ڃZ�b�g
      lv_err_tbl := cv_xxcmn_lookup_values_v; -- �G���[�e�[�u�����F�N�C�b�N�R�[�h���VIEW
      lv_err_key := cv_lookup_type              ||
                    gv_msg_part                 ||
                    cv_xxwip_code_type_name     ||
                    gv_msg_comma                ||
                    cv_lookup_code              ||
                    gv_msg_part                 ||
                    ir_xxwip_delivery_distance_if.code_division;
                                              -- �G���[�L�[���� �N�C�b�N�R�[�h�^�C�v�Fcv_xxwip_code_type,�N�C�b�N�R�[�h�Fcode_division
--
      -- �Ώۃf�[�^�Ȃ����b�Z�[�W�擾
      get_no_data_msg;
    END IF;
--
    -- ���_�R�[�h������
    lt_location_id := NULL;
--
    -- �R�[�h�敪�F1(�q��)�̏ꍇ
    IF (ir_xxwip_delivery_distance_if.code_division = gv_code_type_location) THEN
      BEGIN
        -- ===============================
        -- �z����R�[�h�`�F�b�N
        -- ===============================
        -- OPM�ۊǏꏊ�}�X�^���`�F�b�N
        SELECT xmilv.location_id    -- ���Ə�ID
        INTO   lt_location_id
        FROM   xxcmn_item_locations_v xmilv                    -- OPM�ۊǏꏊ���VIEW
        WHERE  xmilv.segment1 = ir_xxwip_delivery_distance_if.shipping_address_code -- �z����R�[�h
        ;
--
      EXCEPTION
        -- �f�[�^���Ȃ��ꍇ�̓G���[
        WHEN NO_DATA_FOUND THEN
           -- �G���[�e�[�u�����A�G���[�L�[���ڃZ�b�g
          lv_err_tbl := cv_xxcmn_item_locations_v; -- �G���[�e�[�u�����FOPM�ۊǏꏊ���VIEW
          lv_err_key := cv_item_location_code      ||
                        gv_msg_part                ||
                        ir_xxwip_delivery_distance_if.shipping_address_code;
                                               -- �G���[�L�[���� �ۊǏꏊ�R�[�h�Fshipping_address_code
--
        -- �Ώۃf�[�^�Ȃ����b�Z�[�W�擾
        get_no_data_msg;
      END;
--
      -- ===============================
      -- �o�׊Ǘ����敪�`�F�b�N
      -- ===============================
      BEGIN
        -- ���Ə��}�X�^����o�׊Ǘ����敪���擾
        SELECT xlv.ship_mng_code shipment_management -- �o�׊Ǘ����敪
        INTO   lt_shipment_management
        FROM   xxcmn_locations_v   xlv               -- ���Ə����VIEW
        WHERE  xlv.location_id = lt_location_id  -- ���Ə�ID
        ;
--
        -- �o�׊Ǘ����敪�`�F�b�N
      shipment_management_chk(
        iv_msg   => gv_msg_xxxip10059       -- ���b�Z�[�W�FAPP-XXWIP-10059 �o�׊Ǘ����敪�G���[
       ,iv_tkn   => gv_tkn_location_id      -- �g�[�N���FLOCATION_ID
       ,it_value => lt_location_id          -- �l
      );
      EXCEPTION
        WHEN NO_DATA_FOUND THEN  -- *** �f�[�^���Ȃ��ꍇ ***--
          -- �G���[�e�[�u�����A�G���[�L�[���ڃZ�b�g
          lv_err_tbl := cv_xxcmn_locations_v; -- �G���[�e�[�u�����F���Ə����VIEW
          lv_err_key := cv_location_id      ||
                        gv_msg_part         ||
                        lt_location_id;
                                             -- �G���[�L�[���� ���_�R�[�h�Flt_location_code
--
        -- �Ώۃf�[�^�Ȃ����b�Z�[�W�擾
        get_no_data_msg;
      END;
--
    -- �R�[�h�敪�F2(�����)�̏ꍇ
    ELSIF (ir_xxwip_delivery_distance_if.code_division = gv_code_type_customer) THEN
      -- ===============================
      -- �z����R�[�h�`�F�b�N
      -- ===============================
      -- �d����T�C�g�}�X�^���`�F�b�N
      SELECT COUNT(1) cnt
      INTO   ln_temp
      FROM   xxcmn_vendor_sites_v xvsv  -- �d����T�C�g���VIEW
      WHERE  xvsv.vendor_site_code = ir_xxwip_delivery_distance_if.shipping_address_code -- �z����R�[�h
      ;
--
      -- �f�[�^���Ȃ��ꍇ�̓G���[
      IF (ln_temp = 0) THEN
         -- �G���[�e�[�u�����A�G���[�L�[���ڃZ�b�g
        lv_err_tbl := cv_xxcmn_vendor_sites_v; -- �G���[�e�[�u�����F�d����T�C�g���VIEW
        lv_err_key := cv_vendor_site_code  ||
                      gv_msg_part          ||
                      ir_xxwip_delivery_distance_if.shipping_address_code;
                                              -- �G���[�L�[���� �d����T�C�g���Fshipping_address_code
--
        -- �Ώۃf�[�^�Ȃ����b�Z�[�W�擾
        get_no_data_msg;
      END IF;
--
    -- �R�[�h�敪�F3(�z����)�̏ꍇ
    ELSIF (ir_xxwip_delivery_distance_if.code_division = gv_code_type_delivery) THEN
      -- ===============================
      -- �z����R�[�h�`�F�b�N
      -- ===============================
      BEGIN
        -- �p�[�e�B�T�C�g�}�X�^���`�F�b�N
        SELECT xpsv.party_id   party_id  -- �p�[�e�BID
        INTO   lt_party_id
        FROM   xxcmn_party_sites_v xpsv -- �p�[�e�B�T�C�g���VIEW
        WHERE  xpsv.party_site_number  = ir_xxwip_delivery_distance_if.shipping_address_code -- �z����R�[�h
        ;
--
        -- �f�[�^���Ȃ��ꍇ�̓G���[
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
           -- �G���[�e�[�u�����A�G���[�L�[���ڃZ�b�g
          lv_err_tbl := cv_xxcmn_party_sites_v; -- �G���[�e�[�u�����F�p�[�e�B�T�C�g���VIEW
          lv_err_key := cv_party_site_number       ||
                        gv_msg_part                ||
                        ir_xxwip_delivery_distance_if.shipping_address_code;
                                                -- �G���[�L�[���� �T�C�g�ԍ��Fshipping_address_code
--
        -- �Ώۃf�[�^�Ȃ����b�Z�[�W�擾
        get_no_data_msg;
      END;
--
-- 2008/09/02 v1.1 UPDATE START
/*
      -- ===============================
      -- �o�׊Ǘ����敪�`�F�b�N
      -- ===============================
      BEGIN
        -- �o�׊Ǘ����敪���擾
        SELECT xpv.ship_mng_code shipment_management -- �o�׊Ǘ����敪
        INTO   lt_shipment_management
        FROM   xxcmn_parties_v xpv                -- �p�[�e�B���VIEW
        WHERE  xpv.party_id = lt_party_id         -- �p�[�e�BID
        ;
--
        -- �o�׊Ǘ����敪�`�F�b�N
        shipment_management_chk(
          iv_msg   => gv_msg_xxxip10060       -- ���b�Z�[�W�FAPP-XXWIP-10060 �o�׊Ǘ����敪�G���[(�z����)
         ,iv_tkn   => gv_tkn_party_site_number-- �g�[�N���FPARTY_SITE_NUMBER
         ,it_value => ir_xxwip_delivery_distance_if.shipping_address_code        -- �l
        );
--
      EXCEPTION
        WHEN NO_DATA_FOUND THEN  -- *** �f�[�^���Ȃ��ꍇ ***--
          -- �G���[�e�[�u�����A�G���[�L�[���ڃZ�b�g
          lv_err_tbl := cv_xxcmn_parties_v; -- �G���[�e�[�u�����F�p�[�e�B���VIEW
          lv_err_key := cv_party_site_number   ||
                        gv_msg_part            ||
                        ir_xxwip_delivery_distance_if.shipping_address_code;
                                             -- �G���[�L�[���� �T�C�g�ԍ��Fshipping_address_code
--
        -- �Ώۃf�[�^�Ȃ����b�Z�[�W�擾
        get_no_data_msg;
      END;
*/
-- 2008/09/02 v1.1 UPDATE END
    END IF;
--
    -- ===============================
    -- �G���AA�`�F�b�N
    -- ===============================
    IF (ir_xxwip_delivery_distance_if.area_a IS NOT NULL) THEN
      -- �N�C�b�N�R�[�h���VIEW���`�F�b�N
      SELECT COUNT(1) cnt
      INTO   ln_temp
      FROM   xxcmn_lookup_values_v xlvv                         -- �N�C�b�N�R�[�h���VIEW
      WHERE  lookup_type = cv_xxwip_area_a                      -- �N�C�b�N�R�[�h�^�C�v�F�G���AA
      AND    lookup_code = ir_xxwip_delivery_distance_if.area_a -- �N�C�b�N�R�[�h
      ;
--
      -- �f�[�^���Ȃ��ꍇ�̓G���[
      IF (ln_temp = 0) THEN
         -- �G���[�e�[�u�����A�G���[�L�[���ڃZ�b�g
        lv_err_tbl := cv_xxcmn_lookup_values_v; -- �G���[�e�[�u�����F�N�C�b�N�R�[�h���VIEW
        lv_err_key := cv_lookup_type       ||
                      gv_msg_part          ||
                      cv_xxwip_area_a_name ||
                      gv_msg_comma         ||
                      cv_lookup_code       ||
                      gv_msg_part          ||
                      ir_xxwip_delivery_distance_if.area_a;
                                                -- �G���[�L�[���� �N�C�b�N�R�[�h�^�C�v�Fcv_xxwip_area_a,�N�C�b�N�R�[�h�Farea_a
--
        -- �Ώۃf�[�^�Ȃ����b�Z�[�W�擾
        get_no_data_msg;
      END IF;
    END IF;
--
    -- ===============================
    -- �G���AB�`�F�b�N
    -- ===============================
    IF (ir_xxwip_delivery_distance_if.area_b IS NOT NULL) THEN
      -- �N�C�b�N�R�[�h���VIEW���`�F�b�N
      SELECT COUNT(1) cnt
      INTO   ln_temp
      FROM   xxcmn_lookup_values_v xlvv                         -- �N�C�b�N�R�[�h���VIEW
      WHERE  lookup_type = cv_xxwip_area_b                      -- �N�C�b�N�R�[�h�^�C�v�F�G���AB
      AND    lookup_code = ir_xxwip_delivery_distance_if.area_b -- �N�C�b�N�R�[�h
      ;
--
      -- �f�[�^���Ȃ��ꍇ�̓G���[
      IF (ln_temp = 0) THEN
         -- �G���[�e�[�u�����A�G���[�L�[���ڃZ�b�g
        lv_err_tbl := cv_xxcmn_lookup_values_v; -- �G���[�e�[�u�����F�N�C�b�N�R�[�h���VIEW
        lv_err_key := cv_lookup_type         ||
                      gv_msg_part            ||
                      cv_xxwip_area_b_name   ||
                      gv_msg_comma           ||
                      cv_lookup_code         ||
                      gv_msg_part            ||
                      ir_xxwip_delivery_distance_if.area_b;
                                                -- �G���[�L�[���� �N�C�b�N�R�[�h�^�C�v�Fcv_xxwip_area_b,�N�C�b�N�R�[�h�Farea_b
--
        -- �Ώۃf�[�^�Ȃ����b�Z�[�W�擾
        get_no_data_msg;
      END IF;
    END IF;
--
    -- ===============================
    -- �G���AC�`�F�b�N
    -- ===============================
    IF (ir_xxwip_delivery_distance_if.area_c IS NOT NULL) THEN
      -- �N�C�b�N�R�[�h���VIEW���`�F�b�N
      SELECT COUNT(1) cnt
      INTO   ln_temp
      FROM   xxcmn_lookup_values_v xlvv                         -- �N�C�b�N�R�[�h���VIEW
      WHERE  lookup_type = cv_xxwip_area_c                      -- �N�C�b�N�R�[�h�^�C�v�F�G���AC
      AND    lookup_code = ir_xxwip_delivery_distance_if.area_c -- �N�C�b�N�R�[�h
      ;
--
      -- �f�[�^���Ȃ��ꍇ�̓G���[
      IF (ln_temp = 0) THEN
         -- �G���[�e�[�u�����A�G���[�L�[���ڃZ�b�g
        lv_err_tbl := cv_xxcmn_lookup_values_v; -- �G���[�e�[�u�����F�N�C�b�N�R�[�h���VIEW
        lv_err_key := cv_lookup_type         ||
                      gv_msg_part            ||
                      cv_xxwip_area_c_name   ||
                      gv_msg_comma           ||
                      cv_lookup_code         ||
                      gv_msg_part            ||
                      ir_xxwip_delivery_distance_if.area_c;
                                                -- �G���[�L�[���� �N�C�b�N�R�[�h�^�C�v�Fcv_xxwip_area_c,�N�C�b�N�R�[�h�Farea_c
--
        -- �Ώۃf�[�^�Ȃ����b�Z�[�W�擾
        get_no_data_msg;
      END IF;
    END IF;
--
    -- ===============================
    -- OUT�p�����[�^�Z�b�g
    -- ===============================
    ov_retcode := lv_retcode;
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
  END master_data_chk;
--
  /**********************************************************************************
   * Procedure Name   : set_ins_tab
   * Description      : �o�^�pPL/SQL�\����(D-7)
   ***********************************************************************************/
  PROCEDURE set_ins_tab(
    ir_xxwip_delivery_distance_if IN  xxwip_delivery_distance_if%ROWTYPE,  -- 1.xxwip_delivery_distance_if���R�[�h�^
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'set_ins_tab'; -- �v���O������
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
    -- ===============================
    -- �o�^�pPL/SQL�\�ɃZ�b�g
    -- ===============================
    -- �o�^�p�����J�E���g
    gn_ins_tab_cnt := gn_ins_tab_cnt + 1;
--
    -- �l�Z�b�g
    SELECT xxwip_delivery_distance_id_s1.NEXTVAL
    INTO   delivery_distance_id_ins_tab(gn_ins_tab_cnt)  -- �z������ID
    FROM   DUAL;
    goods_classe_ins_tab(gn_ins_tab_cnt)           := ir_xxwip_delivery_distance_if.goods_classe;           -- ���i�敪
    delivery_company_code_ins_tab(gn_ins_tab_cnt) := ir_xxwip_delivery_distance_if.delivery_company_code;  -- �^���Ǝ҃R�[�h
    origin_shipment_ins_tab(gn_ins_tab_cnt)        := ir_xxwip_delivery_distance_if.origin_shipment;        -- �o�Ɍ�
    code_division_ins_tab(gn_ins_tab_cnt)          := ir_xxwip_delivery_distance_if.code_division;          -- �R�[�h�敪
    shipping_address_code_ins_tab(gn_ins_tab_cnt)  := ir_xxwip_delivery_distance_if.shipping_address_code;  -- �z����R�[�h
    start_date_active_ins_tab(gn_ins_tab_cnt)      := ir_xxwip_delivery_distance_if.start_date_active;      -- �K�p�J�n��
    post_distance_ins_tab(gn_ins_tab_cnt)          := ir_xxwip_delivery_distance_if.post_distance;          -- �ԗ�����
    small_distance_ins_tab(gn_ins_tab_cnt)         := ir_xxwip_delivery_distance_if.small_distance;         -- ��������
    consolid_add_dist_ins_tab(gn_ins_tab_cnt)      := ir_xxwip_delivery_distance_if.consolid_add_distance;  -- ���ڊ�������
    actual_distance_ins_tab(gn_ins_tab_cnt)        := ir_xxwip_delivery_distance_if.actual_distance;        -- ���ۋ���
    area_a_ins_tab(gn_ins_tab_cnt)                 := ir_xxwip_delivery_distance_if.area_a;                 -- �G���AA
    area_b_ins_tab(gn_ins_tab_cnt)                 := ir_xxwip_delivery_distance_if.area_b;                 -- �G���AB
    area_c_ins_tab(gn_ins_tab_cnt)                 := ir_xxwip_delivery_distance_if.area_c;                 -- �G���AC
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
  END set_ins_tab;
--
  /**********************************************************************************
   * Procedure Name   : set_upd_tab
   * Description      : �X�V�pPL/SQL�\����(D-9)
   ***********************************************************************************/
  PROCEDURE set_upd_tab(
    ir_xxwip_delivery_distance_if IN  xxwip_delivery_distance_if%ROWTYPE,  -- 1.xxwip_delivery_distance_if���R�[�h�^
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'set_upd_tab'; -- �v���O������
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
    -- ===============================
    -- �X�V�pPL/SQL�\�ɃZ�b�g
    -- ===============================
    -- �X�V�p�����J�E���g
    gn_upd_tab_cnt := gn_upd_tab_cnt + 1;
--
    -- �l�Z�b�g
    goods_classe_upd_tab(gn_upd_tab_cnt)           := ir_xxwip_delivery_distance_if.goods_classe;           -- ���i�敪
    delivery_company_code_upd_tab(gn_upd_tab_cnt) := ir_xxwip_delivery_distance_if.delivery_company_code;  -- �^���Ǝ҃R�[�h
    origin_shipment_upd_tab(gn_upd_tab_cnt)        := ir_xxwip_delivery_distance_if.origin_shipment;        -- �o�Ɍ�
    code_division_upd_tab(gn_upd_tab_cnt)          := ir_xxwip_delivery_distance_if.code_division;          -- �R�[�h�敪
    shipping_address_code_upd_tab(gn_upd_tab_cnt)  := ir_xxwip_delivery_distance_if.shipping_address_code;  -- �z����R�[�h
    start_date_active_upd_tab(gn_upd_tab_cnt)      := ir_xxwip_delivery_distance_if.start_date_active;      -- �K�p�J�n��
    post_distance_upd_tab(gn_upd_tab_cnt)          := ir_xxwip_delivery_distance_if.post_distance;          -- �ԗ�����
    small_distance_upd_tab(gn_upd_tab_cnt)         := ir_xxwip_delivery_distance_if.small_distance;         -- ��������
    consolid_add_dist_upd_tab(gn_upd_tab_cnt)      := ir_xxwip_delivery_distance_if.consolid_add_distance;  -- ���ڊ�������
    actual_distance_upd_tab(gn_upd_tab_cnt)        := ir_xxwip_delivery_distance_if.actual_distance;        -- ���ۋ���
    area_a_upd_tab(gn_upd_tab_cnt)                 := ir_xxwip_delivery_distance_if.area_a;                 -- �G���AA
    area_b_upd_tab(gn_upd_tab_cnt)                 := ir_xxwip_delivery_distance_if.area_b;                 -- �G���AB
    area_c_upd_tab(gn_upd_tab_cnt)                 := ir_xxwip_delivery_distance_if.area_c;                 -- �G���AC
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
  END set_upd_tab;
--
  /**********************************************************************************
   * Procedure Name   : get_ins_data
   * Description      : �o�^�f�[�^�擾����(D-5)
   ***********************************************************************************/
  PROCEDURE get_ins_data(
    it_request_id IN  xxwip_delivery_distance_if.request_id%TYPE,            -- 1.�v��ID
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_ins_data'; -- �v���O������
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
    lr_xxwip_delivery_distance_if  xxwip_delivery_distance_if%ROWTYPE; -- xxwip_delivery_distance_if���R�[�h�^
    lv_dump   VARCHAR2(5000); -- �f�[�^�_���v
--
    -- *** ���[�J���E�J�[�\�� ***
    -- �z�������A�h�I���}�X�^�C���^�t�F�[�X�o�^�J�[�\��
    CURSOR xddi_ins_cur 
    IS
      SELECT xddi.goods_classe                goods_classe                 -- ���i�敪
            ,xddi.delivery_company_code       delivery_company_code        -- �^���Ǝ҃R�[�h
            ,xddi.origin_shipment             origin_shipment              -- �o�Ɍ�
            ,xddi.area_a                      area_a                       -- �G���AA
            ,xddi.area_b                      area_b                       -- �G���AB
            ,xddi.area_c                      area_c                       -- �G���AC
            ,xddi.code_division               code_division                -- �R�[�h�敪
            ,xddi.shipping_address_code       shipping_address_code        -- �z����R�[�h
            ,xddi.start_date_active           start_date_active            -- �K�p�J�n��
            ,xddi.post_distance               post_distance                -- �ԗ�����
            ,xddi.small_distance              small_distance               -- ��������
            ,xddi.consolid_add_distance       consolid_add_distance        -- ���ڊ�������
            ,xddi.actual_distance             actual_distance              -- ���ۋ���
      FROM   xxwip_delivery_distance_if  xddi        -- �z�������A�h�I���}�X�^�C���^�t�F�[�X
      WHERE  xddi.request_id = it_request_id         -- �v��ID
      AND    NOT EXISTS(                             -- �z�������A�h�I���}�X�^�̃L�[���ڂɑ��݂��Ȃ��f�[�^
             SELECT 1
             FROM   xxwip_delivery_distance   xdd    -- �z�������A�h�I���}�X�^
             WHERE  xdd.goods_classe           = xddi.goods_classe          -- ���i�敪
             AND    xdd.delivery_company_code  = xddi.delivery_company_code -- �^���Ǝ҃R�[�h
             AND    xdd.origin_shipment        = xddi.origin_shipment       -- �o�Ɍ�
             AND    xdd.start_date_active      = xddi.start_date_active     -- �K�p�J�n��
             AND    xdd.code_division          = xddi.code_division         -- �R�[�h�敪
             AND    xdd.shipping_address_code  = xddi.shipping_address_code -- �z����R�[�h
             )
      ;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- =============================
    -- �o�^�f�[�^�擾
    -- =============================
    -- �z�������A�h�I���}�X�^�C���^�t�F�[�X�J�[�\��
    <<xddi_ins_loop>>
    FOR lr_xddi_ins IN xddi_ins_cur LOOP
      -- ���R�[�h�Ƀf�[�^�Z�b�g
      lr_xxwip_delivery_distance_if.goods_classe           := lr_xddi_ins.goods_classe;                 -- ���i�敪
      lr_xxwip_delivery_distance_if.delivery_company_code  := lr_xddi_ins.delivery_company_code;        -- �^���Ǝ҃R�[�h
      lr_xxwip_delivery_distance_if.origin_shipment        := lr_xddi_ins.origin_shipment;              -- �o�Ɍ�
      lr_xxwip_delivery_distance_if.area_a                 := lr_xddi_ins.area_a;                       -- �G���AA
      lr_xxwip_delivery_distance_if.area_b                 := lr_xddi_ins.area_b;                       -- �G���AB
      lr_xxwip_delivery_distance_if.area_c                 := lr_xddi_ins.area_c;                       -- �G���AC
      lr_xxwip_delivery_distance_if.code_division          := lr_xddi_ins.code_division;                -- �R�[�h�敪
      lr_xxwip_delivery_distance_if.shipping_address_code  := lr_xddi_ins.shipping_address_code;        -- �z����R�[�h
      lr_xxwip_delivery_distance_if.start_date_active      := lr_xddi_ins.start_date_active;            -- �K�p�J�n��
      lr_xxwip_delivery_distance_if.post_distance          := lr_xddi_ins.post_distance;                -- �ԗ�����
      lr_xxwip_delivery_distance_if.small_distance         := lr_xddi_ins.small_distance;               -- ��������
      lr_xxwip_delivery_distance_if.consolid_add_distance  := lr_xddi_ins.consolid_add_distance;        -- ���ڊ�������
      lr_xxwip_delivery_distance_if.actual_distance        := lr_xddi_ins.actual_distance;              -- ���ۋ���
--
      -- ===============================
      -- D-4.�f�[�^�_���v�擾����
      -- ===============================
      get_data_dump(
        ir_xxwip_delivery_distance_if => lr_xxwip_delivery_distance_if -- 1.xxwip_delivery_distance_if���R�[�h�^
       ,ov_dump    => lv_dump            -- 1.�f�[�^�_���v������
       ,ov_errbuf  => lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode => lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg  => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
--
      -- �G���[�̏ꍇ
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
      -- =============================
      -- D-6.�}�X�^�f�[�^�`�F�b�N����
      -- =============================
      master_data_chk(
        ir_xxwip_delivery_distance_if => lr_xxwip_delivery_distance_if   -- 1.xxwip_delivery_distance_if���R�[�h�^
       ,iv_dump                       => lv_dump                         -- 2.�f�[�^�_���v
       ,ov_errbuf  => lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode => lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg  => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
--
      -- �G���[�̏ꍇ
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
--
      -- �x���̏ꍇ
      ELSIF (lv_retcode = gv_status_warn) THEN
        -- OUT�p�����[�^���x���ɃZ�b�g
        ov_retcode := gv_status_warn;
--
        -- �X�L�b�v�����J�E���g
        gn_warn_cnt   := gn_warn_cnt + 1;
--
      -- ����̏ꍇ
      ELSE
        -- =============================
        -- D-7.�o�^�pPL/SQL�\����
        -- =============================
        set_ins_tab(
          ir_xxwip_delivery_distance_if => lr_xxwip_delivery_distance_if   -- 1.xxwip_delivery_distance_if���R�[�h�^
         ,ov_errbuf  => lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
         ,ov_retcode => lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
         ,ov_errmsg  => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
--
        -- �G���[�̏ꍇ
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_process_expt;
--
        -- ����̏ꍇ
        ELSIF (lv_retcode = gv_status_normal) THEN
          -- ����f�[�^����
          gn_normal_cnt := gn_normal_cnt + 1;
--
          -- ����f�[�^�_���vPL/SQL�\����
          normal_dump_tab(gn_normal_cnt) := lv_dump;
        END IF;
      END IF;
    END LOOP xddi_ins_loop;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      IF (xddi_ins_cur%ISOPEN) THEN
        CLOSE xddi_ins_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      IF (xddi_ins_cur%ISOPEN) THEN
        CLOSE xddi_ins_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      IF (xddi_ins_cur%ISOPEN) THEN
        CLOSE xddi_ins_cur;
      END IF;
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      IF (xddi_ins_cur%ISOPEN) THEN
        CLOSE xddi_ins_cur;
      END IF;
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_ins_data;
--
  /**********************************************************************************
   * Procedure Name   : get_upd_data
   * Description      : �X�V�f�[�^�擾����(D-8)
   ***********************************************************************************/
  PROCEDURE get_upd_data(
    it_request_id IN  xxwip_delivery_distance_if.request_id%TYPE,            -- 1.�v��ID
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_upd_data'; -- �v���O������
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
    lr_xxwip_delivery_distance_if  xxwip_delivery_distance_if%ROWTYPE; -- xxwip_delivery_distance_if���R�[�h�^
    lv_dump   VARCHAR2(5000); -- �f�[�^�_���v
--
    -- *** ���[�J���E�J�[�\�� ***
    -- �z�������A�h�I���}�X�^�C���^�t�F�[�X�o�^�J�[�\��
    CURSOR xddi_upd_cur 
    IS
      SELECT xddi.goods_classe                goods_classe                 -- ���i�敪
            ,xddi.delivery_company_code       delivery_company_code        -- �^���Ǝ҃R�[�h
            ,xddi.origin_shipment             origin_shipment              -- �o�Ɍ�
            ,xddi.area_a                      area_a                       -- �G���AA
            ,xddi.area_b                      area_b                       -- �G���AB
            ,xddi.area_c                      area_c                       -- �G���AC
            ,xddi.code_division               code_division                -- �R�[�h�敪
            ,xddi.shipping_address_code       shipping_address_code        -- �z����R�[�h
            ,xddi.start_date_active           start_date_active            -- �K�p�J�n��
            ,xddi.post_distance               post_distance                -- �ԗ�����
            ,xddi.small_distance              small_distance               -- ��������
            ,xddi.consolid_add_distance       consolid_add_distance        -- ���ڊ�������
            ,xddi.actual_distance             actual_distance              -- ���ۋ���
      FROM   xxwip_delivery_distance_if  xddi        -- �z�������A�h�I���}�X�^�C���^�t�F�[�X
      WHERE  xddi.request_id = it_request_id         -- �v��ID
      AND    EXISTS(                                 -- �z�������A�h�I���}�X�^�̃L�[���ڂɑ��݂���f�[�^
             SELECT 1
             FROM   xxwip_delivery_distance   xdd    -- �z�������A�h�I���}�X�^
             WHERE  xdd.goods_classe           = xddi.goods_classe          -- ���i�敪
             AND    xdd.delivery_company_code  = xddi.delivery_company_code -- �^���Ǝ҃R�[�h
             AND    xdd.origin_shipment        = xddi.origin_shipment       -- �o�Ɍ�
             AND    xdd.start_date_active      = xddi.start_date_active     -- �K�p�J�n��
             AND    xdd.code_division          = xddi.code_division         -- �R�[�h�敪
             AND    xdd.shipping_address_code  = xddi.shipping_address_code -- �z����R�[�h
             )
      ;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- =============================
    -- �X�V�f�[�^�擾
    -- =============================
    -- �z�������A�h�I���}�X�^�C���^�t�F�[�X�J�[�\��
    <<xddi_upd_loop>>
    FOR lr_xddi_upd IN xddi_upd_cur LOOP
      -- ���R�[�h�Ƀf�[�^�Z�b�g
      lr_xxwip_delivery_distance_if.goods_classe           := lr_xddi_upd.goods_classe;                 -- ���i�敪
      lr_xxwip_delivery_distance_if.delivery_company_code  := lr_xddi_upd.delivery_company_code;        -- �^���Ǝ҃R�[�h
      lr_xxwip_delivery_distance_if.origin_shipment        := lr_xddi_upd.origin_shipment;              -- �o�Ɍ�
      lr_xxwip_delivery_distance_if.area_a                 := lr_xddi_upd.area_a;                       -- �G���AA
      lr_xxwip_delivery_distance_if.area_b                 := lr_xddi_upd.area_b;                       -- �G���AB
      lr_xxwip_delivery_distance_if.area_c                 := lr_xddi_upd.area_c;                       -- �G���AC
      lr_xxwip_delivery_distance_if.code_division          := lr_xddi_upd.code_division;                -- �R�[�h�敪
      lr_xxwip_delivery_distance_if.shipping_address_code  := lr_xddi_upd.shipping_address_code;        -- �z����R�[�h
      lr_xxwip_delivery_distance_if.start_date_active      := lr_xddi_upd.start_date_active;            -- �K�p�J�n��
      lr_xxwip_delivery_distance_if.post_distance          := lr_xddi_upd.post_distance;                -- �ԗ�����
      lr_xxwip_delivery_distance_if.small_distance         := lr_xddi_upd.small_distance;               -- ��������
      lr_xxwip_delivery_distance_if.consolid_add_distance  := lr_xddi_upd.consolid_add_distance;        -- ���ڊ�������
      lr_xxwip_delivery_distance_if.actual_distance        := lr_xddi_upd.actual_distance;              -- ���ۋ���
--
      -- ===============================
      -- D-4.�f�[�^�_���v�擾����
      -- ===============================
      get_data_dump(
        ir_xxwip_delivery_distance_if => lr_xxwip_delivery_distance_if -- 1.xxwip_delivery_distance_if���R�[�h�^
       ,ov_dump    => lv_dump            -- 1.�f�[�^�_���v������
       ,ov_errbuf  => lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode => lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg  => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
--
      -- �G���[�̏ꍇ
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
      -- =============================
      -- D-6.�}�X�^�f�[�^�`�F�b�N����
      -- =============================
      master_data_chk(
        ir_xxwip_delivery_distance_if => lr_xxwip_delivery_distance_if   -- 1.xxwip_delivery_distance_if���R�[�h�^
       ,iv_dump                       => lv_dump                         -- 2.�f�[�^�_���v
       ,ov_errbuf  => lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode => lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg  => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
--
      -- �G���[�̏ꍇ
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
--
      -- �x���̏ꍇ
      ELSIF (lv_retcode = gv_status_warn) THEN
        -- OUT�p�����[�^�Ɍx�����Z�b�g
        ov_retcode := gv_status_warn;
--
        -- �X�L�b�v�����J�E���g
        gn_warn_cnt   := gn_warn_cnt + 1;
--
      -- ����̏ꍇ
      ELSE
        -- =============================
        -- D-9.�X�V�pPL/SQL�\����
        -- =============================
        set_upd_tab(
          ir_xxwip_delivery_distance_if => lr_xxwip_delivery_distance_if   -- 1.xxwip_delivery_distance_if���R�[�h�^
         ,ov_errbuf  => lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
         ,ov_retcode => lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
         ,ov_errmsg  => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
--
        -- �G���[�̏ꍇ
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_process_expt;
--
        -- ����̏ꍇ
        ELSIF (lv_retcode = gv_status_normal) THEN
          -- ����f�[�^����
          gn_normal_cnt := gn_normal_cnt + 1;
--
          -- ����f�[�^�_���vPL/SQL�\����
          normal_dump_tab(gn_normal_cnt) := lv_dump;
        END IF;
      END IF;
    END LOOP xddi_upd_loop;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      IF (xddi_upd_cur%ISOPEN) THEN
        CLOSE xddi_upd_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      IF (xddi_upd_cur%ISOPEN) THEN
        CLOSE xddi_upd_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      IF (xddi_upd_cur%ISOPEN) THEN
        CLOSE xddi_upd_cur;
      END IF;
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      IF (xddi_upd_cur%ISOPEN) THEN
        CLOSE xddi_upd_cur;
      END IF;
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_upd_data;
--
--
  /**********************************************************************************
   * Procedure Name   : ins_table_batch
   * Description      : �ꊇ�o�^����(D-10)
   ***********************************************************************************/
  PROCEDURE ins_table_batch(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_table_batch'; -- �v���O������
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
    -- ===============================
    -- �ꊇ�o�^����
    -- ===============================
    FORALL ln_cnt_loop IN 1 .. delivery_distance_id_ins_tab.COUNT
      INSERT INTO xxwip_delivery_distance  xdd   -- �z�������A�h�I���}�X�^
        (xdd.delivery_distance_id   -- �z������ID
        ,xdd.goods_classe           -- ���i�敪
        ,xdd.delivery_company_code  -- �^���Ǝ҃R�[�h
        ,xdd.origin_shipment        -- �o�Ɍ�
        ,xdd.code_division          -- �R�[�h�敪
        ,xdd.shipping_address_code  -- �z����R�[�h
        ,xdd.start_date_active      -- �K�p�J�n��
        ,xdd.post_distance          -- �ԗ�����
        ,xdd.small_distance         -- ��������
        ,xdd.consolid_add_distance  -- ���ڊ�������
        ,xdd.actual_distance        -- ���ۋ���
        ,xdd.area_a                 -- �G���AA
        ,xdd.area_b                 -- �G���AB
        ,xdd.area_c                 -- �G���AC
        ,xdd.created_by             -- �쐬��
        ,xdd.creation_date          -- �쐬��
        ,xdd.last_updated_by        -- �ŏI�X�V��
        ,xdd.last_update_date       -- �ŏI�X�V��
        ,xdd.last_update_login      -- �ŏI�X�V���O�C��
        ,xdd.request_id             -- �v��ID
        ,xdd.program_application_id -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
        ,xdd.program_id             -- �R���J�����g�E�v���O����ID
        ,xdd.program_update_date    -- �v���O�����X�V��
        )
      VALUES
        (delivery_distance_id_ins_tab(ln_cnt_loop)    -- �z������ID
        ,goods_classe_ins_tab(ln_cnt_loop)            -- ���i�敪
        ,delivery_company_code_ins_tab(ln_cnt_loop)  -- �^���Ǝ҃R�[�h
        ,origin_shipment_ins_tab(ln_cnt_loop)         -- �o�Ɍ�
        ,code_division_ins_tab(ln_cnt_loop)           -- �R�[�h�敪
        ,shipping_address_code_ins_tab(ln_cnt_loop)   -- �z����R�[�h
        ,start_date_active_ins_tab(ln_cnt_loop)       -- �K�p�J�n��
        ,NVL(post_distance_ins_tab(ln_cnt_loop),0)    -- �ԗ�����
        ,NVL(small_distance_ins_tab(ln_cnt_loop),0)   -- ��������
        ,NVL(consolid_add_dist_ins_tab(ln_cnt_loop),0)-- ���ڊ�������
        ,NVL(actual_distance_ins_tab(ln_cnt_loop),0)  -- ���ۋ���
        ,area_a_ins_tab(ln_cnt_loop)                  -- �G���AA
        ,area_b_ins_tab(ln_cnt_loop)                  -- �G���AB
        ,area_c_ins_tab(ln_cnt_loop)                  -- �G���AC
        ,FND_GLOBAL.USER_ID                           -- �쐬��
        ,SYSDATE                                      -- �쐬��
        ,FND_GLOBAL.USER_ID                           -- �ŏI�X�V��
        ,SYSDATE                                      -- �ŏI�X�V��
        ,FND_GLOBAL.LOGIN_ID                          -- �ŏI�X�V���O�C��
        ,FND_GLOBAL.CONC_REQUEST_ID                   -- �v��ID
        ,FND_GLOBAL.PROG_APPL_ID                      -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
        ,FND_GLOBAL.CONC_PROGRAM_ID                   -- �R���J�����g�E�v���O����ID
        ,SYSDATE                                      -- �v���O�����X�V��
        );
--
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
  END ins_table_batch;
--
  /**********************************************************************************
   * Procedure Name   : upd_table_batch
   * Description      : �ꊇ�X�V����(D-11)
   ***********************************************************************************/
  PROCEDURE upd_table_batch(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_table_batch'; -- �v���O������
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
    -- ===============================
    -- �ꊇ�X�V����
    -- ===============================
    <<upd_table_batch_loop>>
    FORALL ln_cnt_loop IN 1 .. delivery_company_code_upd_tab.COUNT
      UPDATE xxwip_delivery_distance  xdd   -- �z�������A�h�I���}�X�^
      SET    xdd.post_distance          = NVL(post_distance_upd_tab(ln_cnt_loop),0)    -- �ԗ�����
            ,xdd.small_distance         = NVL(small_distance_upd_tab(ln_cnt_loop),0)   -- ��������
            ,xdd.consolid_add_distance  = NVL(consolid_add_dist_upd_tab(ln_cnt_loop),0)-- ���ڊ�������
            ,xdd.actual_distance        = NVL(actual_distance_upd_tab(ln_cnt_loop),0)  -- ���ۋ���
            ,xdd.area_a                 = area_a_upd_tab(ln_cnt_loop)                  -- �G���AA
            ,xdd.area_b                 = area_b_upd_tab(ln_cnt_loop)                  -- �G���AB
            ,xdd.area_c                 = area_c_upd_tab(ln_cnt_loop)                  -- �G���AC
            ,xdd.last_updated_by        = FND_GLOBAL.USER_ID                           -- �ŏI�X�V��
            ,xdd.last_update_date       = SYSDATE                                      -- �ŏI�X�V��
            ,xdd.last_update_login      = FND_GLOBAL.LOGIN_ID                          -- �ŏI�X�V���O�C��
            ,xdd.request_id             = FND_GLOBAL.CONC_REQUEST_ID                   -- �v��ID
            ,xdd.program_application_id = FND_GLOBAL.PROG_APPL_ID                      -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
            ,xdd.program_id             = FND_GLOBAL.CONC_PROGRAM_ID                   -- �R���J�����g�E�v���O����ID
            ,xdd.program_update_date    = SYSDATE                                      -- �v���O�����X�V��
      WHERE xdd.goods_classe            = goods_classe_upd_tab(ln_cnt_loop)            -- ���i�敪
      AND   xdd.delivery_company_code   = delivery_company_code_upd_tab(ln_cnt_loop)  -- �^���Ǝ҃R�[�h
      AND   xdd.origin_shipment         = origin_shipment_upd_tab(ln_cnt_loop)         -- �o�Ɍ�
      AND   xdd.code_division           = code_division_upd_tab(ln_cnt_loop)           -- �R�[�h�敪
      AND   xdd.shipping_address_code   = shipping_address_code_upd_tab(ln_cnt_loop)   -- �z����R�[�h
      AND   xdd.start_date_active       = start_date_active_upd_tab(ln_cnt_loop)       -- �K�p�J�n��
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
  END upd_table_batch;
--
  /************************************************************************
   * Procedure Name  : update_end_date_active_all
   * Description     : �K�p�I�����X�V����(D-12)
   ************************************************************************/
  PROCEDURE update_end_date_active_all(
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
    cv_prg_name   CONSTANT VARCHAR2(100) := 'update_end_date_active_all'; -- �v���O������
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
    cv_xxcmn_max_date          VARCHAR2(50) := 'XXCMN_MAX_DATE';           -- �v���t�@�C���I�v�V�����FMAX���t
    cv_xxcmn_max_date_name     VARCHAR2(50) := 'XXCMN:MAX���t';            -- �v���t�@�C���I�v�V�����FMAX���t
    cv_xxwip_delivery_distance VARCHAR2(50) := 'XXWIP_DELIVERY_DISTANCE';  -- �z�������A�h�I���}�X�^
--
    -- *** ���[�J���ϐ� ***

    lt_max_date                     fnd_profile_option_values.profile_option_value%TYPE;  -- MAX���t
    ld_max_date                     DATE;
    ln_count                        NUMBER DEFAULT 0;
--
    -- ��r�p�ϐ�
    lt_temp_goods_classe           xxwip_delivery_distance.goods_classe         %TYPE; -- ���i�敪
    lt_temp_delivery_company_code  xxwip_delivery_distance.delivery_company_code%TYPE; -- �^���Ǝ҃R�[�h
    lt_temp_origin_shipment        xxwip_delivery_distance.origin_shipment      %TYPE; -- �o�Ɍ�
    lt_temp_code_division          xxwip_delivery_distance.code_division        %TYPE; -- �R�[�h�敪
    lt_temp_shipping_address_code  xxwip_delivery_distance.shipping_address_code%TYPE; -- �z����R�[�h
    lt_temp_start_date_active      xxwip_delivery_distance.start_date_active    %TYPE; -- �K�p�J�n��
    lt_temp_end_date_active        xxwip_delivery_distance.end_date_active      %TYPE; -- �K�p�I����
--
    -- �X�V�pPL/SQL�\�^
    goods_classe_tab           goods_classe_ttype;          -- ���i�敪
    delivery_company_code_tab  delivery_company_code_ttype; -- �^���Ǝ҃R�[�h
    origin_shipment_tab        origin_shipment_ttype;       -- �o�Ɍ�
    code_division_tab          code_division_ttype;         -- �R�[�h�敪
    shipping_address_code_tab  shipping_address_code_ttype; -- �z����R�[�h
    start_date_active_tab      start_date_active_ttype;     -- �K�p�J�n��
    end_date_active_tab        end_date_active_ttype;       -- �K�p�I����
--
    -- *** ���[�J���E�J�[�\�� ***
    -- �z�������A�h�I���}�X�^�J�[�\��
    CURSOR xxwip_delivery_distance_cur
    IS
      SELECT xdd.goods_classe          goods_classe          -- ���i�敪
            ,xdd.delivery_company_code delivery_company_code -- �^���Ǝ҃R�[�h
            ,xdd.origin_shipment       origin_shipment       -- �o�Ɍ�
            ,xdd.code_division         code_division         -- �R�[�h�敪
            ,xdd.shipping_address_code shipping_address_code -- �z����R�[�h
            ,xdd.start_date_active     start_date_active     -- �K�p�J�n��
            ,xdd.end_date_active       end_date_active       -- �K�p�I����
      FROM   xxwip_delivery_distance  xdd
      ORDER BY
             goods_classe          -- ���i�敪
            ,delivery_company_code -- �^���Ǝ҃R�[�h
            ,origin_shipment       -- �o�Ɍ�
            ,code_division         -- �R�[�h�敪
            ,shipping_address_code -- �z����R�[�h
            ,start_date_active     -- �K�p�J�n��
      ;
--
    xxwip_delivery_distance_rec  xxwip_delivery_distance_cur%ROWTYPE;
--
  BEGIN
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ====================================
    -- MAX���t�擾
    -- ====================================
    lt_max_date := FND_PROFILE.VALUE(cv_xxcmn_max_date);
--
    -- �擾�ł��Ȃ������ꍇ�̓G���[
    IF (lt_max_date IS NULL) THEN
      -- �G���[���b�Z�[�W�擾
      lv_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg(
                    gv_xxcmn               -- ���W���[�������́FXXCMN ����
                   ,gv_msg_xxcmn10002      -- ���b�Z�[�W�FAPP-XXCMN-10002 �v���t�@�C���擾�G���[
                   ,gv_tkn_ng_profile      -- �g�[�N���FNG�v���t�@�C����
                   ,cv_xxcmn_max_date_name -- MAX���t
                   ),1,5000);
--
      RAISE global_process_expt;
    END IF;
    -- ���t�^�ɕϊ�
    ld_max_date := FND_DATE.STRING_TO_DATE( lt_max_date, 'YYYY/MM/DD' );
--
    -- ====================================
    -- �z�������A�h�I���}�X�^�J�[�\��OPEN
    -- ====================================
    OPEN xxwip_delivery_distance_cur;
    FETCH xxwip_delivery_distance_cur INTO xxwip_delivery_distance_rec;
--
    -- �f�[�^�����݂���ꍇ�͏������s��
    IF ( xxwip_delivery_distance_cur%FOUND ) THEN
--
      -- ====================================
      -- �l��TEMP�ϐ��ɃZ�b�g
      -- ====================================
      lt_temp_goods_classe          := xxwip_delivery_distance_rec.goods_classe;           -- ���i�敪
      lt_temp_delivery_company_code := xxwip_delivery_distance_rec.delivery_company_code;  -- �^���Ǝ҃R�[�h
      lt_temp_origin_shipment       := xxwip_delivery_distance_rec.origin_shipment;        -- �o�Ɍ�
      lt_temp_code_division         := xxwip_delivery_distance_rec.code_division;          -- �R�[�h�敪
      lt_temp_shipping_address_code := xxwip_delivery_distance_rec.shipping_address_code;  -- �z����R�[�h
      lt_temp_start_date_active     := xxwip_delivery_distance_rec.start_date_active;      -- �K�p�J�n��
      lt_temp_end_date_active       := xxwip_delivery_distance_rec.end_date_active;        -- �K�p�I����
--
      <<xxwip_delivery_distance_loop>>
      LOOP
        FETCH xxwip_delivery_distance_cur INTO xxwip_delivery_distance_rec;
        EXIT WHEN xxwip_delivery_distance_cur%NOTFOUND;
--
        -- ====================================
        -- �K�p�I�����Z�b�g
        -- ====================================
        -- �L�[�u���C�N��
        IF (lt_temp_goods_classe          <> xxwip_delivery_distance_rec.goods_classe)           -- ���i�敪
        OR (lt_temp_delivery_company_code <> xxwip_delivery_distance_rec.delivery_company_code)  -- �^���Ǝ҃R�[�h
        OR (lt_temp_origin_shipment       <> xxwip_delivery_distance_rec.origin_shipment)        -- �o�Ɍ�
        OR (lt_temp_code_division         <> xxwip_delivery_distance_rec.code_division)          -- �R�[�h�敪
        OR (lt_temp_shipping_address_code <> xxwip_delivery_distance_rec.shipping_address_code)  -- �z����R�[�h
        THEN
          -- �������K�p�I�����łȂ��ꍇ
          IF ((lt_temp_end_date_active IS NULL)
          OR  (lt_temp_end_date_active <> ld_max_date))
          THEN
            -- MAX���t��O���R�[�h�̓K�p�I�����ɃZ�b�g
            ln_count := ln_count + 1;
            goods_classe_tab(ln_count)          := lt_temp_goods_classe;          -- ���i�敪
            delivery_company_code_tab(ln_count) := lt_temp_delivery_company_code; -- �^���Ǝ҃R�[�h
            origin_shipment_tab(ln_count)       := lt_temp_origin_shipment;       -- �o�Ɍ�
            code_division_tab(ln_count)         := lt_temp_code_division;         -- �R�[�h�敪
            shipping_address_code_tab(ln_count) := lt_temp_shipping_address_code; -- �z����R�[�h
            start_date_active_tab(ln_count)     := lt_temp_start_date_active;     -- �K�p�J�n��
            end_date_active_tab(ln_count)       := ld_max_date;                   -- �K�p�I����
--
          END IF;
--
        -- �L�[���u���C�N���Ă��Ȃ��ꍇ
        ELSE
          IF ((lt_temp_end_date_active IS NULL)
          OR  (lt_temp_end_date_active <> xxwip_delivery_distance_rec.start_date_active - 1))
          THEN
            -- �����R�[�h�̓K�p�J�n���|1����O���R�[�h�̓K�p�I�����ɃZ�b�g
            ln_count := ln_count + 1;
            goods_classe_tab(ln_count)          := lt_temp_goods_classe;          -- ���i�敪
            delivery_company_code_tab(ln_count) := lt_temp_delivery_company_code; -- �^���Ǝ҃R�[�h
            origin_shipment_tab(ln_count)       := lt_temp_origin_shipment;       -- �o�Ɍ�
            code_division_tab(ln_count)         := lt_temp_code_division;         -- �R�[�h�敪
            shipping_address_code_tab(ln_count) := lt_temp_shipping_address_code; -- �z����R�[�h
            start_date_active_tab(ln_count)     := lt_temp_start_date_active;     -- �K�p�J�n��
            end_date_active_tab(ln_count)       := xxwip_delivery_distance_rec.start_date_active - 1 ;-- �K�p�I����
--
          END IF;
        END IF;
--
        -- ====================================
        -- �l��TEMP�ϐ��ɃZ�b�g
        -- ====================================
        lt_temp_goods_classe          := xxwip_delivery_distance_rec.goods_classe;           -- ���i�敪
        lt_temp_delivery_company_code := xxwip_delivery_distance_rec.delivery_company_code;  -- �^���Ǝ҃R�[�h
        lt_temp_origin_shipment       := xxwip_delivery_distance_rec.origin_shipment;        -- �o�Ɍ�
        lt_temp_code_division         := xxwip_delivery_distance_rec.code_division;          -- �R�[�h�敪
        lt_temp_shipping_address_code := xxwip_delivery_distance_rec.shipping_address_code;  -- �z����R�[�h
        lt_temp_start_date_active     := xxwip_delivery_distance_rec.start_date_active;      -- �K�p�J�n��
        lt_temp_end_date_active       := xxwip_delivery_distance_rec.end_date_active;        -- �K�p�I����
--
      END LOOP xxwip_delivery_distance_loop;
    END IF;
--
    -- �J�[�\���N���[�Y
    IF (xxwip_delivery_distance_cur%ISOPEN) THEN
      CLOSE xxwip_delivery_distance_cur;
    END IF;
--
    -- ====================================
    -- �ŏI���R�[�h�̓K�p�I�����Z�b�g
    -- ====================================
    -- �������K�p�I�����łȂ��ꍇ
    IF ((lt_temp_end_date_active IS NULL)
    OR  (lt_temp_end_date_active <> ld_max_date))
    THEN
      -- �ŏI���R�[�h��MAX���t��ݒ�
      ln_count := ln_count + 1;
      goods_classe_tab(ln_count)          := lt_temp_goods_classe;          -- ���i�敪
      delivery_company_code_tab(ln_count) := lt_temp_delivery_company_code; -- �^���Ǝ҃R�[�h
      origin_shipment_tab(ln_count)       := lt_temp_origin_shipment;       -- �o�Ɍ�
      code_division_tab(ln_count)         := lt_temp_code_division;         -- �R�[�h�敪
      shipping_address_code_tab(ln_count) := lt_temp_shipping_address_code; -- �z����R�[�h
      start_date_active_tab(ln_count)     := lt_temp_start_date_active;     -- �K�p�J�n��
      end_date_active_tab(ln_count)       := ld_max_date;                   -- �K�p�I����
--
    END IF;
--
    -- ===============================
    -- �ꊇ�X�V����
    -- ===============================
    FORALL ln_cnt_loop IN 1 .. delivery_company_code_tab.COUNT
      UPDATE xxwip_delivery_distance  xdd   -- �z�������A�h�I���}�X�^
      SET    xdd.end_date_active        = end_date_active_tab(ln_cnt_loop)      -- �K�p�I����
            ,xdd.last_updated_by        = FND_GLOBAL.USER_ID                    -- �ŏI�X�V��
            ,xdd.last_update_date       = SYSDATE                               -- �ŏI�X�V��
            ,xdd.last_update_login      = FND_GLOBAL.LOGIN_ID                   -- �ŏI�X�V���O�C��
            ,xdd.request_id             = FND_GLOBAL.CONC_REQUEST_ID            -- �v��ID
            ,xdd.program_application_id = FND_GLOBAL.PROG_APPL_ID               -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
            ,xdd.program_id             = FND_GLOBAL.CONC_PROGRAM_ID            -- �R���J�����g�E�v���O����ID
            ,xdd.program_update_date    = SYSDATE                               -- �v���O�����X�V��
      WHERE xdd.goods_classe            = goods_classe_tab(ln_cnt_loop)         -- ���i�敪
      AND   xdd.delivery_company_code   = delivery_company_code_tab(ln_cnt_loop)-- �^���Ǝ҃R�[�h
      AND   xdd.origin_shipment         = origin_shipment_tab(ln_cnt_loop)      -- �o�Ɍ�
      AND   xdd.code_division           = code_division_tab(ln_cnt_loop)        -- �R�[�h�敪
      AND   xdd.shipping_address_code   = shipping_address_code_tab(ln_cnt_loop)-- �z����R�[�h
      AND   xdd.start_date_active       = start_date_active_tab(ln_cnt_loop)    -- �K�p�J�n��
      ;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ###################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      IF (xxwip_delivery_distance_cur%ISOPEN) THEN
        CLOSE xxwip_delivery_distance_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      IF (xxwip_delivery_distance_cur%ISOPEN) THEN
        CLOSE xxwip_delivery_distance_cur;
      END IF;
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      IF (xxwip_delivery_distance_cur%ISOPEN) THEN
        CLOSE xxwip_delivery_distance_cur;
      END IF;
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--####################################  �Œ蕔 END   ##########################################
  END update_end_date_active_all;
--
--
  /**********************************************************************************
   * Procedure Name   : del_table_data
   * Description      : �f�[�^�폜����(D-13)
   ***********************************************************************************/
  PROCEDURE del_table_data(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'del_table_data'; -- �v���O������
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
    -- ===============================
    -- �z�������A�h�I���}�X�^�C���^�t�F�[�X�폜
    -- ===============================
    FORALL ln_count IN 1..request_id_tab.COUNT
      DELETE xxwip_delivery_distance_if xddi             -- �z�������A�h�I���}�X�^�C���^�t�F�[�X
      WHERE  xddi.request_id = request_id_tab(ln_count)  -- �v��ID
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
  END del_table_data;
--
--
  /**********************************************************************************
   * Procedure Name   : put_dump_msg
   * Description      : �f�[�^�_���v�ꊇ�o�͏���(D-14)
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
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_sep_msg);
--
    -- �����f�[�^�i���o���j
    lv_msg  := SUBSTRB(xxcmn_common_pkg.get_msg(
                 gv_xxcmn               -- ���W���[�������́FXXCMN ����
                ,gv_msg_xxcmn00005      -- ���b�Z�[�W�FAPP-XXCMN-00005 �����f�[�^�i���o���j
                ),1,5000);
--
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_msg);
--
    -- ����f�[�^�_���v
    <<normal_dump_loop>>
    FOR ln_cnt_loop IN 1 .. normal_dump_tab.COUNT
    LOOP
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,normal_dump_tab(ln_cnt_loop));
    END LOOP normal_dump_loop;
--
    --��؂蕶����o��
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_sep_msg);
--
    -- �X�L�b�v�f�[�^�f�[�^�i���o���j
    lv_msg  := SUBSTRB(xxcmn_common_pkg.get_msg(
                 gv_xxcmn               -- ���W���[�������́FXXCMN ����
                ,gv_msg_xxcmn00007      -- ���b�Z�[�W�FAPP-XXCMN-00007 �X�L�b�v�f�[�^�i���o���j
                ),1,5000);
--
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_msg);
--
    -- �x���f�[�^�_���v
    <<warn_dump_loop>>
    FOR ln_cnt_loop IN 1 .. warn_dump_tab.COUNT
    LOOP
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,warn_dump_tab(ln_cnt_loop));
    END LOOP warn_dump_loop;
--
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
    ln_request_count NUMBER;    -- �v��ID�J�E���g
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
    -- �v��ID�J�[�\��
    CURSOR xddi_request_id_cur
    IS
      SELECT fcr.request_id request_id
      FROM   fnd_concurrent_requests fcr   -- �R���J�����g�v��ID�e�[�u��
      WHERE  EXISTS (
               SELECT 1
               FROM   xxwip_delivery_distance_if xddi   -- �z�������A�h�I���}�X�^�C���^�t�F�[�X
               WHERE  xddi.request_id = fcr.request_id  -- �v��ID
               AND    ROWNUM          = 1
             )
      ORDER BY request_id
    ;
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
    -- ===============================
    -- D-1.�v��ID�擾����
    -- ===============================
    <<get_request_id_loop>>
    FOR lr_xddi_request_id IN xddi_request_id_cur
    LOOP
      gn_request_id_cnt := gn_request_id_cnt + 1 ;
      request_id_tab(gn_request_id_cnt) := lr_xddi_request_id.request_id;
    END LOOP get_request_id_loop;
--
    -- ===============================
    -- D-2.���b�N�擾����
    -- ===============================
    get_lock(
      ov_errbuf     => lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode    => lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg     => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    -- �G���[�̏ꍇ
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- �擾�����v��ID������LOOP
    -- ===============================
    <<process_loop>>
    FOR ln_count IN 1..request_id_tab.COUNT
    LOOP
      -- �ϐ�������
      -- �o�^�p�E�X�V�pPL/SQL�\�J�E���g
      gn_ins_tab_cnt := 0;
      gn_upd_tab_cnt := 0;
--
      -- �o�^�pPL/SQL�\
      delivery_distance_id_ins_tab.DELETE;  -- �z������ID
      goods_classe_ins_tab.DELETE;          -- ���i�敪
      delivery_company_code_ins_tab.DELETE;-- �^���Ǝ҃R�[�h
      origin_shipment_ins_tab.DELETE;       -- �o�Ɍ�
      code_division_ins_tab.DELETE;         -- �R�[�h�敪
      shipping_address_code_ins_tab.DELETE; -- �z����R�[�h
      start_date_active_ins_tab.DELETE;     -- �K�p�J�n��
      post_distance_ins_tab.DELETE;         -- �ԗ�����
      small_distance_ins_tab.DELETE;        -- ��������
      consolid_add_dist_ins_tab.DELETE;     -- ���ڊ�������
      actual_distance_ins_tab.DELETE;       -- ���ۋ���
      area_a_ins_tab.DELETE;                -- �G���AA
      area_b_ins_tab.DELETE;                -- �G���AB
      area_c_ins_tab.DELETE;                -- �G���AC
--
      -- �X�V�pPL/SQL�\
      delivery_distance_id_upd_tab.DELETE;  -- �z������ID
      goods_classe_upd_tab.DELETE;          -- ���i�敪
      delivery_company_code_upd_tab.DELETE;-- �^���Ǝ҃R�[�h
      origin_shipment_upd_tab.DELETE;       -- �o�Ɍ�
      code_division_upd_tab.DELETE;         -- �R�[�h�敪
      shipping_address_code_upd_tab.DELETE; -- �z����R�[�h
      start_date_active_upd_tab.DELETE;     -- �K�p�J�n��
      post_distance_upd_tab.DELETE;         -- �ԗ�����
      small_distance_upd_tab.DELETE;        -- ��������
      consolid_add_dist_upd_tab.DELETE;     -- ���ڊ�������
      actual_distance_upd_tab.DELETE;       -- ���ۋ���
      area_a_upd_tab.DELETE;                -- �G���AA
      area_b_upd_tab.DELETE;                -- �G���AB
      area_c_upd_tab.DELETE;                -- �G���AC
--
      -- ===============================
      -- D-3.�d���f�[�^���O����
      -- ===============================
      del_duplication_data(
        it_request_id => request_id_tab(ln_count)    -- 1.�v��ID
       ,ov_errbuf     => lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode    => lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg     => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
--
      -- �G���[�̏ꍇ
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
--
      -- �x���̏ꍇ
      ELSIF (lv_retcode = gv_status_warn) THEN
        ov_retcode := gv_status_warn;
      END IF;
--
      -- ===============================
      -- D-5.�o�^�f�[�^�擾����
      -- ===============================
      get_ins_data(
        it_request_id => request_id_tab(ln_count)    -- 1.�v��ID
       ,ov_errbuf     => lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode    => lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg     => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      -- �G���[�̏ꍇ
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
--
      -- �x���̏ꍇ
      ELSIF (lv_retcode = gv_status_warn) THEN
        ov_retcode := gv_status_warn;
      END IF;
--
      -- ===============================
      -- D-8.�X�V�f�[�^�擾����
      -- ===============================
      get_upd_data(
        it_request_id => request_id_tab(ln_count)    -- 1.�v��ID
       ,ov_errbuf     => lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode    => lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg     => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      -- �G���[�̏ꍇ
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
--
      -- �x���̏ꍇ
      ELSIF (lv_retcode = gv_status_warn) THEN
        ov_retcode := gv_status_warn;
      END IF;
--
      -- ===============================
      -- D-10.�ꊇ�o�^����
      -- ===============================
      ins_table_batch(
        ov_errbuf     => lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode    => lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg     => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
--
      -- �G���[�̏ꍇ
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
      -- ===============================
      -- D-11.�ꊇ�X�V����
      -- ===============================
      upd_table_batch(
        ov_errbuf     => lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode    => lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg     => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
--
      -- �G���[�̏ꍇ
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
    END LOOP process_loop;
--
    -- ===============================
    -- D-12.�K�p�I�����X�V����
    -- ===============================
    update_end_date_active_all(
      ov_errbuf     => lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode    => lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg     => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    -- �G���[�̏ꍇ
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- D-13.�f�[�^�폜����
    -- ===============================
    del_table_data(
      ov_errbuf     => lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode    => lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg     => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    -- �G���[�̏ꍇ
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- D-14.�f�[�^�_���v�ꊇ�o�͏���
    -- ===============================
    put_dump_msg(
      ov_errbuf     => lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode    => lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg     => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    -- �G���[�̏ꍇ
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ###################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      IF (xddi_request_id_cur%ISOPEN) THEN
        CLOSE xddi_request_id_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      IF (xddi_request_id_cur%ISOPEN) THEN
        CLOSE xddi_request_id_cur;
      END IF;
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      IF (xddi_request_id_cur%ISOPEN) THEN
        CLOSE xddi_request_id_cur;
      END IF;
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
      lv_errmsg);  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    -- D-15.���^�[���E�R�[�h�̃Z�b�g�A�I������
    -- ==================================
    --��؂蕶����o��
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_sep_msg);
--
    --���������o��
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00009','CNT',TO_CHAR(gn_normal_cnt));
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
END xxwip720001c;
/
