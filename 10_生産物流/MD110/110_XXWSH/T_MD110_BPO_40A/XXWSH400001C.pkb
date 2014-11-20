CREATE OR REPLACE PACKAGE BODY xxwsh400001c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : XXWSH400001C(body)
 * Description      : ����v�悩��̃��[�t�o�׈˗������쐬
 * MD.050/070       : �o�׈˗�                              (T_MD050_BPO_400)
 *                    ����v�悩��̃��[�t�o�׈˗������쐬  (T_MD070_BPO_40A)
 * Version          : 1.12
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  pro_err_list_make      P �G���[���X�g�쐬
 *  pro_get_cus_option     P �֘A�f�[�^�擾                     (A-1)
 *  pro_param_chk          P ���̓p�����[�^�`�F�b�N             (A-2)
 *  pro_get_to_plan        P ����v���񒊏o                   (A-3)
 *  pro_ship_max_kbn       P �o�ח\���/�ő�z���敪�Z�o        (A-4)
 *  pro_lines_chk          P ���׍��ڃ`�F�b�N                   (A-5)
 *  pro_xsr_chk            P �����\���A�h�I���}�X�^���݃`�F�b�N (A-6)
 *  pro_total_we_ca        P ���v�d��/���v�e�ώZ�o              (A-7)
 *  pro_ship_y_n_chk       P �o�׉ۃ`�F�b�N                   (A-8)
 *  pro_lines_create       P �󒍖��׃A�h�I�����R�[�h����       (A-9)
 *  pro_load_eff_chk       P �ύڌ����`�F�b�N                   (A-10)
 *  pro_headers_create     P �󒍃w�b�_�A�h�I�����R�[�h����     (A-11)
 *  pro_ship_order         P �o�׈˗��o�^����                   (A-12)
 *  submain                P ���C�������v���V�[�W��
 *  main                   P �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/03/04    1.0   Tatsuya Kurata   �V�K�쐬
 *  2008/04/17    1.1   Tatsuya Kurata   �����ύX�v��#40,#42,#45�Ή�
 *  2008/04/30    1.2   Tatsuya Kurata   �����ύX�v��#65�Ή�
 *  2008/06/04    1.3   �Ŗ�  ���\       �s��C��
 *  2008/06/10    1.4   �Γn  ���a       �s��C��(�G���[���X�g�ŃX�y�[�X���߂��폜�j
 *                                       xxwsh_common910_pkg�̋A��l������C��
 *  2008/06/19    1.5   Y.Shindou        �����ύX�v��#143�Ή�
 *  2008/06/27    1.6   �Γn  ���a       �s��C��(���ד��������ATRUNC�Ή��j
 *  2008/07/04    1.7   �㌴  ���D       ST�s�#392�Ή�(�^���敪�A�����S���m�F�˗��敪�A
 *                                       �_��O�^���敪�̃f�t�H���g�l�ݒ�)
 *  2008/07/09    1.8   Oracle �R����_  I_S_192�Ή�
 *  2008/07/30    1.9   Oracle �R����_  ST�w�E28,�ۑ�No32,�ύX�v��178,T_S_476�Ή�
 *  2008/08/06    1.10  Oracle �R����_  �o�גǉ�_2
 *  2008/08/13    1.11  Oracle �ɓ��ЂƂݏo�גǉ�_1
 *  2008/08/18    1.12  Oracle �ɓ��ЂƂݏo�גǉ�_1�̃o�O �G���[�o�͏��𖾍׏��ɕύX
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
--
--################################  �Œ蕔 END   ###############################
--
  -- ==================================================
  -- ���[�U�[��`�O���[�o���^
  -- ==================================================
  -- ���͂o�i�[�p���R�[�h�ϐ�
  TYPE rec_param_data  IS RECORD 
    (
      yyyymm           VARCHAR2(6)    -- �Ώ۔N��
     ,base             VARCHAR2(4)   -- �Ǌ����_
    );
--
  -- ����v����擾�f�[�^�i�[�p���R�[�h�ϐ�
  TYPE rec_to_plan IS RECORD
    (
      for_name    mrp_forecast_designators.forecast_designator%TYPE  -- �t�H�[�L���X�g��
     ,ktn         mrp_forecast_designators.attribute3%TYPE           -- ���_
     ,for_date    mrp_forecast_dates.forecast_date%TYPE              -- ���ח\���
     ,ship_t_no   xxcmn_cust_acct_sites_v.ship_to_no%TYPE            -- �z����
     ,p_s_site    xxcmn_cust_acct_sites_v.party_site_id%TYPE         -- �z����ID
     ,par_num     xxcmn_cust_accounts_v.party_number%TYPE            -- �ڋq
     ,par_id      xxcmn_cust_accounts_v.party_id%TYPE                -- �ڋqID
     ,ship_fr     mrp_forecast_designators.attribute2%TYPE           -- �o�׌�
     ,ship_id     xxcmn_item_locations_v.inventory_location_id%TYPE  -- �o�׌�ID
     ,item_no     xxcmn_item_mst2_v.item_no%TYPE                     -- �i��
     ,item_id     xxcmn_item_mst2_v.inventory_item_id%TYPE           -- �i��ID
     ,amount      mrp_forecast_dates.original_forecast_quantity%TYPE -- ����
     ,item_um     xxcmn_item_mst2_v.item_um%TYPE                     -- �P��
     ,case_am     xxcmn_item_mst2_v.num_of_cases%TYPE                -- ����
     ,ship_am     xxcmn_item_mst2_v.num_of_deliver%TYPE              -- �o�ד���
     ,skbn        xxcmn_item_categories3_v.prod_class_code%TYPE      -- ���i�敪
     ,wei_kbn     xxcmn_item_mst2_v.weight_capacity_class%TYPE       -- �d�ʗe�ϋ敪
     ,out_kbn     xxcmn_item_mst2_v.ship_class%TYPE                  -- �o�׋敪
     ,item_kbn    xxcmn_item_categories3_v.item_class_code%TYPE      -- �i�ڋ敪
     ,sale_kbn    xxcmn_item_mst2_v.sales_div%TYPE                   -- ����Ώۋ敪
     ,end_kbn     xxcmn_item_mst2_v.obsolete_class%TYPE              -- �p�~�敪
     ,rit_kbn     xxcmn_item_mst2_v.rate_class%TYPE                  -- ���敪
     ,no_flg      xxcmn_cust_accounts_v.cust_enable_flag%TYPE        -- ���~�q�\���t���O
     ,conv_unit   xxcmn_item_mst2_v.conv_unit%TYPE                   -- ���o�Ɋ��Z�P��
     ,a_p_flg     xxcmn_item_locations_v.allow_pickup_flag%TYPE      -- �o�׈����Ώۃt���O
-- 2008/08/18 H.Itou Add Start
     ,we_loading_msg_seq NUMBER                                   -- �ύڌ���(�d��)���b�Z�[�W�i�[SEQ
     ,ca_loading_msg_seq NUMBER                                   -- �ύڌ���(�e��)���b�Z�[�W�i�[SEQ
-- 2008/08/18 H.Itou Add End
    );
  TYPE tab_data_to_plan IS TABLE OF rec_to_plan INDEX BY PLS_INTEGER;
--
  -- �G���[���b�Z�[�W�o�͗p
  TYPE rec_err_msg IS RECORD 
    (
      err_msg     VARCHAR2(10000)
    );
  TYPE tab_data_err_msg IS TABLE OF rec_err_msg INDEX BY BINARY_INTEGER;
--
  ---------------------------------------------------
  --      �󒍖��׃A�h�I���o�^�p���ڃe�[�u���^     --
  ---------------------------------------------------
  -- �󒍖��׃A�h�I��ID
  TYPE l_order_line_id               IS TABLE OF
                xxwsh_order_lines_all.order_line_id%TYPE INDEX BY BINARY_INTEGER;
  -- �󒍃w�b�_�A�h�I��ID
  TYPE l_order_header_id             IS TABLE OF
                xxwsh_order_lines_all.order_header_id%TYPE INDEX BY BINARY_INTEGER;
  -- ���הԍ�
  TYPE l_order_line_number           IS TABLE OF
                xxwsh_order_lines_all.order_line_number%TYPE INDEX BY BINARY_INTEGER;
  -- �˗�No
  TYPE l_request_no                  IS TABLE OF
                xxwsh_order_lines_all.request_no%TYPE INDEX BY BINARY_INTEGER;
  -- �o�וi��ID
  TYPE l_shipping_inv_item_id        IS TABLE OF
                xxwsh_order_lines_all.shipping_inventory_item_id%TYPE INDEX BY BINARY_INTEGER;
  -- �o�וi��
  TYPE l_shipping_item_code          IS TABLE OF
                xxwsh_order_lines_all.shipping_item_code%TYPE INDEX BY BINARY_INTEGER;
  -- ����
  TYPE l_quantity                    IS TABLE OF
                xxwsh_order_lines_all.quantity%TYPE INDEX BY BINARY_INTEGER;
  -- �P��
  TYPE l_uom_code                    IS TABLE OF
                xxwsh_order_lines_all.uom_code%TYPE INDEX BY BINARY_INTEGER;
  -- ���_�˗�����
  TYPE l_based_request_quantity      IS TABLE OF
                xxwsh_order_lines_all.based_request_quantity%TYPE INDEX BY BINARY_INTEGER;
  -- �˗��i��ID
  TYPE l_request_item_id             IS TABLE OF
                xxwsh_order_lines_all.request_item_id%TYPE INDEX BY BINARY_INTEGER;
  -- �˗��i��   
  TYPE l_request_item_code           IS TABLE OF
                xxwsh_order_lines_all.request_item_code%TYPE INDEX BY BINARY_INTEGER;
  -- �d��
  TYPE l_weight                      IS TABLE OF
                xxwsh_order_lines_all.weight%TYPE INDEX BY BINARY_INTEGER;
  -- �e��
  TYPE l_capacity                    IS TABLE OF
                xxwsh_order_lines_all.capacity%TYPE INDEX BY BINARY_INTEGER;
  -- �p���b�g�d��
  TYPE l_pallet_weight               IS TABLE OF
                xxwsh_order_lines_all.pallet_weight%TYPE INDEX BY BINARY_INTEGER;
  TYPE l_delete_flag               IS TABLE OF
                xxwsh_order_lines_all.delete_flag%TYPE INDEX BY BINARY_INTEGER;
  TYPE l_created_by                  IS TABLE OF
                xxwsh_order_lines_all.created_by%TYPE INDEX BY BINARY_INTEGER;
  TYPE l_creation_date               IS TABLE OF
                xxwsh_order_lines_all.creation_date%TYPE INDEX BY BINARY_INTEGER;
  TYPE l_last_updated_by             IS TABLE OF
                xxwsh_order_lines_all.last_updated_by%TYPE INDEX BY BINARY_INTEGER;
  TYPE l_last_update_date            IS TABLE OF
                xxwsh_order_lines_all.last_update_date%TYPE INDEX BY BINARY_INTEGER;
  TYPE l_last_update_login           IS TABLE OF
                xxwsh_order_lines_all.last_update_login%TYPE INDEX BY BINARY_INTEGER;
  TYPE l_request_id                  IS TABLE OF
                xxwsh_order_lines_all.request_id%TYPE INDEX BY BINARY_INTEGER;
  TYPE l_program_application_id      IS TABLE OF
                xxwsh_order_lines_all.program_application_id%TYPE INDEX BY BINARY_INTEGER;
  TYPE l_program_id                  IS TABLE OF
                xxwsh_order_lines_all.program_id%TYPE INDEX BY BINARY_INTEGER;
  TYPE l_program_update_date         IS TABLE OF
                xxwsh_order_lines_all.program_update_date%TYPE INDEX BY BINARY_INTEGER;
  ---------------------------------------------------
  --    �󒍃w�b�_�A�h�I���o�^�p���ڃe�[�u���^    ---
  ---------------------------------------------------
  -- �󒍃w�b�_�A�h�I��ID
  TYPE h_order_header_id             IS TABLE OF
                xxwsh_order_headers_all.order_header_id%TYPE INDEX BY BINARY_INTEGER;
  -- �󒍃^�C�vID
  TYPE h_order_type_id               IS TABLE OF
                xxwsh_order_headers_all.order_type_id%TYPE INDEX BY BINARY_INTEGER;
  -- �g�DID
  TYPE h_organization_id             IS TABLE OF
                xxwsh_order_headers_all.organization_id%TYPE INDEX BY BINARY_INTEGER;
  -- �ŐV�t���O
  TYPE h_latest_external_flag        IS TABLE OF
                xxwsh_order_headers_all.latest_external_flag%TYPE INDEX BY BINARY_INTEGER;
  -- �󒍓�
  TYPE h_ordered_date                IS TABLE OF
                xxwsh_order_headers_all.ordered_date%TYPE INDEX BY BINARY_INTEGER;
  -- �ڋqID
  TYPE h_customer_id                 IS TABLE OF
                xxwsh_order_headers_all.customer_id%TYPE INDEX BY BINARY_INTEGER;
  -- �ڋq
  TYPE h_customer_code               IS TABLE OF
                xxwsh_order_headers_all.customer_code%TYPE INDEX BY BINARY_INTEGER;
  -- �o�א�ID
  TYPE h_deliver_to_id               IS TABLE OF
                xxwsh_order_headers_all.deliver_to_id%TYPE INDEX BY BINARY_INTEGER;
  -- �o�א�
  TYPE h_deliver_to                  IS TABLE OF
                xxwsh_order_headers_all.deliver_to%TYPE INDEX BY BINARY_INTEGER;
  -- �z���敪
  TYPE h_shipping_method_code        IS TABLE OF
                xxwsh_order_headers_all.shipping_method_code%TYPE INDEX BY BINARY_INTEGER;
  -- �˗�No
  TYPE h_request_no                  IS TABLE OF
                xxwsh_order_headers_all.request_no%TYPE INDEX BY BINARY_INTEGER;
  -- �X�e�[�^�X
  TYPE h_req_status                  IS TABLE OF
                xxwsh_order_headers_all.req_status%TYPE INDEX BY BINARY_INTEGER;
  -- �o�ח\���
  TYPE h_schedule_ship_date          IS TABLE OF
                xxwsh_order_headers_all.schedule_ship_date%TYPE INDEX BY BINARY_INTEGER;
  -- ���ח\���
  TYPE h_schedule_arrival_date       IS TABLE OF
                xxwsh_order_headers_all.schedule_arrival_date%TYPE INDEX BY BINARY_INTEGER;
  -- �ʒm�X�e�[�^�X
  TYPE h_notif_status                IS TABLE OF
                xxwsh_order_headers_all.notif_status%TYPE INDEX BY BINARY_INTEGER;
  -- �o�׌�ID
  TYPE h_deliver_from_id             IS TABLE OF
                xxwsh_order_headers_all.deliver_from_id%TYPE INDEX BY BINARY_INTEGER;
  -- �o�׌��ۊǏꏊ
  TYPE h_deliver_from                IS TABLE OF
                xxwsh_order_headers_all.deliver_from%TYPE INDEX BY BINARY_INTEGER;
  -- �Ǌ����_
  TYPE h_Head_sales_branch           IS TABLE OF
                xxwsh_order_headers_all.Head_sales_branch%TYPE INDEX BY BINARY_INTEGER;
  -- ���͋��_
  TYPE h_input_sales_branch          IS TABLE OF
                xxwsh_order_headers_all.input_sales_branch%TYPE INDEX BY BINARY_INTEGER;
  -- ���i�敪
  TYPE h_prod_class                  IS TABLE OF
                xxwsh_order_headers_all.prod_class%TYPE INDEX BY BINARY_INTEGER;
  -- ���v����
  TYPE h_sum_quantity                IS TABLE OF
                xxwsh_order_headers_all.sum_quantity%TYPE INDEX BY BINARY_INTEGER;
  -- ������
  TYPE h_small_quantity              IS TABLE OF
                xxwsh_order_headers_all.small_quantity%TYPE INDEX BY BINARY_INTEGER;
  -- ���x������
  TYPE h_label_quantity              IS TABLE OF
                xxwsh_order_headers_all.label_quantity%TYPE INDEX BY BINARY_INTEGER;
  -- �d�ʐύڌ���
  TYPE h_loading_eff_weight          IS TABLE OF
                xxwsh_order_headers_all.loading_efficiency_weight%TYPE INDEX BY BINARY_INTEGER;
  -- �e�ϐύڌ���
  TYPE h_loading_eff_capacity        IS TABLE OF
                xxwsh_order_headers_all.loading_efficiency_capacity%TYPE INDEX BY BINARY_INTEGER;
  -- ��{�d��
  TYPE h_based_weight                IS TABLE OF
                xxwsh_order_headers_all.based_weight%TYPE INDEX BY BINARY_INTEGER;
  -- ��{�e��
  TYPE h_based_capacity              IS TABLE OF
                xxwsh_order_headers_all.based_capacity%TYPE INDEX BY BINARY_INTEGER;
  -- �ύڏd�ʍ��v
  TYPE h_sum_weight                  IS TABLE OF
                xxwsh_order_headers_all.sum_weight%TYPE INDEX BY BINARY_INTEGER;
  -- �ύڗe�ύ��v
  TYPE h_sum_capacity                IS TABLE OF
                xxwsh_order_headers_all.sum_capacity%TYPE INDEX BY BINARY_INTEGER;
  -- ���v�p���b�g�d��
  TYPE h_sum_pallet_weight           IS TABLE OF
                xxwsh_order_headers_all.sum_pallet_weight%TYPE INDEX BY BINARY_INTEGER;
  -- �d�ʗe�ϋ敪
  TYPE h_weight_capacity_class       IS TABLE OF
                xxwsh_order_headers_all.weight_capacity_class%TYPE INDEX BY BINARY_INTEGER;
  -- ���ьv��ϋ敪
  TYPE h_actual_confirm_class        IS TABLE OF
                xxwsh_order_headers_all.actual_confirm_class%TYPE INDEX BY BINARY_INTEGER;
  -- �V�K�C���t���O
  TYPE h_new_modify_flg              IS TABLE OF
                xxwsh_order_headers_all.new_modify_flg%TYPE INDEX BY BINARY_INTEGER;
  -- ���ъǗ�����
  TYPE h_per_management_dept         IS TABLE OF
                xxwsh_order_headers_all.performance_management_dept%TYPE INDEX BY BINARY_INTEGER;
  -- ��ʍX�V����
  TYPE h_screen_update_date          IS TABLE OF
                xxwsh_order_headers_all.screen_update_date%TYPE INDEX BY BINARY_INTEGER;
-- add start 1.7 uehara
  -- �����S���m�F�˗��敪
  TYPE h_confirm_request_class       IS TABLE OF
                xxwsh_order_headers_all.confirm_request_class%TYPE INDEX BY BINARY_INTEGER;
  -- �^���敪
  TYPE h_freight_charge_class        IS TABLE OF
                xxwsh_order_headers_all.freight_charge_class%TYPE INDEX BY BINARY_INTEGER;
  -- �_��O�^���敪
  TYPE h_no_cont_freight_class       IS TABLE OF
                xxwsh_order_headers_all.no_cont_freight_class%TYPE INDEX BY BINARY_INTEGER;
-- add end 1.7 uehara
  TYPE h_created_by                  IS TABLE OF
                xxwsh_order_headers_all.created_by%TYPE INDEX BY BINARY_INTEGER;
  TYPE h_creation_date               IS TABLE OF
                xxwsh_order_headers_all.creation_date%TYPE INDEX BY BINARY_INTEGER;
  TYPE h_last_updated_by             IS TABLE OF
                xxwsh_order_headers_all.last_updated_by%TYPE INDEX BY BINARY_INTEGER;
  TYPE h_last_update_date            IS TABLE OF 
               xxwsh_order_headers_all.last_update_date%TYPE INDEX BY BINARY_INTEGER;
  TYPE h_last_update_login           IS TABLE OF
                xxwsh_order_headers_all.last_update_login%TYPE INDEX BY BINARY_INTEGER;
  TYPE h_request_id                  IS TABLE OF
                xxwsh_order_headers_all.request_id%TYPE INDEX BY BINARY_INTEGER;
  TYPE h_program_application_id      IS TABLE OF
                xxwsh_order_headers_all.program_application_id%TYPE INDEX BY BINARY_INTEGER;
  TYPE h_program_id                  IS TABLE OF
                xxwsh_order_headers_all.program_id%TYPE INDEX BY BINARY_INTEGER;
  TYPE h_program_update_date         IS TABLE OF
                xxwsh_order_headers_all.program_update_date%TYPE INDEX BY BINARY_INTEGER;
--
--#######################  �Œ�O���[�o���ϐ��錾�� START   #######################
--
  gv_out_msg       VARCHAR2(2000);
  gv_sep_msg       VARCHAR2(2000);
  gv_exec_user     VARCHAR2(100);
  gv_conc_name     VARCHAR2(30);
  gv_conc_status   VARCHAR2(30);
  gn_target_cnt    NUMBER;
  gn_normal_cnt    NUMBER;
  gn_error_cnt     NUMBER;
  gn_warn_cnt      NUMBER;
--
--################################  �Œ蕔 END   ###############################
--
  -- ===============================
  -- ���[�U�[��`��O
  -- ===============================
  err_header_expt          EXCEPTION;               -- ���ʊ֐��G���[
--
  -- ==================================================
  -- ���[�U�[��`�O���[�o���萔
  -- ==================================================
  gv_pkg_name        CONSTANT VARCHAR2(15) := 'xxwsh400001c';          -- �p�b�P�[�W��
  -- �v���t�@�C��
  gv_prf_m_org       CONSTANT VARCHAR2(50) := 'XXCMN_MASTER_ORG_ID';   -- XXCMN:�}�X�^�g�D
  gv_prf_tran        CONSTANT VARCHAR2(50) := 'XXWSH_TRAN_TYPE_PLAN';  -- XXWSH:�o�Ɍ`��_����v��
  -- �G���[�R�[�h
  gv_application     CONSTANT VARCHAR2(5)  := 'XXWSH';                 -- �A�v���P�[�V����
  gv_err_ktn         CONSTANT VARCHAR2(20) := 'APP-XXWSH-11001';
                                                          -- �}�X�^�`�F�b�N�G���[���b�Z�[�W
  gv_err_yymm        CONSTANT VARCHAR2(20) := 'APP-XXWSH-11002';
                                                          -- �}�X�^�����G���[���b�Z�[�W
  gv_err_para        CONSTANT VARCHAR2(20) := 'APP-XXWSH-11004';
                                                          -- �K�{���͂o���ݒ�G���[���b�Z�[�W
  gv_err_pro         CONSTANT VARCHAR2(20) := 'APP-XXWSH-11005';
                                                          -- �v���t�@�C���擾�G���[���b�Z�[�W
  gv_err_ord         CONSTANT VARCHAR2(20) := 'APP-XXWSH-11006';
                                                          -- �󒍃^�C�v�擾�G���[���b�Z�[�W
  gv_err_cik         CONSTANT VARCHAR2(20) := 'APP-XXCMN-10121';
                                                          -- �N�C�b�N�R�[�h�擾�G���[���b�Z�[�W
--
  gv_tkn_msg_org     CONSTANT VARCHAR2(20) := 'XXCMN:�}�X�^�g�D';
  gv_tkn_msg_tran    CONSTANT VARCHAR2(25) := 'XXWSH:�o�Ɍ`��_����v��';
  gv_tkn_msg_yymm    CONSTANT VARCHAR2(8)  := '�Ώ۔N��';
  gv_tkn_msg_ktn     CONSTANT VARCHAR2(8)  := '�Ǌ����_';
  -- �g�[�N��
  gv_tkn_in_parm     CONSTANT VARCHAR2(10) := 'IN_PARAM';
  gv_tkn_prof_name   CONSTANT VARCHAR2(10) := 'PROF_NAME';
  gv_tkn_yymm        CONSTANT VARCHAR2(10) := 'YYMM';
  gv_tkn_kyoten      CONSTANT VARCHAR2(10) := 'KYOTEN';
  gv_tkn_order_type  CONSTANT VARCHAR2(10) := 'ORDER_TYPE';
  gv_tkn_lookup_type CONSTANT VARCHAR2(15) := 'LOOKUP_TYPE';
  gv_tkn_meaning     CONSTANT VARCHAR2(10) := 'MEANING';
  -- �G���[���b�Z�[�W���X�g����
  gv_tkn_msg_hfn     CONSTANT VARCHAR2(1)  := '-';
  gv_tkn_msg_err     CONSTANT VARCHAR2(6)  := '�G���[';
  gv_tkn_msg_war     CONSTANT VARCHAR2(4)  := '�x��';
  gv_tkn_msg_1       CONSTANT VARCHAR2(50) := '�u����Ώۋ敪�v�Ɂu1�v�ȊO���Z�b�g����Ă��܂�';
  -- 2008/07/30 Mod ��
--  gv_tkn_msg_2       CONSTANT VARCHAR2(50) := '�u�p�~�敪�v�ɁuD�v���Z�b�g����Ă��܂�';
  gv_tkn_msg_2       CONSTANT VARCHAR2(50) := '�u�p�~�敪�v�Ɂu1�v���Z�b�g����Ă��܂�';
  -- 2008/07/30 Mod ��
  gv_tkn_msg_3       CONSTANT VARCHAR2(50) := '�u���敪�v�Ɂu0�v�ȊO���Z�b�g����Ă��܂�';
  gv_tkn_msg_5       CONSTANT VARCHAR2(60) := '�u���~�q�\���t���O�v�Ɂu0�v�ȊO���Z�b�g����Ă��܂�';
  gv_tkn_msg_6       CONSTANT VARCHAR2(50) := '�ғ����`�F�b�N�G���[';
  gv_tkn_msg_7       CONSTANT VARCHAR2(50) := '���[�h�^�C���Z�o';
  gv_tkn_msg_8       CONSTANT VARCHAR2(50) := '�z�����[�h�^�C���𖞂����܂���';
  gv_tkn_msg_9       CONSTANT VARCHAR2(50) := '����ύX���[�h�^�C���𖞂����܂���';
  gv_tkn_msg_10      CONSTANT VARCHAR2(50) := '�ő�z���敪�擾�G���[';
  gv_tkn_msg_11      CONSTANT VARCHAR2(50) := '�݌ɉ�v���ԃN���[�Y�G���[';
  gv_tkn_msg_12      CONSTANT VARCHAR2(50) := '�o�׉\�i�ڂł͂���܂���(�o�׋敪���u�ہv)';
  gv_tkn_msg_13      CONSTANT VARCHAR2(50) := '�����\���Ƃ��ēo�^����Ă��܂���';
  gv_tkn_msg_14      CONSTANT VARCHAR2(50) := '�o�א�����(���i��)�G���[�F';
  gv_tkn_msg_15      CONSTANT VARCHAR2(50) := '�o�א�����(������)�G���[�F';
  gv_tkn_msg_16      CONSTANT VARCHAR2(50) := '�o�א�����(���i��)���ʃI�[�o�[�G���[';
  gv_tkn_msg_17      CONSTANT VARCHAR2(50) := '�o�א�����(������)���ʃI�[�o�[�G���[';
  gv_tkn_msg_18      CONSTANT VARCHAR2(50) := '�o�א�����(������)�o�ג�~���G���[';
  gv_tkn_msg_19      CONSTANT VARCHAR2(50) := '�u�w���ʁx���w�o�ד����x�̐����{�ł͂���܂���v';
  gv_tkn_msg_20      CONSTANT VARCHAR2(50) := '�ύڃI�[�o�[�G���[';
  gv_tkn_msg_21      CONSTANT VARCHAR2(50) := '�u�w���ʁx���w�����x�̐����{�ł͂���܂���v';
  gv_tkn_msg_22      CONSTANT VARCHAR2(50) := '�˗�No�̔ԃG���[�F';
  gv_tkn_msg_23      CONSTANT VARCHAR2(50) := '�����ΏۊO�̏o�Ɍ��q�ɂł�';
--
  -- 2008/07/30 Add ��
  gv_tkn_msg_24      CONSTANT VARCHAR2(50) := '�P�[�X������0���傫���l��ݒ肵�ĉ������B';
  -- 2008/07/30 Add ��
-- �N�C�b�N�R�[�h
  gv_ship_method     CONSTANT VARCHAR2(20) := 'XXCMN_SHIP_METHOD';
  gv_tr_status       CONSTANT VARCHAR2(25) := 'XXWSH_TRANSACTION_STATUS';
  gv_notif_status    CONSTANT VARCHAR2(20) := 'XXWSH_NOTIF_STATUS';
--
  gv_all_item        CONSTANT VARCHAR2(7)  := 'ZZZZZZZ'; -- �S�i��
--
  gv_yes             CONSTANT VARCHAR2(1)  := 'Y';
  gv_no              CONSTANT VARCHAR2(1)  := 'N';
  gv_0               CONSTANT VARCHAR2(1)  := '0';
  gv_1               CONSTANT VARCHAR2(1)  := '1';
  gv_2               CONSTANT VARCHAR2(1)  := '2';
  gv_3               CONSTANT VARCHAR2(1)  := '3';
  gv_4               CONSTANT VARCHAR2(1)  := '4';
  gv_6               CONSTANT VARCHAR2(1)  := '6';
  gv_9               CONSTANT VARCHAR2(1)  := '9';
--
  -- 2008/07/30 Mod ��
--  gv_delete          CONSTANT VARCHAR2(1)  := 'D';
  gv_delete          CONSTANT VARCHAR2(1)  := '1';
  -- 2008/07/30 Mod ��
  gv_h_plan          CONSTANT VARCHAR2(2)  := '01';
--
  gv_ship_st         CONSTANT VARCHAR2(6)  := '���͒�';
  gv_notice_st       CONSTANT VARCHAR2(6)  := '���ʒm';
  -- �G���[���X�g���ږ�
  gv_name_kind       CONSTANT VARCHAR2(4)  := '���';
  gv_name_dec        CONSTANT VARCHAR2(4)  := '�m��';
  gv_name_req_no     CONSTANT VARCHAR2(8)  := '�˗��m��';
  gv_name_kyoten     CONSTANT VARCHAR2(8)  := '�Ǌ����_';
  gv_name_item_a     CONSTANT VARCHAR2(4)  := '�i��';
  gv_name_qty        CONSTANT VARCHAR2(4)  := '����';
  gv_name_ship_date  CONSTANT VARCHAR2(6)  := '�o�ɓ�';
  gv_name_arr_date   CONSTANT VARCHAR2(4)  := '����';
  gv_name_err_msg    CONSTANT VARCHAR2(16) := '�G���[���b�Z�[�W';
  gv_name_err_clm    CONSTANT VARCHAR2(10) := '�G���[����';
  gv_line            CONSTANT VARCHAR2(25) := '-------------------------';
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gd_sysdate         DATE;              -- �V�X�e�����ݓ��t
  gd_yyyymm          DATE;              -- �Ώ۔N��
  gv_name_m_org      VARCHAR2(20);      -- �}�X�^�g�D
  gv_name_item       VARCHAR2(20);      -- ���i�敪
  gv_name_tran       VARCHAR2(20);      -- �o�Ɍ`��_����v��
  gv_name_ktn        VARCHAR2(20);      -- �Ǌ����_
  gv_err_flg         VARCHAR2(1);       -- �G���[�m�F�p�t���O
  gv_err_sts         VARCHAR2(1);       -- ���ʃG���[���b�Z�[�W �I��ST�m�F�pF
--
  gd_work_day        DATE;              -- �ғ���
  gd_ship_day        DATE;              -- �o�ח\���
  gd_past_day        DATE;              -- �ߋ���
  gv_req_no          VARCHAR2(12);      -- �̔Ԃ���No
  gv_leadtime        VARCHAR2(20);      -- ���Y����LT/����ύXLT
  gv_delivery_lt     VARCHAR2(20);      -- �z�����[�h�^�C��
  gv_max_kbn         VARCHAR2(2);       -- �ő�z���敪
  gv_opm_c_p         VARCHAR2(6);       -- OPM�݌ɉ�v���� CLOSE�ő�N��
  gv_over_kbn        VARCHAR2(1);       -- �ύڃI�[�o�[�敪
  gv_ship_way        VARCHAR2(2);       -- �o�ו��@
  gv_mix_ship        VARCHAR2(2);       -- ���ڔz���敪
  gn_drink_we        NUMBER;            -- �h�����N�ύڏd��
  gn_leaf_we         NUMBER;            -- ���[�t�ύڏd��
  gn_drink_ca        NUMBER;            -- �h�����N�ύڗe��
  gn_leaf_ca         NUMBER;            -- ���[�t�ύڗe��
  gn_prt_max         NUMBER;            -- �p���b�g�ő喇��
  gn_retrun          NUMBER;            -- �Ԃ�l
  gn_ttl_we          NUMBER;            -- ���v�d��
  gn_ttl_ca          NUMBER;            -- ���v�e��
  gn_ttl_prt_we      NUMBER;            -- ���v�p���b�g�d��
  gn_detail_we       NUMBER;            -- ���׏d��
  gn_detail_ca       NUMBER;            -- ���חe��
  gn_ship_amount     NUMBER;            -- �o�גP�ʊ��Z��
  gn_we_loading      NUMBER;            -- �d�ʐύڌ���
  gn_ca_loading      NUMBER;            -- �e�ϐύڌ���
  gn_we_dammy        NUMBER;            -- �d�ʐύڌ���(�_�~�[)
  gn_ca_dammy        NUMBER;            -- �e�ϐύڌ���(�_�~�[)
--
  gn_i               NUMBER;            -- LOOP�J�E���g�p
  gn_headers_seq     NUMBER;            -- �󒍃w�b�_�A�h�I��ID_SEQ
  gn_lines_seq       NUMBER;            -- �󒍖��׃A�h�I��ID_SEQ
--
  -- WHO�J�����擾�p
  gn_created_by      NUMBER;            -- �쐬��
  gd_creation_date   DATE;              -- �쐬��
  gd_last_upd_date   DATE;              -- �ŏI�X�V��
  gn_last_upd_by     NUMBER;            -- �ŏI�X�V��
  gn_last_upd_login  NUMBER;            -- �ŏI�X�V���O�C��
  gn_request_id      NUMBER;            -- �v��ID
  gn_prog_appl_id    NUMBER;            -- �v���O�����A�v���P�[�V����ID
  gn_prog_id         NUMBER;            -- �v���O����ID
  gd_prog_upd_date   DATE;              -- �v���O�����X�V��
--
  gv_err_report      VARCHAR2(5000);
--
  gn_cut             NUMBER DEFAULT 0;  -- �G���[���b�Z�[�W�p�J�E���g
  gn_line_number     NUMBER DEFAULT 0;  -- ���הԍ�
  gn_ttl_amount      NUMBER DEFAULT 0;  -- ���v����
  gn_ttl_ship_am     NUMBER DEFAULT 0;  -- �o�גP�ʊ��Z��
  gn_h_ttl_weight    NUMBER DEFAULT 0;  -- �ύڏd�ʍ��v
  gn_h_ttl_capa      NUMBER DEFAULT 0;  -- �ύڗe�ύ��v
  gn_h_ttl_pallet    NUMBER DEFAULT 0;  -- ���v�p���b�g�d��
--
  gn_item_cnt        NUMBER DEFAULT 0;  -- �Ώۈ���v�挏��(�i�ڒP��)
  gn_req_cnt         NUMBER DEFAULT 0;  -- �o�׈˗��쐬����(�˗��m���P��)
  gn_line_cnt        NUMBER DEFAULT 0;  -- �o�׈˗��쐬���׌���(�˗����גP��)
--
  gn_l_cnt           NUMBER DEFAULT 0;  -- �󒍖��׃A�h�I���쐬�p���R�[�h�p�J�E���g
  gn_h_cnt           NUMBER DEFAULT 0;  -- �󒍃w�b�_�A�h�I���쐬�p���R�[�h�p�J�E���g
--
  gv_odr_type        xxwsh_oe_transaction_types2_v.transaction_type_id%TYPE; -- �󒍃^�C�v�h�c
  gv_ktn             mrp_forecast_designators.attribute3%TYPE;               -- ���_
  gv_ship_fr         mrp_forecast_designators.attribute2%TYPE;               -- �o�׌�
  gv_for_date        mrp_forecast_dates.forecast_date%TYPE;                  -- ���ח\���
  gv_wei_kbn         xxcmn_item_mst2_v.weight_capacity_class%TYPE;           -- �d�ʗe�ϋ敪
  gr_ship_st         xxcmn_lookup_values2_v.lookup_code%TYPE;                -- �o�׈˗��X�e�[�^�X
  gr_notice_st       xxcmn_lookup_values2_v.lookup_code%TYPE;                -- �ʒm�X�e�[�^�X
--
  gr_param           rec_param_data;    -- ���̓p�����[�^
  gt_to_plan         tab_data_to_plan;  -- ����v����擾�f�[�^
  gt_err_msg         tab_data_err_msg;  -- �G���[���b�Z�[�W�o�͗p
--
  -- �󒍖��׃A�h�I���o�^�p����
  gt_l_order_line_id           l_order_line_id;          -- �󒍖��׃A�h�I��ID
  gt_l_order_header_id         l_order_header_id;        -- �󒍃w�b�_�A�h�I��ID
  gt_l_order_line_number       l_order_line_number;      -- ���הԍ�
  gt_l_request_no              l_request_no;             -- �˗�No
  gt_l_shipping_inv_item_id    l_shipping_inv_item_id;   -- �o�וi��ID
  gt_l_shipping_item_code      l_shipping_item_code;     -- �o�וi��
  gt_l_quantity                l_quantity;               -- ����
  gt_l_uom_code                l_uom_code;               -- �P��
  gt_l_based_request_quantity  l_based_request_quantity; -- ���_�˗�����
  gt_l_request_item_id         l_request_item_id;        -- �˗��i��ID
  gt_l_request_item_code       l_request_item_code;      -- �˗��i��
  gt_l_weight                  l_weight;                 -- �d��
  gt_l_capacity                l_capacity;               -- �e��   
  gt_l_pallet_weight           l_pallet_weight;          -- �p���b�g�d��
  gt_l_delete_flag             l_delete_flag;
  gt_l_created_by              l_created_by;
  gt_l_creation_date           l_creation_date;
  gt_l_last_updated_by         l_last_updated_by;
  gt_l_last_update_date        l_last_update_date;
  gt_l_last_update_login       l_last_update_login;
  gt_l_request_id              l_request_id;
  gt_l_program_application_id  l_program_application_id;
  gt_l_program_id              l_program_id;
  gt_l_program_update_date     l_program_update_date;
  -- �󒍃w�b�_�A�h�I���o�^�p����
  gt_h_order_header_id         h_order_header_id;        -- �󒍃w�b�_�A�h�I��ID
  gt_h_order_type_id           h_order_type_id;          -- �󒍃^�C�vID
  gt_h_organization_id         h_organization_id;        -- �g�DID
  gt_h_latest_external_flag    h_latest_external_flag;   -- �ŐV�t���O
  gt_h_ordered_date            h_ordered_date;           -- �󒍓�
  gt_h_customer_id             h_customer_id;            -- �ڋqID
  gt_h_customer_code           h_customer_code;          -- �ڋq
  gt_h_deliver_to_id           h_deliver_to_id;          -- �z����ID
  gt_h_deliver_to              h_deliver_to;             -- �z����
  gt_h_shipping_method_code    h_shipping_method_code;   -- �z���敪
  gt_h_request_no              h_request_no;             -- �˗�No
  gt_h_req_status              h_req_status;             -- �X�e�[�^�X
  gt_h_schedule_ship_date      h_schedule_ship_date;     -- �o�ח\���
  gt_h_schedule_arrival_date   h_schedule_arrival_date;  -- ���ח\���
  gt_h_notif_status            h_notif_status;           -- �ʒm�X�e�[�^�X
  gt_h_deliver_from_id         h_deliver_from_id;        -- �o�׌�ID
  gt_h_deliver_from            h_deliver_from;           -- �o�׌��ۊǏꏊ
  gt_h_Head_sales_branch       h_Head_sales_branch;      -- �Ǌ����_
  gt_h_input_sales_branch      h_input_sales_branch;     -- ���͋��_
  gt_h_prod_class              h_prod_class;             -- ���i�敪
  gt_h_sum_quantity            h_sum_quantity;           -- ���v����
  gt_h_small_quantity          h_small_quantity;         -- ������
  gt_h_label_quantity          h_label_quantity;         -- ���x������
  gt_h_loading_eff_weight      h_loading_eff_weight;     -- �d�ʐύڌ���
  gt_h_loading_eff_capacity    h_loading_eff_capacity;   -- �e�ϐύڌ���
  gt_h_based_weight            h_based_weight;           -- ��{�d��
  gt_h_based_capacity          h_based_capacity;         -- ��{�e��
  gt_h_sum_weight              h_sum_weight;             -- �ύڏd�ʍ��v
  gt_h_sum_capacity            h_sum_capacity;           -- �ύڗe�ύ��v
  gt_h_sum_pallet_weight       h_sum_pallet_weight;      -- ���v�p���b�g�d��
  gt_h_weight_capacity_class   h_weight_capacity_class;  -- �d�ʗe�ϋ敪
  gt_h_actual_confirm_class    h_actual_confirm_class ;  -- ���ьv��ϋ敪
  gt_h_new_modify_flg          h_new_modify_flg;         -- �V�K�C���t���O
  gt_h_per_management_dept     h_per_management_dept;    -- ���ъǗ�����
  gt_h_screen_update_date      h_screen_update_date;     -- ��ʍX�V����
-- add start 1.7 uehara
  gt_h_confirm_request_class   h_confirm_request_class;  -- �����S���m�F�˗��敪
  gt_h_freight_charge_class    h_freight_charge_class;   -- �^���敪
  gt_h_no_cont_freight_class   h_no_cont_freight_class;  -- �_��O�^���敪
-- add end 1.7 uehara
  gt_h_created_by              h_created_by;
  gt_h_creation_date           h_creation_date;
  gt_h_last_updated_by         h_last_updated_by;
  gt_h_last_update_date        h_last_update_date;
  gt_h_last_update_login       h_last_update_login;
  gt_h_request_id              h_request_id;
  gt_h_program_application_id  h_program_application_id;
  gt_h_program_id              h_program_id;
  gt_h_program_update_date     h_program_update_date;
--
--#####################  �Œ苤�ʗ�O�錾�� START   ####################
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
--###########################  �Œ蕔 END   ############################
--
  /**********************************************************************************
   * Procedure Name   : pro_err_list_make
   * Description      : �G���[���X�g�쐬
   ***********************************************************************************/
  PROCEDURE pro_err_list_make
    (
      iv_kind          IN VARCHAR2     --   �G���[���
     ,iv_dec           IN VARCHAR2     --   �m�菈���ł̃`�F�b�N
     ,iv_req_no        IN VARCHAR2     --   �˗�No
     ,iv_kyoten        IN VARCHAR2     --   �Ǌ����_
     ,iv_item          IN VARCHAR2     --   �i��
     ,in_qty           IN NUMBER       --   ����
     ,iv_ship_date     IN VARCHAR2     --   �o�ɓ�
     ,iv_arrival_date  IN VARCHAR2     --   ����
     ,iv_err_msg       IN VARCHAR2     --   �G���[���b�Z�[�W
     ,iv_err_clm       IN VARCHAR2     --   �G���[����
-- 2008/08/18 H.Itou Add Start
     ,in_calc_load_eff_msg_seq IN NUMBER DEFAULT NULL-- -- �ύڌ������b�Z�[�W�i�[SEQ
-- 2008/08/18 H.Itou Add End
     ,ov_errbuf       OUT VARCHAR2     --   �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode      OUT VARCHAR2     --   ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg       OUT VARCHAR2     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'pro_err_list_make'; -- �v���O������
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
    -- *** ���[�J���ϐ� ***
    lv_err_msg      VARCHAR2(5000);
    ln_qty          NUMBER;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ���ʂ�NULL�̏ꍇ�A�O�\��
    IF (in_qty IS NULL) THEN
      ln_qty := NVL(in_qty,0);
    ELSE
      ln_qty := in_qty;
    END IF;
--
    ---------------------------------
    -- ���ʃG���[���b�Z�[�W�̍쐬  --
    ---------------------------------
-- 2008/08/18 H.Itou Del Start �G���[���b�Z�[�W�i�[���O�Ɉړ�
--    -- �e�[�u���J�E���g
--    gn_cut := gn_cut + 1;
-- 2008/08/18 H.Itou Del End
--
    lv_err_msg := iv_kind         || CHR(9) || iv_dec     || CHR(9) || iv_req_no    || CHR(9) ||
                  iv_kyoten       || CHR(9) || iv_item    || CHR(9) ||
                  TO_CHAR(ln_qty,'FM999,999,990.000') || CHR(9) || iv_ship_date || CHR(9) ||
                  iv_arrival_date || CHR(9) || iv_err_msg || CHR(9) || iv_err_clm;
--
-- 2008/08/18 H.Itou Add Start
    -- �ύڌ������b�Z�[�W�i�[SEQ�ɒl������ꍇ�A�ύڌ����G���[�Ȃ̂ŁA�w��ӏ��ɃZ�b�g
    IF (in_calc_load_eff_msg_seq IS NOT NULL) THEN
      gt_err_msg(in_calc_load_eff_msg_seq).err_msg  := lv_err_msg;
--
    -- ����ȊO�́A�e�[�u���J�E���g��i�߂ăZ�b�g
    ELSE
      -- �e�[�u���J�E���g
      gn_cut := gn_cut + 1;
-- 2008/08/18 H.Itou Add End
      -- ���ʃG���[���b�Z�[�W�i�[
      gt_err_msg(gn_cut).err_msg  := lv_err_msg;
-- 2008/08/18 H.Itou Add Start
    END IF;
-- 2008/08/18 H.Itou Add End
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END pro_err_list_make;
--
  /**********************************************************************************
   * Procedure Name   : pro_get_cus_option
   * Description      : �֘A�f�[�^�擾 (A-1)
   ***********************************************************************************/
  PROCEDURE pro_get_cus_option
    (
      ov_errbuf     OUT VARCHAR2     -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode    OUT VARCHAR2     -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg     OUT VARCHAR2     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    )
  IS
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'pro_get_cus_option'; -- �v���O������
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
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- WHO�J�����擾
    gn_created_by     := FND_GLOBAL.USER_ID;           -- �쐬��
    gd_creation_date  := gd_sysdate;                   -- �쐬��
    gn_last_upd_by    := FND_GLOBAL.USER_ID;           -- �ŏI�X�V��
    gd_last_upd_date  := gd_sysdate;                   -- �ŏI�X�V��
    gn_last_upd_login := FND_GLOBAL.LOGIN_ID;          -- �ŏI�X�V���O�C��
    gn_request_id     := FND_GLOBAL.CONC_REQUEST_ID;   -- �v��ID
    gn_prog_appl_id   := FND_GLOBAL.PROG_APPL_ID;      -- �v���O�����A�v���P�[�V����ID
    gn_prog_id        := FND_GLOBAL.CONC_PROGRAM_ID;   -- �v���O����ID
    gd_prog_upd_date  := gd_sysdate;                   -- �v���O�����X�V��
--
    --------------------------------------------------
    -- �N�C�b�N�R�[�h����o�׈˗��X�e�[�^�X���擾 --
    --------------------------------------------------
    BEGIN
--
      -- �o�׈˗��X�e�[�^�X[���͒�]�R�[�h���o
      SELECT xlvv.lookup_code
      INTO   gr_ship_st
      FROM   xxcmn_lookup_values_v  xlvv  -- �N�C�b�N�R�[�h��� V
      WHERE  xlvv.lookup_type = gv_tr_status
      AND    xlvv.meaning     = gv_ship_st;
--
    EXCEPTION
      -- �N�C�b�N�R�[�h�����݂��Ȃ��ꍇ
      WHEN NO_DATA_FOUND THEN
        lv_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg( 'XXCMN'
                                                       ,gv_err_cik          -- �N�C�b�N�b�擾�G���[
                                                       ,gv_tkn_lookup_type  -- �g�[�N��
                                                       ,gv_tr_status
                                                       ,gv_tkn_meaning      -- �g�[�N��
                                                       ,gv_ship_st
                                                      )
                                                      ,1
                                                      ,5000);
        RAISE global_api_expt;
    END;
--
    --------------------------------------------------
    -- �N�C�b�N�R�[�h����ʒm�X�e�[�^�X���擾 --
    --------------------------------------------------
    BEGIN
--
      -- �ʒm�X�e�[�^�X[���ʒm]�R�[�h���o
      SELECT xlvv.lookup_code
      INTO   gr_notice_st
      FROM   xxcmn_lookup_values_v  xlvv  -- �N�C�b�N�R�[�h��� V
      WHERE  xlvv.lookup_type = gv_notif_status
      AND    xlvv.meaning     = gv_notice_st;
--
    EXCEPTION
      -- �N�C�b�N�R�[�h�����݂��Ȃ��ꍇ
      WHEN NO_DATA_FOUND THEN
        lv_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg( 'XXCMN'
                                                       ,gv_err_cik          -- �N�C�b�N�b�擾�G���[
                                                       ,gv_tkn_lookup_type  -- �g�[�N��
                                                       ,gv_notif_status
                                                       ,gv_tkn_meaning      -- �g�[�N��
                                                       ,gv_notice_st
                                                      )
                                                      ,1
                                                      ,5000);
        RAISE global_api_expt;
    END;
--
    ------------------------------------------
    -- �v���t�@�C������}�X�^�g�D�擾
    ------------------------------------------
    gv_name_m_org := SUBSTRB(FND_PROFILE.VALUE(gv_prf_m_org),1,20);
    -- �擾�G���[��
    IF (gv_name_m_org IS NULL) THEN
      lv_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg( gv_application    -- 'XXWSH'
                                                     ,gv_err_pro        -- �v���t�@�C���擾�G���[
                                                     ,gv_tkn_prof_name  -- �g�[�N��
                                                     ,gv_tkn_msg_org    -- ���b�Z�[�W
                                                    )
                                                    ,1
                                                    ,5000);
      RAISE global_api_expt;
    END IF;
--
    ------------------------------------------
    -- �v���t�@�C������o�Ɍ`��_����v��擾
    ------------------------------------------
    gv_name_tran := SUBSTRB(FND_PROFILE.VALUE(gv_prf_tran),1,30);
--
    -- �擾�G���[��
    IF (gv_name_tran IS NULL) THEN
      lv_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg( gv_application    -- 'XXWSH'
                                                     ,gv_err_pro        -- �v���t�@�C���擾�G���[
                                                     ,gv_tkn_prof_name  -- �g�[�N��
                                                     ,gv_tkn_msg_tran   -- ���b�Z�[�W
                                                    )
                                                    ,1
                                                    ,5000);
      RAISE global_api_expt;
    END IF;
--
    -- �擾�����ꍇ�͎󒍃^�C�v���VIEW����󒍃^�C�vID�𒊏o����
    BEGIN
--
      SELECT xettv.transaction_type_id           -- ����^�C�vID
      INTO   gv_odr_type                         -- �󒍃^�C�vID
      FROM   xxwsh_oe_transaction_types_v  xettv    -- �󒍃^�C�v��� V
      WHERE  xettv.transaction_type_name  = gv_name_tran;
--
    EXCEPTION
      -- �󒍃^�C�vID���擾�s�ȏꍇ
      WHEN NO_DATA_FOUND THEN
        lv_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg( gv_application    -- 'XXWSH'
                                                       ,gv_err_ord        -- �󒍃^�C�v�擾�G���[
                                                       ,gv_tkn_order_type -- �g�[�N��
                                                       ,gv_name_tran      -- �v���t�@�C��
                                                      )
                                                      ,1
                                                      ,5000);
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
      ov_errbuf  := SUBSTRB(cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END pro_get_cus_option;
--
  /**********************************************************************************
   * Procedure Name   : pro_param_chk
   * Description      : ���̓p�����[�^�`�F�b�N   (A-2)
   ***********************************************************************************/
  PROCEDURE pro_param_chk
    (
      ov_errbuf     OUT VARCHAR2     --   �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode    OUT VARCHAR2     --   ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg     OUT VARCHAR2     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'pro_param_chk'; -- �v���O������
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
    -- *** ���[�J���ϐ� ***
    ln_cnt    NUMBER;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    ------------------------------------------
    -- ���͂o�u�Ώ۔N���v�̎擾
    ------------------------------------------
    -- �擾�G���[��
    IF (gr_param.yyyymm IS NULL) THEN
      lv_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg( gv_application     -- 'XXWSH'
                                                     ,gv_err_para        -- �K�{���͂o���ݒ�G���[
                                                     ,gv_tkn_in_parm     -- �g�[�N��
                                                     ,gv_tkn_msg_yymm    -- ���b�Z�[�W
                                                    )
                                                    ,1
                                                    ,5000);
      RAISE global_api_expt;
    END IF;
--
    -- ���͂o�u�Ώ۔N���v�̏����ϊ�(YYYYMM)
    gd_yyyymm := FND_DATE.STRING_TO_DATE(gr_param.yyyymm,'YYYYMM');
    -- �ϊ��G���[��
    IF (gd_yyyymm IS NULL) THEN
      lv_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg( gv_application     -- 'XXWSH'
                                                     ,gv_err_yymm        -- �}�X�^�����G���[
                                                     ,gv_tkn_yymm        -- �g�[�N��
                                                     ,gr_param.yyyymm    -- ���͂o[�Ώ۔N��]
                                                    )
                                                    ,1
                                                    ,5000);
      RAISE global_api_expt;
    END IF;
--
    ------------------------------------------
    -- ���͂o�u�Ǌ����_�v�̎擾
    ------------------------------------------
/* 2008/07/30 Del ��
    -- �擾�G���[��
    IF (gr_param.base IS NULL) THEN
      lv_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg( gv_application     -- 'XXWSH'
                                                     ,gv_err_para        -- �K�{���͂o���ݒ�G���[
                                                     ,gv_tkn_in_parm     -- �g�[�N��
                                                     ,gv_tkn_msg_ktn     -- ���b�Z�[�W
                                                    )
                                                    ,1
                                                    ,5000);
      RAISE global_api_expt;
    END IF;
2008/07/30 Del �� */
--
    -- 2008/07/30 Add ��
    -- ���͂o�u�Ǌ����_�v�����͂���Ă�����
    IF (gr_param.base IS NOT NULL) THEN
    -- 2008/07/30 Add ��
--
      ------------------------------------------------------------------------
      -- �ڋq�}�X�^�E�p�[�e�B�}�X�^�ɋ��_���o�^����Ă��邩�ǂ����̔���
      ------------------------------------------------------------------------
      SELECT COUNT(account_number)
      INTO   ln_cnt
      FROM   xxcmn_parties_v    -- �p�[�e�B��� V
      WHERE  account_number      = gr_param.base  -- ���͂o[�Ǌ����_]
      AND    customer_class_code = gv_1           -- '���_'�������u�R�[�h�敪�v
      AND    ROWNUM              = 1;
--
      -- ���͂o[�Ǌ����_]���ڋq�}�X�^�ɑ��݂��Ȃ��ꍇ
      IF (ln_cnt = 0) THEN
        lv_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg( gv_application     -- 'XXWSH'
                                                       ,gv_err_ktn         -- �}�X�^�����G���[
                                                       ,gv_tkn_kyoten      -- �g�[�N��
                                                       ,gr_param.base      -- ���͂o[�Ǌ����_]
                                                      )
                                                      ,1
                                                      ,5000);
        RAISE global_api_expt;
      END IF;
    -- 2008/07/30 Add ��
    END IF;
    -- 2008/07/30 Add ��
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END pro_param_chk;
--
  /**********************************************************************************
   * Procedure Name   : pro_get_to_plan
   * Description      : ����v���񒊏o  (A-3)
   ***********************************************************************************/
  PROCEDURE pro_get_to_plan
    (
      ot_to_plan    OUT NOCOPY tab_data_to_plan   --   �擾���R�[�h�Q
     ,ov_errbuf     OUT VARCHAR2                  --   �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode    OUT VARCHAR2                  --   ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg     OUT VARCHAR2                  --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'pro_get_to_plan'; -- �v���O������
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
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    CURSOR cur_get_to_plan
    IS
      SELECT mfds.forecast_designator       AS for_name   -- �t�H�[�L���X�g��
            ,mfds.attribute3                AS ktn        -- ���_
            ,mfd.forecast_date              AS for_date   -- ���ח\���
            ,xcasv.ship_to_no               AS ship_t_no  -- �z����
            ,xcasv.party_site_id            AS p_s_site   -- �z����ID
            ,xcav.party_number              AS par_num    -- �ڋq
            ,xcav.party_id                  AS par_id     -- �ڋqID
            ,mfds.attribute2                AS ship_fr    -- �o�׌�
            ,xilv.inventory_location_id     AS ship_id    -- �o�׌�ID
            ,ximv.item_no                   AS item_no    -- �i��
            ,ximv.inventory_item_id         AS item_id    -- �i��ID
            ,mfd.original_forecast_quantity AS amount     -- ����
            ,ximv.item_um                   AS item_um    -- �P��
            ,ximv.num_of_cases              AS case_am    -- ����
            ,TO_NUMBER(ximv.num_of_deliver) AS ship_am    -- �o�ד���
            ,xicv.prod_class_code           AS skbn       -- ���i�敪
            ,ximv.weight_capacity_class     AS wei_kbn    -- �d�ʗe�ϋ敪
            ,ximv.ship_class                AS out_kbn    -- �o�׋敪
            ,xicv.item_class_code           AS item_kbn   -- �i�ڋ敪
            ,ximv.sales_div                 AS sale_kbn   -- ����Ώۋ敪
            ,ximv.obsolete_class            AS end_kbn    -- �p�~�敪
            ,ximv.rate_class                AS rit_kbn    -- ���敪
            ,xcav.cust_enable_flag          AS no_flg     -- ���~�q�\���t���O
            ,ximv.conv_unit                 AS conv_unit  -- ���o�Ɋ��Z�P��
            ,xilv.allow_pickup_flag         AS a_p_flg    -- �o�׈����Ώۃt���O
-- 2008/08/18 H.Itou Add Start
            ,NULL                                         -- �ύڌ���(�d��)���b�Z�[�W�i�[SEQ
            ,NULL                                         -- �ύڌ���(�e��)���b�Z�[�W�i�[SEQ
-- 2008/08/18 H.Itou Add End
      FROM  mrp_forecast_designators  mfds   -- �t�H�[�L���X�g��        T
           ,mrp_forecast_items        mfi    -- �t�H�[�L���X�g�i��      T
           ,mrp_forecast_dates        mfd    -- �t�H�[�L���X�g���t      T
           ,xxcmn_item_locations_v   xilv    -- OPM�ۊǏꏊ���         V
           ,xxcmn_cust_accounts_v    xcav    -- �ڋq���                V
           ,xxcmn_cust_acct_sites_v  xcasv   -- �ڋq�T�C�g���          V
           ,xxcmn_item_categories3_v  xicv   -- OPM�i�ڃJ�e�S��������� V
           ,xxcmn_item_mst2_v         ximv   -- OPM�i�ڏ��             V
      WHERE mfds.attribute1                     = gv_h_plan                -- ����v�� '01'
-- 2008/07/30 Mod ��
/*
      AND   mfds.attribute3                     = gr_param.base            -- ���͂o[�Ǌ����_]
*/
      AND  ((gr_param.base IS NULL)
       OR   (mfds.attribute3                    = gr_param.base))          -- ���͂o[�Ǌ����_]
-- 2008/07/30 Mod ��
      AND   mfds.attribute2                     = xilv.segment1            -- �ۊǑq�ɃR�[�h
      AND   mfds.forecast_designator            = mfd.forecast_designator  -- �t�H�[�L���X�g��
      AND   mfi.forecast_designator             = mfds.forecast_designator -- �t�H�[�L���X�g��
      AND   TO_CHAR(mfd.forecast_date,'YYYYMM') = gr_param.yyyymm          -- ���͂o[�Ώ۔N��]
      AND   mfd.organization_id                 = mfds.organization_id     -- �g�DID
      AND   mfds.organization_id                = mfi.organization_id      -- �g�DID
      AND   mfd.inventory_item_id               = mfi.inventory_item_id    -- �i��ID
      AND   ximv.inventory_item_id              = mfi.inventory_item_id    -- �i��ID
      AND   xcav.account_number                 = mfds.attribute3          -- ���_
      AND   xcav.customer_class_code            = gv_1                     -- �ڋq�敪
      AND   xcav.order_auto_code                = gv_1                     -- �o�׈˗������쐬�敪
      AND   xcav.cust_account_id                = xcasv.cust_account_id    -- �ڋqID
      AND   xcasv.primary_flag                  = gv_yes                   -- ��t���O 'Y'
      AND   xcav.party_id                       = xcasv.party_id           -- �p�[�e�BID
      AND   xicv.item_id                        = ximv.item_id             -- �i��ID
      AND   xicv.prod_class_code                = gv_1                     -- '���[�t'
      AND   ximv.start_date_active             <= gd_sysdate
      AND   ximv.end_date_active               >= gd_sysdate
      ORDER BY mfds.attribute3             -- ���_
              ,mfds.attribute2             -- �o�׌�
              ,mfd.forecast_date           -- ���ח\���
              ,ximv.weight_capacity_class  -- �d�ʗe�ϋ敪
              ,ximv.item_no                -- �i��
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
    -- ====================================================
    --   ����v����𒊏o
    -- ====================================================
    -- �J�[�\���I�[�v��
    OPEN cur_get_to_plan;
    -- �o���N�t�F�b�`
    FETCH cur_get_to_plan BULK COLLECT INTO ot_to_plan;
    -- �J�[�\���N���[�Y
    CLOSE cur_get_to_plan;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      -- �J�[�\���I�[�v�����A�N���[�Y��
      IF (cur_get_to_plan%ISOPEN) THEN
        CLOSE cur_get_to_plan;
      END IF;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      -- �J�[�\���I�[�v�����A�N���[�Y��
      IF (cur_get_to_plan%ISOPEN) THEN
        CLOSE cur_get_to_plan;
      END IF;
--
      ov_errbuf  := cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      -- �J�[�\���I�[�v�����A�N���[�Y��
      IF (cur_get_to_plan%ISOPEN) THEN
        CLOSE cur_get_to_plan;
      END IF;
--
      ov_errbuf  := cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END pro_get_to_plan;
--
  /**********************************************************************************
   * Procedure Name   : pro_ship_max_kbn
   * Description      : �o�ח\���/�ő�z���敪�Z�o  (A-4)
   ***********************************************************************************/
  PROCEDURE pro_ship_max_kbn
    (
      ov_errbuf     OUT VARCHAR2     --   �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode    OUT VARCHAR2     --   ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg     OUT VARCHAR2     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'pro_ship_max_kbn'; -- �v���O������
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
    ln_result    NUMBER;
--
    -- *** ���[�J���ϐ� ***
    lv_errmsg_code  VARCHAR2(30);  -- �G���[�E���b�Z�[�W�E�R�[�h
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -----------------------------------------------------------------------------------
    -- 1.���ʊ֐��u�ғ����Z�o�֐��v�ɂāw���ח\����x���ғ������ł��邩�`�F�b�N      --
    -----------------------------------------------------------------------------------
    ln_result := xxwsh_common_pkg.get_oprtn_day
                                (
                                  gt_to_plan(gn_i).for_date   -- ���t           in ���ח\���
                                 ,NULL                        -- �ۊǑq�ɃR�[�h in NULL
                                 ,gt_to_plan(gn_i).ship_t_no  -- �z����R�[�h   in �z����
                                 ,0                           -- ���[�h�^�C��   in 0
                                 ,gt_to_plan(gn_i).skbn       -- ���i�敪       in ���i�敪(���[�t)
                                 ,gd_work_day                 -- �ғ������t    out �ғ���
                                );
--
    -- �ғ����ł͂Ȃ��ꍇ�A���[�j���O
    IF (gd_work_day IS NULL) THEN
--
      -- �G���[���X�g�쐬
      pro_err_list_make
        (
          iv_kind         => gv_tkn_msg_war            --  in ���   '�x��'
         ,iv_dec          => gv_tkn_msg_war            --  in �m��   '�x��'
         ,iv_req_no       => gv_req_no                 --  in �˗�No
         ,iv_kyoten       => gt_to_plan(gn_i).ktn      --  in �Ǌ����_
         ,iv_item         => gt_to_plan(gn_i).item_no  --  in �i��
         ,in_qty          => gt_to_plan(gn_i).amount   --  in ����
         ,iv_ship_date    => gv_tkn_msg_hfn            --  in �o�ɓ�  '-'
         ,iv_arrival_date => TO_CHAR(gt_to_plan(gn_i).for_date,'YYYY/MM/DD')
                                                       --  in ����
         ,iv_err_msg      => gv_tkn_msg_6              --  in �G���[���b�Z�[�W
         ,iv_err_clm      => gv_tkn_msg_hfn            --  in �G���[���� '-'
         ,ov_errbuf       => lv_errbuf                 -- out �G���[�E���b�Z�[�W
         ,ov_retcode      => lv_retcode                -- out ���^�[���E�R�[�h
         ,ov_errmsg       => lv_errmsg                 -- out ���[�U�[�E�G���[�E���b�Z�[�W
        );
      -- ���ʃG���[���b�Z�[�W �I��ST�̔���
      IF (gv_err_sts <> gv_status_error) THEN
        gv_err_sts := gv_status_warn;
      END IF;
    END IF;
--
    -----------------------------------------------------------------------------------------------
    -- 2.���ʊ֐��u���[�h�^�C���Z�o�v�ɂāw����ύX���[�h�^�C���x�w�z�����[�h�^�C���x�擾        --
    -----------------------------------------------------------------------------------------------
    xxwsh_common910_pkg.calc_lead_time
                                (
                                  gv_4                       -- �R�[�h�敪From   in �q��'4'
                                 ,gt_to_plan(gn_i).ship_fr   -- ���o�ɋ敪From   in �o�׌�
                                 ,gv_9                       -- �R�[�h�敪To     in �z����'9'
                                 ,gt_to_plan(gn_i).ship_t_no -- ���o�ɋ敪To     in �z����
                                 ,gt_to_plan(gn_i).skbn      -- ���i�敪         in ���i�敪(���[�t)
                                 ,gv_odr_type                -- �o�Ɍ`��ID       in �󒍃^�C�vID
                                 ,gt_to_plan(gn_i).for_date  -- ���           in ���ח\���
                                 ,lv_retcode                 -- ���^�[���E�R�[�h
                                 ,lv_errmsg_code             -- �G���[�E���b�Z�[�W�E�R�[�h
                                 ,lv_errmsg                  -- ���[�U�[�E�G���[�E���b�Z�[�W
                                 ,gv_leadtime                -- ���Y����LT/����ύXLT
                                 ,gv_delivery_lt             -- �z�����[�h�^�C��
                                );
--
    -- ���ʊ֐��G���[���A�G���[
    IF (lv_retcode = gv_1) THEN
--
      -- �G���[���X�g�쐬
      pro_err_list_make
        (
          iv_kind         => gv_tkn_msg_err            --  in ���   '�G���['
         ,iv_dec          => gv_tkn_msg_hfn            --  in �m��   '-'
         ,iv_req_no       => gv_req_no                 --  in �˗�No
         ,iv_kyoten       => gt_to_plan(gn_i).ktn      --  in �Ǌ����_
         ,iv_item         => gt_to_plan(gn_i).item_no  --  in �i��
         ,in_qty          => gt_to_plan(gn_i).amount   --  in ����
         ,iv_ship_date    => gv_tkn_msg_hfn            --  in �o�ɓ�  '-'
         ,iv_arrival_date => TO_CHAR(gt_to_plan(gn_i).for_date,'YYYY/MM/DD')
                                                       --  in ����
         ,iv_err_msg      => lv_errmsg                 --  in �G���[���b�Z�[�W
         ,iv_err_clm      => gv_tkn_msg_7              --  in �G���[����
         ,ov_errbuf       => lv_errbuf                 -- out �G���[�E���b�Z�[�W
         ,ov_retcode      => lv_retcode                -- out ���^�[���E�R�[�h
         ,ov_errmsg       => lv_errmsg                 -- out ���[�U�[�E�G���[�E���b�Z�[�W
        );
      -- ���ʃG���[���b�Z�[�W �I��ST �G���[�o�^
      gv_err_sts := gv_status_error;
--
      RAISE err_header_expt;
    END IF;
--
    ----------------------------------------------------------------------------
    -- 3.���ʊ֐��u�ғ����Z�o�֐��v�ɂāw�o�ח\����x�Z�o                     --
    ----------------------------------------------------------------------------
    ln_result := xxwsh_common_pkg.get_oprtn_day
                                  (
                                    gt_to_plan(gn_i).for_date -- ���t           in ���ח\���
                                   ,gt_to_plan(gn_i).ship_fr  -- �ۊǑq�ɃR�[�h in �o�׌�
                                   ,NULL                      -- �z����R�[�h   in NULL
                                   ,gv_delivery_lt            -- ���[�h�^�C��   in �z�����[�h�^�C��
                                   ,gt_to_plan(gn_i).skbn     -- ���i�敪       in ���i�敪(���[�t)
                                   ,gd_ship_day               -- �ғ������t    out �o�ח\���
                                  );
--
    ----------------------------------------------------------------------------
    -- 4.�ғ������t(�o�ח\���)���V�X�e�����t���ߋ����ǂ����̔���           --
    ----------------------------------------------------------------------------
    IF (gd_sysdate > gd_ship_day) THEN
      -- �ߋ��̏ꍇ�A�z�����[�h�^�C���𖞂����Ă��Ȃ��B���[�j���O
      pro_err_list_make
        (
          iv_kind         => gv_tkn_msg_war                     --  in ���   '�x��'
         ,iv_dec          => gv_tkn_msg_err                     --  in �m��   '�G���['
         ,iv_req_no       => gv_req_no                          --  in �˗�No
         ,iv_kyoten       => gt_to_plan(gn_i).ktn               --  in �Ǌ����_
         ,iv_item         => gt_to_plan(gn_i).item_no           --  in �i��
         ,in_qty          => gt_to_plan(gn_i).amount            --  in ����
         ,iv_ship_date    => TO_CHAR(gd_ship_day,'YYYY/MM/DD')  --  in �o�ɓ� [�o�ח\���]
         ,iv_arrival_date => TO_CHAR(gt_to_plan(gn_i).for_date,'YYYY/MM/DD')
                                                                --  in ����
         ,iv_err_msg      => gv_tkn_msg_8                       --  in �G���[���b�Z�[�W
         ,iv_err_clm      => gv_delivery_lt                     --  in �G���[���� [�z�����[�h�^�C��]
         ,ov_errbuf       => lv_errbuf                          -- out �G���[�E���b�Z�[�W
         ,ov_retcode      => lv_retcode                         -- out ���^�[���E�R�[�h
         ,ov_errmsg       => lv_errmsg                          -- out ���[�U�[�E�G���[�E���b�Z�[�W
        );
      -- ���ʃG���[���b�Z�[�W �I��ST�̔���
      IF (gv_err_sts <> gv_status_error) THEN
        gv_err_sts := gv_status_warn;
      END IF;
    END IF;
--
    ----------------------------------------------------------------------------
    -- 5.���ʊ֐��u�ғ����Z�o�֐��v�ɂāw�ߋ��ғ����x�Z�o                     --
    ----------------------------------------------------------------------------
    ln_result := xxwsh_common_pkg.get_oprtn_day
                          (
                            gd_ship_day                -- ���t           in �o�ח\���
                           ,NULL                       -- �ۊǑq�ɃR�[�h in NULL
                           ,gt_to_plan(gn_i).ship_t_no -- �z����R�[�h   in �z����
                           ,gv_delivery_lt             -- ���[�h�^�C��   in ���Y����LT/����ύXLT
                           ,gt_to_plan(gn_i).skbn      -- ���i�敪       in ���i�敪(���[�t)
                           ,gd_past_day                -- �ғ������t    out ����ύXLT�̉ߋ���
                           );
--
    ----------------------------------------------------------------------------
    -- 6.�ғ������t(����ύXLT�̉ߋ���)���V�X�e�����t���ߋ����ǂ����̔���   --
    ----------------------------------------------------------------------------
    IF (gd_sysdate > gd_past_day) THEN
      -- �ߋ��̏ꍇ�A���惊�[�h�^�C���𖞂����Ă��Ȃ��B���[�j���O
      pro_err_list_make
        (
          iv_kind         => gv_tkn_msg_war                     --  in ���   '�x��'
         ,iv_dec          => gv_tkn_msg_err                     --  in �m��   '�G���['
         ,iv_req_no       => gv_req_no                          --  in �˗�No
         ,iv_kyoten       => gt_to_plan(gn_i).ktn               --  in �Ǌ����_
         ,iv_item         => gt_to_plan(gn_i).item_no           --  in �i��
         ,in_qty          => gt_to_plan(gn_i).amount            --  in ����
         ,iv_ship_date    => TO_CHAR(gd_ship_day,'YYYY/MM/DD')  --  in �o�ɓ� [�o�ח\���]
         ,iv_arrival_date => TO_CHAR(gt_to_plan(gn_i).for_date,'YYYY/MM/DD')
                                                                --  in ����
         ,iv_err_msg      => gv_tkn_msg_9                       --  in �G���[���b�Z�[�W
         ,iv_err_clm      => gv_leadtime                        --  in �G���[����  [����ύXLT]
         ,ov_errbuf       => lv_errbuf                          -- out �G���[�E���b�Z�[�W
         ,ov_retcode      => lv_retcode                         -- out ���^�[���E�R�[�h
         ,ov_errmsg       => lv_errmsg                          -- out ���[�U�[�E�G���[�E���b�Z�[�W
        );
      -- ���ʃG���[���b�Z�[�W �I��ST�̔���
      IF (gv_err_sts <> gv_status_error) THEN
        gv_err_sts := gv_status_warn;
      END IF;
    END IF;
--
    ----------------------------------------------------------------------------
    -- 7.���ʊ֐��u�ő�z���敪�Z�o�֐��v�ɂāw�ő�z���敪�x�Z�o             --
    ----------------------------------------------------------------------------
    ln_result := xxwsh_common_pkg.get_max_ship_method
                             (
                               gv_4                        -- �R�[�h�敪1       in �q��'4'
                              ,gt_to_plan(gn_i).ship_fr    -- ���o�ɏꏊ�R�[�h1 in �o�׌�
                              ,gv_9                        -- �R�[�h�敪2       in �z����'9'
                              ,gt_to_plan(gn_i).ship_t_no  -- ���o�ɏꏊ�R�[�h2 in �z����
                              ,gt_to_plan(gn_i).skbn       -- ���i�敪          in ���i�敪(���[�t)
                              ,gt_to_plan(gn_i).wei_kbn    -- �d�ʗe�ϋ敪      in �d�ʗe�ϋ敪
                              ,NULL                        -- �����z�ԑΏۋ敪  in NULL
                              ,gd_ship_day                 -- ���            in �o�ח\���
                              ,gv_max_kbn                  -- �ő�z���敪     out �ő�z���敪
                              ,gn_drink_we                 -- �h�����N�ύڏd�� out �h�����N�ύڏd��
                              ,gn_leaf_we                  -- ���[�t�ύڏd��   out ���[�t�ύڏd��
                              ,gn_drink_ca                 -- �h�����N�ύڗe�� out �h�����N�ύڗe��
                              ,gn_leaf_ca                  -- ���[�t�ύڗe��   out ���[�t�ύڗe��
                              ,gn_prt_max                  -- �p���b�g�ő喇�� out �p���b�g�ő喇��
                             );
--
    -- �ő�z���敪�Z�o�֐�������ł͂Ȃ��ꍇ�A�G���[
    IF (ln_result = 1) THEN
--
      -- �G���[���X�g�쐬
      pro_err_list_make
        (
          iv_kind         => gv_tkn_msg_err                     --  in ���   '�G���['
         ,iv_dec          => gv_tkn_msg_hfn                     --  in �m��   '-'
         ,iv_req_no       => gv_req_no                          --  in �˗�No
         ,iv_kyoten       => gt_to_plan(gn_i).ktn               --  in �Ǌ����_
         ,iv_item         => gt_to_plan(gn_i).item_no           --  in �i��
         ,in_qty          => gt_to_plan(gn_i).amount            --  in ����
         ,iv_ship_date    => TO_CHAR(gd_ship_day,'YYYY/MM/DD')  --  in �o�ɓ� [�o�ח\���]
         ,iv_arrival_date => TO_CHAR(gt_to_plan(gn_i).for_date,'YYYY/MM/DD')
                                                                --  in ����
         ,iv_err_msg      => gv_tkn_msg_10                      --  in �G���[���b�Z�[�W
         ,iv_err_clm      => gv_tkn_msg_hfn                     --  in �G���[����  '-'
         ,ov_errbuf       => lv_errbuf                          -- out �G���[�E���b�Z�[�W
         ,ov_retcode      => lv_retcode                         -- out ���^�[���E�R�[�h
         ,ov_errmsg       => lv_errmsg                          -- out ���[�U�[�E�G���[�E���b�Z�[�W
        );
      -- ���ʃG���[���b�Z�[�W �I��ST  �G���[�o�^
      gv_err_sts := gv_status_error;
--
      RAISE err_header_expt;
    END IF;
--
    ----------------------------------------------------------------------------
    -- 8.���ʊ֐��uOPM�݌ɉ�v���� CLOSE�N���擾�֐��v�ɂ�                    --
    --   �w�o�ח\����x�̉�v���Ԃ�Open����Ă��邩�`�F�b�N                   --
    ----------------------------------------------------------------------------
    -- �N���[�Y�̍ő�N���擾
    gv_opm_c_p := xxcmn_common_pkg.get_opminv_close_period; 
--
    -- �o�ח\�����OPM�݌ɉ�v���ԂŃN���[�Y�̏ꍇ
    IF (gv_opm_c_p > TO_CHAR(gd_ship_day,'YYYYMM')) THEN
--
      -- �G���[���X�g�쐬
      pro_err_list_make
        (
          iv_kind         => gv_tkn_msg_err                     --  in ���   '�G���['
         ,iv_dec          => gv_tkn_msg_hfn                     --  in �m��   '-'
         ,iv_req_no       => gv_req_no                          --  in �˗�No
         ,iv_kyoten       => gt_to_plan(gn_i).ktn               --  in �Ǌ����_
         ,iv_item         => gt_to_plan(gn_i).item_no           --  in �i��
         ,in_qty          => gt_to_plan(gn_i).amount            --  in ����
         ,iv_ship_date    => TO_CHAR(gd_ship_day,'YYYY/MM/DD')  --  in �o�ɓ� [�o�ח\���]
         ,iv_arrival_date => TO_CHAR(gt_to_plan(gn_i).for_date,'YYYY/MM/DD')
                                                                --  in ����
         ,iv_err_msg      => gv_tkn_msg_11                      --  in �G���[���b�Z�[�W
         ,iv_err_clm      => gd_ship_day                        --  in �G���[����  [�o�ח\���]
         ,ov_errbuf       => lv_errbuf                          -- out �G���[�E���b�Z�[�W
         ,ov_retcode      => lv_retcode                         -- out ���^�[���E�R�[�h
         ,ov_errmsg       => lv_errmsg                          -- out ���[�U�[�E�G���[�E���b�Z�[�W
        );
      -- ���ʃG���[���b�Z�[�W �I��ST �G���[�o�^
      gv_err_sts := gv_status_error;
--
      RAISE err_header_expt;
    END IF;
--
  EXCEPTION
    -- *** ���ʊ֐� �x���E�G���[ ***
    WHEN err_header_expt THEN
      gv_err_flg := gv_1;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END pro_ship_max_kbn;
--
  /**********************************************************************************
   * Procedure Name   : pro_lines_chk
   * Description      : ���׍��ڃ`�F�b�N (A-5)
   ***********************************************************************************/
  PROCEDURE pro_lines_chk
    (
      ov_errbuf     OUT VARCHAR2     -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode    OUT VARCHAR2     -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg     OUT VARCHAR2     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    )
  IS
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'pro_lines_chk'; -- �v���O������
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
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- �u�o�׋敪�v���w�ہx�̏ꍇ�A���[�j���O
    IF (gt_to_plan(gn_i).out_kbn = gv_0) THEN
--
      -- �G���[���X�g�쐬
      pro_err_list_make
        (
          iv_kind         => gv_tkn_msg_war                     --  in ���  '�x��'
         ,iv_dec          => gv_tkn_msg_err                     --  in �m��  '�G���['
         ,iv_req_no       => gv_req_no                          --  in �˗�No
         ,iv_kyoten       => gt_to_plan(gn_i).ktn               --  in �Ǌ����_
         ,iv_item         => gt_to_plan(gn_i).item_no           --  in �i��
         ,in_qty          => gt_to_plan(gn_i).amount            --  in ����
         ,iv_ship_date    => TO_CHAR(gd_ship_day,'YYYY/MM/DD')  --  in �o�ɓ� [�o�ח\���]
         ,iv_arrival_date => TO_CHAR(gt_to_plan(gn_i).for_date,'YYYY/MM/DD')
                                                                --  in ����
         ,iv_err_msg      => gv_tkn_msg_12                      --  in �G���[���b�Z�[�W
         ,iv_err_clm      => gv_tkn_msg_hfn                     --  in �G���[����  '-'
         ,ov_errbuf       => lv_errbuf                          -- out �G���[�E���b�Z�[�W
         ,ov_retcode      => lv_retcode                         -- out ���^�[���E�R�[�h
         ,ov_errmsg       => lv_errmsg                          -- out ���[�U�[�E�G���[�E���b�Z�[�W
        );
      -- ���ʃG���[���b�Z�[�W �I��ST�̔���
      IF (gv_err_sts <> gv_status_error) THEN
        gv_err_sts := gv_status_warn;
      END IF;
    END IF;
--
    -- �u����Ώۋ敪�v���u1�v�ȊO�̏ꍇ�A���[�j���O
    IF (gt_to_plan(gn_i).sale_kbn <> gv_1) THEN
--
      -- �G���[���X�g�쐬
      pro_err_list_make
        (
          iv_kind         => gv_tkn_msg_war                     --  in ���  '�x��'
         ,iv_dec          => gv_tkn_msg_err                     --  in �m��  '�G���['
         ,iv_req_no       => gv_req_no                          --  in �˗�No
         ,iv_kyoten       => gt_to_plan(gn_i).ktn               --  in �Ǌ����_
         ,iv_item         => gt_to_plan(gn_i).item_no           --  in �i��
         ,in_qty          => gt_to_plan(gn_i).amount            --  in ����
         ,iv_ship_date    => TO_CHAR(gd_ship_day,'YYYY/MM/DD')  --  in �o�ɓ� [�o�ח\���]
         ,iv_arrival_date => TO_CHAR(gt_to_plan(gn_i).for_date,'YYYY/MM/DD')
                                                                --  in ����
         ,iv_err_msg      => gv_tkn_msg_1                       --  in �G���[���b�Z�[�W
         ,iv_err_clm      => gv_tkn_msg_hfn                     --  in �G���[����  '-'
         ,ov_errbuf       => lv_errbuf                          -- out �G���[�E���b�Z�[�W
         ,ov_retcode      => lv_retcode                         -- out ���^�[���E�R�[�h
         ,ov_errmsg       => lv_errmsg                          -- out ���[�U�[�E�G���[�E���b�Z�[�W
        );
      -- ���ʃG���[���b�Z�[�W �I��ST�̔���
      IF (gv_err_sts <> gv_status_error) THEN
        gv_err_sts := gv_status_warn;
      END IF;
    END IF;
--
    -- �u�p�~�敪�v���u1�v�̏ꍇ�A���[�j���O
    IF (gt_to_plan(gn_i).end_kbn = gv_delete) THEN
--
      -- �G���[���X�g�쐬
      pro_err_list_make
        (
          iv_kind         => gv_tkn_msg_war                     --  in ���  '�x��'
         ,iv_dec          => gv_tkn_msg_err                     --  in �m��  '�G���['
         ,iv_req_no       => gv_req_no                          --  in �˗�No
         ,iv_kyoten       => gt_to_plan(gn_i).ktn               --  in �Ǌ����_
         ,iv_item         => gt_to_plan(gn_i).item_no           --  in �i��
         ,in_qty          => gt_to_plan(gn_i).amount            --  in ����
         ,iv_ship_date    => TO_CHAR(gd_ship_day,'YYYY/MM/DD')  --  in �o�ɓ� [�o�ח\���]
         ,iv_arrival_date => TO_CHAR(gt_to_plan(gn_i).for_date,'YYYY/MM/DD')
                                                                --  in ����
         ,iv_err_msg      => gv_tkn_msg_2                       --  in �G���[���b�Z�[�W
         ,iv_err_clm      => gv_tkn_msg_hfn                     --  in �G���[����  '-'
         ,ov_errbuf       => lv_errbuf                          -- out �G���[�E���b�Z�[�W
         ,ov_retcode      => lv_retcode                         -- out ���^�[���E�R�[�h
         ,ov_errmsg       => lv_errmsg                          -- out ���[�U�[�E�G���[�E���b�Z�[�W
        );
      -- ���ʃG���[���b�Z�[�W �I��ST�̔���
      IF (gv_err_sts <> gv_status_error) THEN
        gv_err_sts := gv_status_warn;
      END IF;
    END IF;
--
    -- �u���敪�v���u0�v�ȊO�̏ꍇ�A���[�j���O
    IF (gt_to_plan(gn_i).rit_kbn <> gv_0) THEN
--
      -- �G���[���X�g�쐬
      pro_err_list_make
        (
          iv_kind         => gv_tkn_msg_war                     --  in ���  '�x��'
         ,iv_dec          => gv_tkn_msg_err                     --  in �m��  '�G���['
         ,iv_req_no       => gv_req_no                          --  in �˗�No
         ,iv_kyoten       => gt_to_plan(gn_i).ktn               --  in �Ǌ����_
         ,iv_item         => gt_to_plan(gn_i).item_no           --  in �i��
         ,in_qty          => gt_to_plan(gn_i).amount            --  in ����
         ,iv_ship_date    => TO_CHAR(gd_ship_day,'YYYY/MM/DD')  --  in �o�ɓ� [�o�ח\���]
         ,iv_arrival_date => TO_CHAR(gt_to_plan(gn_i).for_date,'YYYY/MM/DD')
                                                                --  in ����
         ,iv_err_msg      => gv_tkn_msg_3                       --  in �G���[���b�Z�[�W
         ,iv_err_clm      => gv_tkn_msg_hfn                     --  in �G���[����  '-'
         ,ov_errbuf       => lv_errbuf                          -- out �G���[�E���b�Z�[�W
         ,ov_retcode      => lv_retcode                         -- out ���^�[���E�R�[�h
         ,ov_errmsg       => lv_errmsg                          -- out ���[�U�[�E�G���[�E���b�Z�[�W
        );
      -- ���ʃG���[���b�Z�[�W �I��ST�̔���
      IF (gv_err_sts <> gv_status_error) THEN
        gv_err_sts := gv_status_warn;
      END IF;
    END IF;
--
    -- �u���~�q�\���t���O�v���u0�v�ȊO�̏ꍇ�A���[�j���O
    IF (gt_to_plan(gn_i).no_flg <> gv_0) THEN
--
      -- �G���[���X�g�쐬
      pro_err_list_make
        (
          iv_kind         => gv_tkn_msg_war                     --  in ���  '�x��'
         ,iv_dec          => gv_tkn_msg_err                     --  in �m��  '�G���['
         ,iv_req_no       => gv_req_no                          --  in �˗�No
         ,iv_kyoten       => gt_to_plan(gn_i).ktn               --  in �Ǌ����_
         ,iv_item         => gt_to_plan(gn_i).item_no           --  in �i��
         ,in_qty          => gt_to_plan(gn_i).amount            --  in ����
         ,iv_ship_date    => TO_CHAR(gd_ship_day,'YYYY/MM/DD')  --  in �o�ɓ� [�o�ח\���]
         ,iv_arrival_date => TO_CHAR(gt_to_plan(gn_i).for_date,'YYYY/MM/DD')
                                                                --  in ����
         ,iv_err_msg      => gv_tkn_msg_5                       --  in �G���[���b�Z�[�W
         ,iv_err_clm      => gv_tkn_msg_hfn                     --  in �G���[����  '-'
         ,ov_errbuf       => lv_errbuf                          -- out �G���[�E���b�Z�[�W
         ,ov_retcode      => lv_retcode                         -- out ���^�[���E�R�[�h
         ,ov_errmsg       => lv_errmsg                          -- out ���[�U�[�E�G���[�E���b�Z�[�W
        );
      -- ���ʃG���[���b�Z�[�W �I��ST�̔���
      IF (gv_err_sts <> gv_status_error) THEN
        gv_err_sts := gv_status_warn;
      END IF;
    END IF;
--
    -- �u�o�׈����Ώۃt���O�v�������s�u0�v�A���[�j���O
    IF (gt_to_plan(gn_i).a_p_flg = gv_0) THEN
--
      -- �G���[���X�g�쐬
      pro_err_list_make
        (
          iv_kind         => gv_tkn_msg_war                     --  in ���  '�x��'
         ,iv_dec          => gv_tkn_msg_err                     --  in �m��  '�G���['
         ,iv_req_no       => gv_req_no                          --  in �˗�No
         ,iv_kyoten       => gt_to_plan(gn_i).ktn               --  in �Ǌ����_
         ,iv_item         => gt_to_plan(gn_i).item_no           --  in �i��
         ,in_qty          => gt_to_plan(gn_i).amount            --  in ����
         ,iv_ship_date    => TO_CHAR(gd_ship_day,'YYYY/MM/DD')  --  in �o�ɓ� [�o�ח\���]
         ,iv_arrival_date => TO_CHAR(gt_to_plan(gn_i).for_date,'YYYY/MM/DD')
                                                                --  in ����
         ,iv_err_msg      => gv_tkn_msg_23                      --  in �G���[���b�Z�[�W
         ,iv_err_clm      => gt_to_plan(gn_i).ship_fr           --  in �G���[����  �o�׌�
         ,ov_errbuf       => lv_errbuf                          -- out �G���[�E���b�Z�[�W
         ,ov_retcode      => lv_retcode                         -- out ���^�[���E�R�[�h
         ,ov_errmsg       => lv_errmsg                          -- out ���[�U�[�E�G���[�E���b�Z�[�W
        );
      -- ���ʃG���[���b�Z�[�W �I��ST�̔���
      IF (gv_err_sts <> gv_status_error) THEN
        gv_err_sts := gv_status_warn;
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
      ov_errbuf  := SUBSTRB(cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END pro_lines_chk;
--
  /**********************************************************************************
   * Procedure Name   : pro_xsr_chk
   * Description      : �����\���A�h�I���}�X�^���݃`�F�b�N (A-6)
   ***********************************************************************************/
  PROCEDURE pro_xsr_chk
    (
      ov_errbuf     OUT VARCHAR2     --   �G���[�E���b�Z�[�W                  --# �Œ� #
     ,ov_retcode    OUT VARCHAR2     --   ���^�[���E�R�[�h                    --# �Œ� #
     ,ov_errmsg     OUT VARCHAR2     --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
    )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'pro_xsr_chk'; -- �v���O������
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
    -- *** ���[�J���ϐ� ***
    ln_cnt      NUMBER;
    lv_yn_flg   VARCHAR2(1);
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ���݃`�F�b�N�t���O�A�J�E���g�ϐ�������
    ln_cnt    := 0;
    lv_yn_flg := gv_no;
--
    ------------------------------------------------------------------
    -- 1.�i��/�z����/�o�א�ɂĕ����\���A�h�I���ւ̑��݃`�F�b�N     --
    ------------------------------------------------------------------
    SELECT COUNT (xsr.item_code)
    INTO   ln_cnt
    FROM   xxcmn_sourcing_rules  xsr   -- �����\���A�h�I���}�X�^ T
    WHERE  xsr.item_code          = gt_to_plan(gn_i).item_no
    AND    xsr.ship_to_code       = gt_to_plan(gn_i).ship_t_no
    AND    xsr.delivery_whse_code = gt_to_plan(gn_i).ship_fr
    AND    xsr.start_date_active <= gd_ship_day
    AND    xsr.end_date_active   >= gd_ship_day
    AND    ROWNUM                 = 1
    ;
--
    IF (ln_cnt > 0) THEN
      lv_yn_flg := gv_yes;
    END IF;
--
    ------------------------------------------------------------------
    -- 2.�i��/���_/�o�׌��ɂĕ����\���A�h�I���ւ̑��݃`�F�b�N       --
    ------------------------------------------------------------------
    -- ��L1�ɂ�0���̏ꍇ
    IF (lv_yn_flg = gv_no) THEN
      SELECT COUNT (xsr.item_code)
      INTO   ln_cnt
      FROM   xxcmn_sourcing_rules  xsr  -- �����\���A�h�I���}�X�^ T
      WHERE  xsr.item_code          = gt_to_plan(gn_i).item_no
      AND    xsr.base_code          = gt_to_plan(gn_i).ktn
      AND    xsr.delivery_whse_code = gt_to_plan(gn_i).ship_fr
      AND    xsr.start_date_active <= gd_ship_day
      AND    xsr.end_date_active   >= gd_ship_day
      AND    ROWNUM                 = 1
      ;
--
      IF (ln_cnt > 0) THEN
        lv_yn_flg := gv_yes;
      END IF;
    END IF;
--
    ------------------------------------------------------------------
    -- 3.�S�i��/�z����/�o�׌��ɂĕ����\���A�h�I���ւ̑��݃`�F�b�N   --
    ------------------------------------------------------------------
    -- ��L2�ɂ�0���̏ꍇ
    IF (lv_yn_flg = gv_no) THEN
      SELECT COUNT (xsr.item_code)
      INTO   ln_cnt
      FROM   xxcmn_sourcing_rules  xsr  -- �����\���A�h�I���}�X�^ T
      WHERE  xsr.item_code          = gv_all_item
      AND    xsr.ship_to_code       = gt_to_plan(gn_i).ship_t_no
      AND    xsr.delivery_whse_code = gt_to_plan(gn_i).ship_fr
      AND    xsr.start_date_active <= gd_ship_day
      AND    xsr.end_date_active   >= gd_ship_day
      AND    ROWNUM                 = 1
      ;
--
      IF (ln_cnt > 0) THEN
        lv_yn_flg := gv_yes;
      END IF;
    END IF;
--
    ------------------------------------------------------------------
    -- 4.�S�i��/���_/�o�׌��ɂĕ����\���A�h�I���ւ̑��݃`�F�b�N     --
    ------------------------------------------------------------------
    -- ��L3�ɂ�0���̏ꍇ
    IF (lv_yn_flg = gv_no) THEN
      SELECT COUNT (xsr.item_code)
      INTO   ln_cnt
      FROM   xxcmn_sourcing_rules  xsr  -- �����\���A�h�I���}�X�^ T
      WHERE  xsr.item_code          = gv_all_item
      AND    xsr.base_code          = gt_to_plan(gn_i).ktn
      AND    xsr.delivery_whse_code = gt_to_plan(gn_i).ship_fr
      AND    xsr.start_date_active <= gd_ship_day
      AND    xsr.end_date_active   >= gd_ship_day
      AND    ROWNUM                 = 1
      ;
--
      IF (ln_cnt > 0) THEN
        lv_yn_flg := gv_yes;
      END IF;
    END IF;
--
    -- ��L4�ɂ�0���̏ꍇ�A���[�j���O
    IF (lv_yn_flg = gv_no) THEN
--
      -- �G���[���X�g�쐬
      pro_err_list_make
        (
          iv_kind         => gv_tkn_msg_war                     --  in ���  '�x��'
         ,iv_dec          => gv_tkn_msg_err                     --  in �m��  '�G���['
         ,iv_req_no       => gv_req_no                          --  in �˗�No
         ,iv_kyoten       => gt_to_plan(gn_i).ktn               --  in �Ǌ����_
         ,iv_item         => gt_to_plan(gn_i).item_no           --  in �i��
         ,in_qty          => gt_to_plan(gn_i).amount            --  in ����
         ,iv_ship_date    => TO_CHAR(gd_ship_day,'YYYY/MM/DD')  --  in �o�ɓ� [�o�ח\���]
         ,iv_arrival_date => TO_CHAR(gt_to_plan(gn_i).for_date,'YYYY/MM/DD')
                                                                --  in ����
         ,iv_err_msg      => gv_tkn_msg_13                      --  in �G���[���b�Z�[�W
         ,iv_err_clm      => gv_tkn_msg_hfn                     --  in �G���[����  '-'
         ,ov_errbuf       => lv_errbuf                          -- out �G���[�E���b�Z�[�W
         ,ov_retcode      => lv_retcode                         -- out ���^�[���E�R�[�h
         ,ov_errmsg       => lv_errmsg                          -- out ���[�U�[�E�G���[�E���b�Z�[�W
        );
      -- ���ʃG���[���b�Z�[�W �I��ST�̔���
      IF (gv_err_sts <> gv_status_error) THEN
        gv_err_sts := gv_status_warn;
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
      ov_errbuf  := SUBSTRB(cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END pro_xsr_chk;
--
  /**********************************************************************************
   * Procedure Name   : pro_total_we_ca
   * Description      : ���v�d��/���v�e�ώZ�o (A-7)
   ***********************************************************************************/
  PROCEDURE pro_total_we_ca
    (
      ov_errbuf     OUT VARCHAR2     --   �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode    OUT VARCHAR2     --   ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg     OUT VARCHAR2     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'pro_total_we_ca'; -- �v���O������
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
    lv_kougti    CONSTANT VARCHAR2(6)  := '%����%';
--
    -- *** ���[�J���ϐ� ***
    ln_cnt         NUMBER;
    lv_errmsg_code VARCHAR2(30);  -- �G���[�E���b�Z�[�W�E�R�[�h
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -----------------------------------------------------------------------------------
    -- ���ʊ֐��u�ύڌ����`�F�b�N(���v�l�Z�o)�v�ɂāw���v�d��/���v�e�ρx���Z�o       --
    -----------------------------------------------------------------------------------
    xxwsh_common910_pkg.calc_total_value
                               (
                                 gt_to_plan(gn_i).item_no -- �i��              in �i��
                                ,gt_to_plan(gn_i).amount  -- ����              in ����
                                ,lv_retcode               -- ���^�[���E�R�[�h
                                ,lv_errmsg_code           -- �G���[�E���b�Z�[�W�E�R�[�h
                                ,lv_errmsg                -- �G���[�E���b�Z�[�W
                                ,gn_ttl_we                -- ���v�d��         out ���v�d��
                                ,gn_ttl_ca                -- ���v�e��         out ���v�e��
                                ,gn_ttl_prt_we            -- ���v�p���b�g�d�� out ���v�p���b�g�d��
                               );
--
-- 2008/07/30 Mod ��
/*
    -------------------------------------------------------------------------------
    -- ��ő�z���敪��ɕR�Â�������敪����Ώۂ��ǂ����`�F�b�N                    --
    -------------------------------------------------------------------------------
    SELECT count (xlvv.meaning)
    INTO   ln_cnt
    FROM   xxcmn_lookup_values_v  xlvv  -- �N�C�b�N�R�[�h��� V
    WHERE  xlvv.lookup_type = gv_ship_method
    AND    xlvv.lookup_code = gv_max_kbn
    AND    xlvv.attribute6  = gv_1          -- �Ώ�
    AND    xlvv.meaning  LIKE lv_kougti;
--
    -- ����׏d�ʣ����חe�ϣ�Z�o
    IF (ln_cnt = 1) THEN
      -- �w�Ώہx�̏ꍇ
      gn_detail_we := NVL(gn_ttl_we,0);                       -- ���׏d��
      gn_detail_ca := NVL(gn_ttl_ca,0);                       -- ���חe��
    ELSE
      -- ��L�ȊO�̏ꍇ
      gn_detail_we := NVL(gn_ttl_we,0) + NVL(gn_ttl_prt_we,0);  -- ���׏d��
      gn_detail_ca := NVL(gn_ttl_ca,0) + NVL(gn_ttl_prt_we,0);  -- ���חe��
    END IF;
*/
    gn_detail_we := NVL(gn_ttl_we,0);                       -- ���׏d��
    gn_detail_ca := NVL(gn_ttl_ca,0);                       -- ���חe��
-- 2008/07/30 Mod ��
--
    -- ���ʊ֐��ɂāA���^�[���R�[�h���G���[���A�G���[
    IF (lv_retcode = gv_1) THEN
--
      -- �G���[���X�g�쐬
      pro_err_list_make
        (
          iv_kind         => gv_tkn_msg_err            --  in ���  '�G���['
         ,iv_dec          => gv_tkn_msg_hfn            --  in �m��  '-'
         ,iv_req_no       => gv_req_no                 --  in �˗�No
         ,iv_kyoten       => gt_to_plan(gn_i).ktn      --  in �Ǌ����_
         ,iv_item         => gt_to_plan(gn_i).item_no  --  in �i��
         ,in_qty          => gt_to_plan(gn_i).amount   --  in ����
         ,iv_ship_date    => gv_tkn_msg_hfn            --  in �o�ɓ� '-'
         ,iv_arrival_date => TO_CHAR(gt_to_plan(gn_i).for_date,'YYYY/MM/DD')
                                                       --  in ����
         ,iv_err_msg      => lv_errmsg                 --  in �G���[���b�Z�[�W
         ,iv_err_clm      => gv_tkn_msg_hfn            --  in �G���[����  '-'
         ,ov_errbuf       => lv_errbuf                 -- out �G���[�E���b�Z�[�W
         ,ov_retcode      => lv_retcode                -- out ���^�[���E�R�[�h
         ,ov_errmsg       => lv_errmsg                 -- out ���[�U�[�E�G���[�E���b�Z�[�W
        );
      -- ���ʃG���[���b�Z�[�W �I��ST �G���[�o�^
      gv_err_sts := gv_status_error;
--
      RAISE err_header_expt;
    END IF;
--
  EXCEPTION
    -- *** ���ʊ֐� �x���E�G���[ ***
    WHEN err_header_expt THEN
      gv_err_flg := gv_2;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END pro_total_we_ca;
--
  /**********************************************************************************
   * Procedure Name   : pro_ship_y_n_chk
   * Description      : �o�׉ۃ`�F�b�N (A-8)
   ***********************************************************************************/
  PROCEDURE pro_ship_y_n_chk
    (
      ov_errbuf     OUT VARCHAR2     --   �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode    OUT VARCHAR2     --   ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg     OUT VARCHAR2     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'pro_ship_y_n_chk'; -- �v���O������
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
    ln_result   NUMBER;
--
    -- *** ���[�J���ϐ� ***
    lv_errmsg_code VARCHAR2(30);  -- �G���[�E���b�Z�[�W�E�R�[�h
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -----------------------------------------------------------------------------------
    -- ���ʊ֐��u�o�׉ۃ`�F�b�N�v�ɂďo�׎��ѐ��ʁE�o�ח\�����ʂ�                  --
    --   �v�搔�ʂ�OVER���Ă��Ȃ����̃`�F�b�N                                        --
    -----------------------------------------------------------------------------------
    -----------------------------------
    -- �o�א�����(���i��) �`�F�b�N   --
    -----------------------------------
    xxwsh_common910_pkg.check_shipping_judgment
                                  (
                                    gv_2                      -- �`�F�b�N���@�敪 in �w2�x:���i��
                                   ,gt_to_plan(gn_i).ktn      -- ���_             in ���_
                                   ,gt_to_plan(gn_i).item_id  -- �i��ID           in �i��ID
                                   ,gt_to_plan(gn_i).amount   -- ����             in ����
                                   ,gt_to_plan(gn_i).for_date -- �Ώۓ�           in ���ח\���
                                   ,gt_to_plan(gn_i).ship_id  -- �o�׌�ID         in �o�׌�ID
                                   ,NULL
                                   ,lv_retcode                -- ���^�[���E�R�[�h
                                   ,lv_errmsg_code            -- �G���[�E���b�Z�[�W�E�R�[�h
                                   ,lv_errmsg                 -- ���[�U�[�E�G���[�E���b�Z�[�W
                                   ,ln_result                 -- ��������
                                  );
--
    -- �o�א�����(���i��) �o�׉ۃ`�F�b�N �ُ�I���̏ꍇ�A�G���[
    IF (lv_retcode = gv_1) THEN
--
      -- �G���[���X�g�쐬
      pro_err_list_make
        (
          iv_kind         => gv_tkn_msg_err                     --  in ���  '�G���['
         ,iv_dec          => gv_tkn_msg_hfn                     --  in �m��  '-'
         ,iv_req_no       => gv_req_no                          --  in �˗�No
         ,iv_kyoten       => gt_to_plan(gn_i).ktn               --  in �Ǌ����_
         ,iv_item         => gt_to_plan(gn_i).item_no           --  in �i��
         ,in_qty          => gt_to_plan(gn_i).amount            --  in ����
         ,iv_ship_date    => TO_CHAR(gd_ship_day,'YYYY/MM/DD')  --  in �o�ɓ� [�o�ח\���]
         ,iv_arrival_date => TO_CHAR(gt_to_plan(gn_i).for_date,'YYYY/MM/DD')
                                                                --  in ����
         ,iv_err_msg      => gv_tkn_msg_14 || lv_errmsg         --  in �G���[���b�Z�[�W
         ,iv_err_clm      => gv_tkn_msg_hfn                     --  in �G���[����  '-'
         ,ov_errbuf       => lv_errbuf                          -- out �G���[�E���b�Z�[�W
         ,ov_retcode      => lv_retcode                         -- out ���^�[���E�R�[�h
         ,ov_errmsg       => lv_errmsg                          -- out ���[�U�[�E�G���[�E���b�Z�[�W
        );
      -- ���ʃG���[���b�Z�[�W �I��ST �G���[�o�^
      gv_err_sts := gv_status_error;
--
      RAISE err_header_expt;
    END IF;
--
    -- �o�א�����(���i��)�`�F�b�N�ɂāu�������ʁv='1'(���ʃI�[�o�[�G���[)���A���[�j���O
    IF (ln_result = 1) THEN
--
      -- �G���[���X�g�쐬
      pro_err_list_make
        (
          iv_kind         => gv_tkn_msg_war                     --  in ���  '�x��'
         ,iv_dec          => gv_tkn_msg_err                     --  in �m��  '�G���['
         ,iv_req_no       => gv_req_no                          --  in �˗�No
         ,iv_kyoten       => gt_to_plan(gn_i).ktn               --  in �Ǌ����_
         ,iv_item         => gt_to_plan(gn_i).item_no           --  in �i��
         ,in_qty          => gt_to_plan(gn_i).amount            --  in ����
         ,iv_ship_date    => TO_CHAR(gd_ship_day,'YYYY/MM/DD')  --  in �o�ɓ� [�o�ח\���]
         ,iv_arrival_date => TO_CHAR(gt_to_plan(gn_i).for_date,'YYYY/MM/DD')
                                                                --  in ����
         ,iv_err_msg      => gv_tkn_msg_16                      --  in �G���[���b�Z�[�W
         ,iv_err_clm      => gt_to_plan(gn_i).amount            --  in �G���[����  [����]
         ,ov_errbuf       => lv_errbuf                          -- out �G���[�E���b�Z�[�W
         ,ov_retcode      => lv_retcode                         -- out ���^�[���E�R�[�h
         ,ov_errmsg       => lv_errmsg                          -- out ���[�U�[�E�G���[�E���b�Z�[�W
        );
      -- ���ʃG���[���b�Z�[�W �I��ST�̔���
      IF (gv_err_sts <> gv_status_error) THEN
        gv_err_sts := gv_status_warn;
      END IF;
    END IF;
--
    -----------------------------------
    -- �o�א�����(������) �`�F�b�N   --
    -----------------------------------
    xxwsh_common910_pkg.check_shipping_judgment(
                                    gv_3                     -- �`�F�b�N���@�敪 in �w3�x:������
                                   ,gt_to_plan(gn_i).ktn     -- ���_             in ���_
                                   ,gt_to_plan(gn_i).item_id -- �i��ID           in �i��ID
                                   ,gt_to_plan(gn_i).amount  -- ����             in ����
                                   ,gd_ship_day              -- �Ώۓ�           in �o�ח\���
                                   ,gt_to_plan(gn_i).ship_id -- �o�׌�ID         in �o�׌�ID
                                   ,NULL
                                   ,lv_retcode               -- ���^�[���E�R�[�h
                                   ,lv_errmsg_code           -- �G���[�E���b�Z�[�W�E�R�[�h
                                   ,lv_errmsg                -- ���[�U�[�E�G���[�E���b�Z�[�W
                                   ,ln_result                -- ��������
                                  );
--
    -- �o�א�����(������) �o�׉ۃ`�F�b�N �ُ�I���̏ꍇ�A�G���[
    IF (lv_retcode = gv_1) THEN
--
      -- �G���[���X�g�쐬
      pro_err_list_make
        (
          iv_kind         => gv_tkn_msg_err                     --  in ���  '�G���['
         ,iv_dec          => gv_tkn_msg_hfn                     --  in �m��  '-'
         ,iv_req_no       => gv_req_no                          --  in �˗�No
         ,iv_kyoten       => gt_to_plan(gn_i).ktn               --  in �Ǌ����_
         ,iv_item         => gt_to_plan(gn_i).item_no           --  in �i��
         ,in_qty          => gt_to_plan(gn_i).amount            --  in ����
         ,iv_ship_date    => TO_CHAR(gd_ship_day,'YYYY/MM/DD')  --  in �o�ɓ� [�o�ח\���]
         ,iv_arrival_date => TO_CHAR(gt_to_plan(gn_i).for_date,'YYYY/MM/DD')
                                                                --  in ����
         ,iv_err_msg      => gv_tkn_msg_15 || lv_errmsg         --  in �G���[���b�Z�[�W
         ,iv_err_clm      => gv_tkn_msg_hfn                     --  in �G���[����  '-'
         ,ov_errbuf       => lv_errbuf                          -- out �G���[�E���b�Z�[�W
         ,ov_retcode      => lv_retcode                         -- out ���^�[���E�R�[�h
         ,ov_errmsg       => lv_errmsg                          -- out ���[�U�[�E�G���[�E���b�Z�[�W
        );
      -- ���ʃG���[���b�Z�[�W �I��ST �G���[�o�^
      gv_err_sts := gv_status_error;
--
      RAISE err_header_expt;
    END IF;
--
    -- �o�א�����(������)�`�F�b�N�ɂāu�������ʁv='1'(���ʃI�[�o�[�G���[)���A���[�j���O
    IF (ln_result = 1) THEN
--
      -- �G���[���X�g�쐬
      pro_err_list_make
        (
          iv_kind         => gv_tkn_msg_war                     --  in ���  '�x��'
         ,iv_dec          => gv_tkn_msg_err                     --  in �m��  '�G���['
         ,iv_req_no       => gv_req_no                          --  in �˗�No
         ,iv_kyoten       => gt_to_plan(gn_i).ktn               --  in �Ǌ����_
         ,iv_item         => gt_to_plan(gn_i).item_no           --  in �i��
         ,in_qty          => gt_to_plan(gn_i).amount            --  in ����
         ,iv_ship_date    => TO_CHAR(gd_ship_day,'YYYY/MM/DD')  --  in �o�ɓ� [�o�ח\���]
         ,iv_arrival_date => TO_CHAR(gt_to_plan(gn_i).for_date,'YYYY/MM/DD')
                                                                --  in ����
         ,iv_err_msg      => gv_tkn_msg_17                      --  in �G���[���b�Z�[�W
         ,iv_err_clm      => gt_to_plan(gn_i).amount            --  in �G���[����  [����]
         ,ov_errbuf       => lv_errbuf                          -- out �G���[�E���b�Z�[�W
         ,ov_retcode      => lv_retcode                         -- out ���^�[���E�R�[�h
         ,ov_errmsg       => lv_errmsg                          -- out ���[�U�[�E�G���[�E���b�Z�[�W
        );
      -- ���ʃG���[���b�Z�[�W �I��ST�̔���
      IF (gv_err_sts <> gv_status_error) THEN
        gv_err_sts := gv_status_warn;
      END IF;
    END IF;
--
    -- �o�א�����(������)�`�F�b�N�ɂāu�������ʁv='2'(�o�ג�~���G���[)���A���[�j���O
    IF (ln_result = 2) THEN
--
      -- �G���[���X�g�쐬
      pro_err_list_make
        (
          iv_kind         => gv_tkn_msg_war                     --  in ���  '�x��'
         ,iv_dec          => gv_tkn_msg_err                     --  in �m��  '�G���['
         ,iv_req_no       => gv_req_no                          --  in �˗�No
         ,iv_kyoten       => gt_to_plan(gn_i).ktn               --  in �Ǌ����_
         ,iv_item         => gt_to_plan(gn_i).item_no           --  in �i��
         ,in_qty          => gt_to_plan(gn_i).amount            --  in ����
         ,iv_ship_date    => TO_CHAR(gd_ship_day,'YYYY/MM/DD')  --  in �o�ɓ� [�o�ח\���]
         ,iv_arrival_date => TO_CHAR(gt_to_plan(gn_i).for_date,'YYYY/MM/DD')
                                                                --  in ����
         ,iv_err_msg      => gv_tkn_msg_18                      --  in �G���[���b�Z�[�W
         ,iv_err_clm      => gt_to_plan(gn_i).amount            --  in �G���[����  [����]
         ,ov_errbuf       => lv_errbuf                          -- out �G���[�E���b�Z�[�W
         ,ov_retcode      => lv_retcode                         -- out ���^�[���E�R�[�h
         ,ov_errmsg       => lv_errmsg                          -- out ���[�U�[�E�G���[�E���b�Z�[�W
        );
      -- ���ʃG���[���b�Z�[�W �I��ST�̔���
      IF (gv_err_sts <> gv_status_error) THEN
        gv_err_sts := gv_status_warn;
      END IF;
    END IF;
--
  EXCEPTION
    -- *** ���ʊ֐� �x���E�G���[ ***
    WHEN err_header_expt THEN
      gv_err_flg := gv_2;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END pro_ship_y_n_chk;
--
  /**********************************************************************************
   * Procedure Name   : pro_lines_create
   * Description      : �󒍖��׃A�h�I�����R�[�h���� (A-9)
   ***********************************************************************************/
  PROCEDURE pro_lines_create
    (
      ov_errbuf     OUT VARCHAR2     -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode    OUT VARCHAR2     -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg     OUT VARCHAR2     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    )
  IS
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'pro_lines_create'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- *** ���[�J���ϐ� ***
    ln_mod_chk      NUMBER DEFAULT 0;      -- �����{�`�F�b�N
    lv_dsc          VARCHAR2(6);           -- �G���[���b�Z�[�W���e����
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -----------------------------
    -- 1.���הԍ��̍̔�        --
    -----------------------------
    -- ����_���o�׌������ח\������d�ʗe�ϋ敪��̔���
    IF ((gv_ktn      = gt_to_plan(gn_i).ktn)
    AND (gv_ship_fr  = gt_to_plan(gn_i).ship_fr)
    AND (gv_for_date = gt_to_plan(gn_i).for_date)
    AND (gv_wei_kbn  = gt_to_plan(gn_i).wei_kbn))
    THEN
      -- ���הԍ��J�E���g�{�P
      gn_line_number := gn_line_number + 1;
    -- ���񃌃R�[�h���A����_���o�׌������ח\������d�ʗe�ϋ敪��̂����A�P�ł��قȂ�ꍇ
    -- ���הԍ���[1]�Z�b�g
    ELSE
      gn_line_number := 1;
    END IF;
--
    ------------------------------------------------------
    -- 2.�󒍖��׃A�h�I���쐬�p���R�[�h�ϐ��֊i�[       --
    ------------------------------------------------------
    gn_l_cnt := gn_l_cnt + 1;
--
    gt_l_order_line_id(gn_l_cnt)          := gn_lines_seq;             -- �󒍖��׃A�h�I��ID
    gt_l_order_header_id(gn_l_cnt)        := gn_headers_seq;           -- �󒍃w�b�_�A�h�I��ID
    gt_l_order_line_number(gn_l_cnt)      := gn_line_number;           -- ���הԍ�
    gt_l_request_no(gn_l_cnt)             := gv_req_no;                -- �˗�No
    gt_l_shipping_inv_item_id(gn_l_cnt)   := gt_to_plan(gn_i).item_id; -- �o�וi��ID
    gt_l_shipping_item_code(gn_l_cnt)     := gt_to_plan(gn_i).item_no; -- �o�וi��
    gt_l_quantity(gn_l_cnt)               := gt_to_plan(gn_i).amount;  -- ����
    gt_l_uom_code(gn_l_cnt)               := gt_to_plan(gn_i).item_um; -- �P��
    gt_l_based_request_quantity(gn_l_cnt) := gt_to_plan(gn_i).amount;  -- ���_�˗�����
    gt_l_request_item_id(gn_l_cnt)        := gt_to_plan(gn_i).item_id; -- �˗��i��ID
    gt_l_request_item_code(gn_l_cnt)      := gt_to_plan(gn_i).item_no; -- �˗��i��
    gt_l_weight(gn_l_cnt)                 := NVL(gn_detail_we,0);      -- �d��
    gt_l_capacity(gn_l_cnt)               := NVL(gn_detail_ca,0);      -- �e��
    gt_l_pallet_weight(gn_l_cnt)          := NVL(gn_ttl_prt_we,0);     -- �p���b�g�d��
    gt_l_delete_flag(gn_l_cnt)            := 'N';                      -- �폜�t���O
    gt_l_created_by(gn_l_cnt)             := gn_created_by;            -- �쐬��
    gt_l_creation_date(gn_l_cnt)          := gd_creation_date;         -- �쐬��
    gt_l_last_updated_by(gn_l_cnt)        := gn_last_upd_by;           -- �ŏI�X�V��
    gt_l_last_update_date(gn_l_cnt)       := gd_last_upd_date;         -- �ŏI�X�V��
    gt_l_last_update_login(gn_l_cnt)      := gn_last_upd_login;        -- �ŏI�X�V���O�C��
    gt_l_request_id(gn_l_cnt)             := gn_request_id;            -- �v��ID
    gt_l_program_application_id(gn_l_cnt) := gn_prog_appl_id;          -- �v���O�����A�v��ID
    gt_l_program_id(gn_l_cnt)             := gn_prog_id;               -- �v���O����ID
    gt_l_program_update_date(gn_l_cnt)    := gd_prog_upd_date;         -- �v���O�����X�V��
--
    -- �o�׈˗��쐬���׌���(�˗����גP��) �J�E���g
    gn_line_cnt := gn_line_cnt + 1;
--
    ---------------------------------------------------
    -- 3.�o�גP�ʊ��Z���̎Z�o                        --
    ---------------------------------------------------
-- 2008/07/30 Mod ��
    -- (1).��o�ד������ > '0'�̏ꍇ
    IF (gt_to_plan(gn_i).ship_am > 0) THEN
      gn_ship_amount := CEIL(gt_to_plan(gn_i).amount / gt_to_plan(gn_i).ship_am);
--
      -- �󒍃w�b�_�A�h�I�����ڗp�ϐ� ���Z
      gn_ttl_amount   := gn_ttl_amount   + NVL(gt_to_plan(gn_i).amount,0);  -- ���v����
      gn_ttl_ship_am  := gn_ttl_ship_am  + gn_ship_amount;                  -- �o�גP�ʊ��Z��
      gn_h_ttl_weight := gn_h_ttl_weight + NVL(gn_detail_we,0);             -- �ύڏd�ʍ��v
      gn_h_ttl_capa   := gn_h_ttl_capa   + NVL(gn_detail_ca,0);             -- �ύڗe�ύ��v
      gn_h_ttl_pallet := gn_h_ttl_pallet + NVL(gn_ttl_prt_we,0);            -- ���v�p���b�g�d��
--
      -- ����ʣ����o�ד�����̐����{�ł͂Ȃ��ꍇ�A���[�j���O
      ln_mod_chk := MOD(gt_to_plan(gn_i).amount,gt_to_plan(gn_i).ship_am);
      IF (ln_mod_chk <> 0) THEN
--
      -- �G���[���X�g�쐬
        pro_err_list_make
          (
            iv_kind         => gv_tkn_msg_war                    --  in ���  '�x��'
           ,iv_dec          => gv_tkn_msg_err                    --  in �m��  '�G���['
           ,iv_req_no       => gv_req_no                         --  in �˗�No
           ,iv_kyoten       => gt_to_plan(gn_i).ktn              --  in �Ǌ����_
           ,iv_item         => gt_to_plan(gn_i).item_no          --  in �i��
           ,in_qty          => gt_to_plan(gn_i).amount           --  in ����
           ,iv_ship_date    => TO_CHAR(gd_ship_day,'YYYY/MM/DD') --  in �o�ɓ� [�o�ח\���]
           ,iv_arrival_date => TO_CHAR(gt_to_plan(gn_i).for_date,'YYYY/MM/DD')  --  in ����
           ,iv_err_msg      => gv_tkn_msg_19                     --  in �G���[���b�Z�[�W
           ,iv_err_clm      => gv_tkn_msg_hfn                    --  in �G���[����  '-'
           ,ov_errbuf       => lv_errbuf                         -- out �G���[�E���b�Z�[�W
           ,ov_retcode      => lv_retcode                        -- out ���^�[���E�R�[�h
           ,ov_errmsg       => lv_errmsg                         -- out ���[�U�[�E�G���[�Eү����
          );
        -- ���ʃG���[���b�Z�[�W �I��ST�̔���
        IF (gv_err_sts <> gv_status_error) THEN
          gv_err_sts := gv_status_warn;
        END IF;
      END IF;
--
    -- (2).��o�ד������ = '0',NULL�̏ꍇ
    ELSE
      -- (2-1).���o�Ɋ��Z�P�ʂ��ݒ肳��Ă���ꍇ
      IF (gt_to_plan(gn_i).conv_unit IS NOT NULL) THEN
--
        -- (2-1-1).��P�[�X������� > '0'�̏ꍇ
        IF (gt_to_plan(gn_i).case_am > 0) THEN
          gn_ship_amount := CEIL(gt_to_plan(gn_i).amount / gt_to_plan(gn_i).case_am);
--
          -- �󒍃w�b�_�A�h�I�����ڗp�ϐ� ���Z
          gn_ttl_amount   := gn_ttl_amount   + NVL(gt_to_plan(gn_i).amount,0);  -- ���v����
          gn_ttl_ship_am  := gn_ttl_ship_am  + gn_ship_amount;                  -- �o�גP�ʊ��Z��
          gn_h_ttl_weight := gn_h_ttl_weight + NVL(gn_detail_we,0);             -- �ύڏd�ʍ��v
          gn_h_ttl_capa   := gn_h_ttl_capa   + NVL(gn_detail_ca,0);             -- �ύڗe�ύ��v
          gn_h_ttl_pallet := gn_h_ttl_pallet + NVL(gn_ttl_prt_we,0);            -- ���v�p���b�g�d��
--
          -- ����ʣ���������̐����{�ł͂Ȃ��ꍇ�B���[�j���O
          ln_mod_chk := MOD(gt_to_plan(gn_i).amount,gt_to_plan(gn_i).case_am);
          IF (ln_mod_chk <> 0) THEN
            -- ���o�Ɋ��Z�P�ʂ̔���
            IF (gt_to_plan(gn_i).conv_unit IS NOT NULL) THEN
              -- ���o�Ɋ��Z�P�ʂ��ݒ肳��Ă���ꍇ�A�m�荀�� '�G���['
              lv_dsc := gv_tkn_msg_err;
            ELSE
              -- ���o�Ɋ��Z�P�ʂ����ݒ�̏ꍇ�A�m�荀�� '�|'
              lv_dsc := gv_tkn_msg_hfn;
            END IF;
--
            -- �G���[���X�g�쐬
            pro_err_list_make
              (
                iv_kind         => gv_tkn_msg_war                     --  in ���  '�x��'
               ,iv_dec          => lv_dsc                             --  in �m��
               ,iv_req_no       => gv_req_no                          --  in �˗�No
               ,iv_kyoten       => gt_to_plan(gn_i).ktn               --  in �Ǌ����_
               ,iv_item         => gt_to_plan(gn_i).item_no           --  in �i��
               ,in_qty          => gt_to_plan(gn_i).amount            --  in ����
               ,iv_ship_date    => TO_CHAR(gd_ship_day,'YYYY/MM/DD')  --  in �o�ɓ� [�o�ח\���]
               ,iv_arrival_date => TO_CHAR(gt_to_plan(gn_i).for_date,'YYYY/MM/DD')  --  in ����
               ,iv_err_msg      => gv_tkn_msg_21                      --  in �G���[���b�Z�[�W
               ,iv_err_clm      => gv_tkn_msg_hfn                     --  in �G���[����  '-'
               ,ov_errbuf       => lv_errbuf                          -- out �G���[�E���b�Z�[�W
               ,ov_retcode      => lv_retcode                         -- out ���^�[���E�R�[�h
               ,ov_errmsg       => lv_errmsg                          -- out ���[�U�[�E�װ�Eү����
              );
            -- ���ʃG���[���b�Z�[�W �I��ST�̔���
            IF (gv_err_sts <> gv_status_error) THEN
              gv_err_sts := gv_status_warn;
            END IF;
--
            RAISE err_header_expt;
          END IF;
--
        -- (2-1-2).��P�[�X������� = '0',NULL�̏ꍇ
        ELSE
--
          -- �G���[���X�g�쐬
          pro_err_list_make
            (
              iv_kind         => gv_tkn_msg_war                     --  in ���  '�x��'
             ,iv_dec          => lv_dsc                             --  in �m��
             ,iv_req_no       => gv_req_no                          --  in �˗�No
             ,iv_kyoten       => gt_to_plan(gn_i).ktn               --  in �Ǌ����_
             ,iv_item         => gt_to_plan(gn_i).item_no           --  in �i��
             ,in_qty          => gt_to_plan(gn_i).amount            --  in ����
             ,iv_ship_date    => TO_CHAR(gd_ship_day,'YYYY/MM/DD')  --  in �o�ɓ� [�o�ח\���]
             ,iv_arrival_date => TO_CHAR(gt_to_plan(gn_i).for_date,'YYYY/MM/DD')  --  in ����
             ,iv_err_msg      => gv_tkn_msg_24                      --  in �G���[���b�Z�[�W
             ,iv_err_clm      => gv_tkn_msg_hfn                     --  in �G���[����  '-'
             ,ov_errbuf       => lv_errbuf                          -- out �G���[�E���b�Z�[�W
             ,ov_retcode      => lv_retcode                         -- out ���^�[���E�R�[�h
             ,ov_errmsg       => lv_errmsg                          -- out ���[�U�[�E�װ�Eү����
            );
          -- ���ʃG���[���b�Z�[�W �I��ST�̔���
          IF (gv_err_sts <> gv_status_error) THEN
            gv_err_sts := gv_status_warn;
          END IF;
--
          gn_ship_amount  := gt_to_plan(gn_i).amount;
--
          -- �󒍃w�b�_�A�h�I�����ڗp�ϐ� ���Z
          gn_ttl_amount   := gn_ttl_amount   + NVL(gt_to_plan(gn_i).amount,0);  -- ���v����
          gn_ttl_ship_am  := gn_ttl_ship_am  + gn_ship_amount;                  -- �o�גP�ʊ��Z��
          gn_h_ttl_weight := gn_h_ttl_weight + NVL(gn_detail_we,0);             -- �ύڏd�ʍ��v
          gn_h_ttl_capa   := gn_h_ttl_capa   + NVL(gn_detail_ca,0);             -- �ύڗe�ύ��v
          gn_h_ttl_pallet := gn_h_ttl_pallet + NVL(gn_ttl_prt_we,0);            -- ���v�p���b�g�d��
        END IF;
--
      -- (2-2).���o�Ɋ��Z�P�ʂ��ݒ肳��Ă��Ȃ��ꍇ
      ELSE
        gn_ship_amount  := gt_to_plan(gn_i).amount;
--
        -- �󒍃w�b�_�A�h�I�����ڗp�ϐ� ���Z
        gn_ttl_amount   := gn_ttl_amount   + NVL(gt_to_plan(gn_i).amount,0);  -- ���v����
        gn_ttl_ship_am  := gn_ttl_ship_am  + gn_ship_amount;                  -- �o�גP�ʊ��Z��
        gn_h_ttl_weight := gn_h_ttl_weight + NVL(gn_detail_we,0);             -- �ύڏd�ʍ��v
        gn_h_ttl_capa   := gn_h_ttl_capa   + NVL(gn_detail_ca,0);             -- �ύڗe�ύ��v
        gn_h_ttl_pallet := gn_h_ttl_pallet + NVL(gn_ttl_prt_we,0);            -- ���v�p���b�g�d��
      END IF;
    END IF;
--
-- 2008/08/18 H.Itou Add Start �ύڌ���(�d��)�E�ύڌ���(�e��)���b�Z�[�W�p�Ƀ_�~�[�G���[���b�Z�[�W�쐬�B
    -- �e�[�u���J�E���g
    gn_cut := gn_cut + 1;
    gt_err_msg(gn_cut).err_msg  := NULL;
    gt_to_plan(gn_i).we_loading_msg_seq := gn_cut; -- �ύڌ���(�d��)���b�Z�[�W�i�[SEQ
--
    -- �e�[�u���J�E���g
    gn_cut := gn_cut + 1;
    gt_err_msg(gn_cut).err_msg  := NULL;
    gt_to_plan(gn_i).ca_loading_msg_seq := gn_cut; -- �ύڌ���(�e��)���b�Z�[�W�i�[SEQ
--
-- 2008/08/18 H.Itou Add End
/*
    ---------------------------------------------------
    -- 3.�o�גP�ʊ��Z���̎Z�o                        --
    ---------------------------------------------------
    -- (1).��o�ד�������ݒ肳��Ă���ꍇ�A�u���ʁv/�u�o�ד����v(�����_�ȉ��l�̌ܓ�)
    IF (gt_to_plan(gn_i).ship_am IS NOT NULL) THEN
      -- 0���Z����
      IF (gt_to_plan(gn_i).ship_am = 0) THEN
        gn_ship_amount := 0;
      ELSE
        gn_ship_amount := ROUND(gt_to_plan(gn_i).amount / gt_to_plan(gn_i).ship_am,0);
      END IF;
--
      -- �󒍃w�b�_�A�h�I�����ڗp�ϐ� ���Z
      gn_ttl_amount   := gn_ttl_amount   + NVL(gt_to_plan(gn_i).amount,0);  -- ���v����
      gn_ttl_ship_am  := gn_ttl_ship_am  + gn_ship_amount;                  -- �o�גP�ʊ��Z��
      gn_h_ttl_weight := gn_h_ttl_weight + NVL(gn_detail_we,0);             -- �ύڏd�ʍ��v
      gn_h_ttl_capa   := gn_h_ttl_capa   + NVL(gn_detail_ca,0);             -- �ύڗe�ύ��v
      gn_h_ttl_pallet := gn_h_ttl_pallet + NVL(gn_ttl_prt_we,0);            -- ���v�p���b�g�d��
--
      -- ����ʣ����o�ד�����̐����{�ł͂Ȃ��ꍇ�A���[�j���O
      ln_mod_chk := MOD(gt_to_plan(gn_i).amount,gt_to_plan(gn_i).ship_am);
      IF (ln_mod_chk <> 0) THEN
        pro_err_list_make
          (
            iv_kind         => gv_tkn_msg_war                    --  in ���  '�x��'
           ,iv_dec          => gv_tkn_msg_err                    --  in �m��  '�G���['
           ,iv_req_no       => gv_req_no                         --  in �˗�No
           ,iv_kyoten       => gt_to_plan(gn_i).ktn              --  in �Ǌ����_
           ,iv_item         => gt_to_plan(gn_i).item_no          --  in �i��
           ,in_qty          => gt_to_plan(gn_i).amount           --  in ����
           ,iv_ship_date    => TO_CHAR(gd_ship_day,'YYYY/MM/DD') --  in �o�ɓ� [�o�ח\���]
           ,iv_arrival_date => TO_CHAR(gt_to_plan(gn_i).for_date,'YYYY/MM/DD')
                                                                 --  in ����
           ,iv_err_msg      => gv_tkn_msg_19                     --  in �G���[���b�Z�[�W
           ,iv_err_clm      => gv_tkn_msg_hfn                    --  in �G���[����  '-'
           ,ov_errbuf       => lv_errbuf                         -- out �G���[�E���b�Z�[�W
           ,ov_retcode      => lv_retcode                        -- out ���^�[���E�R�[�h
           ,ov_errmsg       => lv_errmsg                         -- out ���[�U�[�E�G���[�E���b�Z�[�W
          );
        -- ���ʃG���[���b�Z�[�W �I��ST�̔���
        IF (gv_err_sts <> gv_status_error) THEN
          gv_err_sts := gv_status_warn;
        END IF;
      END IF;
--
    -- (2).(1)�ȊO�A���������ݒ肳��Ă���ꍇ�A�u���ʁv/�u�����v(�����_�ȉ��l�̌ܓ�)
    ELSIF (gt_to_plan(gn_i).case_am IS NOT NULL) THEN
      -- 0���Z����
      IF (gt_to_plan(gn_i).case_am = 0) THEN
        gn_ship_amount := 0;
      ELSE
        gn_ship_amount := ROUND(gt_to_plan(gn_i).amount / gt_to_plan(gn_i).case_am,0);
      END IF;
--
      -- �󒍃w�b�_�A�h�I�����ڗp�ϐ� ���Z
      gn_ttl_amount   := gn_ttl_amount   + NVL(gt_to_plan(gn_i).amount,0);  -- ���v����
      gn_ttl_ship_am  := gn_ttl_ship_am  + gn_ship_amount;                  -- �o�גP�ʊ��Z��
      gn_h_ttl_weight := gn_h_ttl_weight + NVL(gn_detail_we,0);             -- �ύڏd�ʍ��v
      gn_h_ttl_capa   := gn_h_ttl_capa   + NVL(gn_detail_ca,0);             -- �ύڗe�ύ��v
      gn_h_ttl_pallet := gn_h_ttl_pallet + NVL(gn_ttl_prt_we,0);            -- ���v�p���b�g�d��
--
      -- ����ʣ���������̐����{�ł͂Ȃ��ꍇ�B���[�j���O
      ln_mod_chk := MOD(gt_to_plan(gn_i).amount,gt_to_plan(gn_i).case_am);
      IF (ln_mod_chk <> 0) THEN
        -- ���o�Ɋ��Z�P�ʂ̔���
        IF (gt_to_plan(gn_i).conv_unit IS NOT NULL) THEN
          -- ���o�Ɋ��Z�P�ʂ��ݒ肳��Ă���ꍇ�A�m�荀�� '�G���['
          lv_dsc := gv_tkn_msg_err;
        ELSE
          -- ���o�Ɋ��Z�P�ʂ����ݒ�̏ꍇ�A�m�荀�� '�|'
          lv_dsc := gv_tkn_msg_hfn;
        END IF;
--
        pro_err_list_make
          (
            iv_kind         => gv_tkn_msg_war                     --  in ���  '�x��'
           ,iv_dec          => lv_dsc                             --  in �m��
           ,iv_req_no       => gv_req_no                          --  in �˗�No
           ,iv_kyoten       => gt_to_plan(gn_i).ktn               --  in �Ǌ����_
           ,iv_item         => gt_to_plan(gn_i).item_no           --  in �i��
           ,in_qty          => gt_to_plan(gn_i).amount            --  in ����
           ,iv_ship_date    => TO_CHAR(gd_ship_day,'YYYY/MM/DD')  --  in �o�ɓ� [�o�ח\���]
           ,iv_arrival_date => TO_CHAR(gt_to_plan(gn_i).for_date,'YYYY/MM/DD')
                                                                  --  in ����
           ,iv_err_msg      => gv_tkn_msg_21                      --  in �G���[���b�Z�[�W
           ,iv_err_clm      => gv_tkn_msg_hfn                     --  in �G���[����  '-'
           ,ov_errbuf       => lv_errbuf                          -- out �G���[�E���b�Z�[�W
           ,ov_retcode      => lv_retcode                         -- out ���^�[���E�R�[�h
           ,ov_errmsg       => lv_errmsg                          -- out ���[�U�[�E�G���[�E���b�Z�[�W
          );
        -- ���ʃG���[���b�Z�[�W �I��ST�̔���
        IF (gv_err_sts <> gv_status_error) THEN
          gv_err_sts := gv_status_warn;
        END IF;
--
        RAISE err_header_expt;
      END IF;
--
    -- (3).(2)�ȊO�A�u���ʁv�ݒ�
    ELSE
      gn_ship_amount := gt_to_plan(gn_i).amount;
--
      -- �󒍃w�b�_�A�h�I�����ڗp�ϐ� ���Z
      gn_ttl_amount   := gn_ttl_amount   + NVL(gt_to_plan(gn_i).amount,0);  -- ���v����
      gn_ttl_ship_am  := gn_ttl_ship_am  + gn_ship_amount;                  -- �o�גP�ʊ��Z��
      gn_h_ttl_weight := gn_h_ttl_weight + NVL(gn_detail_we,0);             -- �ύڏd�ʍ��v
      gn_h_ttl_capa   := gn_h_ttl_capa   + NVL(gn_detail_ca,0);             -- �ύڗe�ύ��v
      gn_h_ttl_pallet := gn_h_ttl_pallet + NVL(gn_ttl_prt_we,0);            -- ���v�p���b�g�d��
--
    END IF;
*/
-- 2008/07/30 Mod ��
--
  EXCEPTION
    -- *** ���ʊ֐� �x���E�G���[ ***
    WHEN err_header_expt THEN
      gv_err_flg := gv_2;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END pro_lines_create;
--
  /**********************************************************************************
   * Procedure Name   : pro_load_eff_chk
   * Description      : �ύڌ����`�F�b�N (A-10)
   ***********************************************************************************/
  PROCEDURE pro_load_eff_chk
    (
      in_plan_cnt   IN  NUMBER       -- �ΏۂƂ��Ă���Forecast�̌��� --2008/08/06 Add
     ,ov_errbuf     OUT VARCHAR2     -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode    OUT VARCHAR2     -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg     OUT VARCHAR2     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    )
  IS
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'pro_load_eff_chk'; -- �v���O������
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
    lv_errmsg_code VARCHAR2(30);  -- �G���[�E���b�Z�[�W�E�R�[�h
--
    ln_cnt     NUMBER;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    ln_cnt := in_plan_cnt;
--
   -- ���ʊ֐���ύڌ����`�F�b�N(�ύڌ����Z�o)��ɂă`�F�b�N (���׏d�ʂ̏ꍇ)
    xxwsh_common910_pkg.calc_load_efficiency
                            (
                              gn_h_ttl_weight             -- ���v�d��         in �ύڏd�ʍ��v
                             ,NULL                        -- ���v�e��         in NULL
                             ,gv_4                        -- �R�[�h�敪From   in �q��'4'
/* 2008/08/06 Mod ��
                             ,gt_to_plan(gn_i).ship_fr    -- ���o�ɋ敪From   in �o�׌�
2008/08/06 Mod �� */
                             ,gt_to_plan(ln_cnt).ship_fr  -- ���o�ɋ敪From   in �o�׌�
                             ,gv_9                        -- �R�[�h�敪To     in �z����'9'
/* 2008/08/06 Mod ��
                             ,gt_to_plan(gn_i).ship_t_no  -- ���o�ɋ敪To     in �z����
2008/08/06 Mod �� */
                             ,gt_to_plan(ln_cnt).ship_t_no -- ���o�ɋ敪To     in �z����
                             ,gv_max_kbn                  -- �ő�z���敪     in �ő�z���敪
/* 2008/08/06 Mod ��
                             ,gt_to_plan(gn_i).skbn       -- ���i�敪         in ���i�敪(���[�t)
2008/08/06 Mod �� */
                             ,gt_to_plan(ln_cnt).skbn     -- ���i�敪         in ���i�敪(���[�t)
                             ,NULL                        -- �����z�ԑΏۋ敪 in NULL
                             ,gd_ship_day                 -- ���           in �o�ח\���
                             ,lv_retcode                  -- ���^�[���E�R�[�h
                             ,lv_errmsg_code              -- �G���[�E���b�Z�[�W�E�R�[�h
                             ,lv_errmsg                   -- �G���[�E���b�Z�[�W
                             ,gv_over_kbn                 -- �ύڃI�[�o�[�敪 0:����,1:�I�[�o�[
                             ,gv_ship_way                 -- �o�ו��@
                             ,gn_we_loading               -- �d�ʐύڌ���
                             ,gn_ca_dammy                 -- �e�ϐύڌ���
                             ,gv_mix_ship                 -- ���ڔz���敪
                            );
--
    -- ���^�[���R�[�h���G���[���A�G���[
    IF (lv_retcode = gv_1) THEN
--
-- 2008/08/13 H.Itou ADD START �o�גǉ�_1 �ύڌ����G���[�̃��[�j���O�͖��ׂ��Ƃɏo��
      <<err_loop>>
      FOR i IN ln_cnt - gn_line_number + 1..ln_cnt LOOP
-- 2008/08/13 H.Itou ADD END
      -- �G���[���X�g�쐬
-- 2008/08/13 H.Itou MOD START
--      pro_err_list_make
--        (
--          iv_kind         => gv_tkn_msg_err                     --  in ���  '�G���['
--         ,iv_dec          => gv_tkn_msg_hfn                     --  in �m��  '-'
--         ,iv_req_no       => gv_req_no                          --  in �˗�No
--/* 2008/08/06 Mod ��
--         ,iv_kyoten       => gt_to_plan(gn_i).ktn               --  in �Ǌ����_
--2008/08/06 Mod �� */
--         ,iv_kyoten       => gt_to_plan(ln_cnt).ktn             --  in �Ǌ����_
--/* 2008/08/06 Mod ��
--         ,iv_item         => gt_to_plan(gn_i).item_no           --  in �i��
--2008/08/06 Mod �� */
--         ,iv_item         => gt_to_plan(ln_cnt).item_no         --  in �i��
--/* 2008/08/06 Mod ��
--         ,in_qty          => gt_to_plan(gn_i).amount            --  in ����
--2008/08/06 Mod �� */
--         ,in_qty          => gt_to_plan(ln_cnt).amount          --  in ����
--         ,iv_ship_date    => TO_CHAR(gd_ship_day,'YYYY/MM/DD')  --  in �o�ɓ� [�o�ח\���]
--/* 2008/08/06 Mod ��
--         ,iv_arrival_date => TO_CHAR(gt_to_plan(gn_i).for_date,'YYYY/MM/DD')
--2008/08/06 Mod �� */
--         ,iv_arrival_date => TO_CHAR(gt_to_plan(ln_cnt).for_date,'YYYY/MM/DD')
--                                                                --  in ����
--         ,iv_err_msg      => lv_errmsg                          --  in �G���[���b�Z�[�W
--         ,iv_err_clm      => gv_tkn_msg_hfn                     --  in �G���[����  '-'
--         ,ov_errbuf       => lv_errbuf                          -- out �G���[�E���b�Z�[�W
--         ,ov_retcode      => lv_retcode                         -- out ���^�[���E�R�[�h
--         ,ov_errmsg       => lv_errmsg                          -- out ���[�U�[�E�G���[�E���b�Z�[�W
--        );
        pro_err_list_make
          (
            iv_kind         => gv_tkn_msg_war                     --  in ���  '�x��'
           ,iv_dec          => gv_tkn_msg_err                     --  in �m��  '�G���['
           ,iv_req_no       => gv_req_no                          --  in �˗�No
           ,iv_kyoten       => gt_to_plan(i).ktn                  --  in �Ǌ����_
           ,iv_item         => gt_to_plan(i).item_no              --  in �i��
           ,in_qty          => gt_to_plan(i).amount               --  in ����
           ,iv_ship_date    => TO_CHAR(gd_ship_day,'YYYY/MM/DD')  --  in �o�ɓ� [�o�ח\���]
           ,iv_arrival_date => TO_CHAR(gt_to_plan(i).for_date,'YYYY/MM/DD')
                                                                  --  in ����
           ,iv_err_msg      => gv_tkn_msg_20                      --  in �G���[���b�Z�[�W
           ,iv_err_clm      => gt_to_plan(i).amount               --  in �G���[����  [����]
-- 2008/08/18 H.Itou Add Start �ύڌ������b�Z�[�W���i�[����SEQ�ԍ�
           ,in_calc_load_eff_msg_seq => gt_to_plan(i).we_loading_msg_seq -- �ύڌ���(�d��)���b�Z�[�W�i�[SEQ
--
-- 2008/08/18 H.Itou Add End
           ,ov_errbuf       => lv_errbuf                          -- out �G���[�E���b�Z�[�W
           ,ov_retcode      => lv_retcode                         -- out ���^�[���E�R�[�h
           ,ov_errmsg       => lv_errmsg                          -- out ���[�U�[�E�G���[�E���b�Z�[�W
          );
-- 2008/08/13 H.Itou MOD END
-- 2008/08/13 H.Itou ADD START
      END LOOP err_loop;
-- 2008/08/13 H.Itou ADD END
      -- ���ʃG���[���b�Z�[�W �I��ST �G���[�o�^
      gv_err_sts := gv_status_error;
--
      RAISE err_header_expt;
    END IF;
--
-- 2008/08/06 Mod ��
-- 2008/07/30 Mod ��
--/*
--    -- �ύڃI�[�o�[���A���[�j���O
--    IF (gv_over_kbn = gv_1) THEN
--*/
--    -- �d�ʗe�ϋ敪���d�ʂŐύڃI�[�o�[���A���[�j���O
--    IF ((gv_over_kbn = gv_1) AND (gt_to_plan(gn_i).wei_kbn = gv_1)) THEN
    IF ((gv_over_kbn = gv_1) AND (gt_to_plan(ln_cnt).wei_kbn = gv_1)) THEN
-- 2008/07/30 Mod ��
-- 2008/08/06 Mod ��
--
-- 2008/08/13 H.Itou ADD START �o�גǉ�_1 �ύڌ����G���[�̃��[�j���O�͖��ׂ��Ƃɏo��
      <<warn_loop>>
      FOR i IN ln_cnt - gn_line_number + 1..ln_cnt LOOP
-- 2008/08/13 H.Itou ADD END
      -- �G���[���X�g�쐬
-- 2008/08/13 H.Itou MOD START
--      pro_err_list_make
--        (
--          iv_kind         => gv_tkn_msg_war                     --  in ���  '�x��'
--         ,iv_dec          => gv_tkn_msg_err                     --  in �m��  '�G���['
--         ,iv_req_no       => gv_req_no                          --  in �˗�No
--/* 2008/08/06 Mod ��
--         ,iv_kyoten       => gt_to_plan(gn_i).ktn               --  in �Ǌ����_
--2008/08/06 Mod �� */
--         ,iv_kyoten       => gt_to_plan(ln_cnt).ktn             --  in �Ǌ����_
--/* 2008/08/06 Mod ��
--         ,iv_item         => gt_to_plan(gn_i).item_no           --  in �i��
--2008/08/06 Mod �� */
--         ,iv_item         => gt_to_plan(ln_cnt).item_no         --  in �i��
--/* 2008/08/06 Mod ��
--         ,in_qty          => gt_to_plan(gn_i).amount            --  in ����
--2008/08/06 Mod �� */
--         ,in_qty          => gt_to_plan(ln_cnt).amount          --  in ����
--         ,iv_ship_date    => TO_CHAR(gd_ship_day,'YYYY/MM/DD')  --  in �o�ɓ� [�o�ח\���]
--/* 2008/08/06 Mod ��
--         ,iv_arrival_date => TO_CHAR(gt_to_plan(gn_i).for_date,'YYYY/MM/DD')
--2008/08/06 Mod �� */
--         ,iv_arrival_date => TO_CHAR(gt_to_plan(ln_cnt).for_date,'YYYY/MM/DD')
--                                                                --  in ����
--         ,iv_err_msg      => gv_tkn_msg_20                      --  in �G���[���b�Z�[�W
--/* 2008/08/06 Mod ��
--         ,iv_err_clm      => gt_to_plan(gn_i).amount            --  in �G���[����  [����]
--2008/08/06 Mod �� */
--         ,iv_err_clm      => gt_to_plan(ln_cnt).amount          --  in �G���[����  [����]
--         ,ov_errbuf       => lv_errbuf                          -- out �G���[�E���b�Z�[�W
--         ,ov_retcode      => lv_retcode                         -- out ���^�[���E�R�[�h
--         ,ov_errmsg       => lv_errmsg                          -- out ���[�U�[�E�G���[�E���b�Z�[�W
--        );
        pro_err_list_make
          (
            iv_kind         => gv_tkn_msg_war                     --  in ���  '�x��'
           ,iv_dec          => gv_tkn_msg_err                     --  in �m��  '�G���['
           ,iv_req_no       => gv_req_no                          --  in �˗�No
           ,iv_kyoten       => gt_to_plan(i).ktn                  --  in �Ǌ����_
           ,iv_item         => gt_to_plan(i).item_no              --  in �i��
           ,in_qty          => gt_to_plan(i).amount               --  in ����
           ,iv_ship_date    => TO_CHAR(gd_ship_day,'YYYY/MM/DD')  --  in �o�ɓ� [�o�ח\���]
           ,iv_arrival_date => TO_CHAR(gt_to_plan(i).for_date,'YYYY/MM/DD')
                                                                  --  in ����
           ,iv_err_msg      => gv_tkn_msg_20                      --  in �G���[���b�Z�[�W
           ,iv_err_clm      => gt_to_plan(i).amount               --  in �G���[����  [����]
-- 2008/08/18 H.Itou Add Start �ύڌ������b�Z�[�W���i�[����SEQ�ԍ�
           ,in_calc_load_eff_msg_seq => gt_to_plan(i).we_loading_msg_seq -- �ύڌ���(�d��)���b�Z�[�W�i�[SEQ
-- 2008/08/18 H.Itou Add End
           ,ov_errbuf       => lv_errbuf                          -- out �G���[�E���b�Z�[�W
           ,ov_retcode      => lv_retcode                         -- out ���^�[���E�R�[�h
           ,ov_errmsg       => lv_errmsg                          -- out ���[�U�[�E�G���[�E���b�Z�[�W
          );
-- 2008/08/13 H.Itou MOD END
-- 2008/08/13 H.Itou MOD START
        -- ���ʃG���[���b�Z�[�W �I��ST�̔���
        IF (gv_err_sts <> gv_status_error) THEN
          gv_err_sts := gv_status_warn;
        END IF;
-- 2008/08/13 H.Itou MOD END
-- 2008/08/13 H.Itou ADD START
      END LOOP warn_loop;
-- 2008/08/13 H.Itou ADD END
    END IF;
--
    -- ���ʊ֐���ύڌ����`�F�b�N(�ύڌ����Z�o)��ɂă`�F�b�N (���חe�ς̏ꍇ)
    xxwsh_common910_pkg.calc_load_efficiency
                            (
                              NULL                        -- ���v�d��         in NULL
                             ,gn_h_ttl_capa               -- ���v�e��         in �ύڗe�ύ��v
                             ,gv_4                        -- �R�[�h�敪From   in �q��'4'
/* 2008/08/06 Mod ��
                             ,gt_to_plan(gn_i).ship_fr    -- ���o�ɋ敪From   in �o�׌�
2008/08/06 Mod �� */
                             ,gt_to_plan(ln_cnt).ship_fr  -- ���o�ɋ敪From   in �o�׌�
                             ,gv_9                        -- �R�[�h�敪To     in �z����'9'
/* 2008/08/06 Mod ��
                             ,gt_to_plan(gn_i).ship_t_no  -- ���o�ɋ敪To     in �z����
2008/08/06 Mod �� */
                             ,gt_to_plan(ln_cnt).ship_t_no  -- ���o�ɋ敪To     in �z����
                             ,gv_max_kbn                  -- �ő�z���敪     in �ő�z���敪
/* 2008/08/06 Mod ��
                             ,gt_to_plan(gn_i).skbn       -- ���i�敪         in ���i�敪(���[�t)
2008/08/06 Mod �� */
                             ,gt_to_plan(ln_cnt).skbn     -- ���i�敪         in ���i�敪(���[�t)
                             ,NULL                        -- �����z�ԑΏۋ敪 in NULL
                             ,gd_ship_day                 -- ���           in �o�ח\���
                             ,lv_retcode                  -- ���^�[���E�R�[�h
                             ,lv_errmsg_code              -- �G���[�E���b�Z�[�W�E�R�[�h
                             ,lv_errmsg                   -- �G���[�E���b�Z�[�W
                             ,gv_over_kbn                 -- �ύڃI�[�o�[�敪 0:����,1:�I�[�o�[
                             ,gv_ship_way                 -- �o�ו��@
                             ,gn_we_dammy                 -- �d�ʐύڌ���
                             ,gn_ca_loading               -- �e�ϐύڌ���
                             ,gv_mix_ship                 -- ���ڔz���敪
                            );
--
    -- ���^�[���R�[�h���G���[���A�G���[
    IF (lv_retcode = gv_1) THEN
--
-- 2008/08/13 H.Itou ADD START �o�גǉ�_1 �ύڌ����G���[�̃��[�j���O�͖��ׂ��Ƃɏo��
      <<err_loop>>
      FOR i IN ln_cnt - gn_line_number + 1..ln_cnt LOOP
-- 2008/08/13 H.Itou ADD END
      -- �G���[���X�g�쐬
-- 2008/08/13 H.Itou MOD START
--      pro_err_list_make
--        (
--          iv_kind         => gv_tkn_msg_err                     --  in ���  '�G���['
--         ,iv_dec          => gv_tkn_msg_hfn                     --  in �m��  '-'
--         ,iv_req_no       => gv_req_no                          --  in �˗�No
--/* 2008/08/06 Mod ��
--         ,iv_kyoten       => gt_to_plan(gn_i).ktn               --  in �Ǌ����_
--2008/08/06 Mod �� */
--         ,iv_kyoten       => gt_to_plan(ln_cnt).ktn             --  in �Ǌ����_
--/* 2008/08/06 Mod ��
--         ,iv_item         => gt_to_plan(gn_i).item_no           --  in �i��
--2008/08/06 Mod �� */
--         ,iv_item         => gt_to_plan(ln_cnt).item_no         --  in �i��
--/* 2008/08/06 Mod ��
--         ,in_qty          => gt_to_plan(gn_i).amount            --  in ����
--2008/08/06 Mod �� */
--         ,in_qty          => gt_to_plan(ln_cnt).amount          --  in ����
--         ,iv_ship_date    => TO_CHAR(gd_ship_day,'YYYY/MM/DD')  --  in �o�ɓ� [�o�ח\���]
--/* 2008/08/06 Mod ��
--         ,iv_arrival_date => TO_CHAR(gt_to_plan(gn_i).for_date,'YYYY/MM/DD')
--2008/08/06 Mod �� */
--         ,iv_arrival_date => TO_CHAR(gt_to_plan(ln_cnt).for_date,'YYYY/MM/DD')
--                                                                --  in ����
--         ,iv_err_msg      => lv_errmsg                          --  in �G���[���b�Z�[�W
--         ,iv_err_clm      => gv_tkn_msg_hfn                     --  in �G���[����  '-'
--         ,ov_errbuf       => lv_errbuf                          -- out �G���[�E���b�Z�[�W
--         ,ov_retcode      => lv_retcode                         -- out ���^�[���E�R�[�h
--         ,ov_errmsg       => lv_errmsg                          -- out ���[�U�[�E�G���[�E���b�Z�[�W
--        );
        pro_err_list_make
          (
            iv_kind         => gv_tkn_msg_war                     --  in ���  '�x��'
           ,iv_dec          => gv_tkn_msg_err                     --  in �m��  '�G���['
           ,iv_req_no       => gv_req_no                          --  in �˗�No
           ,iv_kyoten       => gt_to_plan(i).ktn                  --  in �Ǌ����_
           ,iv_item         => gt_to_plan(i).item_no              --  in �i��
           ,in_qty          => gt_to_plan(i).amount               --  in ����
           ,iv_ship_date    => TO_CHAR(gd_ship_day,'YYYY/MM/DD')  --  in �o�ɓ� [�o�ח\���]
           ,iv_arrival_date => TO_CHAR(gt_to_plan(i).for_date,'YYYY/MM/DD')
                                                                  --  in ����
           ,iv_err_msg      => gv_tkn_msg_20                      --  in �G���[���b�Z�[�W
           ,iv_err_clm      => gt_to_plan(i).amount               --  in �G���[����  [����]
-- 2008/08/18 H.Itou Add Start �ύڌ������b�Z�[�W���i�[����SEQ�ԍ�
           ,in_calc_load_eff_msg_seq => gt_to_plan(i).ca_loading_msg_seq -- �ύڌ���(�e��)���b�Z�[�W�i�[SEQ
-- 2008/08/18 H.Itou Add End
           ,ov_errbuf       => lv_errbuf                          -- out �G���[�E���b�Z�[�W
           ,ov_retcode      => lv_retcode                         -- out ���^�[���E�R�[�h
           ,ov_errmsg       => lv_errmsg                          -- out ���[�U�[�E�G���[�E���b�Z�[�W
          );
-- 2008/08/13 H.Itou MOD END
-- 2008/08/13 H.Itou ADD START
      END LOOP err_loop;
-- 2008/08/13 H.Itou ADD END
      -- ���ʃG���[���b�Z�[�W �I��ST �G���[�o�^
      gv_err_sts := gv_status_error;
--
      RAISE err_header_expt;
    END IF;
--
-- 2008/08/06 Mod ��
-- 2008/07/30 Mod ��
--/*
--    -- �ύڃI�[�o�[���A���[�j���O
--    IF (gv_over_kbn = gv_1) THEN
--*/
--    -- �d�ʗe�ϋ敪���e�ςŐύڃI�[�o�[���A���[�j���O
--    IF ((gv_over_kbn = gv_1) AND (gt_to_plan(gn_i).wei_kbn = gv_2)) THEN
    IF ((gv_over_kbn = gv_1) AND (gt_to_plan(ln_cnt).wei_kbn = gv_2)) THEN
-- 2008/07/30 Mod ��
-- 2008/08/06 Mod ��
--
-- 2008/08/13 H.Itou ADD START �o�גǉ�_1 �ύڌ����G���[�̃��[�j���O�͖��ׂ��Ƃɏo��
      <<warn_loop>>
      FOR i IN ln_cnt - gn_line_number + 1..ln_cnt LOOP
-- 2008/08/13 H.Itou ADD END
      -- �G���[���X�g�쐬
-- 2008/08/13 H.Itou MOD START
--      pro_err_list_make
--        (
--          iv_kind         => gv_tkn_msg_war                     --  in ���  '�x��'
--         ,iv_dec          => gv_tkn_msg_err                     --  in �m��  '�G���['
--         ,iv_req_no       => gv_req_no                          --  in �˗�No
--/* 2008/08/06 Mod ��
--         ,iv_kyoten       => gt_to_plan(gn_i).ktn               --  in �Ǌ����_
--2008/08/06 Mod �� */
--         ,iv_kyoten       => gt_to_plan(ln_cnt).ktn             --  in �Ǌ����_
--/* 2008/08/06 Mod ��
--         ,iv_item         => gt_to_plan(gn_i).item_no           --  in �i��
--2008/08/06 Mod �� */
--         ,iv_item         => gt_to_plan(ln_cnt).item_no         --  in �i��
--/* 2008/08/06 Mod ��
--         ,in_qty          => gt_to_plan(gn_i).amount            --  in ����
--2008/08/06 Mod �� */
--         ,in_qty          => gt_to_plan(ln_cnt).amount          --  in ����
--         ,iv_ship_date    => TO_CHAR(gd_ship_day,'YYYY/MM/DD')  --  in �o�ɓ� [�o�ח\���]
--/* 2008/08/06 Mod ��
--         ,iv_arrival_date => TO_CHAR(gt_to_plan(gn_i).for_date,'YYYY/MM/DD')
--2008/08/06 Mod �� */
--         ,iv_arrival_date => TO_CHAR(gt_to_plan(ln_cnt).for_date,'YYYY/MM/DD')
--                                                                --  in ����
--         ,iv_err_msg      => gv_tkn_msg_20                      --  in �G���[���b�Z�[�W
--/* 2008/08/06 Mod ��
--         ,iv_err_clm      => gt_to_plan(gn_i).amount            --  in �G���[����  [����]
--2008/08/06 Mod �� */
--         ,iv_err_clm      => gt_to_plan(ln_cnt).amount          --  in �G���[����  [����]
--         ,ov_errbuf       => lv_errbuf                          -- out �G���[�E���b�Z�[�W
--         ,ov_retcode      => lv_retcode                         -- out ���^�[���E�R�[�h
--         ,ov_errmsg       => lv_errmsg                          -- out ���[�U�[�E�G���[�E���b�Z�[�W
--        );
--
        pro_err_list_make
          (
            iv_kind         => gv_tkn_msg_war                     --  in ���  '�x��'
           ,iv_dec          => gv_tkn_msg_err                     --  in �m��  '�G���['
           ,iv_req_no       => gv_req_no                          --  in �˗�No
           ,iv_kyoten       => gt_to_plan(i).ktn                  --  in �Ǌ����_
           ,iv_item         => gt_to_plan(i).item_no              --  in �i��
           ,in_qty          => gt_to_plan(i).amount               --  in ����
           ,iv_ship_date    => TO_CHAR(gd_ship_day,'YYYY/MM/DD')  --  in �o�ɓ� [�o�ח\���]
           ,iv_arrival_date => TO_CHAR(gt_to_plan(i).for_date,'YYYY/MM/DD')
                                                                  --  in ����
           ,iv_err_msg      => gv_tkn_msg_20                      --  in �G���[���b�Z�[�W
           ,iv_err_clm      => gt_to_plan(i).amount               --  in �G���[����  [����]
-- 2008/08/18 H.Itou Add Start �ύڌ������b�Z�[�W���i�[����SEQ�ԍ�
           ,in_calc_load_eff_msg_seq => gt_to_plan(i).ca_loading_msg_seq -- �ύڌ���(�e��)���b�Z�[�W�i�[SEQ
-- 2008/08/18 H.Itou Add End
           ,ov_errbuf       => lv_errbuf                          -- out �G���[�E���b�Z�[�W
           ,ov_retcode      => lv_retcode                         -- out ���^�[���E�R�[�h
           ,ov_errmsg       => lv_errmsg                          -- out ���[�U�[�E�G���[�E���b�Z�[�W
          );
-- 2008/08/13 H.Itou MOD END
-- 2008/08/13 H.Itou MOD START
        -- ���ʃG���[���b�Z�[�W �I��ST�̔���
        IF (gv_err_sts <> gv_status_error) THEN
          gv_err_sts := gv_status_warn;
        END IF;
-- 2008/08/13 H.Itou MOD END
-- 2008/08/13 H.Itou ADD START �o�גǉ�_1 �ύڌ����G���[�̃��[�j���O�͖��ׂ��Ƃɏo��
      END LOOP warn_loop;
-- 2008/08/13 H.Itou ADD END
    END IF;
--
  EXCEPTION
    -- *** ���ʊ֐� �x���E�G���[ ***
    WHEN err_header_expt THEN
      gv_err_flg := gv_1;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END pro_load_eff_chk;
--
  /**********************************************************************************
   * Procedure Name   : pro_headers_create
   * Description      : �󒍃w�b�_�A�h�I�����R�[�h���� (A-11)
   ***********************************************************************************/
  PROCEDURE pro_headers_create
    (
      in_plan_cnt   IN  NUMBER       -- �ΏۂƂ��Ă���Forecast�̌���
     ,ov_errbuf     OUT VARCHAR2     -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode    OUT VARCHAR2     -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg     OUT VARCHAR2     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    )
  IS
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'pro_headers_create'; -- �v���O������
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
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
        gn_h_cnt := gn_h_cnt + 1;
--
    -- =====================================================
    -- �ύڌ����`�F�b�N (A-10)
    -- =====================================================
    pro_load_eff_chk
      (
        in_plan_cnt       => in_plan_cnt        -- �ΏۂƂ��Ă���Forecast�̌��� --2008/08/06 Add
       ,ov_errbuf         => lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode        => lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg         => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_api_expt;
      --RAISE global_process_expt;
    END IF;
--
    ------------------------------------------------------
    -- �󒍃w�b�_�A�h�I���쐬�p���R�[�h�ϐ��֊i�[       --
    ------------------------------------------------------
--
    gt_h_order_header_id(gn_h_cnt)         := gn_headers_seq;              -- �󒍃w�b�_�A�h�I��ID
    gt_h_order_type_id(gn_h_cnt)           := gv_odr_type;                 -- �󒍃^�C�vID
    gt_h_organization_id(gn_h_cnt)         := gv_name_m_org;               -- �g�DID
    gt_h_latest_external_flag(gn_h_cnt)    := gv_yes;                      -- �ŐV�t���O
    gt_h_ordered_date(gn_h_cnt)            := gd_sysdate;                  -- �󒍓�
    --gt_h_customer_id(gn_h_cnt)             := gt_to_plan(gn_i).par_id;     -- �ڋqID
    --gt_h_customer_code(gn_h_cnt)           := gt_to_plan(gn_i).par_num;    -- �ڋq
    --gt_h_deliver_to_id(gn_h_cnt)           := gt_to_plan(gn_i).p_s_site;   -- �z����ID
    --gt_h_deliver_to(gn_h_cnt)              := gt_to_plan(gn_i).ship_t_no;  -- �z����
    --
    gt_h_customer_id(gn_h_cnt)             := gt_to_plan(in_plan_cnt).par_id;     -- �ڋqID
    gt_h_customer_code(gn_h_cnt)           := gt_to_plan(in_plan_cnt).par_num;    -- �ڋq
    gt_h_deliver_to_id(gn_h_cnt)           := gt_to_plan(in_plan_cnt).p_s_site;   -- �z����ID
    gt_h_deliver_to(gn_h_cnt)              := gt_to_plan(in_plan_cnt).ship_t_no;  -- �z����
    --
    gt_h_shipping_method_code(gn_h_cnt)    := gv_max_kbn;                  -- �z���敪
    gt_h_request_no(gn_h_cnt)              := gv_req_no;                   -- �˗�No
    gt_h_req_status(gn_h_cnt)              := gr_ship_st;                  -- �X�e�[�^�X
    gt_h_schedule_ship_date(gn_h_cnt)      := gd_ship_day;                 -- �o�ח\���
    --gt_h_schedule_arrival_date(gn_h_cnt)   := gt_to_plan(gn_i).for_date;   -- ���ח\���
    gt_h_schedule_arrival_date(gn_h_cnt)   := gt_to_plan(in_plan_cnt).for_date;   -- ���ח\���
    gt_h_notif_status(gn_h_cnt)            := gr_notice_st;                -- �ʒm�X�e�[�^�X
    --gt_h_deliver_from_id(gn_h_cnt)         := gt_to_plan(gn_i).ship_id;    -- �o�׌�ID
    --gt_h_deliver_from(gn_h_cnt)            := gt_to_plan(gn_i).ship_fr;    -- �o�׌��ۊǏꏊ
    --gt_h_Head_sales_branch(gn_h_cnt)       := gt_to_plan(gn_i).ktn;        -- �Ǌ����_
    gt_h_deliver_from_id(gn_h_cnt)         := gt_to_plan(in_plan_cnt).ship_id;    -- �o�׌�ID
    gt_h_deliver_from(gn_h_cnt)            := gt_to_plan(in_plan_cnt).ship_fr;    -- �o�׌��ۊǏꏊ
    gt_h_Head_sales_branch(gn_h_cnt)       := gt_to_plan(in_plan_cnt).ktn;        -- �Ǌ����_
    gt_h_input_sales_branch(gn_h_cnt)      := gr_param.base;               -- ���͋��_
    --gt_h_prod_class(gn_h_cnt)              := gt_to_plan(gn_i).skbn;       -- ���i�敪
    gt_h_prod_class(gn_h_cnt)              := gt_to_plan(in_plan_cnt).skbn; -- ���i�敪
    gt_h_sum_quantity(gn_h_cnt)            := gn_ttl_amount;               -- ���v����
    gt_h_small_quantity(gn_h_cnt)          := gn_ttl_ship_am;              -- ������
    gt_h_label_quantity(gn_h_cnt)          := gn_ttl_ship_am;              -- ���x������
    gt_h_loading_eff_weight(gn_h_cnt)      := gn_we_loading;               -- �d�ʐύڌ���
    gt_h_loading_eff_capacity(gn_h_cnt)    := gn_ca_loading;               -- �e�ϐύڌ���
    gt_h_based_weight(gn_h_cnt)            := gn_leaf_we;                  -- ��{�d��
    gt_h_based_capacity(gn_h_cnt)          := gn_leaf_ca;                  -- ��{�e��
    gt_h_sum_weight(gn_h_cnt)              := gn_h_ttl_weight;             -- �ύڏd�ʍ��v
    gt_h_sum_capacity(gn_h_cnt)            := gn_h_ttl_capa;               -- �ύڗe�ύ��v
    gt_h_sum_pallet_weight(gn_h_cnt)       := gn_h_ttl_pallet;             -- ���v�p���b�g�d��
    --gt_h_weight_capacity_class(gn_h_cnt)   := gt_to_plan(gn_i).wei_kbn;      -- �d�ʗe�ϋ敪
    gt_h_weight_capacity_class(gn_h_cnt)   := gt_to_plan(in_plan_cnt).wei_kbn; -- �d�ʗe�ϋ敪
    gt_h_actual_confirm_class(gn_h_cnt)    := gv_no;                       -- ���ьv��ϋ敪
    gt_h_new_modify_flg(gn_h_cnt)          := gv_no;                       -- �V�K�C���t���O
    gt_h_per_management_dept(gn_h_cnt)     := NULL;                        -- ���ъǗ�����
    gt_h_screen_update_date(gn_h_cnt)      := NULL;                        -- ��ʍX�V����
-- add start 1.7 uehara
    gt_h_confirm_request_class(gn_h_cnt)   := gv_0;                        -- �����S���m�F�˗��敪
    gt_h_freight_charge_class(gn_h_cnt)    := gv_1;                        -- �^���敪
    gt_h_no_cont_freight_class(gn_h_cnt)   := gv_0;                        -- �_��O�^���敪
-- add end 1.7 uehara
    gt_h_created_by(gn_h_cnt)              := gn_created_by;               -- �쐬��
    gt_h_creation_date(gn_h_cnt)           := gd_creation_date;            -- �쐬��
    gt_h_last_updated_by(gn_h_cnt)         := gn_last_upd_by;              -- �ŏI�X�V��
    gt_h_last_update_date(gn_h_cnt)        := gd_last_upd_date;            -- �ŏI�X�V��
    gt_h_last_update_login(gn_h_cnt)       := gn_last_upd_login;           -- �ŏI�X�V���O�C��
    gt_h_request_id(gn_h_cnt)              := gn_request_id;               -- �v��ID
    gt_h_program_application_id(gn_h_cnt)  := gn_prog_appl_id;             -- �v���O�����A�v��ID
    gt_h_program_id(gn_h_cnt)              := gn_prog_id;                  -- �v���O����ID
    gt_h_program_update_date(gn_h_cnt)     := gd_prog_upd_date;            -- �v���O�����X�V��
--
    -- �󒍃w�b�_�A�h�I�����ڗp�ϐ� ������
    gn_ttl_ship_am  := 0;       -- �o�גP�ʊ��Z��
    gn_ttl_amount   := 0;       -- ���v����
    gn_h_ttl_weight := 0;       -- �ύڏd�ʍ��v
    gn_h_ttl_capa   := 0;       -- �ύڗe�ύ��v
    gn_h_ttl_pallet := 0;       -- ���v�p���b�g�d��
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END pro_headers_create;
--
  /**********************************************************************************
   * Procedure Name   : pro_ship_order
   * Description      : �o�׈˗��o�^���� (A-12)
   ***********************************************************************************/
  PROCEDURE pro_ship_order
    (
      ov_errbuf     OUT VARCHAR2     -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode    OUT VARCHAR2     -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg     OUT VARCHAR2     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    )
  IS
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'pro_ship_order'; -- �v���O������
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
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- *************************************************
    -- ***  �󒍃w�b�_�A�h�I���e�[�u���ꊇ�X�V       ***
    -- *************************************************
    FORALL i IN gt_h_order_header_id.FIRST .. gt_h_order_header_id.LAST
      INSERT INTO xxwsh_order_headers_all
        ( order_header_id
         ,order_type_id
         ,organization_id
         ,latest_external_flag
         ,ordered_date
         ,customer_id
         ,customer_code
         ,deliver_to_id
         ,deliver_to
         ,shipping_method_code
         ,request_no
         ,req_status
         ,schedule_ship_date
         ,schedule_arrival_date
         ,notif_status
         ,deliver_from_id
         ,deliver_from
         ,Head_sales_branch 
         ,input_sales_branch
         ,prod_class
         ,sum_quantity
         ,small_quantity
         ,label_quantity
         ,loading_efficiency_weight
         ,loading_efficiency_capacity
         ,based_weight
         ,based_capacity
         ,sum_weight
         ,sum_capacity
         ,sum_pallet_weight
         ,weight_capacity_class
         ,actual_confirm_class
         ,new_modify_flg
         ,performance_management_dept
         ,screen_update_date
-- add start 1.7 uehara
         ,confirm_request_class
         ,freight_charge_class
         ,no_cont_freight_class
-- add end 1.7 uehara
         ,created_by
         ,creation_date
         ,last_updated_by
         ,last_update_date
         ,last_update_login
         ,request_id
         ,program_application_id
         ,program_id
         ,program_update_date
        ) VALUES
        ( gt_h_order_header_id(i)
         ,gt_h_order_type_id(i)
         ,gt_h_organization_id(i)
         ,gt_h_latest_external_flag(i)
         ,gt_h_ordered_date(i)
         ,gt_h_customer_id(i)
         ,gt_h_customer_code(i)
         ,gt_h_deliver_to_id(i)
         ,gt_h_deliver_to(i)
         ,gt_h_shipping_method_code(i)
         ,gt_h_request_no(i)
         ,gt_h_req_status(i)
         ,gt_h_schedule_ship_date(i)
         ,gt_h_schedule_arrival_date(i)
         ,gt_h_notif_status(i)
         ,gt_h_deliver_from_id(i)
         ,gt_h_deliver_from(i)
         ,gt_h_Head_sales_branch(i)
         ,gt_h_input_sales_branch(i)
         ,gt_h_prod_class(i)
         ,gt_h_sum_quantity(i)
         ,gt_h_small_quantity(i)
         ,gt_h_label_quantity(i)
         ,gt_h_loading_eff_weight(i)
         ,gt_h_loading_eff_capacity(i)
         ,gt_h_based_weight(i)
         ,gt_h_based_capacity(i)
         ,gt_h_sum_weight(i)
         ,gt_h_sum_capacity(i)
         ,gt_h_sum_pallet_weight(i)
         ,gt_h_weight_capacity_class(i)
         ,gt_h_actual_confirm_class(i)
         ,gt_h_new_modify_flg(i)
         ,gt_h_per_management_dept(i)
         ,gt_h_screen_update_date(i)
-- add start 1.7 uehara
         ,gt_h_confirm_request_class(i)
         ,gt_h_freight_charge_class(i)
         ,gt_h_no_cont_freight_class(i)
-- add end 1.7 uehara
         ,gt_h_created_by(i)
         ,gt_h_creation_date(i)
         ,gt_h_last_updated_by(i)
         ,gt_h_last_update_date(i)
         ,gt_h_last_update_login(i)
         ,gt_h_request_id(i)
         ,gt_h_program_application_id(i)
         ,gt_h_program_id(i)
         ,gt_h_program_update_date(i)
        );
--
    -- *************************************************
    -- ***  �󒍖��׃A�h�I���e�[�u���ꊇ�X�V         ***
    -- *************************************************
    FORALL i IN gt_l_order_line_id.FIRST .. gt_l_order_line_id.LAST
      INSERT INTO xxwsh_order_lines_all
        ( order_line_id
         ,order_header_id
         ,order_line_number
         ,request_no
         ,shipping_inventory_item_id
         ,shipping_item_code
         ,quantity
         ,uom_code
         ,based_request_quantity
         ,request_item_id
         ,request_item_code
         ,weight
         ,capacity
         ,pallet_weight
         ,delete_flag
         ,created_by
         ,creation_date
         ,last_updated_by
         ,last_update_date
         ,last_update_login
         ,request_id
         ,program_application_id
         ,program_id
         ,program_update_date
        ) VALUES
        ( gt_l_order_line_id(i)
         ,gt_l_order_header_id(i)
         ,gt_l_order_line_number(i)
         ,gt_l_request_no(i)
         ,gt_l_shipping_inv_item_id(i)
         ,gt_l_shipping_item_code(i)
         ,gt_l_quantity(i)
         ,gt_l_uom_code(i)
         ,gt_l_based_request_quantity(i)
         ,gt_l_request_item_id(i)
         ,gt_l_request_item_code(i)
         ,gt_l_weight(i)
         ,gt_l_capacity(i)
         ,gt_l_pallet_weight(i)
         ,gt_l_delete_flag(i)
         ,gt_l_created_by(i)
         ,gt_l_creation_date(i)
         ,gt_l_last_updated_by(i)
         ,gt_l_last_update_date(i)
         ,gt_l_last_update_login(i)
         ,gt_l_request_id(i)
         ,gt_l_program_application_id(i)
         ,gt_l_program_id(i)
         ,gt_l_program_update_date(i)
        );
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END pro_ship_order;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain
    (
      iv_yyyymm   IN   VARCHAR2     --  01.�Ώ۔N��
     ,iv_base     IN   VARCHAR2     --  02.�Ǌ����_
     ,ov_errbuf   OUT  VARCHAR2     --  �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode  OUT  VARCHAR2     --  ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg   OUT  VARCHAR2     --  ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    )
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
    ln_plan_cnt NUMBER;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- =====================================================
    -- ��������
    -- =====================================================
    -- -----------------------------------------------------
    -- �p�����[�^�i�[
    -- -----------------------------------------------------
    gr_param.yyyymm  := iv_yyyymm;    -- �Ώ۔N��
    gr_param.base    := iv_base;      -- �Ǌ����_
--
    -- �J�n���̃V�X�e�����ݓ��t����
    gd_sysdate       := TRUNC( SYSDATE );
--
    -- �O���[�o���ϐ��̏�����
    gn_target_cnt    := 0;
    gn_normal_cnt    := 0;
    gn_error_cnt     := 0;
    gn_warn_cnt      := 0;
--
    -- ���ʃG���[���b�Z�[�W �I��ST������
    gv_err_sts       := gv_status_normal;
--
    -- =====================================================
    --  �֘A�f�[�^�擾 (A-1)
    -- =====================================================
    pro_get_cus_option
      (
        ov_errbuf         => lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode        => lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg         => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- =====================================================
    --  ���̓p�����[�^�`�F�b�N    (A-2)
    -- =====================================================
    pro_param_chk
      (
        ov_errbuf         => lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode        => lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg         => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- =====================================================
    --  ����v���񒊏o  (A-3)
    -- =====================================================
    pro_get_to_plan
      (
        ot_to_plan        => gt_to_plan         -- �擾���R�[�h�Q
       ,ov_errbuf         => lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode        => lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg         => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- 2008/07/09 Add ��
    IF (gt_to_plan.COUNT = 0) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg('XXWSH',
                                            'APP-XXWSH-10002');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      ov_retcode := gv_status_warn;
      RETURN;
    END IF;
    -- 2008/07/09 Add ��
--
    -- ���_/�o�׌�/���ח\���/�d�ʗe�ϋ敪�̕ϐ�������
    gv_ktn      := NULL;
    gv_ship_fr  := NULL;
    gv_for_date := NULL;
    gv_wei_kbn  := NULL;
--
    <<headers_data_loop>>
    FOR i IN 1..gt_to_plan.COUNT LOOP
      -- LOOP�J�E���g�p�ϐ��փJ�E���g���}��
      gn_i := i;
--
      -- �G���[�m�F�p�t���O������
      gv_err_flg := gv_0;
--
      -- �ŏI���R�[�h���A
      -- �܂��͏��񃌃R�[�h�ȊO�ŁA���_/�o�׌�/���ח\���/�d�ʗe�ϋ敪�̂����ǂꂩ���قȂ����ꍇ
      IF (
           (gn_i <> 1)
           AND
           (
             (gt_to_plan(gn_i).ktn      <> gv_ktn) OR
             (gt_to_plan(gn_i).ship_fr  <> gv_ship_fr) OR
             (gt_to_plan(gn_i).for_date <> gv_for_date) OR
             (gt_to_plan(gn_i).wei_kbn  <> gv_wei_kbn)
           )
         )
      THEN
--
        ln_plan_cnt := gn_i - 1;
      -- =====================================================
      -- �󒍃w�b�_�A�h�I�����R�[�h���� (A-11)
      -- =====================================================
        pro_headers_create
          (
            in_plan_cnt       => ln_plan_cnt        -- �ΏۂƂ��Ă���Forecast�̌���
           ,ov_errbuf         => lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
           ,ov_retcode        => lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
           ,ov_errmsg         => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
          );
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_process_expt;
        END IF;
--
      END IF;
--
      -- ���񃌃R�[�h�A�܂��͋��_/�o�׌�/���ח\���/�d�ʗe�ϋ敪�̂����ǂꂩ���قȂ����ꍇ�A���s
      IF  (
            (gn_i = 1)
            OR
            (
              (gt_to_plan(i).ktn      <> gv_ktn) OR
              (gt_to_plan(i).ship_fr  <> gv_ship_fr) OR
              (gt_to_plan(i).for_date <> gv_for_date) OR
              (gt_to_plan(i).wei_kbn  <> gv_wei_kbn)
            )
          )
      THEN
--
        ---------------------------------------------
        -- �󒍃w�b�_�A�h�I��ID �V�[�P���X�擾     --
        ---------------------------------------------
        SELECT xxwsh_order_headers_all_s1.NEXTVAL
        INTO   gn_headers_seq
        FROM   dual;
--
        ---------------------------------------------
        -- ���ʊ֐��u�̔Ԋ֐��v�ɂāA�˗�No �̔�   --
        ---------------------------------------------
        xxcmn_common_pkg.get_seq_no( 
                                     gv_6              -- �̔Ԕԍ��敪  in �˗�No '6'
                                    ,gv_req_no         -- �̔Ԃ���No
                                    ,lv_errbuf         -- �G���[�E���b�Z�[�W
                                    ,lv_retcode        -- ���^�[���E�R�[�h
                                    ,lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W
                                   );
--
        -- �o�׈˗��쐬����(�˗��m���P��)�J�E���g
        gn_req_cnt := gn_req_cnt + 1;
--
        -- ���^�[���R�[�h���G���[�̏ꍇ
        IF (lv_retcode = 1) THEN
--
          -- �G���[���X�g�쐬
          pro_err_list_make
            (
              iv_kind         => gv_tkn_msg_err              --  in ���  '�G���['
             ,iv_dec          => gv_tkn_msg_hfn              --  in �m��  '-'
             ,iv_req_no       => gv_req_no                   --  in �˗�No
             ,iv_kyoten       => gt_to_plan(i).ktn           --  in �Ǌ����_
             ,iv_item         => gt_to_plan(i).item_no       --  in �i��
             ,in_qty          => gt_to_plan(i).amount        --  in ����
             ,iv_ship_date    => gv_tkn_msg_hfn              --  in �o�ɓ�
             ,iv_arrival_date => TO_CHAR(gt_to_plan(gn_i).for_date,'YYYY/MM/DD')
                                                             --  in ����
             ,iv_err_msg      => gv_tkn_msg_22 || lv_errmsg  --  in �G���[���b�Z�[�W
             ,iv_err_clm      => gv_tkn_msg_hfn              --  in �G���[����   '-'
             ,ov_errbuf       => lv_errbuf                   -- out �G���[�E���b�Z�[�W
             ,ov_retcode      => lv_retcode                  -- out ���^�[���E�R�[�h
             ,ov_errmsg       => lv_errmsg                   -- out ���[�U�[�E�G���[�E���b�Z�[�W
            );
          RAISE global_process_expt;
        END IF;
      END IF;
--
      -- =====================================================
      -- �o�ח\���/�ő�z���敪�Z�o (A-4)
      -- =====================================================
      pro_ship_max_kbn
        (
          ov_errbuf         => lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
         ,ov_retcode        => lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
         ,ov_errmsg         => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
      -- �G���[�m�F�p�t���O (A-4�ɂăG���[�̏ꍇ�́A���L�������{���Ȃ�)
      IF (gv_err_flg <> gv_1) THEN
        ---------------------------------------------
        -- �󒍖��׃A�h�I��ID �V�[�P���X�擾       --
        ---------------------------------------------
        SELECT xxwsh_order_lines_all_s1.NEXTVAL
        INTO   gn_lines_seq
        FROM   dual;
--
        -- =====================================================
        -- ���׍��ڃ`�F�b�N (A-5)
        -- =====================================================
        pro_lines_chk
          (
            ov_errbuf         => lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
           ,ov_retcode        => lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
           ,ov_errmsg         => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
          );
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_process_expt;
        END IF;
--
        -- =====================================================
        -- �����\���A�h�I���}�X�^���݃`�F�b�N (A-6)
        -- =====================================================
        pro_xsr_chk
          (
            ov_errbuf         => lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
           ,ov_retcode        => lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
           ,ov_errmsg         => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
          );
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_process_expt;
        END IF;
--
        -- =====================================================
        -- ���v�d��/���v�e�ώZ�o (A-7)
        -- =====================================================
        pro_total_we_ca
          (
            ov_errbuf         => lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
           ,ov_retcode        => lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
           ,ov_errmsg         => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
          );
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_process_expt;
        END IF;
--
        -- �G���[�m�F�p�t���O (A-7�ɂăG���[�̏ꍇ�́A���L�������{���Ȃ�)
        IF (gv_err_flg <> gv_2) THEN
          -- =====================================================
          -- �o�׉ۃ`�F�b�N (A-8)
          -- =====================================================
          pro_ship_y_n_chk
            (
              ov_errbuf         => lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
             ,ov_retcode        => lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
             ,ov_errmsg         => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
            );
          IF (lv_retcode = gv_status_error) THEN
            RAISE global_process_expt;
          END IF;
        END IF;
--
        -- =====================================================
        -- �󒍖��׃A�h�I�����R�[�h���� (A-9)
        -- =====================================================
        pro_lines_create
          (
            ov_errbuf         => lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
           ,ov_retcode        => lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
           ,ov_errmsg         => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
          );
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_process_expt;
        END IF;
--
        -- �G���[�m�F�p�t���O������
        IF (gv_err_flg = gv_2) THEN
          gv_err_flg := gv_0;
        END IF;
      END IF;
--
      -- ���_/�o�׌�/���ח\���/�d�ʗe�ϋ敪����p���ڍX�V
      gv_ktn      := gt_to_plan(i).ktn;          -- ���_
      gv_ship_fr  := gt_to_plan(i).ship_fr;      -- �o�׌�
      gv_for_date := gt_to_plan(i).for_date;     -- ���ח\���
      gv_wei_kbn  := gt_to_plan(i).wei_kbn;      -- �d�ʗe�ϋ敪
--
      -- �Ώۈ���v�挏��(�i�ڒP��)�J�E���g
      gn_item_cnt := gn_item_cnt + 1;
--
    END LOOP headers_data_loop;
--
    IF (gt_to_plan.COUNT <> 0) THEN
      -- =====================================================
      -- �󒍃w�b�_�A�h�I�����R�[�h���� (A-11)
      -- =====================================================
        pro_headers_create
          (
             in_plan_cnt       => (gn_i)            -- �ΏۂƂ��Ă���Forecast�̌���
            ,ov_errbuf         => lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
            ,ov_retcode        => lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
            ,ov_errmsg         => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
          );
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_process_expt;
        END IF;
--
      -- =====================================================
      -- �o�׈˗��o�^���� (A-12)
      -- =====================================================
      pro_ship_order
        (
          ov_errbuf         => lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
         ,ov_retcode        => lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
         ,ov_errmsg         => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
    END IF;
--
    -- �X�e�[�^�X��}��
    IF (gt_to_plan.COUNT = 0) THEN
      ov_retcode := gv_status_normal;
    ELSIF (gv_err_sts = gv_status_warn)
    OR    (gv_err_sts = gv_status_error)
    THEN
      ov_retcode := gv_err_sts;
    END IF;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ###################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_prg_name||gv_msg_part||SQLERRM;
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
  PROCEDURE main
    (
      errbuf     OUT    VARCHAR2     --  �G���[�E���b�Z�[�W  --# �Œ� #
     ,retcode    OUT    VARCHAR2     --  ���^�[���E�R�[�h    --# �Œ� #
     ,iv_yyyymm  IN     VARCHAR2     --  01.�Ώ۔N��
     ,iv_base    IN     VARCHAR2     --  02.�Ǌ����_
    )
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
    --��؂蕶���o��
    gv_sep_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00003');
--
--###########################  �Œ蕔 END   #############################
--
    -- ===============================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ===============================================
    submain
      (
        iv_yyyymm   => iv_yyyymm   -- 01.�Ώ۔N��
       ,iv_base     => iv_base     -- 02.�Ǌ����_
       ,ov_errbuf   => lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode  => lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg   => lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
--
    -----------------------------------------------
    -- ���̓p�����[�^�o��                        --
    -----------------------------------------------
    -- ���̓p�����[�^�u�Ώ۔N���v�o��
    gv_out_msg := xxcmn_common_pkg.get_msg('XXWSH','APP-XXWSH-11007','YYMM',gr_param.yyyymm);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    -- ���̓p�����[�^�u�Ǌ����_�v�o��
    gv_out_msg := xxcmn_common_pkg.get_msg('XXWSH','APP-XXWSH-11008','KYOTEN',gr_param.base);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --��؂蕶����o��
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_sep_msg);
--
    -- �G���[���X�g�o��
    IF (gt_err_msg.COUNT > 0) THEN
      -- ���ږ��o��
      gv_err_report := gv_name_kind      || CHR(9) || gv_name_dec      || CHR(9) ||
                       gv_name_req_no    || CHR(9) || gv_name_kyoten   || CHR(9) ||
                       gv_name_item_a    || CHR(9) || gv_name_qty      || CHR(9) ||
                       gv_name_ship_date || CHR(9) || gv_name_arr_date || CHR(9) ||
                       gv_name_err_msg   || CHR(9) || gv_name_err_clm;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_err_report);
--
      -- ���ڋ�؂���o��
      gv_err_report := gv_line || gv_line || gv_line || gv_line || gv_line || gv_line || gv_line;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_err_report);
--
      -- �G���[���X�g���e�o��
      <<err_report_loop>>
      FOR i IN 1..gt_err_msg.COUNT LOOP
-- 2008/08/18 H.Itou Add Start
        -- �ύڌ����G���[���b�Z�[�W�p�_�~�[�G���[���b�Z�[�W�iNULL�j�͏o�͂��Ȃ�
        IF (gt_err_msg(i).err_msg IS NOT NULL) THEN
-- 2008/08/18 H.Itou Add End
-- 2008/08/18 H.Itou Mod Start
          FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gt_err_msg(i).err_msg);
-- 2008/08/18 H.Itou Mod End
-- 2008/08/18 H.Itou Add Start
        END IF;
-- 2008/08/18 H.Itou Add End
      END LOOP err_report_loop;
--
      --��؂蕶����o��
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_sep_msg);
--
    END IF;
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
      ELSIF (lv_errbuf IS NULL) THEN
        --���[�U�[�E�G���[�E���b�Z�[�W�̃R�s�[
        lv_errbuf := lv_errmsg;
      END IF;
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      --��؂蕶����o��
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_sep_msg);
--
    END IF;
    -- ==================================
    -- ���^�[���E�R�[�h�̃Z�b�g�A�I������
    -- ==================================
    --���������o��(�Ώۈ���v�挏��(�i�ڒP��))
    gv_out_msg := xxcmn_common_pkg.get_msg('XXWSH','APP-XXWSH-11009','CNT',TO_CHAR(gn_item_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --���������o��(�o�׈˗��쐬����(�˗��m���P��))
    gv_out_msg := xxcmn_common_pkg.get_msg('XXWSH','APP-XXWSH-11010','CNT',TO_CHAR(gn_req_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --���������o��(�o�׈˗��쐬����(�˗����גP��))
    gv_out_msg := xxcmn_common_pkg.get_msg('XXWSH','APP-XXWSH-11011','CNT',TO_CHAR(gn_line_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --��؂蕶����o��
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_sep_msg);
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
      errbuf  := cv_prg_name||gv_msg_part||SQLERRM;
      retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      errbuf  := cv_prg_name||gv_msg_part||SQLERRM;
      retcode := gv_status_error;
  END main;
--
--###########################  �Œ蕔 END   #######################################################
--
END xxwsh400001c;
/
